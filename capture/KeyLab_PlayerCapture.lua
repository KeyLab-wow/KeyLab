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
    local className = UnitClass and select(1, UnitClass("player")) or nil
    local specName = nil

    if GetSpecialization and GetSpecializationInfo then
        local specIndex = GetSpecialization()
        if specIndex then
            specName = select(2, GetSpecializationInfo(specIndex))
        end
    end

    player.playerName = name
    player.realm = realm
    player.class = className
    player.spec = specName

    return player
end
