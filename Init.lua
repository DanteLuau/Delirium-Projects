-- Init.lua
-- Delirium entry point.
--
-- Bootstrap flow (per exec):
--   Detect previous Runtime in _G
--     ├── Alive  → Runtime:Destroy() → wait frame → create new
--     └── Dead   → wipe stale state  → create new
--   (none) → scan for orphan GUI → create new
--
-- Public API: CreateWindow, Notify, SetTheme, RegisterTheme, SetReducedMotion

local CoreGui  = game:GetService("CoreGui")
local Players  = game:GetService("Players")

-- ServiceRegistry required first — services self-register during require()
local ServiceRegistry     = require(script.Core.ServiceRegistry)

local Runtime             = require(script.Core.Runtime)
local ThemeEngine         = require(script.Core.ThemeEngine)
local AnimationEngine     = require(script.Core.AnimationEngine)
local NotificationService = require(script.Services.NotificationService)
local DialogService       = require(script.Services.DialogService)
local Window              = require(script.Layout.Window)

-- ─── Constants ─────────────────────────────────────────────────────────────

local RUNTIME_KEY = "__DeliriumRuntime"
local GUI_NAME    = "DeliriumUI"

-- ─── Helpers ───────────────────────────────────────────────────────────────

local function _nukeExistingGui()
    local parents = {
        CoreGui,
        Players.LocalPlayer:FindFirstChild("PlayerGui"),
    }
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == GUI_NAME then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function _createGui(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name            = GUI_NAME
    gui.ResetOnSpawn    = false
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset  = true   -- cover full screen incl. topbar area; avoids backdrop gap
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then
        gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
    end
    return gui
end

-- ─── Bootstrap ─────────────────────────────────────────────────────────────

local _runtime: typeof(Runtime.new()) = nil

local function Bootstrap()
    -- Step 1: Destroy GUI unconditionally — most reliable kill
    _nukeExistingGui()

    -- Step 2: Destroy previous Runtime (handles cascade + service cleanup)
    local existing = _G[RUNTIME_KEY]
    if existing then
        if type(existing.IsAlive) == "function" and existing:IsAlive() then
            pcall(function() existing:Destroy() end)
            task.wait()  -- one frame for async resources to settle
        else
            -- Dead/stale: just reset services
            ServiceRegistry.ResetAll()
        end
        _G[RUNTIME_KEY] = nil
    end

    -- Step 3: Hard reset all services regardless of path above
    ServiceRegistry.ResetAll()

    -- Step 4: Create new Runtime + GUI
    local gui     = _createGui()
    local runtime = Runtime.new()

    -- Runtime owns the ScreenGui instance
    runtime:OwnResource(gui)

    _G[RUNTIME_KEY] = runtime
    _runtime        = runtime

    -- Step 5: Initialize services with the new ScreenGui
    ServiceRegistry.InitAll(gui)

    return runtime, gui
end

-- Run immediately on require
local _runtime, _gui = Bootstrap()

-- ─── Delirium Public API ───────────────────────────────────────────────────

local Delirium = {
    Version = "1.0.0",
}

function Delirium:CreateWindow(config: table)
    assert(config and type(config) == "table",
        "Delirium:CreateWindow expects a configuration table")
    config.Name = config.Name or config.Title or "Delirium"

    local win = Window.new(config, _gui)
    _runtime:RegisterWindow(win)
    return win
end

function Delirium:Notify(config: table)
    return NotificationService.Push(config)
end

function Delirium:SetTheme(themeName: string)
    ThemeEngine.SetTheme(themeName)
end

function Delirium:RegisterTheme(name: string, tokens: table)
    ThemeEngine.RegisterTheme(name, tokens)
end

function Delirium:SetReducedMotion(enabled: boolean)
    AnimationEngine.ReducedMotion = enabled == true
end

-- Returns the session ID of the current runtime.
-- Capture this before async work; check IsCurrent() after to guard stale callbacks.
function Delirium:GetSessionId(): string
    return _runtime.SessionId
end

function Delirium:IsSessionCurrent(sessionId: string): boolean
    return _runtime:IsCurrent(sessionId)
end

-- Expose sub-modules for advanced use
Delirium.Theme     = ThemeEngine
Delirium.Animation = AnimationEngine

return Delirium
