TekagiUI = TekagiUI or {}
TekagiUI.Modules = TekagiUI.Modules or {}

TekagiUI.Modules.Testing = TekagiUI.Modules.Testing or {}

local M = TekagiUI.Modules.Testing

M.defaults = {
	testSetting = true,
}

M.settings = {
	name = "Testing",
	settings = {
		testSetting = {
			type = "bool",
			label = "Test Setting",
		},
	},
}
