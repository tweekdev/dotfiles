-- Claude Code (Anthropic) – spec basée sur LazyVim extra: https://www.lazyvim.org/extras/ai/claudecode
-- Prérequis: Claude Code CLI (curl -fsSL claude.ai/install.sh | bash). Si install local: opts.terminal_cmd = "~/.claude/local/claude"
return {
	"coder/claudecode.nvim",
	dependencies = { "folke/snacks.nvim" },
	opts = {
		terminal = {
			provider = "snacks",
			split_side = "right",
			split_width_percentage = 0.30,
		},
		-- terminal_cmd = "claude",
	},
	event = "VeryLazy",
	keys = {
		{ "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
		{ "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
		{ "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
		{ "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
		{ "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
		{ "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
		{ "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
		{
			"<leader>as",
			"<cmd>ClaudeCodeTreeAdd<cr>",
			desc = "Add file",
			ft = { "NvimTree", "neo-tree", "oil" },
		},
		{ "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
		{ "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
	},
}
