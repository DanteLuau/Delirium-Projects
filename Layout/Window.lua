-- Layout/Window.lua
-- Owns its Tabs. Cascade: Window:Destroy() → Tab:Destroy() → Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
local Root              = script.Parent.Parent
local ThemeEngine       = require(Root.Core.ThemeEngine)
local AnimationEngine   = require(Root.Core.AnimationEngine)
local TweenHelper       = require(Root.Utilities.TweenHelper)
local ComponentHelper   = require(Root.Utilities.ComponentHelper)
local Maid              = require(Root.Core.Maid)
local DialogService     = require(Root.Services.DialogService)
local Tab               = require(script.Parent.Tab)

local TITLEBAR_H     = 45
local BUTTON_SIZE    = 28
local BUTTON_GAP     = 4
local BUTTON_ROW_W   = BUTTON_SIZE * 3 + BUTTON_GAP * 2  -- 92px (3 buttons: ⌘ − ×)
local DRAG_EXCLUSION = BUTTON_ROW_W + 20                  -- 112px from right edge
local MINI_SIZE      = 52    -- MiniIconFrame side length

local Window = {}
Window.__index = Window

-- ─── Constructor ───────────────────────────────────────────────────────────

function Window.new(config: table, parentGui: ScreenGui)
    local self = setmetatable({}, Window)

    self._config     = config
    self.Name        = config.Name     or "Delirium"
    self.Subtitle    = config.Subtitle or ""
    self.IsOpen      = true
    self.IsMinimized = false
    self.IsMiniIcon  = false
    self.CurrentTab  = nil
    self._destroyed  = false
    self._parentGui  = parentGui

    self._tabs = {}
    self._maid = Maid.new()

    -- Store original size for Restore().
    self._originalSize = config.Size or UDim2.fromOffset(580, 380)

    -- ─── Main frame ──────────────────────────────────────────────────────

    self.MainFrame = ComponentHelper.Create("Frame", {
        Name             = "DeliriumMainFrame",
        Size             = self._originalSize,
        Position         = UDim2.fromScale(0.5, 0.5),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        BackgroundColor3 = ThemeEngine.GetToken("Background"),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = parentGui,
    })
    ComponentHelper.AddCorner(self.MainFrame, 10)
    local mainStroke = ComponentHelper.AddStroke(self.MainFrame, ThemeEngine.GetToken("Border"), 1)

    -- ─── Title bar ───────────────────────────────────────────────────────

    self.TitleBar = ComponentHelper.Create("Frame", {
        Name                   = "TitleBar",
        Size                   = UDim2.new(1, 0, 0, TITLEBAR_H),
        BackgroundTransparency = 1,
        Parent                 = self.MainFrame,
    })
    ComponentHelper.AddPadding(self.TitleBar, 0, 0, 16, 16)

    self.TitleLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "TitleLabel",
        Text                   = self.Name,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 16,
        TextColor3             = ThemeEngine.GetToken("Text"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(0.6, 0, 1, 0),
        Position               = UDim2.new(0, 0, 0.20, 0),
        BackgroundTransparency = 1,
        Parent                 = self.TitleBar,
    })

    if self.Subtitle ~= "" then
        ComponentHelper.Create("TextLabel", {
            Name                   = "Subtitle",
            Text                   = self.Subtitle,
            Font                   = Enum.Font.Gotham,
            TextSize               = 12,
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextXAlignment         = Enum.TextXAlignment.Left,
            Size                   = UDim2.new(0.6, 0, 1, 0),
            Position               = UDim2.new(0, 0, 0.30, 0),
            BackgroundTransparency = 1,
            Parent                 = self.TitleBar,
        })
        self.TitleLabel.Size = UDim2.new(0.6, 0, 0.45, 0)
    end

    -- ─── Title bar buttons: [⌘] [−] [×] ─────────────────────────────────

    self.ButtonRow = ComponentHelper.Create("Frame", {
        Name                   = "ButtonRow",
        Size                   = UDim2.fromOffset(BUTTON_ROW_W, BUTTON_SIZE),
        Position               = UDim2.new(1, 0, 0.5, 0),
        AnchorPoint            = Vector2.new(1, 0.5),
        BackgroundTransparency = 1,
        Parent                 = self.TitleBar,
    })
    ComponentHelper.AddListLayout(self.ButtonRow, {
        FillDirection       = Enum.FillDirection.Horizontal,
        Padding             = UDim.new(0, BUTTON_GAP),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
    })

    local errorColor = ThemeEngine.GetToken("Error") or Color3.fromRGB(220, 60, 60)

    -- Build buttons; explicit LayoutOrder keeps order stable regardless of insertion.
    self._miniIconBtn = self:_BuildTitleButton(self.ButtonRow, "⌘", ThemeEngine.GetToken("SubText"))
    self._minimizeBtn = self:_BuildTitleButton(self.ButtonRow, "−", ThemeEngine.GetToken("SubText"))
    self._closeBtn    = self:_BuildTitleButton(self.ButtonRow, "×", errorColor)

    self._miniIconBtn.LayoutOrder = 1
    self._minimizeBtn.LayoutOrder = 2
    self._closeBtn.LayoutOrder    = 3

    self._maid:GiveTask(self._miniIconBtn.MouseButton1Click:Connect(function()
        self:MiniIconify()
    end))
    self._maid:GiveTask(self._minimizeBtn.MouseButton1Click:Connect(function()
        self:ToggleMinimize()
    end))
    self._maid:GiveTask(self._closeBtn.MouseButton1Click:Connect(function()
        self:Close()
    end))

    -- ─── Content container ───────────────────────────────────────────────

    self.ContentContainer = ComponentHelper.Create("Frame", {
        Name                   = "ContentContainer",
        Size                   = UDim2.new(1, 0, 1, -TITLEBAR_H),
        Position               = UDim2.new(0, 0, 0, TITLEBAR_H),
        BackgroundTransparency = 1,
        Parent                 = self.MainFrame,
    })

    self.SideNav = ComponentHelper.Create("ScrollingFrame", {
        Name                   = "SideNav",
        Size                   = UDim2.new(0, 140, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = 0,
        Parent                 = self.ContentContainer,
    })
    ComponentHelper.AddPadding(self.SideNav, 8, 8, 8, 8)
    ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
        Parent    = self.SideNav,
    })

    ComponentHelper.Create("Frame", {
        Name             = "NavDivider",
        Size             = UDim2.new(0, 1, 1, -16),
        Position         = UDim2.new(0, 140, 0, 8),
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        Parent           = self.ContentContainer,
    })

    self.PageView = ComponentHelper.Create("Frame", {
        Name                   = "PageView",
        Size                   = UDim2.new(1, -141, 1, 0),
        Position               = UDim2.new(0, 141, 0, 0),
        BackgroundTransparency = 1,
        Parent                 = self.ContentContainer,
    })

    -- ─── MiniIconFrame (hidden until MiniIconify()) ───────────────────────

    self._miniIconFrame  = self:_BuildMiniIconFrame(parentGui)
    self._miniDragMoved  = false

    -- ─── Dragging ─────────────────────────────────────────────────────────

    self:_EnableDragging()
    self:_EnableMiniIconDragging()

    -- ─── Theme listeners ──────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(self.MainFrame,  nil, { BackgroundColor3 = tokens.Background })
        TweenHelper.Tween(mainStroke,      nil, { Color            = tokens.Border     })
        TweenHelper.Tween(self.TitleLabel, nil, { TextColor3       = tokens.Text       })

        local err = tokens.Error or Color3.fromRGB(220, 60, 60)
        TweenHelper.Tween(self._miniIconBtn, nil, { TextColor3 = tokens.SubText })
        TweenHelper.Tween(self._minimizeBtn, nil, { TextColor3 = tokens.SubText })
        TweenHelper.Tween(self._closeBtn,    nil, { TextColor3 = err            })

        -- MiniIconFrame theme passthrough
        if self._miniIconFrame then
            self._miniIconFrame.BackgroundColor3 = tokens.Surface or tokens.Background
            local stroke = self._miniIconFrame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke.Color = tokens.Border end
            local glyph = self._miniIconFrame:FindFirstChild("Glyph")
            if glyph then glyph.TextColor3 = tokens.SubText end
        end
    end))

    return self
end

-- ─── Private: title button factory ────────────────────────────────────────

-- icon:    single-glyph string ("⌘", "−", "×")
-- hoverBg: Color3 baked into BackgroundColor3; transparency animates in/out
function Window:_BuildTitleButton(parent: Frame, icon: string, hoverBg: Color3): TextButton
    local btn = ComponentHelper.Create("TextButton", {
        Name                   = "TitleBtn",
        Size                   = UDim2.fromOffset(BUTTON_SIZE, BUTTON_SIZE),
        BackgroundColor3       = hoverBg,
        BackgroundTransparency = 1,
        Text                   = icon,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 15,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        AutoButtonColor        = false,
        BorderSizePixel        = 0,
        Parent                 = parent,
    })
    ComponentHelper.AddCorner(btn, 6)

    self._maid:GiveTask(btn.MouseEnter:Connect(function()
        TweenHelper.Tween(btn, TweenHelper.FastInfo, {
            BackgroundTransparency = 0.78,
            TextColor3             = ThemeEngine.GetToken("Text"),
        }, "btnhov")
    end))

    self._maid:GiveTask(btn.MouseLeave:Connect(function()
        TweenHelper.Tween(btn, TweenHelper.FastInfo, {
            BackgroundTransparency = 1,
            TextColor3             = ThemeEngine.GetToken("SubText"),
        }, "btnhov")
    end))

    return btn
end

-- ─── Private: build MiniIconFrame ─────────────────────────────────────────

function Window:_BuildMiniIconFrame(parentGui: ScreenGui): Frame
    local cam    = workspace.CurrentCamera or { ViewportSize = Vector2.new(1920, 1080) }
    local screen = cam.ViewportSize
    local half   = MINI_SIZE / 2

    -- IgnoreGuiInset = true → scale(0.5) = screen centre.
    -- Offset to bottom-left corner: ~20px from each edge.
    local initOffX = -(screen.X / 2) + 20 + half  -- 46px from left edge
    local initOffY =  (screen.Y / 2) - 20 - half  -- 46px from bottom edge

    local frame = ComponentHelper.Create("Frame", {
        Name             = "MiniIconFrame",
        Size             = UDim2.fromOffset(MINI_SIZE, MINI_SIZE),
        AnchorPoint      = Vector2.new(0.5, 0.5),
        Position         = UDim2.new(0.5, initOffX, 0.5, initOffY),
        BackgroundColor3 = ThemeEngine.GetToken("Surface") or ThemeEngine.GetToken("Background"),
        BorderSizePixel  = 0,
        Visible          = false,
        ZIndex           = 90,
        Parent           = parentGui,
    })
    ComponentHelper.AddCorner(frame, 12)
    ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)

    -- Glyph label
    ComponentHelper.Create("TextLabel", {
        Name                   = "Glyph",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "⌘",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 20,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Center,
        TextYAlignment         = Enum.TextYAlignment.Center,
        ZIndex                 = 91,
        Parent                 = frame,
    })

    -- Full-frame TextButton as the click/hover hitbox.
    -- Also used as the InputBegan source for drag (Frame.InputBegan is blocked by this button).
    local hitbox = ComponentHelper.Create("TextButton", {
        Name                   = "RestoreHitbox",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        ZIndex                 = 92,
        Parent                 = frame,
    })

    -- Hover effects
    self._maid:GiveTask(hitbox.MouseEnter:Connect(function()
        TweenHelper.Tween(frame, TweenHelper.FastInfo,
            { BackgroundColor3 = ThemeEngine.GetToken("Border") }, "minihov")
        local glyph = frame:FindFirstChild("Glyph")
        if glyph then
            TweenHelper.Tween(glyph, TweenHelper.FastInfo,
                { TextColor3 = ThemeEngine.GetToken("Text") }, "miniglyph")
        end
    end))

    self._maid:GiveTask(hitbox.MouseLeave:Connect(function()
        local surface = ThemeEngine.GetToken("Surface") or ThemeEngine.GetToken("Background")
        TweenHelper.Tween(frame, TweenHelper.FastInfo,
            { BackgroundColor3 = surface }, "minihov")
        local glyph = frame:FindFirstChild("Glyph")
        if glyph then
            TweenHelper.Tween(glyph, TweenHelper.FastInfo,
                { TextColor3 = ThemeEngine.GetToken("SubText") }, "miniglyph")
        end
    end))

    -- Restore on click — drag detection guard applied in _EnableMiniIconDragging
    self._maid:GiveTask(hitbox.MouseButton1Click:Connect(function()
        if self._miniDragMoved then
            self._miniDragMoved = false
            return
        end
        if self.IsMiniIcon then
            self:RestoreFromMiniIcon()
        end
    end))

    -- Expose hitbox so _EnableMiniIconDragging can wire InputBegan to it directly.
    -- Frame.InputBegan is eaten by the TextButton on top; hitbox IS the input surface.
    self._miniIconHitbox = hitbox

    return frame
end

-- ─── Private: screen clamp helper ─────────────────────────────────────────

-- Returns a clamped UDim2.new(0.5, offX, 0.5, offY) for `frame`
-- given proposed scale-0.5 offsets (pixels from screen centre).
-- Hard clamp: all 4 edges stay within the screen bounds.
function Window:_ClampToScreen(frame: GuiObject, rawOffX: number, rawOffY: number): UDim2
    local cam      = workspace.CurrentCamera or { ViewportSize = Vector2.new(1920, 1080) }
    local screen   = cam.ViewportSize
    local sz       = frame.AbsoluteSize

    -- ScreenGui has IgnoreGuiInset = true → GUI space = full screen.
    -- scale(0.5, 0.5) resolves to (screen.X/2, screen.Y/2) exactly.
    -- We still read topInset so the window can't be dragged behind the Roblox topbar.
    local topInset = GuiService:GetGuiInset().Y   -- 36px on PC, 0 if topbar disabled

    local cx = screen.X * 0.5 + rawOffX
    local cy = screen.Y * 0.5 + rawOffY

    -- Hard clamp:
    --   left  >= 0              →  cx >= sz.X/2
    --   right <= screen.X       →  cx <= screen.X - sz.X/2
    --   top   >= topbar bottom  →  cy >= topInset + sz.Y/2
    --   bot   <= screen.Y       →  cy <= screen.Y - sz.Y/2
    cx = math.clamp(cx, sz.X * 0.5,            screen.X - sz.X * 0.5)
    cy = math.clamp(cy, topInset + sz.Y * 0.5, screen.Y - sz.Y * 0.5)

    return UDim2.new(0.5, cx - screen.X * 0.5,
                     0.5, cy - screen.Y * 0.5)
end

-- ─── Dragging — MainFrame ──────────────────────────────────────────────────

function Window:_EnableDragging()
    local dragging  = false
    local dragStart, startPos

    self._maid:GiveTask(self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        -- Skip the button zone on the right side of the TitleBar.
        local relX = input.Position.X - self.TitleBar.AbsolutePosition.X
        if relX > self.TitleBar.AbsoluteSize.X - DRAG_EXCLUSION then return end

        dragging  = true
        dragStart = input.Position
        startPos  = self.MainFrame.Position
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta  = input.Position - dragStart
            local newPos = self:_ClampToScreen(
                self.MainFrame,
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
            TweenHelper.Tween(self.MainFrame,
                TweenInfo.new(0.04, Enum.EasingStyle.Linear),
                { Position = newPos })
        end
    end))

    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ─── Dragging — MiniIconFrame ──────────────────────────────────────────────

function Window:_EnableMiniIconDragging()
    local DRAG_THRESHOLD = 5   -- pixels; below this treat input as a click
    local dragging       = false
    local dragStart, startPos

    -- Wire to hitbox, NOT frame — the TextButton on top intercepts all InputBegan
    -- events before they reach the parent Frame, so frame.InputBegan never fires.
    self._maid:GiveTask(self._miniIconHitbox.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        dragging            = true
        self._miniDragMoved = false
        dragStart           = input.Position
        startPos            = self._miniIconFrame.Position
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            if delta.Magnitude > DRAG_THRESHOLD then
                self._miniDragMoved = true
            end
            local newPos = self:_ClampToScreen(
                self._miniIconFrame,
                startPos.X.Offset + delta.X,
                startPos.Y.Offset + delta.Y
            )
            self._miniIconFrame.Position = newPos  -- direct assign; snappy drag feel
        end
    end))

    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))
end

-- ─── Tab management ────────────────────────────────────────────────────────

function Window:CreateTab(config: table)
    assert(type(config) == "table" and config.Name,
        "Window:CreateTab requires a config table with a 'Name' field")
    local tab = Tab.new(config, self)
    table.insert(self._tabs, tab)
    if #self._tabs == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function Window:SelectTab(targetTab)
    for _, tab in ipairs(self._tabs) do
        tab:SetActive(tab == targetTab)
    end
    self.CurrentTab = targetTab
end

-- ─── Window state API ──────────────────────────────────────────────────────

function Window:SetTitle(title: string)
    self.Name = title
    self.TitleLabel.Text = title
end

-- Collapse to TitleBar height only.
function Window:Minimize()
    if self.IsMinimized then return end
    self.IsMinimized = true

    -- Hide content slightly before tween ends so content doesn't clip visibly.
    task.delay(0.06, function()
        if self.IsMinimized and self.ContentContainer then
            self.ContentContainer.Visible = false
        end
    end)

    TweenHelper.Tween(self.MainFrame, TweenHelper.SmoothInfo, {
        Size = UDim2.fromOffset(self._originalSize.X.Offset, TITLEBAR_H),
    }, "minimize")

    if self._config.OnMinimize then
        task.spawn(self._config.OnMinimize)
    end
end

-- Restore to original size.
function Window:Restore()
    if not self.IsMinimized then return end
    self.IsMinimized = false

    self.ContentContainer.Visible = true

    TweenHelper.Tween(self.MainFrame, TweenHelper.SmoothInfo, {
        Size = self._originalSize,
    }, "minimize")

    if self._config.OnRestore then
        task.spawn(self._config.OnRestore)
    end
end

function Window:ToggleMinimize()
    if self.IsMinimized then
        self:Restore()
    else
        self:Minimize()
    end
end

-- ─── MiniIcon API ──────────────────────────────────────────────────────────

-- Shrink the window down to the floating MiniIconFrame chip.
function Window:MiniIconify()
    if self.IsMiniIcon or self._destroyed then return end
    self.IsMiniIcon  = true
    self.IsMinimized = false

    self.ContentContainer.Visible = false

    AnimationEngine.FadeOut(self.MainFrame, TweenHelper.FastInfo)
    task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        if not self._destroyed then
            self.MainFrame.Visible = false
        end
    end)

    -- Show MiniIconFrame: fade + spring pop
    self._miniIconFrame.BackgroundTransparency = 1
    self._miniIconFrame.Visible                = true
    AnimationEngine.FadeIn(self._miniIconFrame, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(self._miniIconFrame, 0.80, AnimationEngine.Preset.Spring)

    if self._config.OnMiniIcon then
        task.spawn(self._config.OnMiniIcon)
    end
end

-- Restore from the MiniIconFrame back to the full window.
function Window:RestoreFromMiniIcon()
    if not self.IsMiniIcon or self._destroyed then return end
    self.IsMiniIcon = false

    AnimationEngine.FadeOut(self._miniIconFrame, TweenHelper.FastInfo)
    task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        if not self._destroyed then
            self._miniIconFrame.Visible = false
        end
    end)

    -- Restore window with matching pop
    self.MainFrame.BackgroundTransparency = 1
    self.MainFrame.Size                   = self._originalSize
    self.MainFrame.Visible                = true
    self.ContentContainer.Visible         = true

    AnimationEngine.FadeIn(self.MainFrame, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(self.MainFrame, 0.92, AnimationEngine.Preset.Spring)

    if self._config.OnRestore then
        task.spawn(self._config.OnRestore)
    end
end

-- ─── Close ─────────────────────────────────────────────────────────────────

-- Routes through CloseWarning dialog when configured; otherwise closes immediately.
function Window:Close()
    if self._destroyed then return end

    if self._config.CloseWarning then
        DialogService.Confirm({
            Title   = "Close window?",
            Message = self._config.CloseMessage or "This will close the window.",
            Type    = "Warning",
            Confirm = { Label = "Close",  Callback = function() self:_ExecuteClose() end },
            Cancel  = { Label = "Cancel" },
        })
    else
        self:_ExecuteClose()
    end
end

-- Internal: run the fade-out + destroy sequence.
function Window:_ExecuteClose()
    if self._destroyed then return end

    if self._config.OnClose then
        task.spawn(self._config.OnClose)
    end

    AnimationEngine.FadeOut(self.MainFrame, TweenHelper.FastInfo)
    task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        self:Destroy()
    end)
end

function Window:Show()
    self.IsOpen = true
    self.MainFrame.Visible = true
    TweenHelper.Tween(self.MainFrame, TweenHelper.DefaultInfo, {
        BackgroundTransparency = 0,
    })
end

function Window:Hide()
    self.IsOpen = false
    TweenHelper.Tween(self.MainFrame, TweenHelper.DefaultInfo, {
        BackgroundTransparency = 1,
    })
    task.delay(TweenHelper.DefaultInfo.Time, function()
        if not self.IsOpen then
            self.MainFrame.Visible = false
        end
    end)
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    for _, tab in ipairs(self._tabs) do
        pcall(function() tab:Destroy() end)
    end
    table.clear(self._tabs)

    self._maid:DoCleaning()

    if self.MainFrame and self.MainFrame.Parent then
        self.MainFrame:Destroy()
    end

    if self._miniIconFrame and self._miniIconFrame.Parent then
        self._miniIconFrame:Destroy()
    end
end

return Window
