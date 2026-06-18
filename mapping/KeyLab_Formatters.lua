local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Formatters = KeyLab.Formatters or {}

local Formatters = KeyLab.Formatters

local function SafeNumber(value)
    if KeyLab.Utils and KeyLab.Utils.SafeNumber then
        return KeyLab.Utils.SafeNumber(value)
    end

    local ok, result = pcall(function()
        local n = tonumber(value)
        if type(n) ~= "number" then return nil end
        local copy = n + 0
        if copy ~= copy then return nil end
        if not (copy < math.huge and copy > -math.huge) then return nil end
        return copy
    end)

    if ok and type(result) == "number" then
        return result
    end

    return nil
end

--[[
KeyLab Formatters

Purpose:
- Converts raw saved DB values into readable UI text.
- Does NOT change saved DB values.
- Uses displayType from mapping files.
]]

function Formatters.Number(value)
    value = SafeNumber(value)
    if value == nil then
        return "-"
    end

    if value >= 1000000000 then
        return string.format("%.1fB", value / 1000000000)
    elseif value >= 1000000 then
        return string.format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return string.format("%.1fK", value / 1000)
    end

    return tostring(math.floor(value + 0.5))
end

function Formatters.Percent(value)
    value = SafeNumber(value)
    if value == nil then
        return "-"
    end

    return string.format("%.1f%%", value)
end

function Formatters.Text(value)
    if value == nil or value == "" then
        return "-"
    end

    return tostring(value)
end

function Formatters.DateTime(timestamp)
    timestamp = SafeNumber(timestamp)
    if timestamp == nil then
        return "-"
    end

    return date("%b %d, %Y %I:%M %p", timestamp)
end

function Formatters.Duration(seconds)
    seconds = SafeNumber(seconds)
    if seconds == nil then
        return "-"
    end

    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)

    return string.format("%d:%02d", mins, secs)
end

function Formatters.ByDisplayType(value, displayType)
    if displayType == "percent" then
        return Formatters.Percent(value)
    elseif displayType == "number" then
        return Formatters.Number(value)
    elseif displayType == "text" then
        return Formatters.Text(value)
    elseif displayType == "datetime" then
        return Formatters.DateTime(value)
    elseif displayType == "duration" then
        return Formatters.Duration(value)
    end

    return Formatters.Text(value)
end

function Formatters.Stat(statKey, value)
    local info = KeyLab.Mapping
        and KeyLab.Mapping.Stats
        and KeyLab.Mapping.Stats[statKey]

    if not info then
        return Formatters.Text(value)
    end

    return Formatters.ByDisplayType(value, info.displayType)
end

function Formatters.Metric(metricKey, value)
    local metrics = KeyLab.Mapping and KeyLab.Mapping.Metrics

    if metrics then
        for _, info in pairs(metrics) do
            if info.keylabKey == metricKey then
                return Formatters.ByDisplayType(value, info.displayType)
            end
        end
    end

    local virtualMetrics = KeyLab.Mapping and KeyLab.Mapping.VirtualMetrics
    local virtualInfo = virtualMetrics and virtualMetrics[metricKey]
    if virtualInfo then
        return Formatters.ByDisplayType(value, virtualInfo.displayType)
    end

    return Formatters.Text(value)
end

function Formatters.Player(playerKey, value)
    local info = KeyLab.Mapping
        and KeyLab.Mapping.Player
        and KeyLab.Mapping.Player[playerKey]

    if not info then
        return Formatters.Text(value)
    end

    return Formatters.ByDisplayType(value, info.displayType)
end

function Formatters.MapName(mapID)
    if KeyLab.Mapping and KeyLab.Mapping.GetMapName then
        return KeyLab.Mapping.GetMapName(mapID) or ("Map " .. tostring(mapID))
    end

    return "Map " .. tostring(mapID or "-")
end

function Formatters.AffixName(affixID)
    if KeyLab.Mapping and KeyLab.Mapping.GetAffixName then
        return KeyLab.Mapping.GetAffixName(affixID) or ("Affix " .. tostring(affixID))
    end

    return "Affix " .. tostring(affixID or "-")
end

function Formatters.AffixList(affixIDs)
    if type(affixIDs) ~= "table" then
        return "-"
    end

    local names = {}

    for _, affixID in ipairs(affixIDs) do
        table.insert(names, Formatters.AffixName(affixID))
    end

    if #names == 0 then
        return "-"
    end

    return table.concat(names, ", ")
end
