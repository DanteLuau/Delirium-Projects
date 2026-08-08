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
