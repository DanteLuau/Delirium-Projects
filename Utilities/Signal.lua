-- Utilities/Signal.lua
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal) -- fix: setmetable → setmetatable
    self._handlers = {}
    return self
end

function Signal:Connect(fn: (...any) -> ())
    assert(type(fn) == "function", "Signal:Connect expects a function")
    local handler = { fn = fn, connected = true }
    table.insert(self._handlers, handler)
    return {
        Disconnect = function()
            handler.connected = false
            local index = table.find(self._handlers, handler)
            if index then
                table.remove(self._handlers, index)
            end
        end
    }
end

function Signal:Fire(...)
    local args = { ... }
    for _, handler in ipairs(self._handlers) do
        if handler.connected then
            task.spawn(handler.fn, table.unpack(args))
        end
    end
end

function Signal:Once(fn: (...any) -> ())
    assert(type(fn) == "function", "Signal:Once expects a function")
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect() -- fix: actually disconnect after first fire
        fn(...)
    end)
    return connection
end

-- Clear all handlers without destroying the Signal object.
-- Safe to call from Reset() paths where other modules still hold the Signal ref.
function Signal:DisconnectAll()
    table.clear(self._handlers)
end

function Signal:Destroy()
    table.clear(self._handlers)
    self._handlers = nil
end

return Signal