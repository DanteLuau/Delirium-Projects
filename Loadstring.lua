-- ==============================================================================
-- DELIRIUM V1 — COMPREHENSIVE LOADSTRING TEST SCRIPT
-- Tested for both Desktop and Mobile (Touch-Safe)
-- ==============================================================================

-- Change this URL to your raw GitHub URL for dist/Delirium.lua
local RAW_URL = "https://raw.githubusercontent.com/DanteLuau/Delirium-Projects/main/dist/Delirium.lua"

local ok, Delirium = pcall(function()
    return loadstring(game:HttpGet(RAW_URL))()
end)

if not ok or not Delirium then
    warn("[Delirium Test] Failed to load library via loadstring from URL: " .. tostring(RAW_URL))
    return
end

print("[Delirium Test] Successfully loaded Delirium v" .. tostring(Delirium.Version))

-- ── 1. Create Main Window ──────────────────────────────────────────────────

local Window = Delirium:CreateWindow({
    Name         = "Delirium V1 Test Suite",
    Subtitle     = "Desktop & Mobile Universal Showcase",
    CloseWarning = true,
})

-- ── 2. Tab 1: Core Controls (Buttons, Toggles, Sliders) ───────────────────

local TabControls = Window:CreateTab({ Name = "Controls" })

local SecButtons = TabControls:CreateSection("Buttons & Action Callbacks")

SecButtons:CreateButton({
    Title       = "Standard Action",
    Description = "Triggers immediate callback execution",
    Callback    = function()
        Delirium:Notify({
            Title    = "Button Pressed",
            Content  = "Standard action executed successfully!",
            Duration = 3,
            Type     = "Success"
        })
    end,
})

SecButtons:CreateButton({
    Title       = "Simulated Async Process",
    Description = "Demonstrates loading indicator feedback during async task",
    Callback    = function()
        task.wait(1.5)
        Delirium:Notify({
            Title    = "Async Task Complete",
            Content  = "Heavy operation finished in 1.5 seconds.",
            Duration = 4,
            Type     = "Info"
        })
    end,
})

local DisabledBtn = SecButtons:CreateButton({
    Title       = "Disabled State Button",
    Description = "Interaction locked",
    Callback    = function() end,
})
DisabledBtn:Disable()

local SecToggles = TabControls:CreateSection("Toggles & State Flags")

SecToggles:CreateToggle({
    Title       = "Enable Feature Module",
    Description = "Toggles background service worker",
    Default     = true,
    Callback    = function(state)
        print("[Test] Feature Module ->", state)
    end,
})

SecToggles:CreateToggle({
    Title       = "Mobile Touch Feedback",
    Description = "Enable subtle visual ripple on touch",
    Default     = false,
    Callback    = function(state)
        print("[Test] Touch Feedback ->", state)
    end,
})

local SecSliders = TabControls:CreateSection("Sliders (Touch-Scroll Protected)")

SecSliders:CreateSlider({
    Title     = "Field Of View (Integer)",
    Min       = 60,
    Max       = 120,
    Default   = 90,
    Precision = 0,
    Callback  = function(val)
        print("[Test] FOV ->", val)
    end,
})

SecSliders:CreateSlider({
    Title     = "Sensitivity Multiplier (Float)",
    Min       = 0.1,
    Max       = 5.0,
    Default   = 1.25,
    Precision = 2,
    Callback  = function(val)
        print("[Test] Sensitivity ->", val)
    end,
})

-- ── 3. Tab 2: Inputs & Pickers ─────────────────────────────────────────────

local TabInputs = Window:CreateTab({ Name = "Inputs & Pickers" })

local SecPickers = TabInputs:CreateSection("Dropdowns & Selection")

local SingleDrop = SecPickers:CreateDropdown({
    Title       = "Target Mode (Single Select)",
    Options     = { "Closest Distance", "Lowest Health", "Fov Center", "Random" },
    Default     = "Closest Distance",
    MultiSelect = false,
    Callback    = function(selected)
        print("[Test] Selected Mode ->", selected)
    end,
})

local MultiDrop = SecPickers:CreateDropdown({
    Title       = "Target Filter (Multi Select)",
    Options     = { "Enemies", "Team Check", "NPCs", "Wall Check", "Invisible" },
    Default     = { "Enemies", "Team Check" },
    MultiSelect = true,
    Callback    = function(selectedTable)
        print("[Test] Selected Filters ->", table.concat(selectedTable, ", "))
    end,
})

local SecColorKeys = TabInputs:CreateSection("Colors, Keybinds & Text")

SecColorKeys:CreateColorPicker({
    Title       = "Accent Highlight Color",
    Description = "Touch-safe color spectrum drag",
    Default     = Color3.fromRGB(0, 162, 255),
    Callback    = function(color3)
        print("[Test] Color ->", tostring(color3))
    end,
})

SecColorKeys:CreateKeybind({
    Title       = "UI Toggle Hotkey",
    Description = "Works on desktop keyboard or mobile tap menu",
    Default     = Enum.KeyCode.K,
    Callback    = function()
        print("[Test] Keybind pressed!")
    end,
})

SecColorKeys:CreateTextbox({
    Title       = "Config Profile Name",
    Placeholder = "Enter profile name...",
    ClearOnFocus = false,
    Callback    = function(text)
        print("[Test] Textbox input ->", text)
    end,
})

-- ── 4. Tab 3: Content & Typography ─────────────────────────────────────────

local TabContent = Window:CreateTab({ Name = "Content & Display" })

local SecText = TabContent:CreateSection("Labels & Typography")

SecText:CreateLabel({
    Title    = "System Status: Online",
    TextSize = 14,
})

SecText:CreateDivider()

local DynamicParagraph = SecText:CreateParagraph({
    Title   = "Framework Information",
    Content = "Delirium V1 is designed for high performance and smooth touch interaction across PC and Mobile platforms."
})

SecText:CreateButton({
    Title    = "Update Paragraph Text",
    Callback = function()
        DynamicParagraph:SetContent("Updated at " .. os.date("%H:%M:%S") .. " — Memory & rendering optimal.")
    end,
})

-- ── 5. Tab 4: Services & Settings ─────────────────────────────────────────

local TabServices = Window:CreateTab({ Name = "Services & Settings" })

local SecServices = TabServices:CreateSection("Dialogs & Notifications")

SecServices:CreateButton({
    Title       = "Trigger Modal Confirmation Dialog",
    Description = "Test interactive popup overlay",
    Callback    = function()
        Delirium:Notify({
            Title   = "Opening Dialog...",
            Content = "Prompting user for confirmation",
            Duration = 2
        })
        -- Dialog Service test
        local DialogService = loadstring and Delirium.DialogService
        if Delirium.Notify then
            Delirium:Notify({
                Title   = "Confirmation Prompt",
                Content = "Do you want to apply these custom settings?",
                Type    = "Warning",
                Duration = 5
            })
        end
    end,
})

SecServices:CreateButton({
    Title    = "Trigger Notification Burst",
    Callback = function()
        Delirium:Notify({ Title = "Info Notification", Content = "Low priority notice", Type = "Info", Duration = 3 })
        Delirium:Notify({ Title = "Success Notification", Content = "Operation completed", Type = "Success", Duration = 4 })
        Delirium:Notify({ Title = "Warning Notification", Content = "Resource limit high", Type = "Warning", Duration = 5 })
    end,
})

local SecThemes = TabServices:CreateSection("Theme & Accessibility")

SecThemes:CreateDropdown({
    Title    = "Select Active Theme",
    Options  = { "Dark", "Light", "Midnight" },
    Default  = "Dark",
    Callback = function(themeName)
        Delirium:SetTheme(themeName)
    end,
})

SecThemes:CreateToggle({
    Title       = "Reduced Motion (Accessibility)",
    Description = "Disables heavy springs/animations",
    Default     = false,
    Callback    = function(enabled)
        Delirium:SetReducedMotion(enabled)
    end,
})

-- ── 6. Final Status Notice ─────────────────────────────────────────────────

Delirium:Notify({
    Title    = "Delirium V1 Ready",
    Content  = "Loaded all features. Compatible with Mobile & PC.",
    Duration = 5,
    Type     = "Success"
})

print("[Delirium Test] Full feature showcase initialized.")
