Hooks:Register("GameSetupUpdate")
Hooks:Register("GameSetupPausedUpdate")

Hooks:PostHook(GameSetup, "update", "BLT.GameSetupUpdate", function(self, t, dt)
	Hooks:Call("GameSetupUpdate", t, dt)
end)

Hooks:PostHook(GameSetup, "paused_update", "BLT.GameSetupPausedUpdate", function(self, t, dt)
	Hooks:Call("GameSetupPausedUpdate", t, dt)
end)

Hooks:Add("GameSetupPausedUpdate", "BLT.GameSetupPausedUpdate", callback(BLT, BLT, "PausedUpdate"))
Hooks:Add("GameSetupUpdate", "BLT.GameSetupPausedUpdate", callback(BLT, BLT, "Update"))
