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

    -- Track / hitArea: begin drag on mouse down
    hitArea.MouseButton1Down:Connect(function()
        if not enabled then return end
        startDrag(UserInputService:GetMouseLocation().X)
    end)

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
