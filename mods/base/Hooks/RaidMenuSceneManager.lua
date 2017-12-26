--Annoyingly there isn't a way to remotely disable the escape callback(from what I know) so this should do.
function RaidMenuSceneManager:disable_back(disable)
	self._back_disabled = disable
end

function RaidMenuSceneManager:ignore_back_once()
    self._ignore_back_once = true
end

RaidMenuSceneManager.orig_on_escape = RaidMenuSceneManager.orig_on_escape or RaidMenuSceneManager.on_escape
function RaidMenuSceneManager:on_escape(...)
	if self._back_disabled then
        return
        managers.menu:active_menu().renderer:disable_input(0.2)
    end
    if self._ignore_back_once then
        self._ignore_back_once = nil
        managers.menu:active_menu().renderer:disable_input(0.2)
        return
    end
    if BLT.Dialogs:DialogOpened() then
        BLT.Dialogs:CloseLastDialog()
        managers.menu:active_menu().renderer:disable_input(0.2)
        return
    else
        self:orig_on_escape(...)
    end
end