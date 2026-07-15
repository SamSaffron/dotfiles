local M = {}

function M.setup()
  local manage = require("lazy.manage")
  local commands = require("lazy.view.commands")
  local view_config = require("lazy.view.config")
  local original_update = manage.update
  local original_install = manage.install

  local function blocked(action)
    require("lazy.util").error(
      "Lazy "
        .. action
        .. " is disabled. Use `scripts/update` "
        .. "(`--urgent` or `--conservative` when needed)."
    )
  end

  local function require_pins(opts, action)
    local config = require("lazy.core.config")
    local lock = require("lazy.manage.lock")
    local plugins = opts.plugins or vim.tbl_values(config.plugins)
    for _, plugin in ipairs(plugins) do
      if type(plugin) == "string" then
        plugin = config.plugins[plugin]
      end
      if plugin and plugin.url and not lock.get(plugin) then
        blocked(action .. ": " .. plugin.name .. " has no quarantined lock entry")
        return false
      end
    end
    return true
  end

  -- Restore is the safe application path: lazy.nvim sets lockfile=true before
  -- calling update. Reject every update call that is not explicitly restoring
  -- a complete checked-in lockfile, including direct Lua calls.
  manage.update = function(opts)
    if opts and opts.lockfile and require_pins(opts, "restore") then
      return original_update(opts)
    end
    if not (opts and opts.lockfile) then
      return blocked("update")
    end
  end
  manage.sync = function()
    return blocked("sync")
  end
  manage.install = function(opts)
    if opts and opts.lockfile and require_pins(opts, "install") then
      return original_install(opts)
    end
    if not (opts and opts.lockfile) then
      return blocked("install")
    end
  end

  -- lazy.view.commands captures function references when loaded, so replace
  -- those as well. This covers :Lazy update/sync/install and the U/S/I keys in
  -- the Lazy UI.
  commands.commands.update = manage.update
  commands.commands.sync = manage.sync
  commands.commands.install = manage.install

  view_config.commands.update.desc = "Disabled: use scripts/update"
  view_config.commands.update.desc_plugin = view_config.commands.update.desc
  view_config.commands.sync.desc = "Disabled: use scripts/update"
  view_config.commands.sync.desc_plugin = view_config.commands.sync.desc
  view_config.commands.install.desc = "Disabled: installs must be pinned in lazy-lock.json"
  view_config.commands.install.desc_plugin = view_config.commands.install.desc
end

return M
