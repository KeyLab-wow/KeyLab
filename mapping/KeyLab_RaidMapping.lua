local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Mapping = KeyLab.Mapping or {}
KeyLab.Mapping.Raids = KeyLab.Mapping.Raids or {}

local Raids = KeyLab.Mapping.Raids

-- Exact instance/encounter pairs eligible for raid capture. The configured
-- instance IDs are Encounter Journal IDs; GetInstanceInfo can expose a
-- different map instance ID, so encounter IDs are also used to resolve the
-- configured raid at pull start.
Raids.instances = {
    [1314] = {
        instanceID = 1314,
        name = "Dreamrift",
        encounters = { [2795] = true },
    },
    [1307] = {
        instanceID = 1307,
        name = "Voidspire",
        encounters = {
            [2733] = true, [2734] = true, [2735] = true,
            [2736] = true, [2737] = true, [2738] = true,
        },
    },
    [1308] = {
        instanceID = 1308,
        name = "March on Quel'Danas",
        encounters = { [2739] = true, [2740] = true },
    },
    [1305] = {
        instanceID = 1305,
        name = "Sporefall",
        -- 3159 is the live ENCOUNTER_START/END ID for Rotmire. 2711 is
        -- retained because it is the Encounter Journal boss ID used by the
        -- loot database and preview records.
        encounters = { [3159] = true, [2711] = true },
    },
}

function Raids.IsAllowedEncounter(instanceID, encounterID)
    instanceID = tonumber(instanceID)
    encounterID = tonumber(encounterID)
    local instance = instanceID and Raids.instances[instanceID]
    return instance ~= nil and instance.encounters[encounterID] == true
end

function Raids.IsAllowedInstance(instanceID)
    return Raids.instances[tonumber(instanceID)] ~= nil
end

-- ENCOUNTER_START/END supplies DungeonEncounter IDs, which are different from
-- the boss IDs used by Encounter Journal and loot data. Once the location has
-- been resolved to an explicitly supported raid, any positive encounter ID is
-- a valid boss pull. Raid trash never fires these encounter events.
function Raids.IsAllowedRuntimeEncounter(instanceID, encounterID)
    encounterID = tonumber(encounterID)
    return Raids.IsAllowedInstance(instanceID) and encounterID ~= nil and encounterID > 0
end

function Raids.GetInstance(instanceID)
    return Raids.instances[tonumber(instanceID)]
end

function Raids.GetInstanceForEncounter(encounterID)
    encounterID = tonumber(encounterID)
    if not encounterID then return nil end

    local match = nil
    for _, instance in pairs(Raids.instances) do
        if instance.encounters[encounterID] == true then
            -- Encounter IDs should be unique. Refuse an ambiguous mapping
            -- instead of ever assigning a pull to the wrong raid.
            if match then return nil end
            match = instance
        end
    end
    return match
end

function Raids.GetInstanceByName(instanceName)
    if type(instanceName) ~= "string" or instanceName == "" then return nil end

    local wanted = instanceName:lower():gsub("^the%s+", ""):gsub("[%p%s]+", "")
    for _, instance in pairs(Raids.instances) do
        local candidate = tostring(instance.name or ""):lower():gsub("^the%s+", ""):gsub("[%p%s]+", "")
        if candidate ~= "" and candidate == wanted then return instance end
    end
    return nil
end

return Raids
