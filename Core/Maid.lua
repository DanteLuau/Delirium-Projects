-- Core/Maid.lua
-- Centralized resource cleanup manager.
--
-- Supports:
--   RBXScriptConnection  → :Disconnect()
--   Instance             → :Destroy()
--   function             → called directly
--   table with :Destroy()
--   table with :Disconnect()
--
-- Usage:
--   local maid = Maid.new()
--   maid:GiveTask(connection)
--   maid:GiveTask(instance)
--   maid:GiveTask(function() ... end)
--   maid:DoCleaning()   -- safe, isolated, idempotent

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {}, _cleaned = false }, Maid)
end

-- Add a resource to be cleaned up.
-- Safe to call after DoCleaning — resource is cleaned immediately.
function Maid:GiveTask(task)
    if task == nil then return end
    if self._cleaned then
        -- Already destroyed — clean immediately rather than accumulate
        Maid._cleanTask(task)
        return
    end
    table.insert(self._tasks, task)
end

-- Clean a single task in isolation.
-- Never throws — errors are swallowed so other tasks keep cleaning.
function Maid._cleanTask(task)
    local ok, err = pcall(function()
        local t = type(task)
        if t == "function" then
            task()
        elseif t == "table" or t == "userdata" then
            if typeof(task) == "RBXScriptConnection" then
                task:Disconnect()
            elseif task.Destroy then
                task:Destroy()
            elseif task.Disconnect then
                task:Disconnect()
            end
        end
    end)
    if not ok then
        -- Swallowed — caller may log if diagnostics are enabled
        warn("[Maid] cleanup error: " .. tostring(err))
    end
end

-- Clean all registered tasks in LIFO order.
-- Safe to call multiple times — subsequent calls are no-ops.
function Maid:DoCleaning()
    if self._cleaned then return end
    self._cleaned = true

    -- Reverse order: last registered, first cleaned (LIFO — children before parents)
    for i = #self._tasks, 1, -1 do
        Maid._cleanTask(self._tasks[i])
        self._tasks[i] = nil
    end
    table.clear(self._tasks)
end

-- Alias
Maid.Destroy = Maid.DoCleaning

return Maid
