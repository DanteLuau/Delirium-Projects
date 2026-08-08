-- Services/NotificationService.lua
-- Stacked toast notifications anchored to the top-right of the screen.
--
-- Types:     Info | Success | Warning | Error
-- Features:  Auto-dismiss timeout, timeout progress bar, action button,
--            persistent mode (no auto-dismiss), runtime update (title/message),
--            max-visible cap with overflow queue.
--
-- Initialization:
--   NotificationService.Init(screenGui)  -- called once from Delirium init
--
-- Usage:
--   local handle = NotificationService.Push({
--       Type        = "Success",           -- "Info"|"Success"|"Warning"|"Error"
--       Title       = "Saved",
--       Message     = "Config saved.",     -- optional
--       Duration    = 4,                   -- seconds (0 or nil = persistent)
--       Action      = { Label = "Undo", Callback = function() end },  -- optional
--   })
--   handle:SetMessage("Updated message")
--   handle:Dismiss()

local TweenService     = game:GetService("TweenService")
local Root             = script.Parent.Parent
local ThemeEngine      = require(Root.Core.ThemeEngine)
local AnimationEngine  = require(Root.Core.AnimationEngine)
local ComponentHelper  = require(Root.Utilities.ComponentHelper)

-- ─── Constants ────────────────────────────────────────────────────────────────

local MAX_VISIBLE     = 4        -- maximum toasts shown at once
local NOTIF_WIDTH     = 300      -- pixels
local NOTIF_GAP       = 8        -- gap between toasts
local MARGIN          = 14       -- margin from screen edge
local ANIM_IN_OFFSET  = 24       -- pixels right-offset for slide-in
local ANIM_SLIDE_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local ANIM_OUT_INFO   = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local ANIM_RESTACK    = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

-- Type → accent token mapping
local TYPE_TOKEN = {
    Info    = "Accent",
    Success = "Positive",
    Warning = "Warning",
    Error   = "Error",
}

-- ─── State ────────────────────────────────────────────────────────────────────

local NotificationService = {}

local _container: Frame    = nil   -- UIListLayout parent
local _queue:     table    = {}    -- waiting notifications (overflow)
local _visible:   table    = {}    -- currently shown notification handles
local _initialized         = false

-- ─── Initialization ───────────────────────────────────────────────────────────

-- Must be called once with the root ScreenGui before any Push calls.
function NotificationService.Init(screenGui: ScreenGui)
    if _initialized then return end
    _initialized = true

    _container = ComponentHelper.Create("Frame", {
        Name            = "DeliriumNotifications",
        AnchorPoint     = Vector2.new(1, 0),
        Position        = UDim2.new(1, -MARGIN, 0, MARGIN),
        Size            = UDim2.new(0, NOTIF_WIDTH, 1, -MARGIN * 2),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex          = 100,
        Parent          = screenGui,
    })

    ComponentHelper.Create("UIListLayout", {
        SortOrder        = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Top,
        Padding          = UDim.new(0, NOTIF_GAP),
        Parent           = _container,
    })
end

-- ─── Internal helpers ─────────────────────────────────────────────────────────

-- Re-assigns LayoutOrder to all visible toasts so the UIListLayout
-- respects insertion order consistently.
local function _restack()
    for i, h in ipairs(_visible) do
        h._frame.LayoutOrder = i
    end
end

-- Drain one item from the overflow queue into the visible stack (if room).
local function _drainQueue()
    if #_visible >= MAX_VISIBLE then return end
    local next = table.remove(_queue, 1)
    if next then next:_show() end
end

-- Remove a handle from the visible list and restack.
local function _removeVisible(handle)
    for i, h in ipairs(_visible) do
        if h == handle then
            table.remove(_visible, i)
            break
        end
    end
    _restack()
    _drainQueue()
end

-- ─── Notification handle constructor ─────────────────────────────────────────

local function _buildHandle(config: table)
    local notifType  = config.Type     or "Info"
    local title      = config.Title    or "Notification"
    local message    = config.Message  or ""
    local duration   = config.Duration  -- nil or 0 = persistent
    local action     = config.Action    -- optional {Label, Callback}
    local hasMessage = message ~= ""
    local hasAction  = action ~= nil

    -- Height calculation
    local baseH     = 52
    if hasMessage then baseH += 22 end
    if hasAction  then baseH += 34 end

    local accentToken = TYPE_TOKEN[notifType] or "Accent"

    -- ─── Frame ──────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "Notification_" .. notifType,
        Size             = UDim2.new(1, 0, 0, baseH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        -- Start off-screen to the right; _show() slides it in.
        Position         = UDim2.new(0, NOTIF_WIDTH + ANIM_IN_OFFSET, 0, 0),
        LayoutOrder      = 0,
        Parent           = _container,
    })
    ComponentHelper.AddCorner(frame, 8)
    ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)

    -- Colored left bar
    local colorBar = ComponentHelper.Create("Frame", {
        Name             = "ColorBar",
        Size             = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = frame,
    })
    ComponentHelper.AddCorner(colorBar, 2)

    -- Content area (left-padded past the color bar)
    local content = ComponentHelper.Create("Frame", {
        Name               = "Content",
        Position           = UDim2.new(0, 12, 0, 0),
        Size               = UDim2.new(1, -28, 0, baseH),
        BackgroundTransparency = 1,
        Parent             = frame,
    })
    ComponentHelper.AddPadding(content, 10, 10, 0, 28)

    -- Title
    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 13,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        ZIndex             = 3,
        Parent             = content,
    })

    -- Message
    local messageLabel
    if hasMessage then
        messageLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Message",
            Position           = UDim2.new(0, 0, 0, 20),
            Size               = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            Text               = message,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextTruncate       = Enum.TextTruncate.AtEnd,
            ZIndex             = 3,
            Parent             = content,
        })
    end

    -- Action button
    local actionBtn
    if hasAction then
        local actionY = hasMessage and 44 or 24
        actionBtn = ComponentHelper.Create("TextButton", {
            Name             = "ActionButton",
            Position         = UDim2.new(0, 0, 0, actionY),
            Size             = UDim2.new(0, 80, 0, 22),
            BackgroundColor3 = ThemeEngine.GetToken(accentToken),
            AutoButtonColor  = false,
            Text             = action.Label or "Action",
            TextColor3       = ThemeEngine.GetToken("AccentText"),
            TextSize         = 11,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 3,
            Parent           = content,
        })
        ComponentHelper.AddCorner(actionBtn, 5)
        actionBtn.MouseButton1Click:Connect(function()
            if action.Callback then
                task.spawn(action.Callback)
            end
        end)
    end

    -- Close button (×)
    local closeBtn = ComponentHelper.Create("TextButton", {
        Name               = "CloseBtn",
        AnchorPoint        = Vector2.new(1, 0),
        Position           = UDim2.new(1, -6, 0, 6),
        Size               = UDim2.new(0, 18, 0, 18),
        BackgroundTransparency = 1,
        Text               = "×",
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 16,
        Font               = Enum.Font.GothamBold,
        ZIndex             = 4,
        Parent             = frame,
    })

    -- Timeout progress bar (shrinks width from right to left)
    local progressBg = ComponentHelper.Create("Frame", {
        Name             = "ProgressBg",
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = frame,
    })

    local progressFill = ComponentHelper.Create("Frame", {
        Name             = "ProgressFill",
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = progressBg,
    })

    -- Hide progress bar if persistent
    if not duration or duration <= 0 then
        progressBg.Visible = false
    end

    -- ─── Theme listener ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        frame.BackgroundColor3 = tokens.Surface
        colorBar.BackgroundColor3 = tokens[accentToken]
        titleLabel.TextColor3  = tokens.Text
        if messageLabel then messageLabel.TextColor3 = tokens.SubText end
        progressFill.BackgroundColor3 = tokens[accentToken]
        if actionBtn then actionBtn.BackgroundColor3 = tokens[accentToken] end
    end)

    -- ─── Handle object ──────────────────────────────────────────────────────

    local handle = {}
    handle._frame   = frame
    handle._alive   = true
    local _timer    = nil

    function handle:_show()
        table.insert(_visible, self)
        _restack()

        -- Slide in from the right.
        frame.Position = UDim2.new(0, NOTIF_WIDTH + ANIM_IN_OFFSET, 0, 0)
        AnimationEngine.Play(frame, ANIM_SLIDE_INFO,
            {Position = UDim2.fromScale(0, 0)}, "slide")

        -- Start timeout timer if duration is set.
        if duration and duration > 0 then
            local timerInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            local t = TweenService:Create(progressFill, timerInfo, {Size = UDim2.fromScale(0, 1)})
            t:Play()
            _timer = task.delay(duration, function()
                _timer = nil  -- clear before Dismiss; can't cancel the running thread
                if self._alive then self:Dismiss() end
            end)
        end
    end

    function handle:Dismiss()
        if not self._alive then return end
        self._alive = false
        if _timer then task.cancel(_timer) end
        themeDisconnect()

        -- Slide out to the right, then destroy.
        local t = AnimationEngine.Play(frame, ANIM_OUT_INFO,
            {Position = UDim2.new(0, NOTIF_WIDTH + ANIM_IN_OFFSET, 0, 0)}, "slide")
        if t then
            t.Completed:Connect(function()
                frame:Destroy()
            end)
        else
            frame:Destroy()
        end

        _removeVisible(self)
    end

    -- Runtime update helpers.
    function handle:SetTitle(text: string)
        titleLabel.Text = text
    end

    function handle:SetMessage(text: string)
        if messageLabel then messageLabel.Text = text end
    end

    -- Close button wires to Dismiss.
    closeBtn.MouseButton1Click:Connect(function()
        handle:Dismiss()
    end)

    return handle
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Push a notification. Returns a handle with :Dismiss(), :SetTitle(), :SetMessage().
function NotificationService.Push(config: table)
    assert(_initialized,
        "NotificationService.Init(screenGui) must be called before Push()")
    assert(type(config) == "table", "NotificationService.Push expects a config table")

    local handle = _buildHandle(config)

    if #_visible < MAX_VISIBLE then
        handle:_show()
    else
        -- Queue it; it will show automatically once a slot opens.
        table.insert(_queue, handle)
    end

    return handle
end

-- Dismiss every active notification immediately.
function NotificationService.DismissAll()
    -- Copy the list since Dismiss modifies _visible.
    local snapshot = {table.unpack(_visible)}
    for _, h in ipairs(snapshot) do
        h:Dismiss()
    end
    _queue = {}
end

-- Full reset — called by Bootstrap before creating a new session.
-- Clears all module-level state so Init() can be safely called again.
function NotificationService.Reset()
    local snapshot = {table.unpack(_visible)}
    for _, h in ipairs(snapshot) do
        pcall(function() h:Dismiss() end)
    end
    table.clear(_visible)
    table.clear(_queue)
    -- _container belongs to the old ScreenGui; Bootstrap destroys that separately
    _container   = nil
    _initialized = false
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = require(Root.Core.ServiceRegistry)

ServiceRegistry.Register("NotificationService", {
    Reset = NotificationService.Reset,
    Init  = NotificationService.Init,
}, 50)  -- priority 50 — inits after ThemeEngine (10) since it reads theme tokens

return NotificationService
