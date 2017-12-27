
core:module("SystemMenuManager")

Hooks:PostHook(GenericSystemMenuManager, "event_dialog_shown", "BeardLibEventDialogShown", function(self)
    if BLT.Dialogs:DialogOpened() then
        BLT.Dialogs.IgnoreDialogOnce = true
    end
end)

Hooks:PostHook(GenericSystemMenuManager, "event_dialog_closed", "BeardLibEventDialogClosed", function(self)
    BLT.Dialogs.IgnoreDialogOnce = false
end)