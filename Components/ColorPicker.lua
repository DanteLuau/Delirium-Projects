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

    -- SV cursor dot
    local SVCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0, 10, 0, 10),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(s, 0, 1 - v, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = SVSquare,
    })
    ComponentHelper.AddCorner(SVCursor, 5)
    ComponentHelper.AddStroke(SVCursor, Color3.new(0,0,0), 1)

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

    -- Hue cursor line
    local HueCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(1, 4, 0, 4),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(0.5, 0, h, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = HueStrip,
    })
    ComponentHelper.AddCorner(HueCursor, 2)
    ComponentHelper.AddStroke(HueCursor, Color3.new(0,0,0), 1)

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

    local draggingSV  = false
    local draggingHue = false
    local globalConns = {}

    SVSquare.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingSV = true
            local pos = Vector2.new(input.Position.X, input.Position.Y)
            local rel = pos - SVSquare.AbsolutePosition
            s = math.clamp(rel.X / SVSquare.AbsoluteSize.X, 0, 1)
            v = 1 - math.clamp(rel.Y / SVSquare.AbsoluteSize.Y, 0, 1)
            rebuildColor()
        end
    end)

    HueStrip.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            draggingHue = true
            local pos = Vector2.new(input.Position.X, input.Position.Y)
            local rel = pos - HueStrip.AbsolutePosition
            h = math.clamp(rel.Y / HueStrip.AbsoluteSize.Y, 0, 1)
            rebuildColor()
        end
    end)

    table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

        local pos = Vector2.new(input.Position.X, input.Position.Y)
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
