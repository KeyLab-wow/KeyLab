local ADDON_NAME, KeyLab = ...
KeyLab = KeyLab or {}
_G.KeyLab = KeyLab

KeyLab.UI = KeyLab.UI or {}
KeyLab.UI.SeasonFilter = KeyLab.UI.SeasonFilter or {}
local SeasonFilter = KeyLab.UI.SeasonFilter
local controls = {}

local function CurrentKey()
    return KeyLab.SeasonData and KeyLab.SeasonData.GetSelectedSeasonKey
        and KeyLab.SeasonData.GetSelectedSeasonKey() or "MN_S2"
end

local function CurrentLabel()
    return KeyLab.SeasonData and KeyLab.SeasonData.GetLabel
        and KeyLab.SeasonData.GetLabel(CurrentKey()) or "MN S2"
end

local function RefreshControls()
    for control in pairs(controls) do
        if control and control.dropdown then UIDropDownMenu_SetText(control.dropdown, CurrentLabel()) end
    end
end

local function SelectSeason(seasonKey)
    if KeyLab.SeasonData and KeyLab.SeasonData.SetSelectedSeasonKey then
        KeyLab.SeasonData.SetSelectedSeasonKey(seasonKey)
    end
    RefreshControls()
    if KeyLab.RefreshTabs then KeyLab.RefreshTabs() end
end

function SeasonFilter.Attach(parent, options)
    if not parent or parent.keylabSeasonFilter then return parent and parent.keylabSeasonFilter end
    options = type(options) == "table" and options or {}
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(options.width or 142, 50)
    holder:SetPoint("TOPRIGHT", parent, "TOPRIGHT", options.x or -18, options.y or -8)
    holder:SetFrameLevel(parent:GetFrameLevel() + 8)

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    label:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    label:SetSize(120, 14)
    label:SetJustifyH("LEFT")
    label:SetText("Season")

    local dropdown = KeyLab.UI.Theme.CreateLegacyDropdown(holder)
    dropdown:SetPoint("TOPLEFT", holder, "TOPLEFT", -18, -12)
    UIDropDownMenu_SetWidth(dropdown, options.menuWidth or 104)
    UIDropDownMenu_Initialize(dropdown, function(_, level)
        local selected = CurrentKey()
        local seasonOptions = KeyLab.SeasonData and KeyLab.SeasonData.GetOptions
            and KeyLab.SeasonData.GetOptions() or {
                { value = "MN_S1", label = "MN S1" },
                { value = "MN_S2", label = "MN S2" },
            }
        for _, option in ipairs(seasonOptions) do
            local value = option.value
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.label
            info.checked = selected == value
            info.func = function() SelectSeason(value) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    holder.dropdown = dropdown
    holder:SetScript("OnShow", function() UIDropDownMenu_SetText(dropdown, CurrentLabel()) end)
    controls[holder] = true
    parent.keylabSeasonFilter = holder
    UIDropDownMenu_SetText(dropdown, CurrentLabel())
    return holder
end

function SeasonFilter.Refresh()
    RefreshControls()
end

return SeasonFilter
