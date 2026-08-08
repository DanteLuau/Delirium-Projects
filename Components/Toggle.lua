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
