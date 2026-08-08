-- Core/AnimationEngine.lua
-- Interrupt-safe animation layer. Always cancel the in-flight tween before
-- starting a new one on the same instance+key, so rapid state changes never
-- stack or fight each other.
--
-- Usage:
--   local AnimationEngine = require(script.Parent.AnimationEngine)
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
