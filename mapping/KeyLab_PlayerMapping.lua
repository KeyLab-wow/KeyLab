local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Mapping = KeyLab.Mapping or {}

--[[
KeyLab Player Mapping

Purpose:
- Defines the player identity fields KeyLab stores.
- Uses normal WoW Unit/Specialization APIs.
- Does NOT use C_DamageMeter source names.
]]

KeyLab.Mapping.PlayerOrder = {
    "playerName",
    "realm",
    "class",
    "spec",
}

KeyLab.Mapping.Player = {
    realm = {
        blizzardAPI = "GetRealmName()",
        keylabKey = "realm",
        label = "Realm",
        resultIndex = 1,
        displayType = "text",
        store = true,
    },

    class = {
        blizzardAPI = "UnitClass('player')",
        keylabKey = "class",
        label = "Class",
        resultIndex = 1, -- localized/display class name
        displayType = "text",
        store = true,
    },

    playerName = {
        blizzardAPI = "UnitName('player')",
        keylabKey = "playerName",
        label = "Player Name",
        resultIndex = 1,
        displayType = "text",
        store = true,
    },

    spec = {
        blizzardAPI = "GetSpecializationInfo(GetSpecialization())",
        keylabKey = "spec",
        label = "Spec",
        resultIndex = 2, -- spec display name
        displayType = "text",
        store = true,
    },
}