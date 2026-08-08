-- Services/ConfigService.lua
-- Persistent key-value configuration storage.
-- Profiles are singletons — GetProfile("name") always returns the same object.
-- Relies on executor writefile/readfile/delfile (standard exploit environment).
--
-- Usage:
--   local cfg = ConfigService.GetProfile("MyMenu")
--   cfg:Set("volume", 0.8)
--   local vol = cfg:Get("volume", 1.0)  -- 1.0 is the default
--   cfg:Save()
--   cfg:Load()

local ConfigService = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local FILE_PREFIX = "delirium_cfg_"

-- ─── JSON codec (flat objects only) ──────────────────────────────────────────
-- We don't want a full JSON dep for simple string/number/boolean config data.

local function _jsonEncode(t: table): string
    local parts = {}
    for k, v in pairs(t) do
        local ks = tostring(k):gsub('\\', '\\\\'):gsub('"', '\\"')
        local vs
        if type(v) == "string" then
            vs = '"' .. v:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
        elseif type(v) == "boolean" or type(v) == "number" then
            vs = tostring(v)
        else
            -- Unsupported type: coerce to string
            vs = '"' .. tostring(v):gsub('"', '\\"') .. '"'
        end
        table.insert(parts, '"' .. ks .. '":' .. vs)
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function _jsonDecode(s: string): table
    local result = {}
    -- Strip outer braces
    local inner = s:match("^%s*{(.*)}%s*$")
    if not inner or inner == "" then return result end

    -- Walk the string matching "key": value pairs.
    -- Handles string values (with escapes), booleans, numbers.
    local pos = 1
    local len = #inner

    local function skipWS()
        while pos <= len and inner:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end

    local function readString(): string?
        if inner:sub(pos, pos) ~= '"' then return nil end
        pos = pos + 1
        local out = {}
        while pos <= len do
            local ch = inner:sub(pos, pos)
            if ch == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif ch == '\\' then
                pos = pos + 1
                local esc = inner:sub(pos, pos)
                if esc == '"' then table.insert(out, '"')
                elseif esc == 'n' then table.insert(out, '\n')
                elseif esc == 't' then table.insert(out, '\t')
                elseif esc == '\\' then table.insert(out, '\\')
                else table.insert(out, esc) end
                pos = pos + 1
            else
                table.insert(out, ch)
                pos = pos + 1
            end
        end
        return table.concat(out)
    end

    local function readValue(): any
        skipWS()
        local ch = inner:sub(pos, pos)
        if ch == '"' then
            return readString()
        elseif inner:sub(pos, pos + 3) == "true" then
            pos = pos + 4; return true
        elseif inner:sub(pos, pos + 4) == "false" then
            pos = pos + 5; return false
        elseif inner:sub(pos, pos + 3) == "null" then
            pos = pos + 4; return nil
        else
            -- Number
            local numStr = inner:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
            if numStr then
                pos = pos + #numStr
                return tonumber(numStr)
            end
        end
        return nil
    end

    while pos <= len do
        skipWS()
        if pos > len then break end
        -- Expect a key
        local key = readString()
        if not key then break end
        skipWS()
        -- Expect ':'
        if inner:sub(pos, pos) ~= ':' then break end
        pos = pos + 1
        -- Read value
        local val = readValue()
        if key and val ~= nil then
            result[key] = val
        end
        skipWS()
        -- Optional ','
        if inner:sub(pos, pos) == ',' then
            pos = pos + 1
        end
    end

    return result
end

-- ─── File path ───────────────────────────────────────────────────────────────

local function _filepath(name: string): string
    -- Sanitize: lowercase, replace non-alphanumeric/underscore with underscore
    return FILE_PREFIX .. name:lower():gsub("[^%w_%-]", "_") .. ".json"
end

-- ─── Profile ──────────────────────────────────────────────────────────────────

local Profile    = {}
Profile.__index  = Profile

function Profile.new(name: string): table
    local self     = setmetatable({}, Profile)
    self._name     = name
    self._path     = _filepath(name)
    self._data     = {}
    self._dirty    = false
    self:Load()
    return self
end

-- Get a value. Returns `default` if the key is not set.
function Profile:Get(key: string, default: any): any
    local v = self._data[key]
    return v ~= nil and v or default
end

-- Set a value in memory. Does NOT auto-save; call :Save() to persist.
function Profile:Set(key: string, value: any)
    self._data[key] = value
    self._dirty     = true
end

-- Remove a key from memory. Does NOT auto-save.
function Profile:Delete(key: string)
    self._data[key] = nil
    self._dirty     = true
end

-- Reset all keys in memory. Does NOT auto-save.
function Profile:Reset()
    table.clear(self._data)
    self._dirty = true
end

-- Returns true if there are unsaved in-memory changes.
function Profile:IsDirty(): boolean
    return self._dirty
end

-- Persist current in-memory data to disk.
-- Returns true on success.
function Profile:Save(): boolean
    local ok, err = pcall(writefile, self._path, _jsonEncode(self._data))
    if not ok then
        warn(string.format(
            "ConfigService: save failed for profile '%s' — %s",
            self._name, tostring(err)
        ))
        return false
    end
    self._dirty = false
    return true
end

-- Load data from disk into memory, replacing current in-memory state.
-- Silently no-ops if the file doesn't exist yet.
-- Returns true if data was loaded.
function Profile:Load(): boolean
    local ok, content = pcall(readfile, self._path)
    if not ok or not content or #content == 0 then
        return false  -- file doesn't exist yet, first run
    end
    local decoded = _jsonDecode(content)
    self._data  = decoded
    self._dirty = false
    return true
end

-- Returns a shallow copy of all stored key-value pairs.
function Profile:GetAll(): table
    local copy = {}
    for k, v in pairs(self._data) do
        copy[k] = v
    end
    return copy
end

-- Returns the profile name.
function Profile:GetName(): string
    return self._name
end

-- ─── ConfigService API ────────────────────────────────────────────────────────

local _profiles: {[string]: typeof(Profile.new(""))} = {}

-- Get (or create) a named config profile.
-- Profiles are singletons — same name always returns the same object in-session.
-- Data is auto-loaded from disk on first access.
function ConfigService.GetProfile(name: string)
    assert(type(name) == "string" and #name > 0,
        "ConfigService.GetProfile: name must be a non-empty string")
    if not _profiles[name] then
        _profiles[name] = Profile.new(name)
    end
    return _profiles[name]
end

-- Save all active profiles that have unsaved changes.
function ConfigService.SaveAll()
    for _, profile in pairs(_profiles) do
        if profile:IsDirty() then
            profile:Save()
        end
    end
end

-- Force-save all profiles regardless of dirty state.
function ConfigService.SaveAllForce()
    for _, profile in pairs(_profiles) do
        profile:Save()
    end
end

-- Delete a profile's file from disk and evict it from the cache.
-- Returns true if the file was successfully deleted.
function ConfigService.DeleteProfile(name: string): boolean
    local path = _filepath(name)
    local ok   = pcall(delfile, path)
    _profiles[name] = nil
    return ok
end

-- Returns a sorted list of profile names currently in the in-memory cache.
function ConfigService.ListProfiles(): {string}
    local names = {}
    for name in pairs(_profiles) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = require(script.Parent.Parent.Core.ServiceRegistry)

ServiceRegistry.Register("ConfigService", {
    Reset = function()
        -- On re-exec: evict the in-memory cache so fresh Load() happens next time.
        -- Do NOT wipe disk data — persisted config should survive re-execs.
        table.clear(_profiles)
    end,
}, 20)  -- priority 20 — resets before UI services that consume config

return ConfigService
