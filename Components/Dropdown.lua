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

            Btn.MouseEnter:Connect(function()
                if not isSelected then
                    TweenHelper.Tween(Btn, TweenHelper.FastInfo, {
                        BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
                    })
                end
            end)
            Btn.MouseLeave:Connect(function()
                if not isSelected then
                    TweenHelper.Tween(Btn, TweenHelper.FastInfo, {
                        BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
                    })
                end
            end)

            Btn.MouseButton1Click:Connect(function()
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
                    local closedH = 42
                    TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, closedH) })
                    TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = 0 })
                end
                RenderOptions()
                OnChanged:Fire(currentSelection)
            end)
        end
    end

    -- ─── Open / close ──────────────────────────────────────────────────────

    Trigger.MouseButton1Click:Connect(function()
        if not enabled then return end
        isOpen = not isOpen
        local targetH = isOpen and (54 + UIList.AbsoluteContentSize.Y) or 42
        TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, targetH) })
        TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = isOpen and 180 or 0 })
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
        themeDisconnect()
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged

    return api
end

return Dropdown
