local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.DB = KeyLab.DB or {}
KeyLab.DB.Practice = KeyLab.DB.Practice or {}

local PracticeDB = KeyLab.DB.Practice
local activePracticeSession = nil

local STATUS_OPTIONS = {
    { value = nil, label = "Unmarked" },
    { value = "baseline", label = "Baseline" },
    { value = "favorite", label = "Favorite" },
    { value = "review", label = "Review" },
    { value = "ignore", label = "Ignore" },
}

--[[
KeyLab_PracticeDB.lua

Purpose:
- Stores training dummy / controlled practice sessions.
- Keeps practice data separate from Mythic+ encounter records.
- Does NOT capture Blizzard data.
- Does NOT build UI.
]]

local function GetDB()
    if KeyLab.DB and KeyLab.DB.Get then
        return KeyLab.DB.Get()
    end

    if type(KeyLabDB) ~= "table" then
        KeyLabDB = {}
    end

    return KeyLabDB
end

local function GetSessionsTable()
    local db = GetDB()
    if type(db.practiceSessions) ~= "table" then
        db.practiceSessions = {}
    end
    return db.practiceSessions
end

function PracticeDB.GetAll()
    return GetSessionsTable()
end

function PracticeDB.GetByID(sessionID)
    sessionID = tostring(sessionID or "")
    if sessionID == "" then return nil end

    local sessions = GetSessionsTable()
    for _, session in ipairs(sessions) do
        if tostring(session and session.id or "") == sessionID then
            return session
        end
    end

    return nil
end

function PracticeDB.AddSession(session)
    if type(session) ~= "table" then
        return false, "practice session was not a table"
    end

    local sessions = GetSessionsTable()
    session.timestamp = session.timestamp or time()
    session.id = session.id or ("practice-" .. tostring(session.timestamp) .. "-" .. tostring(#sessions + 1))
    table.insert(sessions, session)
    return true, session
end

function PracticeDB.UpdateSession(sessionID, updates)
    sessionID = tostring(sessionID or "")
    if sessionID == "" or type(updates) ~= "table" then return false end

    local sessions = GetSessionsTable()
    for _, session in ipairs(sessions) do
        if tostring(session and session.id or "") == sessionID then
            for key, value in pairs(updates) do
                session[key] = value
            end
            return true, session
        end
    end

    return false
end

function PracticeDB.DeleteSession(sessionID)
    sessionID = tostring(sessionID or "")
    if sessionID == "" then return false end

    local sessions = GetSessionsTable()
    for index, session in ipairs(sessions) do
        if tostring(session and session.id or "") == sessionID then
            table.remove(sessions, index)
            return true
        end
    end

    return false
end

function PracticeDB.GetStatusOptions()
    return STATUS_OPTIONS
end

function PracticeDB.GetStatusLabel(status)
    for _, option in ipairs(STATUS_OPTIONS) do
        if option.value == status then
            return option.label
        end
    end

    return "Unmarked"
end

function PracticeDB.SetStatus(sessionID, status)
    sessionID = tostring(sessionID or "")
    if sessionID == "" then return false end

    local sessions = GetSessionsTable()
    for _, session in ipairs(sessions) do
        if tostring(session and session.id or "") == sessionID then
            session.status = status
            return true
        end
    end

    return false
end

function PracticeDB.SetActive(active)
    activePracticeSession = active
    return active
end

function PracticeDB.GetActive()
    if type(activePracticeSession) == "table" then
        return activePracticeSession
    end
    return nil
end

function PracticeDB.ClearActive()
    activePracticeSession = nil
end

return PracticeDB
