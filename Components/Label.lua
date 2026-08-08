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
