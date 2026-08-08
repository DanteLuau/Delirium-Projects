-- Layout/Section.lua
-- Owns its component handles. Cascade: Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local Root            = script.Parent.Parent
local ThemeEngine     = require(Root.Core.ThemeEngine)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local Maid            = require(Root.Core.Maid)

local Button      = require(Root.Components.Button)
local Toggle      = require(Root.Components.Toggle)
local Slider      = require(Root.Components.Slider)
local TextBox     = require(Root.Components.TextBox)
local Dropdown    = require(Root.Components.Dropdown)
local Keybind     = require(Root.Components.Keybind)
local ColorPicker = require(Root.Components.ColorPicker)
local Label       = require(Root.Components.Label)
local Paragraph   = require(Root.Components.Paragraph)
local Divider     = require(Root.Components.Divider)

local Section = {}
Section.__index = Section

function Section.new(title: string, parentContent: Instance)
    local self = setmetatable({}, Section)

    self.Title           = title or "Section"
    self._componentCount = 1
    self._destroyed      = false

    -- Owned children and resources
    self._handles = {}
    self._maid    = Maid.new()

    -- ─── Frame ─────────────────────────────────────────────────────────────

    self.Frame = ComponentHelper.Create("Frame", {
        Name                   = "Section_" .. self.Title,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        Parent                 = parentContent,
    })
    ComponentHelper.AddCorner(self.Frame, 8)
    local stroke = ComponentHelper.AddStroke(self.Frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(self.Frame, 10, 10, 10, 10)

    ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 8),
        Parent    = self.Frame,
    })

    self.HeaderLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "SectionHeader",
        Text                   = string.upper(self.Title),
        Font                   = Enum.Font.GothamBold,
        TextSize               = 11,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(1, 0, 0, 16),
        BackgroundTransparency = 1,
        LayoutOrder            = 0,
        Parent                 = self.Frame,
    })

    -- ─── Theme listener ─────────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(self.Frame,       nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(stroke,           nil, { Color = tokens.Border })
        TweenHelper.Tween(self.HeaderLabel, nil, { TextColor3 = tokens.SubText })
    end))

    return self
end

-- ─── Internal ──────────────────────────────────────────────────────────────

function Section:_nextOrder(): number
    local order = self._componentCount
    self._componentCount += 1
    return order
end

local function _applyOrder(frame: Instance, order: number)
    if frame then frame.LayoutOrder = order end
end

-- Track and return a component handle.
function Section:_register(handle)
    table.insert(self._handles, handle)
    return handle
end

-- ─── Component factory ─────────────────────────────────────────────────────

function Section:CreateButton(config: table)
    local h = Button.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddButton = Section.CreateButton

function Section:CreateToggle(config: table)
    local h = Toggle.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddToggle = Section.CreateToggle

function Section:CreateSlider(config: table)
    local h = Slider.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddSlider = Section.CreateSlider

function Section:CreateTextbox(config: table)
    local h = TextBox.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddTextbox = Section.CreateTextbox

function Section:CreateDropdown(config: table)
    local h = Dropdown.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddDropdown = Section.CreateDropdown

function Section:CreateKeybind(config: table)
    local h = Keybind.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddKeybind = Section.CreateKeybind

function Section:CreateColorPicker(config: table)
    local h = ColorPicker.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddColorPicker = Section.CreateColorPicker

function Section:CreateLabel(config: table)
    local h = Label.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddLabel = Section.CreateLabel

function Section:CreateParagraph(config: table)
    local h = Paragraph.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddParagraph = Section.CreateParagraph

function Section:CreateDivider(config: table)
    local h = Divider.New(self.Frame, config or {})
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h)
end
Section.AddDivider = Section.CreateDivider

-- ─── Public API ─────────────────────────────────────────────────────────────

function Section:SetTitle(title: string)
    self.Title = title
    self.HeaderLabel.Text = string.upper(title)
end

function Section:Show()
    self.Frame.Visible = true
end

function Section:Hide()
    self.Frame.Visible = false
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Section:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- Cascade: destroy all owned component handles
    -- Each handle cleans its own themeDisconnect, connections, signals, instances.
    for _, handle in ipairs(self._handles) do
        pcall(function() handle:Destroy() end)
    end
    table.clear(self._handles)

    -- Clean own resources: theme listener
    self._maid:DoCleaning()

    -- Destroy root GUI instance
    if self.Frame and self.Frame.Parent then
        self.Frame:Destroy()
    end
end

return Section
