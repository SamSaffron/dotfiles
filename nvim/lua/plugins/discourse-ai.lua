return {
	dir = "~/Source/discourse_ai_nvim", -- Path to your local plugin directory
	name = "discourse_ai",
	lazy = false,
	config = function()
		require("discourse_ai").setup()
	end,
	keys = {
		{ "<leader>r", "<cmd>Lazy reload discourse_ai<cr>", desc = "Reload plugin" },
		{ "<leader>rc", "<cmd>ChatOpen<cr>", desc = "Open Chat Window" },
	},
}
