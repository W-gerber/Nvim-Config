return {
  "Shatur/neovim-session-manager",
  cmd = { "SessionManager" },
  keys = {
    { "<leader>sl", "<cmd>SessionManager load_session<cr>", desc = "Load session" },
    { "<leader>ss", "<cmd>SessionManager save_current_session<cr>", desc = "Save session" },
    { "<leader>sd", "<cmd>SessionManager delete_session<cr>", desc = "Delete session" },
  },
  config = function()
    local config = require('session_manager.config')
    require('session_manager').setup({
      -- Avoid restoring windows (e.g. terminal) on every startup.
      -- Load sessions manually via the dashboard button when desired.
      autoload_mode = config.AutoloadMode.Disabled,
      autosave_last_session = true,
      autosave_ignore_not_normal = true,
      autosave_only_in_session = false,
      max_path_length = 80,
    })
  end,
}
