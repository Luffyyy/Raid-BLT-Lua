Hooks:RegisterHook("LogicOnSelectNode")
core:module("CoreMenuLogic")
_G.CloneClass(Logic)

function Logic.select_node(self, node_name, queue, ...)
	self.orig.select_node(self, node_name, queue, ...)
	_G.Hooks:Call("LogicOnSelectNode", self, node_name, queue, ...)
end
