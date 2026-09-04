local _, KeyLab = ...
KeyLab.UI = KeyLab.UI or {}

-- One confirmation path for manual Targets, guide lists and crafted plans.
-- Retry with a fingerprint of the named conflicts, never a blanket override.
function KeyLab.UI.RunPlanChange(specID, save, complete)
    local db = KeyLab.LootTargetsDB
    local character = db.GetCurrentCharacterKey()
    local function Attempt(approval)
        if db.GetCurrentCharacterKey() ~= character or db.GetCurrentSpecID() ~= specID then
            complete(false, "Your character or specialization changed. Reopen this plan.")
            return
        end
        if InCombatLockdown and InCombatLockdown() then complete(false, "Wait until combat ends."); return end
        local ok, message, details = save(approval)
        if not ok and message == "plan_conflict" and details then
            StaticPopupDialogs.KEYLAB_REPLACE_SLOT_PLAN = StaticPopupDialogs.KEYLAB_REPLACE_SLOT_PLAN or {
                text = "Replace existing plan?\n\n%s\n\nThese entries will be removed. Saved Alternatives will stay.",
                button1 = "Replace", button2 = "Cancel", timeout = 0,
                whileDead = true, hideOnEscape = true, preferredIndex = 3,
                OnAccept = function(_, data) data.accept() end,
            }
            local theme = KeyLab.UI.Theme
            if theme and theme.BrandConfirmationDialog then theme.BrandConfirmationDialog(StaticPopupDialogs.KEYLAB_REPLACE_SLOT_PLAN) end
            StaticPopup_Show("KEYLAB_REPLACE_SLOT_PLAN", details.text, nil, {
                accept = function() Attempt(details.token) end,
            })
            return
        end
        if ok then
            local shopping = KeyLab.CraftingShoppingWindow
            if shopping and shopping.IsShown and shopping.IsShown() then shopping.Refresh() end
            if KeyLab.GearTargetsWindow and KeyLab.GearTargetsWindow.RefreshVisible then KeyLab.GearTargetsWindow.RefreshVisible() end
        end
        complete(ok, message)
    end
    Attempt(nil)
end
