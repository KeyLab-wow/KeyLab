local ADDON_NAME, KeyLab = ...

KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

-- Permanent class/spec sequence storage and configuration layer.
--
-- The protected click body below is intentionally identical to the Retail
-- 12.0.7 build 68453 golden prototype. This file adds storage, multiple
-- pre-created buttons, binding ownership, spellbook selection, and lifecycle
-- management around that proven body. It does not add timing, polling,
-- readiness/GCD detection, success detection, or any new advancement rule.

local Library = {}
KeyLab.SequencerLibrary = Library

local MAX_SEQUENCES = 50
local MAX_VERSIONS = 20
local MAX_BLOCKS = 50
local MAX_BLOCK_CHARS = 255
local MAX_LOOP_POSITIONS = (MAX_BLOCKS * (MAX_BLOCKS + 1)) / 2
local RECYCLE_SECONDS = 30 * 24 * 60 * 60
local MODIFIER_BUDGET_OVERHEAD = 16
local MODE_EVEN_CYCLE = "even_cycle"
local MODE_WEIGHTED_CYCLE = "weighted_cycle"
local MODE_SCHEMA_VERSION = 2

Library.MAX_SEQUENCES = MAX_SEQUENCES
Library.MAX_VERSIONS = MAX_VERSIONS
Library.MAX_BLOCKS = MAX_BLOCKS
Library.MAX_BLOCK_CHARS = MAX_BLOCK_CHARS
Library.RECYCLE_SECONDS = RECYCLE_SECONDS
Library.MODE_EVEN_CYCLE = MODE_EVEN_CYCLE
Library.MODE_WEIGHTED_CYCLE = MODE_WEIGHTED_CYCLE

local MODE_NAMES = {
    [MODE_EVEN_CYCLE] = "Even Cycle",
    [MODE_WEIGHTED_CYCLE] = "Weighted Cycle",
    mixed = "Mixed Groups",
}

local MODIFIER_NAMES = { CTRL = true, SHIFT = true, ALT = true }
local PRIMARY_COMMANDS = { cast = true, use = true, castsequence = true }
local SUPPORT_COMMANDS = {
    startattack = true,
    autoshot = true,
    stopattack = true,
    stopcasting = true,
    stopmacro = true,
    cancelaura = true,
    cancelform = true,
    dismount = true,
    petattack = true,
    petfollow = true,
    petpassive = true,
    petassist = true,
    focus = true,
    clearfocus = true,
    target = true,
    cleartarget = true,
    assist = true,
    equip = true,
    equipslot = true,
}

local TARGET_OPTIONS = {
    "", "@target", "@player", "@focus", "@mouseover", "@pet", "@cursor",
    "@none", "@targettarget", "@focustarget", "@pettarget",
}
for index = 1, 4 do table.insert(TARGET_OPTIONS, "@party" .. tostring(index)) end
for index = 1, 40 do table.insert(TARGET_OPTIONS, "@raid" .. tostring(index)) end
for index = 1, 5 do table.insert(TARGET_OPTIONS, "@arena" .. tostring(index)) end

local CONDITION_OPTIONS = {
    "exists", "noexists", "help", "harm", "dead", "nodead", "combat",
    "nocombat", "channeling", "channeling:Spell Name", "nochanneling", "mod:ctrl", "mod:shift",
    "mod:alt", "nomod", "form:1", "group", "group:party", "group:raid",
    "button:1", "button:2", "button:3", "button:4", "button:5", "flyable",
    "noflyable", "flying", "noflying", "indoors", "outdoors", "known:Spell Name",
    "noknown:Spell Name", "mounted", "nomounted", "pet", "pet:Pet Type", "nopet", "spec:1", "stealth",
    "nostealth", "swimming", "noswimming",
}

Library.TARGET_OPTIONS = TARGET_OPTIONS
Library.CONDITION_OPTIONS = CONDITION_OPTIONS
Library.MODE_NAMES = MODE_NAMES

local Trim
local TARGET_SET = {}
for _, value in ipairs(TARGET_OPTIONS) do TARGET_SET[value] = true end

local CONDITION_EXACT = {
    exists=true, noexists=true, help=true, harm=true, dead=true, nodead=true,
    combat=true, nocombat=true, channeling=true, nochanneling=true,
    nomod=true, group=true, ["group:party"]=true, ["group:raid"]=true,
    flyable=true, noflyable=true, flying=true, noflying=true, indoors=true,
    outdoors=true, mounted=true, nomounted=true, pet=true, nopet=true,
    stealth=true, nostealth=true, swimming=true, noswimming=true,
}

local function IsSafeCondition(value)
    value = Trim(value):lower()
    if CONDITION_EXACT[value] then return true end
    if value == "mod:ctrl" or value == "mod:shift" or value == "mod:alt" then return true end
    if value:match("^button:[1-5]$") then return true end
    if value:match("^form:%d+[/0-9]*$") then return true end
    if value:match("^spec:%d+[/0-9]*$") then return true end
    if value:match("^channeling:.+$") or value:match("^nochanneling:.+$") then return true end
    if value:match("^known:.+$") or value:match("^noknown:.+$") then return true end
    if value:match("^pet:.+$") then return true end
    return false
end

Trim = function(value)
    value = tostring(value or "")
    value = value:gsub("^%s+", "")
    value = value:gsub("%s+$", "")
    return value
end

local function Now()
    return time and time() or 0
end

local function InCombat()
    return InCombatLockdown and InCombatLockdown() == true
end

local function Print(message)
    Library.lastMessage = tostring(message or "")
    if KeyLab.Print then
        KeyLab.Print("Sequencer: " .. Library.lastMessage)
    else
        print("|cffd4af37KeyLab Sequencer:|r " .. Library.lastMessage)
    end
end

local function DeepCopy(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local result = {}
    seen[value] = result
    for key, item in pairs(value) do result[DeepCopy(key, seen)] = DeepCopy(item, seen) end
    return result
end

local function ArrayRemove(array, wanted)
    for index, value in ipairs(array or {}) do
        if value == wanted then table.remove(array, index); return true end
    end
    return false
end

local function NormalizeMode(value)
    value = Trim(value):lower():gsub("[%s_-]+", "")
    if value == "evencycle" or value == "even" or value == "sequential" or value == "seq" then
        return MODE_EVEN_CYCLE
    end
    if value == "weightedcycle" or value == "weighted" or value == "priority" or value == "prio" then
        return MODE_WEIGHTED_CYCLE
    end
    -- Reverse Priority is retired. Old saved values quietly move to the only
    -- remaining weighted mode instead of leaving a sequence invalid.
    if value == "reverse" or value == "reversepriority" or value == "rev" then
        return MODE_WEIGHTED_CYCLE
    end
    return nil
end

local function NormalizeBinding(value)
    value = Trim(value):upper():gsub("%s+", "")
    value = value:gsub("^CONTROL%-", "CTRL-")
    if value == "" then return "" end
    if value == "BUTTON1" or value == "BUTTON2" then
        return nil, "BUTTON1 and BUTTON2 are reserved. Use BUTTON3, BUTTON4, or BUTTON5."
    end
    if not value:match("^[A-Z0-9%-]+$") then
        return nil, "That binding contains unsupported characters."
    end
    return value
end

local function ModifierBinding(binding, modifierKey)
    if not modifierKey then return nil end
    if binding:find("CTRL-", 1, true) or binding:find("SHIFT-", 1, true) or binding:find("ALT-", 1, true) then
        return nil, "A Global Modifier Action requires an unmodified sequence binding."
    end
    return modifierKey .. "-" .. binding
end

local function NewID(prefix)
    local db = KeyLabDB and KeyLabDB.sequencerLibrary
    db.idCounter = (tonumber(db.idCounter) or 0) + 1
    return tostring(prefix or "id") .. "-" .. tostring(Now()) .. "-" .. tostring(db.idCounter)
end

local function CurrentOwner()
    local localizedClass, classFile
    if UnitClass then localizedClass, classFile = UnitClass("player") end
    classFile = classFile or "UNKNOWN"
    local specIndex = GetSpecialization and GetSpecialization() or nil
    local specID, specName
    if specIndex and GetSpecializationInfo then
        specID, specName = GetSpecializationInfo(specIndex)
    end
    specID = tonumber(specID) or 0
    specName = specName or "No Specialization"
    return classFile .. ":" .. tostring(specID), classFile, localizedClass or classFile, specID, specName
end

local function NormalizeStoredVersion(version)
    if type(version) ~= "table" then return end
    version.mode = NormalizeMode(version.mode) or MODE_EVEN_CYCLE
    for _, block in ipairs(version.blocks or {}) do
        if type(block) == "table" and block.mode ~= nil then
            block.mode = NormalizeMode(block.mode) or version.mode
        end
    end
end

local function NormalizeStoredSequence(sequence)
    if type(sequence) ~= "table" then return end
    for _, version in pairs(sequence.versions or {}) do
        NormalizeStoredVersion(version)
    end
end

local function MigrateStoredModes(db)
    if (tonumber(db.schemaVersion) or 1) >= MODE_SCHEMA_VERSION then return end
    for _, collection in pairs(db.collections or {}) do
        if type(collection) == "table" then
            for _, sequence in pairs(collection.sequences or {}) do
                NormalizeStoredSequence(sequence)
            end
            for _, entry in ipairs(collection.recycleBin or {}) do
                if type(entry) == "table" then
                    if entry.type == "sequence" then
                        NormalizeStoredSequence(entry.data)
                    elseif entry.type == "version" then
                        NormalizeStoredVersion(entry.data)
                    end
                end
            end
        end
    end
    db.schemaVersion = MODE_SCHEMA_VERSION
end

local function EnsureRoot()
    KeyLabDB = type(KeyLabDB) == "table" and KeyLabDB or {}
    KeyLabDB.sequencerLibrary = type(KeyLabDB.sequencerLibrary) == "table" and KeyLabDB.sequencerLibrary or {}
    local db = KeyLabDB.sequencerLibrary
    db.collections = type(db.collections) == "table" and db.collections or {}
    db.idCounter = tonumber(db.idCounter) or 0
    MigrateStoredModes(db)
    return db
end

local function EnsureCollection(create)
    local db = EnsureRoot()
    local ownerKey, classFile, className, specID, specName = CurrentOwner()
    local collection = db.collections[ownerKey]
    if type(collection) ~= "table" and create ~= false then
        collection = {
            ownerKey = ownerKey,
            classFile = classFile,
            className = className,
            specID = specID,
            specName = specName,
            sequences = {},
            order = {},
            recycleBin = {},
        }
        db.collections[ownerKey] = collection
    end
    if type(collection) == "table" then
        collection.sequences = type(collection.sequences) == "table" and collection.sequences or {}
        collection.order = type(collection.order) == "table" and collection.order or {}
        collection.recycleBin = type(collection.recycleBin) == "table" and collection.recycleBin or {}
        collection.classFile = classFile
        collection.className = className
        collection.specID = specID
        collection.specName = specName
    end
    return collection, ownerKey
end

local function NormalizeSlots(collection)
    local used = {}
    for _, sequenceID in ipairs(collection.order or {}) do
        local sequence = collection.sequences[sequenceID]
        local slot = sequence and tonumber(sequence.slot) or nil
        if not slot or slot < 1 or slot > MAX_SEQUENCES or used[slot] then
            if sequence then sequence.slot = nil end
        else
            sequence.slot = slot
            used[slot] = sequenceID
        end
    end
    for _, sequenceID in ipairs(collection.order or {}) do
        local sequence = collection.sequences[sequenceID]
        if sequence and not sequence.slot then
            for slot = 1, MAX_SEQUENCES do
                if not used[slot] then sequence.slot = slot; used[slot] = sequenceID; break end
            end
        end
    end
    return used
end

local function AllocateSlot(collection)
    local used = NormalizeSlots(collection)
    for slot = 1, MAX_SEQUENCES do if not used[slot] then return slot end end
    return nil
end

local function DefaultAction(text)
    return { text = Trim(text), spellID = nil, savedName = Trim(text), skillLine = nil }
end

local function DefaultClause(text)
    return { target = "", conditions = {}, action = DefaultAction(text) }
end

local function DefaultCommand(kind, text)
    kind = (PRIMARY_COMMANDS[kind] or SUPPORT_COMMANDS[kind]) and kind or "cast"
    return { kind = kind, reset = kind == "castsequence" and "target" or nil, clauses = { DefaultClause(text) } }
end

local function DefaultBlock()
    return { enabled = true, commands = { DefaultCommand("cast", "") } }
end

local function DefaultVersion(name)
    return {
        id = NewID("version"),
        name = Trim(name) ~= "" and Trim(name) or "Version Default",
        mode = MODE_EVEN_CYCLE,
        blocks = {},
        modifierKey = nil,
        modifierCommand = nil,
        createdAt = Now(),
        updatedAt = Now(),
    }
end

local function ValidateBracketGroups(value, modifierKeys)
    value = tostring(value or "")
    local withoutGroups = value:gsub("%b[]", function(group)
        local content = group:sub(2, -2)
        if Trim(content) == "" then return " " end
        for part in (content .. ","):gmatch("(.-),") do
            part = Trim(part)
            local lower = part:lower()
            if lower:sub(1, 1) == "@" then
                if not TARGET_SET[lower] then
                    modifierKeys.error = tostring(part) .. " is not a supported macro target."
                end
            elseif not IsSafeCondition(lower) then
                modifierKeys.error = tostring(part) .. " is not a supported macro condition."
            elseif lower == "mod:ctrl" or lower == "mod:shift" or lower == "mod:alt" then
                modifierKeys[lower:sub(5):upper()] = true
            end
        end
        return " "
    end)
    if modifierKeys.error then return nil, modifierKeys.error end
    if withoutGroups:find("[", 1, true) or withoutGroups:find("]", 1, true) then
        return nil, "A macro condition has an unmatched bracket."
    end
    return withoutGroups
end

local function IsKnownSpellAction(action)
    local spellName = Trim(action):gsub("^!", "")
    if spellName == "" then return false end

    if C_Spell and C_Spell.GetSpellInfo then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellName)
        if ok and info and Trim(info.name) ~= "" then return true end
    end
    if GetSpellInfo then
        local ok, name = pcall(GetSpellInfo, spellName)
        if ok and Trim(name) ~= "" then return true end
    end
    return false
end

local function MatchesSequenceName(action, draftSequenceName)
    local wanted = Trim(action):gsub("^!", ""):lower()
    if wanted == "" or wanted == "nil" or IsKnownSpellAction(action) then return false end
    if Trim(draftSequenceName):lower() == wanted then return true end

    local collection = EnsureCollection(false)
    for _, sequence in pairs(collection and collection.sequences or {}) do
        if Trim(sequence and sequence.name):lower() == wanted then return true end
    end
    return false
end

local function ValidateMacroText(text, draftSequenceName)
    if type(text) ~= "string" then return nil, "Enter a supported WoW macro." end
    if #text == 0 or Trim(text) == "" then return nil, "Enter a supported WoW macro." end
    if #text > MAX_BLOCK_CHARS then
        return nil, "This macro uses " .. tostring(#text) .. " of 255 characters."
    end

    local normalized = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    local primaryCount = 0
    local lineNumber = 0
    local modifierKeys = {}
    for line in (normalized .. "\n"):gmatch("(.-)\n") do
        lineNumber = lineNumber + 1
        if Trim(line) ~= "" then
            local command, argument = line:match("^%s*/([%a]+)%s*(.-)%s*$")
            command = command and command:lower() or nil
            if not command then
                return nil, "Line " .. tostring(lineNumber) .. " must begin with a supported slash command."
            end
            if command == "run" or command == "script" or command == "dump" or command == "click" then
                return nil, "/" .. command .. " is intentionally unsupported."
            end
            if not PRIMARY_COMMANDS[command] and not SUPPORT_COMMANDS[command] then
                return nil, "/" .. command .. " is not a supported macro command."
            end
            if PRIMARY_COMMANDS[command] then
                primaryCount = primaryCount + 1
            end

            local plain, conditionError = ValidateBracketGroups(argument, modifierKeys)
            if not plain then return nil, "Line " .. tostring(lineNumber) .. ": " .. tostring(conditionError) end
            plain = Trim(plain)
            if command == "cast" or command == "use" then
                if plain == "" then return nil, "Line " .. tostring(lineNumber) .. ": /" .. command .. " requires an action." end
                for clause in (plain .. ";"):gmatch("(.-);") do
                    if Trim(clause) == "" then
                        return nil, "Line " .. tostring(lineNumber) .. ": every /" .. command .. " clause requires an action."
                    end
                    if command == "cast" and MatchesSequenceName(clause, draftSequenceName) then
                        return nil, "Line " .. tostring(lineNumber) .. ": a KeyLab sequence cannot be cast by name. Add the spell directly."
                    end
                end
            elseif command == "castsequence" then
                if plain == "" then
                    return nil, "Line " .. tostring(lineNumber) .. ": /castsequence requires at least one action."
                end
                for clause in (plain .. ";"):gmatch("(.-);") do
                    clause = Trim(clause)
                    if clause == "" then
                        return nil, "Line " .. tostring(lineNumber) .. ": every /castsequence clause requires an action."
                    end
                    if clause:lower():match("^reset=") then
                        clause = clause:match("^reset=[^%s]+%s+(.+)$")
                        if not clause or Trim(clause) == "" then
                            return nil, "Line " .. tostring(lineNumber) .. ": /castsequence reset= requires at least one action."
                        end
                    end
                    for action in (clause .. ","):gmatch("(.-),") do
                        if Trim(action) == "" then
                            return nil, "Line " .. tostring(lineNumber) .. ": every /castsequence step requires an action."
                        end
                        if MatchesSequenceName(action, draftSequenceName) then
                            return nil, "Line " .. tostring(lineNumber) .. ": a KeyLab sequence cannot be used as a /castsequence action. Add the spell directly."
                        end
                    end
                end
            elseif (command == "equip" or command == "equipslot") and plain == "" then
                return nil, "Line " .. tostring(lineNumber) .. ": /" .. command .. " requires an item."
            end
        end
    end
    if primaryCount < 1 then
        return nil, "Each enabled macro must contain at least one /cast, /use, or /castsequence action."
    end
    local orderedModifiers = {}
    for _, key in ipairs({ "CTRL", "SHIFT", "ALT" }) do
        if modifierKeys[key] then table.insert(orderedModifiers, key) end
    end
    return true, nil, orderedModifiers
end

local function DefaultSequence(name)
    local version = DefaultVersion("Version Default")
    return {
        id = NewID("sequence"),
        name = Trim(name) ~= "" and Trim(name) or "New Sequence",
        slot = nil,
        binding = "",
        forceBinding = false,
        activeVersionId = version.id,
        versionOrder = { version.id },
        versions = { [version.id] = version },
        createdAt = Now(),
        updatedAt = Now(),
    }
end

local function UniqueName(existing, base)
    base = Trim(base) ~= "" and Trim(base) or "Restored"
    local used = {}
    for _, item in pairs(existing or {}) do used[Trim(item.name):lower()] = true end
    if not used[base:lower()] then return base end
    local number = 2
    while used[(base .. " " .. tostring(number)):lower()] do number = number + 1 end
    return base .. " " .. tostring(number)
end

local DUPLICATE_SEQUENCE_NAME_MESSAGE = "A sequence with this name already exists for this specialization."

local function SequenceNameExists(collection, name, excludeSequenceID)
    local wanted = Trim(name):lower()
    if wanted == "" then return false end
    for sequenceID, sequence in pairs(collection and collection.sequences or {}) do
        if sequenceID ~= excludeSequenceID and Trim(sequence and sequence.name):lower() == wanted then return true end
    end
    return false
end

local function RestoredSequenceName(collection, originalName)
    local base = Trim(originalName)
    if base == "" then base = "Restored Sequence" end
    return UniqueName(collection.sequences, base .. " Restored")
end

local function ResolveSpellName(action)
    action = type(action) == "table" and action or DefaultAction(action)
    local spellID = tonumber(action.spellID)
    if spellID and C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        if info and Trim(info.name) ~= "" then return Trim(info.name), true end
    elseif spellID and GetSpellInfo then
        local name = GetSpellInfo(spellID)
        if Trim(name) ~= "" then return Trim(name), true end
    end
    local fallback = Trim(action.savedName)
    if fallback == "" then fallback = Trim(action.text) end
    return fallback, spellID == nil
end

local function ClausePrefix(clause)
    clause = type(clause) == "table" and clause or {}
    local values = {}
    local target = Trim(clause.target)
    if not TARGET_SET[target] then return nil, "That temporary target is not available in the confirmed builder." end
    if target ~= "" then table.insert(values, target) end
    for _, condition in ipairs(clause.conditions or {}) do
        condition = Trim(condition)
        if condition ~= "" then
            if not IsSafeCondition(condition) then return nil, tostring(condition) .. " is not available in the confirmed builder." end
            table.insert(values, condition)
        end
    end
    return #values > 0 and ("[" .. table.concat(values, ",") .. "] ") or ""
end

local function GenerateCommand(command)
    command = type(command) == "table" and command or {}
    local kind = Trim(command.kind):lower()
    if not PRIMARY_COMMANDS[kind] and not SUPPORT_COMMANDS[kind] then
        return nil, "Choose a supported command."
    end
    local clauses = type(command.clauses) == "table" and command.clauses or {}
    if #clauses == 0 then return nil, "/" .. kind .. " requires at least one clause." end
    if kind == "castsequence" and #clauses > 1 then
        return nil, "Once Until Reset currently supports one clause."
    end
    local generated = {}
    for _, clause in ipairs(clauses) do
        local actionText = ""
        if type(clause.action) == "table" then
            actionText = ResolveSpellName(clause.action)
        else
            actionText = Trim(clause.action)
        end
        if PRIMARY_COMMANDS[kind] or kind == "equip" or kind == "equipslot" then
            if actionText == "" then return nil, "/" .. kind .. " requires an action." end
        end
        local body, prefixError = ClausePrefix(clause)
        if not body then return nil, prefixError end
        if kind == "castsequence" then
            local reset = Trim(command.reset)
            if reset ~= "target" then
                return nil, "Only the Retail-confirmed reset=target Action, nil form is available."
            end
            body = body .. "reset=target " .. actionText .. ", nil"
        else
            body = body .. actionText
        end
        local generatedClause = Trim(body)
        table.insert(generated, generatedClause)
    end
    local suffix = Trim(table.concat(generated, "; "))
    return "/" .. kind .. (suffix ~= "" and (" " .. suffix) or "")
end

local function GenerateBlock(block)
    block = type(block) == "table" and block or {}
    if block.enabled == false then return "", nil, true end
    if type(block.macroText) == "string" then
        local valid, message = ValidateMacroText(block.macroText)
        if not valid then return nil, message end
        return block.macroText
    end
    local lines = {}
    local primaryCount = 0
    local primarySeen = false
    for _, command in ipairs(block.commands or {}) do
        local kind = Trim(command.kind):lower()
        if PRIMARY_COMMANDS[kind] then
            primaryCount = primaryCount + 1
            primarySeen = true
        elseif SUPPORT_COMMANDS[kind] then
            if primarySeen then return nil, "Supporting commands must appear above the primary action." end
        end
        local line, message = GenerateCommand(command)
        if not line then return nil, message end
        table.insert(lines, line)
    end
    if primaryCount ~= 1 then
        return nil, "Each enabled macro must contain exactly one /cast, /use, or Once Until Reset primary action."
    end
    local text = table.concat(lines, "\n")
    if #text > MAX_BLOCK_CHARS then
        return nil, "The generated macro uses " .. tostring(#text) .. " of 255 characters."
    end
    return text
end

local function GenerateModifier(version)
    local key = version and Trim(version.modifierKey):upper() or ""
    if key == "" then return nil, nil end
    if not MODIFIER_NAMES[key] then return nil, "Choose Ctrl, Shift, Alt, or Off for the Global Modifier Action." end
    if type(version.modifierCommand) ~= "table" then return nil, "Choose a Global Modifier Action." end
    local kind = Trim(version.modifierCommand.kind):lower()
    if not PRIMARY_COMMANDS[kind] or kind == "castsequence" then
        return nil, "The Global Modifier Action must be one /cast or /use action."
    end
    local line, message = GenerateCommand(version.modifierCommand)
    if not line then return nil, message end
    return line, nil, key
end

local function BuildLoop(mode, blockCount)
    mode = NormalizeMode(mode)
    local loop = {}
    if mode == MODE_EVEN_CYCLE then
        -- Proven Sequential algorithm, renamed only.
        for index = 1, blockCount do table.insert(loop, index) end
    elseif mode == MODE_WEIGHTED_CYCLE then
        -- Proven Priority algorithm, renamed only.
        for depth = 1, blockCount do
            for index = 1, depth do table.insert(loop, index) end
        end
    end
    return loop
end

local function GetBlockMode(version, block)
    return NormalizeMode(type(block) == "table" and block.mode or nil)
        or NormalizeMode(type(version) == "table" and version.mode or nil)
        or MODE_EVEN_CYCLE
end

local function GetBlockGroups(version)
    local groups = {}
    local blocks = type(version) == "table" and version.blocks or {}
    local current
    for sourceIndex, block in ipairs(blocks or {}) do
        local mode = GetBlockMode(version, block)
        if not current or current.mode ~= mode then
            current = {
                mode = mode,
                startIndex = sourceIndex,
                endIndex = sourceIndex,
                blockCount = 0,
            }
            table.insert(groups, current)
        end
        current.endIndex = sourceIndex
        current.blockCount = current.blockCount + 1
    end
    return groups
end

local function GetVersionModeSummary(version)
    local groups = GetBlockGroups(version)
    if #groups == 0 then
        return NormalizeMode(type(version) == "table" and version.mode or nil) or MODE_EVEN_CYCLE
    end
    local firstMode = groups[1].mode
    for index = 2, #groups do
        if groups[index].mode ~= firstMode then return "mixed" end
    end
    return firstMode
end

local function SetBlockGroupMode(version, startIndex, endIndex, mode)
    if type(version) ~= "table" then return false, "Choose a version first." end
    mode = NormalizeMode(mode)
    if not mode then return false, "Choose Even Cycle or Weighted Cycle." end
    local blocks = version.blocks or {}
    startIndex = math.max(1, tonumber(startIndex) or 1)
    endIndex = math.min(#blocks, tonumber(endIndex) or startIndex)
    if startIndex > endIndex then return false, "That macro group is empty." end
    for index = startIndex, endIndex do
        if type(blocks[index]) == "table" then blocks[index].mode = mode end
    end
    if GetVersionModeSummary(version) ~= "mixed" then version.mode = mode end
    return true
end

local function SetAllBlockModes(version, mode)
    if type(version) ~= "table" then return false, "Choose a version first." end
    mode = NormalizeMode(mode)
    if not mode then return false, "Choose Even Cycle or Weighted Cycle." end
    version.mode = mode
    for _, block in ipairs(version.blocks or {}) do
        if type(block) == "table" then block.mode = mode end
    end
    return true
end

local function ValidateVersion(version)
    if type(version) ~= "table" then return nil, "The selected version is missing." end
    local mode = NormalizeMode(version.mode)
    if not mode then return nil, "Choose Even Cycle or Weighted Cycle." end
    local blocks = {}
    local sourceIndexes = {}
    local groups = {}
    local currentGroup
    local inlineModifierSet = {}
    if #(version.blocks or {}) > MAX_BLOCKS then return nil, "A version may contain at most 50 macros." end
    for sourceIndex, block in ipairs(version.blocks or {}) do
        local blockMode = GetBlockMode(version, block)
        if not currentGroup or currentGroup.mode ~= blockMode then
            currentGroup = {
                mode = blockMode,
                startIndex = sourceIndex,
                endIndex = sourceIndex,
                compactIndexes = {},
            }
            table.insert(groups, currentGroup)
        end
        currentGroup.endIndex = sourceIndex
        local text, message, disabled = GenerateBlock(block)
        if not text and not disabled then return nil, "Macro " .. tostring(sourceIndex) .. ": " .. tostring(message) end
        if not disabled then
            table.insert(blocks, text)
            table.insert(sourceIndexes, sourceIndex)
            table.insert(currentGroup.compactIndexes, #blocks)
            if type(block.macroText) == "string" then
                local _, _, modifiers = ValidateMacroText(block.macroText)
                for _, key in ipairs(modifiers or {}) do inlineModifierSet[key] = true end
            end
        end
    end
    if #blocks == 0 then return nil, "Enable and complete at least one macro." end
    local modifierText, modifierError, modifierKey = GenerateModifier(version)
    if modifierError then return nil, "Global Modifier Action: " .. modifierError end
    if modifierText then
        if inlineModifierSet[modifierKey] then
            return nil, "Global Modifier Action overlaps an inline [mod:" .. tostring(modifierKey):lower() .. "] condition."
        end
        for index, text in ipairs(blocks) do
            local effective = #text + #modifierText + MODIFIER_BUDGET_OVERHEAD
            if effective > MAX_BLOCK_CHARS then
                return nil, "Macro " .. tostring(sourceIndexes[index]) .. " uses " .. tostring(effective)
                    .. " of 255 effective characters with the Global Modifier Action."
            end
        end
    end
    local inlineModifierKeys = {}
    for _, key in ipairs({ "CTRL", "SHIFT", "ALT" }) do
        if inlineModifierSet[key] then table.insert(inlineModifierKeys, key) end
    end
    local loop = {}
    local enabledGroups = {}
    for _, group in ipairs(groups) do
        if #group.compactIndexes > 0 then
            local localLoop = BuildLoop(group.mode, #group.compactIndexes)
            for _, localIndex in ipairs(localLoop) do
                table.insert(loop, group.compactIndexes[localIndex])
            end
            table.insert(enabledGroups, {
                mode = group.mode,
                startIndex = group.startIndex,
                endIndex = group.endIndex,
                enabledBlockCount = #group.compactIndexes,
                loopLength = #localLoop,
            })
        end
    end
    return {
        mode = mode,
        modeSummary = GetVersionModeSummary(version),
        blocks = blocks,
        sourceIndexes = sourceIndexes,
        groups = enabledGroups,
        modifierText = modifierText,
        modifierKey = modifierKey,
        inlineModifierKeys = inlineModifierKeys,
        loop = loop,
    }
end

Library.GenerateCommand = GenerateCommand
Library.GenerateBlock = GenerateBlock
Library.ValidateMacroText = ValidateMacroText
Library.GetBlockText = function(block)
    if type(block) == "table" and type(block.macroText) == "string" then return block.macroText end
    return GenerateBlock(block)
end
Library.ValidateVersion = ValidateVersion
Library.BuildLoop = BuildLoop
Library.NormalizeMode = NormalizeMode
Library.GetBlockMode = GetBlockMode
Library.GetBlockGroups = GetBlockGroups
Library.GetVersionModeSummary = GetVersionModeSummary
Library.SetBlockGroupMode = SetBlockGroupMode
Library.SetAllBlockModes = SetAllBlockModes
Library.DeepCopy = DeepCopy
Library.DefaultBlock = DefaultBlock
Library.DefaultCommand = DefaultCommand
Library.DefaultClause = DefaultClause
Library.ResolveSpellName = ResolveSpellName
Library.IsSafeCondition = IsSafeCondition

local function AddBindingModifier(binding, modifierKey)
    local modifiers = { CTRL = false, SHIFT = false, ALT = false }
    local keyParts = {}
    for part in tostring(binding or ""):gmatch("[^%-]+") do
        if modifiers[part] ~= nil then modifiers[part] = true else table.insert(keyParts, part) end
    end
    modifiers[modifierKey] = true
    local parts = {}
    for _, key in ipairs({ "CTRL", "SHIFT", "ALT" }) do
        if modifiers[key] then table.insert(parts, key) end
    end
    for _, part in ipairs(keyParts) do table.insert(parts, part) end
    return table.concat(parts, "-")
end

local function BindingHasModifier(binding, modifierKey)
    for part in tostring(binding or ""):gmatch("[^%-]+") do
        if part == modifierKey then return true end
    end
    return false
end

local function BuildBindingPlan(binding, runtime)
    local plan = { { binding = binding, button = "LeftButton" } }
    local seen = { [binding] = true }
    if runtime.modifierKey then
        local companion, message = ModifierBinding(binding, runtime.modifierKey)
        if not companion then return nil, message end
        table.insert(plan, { binding = companion, button = "RightButton" })
        seen[companion] = true
    end
    for _, modifierKey in ipairs(runtime.inlineModifierKeys or {}) do
        if not BindingHasModifier(binding, modifierKey) then
            local companion = AddBindingModifier(binding, modifierKey)
            if not seen[companion] then
                table.insert(plan, { binding = companion, button = "LeftButton" })
                seen[companion] = true
            end
        end
    end
    return plan
end

local secureButtons = {}
local bindingOwners = {}
local sequenceSlots = {}

local function CreateSecureSlot(slot)
    local secureButton = CreateFrame("Button", "KeyLabSequencerButton" .. tostring(slot), nil, "SecureActionButtonTemplate,SecureHandlerBaseTemplate")
    secureButton:RegisterForClicks("AnyDown", "AnyUp")

    -- GOLDEN SECURE CLICK BODY. Keep byte-for-byte behavior aligned with the
    -- preserved Retail-tested prototype.
    SecureHandlerWrapScript(secureButton, "OnClick", secureButton, [=[
    local useDown = self:GetAttribute("useOnKeyDown")
    local shouldExecute = (down and useDown) or ((not down) and (not useDown))
    if down then
        self:SetAttribute("downEvents", (tonumber(self:GetAttribute("downEvents")) or 0) + 1)
    else
        self:SetAttribute("upEvents", (tonumber(self:GetAttribute("upEvents")) or 0) + 1)
    end
    if shouldExecute then
        if down then
            self:SetAttribute("executedDownEvents", (tonumber(self:GetAttribute("executedDownEvents")) or 0) + 1)
        else
            self:SetAttribute("executedUpEvents", (tonumber(self:GetAttribute("executedUpEvents")) or 0) + 1)
        end
        local cursor = tonumber(self:GetAttribute("cursor")) or 1
        local loopLength = tonumber(self:GetAttribute("loopLength")) or 1
        local blockIndex = tonumber(self:GetAttribute("loop" .. cursor)) or 1
        local modifierKey = self:GetAttribute("modifierKey")
        -- The companion modifier binding securely invokes RightButton while the
        -- ordinary sequence binding invokes LeftButton. This avoids relying on
        -- modifier-key state APIs inside the restricted snippet.
        local useModifier = modifierKey and button == "RightButton"

        local macrotext
        if useModifier then
            macrotext = self:GetAttribute("modifierMacro")
        else
            macrotext = self:GetAttribute("block" .. blockIndex)
        end

        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", macrotext)
        self:SetAttribute("lastBlock", blockIndex)
        self:SetAttribute("lastWasModifier", useModifier)
        self:SetAttribute("pressCount", (tonumber(self:GetAttribute("pressCount")) or 0) + 1)
        if useModifier then
            self:SetAttribute("modifierPresses", (tonumber(self:GetAttribute("modifierPresses")) or 0) + 1)
        end

        local combatState = SecureCmdOptionParse("[combat]1;0")
        if combatState == "1" then
            self:SetAttribute("combatPresses", (tonumber(self:GetAttribute("combatPresses")) or 0) + 1)
        end

        cursor = (cursor % loopLength) + 1
        self:SetAttribute("cursor", cursor)
    else
        -- Remove the prepared protected action before WoW handles the ignored
        -- edge. The opposite edge must neither execute nor advance.
        self:SetAttribute("type", nil)
        self:SetAttribute("macrotext", nil)
        self:SetAttribute("ignoredEdgeEvents", (tonumber(self:GetAttribute("ignoredEdgeEvents")) or 0) + 1)
    end
]=])

    secureButtons[slot] = secureButton
    bindingOwners[slot] = CreateFrame("Frame", "KeyLabSequencerBindingOwner" .. tostring(slot), nil)
end

for slot = 1, MAX_SEQUENCES do CreateSecureSlot(slot) end

local function ClearAllBindings()
    if not ClearOverrideBindings then return end
    for slot = 1, MAX_SEQUENCES do ClearOverrideBindings(bindingOwners[slot]) end
end

local function ClearSlot(slot)
    local button = secureButtons[slot]
    local oldBlocks = tonumber(button:GetAttribute("blockCount")) or 0
    local oldLoop = tonumber(button:GetAttribute("loopLength")) or 0
    for index = 1, oldBlocks do button:SetAttribute("block" .. index, nil) end
    for index = 1, oldLoop do button:SetAttribute("loop" .. index, nil) end
    button:SetAttribute("type", nil)
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("sequenceId", nil)
    button:SetAttribute("blockCount", 0)
    button:SetAttribute("loopLength", 0)
    button:SetAttribute("cursor", 1)
end

local function BindingConflict(binding, ownSlot)
    if not binding or binding == "" or not GetBindingAction then return nil end
    local action = GetBindingAction(binding)
    if action == nil or action == "" then return nil end
    if ownSlot and action:find("KeyLabSequencerButton" .. tostring(ownSlot), 1, true) then return nil end

    -- Addons can save permanent CLICK bindings in WoW's account binding set.
    -- Uninstalling the addon does not remove those records, so a character can
    -- inherit an action such as "CLICK BM +:LeftButton" even though no button
    -- exists to receive it. An absent click target is an abandoned binding, not
    -- a live action that needs replacement confirmation.
    local clickTarget = type(action) == "string" and action:match("^CLICK%s+(.+):[^:]+$") or nil
    if clickTarget and (_G == nil or _G[clickTarget] == nil) then return nil end

    return action
end

local function ConfigureSlot(slot, sequence, runtime)
    local button = secureButtons[slot]
    local oldBlocks = tonumber(button:GetAttribute("blockCount")) or 0
    local oldLoop = tonumber(button:GetAttribute("loopLength")) or 0
    button:SetAttribute("type", "macro")
    button:SetAttribute("macrotext", nil)
    button:SetAttribute("sequenceId", sequence.id)
    button:SetAttribute("useOnKeyDown", GetCVarBool and GetCVarBool("ActionButtonUseKeyDown") or false)
    button:SetAttribute("cursor", 1)
    button:SetAttribute("mode", runtime.mode)
    button:SetAttribute("activeVersion", sequence.activeVersionId)
    button:SetAttribute("blockCount", #runtime.blocks)
    button:SetAttribute("loopLength", #runtime.loop)
    button:SetAttribute("modifierKey", runtime.modifierKey)
    button:SetAttribute("modifierMacro", runtime.modifierText)
    button:SetAttribute("pressCount", 0)
    button:SetAttribute("combatPresses", 0)
    button:SetAttribute("modifierPresses", 0)
    button:SetAttribute("downEvents", 0)
    button:SetAttribute("upEvents", 0)
    button:SetAttribute("executedDownEvents", 0)
    button:SetAttribute("executedUpEvents", 0)
    button:SetAttribute("ignoredEdgeEvents", 0)
    button:SetAttribute("lastBlock", nil)
    button:SetAttribute("lastWasModifier", false)
    button:SetAttribute("resetCount", 0)
    button:SetAttribute("lastResetReason", "configuration applied")
    for index = 1, math.max(oldBlocks, #runtime.blocks) do button:SetAttribute("block" .. index, runtime.blocks[index]) end
    for index = 1, math.max(oldLoop, #runtime.loop) do button:SetAttribute("loop" .. index, runtime.loop[index]) end
end

local function PurgeExpired(collection)
    collection = collection or EnsureCollection(true)
    local cutoff = Now() - RECYCLE_SECONDS
    for index = #(collection.recycleBin or {}), 1, -1 do
        if (tonumber(collection.recycleBin[index].deletedAt) or 0) <= cutoff then table.remove(collection.recycleBin, index) end
    end
end

function Library.ApplyAll(reason)
    if InCombat() then
        Library.pendingApply = true
        Library.lastMessage = "Secure sequence changes are queued until combat ends."
        return false, Library.lastMessage
    end
    local collection = EnsureCollection(true)
    PurgeExpired(collection)
    local slotAssignments = NormalizeSlots(collection)
    ClearAllBindings()
    sequenceSlots = {}
    local errors = {}
    local usedBindings = {}

    for slot = 1, MAX_SEQUENCES do
        local sequenceID = slotAssignments[slot]
        local sequence = sequenceID and collection.sequences[sequenceID] or nil
        if not sequence then
            ClearSlot(slot)
        else
            sequenceSlots[sequenceID] = slot
            local version = sequence.versions and sequence.versions[sequence.activeVersionId]
            local runtime, validationError = ValidateVersion(version)
            local binding, bindingError = NormalizeBinding(sequence.binding)
            if not binding then validationError = bindingError end
            if runtime and binding ~= "" then
                local plan
                plan, bindingError = BuildBindingPlan(binding, runtime)
                if not plan then validationError = bindingError end
                for _, planned in ipairs(plan or {}) do
                    if usedBindings[planned.binding] then
                        validationError = planned.binding .. " overlaps another KeyLab sequence."
                        break
                    end
                    local conflict = BindingConflict(planned.binding, slot)
                    local protectedConflict = conflict and tostring(conflict):find("KeyLabSequencer", 1, true)
                    if protectedConflict or (not sequence.forceBinding and conflict) then
                        validationError = planned.binding .. " is already assigned to " .. tostring(conflict) .. "."
                        break
                    end
                end
                if not validationError then
                    ConfigureSlot(slot, sequence, runtime)
                    for _, planned in ipairs(plan) do
                        local ok, err = pcall(SetOverrideBindingClick, bindingOwners[slot], true, planned.binding, secureButtons[slot]:GetName(), planned.button)
                        if not ok then validationError = tostring(err); break end
                    end
                    if not validationError then
                        for _, planned in ipairs(plan) do usedBindings[planned.binding] = sequenceID end
                    end
                end
            elseif runtime then
                ConfigureSlot(slot, sequence, runtime)
            end
            if validationError then
                if ClearOverrideBindings then ClearOverrideBindings(bindingOwners[slot]) end
                ClearSlot(slot)
                sequenceSlots[sequenceID] = nil
                table.insert(errors, tostring(sequence.name or "Sequence") .. ": " .. tostring(validationError))
            end
        end
    end

    Library.pendingApply = false
    Library.lastAppliedReason = tostring(reason or "manual")
    if #errors > 0 then
        Library.lastMessage = table.concat(errors, " ")
        return false, Library.lastMessage
    end
    Library.lastMessage = "All valid sequences for " .. tostring(collection.className) .. " / " .. tostring(collection.specName) .. " are configured."
    return true, Library.lastMessage
end


function Library.ApplySequence(sequenceID, reason)
    if InCombat() then
        Library.pendingApply = true
        return false, "Secure sequence changes are queued until combat ends."
    end
    local collection = EnsureCollection(true)
    NormalizeSlots(collection)
    local sequence = collection.sequences[sequenceID]
    local slot = sequence and tonumber(sequence.slot) or nil
    if not sequence or not slot then return false, "The sequence was not found." end

    if ClearOverrideBindings then ClearOverrideBindings(bindingOwners[slot]) end
    local version = sequence.versions and sequence.versions[sequence.activeVersionId]
    local runtime, validationError = ValidateVersion(version)
    local binding, bindingError = NormalizeBinding(sequence.binding)
    if not binding then validationError = bindingError end
    local plan
    if runtime and binding ~= "" then
        plan, bindingError = BuildBindingPlan(binding, runtime)
        if not plan then validationError = bindingError end
        for _, planned in ipairs(plan or {}) do
            local conflict = BindingConflict(planned.binding, slot)
            local protectedConflict = conflict and tostring(conflict):find("KeyLabSequencer", 1, true)
            if protectedConflict or (not sequence.forceBinding and conflict) then
                validationError = planned.binding .. " is already assigned to " .. tostring(conflict) .. "."
                break
            end
        end
    end
    if not validationError then
        ConfigureSlot(slot, sequence, runtime)
        sequenceSlots[sequenceID] = slot
        if binding ~= "" then
            for _, planned in ipairs(plan or {}) do
                local ok, err = pcall(SetOverrideBindingClick, bindingOwners[slot], true, planned.binding, secureButtons[slot]:GetName(), planned.button)
                if not ok then validationError = tostring(err); break end
            end
        end
    end
    if validationError then
        if ClearOverrideBindings then ClearOverrideBindings(bindingOwners[slot]) end
        ClearSlot(slot)
        sequenceSlots[sequenceID] = nil
        Library.lastMessage = tostring(sequence.name or "Sequence") .. ": " .. tostring(validationError)
        return false, Library.lastMessage
    end
    Library.lastMessage = tostring(sequence.name) .. " was configured without resetting other sequences."
    Library.lastAppliedReason = tostring(reason or "sequence apply")
    return true, Library.lastMessage
end

function Library.GetCollectionSnapshot()
    local collection, ownerKey = EnsureCollection(true)
    PurgeExpired(collection)
    NormalizeSlots(collection)
    return DeepCopy(collection), ownerKey
end

function Library.GetSequence(sequenceID)
    local collection = EnsureCollection(true)
    return collection.sequences[sequenceID]
end

function Library.GetSequenceCopy(sequenceID)
    return DeepCopy(Library.GetSequence(sequenceID))
end

function Library.CreateSequence(name)
    if InCombat() then return nil, "Sequences cannot be created during combat." end
    local collection = EnsureCollection(true)
    if #collection.order >= MAX_SEQUENCES then return nil, "This class/spec already has 50 sequences." end
    local explicitName = name ~= nil and Trim(name) or nil
    if explicitName == "" then return nil, "Enter a sequence name." end
    if explicitName and SequenceNameExists(collection, explicitName) then return nil, DUPLICATE_SEQUENCE_NAME_MESSAGE end
    local sequence = DefaultSequence(explicitName or UniqueName(collection.sequences, "New Sequence"))
    sequence.slot = AllocateSlot(collection)
    collection.sequences[sequence.id] = sequence
    table.insert(collection.order, sequence.id)
    return sequence.id, "New Sequence and Version Default were created together."
end

function Library.DuplicateSequence(sequenceID)
    if InCombat() then return nil, "Sequences cannot be duplicated during combat." end
    local collection = EnsureCollection(true)
    if #collection.order >= MAX_SEQUENCES then return nil, "This class/spec already has 50 sequences." end
    local source = collection.sequences[sequenceID]
    if not source then return nil, "The sequence was not found." end
    local copy = DeepCopy(source)
    copy.id = NewID("sequence")
    copy.slot = AllocateSlot(collection)
    copy.name = UniqueName(collection.sequences, tostring(source.name) .. " Copy")
    copy.binding = ""
    copy.forceBinding = false
    copy.createdAt = Now()
    copy.updatedAt = Now()
    local versions = {}
    local order = {}
    for _, oldID in ipairs(copy.versionOrder or {}) do
        local version = copy.versions[oldID]
        if version then
            local newID = NewID("version")
            version.id = newID
            versions[newID] = version
            table.insert(order, newID)
            if oldID == copy.activeVersionId then copy.activeVersionId = newID end
        end
    end
    copy.versions = versions
    copy.versionOrder = order
    collection.sequences[copy.id] = copy
    table.insert(collection.order, copy.id)
    Library.ApplySequence(copy.id, "sequence duplicated")
    return copy.id, "Sequence duplicated without a binding."
end

function Library.SaveSequence(sequenceDraft)
    if InCombat() then return false, "Sequences cannot be saved during combat." end
    if type(sequenceDraft) ~= "table" or Trim(sequenceDraft.id) == "" then return false, "The sequence draft is invalid." end
    local collection = EnsureCollection(true)
    local existingSequence = collection.sequences[sequenceDraft.id]
    if not existingSequence then return false, "The sequence no longer exists." end
    sequenceDraft.slot = existingSequence.slot
    sequenceDraft.name = Trim(sequenceDraft.name)
    if sequenceDraft.name == "" then return false, "Enter a sequence name." end
    if SequenceNameExists(collection, sequenceDraft.name, sequenceDraft.id) then return false, DUPLICATE_SEQUENCE_NAME_MESSAGE end
    local binding, bindingError = NormalizeBinding(sequenceDraft.binding)
    if not binding then return false, bindingError end
    sequenceDraft.binding = binding
    if #(sequenceDraft.versionOrder or {}) < 1 then return false, "A sequence must contain at least one version." end
    if #(sequenceDraft.versionOrder or {}) > MAX_VERSIONS then return false, "A sequence may contain at most 20 versions." end
    for _, versionID in ipairs(sequenceDraft.versionOrder or {}) do
        local version = sequenceDraft.versions and sequenceDraft.versions[versionID]
        if not version then return false, "A saved version is missing." end
        version.name = Trim(version.name)
        if version.name == "" then return false, "Every version needs a name." end
        for blockIndex, block in ipairs(version.blocks or {}) do
            if block and block.enabled ~= false and type(block.macroText) == "string" then
                local valid, validationMessage = ValidateMacroText(block.macroText, sequenceDraft.name)
                if not valid then
                    return false, tostring(version.name) .. ": Macro " .. tostring(blockIndex) .. ": " .. tostring(validationMessage)
                end
            end
        end
        local _, message = ValidateVersion(version)
        if message then return false, tostring(version.name) .. ": " .. tostring(message) end
        version.updatedAt = Now()
    end
    if not sequenceDraft.versions[sequenceDraft.activeVersionId] then
        return false, "Choose an active version."
    end
    sequenceDraft.updatedAt = Now()
    local previousSequence = DeepCopy(existingSequence)
    collection.sequences[sequenceDraft.id] = DeepCopy(sequenceDraft)
    local applied, message = Library.ApplySequence(sequenceDraft.id, "saved sequence")
    if not applied then
        collection.sequences[sequenceDraft.id] = previousSequence
        Library.ApplySequence(sequenceDraft.id, "restored after failed save")
    end
    return applied, applied and "Sequence saved and secure bindings refreshed." or message
end

function Library.CheckBinding(binding, sequenceID)
    local normalized, message = NormalizeBinding(binding)
    if not normalized then return false, message end
    if normalized == "" then return true end
    local collection = EnsureCollection(true)
    for otherID, sequence in pairs(collection.sequences) do
        if otherID ~= sequenceID then
            local otherBinding = NormalizeBinding(sequence.binding)
            local active = sequence.versions and sequence.versions[sequence.activeVersionId]
            local runtime = active and ValidateVersion(active) or nil
            local plan = runtime and otherBinding and otherBinding ~= "" and BuildBindingPlan(otherBinding, runtime) or nil
            for _, planned in ipairs(plan or {}) do
                if planned.binding == normalized then
                    return false, normalized .. " is already assigned to KeyLab sequence " .. tostring(sequence.name) .. ".", "keylab"
                end
            end
        end
    end
    local conflict = BindingConflict(normalized, sequenceID and sequenceSlots[sequenceID] or nil)
    if conflict then return false, normalized .. " is currently assigned to " .. tostring(conflict) .. ".", "wow" end
    return true
end

function Library.CheckSequenceBinding(sequenceDraft)
    if type(sequenceDraft) ~= "table" then return false, "No sequence is selected." end
    local binding, message = NormalizeBinding(sequenceDraft.binding)
    if not binding then return false, message end
    if binding == "" then return true end
    local version = sequenceDraft.versions and sequenceDraft.versions[sequenceDraft.activeVersionId]
    local runtime, validationError = ValidateVersion(version)
    if not runtime then return false, validationError end
    local plan
    plan, validationError = BuildBindingPlan(binding, runtime)
    if not plan then return false, validationError end

    local collection = EnsureCollection(true)
    for _, planned in ipairs(plan) do
        for otherID, other in pairs(collection.sequences) do
            if otherID ~= sequenceDraft.id then
                local otherBinding = NormalizeBinding(other.binding)
                local otherVersion = other.versions and other.versions[other.activeVersionId]
                local otherRuntime = otherVersion and ValidateVersion(otherVersion) or nil
                local otherPlan = otherRuntime and otherBinding and otherBinding ~= "" and BuildBindingPlan(otherBinding, otherRuntime) or nil
                for _, otherPlanned in ipairs(otherPlan or {}) do
                    if planned.binding == otherPlanned.binding then
                        return false, planned.binding .. " is already assigned to KeyLab sequence " .. tostring(other.name) .. ".", "keylab"
                    end
                end
            end
        end
        local conflict = BindingConflict(planned.binding, tonumber(sequenceDraft.slot))
        if conflict then
            return false, planned.binding .. " is currently assigned to " .. tostring(conflict) .. ".", "wow"
        end
    end
    return true
end

function Library.GetBindingStatus(sequenceID)
    local collection = EnsureCollection(true)
    local sequence = collection.sequences[sequenceID]
    if not sequence then return false, "Sequence missing" end
    local binding, message = NormalizeBinding(sequence.binding)
    if not binding then return false, message end
    if binding == "" then return true, "Unbound" end
    local version = sequence.versions and sequence.versions[sequence.activeVersionId]
    local runtime, validationError = ValidateVersion(version)
    if not runtime then return false, validationError end
    local plan
    plan, validationError = BuildBindingPlan(binding, runtime)
    if not plan then return false, validationError end

    for _, planned in ipairs(plan) do
        for otherID, other in pairs(collection.sequences) do
            if otherID ~= sequenceID then
                local otherBinding = NormalizeBinding(other.binding)
                local otherVersion = other.versions and other.versions[other.activeVersionId]
                local otherRuntime = otherVersion and ValidateVersion(otherVersion) or nil
                local otherPlan = otherRuntime and otherBinding and otherBinding ~= "" and BuildBindingPlan(otherBinding, otherRuntime) or nil
                for _, otherPlanned in ipairs(otherPlan or {}) do
                    if planned.binding == otherPlanned.binding then
                        return false, "Conflicts with " .. tostring(other.name)
                    end
                end
            end
        end
        local conflict = BindingConflict(planned.binding, tonumber(sequence.slot))
        if conflict and not sequence.forceBinding then
            return false, "Conflicts with " .. tostring(conflict)
        end
    end
    return true, #plan > 1 and ("Active + " .. tostring(#plan - 1) .. " modifier binding" .. (#plan > 2 and "s" or "")) or "Active"
end

function Library.NewVersion(sequenceDraft, name, duplicateVersionID)
    if type(sequenceDraft) ~= "table" then return nil, "No sequence is selected." end
    if #(sequenceDraft.versionOrder or {}) >= MAX_VERSIONS then return nil, "This sequence already has 20 versions." end
    local version
    if duplicateVersionID and sequenceDraft.versions[duplicateVersionID] then
        version = DeepCopy(sequenceDraft.versions[duplicateVersionID])
        version.id = NewID("version")
        version.name = UniqueName(sequenceDraft.versions, name or (tostring(version.name) .. " Copy"))
    else
        version = DefaultVersion(UniqueName(sequenceDraft.versions, name or "Version Default"))
    end
    version.createdAt = Now()
    version.updatedAt = Now()
    sequenceDraft.versions[version.id] = version
    table.insert(sequenceDraft.versionOrder, version.id)
    return version.id, "Version added to the draft. Save Changes to commit it."
end

function Library.DeleteSequence(sequenceID)
    if InCombat() then return false, "Sequences cannot be deleted during combat." end
    local collection = EnsureCollection(true)
    local sequence = collection.sequences[sequenceID]
    if not sequence then return false, "The sequence was not found." end
    table.insert(collection.recycleBin, 1, {
        id = NewID("deleted"), type = "sequence", name = sequence.name,
        deletedAt = Now(), data = DeepCopy(sequence),
    })
    local slot = tonumber(sequence.slot)
    if slot and ClearOverrideBindings then ClearOverrideBindings(bindingOwners[slot]) end
    if slot then ClearSlot(slot) end
    sequenceSlots[sequenceID] = nil
    collection.sequences[sequenceID] = nil
    ArrayRemove(collection.order, sequenceID)
    return true, "Sequence moved to the Recycle Bin for 30 days."
end

function Library.DeleteVersion(sequenceID, versionID)
    if InCombat() then return false, "Versions cannot be deleted during combat." end
    local collection = EnsureCollection(true)
    local sequence = collection.sequences[sequenceID]
    local version = sequence and sequence.versions and sequence.versions[versionID]
    if not version then return false, "The version was not found." end
    if #(sequence.versionOrder or {}) <= 1 then return Library.DeleteSequence(sequenceID) end
    table.insert(collection.recycleBin, 1, {
        id = NewID("deleted"), type = "version", name = version.name,
        sequenceId = sequenceID, sequenceName = sequence.name,
        deletedAt = Now(), data = DeepCopy(version),
    })
    sequence.versions[versionID] = nil
    ArrayRemove(sequence.versionOrder, versionID)
    if sequence.activeVersionId == versionID then sequence.activeVersionId = sequence.versionOrder[1] end
    sequence.updatedAt = Now()
    Library.ApplySequence(sequenceID, "version deleted")
    return true, "Version moved to the Recycle Bin for 30 days."
end

function Library.RestoreDeleted(deletedID, requestedName)
    if InCombat() then return nil, "Recycle Bin items cannot be restored during combat." end
    local collection = EnsureCollection(true)
    PurgeExpired(collection)
    local entry, entryIndex
    for index, candidate in ipairs(collection.recycleBin) do
        if candidate.id == deletedID then entry, entryIndex = candidate, index; break end
    end
    if not entry then return nil, "That Recycle Bin item is no longer available." end
    if entry.type == "sequence" then
        if #collection.order >= MAX_SEQUENCES then return nil, "This class/spec already has 50 sequences." end
        local sequence = DeepCopy(entry.data)
        local restoredName
        if requestedName ~= nil then
            restoredName = Trim(requestedName)
            if restoredName == "" then return nil, "Enter a sequence name.", "invalid_name", RestoredSequenceName(collection, sequence.name) end
        else
            restoredName = Trim(sequence.name)
        end
        if SequenceNameExists(collection, restoredName) then
            return nil, DUPLICATE_SEQUENCE_NAME_MESSAGE, "name_conflict", RestoredSequenceName(collection, sequence.name)
        end
        if collection.sequences[sequence.id] then sequence.id = NewID("sequence") end
        sequence.slot = AllocateSlot(collection)
        sequence.name = restoredName
        local bindingOkay = Library.CheckBinding(sequence.binding, sequence.id)
        local restoredUnbound = not bindingOkay
        if restoredUnbound then sequence.binding = ""; sequence.forceBinding = false end
        collection.sequences[sequence.id] = sequence
        table.insert(collection.order, sequence.id)
        table.remove(collection.recycleBin, entryIndex)
        Library.ApplySequence(sequence.id, "sequence restored")
        return sequence.id, restoredUnbound and "Sequence restored unbound because its old binding is now in use." or "Sequence restored."
    end
    local sequence = collection.sequences[entry.sequenceId]
    if not sequence then
        if #collection.order >= MAX_SEQUENCES then return nil, "This class/spec already has 50 sequences." end
        local containerName = Trim(entry.sequenceName)
        if containerName == "" then containerName = "Restored Sequence" end
        if SequenceNameExists(collection, containerName) then containerName = RestoredSequenceName(collection, containerName) end
        sequence = DefaultSequence(containerName)
        sequence.slot = AllocateSlot(collection)
        sequence.versions = {}
        sequence.versionOrder = {}
        sequence.activeVersionId = nil
        collection.sequences[sequence.id] = sequence
        table.insert(collection.order, sequence.id)
    end
    if #(sequence.versionOrder or {}) >= MAX_VERSIONS then return nil, "The destination sequence already has 20 versions." end
    local version = DeepCopy(entry.data)
    if sequence.versions[version.id] then version.id = NewID("version") end
    version.name = UniqueName(sequence.versions, version.name)
    sequence.versions[version.id] = version
    table.insert(sequence.versionOrder, version.id)
    if not sequence.activeVersionId then sequence.activeVersionId = version.id end
    table.remove(collection.recycleBin, entryIndex)
    Library.ApplySequence(sequence.id, "version restored")
    return sequence.id, "Version restored."
end

function Library.PermanentlyDelete(deletedID)
    if InCombat() then return false, "Recycle Bin items cannot be removed during combat." end
    local collection = EnsureCollection(true)
    for index, entry in ipairs(collection.recycleBin) do
        if entry.id == deletedID then table.remove(collection.recycleBin, index); return true, "Item permanently deleted." end
    end
    return false, "That Recycle Bin item is no longer available."
end

function Library.GetRecycleBin()
    local collection = EnsureCollection(true)
    PurgeExpired(collection)
    local result = DeepCopy(collection.recycleBin)
    local now = Now()
    for _, entry in ipairs(result) do
        entry.daysRemaining = math.max(0, math.ceil((RECYCLE_SECONDS - (now - (tonumber(entry.deletedAt) or 0))) / 86400))
    end
    return result
end

function Library.ActivateVersion(sequenceID, versionID)
    if InCombat() then return false, "Versions cannot be activated during combat." end
    local sequence = Library.GetSequence(sequenceID)
    if not sequence or not sequence.versions or not sequence.versions[versionID] then return false, "The version was not found." end
    local previousVersionID = sequence.activeVersionId
    sequence.activeVersionId = versionID
    sequence.updatedAt = Now()
    local applied, message = Library.ApplySequence(sequenceID, "version activation")
    if not applied then
        sequence.activeVersionId = previousVersionID
        Library.ApplySequence(sequenceID, "restored after failed version activation")
    end
    return applied, applied and "Version activated and reset to its first loop position." or message
end

function Library.ResetSequence(sequenceID, reason)
    if InCombat() then return false, "Reset Sequence is available outside combat." end
    local slot = sequenceSlots[sequenceID]
    local button = slot and secureButtons[slot]
    if not button then return false, "Save and apply this sequence before resetting it." end
    button:SetAttribute("cursor", 1)
    button:SetAttribute("lastResetReason", tostring(reason or "manual Reset Sequence"))
    button:SetAttribute("resetCount", (tonumber(button:GetAttribute("resetCount")) or 0) + 1)
    return true, "Sequence returned to its first loop position."
end

function Library.ResetAllRuntime(reason)
    if InCombat() then return false end
    for _, button in ipairs(secureButtons) do
        if button:GetAttribute("sequenceId") then
            button:SetAttribute("cursor", 1)
            button:SetAttribute("lastResetReason", tostring(reason or "reset"))
            button:SetAttribute("resetCount", (tonumber(button:GetAttribute("resetCount")) or 0) + 1)
        end
    end
    return true
end

function Library.GetRuntime(sequenceID)
    local slot = sequenceSlots[sequenceID]
    local button = slot and secureButtons[slot]
    if not button then return nil end
    local cursor = tonumber(button:GetAttribute("cursor")) or 1
    local sequence = Library.GetSequence(sequenceID)
    local version = sequence and sequence.versions and sequence.versions[sequence.activeVersionId]
    local configured = version and ValidateVersion(version) or nil
    local lastCompact = tonumber(button:GetAttribute("lastBlock"))
    local nextCompact = tonumber(button:GetAttribute("loop" .. cursor))
    return {
        pressCount = tonumber(button:GetAttribute("pressCount")) or 0,
        combatPresses = tonumber(button:GetAttribute("combatPresses")) or 0,
        modifierPresses = tonumber(button:GetAttribute("modifierPresses")) or 0,
        lastBlock = configured and lastCompact and configured.sourceIndexes[lastCompact] or lastCompact,
        nextBlock = configured and nextCompact and configured.sourceIndexes[nextCompact] or nextCompact,
        lastResetReason = button:GetAttribute("lastResetReason"),
        useOnKeyDown = button:GetAttribute("useOnKeyDown") == true,
    }
end

-- Read-only practice metadata. These helpers observe the counters already
-- maintained by the golden secure click body; they do not change execution,
-- bindings, cursor position, reset behavior, or advancement.
function Library.GetUsageSnapshot()
    local collection = EnsureCollection(true)
    local snapshot = {}
    for _, sequenceID in ipairs(collection.order or {}) do
        local sequence = collection.sequences and collection.sequences[sequenceID]
        local slot = sequenceSlots[sequenceID]
        local button = slot and secureButtons[slot]
        if sequence and button then
            local versionID = button:GetAttribute("activeVersion") or sequence.activeVersionId
            local version = sequence.versions and sequence.versions[versionID]
            snapshot[sequenceID] = {
                sequenceID = sequenceID,
                versionID = versionID,
                sequenceName = tostring(sequence.name or "Sequence"),
                versionName = tostring(version and version.name or "Version"),
                className = collection.className,
                specName = collection.specName,
                pressCount = tonumber(button:GetAttribute("pressCount")) or 0,
                combatPresses = tonumber(button:GetAttribute("combatPresses")) or 0,
            }
        end
    end
    return snapshot
end

function Library.GetUsagesSince(baseline)
    baseline = type(baseline) == "table" and baseline or {}
    local current = Library.GetUsageSnapshot()
    local used = {}
    for sequenceID, usage in pairs(current) do
        local before = type(baseline[sequenceID]) == "table" and baseline[sequenceID] or {}
        local presses = math.max(0, (tonumber(usage.pressCount) or 0) - (tonumber(before.pressCount) or 0))
        local combatPresses = math.max(0, (tonumber(usage.combatPresses) or 0) - (tonumber(before.combatPresses) or 0))
        if presses > 0 then
            local candidate = DeepCopy(usage)
            candidate.pressCount = presses
            candidate.combatPresses = combatPresses
            candidate.autoDetected = true
            candidate.versionChangedDuringSession = before.versionID ~= nil and before.versionID ~= usage.versionID or nil
            table.insert(used, candidate)
        end
    end
    table.sort(used, function(a, b)
        local aCombat = tonumber(a.combatPresses) or 0
        local bCombat = tonumber(b.combatPresses) or 0
        if aCombat ~= bCombat then return aCombat > bCombat end
        local aPresses = tonumber(a.pressCount) or 0
        local bPresses = tonumber(b.pressCount) or 0
        if aPresses ~= bPresses then return aPresses > bPresses end
        local aName = tostring(a.sequenceName or "")
        local bName = tostring(b.sequenceName or "")
        if aName ~= bName then return aName < bName end
        return tostring(a.versionName or "") < tostring(b.versionName or "")
    end)
    return used
end

function Library.GetMostUsedSince(baseline)
    local used = Library.GetUsagesSince(baseline)
    local best = used[1]
    if best then best.additionalSequencesUsed = math.max(0, #used - 1) end
    return best
end

function Library.GetLoopPreview(version)
    local runtime, message = ValidateVersion(version)
    if not runtime then return nil, message end
    local values = {}
    for _, value in ipairs(runtime.loop) do table.insert(values, tostring(runtime.sourceIndexes[value] or value)) end
    return table.concat(values, " > "), #runtime.loop, #runtime.blocks
end

local spellCache = { ownerKey = nil, spells = {}, byID = {} }

function Library.RefreshSpellbook()
    local ownerKey = CurrentOwner()
    local spells, byID = {}, {}
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or "player"
    if C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo then
        local skillLineCount = C_SpellBook.GetNumSpellBookSkillLines() or 0
        for lineIndex = 1, skillLineCount do
            local line = C_SpellBook.GetSpellBookSkillLineInfo(lineIndex)
            local offSpec = line and tonumber(line.offSpecID) or 0
            if line and offSpec == 0 then
                local first = (tonumber(line.itemIndexOffset) or 0) + 1
                local count = tonumber(line.numSpellBookItems) or 0
                for itemIndex = first, first + count - 1 do
                    local item = C_SpellBook.GetSpellBookItemInfo(itemIndex, bank)
                    local spellID = item and tonumber(item.spellID or item.actionID)
                    local isFuture = Enum and Enum.SpellBookItemType and item and item.itemType == Enum.SpellBookItemType.FutureSpell
                    local isSpell = not (Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell)
                        or (item and item.itemType == Enum.SpellBookItemType.Spell)
                    local passive = spellID and C_Spell and C_Spell.IsSpellPassive and C_Spell.IsSpellPassive(spellID)
                    if spellID and isSpell and not isFuture and not passive and not byID[spellID] then
                        local name, available = ResolveSpellName({ spellID = spellID })
                        if available and name ~= "" then
                            local entry = { spellID = spellID, name = name, skillLine = line.name or "Spellbook", iconID = item.iconID }
                            byID[spellID] = entry
                            table.insert(spells, entry)
                        end
                    end
                end
            end
        end
    end
    table.sort(spells, function(a, b)
        if a.name == b.name then return a.spellID < b.spellID end
        return a.name < b.name
    end)
    local counts = {}
    for _, entry in ipairs(spells) do counts[entry.name] = (counts[entry.name] or 0) + 1 end
    for _, entry in ipairs(spells) do
        entry.label = counts[entry.name] > 1 and (entry.name .. " - " .. tostring(entry.skillLine) .. " (" .. tostring(entry.spellID) .. ")") or entry.name
    end
    spellCache = { ownerKey = ownerKey, spells = spells, byID = byID }
    return spells
end

function Library.GetSpellbook()
    local ownerKey = CurrentOwner()
    if spellCache.ownerKey ~= ownerKey then Library.RefreshSpellbook() end
    return spellCache.spells, spellCache.byID
end

local function ParsePrototypeBlock(text)
    text = Trim(text)
    if text == "" then return nil end
    local block = { enabled = true, commands = {} }
    for line in (text:gsub("\r\n", "\n") .. "\n"):gmatch("(.-)\n") do
        line = Trim(line)
        if line ~= "" then
            local command, rest = line:match("^/(%S+)%s*(.-)$")
            command = Trim(command):lower()
            rest = Trim(rest)
            local parsed
            if command == "castsequence" then
                local action = rest:match("^reset=target%s+(.+),%s*nil$")
                if action then parsed = DefaultCommand("castsequence", action) end
            elseif PRIMARY_COMMANDS[command] or SUPPORT_COMMANDS[command] then
                parsed = DefaultCommand(command, rest)
            end
            if parsed then table.insert(block.commands, parsed) end
        end
    end
    return #block.commands > 0 and block or nil
end

local function MigratePrototype()
    local root = EnsureRoot()
    if root.prototypeMigrationComplete then return end
    root.prototypeMigrationComplete = true
    local old = KeyLabDB and KeyLabDB.sequencerPrototype
    if type(old) ~= "table" or type(old.versions) ~= "table" then return end
    local collection = EnsureCollection(true)
    if #collection.order >= MAX_SEQUENCES then return end
    local sequence = DefaultSequence("Retail-Proven Prototype")
    sequence.slot = AllocateSlot(collection)
    sequence.binding = NormalizeBinding(old.binding) or ""
    sequence.forceBinding = old.forceBinding == true
    sequence.versions = {}
    sequence.versionOrder = {}
    for _, oldName in ipairs({ "A", "B" }) do
        local oldVersion = old.versions[oldName]
        if type(oldVersion) == "table" then
            local version = DefaultVersion("Version " .. oldName)
            version.mode = NormalizeMode(oldVersion.mode) or MODE_EVEN_CYCLE
            version.blocks = {}
            for _, text in ipairs(oldVersion.blocks or {}) do
                local block = ParsePrototypeBlock(text)
                if block then table.insert(version.blocks, block) end
            end
            if #version.blocks == 0 then version.blocks = { DefaultBlock() } end
            version.modifierKey = MODIFIER_NAMES[oldVersion.modifierKey] and oldVersion.modifierKey or nil
            if version.modifierKey and Trim(oldVersion.modifierAction) ~= "" then
                local modifier = ParsePrototypeBlock(oldVersion.modifierAction)
                version.modifierCommand = modifier and modifier.commands and modifier.commands[1] or nil
            end
            sequence.versions[version.id] = version
            table.insert(sequence.versionOrder, version.id)
            if old.activeVersion == oldName then sequence.activeVersionId = version.id end
        end
    end
    if #sequence.versionOrder == 0 then return end
    if not sequence.versions[sequence.activeVersionId] then sequence.activeVersionId = sequence.versionOrder[1] end
    collection.sequences[sequence.id] = sequence
    table.insert(collection.order, sequence.id)
    if KeyLab.SequencerPrototype and KeyLab.SequencerPrototype.Unbind then
        KeyLab.SequencerPrototype.Unbind()
    else
        old.binding = ""
    end
    Print("The Retail-proven prototype setup was imported into the current class/spec library and the diagnostic binding was released.")
end

function Library.PrepareForAddonReset()
    Library.pendingApply = false
    if InCombat() then Library.pendingClearBindings = true; return false end
    ClearAllBindings()
    Library.pendingClearBindings = false
    return true
end

function Library.GetLastMessage()
    return Library.lastMessage or ""
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("SPELLS_CHANGED")
events:RegisterEvent("PLAYER_TALENT_UPDATE")

events:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 == ADDON_NAME then EnsureRoot() end
        return
    end
    if event == "PLAYER_LOGIN" then
        MigratePrototype()
        Library.RefreshSpellbook()
        Library.ApplyAll("login or reload")
        return
    end
    if event == "PLAYER_REGEN_ENABLED" then
        if Library.pendingClearBindings then
            ClearAllBindings()
            Library.pendingClearBindings = false
            Library.pendingApply = false
        elseif Library.pendingApply then
            Library.ApplyAll("deferred until combat ended")
        else
            Library.ResetAllRuntime("combat end")
        end
        return
    end
    if event == "PLAYER_SPECIALIZATION_CHANGED" and (arg1 == nil or arg1 == "player") then
        Library.RefreshSpellbook()
        Library.ApplyAll("specialization change")
        return
    end
    if event == "SPELLS_CHANGED" or event == "PLAYER_TALENT_UPDATE" then
        Library.RefreshSpellbook()
    end
end)

Library.secureButtons = secureButtons
Library.bindingOwners = bindingOwners

return Library
