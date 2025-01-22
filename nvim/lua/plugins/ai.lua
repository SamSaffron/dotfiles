return {
	{
		"GeorgesAlkhouri/nvim-aider",
		cmd = {
			"AiderTerminalToggle",
			"AiderHealth",
		},
		keys = {
			{ "<leader>a/", "<cmd>AiderTerminalToggle<cr>", desc = "Open Aider" },
			{ "<leader>as", "<cmd>AiderTerminalSend<cr>", desc = "Send to Aider", mode = { "n", "v" } },
			{ "<leader>ac", "<cmd>AiderQuickSendCommand<cr>", desc = "Send Command To Aider" },
			{ "<leader>ab", "<cmd>AiderQuickSendBuffer<cr>", desc = "Send Buffer To Aider" },
			{ "<leader>a+", "<cmd>AiderQuickAddFile<cr>", desc = "Add File to Aider" },
			{ "<leader>a-", "<cmd>AiderQuickDropFile<cr>", desc = "Drop File from Aider" },
			{ "<leader>ar", "<cmd>AiderQuickReadOnlyFile<cr>", desc = "Add File as Read-Only" },
		},
		dependencies = {
			"folke/snacks.nvim",
			"nvim-telescope/telescope.nvim",
		},
		config = true,
	},
}
