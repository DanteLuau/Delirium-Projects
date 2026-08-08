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

    triggerBtn.MouseEnter:Connect(function()
        if not enabled or loading then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        })
    end)

    triggerBtn.MouseLeave:Connect(function()
        if not enabled or loading then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        })
    end)

    triggerBtn.MouseButton1Down:Connect(function()
        if not enabled or loading then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            Size = UDim2.new(1, -4, 0, baseH - 2),
        })
    end)

    triggerBtn.MouseButton1Up:Connect(function()
        if not enabled or loading then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            Size = UDim2.new(1, 0, 0, baseH),
        })
    end)

    triggerBtn.MouseButton1Click:Connect(function()
        if not enabled or loading then return end

        OnClicked:Fire()

        -- Wrap callback with loading animation
        task.spawn(function()
            playLoading()
            callback()
            playSuccess()
        end)
    end)

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
        OnClicked:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnClicked = OnClicked

    return api
end

return Button
