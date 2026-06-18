local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.ChallengeTimer = KeyLab.Capture.ChallengeTimer or {}

local ChallengeTimer = KeyLab.Capture.ChallengeTimer

--[[
KeyLab_ChallengeTimer.lua

Purpose:
- Own official Challenge Mode timer capture.
- Keep run result, timer delta, chest result, and official death count out of UI code.
- Does NOT read C_DamageMeter.
- Does NOT build saved encounter records.
]]

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end

    local ok, a, b, c, d, e, f, g, h = pcall(func, ...)
    if not ok then
        return false, tostring(a)
    end

    return true, a, b, c, d, e, f, g, h
end

local function CopyArray(list)
    local out = {}
    if type(list) ~= "table" then return out end

    for i, value in ipairs(list) do
        out[i] = value
    end

    return out
end

local function CopyContext(context)
    local out = {}
    if type(context) == "table" then
        for key, value in pairs(context) do
            if key == "affixIDs" then
                out.affixIDs = CopyArray(value)
            else
                out[key] = value
            end
        end
    end

    out.affixIDs = out.affixIDs or {}
    return out
end

local function NormalizeSeconds(value)
    value = tonumber(value)
    if not value then return nil end
    if math.abs(value) > 100000 then
        value = value / 1000
    end
    return value
end

local function RoundSeconds(value)
    value = NormalizeSeconds(value)
    if not value then return nil end
    if value < 0 then
        return math.ceil(value)
    end
    return math.floor(value)
end

local function ApplyMapName(context)
    if type(context) ~= "table" then return context end
    if context.mapID and KeyLab.Mapping and KeyLab.Mapping.GetMapName then
        context.dungeonName = KeyLab.Mapping.GetMapName(context.mapID) or context.dungeonName
    end
    if not context.dungeonName and GetRealZoneText then
        context.dungeonName = GetRealZoneText()
    end
    return context
end

local function ReadActiveChallenge(context)
    context = CopyContext(context)

    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        local ok, mapID = SafeCall(C_ChallengeMode.GetActiveChallengeMapID)
        if ok and mapID and mapID ~= 0 then
            context.mapID = mapID
        end
    end

    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local ok, level, affixes = SafeCall(C_ChallengeMode.GetActiveKeystoneInfo)
        if ok then
            context.keyLevel = level or context.keyLevel
            if type(affixes) == "table" then
                context.affixIDs = CopyArray(affixes)
            end
        end
    end

    return ApplyMapName(context)
end

local function ApplyMapTimer(context)
    if type(context) ~= "table" or not context.mapID then return context end

    if C_ChallengeMode and C_ChallengeMode.GetMapUIInfo then
        local ok, name, _, timeLimit = SafeCall(C_ChallengeMode.GetMapUIInfo, context.mapID)
        if ok then
            context.dungeonName = context.dungeonName or name
            local limit = NormalizeSeconds(timeLimit)
            if limit and limit > 0 then
                context.timeLimitSeconds = limit
                context.timeLimitSource = "challengeModeMapUIInfo"
            end
        end
    end

    if (not context.timeLimitSeconds or context.timeLimitSeconds <= 0)
        and KeyLab.Mapping and KeyLab.Mapping.GetMapTimerSeconds
    then
        local limit = KeyLab.Mapping.GetMapTimerSeconds(context.mapID)
        if limit and limit > 0 then
            context.timeLimitSeconds = limit
            context.timeLimitSource = "keyLabMapTimer"
        end
    end

    local limit = tonumber(context.timeLimitSeconds)
    if limit and limit > 0 then
        context.level2TimeSeconds = math.floor(limit * 0.8)
        context.level3TimeSeconds = math.floor(limit * 0.6)
    end

    return context
end

local function ReadRemainingSeconds()
    if not C_ChallengeMode or not C_ChallengeMode.GetTimeRemainingSeconds then
        return nil
    end

    local ok, remaining = SafeCall(C_ChallengeMode.GetTimeRemainingSeconds)
    if not ok then return nil end
    return NormalizeSeconds(remaining)
end

local function ReadOfficialDeathCount()
    if not C_ChallengeMode or not C_ChallengeMode.GetDeathCount then
        return nil
    end

    local ok, count = SafeCall(C_ChallengeMode.GetDeathCount)
    count = ok and tonumber(count) or nil
    if count and count >= 0 then return math.floor(count) end
    return nil
end

local function ReadCompletionInfo()
    if not C_ChallengeMode or not C_ChallengeMode.GetCompletionInfo then
        return nil
    end

    local ok, mapID, level, duration, onTime, upgradeLevels = SafeCall(C_ChallengeMode.GetCompletionInfo)
    if not ok then return nil end

    return {
        mapID = mapID,
        keyLevel = level,
        durationSeconds = NormalizeSeconds(duration),
        timed = onTime,
        keystoneUpgradeLevels = tonumber(upgradeLevels),
    }
end

local function ApplyCompletionInfo(context)
    local completion = ReadCompletionInfo()
    if type(completion) ~= "table" then return context end

    context.mapID = completion.mapID or context.mapID
    context.keyLevel = completion.keyLevel or context.keyLevel

    if completion.durationSeconds and completion.durationSeconds > 0 then
        context.durationSeconds = completion.durationSeconds
        context.durationSource = "challengeModeCompletionInfo"
        context.timingSource = "challengeModeCompletionInfo"
    end

    if completion.timed ~= nil then
        context.timed = completion.timed == true
        context.timedSource = "challengeModeCompletionInfo"
    end

    if completion.keystoneUpgradeLevels then
        context.keystoneUpgradeLevels = math.max(0, math.floor(completion.keystoneUpgradeLevels))
        context.keystoneUpgradeLevelsSource = "challengeModeCompletionInfo"
    end

    return ApplyMapName(context)
end

local function ApplyRemainingTiming(context, timingSource)
    local remaining = ReadRemainingSeconds()
    if not remaining then return context end

    local roundedRemaining = RoundSeconds(remaining)
    local limit = tonumber(context.timeLimitSeconds)

    context.remainingSeconds = roundedRemaining
    context.remainingSource = timingSource

    if limit and limit > 0 and not context.durationSeconds then
        context.timeDeltaSeconds = roundedRemaining
        context.durationSeconds = math.max(0, limit - roundedRemaining)
        context.durationSource = timingSource
        context.timingSource = timingSource

        if context.timed == nil then
            context.timed = roundedRemaining >= 0
            context.timedSource = timingSource
        end
    end

    return context
end

local function ApplyTimerMath(context)
    local duration = tonumber(context.durationSeconds)
    local limit = tonumber(context.timeLimitSeconds)

    if duration and duration > 0 and limit and limit > 0 then
        if context.timeDeltaSeconds == nil then
            context.timeDeltaSeconds = limit - duration
        end

        if context.timed == nil and context.durationSource then
            context.timed = duration <= limit
            context.timedSource = context.durationSource
        end

        if not context.keystoneUpgradeLevels and context.timed == true
            and KeyLab.Mapping and KeyLab.Mapping.GetTimerUpgradeLevels
        then
            context.keystoneUpgradeLevels = KeyLab.Mapping.GetTimerUpgradeLevels(duration, limit, true)
            context.keystoneUpgradeLevelsSource = "keyLabTimerThreshold"
        end
    end

    if context.timed ~= nil then
        context.result = context.timed and "Timed" or "Untimed"
    end

    return context
end

local function ApplyOfficialDeaths(context)
    local deathCount = ReadOfficialDeathCount()
    if deathCount ~= nil then
        context.deathCount = deathCount
        context.officialDeathCount = deathCount
        context.deathCountSource = "challengeModeDeathCount"
    end
    return context
end

function ChallengeTimer.Start(context)
    context = ReadActiveChallenge(context)
    context = ApplyMapTimer(context)

    context.challengeStartedAt = time and time() or nil
    context.challengeStartedAtText = date and date("%Y-%m-%d %H:%M:%S", context.challengeStartedAt) or nil
    context.challengeStartedAtRuntime = GetTime and GetTime() or nil
    context.timingSource = context.timingSource or "challengeModeStart"

    return context
end

function ChallengeTimer.RefineStart(context)
    context = ApplyMapTimer(ReadActiveChallenge(context))
    context = ApplyRemainingTiming(context, "challengeModeRemainingAtStart")
    context.durationSeconds = nil
    context.durationSource = nil
    context.timeDeltaSeconds = nil
    context.remainingSeconds = nil
    context.remainingSource = nil
    context.timed = nil
    context.timedSource = nil
    context.result = nil

    return context
end

function ChallengeTimer.Complete(context)
    context = ApplyMapTimer(ReadActiveChallenge(context))
    context = ApplyCompletionInfo(context)
    context = ApplyMapTimer(context)
    context = ApplyRemainingTiming(context, "challengeModeRemainingAtCompletion")
    context = ApplyTimerMath(context)
    context = ApplyOfficialDeaths(context)

    context.challengeCompletedAt = time and time() or nil
    context.challengeCompletedAtText = date and date("%Y-%m-%d %H:%M:%S", context.challengeCompletedAt) or nil
    context.challengeCompletedAtRuntime = GetTime and GetTime() or nil

    return context
end

return ChallengeTimer
