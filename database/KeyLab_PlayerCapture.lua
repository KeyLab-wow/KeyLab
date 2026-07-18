local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.Capture = KeyLab.Capture or {}
KeyLab.Capture.Player = KeyLab.Capture.Player or {}

local PlayerCapture = KeyLab.Capture.Player

--[[
KeyLab_PlayerCapture.lua

Purpose:
- Captures approved player identity fields only.
- Uses normal WoW Unit/Specialization APIs.
- Does NOT read C_DamageMeter source.name.
]]

function PlayerCapture.GetSnapshot()
    local player = {}

    local name = UnitName and UnitName("player") or nil
    local realm = GetRealmName and GetRealmName() or nil
    local className, classFile, classID
    if UnitClass then
        className, classFile, classID = UnitClass("player")
    end
    local specName = nil
    local specID = nil
    local blizzardRole = nil

    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            specID, specName, _, _, blizzardRole = GetSpecializationInfo(specIndex)
        end
    end

    player.playerName = name
    player.realm = realm
    player.class = className
    player.classFile = classFile
    player.classID = classID
    player.spec = specName
    player.specID = specID
    player.blizzardRole = blizzardRole
    player.role = KeyLab.Mapping
        and KeyLab.Mapping.ClassSpecs
        and KeyLab.Mapping.ClassSpecs.GetRole
        and KeyLab.Mapping.ClassSpecs.GetRole(specID, className, specName)
        or blizzardRole

    return player
end
