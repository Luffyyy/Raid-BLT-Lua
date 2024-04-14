core:module("SystemMenuManager")

Hooks:PostHook(GenericSystemMenuManager, "event_dialog_shown", "BLT.EventDialogShown", function(self)
    if BLT.Dialogs:DialogOpened() then
        BLT.Dialogs.IgnoreDialogOnce = true
    end
end)

Hooks:PostHook(GenericSystemMenuManager, "event_dialog_closed", "BLT.EventDialogClosed", function(self)
    BLT.Dialogs.IgnoreDialogOnce = false
end)
