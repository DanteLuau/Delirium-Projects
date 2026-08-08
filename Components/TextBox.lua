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
