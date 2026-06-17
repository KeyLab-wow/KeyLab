local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Sessions = KeyLab.Capture.Sessions or {}

local Sessions = KeyLab.Capture.Sessions

--[[
KeyLab_Sessions.lua

Purpose:
- Owns temporary capture DB helpers.
- Owns Challenge Mode context collection.
- Validates allowed Mythic+ map/key context using mapping files.
- Does NOT read C_DamageMeter combat source rows.
- Does NOT capture player stats/talents.
- Does NOT format UI text.
]]

local CAPTURE_VERSION = "0.1.4"

local function SafeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end

    local ok, a, b, c, d, e, f, g, h, i, j = pcall(func, ...)
    if not ok then
        return false, tostring(a)
    end

    return true, a, b, c, d, e, f, g, h, i, j
end

local function CopyArray(list)
    local copy = {}

    if type(list) ~= "table" then
        return copy
    end

    for i, value in ipairs(list) do
        copy[i] = value
    end

    return copy
end

Sessions.SafeCall = SafeCall
Sessions.CopyArray = CopyArray

local function NormalizeSeconds(value)
    value = tonumber(value)
    if not value then return nil end
    -- Some Blizzard timer fields are milliseconds in older/newer APIs.
    if value > 100000 then
        value = value / 1000
    end
    return value
end

local function AddMapTimerInfo(context)
    if type(context) ~= "table" or not context.mapID then return context end
    if not C_ChallengeMode or not C_ChallengeMode.GetMapUIInfo then return context end

    local ok, name, id, timeLimit = SafeCall(C_ChallengeMode.GetMapUIInfo, context.mapID)
    if ok then
        context.timeLimitSeconds = NormalizeSeconds(timeLimit) or context.timeLimitSeconds
        context.dungeonName = context.dungeonName or name
    end

    return context
end

function Sessions.EnsureCaptureDB()
    if type(KeyLabCaptureDB) ~= "table" then
        KeyLabCaptureDB = {}
    end

    KeyLabCaptureDB.version = KeyLabCaptureDB.version or CAPTURE_VERSION
    return KeyLabCaptureDB
end

function Sessions.ResetCaptureDB()
    KeyLabCaptureDB = {
        version = CAPTURE_VERSION,
        active = false,
        completedSeen = false,
        interrupted = false,
    }

    return KeyLabCaptureDB
end

function Sessions.GetChallengeContext()
    local context = {
        mapID = nil,
        dungeonName = nil,
        keyLevel = nil,
        affixIDs = {},
    }

    if C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID then
        local ok, activeMapID = SafeCall(C_ChallengeMode.GetActiveChallengeMapID)
        if ok then
            context.mapID = activeMapID
        end
    end

    if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
        local ok, level, affixes = SafeCall(C_ChallengeMode.GetActiveKeystoneInfo)
        if ok then
            context.keyLevel = level
            context.affixIDs = CopyArray(affixes)
        end
    end

    if context.mapID and KeyLab.Mapping and KeyLab.Mapping.GetMapName then
        context.dungeonName = KeyLab.Mapping.GetMapName(context.mapID)
    end

    AddMapTimerInfo(context)

    if not context.dungeonName and GetRealZoneText then
        context.dungeonName = GetRealZoneText()
    end

    return context
end

function Sessions.GetCompletionContext()
    local context = Sessions.GetChallengeContext()

    if C_ChallengeMode and C_ChallengeMode.GetCompletionInfo then
        local ok, mapID, level, duration, onTime, keystoneUpgradeLevels = SafeCall(C_ChallengeMode.GetCompletionInfo)
        if ok then
            context.mapID = mapID or context.mapID
            context.keyLevel = level or context.keyLevel
            context.durationSeconds = NormalizeSeconds(duration) or context.durationSeconds
            if onTime ~= nil then
                context.timed = onTime == true
            end
            context.keystoneUpgradeLevels = keystoneUpgradeLevels
        end
    end

    if context.mapID and KeyLab.Mapping and KeyLab.Mapping.GetMapName then
        context.dungeonName = KeyLab.Mapping.GetMapName(context.mapID) or context.dungeonName
    end

    AddMapTimerInfo(context)

    if context.timed == nil and context.durationSeconds and context.timeLimitSeconds then
        context.timed = context.durationSeconds <= context.timeLimitSeconds
    end

    if context.timed ~= nil then
        context.result = context.timed and "Timed" or "Untimed"
    end

    return context
end

function Sessions.IsAllowedChallengeContext(context)
    if type(context) ~= "table" then
        return false, "missing challenge context"
    end

    if not context.mapID then
        return false, "missing active challenge mapID"
    end

    if KeyLab.Mapping and KeyLab.Mapping.IsAllowedChallengeMap then
        if not KeyLab.Mapping.IsAllowedChallengeMap(context.mapID) then
            return false, "mapID is not allowed by KeyLab map mapping: " .. tostring(context.mapID)
        end
    end

    if not context.keyLevel or context.keyLevel <= 0 then
        return false, "missing key level"
    end

    return true
end

function Sessions.MakeEncounterID(context)
    local timestamp = time()
    local mapID = context and context.mapID or 0
    local keyLevel = context and context.keyLevel or 0
    local playerName = UnitName and UnitName("player") or "player"

    return string.format(
        "%s-%s-%s-%s",
        date("%Y%m%d%H%M%S", timestamp),
        tostring(mapID),
        tostring(keyLevel),
        tostring(playerName)
    )
end
