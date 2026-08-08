-- Components/Paragraph.lua
-- Multi-line wrapped text block. Optional bold title above the body.
-- Height grows automatically with content via AutomaticSize.
--
-- Usage:
--   Section:CreateParagraph({
--       Title = "About",  -- optional
--       Content = "Long text that wraps across multiple lines...",
--   })

local Root            = script.Parent.Parent
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ThemeEngine     = require(Root.Core.ThemeEngine)

local Paragraph = {}

function Paragraph.New(parent: Instance, config: table)
    config = config or {}

    local title    = config.Title   or ""
    local content  = config.Content or config.Text or ""
    local hasTitle = title ~= ""

    -- ─── Frame ──────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name          = "ParagraphComponent",
        Size          = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
        Parent          = parent,
    })
    ComponentHelper.AddCorner(frame, 8)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, 10, 10, 12, 12)

    ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 6),
        Parent    = frame,
    })

    -- Optional title label
    local titleLabel
    if hasTitle then
        titleLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Title",
            Size               = UDim2.new(1, 0, 0, 0),
            AutomaticSize      = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text               = title,
            TextColor3         = ThemeEngine.GetToken("Text"),
            TextSize           = 13,
            Font               = Enum.Font.GothamBold,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextWrapped        = true,
            LayoutOrder        = 0,
            Parent             = frame,
        })
    end

    -- Body text
    local bodyLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Body",
        Size               = UDim2.new(1, 0, 0, 0),
        AutomaticSize      = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text               = content,
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 12,
        Font               = Enum.Font.Gotham,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextWrapped        = true,
        LineHeight         = 1.4,
        LayoutOrder        = 1,
        Parent             = frame,
    })

    -- ─── Theme updates ───────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame,      nil, {BackgroundColor3 = tokens.Surface})
        TweenHelper.Tween(stroke,     nil, {Color = tokens.Border})
        TweenHelper.Tween(bodyLabel,  nil, {TextColor3 = tokens.SubText})
        if titleLabel then
            TweenHelper.Tween(titleLabel, nil, {TextColor3 = tokens.Text})
        end
    end)

    -- ─── Public API ──────────────────────────────────────────────────────────

    local api = {}

    function api:SetTitle(text: string)
        if titleLabel then
            titleLabel.Text = text
        end
    end

    function api:SetContent(text: string)
        bodyLabel.Text = tostring(text)
    end

    -- Append text on a new line.
    function api:Append(text: string)
        bodyLabel.Text = bodyLabel.Text .. "\n" .. tostring(text)
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

return Paragraph
