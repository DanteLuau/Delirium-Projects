-- Core/Runtime.lua
-- Represents one active Delirium execution session.
--
-- Owns: services, windows, global resources.
-- Stored in _G[SESSION_KEY] so the next exec can detect and destroy it.
--
-- Usage (internal — called by Init.lua):
--   local runtime = Runtime.new()
--   runtime:IsAlive()
--   runtime:IsCurrent(sessionId)
--   runtime:Destroy()

local Maid = require(script.Parent.Maid)

-- ─── ID generation ────────────────────────────────────────────────────────────

local function _generateId(): string
    return string.format("DLR_%x_%x", os.clock() * 1e6 // 1, math.random(0, 0xFFFF))
end

-- ─── Runtime ──────────────────────────────────────────────────────────────────

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new()
    local self = setmetatable({}, Runtime)

    self.SessionId  = _generateId()
    self._alive     = true
    self._maid      = Maid.new()

    -- Registered service objects (expose :Destroy())
    -- Keyed by name to prevent duplicates.
    self._services  = {}  -- { [name] = serviceObject }

    -- Owned windows
    self._windows   = {}

    return self
end

-- ── Query ──────────────────────────────────────────────────────────────────

function Runtime:IsAlive(): boolean
    return self._alive
end

-- Async stale-callback guard.
-- Usage: if not runtime:IsCurrent(capturedId) then return end
function Runtime:IsCurrent(sessionId: string): boolean
    return self._alive and self.SessionId == sessionId
end

-- ── Service management ────────────────────────────────────────────────────

-- Register a service by name.
-- If a service with the same name already exists, it is destroyed first.
-- service must expose :Destroy() or be a plain cleanup function.
function Runtime:RegisterService(name: string, service)
    assert(type(name) == "string" and #name > 0,
        "Runtime:RegisterService — name must be a non-empty string")

    local existing = self._services[name]
    if existing then
        -- Replace: destroy old registration before accepting new one
        pcall(function()
            if type(existing) == "function" then
                existing()
            elseif existing.Destroy then
                existing:Destroy()
            end
        end)
    end

    self._services[name] = service
end

function Runtime:GetService(name: string)
    return self._services[name]
end

-- ── Window management ─────────────────────────────────────────────────────

function Runtime:RegisterWindow(window)
    table.insert(self._windows, window)
end

-- ── Resource management ───────────────────────────────────────────────────

-- Give any resource to the runtime's own Maid.
function Runtime:OwnResource(task)
    self._maid:GiveTask(task)
end

-- ── Destruction ───────────────────────────────────────────────────────────

function Runtime:Destroy()
    if not self._alive then return end  -- idempotent
    self._alive = false

    -- 1. Destroy windows (cascade: Window → Tab → Section → Component)
    for _, win in ipairs(self._windows) do
        pcall(function() win:Destroy() end)
    end
    table.clear(self._windows)

    -- 2. Destroy services
    for name, service in pairs(self._services) do
        pcall(function()
            if type(service) == "function" then
                service()
            elseif service.Destroy then
                service:Destroy()
            end
        end)
        self._services[name] = nil
    end

    -- 3. Clean runtime-owned resources
    self._maid:DoCleaning()
end

return Runtime
