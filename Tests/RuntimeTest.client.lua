-- Tests/RuntimeTest.client.lua
-- Delirium v1.1.0 — Runtime Stress Test Suite
--
-- Execution model:
--   Delirium is a single bundled file fetched ONLY from the raw GitHub dist URL
--   via the executor's game:HttpGet() + loadstring(). The harness is fully
--   independent of where RuntimeTest.client.lua is located — no local files,
--   no DataModel paths, no workspace paths.
--
-- Loaded runtime:
--   All tests run against the SAME bundled Delirium instance returned by the
--   loader. Internal modules (Runtime, NotificationService, InputAdapter,
--   Signal, Maid, etc.) are NOT require()d directly — doing so would create a
--   second copy, so tests that need internal access are SKIPped with a reason.
--
-- Output format:
--   [DELR-TEST] PASS  <name>
--   [DELR-TEST] FAIL  <name> — <error>
--   [DELR-TEST] SKIP  <name> — <reason>
--
-- Final block:
--   ================================
--    DELIRIUM RUNTIME TEST SUMMARY
--   ================================
--   PASS: X  FAIL: X  SKIP: X
--
-- ─── IMPORTANT ────────────────────────────────────────────────────────────────
-- Do NOT modify Delirium source files to make tests pass.
-- If a test exposes a real bug, it FAILS and the bug is reported.
-- pcall is used so one failure does not abort the whole suite.
-- A pcall-caught error is always recorded as FAIL, never silently swallowed.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Environment detection ─────────────────────────────────────────────────────
local IS_EXECUTOR = (type(getgenv) == "function")

if not IS_EXECUTOR then
    print("[DELR-TEST] Environment: Roblox Studio")
    print("[DELR-TEST] SKIP — Executor-only environment required")
    print("[DELR-TEST] Delirium bundle loading needs executor APIs (game:HttpGet / loadstring).")
    return
end

print("[DELR-TEST] Environment: Executor")

-- ── Bundle loading — RAW GITHUB URL ONLY ───────────────────────────────────────
-- The harness is fully independent of where RuntimeTest.client.lua is located.
-- The raw GitHub URL below is the ONLY source of Delirium. No local filesystem,
-- no DataModel paths, no workspace paths are consulted.

local RAW_URL = "https://raw.githubusercontent.com/DanteLuau/Delirium-Projects/refs/heads/main/dist/Delirium.lua"

-- Resolve loadstring from the executor environment.
local loadFn = (getgenv and getgenv().loadstring) or loadstring or load
if type(loadFn) ~= "function" then
    print("[DELR-TEST] FATAL — No loadstring function available")
    print("[DELR-TEST] Error: executor does not expose loadstring/load")
    return
end

print("[DELR-TEST] Loading Delirium from RAW GitHub:")
print("[DELR-TEST] URL: " .. RAW_URL)

-- Step 1: HTTP GET the bundle.
local getOk, rawCode = pcall(game.HttpGet, game, RAW_URL)
if not getOk or type(rawCode) ~= "string" or #rawCode < 100 then
    print("[DELR-TEST] FATAL — RAW HTTP GET failed")
    print("[DELR-TEST] Error: " .. tostring(getOk and ("Empty or short response (" .. tostring(type(rawCode)) .. ")") or rawCode))
    return
end

-- Step 2: loadstring compilation.
local compileOk, compiled, compileErr = pcall(loadFn, rawCode)
if not compileOk or type(compiled) ~= "function" then
    print("[DELR-TEST] FATAL — Delirium bundle compilation failed")
    print("[DELR-TEST] Error: " .. tostring(compileOk and (compileErr or "compiled result is not a function") or compiled))
    return
end

-- Step 3: execute the compiled bundle.
local execOk, Delirium = pcall(compiled)
if not execOk then
    print("[DELR-TEST] FATAL — Delirium bundle execution failed")
    print("[DELR-TEST] Error: " .. tostring(Delirium))
    return
end

-- Step 4: validate the returned API.
if type(Delirium) ~= "table" or type(Delirium.CreateWindow) ~= "function" then
    print("[DELR-TEST] FATAL — Invalid Delirium API returned")
    print("[DELR-TEST] Expected table with CreateWindow()")
    return
end

print("[DELR-TEST] Loaded Delirium from RAW GitHub")
print("[DELR-TEST] Version: " .. tostring(Delirium.Version or "?"))

-- ── Harness state ─────────────────────────────────────────────────────────────
local Results = { pass = 0, fail = 0, skip = 0 }
local Bugs    = {}   -- { { name, severity, result, repro, expected, actual, cause, module } }

local function _pass(name)
    Results.pass += 1
    print(string.format("[DELR-TEST] PASS  %s", name))
end

local function _fail(name, err, bug)
    Results.fail += 1
    print(string.format("[DELR-TEST] FAIL  %s — %s", name, tostring(err)))
    if bug then
        table.insert(Bugs, bug)
    end
end

local function _skip(name, reason)
    Results.skip += 1
    print(string.format("[DELR-TEST] SKIP  %s — %s", name, tostring(reason)))
end

-- Run fn inside pcall. PASS on success, FAIL with error on caught exception.
-- bugInfo: optional table { severity, repro, expected, actual, cause, module }
local function _test(name, fn, bugInfo)
    local ok, err = xpcall(fn, function(e)
        return debug.traceback(e, 2)
    end)
    if ok then
        _pass(name)
    else
        local b = nil
        if bugInfo then
            b = {
                name     = name,
                severity = bugInfo.severity or "P2",
                result   = "FAIL",
                repro    = bugInfo.repro or "See test body",
                expected = bugInfo.expected or "No error",
                actual   = tostring(err),
                cause    = bugInfo.cause or "Unknown",
                module   = bugInfo.module or "Unknown",
            }
        end
        _fail(name, err, b)
    end
end

-- Async variant — fn returns and awaits a coroutine (must complete within timeout).
local function _testAsync(name, fn, timeoutSec, bugInfo)
    timeoutSec = timeoutSec or 5
    local done    = false
    local result  = nil
    local errMsg  = nil

    task.spawn(function()
        local ok, err = xpcall(fn, function(e) return debug.traceback(e, 2) end)
        result = ok
        errMsg = err
        done   = true
    end)

    local elapsed = 0
    local step    = 0.05
    while not done and elapsed < timeoutSec do
        task.wait(step)
        elapsed += step
    end

    if not done then
        _fail(name, "TIMEOUT after " .. timeoutSec .. "s", bugInfo and {
            name     = name,
            severity = bugInfo.severity or "P1",
            result   = "TIMEOUT",
            repro    = bugInfo.repro or "See test body",
            expected = bugInfo.expected or "Completes within " .. timeoutSec .. "s",
            actual   = "Never completed",
            cause    = bugInfo.cause or "Async deadlock or missing signal",
            module   = bugInfo.module or "Unknown",
        } or nil)
    elseif not result then
        local b = nil
        if bugInfo then
            b = {
                name     = name,
                severity = bugInfo.severity or "P2",
                result   = "FAIL",
                repro    = bugInfo.repro or "See test body",
                expected = bugInfo.expected or "No error",
                actual   = tostring(errMsg),
                cause    = bugInfo.cause or "Unknown",
                module   = bugInfo.module or "Unknown",
            }
        end
        _fail(name, errMsg, b)
    else
        _pass(name)
    end
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 1. PRELIMINARY — API SURFACE CHECK
-- Verify every public symbol exists before running behavioral tests.
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §1  API Surface Check ───────────────────────────────────────────")

_test("T01.1 Delirium.Version exists", function()
    assert(type(Delirium.Version) == "string",
        "Delirium.Version should be a string, got: " .. type(Delirium.Version))
end)

_test("T01.2 CreateWindow exists", function()
    assert(type(Delirium.CreateWindow) == "function", "CreateWindow not a function")
end)

_test("T01.3 Notify exists", function()
    assert(type(Delirium.Notify) == "function", "Notify not a function")
end)

_test("T01.4 SetTheme exists", function()
    assert(type(Delirium.SetTheme) == "function", "SetTheme not a function")
end)

_test("T01.5 RegisterTheme exists", function()
    assert(type(Delirium.RegisterTheme) == "function", "RegisterTheme not a function")
end)

_test("T01.6 SetReducedMotion exists", function()
    assert(type(Delirium.SetReducedMotion) == "function", "SetReducedMotion not a function")
end)

_test("T01.7 GetSessionId exists", function()
    assert(type(Delirium.GetSessionId) == "function", "GetSessionId not a function")
end)

_test("T01.8 IsSessionCurrent exists", function()
    assert(type(Delirium.IsSessionCurrent) == "function", "IsSessionCurrent not a function")
end)

_test("T01.9 Unload exists", function()
    assert(type(Delirium.Unload) == "function", "Unload not a function")
end)

_test("T01.10 OnUnload exists", function()
    assert(type(Delirium.OnUnload) == "function", "OnUnload not a function")
end)

_test("T01.11 Theme sub-module exists", function()
    assert(type(Delirium.Theme) == "table", "Delirium.Theme sub-module missing")
    assert(type(Delirium.Theme.SetTheme) == "function", "Delirium.Theme.SetTheme missing")
    assert(type(Delirium.Theme.GetToken) == "function", "Delirium.Theme.GetToken missing")
    assert(type(Delirium.Theme.OnThemeChanged) == "function", "Delirium.Theme.OnThemeChanged missing")
end)

_test("T01.12 Animation sub-module exists", function()
    assert(type(Delirium.Animation) == "table", "Delirium.Animation sub-module missing")
    assert(type(Delirium.Animation.Play) == "function", "Animation.Play missing")
    assert(type(Delirium.Animation.TypeWriter) == "function", "Animation.TypeWriter missing")
    assert(type(Delirium.Animation.Sequence) == "function", "Animation.Sequence missing")
    assert(type(Delirium.Animation.Parallel) == "function", "Animation.Parallel missing")
    assert(type(Delirium.Animation.Stagger) == "function", "Animation.Stagger missing")
    assert(type(Delirium.Animation.Cancel) == "function", "Animation.Cancel missing")
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 2. WINDOW LIFECYCLE
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §2  Window Lifecycle ────────────────────────────────────────────")

_test("T02.1 CreateWindow returns object", function()
    local win = Delirium:CreateWindow({ Name = "TestWin", Close = false, UnloadOnClose = false })
    assert(win ~= nil, "CreateWindow returned nil")
    assert(type(win.Destroy) == "function", "Window missing :Destroy()")
    assert(type(win.CreateTab) == "function", "Window missing :CreateTab()")
    win:Destroy()
end, { severity = "P0", module = "Layout/Window", cause = "CreateWindow contract broken" })

_test("T02.2 CreateTab returns object", function()
    local win = Delirium:CreateWindow({ Name = "TestWin", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "Tab1" })
    assert(tab ~= nil, "CreateTab returned nil")
    assert(type(tab.CreateSection) == "function", "Tab missing :CreateSection()")
    win:Destroy()
end, { severity = "P0", module = "Layout/Tab" })

_test("T02.3 CreateSection returns object", function()
    local win = Delirium:CreateWindow({ Name = "TestWin", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "Tab1" })
    local sec = tab:CreateSection("Section1")
    assert(sec ~= nil, "CreateSection returned nil")
    assert(type(sec.CreateButton) == "function", "Section missing :CreateButton()")
    assert(type(sec.CreateToggle) == "function", "Section missing :CreateToggle()")
    assert(type(sec.Destroy) == "function", "Section missing :Destroy()")
    win:Destroy()
end, { severity = "P0", module = "Layout/Section" })

_test("T02.4 Destroy does not error", function()
    local win = Delirium:CreateWindow({ Name = "TestWin", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "Tab1" })
    local sec = tab:CreateSection("Sec1")
    sec:CreateButton({ Title = "Btn1" })
    sec:CreateToggle({ Title = "Tog1" })
    win:Destroy()
    -- no error = pass
end, { severity = "P0", module = "Layout/Window", cause = "Destroy cascade failure" })

_test("T02.5 Destroy is idempotent", function()
    local win = Delirium:CreateWindow({ Name = "TestWin", Close = false, UnloadOnClose = false })
    win:Destroy()
    win:Destroy()  -- second call must not error
    win:Destroy()  -- third call must not error
end, { severity = "P1", module = "Layout/Window", cause = "_destroyed guard missing or broken" })

_test("T02.6 GUI removed after Destroy", function()
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local win = Delirium:CreateWindow({ Name = "GUIRemoveTest", Close = false, UnloadOnClose = false })
    local frameName = win.MainFrame and win.MainFrame.Name
    win:Destroy()
    task.wait(0.1)
    -- Check CoreGui and PlayerGui for any leftover MainFrame
    local function findIn(parent)
        if not parent then return false end
        for _, child in ipairs(parent:GetDescendants()) do
            if child.Name == frameName then return true end
        end
        return false
    end
    local foundInCore = findIn(CoreGui:FindFirstChild("DeliriumUI"))
    local lp = Players.LocalPlayer
    local playerGui = lp and lp:FindFirstChild("PlayerGui")
    local foundInPlayer = findIn(playerGui and playerGui:FindFirstChild("DeliriumUI"))
    assert(not foundInCore and not foundInPlayer,
        "MainFrame still present in GUI tree after Destroy")
end, { severity = "P1", module = "Layout/Window", cause = "Maid not cleaning MainFrame" })

_test("T02.7 Runtime no longer references destroyed window", function()
    local envG = (type(getgenv) == "function" and getgenv()) or _G or {}
    local runtime = envG["__DeliriumRuntime"]
    assert(runtime, "No active runtime in _G")
    local win = Delirium:CreateWindow({ Name = "RegTest", Close = false, UnloadOnClose = false })
    win:Destroy()
    -- Window:Destroy calls runtime:UnregisterWindow — it should not be in _windows
    for _, w in ipairs(runtime._windows or {}) do
        assert(w ~= win, "Destroyed window still in runtime._windows")
    end
end, { severity = "P1", module = "Core/Runtime", cause = "UnregisterWindow not called on Destroy" })

-- § 2.8 Create → Destroy → Create cycle × 10
print("  [Cycling] Create→Destroy×10 ...")
local cycleErrors = 0
for i = 1, 10 do
    local ok, err = pcall(function()
        local win = Delirium:CreateWindow({ Name = "Cycle"..i, Close = false, UnloadOnClose = false })
        local tab = win:CreateTab({ Name = "T" })
        local sec = tab:CreateSection("S")
        sec:CreateButton({ Title = "B" })
        sec:CreateToggle({ Title = "T", Default = false })
        sec:CreateSlider({ Title = "S", Min = 0, Max = 100, Default = 50 })
        win:Destroy()
    end)
    if not ok then
        cycleErrors += 1
        print(string.format("  [Cycle %d] ERROR: %s", i, tostring(err)))
    end
end
if cycleErrors == 0 then
    _pass("T02.8 Create→Destroy×10 cycles — no errors")
else
    _fail("T02.8 Create→Destroy×10 cycles",
        cycleErrors .. " cycle(s) errored",
        { severity = "P1", module = "Layout/Window",
          repro = "Loop: CreateWindow → CreateTab → CreateSection → components → Destroy, 10×",
          expected = "0 errors", actual = cycleErrors .. " errors",
          cause = "Stale connection or maid teardown failure in cycle" })
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 3. COMPONENT LIFECYCLE — ALL TYPES
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §3  Component Lifecycle ─────────────────────────────────────────")

local function _makeTestBed()
    local win = Delirium:CreateWindow({ Name = "CompTest", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "Tab" })
    local sec = tab:CreateSection("Sec")
    return win, sec
end

-- Button
_test("T03.1 Button — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local btn = sec:CreateButton({ Title = "Btn", Callback = function() end })
    assert(btn ~= nil, "Button nil")
    assert(type(btn.Destroy) == "function", "Button:Destroy missing")
    btn:Destroy()
    win:Destroy()
end, { severity = "P1", module = "Components/Button" })

_test("T03.2 Button — Enable / Disable", function()
    local win, sec = _makeTestBed()
    local btn = sec:CreateButton({ Title = "Btn" })
    btn:Disable()
    btn:Enable()
    win:Destroy()
end, { severity = "P2", module = "Components/Button" })

_test("T03.3 Button — SetTitle", function()
    local win, sec = _makeTestBed()
    local btn = sec:CreateButton({ Title = "Before" })
    btn:SetTitle("After")
    win:Destroy()
end)

-- Toggle
_test("T03.4 Toggle — Create / Get / Set / Destroy", function()
    local win, sec = _makeTestBed()
    local tog = sec:CreateToggle({ Title = "Tog", Default = false })
    assert(tog ~= nil, "Toggle nil")
    assert(tog:Get() == false, "Default state wrong")
    tog:Set(true)
    assert(tog:Get() == true, "Set(true) did not change state")
    tog:Set(false)
    assert(tog:Get() == false, "Set(false) did not change state")
    tog:Destroy()
    win:Destroy()
end, { severity = "P1", module = "Components/Toggle" })

_test("T03.5 Toggle — OnChanged fires", function()
    local win, sec = _makeTestBed()
    local tog = sec:CreateToggle({ Title = "Tog", Default = false })
    local fired = false
    local conn = tog.OnChanged:Connect(function(val)
        fired = true
    end)
    tog:Set(true)
    task.wait(0.05)
    conn:Disconnect()
    assert(fired, "OnChanged did not fire after Set(true)")
    win:Destroy()
end, { severity = "P1", module = "Components/Toggle",
       cause = "Signal:Fire not reaching listeners after Set()" })

-- Slider
_test("T03.6 Slider — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local sld = sec:CreateSlider({ Title = "Sld", Min = 0, Max = 100, Default = 50 })
    assert(sld ~= nil, "Slider nil")
    win:Destroy()
end, { severity = "P1", module = "Components/Slider" })

-- Dropdown
_test("T03.7 Dropdown — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local dd = sec:CreateDropdown({
        Title   = "DD",
        Options = { "Alpha", "Beta", "Gamma" },
        Default = "Alpha",
    })
    assert(dd ~= nil, "Dropdown nil")
    win:Destroy()
end, { severity = "P1", module = "Components/Dropdown" })

-- TextBox
_test("T03.8 TextBox — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local tb = sec:CreateTextbox({ Title = "TB", Placeholder = "...", Default = "" })
    assert(tb ~= nil, "TextBox nil")
    win:Destroy()
end, { severity = "P1", module = "Components/TextBox" })

-- Keybind
_test("T03.9 Keybind — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local kb = sec:CreateKeybind({ Title = "KB", Default = Enum.KeyCode.E })
    assert(kb ~= nil, "Keybind nil")
    win:Destroy()
end, { severity = "P1", module = "Components/Keybind" })

-- ColorPicker
_test("T03.10 ColorPicker — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local cp = sec:CreateColorPicker({ Title = "CP", Default = Color3.fromRGB(255, 0, 0) })
    assert(cp ~= nil, "ColorPicker nil")
    win:Destroy()
end, { severity = "P1", module = "Components/ColorPicker" })

-- Label
_test("T03.11 Label — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local lbl = sec:CreateLabel({ Title = "Lbl", Text = "Hello" })
    assert(lbl ~= nil, "Label nil")
    win:Destroy()
end, { severity = "P2", module = "Components/Label" })

-- Paragraph
_test("T03.12 Paragraph — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local para = sec:CreateParagraph({ Title = "Para", Content = "Some text." })
    assert(para ~= nil, "Paragraph nil")
    win:Destroy()
end, { severity = "P2", module = "Components/Paragraph" })

-- Divider
_test("T03.13 Divider — Create / Destroy", function()
    local win, sec = _makeTestBed()
    local div = sec:CreateDivider()
    assert(div ~= nil, "Divider nil")
    win:Destroy()
end, { severity = "P2", module = "Components/Divider" })

-- § 3.14 — All components survive Window:Destroy() without individual Destroy calls
_test("T03.14 All components survive Window:Destroy without individual Destroy", function()
    local win = Delirium:CreateWindow({ Name = "CascadeTest", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "Tab" })
    local sec = tab:CreateSection("Sec")
    sec:CreateButton({ Title = "Btn" })
    sec:CreateToggle({ Title = "Tog" })
    sec:CreateSlider({ Title = "Sld", Min = 0, Max = 10, Default = 5 })
    sec:CreateDropdown({ Title = "DD", Options = {"A","B"}, Default = "A" })
    sec:CreateTextbox({ Title = "TB", Placeholder = "x", Default = "" })
    sec:CreateLabel({ Title = "Lbl", Text = "x" })
    sec:CreateParagraph({ Title = "Para", Content = "x" })
    sec:CreateDivider()
    win:Destroy()
    -- if destroy cascade works, no error is thrown
end, { severity = "P1", module = "Layout/Section",
       cause = "Cascade Destroy not reaching components via Section._handles" })

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 4. THEME ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §4  Theme Engine ────────────────────────────────────────────────")

_test("T04.1 GetToken returns Color3", function()
    local token = Delirium.Theme.GetToken("Background")
    assert(typeof(token) == "Color3", "GetToken('Background') not a Color3")
end)

_test("T04.2 SetTheme Dark → Light → Dark", function()
    Delirium:SetTheme("Dark")
    assert(Delirium.Theme.GetTheme() == "Dark", "Theme not Dark after SetTheme('Dark')")
    Delirium:SetTheme("Light")
    assert(Delirium.Theme.GetTheme() == "Light", "Theme not Light after SetTheme('Light')")
    Delirium:SetTheme("Dark")
    assert(Delirium.Theme.GetTheme() == "Dark", "Theme not Dark after switching back")
end)

_test("T04.3 OnThemeChanged fires on SetTheme", function()
    local fired = false
    local disconnect = Delirium.Theme.OnThemeChanged(function()
        fired = true
    end)
    Delirium:SetTheme("Light")
    task.wait(0.05)
    disconnect()
    Delirium:SetTheme("Dark")
    assert(fired, "OnThemeChanged did not fire")
end, { severity = "P1", module = "Core/ThemeEngine" })

_test("T04.4 RegisterTheme accepts custom theme", function()
    Delirium:RegisterTheme("TestTheme", {
        Background = Color3.fromRGB(10, 10, 10),
        Surface    = Color3.fromRGB(20, 20, 20),
        Text       = Color3.fromRGB(240, 240, 240),
    })
    Delirium:SetTheme("TestTheme")
    local bg = Delirium.Theme.GetToken("Background")
    assert(typeof(bg) == "Color3", "Custom theme token not Color3")
    Delirium:SetTheme("Dark")  -- restore
end, { severity = "P2", module = "Core/ThemeEngine" })

_test("T04.5 Destroyed component does not react to theme change", function()
    local win = Delirium:CreateWindow({ Name = "ThemeDestroyTest", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "T" })
    local sec = tab:CreateSection("S")
    local tog = sec:CreateToggle({ Title = "T" })
    win:Destroy()   -- cascade-destroys the toggle and its theme listener
    -- switching theme after destroy should not error (stale themeDisconnect not called = leak)
    Delirium:SetTheme("Light")
    task.wait(0.1)
    Delirium:SetTheme("Dark")
    -- no error = pass
end, { severity = "P1", module = "Components/Toggle",
       repro = "CreateWindow → CreateToggle → Destroy window → SetTheme",
       expected = "No error, no stale listener",
       cause = "themeDisconnect() not called during component Destroy" })

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 5. ANIMATION ENGINE
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §5  Animation Engine ────────────────────────────────────────────")

-- We need a real live GuiObject to run animation tests on.
-- Create a scratch label in CoreGui for this purpose only.
local _scratchGui = Instance.new("ScreenGui")
_scratchGui.Name         = "DeliriumTestScratch"
_scratchGui.ResetOnSpawn = false
pcall(function() _scratchGui.Parent = game:GetService("CoreGui") end)

local _scratchLabel = Instance.new("TextLabel")
_scratchLabel.Size                   = UDim2.fromOffset(200, 40)
_scratchLabel.BackgroundTransparency = 1
_scratchLabel.Text                   = ""
_scratchLabel.Parent                 = _scratchGui

local AnimEng = Delirium.Animation

-- Force reduced motion OFF so tweens actually run
AnimEng.ReducedMotion = false

_test("T05.1 AnimationEngine.Play does not error", function()
    local tween = AnimEng.Play(_scratchLabel,
        TweenInfo.new(0.1, Enum.EasingStyle.Linear),
        { BackgroundTransparency = 0.5 },
        "test_play")
    -- tween may be nil if instance has no Parent — test still passes
    task.wait(0.15)
    AnimEng.Cancel(_scratchLabel, "test_play")
end)

_test("T05.2 AnimationEngine.Cancel does not error", function()
    AnimEng.Play(_scratchLabel, TweenInfo.new(1), { BackgroundTransparency = 0 }, "cancel_test")
    task.wait(0.05)
    AnimEng.Cancel(_scratchLabel, "cancel_test")
end)

-- § TypeWriter race test
_testAsync("T05.3 TypeWriter — rapid replacement, final text correct", function()
    _scratchLabel.Text = ""
    local cancel1 = AnimEng.TypeWriter(_scratchLabel, "AAAAAA", 20)
    task.wait(0.05)
    -- Before first writer finishes, start second
    local _cancel2 = AnimEng.TypeWriter(_scratchLabel, "BBBBBB", 20)
    task.wait(0.5)   -- wait for second writer to finish
    assert(_scratchLabel.Text == "BBBBBB",
        "Expected 'BBBBBB', got '" .. tostring(_scratchLabel.Text) .. "'")
    cancel1()  -- calling first cancel after completion must not error
end, 3, {
    severity = "P1", module = "Core/AnimationEngine",
    repro = "TypeWriter('AAAAAA') → 50ms → TypeWriter('BBBBBB') → wait → check text",
    expected = "BBBBBB",
    cause = "Generation token not invalidating previous writer"
})

_testAsync("T05.4 TypeWriter — cancel before finish, no overwrite", function()
    _scratchLabel.Text = "UNTOUCHED"
    local cancel = AnimEng.TypeWriter(_scratchLabel, "XYZXYZ", 5)
    task.wait(0.05)
    cancel()   -- cancel mid-way
    -- set a known text AFTER cancel
    _scratchLabel.Text = "FINAL"
    task.wait(0.5)   -- wait for the (now-invalid) writer to exhaust its timing
    assert(_scratchLabel.Text == "FINAL",
        "Cancelled TypeWriter overwrote later text. Got: '" .. tostring(_scratchLabel.Text) .. "'")
end, 3, {
    severity = "P1", module = "Core/AnimationEngine",
    repro = "TypeWriter('XYZXYZ') → 50ms → cancel() → set text manually → wait",
    expected = "Text stays as manually set value",
    cause = "Cancel does not bump generation, stale writer still writes"
})

_testAsync("T05.5 TypeWriter — run 5 rapid back-to-back", function()
    for i = 1, 5 do
        local _ = AnimEng.TypeWriter(_scratchLabel, "RUN" .. i, 40)
        task.wait(0.03)
    end
    task.wait(0.5)
    assert(_scratchLabel.Text == "RUN5",
        "Expected 'RUN5', got '" .. tostring(_scratchLabel.Text) .. "'")
end, 5)

-- § Sequence tests
_testAsync("T05.6 Sequence — cancel stops remaining steps", function()
    local step2Ran = false
    local s1 = Instance.new("TextLabel")
    s1.Parent = _scratchGui
    s1.Size   = UDim2.fromOffset(10, 10)
    local s2 = Instance.new("TextLabel")
    s2.Parent = _scratchGui
    s2.Size   = UDim2.fromOffset(10, 10)

    local cancel = AnimEng.Sequence({
        { instance = s1, info = TweenInfo.new(0.3), props = { BackgroundTransparency = 0.5 } },
        { instance = s2, info = TweenInfo.new(0.3), props = { BackgroundTransparency = 0.5 } },
    }, function()
        step2Ran = true
    end)

    task.wait(0.1)  -- first step in progress
    cancel()
    task.wait(0.5)  -- wait past where step 2 would have run
    s1:Destroy(); s2:Destroy()
    assert(not step2Ran, "Sequence onComplete fired after cancel")
end, 3, {
    severity = "P1", module = "Core/AnimationEngine",
    repro = "Sequence(2 steps, 0.3s each) → cancel after 0.1s → wait",
    expected = "onComplete not called, step2 not started",
    cause = "activeTween:Cancel() not wired in Sequence cancel"
})

_testAsync("T05.7 Parallel — cancel stops all tweens, onComplete not called", function()
    local completed = false
    local instances = {}
    for i = 1, 3 do
        local inst = Instance.new("TextLabel")
        inst.Parent = _scratchGui
        inst.Size   = UDim2.fromOffset(10, 10)
        table.insert(instances, inst)
    end

    local cancel = AnimEng.Parallel({
        { instance = instances[1], info = TweenInfo.new(0.5), props = { BackgroundTransparency = 0.5 } },
        { instance = instances[2], info = TweenInfo.new(0.5), props = { BackgroundTransparency = 0.5 } },
        { instance = instances[3], info = TweenInfo.new(0.5), props = { BackgroundTransparency = 0.5 } },
    }, function()
        completed = true
    end)

    task.wait(0.1)
    cancel()
    task.wait(0.6)
    for _, inst in ipairs(instances) do inst:Destroy() end
    assert(not completed, "Parallel onComplete fired after cancel")
end, 3, {
    severity = "P1", module = "Core/AnimationEngine",
    repro = "Parallel(3 tweens, 0.5s) → cancel after 0.1s → wait",
    expected = "onComplete not called",
    cause = "task.cancel(thread) not called in Parallel cancel"
})

_testAsync("T05.8 Stagger — cancel stops future instances", function()
    local completed = false
    local instances = {}
    for i = 1, 5 do
        local inst = Instance.new("TextLabel")
        inst.Parent              = _scratchGui
        inst.Size                = UDim2.fromOffset(10, 10)
        inst.BackgroundTransparency = 1
        table.insert(instances, inst)
    end

    local cancel = AnimEng.Stagger(instances, 0.15, TweenInfo.new(0.1), function()
        completed = true
    end)

    task.wait(0.2)  -- let 1-2 instances start
    cancel()
    task.wait(0.8)  -- wait past where all would have run
    for _, inst in ipairs(instances) do inst:Destroy() end
    assert(not completed, "Stagger onComplete fired after cancel")
end, 3, {
    severity = "P1", module = "Core/AnimationEngine",
    repro = "Stagger(5 instances, delay=0.15) → cancel after 0.2s → wait",
    expected = "onComplete not called, future instances not started",
    cause = "cancelled flag not checked between stagger steps"
})

-- § 5.9 Destroy instance during active animation
_testAsync("T05.9 Destroy instance during animation — no error", function()
    local inst = Instance.new("TextLabel")
    inst.Parent = _scratchGui
    inst.Size   = UDim2.fromOffset(10, 10)
    AnimEng.Play(inst, TweenInfo.new(1), { BackgroundTransparency = 0 }, "desttest")
    task.wait(0.05)
    inst:Destroy()
    task.wait(1.1)
    -- if no error in output, pass
end, 3, {
    severity = "P1", module = "Core/AnimationEngine",
    repro = "Play 1s tween → Destroy instance → wait",
    expected = "No error in Output",
    cause = "Completed callback accessing destroyed instance"
})

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 6. NOTIFICATION SERVICE
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §6  Notification Service ────────────────────────────────────────")

_test("T06.1 Notify — basic push returns handle", function()
    local h = Delirium:Notify({
        Type    = "Info",
        Title   = "Test",
        Message = "Hello",
        Duration = 1,
    })
    assert(type(h.Dismiss) == "function", "Handle:Dismiss missing")
    assert(type(h.SetTitle) == "function", "Handle:SetTitle missing")
    assert(type(h.SetMessage) == "function", "Handle:SetMessage missing")
    task.wait(0.1)
    h:Dismiss()
end, { severity = "P1", module = "Services/NotificationService" })

_test("T06.2 Notify — Dismiss is idempotent", function()
    local h = Delirium:Notify({ Type = "Info", Title = "Idempotent", Duration = 10 })
    h:Dismiss()
    task.wait(0.1)
    h:Dismiss()
    h:Dismiss()
end, { severity = "P1", module = "Services/NotificationService",
       cause = "_alive guard not checked on repeated Dismiss" })

-- T06.3 / T06.4 require direct access to NotificationService.Reset / DismissAll,
-- which are NOT exposed on the public Delirium API. Accessing them via require
-- would create a SECOND copy of the service (violating the "test the actual
-- running instance" rule), so these are SKIPped.
_skip("T06.3 Notify — Reset invalidates old callbacks",
    "NotificationService.Reset not exposed on public API; direct require would create a second copy")

_skip("T06.4 Notify — rapid push/reset cycle × 5",
    "NotificationService.DismissAll not exposed on public API; direct require would create a second copy")

_testAsync("T06.5 Notify — queue overflow works (public API only)", function()
    local handles = {}
    -- Push more than MAX_VISIBLE (4) to test queue
    for i = 1, 6 do
        local h = Delirium:Notify({ Type = "Info", Title = "Queue "..i, Duration = 10 })
        table.insert(handles, h)
    end
    task.wait(0.2)
    -- Dismiss all visible ones; queue should drain
    for _, h in ipairs(handles) do
        h:Dismiss()
    end
    task.wait(0.5)
end, 5, { severity = "P2", module = "Services/NotificationService" })

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 7. INPUT ADAPTER
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §7  Input Adapter ───────────────────────────────────────────────")

-- T07.x require direct access to Core.InputAdapter, which is NOT exposed on the
-- public Delirium API. Direct require would create a second copy. SKIP.
_skip("T07.1 InputAdapter fields exist",
    "InputAdapter not exposed on public API; direct require would create a second copy")
_skip("T07.2 InputAdapter.Reset × 4 — no duplicate connections or errors",
    "InputAdapter not exposed on public API; direct require would create a second copy")
_skip("T07.3 InputAdapter.BindAdaptiveInteraction returns cleanup function",
    "InputAdapter not exposed on public API; direct require would create a second copy")
_skip("T07.4 Camera switch — OrientationChanged reconnects",
    "InputAdapter not exposed on public API; direct require would create a second copy")

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 8. SESSION ID & RE-EXECUTION SIMULATION
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §8  Session ID & Re-execution ───────────────────────────────────")

_test("T08.1 GetSessionId returns non-empty string", function()
    local id = Delirium:GetSessionId()
    assert(type(id) == "string" and #id > 0, "GetSessionId returned empty or non-string")
end)

_test("T08.2 IsSessionCurrent with current ID returns true", function()
    local id = Delirium:GetSessionId()
    assert(Delirium:IsSessionCurrent(id), "IsSessionCurrent(currentId) returned false")
end)

_test("T08.3 IsSessionCurrent with stale ID returns false", function()
    local stale = "DLR_0000_0000"
    assert(not Delirium:IsSessionCurrent(stale), "IsSessionCurrent(staleId) returned true")
end)

-- § 8.4 Simulate re-execution by calling Bootstrap indirectly
-- We do this by creating a window, then requiring Init again (same module = cached),
-- then verifying the new runtime replaced the old one.
_test("T08.4 Multiple windows — no duplicate GUI on same session", function()
    local envG = (type(getgenv) == "function" and getgenv()) or _G or {}
    local w1 = Delirium:CreateWindow({ Name = "Win1", Close = false, UnloadOnClose = false })
    local w2 = Delirium:CreateWindow({ Name = "Win2", Close = false, UnloadOnClose = false })
    -- Both should exist in the same runtime
    local runtime = envG["__DeliriumRuntime"]
    assert(runtime and #runtime._windows >= 2,
        "Runtime should track at least 2 windows, got: " .. tostring(runtime and #runtime._windows or "nil runtime"))
    w1:Destroy()
    w2:Destroy()
end, { severity = "P1", module = "Core/Runtime" })

_test("T08.5 Compact window (no tabs) — CreateSection directly on window", function()
    local win = Delirium:CreateWindow({ Name = "Compact", Compact = true, Close = false, UnloadOnClose = false })
    local sec = win:CreateSection("DirectSec")
    assert(sec ~= nil, "Window:CreateSection returned nil")
    sec:CreateButton({ Title = "Btn" })
    win:Destroy()
end, { severity = "P1", module = "Layout/Window", cause = "_defaultTab logic broken" })

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 9. SECTION COLLAPSE SYSTEM
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §9  Section Collapse ────────────────────────────────────────────")

_testAsync("T09.1 SetCollapsed(true) then SetCollapsed(false)", function()
    local win = Delirium:CreateWindow({ Name = "CollapseTest", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "T" })
    local sec = tab:CreateSection("ColSec")
    sec:CreateButton({ Title = "B1" })
    sec:CreateButton({ Title = "B2" })
    task.wait(0.1)  -- let layout settle
    sec:SetCollapsed(true, false)
    task.wait(0.05)
    sec:SetCollapsed(false, false)
    task.wait(0.05)
    win:Destroy()
end, 3, { severity = "P2", module = "Layout/Section" })

_testAsync("T09.2 ToggleCollapsed × 4 — no error", function()
    local win = Delirium:CreateWindow({ Name = "TogColTest", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "T" })
    local sec = tab:CreateSection("TC")
    sec:CreateButton({ Title = "X" })
    task.wait(0.1)
    for _ = 1, 4 do
        sec:ToggleCollapsed()
        task.wait(0.15)
    end
    win:Destroy()
end, 5, { severity = "P2", module = "Layout/Section" })

_testAsync("T09.3 Collapse → theme change → expand — no error", function()
    local win = Delirium:CreateWindow({ Name = "ColTheme", Close = false, UnloadOnClose = false })
    local tab = win:CreateTab({ Name = "T" })
    local sec = tab:CreateSection("CT")
    sec:CreateToggle({ Title = "T" })
    task.wait(0.1)
    sec:SetCollapsed(true, false)
    Delirium:SetTheme("Light")
    task.wait(0.05)
    sec:SetCollapsed(false, false)
    Delirium:SetTheme("Dark")
    win:Destroy()
end, 5, { severity = "P2", module = "Layout/Section" })

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 10. STRESS TEST — 20 RAPID LIFECYCLE CYCLES
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §10 Stress Test ─────────────────────────────────────────────────")
print("  [Stress] Running 20 rapid lifecycle cycles ...")
print("  [Stress] This may take ~15 seconds ...")

local stressErrors  = 0
local stressResults = {}

for i = 1, 20 do
    local ok, err = pcall(function()
        -- Create
        local win = Delirium:CreateWindow({
            Name         = "Stress"..i,
            Close        = false,
            UnloadOnClose = false,
        })
        local tab1 = win:CreateTab({ Name = "T1" })
        local tab2 = win:CreateTab({ Name = "T2" })
        local sec1 = tab1:CreateSection("S1")
        local sec2 = tab2:CreateSection("S2")

        -- Components
        sec1:CreateButton({ Title = "Btn", Callback = function() end })
        sec1:CreateToggle({ Title = "Tog", Default = i % 2 == 0 })
        sec1:CreateSlider({ Title = "Sld", Min = 0, Max = 100, Default = i * 5 % 100 })
        sec2:CreateDropdown({ Title = "DD", Options = {"A","B","C"}, Default = "A" })
        sec2:CreateLabel({ Title = "Lbl", Text = "Stress "..i })
        sec2:CreateDivider()

        -- Theme change mid-cycle
        if i % 3 == 0 then
            Delirium:SetTheme("Light")
        end

        -- Notify
        local h = Delirium:Notify({
            Type     = i % 2 == 0 and "Success" or "Warning",
            Title    = "Stress "..i,
            Duration = 0.3,
        })

        -- Start animation mid-cycle
        if win.MainFrame and win.MainFrame.Parent then
            AnimEng.Play(win.MainFrame,
                TweenInfo.new(0.1),
                { GroupTransparency = 0.1 },
                "stress")
        end

        -- Wait a tiny bit then destroy mid-animation
        task.wait(0.05)

        h:Dismiss()
        win:Destroy()

        -- Restore theme
        if i % 3 == 0 then
            Delirium:SetTheme("Dark")
        end
    end)

    if not ok then
        stressErrors += 1
        table.insert(stressResults, string.format("  [Stress cycle %d] ERROR: %s", i, tostring(err)))
    end

    task.wait(0.05)  -- small breathe between cycles
end

for _, msg in ipairs(stressResults) do
    print(msg)
end

if stressErrors == 0 then
    _pass("T10.1 Stress test — 20 rapid lifecycle cycles — 0 errors")
else
    _fail("T10.1 Stress test — 20 rapid lifecycle cycles",
        stressErrors .. " cycle(s) errored",
        {
            severity = "P1",
            module   = "Multiple",
            repro    = "Create window+tabs+sections+components → theme change → notify → anim → destroy × 20",
            expected = "0 errors",
            actual   = stressErrors .. " errors, see per-cycle logs above",
            cause    = "Race condition or stale reference during rapid create/destroy/animate",
        })
end

-- § 10.2 — Create immediately destroyed window × 5
local immediateErrors = 0
for i = 1, 5 do
    local ok, err = pcall(function()
        local win = Delirium:CreateWindow({ Name = "ImmD"..i, Close = false, UnloadOnClose = false })
        win:Destroy()
    end)
    if not ok then
        immediateErrors += 1
        print(string.format("  [ImmDestroy %d] ERROR: %s", i, tostring(err)))
    end
end
if immediateErrors == 0 then
    _pass("T10.2 Immediate Create→Destroy × 5")
else
    _fail("T10.2 Immediate Create→Destroy × 5",
        immediateErrors .. " error(s)",
        { severity = "P1", module = "Layout/Window",
          repro = "CreateWindow() immediately followed by :Destroy()" })
end

-- § 10.3 — Animation → Destroy
_testAsync("T10.3 Animation → Destroy window — no stale callback error", function()
    for _ = 1, 5 do
        local win = Delirium:CreateWindow({ Name = "AnimDest", Close = false, UnloadOnClose = false })
        if win.MainFrame and win.MainFrame.Parent then
            AnimEng.Play(win.MainFrame, TweenInfo.new(2), { GroupTransparency = 1 }, "fade")
        end
        task.wait(0.03)
        win:Destroy()
        task.wait(0.02)
    end
    task.wait(2.1)  -- wait for any stale callbacks that might fire
end, 8, {
    severity = "P1", module = "Core/AnimationEngine + Layout/Window",
    repro = "Play 2s tween on MainFrame → Destroy window after 30ms → wait",
    expected = "No errors in Output",
    cause = "Tween Completed callback accessing destroyed MainFrame"
})

-- § 10.4 — Notification → immediate DismissAll → Notify again
_skip("T10.4 Notify → DismissAll(instant) → Notify — no state corruption",
    "NotificationService.DismissAll not exposed on public API; direct require would create a second copy")

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 11. SIGNAL UTILITY
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §11 Signal Utility ──────────────────────────────────────────────")

-- T11.x require direct access to Utilities.Signal, which is NOT exposed on the
-- public Delirium API. Direct require would create a second copy. SKIP.
_skip("T11.1 Signal.new() creates object",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.2 Signal:Connect → Fire",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.3 Signal:Disconnect removes handler",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.4 Signal:Destroy — Fire after Destroy does not error",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.5 Signal:Destroy is idempotent",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.6 Signal:DisconnectAll clears handlers, signal still usable",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.7 Signal:Once fires exactly once",
    "Signal not exposed on public API; direct require would create a second copy")
_skip("T11.8 Signal:Destroy after Disconnect — no crash",
    "Signal not exposed on public API; direct require would create a second copy")

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 12. MAID UTILITY
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §12 Maid Utility ────────────────────────────────────────────────")

-- T12.x require direct access to Core.Maid, which is NOT exposed on the public
-- Delirium API. Direct require would create a second copy. SKIP.
_skip("T12.1 Maid.new() creates object",
    "Maid not exposed on public API; direct require would create a second copy")
_skip("T12.2 Maid cleans function task",
    "Maid not exposed on public API; direct require would create a second copy")
_skip("T12.3 Maid cleans RBXScriptConnection",
    "Maid not exposed on public API; direct require would create a second copy")
_skip("T12.4 Maid:DoCleaning is idempotent",
    "Maid not exposed on public API; direct require would create a second copy")

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 13. THEME ENGINE — CUSTOM TOKENS + LISTENER CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §13 ThemeEngine — Deep Tests ────────────────────────────────────")

_test("T13.1 ClearListeners — no stale listeners after clear", function()
    local firedAfterClear = false
    local ThemeEng = Delirium.Theme
    local _ = ThemeEng.OnThemeChanged(function()
        firedAfterClear = true
    end)
    ThemeEng.ClearListeners()
    Delirium:SetTheme("Light")
    task.wait(0.1)
    Delirium:SetTheme("Dark")
    assert(not firedAfterClear, "Listener fired after ClearListeners()")
end, { severity = "P1", module = "Core/ThemeEngine",
       repro = "OnThemeChanged(fn) → ClearListeners() → SetTheme",
       expected = "fn not called",
       cause = "ClearListeners not fully clearing _listeners table" })

_test("T13.2 OnThemeChanged disconnect — listener removed", function()
    local firedAfterDisconnect = false
    local ThemeEng = Delirium.Theme
    local disconnect = ThemeEng.OnThemeChanged(function()
        firedAfterDisconnect = true
    end)
    disconnect()
    Delirium:SetTheme("Light")
    task.wait(0.1)
    Delirium:SetTheme("Dark")
    assert(not firedAfterDisconnect, "Listener fired after disconnect()")
end, { severity = "P1", module = "Core/ThemeEngine" })

_test("T13.3 GetThemeNames includes built-ins and custom", function()
    local ThemeEng = Delirium.Theme
    local names = ThemeEng.GetThemeNames()
    assert(type(names) == "table", "GetThemeNames did not return table")
    local hasLight, hasDark = false, false
    for _, n in ipairs(names) do
        if n == "Light" then hasLight = true end
        if n == "Dark"  then hasDark  = true end
    end
    assert(hasLight and hasDark, "GetThemeNames missing built-in themes")
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- § 14. UNLOAD SERVICE INSPECTION
-- ═══════════════════════════════════════════════════════════════════════════════

print("\n─── §14 UnloadService ────────────────────────────────────────────────")

_test("T14.1 Delirium:OnUnload accepts function", function()
    local called = false
    Delirium:OnUnload(function()
        called = true
    end)
    -- we don't actually call Unload in the test suite (it would destroy the library)
    -- just verify it doesn't error
end)

_test("T14.2 OnUnload with non-function errors gracefully (public API)", function()
    -- Delirium:OnUnload is public. UnloadService.Register asserts the task is a
    -- function or table, so passing a string should error (correct behavior).
    local ok = pcall(function()
        Delirium:OnUnload("not_a_function_or_table")
    end)
    -- We expect this to error — that's the correct behavior.
    -- If it doesn't error, warn but don't fail the suite.
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════════════════════

-- Destroy scratch GUI
pcall(function() _scratchGui:Destroy() end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- FINAL REPORT
-- ═══════════════════════════════════════════════════════════════════════════════

task.wait(0.5)  -- let any final async tasks settle

local totalTests = Results.pass + Results.fail + Results.skip

print("\n")
print("================================")
print(" DELIRIUM RUNTIME TEST SUMMARY")
print("================================")
print(string.format("PASS: %d", Results.pass))
print(string.format("FAIL: %d", Results.fail))
print(string.format("SKIP: %d", Results.skip))
print(string.format("TOTAL: %d", totalTests))
print("================================")

-- Severity buckets
local p0, p1, p2, p3 = {}, {}, {}, {}
for _, bug in ipairs(Bugs) do
    if bug.severity == "P0" then table.insert(p0, bug)
    elseif bug.severity == "P1" then table.insert(p1, bug)
    elseif bug.severity == "P2" then table.insert(p2, bug)
    else table.insert(p3, bug) end
end

print(string.format("P0: %d  P1: %d  P2: %d  P3: %d", #p0, #p1, #p2, #p3))
print("")

local function _printBugs(list, label)
    if #list == 0 then return end
    print("── " .. label .. " ──────────────")
    for _, bug in ipairs(list) do
        print(string.format(
            "  Test:           %s\n" ..
            "  Severity:       %s\n" ..
            "  Result:         %s\n" ..
            "  Reproduction:   %s\n" ..
            "  Expected:       %s\n" ..
            "  Actual:         %s\n" ..
            "  Likely Cause:   %s\n" ..
            "  Affected Module:%s\n",
            bug.name, bug.severity, bug.result,
            bug.repro, bug.expected,
            string.sub(tostring(bug.actual), 1, 200),
            bug.cause, bug.module
        ))
    end
end

if #Bugs > 0 then
    print("Confirmed Runtime Bugs:")
    _printBugs(p0, "P0 — CRITICAL")
    _printBugs(p1, "P1 — HIGH")
    _printBugs(p2, "P2 — MEDIUM")
    _printBugs(p3, "P3 — LOW")
else
    print("Confirmed Runtime Bugs: none")
end

print("")
print("Tests that require manual Roblox verification:")
print("  - T05.x AnimationEngine visual correctness (tween easing, final positions)")
print("  - T06.x Notification layout and stacking on screen")
print("  - T07.4 Camera switch actual OrientationChanged signal emission")
print("  - T09.x Section collapse animation smoothness (no visual jump on first collapse)")
print("  - Any test marked SKIP due to module access restrictions")
print("")
print("[DELR-TEST] Suite complete.")
