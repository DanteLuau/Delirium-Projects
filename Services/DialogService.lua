-- Services/DialogService.lua
-- Single-instance modal confirmation dialogs rendered over the full screen.
--
-- Dynamic and reusable — not tied to any specific window or action.
-- Only one dialog active at a time. Subsequent calls while one is active
-- are rejected with a warning (queue support is a future enhancement).
--
-- Usage:
--   local handle = DialogService.Confirm({
--       Title   = "Close window?",
--       Message = "This action cannot be undone.",   -- optional
--       Type    = "Warning",                          -- Info|Warning|Error|Success
--       Confirm = { Label = "Close",  Callback = function() ... end },
--       Cancel  = { Label = "Cancel", Callback = function() ... end },
--       -- Cancel = nil → no cancel button; backdrop click does nothing
--   })
--   handle:Dismiss()  -- programmatic dismiss (fires Cancel.Callback if set)

local Root            = script.Parent.Parent
local ThemeEngine     = require(Root.Core.ThemeEngine)
local AnimationEngine = require(Root.Core.AnimationEngine)
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ServiceRegistry = require(Root.Core.ServiceRegistry)

-- ─── Constants ────────────────────────────────────────────────────────────────

local CARD_W         = 300
local BACKDROP_ALPHA = 0.52

-- Type → accent color token (mirrors NotificationService's TYPE_TOKEN)
local TYPE_TOKEN = {
    Info    = "Accent",
    Warning = "Warning",
    Error   = "Error",
    Success = "Positive",
}

-- ─── State ────────────────────────────────────────────────────────────────────

local DialogService = {}

local _screenGui:  ScreenGui = nil
local _activeDialog          = nil
local _initialized           = false

-- ─── Init / Reset ─────────────────────────────────────────────────────────────

function DialogService.Init(screenGui: ScreenGui)
    if _initialized then return end
    _screenGui   = screenGui
    _initialized = true
end

function DialogService.Reset()
    if _activeDialog then
        pcall(function() _activeDialog:Dismiss() end)
        _activeDialog = nil
    end
    _screenGui   = nil
    _initialized = false
end

-- ─── Internal builder ─────────────────────────────────────────────────────────

local function _buildDialog(config: table)
    local dialogType = config.Type    or "Info"
    local title      = config.Title   or "Confirm"
    local message    = config.Message
    local confirmCfg = config.Confirm or {}
    local cancelCfg  = config.Cancel  -- nil = no cancel button

    local hasMessage = message and message ~= ""
    local hasCancel  = cancelCfg ~= nil

    local accentToken = TYPE_TOKEN[dialogType] or "Accent"

    -- Card height: title (14+16) + optional message row + action row + bottom pad
    local cardH = hasMessage and 130 or 108

    -- ─── Backdrop ─────────────────────────────────────────────────────────────
    -- Clickable if cancel is available so clicking outside dismisses the dialog.

    local backdropClass = hasCancel and "TextButton" or "Frame"
    local backdrop = ComponentHelper.Create(backdropClass, {
        Name                   = "DialogBackdrop",
        Size                   = UDim2.fromScale(1, 1),
        Position               = UDim2.fromScale(0, 0),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,   -- animated in
        BorderSizePixel        = 0,
        ZIndex                 = 200,
        Parent                 = _screenGui,
    })
    if backdropClass == "TextButton" then
        backdrop.Text            = ""
        backdrop.AutoButtonColor = false
    end

    -- ─── Card ─────────────────────────────────────────────────────────────────

    local card = ComponentHelper.Create("Frame", {
        Name                   = "DialogCard",
        Size                   = UDim2.fromOffset(CARD_W, cardH),
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 1,   -- animated in
        BorderSizePixel        = 0,
        ZIndex                 = 201,
        Parent                 = backdrop,
    })
    ComponentHelper.AddCorner(card, 10)
    local cardStroke = ComponentHelper.AddStroke(card, ThemeEngine.GetToken("Border"), 1)

    -- Colored left bar (4px, same pattern as NotificationService)
    local typeBar = ComponentHelper.Create("Frame", {
        Name             = "TypeBar",
        Size             = UDim2.new(0, 4, 1, 0),
        Position         = UDim2.fromScale(0, 0),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        BorderSizePixel  = 0,
        ZIndex           = 202,
        Parent           = card,
    })
    ComponentHelper.AddCorner(typeBar, 2)

    -- Title
    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(1, -36, 0, 16),
        Position               = UDim2.fromOffset(20, 14),
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = ThemeEngine.GetToken("Text"),
        TextSize               = 13,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextTruncate           = Enum.TextTruncate.AtEnd,
        ZIndex                 = 202,
        Parent                 = card,
    })

    -- Message (optional)
    local messageLabel
    if hasMessage then
        messageLabel = ComponentHelper.Create("TextLabel", {
            Name                   = "Message",
            Size                   = UDim2.new(1, -36, 0, 28),
            Position               = UDim2.fromOffset(20, 34),
            BackgroundTransparency = 1,
            Text                   = message,
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextSize               = 11,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            ZIndex                 = 202,
            Parent                 = card,
        })
    end

    -- Action row — anchored to bottom of card
    local actionRow = ComponentHelper.Create("Frame", {
        Name                   = "ActionRow",
        Size                   = UDim2.new(1, -32, 0, 28),
        Position               = UDim2.new(0, 16, 1, -42),
        BackgroundTransparency = 1,
        ZIndex                 = 202,
        Parent                 = card,
    })
    ComponentHelper.AddListLayout(actionRow, {
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 8),
    })

    -- Cancel button (ghost style)
    local cancelBtn
    if hasCancel then
        cancelBtn = ComponentHelper.Create("TextButton", {
            Name                   = "CancelBtn",
            Size                   = UDim2.fromOffset(72, 28),
            BackgroundColor3       = ThemeEngine.GetToken("Surface"),
            BackgroundTransparency = 0.4,
            AutoButtonColor        = false,
            Text                   = cancelCfg.Label or "Cancel",
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextSize               = 11,
            Font                   = Enum.Font.GothamBold,
            ZIndex                 = 203,
            LayoutOrder            = 1,
            Parent                 = actionRow,
        })
        ComponentHelper.AddCorner(cancelBtn, 6)
        ComponentHelper.AddStroke(cancelBtn, ThemeEngine.GetToken("Border"), 1)
    end

    -- Confirm button (colored by type)
    local confirmBtn = ComponentHelper.Create("TextButton", {
        Name             = "ConfirmBtn",
        Size             = UDim2.fromOffset(72, 28),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        AutoButtonColor  = false,
        Text             = confirmCfg.Label or "Confirm",
        TextColor3       = Color3.fromRGB(255, 255, 255),
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 203,
        LayoutOrder      = 2,
        Parent           = actionRow,
    })
    ComponentHelper.AddCorner(confirmBtn, 6)

    -- ─── Handle ───────────────────────────────────────────────────────────────

    local handle    = {}
    local _alive    = true
    local themeDisc = nil

    local function _dismiss(onDone)
        if not _alive then return end
        _alive        = false
        _activeDialog = nil

        if themeDisc then themeDisc() end

        AnimationEngine.FadeOut(card, TweenHelper.FastInfo)
        AnimationEngine.Play(backdrop, TweenHelper.FastInfo,
            { BackgroundTransparency = 1 }, "dlg_bg")

        task.delay((TweenHelper.FastInfo.Time or 0.12) + 0.02, function()
            if backdrop and backdrop.Parent then
                backdrop:Destroy()
            end
            if onDone then task.spawn(onDone) end
        end)
    end

    -- Theme listener (ephemeral — only during dialog lifetime)
    themeDisc = ThemeEngine.OnThemeChanged(function(tokens)
        if not _alive then return end
        card.BackgroundColor3       = tokens.Surface
        cardStroke.Color            = tokens.Border
        typeBar.BackgroundColor3    = tokens[accentToken] or tokens.Accent
        titleLabel.TextColor3       = tokens.Text
        if messageLabel then
            messageLabel.TextColor3 = tokens.SubText
        end
        if cancelBtn then
            cancelBtn.BackgroundColor3 = tokens.Surface
        end
    end)

    -- Button hover feedback
    if cancelBtn then
        cancelBtn.MouseEnter:Connect(function()
            TweenHelper.Tween(cancelBtn, TweenHelper.FastInfo,
                { BackgroundTransparency = 0.15 }, "cbhov")
        end)
        cancelBtn.MouseLeave:Connect(function()
            TweenHelper.Tween(cancelBtn, TweenHelper.FastInfo,
                { BackgroundTransparency = 0.4 }, "cbhov")
        end)
    end

    confirmBtn.MouseEnter:Connect(function()
        TweenHelper.Tween(confirmBtn, TweenHelper.FastInfo,
            { BackgroundTransparency = 0.18 }, "cfhov")
    end)
    confirmBtn.MouseLeave:Connect(function()
        TweenHelper.Tween(confirmBtn, TweenHelper.FastInfo,
            { BackgroundTransparency = 0 }, "cfhov")
    end)

    -- Button click wiring
    if cancelBtn then
        cancelBtn.MouseButton1Click:Connect(function()
            _dismiss(cancelCfg.Callback)
        end)
    end

    confirmBtn.MouseButton1Click:Connect(function()
        _dismiss(confirmCfg.Callback)
    end)

    -- Backdrop click = cancel (only when cancel button is present)
    if hasCancel and backdropClass == "TextButton" then
        backdrop.MouseButton1Click:Connect(function()
            _dismiss(cancelCfg.Callback)
        end)
    end

    -- Programmatic dismiss
    function handle:Dismiss()
        _dismiss(cancelCfg and cancelCfg.Callback)
    end

    return handle, backdrop, card
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Show a modal confirmation dialog. Returns a handle with :Dismiss().
-- Only one dialog can be active at a time.
function DialogService.Confirm(config: table)
    assert(_initialized,
        "DialogService.Init(screenGui) must be called before Confirm()")
    assert(type(config) == "table",
        "DialogService.Confirm expects a config table")

    if _activeDialog then
        warn("[DialogService] A dialog is already active — dismiss it before showing another.")
        return nil
    end

    local handle, backdrop, card = _buildDialog(config)
    _activeDialog = handle

    -- Animate backdrop in
    AnimationEngine.Play(backdrop, TweenHelper.DefaultInfo,
        { BackgroundTransparency = BACKDROP_ALPHA }, "dlg_bg")

    -- Animate card in (FadeIn + Pop run in parallel via different keys)
    AnimationEngine.FadeIn(card, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(card, 0.88, AnimationEngine.Preset.Spring)

    return handle
end

-- ─── Self-register ────────────────────────────────────────────────────────────

ServiceRegistry.Register("DialogService", {
    Reset = DialogService.Reset,
    Init  = DialogService.Init,
}, 55)  -- priority 55: after ThemeEngine (10) and NotificationService (50)

return DialogService
