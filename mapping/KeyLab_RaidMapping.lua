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
    [1320] = {
        instanceID = 1320,
        name = "The Venomous Abyss",
        encounters = {
            [2888] = true, [2874] = true, [2894] = true, [2882] = true,
            [2871] = true, [2887] = true, [2883] = true, [2895] = true,
        },
        encounterNames = {
            [2888] = "Nek'zali the Soulcoiler",
            [2874] = "Entombed Sentinels",
            [2894] = "The Lost Explorers",
            [2882] = "Vashnik the Malignant",
            [2871] = "Sszorak",
            [2887] = "The Twin Fangs",
            [2883] = "The Coiled Altar",
            [2895] = "Ula'tek",
        },
    },
    [1317] = {
        instanceID = 1317,
        name = "The Tidebound Grotto",
        encounters = { [2849] = true },
        encounterNames = { [2849] = "Nymrissa Wavecaller" },
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

-- Called only for a finished raid pull. Resolve the loot boss from the small
-- local catalog; do not scan or change the Encounter Journal during combat.
function Raids.GetLootEncounterByName(instanceID, encounterName)
    local instance = Raids.GetInstance(instanceID)
    if not instance or type(encounterName) ~= "string" then return nil end
    local function Normalize(name)
        return name:lower():gsub("’", "'"):gsub("[%p%s]+", "")
    end
    local wanted = Normalize(encounterName)
    if wanted == "" then return nil end
    local match
    for journalID, name in pairs(instance.encounterNames or {}) do
        if Normalize(name) == wanted then
            if match then return nil end
            match = journalID
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
