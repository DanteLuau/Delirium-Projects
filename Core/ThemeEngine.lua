-- Core/ThemeEngine.lua
-- Centralized visual token system with runtime theme switching.
-- OnThemeChanged() returns a disconnect function — call it on component :Destroy()
-- to prevent memory leaks.

local THEMES = {
    Dark = {
        -- Base surfaces
        Background    = Color3.fromRGB(15, 15, 20),
        Surface       = Color3.fromRGB(24, 24, 32),
        SurfaceHover  = Color3.fromRGB(30, 30, 42),
        SurfaceActive = Color3.fromRGB(36, 36, 52),
        Border        = Color3.fromRGB(45, 45, 60),

        -- Text hierarchy
        Text         = Color3.fromRGB(235, 235, 250),
        SubText      = Color3.fromRGB(120, 120, 148),
        DisabledText = Color3.fromRGB(65, 65, 85),

        -- Accent / brand
        Accent     = Color3.fromRGB(120, 95, 230),
        AccentDim  = Color3.fromRGB(78, 58, 165),
        AccentText = Color3.fromRGB(255, 255, 255),

        -- Status colors
        Positive = Color3.fromRGB(55, 200, 100),
        Warning  = Color3.fromRGB(240, 185, 55),
        Error    = Color3.fromRGB(220, 65, 65),

        -- Component-specific tokens
        InputBackground = Color3.fromRGB(18, 18, 26),
        ToggleOff       = Color3.fromRGB(45, 45, 60),
        SliderTrack     = Color3.fromRGB(40, 40, 55),
        ScrollBar       = Color3.fromRGB(55, 55, 75),

        -- Layering / overlay tokens
        CardBackground    = Color3.fromRGB(28, 28, 38),
        TooltipBackground = Color3.fromRGB(30, 30, 44),
        Overlay           = Color3.fromRGB(0,  0,  0),   -- used with BackgroundTransparency ~0.5
    },

    Light = {
        Background    = Color3.fromRGB(245, 245, 250),
        Surface       = Color3.fromRGB(255, 255, 255),
        SurfaceHover  = Color3.fromRGB(238, 238, 248),
        SurfaceActive = Color3.fromRGB(228, 228, 242),
        Border        = Color3.fromRGB(200, 200, 215),

        Text         = Color3.fromRGB(20, 20, 30),
        SubText      = Color3.fromRGB(100, 100, 120),
        DisabledText = Color3.fromRGB(160, 160, 175),

        Accent     = Color3.fromRGB(100, 75, 210),
        AccentDim  = Color3.fromRGB(68,  50, 155),   -- darker/muted, not lighter
        AccentText = Color3.fromRGB(255, 255, 255),

        Positive = Color3.fromRGB(28, 160, 68),
        Warning  = Color3.fromRGB(195, 130, 18),
        Error    = Color3.fromRGB(190, 45, 45),

        InputBackground = Color3.fromRGB(232, 232, 242),
        ToggleOff       = Color3.fromRGB(195, 195, 212),
        SliderTrack     = Color3.fromRGB(195, 195, 212),
        ScrollBar       = Color3.fromRGB(180, 180, 200),

        -- Layering / overlay tokens
        CardBackground    = Color3.fromRGB(248, 248, 253),
        TooltipBackground = Color3.fromRGB(30,  30,  44),  -- intentionally dark; tooltips stay dark
        Overlay           = Color3.fromRGB(0,   0,   0),
    },
}

local ThemeEngine = {
    _currentTheme    = "Dark",
    _listeners       = {},
    _nextListenerId  = 0,
}

-- ─── Core API ─────────────────────────────────────────────────────────────────

-- Get a single color token for the current theme.
-- On missing token: falls back to Dark theme, then emits a warning and returns a
-- hot-pink sentinel (visible in dev) rather than crashing the entire frame.
function ThemeEngine.GetToken(tokenName: string): Color3
    local theme = THEMES[ThemeEngine._currentTheme]
    assert(theme, "ThemeEngine: unknown theme — " .. tostring(ThemeEngine._currentTheme))
    local token = theme[tokenName]
    if token == nil then
        token = THEMES.Dark[tokenName]
        if token == nil then
            warn(string.format(
                "ThemeEngine: token '%s' not found in '%s' or Dark fallback",
                tostring(tokenName), ThemeEngine._currentTheme
            ))
            return Color3.fromRGB(255, 0, 200)  -- hot-pink sentinel — fix your token name
        end
    end
    return token
end

-- Get the current theme name.
function ThemeEngine.GetTheme(): string
    return ThemeEngine._currentTheme
end

-- Get all tokens for the current theme (useful for bulk reads).
function ThemeEngine.GetTokens(): table
    return THEMES[ThemeEngine._currentTheme]
end

-- Switch the active theme and notify all listeners.
-- Listener errors are caught and warned rather than crashing the theme switch.
function ThemeEngine.SetTheme(themeName: string)
    assert(THEMES[themeName], "ThemeEngine: theme '" .. tostring(themeName) .. "' does not exist")
    ThemeEngine._currentTheme = themeName
    local tokens = THEMES[themeName]
    for id, listener in pairs(ThemeEngine._listeners) do
        task.spawn(function()
            local ok, err = pcall(listener, tokens)
            if not ok then
                warn(string.format(
                    "ThemeEngine: listener [%d] errored during SetTheme('%s') — %s",
                    id, themeName, tostring(err)
                ))
            end
        end)
    end
end

-- Register a listener for theme changes.
-- Returns a DISCONNECT FUNCTION — call it in component :Destroy() to prevent leaks.
function ThemeEngine.OnThemeChanged(callback: (tokens: table) -> ()): () -> ()
    assert(type(callback) == "function", "ThemeEngine.OnThemeChanged expects a function")
    ThemeEngine._nextListenerId += 1
    local id = ThemeEngine._nextListenerId
    ThemeEngine._listeners[id] = callback
    return function()
        ThemeEngine._listeners[id] = nil
    end
end

-- ─── Extension API ────────────────────────────────────────────────────────────

-- Register a custom theme. Tokens not provided fall back to Dark values.
function ThemeEngine.RegisterTheme(name: string, tokens: table)
    assert(type(name) == "string" and #name > 0, "RegisterTheme: name must be a non-empty string")
    assert(type(tokens) == "table", "RegisterTheme: tokens must be a table")
    -- Fill any missing tokens from Dark as fallback
    local built = {}
    for key, default in pairs(THEMES.Dark) do
        built[key] = tokens[key] or default
    end
    -- Include any extra custom tokens
    for key, val in pairs(tokens) do
        built[key] = val
    end
    THEMES[name] = built
end

-- List all registered theme names.
function ThemeEngine.GetThemeNames(): {string}
    local names = {}
    for name in pairs(THEMES) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Clear all registered theme listeners — called by Bootstrap on session teardown.
-- Prevents stale callbacks from destroyed components accumulating across execs.
function ThemeEngine.ClearListeners()
    table.clear(ThemeEngine._listeners)
    ThemeEngine._nextListenerId = 0
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = require(script.Parent.ServiceRegistry)

ServiceRegistry.Register("ThemeEngine", {
    Reset = ThemeEngine.ClearListeners,
    -- No Init: ThemeEngine does not need the ScreenGui
}, 10)  -- priority 10 — resets before services that depend on theme tokens

return ThemeEngine
