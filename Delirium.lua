-- Delirium v1.0.0
-- GENERATED FILE
-- DO NOT EDIT
--
-- Built with bundle.py — do not edit directly
-- Source: github.com/DanteLuau/Delirium-Projects

local _Delirium_modules = {}
local _Delirium_loaded  = {}
local _Delirium_nil     = {} -- sentinel: module returned nil

local function _Delirium_require(name)
    if _Delirium_loaded[name] == nil then
        local mod = _Delirium_modules[name]
        assert(mod, '[Delirium] Unknown module: ' .. tostring(name))
        local result = mod()
        _Delirium_loaded[name] = (result == nil) and _Delirium_nil or result
    end
    local v = _Delirium_loaded[name]
    return (v == _Delirium_nil) and nil or v
end

-- ── Utilities.ComponentHelper ─────────────────────────────
_Delirium_modules["Utilities.ComponentHelper"] = function()
-- Utilities/ComponentHelper.lua
-- Instance creation and decorator helpers.
-- Every Add* function parents the created constraint to `parent` AND returns it,
-- so callers can keep a reference if they need runtime updates.

local ComponentHelper = {}

-- ─── Core factory ──────────────────────────────────────────────────────────

-- Create an Instance, apply a property table, and optionally parent children.
-- Children (if provided) must be a sequential table of Instance values.
function ComponentHelper.Create(className: string, properties: table?, children: table?): Instance
    local instance = Instance.new(className)

    if properties then
        for prop, val in pairs(properties) do
            if prop ~= "Parent" then
                instance[prop] = val
            end
        end
        -- Set Parent last to avoid partial-parented Instance warnings.
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end

    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end

    return instance
end

-- ─── Decorators ─────────────────────────────────────────────────────────────

function ComponentHelper.AddCorner(parent: Instance, radius: number?): UICorner
    return ComponentHelper.Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent       = parent,
    })
end

function ComponentHelper.AddStroke(
    parent:    Instance,
    color:     Color3?,
    thickness: number?
): UIStroke
    return ComponentHelper.Create("UIStroke", {
        Color           = color or Color3.fromRGB(45, 45, 55),
        Thickness       = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent          = parent,
    })
end

function ComponentHelper.AddPadding(
    parent: Instance,
    top:    number?,
    bottom: number?,
    left:   number?,
    right:  number?
): UIPadding
    return ComponentHelper.Create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 12),
        PaddingRight  = UDim.new(0, right  or 12),
        Parent        = parent,
    })
end

-- ─── Layout helpers ─────────────────────────────────────────────────────────

-- Creates a UIListLayout inside `parent`.
-- opts: { SortOrder?, FillDirection?, Padding?, HorizontalAlignment?, VerticalAlignment? }
function ComponentHelper.AddListLayout(parent: Instance, opts: table?): UIListLayout
    opts = opts or {}
    return ComponentHelper.Create("UIListLayout", {
        SortOrder           = opts.SortOrder           or Enum.SortOrder.LayoutOrder,
        FillDirection       = opts.FillDirection       or Enum.FillDirection.Vertical,
        Padding             = opts.Padding             or UDim.new(0, 8),
        HorizontalAlignment = opts.HorizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = opts.VerticalAlignment   or Enum.VerticalAlignment.Top,
        Parent              = parent,
    })
end

-- Creates a UIGridLayout inside `parent`.
-- opts.CellPadding: UDim2   — explicit padding (takes priority)
-- opts.CellPaddingH: number — pixel gap between columns (convenience)
-- opts.CellPaddingV: number — pixel gap between rows   (convenience)
function ComponentHelper.AddGridLayout(parent: Instance, opts: table?): UIGridLayout
    opts = opts or {}
    -- UIGridLayout.CellPadding is a UDim2. Build it from convenience opts if needed.
    local cellPad: UDim2
    if opts.CellPadding then
        cellPad = opts.CellPadding
    else
        cellPad = UDim2.new(0, opts.CellPaddingH or 4, 0, opts.CellPaddingV or 4)
    end
    return ComponentHelper.Create("UIGridLayout", {
        SortOrder     = opts.SortOrder     or Enum.SortOrder.LayoutOrder,
        CellSize      = opts.CellSize      or UDim2.new(0.5, -4, 0, 36),
        CellPadding   = cellPad,
        FillDirection = opts.FillDirection or Enum.FillDirection.Horizontal,
        Parent        = parent,
    })
end

-- ─── Batch token helper ─────────────────────────────────────────────────────

-- Apply multiple theme tokens to a single instance in one call.
-- tokenMap: { [PropertyName] = TokenName, ... }
-- theme:    table from ThemeEngine.GetTokens() or ThemeEngine.GetToken()
--
-- Example:
--   ComponentHelper.ApplyTokens(frame, {
--       BackgroundColor3 = "Surface",
--       BorderColor3     = "Border",
--   }, ThemeEngine.GetTokens())
function ComponentHelper.ApplyTokens(instance: Instance, tokenMap: table, theme: table)
    for prop, tokenName in pairs(tokenMap) do
        local value = theme[tokenName]
        if value ~= nil then
            instance[prop] = value
        else
            warn(string.format(
                "ComponentHelper.ApplyTokens: token '%s' not found in theme (property '%s')",
                tostring(tokenName), tostring(prop)
            ))
        end
    end
end

-- ─── Constraint helpers ──────────────────────────────────────────────────────

-- Locks min/max pixel size on a parent.
function ComponentHelper.AddSizeConstraint(
    parent: Instance,
    minSize: Vector2?,
    maxSize: Vector2?
): UISizeConstraint
    return ComponentHelper.Create("UISizeConstraint", {
        MinSize = minSize or Vector2.new(0, 0),
        MaxSize = maxSize or Vector2.new(math.huge, math.huge),
        Parent  = parent,
    })
end

-- Enforces a fixed width/height ratio on a parent.
function ComponentHelper.AddAspectRatio(
    parent:          Instance,
    ratio:           number,
    dominantAxis:    Enum.DominantAxis?,
    aspectType:      Enum.AspectType?
): UIAspectRatioConstraint
    return ComponentHelper.Create("UIAspectRatioConstraint", {
        AspectRatio  = ratio,
        DominantAxis = dominantAxis or Enum.DominantAxis.Width,
        AspectType   = aspectType   or Enum.AspectType.FitWithinMaxSize,
        Parent       = parent,
    })
end

-- Constrains text size to a min/max pixel range.
-- Useful for responsive text that scales with container size.
function ComponentHelper.AddTextSizeConstraint(
    parent:  Instance,
    minSize: number?,
    maxSize: number?
): UITextSizeConstraint
    return ComponentHelper.Create("UITextSizeConstraint", {
        MinTextSize = minSize or 10,
        MaxTextSize = maxSize or 24,
        Parent      = parent,
    })
end

-- ─── Gradient helper ─────────────────────────────────────────────────────────

-- Creates a UIGradient inside `parent`.
-- colors: ColorSequence | array of {time, Color3} keypoints
-- transparency: optional NumberSequence
function ComponentHelper.AddGradient(
    parent:       Instance,
    colors:       ColorSequence | table,
    rotation:     number?,
    transparency: NumberSequence?
): UIGradient
    local colorSeq: ColorSequence
    if typeof(colors) == "ColorSequence" then
        colorSeq = colors
    else
        -- Build from keypoint array: {{0, Color3}, {1, Color3}, ...}
        local kps = {}
        for _, kp in ipairs(colors) do
            table.insert(kps, ColorSequenceKeypoint.new(kp[1], kp[2]))
        end
        colorSeq = ColorSequence.new(kps)
    end

    return ComponentHelper.Create("UIGradient", {
        Color        = colorSeq,
        Rotation     = rotation     or 0,
        Transparency = transparency or NumberSequence.new(0),
        Parent       = parent,
    })
end

return ComponentHelper

end

-- ── Utilities.Signal ──────────────────────────────────────
_Delirium_modules["Utilities.Signal"] = function()
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
    -- BUG-B fix: guard against Fire() being called after Destroy().
    -- Destroy() sets _handlers = nil; ipairs(nil) would error without this check.
    if not self._handlers then return end
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
end

-- ── Utilities.TweenHelper ─────────────────────────────────
_Delirium_modules["Utilities.TweenHelper"] = function()
-- Utilities/TweenHelper.lua
-- Thin wrapper kept for backward compatibility with existing component code.
-- All preset TweenInfos mirror AnimationEngine.Preset.
-- New code should prefer AnimationEngine directly.

local TweenService     = game:GetService("TweenService")
local AnimationEngine  = _Delirium_require("Core.AnimationEngine")

local TweenHelper = {}

-- ─── Preset TweenInfos (backward compat) ──────────────────────────────────

TweenHelper.FastInfo    = AnimationEngine.Preset.Fast
TweenHelper.DefaultInfo = AnimationEngine.Preset.Default
TweenHelper.SmoothInfo  = AnimationEngine.Preset.Smooth
TweenHelper.SpringInfo  = AnimationEngine.Preset.Spring
TweenHelper.SlowInfo    = AnimationEngine.Preset.Slow

-- ─── Core helpers ──────────────────────────────────────────────────────────

-- Interrupt-safe tween. Delegates to AnimationEngine so concurrent calls on
-- the same instance+key cancel each other instead of stacking.
-- key is optional; defaults to "default" (all calls without a key share one slot).
function TweenHelper.Tween(
    instance:   Instance,
    tweenInfo:  TweenInfo?,
    properties: table,
    key:        string?
): Tween?
    return AnimationEngine.Play(instance, tweenInfo, properties, key)
end

-- Cancel all active tweens on an instance.
function TweenHelper.Cancel(instance: Instance, key: string?)
    AnimationEngine.Cancel(instance, key)
end

-- Hover helpers — returns {Enter, Leave} for connecting to MouseEnter/Leave.
-- Prefer using InputAdapter.BindAdaptiveInteraction for full cross-platform support.
function TweenHelper.BindHover(
    instance:    Instance,
    hoverProps:  table,
    normalProps: table
): {Enter: ()->(), Leave: ()->()}
    return {
        Enter = function()
            TweenHelper.Tween(instance, TweenHelper.FastInfo, hoverProps, "hover")
        end,
        Leave = function()
            TweenHelper.Tween(instance, TweenHelper.FastInfo, normalProps, "hover")
        end,
    }
end

return TweenHelper

end

-- ── Core.AnimationEngine ──────────────────────────────────
_Delirium_modules["Core.AnimationEngine"] = function()
-- Core/AnimationEngine.lua
-- Interrupt-safe animation layer. Always cancel the in-flight tween before
-- starting a new one on the same instance+key, so rapid state changes never
-- stack or fight each other.
--
-- Usage:
--   local AnimationEngine = _Delirium_require("Core.AnimationEngine")
--   AnimationEngine.Play(frame, AnimationEngine.Preset.Spring, { Size = ... }, "resize")
--   AnimationEngine.SlideIn(frame, "Bottom", 20)
--   AnimationEngine.FadeIn(frame)

local TweenService = game:GetService("TweenService")

-- ─── Presets ──────────────────────────────────────────────────────────────────

local Preset = {
    Instant = TweenInfo.new(0,    Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    Fast    = TweenInfo.new(0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Default = TweenInfo.new(0.25, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Smooth  = TweenInfo.new(0.35, Enum.EasingStyle.Cubic,  Enum.EasingDirection.Out),
    Spring  = TweenInfo.new(0.40, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    Bounce  = TweenInfo.new(0.50, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Slow    = TweenInfo.new(0.60, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
}

-- ─── State ────────────────────────────────────────────────────────────────────

-- Weak keys so destroyed instances don't prevent garbage collection.
local _active: {[Instance]: {[string]: Tween}} = setmetatable({}, {__mode = "k"})

local AnimationEngine = {
    Preset        = Preset,
    ReducedMotion = false,  -- set true for accessibility / testing
}

-- ─── Core ─────────────────────────────────────────────────────────────────────

-- Play a tween, cancelling any existing one registered under the same key.
-- key:  optional string that identifies this "slot" on the instance.
--       Two concurrent animations that share a key will interrupt each other.
--       Animations with different keys run in parallel without interference.
-- Returns the Tween so callers can :Wait() if they need sequencing.
function AnimationEngine.Play(
    instance:   Instance,
    tweenInfo:  TweenInfo?,
    props:      table,
    key:        string?
): Tween?
    if not instance or not instance.Parent then return nil end

    local info = AnimationEngine.ReducedMotion and Preset.Instant
        or tweenInfo or Preset.Default

    local slot = key or "__default__"

    -- Cancel the current occupant of this slot, if any.
    local bucket = _active[instance]
    if bucket then
        local existing = bucket[slot]
        if existing then
            existing:Cancel()
        end
    else
        _active[instance] = {}
        bucket = _active[instance]
    end

    local tween = TweenService:Create(instance, info, props)
    bucket[slot] = tween

    tween.Completed:Connect(function()
        -- Only clear if we're still the registered tween (not already replaced).
        if _active[instance] and _active[instance][slot] == tween then
            _active[instance][slot] = nil
        end
    end)

    tween:Play()
    return tween
end

-- Cancel all active tweens on an instance (or only those under a specific key).
function AnimationEngine.Cancel(instance: Instance, key: string?)
    if not _active[instance] then return end
    if key then
        local t = _active[instance][key]
        if t then
            t:Cancel()
            _active[instance][key] = nil
        end
    else
        for k, t in pairs(_active[instance]) do
            t:Cancel()
            _active[instance][k] = nil
        end
    end
end

-- ─── Convenience helpers ──────────────────────────────────────────────────────

-- Fade a GuiObject to fully opaque. Applies BackgroundTransparency always;
-- also fades TextTransparency on text instances and ImageTransparency on image instances.
-- `fromAlpha`: if provided, all applicable transparencies are snapped to this first.
function AnimationEngine.FadeIn(
    instance:  GuiObject,
    fromAlpha: number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end

    local props = {}

    -- Background — all GuiObjects
    if fromAlpha ~= nil then instance.BackgroundTransparency = fromAlpha end
    props.BackgroundTransparency = 0

    -- Text transparency
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        if fromAlpha ~= nil then instance.TextTransparency = fromAlpha end
        props.TextTransparency = 0
    end

    -- Image transparency
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        if fromAlpha ~= nil then instance.ImageTransparency = fromAlpha end
        props.ImageTransparency = 0
    end

    return AnimationEngine.Play(instance, info or Preset.Default, props, "fade")
end

-- Fade a GuiObject to fully transparent. Mirrors FadeIn target properties.
function AnimationEngine.FadeOut(instance: GuiObject, info: TweenInfo?): Tween?
    if not instance or not instance.Parent then return nil end

    local props = { BackgroundTransparency = 1 }

    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        props.TextTransparency = 1
    end
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        props.ImageTransparency = 1
    end

    return AnimationEngine.Play(instance, info or Preset.Default, props, "fade")
end

-- Slide a GuiObject in from a direction by offsetting its position.
-- direction: "Top" | "Bottom" | "Left" | "Right"
-- distance:  pixel offset to start from (default 20)
function AnimationEngine.SlideIn(
    instance:  GuiObject,
    direction: string,
    distance:  number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end
    local d          = distance or 20
    local targetPos  = instance.Position
    local ox, oy     = 0, 0

    if direction == "Top"    then oy = -d end
    if direction == "Bottom" then oy =  d end
    if direction == "Left"   then ox = -d end
    if direction == "Right"  then ox =  d end

    instance.Position = UDim2.new(
        targetPos.X.Scale, targetPos.X.Offset + ox,
        targetPos.Y.Scale, targetPos.Y.Offset + oy
    )
    return AnimationEngine.Play(instance, info or Preset.Smooth,
        {Position = targetPos}, "slide")
end

-- Slide a GuiObject out toward a direction.
-- targetPos is optional; if omitted the current position is used as base.
function AnimationEngine.SlideOut(
    instance:  GuiObject,
    direction: string,
    distance:  number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end
    local d         = distance or 20
    local basePos   = instance.Position
    local ox, oy    = 0, 0

    if direction == "Top"    then oy = -d end
    if direction == "Bottom" then oy =  d end
    if direction == "Left"   then ox = -d end
    if direction == "Right"  then ox =  d end

    return AnimationEngine.Play(instance, info or Preset.Smooth, {
        Position = UDim2.new(
            basePos.X.Scale, basePos.X.Offset + ox,
            basePos.Y.Scale, basePos.Y.Offset + oy
        )
    }, "slide")
end

-- Quick spring pop — scales size from `fromScale` factor to full size.
-- Compensates AnchorPoint so the element scales from its visual center,
-- not from the top-left corner. Original AnchorPoint and Position are restored
-- after the tween completes.
function AnimationEngine.Pop(
    instance:  GuiObject,
    fromScale: number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end

    local f          = fromScale or 0.88
    local finalSize  = instance.Size
    local origAnchor = instance.AnchorPoint
    local origPos    = instance.Position

    -- Rebase to center anchor so scaling appears to grow from the visual center.
    -- Compensate position to keep the element visually in the same spot.
    local adjX = finalSize.X.Offset * (0.5 - origAnchor.X)
    local adjY = finalSize.Y.Offset * (0.5 - origAnchor.Y)
    instance.AnchorPoint = Vector2.new(0.5, 0.5)
    instance.Position    = UDim2.new(
        origPos.X.Scale, origPos.X.Offset + adjX,
        origPos.Y.Scale, origPos.Y.Offset + adjY
    )

    -- Start scaled-down
    instance.Size = UDim2.new(
        finalSize.X.Scale * f, finalSize.X.Offset * f,
        finalSize.Y.Scale * f, finalSize.Y.Offset * f
    )

    local tween = AnimationEngine.Play(instance, info or Preset.Spring,
        { Size = finalSize }, "pop")

    -- Restore original anchor/position after spring settles
    if tween then
        tween.Completed:Connect(function()
            if instance and instance.Parent then
                instance.AnchorPoint = origAnchor
                instance.Position    = origPos
            end
        end)
    end

    return tween
end

-- Pulse: attention-grab ping-pong scale. Does NOT interrupt running tweens
-- on other keys. Runs `count` cycles then returns to original size.
-- Returns a cancel function that snaps back to original size immediately.
function AnimationEngine.Pulse(
    instance: GuiObject,
    scale:    number?,
    count:    number?,
    info:     TweenInfo?
): () -> ()
    if not instance or not instance.Parent then return function() end end

    local s        = scale or 1.05
    local times    = count or 2
    local pInfo    = info  or TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local origSize = instance.Size
    local cancelled = false

    task.spawn(function()
        for _ = 1, times do
            if cancelled or not instance.Parent then break end
            local big = UDim2.new(
                origSize.X.Scale * s, origSize.X.Offset * s,
                origSize.Y.Scale * s, origSize.Y.Offset * s
            )
            local t1 = AnimationEngine.Play(instance, pInfo, { Size = big }, "pulse")
            if t1 then t1.Completed:Wait() end
            if cancelled or not instance.Parent then break end
            local t2 = AnimationEngine.Play(instance, pInfo, { Size = origSize }, "pulse")
            if t2 then t2.Completed:Wait() end
        end
    end)

    return function()
        cancelled = true
        AnimationEngine.Cancel(instance, "pulse")
        if instance and instance.Parent then
            instance.Size = origSize
        end
    end
end

-- TypeWriter: reveals `text` one character at a time on a text instance.
-- `speed`: characters per second (default 30).
-- Returns a cancel function that snaps to full text.
function AnimationEngine.TypeWriter(
    instance:   TextLabel | TextButton | TextBox,
    text:       string,
    speed:      number?,
    onComplete: (()->())?
): () -> ()
    if not instance or not instance.Parent then return function() end end

    local interval  = 1 / (speed or 30)
    local cancelled = false
    instance.Text   = ""

    task.spawn(function()
        for i = 1, #text do
            if cancelled or not instance.Parent then break end
            instance.Text = string.sub(text, 1, i)
            task.wait(interval)
        end
        if not cancelled and instance.Parent then
            instance.Text = text
        end
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
    end)

    return function()
        cancelled = true
        if instance and instance.Parent then
            instance.Text = text  -- snap to full
        end
    end
end

-- ─── Sequencing ───────────────────────────────────────────────────────────────

-- Run a list of steps one after another.
-- Each step: { instance, info?, props, key? }
-- onComplete fires after the last step finishes.
-- Returns a cancel function — cancels the in-flight tween and skips remaining steps.
function AnimationEngine.Sequence(
    steps:      {{instance: Instance, info: TweenInfo?, props: table, key: string?}},
    onComplete: (()->())?
): () -> ()
    local cancelled = false

    task.spawn(function()
        for _, step in ipairs(steps) do
            if cancelled then break end
            local tween = AnimationEngine.Play(step.instance, step.info, step.props, step.key)
            if tween then tween.Completed:Wait() end
        end
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
    end)

    return function()
        cancelled = true
    end
end

-- Fire all steps simultaneously, then call onComplete after the longest one.
-- Returns a cancel function.
function AnimationEngine.Parallel(
    steps:      {{instance: Instance, info: TweenInfo?, props: table, key: string?}},
    onComplete: (()->())?
): () -> ()
    local cancelled = false
    local longest   = 0

    for _, step in ipairs(steps) do
        local tween = AnimationEngine.Play(step.instance, step.info, step.props, step.key)
        if tween then
            local t = step.info and step.info.Time or Preset.Default.Time
            if t > longest then longest = t end
        end
    end

    local thread = task.delay(longest, function()
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
    end)

    return function()
        cancelled = true
        pcall(task.cancel, thread)
    end
end

-- Stagger: animate a list of instances in sequence with a delay between each.
-- Each instance receives FadeIn + SlideIn from Bottom.
-- Returns a cancel function.
function AnimationEngine.Stagger(
    instances:  {GuiObject},
    delay:      number?,
    info:       TweenInfo?,
    onComplete: (()->())?
): () -> ()
    local d         = delay or 0.06
    local cancelled = false

    task.spawn(function()
        for _, inst in ipairs(instances) do
            if cancelled then break end
            if inst and inst.Parent then
                AnimationEngine.FadeIn(inst, 1, info or Preset.Default)
                AnimationEngine.SlideIn(inst, "Bottom", 12, info or Preset.Smooth)
            end
            task.wait(d)
        end
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
    end)

    return function()
        cancelled = true
    end
end

return AnimationEngine

end

-- ── Core.InputAdapter ─────────────────────────────────────
_Delirium_modules["Core.InputAdapter"] = function()
-- Core/InputAdapter.lua
-- Detects device type, input mode, orientation, and safe area.
-- Provides BindAdaptiveInteraction for cross-platform interaction binding.
--
-- Owns its UserInputService connection via Maid — safe to Reset() between execs.
--
-- Signals (stable refs — never replaced across Reset()):
--   InputAdapter.InputModeChanged  → fires(newMode: string)
--   InputAdapter.OrientationChanged → fires(newOrientation: string)

local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local Signal           = _Delirium_require("Utilities.Signal")
local Maid             = _Delirium_require("Core.Maid")

-- ─── Enums ───────────────────────────────────────────────────────────────────

local DeviceType = {
    Desktop = "Desktop",
    Tablet  = "Tablet",
    Phone   = "Phone",
    Console = "Console",
}

local InputMode = {
    Mouse    = "Mouse",
    Touch    = "Touch",
    Gamepad  = "Gamepad",
    Keyboard = "Keyboard",
}

-- ─── Internal helpers ─────────────────────────────────────────────────────────

local function classifyDevice(): string
    if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        return DeviceType.Console
    end
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local camera   = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        return math.min(viewport.X, viewport.Y) >= 600 and DeviceType.Tablet or DeviceType.Phone
    end
    return DeviceType.Desktop
end

local function classifyInputMode(inputType: Enum.UserInputType): string
    local name = inputType.Name
    if name:find("Mouse")   then return InputMode.Mouse   end
    if name:find("Touch")   then return InputMode.Touch   end
    if name:find("Gamepad") then return InputMode.Gamepad end
    return InputMode.Keyboard
end

-- ─── State ────────────────────────────────────────────────────────────────────

local _maid = Maid.new()

local InputAdapter = {
    DeviceType    = DeviceType,
    InputModeEnum = InputMode,

    CurrentDevice      = classifyDevice(),
    CurrentInputMode   = classifyInputMode(UserInputService:GetLastInputType()),
    CurrentOrientation = "Landscape",

    IsDesktop = false,
    IsPhone   = false,
    IsTablet  = false,
    IsConsole = false,
    IsTouch   = false,

    -- Stable Signal refs — NEVER replaced across Reset().
    -- Other modules hold these; replacing them would leave stale refs.
    InputModeChanged   = Signal.new(),
    OrientationChanged = Signal.new(),
}

local function _updateFlags()
    local d = InputAdapter.CurrentDevice
    InputAdapter.IsDesktop = d == DeviceType.Desktop
    InputAdapter.IsPhone   = d == DeviceType.Phone
    InputAdapter.IsTablet  = d == DeviceType.Tablet
    InputAdapter.IsConsole = d == DeviceType.Console
    InputAdapter.IsTouch   = d == DeviceType.Phone or d == DeviceType.Tablet
end

_updateFlags()

-- ─── Internal: wire managed connections ──────────────────────────────────────

local function _wireConnections()
    -- Input mode tracking
    _maid:GiveTask(
        UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
            local newMode = classifyInputMode(lastInputType)
            if newMode ~= InputAdapter.CurrentInputMode then
                InputAdapter.CurrentInputMode = newMode
                InputAdapter.InputModeChanged:Fire(newMode)
            end
        end)
    )

    -- Orientation tracking via camera viewport changes
    local camera = workspace.CurrentCamera
    if camera then
        local function checkOrientation()
            local vp  = camera.ViewportSize
            local ori = vp.X >= vp.Y and "Landscape" or "Portrait"
            if ori ~= InputAdapter.CurrentOrientation then
                InputAdapter.CurrentOrientation = ori
                InputAdapter.OrientationChanged:Fire(ori)
            end
        end
        _maid:GiveTask(
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(checkOrientation)
        )
        -- Sync initial value
        local vp  = camera.ViewportSize
        InputAdapter.CurrentOrientation = vp.X >= vp.Y and "Landscape" or "Portrait"
    end
end

_wireConnections()

-- ─── Reset (called by Bootstrap between execs) ────────────────────────────────

function InputAdapter.Reset()
    -- Disconnect all managed connections
    _maid:DoCleaning()

    -- Clear signal handlers WITHOUT replacing the Signal objects.
    -- External modules hold these refs; destroying/replacing them leaves stale refs.
    InputAdapter.InputModeChanged:DisconnectAll()
    InputAdapter.OrientationChanged:DisconnectAll()

    -- Reinitialize state
    InputAdapter.CurrentDevice      = classifyDevice()
    InputAdapter.CurrentInputMode   = classifyInputMode(UserInputService:GetLastInputType())
    InputAdapter.CurrentOrientation = InputAdapter.GetOrientation()
    _updateFlags()

    -- Fresh Maid and reconnect
    _maid = Maid.new()
    _wireConnections()
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Returns "Landscape" or "Portrait" based on current viewport.
function InputAdapter.GetOrientation(): string
    local camera   = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    return viewport.X >= viewport.Y and "Landscape" or "Portrait"
end

-- Returns safe area insets in pixels (accounts for Roblox topbar and notches).
function InputAdapter.GetSafeAreaInsets(): {Top: number, Bottom: number, Left: number, Right: number}
    local topLeft, bottomRight = GuiService:GetGuiInset()
    return {
        Top    = topLeft.Y,
        Bottom = bottomRight.Y,
        Left   = topLeft.X,
        Right  = bottomRight.X,
    }
end

--[[
    BindAdaptiveInteraction(guiObject, callbacks) → disconnect: () -> ()

    Binds adaptive callbacks based on the current device type.
    Returns a cleanup function — store it and call on component :Destroy().

    Callbacks (all optional):
        OnPress     — tap (touch) or left click (desktop)
        OnHover     — mouse enter (desktop only)
        OnHoverEnd  — mouse leave (desktop only)
        OnLongPress — hold (touch) or right click (desktop)
        OnScroll    — mouse wheel or touch scroll delta
]]
--[[
    BindAdaptiveInteraction(guiObject, callbacks) → disconnect: () -> ()

    Binds platform-appropriate callbacks. Evaluated at bind time from
    CurrentDevice; call again after a device switch for updated behavior.

    Callbacks (all optional):
        OnPress      — released tap (touch, no drag) or left click (desktop/gamepad)
        OnHover      — mouse enter (desktop only)
        OnHoverEnd   — mouse leave (desktop only)
        OnLongPress  — hold 0.5s (touch) or right-click (desktop)
        OnScroll     — mouse wheel Z delta (desktop) or touch scroll delta Y
]]
function InputAdapter.BindAdaptiveInteraction(guiObject: GuiObject, callbacks: table): () -> ()
    local localMaid = Maid.new()

    local function add(signal, fn)
        localMaid:GiveTask(signal:Connect(fn))
    end

    if InputAdapter.IsTouch then
        -- ── Touch ──────────────────────────────────────────────────────────
        local longThread    = nil
        local touchMoved    = false
        local LONG_DURATION = 0.5
        local MOVE_THRESH   = 8  -- pixels before we consider it a drag

        add(guiObject.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            touchMoved = false

            -- Long-press timer starts on finger-down
            if callbacks.OnLongPress then
                longThread = task.delay(LONG_DURATION, function()
                    if not touchMoved then
                        task.spawn(callbacks.OnLongPress)
                    end
                    longThread = nil
                end)
            end
        end)

        add(guiObject.InputChanged, function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            if input.Delta.Magnitude > MOVE_THRESH then
                touchMoved = true
                if longThread then
                    pcall(task.cancel, longThread)
                    longThread = nil
                end
                -- Touch scroll delta
                if callbacks.OnScroll then
                    callbacks.OnScroll(-input.Delta.Y)
                end
            end
        end)

        add(guiObject.InputEnded, function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            if longThread then
                pcall(task.cancel, longThread)
                longThread = nil
            end
            -- Only fire OnPress if the finger didn't drag (tap, not scroll)
            if not touchMoved and callbacks.OnPress then
                task.spawn(callbacks.OnPress)
            end
        end)

    elseif InputAdapter.IsConsole then
        -- ── Gamepad ────────────────────────────────────────────────────────
        -- GuiObject activation via Gamepad A button fires MouseButton1Click
        -- on focused elements; MouseEnter/Leave fire on selection change.
        if callbacks.OnPress    then add(guiObject.MouseButton1Click, callbacks.OnPress)    end
        if callbacks.OnHover    then add(guiObject.MouseEnter,        callbacks.OnHover)    end
        if callbacks.OnHoverEnd then add(guiObject.MouseLeave,        callbacks.OnHoverEnd) end

    else
        -- ── Desktop / Mouse ────────────────────────────────────────────────
        if callbacks.OnHover     then add(guiObject.MouseEnter,        callbacks.OnHover)     end
        if callbacks.OnHoverEnd  then add(guiObject.MouseLeave,        callbacks.OnHoverEnd)  end
        if callbacks.OnPress     then add(guiObject.MouseButton1Click, callbacks.OnPress)     end
        if callbacks.OnLongPress then add(guiObject.MouseButton2Click, callbacks.OnLongPress) end

        if callbacks.OnScroll then
            add(guiObject.InputChanged, function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    callbacks.OnScroll(input.Position.Z)
                end
            end)
        end
    end

    return function()
        localMaid:DoCleaning()
    end
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("InputAdapter", {
    Reset = InputAdapter.Reset,
}, 5)  -- priority 5 — resets first (other services may use InputAdapter)

return InputAdapter

end

-- ── Core.Maid ─────────────────────────────────────────────
_Delirium_modules["Core.Maid"] = function()
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

end

-- ── Core.Runtime ──────────────────────────────────────────
_Delirium_modules["Core.Runtime"] = function()
-- Core/Runtime.lua
-- Represents one active Delirium execution session.
--
-- Owns: services, windows, global resources.
-- Stored in _G[SESSION_KEY] so the next exec can detect and destroy it.
--
-- Usage (internal — called by Init.lua):
--   local runtime = Runtime.new()
--   runtime:IsAlive()
--   runtime:IsCurrent(sessionId)
--   runtime:Destroy()

local Maid = _Delirium_require("Core.Maid")

-- ─── ID generation ────────────────────────────────────────────────────────────

local function _generateId(): string
    return string.format("DLR_%x_%x", os.clock() * 1e6 // 1, math.random(0, 0xFFFF))
end

-- ─── Runtime ──────────────────────────────────────────────────────────────────

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new()
    local self = setmetatable({}, Runtime)

    self.SessionId  = _generateId()
    self._alive     = true
    self._maid      = Maid.new()

    -- Registered service objects (expose :Destroy())
    -- Keyed by name to prevent duplicates.
    self._services  = {}  -- { [name] = serviceObject }

    -- Owned windows
    self._windows   = {}

    return self
end

-- ── Query ──────────────────────────────────────────────────────────────────

function Runtime:IsAlive(): boolean
    return self._alive
end

-- Async stale-callback guard.
-- Usage: if not runtime:IsCurrent(capturedId) then return end
function Runtime:IsCurrent(sessionId: string): boolean
    return self._alive and self.SessionId == sessionId
end

-- ── Service management ────────────────────────────────────────────────────

-- Register a service by name.
-- If a service with the same name already exists, it is destroyed first.
-- service must expose :Destroy() or be a plain cleanup function.
function Runtime:RegisterService(name: string, service)
    assert(type(name) == "string" and #name > 0,
        "Runtime:RegisterService — name must be a non-empty string")

    local existing = self._services[name]
    if existing then
        -- Replace: destroy old registration before accepting new one
        pcall(function()
            if type(existing) == "function" then
                existing()
            elseif existing.Destroy then
                existing:Destroy()
            end
        end)
    end

    self._services[name] = service
end

function Runtime:GetService(name: string)
    return self._services[name]
end

-- ── Window management ─────────────────────────────────────────────────────

function Runtime:RegisterWindow(window)
    table.insert(self._windows, window)
end

-- ── Resource management ───────────────────────────────────────────────────

-- Give any resource to the runtime's own Maid.
function Runtime:OwnResource(task)
    self._maid:GiveTask(task)
end

-- ── Destruction ───────────────────────────────────────────────────────────

function Runtime:Destroy()
    if not self._alive then return end  -- idempotent
    self._alive = false

    -- 1. Destroy windows (cascade: Window → Tab → Section → Component)
    for _, win in ipairs(self._windows) do
        pcall(function() win:Destroy() end)
    end
    table.clear(self._windows)

    -- 2. Destroy services
    for name, service in pairs(self._services) do
        pcall(function()
            if type(service) == "function" then
                service()
            elseif service.Destroy then
                service:Destroy()
            end
        end)
        self._services[name] = nil
    end

    -- 3. Clean runtime-owned resources
    self._maid:DoCleaning()
end

return Runtime

end

-- ── Core.ServiceRegistry ──────────────────────────────────
_Delirium_modules["Core.ServiceRegistry"] = function()
-- Core/ServiceRegistry.lua
-- Lifecycle registry for Delirium services.
--
-- Services self-register at require() time.
-- Bootstrap calls ResetAll() / InitAll(gui) — never needs to know service names.
-- Duplicate names are rejected: re-registering the same name replaces the old entry
-- after safely destroying it.
--
-- Adding a new service:
--   1. Write Reset() and/or Init(gui) on your service module.
--   2. At the bottom of the file: ServiceRegistry.Register("Name", hooks, priority)
--   Done. Bootstrap picks it up automatically.

local _registry = {}      -- ordered array: { name, hooks, priority }
local _byName   = {}      -- name → index in _registry (for duplicate detection)

local ServiceRegistry = {}

-- Register a service.
--
-- name     : string   — unique identifier; duplicate names replace the old entry.
-- hooks    : table    — { Reset?: () -> (), Init?: (gui: ScreenGui) -> () }
-- priority : number?  — lower = runs first in ResetAll/InitAll (default 50)
function ServiceRegistry.Register(name: string, hooks: table, priority: number?)
    assert(type(name)  == "string" and #name > 0,
        "ServiceRegistry.Register: name must be a non-empty string")
    assert(type(hooks) == "table",
        "ServiceRegistry.Register: hooks must be a table")

    -- Duplicate prevention: destroy old entry before replacing
    local existingIdx = _byName[name]
    if existingIdx then
        local old = _registry[existingIdx]
        if old and type(old.hooks.Reset) == "function" then
            pcall(old.hooks.Reset)
        end
        table.remove(_registry, existingIdx)
        -- Rebuild name→index map after removal
        _byName = {}
        for i, entry in ipairs(_registry) do
            _byName[entry.name] = i
        end
    end

    local entry = {
        name     = name,
        hooks    = hooks,
        priority = priority or 50,
    }
    table.insert(_registry, entry)
    table.sort(_registry, function(a, b) return a.priority < b.priority end)

    -- Rebuild map after sort
    _byName = {}
    for i, e in ipairs(_registry) do
        _byName[e.name] = i
    end
end

-- Reset all registered services in priority order.
-- Called by Bootstrap before creating a new session.
function ServiceRegistry.ResetAll()
    for _, entry in ipairs(_registry) do
        if type(entry.hooks.Reset) == "function" then
            pcall(entry.hooks.Reset)
        end
    end
end

-- Initialize all registered services that have an Init hook.
-- Called by Bootstrap after the new ScreenGui is live.
function ServiceRegistry.InitAll(gui: ScreenGui)
    for _, entry in ipairs(_registry) do
        if type(entry.hooks.Init) == "function" then
            pcall(entry.hooks.Init, gui)
        end
    end
end

-- List registered services (debug).
function ServiceRegistry.List(): {string}
    local out = {}
    for _, entry in ipairs(_registry) do
        table.insert(out, string.format("[%d] %s", entry.priority, entry.name))
    end
    return out
end

return ServiceRegistry

end

-- ── Core.ThemeEngine ──────────────────────────────────────
_Delirium_modules["Core.ThemeEngine"] = function()
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

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("ThemeEngine", {
    Reset = ThemeEngine.ClearListeners,
    -- No Init: ThemeEngine does not need the ScreenGui
}, 10)  -- priority 10 — resets before services that depend on theme tokens

return ThemeEngine

end

-- ── Layout.Section ────────────────────────────────────────
_Delirium_modules["Layout.Section"] = function()
-- Layout/Section.lua
-- Owns its component handles. Cascade: Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local Root            = script.Parent.Parent
local ThemeEngine     = require(Root.Core.ThemeEngine)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local Maid            = require(Root.Core.Maid)

local Button      = require(Root.Components.Button)
local Toggle      = require(Root.Components.Toggle)
local Slider      = require(Root.Components.Slider)
local TextBox     = require(Root.Components.TextBox)
local Dropdown    = require(Root.Components.Dropdown)
local Keybind     = require(Root.Components.Keybind)
local ColorPicker = require(Root.Components.ColorPicker)
local Label       = require(Root.Components.Label)
local Paragraph   = require(Root.Components.Paragraph)
local Divider     = require(Root.Components.Divider)

local Section = {}
Section.__index = Section

function Section.new(title: string, parentContent: Instance)
    local self = setmetatable({}, Section)

    self.Title           = title or "Section"
    self._componentCount = 1
    self._destroyed      = false

    -- Owned children and resources
    self._handles = {}
    self._maid    = Maid.new()

    -- ─── Frame ─────────────────────────────────────────────────────────────

    self._collapsed = false
    self._contentH  = 0   -- cached content height (px) used when expanding

    -- Collapsed height: header (16px) + top padding (10) + bottom padding (10) = 36px
    local COLLAPSED_H = 36

    self.Frame = ComponentHelper.Create("Frame", {
        Name                   = "Section_" .. self.Title,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,   -- required: clips content when collapsed
        Parent                 = parentContent,
    })
    ComponentHelper.AddCorner(self.Frame, 8)
    local stroke = ComponentHelper.AddStroke(self.Frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(self.Frame, 10, 10, 10, 10)

    -- Store layout ref so SetCollapsed can read AbsoluteContentSize
    self._layout = ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
        Parent    = self.Frame,
    })

    self.HeaderLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "SectionHeader",
        Text                   = string.upper(self.Title),
        Font                   = Enum.Font.GothamBold,
        TextSize               = 11,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder            = 0,
        Parent                 = self.Frame,
    })

    -- Chevron indicator — child of HeaderLabel so it doesn't enter the UIListLayout
    self._chevron = ComponentHelper.Create("TextLabel", {
        Name                   = "Chevron",
        Size                   = UDim2.new(0, 14, 1, 0),
        Position               = UDim2.new(1, -2, 0, 0),
        AnchorPoint            = Vector2.new(1, 0),
        Text                   = "▾",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 11,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Parent                 = self.HeaderLabel,
    })

    -- Collapse toggle — TextLabels fire InputBegan on both mouse and touch
    self._maid:GiveTask(self.HeaderLabel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self:ToggleCollapsed()
        end
    end))

    -- ─── Theme listener ─────────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(self.Frame,       nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(stroke,           nil, { Color = tokens.Border })
        TweenHelper.Tween(self.HeaderLabel, nil, { TextColor3 = tokens.SubText })
        TweenHelper.Tween(self._chevron,    nil, { TextColor3 = tokens.SubText })
    end))

    return self
end

-- ─── Internal ──────────────────────────────────────────────────────────────

function Section:_nextOrder(): number
    local order = self._componentCount
    self._componentCount += 1
    return order
end

local function _applyOrder(frame: Instance, order: number)
    if frame then frame.LayoutOrder = order end
end

-- Track and return a component handle.
function Section:_register(handle)
    table.insert(self._handles, handle)
    return handle
end

-- ─── Component factory ─────────────────────────────────────────────────────

function Section:CreateButton(config: table)
    local h = Button.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddButton = Section.CreateButton

function Section:CreateToggle(config: table)
    local h = Toggle.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddToggle = Section.CreateToggle

function Section:CreateSlider(config: table)
    local h = Slider.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddSlider = Section.CreateSlider

function Section:CreateTextbox(config: table)
    local h = TextBox.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddTextbox = Section.CreateTextbox

function Section:CreateDropdown(config: table)
    local h = Dropdown.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddDropdown = Section.CreateDropdown

function Section:CreateKeybind(config: table)
    local h = Keybind.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddKeybind = Section.CreateKeybind

function Section:CreateColorPicker(config: table)
    local h = ColorPicker.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddColorPicker = Section.CreateColorPicker

function Section:CreateLabel(config: table)
    local h = Label.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddLabel = Section.CreateLabel

function Section:CreateParagraph(config: table)
    local h = Paragraph.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddParagraph = Section.CreateParagraph

function Section:CreateDivider(config: table)
    local h = Divider.New(self.Frame, config or {})
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddDivider = Section.CreateDivider

-- ─── Collapse system ──────────────────────────────────────────────────────────

-- BUG-A fix: ToggleCollapsed / SetCollapsed were never implemented.
-- The header's InputBegan handler called self:ToggleCollapsed() which didn't
-- exist → crash on every tap. Implemented here.
--
-- Strategy:
--   Collapse: capture AbsoluteSize.Y → disable AutomaticSize → tween to COLLAPSED_H.
--   Expand:   tween back to captured height → re-enable AutomaticSize so future
--             content additions keep working.
--   Both:     rotate chevron and toggle ClipsDescendants timing so content doesn't
--             peek before the frame shrinks.

local COLLAPSED_H = 36  -- header (16px) + top padding (10) + bottom padding (10)

function Section:SetCollapsed(collapsed: boolean, animate: boolean)
    if collapsed == self._collapsed then return end
    self._collapsed = collapsed

    -- Chevron: ▾ at 0° when expanded, rotated -90° when collapsed.
    local chevronRot = collapsed and -90 or 0
    if animate then
        TweenHelper.Tween(self._chevron, TweenHelper.FastInfo, { Rotation = chevronRot })
    else
        self._chevron.Rotation = chevronRot
    end

    if collapsed then
        -- Snapshot full height before disabling AutomaticSize.
        -- AbsoluteSize.Y reflects the current rendered height reliably here
        -- because we only collapse after the frame has already been laid out.
        self._contentH = self.Frame.AbsoluteSize.Y

        -- Stop AutomaticSize so we can manually drive the Size.
        self.Frame.AutomaticSize = Enum.AutomaticSize.None
        self.Frame.ClipsDescendants = true  -- already true, but be explicit

        if animate then
            TweenHelper.Tween(self.Frame, TweenHelper.FastInfo,
                { Size = UDim2.new(1, 0, 0, COLLAPSED_H) })
        else
            self.Frame.Size = UDim2.new(1, 0, 0, COLLAPSED_H)
        end
    else
        -- Expand: use cached full height. Fall back to a sensible estimate if
        -- _contentH was never captured (e.g. collapsed before first layout).
        local targetH = self._contentH > 0 and self._contentH
            or (COLLAPSED_H + self._layout.AbsoluteContentSize.Y + 8)

        if animate then
            TweenHelper.Tween(self.Frame, TweenHelper.FastInfo,
                { Size = UDim2.new(1, 0, 0, targetH) },
                function()
                    -- Re-enable AutomaticSize after tween completes so future
                    -- component additions still auto-resize the section.
                    if not self._collapsed then
                        self.Frame.AutomaticSize = Enum.AutomaticSize.Y
                    end
                end)
            -- Re-enable after tween time; Tween() doesn't expose a Completed cb,
            -- so use task.delay with a conservative offset.
            task.delay(TweenHelper.FastInfo.Time + 0.02, function()
                if not self._collapsed and self.Frame and self.Frame.Parent then
                    self.Frame.AutomaticSize = Enum.AutomaticSize.Y
                end
            end)
        else
            self.Frame.Size          = UDim2.new(1, 0, 0, targetH)
            self.Frame.AutomaticSize = Enum.AutomaticSize.Y
        end
    end
end

function Section:ToggleCollapsed()
    self:SetCollapsed(not self._collapsed, true)
end

-- ─── Public API ─────────────────────────────────────────────────────────────

function Section:SetTitle(title: string)
    self.Title = title
    self.HeaderLabel.Text = string.upper(title)
end

function Section:Show()
    self.Frame.Visible = true
end

function Section:Hide()
    self.Frame.Visible = false
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Section:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- Cascade: destroy all owned component handles
    -- Each handle cleans its own themeDisconnect, connections, signals, instances.
    for _, handle in ipairs(self._handles) do
        pcall(function() handle:Destroy() end)
    end
    table.clear(self._handles)

    -- Clean own resources: theme listener
    self._maid:DoCleaning()

    -- Destroy root GUI instance
    if self.Frame and self.Frame.Parent then
        self.Frame:Destroy()
    end
end

return Section

end

-- ── Layout.Tab ────────────────────────────────────────────
_Delirium_modules["Layout.Tab"] = function()
-- Layout/Tab.lua
-- Owns its Sections. Cascade: Tab:Destroy() → Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local Root            = script.Parent.Parent
local ThemeEngine     = require(Root.Core.ThemeEngine)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local Maid            = require(Root.Core.Maid)
local Section         = _Delirium_require("Layout.Section")

local Tab = {}
Tab.__index = Tab

function Tab.new(config: table, windowManager: table)
    local self = setmetatable({}, Tab)

    self.Name          = config.Name or "Tab"
    self.Icon          = config.Icon or ""
    self.WindowManager = windowManager
    self.IsActive      = false
    self._destroyed    = false

    -- Owned children and resources
    self._sections = {}
    self._maid     = Maid.new()

    -- ─── Nav button ────────────────────────────────────────────────────────

    self.NavButton = ComponentHelper.Create("TextButton", {
        Name                   = "Nav_" .. self.Name,
        Size                   = UDim2.new(1, 0, 0, 34),
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 1,
        AutoButtonColor        = false,
        Text                   = "",
        Parent                 = windowManager.SideNav,
    })
    ComponentHelper.AddCorner(self.NavButton, 6)
    ComponentHelper.AddPadding(self.NavButton, 0, 0, 10, 10)

    self.Indicator = ComponentHelper.Create("Frame", {
        Name                   = "Indicator",
        Size                   = UDim2.new(0, 3, 0, 16),
        Position               = UDim2.new(0, -6, 0.5, -8),
        BackgroundColor3       = ThemeEngine.GetToken("Accent"),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = self.NavButton,
    })
    ComponentHelper.AddCorner(self.Indicator, 2)

    self.NavLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "Label",
        Text                   = self.Name,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 13,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent                 = self.NavButton,
    })

    -- ─── Page canvas ───────────────────────────────────────────────────────

    self.PageCanvas = ComponentHelper.Create("ScrollingFrame", {
        Name                   = "Page_" .. self.Name,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = ThemeEngine.GetToken("Border"),
        Visible                = false,
        Parent                 = windowManager.PageView,
    })
    ComponentHelper.AddPadding(self.PageCanvas, 12, 12, 12, 12)

    local pageLayout = ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 12),
        Parent    = self.PageCanvas,
    })

    -- Auto-resize canvas
    self._maid:GiveTask(
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self.PageCanvas.CanvasSize =
                UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 24)
        end)
    )

    -- ─── Interaction ───────────────────────────────────────────────────────

    self._maid:GiveTask(
        self.NavButton.MouseButton1Click:Connect(function()
            self.WindowManager:SelectTab(self)
        end)
    )

    self._maid:GiveTask(
        self.NavButton.MouseEnter:Connect(function()
            if self.IsActive then return end
            TweenHelper.Tween(self.NavButton, TweenHelper.FastInfo, {
                BackgroundTransparency = 0.6,
                BackgroundColor3       = ThemeEngine.GetToken("Surface"),
            })
            TweenHelper.Tween(self.NavLabel, TweenHelper.FastInfo, {
                TextColor3 = ThemeEngine.GetToken("Text"),
            })
        end)
    )

    self._maid:GiveTask(
        self.NavButton.MouseLeave:Connect(function()
            if self.IsActive then return end
            TweenHelper.Tween(self.NavButton, TweenHelper.FastInfo, {
                BackgroundTransparency = 1,
            })
            TweenHelper.Tween(self.NavLabel, TweenHelper.FastInfo, {
                TextColor3 = ThemeEngine.GetToken("SubText"),
            })
        end)
    )

    -- ─── Theme listener ────────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        self.PageCanvas.ScrollBarImageColor3 = tokens.Border
        if self.IsActive then
            self.NavLabel.TextColor3        = tokens.Accent
            self.Indicator.BackgroundColor3 = tokens.Accent
            self.NavButton.BackgroundColor3 = tokens.Surface
        else
            self.NavLabel.TextColor3 = tokens.SubText
        end
    end))

    return self
end

-- ─── Section management ────────────────────────────────────────────────────

function Tab:CreateSection(title: string)
    local section = Section.new(title, self.PageCanvas)
    table.insert(self._sections, section)
    return section
end

function Tab:SetActive(active: boolean)
    self.IsActive = active
    self.PageCanvas.Visible = active

    if active then
        TweenHelper.Tween(self.NavButton, TweenHelper.DefaultInfo, {
            BackgroundTransparency = 0.2,
            BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        })
        TweenHelper.Tween(self.NavLabel, TweenHelper.DefaultInfo, {
            TextColor3 = ThemeEngine.GetToken("Accent"),
        })
        TweenHelper.Tween(self.Indicator, TweenHelper.DefaultInfo, {
            BackgroundTransparency = 0,
        })
    else
        TweenHelper.Tween(self.NavButton, TweenHelper.FastInfo, {
            BackgroundTransparency = 1,
        })
        TweenHelper.Tween(self.NavLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("SubText"),
        })
        TweenHelper.Tween(self.Indicator, TweenHelper.FastInfo, {
            BackgroundTransparency = 1,
        })
    end
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Tab:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- Cascade: destroy all owned sections (Section → Component)
    for _, section in ipairs(self._sections) do
        pcall(function() section:Destroy() end)
    end
    table.clear(self._sections)

    -- Clean own resources: theme listener + input connections
    self._maid:DoCleaning()

    -- Destroy UI instances
    if self.NavButton  and self.NavButton.Parent  then self.NavButton:Destroy()  end
    if self.PageCanvas and self.PageCanvas.Parent then self.PageCanvas:Destroy() end
end

return Tab

end

-- ── Layout.Window ─────────────────────────────────────────
_Delirium_modules["Layout.Window"] = function()
-- Layout/Window.lua
-- Owns its Tabs. Cascade: Window:Destroy() → Tab:Destroy() → Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local Root              = script.Parent.Parent
local ThemeEngine       = require(Root.Core.ThemeEngine)
local AnimationEngine   = require(Root.Core.AnimationEngine)
local TweenHelper       = require(Root.Utilities.TweenHelper)
local ComponentHelper   = require(Root.Utilities.ComponentHelper)
local Maid              = require(Root.Core.Maid)
local DialogService     = require(Root.Services.DialogService)
local Tab               = _Delirium_require("Layout.Tab")

local TITLEBAR_H     = 45
local BUTTON_SIZE    = 28
local BUTTON_GAP     = 4
local BUTTON_ROW_W   = BUTTON_SIZE * 3 + BUTTON_GAP * 2  -- 92px (3 buttons: ⌘ − ×)
local DRAG_EXCLUSION = BUTTON_ROW_W + 20                  -- 112px from right edge
local MINI_SIZE      = 52    -- MiniIconFrame side length

local Window = {}
Window.__index = Window

-- ─── Constructor ───────────────────────────────────────────────────────────

function Window.new(config: table, parentGui: ScreenGui)
    local self = setmetatable({}, Window)

    self._config     = config
    self.Name        = config.Name     or "Delirium"
    self.Subtitle    = config.Subtitle or ""
    self.IsOpen      = true
    self.IsMinimized = false
    self.IsMiniIcon  = false
    self.CurrentTab  = nil
    self._destroyed  = false
    self._parentGui  = parentGui

    self._tabs = {}
    self._maid = Maid.new()

    -- Compute a sensible default size that fits on the current screen.
    -- On narrow phones (< 420px wide) the 580px default clips off-screen;
    -- clamp to 94% of viewport while keeping the minimum usable at 320x320.
    local function _responsiveDefaultSize(): UDim2
        local cam = workspace.CurrentCamera
        local vp  = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        local w   = math.clamp(math.floor(vp.X * 0.94), 320, 580)
        local h   = math.clamp(math.floor(vp.Y * 0.70), 320, 380)
        return UDim2.fromOffset(w, h)
    end

    -- Store original size for Restore().
    self._originalSize = config.Size or _responsiveDefaultSize()

    -- ─── Main frame ──────────────────────────────────────────────────────

    self.MainFrame = ComponentHelper.Create("Frame", {
        Name             = "DeliriumMainFrame",
        Size             = self._originalSize,
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = ThemeEngine.GetToken("Background"),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = parentGui,
    })
    ComponentHelper.AddCorner(self.MainFrame, 10)
    local mainStroke = ComponentHelper.AddStroke(self.MainFrame, ThemeEngine.GetToken("Border"), 1)

    -- ─── Title bar ───────────────────────────────────────────────────────

    self.TitleBar = ComponentHelper.Create("Frame", {
        Name                   = "TitleBar",
        Size                   = UDim2.new(1, 0, 0, TITLEBAR_H),
        BackgroundTransparency = 1,
        Parent                 = self.MainFrame,
    })
    ComponentHelper.AddPadding(self.TitleBar, 0, 0, 16, 16)

    self.TitleLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "TitleLabel",
        Text                   = self.Name,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 16,
        TextColor3             = ThemeEngine.GetToken("Text"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(0.6, 0, 1, 0),
        Position               = UDim2.new(0, 0, 0.20, 0),
        BackgroundTransparency = 1,
        Parent                 = self.TitleBar,
    })

    if self.Subtitle ~= "" then
        ComponentHelper.Create("TextLabel", {
            Name                   = "Subtitle",
            Text                   = self.Subtitle,
            Font                   = Enum.Font.Gotham,
            TextSize               = 12,
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextXAlignment         = Enum.TextXAlignment.Left,
            Size                   = UDim2.new(0.6, 0, 1, 0),
            Position               = UDim2.new(0, 0, 0.30, 0),
            BackgroundTransparency = 1,
            Parent                 = self.TitleBar,
        })
        self.TitleLabel.Size = UDim2.new(0.6, 0, 0.45, 0)
    end

    -- ─── Title bar buttons: [⌘] [−] [×] ─────────────────────────────────

    self.ButtonRow = ComponentHelper.Create("Frame", {
        Name                   = "ButtonRow",
        Size                   = UDim2.fromOffset(BUTTON_ROW_W, BUTTON_SIZE),
        Position               = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Parent                 = self.TitleBar,
    })
    ComponentHelper.AddListLayout(self.ButtonRow, {
        FillDirection       = Enum.FillDirection.Horizontal,
        Padding             = UDim.new(0, BUTTON_GAP),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
    })

    local errorColor = ThemeEngine.GetToken("Error") or Color3.fromRGB(220, 60, 60)

    -- Build buttons; explicit LayoutOrder keeps order stable regardless of insertion.
    self._miniIconBtn = self:_BuildTitleButton(self.ButtonRow, "⌘", ThemeEngine.GetToken("SubText"))
    self._minimizeBtn = self:_BuildTitleButton(self.ButtonRow, "−", ThemeEngine.GetToken("SubText"))
    self._closeBtn    = self:_BuildTitleButton(self.ButtonRow, "×", errorColor)

    self._miniIconBtn.LayoutOrder = 1
    self._minimizeBtn.LayoutOrder = 2
    self._closeBtn.LayoutOrder    = 3

    self._maid:GiveTask(self._miniIconBtn.MouseButton1Click:Connect(function()
        self:MiniIconify()
    end))
    self._maid:GiveTask(self._minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end))
    self._maid:GiveTask(self._closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end))

    -- ─── Content container ───────────────────────────────────────────────

    self.ContentContainer = ComponentHelper.Create("Frame", {
        Name                   = "ContentContainer",
        Size                   = UDim2.new(1, 0, 1, -TITLEBAR_H),
        Position               = UDim2.new(0, 0, 0, TITLEBAR_H),
        BackgroundTransparency = 1,
        Parent                 = self.MainFrame,
    })

    self.SideNav = ComponentHelper.Create("ScrollingFrame", {
        Name                   = "SideNav",
        Size                   = UDim2.new(0, 140, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 0,
        Parent                 = self.ContentContainer,
    })
    ComponentHelper.AddPadding(self.SideNav, 8, 8, 8, 8)
    ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
        Parent    = self.SideNav,
    })

    ComponentHelper.Create("Frame", {
        Name             = "NavDivider",
        Size             = UDim2.new(0, 1, 1, -16),
        Position         = UDim2.new(0, 140, 0, 8),
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        Parent           = self.ContentContainer,
    })

    self.PageView = ComponentHelper.Create("Frame", {
        Name                   = "PageView",
        Size                   = UDim2.new(1, -141, 1, 0),
        Position               = UDim2.new(0, 141, 0, 0),
        BackgroundTransparency = 1,
        Parent                 = self.ContentContainer,
    })

    -- ─── MiniIconFrame (hidden until MiniIconify()) ───────────────────────

    self._miniIconFrame  = self:_BuildMiniIconFrame(parentGui)
    self._miniDragMoved  = false

    -- ─── Dragging ─────────────────────────────────────────────────────────

    self:_EnableDragging()
    self:_EnableMiniIconDragging()

    -- ─── Theme listeners ──────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(self.MainFrame,  nil, { BackgroundColor3 = tokens.Background })
        TweenHelper.Tween(mainStroke,      nil, { Color            = tokens.Border     })
        TweenHelper.Tween(self.TitleLabel, nil, { TextColor3       = tokens.Text       })

        local err = tokens.Error or Color3.fromRGB(220, 60, 60)
        TweenHelper.Tween(self._miniIconBtn, nil, { TextColor3 = tokens.SubText })
        TweenHelper.Tween(self._minimizeBtn, nil, { TextColor3 = tokens.SubText })
        TweenHelper.Tween(self._closeBtn,    nil, { TextColor3 = err            })

        -- MiniIconFrame theme passthrough
        if self._miniIconFrame then
            self._miniIconFrame.BackgroundColor3 = tokens.Surface or tokens.Background
            local stroke = self._miniIconFrame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = tokens.Border end
            local glyph = self._miniIconFrame:FindFirstChild("Glyph")
            if glyph then glyph.TextColor3 = tokens.SubText end
        end
    end))

    return self
end

-- ─── Private: title button factory ────────────────────────────────────────

-- icon:    single-glyph string ("⌘", "−", "×")
-- hoverBg: Color3 baked into BackgroundColor3; transparency animates in/out
function Window:_BuildTitleButton(parent: Frame, icon: string, hoverBg: Color3): TextButton
    local btn = ComponentHelper.Create("TextButton", {
        Name                   = "TitleBtn",
        Size                   = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        BackgroundColor3       = hoverBg,
        BackgroundTransparency = 1,
        Text                   = icon,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 15,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        AutoButtonColor        = false,
        BorderSizePixel        = 0,
        Parent                 = parent,
    })
    ComponentHelper.AddCorner(btn, 6)

    self._maid:GiveTask(btn.MouseEnter:Connect(function()
        TweenHelper.Tween(btn, TweenHelper.FastInfo, {
            BackgroundTransparency = 0.78,
            TextColor3             = ThemeEngine.GetToken("Text"),
        }, "btnhov")
    end))

    self._maid:GiveTask(btn.MouseLeave:Connect(function()
        TweenHelper.Tween(btn, TweenHelper.FastInfo, {
            BackgroundTransparency = 1,
            TextColor3             = ThemeEngine.GetToken("SubText"),
        }, "btnhov")
    end))

    return btn
end

-- ─── Private: build MiniIconFrame ─────────────────────────────────────────

function Window:_BuildMiniIconFrame(parentGui: ScreenGui): Frame
    local cam    = workspace.CurrentCamera or { ViewportSize = Vector2.new(1920, 1080) }
    local screen = cam.ViewportSize
    local half   = MINI_SIZE / 2

    -- IgnoreGuiInset = true → scale(0.5) = screen centre.
    -- Offset to bottom-left corner: ~20px from each edge.
    local initOffX = -(screen.X / 2) + 20 + half  -- 46px from left edge
    local initOffY =  (screen.Y / 2) - 20 - half  -- 46px from bottom edge

    local frame = ComponentHelper.Create("Frame", {
        Name             = "MiniIconFrame",
        Size             = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, initOffX, 0.5, initOffY),
        BackgroundColor3 = ThemeEngine.GetToken("Surface") or ThemeEngine.GetToken("Background"),
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 90,
        Parent           = parentGui,
    })
    ComponentHelper.AddCorner(frame, 12)
    ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)

    -- Glyph label
    ComponentHelper.Create("TextLabel", {
        Name                   = "Glyph",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "⌘",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 20,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Center,
        TextYAlignment         = Enum.TextYAlignment.Center,
        ZIndex                 = 91,
        Parent                 = frame,
    })

    -- Full-frame TextButton as the click/hover hitbox.
    -- Also used as the InputBegan source for drag (Frame.InputBegan is blocked by this button).
    local hitbox = ComponentHelper.Create("TextButton", {
        Name                   = "RestoreHitbox",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        ZIndex                 = 92,
        Parent                 = frame,
    })

    -- Hover effects
    self._maid:GiveTask(hitbox.MouseEnter:Connect(function()
        TweenHelper.Tween(frame, TweenHelper.FastInfo,
            { BackgroundColor3 = ThemeEngine.GetToken("Border") }, "minihov")
        local glyph = frame:FindFirstChild("Glyph")
        if glyph then
            TweenHelper.Tween(glyph, TweenHelper.FastInfo,
                { TextColor3 = ThemeEngine.GetToken("Text") }, "miniglyph")
        end
    end))

    self._maid:GiveTask(hitbox.MouseLeave:Connect(function()
        local surface = ThemeEngine.GetToken("Surface") or ThemeEngine.GetToken("Background")
        TweenHelper.Tween(frame, TweenHelper.FastInfo,
            { BackgroundColor3 = surface }, "minihov")
        local glyph = frame:FindFirstChild("Glyph")
        if glyph then
            TweenHelper.Tween(glyph, TweenHelper.FastInfo,
                { TextColor3 = ThemeEngine.GetToken("SubText") }, "miniglyph")
        end
    end))

    -- Restore on click — drag detection guard applied in _EnableMiniIconDragging
    self._maid:GiveTask(hitbox.MouseButton1Click:Connect(function()
        if self._miniDragMoved then
            self._miniDragMoved = false
            return
        end
        if self.IsMiniIcon then
            self:RestoreFromMiniIcon()
        end
    end))

    -- Expose hitbox so _EnableMiniIconDragging can wire InputBegan to it directly.
    -- Frame.InputBegan is eaten by the TextButton on top; hitbox IS the input surface.
    self._miniIconHitbox = hitbox

    return frame
end

-- ─── Private: screen clamp helper ─────────────────────────────────────────

-- Returns a clamped UDim2.new(0.5, offX, 0.5, offY) for `frame`
-- given proposed scale-0.5 offsets (pixels from screen centre).
-- Hard clamp: all 4 edges stay within the screen bounds.
function Window:_ClampToScreen(frame: GuiObject, rawOffX: number, rawOffY: number): UDim2
    local cam      = workspace.CurrentCamera or { ViewportSize = Vector2.new(1920, 1080) }
    local screen   = cam.ViewportSize
    local sz       = frame.AbsoluteSize

    -- ScreenGui has IgnoreGuiInset = true → GUI space = full screen.
    -- scale(0.5, 0.5) resolves to (screen.X/2, screen.Y/2) exactly.
    -- Read both top and bottom insets: top = Roblox topbar/notch; bottom = home bar.
    local topLeft, bottomRight = GuiService:GetGuiInset()
    local topInset    = topLeft.Y        -- 36px on PC, notch height on iPhone
    local bottomInset = bottomRight.Y    -- home-bar area on modern phones

    local cx = screen.X * 0.5 + rawOffX
    local cy = screen.Y * 0.5 + rawOffY

    -- Hard clamp:
    --   left   >= 0                →  cx >= sz.X/2
    --   right  <= screen.X         →  cx <= screen.X - sz.X/2
    --   top    >= topbar bottom     →  cy >= topInset + sz.Y/2
    --   bottom <= screen - homebar  →  cy <= screen.Y - bottomInset - sz.Y/2
    cx = math.clamp(cx, sz.X * 0.5,                          screen.X - sz.X * 0.5)
    cy = math.clamp(cy, topInset + sz.Y * 0.5,               screen.Y - bottomInset - sz.Y * 0.5)

    return UDim2.new(0.5, cx - screen.X * 0.5,
                     0.5, cy - screen.Y * 0.5)
end

-- ─── Dragging — MainFrame ──────────────────────────────────────────────────

function Window:_EnableDragging()
    local dragging  = false
    local dragStart, startPos

    self._maid:GiveTask(self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        -- Skip the button zone on the right side of the TitleBar.
        local relX = input.Position.X - self.TitleBar.AbsolutePosition.X
        if relX > self.TitleBar.AbsoluteSize.X - DRAG_EXCLUSION then return end

        dragging  = true
        dragStart = input.Position
        startPos  = self.MainFrame.Position
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta  = input.Position - dragStart
            local newPos = self:_ClampToScreen(
                self.MainFrame,
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
            -- BUG-04 fix: key="drag" ensures AnimationEngine cancels the previous
            -- in-flight tween before starting a new one. Without this, rapid touch
            -- updates (60fps) stack hundreds of 0.04s tweens that fight each other,
            -- causing rubber-band jitter on mobile.
            AnimationEngine.Play(self.MainFrame,
                TweenInfo.new(0.04, Enum.EasingStyle.Linear),
                { Position = newPos },
                "drag")
        end
    end))

    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ─── Dragging — MiniIconFrame ──────────────────────────────────────────────

function Window:_EnableMiniIconDragging()
    local DRAG_THRESHOLD = 5   -- pixels; below this treat input as a click
    local dragging       = false
    local dragStart, startPos

    -- Wire to hitbox, NOT frame — the TextButton on top intercepts all InputBegan
    -- events before they reach the parent Frame, so frame.InputBegan never fires.
    self._maid:GiveTask(self._miniIconHitbox.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging            = true
        self._miniDragMoved = false
        dragStart           = input.Position
        startPos            = self._miniIconFrame.Position
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > DRAG_THRESHOLD then
                self._miniDragMoved = true
            end
            local newPos = self:_ClampToScreen(
                self._miniIconFrame,
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
            self._miniIconFrame.Position = newPos  -- direct assign; snappy drag feel
        end
    end))

    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ─── Tab management ────────────────────────────────────────────────────────

function Window:CreateTab(config: table)
    assert(type(config) == "table" and config.Name,
        "Window:CreateTab requires a config table with a 'Name' field")
    local tab = Tab.new(config, self)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Window:SelectTab(targetTab)
    for _, tab in ipairs(self._tabs) do
        tab:SetActive(tab == targetTab)
    end
    self.CurrentTab = targetTab
end

-- ─── Window state API ──────────────────────────────────────────────────────

function Window:SetTitle(title: string)
    self.Name = title
    self.TitleLabel.Text = title
end

-- Collapse to TitleBar height only.
function Window:Minimize()
    if self.IsMinimized then return end
    self.IsMinimized = true

    -- Hide content slightly before tween ends so content doesn't clip visibly.
    task.delay(0.06, function()
        if self.IsMinimized and self.ContentContainer then
            self.ContentContainer.Visible = false
        end
    end)

    TweenHelper.Tween(self.MainFrame, TweenHelper.SmoothInfo, {
        Size = UDim2.fromOffset(self._originalSize.X.Offset, TITLEBAR_H),
    }, "minimize")

    if self._config.OnMinimize then
        task.spawn(self._config.OnMinimize)
    end
end

-- Restore to original size.
function Window:Restore()
    if not self.IsMinimized then return end
    self.IsMinimized = false

    self.ContentContainer.Visible = true

    TweenHelper.Tween(self.MainFrame, TweenHelper.SmoothInfo, {
        Size = self._originalSize,
    }, "minimize")

    if self._config.OnRestore then
        task.spawn(self._config.OnRestore)
    end
end

function Window:ToggleMinimize()
    if self.IsMinimized then
        self:Restore()
    else
        self:Minimize()
    end
end

-- ─── MiniIcon API ──────────────────────────────────────────────────────────

-- Shrink the window down to the floating MiniIconFrame chip.
function Window:MiniIconify()
    if self.IsMiniIcon or self._destroyed then return end
    self.IsMiniIcon  = true
    self.IsMinimized = false

    self.ContentContainer.Visible = false

    AnimationEngine.FadeOut(self.MainFrame, TweenHelper.FastInfo)
    task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        if not self._destroyed then
            self.MainFrame.Visible = false
        end
    end)

    -- Show MiniIconFrame: fade + spring pop
    self._miniIconFrame.BackgroundTransparency = 1
    self._miniIconFrame.Visible                = true
    AnimationEngine.FadeIn(self._miniIconFrame, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(self._miniIconFrame, 0.80, AnimationEngine.Preset.Spring)

    if self._config.OnMiniIcon then
        task.spawn(self._config.OnMiniIcon)
    end
end

-- Restore from the MiniIconFrame back to the full window.
function Window:RestoreFromMiniIcon()
    if not self.IsMiniIcon or self._destroyed then return end
    self.IsMiniIcon = false

    AnimationEngine.FadeOut(self._miniIconFrame, TweenHelper.FastInfo)
    task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        if not self._destroyed then
            self._miniIconFrame.Visible = false
        end
    end)

    -- Restore window with matching pop
    self.MainFrame.BackgroundTransparency = 1
    self.MainFrame.Size                   = self._originalSize
    self.MainFrame.Visible                = true
    self.ContentContainer.Visible         = true

    AnimationEngine.FadeIn(self.MainFrame, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(self.MainFrame, 0.92, AnimationEngine.Preset.Spring)

    if self._config.OnRestore then
        task.spawn(self._config.OnRestore)
    end
end

-- ─── Close ─────────────────────────────────────────────────────────────────

-- Routes through CloseWarning dialog when configured; otherwise closes immediately.
function Window:Close()
    if self._destroyed then return end

    if self._config.CloseWarning then
        DialogService.Confirm({
            Title   = "Close window?",
            Message = self._config.CloseMessage or "This will close the window.",
            Type    = "Warning",
            Confirm = { Label = "Close",  Callback = function() self:_ExecuteClose() end },
            Cancel  = { Label = "Cancel" },
        })
    else
        self:_ExecuteClose()
    end
end

-- Internal: run the fade-out + destroy sequence.
function Window:_ExecuteClose()
    if self._destroyed then return end

    if self._config.OnClose then
        task.spawn(self._config.OnClose)
    end

    AnimationEngine.FadeOut(self.MainFrame, TweenHelper.FastInfo)
    task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        self:Destroy()
    end)
end

function Window:Show()
    self.IsOpen = true
    self.MainFrame.Visible = true
    TweenHelper.Tween(self.MainFrame, TweenHelper.DefaultInfo, {
        BackgroundTransparency = 0,
    })
end

function Window:Hide()
    self.IsOpen = false
    TweenHelper.Tween(self.MainFrame, TweenHelper.DefaultInfo, {
        BackgroundTransparency = 1,
    })
    task.delay(TweenHelper.DefaultInfo.Time, function()
        if not self.IsOpen then
            self.MainFrame.Visible = false
        end
    end)
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    for _, tab in ipairs(self._tabs) do
        pcall(function() tab:Destroy() end)
    end
    table.clear(self._tabs)

    self._maid:DoCleaning()

    if self.MainFrame and self.MainFrame.Parent then
        self.MainFrame:Destroy()
    end

    if self._miniIconFrame and self._miniIconFrame.Parent then
        self._miniIconFrame:Destroy()
    end
end

return Window

end

-- ── Components.Button ─────────────────────────────────────
_Delirium_modules["Components.Button"] = function()
-- Components/Button.lua
-- Signature feature: built-in loading fill animation (left → right) on click.
-- Wraps async callbacks automatically: starts loading on click, success state on return.

local TweenService = game:GetService("TweenService")
local Root          = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)
local Signal          = require(Root.Utilities.Signal)

local Button = {}

local LOADING_FILL_INFO   = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SUCCESS_HOLD        = 0.6  -- seconds success color is shown before reset
local SUCCESS_FADE_INFO   = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Button.New(parent: Instance, config: table)
    config = config or {}
    local callback = config.Callback or function() end
    local hasDesc  = config.Description ~= nil and config.Description ~= ""
    local baseH    = hasDesc and 48 or 40

    local enabled  = true
    local loading  = false

    -- ─── Frames ────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "ButtonComponent",
        Size             = UDim2.new(1, 0, 0, baseH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, 8)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, 6, 6, 12, 12)

    -- Loading fill overlay (sits behind content)
    local loadFill = ComponentHelper.Create("Frame", {
        Name             = "LoadFill",
        Size             = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = ThemeEngine.GetToken("AccentDim"),
        BackgroundTransparency = 0.55,
        BorderSizePixel  = 0,
        ZIndex           = 1,
        Parent           = frame,
    })

    -- Title label
    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, -30, hasDesc and 0.5 or 1, 0),
        BackgroundTransparency = 1,
        Text               = config.Title or "Button",
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 14,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        ZIndex             = 3,
        Parent             = frame,
    })

    local descLabel
    if hasDesc then
        descLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Description",
            Size               = UDim2.new(1, -30, 0.5, 0),
            Position           = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Text               = config.Description,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            ZIndex             = 3,
            Parent             = frame,
        })
    end

    local icon = ComponentHelper.Create("ImageLabel", {
        Name               = "Icon",
        Size               = UDim2.new(0, 16, 0, 16),
        Position           = UDim2.new(1, -16, 0.5, -8),
        BackgroundTransparency = 1,
        Image              = "rbxassetid://10709791437",
        ImageColor3        = ThemeEngine.GetToken("SubText"),
        ZIndex             = 3,
        Parent             = frame,
    })

    local triggerBtn = ComponentHelper.Create("TextButton", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = "",
        ZIndex             = 5,
        Parent             = frame,
    })

    -- ─── Signals ───────────────────────────────────────────────────────────

    local OnClicked = Signal.new()

    -- ─── Loading animation ─────────────────────────────────────────────────

    local function playLoading()
        loading = true
        triggerBtn.Active = false

        -- Fill left → right
        loadFill.Size = UDim2.new(0, 0, 1, 0)
        local fillTween = TweenService:Create(loadFill, LOADING_FILL_INFO, {
            Size = UDim2.new(1, 0, 1, 0)
        })
        fillTween:Play()
        fillTween.Completed:Wait()
    end

    local function playSuccess()
        -- Flash success color
        TweenHelper.Tween(loadFill, SUCCESS_FADE_INFO, {
            BackgroundColor3 = ThemeEngine.GetToken("Positive"),
            BackgroundTransparency = 0.4,
        })
        task.wait(SUCCESS_HOLD)

        -- Fade the fill out
        TweenHelper.Tween(loadFill, SUCCESS_FADE_INFO, {
            BackgroundTransparency = 1,
        })
        task.wait(SUCCESS_FADE_INFO.Time)

        loadFill.Size = UDim2.new(0, 0, 1, 0)
        loadFill.BackgroundColor3 = ThemeEngine.GetToken("AccentDim")
        loadFill.BackgroundTransparency = 0.55

        loading = false
        triggerBtn.Active = true
    end

    -- ─── Hover & press animations ──────────────────────────────────────────

    -- Store all input connections so they're cleaned in api:Destroy()
    local inputConns = {}

    table.insert(inputConns, triggerBtn.MouseEnter:Connect(function()
        if not enabled or loading then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        })
    end))

    table.insert(inputConns, triggerBtn.MouseLeave:Connect(function()
        if not enabled or loading then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        })
    end))

    -- Use InputBegan/InputEnded instead of MouseButton1Down/Up so touch
    -- InputEnded fires even when the finger slides off the button.
    table.insert(inputConns, triggerBtn.InputBegan:Connect(function(input)
        if not enabled or loading then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            Size = UDim2.new(1, -4, 0, baseH - 2),
        })
    end))

    table.insert(inputConns, triggerBtn.InputEnded:Connect(function(input)
        if not enabled or loading then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            Size = UDim2.new(1, 0, 0, baseH),
        })
    end))

    table.insert(inputConns, triggerBtn.MouseButton1Click:Connect(function()
        if not enabled or loading then return end

        OnClicked:Fire()

        -- Wrap callback with loading animation.
        -- pcall ensures playSuccess() always runs — even if callback throws.
        -- Without this, a runtime error leaves loading=true and bricks the button forever.
        task.spawn(function()
            playLoading()
            local ok, err = pcall(callback)
            if not ok then
                warn("[Delirium] Button callback error: " .. tostring(err))
            end
            playSuccess()
        end)
    end))

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(stroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        icon.ImageColor3 = tokens.SubText
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
        if not loading then
            loadFill.BackgroundColor3 = tokens.AccentDim
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Enable()
        enabled = true
        triggerBtn.Active = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
        TweenHelper.Tween(icon, TweenHelper.FastInfo, {
            ImageColor3 = ThemeEngine.GetToken("SubText"),
        })
        TweenHelper.Tween(stroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
    end

    function api:Disable()
        enabled = false
        triggerBtn.Active = false
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
        TweenHelper.Tween(icon, TweenHelper.FastInfo, {
            ImageColor3 = ThemeEngine.GetToken("DisabledText"),
        })
        TweenHelper.Tween(stroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
    end

    function api:SetLoading(state: boolean)
        if state then
            task.spawn(playLoading)
        else
            task.spawn(playSuccess)
        end
    end

    function api:SetTitle(title: string)
        titleLabel.Text = title
    end

    function api:SetDescription(desc: string)
        if descLabel then
            descLabel.Text = desc
        end
    end

    function api:Show()
        frame.Visible = true
    end

    function api:Hide()
        frame.Visible = false
    end

    function api:Destroy()
        themeDisconnect()
        for _, conn in ipairs(inputConns) do
            conn:Disconnect()
        end
        table.clear(inputConns)
        OnClicked:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnClicked = OnClicked

    return api
end

return Button

end

-- ── Components.ColorPicker ────────────────────────────────
_Delirium_modules["Components.ColorPicker"] = function()
-- Components/ColorPicker.lua
-- Inline expandable HSV color picker.
-- Hue strip + SV gradient square + hex preview.

local UserInputService = game:GetService("UserInputService")
local Root             = script.Parent.Parent
local ComponentHelper  = require(Root.Utilities.ComponentHelper)
local TweenHelper      = require(Root.Utilities.TweenHelper)
local ThemeEngine      = require(Root.Core.ThemeEngine)
local Signal           = require(Root.Utilities.Signal)

local ColorPicker = {}

-- Convert Color3 → H,S,V (0–1 each)
local function toHSV(c: Color3): (number, number, number)
    return Color3.toHSV(c)
end

-- Build a hex string from Color3
local function toHex(c: Color3): string
    return string.format("#%02X%02X%02X",
        math.round(c.R * 255),
        math.round(c.G * 255),
        math.round(c.B * 255))
end

-- ─── Gradient builder helpers ─────────────────────────────────────────────────

-- Fills a UIGradient with a horizontal hue spectrum
local function applyHueGradient(uiGrad: UIGradient)
    local seq = {}
    for i = 0, 6 do
        table.insert(seq, ColorSequenceKeypoint.new(i / 6,
            Color3.fromHSV(i / 6, 1, 1)))
    end
    uiGrad.Color = ColorSequence.new(seq)
end

-- Fills a UIGradient for SV square at a given hue
local function applySVGradient(satGrad: UIGradient, valGrad: UIGradient, hue: number)
    -- Horizontal: white → full hue color
    satGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
        ColorSequenceKeypoint.new(1, Color3.fromHSV(hue, 1, 1)),
    })
    -- Vertical overlay: transparent → black (applied via separate frame on top)
    valGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
        ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
    })
    valGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(1, 0),
    })
    valGrad.Rotation = 90
end

-- ─── Main constructor ─────────────────────────────────────────────────────────

function ColorPicker.New(parent: Instance, config: table)
    config = config or {}
    local title        = config.Title       or "Color"
    local desc         = config.Description or ""
    local currentColor = config.Default     or Color3.fromRGB(100, 80, 240)
    local enabled      = true
    local isOpen       = false

    local h, s, v = toHSV(currentColor)

    local OnChanged = Signal.new()

    -- ─── Row (collapsed state) ─────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "ColorPickerRow",
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, 8)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    local LabelContainer = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.7, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent             = Row,
    })
    ComponentHelper.AddPadding(LabelContainer, 6, 6, 12, 0)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(1, 0, 0, 18),
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 13,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent             = LabelContainer,
    })

    local descLabel
    if desc ~= "" then
        descLabel = ComponentHelper.Create("TextLabel", {
            Position           = UDim2.new(0, 0, 0, 18),
            Size               = UDim2.new(1, 0, 0, 14),
            Text               = desc,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Parent             = LabelContainer,
        })
    end

    -- Color swatch (right side, acts as toggle)
    local Swatch = ComponentHelper.Create("TextButton", {
        Position           = UDim2.new(1, -44, 0.5, -12),
        Size               = UDim2.new(0, 32, 0, 24),
        BackgroundColor3   = currentColor,
        Text               = "",
        AutoButtonColor    = false,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(Swatch, 6)
    ComponentHelper.AddStroke(Swatch, ThemeEngine.GetToken("Border"), 1)

    -- ─── Expanded picker area ──────────────────────────────────────────────

    local PICKER_H = 168  -- total height of picker content below the row

    -- SV square
    local SVSquare = ComponentHelper.Create("Frame", {
        Position           = UDim2.new(0, 12, 0, 52),
        Size               = UDim2.new(1, -76, 0, 120),
        BackgroundColor3   = Color3.fromHSV(h, 1, 1),
        BorderSizePixel    = 0,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(SVSquare, 6)

    -- Saturation gradient (horizontal)
    local satGrad = ComponentHelper.Create("UIGradient", {
        Color  = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
        }),
        Parent = SVSquare,
    })

    -- Value (darkness) overlay
    local valOverlay = ComponentHelper.Create("Frame", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundColor3   = Color3.new(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel    = 0,
        Parent             = SVSquare,
    })
    ComponentHelper.AddCorner(valOverlay, 6)
    local valGrad = ComponentHelper.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0,0,0)),
            ColorSequenceKeypoint.new(1, Color3.new(0,0,0)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent   = valOverlay,
    })

    -- SV cursor dot (20px so touch can actually grab it)
    local SVCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0, 20, 0, 20),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(s, 0, 1 - v, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = SVSquare,
    })
    ComponentHelper.AddCorner(SVCursor, 10)
    ComponentHelper.AddStroke(SVCursor, Color3.new(0,0,0), 1.5)

    -- Hue strip (right of SV square)
    local HueStrip = ComponentHelper.Create("Frame", {
        Position           = UDim2.new(1, -56, 0, 52),
        Size               = UDim2.new(0, 16, 0, 120),
        BackgroundColor3   = Color3.new(1,1,1),
        BorderSizePixel    = 0,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(HueStrip, 4)
    local hueGrad = ComponentHelper.Create("UIGradient", { Rotation = 90, Parent = HueStrip })
    applyHueGradient(hueGrad)

    -- Hue cursor line (8px tall — taller touch target on the narrow strip)
    local HueCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(1, 4, 0, 8),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(0.5, 0, h, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = HueStrip,
    })
    ComponentHelper.AddCorner(HueCursor, 4)
    ComponentHelper.AddStroke(HueCursor, Color3.new(0,0,0), 1.5)

    -- Hex display label
    local HexLabel = ComponentHelper.Create("TextLabel", {
        Position           = UDim2.new(0, 12, 0, 180),
        Size               = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text               = toHex(currentColor),
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 11,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = Row,
    })

    -- ─── Internal update ───────────────────────────────────────────────────

    local function rebuildColor()
        currentColor = Color3.fromHSV(h, s, v)
        Swatch.BackgroundColor3 = currentColor
        HexLabel.Text = toHex(currentColor)
        -- Update SV square background and gradient
        SVSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        satGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1,1,1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
        })
        -- Move cursors
        SVCursor.Position  = UDim2.new(s, 0, 1 - v, 0)
        HueCursor.Position = UDim2.new(0.5, 0, h, 0)
        OnChanged:Fire(currentColor)
    end

    -- ─── SV square drag ────────────────────────────────────────────────────
    -- Touch threshold: only start SV drag after clear 2D movement, preventing
    -- accidental color changes when scrolling past a ColorPicker.

    -- BUG-06 fix: use pending flags so touch drags are only committed after
    -- direction intent is confirmed. Previously draggingSV=true was set immediately
    -- on InputBegan, which intercepted every passing scroll gesture on SVSquare.
    -- Now the global InputChanged handler only updates color once committed.
    local draggingSV    = false   -- SV drag committed (mouse or confirmed touch)
    local draggingHue   = false   -- Hue drag committed (mouse or confirmed touch)
    local svPending     = false   -- touch finger down on SV square, direction undecided
    local huePending    = false   -- touch finger down on hue strip, direction undecided
    local globalConns   = {}
    local svTouchStart  = Vector2.zero
    local hueTouchStart = 0
    local SV_THRESHOLD  = 8   -- pixels before committing to a drag

    table.insert(globalConns, SVSquare.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Mouse: immediate commit, no threshold needed
            draggingSV = true
            local rel  = Vector2.new(input.Position.X, input.Position.Y) - SVSquare.AbsolutePosition
            s = math.clamp(rel.X / SVSquare.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp(rel.Y / SVSquare.AbsoluteSize.Y, 0, 1)
            rebuildColor()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            -- Touch: record start, mark pending — do NOT set draggingSV yet.
            -- Direction is resolved in InputChanged once movement exceeds threshold.
            svTouchStart = Vector2.new(input.Position.X, input.Position.Y)
            svPending    = true
            draggingSV   = false
        end
    end))

    table.insert(globalConns, HueStrip.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingHue = true
            local rel = Vector2.new(input.Position.X, input.Position.Y) - HueStrip.AbsolutePosition
            h = math.clamp(rel.Y / HueStrip.AbsoluteSize.Y, 0, 1)
            rebuildColor()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            hueTouchStart = input.Position.Y
            huePending    = true
            draggingHue   = false
        end
    end))

    table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local pos = Vector2.new(input.Position.X, input.Position.Y)

        -- ── Resolve SV pending state ──────────────────────────────────────
        if svPending and input.UserInputType == Enum.UserInputType.Touch then
            local delta = pos - svTouchStart
            if delta.Magnitude >= SV_THRESHOLD then
                svPending = false
                if math.abs(delta.Y) > math.abs(delta.X) * 1.5 then
                    -- Vertical scroll intent dominates — yield to scroll container
                    draggingSV = false
                else
                    -- Horizontal (2D paint) intent confirmed — commit to SV drag
                    draggingSV = true
                end
            end
        end

        -- ── Resolve Hue pending state ─────────────────────────────────────
        if huePending and input.UserInputType == Enum.UserInputType.Touch then
            local dy = math.abs(input.Position.Y - hueTouchStart)
            if dy >= SV_THRESHOLD then
                huePending  = false
                draggingHue = true   -- hue strip is vertical-only, any Y motion commits
            elseif math.abs(input.Position.X - svTouchStart.X) > SV_THRESHOLD then
                huePending  = false  -- clear horizontal swipe — not a hue drag
            end
        end

        -- ── Apply committed drags ─────────────────────────────────────────
        if draggingSV then
            local rel = pos - SVSquare.AbsolutePosition
            s = math.clamp(rel.X / SVSquare.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp(rel.Y / SVSquare.AbsoluteSize.Y, 0, 1)
            rebuildColor()
        elseif draggingHue then
            local rel = pos - HueStrip.AbsolutePosition
            h = math.clamp(rel.Y / HueStrip.AbsoluteSize.Y, 0, 1)
            rebuildColor()
        end
    end))

    table.insert(globalConns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV  = false
            draggingHue = false
            svPending   = false
            huePending  = false
        end
    end))

    -- ─── Swatch toggle ─────────────────────────────────────────────────────

    Swatch.MouseButton1Click:Connect(function()
        if not enabled then return end
        isOpen = not isOpen
        local targetH = isOpen and (42 + PICKER_H) or 42
        TweenHelper.Tween(Row, TweenHelper.DefaultInfo, { Size = UDim2.new(1, 0, 0, targetH) })
    end)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(Row, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(rowStroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(HexLabel, nil, { TextColor3 = tokens.SubText })
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Get(): Color3
        return currentColor
    end

    function api:Set(color: Color3)
        currentColor = color
        h, s, v = toHSV(color)
        rebuildColor()
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
    end

    function api:Disable()
        enabled = false
        if isOpen then
            isOpen = false
            TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, 42) })
        end
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(t: string) titleLabel.Text = t end

    function api:Show()  Row.Visible = true  end
    function api:Hide()  Row.Visible = false end

    function api:Destroy()
        themeDisconnect()
        for _, conn in ipairs(globalConns) do
            conn:Disconnect()
        end
        table.clear(globalConns)
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged

    return api
end

return ColorPicker

end

-- ── Components.Divider ────────────────────────────────────
_Delirium_modules["Components.Divider"] = function()
-- Components/Divider.lua
-- Horizontal visual separator. Optional text label centered over the line.
-- Consumes minimal vertical space (16px without label, 20px with label).
--
-- Usage:
--   Section:CreateDivider()
--   Section:CreateDivider({ Label = "Advanced" })

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)

local Divider = {}

function Divider.New(parent: Instance, config: table)
    config = config or {}

    local label    = config.Label or ""
    local hasLabel = label ~= ""
    local height   = hasLabel and 20 or 16

    -- ─── Frame ──────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name               = "DividerComponent",
        Size               = UDim2.new(1, 0, 0, height),
        BackgroundTransparency = 1,
        BorderSizePixel    = 0,
        Parent             = parent,
    })

    -- Left line
    local leftLine = ComponentHelper.Create("Frame", {
        Name             = "LineLeft",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = hasLabel and UDim2.new(0.5, -6, 0, 1) or UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })

    local rightLine
    local textLabel

    if hasLabel then
        -- Right line
        rightLine = ComponentHelper.Create("Frame", {
            Name             = "LineRight",
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, 0, 0.5, 0),
            Size             = UDim2.new(0.5, -6, 0, 1),
            BackgroundColor3 = ThemeEngine.GetToken("Border"),
            BorderSizePixel  = 0,
            Parent           = frame,
        })

        -- Center label
        textLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Label",
            AnchorPoint        = Vector2.new(0.5, 0.5),
            Position           = UDim2.new(0.5, 0, 0.5, 0),
            Size               = UDim2.new(0, 0, 1, 0),
            AutomaticSize      = Enum.AutomaticSize.X,
            BackgroundTransparency = 1,
            Text               = label,
            TextColor3         = ThemeEngine.GetToken("DisabledText"),
            TextSize           = 10,
            Font               = Enum.Font.GothamMedium,
            TextXAlignment     = Enum.TextXAlignment.Center,
            Parent             = frame,
        })
    end

    -- ─── Theme updates ───────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(leftLine, nil, {BackgroundColor3 = tokens.Border})
        if rightLine then TweenHelper.Tween(rightLine, nil, {BackgroundColor3 = tokens.Border}) end
        if textLabel then TweenHelper.Tween(textLabel, nil, {TextColor3 = tokens.DisabledText}) end
    end)

    -- ─── Public API ──────────────────────────────────────────────────────────

    local api = {}

    function api:SetLabel(text: string)
        if textLabel then textLabel.Text = text end
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        themeDisconnect()
        frame:Destroy()
    end

    api.Instance = frame
    return api
end

return Divider

end

-- ── Components.Dropdown ───────────────────────────────────
_Delirium_modules["Components.Dropdown"] = function()
-- Components/Dropdown.lua
-- Accordion-style dropdown with multi-select support.

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)
local Signal          = require(Root.Utilities.Signal)

local Dropdown = {}

function Dropdown.New(parent: Instance, config: table)
    config = config or {}
    local title   = config.Title       or "Dropdown"
    local desc    = config.Description or ""
    local options = config.Options     or {}
    local isMulti = config.Multi       == true
    local enabled = true
    local isOpen  = false

    -- current selection: string (single) or table (multi)
    local currentSelection = config.Default
        or (isMulti and {} or (options[1] or ""))

    local OnChanged = Signal.new()

    -- ─── Row container ─────────────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "DropdownRow",
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, 8)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    -- Label side
    local LabelContainer = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.5, 0, 0, 42),
        BackgroundTransparency = 1,
        Parent             = Row,
    })
    ComponentHelper.AddPadding(LabelContainer, 6, 6, 12, 0)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(1, 0, 0, 18),
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 13,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent             = LabelContainer,
    })

    local descLabel
    if desc ~= "" then
        descLabel = ComponentHelper.Create("TextLabel", {
            Position           = UDim2.new(0, 0, 0, 18),
            Size               = UDim2.new(1, 0, 0, 14),
            Text               = desc,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Parent             = LabelContainer,
        })
    end

    -- Trigger button (right side)
    local Trigger = ComponentHelper.Create("TextButton", {
        Position           = UDim2.new(0.55, 0, 0, 6),
        Size               = UDim2.new(0.42, 0, 0, 30),
        BackgroundColor3   = ThemeEngine.GetToken("SurfaceActive"),
        AutoButtonColor    = false,
        Text               = "",
        Parent             = Row,
    })
    ComponentHelper.AddCorner(Trigger, 6)

    local function selectionText(): string
        if isMulti then
            return #currentSelection > 0 and table.concat(currentSelection, ", ") or "None"
        end
        return tostring(currentSelection)
    end

    local SelectedText = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(1, -24, 1, 0),
        Position           = UDim2.new(0, 8, 0, 0),
        Text               = selectionText(),
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 12,
        Font               = Enum.Font.Gotham,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent             = Trigger,
    })

    local Arrow = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(0, 16, 0, 16),
        Position           = UDim2.new(1, -20, 0.5, -8),
        Text               = "▾",
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 12,
        Font               = Enum.Font.GothamBold,
        BackgroundTransparency = 1,
        Parent             = Trigger,
    })

    -- Connections created inside RenderOptions — cleaned before every re-render
    -- so theme changes and refreshes don't accumulate listeners on destroyed buttons.
    local optionConns = {}

    -- Option list (expands below)
    local OptionList = ComponentHelper.Create("Frame", {
        Position           = UDim2.new(0, 8, 0, 48),
        Size               = UDim2.new(1, -16, 0, 0),
        BackgroundTransparency = 1,
        Parent             = Row,
    })

    local UIList = ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
        Parent    = OptionList,
    })

    -- ─── Render options ────────────────────────────────────────────────────

    local function RenderOptions()
        -- BUG-02 fix: disconnect previous option connections before destroying
        -- their buttons. Roblox disconnects on :Destroy() eventually, but explicit
        -- cleanup prevents any window where stale listeners could fire.
        for _, conn in ipairs(optionConns) do
            conn:Disconnect()
        end
        table.clear(optionConns)

        for _, child in ipairs(OptionList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for idx, opt in ipairs(options) do
            local isSelected = isMulti
                and table.find(currentSelection, opt) ~= nil
                or  currentSelection == opt

            local Btn = ComponentHelper.Create("TextButton", {
                Size             = UDim2.new(1, 0, 0, 28),
                BackgroundColor3 = isSelected and ThemeEngine.GetToken("Accent") or ThemeEngine.GetToken("SurfaceHover"),
                Text             = "  " .. tostring(opt),
                TextColor3       = isSelected and ThemeEngine.GetToken("AccentText") or ThemeEngine.GetToken("Text"),
                TextSize         = 12,
                Font             = Enum.Font.Gotham,
                TextXAlignment   = Enum.TextXAlignment.Left,
                AutoButtonColor  = false,
                LayoutOrder      = idx,
                Parent           = OptionList,
            })
            ComponentHelper.AddCorner(Btn, 5)

            -- Store all three connections — cleaned on next RenderOptions() call
            table.insert(optionConns, Btn.MouseEnter:Connect(function()
                if not isSelected then
                    TweenHelper.Tween(Btn, TweenHelper.FastInfo, {
                        BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
                    })
                end
            end))
            table.insert(optionConns, Btn.MouseLeave:Connect(function()
                if not isSelected then
                    TweenHelper.Tween(Btn, TweenHelper.FastInfo, {
                        BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
                    })
                end
            end))
            table.insert(optionConns, Btn.MouseButton1Click:Connect(function()
                if not enabled then return end
                if isMulti then
                    local foundIdx = table.find(currentSelection, opt)
                    if foundIdx then
                        table.remove(currentSelection, foundIdx)
                    else
                        table.insert(currentSelection, opt)
                    end
                    SelectedText.Text = selectionText()
                else
                    currentSelection = opt
                    SelectedText.Text = tostring(opt)
                    -- Auto-close on single select
                    isOpen = false
                    TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, 42) })
                    TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = 0 })
                end
                RenderOptions()
                OnChanged:Fire(currentSelection)
            end))
        end
    end

    -- ─── Open / close ──────────────────────────────────────────────────────

    -- BUG-02 fix: store the Trigger connection so api:Destroy() can clean it.
    local triggerConn = Trigger.MouseButton1Click:Connect(function()
        if not enabled then return end
        isOpen = not isOpen
        TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = isOpen and 180 or 0 })
        if isOpen then
            -- BUG-03 fix: defer one frame so Roblox resolves AbsoluteContentSize
            -- before we read it. On mobile, layout is not synchronous with the click.
            task.defer(function()
                if not isOpen then return end  -- guard: user may have closed before frame
                local targetH = 54 + UIList.AbsoluteContentSize.Y
                TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, targetH) })
            end)
        else
            TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, 42) })
        end
    end)

    RenderOptions()

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(Row, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(rowStroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(Trigger, nil, { BackgroundColor3 = tokens.SurfaceActive })
        TweenHelper.Tween(SelectedText, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(Arrow, nil, { TextColor3 = tokens.SubText })
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
        -- Re-render option buttons with new theme colors
        RenderOptions()
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Get()
        return currentSelection
    end

    function api:Set(val)
        currentSelection = val
        SelectedText.Text = selectionText()
        RenderOptions()
        OnChanged:Fire(currentSelection)
    end

    function api:Refresh()
        RenderOptions()
    end

    function api:SetOptions(newOptions: table)
        options = newOptions
        -- Reset selection if it's no longer valid
        if not isMulti and not table.find(options, currentSelection) then
            currentSelection = options[1] or ""
            SelectedText.Text = selectionText()
        end
        RenderOptions()
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
    end

    function api:Disable()
        enabled = false
        if isOpen then
            isOpen = false
            TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, 42) })
            TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = 0 })
        end
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(t: string) titleLabel.Text = t end

    function api:Show()  Row.Visible = true  end
    function api:Hide()  Row.Visible = false end

    function api:Destroy()
        triggerConn:Disconnect()
        for _, conn in ipairs(optionConns) do
            conn:Disconnect()
        end
        table.clear(optionConns)
        themeDisconnect()
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged

    return api
end

return Dropdown

end

-- ── Components.Keybind ────────────────────────────────────
_Delirium_modules["Components.Keybind"] = function()
-- Components/Keybind.lua
-- Mobile: tapping while listening cancels (no physical keyboard).
-- Auto-cancel after 6s on touch devices so the component never stays stuck.

local UserInputService = game:GetService("UserInputService")
local Root             = script.Parent.Parent
local ComponentHelper  = require(Root.Utilities.ComponentHelper)
local TweenHelper      = require(Root.Utilities.TweenHelper)
local ThemeEngine      = require(Root.Core.ThemeEngine)
local InputAdapter     = require(Root.Core.InputAdapter)
local Signal           = require(Root.Utilities.Signal)

local Keybind = {}

function Keybind.New(parent: Instance, config: table)
    config = config or {}
    local title      = config.Title       or "Keybind"
    local desc       = config.Description or ""
    local currentKey = config.Default     or Enum.KeyCode.E
    local enabled    = true
    local isListening = false

    local OnChanged = Signal.new()

    -- ─── Row ───────────────────────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "KeybindRow",
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, 8)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    local LabelContainer = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.65, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent             = Row,
    })
    ComponentHelper.AddPadding(LabelContainer, 6, 6, 12, 0)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(1, 0, 0, 18),
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 13,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent             = LabelContainer,
    })

    local descLabel
    if desc ~= "" then
        descLabel = ComponentHelper.Create("TextLabel", {
            Position           = UDim2.new(0, 0, 0, 18),
            Size               = UDim2.new(1, 0, 0, 14),
            Text               = desc,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Parent             = LabelContainer,
        })
    end

    local BindBtn = ComponentHelper.Create("TextButton", {
        Position           = UDim2.new(0.68, 0, 0, 7),
        Size               = UDim2.new(0.29, 0, 0, 28),
        BackgroundColor3   = ThemeEngine.GetToken("SurfaceActive"),
        Text               = currentKey.Name,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 11,
        Font               = Enum.Font.GothamBold,
        AutoButtonColor    = false,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(BindBtn, 6)
    local btnStroke = ComponentHelper.AddStroke(BindBtn, ThemeEngine.GetToken("Border"), 1)

    -- ─── Listening logic ───────────────────────────────────────────────────

    local globalConn
    local timeoutThread
    local MOBILE_LISTEN_TIMEOUT = 6  -- seconds before auto-cancel on touch

    -- Truncate long key names for the narrow button on mobile.
    local function keyDisplayName(): string
        if InputAdapter.IsTouch then
            return currentKey.Name:sub(1, 6)
        end
        return currentKey.Name
    end

    -- Apply initial display text based on device.
    BindBtn.Text = keyDisplayName()

    local function stopListening()
        isListening = false
        if globalConn then
            globalConn:Disconnect()
            globalConn = nil
        end
        if timeoutThread then
            pcall(task.cancel, timeoutThread)
            timeoutThread = nil
        end
        BindBtn.Text       = keyDisplayName()
        BindBtn.TextColor3 = ThemeEngine.GetToken("Text")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
    end

    BindBtn.MouseButton1Click:Connect(function()
        if not enabled then return end
        -- Tapping while listening cancels on mobile (no Escape key available).
        if isListening then
            stopListening()
            return
        end

        isListening = true
        BindBtn.Text       = "..."
        BindBtn.TextColor3 = ThemeEngine.GetToken("Warning")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Warning"),
        })

        -- Auto-cancel on touch after timeout — keyboard input will never arrive.
        if InputAdapter.IsTouch then
            timeoutThread = task.delay(MOBILE_LISTEN_TIMEOUT, function()
                timeoutThread = nil
                if isListening then stopListening() end
            end)
        end

        globalConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
            if gameProcessed then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                stopListening()
                return
            end
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKey = input.KeyCode
                OnChanged:Fire(currentKey)
                stopListening()
            end
        end)
    end)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(Row, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(rowStroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(BindBtn, nil, { BackgroundColor3 = tokens.SurfaceActive })
        if not isListening then
            TweenHelper.Tween(BindBtn, nil, { TextColor3 = tokens.Text })
            TweenHelper.Tween(btnStroke, nil, { Color = tokens.Border })
        end
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Get(): Enum.KeyCode
        return currentKey
    end

    function api:Set(key: Enum.KeyCode)
        if isListening then stopListening() end
        currentKey = key
        BindBtn.Text = keyDisplayName()
        OnChanged:Fire(currentKey)
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
    end

    function api:Disable()
        enabled = false
        if isListening then stopListening() end
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(t: string) titleLabel.Text = t end

    function api:Show()  Row.Visible = true  end
    function api:Hide()  Row.Visible = false end

    function api:Destroy()
        if globalConn then globalConn:Disconnect() end
        if timeoutThread then pcall(task.cancel, timeoutThread) end
        themeDisconnect()
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged

    return api
end

return Keybind

end

-- ── Components.Label ──────────────────────────────────────
_Delirium_modules["Components.Label"] = function()
-- Components/Label.lua
-- Inline display label. Left side: name. Right side: optional value.
-- Variants control value color: "default" | "accent" | "positive" | "warning" | "error"
--
-- Usage:
--   Section:CreateLabel({ Title = "Version",  Value = "1.0.0" })
--   Section:CreateLabel({ Title = "Status",   Value = "Active",  Variant = "positive" })
--   Section:CreateLabel({ Title = "Notice",   Value = "Low HP",  Variant = "warning"  })

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)

local VARIANT_TOKEN = {
    default  = "SubText",
    accent   = "Accent",
    positive = "Positive",
    warning  = "Warning",
    error    = "Error",
    sub      = "DisabledText",
}

local Label = {}

function Label.New(parent: Instance, config: table)
    config = config or {}

    local title    = config.Title   or ""
    local value    = config.Value   or ""
    local variant  = config.Variant or "default"
    local valueToken = VARIANT_TOKEN[variant] or "SubText"

    -- ─── Frame ──────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "LabelComponent",
        Size             = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 0.6,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, 6)
    ComponentHelper.AddPadding(frame, 4, 4, 12, 12)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(0.6, 0, 1, 0),
        BackgroundTransparency = 1,
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 12,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        Parent             = frame,
    })

    local valueLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Value",
        Position           = UDim2.new(0.6, 0, 0, 0),
        Size               = UDim2.new(0.4, 0, 1, 0),
        BackgroundTransparency = 1,
        Text               = tostring(value),
        TextColor3         = ThemeEngine.GetToken(valueToken),
        TextSize           = 12,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Right,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        Parent             = frame,
    })

    -- ─── Theme updates ───────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame,       nil, {BackgroundColor3 = tokens.Surface})
        TweenHelper.Tween(titleLabel,  nil, {TextColor3 = tokens.SubText})
        TweenHelper.Tween(valueLabel,  nil, {TextColor3 = tokens[valueToken]})
    end)

    -- ─── Public API ──────────────────────────────────────────────────────────

    local api = {}

    function api:SetTitle(text: string)
        titleLabel.Text = tostring(text)
    end

    function api:SetValue(text: string | number)
        valueLabel.Text = tostring(text)
    end

    function api:SetVariant(v: string)
        variant      = v
        valueToken   = VARIANT_TOKEN[v] or "SubText"
        valueLabel.TextColor3 = ThemeEngine.GetToken(valueToken)
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        themeDisconnect()
        frame:Destroy()
    end

    api.Instance = frame
    return api
end

return Label

end

-- ── Components.Paragraph ──────────────────────────────────
_Delirium_modules["Components.Paragraph"] = function()
-- Components/Paragraph.lua
-- Multi-line wrapped text block. Optional bold title above the body.
-- Height grows automatically with content via AutomaticSize.
--
-- Usage:
--   Section:CreateParagraph({
--       Title = "About",  -- optional
--       Content = "Long text that wraps across multiple lines...",
--   })

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)

local Paragraph = {}

function Paragraph.New(parent: Instance, config: table)
    config = config or {}

    local title    = config.Title   or ""
    local content  = config.Content or config.Text or ""
    local hasTitle = title ~= ""

    -- ─── Frame ──────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name          = "ParagraphComponent",
        Size          = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent          = parent,
    })
    ComponentHelper.AddCorner(frame, 8)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, 10, 10, 12, 12)

    ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 6),
        Parent    = frame,
    })

    -- Optional title label
    local titleLabel
    if hasTitle then
        titleLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Title",
            Size               = UDim2.new(1, 0, 0, 0),
            AutomaticSize      = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text               = title,
            TextColor3         = ThemeEngine.GetToken("Text"),
            TextSize           = 13,
            Font               = Enum.Font.GothamBold,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextWrapped        = true,
            LayoutOrder        = 0,
            Parent             = frame,
        })
    end

    -- Body text
    local bodyLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Body",
        Size               = UDim2.new(1, 0, 0, 0),
        AutomaticSize      = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text               = content,
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 12,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextWrapped        = true,
        LineHeight         = 1.4,
        LayoutOrder        = 1,
        Parent             = frame,
    })

    -- ─── Theme updates ───────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame,      nil, {BackgroundColor3 = tokens.Surface})
        TweenHelper.Tween(stroke,     nil, {Color = tokens.Border})
        TweenHelper.Tween(bodyLabel,  nil, {TextColor3 = tokens.SubText})
        if titleLabel then
            TweenHelper.Tween(titleLabel, nil, {TextColor3 = tokens.Text})
        end
    end)

    -- ─── Public API ──────────────────────────────────────────────────────────

    local api = {}

    function api:SetTitle(text: string)
        if titleLabel then
            titleLabel.Text = text
        end
    end

    function api:SetContent(text: string)
        bodyLabel.Text = tostring(text)
    end

    -- Append text on a new line.
    function api:Append(text: string)
        bodyLabel.Text = bodyLabel.Text .. "\n" .. tostring(text)
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        themeDisconnect()
        frame:Destroy()
    end

    api.Instance = frame
    return api
end

return Paragraph

end

-- ── Components.Slider ─────────────────────────────────────
_Delirium_modules["Components.Slider"] = function()
-- Components/Slider.lua
-- Touch threshold: slider drag only starts after clear horizontal intent,
-- preventing accidental activation during scroll gestures.

local UserInputService = game:GetService("UserInputService")
local Root             = script.Parent.Parent
local ComponentHelper  = require(Root.Utilities.ComponentHelper)
local TweenHelper      = require(Root.Utilities.TweenHelper)
local ThemeEngine      = require(Root.Core.ThemeEngine)
local Signal           = require(Root.Utilities.Signal)

local Slider = {}

-- Touch drag is only initiated once horizontal movement exceeds this threshold,
-- avoiding accidental activation during vertical scroll gestures.
local TOUCH_DRAG_THRESHOLD = 6 -- pixels

function Slider.New(parent: Instance, config: table)
    config = config or {}
    local min       = config.Min      or 0
    local max       = config.Max      or 100
    local precision = config.Precision or 0
    local callback  = config.Callback or function() end
    local enabled   = true
    local value     = math.clamp(config.Default or min, min, max)

    -- ─── Frames ────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "SliderComponent",
        Size             = UDim2.new(1, 0, 0, 50),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, 8)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, 8, 8, 12, 12)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, -60, 0, 18),
        BackgroundTransparency = 1,
        Text               = config.Title or "Slider",
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 14,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = frame,
    })

    local valueLabel = ComponentHelper.Create("TextLabel", {
        Name               = "ValueLabel",
        Size               = UDim2.new(0, 50, 0, 18),
        Position           = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Text               = tostring(value),
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 13,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Right,
        Parent             = frame,
    })

    local track = ComponentHelper.Create("Frame", {
        Name             = "Track",
        Size             = UDim2.new(1, 0, 0, 6),
        Position         = UDim2.new(0, 0, 1, -8),
        BackgroundColor3 = ThemeEngine.GetToken("SliderTrack"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })
    ComponentHelper.AddCorner(track, 3)

    local fill = ComponentHelper.Create("Frame", {
        Name             = "Fill",
        Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = ThemeEngine.GetToken("Accent"),
        BorderSizePixel  = 0,
        Parent           = track,
    })
    ComponentHelper.AddCorner(fill, 3)

    -- Invisible wider hit area on top of track (easier to grab)
    local hitArea = ComponentHelper.Create("TextButton", {
        Name               = "HitArea",
        Size               = UDim2.new(1, 0, 0, 20),
        Position           = UDim2.new(0, 0, 0.5, -10),
        BackgroundTransparency = 1,
        Text               = "",
        Parent             = track,
    })

    -- ─── Signals ───────────────────────────────────────────────────────────

    local OnChanged = Signal.new()

    -- ─── Value logic ───────────────────────────────────────────────────────

    local function computeValue(screenX: number): number
        local pct  = math.clamp((screenX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw  = min + pct * (max - min)
        local factor = 10 ^ precision
        return math.round(raw * factor) / factor
    end

    local function applyValue(newVal: number, fireSignal: boolean)
        if newVal == value then return end
        value = newVal
        valueLabel.Text = tostring(value)
        local ratio = (value - min) / (max - min)
        TweenHelper.Tween(fill, TweenHelper.FastInfo, { Size = UDim2.new(ratio, 0, 1, 0) })
        if fireSignal then
            OnChanged:Fire(value)
            task.spawn(callback, value)
        end
    end

    -- ─── Input handling (scoped connections — no global leak) ──────────────

    local dragging      = false
    local touchStartX   = 0
    local touchDragReady = false  -- true once horizontal intent confirmed
    local globalConns   = {}

    local function startDrag(screenX: number)
        dragging = true
        applyValue(computeValue(screenX), true)
    end

    local function stopDrag()
        dragging      = false
        touchDragReady = false
    end

    -- Track / hitArea: begin drag on mouse down (stored so Destroy cleans it)
    table.insert(globalConns, hitArea.MouseButton1Down:Connect(function()
        if not enabled then return end
        startDrag(UserInputService:GetMouseLocation().X)
    end))

    -- Touch: begin on InputBegan, confirm horizontal intent before dragging
    table.insert(globalConns, hitArea.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.Touch then
            touchStartX    = input.Position.X
            touchDragReady = false
            dragging       = true
        end
    end))

    -- Global move: handle both mouse drag and touch drag
    table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if not enabled then return end

        if input.UserInputType == Enum.UserInputType.MouseMovement then
            applyValue(computeValue(input.Position.X), true)

        elseif input.UserInputType == Enum.UserInputType.Touch then
            local dx = math.abs(input.Position.X - touchStartX)
            local dy = math.abs(input.Position.Y - (hitArea.AbsolutePosition.Y + hitArea.AbsoluteSize.Y / 2))

            if not touchDragReady then
                -- Confirm horizontal intent: horizontal delta must dominate vertical
                if dx > TOUCH_DRAG_THRESHOLD and dx > dy * 1.5 then
                    touchDragReady = true
                elseif dy > TOUCH_DRAG_THRESHOLD then
                    -- Vertical scroll intent — cancel drag, yield to scroll
                    stopDrag()
                end
            end

            if touchDragReady then
                applyValue(computeValue(input.Position.X), true)
            end
        end
    end))

    -- Global end: stop dragging
    table.insert(globalConns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            stopDrag()
        end
    end))

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(stroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(valueLabel, nil, { TextColor3 = tokens.SubText })
        TweenHelper.Tween(track, nil, { BackgroundColor3 = tokens.SliderTrack })
        TweenHelper.Tween(fill, nil, { BackgroundColor3 = tokens.Accent })
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Get(): number
        return value
    end

    function api:Set(val: number)
        local clamped = math.clamp(val, min, max)
        local factor  = 10 ^ precision
        clamped = math.round(clamped * factor) / factor
        value = clamped
        valueLabel.Text = tostring(value)
        local ratio = (value - min) / (max - min)
        TweenHelper.Tween(fill, TweenHelper.FastInfo, { Size = UDim2.new(ratio, 0, 1, 0) })
        OnChanged:Fire(value)
        task.spawn(callback, value)
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
        TweenHelper.Tween(fill, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Accent"),
        })
    end

    function api:Disable()
        enabled = false
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
        TweenHelper.Tween(fill, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(title: string)
        titleLabel.Text = title
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        themeDisconnect()
        for _, conn in ipairs(globalConns) do
            conn:Disconnect()
        end
        table.clear(globalConns)
        OnChanged:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnChanged = OnChanged

    return api
end

return Slider

end

-- ── Components.TextBox ────────────────────────────────────
_Delirium_modules["Components.TextBox"] = function()
-- Components/TextBox.lua

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)
local Signal          = require(Root.Utilities.Signal)

local TextBox = {}

function TextBox.New(parent: Instance, config: table)
    config = config or {}
    local title       = config.Title        or "Input"
    local desc        = config.Description  or ""
    local placeholder = config.Placeholder  or "Type here..."
    local defaultText = config.Default      or ""
    local enabled     = true

    local OnChanged = Signal.new()
    local OnSubmit  = Signal.new()

    -- ─── Row ───────────────────────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "TextBoxRow",
        Size             = UDim2.new(1, 0, 0, 42),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, 8)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    local LabelContainer = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.55, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent             = Row,
    })
    ComponentHelper.AddPadding(LabelContainer, 6, 6, 12, 0)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(1, 0, 0, 18),
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 13,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent             = LabelContainer,
    })

    local descLabel
    if desc ~= "" then
        descLabel = ComponentHelper.Create("TextLabel", {
            Position           = UDim2.new(0, 0, 0, 18),
            Size               = UDim2.new(1, 0, 0, 14),
            Text               = desc,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            BackgroundTransparency = 1,
            Parent             = LabelContainer,
        })
    end

    local InputBox = ComponentHelper.Create("TextBox", {
        Position           = UDim2.new(0.58, 0, 0, 6),
        Size               = UDim2.new(0.39, 0, 0, 30),
        BackgroundColor3   = ThemeEngine.GetToken("InputBackground"),
        Text               = defaultText,
        PlaceholderText    = placeholder,
        PlaceholderColor3  = ThemeEngine.GetToken("SubText"),
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 12,
        Font               = Enum.Font.Gotham,
        ClearTextOnFocus   = config.ClearOnFocus == true,
        TextEditable       = true,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(InputBox, 6)
    local inputStroke = ComponentHelper.AddStroke(InputBox, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(InputBox, 0, 0, 6, 6)

    -- ─── Focus animations ──────────────────────────────────────────────────

    -- BUG-05 fix: scroll the parent PageCanvas so the TextBox stays visible
    -- when the mobile keyboard pushes the viewport upward.
    -- Walks up the ancestor chain to find the first ScrollingFrame (Tab's PageCanvas),
    -- then adjusts CanvasPosition if the Row is below the visible region.
    -- task.defer gives Roblox one frame to resolve AbsolutePosition after focus.
    local function _scrollIntoView()
        task.defer(function()
            if not Row or not Row.Parent then return end
            local canvas = Row:FindFirstAncestorWhichIsA("ScrollingFrame")
            if not canvas then return end

            local rowAbsY    = Row.AbsolutePosition.Y
            local canvasAbsY = canvas.AbsolutePosition.Y
            local scrollY    = canvas.CanvasPosition.Y
            local visibleH   = canvas.AbsoluteSize.Y
            local rowH       = Row.AbsoluteSize.Y

            -- Position of Row relative to canvas content top
            local relTop    = rowAbsY - canvasAbsY + scrollY
            local relBottom = relTop + rowH

            -- If the bottom of the Row is below the visible window, scroll down.
            if relBottom > scrollY + visibleH then
                canvas.CanvasPosition = Vector2.new(0, relBottom - visibleH + 8)
            -- If the top of the Row is above the visible window, scroll up.
            elseif relTop < scrollY then
                canvas.CanvasPosition = Vector2.new(0, relTop - 8)
            end
        end)
    end

    InputBox.Focused:Connect(function()
        if not enabled then
            InputBox:ReleaseFocus()
            return
        end
        TweenHelper.Tween(inputStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Accent"),
        })
        TweenHelper.Tween(Row, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        })
        _scrollIntoView()
    end)

    InputBox.FocusLost:Connect(function(enterPressed)
        TweenHelper.Tween(inputStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
        TweenHelper.Tween(Row, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        })
        OnChanged:Fire(InputBox.Text)
        if enterPressed then
            OnSubmit:Fire(InputBox.Text)
        end
    end)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(Row, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(rowStroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(InputBox, nil, {
            BackgroundColor3 = tokens.InputBackground,
            TextColor3       = tokens.Text,
            PlaceholderColor3 = tokens.SubText,
        })
        TweenHelper.Tween(inputStroke, nil, { Color = tokens.Border })
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Get(): string
        return InputBox.Text
    end

    function api:Set(text: string)
        InputBox.Text = tostring(text)
        OnChanged:Fire(InputBox.Text)
    end

    function api:Enable()
        enabled = true
        InputBox.TextEditable = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
        TweenHelper.Tween(InputBox, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
    end

    function api:Disable()
        enabled = false
        InputBox.TextEditable = false
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
        TweenHelper.Tween(InputBox, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(t: string)  titleLabel.Text = t end
    function api:SetDescription(d: string)
        if descLabel then descLabel.Text = d end
    end
    function api:SetPlaceholder(p: string)
        InputBox.PlaceholderText = p
    end

    function api:Show()  Row.Visible = true  end
    function api:Hide()  Row.Visible = false end

    function api:Destroy()
        themeDisconnect()
        OnChanged:Destroy()
        OnSubmit:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged
    api.OnSubmit  = OnSubmit

    return api
end

return TextBox

end

-- ── Components.Toggle ─────────────────────────────────────
_Delirium_modules["Components.Toggle"] = function()
-- Components/Toggle.lua

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)
local Signal          = require(Root.Utilities.Signal)

local Toggle = {}

function Toggle.New(parent: Instance, config: table)
    config = config or {}
    local callback = config.Callback or function() end
    local hasDesc  = config.Description ~= nil and config.Description ~= ""
    local baseH    = hasDesc and 48 or 40
    local state    = config.Default == true
    local enabled  = true

    -- ─── Frames ────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "ToggleComponent",
        Size             = UDim2.new(1, 0, 0, baseH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, 8)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, 6, 6, 12, 12)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, -52, hasDesc and 0.5 or 1, 0),
        BackgroundTransparency = 1,
        Text               = config.Title or "Toggle",
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 14,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = frame,
    })

    local descLabel
    if hasDesc then
        descLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Description",
            Size               = UDim2.new(1, -52, 0.5, 0),
            Position           = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Text               = config.Description,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = frame,
        })
    end

    -- Switch track
    local track = ComponentHelper.Create("Frame", {
        Name             = "Track",
        Size             = UDim2.new(0, 38, 0, 20),
        Position         = UDim2.new(1, -38, 0.5, -10),
        BackgroundColor3 = state and ThemeEngine.GetToken("Accent") or ThemeEngine.GetToken("ToggleOff"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })
    ComponentHelper.AddCorner(track, 10)

    -- Switch knob
    local knob = ComponentHelper.Create("Frame", {
        Name             = "Knob",
        Size             = UDim2.new(0, 14, 0, 14),
        Position         = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
        Parent           = track,
    })
    ComponentHelper.AddCorner(knob, 7)

    local triggerBtn = ComponentHelper.Create("TextButton", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = "",
        Parent             = frame,
    })

    -- ─── Signals ───────────────────────────────────────────────────────────

    local OnChanged = Signal.new()

    -- ─── State management ─────────────────────────────────────────────────

    local function applyState(newState: boolean, animate: boolean)
        state = newState
        local trackColor = state and ThemeEngine.GetToken("Accent") or ThemeEngine.GetToken("ToggleOff")
        local knobPos    = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)

        if animate then
            TweenHelper.Tween(track, TweenHelper.FastInfo, { BackgroundColor3 = trackColor })
            TweenHelper.Tween(knob,  TweenHelper.SpringInfo, { Position = knobPos })
        else
            track.BackgroundColor3 = trackColor
            knob.Position          = knobPos
        end

        OnChanged:Fire(state)
        task.spawn(callback, state)
    end

    triggerBtn.MouseButton1Click:Connect(function()
        if not enabled then return end
        applyState(not state, true)
    end)

    -- Hover feedback
    triggerBtn.MouseEnter:Connect(function()
        if not enabled then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        })
    end)
    triggerBtn.MouseLeave:Connect(function()
        if not enabled then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        })
    end)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame, nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(stroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel, nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(track, nil, {
            BackgroundColor3 = state and tokens.Accent or tokens.ToggleOff,
        })
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Get(): boolean
        return state
    end

    function api:Set(val: boolean)
        applyState(val == true, true)
    end

    function api:Enable()
        enabled = true
        triggerBtn.Active = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
    end

    function api:Disable()
        enabled = false
        triggerBtn.Active = false
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(title: string)
        titleLabel.Text = title
    end

    function api:SetDescription(desc: string)
        if descLabel then
            descLabel.Text = desc
        end
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        themeDisconnect()
        OnChanged:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnChanged = OnChanged

    return api
end

return Toggle

end

-- ── Services.ConfigService ────────────────────────────────
_Delirium_modules["Services.ConfigService"] = function()
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

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("ConfigService", {
    Reset = function()
        -- On re-exec: evict the in-memory cache so fresh Load() happens next time.
        -- Do NOT wipe disk data — persisted config should survive re-execs.
        table.clear(_profiles)
    end,
}, 20)  -- priority 20 — resets before UI services that consume config

return ConfigService

end

-- ── Services.DialogService ────────────────────────────────
_Delirium_modules["Services.DialogService"] = function()
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

    -- Card height: title row + optional message row + action row (36px tall) + padding
    local cardH = hasMessage and 138 or 116

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
    -- BUG-C fix: start stroke fully transparent so it fades in with the card
    -- instead of popping visible while the card's BackgroundTransparency is still 1.
    local cardStroke = ComponentHelper.AddStroke(card, ThemeEngine.GetToken("Border"), 1)
    cardStroke.Transparency = 1  -- animated to 0 in Confirm()

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

    -- Action row — anchored to bottom of card (36px tall for touch)
    local actionRow = ComponentHelper.Create("Frame", {
        Name                   = "ActionRow",
        Size                   = UDim2.new(1, -32, 0, 36),
        Position               = UDim2.new(0, 16, 1, -50),
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

    -- Cancel button (ghost style) — 36px height for comfortable touch target
    local cancelBtn
    if hasCancel then
        cancelBtn = ComponentHelper.Create("TextButton", {
            Name                   = "CancelBtn",
            Size                   = UDim2.fromOffset(80, 36),
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

    -- Confirm button (colored by type) — 36px height for comfortable touch target
    local confirmBtn = ComponentHelper.Create("TextButton", {
        Name             = "ConfirmBtn",
        Size             = UDim2.fromOffset(80, 36),
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

    return handle, backdrop, card, cardStroke
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

    local handle, backdrop, card, cardStroke = _buildDialog(config)
    _activeDialog = handle

    -- Animate backdrop in
    AnimationEngine.Play(backdrop, TweenHelper.DefaultInfo,
        { BackgroundTransparency = BACKDROP_ALPHA }, "dlg_bg")

    -- Animate card in (FadeIn + Pop run in parallel via different keys).
    -- BUG-C fix: also fade the UIStroke in so it doesn't pop before the
    -- card background has faded in. cardStroke.Transparency starts at 1.
    AnimationEngine.FadeIn(card, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(card, 0.88, AnimationEngine.Preset.Spring)
    AnimationEngine.Play(cardStroke, TweenHelper.DefaultInfo,
        { Transparency = 0 }, "fade")

    return handle
end

-- ─── Self-register ────────────────────────────────────────────────────────────

ServiceRegistry.Register("DialogService", {
    Reset = DialogService.Reset,
    Init  = DialogService.Init,
}, 55)  -- priority 55: after ThemeEngine (10) and NotificationService (50)

return DialogService

end

-- ── Services.NotificationService ──────────────────────────
_Delirium_modules["Services.NotificationService"] = function()
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
local GuiService       = game:GetService("GuiService")
local Root             = script.Parent.Parent
local ThemeEngine      = require(Root.Core.ThemeEngine)
local AnimationEngine  = require(Root.Core.AnimationEngine)
local ComponentHelper  = require(Root.Utilities.ComponentHelper)

-- ─── Constants ────────────────────────────────────────────────────────────────

local MAX_VISIBLE     = 4        -- maximum toasts shown at once
local NOTIF_GAP       = 8        -- gap between toasts
local MARGIN          = 14       -- margin from screen edge
local ANIM_IN_OFFSET  = 24       -- pixels right-offset for slide-in

-- Compute safe notification width: max 300px but clamped to 80% of screen
-- width so notifications never overflow on narrow phones.
local function _notifWidth(): number
    local cam    = workspace.CurrentCamera
    local vp     = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    return math.min(300, math.floor(vp.X * 0.80))
end

local NOTIF_WIDTH = _notifWidth()
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

    -- Recompute width at init time (camera may not have been ready at module load).
    NOTIF_WIDTH = _notifWidth()

    -- Respect platform safe area: top inset pushes notifications below the
    -- Roblox topbar / notch; right inset keeps them away from the edge.
    local topLeft, bottomRight = GuiService:GetGuiInset()
    local topInset   = math.max(topLeft.Y,    MARGIN)
    local rightInset = math.max(bottomRight.X, MARGIN)

    _container = ComponentHelper.Create("Frame", {
        Name            = "DeliriumNotifications",
        AnchorPoint     = Vector2.new(1, 0),
        Position        = UDim2.new(1, -rightInset, 0, topInset),
        Size            = UDim2.new(0, NOTIF_WIDTH, 1, -(topInset + MARGIN)),
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

end

-- ── Init (entry point) ──────────────────────────────────
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
local ServiceRegistry     = _Delirium_require("Core.ServiceRegistry")

local Runtime             = _Delirium_require("Core.Runtime")
local ThemeEngine         = _Delirium_require("Core.ThemeEngine")
local AnimationEngine     = _Delirium_require("Core.AnimationEngine")
local NotificationService = _Delirium_require("Services.NotificationService")
local DialogService       = _Delirium_require("Services.DialogService")
local Window              = _Delirium_require("Layout.Window")

-- ─── Constants ─────────────────────────────────────────────────────────────

local RUNTIME_KEY = "__DeliriumRuntime"
local GUI_NAME    = "DeliriumUI"

-- ─── Helpers ───────────────────────────────────────────────────────────────

local function _nukeExistingGui()
    local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    local parents = {
        CoreGui,
        playerGui,
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
        local lp = Players.LocalPlayer
        if not lp then
            pcall(function()
                lp = Players:GetPropertyChangedSignal("LocalPlayer"):Wait() and Players.LocalPlayer
            end)
            lp = lp or Players.LocalPlayer
        end
        if lp then
            gui.Parent = lp:WaitForChild("PlayerGui")
        end
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
git add dist/Delirium.lua Init.lua
git commit -m "Fix LocalPlayer nil check in Init"
git push origin main