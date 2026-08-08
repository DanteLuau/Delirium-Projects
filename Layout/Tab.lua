-- Layout/Tab.lua
-- Owns its Sections. Cascade: Tab:Destroy() → Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local Root            = script.Parent.Parent
local ThemeEngine     = require(Root.Core.ThemeEngine)
local TweenHelper     = require(Root.Utilities.TweenHelper)
local ComponentHelper = require(Root.Utilities.ComponentHelper)
local Maid            = require(Root.Core.Maid)
local Section         = require(script.Parent.Section)

local Tab = {}
Tab.__index = Tab

function Tab.new(config: table, windowManager: table)
    local self = setmetatable({}, Tab)

    self.Name          = config.Name or "Tab"
    self.Icon          = config.Icon or ""
    self.WindowManager = windowManager
    self.IsActive      = false
    self._destroyed    = false

    -- Owned children and resources
    self._sections = {}
    self._maid     = Maid.new()

    -- ─── Nav button ────────────────────────────────────────────────────────

    self.NavButton = ComponentHelper.Create("TextButton", {
        Name                   = "Nav_" .. self.Name,
        Size                   = UDim2.new(1, 0, 0, 34),
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 1,
        AutoButtonColor        = false,
        Text                   = "",
        Parent                 = windowManager.SideNav,
    })
    ComponentHelper.AddCorner(self.NavButton, 6)
    ComponentHelper.AddPadding(self.NavButton, 0, 0, 10, 10)

    self.Indicator = ComponentHelper.Create("Frame", {
        Name                   = "Indicator",
        Size                   = UDim2.new(0, 3, 0, 16),
        Position               = UDim2.new(0, -6, 0.5, -8),
        BackgroundColor3       = ThemeEngine.GetToken("Accent"),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        Parent                 = self.NavButton,
    })
    ComponentHelper.AddCorner(self.Indicator, 2)

    self.NavLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "Label",
        Text                   = self.Name,
        Font                   = Enum.Font.GothamMedium,
        TextSize               = 13,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Parent                 = self.NavButton,
    })

    -- ─── Page canvas ───────────────────────────────────────────────────────

    self.PageCanvas = ComponentHelper.Create("ScrollingFrame", {
        Name                   = "Page_" .. self.Name,
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 3,
        ScrollBarImageColor3   = ThemeEngine.GetToken("Border"),
        Visible                = false,
        Parent                 = windowManager.PageView,
    })
    ComponentHelper.AddPadding(self.PageCanvas, 12, 12, 12, 12)

    local pageLayout = ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 12),
        Parent    = self.PageCanvas,
    })

    -- Auto-resize canvas
    self._maid:GiveTask(
        pageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self.PageCanvas.CanvasSize =
                UDim2.new(0, 0, 0, pageLayout.AbsoluteContentSize.Y + 24)
        end)
    )

    -- ─── Interaction ───────────────────────────────────────────────────────

    self._maid:GiveTask(
        self.NavButton.MouseButton1Click:Connect(function()
            self.WindowManager:SelectTab(self)
        end)
    )

    self._maid:GiveTask(
        self.NavButton.MouseEnter:Connect(function()
            if self.IsActive then return end
            TweenHelper.Tween(self.NavButton, TweenHelper.FastInfo, {
                BackgroundTransparency = 0.6,
                BackgroundColor3       = ThemeEngine.GetToken("Surface"),
            })
            TweenHelper.Tween(self.NavLabel, TweenHelper.FastInfo, {
                TextColor3 = ThemeEngine.GetToken("Text"),
            })
        end)
    )

    self._maid:GiveTask(
        self.NavButton.MouseLeave:Connect(function()
            if self.IsActive then return end
            TweenHelper.Tween(self.NavButton, TweenHelper.FastInfo, {
                BackgroundTransparency = 1,
            })
            TweenHelper.Tween(self.NavLabel, TweenHelper.FastInfo, {
                TextColor3 = ThemeEngine.GetToken("SubText"),
            })
        end)
    )

    -- ─── Theme listener ────────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        self.PageCanvas.ScrollBarImageColor3 = tokens.Border
        if self.IsActive then
            self.NavLabel.TextColor3        = tokens.Accent
            self.Indicator.BackgroundColor3 = tokens.Accent
            self.NavButton.BackgroundColor3 = tokens.Surface
        else
            self.NavLabel.TextColor3 = tokens.SubText
        end
    end))

    return self
end

-- ─── Section management ────────────────────────────────────────────────────

function Tab:CreateSection(title: string)
    local section = Section.new(title, self.PageCanvas)
    table.insert(self._sections, section)
    return section
end

function Tab:SetActive(active: boolean)
    self.IsActive = active
    self.PageCanvas.Visible = active

    if active then
        TweenHelper.Tween(self.NavButton, TweenHelper.DefaultInfo, {
            BackgroundTransparency = 0.2,
            BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        })
        TweenHelper.Tween(self.NavLabel, TweenHelper.DefaultInfo, {
            TextColor3 = ThemeEngine.GetToken("Accent"),
        })
        TweenHelper.Tween(self.Indicator, TweenHelper.DefaultInfo, {
            BackgroundTransparency = 0,
        })
    else
        TweenHelper.Tween(self.NavButton, TweenHelper.FastInfo, {
            BackgroundTransparency = 1,
        })
        TweenHelper.Tween(self.NavLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("SubText"),
        })
        TweenHelper.Tween(self.Indicator, TweenHelper.FastInfo, {
            BackgroundTransparency = 1,
        })
    end
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Tab:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- Cascade: destroy all owned sections (Section → Component)
    for _, section in ipairs(self._sections) do
        pcall(function() section:Destroy() end)
    end
    table.clear(self._sections)

    -- Clean own resources: theme listener + input connections
    self._maid:DoCleaning()

    -- Destroy UI instances
    if self.NavButton  and self.NavButton.Parent  then self.NavButton:Destroy()  end
    if self.PageCanvas and self.PageCanvas.Parent then self.PageCanvas:Destroy() end
end

return Tab
