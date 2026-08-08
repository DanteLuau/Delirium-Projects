-- Core/ServiceRegistry.lua
-- Lifecycle registry for Delirium services.
--
-- Services self-register at require() time.
-- Bootstrap calls ResetAll() / InitAll(gui) — never needs to know service names.
-- Duplicate names are rejected: re-registering the same name replaces the old entry
-- after safely destroying it.
--
-- Adding a new service:
--   1. Write Reset() and/or Init(gui) on your service module.
--   2. At the bottom of the file: ServiceRegistry.Register("Name", hooks, priority)
--   Done. Bootstrap picks it up automatically.

local _registry = {}      -- ordered array: { name, hooks, priority }
local _byName   = {}      -- name → index in _registry (for duplicate detection)

local ServiceRegistry = {}

-- Register a service.
--
-- name     : string   — unique identifier; duplicate names replace the old entry.
-- hooks    : table    — { Reset?: () -> (), Init?: (gui: ScreenGui) -> () }
-- priority : number?  — lower = runs first in ResetAll/InitAll (default 50)
function ServiceRegistry.Register(name: string, hooks: table, priority: number?)
    assert(type(name)  == "string" and #name > 0,
        "ServiceRegistry.Register: name must be a non-empty string")
    assert(type(hooks) == "table",
        "ServiceRegistry.Register: hooks must be a table")

    -- Duplicate prevention: destroy old entry before replacing
    local existingIdx = _byName[name]
    if existingIdx then
        local old = _registry[existingIdx]
        if old and type(old.hooks.Reset) == "function" then
            pcall(old.hooks.Reset)
        end
        table.remove(_registry, existingIdx)
        -- Rebuild name→index map after removal
        _byName = {}
        for i, entry in ipairs(_registry) do
            _byName[entry.name] = i
        end
    end

    local entry = {
        name     = name,
        hooks    = hooks,
        priority = priority or 50,
    }
    table.insert(_registry, entry)
    table.sort(_registry, function(a, b) return a.priority < b.priority end)

    -- Rebuild map after sort
    _byName = {}
    for i, e in ipairs(_registry) do
        _byName[e.name] = i
    end
end

-- Reset all registered services in priority order.
-- Called by Bootstrap before creating a new session.
function ServiceRegistry.ResetAll()
    for _, entry in ipairs(_registry) do
        if type(entry.hooks.Reset) == "function" then
            pcall(entry.hooks.Reset)
        end
    end
end

-- Initialize all registered services that have an Init hook.
-- Called by Bootstrap after the new ScreenGui is live.
function ServiceRegistry.InitAll(gui: ScreenGui)
    for _, entry in ipairs(_registry) do
        if type(entry.hooks.Init) == "function" then
            pcall(entry.hooks.Init, gui)
        end
    end
end

-- List registered services (debug).
function ServiceRegistry.List(): {string}
    local out = {}
    for _, entry in ipairs(_registry) do
        table.insert(out, string.format("[%d] %s", entry.priority, entry.name))
    end
    return out
end

return ServiceRegistry
