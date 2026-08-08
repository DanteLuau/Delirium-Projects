-- Components/Keybind.lua

local UserInputService = game:GetService("UserInputService")
local Root             = script.Parent.Parent
local ComponentHelper  = require(Root.Utilities.ComponentHelper)
local TweenHelper      = require(Root.Utilities.TweenHelper)
local ThemeEngine      = require(Root.Core.ThemeEngine)
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

    local function stopListening()
        isListening = false
        if globalConn then
            globalConn:Disconnect()
            globalConn = nil
        end
        BindBtn.Text      = currentKey.Name
        BindBtn.TextColor3 = ThemeEngine.GetToken("Text")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
    end

    BindBtn.MouseButton1Click:Connect(function()
        if not enabled or isListening then return end
        isListening = true
        BindBtn.Text       = "..."
        BindBtn.TextColor3 = ThemeEngine.GetToken("Warning")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Warning"),
        })

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
        BindBtn.Text = key.Name
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
        themeDisconnect()
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged

    return api
end

return Keybind
