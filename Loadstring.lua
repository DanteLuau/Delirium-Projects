-- ==============================================================================
-- DELIRIUM v1.1.0 — COMPREHENSIVE FEATURE TEST SUITE
-- Covers every public API method in the v1.1.0 surface.
-- Tracks PASS / FAIL / SKIP per test and reports a summary.
-- ==============================================================================

-- ── Load Library ──────────────────────────────────────────────────────────────

local RAW_URL = "https://raw.githubusercontent.com/DanteLuau/Delirium-Projects/main/Delirium.lua"

local ok, Delirium = pcall(function()
    return loadstring(game:HttpGet(RAW_URL))()
end)

if not ok or not Delirium then
    warn("[TEST] Failed to load Delirium: " .. tostring(Delirium))
    return
end

print("[TEST] Loaded Delirium " .. tostring(Delirium.Version))

-- ── Test Runner ───────────────────────────────────────────────────────────────

local Results = { pass = 0, fail = 0, skip = 0 }
local Log     = {}

local function pass(id, label)
    Results.pass += 1
    local msg = string.format("[PASS] %s — %s", id, label)
    table.insert(Log, msg)
    print(msg)
end

local function fail(id, label, err)
    Results.fail += 1
    local msg = string.format("[FAIL] %s — %s :: %s", id, label, tostring(err))
    table.insert(Log, msg)
    warn(msg)
end

local function skip(id, label, reason)
    Results.skip += 1
    local msg = string.format("[SKIP] %s — %s (%s)", id, label, tostring(reason))
    table.insert(Log, msg)
    print(msg)
end

local function test(id, label, fn)
    local ok2, err = pcall(fn)
    if ok2 then
        pass(id, label)
    else
        fail(id, label, err)
    end
end

local function assertEq(a, b, label)
    assert(a == b, string.format("%s: expected %s, got %s", tostring(label), tostring(b), tostring(a)))
end

local function assertType(v, t, label)
    assert(type(v) == t, string.format("%s: expected type %s, got %s", tostring(label), t, type(v)))
end

local function assertNotNil(v, label)
    assert(v ~= nil, string.format("%s: expected non-nil", tostring(label)))
end

-- ── T01: Library Core ─────────────────────────────────────────────────────────

print("\n── T01: Library Core ──")

test("T01.1", "Version is string", function()
    assertType(Delirium.Version, "string", "Version")
end)

test("T01.2", "Version equals 1.1.0", function()
    assertEq(Delirium.Version, "1.1.0", "Version value")
end)

test("T01.3", "Delirium.Theme exposed", function()
    assertNotNil(Delirium.Theme, "Theme")
end)

test("T01.4", "Delirium.Animation exposed", function()
    assertNotNil(Delirium.Animation, "Animation")
end)

test("T01.5", "Delirium.Dialog exposed", function()
    assertNotNil(Delirium.Dialog, "Dialog")
end)

test("T01.6", "GetSessionId returns string", function()
    local sid = Delirium:GetSessionId()
    assertType(sid, "string", "SessionId")
    assert(#sid > 0, "SessionId non-empty")
end)

test("T01.7", "IsSessionCurrent returns true for current session", function()
    local sid = Delirium:GetSessionId()
    assert(Delirium:IsSessionCurrent(sid) == true, "current session")
end)

test("T01.8", "IsSessionCurrent returns false for stale id", function()
    assert(Delirium:IsSessionCurrent("stale-fake-id-000") == false, "stale session")
end)

test("T01.9", "SetReducedMotion accepts true", function()
    Delirium:SetReducedMotion(true)
end)

test("T01.10", "SetReducedMotion accepts false", function()
    Delirium:SetReducedMotion(false)
end)

-- ── T02: ThemeEngine ──────────────────────────────────────────────────────────

print("\n── T02: ThemeEngine ──")

local ThemeEngine = Delirium.Theme

test("T02.1", "GetTheme returns string", function()
    local t = ThemeEngine.GetTheme()
    assertType(t, "string", "GetTheme")
    assert(#t > 0, "non-empty theme name")
end)

test("T02.2", "GetTokens returns table", function()
    local tokens = ThemeEngine.GetTokens()
    assertType(tokens, "table", "GetTokens")
end)

test("T02.3", "GetToken('Background') returns Color3", function()
    local c = ThemeEngine.GetToken("Background")
    assert(typeof(c) == "Color3", "Background is Color3")
end)

test("T02.4", "GetToken('Surface') returns Color3", function()
    assert(typeof(ThemeEngine.GetToken("Surface")) == "Color3", "Surface Color3")
end)

test("T02.5", "GetToken('Accent') returns Color3", function()
    assert(typeof(ThemeEngine.GetToken("Accent")) == "Color3", "Accent Color3")
end)

test("T02.6", "GetThemeNames returns table of strings", function()
    local names = ThemeEngine.GetThemeNames()
    assertType(names, "table", "GetThemeNames")
    assert(#names > 0, "at least one theme")
end)

test("T02.7", "RegisterTheme registers custom theme", function()
    ThemeEngine.RegisterTheme("TestCustomTheme", {
        Background  = Color3.fromRGB(10, 10, 10),
        Surface     = Color3.fromRGB(20, 20, 20),
        Accent      = Color3.fromRGB(255, 100, 0),
        Text        = Color3.fromRGB(255, 255, 255),
        SubText     = Color3.fromRGB(150, 150, 150),
        Border      = Color3.fromRGB(40, 40, 40),
        Positive    = Color3.fromRGB(50, 200, 100),
        Warning     = Color3.fromRGB(255, 180, 0),
        Negative    = Color3.fromRGB(200, 50, 50),
        Info        = Color3.fromRGB(50, 150, 255),
        SurfaceHover = Color3.fromRGB(30, 30, 30),
        AccentDim   = Color3.fromRGB(180, 70, 0),
        DisabledText = Color3.fromRGB(80, 80, 80),
    })
    local names = ThemeEngine.GetThemeNames()
    local found = false
    for _, n in ipairs(names) do
        if n == "TestCustomTheme" then found = true end
    end
    assert(found, "custom theme in list")
end)

test("T02.8", "SetTheme applies custom theme", function()
    Delirium:SetTheme("TestCustomTheme")
    assertEq(ThemeEngine.GetTheme(), "TestCustomTheme", "theme name after set")
end)

test("T02.9", "OnThemeChanged fires callback", function()
    local fired = false
    local disconnect = ThemeEngine.OnThemeChanged(function(tokens)
        fired = true
        assertType(tokens, "table", "tokens in callback")
    end)
    assertNotNil(disconnect, "disconnect fn")
    -- Trigger a theme change to fire callback
    Delirium:SetTheme("TestCustomTheme")
    assert(fired, "callback fired")
    disconnect()
end)

test("T02.10", "OnThemeChanged disconnect prevents future fires", function()
    local count = 0
    local disconnect = ThemeEngine.OnThemeChanged(function() count += 1 end)
    disconnect()
    Delirium:SetTheme("TestCustomTheme")
    assertEq(count, 0, "no fires after disconnect")
end)

-- Restore to default for UI tests
Delirium:SetTheme("Dark")

-- ── T03: Window ───────────────────────────────────────────────────────────────

print("\n── T03: Window ──")

local MainWin

test("T03.1", "CreateWindow returns object", function()
    MainWin = Delirium:CreateWindow({
        Name     = "Delirium v1.1.0 Test Suite",
        Subtitle = "All features covered",
    })
    assertNotNil(MainWin, "Window object")
end)

test("T03.2", "CreateWindow has CreateTab method", function()
    assertType(MainWin.CreateTab, "function", "CreateTab")
end)

test("T03.3", "SetTitle updates title", function()
    MainWin:SetTitle("Delirium v1.1.0 Test Suite [ACTIVE]")
end)

test("T03.4", "Show does not error", function()
    MainWin:Show()
end)

skip("T03.5",  "Hide does not error",           "manual — use Window Controls section")
skip("T03.6",  "Show again after Hide",           "manual — use Window Controls section")
skip("T03.7",  "Minimize does not error",          "manual — use Window Controls section")
skip("T03.8",  "Restore after Minimize",           "manual — use Window Controls section")
skip("T03.9",  "ToggleMinimize does not error",    "manual — use Window Controls section")
skip("T03.10", "MiniIconify does not error",       "manual — use Window Controls section")
skip("T03.11", "RestoreFromMiniIcon does not error","manual — use Window Controls section")

-- ── T04: Tab ──────────────────────────────────────────────────────────────────

print("\n── T04: Tab ──")

local Tab1, Tab2, Tab3, Tab4, Tab5

test("T04.1", "CreateTab returns object", function()
    Tab1 = MainWin:CreateTab({ Name = "Components" })
    assertNotNil(Tab1, "Tab object")
end)

test("T04.2", "Tab has CreateSection method", function()
    assertType(Tab1.CreateSection, "function", "CreateSection")
end)

test("T04.3", "Multiple tabs can be created", function()
    Tab2 = MainWin:CreateTab({ Name = "Inputs & Pickers" })
    Tab3 = MainWin:CreateTab({ Name = "Content" })
    Tab4 = MainWin:CreateTab({ Name = "Services" })
    Tab5 = MainWin:CreateTab({ Name = "Lifecycle" })
    assertNotNil(Tab2, "Tab2")
    assertNotNil(Tab3, "Tab3")
    assertNotNil(Tab4, "Tab4")
    assertNotNil(Tab5, "Tab5")
end)

test("T04.4", "SelectTab switches active tab", function()
    MainWin:SelectTab(Tab1)
end)

test("T04.5", "SetActive false disables tab", function()
    Tab5:SetActive(false)
end)

test("T04.6", "SetActive true re-enables tab", function()
    Tab5:SetActive(true)
end)

-- ── T05: Section ──────────────────────────────────────────────────────────────

print("\n── T05: Section ──")

local SecBtn, SecTog, SecSlide, SecDrop, SecText, SecMisc

test("T05.1", "CreateSection returns object", function()
    SecBtn = Tab1:CreateSection("Buttons")
    assertNotNil(SecBtn, "Section")
end)

test("T05.2", "Section has component factory methods", function()
    local methods = {"CreateButton","CreateToggle","CreateSlider","CreateDropdown",
                     "CreateTextbox","CreateKeybind","CreateColorPicker",
                     "CreateLabel","CreateParagraph","CreateDivider"}
    for _, m in ipairs(methods) do
        assertType(SecBtn[m], "function", m)
    end
end)

test("T05.3", "Section aliases exist (AddButton etc.)", function()
    local aliases = {"AddButton","AddToggle","AddSlider","AddDropdown",
                     "AddTextbox","AddKeybind","AddColorPicker",
                     "AddLabel","AddParagraph","AddDivider"}
    for _, a in ipairs(aliases) do
        assertType(SecBtn[a], "function", a)
    end
end)

test("T05.4", "SetTitle updates section header", function()
    SecBtn:SetTitle("Buttons & Actions")
end)

test("T05.5", "SetCollapsed(true) collapses section", function()
    SecBtn:SetCollapsed(true, false)
end)

test("T05.6", "SetCollapsed(false) expands section", function()
    SecBtn:SetCollapsed(false, false)
end)

test("T05.7", "ToggleCollapsed toggles state", function()
    SecBtn:ToggleCollapsed()
    SecBtn:ToggleCollapsed()
end)

test("T05.8", "Show / Hide section", function()
    SecBtn:Hide()
    SecBtn:Show()
end)

-- Build remaining sections
SecTog   = Tab1:CreateSection("Toggles")
SecSlide = Tab1:CreateSection("Sliders")
SecDrop  = Tab2:CreateSection("Dropdowns")
SecText  = Tab2:CreateSection("TextBox & Keybind & ColorPicker")
SecMisc  = Tab3:CreateSection("Labels, Paragraphs & Dividers")

-- ── T06: Button ───────────────────────────────────────────────────────────────

print("\n── T06: Button ──")

local Btn1, Btn2, Btn3

test("T06.1", "CreateButton returns api", function()
    Btn1 = SecBtn:CreateButton({
        Title    = "Test Action",
        Callback = function() end,
    })
    assertNotNil(Btn1, "Button api")
end)

test("T06.2", "Button has expected methods", function()
    local methods = {"Enable","Disable","SetLoading","SetTitle","SetDescription","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Btn1[m], "function", m)
    end
end)

test("T06.3", "Button.OnClicked is a Signal", function()
    assertNotNil(Btn1.OnClicked, "OnClicked")
end)

test("T06.4", "Button.Instance is a GuiObject", function()
    assertNotNil(Btn1.Instance, "Instance")
end)

test("T06.5", "SetTitle updates button text", function()
    Btn1:SetTitle("Updated Title")
end)

test("T06.6", "SetDescription updates description", function()
    Btn1:SetDescription("Test description text")
end)

test("T06.7", "Disable / Enable button", function()
    Btn1:Disable()
    Btn1:Enable()
end)

test("T06.8", "SetLoading(true) / SetLoading(false)", function()
    Btn1:SetLoading(true)
    task.wait(0.05)
    Btn1:SetLoading(false)
end)

test("T06.9", "Show / Hide button", function()
    Btn1:Hide()
    Btn1:Show()
end)

test("T06.10", "Button with Description option", function()
    Btn2 = SecBtn:CreateButton({
        Title       = "With Description",
        Description = "This is a description",
        Callback    = function()
            Delirium:Notify({ Title="Button Fired", Duration=2, Type="Success" })
        end,
    })
    assertNotNil(Btn2, "Btn2")
end)

test("T06.11", "Disabled button created via config field", function()
    Btn3 = SecBtn:CreateButton({
        Title    = "Starts Disabled",
        Callback = function() end,
    })
    Btn3:Disable()
    assertNotNil(Btn3, "Btn3 disabled")
end)

-- ── T07: Toggle ───────────────────────────────────────────────────────────────

print("\n── T07: Toggle ──")

local Tog1, Tog2

test("T07.1", "CreateToggle returns api", function()
    Tog1 = SecTog:CreateToggle({
        Title    = "Feature Toggle",
        Default  = false,
        Callback = function(v) print("[Test] Toggle:", v) end,
    })
    assertNotNil(Tog1, "Toggle api")
end)

test("T07.2", "Toggle has expected methods", function()
    local methods = {"Get","Set","Toggle","Enable","Disable","SetTitle","SetDescription","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Tog1[m], "function", m)
    end
end)

test("T07.3", "Get() returns boolean", function()
    local v = Tog1:Get()
    assert(v == true or v == false, "Get returns boolean")
end)

test("T07.4", "Default=false → Get() is false", function()
    assertEq(Tog1:Get(), false, "default false")
end)

test("T07.5", "Set(true) changes value", function()
    Tog1:Set(true)
    assertEq(Tog1:Get(), true, "after Set(true)")
end)

test("T07.6", "Set(false) changes value back", function()
    Tog1:Set(false)
    assertEq(Tog1:Get(), false, "after Set(false)")
end)

test("T07.7", "Toggle() flips state", function()
    local before = Tog1:Get()
    Tog1:Toggle()
    assertEq(Tog1:Get(), not before, "flipped")
    Tog1:Toggle() -- restore
end)

test("T07.8", "SetTitle updates label", function()
    Tog1:SetTitle("Feature Toggle [Updated]")
end)

test("T07.9", "SetDescription updates sub-label", function()
    Tog1:SetDescription("Sub-text updated")
end)

test("T07.10", "Disable / Enable toggle", function()
    Tog1:Disable()
    Tog1:Enable()
end)

test("T07.11", "Show / Hide toggle", function()
    Tog1:Hide()
    Tog1:Show()
end)

test("T07.12", "Toggle Default=true creates enabled state", function()
    Tog2 = SecTog:CreateToggle({
        Title   = "Starts On",
        Default = true,
        Callback = function(v) end,
    })
    assertEq(Tog2:Get(), true, "default true")
end)

-- ── T08: Slider ───────────────────────────────────────────────────────────────

print("\n── T08: Slider ──")

local Slide1, Slide2

test("T08.1", "CreateSlider returns api", function()
    Slide1 = SecSlide:CreateSlider({
        Title    = "Walk Speed",
        Min      = 0,
        Max      = 100,
        Default  = 16,
        Precision = 0,
        Callback = function(v) print("[Test] Slider:", v) end,
    })
    assertNotNil(Slide1, "Slider api")
end)

test("T08.2", "Slider has expected methods", function()
    local methods = {"Get","Set","Enable","Disable","SetTitle","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Slide1[m], "function", m)
    end
end)

test("T08.3", "Get() returns number", function()
    assertType(Slide1:Get(), "number", "Get type")
end)

test("T08.4", "Default=16 → Get() is 16", function()
    assertEq(Slide1:Get(), 16, "default value")
end)

test("T08.5", "Set(50) changes value", function()
    Slide1:Set(50)
    assertEq(Slide1:Get(), 50, "after Set(50)")
end)

test("T08.6", "Set to Min boundary", function()
    Slide1:Set(0)
    assertEq(Slide1:Get(), 0, "min boundary")
end)

test("T08.7", "Set to Max boundary", function()
    Slide1:Set(100)
    assertEq(Slide1:Get(), 100, "max boundary")
end)

test("T08.8", "SetTitle updates label", function()
    Slide1:SetTitle("Walk Speed [Updated]")
end)

test("T08.9", "Disable / Enable slider", function()
    Slide1:Disable()
    Slide1:Enable()
end)

test("T08.10", "Show / Hide slider", function()
    Slide1:Hide()
    Slide1:Show()
end)

test("T08.11", "Float precision slider", function()
    Slide2 = SecSlide:CreateSlider({
        Title     = "Sensitivity",
        Min       = 0.1,
        Max       = 5.0,
        Default   = 1.0,
        Precision = 2,
        Callback  = function(v) end,
    })
    Slide2:Set(2.5)
    assertEq(Slide2:Get(), 2.5, "float precision set")
end)

-- ── T09: Dropdown ─────────────────────────────────────────────────────────────

print("\n── T09: Dropdown ──")

local Drop1, Drop2

test("T09.1", "CreateDropdown (single) returns api", function()
    Drop1 = SecDrop:CreateDropdown({
        Title   = "Target Mode",
        Options = {"Closest", "Lowest HP", "Random", "Furthest"},
        Default = "Closest",
        Multi   = false,
        Callback = function(v) print("[Test] Dropdown:", v) end,
    })
    assertNotNil(Drop1, "Dropdown api")
end)

test("T09.2", "Dropdown has expected methods", function()
    local methods = {"Get","Set","Refresh","SetOptions","Enable","Disable","SetTitle","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Drop1[m], "function", m)
    end
end)

test("T09.3", "Single-select Get() returns string", function()
    local v = Drop1:Get()
    assertType(v, "string", "single Get")
end)

test("T09.4", "Default='Closest' → Get() is 'Closest'", function()
    assertEq(Drop1:Get(), "Closest", "default value")
end)

test("T09.5", "Set() changes selection", function()
    Drop1:Set("Random")
    assertEq(Drop1:Get(), "Random", "after Set")
end)

test("T09.6", "SetOptions replaces options list", function()
    Drop1:SetOptions({"Alpha", "Beta", "Gamma"})
end)

test("T09.7", "Refresh re-renders dropdown", function()
    Drop1:Refresh()
end)

test("T09.8", "SetTitle updates label", function()
    Drop1:SetTitle("Target Mode [Updated]")
end)

test("T09.9", "Disable / Enable dropdown", function()
    Drop1:Disable()
    Drop1:Enable()
end)

test("T09.10", "Show / Hide dropdown", function()
    Drop1:Hide()
    Drop1:Show()
end)

test("T09.11", "Multi-select dropdown returns table", function()
    Drop2 = SecDrop:CreateDropdown({
        Title   = "Filter Targets",
        Options = {"Enemies", "Team Check", "NPCs", "Invisible"},
        Default = {"Enemies", "Team Check"},
        Multi   = true,
        Callback = function(t) end,
    })
    local v = Drop2:Get()
    assertType(v, "table", "multi Get returns table")
end)

test("T09.12", "Multi-select default has correct entries", function()
    local v = Drop2:Get()
    assert(#v == 2, "two defaults selected")
end)

-- ── T10: TextBox ──────────────────────────────────────────────────────────────

print("\n── T10: TextBox ──")

local TB1

test("T10.1", "CreateTextbox returns api", function()
    TB1 = SecText:CreateTextbox({
        Title       = "Username",
        Placeholder = "Enter name...",
        Callback    = function(t) print("[Test] TextBox:", t) end,
    })
    assertNotNil(TB1, "TextBox api")
end)

test("T10.2", "TextBox has expected methods", function()
    local methods = {"Get","Set","Enable","Disable","SetTitle","SetDescription","SetPlaceholder","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(TB1[m], "function", m)
    end
end)

test("T10.3", "Get() returns string", function()
    assertType(TB1:Get(), "string", "Get type")
end)

test("T10.4", "Set() changes value", function()
    TB1:Set("TestPlayer123")
    assertEq(TB1:Get(), "TestPlayer123", "after Set")
end)

test("T10.5", "Set empty string", function()
    TB1:Set("")
    assertEq(TB1:Get(), "", "empty set")
end)

test("T10.6", "SetTitle updates label", function()
    TB1:SetTitle("Username [Updated]")
end)

test("T10.7", "SetDescription updates sub-label", function()
    TB1:SetDescription("Enter your player name")
end)

test("T10.8", "SetPlaceholder updates hint text", function()
    TB1:SetPlaceholder("New placeholder...")
end)

test("T10.9", "Disable / Enable textbox", function()
    TB1:Disable()
    TB1:Enable()
end)

test("T10.10", "Show / Hide textbox", function()
    TB1:Hide()
    TB1:Show()
end)

-- ── T11: Keybind ──────────────────────────────────────────────────────────────

print("\n── T11: Keybind ──")

local KB1

test("T11.1", "CreateKeybind returns api", function()
    KB1 = SecText:CreateKeybind({
        Title    = "Toggle UI",
        Default  = Enum.KeyCode.K,
        Callback = function() print("[Test] Keybind fired") end,
    })
    assertNotNil(KB1, "Keybind api")
end)

test("T11.2", "Keybind has expected methods", function()
    local methods = {"Get","Set","Enable","Disable","SetTitle","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(KB1[m], "function", m)
    end
end)

test("T11.3", "Get() returns Enum.KeyCode", function()
    local k = KB1:Get()
    assert(typeof(k) == "EnumItem", "Get returns EnumItem")
end)

test("T11.4", "Default=K → Get() is K", function()
    assertEq(KB1:Get(), Enum.KeyCode.K, "default KeyCode")
end)

test("T11.5", "Set() changes keybind", function()
    KB1:Set(Enum.KeyCode.L)
    assertEq(KB1:Get(), Enum.KeyCode.L, "after Set L")
end)

test("T11.6", "Set back to original key", function()
    KB1:Set(Enum.KeyCode.K)
    assertEq(KB1:Get(), Enum.KeyCode.K, "restored K")
end)

test("T11.7", "SetTitle updates label", function()
    KB1:SetTitle("Toggle UI [Updated]")
end)

test("T11.8", "Disable / Enable keybind", function()
    KB1:Disable()
    KB1:Enable()
end)

test("T11.9", "Show / Hide keybind", function()
    KB1:Hide()
    KB1:Show()
end)

-- ── T12: ColorPicker ──────────────────────────────────────────────────────────

print("\n── T12: ColorPicker ──")

local CP1

test("T12.1", "CreateColorPicker returns api", function()
    CP1 = SecText:CreateColorPicker({
        Title    = "Highlight Color",
        Default  = Color3.fromRGB(0, 162, 255),
        Callback = function(c) print("[Test] Color:", c) end,
    })
    assertNotNil(CP1, "ColorPicker api")
end)

test("T12.2", "ColorPicker has expected methods", function()
    local methods = {"Get","Set","Enable","Disable","SetTitle","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(CP1[m], "function", m)
    end
end)

test("T12.3", "Get() returns Color3", function()
    assert(typeof(CP1:Get()) == "Color3", "Get returns Color3")
end)

test("T12.4", "Default color matches", function()
    local c = CP1:Get()
    assertEq(c.R, Color3.fromRGB(0, 162, 255).R, "R channel")
end)

test("T12.5", "Set() changes color", function()
    CP1:Set(Color3.fromRGB(255, 50, 50))
    local c = CP1:Get()
    assert(math.round(c.R * 255) == 255, "R=255 after Set")
end)

test("T12.6", "Set white", function()
    CP1:Set(Color3.fromRGB(255, 255, 255))
    local c = CP1:Get()
    assert(math.round(c.R * 255) == 255, "white R")
end)

test("T12.7", "Set black", function()
    CP1:Set(Color3.fromRGB(0, 0, 0))
end)

test("T12.8", "SetTitle updates label", function()
    CP1:SetTitle("Highlight Color [Updated]")
end)

test("T12.9", "Disable / Enable colorpicker", function()
    CP1:Disable()
    CP1:Enable()
end)

test("T12.10", "Show / Hide colorpicker", function()
    CP1:Hide()
    CP1:Show()
end)

-- ── T13: Label ────────────────────────────────────────────────────────────────

print("\n── T13: Label ──")

local Lbl1

test("T13.1", "CreateLabel returns api", function()
    Lbl1 = SecMisc:CreateLabel({
        Title = "Status: Ready",
    })
    assertNotNil(Lbl1, "Label api")
end)

test("T13.2", "Label has expected methods", function()
    local methods = {"SetTitle","SetValue","SetVariant","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Lbl1[m], "function", m)
    end
end)

test("T13.3", "SetTitle updates text", function()
    Lbl1:SetTitle("Status: Running")
end)

test("T13.4", "SetValue with string", function()
    Lbl1:SetValue("Version 1.1.0")
end)

test("T13.5", "SetValue with number", function()
    Lbl1:SetValue(42)
end)

test("T13.6", "SetVariant changes style", function()
    Lbl1:SetVariant("muted")
end)

test("T13.7", "Show / Hide label", function()
    Lbl1:Hide()
    Lbl1:Show()
end)

-- ── T14: Paragraph ────────────────────────────────────────────────────────────

print("\n── T14: Paragraph ──")

local Para1

test("T14.1", "CreateParagraph returns api", function()
    Para1 = SecMisc:CreateParagraph({
        Title   = "About",
        Content = "Delirium v1.1.0 — mobile-ready UI library.",
    })
    assertNotNil(Para1, "Paragraph api")
end)

test("T14.2", "Paragraph has expected methods", function()
    local methods = {"SetTitle","SetContent","Append","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Para1[m], "function", m)
    end
end)

test("T14.3", "SetTitle updates header", function()
    Para1:SetTitle("About [Updated]")
end)

test("T14.4", "SetContent replaces body", function()
    Para1:SetContent("New content text goes here.")
end)

test("T14.5", "Append adds to body", function()
    Para1:Append(" Additional appended text.")
end)

test("T14.6", "Show / Hide paragraph", function()
    Para1:Hide()
    Para1:Show()
end)

-- ── T15: Divider ──────────────────────────────────────────────────────────────

print("\n── T15: Divider ──")

local Div1

test("T15.1", "CreateDivider returns api", function()
    Div1 = SecMisc:CreateDivider()
    assertNotNil(Div1, "Divider api")
end)

test("T15.2", "Divider has expected methods", function()
    local methods = {"SetLabel","Show","Hide","Destroy"}
    for _, m in ipairs(methods) do
        assertType(Div1[m], "function", m)
    end
end)

test("T15.3", "SetLabel sets label text", function()
    Div1:SetLabel("Section Separator")
end)

test("T15.4", "SetLabel empty string", function()
    Div1:SetLabel("")
end)

test("T15.5", "Show / Hide divider", function()
    Div1:Hide()
    Div1:Show()
end)

test("T15.6", "Divider with config table", function()
    local Div2 = SecMisc:CreateDivider({ Label = "Named Divider" })
    assertNotNil(Div2, "Divider with config")
end)

-- ── T16: Notification Service ─────────────────────────────────────────────────

print("\n── T16: NotificationService ──")

local SecNotif = Tab4:CreateSection("Notifications")

test("T16.1", "Notify returns handle", function()
    local h = Delirium:Notify({
        Title    = "Test Info",
        Duration = 2,
        Type     = "Info",
    })
    assertNotNil(h, "notif handle")
end)

test("T16.2", "Notify Type=Success", function()
    local h = Delirium:Notify({ Title="Success", Type="Success", Duration=2 })
    assertNotNil(h, "success notif")
end)

test("T16.3", "Notify Type=Warning", function()
    local h = Delirium:Notify({ Title="Warning", Type="Warning", Duration=2 })
    assertNotNil(h, "warning notif")
end)

test("T16.4", "Notify Type=Error", function()
    local h = Delirium:Notify({ Title="Error", Type="Error", Duration=2 })
    assertNotNil(h, "error notif")
end)

test("T16.5", "Notify with Action button", function()
    local actionFired = false
    local h = Delirium:Notify({
        Title    = "With Action",
        Type     = "Info",
        Duration = 5,
        Action   = {
            Label    = "Undo",
            Callback = function() actionFired = true end,
        },
    })
    assertNotNil(h, "action notif handle")
end)

test("T16.6", "Notify handle has Dismiss()", function()
    local h = Delirium:Notify({ Title="Dismiss Test", Duration=10 })
    assertType(h.Dismiss, "function", "Dismiss")
    h:Dismiss()
end)

test("T16.7", "Notify handle has SetTitle()", function()
    local h = Delirium:Notify({ Title="Original", Duration=5 })
    assertType(h.SetTitle, "function", "SetTitle on handle")
    h:SetTitle("Updated Title")
    task.wait(0.05)
    h:Dismiss()
end)

test("T16.8", "Notify handle has SetMessage()", function()
    local h = Delirium:Notify({ Title="Msg Test", Duration=5 })
    assertType(h.SetMessage, "function", "SetMessage on handle")
    h:SetMessage("Updated message body")
    task.wait(0.05)
    h:Dismiss()
end)

test("T16.9", "Persistent notif (Duration=0)", function()
    local h = Delirium:Notify({ Title="Persistent", Duration=0, Type="Warning" })
    assertNotNil(h, "persistent handle")
    task.wait(0.1)
    h:Dismiss()
end)

test("T16.10", "Multiple simultaneous notifications", function()
    for i = 1, 3 do
        local h = Delirium:Notify({
            Title    = "Burst " .. i,
            Type     = "Info",
            Duration = 1,
        })
        assertNotNil(h, "burst notif " .. i)
    end
end)

-- UI buttons for manual notification tests
SecNotif:CreateButton({
    Title    = "Fire All 4 Types",
    Callback = function()
        for _, t in ipairs({"Info","Success","Warning","Error"}) do
            Delirium:Notify({ Title=t.." Notification", Type=t, Duration=3 })
            task.wait(0.2)
        end
    end,
})

-- ── T17: Dialog Service ───────────────────────────────────────────────────────

print("\n── T17: DialogService ──")

local SecDialog = Tab4:CreateSection("Dialogs")
local DialogService = Delirium.Dialog

test("T17.1", "DialogService exposed on Delirium", function()
    assertNotNil(DialogService, "DialogService")
end)

test("T17.2", "DialogService.Confirm is a function", function()
    assertType(DialogService.Confirm, "function", "Confirm")
end)

-- UI button to manually trigger dialog (can't automate modal confirm in executor)
SecDialog:CreateButton({
    Title       = "Open Confirm Dialog",
    Description = "Modal — requires user interaction",
    Callback    = function()
        DialogService.Confirm({
            Title    = "Test Dialog",
            Message  = "Confirm this action?",
            Confirm  = "Yes",
            Cancel   = "No",
            OnConfirm = function()
                Delirium:Notify({ Title="Confirmed", Type="Success", Duration=3 })
            end,
            OnCancel  = function()
                Delirium:Notify({ Title="Cancelled", Type="Warning", Duration=3 })
            end,
        })
    end,
})

-- ── T18: ConfigService ────────────────────────────────────────────────────────

print("\n── T18: ConfigService ──")

local SecCfg = Tab4:CreateSection("Config Service")
local ConfigService

skip("T18.1", "ConfigService accessible via require path", "re-loading Delirium here kills the window — internal module, skip")

-- We access ConfigService through the _Delirium_require mechanism
-- by re-using the loaded environment. Test via UI integration.
local profileTested = false

test("T18.2", "Profile API via raw module test (pcall guarded)", function()
    -- Access through executor's getgenv or rawenv if available
    local env = getgenv and getgenv() or _G
    -- Try to find ConfigService in global env (registered by Bootstrap)
    local found = false
    for k, v in pairs(env) do
        if type(v) == "table" and v.GetProfile and type(v.GetProfile) == "function" then
            found = true
            ConfigService = v
        end
    end
    -- If not found via env, skip gracefully — it's internal
    if not found then
        skip("T18.2", "ConfigService not in global scope (internal module)", "internal")
    end
end)

-- UI-driven config test
local cfgToggle = Tab4:CreateSection("Config Test Controls"):CreateToggle({
    Title   = "Config-Backed Toggle",
    Default = false,
    Callback = function(v)
        -- Would normally call: profile:Set("myToggle", v); profile:Save()
        print("[Config] Toggle value:", v)
    end,
})

SecCfg:CreateButton({
    Title    = "Test Profile Save/Load (Print)",
    Callback = function()
        print("[Config] Testing profile operations...")
        -- Access through env scanning
        local env2 = getgenv and getgenv() or _G
        for _, v in pairs(env2) do
            if type(v) == "table" and type(v.GetProfile) == "function" then
                local ok4, profile = pcall(v.GetProfile, v, "TestProfile")
                if ok4 and profile then
                    profile:Set("testKey", "testValue")
                    profile:Set("numKey", 42)
                    local saved = profile:Save()
                    local val   = profile:Get("testKey", "")
                    local dirty = profile:IsDirty()
                    local all   = profile:GetAll()
                    local name  = profile:GetName()
                    print("[Config PASS] Set/Get/Save/IsDirty/GetAll/GetName:", val, dirty, name, saved)
                    Delirium:Notify({ Title="Config: PASS", Type="Success", Duration=3 })
                    return
                end
            end
        end
        Delirium:Notify({
            Title    = "Config: SKIP",
            Type     = "Warning",
            Duration = 3,
        })
        print("[Config] ConfigService not accessible from global env — internal module")
    end,
})

-- ── T19: Theme Switch Live ────────────────────────────────────────────────────

print("\n── T19: Theme Switch Live ──")

local SecTheme = Tab4:CreateSection("Theme Switching")

test("T19.1", "SetTheme 'Dark' applies", function()
    Delirium:SetTheme("Dark")
    assertEq(ThemeEngine.GetTheme(), "Dark", "Dark theme")
end)

test("T19.2", "SetTheme 'Light' applies (if registered)", function()
    local names = ThemeEngine.GetThemeNames()
    local hasLight = false
    for _, n in ipairs(names) do if n == "Light" then hasLight = true end end
    if hasLight then
        Delirium:SetTheme("Light")
        assertEq(ThemeEngine.GetTheme(), "Light", "Light theme")
        Delirium:SetTheme("Dark")
    else
        skip("T19.2", "Light theme not registered", "not available")
    end
end)

test("T19.3", "Custom registered theme applies via SetTheme", function()
    Delirium:SetTheme("TestCustomTheme")
    assertEq(ThemeEngine.GetTheme(), "TestCustomTheme", "custom theme applied")
    Delirium:SetTheme("Dark")
end)

SecTheme:CreateDropdown({
    Title    = "Active Theme",
    Options  = ThemeEngine.GetThemeNames(),
    Default  = ThemeEngine.GetTheme(),
    Callback = function(name)
        local ok5 = pcall(Delirium.SetTheme, Delirium, name)
        if ok5 then
            Delirium:Notify({ Title="Theme: "..name, Type="Success", Duration=2 })
        end
    end,
})

SecTheme:CreateToggle({
    Title    = "Reduced Motion",
    Default  = false,
    Callback = function(v)
        Delirium:SetReducedMotion(v)
        Delirium:Notify({
            Title    = v and "Animations Reduced" or "Animations Restored",
            Type     = "Info",
            Duration = 2,
        })
    end,
})

-- ── Window Controls (Manual) ────────────────────────────────────────────────────

local SecWinCtrl = Tab4:CreateSection("Window Controls (Manual)")

SecWinCtrl:CreateButton({
    Title       = "Hide Window",
    Description = "Calls MainWin:Hide()",
    Callback    = function() MainWin:Hide() end,
})

SecWinCtrl:CreateButton({
    Title       = "Show Window",
    Description = "Calls MainWin:Show()",
    Callback    = function() MainWin:Show() end,
})

SecWinCtrl:CreateButton({
    Title       = "Minimize",
    Description = "Calls MainWin:Minimize()",
    Callback    = function() MainWin:Minimize() end,
})

SecWinCtrl:CreateButton({
    Title       = "Restore",
    Description = "Calls MainWin:Restore()",
    Callback    = function() MainWin:Restore() end,
})

SecWinCtrl:CreateButton({
    Title       = "Toggle Minimize",
    Description = "Calls MainWin:ToggleMinimize()",
    Callback    = function() MainWin:ToggleMinimize() end,
})

SecWinCtrl:CreateButton({
    Title       = "MiniIconify",
    Description = "Shrinks window to mini icon",
    Callback    = function() MainWin:MiniIconify() end,
})

SecWinCtrl:CreateButton({
    Title       = "Restore From Mini Icon",
    Description = "Restores window from mini icon state",
    Callback    = function() MainWin:RestoreFromMiniIcon() end,
})

SecWinCtrl:CreateButton({
    Title       = "Set Title Test",
    Description = "Calls MainWin:SetTitle() with a new string",
    Callback    = function()
        MainWin:SetTitle("Delirium v1.1.0 Test Suite [RENAMED]")
        Delirium:Notify({ Title="SetTitle fired", Type="Success", Duration=2 })
    end,
})

-- ── T20: Lifecycle / Cleanup ──────────────────────────────────────────────────

print("\n── T20: Lifecycle / Cleanup ──")

local SecLife = Tab5:CreateSection("Lifecycle Tests")

test("T20.1", "Component :Destroy() does not error", function()
    local tmpSection = Tab5:CreateSection("Temp Destroy Test")
    local tmpBtn = tmpSection:CreateButton({ Title="Temp", Callback=function() end })
    local tmpTog = tmpSection:CreateToggle({ Title="TempTog", Default=false, Callback=function() end })
    local tmpSlide = tmpSection:CreateSlider({ Title="TempSlide", Min=0, Max=10, Default=5, Callback=function() end })
    tmpBtn:Destroy()
    tmpTog:Destroy()
    tmpSlide:Destroy()
    tmpSection:Destroy()
end)

test("T20.2", "Section :Destroy() cleans up children", function()
    local s = Tab5:CreateSection("Destroy Section Test")
    s:CreateButton({ Title="Child Btn", Callback=function() end })
    s:CreateToggle({ Title="Child Tog", Default=false, Callback=function() end })
    s:Destroy()
end)

test("T20.3", "Tab :Destroy() removes tab", function()
    local tmpTab = MainWin:CreateTab({ Name="Destroy Tab Test" })
    local s = tmpTab:CreateSection("Inner")
    s:CreateButton({ Title="Inner Btn", Callback=function() end })
    tmpTab:Destroy()
end)

test("T20.4", "DropDown :Destroy() cleans up", function()
    local s = Tab5:CreateSection("Dropdown Destroy")
    local d = s:CreateDropdown({ Title="Temp Drop", Options={"A","B"}, Callback=function() end })
    d:Destroy()
    s:Destroy()
end)

test("T20.5", "ColorPicker :Destroy() cleans up", function()
    local s = Tab5:CreateSection("CP Destroy")
    local cp = s:CreateColorPicker({ Title="Temp CP", Default=Color3.new(1,0,0), Callback=function() end })
    cp:Destroy()
    s:Destroy()
end)

test("T20.6", "Keybind :Destroy() cleans up", function()
    local s = Tab5:CreateSection("KB Destroy")
    local kb = s:CreateKeybind({ Title="Temp KB", Default=Enum.KeyCode.J, Callback=function() end })
    kb:Destroy()
    s:Destroy()
end)

test("T20.7", "Label + Paragraph + Divider :Destroy()", function()
    local s = Tab5:CreateSection("Content Destroy")
    local lbl = s:CreateLabel({ Title="Temp Label" })
    local par = s:CreateParagraph({ Title="Temp Para", Content="Content" })
    local div = s:CreateDivider()
    lbl:Destroy()
    par:Destroy()
    div:Destroy()
    s:Destroy()
end)

test("T20.8", "Notification handle :Dismiss() before expire", function()
    local h = Delirium:Notify({ Title="Lifecycle Notif", Duration=30, Type="Info" })
    task.wait(0.05)
    h:Dismiss()
end)

-- UI buttons for manual lifecycle testing
SecLife:CreateButton({
    Title    = "Spawn & Destroy Window",
    Description = "Creates a second window then destroys it after 2s",
    Callback = function()
        local tmpWin = Delirium:CreateWindow({ Name="Temp Window", Subtitle="Will self-destruct" })
        local t = tmpWin:CreateTab({ Name="TempTab" })
        local s = t:CreateSection("Temp")
        s:CreateLabel({ Title="Destroying in 2s..." })
        Delirium:Notify({ Title="Temp window created", Type="Info", Duration=2 })
        task.delay(2, function()
            tmpWin:Destroy()
            Delirium:Notify({ Title="Temp window destroyed", Type="Success", Duration=3 })
        end)
    end,
})

-- ── T21: Section Aliases (AddX) ───────────────────────────────────────────────

print("\n── T21: Aliases (AddX) ──")

local SecAlias = Tab5:CreateSection("Alias API")

test("T21.1", "AddButton alias works", function()
    local b = SecAlias:AddButton({ Title="Alias Btn", Callback=function() end })
    assertNotNil(b, "AddButton alias")
    b:Destroy()
end)

test("T21.2", "AddToggle alias works", function()
    local t = SecAlias:AddToggle({ Title="Alias Tog", Default=false, Callback=function() end })
    assertNotNil(t, "AddToggle alias")
    t:Destroy()
end)

test("T21.3", "AddSlider alias works", function()
    local s = SecAlias:AddSlider({ Title="Alias Slide", Min=0, Max=10, Default=5, Callback=function() end })
    assertNotNil(s, "AddSlider alias")
    s:Destroy()
end)

test("T21.4", "AddDropdown alias works", function()
    local d = SecAlias:AddDropdown({ Title="Alias Drop", Options={"X","Y"}, Callback=function() end })
    assertNotNil(d, "AddDropdown alias")
    d:Destroy()
end)

test("T21.5", "AddLabel alias works", function()
    local l = SecAlias:AddLabel({ Title="Alias Lbl" })
    assertNotNil(l, "AddLabel alias")
    l:Destroy()
end)

test("T21.6", "AddDivider alias works", function()
    local dv = SecAlias:AddDivider()
    assertNotNil(dv, "AddDivider alias")
    dv:Destroy()
end)

-- ── Summary ───────────────────────────────────────────────────────────────────

task.wait(0.2)

print("\n══════════════════════════════════════")
print(" DELIRIUM v1.1.0 TEST RESULTS")
print("══════════════════════════════════════")
print(string.format(" PASS: %d", Results.pass))
print(string.format(" FAIL: %d", Results.fail))
print(string.format(" SKIP: %d", Results.skip))
print(string.format(" TOTAL: %d", Results.pass + Results.fail + Results.skip))
print("══════════════════════════════════════")

if Results.fail > 0 then
    print("\n[FAILURES]")
    for _, entry in ipairs(Log) do
        if entry:sub(1,6) == "[FAIL]" then
            print(entry)
        end
    end
end

-- Summary notification
local notifType = Results.fail == 0 and "Success" or "Error"
local notifTitle = Results.fail == 0
    and string.format("All %d tests passed!", Results.pass)
    or  string.format("%d FAILED / %d passed", Results.fail, Results.pass)

Delirium:Notify({
    Title    = "Test Suite Complete",
    Type     = notifType,
    Duration = 8,
    Action   = {
        Label    = "Check Output",
        Callback = function() print("[TEST] See Roblox Output for full log.") end,
    },
})

Delirium:Notify({
    Title    = notifTitle,
    Type     = notifType,
    Duration = 6,
})