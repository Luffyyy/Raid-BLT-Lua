
CloneClass( ChatManager )

Hooks:RegisterHook("ChatManagerOnSendMessage")
function ChatManager:send_message(channel_id, sender, message, ...)
	Hooks:Call("ChatManagerOnSendMessage", channel_id, sender, message)
	return self.orig.send_message(self, channel_id, sender, message, ...)
end

Hooks:RegisterHook("ChatManagerOnReceiveMessage")
function ChatManager:receive_message_by_peer(peer, some_fucking_table, message, ...)
	Hooks:Call("ChatManagerOnReceiveMessage", 1, tostring(some_fucking_table._name), tostring(message))
	return self.orig.receive_message_by_peer(self, peer, some_fucking_table, message, ...)
end