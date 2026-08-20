-- Delirium v0.3.11  [Delirium.lua]
-- GENERATED FILE
-- DO NOT EDIT
--
-- Built with bundle.py — do not edit directly
-- Source: github.com/DanteLuau/Delirium-Projects

local _Delirium_modules = {}
local _Delirium_loaded  = {}
local _Delirium_nil     = {} -- sentinel: module returned nil

local function _Delirium_require(name)
    if _Delirium_loaded[name] == nil then
        local mod = _Delirium_modules[name]
        assert(mod, '[Delirium] Unknown module: ' .. tostring(name))
        local result = mod()
        _Delirium_loaded[name] = (result == nil) and _Delirium_nil or result
    end
    local v = _Delirium_loaded[name]
    return (v == _Delirium_nil) and nil or v
end

-- ── Utilities.ComponentHelper ─────────────────────────────
_Delirium_modules["Utilities.ComponentHelper"] = function()
-- Utilities/ComponentHelper.lua
-- Instance creation and decorator helpers.
-- Every Add* function parents the created constraint to `parent` AND returns it,
-- so callers can keep a reference if they need runtime updates.

local ComponentHelper = {}

-- ─── Core factory ──────────────────────────────────────────────────────────

-- Create an Instance, apply a property table, and optionally parent children.
-- Children (if provided) must be a sequential table of Instance values.
function ComponentHelper.Create(className: string, properties: table?, children: table?): Instance
    local instance = Instance.new(className)

    if properties then
        for prop, val in pairs(properties) do
            if prop ~= "Parent" then
                instance[prop] = val
            end
        end
        -- Set Parent last to avoid partial-parented Instance warnings.
        if properties.Parent then
            instance.Parent = properties.Parent
        end
    end

    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end

    return instance
end

-- ─── Decorators ─────────────────────────────────────────────────────────────

function ComponentHelper.AddCorner(parent: Instance, radius: number?): UICorner
    return ComponentHelper.Create("UICorner", {
        CornerRadius = UDim.new(0, radius or 8),
        Parent       = parent,
    })
end

function ComponentHelper.AddStroke(
    parent:    Instance,
    color:     Color3?,
    thickness: number?
): UIStroke
    return ComponentHelper.Create("UIStroke", {
        Color           = color or Color3.fromRGB(45, 45, 55),
        Thickness       = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent          = parent,
    })
end

function ComponentHelper.AddPadding(
    parent: Instance,
    top:    number?,
    bottom: number?,
    left:   number?,
    right:  number?
): UIPadding
    return ComponentHelper.Create("UIPadding", {
        PaddingTop    = UDim.new(0, top    or 8),
        PaddingBottom = UDim.new(0, bottom or 8),
        PaddingLeft   = UDim.new(0, left   or 12),
        PaddingRight  = UDim.new(0, right  or 12),
        Parent        = parent,
    })
end

-- ─── Layout helpers ─────────────────────────────────────────────────────────

-- Creates a UIListLayout inside `parent`.
-- opts: { SortOrder?, FillDirection?, Padding?, HorizontalAlignment?, VerticalAlignment? }
function ComponentHelper.AddListLayout(parent: Instance, opts: table?): UIListLayout
    opts = opts or {}
    return ComponentHelper.Create("UIListLayout", {
        SortOrder           = opts.SortOrder           or Enum.SortOrder.LayoutOrder,
        FillDirection       = opts.FillDirection       or Enum.FillDirection.Vertical,
        Padding             = opts.Padding             or UDim.new(0, 8),
        HorizontalAlignment = opts.HorizontalAlignment or Enum.HorizontalAlignment.Left,
        VerticalAlignment   = opts.VerticalAlignment   or Enum.VerticalAlignment.Top,
        Parent              = parent,
    })
end

-- Creates a UIGridLayout inside `parent`.
-- opts.CellPadding: UDim2   — explicit padding (takes priority)
-- opts.CellPaddingH: number — pixel gap between columns (convenience)
-- opts.CellPaddingV: number — pixel gap between rows   (convenience)
function ComponentHelper.AddGridLayout(parent: Instance, opts: table?): UIGridLayout
    opts = opts or {}
    -- UIGridLayout.CellPadding is a UDim2. Build it from convenience opts if needed.
    local cellPad: UDim2
    if opts.CellPadding then
        cellPad = opts.CellPadding
    else
        cellPad = UDim2.new(0, opts.CellPaddingH or 4, 0, opts.CellPaddingV or 4)
    end
    return ComponentHelper.Create("UIGridLayout", {
        SortOrder     = opts.SortOrder     or Enum.SortOrder.LayoutOrder,
        CellSize      = opts.CellSize      or UDim2.new(0.5, -4, 0, 36),
        CellPadding   = cellPad,
        FillDirection = opts.FillDirection or Enum.FillDirection.Horizontal,
        Parent        = parent,
    })
end

-- ─── Batch token helper ─────────────────────────────────────────────────────

-- Apply multiple theme tokens to a single instance in one call.
-- tokenMap: { [PropertyName] = TokenName, ... }
-- theme:    table from ThemeEngine.GetTokens() or ThemeEngine.GetToken()
--
-- Example:
--   ComponentHelper.ApplyTokens(frame, {
--       BackgroundColor3 = "Surface",
--       BorderColor3     = "Border",
--   }, ThemeEngine.GetTokens())
function ComponentHelper.ApplyTokens(instance: Instance, tokenMap: table, theme: table)
    for prop, tokenName in pairs(tokenMap) do
        local value = theme[tokenName]
        if value ~= nil then
            instance[prop] = value
        else
            warn(string.format(
                "ComponentHelper.ApplyTokens: token '%s' not found in theme (property '%s')",
                tostring(tokenName), tostring(prop)
            ))
        end
    end
end

-- ─── Constraint helpers ──────────────────────────────────────────────────────

-- Locks min/max pixel size on a parent.
function ComponentHelper.AddSizeConstraint(
    parent: Instance,
    minSize: Vector2?,
    maxSize: Vector2?
): UISizeConstraint
    return ComponentHelper.Create("UISizeConstraint", {
        MinSize = minSize or Vector2.new(0, 0),
        MaxSize = maxSize or Vector2.new(math.huge, math.huge),
        Parent  = parent,
    })
end

-- Enforces a fixed width/height ratio on a parent.
function ComponentHelper.AddAspectRatio(
    parent:          Instance,
    ratio:           number,
    dominantAxis:    Enum.DominantAxis?,
    aspectType:      Enum.AspectType?
): UIAspectRatioConstraint
    return ComponentHelper.Create("UIAspectRatioConstraint", {
        AspectRatio  = ratio,
        DominantAxis = dominantAxis or Enum.DominantAxis.Width,
        AspectType   = aspectType   or Enum.AspectType.FitWithinMaxSize,
        Parent       = parent,
    })
end

-- Constrains text size to a min/max pixel range.
-- Useful for responsive text that scales with container size.
function ComponentHelper.AddTextSizeConstraint(
    parent:  Instance,
    minSize: number?,
    maxSize: number?
): UITextSizeConstraint
    return ComponentHelper.Create("UITextSizeConstraint", {
        MinTextSize = minSize or 10,
        MaxTextSize = maxSize or 24,
        Parent      = parent,
    })
end

-- ─── Gradient helper ─────────────────────────────────────────────────────────

-- Creates a UIGradient inside `parent`.
-- colors: ColorSequence | array of {time, Color3} keypoints
-- transparency: optional NumberSequence
function ComponentHelper.AddGradient(
    parent:       Instance,
    colors:       ColorSequence | table,
    rotation:     number?,
    transparency: NumberSequence?
): UIGradient
    local colorSeq: ColorSequence
    if typeof(colors) == "ColorSequence" then
        colorSeq = colors
    else
        -- Build from keypoint array: {{0, Color3}, {1, Color3}, ...}
        local kps = {}
        for _, kp in ipairs(colors) do
            table.insert(kps, ColorSequenceKeypoint.new(kp[1], kp[2]))
        end
        colorSeq = ColorSequence.new(kps)
    end

    return ComponentHelper.Create("UIGradient", {
        Color        = colorSeq,
        Rotation     = rotation     or 0,
        Transparency = transparency or NumberSequence.new(0),
        Parent       = parent,
    })
end

-- ─── Automatic Callback Pipeline ──────────────────────────────────────────────
-- Automatically binds config.Callback to any signals present on a component API handle.
-- Works for all existing components (Button, Toggle, Slider, Dropdown, ColorPicker, TextBox, Keybind)
-- AND any future components automatically!
function ComponentHelper.BindCallback(api: table, config: table?)
    if not api or type(api) ~= "table" or not config or type(config) ~= "table" then
        return api
    end
    if api._callbackBound then
        return api  -- already bound, guard against duplicate connection
    end

    local callback = config.Callback
    if type(callback) == "function" then
        api._callbackBound = true
        -- Bind to the primary change signal(s) only.
        --
        -- OnChanged is the universal "value changed" signal shared by all
        -- stateful components. OnActivated is additionally bound for Keybind
        -- (fires on key press, distinct from OnChanged which fires on Set).
        -- OnClicked and OnSubmit are intentionally NOT bound:
        --   * OnClicked is Button's action signal — Button manages its own
        --     config.Callback via the loading animation path, so binding it
        --     here would double-fire the callback on every click.
        --   * OnSubmit is a submit-specific signal for direct listeners;
        --     binding it alongside OnChanged would double-fire on submit.
        local signals = {}
        if api.OnChanged then table.insert(signals, api.OnChanged) end
        if api.OnActivated then table.insert(signals, api.OnActivated) end
        for _, sig in ipairs(signals) do
            if sig and type(sig.Connect) == "function" then
                sig:Connect(function(...)
                    -- Direct pcall (no task.spawn) so callback fires synchronously
                    -- within the signal dispatch frame. Avoids double-async delay where
                    -- Signal:Fire already task.spawns the handler: adding another
                    -- task.spawn pushes the callback 2+ frames out, causing timing
                    -- failures in tests that assert immediately after Set().
                    local ok, err = pcall(callback, ...)
                    if not ok then
                        warn("[Delirium] Component callback error: " .. tostring(err))
                    end
                end)
            end
        end
    end

    return api
end

return ComponentHelper

end

-- ── Utilities.DeviceDetector ──────────────────────────────
_Delirium_modules["Utilities.DeviceDetector"] = function()
-- Utilities/DeviceDetector.lua
-- Single authoritative source of device/platform classification for Delirium.
--
-- Consumed by Window.lua, SideNav, and any layout system that needs to know
-- whether it is running on mobile, desktop, tablet, or console.
--
-- Design rules:
--   • Never relies on a single signal alone (not just TouchEnabled, not just viewport).
--   • Event-driven — no per-frame polling, no RenderStepped.
--   • Camera-nil-safe: UIS input capability signals are always available regardless
--     of camera state and are evaluated immediately on require().
--   • Exposes readiness explicitly so callers can decide whether to wait or use
--     the best-available estimate.
--
-- Platform hierarchy (in priority order):
--   Console  → GamepadEnabled  AND  NOT KeyboardEnabled  AND  NOT TouchEnabled
--   Desktop  → (KeyboardEnabled AND MouseEnabled)  OR  (TouchEnabled AND MouseEnabled)
--   Tablet   → TouchEnabled  AND  NOT MouseEnabled  AND  min(vp) >= 600
--   Mobile   → TouchEnabled  AND  NOT MouseEnabled  AND  min(vp) <  600 (or vp unavailable)
--
-- The Desktop rule covers touchscreen laptops/monitors (TouchEnabled=true, MouseEnabled=true).
-- They must NOT be classified as Mobile.

local UserInputService = game:GetService("UserInputService")
-- local Root             = script.Parent.Parent
local Signal           = _Delirium_require("Utilities.Signal")
local Maid             = _Delirium_require("Core.Maid")
local ServiceRegistry  = _Delirium_require("Core.ServiceRegistry")

-- ─── Platform constants ───────────────────────────────────────────────────────

local Platform = {
    Mobile  = "Mobile",
    Tablet  = "Tablet",
    Desktop = "Desktop",
    Console = "Console",
    Unknown = "Unknown",
}

-- ─── Module state ─────────────────────────────────────────────────────────────

local _maid     = Maid.new()
local _platform = Platform.Unknown
local _viewport = Vector2.new(0, 0)
local _ready    = false      -- true once viewport.X > 0 and viewport.Y > 0

local _cameraConn = nil      -- current camera's ViewportSize PropertyChanged connection

-- ─── Public API ───────────────────────────────────────────────────────────────

local DeviceDetector = {
    Platform = Platform,

    -- Fires whenever platform or viewport changes.
    -- Signature: Changed:Connect(function(platform: string, viewport: Vector2) end)
    Changed  = Signal.new(),
}

-- ─── UIS-based classification (camera-independent) ────────────────────────────
--
-- Returns a definitive Platform string when UIS signals alone are conclusive.
-- Returns nil when the device is touch-only and viewport is needed to distinguish
-- phone vs tablet.
local function _classifyFromUIS(): string?
    local touch    = UserInputService.TouchEnabled
    local mouse    = UserInputService.MouseEnabled
    local keyboard = UserInputService.KeyboardEnabled
    local gamepad  = UserInputService.GamepadEnabled

    -- Console: gamepad-primary, no keyboard, no touch
    if gamepad and not keyboard and not touch then
        return Platform.Console
    end

    -- Touchscreen desktop/laptop: both touch AND mouse present → not a phone
    -- This catches Surface, touchscreen monitors, Windows convertibles, etc.
    if touch and mouse then
        return Platform.Desktop
    end

    -- Standard desktop: keyboard + mouse, no touch
    if keyboard and mouse and not touch then
        return Platform.Desktop
    end

    -- Touch-only (no mouse): could be phone or tablet — need viewport to decide
    if touch and not mouse then
        return nil
    end

    -- Keyboard without mouse (edge case): treat as desktop
    if keyboard and not mouse then
        return Platform.Desktop
    end

    return nil  -- truly ambiguous; caller will use fallback
end

-- Refines touch-only result into Mobile vs Tablet using the viewport.
-- Called only when viewport is known valid (X > 0, Y > 0).
local function _refineTouchDevice(vp: Vector2): string
    -- Tablet: minimum dimension >= 600px (holds in both portrait and landscape)
    return math.min(vp.X, vp.Y) >= 600 and Platform.Tablet or Platform.Mobile
end

-- Full classification combining UIS + viewport.
local function _classify(vp: Vector2): string
    local fromUIS = _classifyFromUIS()

    -- Definitive from UIS alone — no need to look at viewport
    if fromUIS ~= nil then
        return fromUIS
    end

    -- Touch-only device: use viewport to decide phone vs tablet
    if vp.X > 0 and vp.Y > 0 then
        return _refineTouchDevice(vp)
    end

    -- Viewport not yet valid: best guess from UIS alone
    -- TouchEnabled=true, MouseEnabled=false → definitely a touch-only device;
    -- assume Mobile (safer: smaller window) until viewport confirms tablet.
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        return Platform.Mobile
    end

    return Platform.Desktop  -- safe default when nothing else fits
end

-- ─── Internal update ──────────────────────────────────────────────────────────

local function _update(vp: Vector2, fireChanged: boolean)
    local newPlatform = _classify(vp)
    local vpChanged   = (vp.X ~= _viewport.X or vp.Y ~= _viewport.Y)
    local platChanged = (newPlatform ~= _platform)

    _platform = newPlatform
    _viewport = vp
    _ready    = vp.X > 0 and vp.Y > 0

    if fireChanged and (platChanged or vpChanged) then
        DeviceDetector.Changed:Fire(newPlatform, vp)
    end
end

-- ─── Camera wiring ────────────────────────────────────────────────────────────

local function _bindCamera(camera)
    -- Disconnect previous camera's listener first
    if _cameraConn then
        _cameraConn:Disconnect()
        _cameraConn = nil
    end
    if not camera then return end

    -- Immediately evaluate current viewport
    local vp = camera.ViewportSize
    _update(vp, true)

    -- Track future viewport changes (orientation flips, window resize, notch adjustments)
    _cameraConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        _update(camera.ViewportSize, true)
    end)
end

local function _wireAll()
    -- React to the camera object itself being swapped (Roblox can replace it)
    _maid:GiveTask(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        _bindCamera(workspace.CurrentCamera)
    end))

    -- Ensure _cameraConn is always disconnected when the Maid cleans up
    _maid:GiveTask(function()
        if _cameraConn then
            _cameraConn:Disconnect()
            _cameraConn = nil
        end
    end)

    -- Initial camera bind (may be nil on very early require)
    local cam = workspace.CurrentCamera
    if cam then
        _bindCamera(cam)
    else
        -- Camera not yet available: classify from UIS signals only.
        -- _update with zero viewport → _classify will use UIS-only path.
        _update(Vector2.new(0, 0), false)
        -- The workspace.CurrentCamera PropertyChanged listener above will fire
        -- when the camera becomes available and trigger a proper re-evaluation.
    end
end

_wireAll()

-- ─── Public read API ──────────────────────────────────────────────────────────

--- Returns the current platform string ("Mobile", "Desktop", "Tablet", "Console", "Unknown").
function DeviceDetector:GetPlatform(): string
    return _platform
end

--- Returns the last known valid viewport size.
--- Returns Vector2(0,0) if viewport has not yet resolved.
function DeviceDetector:GetViewport(): Vector2
    return _viewport
end

--- True once the viewport has a non-zero size (camera available and settled).
function DeviceDetector:IsViewportReady(): boolean
    return _ready
end

--- True for Mobile and Tablet platforms.
--- Use this as the gate for compact/touch-optimised layouts.
function DeviceDetector:IsMobile(): boolean
    return _platform == Platform.Mobile or _platform == Platform.Tablet
end

--- True for Desktop and Console platforms.
function DeviceDetector:IsDesktop(): boolean
    return _platform == Platform.Desktop or _platform == Platform.Console
end

--- Raw capability check — true if the device has any touch hardware.
--- Does NOT imply the device is a phone; use IsMobile() for layout decisions.
function DeviceDetector:IsTouchDevice(): boolean
    return UserInputService.TouchEnabled
end

--- Yields the calling coroutine until the viewport is valid (non-zero).
--- Returns immediately if already ready.
--- Hard timeout: 3 seconds — returns best-available result regardless.
--- Safe to call from task.spawn(); do NOT call on the main thread without wrapping.
function DeviceDetector:WaitForReady(): (string, Vector2)
    if _ready then
        return _platform, _viewport
    end

    local done      = false
    local conn

    conn = DeviceDetector.Changed:Connect(function(_, vp)
        if vp.X > 0 and vp.Y > 0 then
            done = true
            pcall(function() conn:Disconnect() end)
        end
    end)

    -- Bounded wait: check every 50ms, give up after 3s
    local deadline = os.time() + 3
    while not done and os.time() < deadline do
        task.wait(0.05)
    end

    -- Ensure conn is always cleaned up
    pcall(function() conn:Disconnect() end)

    -- If timeout fired before viewport resolved, force a re-evaluation
    if not _ready then
        local cam = workspace.CurrentCamera
        if cam then
            _update(cam.ViewportSize, false)
        end
    end

    return _platform, _viewport
end

-- ─── Reset / lifecycle ────────────────────────────────────────────────────────
--
-- Called by ServiceRegistry.ResetAll() during Bootstrap (between execs).
-- Tears down all camera connections, resets state, and re-initialises cleanly.
-- Prevents duplicate connections from stacking across Delirium reloads.

function DeviceDetector.Reset()
    _maid:DoCleaning()
    _maid     = Maid.new()
    _platform = Platform.Unknown
    _viewport = Vector2.new(0, 0)
    _ready    = false
    -- Do NOT call Changed:DisconnectAll() here.
    -- External consumers that subscribed to Changed must survive a Reset() —
    -- clearing all handlers would silently drop their subscriptions.
    -- DeviceDetector never subscribes to its own Changed signal, so no
    -- internal cleanup is needed here.
    _wireAll()
end

-- ─── Self-register ────────────────────────────────────────────────────────────
-- Priority 4: runs before InputAdapter (5) so device state is authoritative
-- before any system that depends on it initialises.

ServiceRegistry.Register("DeviceDetector", {
    Reset = DeviceDetector.Reset,
}, 4)

return DeviceDetector

end

-- ── Utilities.Geometry ────────────────────────────────────
_Delirium_modules["Utilities.Geometry"] = function()
-- Utilities/Geometry.lua
-- Shared geometry utilities for viewport-relative element positioning.
-- Provides popup placement (position, anchor, flip direction) that anchors
-- to a trigger element and clamps to the visible viewport with safe-area insets.

local GuiService = game:GetService("GuiService")
local Geometry = {}

-- ─── Viewport queries ────────────────────────────────────────────────────────

-- Returns the current viewport size and safe-area insets in pixels.
-- Result: Vector2 viewportSize, topInset, bottomInset, leftInset, rightInset
function Geometry.GetViewport()
	local cam = workspace.CurrentCamera
	local vp = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
	local topLeft, bottomRight = GuiService:GetGuiInset()
	return vp, topLeft.Y, bottomRight.Y, topLeft.X, bottomRight.X
end

-- Returns a visible-bounds rect in screen space.
-- When `container` is provided, the rect is the container's visible area
-- (AbsolutePosition → AbsolutePosition + AbsoluteSize). Otherwise it falls back
-- to the full viewport with safe-area insets.
-- Result: { Top, Bottom, Left, Right } in screen pixels.
function Geometry.GetVisibleBounds(container: GuiObject?)
	if container and container.Parent then
		local pos = container.AbsolutePosition
		local sz  = container.AbsoluteSize
		return {
			Top    = pos.Y,
			Bottom = pos.Y + sz.Y,
			Left   = pos.X,
			Right  = pos.X + sz.X,
		}
	end
	local vp, topInset, bottomInset, leftInset, rightInset = Geometry.GetViewport()
	return {
		Top    = topInset,
		Bottom = vp.Y - bottomInset,
		Left   = leftInset,
		Right  = vp.X - rightInset,
	}
end

-- ─── Core positioning ────────────────────────────────────────────────────────

-- Position a popup adjacent to a trigger rectangle in screen space.
--
-- triggerPos:   Vector2 — top-left corner of the trigger in screen pixels
-- triggerSize:  Vector2 — width, height of the trigger in pixels
-- popupSize:    Vector2 — desired popup width, height in pixels
-- margin:       number  — gap between trigger and popup (default 4)
-- bounds:       table?  — visible-bounds rect { Top, Bottom, Left, Right } in
--                         screen pixels. Defaults to the full viewport with
--                         safe-area insets. Pass the visible PageCanvas/Window
--                         region so placement respects the actual visible area.
--
-- Anchoring model:
--   The returned `Position` is an absolute screen-space coordinate that
--   should be applied as UDim2.new(0, pos.X, 0, pos.Y) on a GUI object whose
--   AnchorPoint is set to `AnchorPoint`.
--
-- Direction decision (bounds-relative, not viewport-only):
--   • Prefers opening downward when the popup fits below the trigger.
--   • Flips upward when space below is insufficient but space above suffices.
--   • When neither fully fits, opens toward the side with more room and
--     clamps the popup height so it never extends past the bounds.
--
-- Returns a table:
--   Position       — Vector2 absolute screen position for the popup
--   AnchorPoint    — Vector2: (0,0) = top-left anchored, (0,1) = bottom-left anchored
--   Size           — Vector2: final clamped popup width/height
--   OpenDownward — boolean: true = popup opens below trigger, false = above
--
function Geometry.PositionNear(triggerPos, triggerSize, popupSize, margin, bounds)
	margin = margin or 4
	bounds = bounds or Geometry.GetVisibleBounds()

	local popupW = math.min(popupSize.X, (bounds.Right - bounds.Left) - margin * 2)
	local popupH = popupSize.Y

	local triggerBottom = triggerPos.Y + triggerSize.Y
	local triggerTop    = triggerPos.Y

	-- Horizontal: align popup left edge with trigger left edge, clamped to bounds.
	local popupX = math.clamp(triggerPos.X, bounds.Left + margin, math.max(bounds.Left + margin, bounds.Right - popupW - margin))

	-- Vertical: decide direction based on available space in the *visible bounds*
	-- (the PageCanvas/Window region, not just the global viewport).
	local spaceBelow = bounds.Bottom - triggerBottom - margin
	local spaceAbove =  triggerTop   - bounds.Top    - margin

	local openDownward

	if spaceBelow >= popupH then
		openDownward = true
	elseif spaceAbove >= popupH then
		openDownward = false
	else
		-- Neither direction fully fits — open toward the side with more room.
		openDownward = spaceBelow >= spaceAbove
	end

	local anchorPoint, popupY, finalH

	if openDownward then
		anchorPoint = Vector2.new(0, 0)  -- anchor to top-left of popup
		popupY      = triggerBottom + margin
		finalH      = math.min(popupH, math.max(48, spaceBelow))
		-- Clamp: popup must not extend past the bottom bound.
		finalH      = math.min(finalH, bounds.Bottom - popupY - margin)
	else
		anchorPoint = Vector2.new(0, 1)  -- anchor to bottom-left of popup
		popupY      = triggerTop - margin
		finalH      = math.min(popupH, math.max(48, spaceAbove))
		-- Clamp: popup must not extend past the top bound.
		finalH      = math.min(finalH, popupY - bounds.Top - margin)
	end

	-- Guard against degenerate heights (happens on tiny viewports).
	finalH = math.max(finalH, 48)

	return {
		Position       = Vector2.new(popupX, popupY),
		AnchorPoint    = anchorPoint,
		Size           = Vector2.new(popupW, finalH),
		OpenDownward  = openDownward,
	}
end

return Geometry

end

-- ── Utilities.Signal ──────────────────────────────────────
_Delirium_modules["Utilities.Signal"] = function()
-- Utilities/Signal.lua
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({}, Signal) -- fix: setmetable → setmetatable
    self._handlers = {}
    return self
end

function Signal:Connect(fn: (...any) -> ())
    assert(type(fn) == "function", "Signal:Connect expects a function")
    local handler = { fn = fn, connected = true }
    table.insert(self._handlers, handler)
    return {
        Disconnect = function()
            handler.connected = false
            -- Guard: signal may have been Destroy()d already (_handlers = nil).
            -- table.find(nil, ...) would error without this check.
            if not self._handlers then return end
            local index = table.find(self._handlers, handler)
            if index then
                table.remove(self._handlers, index)
            end
        end
    }
end

-- Alias so signal:OnChanged(fn) works as Connect(fn)
function Signal:OnChanged(fn: (...any) -> ())
    return self:Connect(fn)
end

Signal.__call = function(self, fn)
    return self:Connect(fn)
end

function Signal:Fire(...)
    -- BUG-B fix: guard against Fire() being called after Destroy().
    -- Destroy() sets _handlers = nil; ipairs(nil) would error without this check.
    if not self._handlers then return end
    local args = { ... }
    for _, handler in ipairs(self._handlers) do
        if handler.connected then
            local ok, err = pcall(handler.fn, table.unpack(args))
            if not ok then
                warn("[Signal] handler error: " .. tostring(err))
            end
        end
    end
end

-- Async variant: each handler is spawned in its own task.
-- No ordering guarantee and no error propagation back to the caller.
-- Use when handlers may yield or when fire-and-forget async behaviour is needed.
function Signal:FireDeferred(...)
    if not self._handlers then return end
    local args = { ... }
    for _, handler in ipairs(self._handlers) do
        if handler.connected then
            task.spawn(handler.fn, table.unpack(args))
        end
    end
end

function Signal:Once(fn: (...any) -> ())
    assert(type(fn) == "function", "Signal:Once expects a function")
    local connection
    connection = self:Connect(function(...)
        connection:Disconnect() -- fix: actually disconnect after first fire
        fn(...)
    end)
    return connection
end

-- Clear all handlers without destroying the Signal object.
-- Safe to call from Reset() paths where other modules still hold the Signal ref.
function Signal:DisconnectAll()
    if not self._handlers then return end
    table.clear(self._handlers)
end

function Signal:Destroy()
    if not self._handlers then return end
    table.clear(self._handlers)
    self._handlers = nil
end

return Signal
end

-- ── Utilities.TweenHelper ─────────────────────────────────
_Delirium_modules["Utilities.TweenHelper"] = function()
-- Utilities/TweenHelper.lua
-- Thin wrapper kept for backward compatibility with existing component code.
-- All preset TweenInfos mirror AnimationEngine.Preset.
-- New code should prefer AnimationEngine directly.

local TweenService     = game:GetService("TweenService")
local AnimationEngine  = _Delirium_require("Core.AnimationEngine")

local TweenHelper = {}

-- ─── Preset TweenInfos (backward compat) ──────────────────────────────────

TweenHelper.FastInfo    = AnimationEngine.Preset.Fast
TweenHelper.DefaultInfo = AnimationEngine.Preset.Default
TweenHelper.SmoothInfo  = AnimationEngine.Preset.Smooth
TweenHelper.SpringInfo  = AnimationEngine.Preset.Spring
TweenHelper.SlowInfo    = AnimationEngine.Preset.Slow

-- ─── Core helpers ──────────────────────────────────────────────────────────

-- Interrupt-safe tween. Delegates to AnimationEngine so concurrent calls on
-- the same instance+key cancel each other instead of stacking.
-- key is optional; defaults to "default" (all calls without a key share one slot).
function TweenHelper.Tween(
    instance:   Instance,
    tweenInfo:  TweenInfo?,
    properties: table,
    key:        string?
): Tween?
    return AnimationEngine.Play(instance, tweenInfo, properties, key)
end

-- Cancel all active tweens on an instance.
function TweenHelper.Cancel(instance: Instance, key: string?)
    AnimationEngine.Cancel(instance, key)
end

-- Hover helpers — returns {Enter, Leave} for connecting to MouseEnter/Leave.
-- Prefer using InputAdapter.BindAdaptiveInteraction for full cross-platform support.
function TweenHelper.BindHover(
    instance:    Instance,
    hoverProps:  table,
    normalProps: table
): {Enter: ()->(), Leave: ()->()}
    return {
        Enter = function()
            TweenHelper.Tween(instance, TweenHelper.FastInfo, hoverProps, "hover")
        end,
        Leave = function()
            TweenHelper.Tween(instance, TweenHelper.FastInfo, normalProps, "hover")
        end,
    }
end

return TweenHelper

end

-- ── Core.AnimationEngine ──────────────────────────────────
_Delirium_modules["Core.AnimationEngine"] = function()
-- Core/AnimationEngine.lua
-- Interrupt-safe animation layer. Always cancel the in-flight tween before
-- starting a new one on the same instance+key, so rapid state changes never
-- stack or fight each other.
--
-- Usage:
--   local AnimationEngine = _Delirium_require("Core.AnimationEngine")
--   AnimationEngine.Play(frame, AnimationEngine.Preset.Spring, { Size = ... }, "resize")
--   AnimationEngine.SlideIn(frame, "Bottom", 20)
--   AnimationEngine.FadeIn(frame)

local TweenService = game:GetService("TweenService")

-- ─── Presets ──────────────────────────────────────────────────────────────────

local Preset = {
    Instant = TweenInfo.new(0,    Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
    Fast    = TweenInfo.new(0.12, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Default = TweenInfo.new(0.25, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
    Smooth  = TweenInfo.new(0.35, Enum.EasingStyle.Cubic,  Enum.EasingDirection.Out),
    Spring  = TweenInfo.new(0.40, Enum.EasingStyle.Back,   Enum.EasingDirection.Out),
    Bounce  = TweenInfo.new(0.50, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out),
    Slow    = TweenInfo.new(0.60, Enum.EasingStyle.Quad,   Enum.EasingDirection.Out),
}

-- ─── State ────────────────────────────────────────────────────────────────────

-- Weak keys so destroyed instances don't prevent garbage collection.
local _active: {[Instance]: {[string]: Tween}} = setmetatable({}, {__mode = "k"})

-- Pulse generation counter (weak keys).
-- Each Pulse() call and each cancel bumps the generation; a stale loop checks
-- its captured generation before restoring state, so a cancelled/concurrent
-- pulse can never overwrite the state of a newer animation.
local _pulseGen: {[Instance]: number} = setmetatable({}, {__mode = "k"})

-- TypeWriter generation counter (weak keys).
-- Starting a new TypeWriter (or cancelling one) bumps the generation for that
-- instance; a stale writer loop checks its captured generation before writing
-- the next character, so an old writer can never overwrite newer text.
local _typeGen: {[Instance]: number} = setmetatable({}, {__mode = "k"})

local AnimationEngine = {
    Preset        = Preset,
    ReducedMotion = false,  -- set true for accessibility / testing
}

-- ─── Core ─────────────────────────────────────────────────────────────────────

-- Play a tween, cancelling any existing one registered under the same key.
-- key:  optional string that identifies this "slot" on the instance.
--       Two concurrent animations that share a key will interrupt each other.
--       Animations with different keys run in parallel without interference.
-- Returns the Tween so callers can :Wait() if they need sequencing.
function AnimationEngine.Play(
    instance:   Instance,
    tweenInfo:  TweenInfo?,
    props:      table,
    key:        string?
): Tween?
    if not instance or not instance.Parent then return nil end

    local info = AnimationEngine.ReducedMotion and Preset.Instant
        or tweenInfo or Preset.Default

    local slot = key or "__default__"

    -- Cancel the current occupant of this slot, if any.
    local bucket = _active[instance]
    if bucket then
        local existing = bucket[slot]
        if existing then
            existing:Cancel()
        end
    else
        _active[instance] = {}
        bucket = _active[instance]
    end

    local tween = TweenService:Create(instance, info, props)
    bucket[slot] = tween

    tween.Completed:Connect(function()
        -- Only clear if we're still the registered tween (not already replaced).
        if _active[instance] and _active[instance][slot] == tween then
            _active[instance][slot] = nil
        end
    end)

    tween:Play()
    return tween
end

-- Cancel all active tweens on an instance (or only those under a specific key).
function AnimationEngine.Cancel(instance: Instance, key: string?)
    if not _active[instance] then return end
    if key then
        local t = _active[instance][key]
        if t then
            t:Cancel()
            _active[instance][key] = nil
        end
    else
        for k, t in pairs(_active[instance]) do
            t:Cancel()
            _active[instance][k] = nil
        end
    end
end

-- ─── Convenience helpers ──────────────────────────────────────────────────────

-- Fade a GuiObject to fully opaque. Applies BackgroundTransparency always;
-- also fades GroupTransparency on CanvasGroups, TextTransparency on text instances, and ImageTransparency on image instances.
function AnimationEngine.FadeIn(
    instance:  GuiObject,
    fromAlpha: number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end

    local props = {}

    if instance:IsA("CanvasGroup") then
        if fromAlpha ~= nil then instance.GroupTransparency = fromAlpha end
        props.GroupTransparency = 0
    end

    -- Background — all GuiObjects
    if fromAlpha ~= nil then instance.BackgroundTransparency = fromAlpha end
    props.BackgroundTransparency = 0

    -- Text transparency
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        if fromAlpha ~= nil then instance.TextTransparency = fromAlpha end
        props.TextTransparency = 0
    end

    -- Image transparency
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        if fromAlpha ~= nil then instance.ImageTransparency = fromAlpha end
        props.ImageTransparency = 0
    end

    return AnimationEngine.Play(instance, info or Preset.Default, props, "fade")
end

-- Fade a GuiObject to fully transparent. Mirrors FadeIn target properties.
function AnimationEngine.FadeOut(instance: GuiObject, info: TweenInfo?): Tween?
    if not instance or not instance.Parent then return nil end

    local props = { BackgroundTransparency = 1 }

    if instance:IsA("CanvasGroup") then
        props.GroupTransparency = 1
    end
    if instance:IsA("TextLabel") or instance:IsA("TextButton") or instance:IsA("TextBox") then
        props.TextTransparency = 1
    end
    if instance:IsA("ImageLabel") or instance:IsA("ImageButton") then
        props.ImageTransparency = 1
    end

    return AnimationEngine.Play(instance, info or Preset.Default, props, "fade")
end

-- CloseWindow: Smooth scale-down + slide-down + GroupTransparency fade-out for windows.
function AnimationEngine.CloseWindow(
    mainFrame: GuiObject,
    onComplete: (() -> ())?,
    info: TweenInfo?
): Tween?
    if not mainFrame or not mainFrame.Parent then
        if onComplete then task.spawn(onComplete) end
        return nil
    end

    local tweenInfo = info or Preset.Fast
    local props     = { BackgroundTransparency = 1 }

    if mainFrame:IsA("CanvasGroup") then
        props.GroupTransparency = 1
    end

    local origPos = mainFrame.Position
    props.Position = UDim2.new(
        origPos.X.Scale, origPos.X.Offset,
        origPos.Y.Scale, origPos.Y.Offset + 14
    )

    local tween = AnimationEngine.Play(mainFrame, tweenInfo, props, "window_close")
    if tween then
        tween.Completed:Connect(function()
            if onComplete then task.spawn(onComplete) end
        end)
    else
        if onComplete then task.spawn(onComplete) end
    end

    return tween
end

-- Slide a GuiObject in from a direction by offsetting its position.
-- direction: "Top" | "Bottom" | "Left" | "Right"
-- distance:  pixel offset to start from (default 20)
function AnimationEngine.SlideIn(
    instance:  GuiObject,
    direction: string,
    distance:  number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end
    local d          = distance or 20
    local targetPos  = instance.Position
    local ox, oy     = 0, 0

    if direction == "Top"    then oy = -d end
    if direction == "Bottom" then oy =  d end
    if direction == "Left"   then ox = -d end
    if direction == "Right"  then ox =  d end

    instance.Position = UDim2.new(
        targetPos.X.Scale, targetPos.X.Offset + ox,
        targetPos.Y.Scale, targetPos.Y.Offset + oy
    )
    return AnimationEngine.Play(instance, info or Preset.Smooth,
        {Position = targetPos}, "slide")
end

-- Slide a GuiObject out toward a direction.
-- targetPos is optional; if omitted the current position is used as base.
function AnimationEngine.SlideOut(
    instance:  GuiObject,
    direction: string,
    distance:  number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end
    local d         = distance or 20
    local basePos   = instance.Position
    local ox, oy    = 0, 0

    if direction == "Top"    then oy = -d end
    if direction == "Bottom" then oy =  d end
    if direction == "Left"   then ox = -d end
    if direction == "Right"  then ox =  d end

    return AnimationEngine.Play(instance, info or Preset.Smooth, {
        Position = UDim2.new(
            basePos.X.Scale, basePos.X.Offset + ox,
            basePos.Y.Scale, basePos.Y.Offset + oy
        )
    }, "slide")
end

-- Quick spring pop — scales size from `fromScale` factor to full size.
-- Compensates AnchorPoint so the element scales from its visual center,
-- not from the top-left corner. Original AnchorPoint and Position are restored
-- after the tween completes.
function AnimationEngine.Pop(
    instance:  GuiObject,
    fromScale: number?,
    info:      TweenInfo?
): Tween?
    if not instance or not instance.Parent then return nil end

    local f          = fromScale or 0.88
    local finalSize  = instance.Size
    local origAnchor = instance.AnchorPoint
    local origPos    = instance.Position

    -- Rebase to center anchor so scaling appears to grow from the visual center.
    -- Compensate position to keep the element visually in the same spot.
    local adjX = finalSize.X.Offset * (0.5 - origAnchor.X)
    local adjY = finalSize.Y.Offset * (0.5 - origAnchor.Y)
    instance.AnchorPoint = Vector2.new(0.5, 0.5)
    instance.Position    = UDim2.new(
        origPos.X.Scale, origPos.X.Offset + adjX,
        origPos.Y.Scale, origPos.Y.Offset + adjY
    )

    -- Start scaled-down
    instance.Size = UDim2.new(
        finalSize.X.Scale * f, finalSize.X.Offset * f,
        finalSize.Y.Scale * f, finalSize.Y.Offset * f
    )

    local tween = AnimationEngine.Play(instance, info or Preset.Spring,
        { Size = finalSize }, "pop")

    -- Restore original anchor/position after spring settles.
    -- P2.1 race fix: only restore if THIS tween is still the registered occupant
    -- of the "pop" slot. If a newer Pop()/animation cancelled us and took over,
    -- restoring would fight the new animation and snap geometry back.
    if tween then
        tween.Completed:Connect(function()
            if instance and instance.Parent
                and _active[instance] and _active[instance]["pop"] == tween then
                instance.AnchorPoint = origAnchor
                instance.Position    = origPos
            end
        end)
    end

    return tween
end

-- Pulse: attention-grab ping-pong scale. Does NOT interrupt running tweens
-- on other keys. Runs `count` cycles then returns to original size.
-- Returns a cancel function that snaps back to original size immediately.
function AnimationEngine.Pulse(
    instance: GuiObject,
    scale:    number?,
    count:    number?,
    info:     TweenInfo?
): () -> ()
    if not instance or not instance.Parent then return function() end end

    local s         = scale or 1.05
    local times     = count or 2
    local pInfo     = info  or TweenInfo.new(0.16, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    local origSize  = instance.Size
    local cancelled = false

    -- P2.1 race fix: generation token. Each Pulse() increments the per-instance
    -- generation; loops stop the moment they're no longer current, so two
    -- concurrent Pulse() calls can never fight over final size restoration.
    _pulseGen[instance] = (_pulseGen[instance] or 0) + 1
    local myGen = _pulseGen[instance]

    task.spawn(function()
        for _ = 1, times do
            if cancelled or _pulseGen[instance] ~= myGen or not instance.Parent then break end
            local big = UDim2.new(
                origSize.X.Scale * s, origSize.X.Offset * s,
                origSize.Y.Scale * s, origSize.Y.Offset * s
            )
            local t1 = AnimationEngine.Play(instance, pInfo, { Size = big }, "pulse")
            if t1 then t1.Completed:Wait() end
            if cancelled or _pulseGen[instance] ~= myGen or not instance.Parent then break end
            local t2 = AnimationEngine.Play(instance, pInfo, { Size = origSize }, "pulse")
            if t2 then t2.Completed:Wait() end
        end
    end)

    return function()
        cancelled = true
        _pulseGen[instance] = (_pulseGen[instance] or 0) + 1  -- invalidate this run
        AnimationEngine.Cancel(instance, "pulse")
        if instance and instance.Parent then
            instance.Size = origSize
        end
    end
end

-- TypeWriter: reveals `text` one character at a time on a text instance.
-- `speed`: characters per second (default 30).
-- Returns a cancel function that snaps to full text.
--
-- P1 race fix: per-instance generation token. Starting a new TypeWriter on the
-- same instance invalidates any previous writer; a stale writer stops writing
-- immediately and never fires onComplete. Cancel() bumps the generation too,
-- so it only invalidates its own run.
function AnimationEngine.TypeWriter(
    instance:   TextLabel | TextButton | TextBox,
    text:       string,
    speed:      number?,
    onComplete: (()->())?
): () -> ()
    if not instance or not instance.Parent then return function() end end

    local interval  = 1 / (speed or 30)
    local cancelled = false

    _typeGen[instance] = (_typeGen[instance] or 0) + 1
    local myGen = _typeGen[instance]

    instance.Text = ""

    task.spawn(function()
        for i = 1, #text do
            if cancelled or _typeGen[instance] ~= myGen or not instance.Parent then break end
            instance.Text = string.sub(text, 1, i)
            task.wait(interval)
        end
        -- Only the current generation may finalize text / fire onComplete.
        if not cancelled and _typeGen[instance] == myGen and instance.Parent then
            instance.Text = text
        end
        if not cancelled and _typeGen[instance] == myGen and onComplete then
            task.spawn(onComplete)
        end
    end)

    return function()
        cancelled = true
        _typeGen[instance] = (_typeGen[instance] or 0) + 1  -- invalidate this run
        if instance and instance.Parent then
            instance.Text = text  -- snap to full
        end
    end
end

-- ─── Sequencing ───────────────────────────────────────────────────────────────

-- Run a list of steps one after another.
-- Each step: { instance, info?, props, key? }
-- onComplete fires after the last step finishes.
-- Returns a cancel function — cancels the in-flight tween and skips remaining steps.
--
-- P1 fix: the cancel function now actually cancels the currently running tween
-- (not just a flag), so no remaining steps start and onComplete never fires.
function AnimationEngine.Sequence(
    steps:      {{instance: Instance, info: TweenInfo?, props: table, key: string?}},
    onComplete: (()->())?
): () -> ()
    local cancelled = false
    local activeTween: Tween? = nil

    task.spawn(function()
        for _, step in ipairs(steps) do
            if cancelled then break end
            local tween = AnimationEngine.Play(step.instance, step.info, step.props, step.key)
            if tween then
                activeTween = tween
                tween.Completed:Wait()
                activeTween = nil
            end
            if cancelled then break end
        end
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
    end)

    return function()
        cancelled = true
        if activeTween then
            pcall(function() activeTween:Cancel() end)
            activeTween = nil
        end
    end
end

-- Fire all steps simultaneously, then call onComplete after the longest one.
-- Returns a cancel function.
--
-- P1 fix: tracks every tween created by Parallel and cancels them all on cancel,
-- so no animation keeps running after cancellation. Only tweens created by THIS
-- Parallel call are cancelled — unrelated animations on other keys are untouched.
function AnimationEngine.Parallel(
    steps:      {{instance: Instance, info: TweenInfo?, props: table, key: string?}},
    onComplete: (()->())?
): () -> ()
    local cancelled = false
    local longest   = 0
    local tweens: {Tween} = {}

    for _, step in ipairs(steps) do
        local tween = AnimationEngine.Play(step.instance, step.info, step.props, step.key)
        if tween then
            table.insert(tweens, tween)
            local t = step.info and step.info.Time or Preset.Default.Time
            if t > longest then longest = t end
        end
    end

    local thread = task.delay(longest, function()
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
        table.clear(tweens)
    end)

    return function()
        cancelled = true
        pcall(task.cancel, thread)
        for _, tween in ipairs(tweens) do
            pcall(function() tween:Cancel() end)
        end
        table.clear(tweens)
    end
end

-- Stagger: animate a list of instances in sequence with a delay between each.
-- Each instance receives FadeIn + SlideIn from Bottom.
-- Returns a cancel function.
--
-- P2 fix: tracks the tweens started for each staggered instance and cancels
-- them on cancel, so already-started animations stop immediately.
function AnimationEngine.Stagger(
    instances:  {GuiObject},
    delay:      number?,
    info:       TweenInfo?,
    onComplete: (()->())?
): () -> ()
    local d         = delay or 0.06
    local cancelled = false
    local activeTweens: {Tween} = {}

    task.spawn(function()
        for _, inst in ipairs(instances) do
            if cancelled then break end
            if inst and inst.Parent then
                local t1 = AnimationEngine.FadeIn(inst, 1, info or Preset.Default)
                local t2 = AnimationEngine.SlideIn(inst, "Bottom", 12, info or Preset.Smooth)
                if t1 then table.insert(activeTweens, t1) end
                if t2 then table.insert(activeTweens, t2) end
            end
            task.wait(d)
        end
        if not cancelled and onComplete then
            task.spawn(onComplete)
        end
        table.clear(activeTweens)
    end)

    return function()
        cancelled = true
        for _, tween in ipairs(activeTweens) do
            pcall(function() tween:Cancel() end)
        end
        table.clear(activeTweens)
    end
end

return AnimationEngine
end

-- ── Core.InputAdapter ─────────────────────────────────────
_Delirium_modules["Core.InputAdapter"] = function()
-- Core/InputAdapter.lua
-- Detects device type, input mode, orientation, and safe area.
-- Provides BindAdaptiveInteraction for cross-platform interaction binding.
--
-- Owns its UserInputService connection via Maid — safe to Reset() between execs.
--
-- Signals (stable refs — never replaced across Reset()):
--   InputAdapter.InputModeChanged  → fires(newMode: string)
--   InputAdapter.OrientationChanged → fires(newOrientation: string)

local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
local Signal           = _Delirium_require("Utilities.Signal")
local Maid             = _Delirium_require("Core.Maid")
local DeviceDetector   = _Delirium_require("Utilities.DeviceDetector")

-- ─── Enums ───────────────────────────────────────────────────────────────────

local DeviceType = {
    Desktop = "Desktop",
    Tablet  = "Tablet",
    Phone   = "Phone",
    Console = "Console",
}

local InputMode = {
    Mouse    = "Mouse",
    Touch    = "Touch",
    Gamepad  = "Gamepad",
    Keyboard = "Keyboard",
}

-- ─── Internal helpers ─────────────────────────────────────────────────────────

-- Map DeviceDetector platform strings to InputAdapter DeviceType strings.
-- DeviceDetector is the single authoritative source for platform classification;
-- InputAdapter delegates here instead of duplicating UIS + viewport detection logic.
local _platformMap = {
    [DeviceDetector.Platform.Mobile]  = DeviceType.Phone,
    [DeviceDetector.Platform.Tablet]  = DeviceType.Tablet,
    [DeviceDetector.Platform.Desktop] = DeviceType.Desktop,
    [DeviceDetector.Platform.Console] = DeviceType.Console,
}

local function classifyDevice(): string
    return _platformMap[DeviceDetector:GetPlatform()] or DeviceType.Desktop
end

local function classifyInputMode(inputType: Enum.UserInputType): string
    local name = inputType.Name
    if name:find("Mouse")   then return InputMode.Mouse   end
    if name:find("Touch")   then return InputMode.Touch   end
    if name:find("Gamepad") then return InputMode.Gamepad end
    return InputMode.Keyboard
end

-- ─── State ────────────────────────────────────────────────────────────────────

local _maid = Maid.new()

local InputAdapter = {
    DeviceType    = DeviceType,
    InputModeEnum = InputMode,

    CurrentDevice      = classifyDevice(),
    CurrentInputMode   = classifyInputMode(UserInputService:GetLastInputType()),
    CurrentOrientation = "Landscape",

    IsDesktop = false,
    IsPhone   = false,
    IsTablet  = false,
    IsConsole = false,
    IsTouch   = false,

    -- Stable Signal refs — NEVER replaced across Reset().
    -- Other modules hold these; replacing them would leave stale refs.
    InputModeChanged   = Signal.new(),
    OrientationChanged = Signal.new(),
}

local function _updateFlags()
    local d = InputAdapter.CurrentDevice
    InputAdapter.IsDesktop = d == DeviceType.Desktop
    InputAdapter.IsPhone   = d == DeviceType.Phone
    InputAdapter.IsTablet  = d == DeviceType.Tablet
    InputAdapter.IsConsole = d == DeviceType.Console
    InputAdapter.IsTouch   = d == DeviceType.Phone or d == DeviceType.Tablet
end

_updateFlags()

-- ─── Internal: wire managed connections ──────────────────────────────────────

-- P2 fix: orientation tracking must follow workspace.CurrentCamera changes.
-- The old implementation bound ViewportSize to whatever camera existed at
-- module load; switching cameras left the old connection alive and the new
-- camera untracked. We now listen for CurrentCamera changes and rebind the
-- ViewportSize connection to the current camera. All camera connections are
-- owned by the same Maid, so Reset() tears them down together — repeated
-- Reset()/re-execution cannot stack duplicate camera listeners.
local function _wireCameraTracking()
    local cameraConn = nil  -- current camera's ViewportSize connection

    local function checkOrientation(camera)
        local vp  = camera.ViewportSize
        local ori = vp.X >= vp.Y and "Landscape" or "Portrait"
        if ori ~= InputAdapter.CurrentOrientation then
            InputAdapter.CurrentOrientation = ori
            InputAdapter.OrientationChanged:Fire(ori)
        end
    end

    -- Bind viewport tracking to `camera`, disconnecting any previous camera.
    local function bindCamera(camera)
        if cameraConn then
            cameraConn:Disconnect()
            cameraConn = nil
        end
        if not camera then return end
        cameraConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            checkOrientation(camera)
        end)
        -- Sync initial value
        local vp  = camera.ViewportSize
        InputAdapter.CurrentOrientation = vp.X >= vp.Y and "Landscape" or "Portrait"
    end

    -- Bind to the initial camera.
    bindCamera(workspace.CurrentCamera)

    -- Rebind whenever the camera object itself changes.
    _maid:GiveTask(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        bindCamera(workspace.CurrentCamera)
    end))

    -- Ensure the camera connection is cleaned up with the Maid.
    _maid:GiveTask(function()
        if cameraConn then
            cameraConn:Disconnect()
            cameraConn = nil
        end
    end)
end

local function _wireConnections()
    -- Input mode tracking
    _maid:GiveTask(
        UserInputService.LastInputTypeChanged:Connect(function(lastInputType)
            local newMode = classifyInputMode(lastInputType)
            if newMode ~= InputAdapter.CurrentInputMode then
                InputAdapter.CurrentInputMode = newMode
                InputAdapter.InputModeChanged:Fire(newMode)
            end
        end)
    )

    -- Device type sync: when DeviceDetector reclassifies the platform (viewport
    -- change, orientation flip, camera swap), update InputAdapter flags to match.
    -- Single source of truth: no duplicate UIS/viewport detection here.
    _maid:GiveTask(
        DeviceDetector.Changed:Connect(function(platform, _vp)
            local newDevice = _platformMap[platform] or DeviceType.Desktop
            if newDevice ~= InputAdapter.CurrentDevice then
                InputAdapter.CurrentDevice = newDevice
                _updateFlags()
            end
        end)
    )

    -- Orientation tracking via camera viewport changes (P2: rebinds on switch)
    _wireCameraTracking()
end

_wireConnections()

-- ─── Reset (called by Bootstrap between execs) ────────────────────────────────

function InputAdapter.Reset()
    -- Disconnect all managed connections
    _maid:DoCleaning()

    -- Clear signal handlers WITHOUT replacing the Signal objects.
    -- External modules hold these refs; destroying/replacing them leaves stale refs.
    InputAdapter.InputModeChanged:DisconnectAll()
    InputAdapter.OrientationChanged:DisconnectAll()

    -- Reinitialize state
    InputAdapter.CurrentDevice      = classifyDevice()
    InputAdapter.CurrentInputMode   = classifyInputMode(UserInputService:GetLastInputType())
    InputAdapter.CurrentOrientation = InputAdapter.GetOrientation()
    _updateFlags()

    -- Fresh Maid and reconnect
    _maid = Maid.new()
    _wireConnections()
    -- P2: clear pointer ownership so stale owners from a previous exec can't block new gestures.
    _pointerOwner = nil
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Returns "Landscape" or "Portrait" based on current viewport.
function InputAdapter.GetOrientation(): string
    local camera   = workspace.CurrentCamera
    local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
    return viewport.X >= viewport.Y and "Landscape" or "Portrait"
end

-- Returns safe area insets in pixels (accounts for Roblox topbar and notches).
function InputAdapter.GetSafeAreaInsets(): {Top: number, Bottom: number, Left: number, Right: number}
    local topLeft, bottomRight = GuiService:GetGuiInset()
    return {
        Top    = topLeft.Y,
        Bottom = bottomRight.Y,
        Left   = topLeft.X,
        Right  = bottomRight.X,
    }
end

--[[
    BindAdaptiveInteraction(guiObject, callbacks) → disconnect: () -> ()

    Binds adaptive callbacks based on the current device type.
    Returns a cleanup function — store it and call on component :Destroy().

    Callbacks (all optional):
        OnPress     — tap (touch) or left click (desktop)
        OnHover     — mouse enter (desktop only)
        OnHoverEnd  — mouse leave (desktop only)
        OnLongPress — hold (touch) or right click (desktop)
        OnScroll    — mouse wheel or touch scroll delta
]]
--[[
    BindAdaptiveInteraction(guiObject, callbacks) → disconnect: () -> ()

    Binds platform-appropriate callbacks. Evaluated at bind time from
    CurrentDevice; call again after a device switch for updated behavior.

    Callbacks (all optional):
        OnPress      — released tap (touch, no drag) or left click (desktop/gamepad)
        OnHover      — mouse enter (desktop only)
        OnHoverEnd   — mouse leave (desktop only)
        OnLongPress  — hold 0.5s (touch) or right-click (desktop)
        OnScroll     — mouse wheel Z delta (desktop) or touch scroll delta Y
]]
function InputAdapter.BindAdaptiveInteraction(guiObject: GuiObject, callbacks: table): () -> ()
    local localMaid = Maid.new()

    local function add(signal, fn)
        localMaid:GiveTask(signal:Connect(fn))
    end

    if InputAdapter.IsTouch then
        -- ── Touch ──────────────────────────────────────────────────────────
        local longThread    = nil
        local touchMoved    = false
        local LONG_DURATION = 0.5
        local MOVE_THRESH   = 8  -- pixels before we consider it a drag

        add(guiObject.InputBegan, function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            touchMoved = false

            -- Long-press timer starts on finger-down
            if callbacks.OnLongPress then
                longThread = task.delay(LONG_DURATION, function()
                    if not touchMoved then
                        task.spawn(callbacks.OnLongPress)
                    end
                    longThread = nil
                end)
            end
        end)

        add(guiObject.InputChanged, function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            if input.Delta.Magnitude > MOVE_THRESH then
                touchMoved = true
                if longThread then
                    pcall(task.cancel, longThread)
                    longThread = nil
                end
                -- Touch scroll delta
                if callbacks.OnScroll then
                    callbacks.OnScroll(-input.Delta.Y)
                end
            end
        end)

        add(guiObject.InputEnded, function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            if longThread then
                pcall(task.cancel, longThread)
                longThread = nil
            end
            -- Only fire OnPress if the finger didn't drag (tap, not scroll)
            if not touchMoved and callbacks.OnPress then
                task.spawn(callbacks.OnPress)
            end
        end)

    elseif InputAdapter.IsConsole then
        -- ── Gamepad ────────────────────────────────────────────────────────
        -- GuiObject activation via Gamepad A button fires MouseButton1Click
        -- on focused elements; MouseEnter/Leave fire on selection change.
        if callbacks.OnPress    then add(guiObject.MouseButton1Click, callbacks.OnPress)    end
        if callbacks.OnHover    then add(guiObject.MouseEnter,        callbacks.OnHover)    end
        if callbacks.OnHoverEnd then add(guiObject.MouseLeave,        callbacks.OnHoverEnd) end

    else
        -- ── Desktop / Mouse ────────────────────────────────────────────────
        if callbacks.OnHover     then add(guiObject.MouseEnter,        callbacks.OnHover)     end
        if callbacks.OnHoverEnd  then add(guiObject.MouseLeave,        callbacks.OnHoverEnd)  end
        if callbacks.OnPress     then add(guiObject.MouseButton1Click, callbacks.OnPress)     end
        if callbacks.OnLongPress then add(guiObject.MouseButton2Click, callbacks.OnLongPress) end

        if callbacks.OnScroll then
            add(guiObject.InputChanged, function(input)
                if input.UserInputType == Enum.UserInputType.MouseWheel then
                    callbacks.OnScroll(input.Position.Z)
                end
            end)
        end
    end

    return function()
        localMaid:DoCleaning()
    end
end

-- ─── P2: Centralized input constants ───────────────────────────────────────────
--
-- Single source of truth for drag deadzone thresholds and scroll classification.
-- Components and Window.lua reference these instead of defining their own.
--
-- Why separate values for mouse vs touch:
--   Mouse   — pixel-precise; 5px deadzone prevents jitter on click-without-drag.
--   Touch   — contact area is ~44px and position is imprecise; 8px gives a
--             comfortable deadzone before committing to a drag gesture.
-- GESTURE_THRESHOLD is larger than DRAG_THRESHOLD so ambiguous small movements
-- stay undecided long enough to classify scroll-vs-drag intent accurately.

InputAdapter.DRAG_THRESHOLD_MOUSE = 5    -- px: mouse minimum movement to start drag
InputAdapter.DRAG_THRESHOLD_TOUCH = 8    -- px: touch minimum movement to start drag
InputAdapter.GESTURE_THRESHOLD    = 10   -- px: minimum movement before scroll-vs-drag is classified
InputAdapter.SCROLL_DOMINANCE     = 1.4  -- dy must be >= dx * this to classify as scroll intent

-- ─── P2: Pointer utilities ────────────────────────────────────────────────────

-- GetPointerPosition(input) → Vector2
-- Returns the 2D screen position of a mouse or touch input, discarding the
-- Z component Roblox includes in input.Position (used for mouse wheel delta).
function InputAdapter.GetPointerPosition(input: InputObject): Vector2
    return Vector2.new(input.Position.X, input.Position.Y)
end

-- IsScrollIntent(delta) → boolean
-- Returns true when the movement delta has dominant vertical intent,
-- suggesting the user means to scroll rather than perform a horizontal drag.
-- delta: Vector2 — (currentPosition - startPosition) or InputChanged delta.
function InputAdapter.IsScrollIntent(delta: Vector2): boolean
    local ax = math.abs(delta.X)
    local ay = math.abs(delta.Y)
    return ay >= ax * InputAdapter.SCROLL_DOMINANCE
end

-- ─── P2: Pointer ownership ────────────────────────────────────────────────────
--
-- Lightweight cooperative ownership model for pointer/touch gestures.
-- Any system that begins a pointer interaction can claim ownership;
-- other systems check ClaimPointer before stealing the gesture.
--
-- Ownership is ADVISORY — components are not forced to yield, but
-- well-behaved consumers should respect ClaimPointer's return value.
-- Per-component enforcement wires into this in P3.

local _pointerOwner = nil  -- any comparable value: string tag or object reference

-- Claim the active pointer for `owner`.
-- Returns true  → claim succeeded (no prior owner, or owner is self).
-- Returns false → another system already owns the pointer.
function InputAdapter.ClaimPointer(owner): boolean
    if _pointerOwner == nil or _pointerOwner == owner then
        _pointerOwner = owner
        return true
    end
    return false
end

-- Release the pointer. Silent no-op if `owner` is not the current owner.
function InputAdapter.ReleasePointer(owner)
    if _pointerOwner == owner then
        _pointerOwner = nil
    end
end

-- Force-release regardless of current owner. Used during cleanup / window destroy.
function InputAdapter.ForceReleasePointer()
    _pointerOwner = nil
end

-- Returns the current owner, or nil if unclaimed.
function InputAdapter.GetPointerOwner()
    return _pointerOwner
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("InputAdapter", {
    Reset = InputAdapter.Reset,
}, 5)  -- priority 5 — resets first (other services may use InputAdapter)

return InputAdapter

end

-- ── Core.Maid ─────────────────────────────────────────────
_Delirium_modules["Core.Maid"] = function()
-- Core/Maid.lua
-- Centralized resource cleanup manager.
--
-- Supports:
--   RBXScriptConnection  → :Disconnect()
--   Instance             → :Destroy()
--   function             → called directly
--   table with :Destroy()
--   table with :Disconnect()
--
-- Usage:
--   local maid = Maid.new()
--   maid:GiveTask(connection)
--   maid:GiveTask(instance)
--   maid:GiveTask(function() ... end)
--   maid:DoCleaning()   -- safe, isolated, idempotent

local Maid = {}
Maid.__index = Maid

function Maid.new()
    return setmetatable({ _tasks = {}, _cleaned = false }, Maid)
end

-- Add a resource to be cleaned up.
-- Safe to call after DoCleaning — resource is cleaned immediately.
function Maid:GiveTask(task)
    if task == nil then return end
    if self._cleaned then
        -- Already destroyed — clean immediately rather than accumulate
        Maid._cleanTask(task)
        return
    end
    table.insert(self._tasks, task)
end

-- Clean a single task in isolation.
-- Never throws — errors are swallowed so other tasks keep cleaning.
function Maid._cleanTask(task)
    local ok, err = pcall(function()
        local t = type(task)
        if t == "function" then
            task()
        elseif t == "table" or t == "userdata" then
            if typeof(task) == "RBXScriptConnection" then
                task:Disconnect()
            elseif task.Destroy then
                task:Destroy()
            elseif task.Disconnect then
                task:Disconnect()
            end
        end
    end)
    if not ok then
        -- Swallowed — caller may log if diagnostics are enabled
        warn("[Maid] cleanup error: " .. tostring(err))
    end
end

-- Clean all registered tasks in LIFO order.
-- Safe to call multiple times — subsequent calls are no-ops.
function Maid:DoCleaning()
    if self._cleaned then return end
    self._cleaned = true

    -- Reverse order: last registered, first cleaned (LIFO — children before parents)
    for i = #self._tasks, 1, -1 do
        Maid._cleanTask(self._tasks[i])
        self._tasks[i] = nil
    end
    table.clear(self._tasks)
end

-- Alias
Maid.Destroy = Maid.DoCleaning

-- Schedule fn to run after `seconds`. The pending thread is registered with the
-- Maid so DoCleaning() cancels it before it fires — prevents callbacks running
-- on components that have already been destroyed.
-- If the Maid has already been cleaned, GiveTask() immediately invokes the
-- cancel closure, which is a safe no-op because thread is assigned before GiveTask.
function Maid:Delay(seconds: number, fn: () -> ())
    local thread
    thread = task.delay(seconds, fn)
    self:GiveTask(function()
        pcall(task.cancel, thread)
    end)
end

return Maid

end

-- ── Core.Runtime ──────────────────────────────────────────
_Delirium_modules["Core.Runtime"] = function()
-- Core/Runtime.lua
-- Represents one active Delirium execution session.
--
-- Owns: services, windows, global resources.
-- Stored in _G[SESSION_KEY] so the next exec can detect and destroy it.
--
-- Usage (internal — called by Init.lua):
--   local runtime = Runtime.new()
--   runtime:IsAlive()
--   runtime:IsCurrent(sessionId)
--   runtime:Destroy()

local Maid = _Delirium_require("Core.Maid")

-- ─── ID generation ────────────────────────────────────────────────────────────

local function _generateId(): string
    return string.format("DLR_%x_%x", os.clock() * 1e6 // 1, math.random(0, 0xFFFF))
end

-- ─── Runtime ──────────────────────────────────────────────────────────────────

local Runtime = {}
Runtime.__index = Runtime

function Runtime.new()
    local self = setmetatable({}, Runtime)

    self.SessionId  = _generateId()
    self._alive     = true
    self._maid      = Maid.new()

    -- Registered service objects (expose :Destroy())
    -- Keyed by name to prevent duplicates.
    self._services  = {}  -- { [name] = serviceObject }

    -- Owned windows
    self._windows   = {}

    return self
end

-- ── Query ──────────────────────────────────────────────────────────────────

function Runtime:IsAlive(): boolean
    return self._alive
end

-- Async stale-callback guard.
-- Usage: if not runtime:IsCurrent(capturedId) then return end
function Runtime:IsCurrent(sessionId: string): boolean
    return self._alive and self.SessionId == sessionId
end

-- ── Service management ────────────────────────────────────────────────────

-- Register a service by name.
-- If a service with the same name already exists, it is destroyed first.
-- service must expose :Destroy() or be a plain cleanup function.
function Runtime:RegisterService(name: string, service)
    assert(type(name) == "string" and #name > 0,
        "Runtime:RegisterService — name must be a non-empty string")

    local existing = self._services[name]
    if existing then
        -- Replace: destroy old registration before accepting new one
        pcall(function()
            if type(existing) == "function" then
                existing()
            elseif existing.Destroy then
                existing:Destroy()
            end
        end)
    end

    self._services[name] = service
end

function Runtime:GetService(name: string)
    return self._services[name]
end

-- ── Window management ─────────────────────────────────────────────────────

function Runtime:RegisterWindow(window)
    window._runtime = self
    table.insert(self._windows, window)
end

-- Remove a single window from the registry (called by Window:Destroy).
-- Prevents double-destroy when UnloadService cascades Runtime:Destroy().
function Runtime:UnregisterWindow(window)
    for i, w in ipairs(self._windows) do
        if w == window then
            table.remove(self._windows, i)
            break
        end
    end
end

-- ── Resource management ───────────────────────────────────────────────────

-- Give any resource to the runtime's own Maid.
function Runtime:OwnResource(task)
    self._maid:GiveTask(task)
end

-- ── Destruction ───────────────────────────────────────────────────────────

function Runtime:Destroy()
    if not self._alive then return end  -- idempotent
    self._alive = false

    -- 1. Destroy windows (cascade: Window → Tab → Section → Component)
    -- Snapshot first: Window:Destroy() unregisters itself from self._windows,
    -- which would otherwise shift entries and make ipairs skip windows.
    local windows = { table.unpack(self._windows) }
    for _, win in ipairs(windows) do
        pcall(function() win:Destroy() end)
    end
    table.clear(self._windows)

    -- 2. Destroy services
    for name, service in pairs(self._services) do
        pcall(function()
            if type(service) == "function" then
                service()
            elseif service.Destroy then
                service:Destroy()
            end
        end)
        self._services[name] = nil
    end

    -- 3. Clean runtime-owned resources
    self._maid:DoCleaning()
end

return Runtime

end

-- ── Core.ServiceRegistry ──────────────────────────────────
_Delirium_modules["Core.ServiceRegistry"] = function()
-- Core/ServiceRegistry.lua
-- Lifecycle registry for Delirium services.
--
-- Services self-register at require() time.
-- Bootstrap calls ResetAll() / InitAll(gui) — never needs to know service names.
-- Duplicate names are rejected: re-registering the same name replaces the old entry
-- after safely destroying it.
--
-- Adding a new service:
--   1. Write Reset() and/or Init(gui) on your service module.
--   2. At the bottom of the file: ServiceRegistry.Register("Name", hooks, priority)
--   Done. Bootstrap picks it up automatically.

local _registry = {}      -- ordered array: { name, hooks, priority }
local _byName   = {}      -- name → index in _registry (for duplicate detection)

local ServiceRegistry = {}

-- Register a service.
--
-- name     : string   — unique identifier; duplicate names replace the old entry.
-- hooks    : table    — { Reset?: () -> (), Init?: (gui: ScreenGui) -> () }
-- priority : number?  — lower = runs first in ResetAll/InitAll (default 50)
function ServiceRegistry.Register(name: string, hooks: table, priority: number?)
    assert(type(name)  == "string" and #name > 0,
        "ServiceRegistry.Register: name must be a non-empty string")
    assert(type(hooks) == "table",
        "ServiceRegistry.Register: hooks must be a table")

    -- Duplicate prevention: destroy old entry before replacing
    local existingIdx = _byName[name]
    if existingIdx then
        local old = _registry[existingIdx]
        if old and type(old.hooks.Reset) == "function" then
            pcall(old.hooks.Reset)
        end
        table.remove(_registry, existingIdx)
        -- Rebuild name→index map after removal
        _byName = {}
        for i, entry in ipairs(_registry) do
            _byName[entry.name] = i
        end
    end

    local entry = {
        name     = name,
        hooks    = hooks,
        priority = priority or 50,
    }
    table.insert(_registry, entry)
    table.sort(_registry, function(a, b) return a.priority < b.priority end)

    -- Rebuild map after sort
    _byName = {}
    for i, e in ipairs(_registry) do
        _byName[e.name] = i
    end
end

-- Reset all registered services in priority order.
-- Called by Bootstrap before creating a new session.
function ServiceRegistry.ResetAll()
    for _, entry in ipairs(_registry) do
        if type(entry.hooks.Reset) == "function" then
            local ok, err = pcall(entry.hooks.Reset)
            if not ok then
                warn(string.format("[ServiceRegistry] Error resetting service '%s': %s", tostring(entry.name), tostring(err)))
            end
        end
    end
end

-- Initialize all registered services that have an Init hook.
-- Called by Bootstrap after the new ScreenGui is live.
function ServiceRegistry.InitAll(gui: ScreenGui)
    for _, entry in ipairs(_registry) do
        if type(entry.hooks.Init) == "function" then
            local ok, err = pcall(entry.hooks.Init, gui)
            if not ok then
                warn(string.format("[ServiceRegistry] Error initializing service '%s': %s", tostring(entry.name), tostring(err)))
            end
        end
    end
end

-- List registered services (debug).
function ServiceRegistry.List(): {string}
    local out = {}
    for _, entry in ipairs(_registry) do
        table.insert(out, string.format("[%d] %s", entry.priority, entry.name))
    end
    return out
end

return ServiceRegistry

end

-- ── Core.ThemeEngine ──────────────────────────────────────
_Delirium_modules["Core.ThemeEngine"] = function()
-- Core/ThemeEngine.lua
-- Centralized visual token system with runtime theme switching.
-- OnThemeChanged() returns a disconnect function — call it on component :Destroy()
-- to prevent memory leaks.

local THEMES = {
    Dark = {
        -- Base surfaces
        Background    = Color3.fromRGB(15, 15, 20),
        Surface       = Color3.fromRGB(24, 24, 32),
        SurfaceHover  = Color3.fromRGB(30, 30, 42),
        SurfaceActive = Color3.fromRGB(36, 36, 52),
        Border        = Color3.fromRGB(45, 45, 60),

        -- Text hierarchy
        Text         = Color3.fromRGB(235, 235, 250),
        SubText      = Color3.fromRGB(120, 120, 148),
        DisabledText = Color3.fromRGB(65, 65, 85),

        -- Accent / brand
        Accent     = Color3.fromRGB(120, 95, 230),
        AccentDim  = Color3.fromRGB(78, 58, 165),
        AccentText = Color3.fromRGB(255, 255, 255),

        -- Status colors
        Positive = Color3.fromRGB(55, 200, 100),
        Warning  = Color3.fromRGB(240, 185, 55),
        Error    = Color3.fromRGB(220, 65, 65),

        -- Component-specific tokens
        InputBackground = Color3.fromRGB(18, 18, 26),
        ToggleOff       = Color3.fromRGB(45, 45, 60),
        SliderTrack     = Color3.fromRGB(40, 40, 55),
        ScrollBar       = Color3.fromRGB(55, 55, 75),

        -- Layering / overlay tokens
        CardBackground    = Color3.fromRGB(28, 28, 38),
        TooltipBackground = Color3.fromRGB(30, 30, 44),
        Overlay           = Color3.fromRGB(0,  0,  0),   -- used with BackgroundTransparency ~0.5
    },

    Light = {
        Background    = Color3.fromRGB(245, 245, 250),
        Surface       = Color3.fromRGB(255, 255, 255),
        SurfaceHover  = Color3.fromRGB(238, 238, 248),
        SurfaceActive = Color3.fromRGB(228, 228, 242),
        Border        = Color3.fromRGB(200, 200, 215),

        Text         = Color3.fromRGB(20, 20, 30),
        SubText      = Color3.fromRGB(100, 100, 120),
        DisabledText = Color3.fromRGB(160, 160, 175),

        Accent     = Color3.fromRGB(100, 75, 210),
        AccentDim  = Color3.fromRGB(68,  50, 155),   -- darker/muted, not lighter
        AccentText = Color3.fromRGB(255, 255, 255),

        Positive = Color3.fromRGB(28, 160, 68),
        Warning  = Color3.fromRGB(195, 130, 18),
        Error    = Color3.fromRGB(190, 45, 45),

        InputBackground = Color3.fromRGB(232, 232, 242),
        ToggleOff       = Color3.fromRGB(195, 195, 212),
        SliderTrack     = Color3.fromRGB(195, 195, 212),
        ScrollBar       = Color3.fromRGB(180, 180, 200),

        -- Layering / overlay tokens
        CardBackground    = Color3.fromRGB(248, 248, 253),
        TooltipBackground = Color3.fromRGB(30,  30,  44),  -- intentionally dark; tooltips stay dark
        Overlay           = Color3.fromRGB(0,   0,   0),
    },
}

local ThemeEngine = {
    _currentTheme    = "Dark",
    _listeners       = {},
    _nextListenerId  = 0,
}

-- ─── Core API ─────────────────────────────────────────────────────────────────

-- Get a single color token for the current theme.
-- On missing token: falls back to Dark theme, then emits a warning and returns a
-- hot-pink sentinel (visible in dev) rather than crashing the entire frame.
local function _isLightColor(c: Color3): boolean
    local l = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
    return l > 0.5
end

-- Get a single color token for the current theme.
function ThemeEngine.GetToken(tokenName: string): Color3
    local theme = THEMES[ThemeEngine._currentTheme]
    assert(theme, "ThemeEngine: unknown theme — " .. tostring(ThemeEngine._currentTheme))
    local token = theme[tokenName]
    if token ~= nil then return token end

    -- Intelligent dynamic token fallback
    local surface = theme.Surface or THEMES.Dark.Surface
    local isLight = _isLightColor(surface)

    if tokenName == "SurfaceHover" then
        return isLight
            and Color3.new(math.max(0, surface.R - 0.05), math.max(0, surface.G - 0.05), math.max(0, surface.B - 0.05))
            or  Color3.new(math.min(1, surface.R + 0.05), math.min(1, surface.G + 0.05), math.min(1, surface.B + 0.05))
    elseif tokenName == "SurfaceActive" then
        return isLight
            and Color3.new(math.max(0, surface.R - 0.09), math.max(0, surface.G - 0.09), math.max(0, surface.B - 0.09))
            or  Color3.new(math.min(1, surface.R + 0.09), math.min(1, surface.G + 0.09), math.min(1, surface.B + 0.09))
    elseif tokenName == "CardBackground" then
        return surface
    elseif tokenName == "InputBackground" then
        return isLight
            and Color3.new(math.max(0, surface.R - 0.07), math.max(0, surface.G - 0.07), math.max(0, surface.B - 0.07))
            or  Color3.new(math.max(0, surface.R - 0.04), math.max(0, surface.G - 0.04), math.max(0, surface.B - 0.04))
    elseif tokenName == "ToggleOff" or tokenName == "SliderTrack" or tokenName == "ScrollBar" then
        return theme.Border or THEMES.Dark.Border
    elseif tokenName == "AccentText" then
        local accent = theme.Accent or THEMES.Dark.Accent
        return _isLightColor(accent) and Color3.fromRGB(20, 20, 30) or Color3.fromRGB(255, 255, 255)
    elseif tokenName == "DisabledText" then
        return theme.SubText or THEMES.Dark.SubText
    end

    token = THEMES.Dark[tokenName]
    if token == nil then
        warn(string.format("ThemeEngine: token '%s' not found in '%s' or Dark fallback", tostring(tokenName), ThemeEngine._currentTheme))
        return Color3.fromRGB(255, 0, 200)
    end
    return token
end

-- Get the current theme name.
function ThemeEngine.GetTheme(): string
    return ThemeEngine._currentTheme
end

-- Get all tokens for the current theme (useful for bulk reads).
function ThemeEngine.GetTokens(): table
    local proxy = setmetatable({}, {
        __index = function(_, key)
            return ThemeEngine.GetToken(key)
        end
    })
    return proxy
end

-- Switch the active theme and notify all listeners.
function ThemeEngine.SetTheme(themeName: string)
    assert(THEMES[themeName], "ThemeEngine: theme '" .. tostring(themeName) .. "' does not exist")
    ThemeEngine._currentTheme = themeName

    -- Wrap in proxy so any token access automatically resolves via ThemeEngine.GetToken
    local tokensProxy = setmetatable({}, {
        __index = function(_, key)
            return ThemeEngine.GetToken(key)
        end
    })

    for id, listener in pairs(ThemeEngine._listeners) do
        task.spawn(function()
            local ok, err = pcall(listener, tokensProxy)
            if not ok then
                warn(string.format(
                    "ThemeEngine: listener [%d] errored during SetTheme('%s') — %s",
                    id, themeName, tostring(err)
                ))
            end
        end)
    end
end

-- Register a listener for theme changes.
function ThemeEngine.OnThemeChanged(callback: (tokens: table) -> ()): () -> ()
    assert(type(callback) == "function", "ThemeEngine.OnThemeChanged expects a function")
    ThemeEngine._nextListenerId += 1
    local id = ThemeEngine._nextListenerId
    ThemeEngine._listeners[id] = callback
    return function()
        ThemeEngine._listeners[id] = nil
    end
end

-- ─── Extension API ────────────────────────────────────────────────────────────

-- Register a custom theme. Tokens not provided fall back dynamically via ThemeEngine.GetToken.
function ThemeEngine.RegisterTheme(name: string, tokens: table)
    assert(type(name) == "string" and #name > 0, "RegisterTheme: name must be a non-empty string")
    assert(type(tokens) == "table", "RegisterTheme: tokens must be a table")

    local built = {}
    for key, val in pairs(tokens) do
        built[key] = val
    end
    THEMES[name] = built
end

-- List all registered theme names.
function ThemeEngine.GetThemeNames(): {string}
    local names = {}
    for name in pairs(THEMES) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Clear all registered theme listeners — called by Bootstrap on session teardown.
-- Prevents stale callbacks from destroyed components accumulating across execs.
function ThemeEngine.ClearListeners()
    table.clear(ThemeEngine._listeners)
    ThemeEngine._nextListenerId = 0
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("ThemeEngine", {
    Reset = ThemeEngine.ClearListeners,
    -- No Init: ThemeEngine does not need the ScreenGui
}, 10)  -- priority 10 — resets before services that depend on theme tokens

return ThemeEngine

end

-- ── Core.VariantEngine ────────────────────────────────────
_Delirium_modules["Core.VariantEngine"] = function()
-- Core/VariantEngine.lua
-- Centralized visual variant system for Delirium components.
--
-- Design contract:
--   • Resolve()           → shallow copy of layout/sizing props for (componentType, variant).
--   • ResolveWithTheme()  → Resolve() merged with optional theme-derived props from a
--                           registered ThemeResolver. Use this when a variant needs to
--                           produce theme-dependent values (e.g. a future 'Danger' variant
--                           that pulls from tokens.Error). Components that don't need theme
--                           overrides continue using Resolve() unchanged — zero cost.
--   • RegisterVariant()   → extend the variant table at runtime without editing this file.
--   • HasComponent() / HasVariant() → cheap pre-validation for callers.
--   • RegisterVariantThemeResolver() → attach a (tokens) -> props function to any variant;
--                                      called lazily by ResolveWithTheme().
--
-- Immutability contract: every Resolve / ResolveWithTheme call returns a fresh shallow
-- copy so components cannot accidentally mutate global definitions.
--
-- Lifecycle: Reset() clears custom registrations and theme resolvers so repeated
-- executions start clean. Built-in VARIANTS are never wiped.

-- ─── Luau type exports ───────────────────────────────────────────────────────
-- These are used for documentation and strict-mode tooling.
-- They are not enforced at runtime in executor environments.

export type VariantProps       = {[string]: any}          -- layout/sizing/flag values
export type VariantMap         = {[string]: VariantProps}  -- variantName → props
export type ComponentVariantMap= {[string]: VariantMap}   -- componentType → variants
export type ThemeResolverFn    = (tokens: {[string]: Color3}) -> VariantProps

-- ─── Engine state ─────────────────────────────────────────────────────────────

local VariantEngine = {}

-- Built-in variant definitions.  Never cleared by Reset().
local VARIANTS: ComponentVariantMap = {
    Button = {
        Default = {
            Height     = 40,
            HeightDesc = 48,
            Corner     = 8,
            PadTop     = 6,
            PadBot     = 6,
            PadL       = 12,
            PadR       = 12,
        },
        Compact = {
            Height     = 32,
            HeightDesc = 40,
            Corner     = 6,
            PadTop     = 4,
            PadBot     = 4,
            PadL       = 10,
            PadR       = 10,
        },
        Large = {
            Height     = 48,
            HeightDesc = 56,
            Corner     = 10,
            PadTop     = 8,
            PadBot     = 8,
            PadL       = 14,
            PadR       = 14,
        },
    },

    Toggle = {
        Default = {
            Height     = 40,
            HeightDesc = 48,
            Corner     = 8,
            PadTop     = 6,
            PadBot     = 6,
            PadL       = 12,
            PadR       = 12,
            TrackW     = 38,
            TrackH     = 20,
            KnobSize   = 14,
        },
        Compact = {
            Height     = 32,
            HeightDesc = 40,
            Corner     = 6,
            PadTop     = 4,
            PadBot     = 4,
            PadL       = 10,
            PadR       = 10,
            TrackW     = 32,
            TrackH     = 16,
            KnobSize   = 10,
        },
        Large = {
            Height     = 48,
            HeightDesc = 56,
            Corner     = 10,
            PadTop     = 8,
            PadBot     = 8,
            PadL       = 14,
            PadR       = 14,
            TrackW     = 44,
            TrackH     = 24,
            KnobSize   = 18,
        },
    },

    Slider = {
        Default = {
            Height = 50,
            Corner = 8,
            PadTop = 8,
            PadBot = 8,
            PadL   = 12,
            PadR   = 12,
            TrackH = 6,
        },
        Compact = {
            Height = 42,
            Corner = 6,
            PadTop = 6,
            PadBot = 6,
            PadL   = 10,
            PadR   = 10,
            TrackH = 4,
        },
        Large = {
            Height = 58,
            Corner = 10,
            PadTop = 10,
            PadBot = 10,
            PadL   = 14,
            PadR   = 14,
            TrackH = 8,
        },
    },

    Dropdown = {
        Default = {
            RowH          = 42,
            Corner        = 8,
            TriggerH      = 30,
            TriggerWScale = 0.42,
            OptionItemH   = 28,
        },
        Compact = {
            RowH          = 34,
            Corner        = 6,
            TriggerH      = 24,
            TriggerWScale = 0.42,
            OptionItemH   = 24,
        },
        Large = {
            RowH          = 50,
            Corner        = 10,
            TriggerH      = 36,
            TriggerWScale = 0.42,
            OptionItemH   = 32,
        },
    },

    TextBox = {
        Default = {
            RowH        = 42,
            Corner      = 8,
            InputH      = 30,
            InputWScale = 0.45,
        },
        Compact = {
            RowH        = 34,
            Corner      = 6,
            InputH      = 24,
            InputWScale = 0.45,
        },
        Large = {
            RowH        = 50,
            Corner      = 10,
            InputH      = 36,
            InputWScale = 0.45,
        },
    },

    Keybind = {
        Default = {
            RowH     = 42,
            Corner   = 8,
            BindBtnH = 28,
            BindBtnW = 75,
        },
        Compact = {
            RowH     = 34,
            Corner   = 6,
            BindBtnH = 24,
            BindBtnW = 65,
        },
        Large = {
            RowH     = 50,
            Corner   = 10,
            BindBtnH = 34,
            BindBtnW = 85,
        },
    },

    ColorPicker = {
        Default = {
            RowH    = 42,
            Corner  = 8,
            SwatchW = 32,
            SwatchH = 24,
        },
        Compact = {
            RowH    = 34,
            Corner  = 6,
            SwatchW = 28,
            SwatchH = 20,
        },
        Large = {
            RowH    = 50,
            Corner  = 10,
            SwatchW = 36,
            SwatchH = 28,
        },
    },
}

-- Custom variants registered at runtime via RegisterVariant().
-- Separate from VARIANTS so Reset() can wipe custom entries without touching builtins.
-- Key format: "ComponentType:VariantName"
local _customKeys: {[string]: boolean} = {}

-- Theme resolver functions: _THEME_RESOLVERS[componentType][variantName] = fn(tokens)->props
-- Merged on top of Resolve() output by ResolveWithTheme(). Cleared by Reset().
local _THEME_RESOLVERS: {[string]: {[string]: ThemeResolverFn}} = {}

-- ─── Internal helpers ─────────────────────────────────────────────────────────────

local function shallowCopy(tbl: VariantProps): VariantProps
    local copy: VariantProps = {}
    for k, v in pairs(tbl) do
        copy[k] = v
    end
    return copy
end

local function _resolveDef(componentType: string, variantName: string?): VariantProps?
    local compDef = VARIANTS[componentType]
    if not compDef then return nil end

    if variantName == nil or variantName == "" or variantName == "Default" then
        return compDef.Default
    end

    return compDef[variantName] or nil
end

-- ─── Core resolution API ───────────────────────────────────────────────────────────

-- Resolve layout/sizing props for a component variant.
-- • variantName = nil / "" / "Default" → returns Default props.
-- • Unknown variantName → warns + returns Default (never crashes).
-- • Unknown componentType → warns + returns {}.
-- Returns a shallow copy so mutations are local to the caller.
function VariantEngine.Resolve(componentType: string, variantName: string?): VariantProps
    local compDef = VARIANTS[componentType]
    if not compDef then
        warn("[Delirium VariantEngine] Unknown component type: " .. tostring(componentType))
        return {}
    end

    local normalised = (variantName == nil or variantName == "") and "Default" or variantName

    local style = compDef[normalised]
    if not style then
        warn(string.format(
            "[Delirium VariantEngine] Unknown variant '%s' for '%s'; falling back to Default",
            tostring(variantName), componentType
        ))
        style = compDef.Default
    end

    return shallowCopy(style)
end

-- Resolve layout props AND merge any registered theme-derived props on top.
-- • Identical to Resolve() when no ThemeResolver is registered for this variant.
-- • Requires ThemeEngine to be accessible; when tokens cannot be fetched (e.g.
--   ThemeEngine not yet loaded) falls back gracefully to Resolve()-only output.
-- Components that never need theme overrides should continue using Resolve().
function VariantEngine.ResolveWithTheme(componentType: string, variantName: string?): VariantProps
    local base = VariantEngine.Resolve(componentType, variantName)

    local compResolvers = _THEME_RESOLVERS[componentType]
    if not compResolvers then return base end

    local normalised = (variantName == nil or variantName == "") and "Default" or variantName
    local resolverFn = compResolvers[normalised]
    if not resolverFn then return base end

    -- Attempt to fetch current theme tokens; fail gracefully if ThemeEngine unavailable.
    local ok, tokens = pcall(function()
        local ThemeEngine = _Delirium_require("Core.ThemeEngine")
        return ThemeEngine.GetTokens()
    end)

    if not ok or not tokens then return base end

    -- Merge theme-derived props onto the base copy (theme props win on key collision).
    local okMerge, extraProps = pcall(resolverFn, tokens)
    if not okMerge or type(extraProps) ~= "table" then
        warn(string.format(
            "[Delirium VariantEngine] ThemeResolver for '%s/%s' errored: %s",
            componentType, tostring(variantName), tostring(extraProps)
        ))
        return base
    end

    for k, v in pairs(extraProps) do
        base[k] = v
    end
    return base
end

-- ─── Query API ──────────────────────────────────────────────────────────────────

-- Returns true when the component type has any registered variants (built-in or custom).
function VariantEngine.HasComponent(componentType: string): boolean
    return VARIANTS[componentType] ~= nil
end

-- Returns true when the specific variant exists for the component type.
-- "Default" always returns true for any registered component type.
function VariantEngine.HasVariant(componentType: string, variantName: string): boolean
    local compDef = VARIANTS[componentType]
    if not compDef then return false end
    return compDef[variantName] ~= nil
end

-- Returns a sorted list of known variant names for a component type.
function VariantEngine.GetVariantNames(componentType: string): {string}
    local compDef = VARIANTS[componentType]
    if not compDef then return {} end

    local names: {string} = {}
    for name in pairs(compDef) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- Returns a sorted list of all registered component type names.
function VariantEngine.GetComponentNames(): {string}
    local names: {string} = {}
    for name in pairs(VARIANTS) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- ─── Extension API ────────────────────────────────────────────────────────────────

-- Register a custom variant (or override an existing one) at runtime.
-- • componentType must already exist (cannot create new component types here).
-- • variantName "Default" may be overridden if explicitly intended.
-- • props must be a non-empty table.
-- Custom variants are tracked separately so Reset() can clear them without
-- touching built-in definitions.
function VariantEngine.RegisterVariant(
    componentType: string,
    variantName: string,
    props: VariantProps
)
    assert(type(componentType) == "string" and #componentType > 0,
        "[VariantEngine.RegisterVariant] componentType must be a non-empty string")
    assert(type(variantName) == "string" and #variantName > 0,
        "[VariantEngine.RegisterVariant] variantName must be a non-empty string")
    assert(type(props) == "table",
        "[VariantEngine.RegisterVariant] props must be a table")

    if not VARIANTS[componentType] then
        warn(string.format(
            "[Delirium VariantEngine] RegisterVariant: unknown component type '%s'",
            componentType
        ))
        return
    end

    VARIANTS[componentType][variantName] = shallowCopy(props)
    _customKeys[componentType .. ":" .. variantName] = true
end

-- Attach a theme-resolver function to a variant.
-- fn(tokens) is called by ResolveWithTheme() and its return table is merged
-- onto the base variant props. Useful for variants that need to produce
-- theme-dependent values (colors, derived sizes) without hardcoding them.
-- • componentType and variantName must exist at registration time.
-- • fn must be a function; bad fn errors are caught at resolve-time, not here.
-- Theme resolvers are cleared by Reset() (same lifecycle as custom variants).
function VariantEngine.RegisterVariantThemeResolver(
    componentType: string,
    variantName: string,
    fn: ThemeResolverFn
)
    assert(type(componentType) == "string" and #componentType > 0,
        "[VariantEngine.RegisterVariantThemeResolver] componentType must be non-empty string")
    assert(type(variantName) == "string" and #variantName > 0,
        "[VariantEngine.RegisterVariantThemeResolver] variantName must be non-empty string")
    assert(type(fn) == "function",
        "[VariantEngine.RegisterVariantThemeResolver] fn must be a function")

    if not VariantEngine.HasComponent(componentType) then
        warn(string.format(
            "[Delirium VariantEngine] RegisterVariantThemeResolver: unknown component type '%s'",
            componentType
        ))
        return
    end

    if not _THEME_RESOLVERS[componentType] then
        _THEME_RESOLVERS[componentType] = {}
    end
    _THEME_RESOLVERS[componentType][variantName] = fn
end

-- ─── Lifecycle ────────────────────────────────────────────────────────────────────

-- Remove all custom-registered variants and all theme resolvers.
-- Built-in VARIANTS entries are never touched.
-- Called by ServiceRegistry on session teardown / re-execution.
local function Reset()
    -- Remove custom variant entries from VARIANTS
    for key in pairs(_customKeys) do
        local sep = string.find(key, ":", 1, true)
        if sep then
            local compType   = string.sub(key, 1, sep - 1)
            local varName    = string.sub(key, sep + 1)
            if VARIANTS[compType] then
                VARIANTS[compType][varName] = nil
            end
        end
    end
    table.clear(_customKeys)

    -- Clear all theme resolvers
    table.clear(_THEME_RESOLVERS)
end

-- ─── Self-register ────────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("VariantEngine", {
    Reset = Reset,
    -- No Init: VariantEngine does not need the ScreenGui.
}, 9)  -- priority 9 — resets just before ThemeEngine (10) so ThemeEngine listeners
       -- don't fire against stale resolvers during the same teardown cycle.

return VariantEngine

end

-- ── Layout.Section ────────────────────────────────────────
_Delirium_modules["Layout.Section"] = function()
-- Layout/Section.lua
-- Owns its component handles. Cascade: Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.
--
-- Collapse gesture model (M2 fix):
--   Touch begin on header  → store InputObject ref, record start position, mark PENDING
--   Touch move             → tracked via UserInputService.InputChanged (global, not HeaderLabel)
--                            if delta > TAP_MOVE_THRESHOLD → mark DRAG, cancel toggle intent
--   Touch end              → tracked via UserInputService.InputEnded (global)
--                            if NOT drag → fire ToggleCollapsed (confirmed tap)
--
-- WHY global listeners instead of HeaderLabel.InputChanged / InputEnded:
--   Roblox's ScrollingFrame (PageCanvas) consumes InputChanged events once it
--   detects a scroll gesture. HeaderLabel stops seeing movement events, so
--   _tapDragged never gets set to true. When the finger lifts, InputEnded fires
--   ToggleCollapsed incorrectly. UserInputService signals cannot be suppressed
--   by the ScrollingFrame. We filter to our specific touch using the InputObject
--   reference — Roblox reuses the same InputObject instance across all Changed
--   events for a given finger, so reference equality is a reliable filter.
--
-- First-collapse animation fix (M8):
--   Problem: on first collapse, AutomaticSize=Y was still active so Frame.AbsoluteSize.Y
--   was unreliable (0 or stale). Tween started from undefined geometry → visible jump.
--   Fix: snapshot AbsoluteSize AFTER disabling AutomaticSize and explicitly locking Size
--   to the current AbsoluteSize first. This guarantees the tween always starts from the
--   correct measured height regardless of layout pass timing.

local UserInputService = game:GetService("UserInputService")
-- local Root            = script.Parent.Parent
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local Maid            = _Delirium_require("Core.Maid")

local Button        = _Delirium_require("Components.Button")
local Toggle        = _Delirium_require("Components.Toggle")
local Slider        = _Delirium_require("Components.Slider")
local TextBox       = _Delirium_require("Components.TextBox")
local Dropdown      = _Delirium_require("Components.Dropdown")
local Keybind       = _Delirium_require("Components.Keybind")
local ColorPicker   = _Delirium_require("Components.ColorPicker")
local Label         = _Delirium_require("Components.Label")
local Paragraph     = _Delirium_require("Components.Paragraph")
local Divider       = _Delirium_require("Components.Divider")
local UnloadService = _Delirium_require("Services.UnloadService")

local Section = {}
Section.__index = Section

-- Tap vs scroll discrimination threshold (pixels).
local TAP_MOVE_THRESHOLD = 12

-- Collapsed height: header (16) + top pad (10) + bottom pad (10)
local COLLAPSED_H = 36

function Section.new(title: string, parentContent: Instance, ownerTab)
    local self = setmetatable({}, Section)

    self.Title           = title or "Section"
    self._componentCount = 1
    self._destroyed      = false
    self._ownerTab       = ownerTab or nil   -- optional; enables debug ID allocation

    self._handles = {}
    self._maid    = Maid.new()

    -- ─── Frame ─────────────────────────────────────────────────────────────

    self._collapsed = false
    self._contentH  = 0

    self.Frame = ComponentHelper.Create("Frame", {
        Name                   = "Section_" .. self.Title,
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        BackgroundTransparency = 0.5,
        BorderSizePixel        = 0,
        ClipsDescendants       = true,
        Parent                 = parentContent,
    })
    ComponentHelper.AddCorner(self.Frame, 8)
    local stroke = ComponentHelper.AddStroke(self.Frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(self.Frame, 10, 10, 10, 10)

    self._layout = ComponentHelper.Create("UIListLayout", {
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

    self._chevron = ComponentHelper.Create("TextLabel", {
        Name                   = "Chevron",
        Size                   = UDim2.new(0, 14, 1, 0),
        Position               = UDim2.new(1, -2, 0, 0),
        AnchorPoint            = Vector2.new(1, 0),
        Text                   = "▾",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 11,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Right,
        BackgroundTransparency = 1,
        Parent                 = self.HeaderLabel,
    })

    -- ─── Tap-vs-scroll discrimination (M2 fix) ─────────────────────────────
    --
    -- BUG-SEC fix: HeaderLabel is a TextLabel. On desktop, TextLabel.InputBegan
    -- does NOT fire for MouseButton1 clicks — only TextButton receives those.
    -- Fix: transparent TextButton (HeaderBtn) overlays the full header row.
    --   Desktop: HeaderBtn.Activated  → ToggleCollapsed (clean, no gesture needed)
    --   Mobile:  HeaderBtn.InputBegan → start tap-vs-scroll discrimination
    --            UserInputService.InputChanged / InputEnded → confirm or cancel

    local HeaderBtn = ComponentHelper.Create("TextButton", {
        Name                   = "HeaderBtn",
        Size                   = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        ZIndex                 = self.HeaderLabel.ZIndex + 1,
        Parent                 = self.HeaderLabel,
    })

    local _tapInput   = nil
    local _tapStartX  = 0
    local _tapStartY  = 0
    local _tapPending = false
    local _tapDragged = false

    -- Desktop: MouseButton1Click only fires for actual mouse button presses,
    -- never for touch events. Guard additionally with not TouchEnabled so
    -- touchscreen PCs route through the InputEnded path instead.
    self._maid:GiveTask(HeaderBtn.MouseButton1Click:Connect(function()
        if UserInputService.TouchEnabled then return end  -- touch uses InputEnded path
        self:ToggleCollapsed()
    end))

    -- Mobile: InputBegan starts tap-vs-scroll classification.
    self._maid:GiveTask(HeaderBtn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        _tapInput   = input
        _tapStartX  = input.Position.X
        _tapStartY  = input.Position.Y
        _tapPending = true
        _tapDragged = false
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not _tapPending           then return end
        if input ~= _tapInput        then return end
        local dx = math.abs(input.Position.X - _tapStartX)
        local dy = math.abs(input.Position.Y - _tapStartY)
        if math.sqrt(dx * dx + dy * dy) > TAP_MOVE_THRESHOLD then
            _tapDragged = true
            _tapPending = false
        end
    end))

    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        if input ~= _tapInput then return end
        if _tapPending and not _tapDragged then
            self:ToggleCollapsed()
        end
        _tapPending = false
        _tapDragged = false
        _tapInput   = nil
    end))

    -- ─── Theme listener ─────────────────────────────────────────────────────

    self._maid:GiveTask(ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(self.Frame,       nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(stroke,           nil, { Color = tokens.Border             })
        TweenHelper.Tween(self.HeaderLabel, nil, { TextColor3 = tokens.SubText       })
        TweenHelper.Tween(self._chevron,    nil, { TextColor3 = tokens.SubText       })
    end))

    -- M8 fix: snapshot settled height after first layout pass.
    -- task.defer gives Roblox one frame to resolve AbsoluteSize after construction.
    task.defer(function()
        if self._destroyed then return end
        local h = self.Frame.AbsoluteSize.Y
        if h > COLLAPSED_H then
            self._contentH = h
        end
    end)

    -- Keep _contentH current whenever children are added or resized.
    -- AbsoluteContentSize changes when a child's size changes (e.g. Paragraph
    -- height recomputed via TextService). Without this, _contentH stays at the
    -- constructor-time snapshot and SetCollapsed uses stale data.
    self._maid:GiveTask(self._layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if self._collapsed then return end  -- don't update while collapsed
        local h = self.Frame.AbsoluteSize.Y
        if h > COLLAPSED_H then
            self._contentH = h
        end
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

function Section:_register(handle, config)
    ComponentHelper.BindCallback(handle, config)
    table.insert(self._handles, handle)

    if handle and type(handle) ~= "table" then
        return handle
    end

    -- Determine prevention from config flags
    local preventUnload = false
    if config and type(config) == "table" then
        if config.KeepOnUnload == true
            or config.IgnoreUnload == true
            or config.AutoUnload == false
        then
            preventUnload = true
        end
    end

    handle._keepOnUnload = preventUnload

    -- Auto-register component cleanup with UnloadService (runs on Delirium:Unload)
    UnloadService.Register(function()
        if not handle._keepOnUnload and not handle._destroyed then
            if type(handle.Destroy) == "function" then
                pcall(handle.Destroy, handle)
            end
        end
    end)

    -- Runtime prevention API ─────────────────────────────────────────────────
    function handle:SetKeepOnUnload(keep: boolean)
        self._keepOnUnload = keep == true
    end

    -- Alias: SetIgnoreUnload(true) == SetKeepOnUnload(true)
    function handle:SetIgnoreUnload(ignore: boolean)
        self:SetKeepOnUnload(ignore)
    end

    return handle
end

function Section:_allocDebugId(componentType: string): string?
    local ot = self._ownerTab
    if ot and ot._debugMode then
        return ot:_AllocDebugId(componentType)
    end
    return nil
end

-- ─── Component factory ─────────────────────────────────────────────────────

function Section:CreateButton(config: table)
    local h = Button.New(self.Frame, config, self:_allocDebugId("Button"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddButton = Section.CreateButton

function Section:CreateToggle(config: table)
    local h = Toggle.New(self.Frame, config, self:_allocDebugId("Toggle"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddToggle = Section.CreateToggle

function Section:CreateSlider(config: table)
    local h = Slider.New(self.Frame, config, self:_allocDebugId("Slider"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddSlider = Section.CreateSlider

function Section:CreateTextbox(config: table)
    local h = TextBox.New(self.Frame, config, self:_allocDebugId("TextBox"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddTextbox = Section.CreateTextbox

function Section:CreateDropdown(config: table)
    local h = Dropdown.New(self.Frame, config, self:_allocDebugId("Dropdown"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddDropdown = Section.CreateDropdown

function Section:CreateKeybind(config: table)
    local h = Keybind.New(self.Frame, config, self:_allocDebugId("Keybind"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddKeybind = Section.CreateKeybind

function Section:CreateColorPicker(config: table)
    local h = ColorPicker.New(self.Frame, config, self:_allocDebugId("ColorPicker"))
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddColorPicker = Section.CreateColorPicker

function Section:CreateLabel(config: table)
    local h = Label.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddLabel = Section.CreateLabel

function Section:CreateParagraph(config: table)
    local h = Paragraph.New(self.Frame, config)
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddParagraph = Section.CreateParagraph

function Section:CreateDivider(config: table)
    local h = Divider.New(self.Frame, config or {})
    _applyOrder(h.Instance, self:_nextOrder())
    return self:_register(h, config)
end
Section.AddDivider = Section.CreateDivider

-- ─── Collapse system (M8 fix) ─────────────────────────────────────────────────
--
-- Root cause of first-collapse jump:
--   Frame.AutomaticSize = Y was active while we called self.Frame.AbsoluteSize.Y.
--   With AutomaticSize active, Roblox drives Size internally and the explicit
--   Size property is ignored / stale. AbsoluteSize reflects the auto-computed
--   value, but only AFTER the layout pass resolves — which may not have happened
--   yet if this is the first interaction immediately after parenting.
--
--   The old flow was:
--     1. Read AbsoluteSize.Y  ← potentially 0 or stale on first call
--     2. Disable AutomaticSize
--     3. Tween from current (wrong) Size to COLLAPSED_H  ← jump
--
--   Fixed flow (collapse):
--     1. Disable AutomaticSize
--     2. Explicitly lock Size.Y to current AbsoluteSize.Y (snapshot)
--        This makes the explicit Size match reality before tween starts.
--     3. Store snapshot as _contentH
--     4. Tween from locked Size to COLLAPSED_H  ← smooth, always correct
--
--   Fixed flow (expand):
--     1. Set Size.Y to COLLAPSED_H (current state — no jump)
--     2. Tween to _contentH
--     3. Re-enable AutomaticSize after tween settles

function Section:SetCollapsed(collapsed: boolean, animate: boolean)
    if collapsed == self._collapsed then return end
    self._collapsed = collapsed

    if collapsed then
        -- ── COLLAPSE ──────────────────────────────────────────────────────
        --
        -- ROOT-CAUSE FIX: read AbsoluteSize.Y BEFORE setting AutomaticSize = None.
        -- When AutomaticSize switches to None, Roblox immediately uses the explicit
        -- Size property. The explicit Size is UDim2.new(1,0,0,0) (set at construction).
        -- So AbsoluteSize.Y drops to 0 the instant AutomaticSize = None is assigned.
        -- Reading AFTER = always 0 → guard fires → retry loop →
        -- AutomaticSize toggles → pageLayout.AbsoluteContentSizeChanged fires →
        -- re-entrancy at depth 80.
        --
        -- Reading BEFORE = actual computed height with all children = correct.
        local fullH = self.Frame.AbsoluteSize.Y

        -- Secondary: fall back to cached _contentH if live read is stale (e.g.
        -- collapse called mid-expand-tween where AbsoluteSize is still intermediate).
        if fullH <= COLLAPSED_H and self._contentH > COLLAPSED_H then
            fullH = self._contentH
        end

        if fullH <= COLLAPSED_H then
            -- Layout is already at or below collapsed height; lock frame size safely without recursion
            if animate then
                TweenHelper.Tween(self._chevron, TweenHelper.FastInfo, { Rotation = -90 })
            else
                self._chevron.Rotation = -90
            end
            self.Frame.AutomaticSize = Enum.AutomaticSize.None
            self.Frame.Size = UDim2.new(1, 0, 0, COLLAPSED_H)
            return
        end
        self._contentH = fullH

        -- Chevron — rotate after geometry is confirmed.
        if animate then
            TweenHelper.Tween(self._chevron, TweenHelper.FastInfo, { Rotation = -90 })
        else
            self._chevron.Rotation = -90
        end

        -- Disable AutomaticSize AFTER snapshotting fullH, then lock Size.
        self.Frame.AutomaticSize = Enum.AutomaticSize.None
        self.Frame.Size = UDim2.new(1, 0, 0, fullH)

        -- Tween from locked full height → collapsed height.
        if animate then
            TweenHelper.Tween(self.Frame, TweenHelper.FastInfo,
                { Size = UDim2.new(1, 0, 0, COLLAPSED_H) }, "collapse")
            task.delay(TweenHelper.FastInfo.Time, function()
                if self._collapsed and self.Frame and self.Frame.Parent then
                    for _, child in ipairs(self.Frame:GetChildren()) do
                        if child ~= self.HeaderLabel and child:IsA("GuiObject") then
                            child.Visible = false
                        end
                    end
                end
            end)
        else
            self.Frame.Size = UDim2.new(1, 0, 0, COLLAPSED_H)
            for _, child in ipairs(self.Frame:GetChildren()) do
                if child ~= self.HeaderLabel and child:IsA("GuiObject") then
                    child.Visible = false
                end
            end
        end

    else
        -- ── EXPAND ────────────────────────────────────────────────────────
        -- Make all child components visible before expand animation starts
        for _, child in ipairs(self.Frame:GetChildren()) do
            if child ~= self.HeaderLabel and child:IsA("GuiObject") then
                child.Visible = true
            end
        end

        -- Chevron first — expand never has a layout-race condition since the
        -- section was already collapsed at a known geometry.
        if animate then
            TweenHelper.Tween(self._chevron, TweenHelper.FastInfo, { Rotation = 0 })
        else
            self._chevron.Rotation = 0
        end

        local targetH = self._contentH > COLLAPSED_H and self._contentH
            or (COLLAPSED_H + self._layout.AbsoluteContentSize.Y + 20)

        -- Ensure explicit Size matches current collapsed state before tweening.
        -- Defensive: handles the case where expand is called without a prior collapse.
        self.Frame.AutomaticSize = Enum.AutomaticSize.None
        self.Frame.Size          = UDim2.new(1, 0, 0, COLLAPSED_H)

        if animate then
            TweenHelper.Tween(self.Frame, TweenHelper.FastInfo,
                { Size = UDim2.new(1, 0, 0, targetH) }, "collapse")
            -- Re-enable AutomaticSize after tween settles so future component
            -- additions continue to auto-resize the section correctly.
            task.delay(TweenHelper.FastInfo.Time + 0.02, function()
                if not self._collapsed and self.Frame and self.Frame.Parent then
                    self.Frame.AutomaticSize = Enum.AutomaticSize.Y
                end
            end)
        else
            self.Frame.Size          = UDim2.new(1, 0, 0, targetH)
            self.Frame.AutomaticSize = Enum.AutomaticSize.Y
        end
    end
end

function Section:ToggleCollapsed()
    self:SetCollapsed(not self._collapsed, true)
end

-- ─── Public API ─────────────────────────────────────────────────────────────

function Section:SetTitle(title: string)
    self.Title = title
    self.HeaderLabel.Text = string.upper(title)
end

function Section:Show()  self.Frame.Visible = true  end
function Section:Hide()  self.Frame.Visible = false end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Section:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    for _, handle in ipairs(self._handles) do
        pcall(function() handle:Destroy() end)
    end
    table.clear(self._handles)

    self._maid:DoCleaning()

    if self.Frame and self.Frame.Parent then
        self.Frame:Destroy()
    end
end

return Section

end

-- ── Layout.Tab ────────────────────────────────────────────
_Delirium_modules["Layout.Tab"] = function()
-- Layout/Tab.lua
-- Owns its Sections. Cascade: Tab:Destroy() → Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.
-- local Root            = script.Parent.Parent
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local Maid            = _Delirium_require("Core.Maid")
local Section         = _Delirium_require("Layout.Section")
local Dropdown        = _Delirium_require("Components.Dropdown")

local Tab = {}
Tab.__index = Tab

function Tab.new(config: table, windowManager: table)
    local self = setmetatable({}, Tab)

    self.Name          = config.Name or "Tab"
    self.Icon          = config.Icon or ""
    self.WindowManager = windowManager
    self.IsActive      = false
    self._destroyed    = false

    -- ─── Debug mode (three-way: nil = inherit, true = on, false = off) ───────
    -- Inherits from the parent Window unless explicitly overridden in config.
    local windowDebug = windowManager and windowManager._debugMode or false
    if config.DebugMode ~= nil then
        self._debugMode = config.DebugMode == true
    else
        self._debugMode = windowDebug
    end
    -- Monotonic per-type counter. Never decremented on destroy so identities
    -- remain unambiguous even after a component is removed.
    self._componentCounters = {}
    self._debugLabel        = self.Name

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
            -- Active: accent label, accent indicator visible, surface background
            self.NavLabel.TextColor3              = tokens.Accent
            self.Indicator.BackgroundColor3       = tokens.Accent
            self.Indicator.BackgroundTransparency = 0
            self.NavButton.BackgroundColor3       = tokens.Surface
            self.NavButton.BackgroundTransparency = 0.2
        else
            -- Inactive: subdued label, indicator hidden, bg transparent
            self.NavLabel.TextColor3              = tokens.SubText
            self.Indicator.BackgroundColor3       = tokens.Accent  -- pre-load color so next activation tweens correctly
            self.Indicator.BackgroundTransparency = 1
            self.NavButton.BackgroundTransparency = 1
        end
    end))

    return self
end

-- ─── Section management ────────────────────────────────────────────────────

function Tab:CreateSection(title: string)
    local section = Section.new(title, self.PageCanvas, self)
    table.insert(self._sections, section)
    return section
end

-- Allocate a monotonic debug identity for a component.
-- Format: "TabName > TypeN" where N never resets on destroy.
function Tab:_AllocDebugId(componentType: string): string
    local n = (self._componentCounters[componentType] or 0) + 1
    self._componentCounters[componentType] = n
    return string.format("%s > %s%d", self._debugLabel, componentType, n)
end

-- ─── Private: pure visual activation update ───────────────────────────────
--
-- Called exclusively by Window:SelectTab to apply visual state without
-- any SelectTab recursion. External code should use SetActive() instead,
-- which routes through SelectTab to guarantee mutual exclusivity.

function Tab:_ApplyActive(active: boolean)
    self.IsActive = active
    self.PageCanvas.Visible = active

    if not active then
        -- The popup lives in the ScreenGui overlay, not inside PageCanvas, so
        -- it does not automatically disappear when the page is hidden.
        -- Explicitly close the active popup (if any) on tab deactivation.
        Dropdown.CloseActive()
    end

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

-- ─── Public: tab activation ───────────────────────────────────────────────
--
-- FIX (BUG-TAB-DUAL): Previously this method applied visual state directly
-- without notifying sibling tabs, allowing multiple tabs to show as active
-- simultaneously (e.g. test T04.6 calling Tab5:SetActive(true) while Tab1
-- was still visible caused two PageCanvases to be Visible=true at once,
-- which locked the UI).
--
-- SetActive(true)  → delegates to Window:SelectTab, which calls _ApplyActive
--                    on all tabs, guaranteeing mutual exclusivity.
-- SetActive(false) → directly applies the inactive visual state (safe, no
--                    sibling tabs are affected).

function Tab:SetActive(active: boolean)
    if active then
        -- Route through Window:SelectTab so all sibling tabs are deactivated first.
        self.WindowManager:SelectTab(self)
    else
        self:_ApplyActive(false)
    end
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Tab:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- FIX (BUG-TAB-STALE): Remove self from the Window's tab registry so that
    -- Window:SelectTab never iterates over destroyed Tab instances (which would
    -- error on Visible = active since PageCanvas is already destroyed).
    -- Also clear CurrentTab if this was the active one.
    local wm = self.WindowManager
    if wm then
        local tabs = wm._tabs
        if tabs then
            for i, t in ipairs(tabs) do
                if t == self then
                    table.remove(tabs, i)
                    break
                end
            end
        end
        if wm.CurrentTab == self then
            wm.CurrentTab = nil
        end
    end

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

end

-- ── Layout.Window ─────────────────────────────────────────
_Delirium_modules["Layout.Window"] = function()
-- Layout/Window.lua
-- Owns its Tabs. Cascade: Window:Destroy() → Tab:Destroy() → Section:Destroy() → Component:Destroy()
-- Idempotent: multiple :Destroy() calls are safe.

local UserInputService  = game:GetService("UserInputService")
local GuiService        = game:GetService("GuiService")
-- local Root              = script.Parent.Parent
local ThemeEngine       = _Delirium_require("Core.ThemeEngine")
local AnimationEngine   = _Delirium_require("Core.AnimationEngine")
local TweenHelper       = _Delirium_require("Utilities.TweenHelper")
local ComponentHelper   = _Delirium_require("Utilities.ComponentHelper")
local Maid              = _Delirium_require("Core.Maid")
local DialogService     = _Delirium_require("Services.DialogService")
local UnloadService     = _Delirium_require("Services.UnloadService")
local Tab               = _Delirium_require("Layout.Tab")
local DeviceDetector    = _Delirium_require("Utilities.DeviceDetector")
local InputAdapter      = _Delirium_require("Core.InputAdapter")
local Dropdown          = _Delirium_require("Components.Dropdown")

local TITLEBAR_H     = 45
local BUTTON_SIZE    = 28
local BUTTON_GAP     = 4
local BUTTON_ROW_W   = BUTTON_SIZE * 3 + BUTTON_GAP * 2  -- 92px (3 buttons: ⌘ − ×)
local DRAG_EXCLUSION = BUTTON_ROW_W + 20                  -- 112px from right edge
local MINI_SIZE      = 38    -- MiniIconFrame side length

-- Resize handle
local RESIZE_HANDLE_SIZE     = 16   -- px, bottom-right corner hitbox
local RESIZE_THRESHOLD_MOUSE =  5   -- px deadzone (mouse)
local RESIZE_THRESHOLD_TOUCH = 10   -- px deadzone (touch)

-- Drag deadzone: minimum movement before a drag gesture commits.
-- P2: Thresholds are centralized in Core/InputAdapter.lua.
--     Reference: InputAdapter.DRAG_THRESHOLD_MOUSE / InputAdapter.DRAG_THRESHOLD_TOUCH
local RESIZE_MIN_W_DEFAULT   = 240  -- px
local RESIZE_MIN_H_DEFAULT   = 160  -- px

-- P0: Responsive spawn margins.
-- Minimum gap between Window edges and the viewport boundary at creation time.
-- These are one-shot constraints — the user may drag/resize to the edge afterward.
local SPAWN_MARGIN_H = 20   -- px per side, horizontal
local SPAWN_MARGIN_V = 16   -- px per side, vertical (applied to usable area after insets)

-- ─── Focus / ZIndex management ───────────────────────────────────────────────
-- Module-local monotonic counter. Every time a Window receives focus it claims
-- the next integer, guaranteeing it renders above every other Delirium window
-- in the same ScreenGui (ZIndexBehavior = Sibling).
-- Counter grows throughout the session lifetime — no overflow risk in practice.
local _focusCounter = 0
local function _nextFocusZ(): number
    _focusCounter = _focusCounter + 1
    return _focusCounter
end

-- ─── P0: Responsive sizing helpers (module-level, no self) ──────────────────
--
-- _computeSize(preferred?)
--   Constrains the preferred Window size to the current usable viewport.
--   Rule set (P0.1 – P0.5):
--     • Preferred fits → return it unchanged.
--     • Preferred overflows → clamp to (viewport - margins).
--     • No preferred → derive a proportional default from the viewport.
--     • Never go below RESIZE_MIN_W_DEFAULT × RESIZE_MIN_H_DEFAULT.
--     • On desktop (large viewport) the original default size is preserved.
--
local function _computeSize(preferred: UDim2?): UDim2
    local vp    = DeviceDetector:GetViewport()
    local ready = DeviceDetector:IsViewportReady()

    local prefW: number
    local prefH: number
    if preferred then
        prefW = preferred.X.Offset
        prefH = preferred.Y.Offset
    end

    -- Viewport unavailable: trust caller for desktop, cap for mobile.
    if not ready then
        if DeviceDetector:IsMobile() then
            return UDim2.fromOffset(
                math.clamp(prefW or 340, RESIZE_MIN_W_DEFAULT, 340),
                math.clamp(prefH or 300, RESIZE_MIN_H_DEFAULT, 300)
            )
        end
        return UDim2.fromOffset(prefW or 580, prefH or 380)
    end

    -- Viewport ready: derive usable area, applying GuiInset on both axes.
    local topLeft, bottomRight = GuiService:GetGuiInset()
    local usableH = vp.Y - topLeft.Y - bottomRight.Y

    -- Maximum allowed dimensions: viewport minus per-side spawn margins.
    local maxW = math.max(RESIZE_MIN_W_DEFAULT, vp.X    - SPAWN_MARGIN_H * 2)
    local maxH = math.max(RESIZE_MIN_H_DEFAULT, usableH - SPAWN_MARGIN_V * 2)

    -- No preferred size: compute a proportional default from the viewport.
    -- Phone-sized viewports get scaled-down defaults; desktop keeps 580×380.
    if not prefW then
        if vp.X < 600 then
            prefW = math.floor(vp.X    * 0.60)
            prefH = math.floor(usableH * 0.60)
        else
            prefW = 580
            prefH = 380
        end
    end

    -- Clamp: this is the core constraint missing when config.Size was provided.
    -- On desktop with a large viewport maxW >> 580 so preferred passes through unchanged.
    local finalW = math.clamp(prefW, RESIZE_MIN_W_DEFAULT, maxW)
    local finalH = math.clamp(prefH, RESIZE_MIN_H_DEFAULT, maxH)
    return UDim2.fromOffset(finalW, finalH)
end

-- _computeInitialPosition()
--   Centers the Window in the USABLE viewport (below Roblox topbar, above home-bar).
--   With AnchorPoint(0.5,0.5) and scale(0.5,…) origin, an offset of 0 centers in
--   the TOTAL viewport; we add a Y-offset to re-center in the narrower usable area.
--   On desktop the shift is ~18 px — visually imperceptible and technically correct.
--
local function _computeInitialPosition(): UDim2
    local vp    = DeviceDetector:GetViewport()
    local ready = DeviceDetector:IsViewportReady()
    if not ready then
        return UDim2.fromScale(0.5, 0.5)
    end
    local topLeft, bottomRight = GuiService:GetGuiInset()
    local topInset    = topLeft.Y
    local bottomInset = bottomRight.Y
    local usableH     = vp.Y - topInset - bottomInset
    -- Midpoint of the usable area in screen-space Y, then convert to a scale(0.5) offset.
    local usableMidY  = topInset + usableH * 0.5
    local offY        = usableMidY - vp.Y * 0.5
    return UDim2.new(0.5, 0, 0.5, math.floor(offY))
end

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
    self._debugMode  = config.DebugMode == true

    self._tabs = {}
    self._maid = Maid.new()

    -- Resize state
    self._isResizable   = config.Resizable == true
    self._resizeMinSize = (type(config.MinSize) == "userdata" and config.MinSize)
                          or Vector2.new(RESIZE_MIN_W_DEFAULT, RESIZE_MIN_H_DEFAULT)
    self._isDragging    = false
    self._dragPending   = false   -- true from InputBegan until deadzone is crossed
    self._isResizing    = false
    self._resizeHandle  = nil

    -- Store original size for Restore().
    -- P0: _computeSize() applies viewport-aware clamping regardless of whether
    -- config.Size was provided. Previously, a caller-supplied config.Size bypassed
    -- all responsive logic, spawning a 580px-wide window on a 390px phone screen.
    self._originalSize = _computeSize(config.Size)

    -- Track last known viewport for proportional edge-anchored position remapping
    local initVp = DeviceDetector:GetViewport()
    if initVp and initVp.X > 0 and initVp.Y > 0 then
        self._lastViewport = initVp
    else
        local cam = workspace.CurrentCamera
        self._lastViewport = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
    end

    -- ─── Main frame ──────────────────────────────────────────────────────

    self.MainFrame = ComponentHelper.Create("CanvasGroup", {
        Name              = "DeliriumMainFrame",
        Size              = self._originalSize,
        Position          = _computeInitialPosition(),
        AnchorPoint       = Vector2.new(0.5, 0.5),
        BackgroundColor3  = ThemeEngine.GetToken("Background"),
        BorderSizePixel   = 0,
        GroupTransparency = 0,
        ClipsDescendants  = true,
        Parent            = parentGui,
    })
    ComponentHelper.AddCorner(self.MainFrame, 10)
    local mainStroke = ComponentHelper.AddStroke(self.MainFrame, ThemeEngine.GetToken("Border"), 1)

    -- ─── Overlay layer ────────────────────────────────────────────────────
    -- A transparent Frame that lives as a sibling of MainFrame in the ScreenGui.
    -- Floating popups (Dropdown, ColorPicker, context menus) are parented to
    -- this overlay instead of the raw ScreenGui ancestor, so they are owned
    -- by the Window and cleaned up automatically when it is destroyed.
    -- ZIndex is kept above MainFrame so popups always render above window
    -- content; _Focus() re-raises it to track window stacking order.
    self.Overlay = ComponentHelper.Create("Frame", {
        Name                   = "DeliriumOverlay",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ClipsDescendants       = false,
        ZIndex                 = 299,
        Parent                 = parentGui,
    })
    self._maid:GiveTask(self.Overlay)

    -- ─── Input sink ──────────────────────────────────────────────────────
    -- Transparent TextButton at ZIndex=1 (lowest possible) covering the full
    -- MainFrame. Absorbs clicks/touches that land on empty window background
    -- so they don't fall through to the game camera or input stack.
    --
    -- FIX (BUG-NAV): InputSink MUST be created FIRST — before TitleBar and
    -- ContentContainer — so that at equal ZIndex (1) the later-added siblings
    -- (TitleBar, ContentContainer) rank above it in Roblox's Sibling input
    -- dispatch. With the old ordering (InputSink last) it shadowed every
    -- interactive child of TitleBar and ContentContainer, making title buttons,
    -- NavButtons, and all component inputs completely unresponsive.
    local inputSink = ComponentHelper.Create("TextButton", {
        Name                   = "InputSink",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        ZIndex                 = 1,
        Parent                 = self.MainFrame,
    })
    -- Focus: clicking the window background brings this window to the front.
    self._maid:GiveTask(inputSink.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            self:_Focus()
        end
    end))

    -- ─── Title bar ───────────────────────────────────────────────────────

    self.TitleBar = ComponentHelper.Create("Frame", {
        Name                   = "TitleBar",
        Size                   = UDim2.new(1, 0, 0, TITLEBAR_H),
        BackgroundTransparency = 1,
        ZIndex                 = 2,   -- above InputSink (ZIndex=1); propagates to all children
        Parent                 = self.MainFrame,
    })
    ComponentHelper.AddPadding(self.TitleBar, 0, 0, 16, 16)

    -- DragZone: transparent TextButton covering the draggable region of TitleBar.
    -- Using a TextButton (not a Frame) ensures touch InputBegan is consumed by
    -- the GUI system, preventing Roblox's camera from also receiving the touch.
    -- Width = full bar minus DRAG_EXCLUSION (button zone) so title buttons stay hit-testable.
    self._dragZone = ComponentHelper.Create("TextButton", {
        Name                   = "DragZone",
        Size                   = UDim2.new(1, -DRAG_EXCLUSION, 1, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        ZIndex                 = 2,
        Parent                 = self.TitleBar,
    })

    -- P1: Title fills available horizontal space minus explicit room for the ButtonRow.
    -- The old 0.6 fraction caused TitleLabel to overlap ButtonRow on narrow windows
    -- (e.g. at 240px: title right=160px, ButtonRow left=148px → 12px overlap).
    -- BUTTON_ROW_W (92px) + 8px gap = 100px reserved; consistent 8px clearance at every width.
    local TITLE_RESERVE = BUTTON_ROW_W + 8   -- 100px: buttons (92) + gap (8)

    self.TitleLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "TitleLabel",
        Text                   = self.Name,
        Font                   = Enum.Font.GothamBold,
        TextSize               = 16,
        TextColor3             = ThemeEngine.GetToken("Text"),
        TextXAlignment         = Enum.TextXAlignment.Left,
        Size                   = UDim2.new(1, -TITLE_RESERVE, 1, 0),
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
            Size                   = UDim2.new(1, -TITLE_RESERVE, 1, 0),
            Position               = UDim2.new(0, 0, 0.30, 0),
            BackgroundTransparency = 1,
            Parent                 = self.TitleBar,
        })
        self.TitleLabel.Size = UDim2.new(1, -TITLE_RESERVE, 0.45, 0)
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

    self._maid:GiveTask(self._miniIconBtn.Activated:Connect(function()
        self:MiniIconify()
    end))
    self._maid:GiveTask(self._minimizeBtn.Activated:Connect(function()
        self:ToggleMinimize()
    end))
    self._maid:GiveTask(self._closeBtn.Activated:Connect(function()
        self:Close()
    end))

    -- Configurable titlebar button visibility (default true)
    if config.MiniIcon == false then self._miniIconBtn.Visible = false end
    if config.Minimize == false then self._minimizeBtn.Visible = false end
    if config.Close    == false then self._closeBtn.Visible    = false end

    -- ─── Content container ───────────────────────────────────────────────

    self.ContentContainer = ComponentHelper.Create("Frame", {
        Name                   = "ContentContainer",
        Size                   = UDim2.new(1, 0, 1, -TITLEBAR_H),
        Position               = UDim2.new(0, 0, 0, TITLEBAR_H),
        BackgroundTransparency = 1,
        ZIndex                 = 2,   -- above InputSink (ZIndex=1); propagates to all children
        Parent                 = self.MainFrame,
    })

    -- Layout mode: Full (with SideNav tabs) vs Compact / NoTabs (full-width page canvas)
    local isCompact = config.Compact == true or config.Tabs == false or config.NoTabs == true
    self._isCompact = isCompact

    -- P1: Responsive sidenav width.
    -- Prefer the established desktop width (140px); never exceed 35% of the
    -- initial Window width so the content area always retains usable space.
    -- On isCompact mode the sidenav is hidden entirely (0px).
    -- The 35% ratio preserves the desktop layout on wide windows (35% of 400px+ >= 140)
    -- while proportionally yielding space to content on narrower phone windows.
    local windowW        = self._originalSize.X.Offset
    local SIDENAV_DEST_W = 140   -- existing desktop target; preserved on wide windows
    local navW = isCompact and 0
        or math.min(SIDENAV_DEST_W, math.floor(windowW * 0.35))
    -- Show scrollbar on narrow sidenavs where touch-scrolling many tabs is likely.
    local navScrollBar = (navW > 0 and navW < SIDENAV_DEST_W) and 2 or 0

    self.SideNav = ComponentHelper.Create("ScrollingFrame", {
        Name                   = "SideNav",
        Size                   = UDim2.new(0, navW, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ScrollBarThickness     = navScrollBar,
        Visible                = not isCompact,
        Parent                 = self.ContentContainer,
    })
    ComponentHelper.AddPadding(self.SideNav, 8, 8, 8, 8)
    local sideNavLayout = ComponentHelper.Create("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding   = UDim.new(0, 4),
        Parent    = self.SideNav,
    })

    self._maid:GiveTask(
        sideNavLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            self.SideNav.CanvasSize =
                UDim2.new(0, 0, 0, sideNavLayout.AbsoluteContentSize.Y + 16)
        end)
    )

    local divider = ComponentHelper.Create("Frame", {
        Name             = "NavDivider",
        Size             = UDim2.new(0, 1, 1, -16),
        Position         = UDim2.new(0, navW, 0, 8),
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        Visible          = not isCompact,
        Parent           = self.ContentContainer,
    })

    self.PageView = ComponentHelper.Create("Frame", {
        Name                   = "PageView",
        Size                   = isCompact and UDim2.new(1, 0, 1, 0) or UDim2.new(1, -(navW + 1), 1, 0),
        Position               = isCompact and UDim2.new(0, 0, 0, 0) or UDim2.new(0, navW + 1, 0, 0),
        BackgroundTransparency = 1,
        Parent                 = self.ContentContainer,
    })

    -- ─── MiniIconFrame (hidden until MiniIconify()) ───────────────────────

    self._miniIconFrame  = self:_BuildMiniIconFrame(parentGui)
    self._miniDragMoved  = false

    -- ─── Dragging ─────────────────────────────────────────────────────────

    self:_EnableDragging()
    self:_EnableMiniIconDragging()
    self:_EnableResizing()
    -- Claim initial ZIndex so later-created windows start above earlier ones.
    self:_Focus()

    -- ─── Viewport resize / orientation change listener ────────────────────
    -- Re-clamps MainFrame and MiniIconFrame so they never get lost offscreen
    -- when toggling fullscreen or resizing the Roblox client window.
    self._maid:GiveTask(DeviceDetector.Changed:Connect(function(_, vp)
        self:_OnViewportChanged(vp)
    end))

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

        -- Resize handle theme passthrough
        if self._resizeHandle then
            local glyph = self._resizeHandle:FindFirstChild("ResizeGlyph")
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
        ZIndex                 = 10,
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
    ComponentHelper.AddCorner(frame, 8)
    ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)

    -- Glyph label
    ComponentHelper.Create("TextLabel", {
        Name                   = "Glyph",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "⌘",
        Font                   = Enum.Font.GothamBold,
        TextSize               = 16,
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
    -- Read both top and bottom insets: top = Roblox topbar/notch; bottom = home bar.
    local topLeft, bottomRight = GuiService:GetGuiInset()
    local topInset    = topLeft.Y        -- 36px on PC, notch height on iPhone
    local bottomInset = bottomRight.Y    -- home-bar area on modern phones

    local cx = screen.X * 0.5 + rawOffX
    local cy = screen.Y * 0.5 + rawOffY

    -- Hard clamp:
    --   left   >= 0                →  cx >= sz.X/2
    --   right  <= screen.X         →  cx <= screen.X - sz.X/2
    --   top    >= topbar bottom     →  cy >= topInset + sz.Y/2
    --   bottom <= screen - homebar  →  cy <= screen.Y - bottomInset - sz.Y/2
    local minX = sz.X * 0.5
    local maxX = math.max(minX, screen.X - sz.X * 0.5)
    local minY = topInset + sz.Y * 0.5
    local maxY = math.max(minY, screen.Y - bottomInset - sz.Y * 0.5)

    cx = math.clamp(cx, minX, maxX)
    cy = math.clamp(cy, minY, maxY)

    return UDim2.new(0.5, cx - screen.X * 0.5,
                     0.5, cy - screen.Y * 0.5)
end

-- ─── Proportional screen-edge remapping helper ────────────────────────────
-- Maps frame's relative edge position from oldVP into newVP proportionally.
-- If the frame was positioned near a screen corner/edge (e.g. bottom-left),
-- it stays anchored at that same relative edge in the new resolution instead
-- of jumping inward to the screen center.
function Window:_RemapPositionToViewport(frame: GuiObject, oldVP: Vector2, newVP: Vector2): UDim2
    local sz = frame.AbsoluteSize
    local topLeft, bottomRight = GuiService:GetGuiInset()
    local topInset    = topLeft.Y
    local bottomInset = bottomRight.Y

    local oldCx = oldVP.X * 0.5 + frame.Position.X.Offset
    local oldCy = oldVP.Y * 0.5 + frame.Position.Y.Offset

    local oldMinX = sz.X * 0.5
    local oldMaxX = math.max(oldMinX, oldVP.X - sz.X * 0.5)
    local oldRangeX = oldMaxX - oldMinX

    local oldMinY = topInset + sz.Y * 0.5
    local oldMaxY = math.max(oldMinY, oldVP.Y - bottomInset - sz.Y * 0.5)
    local oldRangeY = oldMaxY - oldMinY

    local ratioX = (oldRangeX > 0) and math.clamp((oldCx - oldMinX) / oldRangeX, 0, 1) or 0.5
    local ratioY = (oldRangeY > 0) and math.clamp((oldCy - oldMinY) / oldRangeY, 0, 1) or 0.5

    local newMinX = sz.X * 0.5
    local newMaxX = math.max(newMinX, newVP.X - sz.X * 0.5)
    local newRangeX = newMaxX - newMinX

    local newMinY = topInset + sz.Y * 0.5
    local newMaxY = math.max(newMinY, newVP.Y - bottomInset - sz.Y * 0.5)
    local newRangeY = newMaxY - newMinY

    local newCx = newMinX + ratioX * newRangeX
    local newCy = newMinY + ratioY * newRangeY

    newCx = math.clamp(newCx, newMinX, newMaxX)
    newCy = math.clamp(newCy, newMinY, newMaxY)

    return UDim2.new(0.5, newCx - newVP.X * 0.5,
                     0.5, newCy - newVP.Y * 0.5)
end

-- ─── Viewport resize handler ──────────────────────────────────────────────

function Window:_OnViewportChanged(vp: Vector2)
    if self._destroyed then return end
    if not vp or vp.X <= 0 or vp.Y <= 0 then return end

    local oldVP = self._lastViewport or vp

    -- 1. MainFrame: clamp size & remap position proportionally
    if self.MainFrame and self.MainFrame.Parent then
        local topLeft, bottomRight = GuiService:GetGuiInset()
        local usableH = vp.Y - topLeft.Y - bottomRight.Y

        -- If not minimized or mini-icon, clamp size if viewport shrunk below current window size
        if not self.IsMinimized and not self.IsMiniIcon then
            local maxW = math.max(self._resizeMinSize.X, vp.X - SPAWN_MARGIN_H * 2)
            local maxH = math.max(self._resizeMinSize.Y, usableH - SPAWN_MARGIN_V * 2)

            local curW = self.MainFrame.AbsoluteSize.X
            local curH = self.MainFrame.AbsoluteSize.Y

            if curW > maxW or curH > maxH then
                local clampedW = math.clamp(curW, self._resizeMinSize.X, maxW)
                local clampedH = math.clamp(curH, self._resizeMinSize.Y, maxH)
                self.MainFrame.Size = UDim2.fromOffset(clampedW, clampedH)
                self._originalSize  = UDim2.fromOffset(clampedW, clampedH)
            end
        end

        -- Remap MainFrame position proportionally relative to screen edges
        if oldVP.X > 0 and oldVP.Y > 0 and (oldVP.X ~= vp.X or oldVP.Y ~= vp.Y) then
            self.MainFrame.Position = self:_RemapPositionToViewport(self.MainFrame, oldVP, vp)
        else
            self.MainFrame.Position = self:_ClampToScreen(
                self.MainFrame,
                self.MainFrame.Position.X.Offset,
                self.MainFrame.Position.Y.Offset
            )
        end
    end

    -- 2. MiniIconFrame: remap position proportionally so it stays at the corner/edge
    if self._miniIconFrame and self._miniIconFrame.Parent then
        if oldVP.X > 0 and oldVP.Y > 0 and (oldVP.X ~= vp.X or oldVP.Y ~= vp.Y) then
            self._miniIconFrame.Position = self:_RemapPositionToViewport(self._miniIconFrame, oldVP, vp)
        else
            self._miniIconFrame.Position = self:_ClampToScreen(
                self._miniIconFrame,
                self._miniIconFrame.Position.X.Offset,
                self._miniIconFrame.Position.Y.Offset
            )
        end
    end

    self._lastViewport = vp
end

-- ─── Focus ────────────────────────────────────────────────────────────────

-- Raise this Window above all other Delirium windows by assigning the next
-- monotonic ZIndex to MainFrame. With ZIndexBehavior = Sibling this is all
-- that is required — children inherit the higher base and render on top.
function Window:_Focus()
    if self._destroyed then return end
    local z = _nextFocusZ()
    self.MainFrame.ZIndex = z
    -- Keep the overlay above this window's MainFrame so popups always render
    -- above window content but below other windows when they gain focus.
    if self.Overlay then
        self.Overlay.ZIndex = z + 1000
    end
end

-- ─── Dragging — MainFrame ──────────────────────────────────────────────────

function Window:_EnableDragging()
    local dragStart, startPos
    local activeDragTouch = nil  -- P2: touch input object for the active drag gesture

    -- Wire to DragZone TextButton (not TitleBar Frame) so touch is consumed
    -- by the GUI system and does not also rotate the game camera.
    -- DRAG_EXCLUSION guard is no longer needed here because DragZone already
    -- covers only the non-button portion of the TitleBar.
    self._maid:GiveTask(self._dragZone.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        -- Block drag while a resize gesture is active.
        if self._isResizing then return end
        -- P2: Multi-touch safety — ignore new touches while a drag gesture is already
        -- active. Without this guard a second finger on DragZone overwrites dragStart/
        -- startPos, corrupting the in-flight gesture for the first finger.
        if input.UserInputType == Enum.UserInputType.Touch and activeDragTouch ~= nil then
            return
        end
        -- Focus: clicking/dragging the titlebar raises this window.
        self:_Focus()
        -- Stage 1: pending — record origin, wait for deadzone crossing in InputChanged.
        -- _isDragging stays false until the threshold is exceeded, so a tap that
        -- releases before moving DRAG_THRESHOLD_* px never moves the window.
        self._dragPending = true
        self._isDragging  = false
        dragStart         = input.Position
        startPos          = self.MainFrame.Position
        -- P2: Record which touch started this drag so unrelated touches are ignored.
        activeDragTouch = (input.UserInputType == Enum.UserInputType.Touch) and input or nil
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not self._dragPending and not self._isDragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        -- P2: Touch identity check — only track the touch that started this drag.
        -- Unrelated second-finger movements are silently ignored so they cannot
        -- corrupt the in-flight drag position or prematurely commit the gesture.
        if input.UserInputType == Enum.UserInputType.Touch and input ~= activeDragTouch then
            return
        end

        local delta   = input.Position - dragStart
        local isTouch = (input.UserInputType == Enum.UserInputType.Touch)

        -- Stage 2: commit — promote pending → active once deadzone is crossed.
        if self._dragPending then
            local threshold = isTouch and InputAdapter.DRAG_THRESHOLD_TOUCH or InputAdapter.DRAG_THRESHOLD_MOUSE
            if delta.Magnitude < threshold then return end
            self._dragPending = false
            self._isDragging  = true
        end

        local newPos = self:_ClampToScreen(
            self.MainFrame,
            startPos.X.Offset + delta.X,
            startPos.Y.Offset + delta.Y
        )
        -- Direct assignment: zero tween overhead, zero latency, frame-perfect.
        -- Tween-per-InputChanged stacked hundreds of 0.04s tweens at 60fps (BUG-04);
        -- direct assign eliminates the AnimationEngine round-trip entirely.
        self.MainFrame.Position = newPos
    end))

    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Mouse release always ends drag.
            self._isDragging  = false
            self._dragPending = false
            activeDragTouch   = nil
        elseif input.UserInputType == Enum.UserInputType.Touch then
            -- P2: Only reset drag state when the specific touch that started it ends.
            -- A different (unrelated) touch ending must not cancel an active drag gesture.
            if input == activeDragTouch then
                self._isDragging  = false
                self._dragPending = false
                activeDragTouch   = nil
            end
        end
    end))
end

-- ─── Dragging — MiniIconFrame ──────────────────────────────────────────────

function Window:_EnableMiniIconDragging()
    -- P2: Thresholds from InputAdapter (centralized).
    -- Mouse uses a smaller deadzone (pixel-precise); touch uses a larger one
    -- (imprecise finger contact). Old code applied the mouse threshold (5px)
    -- to both input types, making touch drag too sensitive.
    local dragging        = false
    local dragStart, startPos
    local activeMiniTouch = nil  -- P2: touch identity for the active mini-icon drag

    -- Wire to hitbox, NOT frame — the TextButton on top intercepts all InputBegan
    -- events before they reach the parent Frame, so frame.InputBegan never fires.
    self._maid:GiveTask(self._miniIconHitbox.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        -- P2: Ignore new touches while a drag is already active.
        if input.UserInputType == Enum.UserInputType.Touch and dragging then
            return
        end
        dragging            = true
        self._miniDragMoved = false
        dragStart           = input.Position
        startPos            = self._miniIconFrame.Position
        activeMiniTouch     = (input.UserInputType == Enum.UserInputType.Touch) and input or nil
    end))

    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        -- P2: Touch identity check — only track the touch that started this drag.
        if input.UserInputType == Enum.UserInputType.Touch and input ~= activeMiniTouch then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta     = input.Position - dragStart
            local threshold = (input.UserInputType == Enum.UserInputType.Touch)
                and InputAdapter.DRAG_THRESHOLD_TOUCH
                or  InputAdapter.DRAG_THRESHOLD_MOUSE
            if delta.Magnitude > threshold then
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging        = false
            activeMiniTouch = nil
        elseif input.UserInputType == Enum.UserInputType.Touch then
            -- P2: Only reset if this is the active mini-icon drag touch.
            if input == activeMiniTouch then
                dragging        = false
                activeMiniTouch = nil
            end
        end
    end))
end

-- ─── Resize handle (bottom-right corner) ──────────────────────────────────

function Window:_EnableResizing()
    -- Build a transparent input region at the bottom-right corner.
    -- Visibility is gated by self._isResizable; the connections are wired once
    -- at construction time so SetResizable(true/false) never creates duplicates.
    local handle = ComponentHelper.Create("TextButton", {
        Name                   = "ResizeHandle",
        Size                   = UDim2.fromOffset(RESIZE_HANDLE_SIZE, RESIZE_HANDLE_SIZE),
        Position               = UDim2.new(1, -RESIZE_HANDLE_SIZE, 1, -RESIZE_HANDLE_SIZE),
        AnchorPoint            = Vector2.new(0, 0),
        BackgroundTransparency = 1,
        Text                   = "",
        AutoButtonColor        = false,
        ZIndex                 = 15,
        Visible                = self._isResizable,
        Parent                 = self.MainFrame,
    })
    -- Subtle corner glyph — a barely-visible hint of the resize grip.
    ComponentHelper.Create("TextLabel", {
        Name                   = "ResizeGlyph",
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text                   = "\u{22F1}",   -- DIAGONAL ELLIPSIS ⋱
        Font                   = Enum.Font.GothamBold,
        TextSize               = 11,
        TextColor3             = ThemeEngine.GetToken("SubText"),
        TextXAlignment         = Enum.TextXAlignment.Right,
        TextYAlignment         = Enum.TextYAlignment.Bottom,
        ZIndex                 = 16,
        Parent                 = handle,
    })
    self._resizeHandle = handle

    -- ── Per-gesture state ──────────────────────────────────────────────────
    local resizing          = false
    local resizeStart       = nil  -- Vector3 input.Position at gesture start
    local startSize         = nil  -- Vector2 frame AbsoluteSize at gesture start
    local startPos          = nil  -- UDim2  frame Position at gesture start
    local startTopLeft      = nil  -- Vector2 screen-space top-left corner (stays fixed)
    local activeResizeTouch = nil  -- P2: touch input object for the active resize gesture

    -- InputBegan on handle → begin gesture
    self._maid:GiveTask(handle.InputBegan:Connect(function(input)
        if not self._isResizable then return end
        if self._isDragging      then return end
        if self.IsMinimized      then return end
        if self.IsMiniIcon       then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        -- P2: Ignore additional touches while a resize is already in progress.
        if input.UserInputType == Enum.UserInputType.Touch and resizing then
            return
        end

        local cam = workspace.CurrentCamera
        local vp  = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)

        resizing          = true
        self._isResizing  = true
        resizeStart       = input.Position
        startPos          = self.MainFrame.Position
        startSize         = self.MainFrame.AbsoluteSize
        -- P2: Record which touch started the resize gesture.
        activeResizeTouch = (input.UserInputType == Enum.UserInputType.Touch) and input or nil

        -- Top-left corner in screen space; stays fixed during a bottom-right resize.
        -- MainFrame AnchorPoint = (0.5, 0.5), scale position = (0.5, 0.5).
        -- Center = (vp.X*0.5 + pos.X.Offset, vp.Y*0.5 + pos.Y.Offset)
        startTopLeft = Vector2.new(
            vp.X * 0.5 + startPos.X.Offset - startSize.X * 0.5,
            vp.Y * 0.5 + startPos.Y.Offset - startSize.Y * 0.5
        )
    end))

    -- InputChanged (global) → apply resize once deadzone threshold is crossed
    self._maid:GiveTask(UserInputService.InputChanged:Connect(function(input)
        if not resizing then return end
        -- Guard: don't fight Minimize/MiniIconify tweens — both touch MainFrame.Size.
        if self.IsMinimized or self.IsMiniIcon then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end
        -- P2: Touch identity check — only track the touch that started this resize.
        -- An unrelated second finger must not drive the resize or corrupt its state.
        if input.UserInputType == Enum.UserInputType.Touch and input ~= activeResizeTouch then
            return
        end

        local delta     = input.Position - resizeStart
        local isTouch   = (input.UserInputType == Enum.UserInputType.Touch)
        local threshold = isTouch and RESIZE_THRESHOLD_TOUCH or RESIZE_THRESHOLD_MOUSE

        -- Deadzone: absorb tiny accidental movements without starting a resize.
        if delta.Magnitude < threshold then return end

        local cam = workspace.CurrentCamera
        local vp  = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)

        -- Max size: bottom-right corner must not exceed the viewport boundary.
        local maxW = math.max(self._resizeMinSize.X, vp.X - startTopLeft.X)
        local maxH = math.max(self._resizeMinSize.Y, vp.Y - startTopLeft.Y)

        local newW = math.clamp(startSize.X + delta.X, self._resizeMinSize.X, maxW)
        local newH = math.clamp(startSize.Y + delta.Y, self._resizeMinSize.Y, maxH)

        -- Position adjustment keeps top-left corner fixed.
        -- With AnchorPoint(0.5,0.5): new_offset = old_offset + (new_size - old_size) / 2
        local newOffX = startPos.X.Offset + (newW - startSize.X) * 0.5
        local newOffY = startPos.Y.Offset + (newH - startSize.Y) * 0.5

        -- Direct assignment — no tween. Responsive, zero-latency resize.
        self.MainFrame.Size     = UDim2.fromOffset(newW, newH)
        self.MainFrame.Position = UDim2.new(0.5, newOffX, 0.5, newOffY)
    end))

    -- InputEnded (global) → commit resize, release lock
    self._maid:GiveTask(UserInputService.InputEnded:Connect(function(input)
        if not resizing then return end
        -- P2: Only commit when the input that started the resize ends.
        -- Mouse: MouseButton1 always matches. Touch: only the tracked touch identity.
        local isActiveEnd = (input.UserInputType == Enum.UserInputType.MouseButton1)
            or (input.UserInputType == Enum.UserInputType.Touch and input == activeResizeTouch)
        if not isActiveEnd then return end

        resizing          = false
        self._isResizing  = false
        activeResizeTouch = nil

        -- Commit: update _originalSize so Minimize → Restore uses the resized dimensions.
        local sz = self.MainFrame.AbsoluteSize
        self._originalSize = UDim2.fromOffset(sz.X, sz.Y)
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

-- Direct section creation helper (no explicit tab required).
-- Ideal for compact floating windows, overlays, or simple single-page panels.
function Window:CreateSection(title: string)
    if not self._defaultTab then
        self._defaultTab = self:CreateTab({ Name = "Main" })
        if self._isCompact and self._defaultTab.NavButton then
            self._defaultTab.NavButton.Visible = false
        end
    end
    return self._defaultTab:CreateSection(title)
end
Window.AddSection = Window.CreateSection

-- Register a callback to execute when this session is fully unloaded.
-- Delegates to UnloadService so it fires even if the window is closed first.
function Window:OnUnload(fn: () -> ())
    if type(fn) == "function" then
        UnloadService.Register(fn)
    end
end
-- Alias
Window.OnClose = Window.OnUnload

-- SelectTab: the single authoritative source of tab activation.
-- Uses Tab:_ApplyActive() (private visual-only method) so there is no
-- circular call back into SelectTab. Skips destroyed tab entries.
function Window:SelectTab(targetTab)
    for _, tab in ipairs(self._tabs) do
        if not tab._destroyed then
            tab:_ApplyActive(tab == targetTab)
        end
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

    -- Terminate any in-flight drag or resize gesture so they don't fight
    -- the minimize tween (drag moves Position; resize writes Size directly).
    self._isDragging = false
    self._isResizing = false
    if self._resizeHandle then
        self._resizeHandle.Visible = false
    end

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

    -- Close any open dropdown popup; it floats on the overlay and would
    -- remain visible over the collapsed window otherwise.
    Dropdown.CloseActive()
end
function Window:Restore()
    if not self.IsMinimized then return end
    self.IsMinimized = false

    self.ContentContainer.Visible = true
    if self._resizeHandle then
        self._resizeHandle.Visible = self._isResizable
    end

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
    local _miniIconHideDelay = task.delay(TweenHelper.FastInfo.Time + 0.02, function()
        if not self._destroyed then
            self.MainFrame.Visible = false
        end
    end)
    self._maid:GiveTask(function() task.cancel(_miniIconHideDelay) end)

    -- Show MiniIconFrame: fade + spring pop
    self._miniIconFrame.BackgroundTransparency = 1
    self._miniIconFrame.Visible                = true
    AnimationEngine.FadeIn(self._miniIconFrame, 1, TweenHelper.DefaultInfo)
    AnimationEngine.Pop(self._miniIconFrame, 0.80, AnimationEngine.Preset.Spring)

    if self._config.OnMiniIcon then
        task.spawn(self._config.OnMiniIcon)
    end

    -- Close any open dropdown popup before shrinking to the mini-icon chip.
    Dropdown.CloseActive()
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
    self.MainFrame.GroupTransparency      = 1
    self.MainFrame.BackgroundTransparency = 1
    self.MainFrame.Size                   = self._originalSize
    self.MainFrame.Visible                = true
    self:_Focus()    -- restored window should be above all others
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
    if self._config.OnUnload then
        task.spawn(self._config.OnUnload)
    end

    -- Check if window close should trigger a full script unload
    local isMain = (self._runtime and #self._runtime._windows <= 1)
    if self._config.UnloadOnClose == true or (self._config.UnloadOnClose ~= false and isMain) then
        UnloadService.Unload({ Duration = 2.5 })
        return
    end

    AnimationEngine.CloseWindow(self.MainFrame, function()
        self:Destroy()
    end, TweenHelper.FastInfo)
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
    -- Close any open dropdown popup before hiding the window.
    Dropdown.CloseActive()
    TweenHelper.Tween(self.MainFrame, TweenHelper.DefaultInfo, {
        BackgroundTransparency = 1,
    })
    task.delay(TweenHelper.DefaultInfo.Time, function()
        if not self.IsOpen then
            self.MainFrame.Visible = false
        end
    end)
end

-- ─── Resize public API ─────────────────────────────────────────────────────

-- Programmatically resize the Window, respecting min/viewport constraints.
-- Top-left corner stays fixed (same behavior as user-driven resize).
function Window:SetSize(size: Vector2)
    assert(typeof(size) == "Vector2", "Window:SetSize expects a Vector2")
    local cam = workspace.CurrentCamera
    local vp  = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)

    local curPos  = self.MainFrame.Position
    local curSize = self.MainFrame.AbsoluteSize

    local topLeftX = vp.X * 0.5 + curPos.X.Offset - curSize.X * 0.5
    local topLeftY = vp.Y * 0.5 + curPos.Y.Offset - curSize.Y * 0.5

    local maxW = math.max(self._resizeMinSize.X, vp.X - topLeftX)
    local maxH = math.max(self._resizeMinSize.Y, vp.Y - topLeftY)

    local newW = math.clamp(size.X, self._resizeMinSize.X, maxW)
    local newH = math.clamp(size.Y, self._resizeMinSize.Y, maxH)

    local newOffX = curPos.X.Offset + (newW - curSize.X) * 0.5
    local newOffY = curPos.Y.Offset + (newH - curSize.Y) * 0.5

    self.MainFrame.Size     = UDim2.fromOffset(newW, newH)
    self.MainFrame.Position = UDim2.new(0.5, newOffX, 0.5, newOffY)
    self._originalSize      = UDim2.fromOffset(newW, newH)
end

-- Return the current Window size as Vector2.
function Window:GetSize(): Vector2
    local sz = self.MainFrame.AbsoluteSize
    return Vector2.new(sz.X, sz.Y)
end

-- Set the Window's center position in absolute screen-space pixels.
-- Clamped through _ClampToScreen — same inset/boundary rules as drag.
-- Example: window:SetPosition(Vector2.new(200, 300))
function Window:SetPosition(pos: Vector2)
    assert(typeof(pos) == "Vector2", "Window:SetPosition expects a Vector2")
    local cam    = workspace.CurrentCamera
    local vp     = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
    -- Convert absolute screen-space coords to scale(0.5) offsets.
    local rawOffX = pos.X - vp.X * 0.5
    local rawOffY = pos.Y - vp.Y * 0.5
    self.MainFrame.Position = self:_ClampToScreen(self.MainFrame, rawOffX, rawOffY)
end

-- Return the Window's current center position in absolute screen-space pixels.
function Window:GetPosition(): Vector2
    local cam  = workspace.CurrentCamera
    local vp   = (cam and cam.ViewportSize) or Vector2.new(1920, 1080)
    local pos  = self.MainFrame.Position
    return Vector2.new(
        vp.X * 0.5 + pos.X.Offset,
        vp.Y * 0.5 + pos.Y.Offset
    )
end

-- Enable or disable user resize interaction.
-- Safe to call multiple times. Does NOT create or destroy connections.
function Window:SetResizable(enabled: boolean)
    self._isResizable = enabled == true
    if self._resizeHandle then
        -- Stay hidden if the window is currently minimized.
        self._resizeHandle.Visible = self._isResizable and not self.IsMinimized
    end
end

-- Return whether user resize is currently enabled.
function Window:IsResizable(): boolean
    return self._isResizable
end

-- Return a human-readable tree representation of all tabs, sections, and components.
function Window:GetDebugTree(): string
    local lines = {}
    table.insert(lines, string.format("Window[%s] (DebugMode=%s)", self.Name, tostring(self._debugMode)))
    for _, tab in ipairs(self._tabs) do
        table.insert(lines, string.format("  Tab[%s] (DebugMode=%s)", tab.Name, tostring(tab._debugMode)))
        for _, section in ipairs(tab._sections) do
            table.insert(lines, string.format("    Section[%s]", section.Title))
            for _, handle in ipairs(section._handles) do
                local debugId = handle._debugId or "none"
                table.insert(lines, string.format("      Component (%s)", debugId))
            end
        end
    end
    return table.concat(lines, "\n")
end

-- ─── Destroy (idempotent) ──────────────────────────────────────────────────

function Window:Destroy()
    if self._destroyed then return end
    self._destroyed = true

    -- Remove from runtime tracking first to prevent double-destroy during unload cascade
    if self._runtime and type(self._runtime.UnregisterWindow) == "function" then
        pcall(function() self._runtime:UnregisterWindow(self) end)
    end

    -- Snapshot first: Tab:Destroy() removes itself from self._tabs, which
    -- would otherwise shift entries and make ipairs skip tabs.
    local tabs = { table.unpack(self._tabs) }
    for _, tab in ipairs(tabs) do
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

end

-- ── Components.Button ─────────────────────────────────────
_Delirium_modules["Components.Button"] = function()
-- Components/Button.lua
-- Signature feature: built-in loading fill animation (left → right) on click.
-- Wraps async callbacks automatically: starts loading on click, success state on return.
-- local Root          = script.Parent.Parent
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local Signal          = _Delirium_require("Utilities.Signal")
local VariantEngine   = _Delirium_require("Core.VariantEngine")

local Button = {}

local LOADING_FILL_INFO   = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local SUCCESS_HOLD        = 0.6  -- seconds success color is shown before reset
local SUCCESS_FADE_INFO   = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function Button.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style    = VariantEngine.Resolve("Button", config.Variant)
    local callback = config.Callback or function() end
    local hasDesc  = config.Description ~= nil and config.Description ~= ""
    local baseH    = hasDesc and style.HeightDesc or style.Height

    local enabled    = true
    local loading    = false
    local success    = false
    local hovered    = false
    local _destroyed = false
    local _visualGen = 0

    -- ─── Frames ────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "ButtonComponent",
        Size             = UDim2.new(1, 0, 0, baseH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, style.Corner)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, style.PadTop, style.PadBot, style.PadL, style.PadR)

    -- Debug identity: stored always, attribute set on frame when debugId is present.
    if debugId then
        frame:SetAttribute("DeliriumDebugId", debugId)
    end

    -- Loading fill overlay (positioned with negative padding offset so it fits the full button shape)
    local loadFill = ComponentHelper.Create("Frame", {
        Name                   = "LoadFill",
        Position               = UDim2.new(0, -style.PadL, 0, -style.PadTop),
        Size                   = UDim2.new(0, 0, 1, style.PadTop + style.PadBot),
        BackgroundColor3       = ThemeEngine.GetToken("AccentDim"),
        BackgroundTransparency = 1,
        BorderSizePixel        = 0,
        ZIndex                 = 1,
        Parent                 = frame,
    })
    ComponentHelper.AddCorner(loadFill, style.Corner)

    -- Title label
    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(1, -30, hasDesc and 0.5 or 1, 0),
        BackgroundTransparency = 1,
        Text                   = config.Title or config.Name or config.Text or "Button",
        TextColor3             = ThemeEngine.GetToken("Text"),
        TextSize               = 14,
        Font                   = Enum.Font.GothamMedium,
        TextXAlignment         = Enum.TextXAlignment.Left,
        ZIndex                 = 3,
        Parent                 = frame,
    })

    local descLabel
    if hasDesc then
        descLabel = ComponentHelper.Create("TextLabel", {
            Name                   = "Description",
            Size                   = UDim2.new(1, -30, 0.5, 0),
            Position               = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Text                   = config.Description,
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextSize               = 11,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            ZIndex                 = 3,
            Parent                 = frame,
        })
    end

    local icon = ComponentHelper.Create("ImageLabel", {
        Name                   = "Icon",
        Size                   = UDim2.new(0, 16, 0, 16),
        Position               = UDim2.new(1, -16, 0.5, -8),
        BackgroundTransparency = 1,
        Image                  = "rbxassetid://10709791437",
        ImageColor3            = ThemeEngine.GetToken("SubText"),
        ZIndex                 = 3,
        Parent                 = frame,
    })

    local triggerBtn = ComponentHelper.Create("TextButton", {
        Size                   = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        AutoButtonColor        = false,
        Text                   = "",
        ZIndex                 = 5,
        Parent                 = frame,
    })

    -- ─── Signals ───────────────────────────────────────────────────────────

    local OnClicked = Signal.new()

    -- ─── Loading & Success animation ───────────────────────────────────────

    local function playLoading(): boolean
        _visualGen += 1
        local myGen = _visualGen

        loading = true
        success = false

        -- Invalidate and cancel any running fill tweens
        TweenHelper.Cancel(loadFill)

        -- Keep base frame consistent with current hover state
        TweenHelper.Cancel(frame, "press")
        frame.Size = UDim2.new(1, 0, 0, baseH)
        frame.BackgroundColor3 = hovered
            and ThemeEngine.GetToken("SurfaceHover")
            or  ThemeEngine.GetToken("Surface")

        -- Restore visibility and reset size before animating
        loadFill.BackgroundColor3       = ThemeEngine.GetToken("AccentDim")
        loadFill.BackgroundTransparency = 0.55
        loadFill.Size                   = UDim2.new(0, 0, 1, style.PadTop + style.PadBot)

        -- Fill left → right across full padded button width
        local fillTween = TweenHelper.Tween(loadFill, LOADING_FILL_INFO, {
            Size = UDim2.new(1, style.PadL + style.PadR, 1, style.PadTop + style.PadBot)
        }, "fill")

        if fillTween then
            fillTween.Completed:Wait()
        else
            task.wait(LOADING_FILL_INFO.Time)
        end

        return myGen == _visualGen and not _destroyed
    end

    local function playSuccess(capturedGen: number?)
        if capturedGen and capturedGen ~= _visualGen then return end
        if _destroyed or not frame.Parent then
            loading = false
            success = false
            return
        end

        local myGen = _visualGen
        loading = false
        success = true

        -- Maintain frame background matching hover state
        TweenHelper.Cancel(frame, "press")
        frame.Size = UDim2.new(1, 0, 0, baseH)
        frame.BackgroundColor3 = hovered
            and ThemeEngine.GetToken("SurfaceHover")
            or  ThemeEngine.GetToken("Surface")

        -- Flash success color (Positive / Green)
        local successTween = TweenHelper.Tween(loadFill, SUCCESS_FADE_INFO, {
            BackgroundColor3       = ThemeEngine.GetToken("Positive"),
            BackgroundTransparency = 0.4,
        }, "fill")

        if successTween then
            successTween.Completed:Wait()
        else
            task.wait(SUCCESS_FADE_INFO.Time)
        end

        if myGen ~= _visualGen or _destroyed or not frame.Parent then return end

        task.wait(SUCCESS_HOLD)

        if myGen ~= _visualGen or _destroyed or not frame.Parent then return end

        -- Fade the fill out smoothly revealing the already-matching frame surface underneath
        local fadeTween = TweenHelper.Tween(loadFill, SUCCESS_FADE_INFO, {
            BackgroundTransparency = 1,
        }, "fill")

        if fadeTween then
            fadeTween.Completed:Wait()
        else
            task.wait(SUCCESS_FADE_INFO.Time)
        end

        if myGen ~= _visualGen or _destroyed or not frame.Parent then return end

        -- Reset loadFill geometry & tokens while fully transparent (BackgroundTransparency = 1)
        loadFill.BackgroundTransparency = 1
        loadFill.Size                   = UDim2.new(0, 0, 1, style.PadTop + style.PadBot)
        loadFill.BackgroundColor3       = ThemeEngine.GetToken("AccentDim")

        success = false
        loading = false

        if enabled then
            frame.BackgroundColor3 = hovered
                and ThemeEngine.GetToken("SurfaceHover")
                or  ThemeEngine.GetToken("Surface")
        end
    end

    -- ─── Hover & press animations ──────────────────────────────────────────

    -- Store all input connections so they're cleaned in api:Destroy()
    local inputConns = {}

    table.insert(inputConns, triggerBtn.MouseEnter:Connect(function()
        hovered = true
        if not enabled then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        }, "hover")
    end))

    table.insert(inputConns, triggerBtn.MouseLeave:Connect(function()
        hovered = false
        if not enabled then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        }, "hover")
    end))

    -- Use InputBegan/InputEnded instead of MouseButton1Down/Up so touch
    -- InputEnded fires even when the finger slides off the button.
    table.insert(inputConns, triggerBtn.InputBegan:Connect(function(input)
        if not enabled or loading or success then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            Size = UDim2.new(1, -4, 0, baseH - 2),
        }, "press")
    end))

    table.insert(inputConns, triggerBtn.InputEnded:Connect(function(input)
        if not enabled then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            Size = UDim2.new(1, 0, 0, baseH),
        }, "press")
    end))

    table.insert(inputConns, triggerBtn.MouseButton1Click:Connect(function()
        if not enabled or loading or success then return end

        OnClicked:Fire()

        -- Wrap callback with loading animation.
        -- pcall ensures playSuccess() always runs — even if callback throws.
        -- Without this, a runtime error leaves loading=true and bricks the button forever.
        task.spawn(function()
            local gen = _visualGen + 1
            local okLoading = playLoading()
            if not okLoading or gen ~= _visualGen or _destroyed then return end

            local ok, err = pcall(callback)
            if not ok then
                warn("[Delirium] Button callback error: " .. tostring(err))
            end

            if gen == _visualGen and not _destroyed then
                playSuccess(gen)
            end
        end)
    end))

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        if not loading and not success then
            frame.BackgroundColor3  = hovered and tokens.SurfaceHover or tokens.Surface
            loadFill.BackgroundColor3 = tokens.AccentDim
        elseif success then
            loadFill.BackgroundColor3 = tokens.Positive
        elseif loading then
            loadFill.BackgroundColor3 = tokens.AccentDim
        end

        stroke.Color          = tokens.Border
        titleLabel.TextColor3 = enabled and tokens.Text or tokens.DisabledText
        icon.ImageColor3      = enabled and tokens.SubText or tokens.DisabledText
        if descLabel then
            descLabel.TextColor3 = tokens.SubText
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = {}

    function api:Enable()
        enabled = true
        triggerBtn.Active = true
        if not loading and not success then
            TweenHelper.Tween(frame, TweenHelper.FastInfo, {
                BackgroundColor3 = hovered and ThemeEngine.GetToken("SurfaceHover") or ThemeEngine.GetToken("Surface"),
            }, "hover")
        end
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
        _visualGen += 1
        loading = false
        success = false
        TweenHelper.Cancel(loadFill)
        TweenHelper.Cancel(frame, "hover")
        TweenHelper.Cancel(frame, "press")
        loadFill.BackgroundTransparency = 1
        loadFill.Size = UDim2.new(0, 0, 1, style.PadTop + style.PadBot)
        frame.Size = UDim2.new(1, 0, 0, baseH)
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        }, "hover")
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
            task.spawn(function()
                playLoading()
            end)
        else
            task.spawn(function()
                playSuccess()
            end)
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
        if _destroyed then return end
        _destroyed = true
        _visualGen += 1
        themeDisconnect()
        TweenHelper.Cancel(loadFill)
        TweenHelper.Cancel(frame)
        for _, conn in ipairs(inputConns) do
            conn:Disconnect()
        end
        table.clear(inputConns)
        OnClicked:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnClicked = OnClicked
    api._debugId  = debugId or nil

    return api
end

return Button

end

-- ── Components.ColorPicker ────────────────────────────────
_Delirium_modules["Components.ColorPicker"] = function()
-- Components/ColorPicker.lua
-- Modern expandable HSV + Alpha color picker (matching Rayfield Gen2 design).
-- Features: SV gradient square + Hue pill strip + Alpha pill strip + Color preview + Hex & Alpha pills.

local UserInputService = game:GetService("UserInputService")
-- local Root             = script.Parent.Parent
local ComponentHelper  = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper      = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine      = _Delirium_require("Core.ThemeEngine")
local Signal           = _Delirium_require("Utilities.Signal")
local InputAdapter     = _Delirium_require("Core.InputAdapter")
local VariantEngine    = _Delirium_require("Core.VariantEngine")

local ColorPicker = {}

local function toHSV(c: Color3): (number, number, number)
    return Color3.toHSV(c)
end

local function toHex(c: Color3): string
    return string.format("#%02X%02X%02X",
        math.round(c.R * 255),
        math.round(c.G * 255),
        math.round(c.B * 255))
end

local function applyHueGradient(uiGrad: UIGradient)
    local seq = {}
    for i = 0, 6 do
        table.insert(seq, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
    end
    uiGrad.Color = ColorSequence.new(seq)
end

local GestureState = {
    IDLE    = "IDLE",
    PENDING = "PENDING",
    SV      = "SV",
    HUE     = "HUE",
    ALPHA   = "ALPHA",
    YIELDED = "YIELDED",
}

function ColorPicker.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style        = VariantEngine.Resolve("ColorPicker", config.Variant)
    local title        = config.Title or config.Name or config.Text or "Color"
    local desc         = config.Description or ""
    local currentColor = config.Default or Color3.fromRGB(100, 180, 255)
    local alpha        = type(config.Alpha) == "number" and math.clamp(config.Alpha, 0, 1) or 1
    local enabled      = true
    local _destroyed   = false
    local isOpen       = false

    local h, s, v = toHSV(currentColor)

    local OnChanged = Signal.new()

    local hasDesc  = desc ~= ""
    local baseRowH = hasDesc and (style.RowH + 6) or style.RowH

    -- ─── Row (collapsed state container) ──────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "ColorPickerRow",
        Size             = UDim2.new(1, 0, 0, baseRowH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, style.Corner)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    if debugId then
        Row:SetAttribute("DeliriumDebugId", debugId)
    end

    local LabelContainer = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.7, 0, 0, baseRowH),
        BackgroundTransparency = 1,
        Parent             = Row,
    })
    ComponentHelper.AddPadding(LabelContainer, 6, 6, 12, 0)

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.new(1, 0, 0, hasDesc and 16 or 18),
        Position           = hasDesc and UDim2.new(0, 0, 0, 4) or UDim2.new(0, 0, 0.5, -9),
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 13,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Parent             = LabelContainer,
    })

    local descLabel
    if hasDesc then
        descLabel = ComponentHelper.Create("TextLabel", {
            Position           = UDim2.new(0, 0, 0, 24),
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

    -- Small Swatch box on right (fitted for collapsed state)
    local Swatch = ComponentHelper.Create("TextButton", {
        Position           = UDim2.new(1, -(style.SwatchW + 12), 0, (baseRowH - style.SwatchH) / 2),
        Size               = UDim2.new(0, style.SwatchW, 0, style.SwatchH),
        BackgroundColor3   = currentColor,
        BackgroundTransparency = 1 - alpha,
        Text               = "",
        AutoButtonColor    = false,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(Swatch, 6)
    ComponentHelper.AddStroke(Swatch, ThemeEngine.GetToken("Border"), 1)

    -- ─── Expanded picker container ─────────────────────────────────────────

    local EXPANDED_H = baseRowH + 138

    local PickerContainer = ComponentHelper.Create("Frame", {
        Name               = "PickerContainer",
        Position           = UDim2.new(0, 12, 0, baseRowH + 6),
        Size               = UDim2.new(1, -24, 0, 124),
        BackgroundTransparency = 1,
        Visible            = false,
        Parent             = Row,
    })

    -- 1. Saturation/Value Square (Left)
    local SVSquare = ComponentHelper.Create("Frame", {
        Name               = "SVSquare",
        Position           = UDim2.new(0, 0, 0, 0),
        Size               = UDim2.new(0.48, -20, 1, 0),
        BackgroundColor3   = Color3.fromHSV(h, 1, 1),
        BorderSizePixel    = 0,
        Parent             = PickerContainer,
    })
    ComponentHelper.AddCorner(SVSquare, 8)

    local satGrad = ComponentHelper.Create("UIGradient", {
        Color  = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
        }),
        Parent = SVSquare,
    })

    local valOverlay = ComponentHelper.Create("Frame", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundColor3   = Color3.new(0, 0, 0),
        BackgroundTransparency = 0,
        BorderSizePixel    = 0,
        Parent             = SVSquare,
    })
    ComponentHelper.AddCorner(valOverlay, 8)
    ComponentHelper.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0, 0, 0)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Rotation = 90,
        Parent   = valOverlay,
    })

    local SVCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0, 16, 0, 16),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(s, 0, 1 - v, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = SVSquare,
    })
    ComponentHelper.AddCorner(SVCursor, 8)
    ComponentHelper.AddStroke(SVCursor, Color3.new(0, 0, 0), 1.5)

    -- 2. Hue Strip (Middle Left)
    local HueStrip = ComponentHelper.Create("Frame", {
        Name               = "HueStrip",
        Position           = UDim2.new(0.48, -14, 0, 0),
        Size               = UDim2.new(0, 14, 1, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        Parent             = PickerContainer,
    })
    ComponentHelper.AddCorner(HueStrip, 7)
    local hueGrad = ComponentHelper.Create("UIGradient", { Rotation = 90, Parent = HueStrip })
    applyHueGradient(hueGrad)

    local HueCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0, 22, 0, 10),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(0.5, 0, h, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = HueStrip,
    })
    ComponentHelper.AddCorner(HueCursor, 5)
    ComponentHelper.AddStroke(HueCursor, Color3.new(0, 0, 0), 1.5)

    -- 3. Alpha / Opacity Strip (Middle Right)
    local AlphaStrip = ComponentHelper.Create("Frame", {
        Name               = "AlphaStrip",
        Position           = UDim2.new(0.48, 8, 0, 0),
        Size               = UDim2.new(0, 14, 1, 0),
        BackgroundColor3   = currentColor,
        BorderSizePixel    = 0,
        Parent             = PickerContainer,
    })
    ComponentHelper.AddCorner(AlphaStrip, 7)

    local alphaGrad = ComponentHelper.Create("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0)),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Rotation = 90,
        Parent   = AlphaStrip,
    })

    local AlphaCursor = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0, 22, 0, 10),
        AnchorPoint        = Vector2.new(0.5, 0.5),
        Position           = UDim2.new(0.5, 0, 1 - alpha, 0),
        BackgroundColor3   = Color3.new(1, 1, 1),
        BorderSizePixel    = 0,
        ZIndex             = 5,
        Parent             = AlphaStrip,
    })
    ComponentHelper.AddCorner(AlphaCursor, 5)
    ComponentHelper.AddStroke(AlphaCursor, Color3.new(0, 0, 0), 1.5)

    -- 4. Color Preview Display (Right Top)
    local ColorPreviewBox = ComponentHelper.Create("Frame", {
        Name               = "ColorPreviewBox",
        Position           = UDim2.new(0.48, 30, 0, 0),
        Size               = UDim2.new(0.52, -30, 0, 76),
        BackgroundColor3   = currentColor,
        BackgroundTransparency = 1 - alpha,
        BorderSizePixel    = 0,
        Parent             = PickerContainer,
    })
    ComponentHelper.AddCorner(ColorPreviewBox, 10)
    local previewStroke = ComponentHelper.AddStroke(ColorPreviewBox, ThemeEngine.GetToken("Border"), 1)

    -- 5. Hex & Alpha Input Pills (Right Bottom)
    local PillsContainer = ComponentHelper.Create("Frame", {
        Position           = UDim2.new(0.48, 30, 0, 84),
        Size               = UDim2.new(0.52, -30, 0, 32),
        BackgroundTransparency = 1,
        Parent             = PickerContainer,
    })

    local HexPill = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.58, -3, 1, 0),
        Position           = UDim2.new(0, 0, 0, 0),
        BackgroundColor3   = ThemeEngine.GetToken("InputBackground"),
        BorderSizePixel    = 0,
        Parent             = PillsContainer,
    })
    ComponentHelper.AddCorner(HexPill, 6)
    local hexStroke = ComponentHelper.AddStroke(HexPill, ThemeEngine.GetToken("Border"), 1)

    local HexLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = toHex(currentColor),
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 11,
        Font               = Enum.Font.GothamMedium,
        Parent             = HexPill,
    })

    local AlphaPill = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.42, -3, 1, 0),
        Position           = UDim2.new(0.58, 3, 0, 0),
        BackgroundColor3   = ThemeEngine.GetToken("InputBackground"),
        BorderSizePixel    = 0,
        Parent             = PillsContainer,
    })
    ComponentHelper.AddCorner(AlphaPill, 6)
    local alphaStroke = ComponentHelper.AddStroke(AlphaPill, ThemeEngine.GetToken("Border"), 1)

    local AlphaLabel = ComponentHelper.Create("TextLabel", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = math.round(alpha * 100) .. "%",
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 11,
        Font               = Enum.Font.GothamMedium,
        Parent             = AlphaPill,
    })

    -- ─── Internal color update ─────────────────────────────────────────────

    local lastFireTime  = 0
    local FIRE_THROTTLE = 0.04

    local function rebuildColor(forceFire: boolean?)
        currentColor = Color3.fromHSV(h, s, v)
        Swatch.BackgroundColor3          = currentColor
        Swatch.BackgroundTransparency    = 1 - alpha
        ColorPreviewBox.BackgroundColor3 = currentColor
        ColorPreviewBox.BackgroundTransparency = 1 - alpha
        AlphaStrip.BackgroundColor3      = currentColor

        HexLabel.Text   = toHex(currentColor)
        AlphaLabel.Text = math.round(alpha * 100) .. "%"

        SVSquare.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
        satGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1)),
        })
        SVCursor.Position    = UDim2.new(s, 0, 1 - v, 0)
        HueCursor.Position   = UDim2.new(0.5, 0, h, 0)
        AlphaCursor.Position = UDim2.new(0.5, 0, 1 - alpha, 0)

        local now = os.clock()
        if forceFire or (now - lastFireTime >= FIRE_THROTTLE) then
            lastFireTime = now
            OnChanged:Fire(currentColor, alpha)
        end
    end

    -- ─── Unified gesture state machine ────────────────────────────────────

    local gestureState       = GestureState.IDLE
    local gestureStartX      = 0
    local gestureStartY      = 0
    local globalConns        = {}
    local activeGestureTouch = nil
    local pointerOwner       = {}

    local _pageCanvas = nil
    local function _getPageCanvas()
        if _pageCanvas and _pageCanvas.Parent then return _pageCanvas end
        local anc = Row.Parent
        while anc do
            if anc:IsA("ScrollingFrame") then
                _pageCanvas = anc
                return anc
            end
            anc = anc.Parent
        end
        return nil
    end

    local function _lockPageScroll()
        local pc = _getPageCanvas()
        if pc then pcall(function() pc.ScrollingEnabled = false end) end
    end

    local function _unlockPageScroll()
        local pc = _getPageCanvas()
        if pc then pcall(function() pc.ScrollingEnabled = true end) end
    end

    local function resetGesture()
        if gestureState == GestureState.SV or gestureState == GestureState.HUE or gestureState == GestureState.ALPHA then
            rebuildColor(true)
        end
        gestureState       = GestureState.IDLE
        activeGestureTouch = nil
        InputAdapter.ReleasePointer(pointerOwner)
        _unlockPageScroll()
    end

    local function applySV(pos: Vector3)
        local rel = Vector2.new(pos.X, pos.Y) - SVSquare.AbsolutePosition
        s = math.clamp(rel.X / SVSquare.AbsoluteSize.X, 0, 1)
        v = 1 - math.clamp(rel.Y / SVSquare.AbsoluteSize.Y, 0, 1)
        rebuildColor()
    end

    local function applyHue(pos: Vector3)
        local rel = Vector2.new(pos.X, pos.Y) - HueStrip.AbsolutePosition
        h = math.clamp(rel.Y / HueStrip.AbsoluteSize.Y, 0, 1)
        rebuildColor()
    end

    local function applyAlpha(pos: Vector3)
        local rel = Vector2.new(pos.X, pos.Y) - AlphaStrip.AbsolutePosition
        alpha = 1 - math.clamp(rel.Y / AlphaStrip.AbsoluteSize.Y, 0, 1)
        rebuildColor()
    end

    -- SVSquare listeners
    table.insert(globalConns, SVSquare.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not InputAdapter.ClaimPointer(pointerOwner) then return end
            gestureState = GestureState.SV
            applySV(input.Position)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            if gestureState == GestureState.IDLE then
                if InputAdapter.GetPointerOwner() ~= nil then return end
                gestureState       = GestureState.PENDING
                gestureStartX      = input.Position.X
                gestureStartY      = input.Position.Y
                activeGestureTouch = input
            end
        end
    end))

    -- HueStrip listeners
    table.insert(globalConns, HueStrip.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not InputAdapter.ClaimPointer(pointerOwner) then return end
            gestureState = GestureState.HUE
            applyHue(input.Position)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            if gestureState == GestureState.IDLE then
                if InputAdapter.GetPointerOwner() ~= nil then return end
                gestureState       = GestureState.PENDING
                gestureStartX      = input.Position.X
                gestureStartY      = input.Position.Y
                activeGestureTouch = input
            end
        end
    end))

    -- AlphaStrip listeners
    table.insert(globalConns, AlphaStrip.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if not InputAdapter.ClaimPointer(pointerOwner) then return end
            gestureState = GestureState.ALPHA
            applyAlpha(input.Position)
        elseif input.UserInputType == Enum.UserInputType.Touch then
            if gestureState == GestureState.IDLE then
                if InputAdapter.GetPointerOwner() ~= nil then return end
                gestureState       = GestureState.PENDING
                gestureStartX      = input.Position.X
                gestureStartY      = input.Position.Y
                activeGestureTouch = input
            end
        end
    end))

    -- Gesture motion tracker
    table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
        if not enabled then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end

        if gestureState == GestureState.SV then
            applySV(input.Position)
        elseif gestureState == GestureState.HUE then
            applyHue(input.Position)
        elseif gestureState == GestureState.ALPHA then
            applyAlpha(input.Position)
        elseif gestureState == GestureState.PENDING then
            if input ~= activeGestureTouch then return end
            local dx = math.abs(input.Position.X - gestureStartX)
            local dy = math.abs(input.Position.Y - gestureStartY)
            local dist = math.sqrt(dx * dx + dy * dy)

            if dist >= InputAdapter.GESTURE_THRESHOLD then
                if not InputAdapter.ClaimPointer(pointerOwner) then
                    gestureState = GestureState.YIELDED
                    return
                end
                -- Decide which element got touch intent
                local svPos  = SVSquare.AbsolutePosition
                local svSize = SVSquare.AbsoluteSize
                local huePos = HueStrip.AbsolutePosition
                local hueSize = HueStrip.AbsoluteSize

                if gestureStartX >= svPos.X and gestureStartX <= svPos.X + svSize.X
                    and gestureStartY >= svPos.Y and gestureStartY <= svPos.Y + svSize.Y then
                    gestureState = GestureState.SV
                    _lockPageScroll()
                    applySV(input.Position)
                elseif gestureStartX >= huePos.X and gestureStartX <= huePos.X + hueSize.X then
                    gestureState = GestureState.HUE
                    _lockPageScroll()
                    applyHue(input.Position)
                else
                    gestureState = GestureState.ALPHA
                    _lockPageScroll()
                    applyAlpha(input.Position)
                end
            end
        end
    end))

    -- Release
    table.insert(globalConns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resetGesture()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            if input == activeGestureTouch then
                resetGesture()
            end
        end
    end))

    -- ─── Swatch / Row expand toggle ────────────────────────────────────────

    local function toggleExpand()
        if not enabled then return end
        isOpen = not isOpen
        local targetH = isOpen and EXPANDED_H or style.RowH
        if isOpen then
            PickerContainer.Visible = true
            TweenHelper.Tween(Row, TweenHelper.DefaultInfo, { Size = UDim2.new(1, 0, 0, targetH) })
        else
            TweenHelper.Tween(Row, TweenHelper.DefaultInfo, { Size = UDim2.new(1, 0, 0, targetH) })
            task.delay(TweenHelper.DefaultInfo.Time, function()
                if not isOpen and PickerContainer and PickerContainer.Parent then
                    PickerContainer.Visible = false
                end
            end)
        end
    end

    Swatch.MouseButton1Click:Connect(toggleExpand)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(Row,           nil, { BackgroundColor3 = tokens.Surface })
        TweenHelper.Tween(rowStroke,     nil, { Color = tokens.Border })
        TweenHelper.Tween(titleLabel,    nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(HexLabel,      nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(AlphaLabel,    nil, { TextColor3 = tokens.Text })
        TweenHelper.Tween(previewStroke, nil, { Color = tokens.Border })
        TweenHelper.Tween(hexStroke,     nil, { Color = tokens.Border })
        TweenHelper.Tween(alphaStroke,   nil, { Color = tokens.Border })
        TweenHelper.Tween(HexPill,       nil, { BackgroundColor3 = tokens.InputBackground })
        TweenHelper.Tween(AlphaPill,     nil, { BackgroundColor3 = tokens.InputBackground })
        if descLabel then
            TweenHelper.Tween(descLabel, nil, { TextColor3 = tokens.SubText })
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = setmetatable({}, {
        __tostring = function(self)
            return self:GetDisplay()
        end
    })

    function api:Get(): (Color3, number)
        return currentColor, alpha
    end

    function api:GetDisplay(): string
        return toHex(currentColor)
    end

    function api:Set(color: Color3, newAlpha: number?)
        h, s, v = toHSV(color)
        if type(newAlpha) == "number" then
            alpha = math.clamp(newAlpha, 0, 1)
        end
        rebuildColor(true)
        -- Preserve the exact Color3 the caller passed so Get() returns it bitwise-equal.
        -- rebuildColor() sets currentColor = Color3.fromHSV(h,s,v) which loses precision
        -- on non-primary colors due to HSV round-trip; lock it back to the source here.
        currentColor = color
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo,
            { TextColor3 = ThemeEngine.GetToken("Text") })
    end

    function api:Disable()
        enabled = false
        resetGesture()
        if isOpen then
            isOpen = false
            TweenHelper.Tween(Row, TweenHelper.FastInfo, { Size = UDim2.new(1, 0, 0, style.RowH) })
        end
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo,
            { TextColor3 = ThemeEngine.GetToken("DisabledText") })
    end

    function api:SetTitle(t: string) titleLabel.Text = t end

    function api:Show()  Row.Visible = true  end
    function api:Hide()  Row.Visible = false end

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        resetGesture()
        themeDisconnect()
        for _, conn in ipairs(globalConns) do conn:Disconnect() end
        table.clear(globalConns)
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged
    api._debugId  = debugId or nil

    return api
end

return ColorPicker

end

-- ── Components.Divider ────────────────────────────────────
_Delirium_modules["Components.Divider"] = function()
-- Components/Divider.lua
-- Horizontal visual separator. Optional text label centered over the line.
-- Consumes minimal vertical space (16px without label, 20px with label).
--
-- Usage:
--   Section:CreateDivider()
--   Section:CreateDivider({ Label = "Advanced" })
-- local Root            = script.Parent.Parent
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local Maid            = _Delirium_require("Core.Maid")

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
    -- When hasLabel: start at size 0, signal resizes after label width is known.
    -- When no label: full width immediately (no dynamic resize needed).
    local leftLine = ComponentHelper.Create("Frame", {
        Name             = "LineLeft",
        AnchorPoint      = Vector2.new(0, 0.5),
        Position         = UDim2.new(0, 0, 0.5, 0),
        Size             = hasLabel and UDim2.new(0, 0, 0, 1) or UDim2.new(1, 0, 0, 1),  -- sized by signal when hasLabel
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })

    local rightLine
    local textLabel

    if hasLabel then
        -- Right line
        -- Initial size 0: the AbsoluteSize signal below resizes both lines once
        -- the label's width is known. Starting at 0 prevents a one-frame overlap
        -- where the 50%-6px default extends over the label before the signal fires.
        rightLine = ComponentHelper.Create("Frame", {
            Name             = "LineRight",
            AnchorPoint      = Vector2.new(1, 0.5),
            Position         = UDim2.new(1, 0, 0.5, 0),
            Size             = UDim2.new(0, 0, 0, 1),  -- sized by signal below
            BackgroundColor3 = ThemeEngine.GetToken("Border"),
            BorderSizePixel  = 0,
            Parent           = frame,
        })

        -- Center label — padding 6px each side so text never touches the lines.
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

        -- Resize lines dynamically so they never overlap the label regardless of
        -- text length. 8px gap on each side of the label gives breathing room.
        --
        -- Three-path approach (race fix):
        --   Signal 1: textLabel.AbsoluteSize fires when text width is known.
        --   Signal 2: frame.AbsoluteSize     fires when parent container resolves its width.
        --   Fallback: task.defer fires one frame after construction — by then Roblox's
        --             layout engine has resolved ALL AbsoluteSize values. This catches
        --             the race where both signals fire on the same frame with stale zeros
        --             (both guard early, both stabilize, neither fires again).
        local GAP = 8
        local function _resizeLines()
            local labelHalf = textLabel.AbsoluteSize.X / 2
            local frameW    = frame.AbsoluteSize.X
            -- Skip only if BOTH are zero (frame truly not laid out yet).
            -- If frameW is resolved but labelHalf is still 0, lineW = frameW/2 - GAP
            -- which is correct for a zero-width label edge case.
            if frameW <= 0 then return end
            local lineW = math.max(0, (frameW / 2) - labelHalf - GAP)
            leftLine.Size  = UDim2.new(0, lineW, 0, 1)
            rightLine.Size = UDim2.new(0, lineW, 0, 1)
        end

        maid:GiveTask(textLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(_resizeLines))
        maid:GiveTask(frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(_resizeLines))
        -- Deferred fallback: runs after the current layout pass fully resolves.
        task.defer(_resizeLines)
    end

    -- ─── Theme updates ───────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(leftLine, nil, {BackgroundColor3 = tokens.Border})
        if rightLine then TweenHelper.Tween(rightLine, nil, {BackgroundColor3 = tokens.Border}) end
        if textLabel then TweenHelper.Tween(textLabel, nil, {TextColor3 = tokens.DisabledText}) end
    end)

    -- ─── Public API ──────────────────────────────────────────────────────────

    local _destroyed = false
    local maid       = Maid.new()
    local api = {}

    function api:SetLabel(text: string)
        if textLabel then textLabel.Text = text end
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        maid:DoCleaning()
        themeDisconnect()
        frame:Destroy()
    end

    api.Instance = frame
    return api
end

return Divider

end

-- ── Components.Dropdown ───────────────────────────────────
_Delirium_modules["Components.Dropdown"] = function()
-- Components/Dropdown.lua
-- Floating Popup Dropdown with multi-select support.
--
-- Architecture:
--   - Clicking Trigger opens a floating overlay Frame parented to the
--     Window-owned DeliriumOverlay (not directly to the ScreenGui ancestor).
--   - Positioning is computed by Utilities.Geometry.PositionNear, which anchors
--     the popup to the Trigger's AbsolutePosition/AbsoluteSize and flips up/down
--     based on viewport space (not Window frame space).
--   - Only one dropdown popup is open at a time (CloseActive).
--   - Auto-closes when clicking outside, pressing Escape, or opening another Dropdown.

local UserInputService = game:GetService("UserInputService")
local GuiService       = game:GetService("GuiService")
-- local Root             = script.Parent.Parent
local ComponentHelper  = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper      = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine      = _Delirium_require("Core.ThemeEngine")
local Signal           = _Delirium_require("Utilities.Signal")
local VariantEngine    = _Delirium_require("Core.VariantEngine")
local Geometry         = _Delirium_require("Utilities.Geometry")

local Dropdown = {}

-- Track currently open dropdown globally so opening a new dropdown closes the previous one.
local activeOpenDropdownClose = nil

function Dropdown.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style      = VariantEngine.Resolve("Dropdown", config.Variant)
    local title   = config.Title or config.Name or config.Text or "Dropdown"
    local desc    = config.Description or ""
    local options = config.Options     or {}
    local isMulti    = config.Multi       == true
    local enabled    = true
    local isOpen     = false
    local _destroyed = false

    -- current selection: string (single) or table (multi)
    local currentSelection = config.Default
        or (isMulti and {} or (options[1] or ""))

    local OnChanged = Signal.new()

    -- Cache Window-owned overlay for popup parenting.
    -- The overlay is a sibling Frame of DeliriumMainFrame inside the shared
    -- ScreenGui, so it is NOT in our ancestor chain. We first walk up to find
    -- our own Window's MainFrame, then look for the overlay among its siblings.
    -- Falls back to the ScreenGui ancestor when no overlay is present (backward
    -- compatibility with builds that predate the overlay layer).
    local _overlayAncestor = nil
    local function _getOverlay(): Instance?
        if _overlayAncestor and _overlayAncestor.Parent then return _overlayAncestor end

        -- Walk up to find our Window's MainFrame.
        local anc = parent
        while anc do
            if anc.Name == "DeliriumMainFrame" then
                local sg = anc.Parent
                if sg then
                    -- Look for the overlay among siblings of MainFrame.
                    for _, child in ipairs(sg:GetChildren()) do
                        if child.Name == "DeliriumOverlay" then
                            _overlayAncestor = child
                            return child
                        end
                    end
                    -- Fallback: use the ScreenGui directly (no overlay in this build).
                    _overlayAncestor = sg
                    return sg
                end
            end
            anc = anc.Parent
        end

        -- Last-resort fallback: walk up to any ScreenGui ancestor.
        anc = parent
        while anc do
            if anc:IsA("ScreenGui") then
                _overlayAncestor = anc
                return anc
            end
            anc = anc.Parent
        end
        return nil
    end

    -- ─── Row container ─────────────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "DropdownRow",
        Size             = UDim2.new(1, 0, 0, style.RowH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        ClipsDescendants = false, -- allow popups to break bounds if needed
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, style.Corner)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    if debugId then
        Row:SetAttribute("DeliriumDebugId", debugId)
    end

    -- Label side
    local LabelContainer = ComponentHelper.Create("Frame", {
        Size               = UDim2.new(0.5, 0, 0, style.RowH),
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
        Size               = UDim2.new(style.TriggerWScale, 0, 0, style.TriggerH),
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

    -- ─── Floating Popup Frame ──────────────────────────────────────────────

    local OPTION_ITEM_H = style.OptionItemH
    local OPTION_GAP    = 4
    local OPTION_MAX_H  = 200
    local POPUP_GAP     = 4

    local PopupFrame      = nil
    local OptionScroll    = nil
    local OptionList      = nil
    local UIList          = nil
    local optionConns     = {}
    local outsideClickConn = nil
    local scrollConn      = nil   -- tracks UIList canvas-size connection for cleanup
    local anchorConns     = {}    -- anchor/layout connections for repositioning

    -- ── Anchor / layout tracking (Dropdown 2.0) ─────────────────────────────
    -- The popup lives in the Window-owned DeliriumOverlay (a full-screen sibling
    -- of MainFrame). Its position must be derived from the CURRENT Trigger
    -- geometry + visible bounds, and rebound to layout changes. We cache the
    -- PageCanvas (visible region) and MainFrame (drag/resize) ancestors.

    local _pageCanvas = nil
    local _mainFrame  = nil
    local _overlay    = nil

    local function _findAncestors()
        local anc = parent
        while anc do
            if not _mainFrame and anc.Name == "DeliriumMainFrame" then
                _mainFrame = anc
            end
            if not _pageCanvas and anc:IsA("ScrollingFrame") then
                _pageCanvas = anc
            end
            if _mainFrame and _pageCanvas then break end
            anc = anc.Parent
        end
    end

    -- Convert a screen-space point into DeliriumOverlay-local coordinates.
    -- The Overlay is a full-screen sibling of MainFrame (IgnoreGuiInset=true,
    -- default position), so Overlay-local == screen space in the current build.
    -- We still subtract Overlay.AbsolutePosition so the math is correct even if
    -- the Overlay is ever repositioned.
    local function _toOverlayLocal(screenPos: Vector2): Vector2
        if _overlay and _overlay.Parent then
            local oPos = _overlay.AbsolutePosition
            return Vector2.new(screenPos.X - oPos.X, screenPos.Y - oPos.Y)
        end
        return screenPos
    end

    -- Compute the visible bounds for placement.
    -- Priority: visible PageCanvas region → Window MainFrame region → viewport.
    local function _getVisibleBounds()
        if _pageCanvas and _pageCanvas.Parent then
            return Geometry.GetVisibleBounds(_pageCanvas)
        end
        if _mainFrame and _mainFrame.Parent then
            return Geometry.GetVisibleBounds(_mainFrame)
        end
        return Geometry.GetVisibleBounds()
    end

    -- Recompute the popup position from the CURRENT trigger geometry + bounds.
    -- Called on open and whenever a bound layout/scroll event fires.
    local function repositionPopup()
        if not PopupFrame or not PopupFrame.Parent then return end
        if not Trigger or not Trigger.Parent then return end

        local trigPos  = Trigger.AbsolutePosition
        local trigSize = Trigger.AbsoluteSize

        local contentH = #options * (OPTION_ITEM_H + OPTION_GAP)
        local popupH   = math.min(contentH, OPTION_MAX_H)
        local popupW   = trigSize.X

        local geom = Geometry.PositionNear(
            trigPos,
            trigSize,
            Vector2.new(popupW, popupH),
            POPUP_GAP,
            _getVisibleBounds()
        )

        local targetW = geom.Size.X
        local targetH = geom.Size.Y

        -- Convert screen-space anchor to Overlay-local coordinates.
        local localPos = _toOverlayLocal(geom.Position)

        PopupFrame.AnchorPoint = geom.AnchorPoint
        PopupFrame.Position    = UDim2.new(0, localPos.X, 0, localPos.Y)
        PopupFrame.Size        = UDim2.new(0, targetW, 0, targetH)
    end

    -- Bind event-driven repositioning. No RenderStepped/Heartbeat polling.
    local function bindAnchor()
        _findAncestors()

        -- PageCanvas scroll: trigger moves vertically as the page scrolls.
        if _pageCanvas and _pageCanvas.Parent then
            table.insert(anchorConns,
                _pageCanvas:GetPropertyChangedSignal("CanvasPosition"):Connect(repositionPopup))
            table.insert(anchorConns,
                _pageCanvas:GetPropertyChangedSignal("AbsolutePosition"):Connect(repositionPopup))
        end

        -- Window drag: MainFrame.Position changes.
        if _mainFrame and _mainFrame.Parent then
            table.insert(anchorConns,
                _mainFrame:GetPropertyChangedSignal("Position"):Connect(repositionPopup))
            table.insert(anchorConns,
                _mainFrame:GetPropertyChangedSignal("AbsolutePosition"):Connect(repositionPopup))
            -- Window resize: MainFrame.AbsoluteSize changes.
            table.insert(anchorConns,
                _mainFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(repositionPopup))
        end

        -- Viewport resize: camera ViewportSize changes.
        local cam = workspace.CurrentCamera
        if cam then
            table.insert(anchorConns,
                cam:GetPropertyChangedSignal("ViewportSize"):Connect(repositionPopup))
        end
    end

    local function unbindAnchor()
        for _, conn in ipairs(anchorConns) do
            conn:Disconnect()
        end
        table.clear(anchorConns)
    end

    local function destroyPopup()
        unbindAnchor()

        if outsideClickConn then
            outsideClickConn:Disconnect()
            outsideClickConn = nil
        end
        if scrollConn then
            scrollConn:Disconnect()
            scrollConn = nil
        end
        for _, conn in ipairs(optionConns) do
            conn:Disconnect()
        end
        table.clear(optionConns)

        local frameToDestroy = PopupFrame
        PopupFrame = nil
        isOpen = false

        if activeOpenDropdownClose == destroyPopup then
            activeOpenDropdownClose = nil
        end

        TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = 0 })

        if frameToDestroy and frameToDestroy.Parent then
            local currentW = frameToDestroy.Size.X.Offset
            local closeTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
            local tween = TweenHelper.Tween(frameToDestroy, closeTweenInfo, {
                Size = UDim2.new(0, currentW, 0, 0),
            })
            task.delay(0.15, function()
                pcall(function() frameToDestroy:Destroy() end)
            end)
        end
    end

    local function RenderPopupOptions()
        if not OptionList then return end
        for _, conn in ipairs(optionConns) do
            conn:Disconnect()
        end
        table.clear(optionConns)

        for _, child in ipairs(OptionList:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end

        for idx, opt in ipairs(options) do
            local isSelected = isMulti
                and table.find(currentSelection, opt) ~= nil
                or  currentSelection == opt

            local Btn = ComponentHelper.Create("TextButton", {
                Size             = UDim2.new(1, 0, 0, OPTION_ITEM_H),
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

            table.insert(optionConns, Btn.MouseEnter:Connect(function()
                if not isSelected then
                    TweenHelper.Tween(Btn, TweenHelper.FastInfo, {
                        BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
                    })
                end
            end))
            table.insert(optionConns, Btn.MouseLeave:Connect(function()
                if not isSelected then
                    TweenHelper.Tween(Btn, TweenHelper.FastInfo, {
                        BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
                    })
                end
            end))
            table.insert(optionConns, Btn.Activated:Connect(function()
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
                    destroyPopup()
                end
                RenderPopupOptions()
                OnChanged:Fire(currentSelection)
            end))
        end
    end

    local function openPopup()
        if activeOpenDropdownClose and activeOpenDropdownClose ~= destroyPopup then
            activeOpenDropdownClose()
        end
        activeOpenDropdownClose = destroyPopup

        local overlay = _getOverlay()
        if not overlay then return end
        _overlay = overlay

        -- Find PageCanvas / MainFrame ancestors for anchor + bounds tracking.
        _findAncestors()

        -- Initial frame: zero-height, positioned by repositionPopup().
        PopupFrame = ComponentHelper.Create("Frame", {
            Name                   = "DropdownPopupOverlay",
            AnchorPoint            = Vector2.new(0, 0),
            Size                   = UDim2.new(0, 0, 0, 0),
            Position               = UDim2.new(0, 0, 0, 0),
            BackgroundColor3       = ThemeEngine.GetToken("Surface"),
            BorderSizePixel        = 0,
            ClipsDescendants       = true,
            ZIndex                 = 1,
            Parent                 = overlay,
        })
        ComponentHelper.AddCorner(PopupFrame, 8)
        ComponentHelper.AddStroke(PopupFrame, ThemeEngine.GetToken("Border"), 1)

        -- Compute the correct anchor/position/size from current geometry.
        repositionPopup()

        local targetW = PopupFrame.Size.X.Offset
        local targetH = PopupFrame.Size.Y.Offset

        -- Start at zero height for smooth opening expansion
        PopupFrame.Size = UDim2.new(0, targetW, 0, 0)

        -- Smooth expansion animation
        local animInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
        TweenHelper.Tween(PopupFrame, animInfo, {
            Size = UDim2.new(0, targetW, 0, targetH),
        })

        OptionScroll = ComponentHelper.Create("ScrollingFrame", {
            Size                   = UDim2.new(1, -8, 1, -8),
            Position               = UDim2.new(0, 4, 0, 4),
            BackgroundTransparency = 1,
            BorderSizePixel        = 0,
            ScrollBarThickness     = 3,
            ScrollBarImageColor3   = ThemeEngine.GetToken("ScrollBar"),
            ScrollingDirection     = Enum.ScrollingDirection.Y,
            ZIndex                 = 2,
            Parent                 = PopupFrame,
        })

        OptionList = ComponentHelper.Create("Frame", {
            Size               = UDim2.new(1, 0, 1, 0),
            BackgroundTransparency = 1,
            ZIndex             = 2,
            Parent             = OptionScroll,
        })

        UIList = ComponentHelper.Create("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, OPTION_GAP),
            Parent    = OptionList,
        })

        scrollConn = UIList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            if OptionScroll and OptionScroll.Parent then
                OptionScroll.CanvasSize = UDim2.new(0, 0, 0, UIList.AbsoluteContentSize.Y + 4)
            end
        end)

        RenderPopupOptions()

        -- Bind event-driven repositioning (scroll / window move / resize / viewport).
        bindAnchor()

        isOpen = true
        TweenHelper.Tween(Arrow, TweenHelper.FastInfo, { Rotation = 180 })

        -- Outside click listener to auto-close popup.
        -- Langsung connect tanpa task.defer:
        -- Trigger.Activated terpanggil setelah InputEnded, jadi koneksi ini
        -- tidak akan menangkap klik yang sama yang membuka popup.
        -- Dengan direct connect, destroyPopup() selalu punya handle valid
        -- untuk di-disconnect — tidak ada race condition.
        outsideClickConn = UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                local mPos = input.Position
                if PopupFrame and PopupFrame.Parent then
                    local pPos = PopupFrame.AbsolutePosition
                    local pSize = PopupFrame.AbsoluteSize
                    local tPos = Trigger.AbsolutePosition
                    local tSize = Trigger.AbsoluteSize

                    local inPopup = (mPos.X >= pPos.X and mPos.X <= pPos.X + pSize.X and mPos.Y >= pPos.Y and mPos.Y <= pPos.Y + pSize.Y)
                    local inTrigger = (mPos.X >= tPos.X and mPos.X <= tPos.X + tSize.X and mPos.Y >= tPos.Y and mPos.Y <= tPos.Y + tSize.Y)

                    if not inPopup and not inTrigger then
                        destroyPopup()
                    end
                end
            end
        end)
    end

    local triggerConn = Trigger.Activated:Connect(function()
        if not enabled then return end
        if isOpen then
            destroyPopup()
        else
            openPopup()
        end
    end)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        Row.BackgroundColor3       = tokens.Surface
        rowStroke.Color            = tokens.Border
        titleLabel.TextColor3      = tokens.Text
        Trigger.BackgroundColor3   = tokens.SurfaceActive
        SelectedText.TextColor3    = tokens.Text
        Arrow.TextColor3           = tokens.SubText
        if descLabel then descLabel.TextColor3 = tokens.SubText end
        if PopupFrame and PopupFrame.Parent then
            PopupFrame.BackgroundColor3 = tokens.Surface
        end
        RenderPopupOptions()
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = setmetatable({}, {
        __tostring = function(self)
            return self:GetDisplay()
        end
    })

    function api:Get()
        return currentSelection
    end

    function api:GetDisplay(): string
        if isMulti then
            return table.concat(currentSelection, ", ")
        end
        return tostring(currentSelection)
    end

    function api:Set(val)
        currentSelection = val
        SelectedText.Text = selectionText()
        RenderPopupOptions()
        OnChanged:Fire(currentSelection)
    end

    function api:Refresh()
        RenderPopupOptions()
    end

    function api:SetOptions(newOptions: table)
        options = newOptions
        if not isMulti and not table.find(options, currentSelection) then
            currentSelection = options[1] or ""
            SelectedText.Text = selectionText()
        end
        RenderPopupOptions()
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
            destroyPopup()
        end
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(t: string) titleLabel.Text = t end

    function api:Show()  Row.Visible = true  end
    function api:Hide()
        destroyPopup()
        Row.Visible = false
    end

    function api:Destroy()
        _destroyed = true
        destroyPopup()
        triggerConn:Disconnect()
        themeDisconnect()
        OnChanged:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged
    api._debugId  = debugId or nil

    return api
end

-- Close the currently-open popup (if any).
-- Called by Tab:_ApplyActive(false) to ensure popups don't stay visible
-- after a tab switch (the popup lives in the Window-owned overlay, not in
-- PageCanvas, so it is not automatically hidden with the page).
function Dropdown.CloseActive()
    if activeOpenDropdownClose then
        activeOpenDropdownClose()
    end
end

return Dropdown

end

-- ── Components.Keybind ────────────────────────────────────
_Delirium_modules["Components.Keybind"] = function()
-- Components/Keybind.lua
-- Desktop : bind via keyboard (existing behaviour).
-- Mobile  : floating on-screen TouchButton that fires OnActivated on tap.
--           BindBtn enters placement-drag mode so the user can reposition it.
--           Position persisted per-keybind title via ConfigService.

local UserInputService = game:GetService("UserInputService")
-- local Root             = script.Parent.Parent
local ComponentHelper  = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper      = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine      = _Delirium_require("Core.ThemeEngine")
local InputAdapter     = _Delirium_require("Core.InputAdapter")
local Signal           = _Delirium_require("Utilities.Signal")
local VariantEngine    = _Delirium_require("Core.VariantEngine")
local ConfigService    = _Delirium_require("Services.ConfigService")

-- ─── Module-level helpers ─────────────────────────────────────────────────────

-- Walk up the instance tree to find the first ScreenGui ancestor.
local function _findScreenGui(inst: Instance): ScreenGui?
    local cur = inst.Parent
    while cur do
        if cur:IsA("ScreenGui") then return cur end
        cur = cur.Parent
    end
    return nil
end

-- Clamp an offset Vector2 position so the button stays inside the viewport.
local function _clampPosition(pos: Vector2, btnSize: Vector2): Vector2
    local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
        or Vector2.new(1920, 1080)
    return Vector2.new(
        math.clamp(pos.X, 0, vp.X - btnSize.X),
        math.clamp(pos.Y, 0, vp.Y - btnSize.Y)
    )
end

-- Touch button size (px). Touch-friendly 52×52 target.
local TOUCH_BTN_SIZE = Vector2.new(52, 52)

local Keybind = {}

function Keybind.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style      = VariantEngine.Resolve("Keybind", config.Variant)
    local title      = config.Title or config.Name or config.Text or "Keybind"
    local desc       = config.Description or ""
    local currentKey = config.Default     or Enum.KeyCode.E
    local enabled      = true
    local _destroyed  = false
    local isListening = false
    -- Set to true the moment a new key is recorded. Cleared after the current
    -- InputBegan event cycle via task.defer. Guards _activateConn from firing
    -- OnActivated on the same input that was just used to rebind the key,
    -- which can happen when Roblox fires globalConn before _activateConn in
    -- the same InputBegan dispatch (connection order is not guaranteed).
    local _justRebound = false

    local OnChanged   = Signal.new()
    local OnActivated = Signal.new()

    -- ─── ConfigService — touch button position persistence ─────────────────
    local _cfg     = ConfigService.GetProfile("Delirium_KeybindPositions")
    local _cfgKeyX = "touchbtn_" .. title .. "_x"
    local _cfgKeyY = "touchbtn_" .. title .. "_y"

    local function _loadTouchPos(): Vector2
        local x = _cfg:Get(_cfgKeyX, nil)
        local y = _cfg:Get(_cfgKeyY, nil)
        if x and y then
            return _clampPosition(Vector2.new(x, y), TOUCH_BTN_SIZE)
        end
        -- Default: bottom-right quadrant.
        local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize
            or Vector2.new(800, 600)
        return _clampPosition(Vector2.new(vp.X * 0.82, vp.Y * 0.88), TOUCH_BTN_SIZE)
    end

    local function _saveTouchPos(pos: Vector2)
        _cfg:Set(_cfgKeyX, pos.X)
        _cfg:Set(_cfgKeyY, pos.Y)
        _cfg:Save()
    end

    -- ─── Persistent key-press listener (desktop only) ───────────────────────
    -- NOTE: gameProcessed guard omitted intentionally — DisplayOrder=100 marks
    -- all inputs as gameProcessed=true even when the window is hidden.
    local _activateConn = UserInputService.InputBegan:Connect(function(input, _)
        if not enabled    then return end
        if isListening    then return end
        if _justRebound   then return end   -- same InputBegan that just recorded a new key
        if InputAdapter.IsTouch then return end          -- handled by TouchButton
        if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode ~= currentKey then return end
        OnActivated:Fire(currentKey)
    end)

    -- ─── Row ───────────────────────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "KeybindRow",
        Size             = UDim2.new(1, 0, 0, style.RowH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, style.Corner)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    if debugId then
        Row:SetAttribute("DeliriumDebugId", debugId)
    end

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
        Position           = UDim2.new(1, -(style.BindBtnW + 8), 0.5, -style.BindBtnH/2),
        Size               = UDim2.new(0, style.BindBtnW, 0, style.BindBtnH),
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

    -- ─── Listening logic (desktop) ─────────────────────────────────────────

    local globalConn
    local timeoutThread

    local function keyDisplayName(): string
        if InputAdapter.IsTouch then
            return currentKey.Name:sub(1, 4)
        end
        return currentKey.Name
    end

    BindBtn.Text = keyDisplayName()

    local function stopListening()
        isListening = false
        if globalConn then
            globalConn:Disconnect()
            globalConn = nil
        end
        if timeoutThread then
            pcall(task.cancel, timeoutThread)
            timeoutThread = nil
        end
        BindBtn.Text       = keyDisplayName()
        BindBtn.TextColor3 = ThemeEngine.GetToken("Text")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
    end

    local hoverConn1 = BindBtn.MouseEnter:Connect(function()
        if not enabled or isListening then return end
        TweenHelper.Tween(BindBtn, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        }, "btn_hover")
    end)
    local hoverConn2 = BindBtn.MouseLeave:Connect(function()
        if not enabled or isListening then return end
        TweenHelper.Tween(BindBtn, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
        }, "btn_hover")
    end)

    -- ─── Touch button (mobile only) ────────────────────────────────────────

    local TouchButton      = nil
    local touchBtnStroke   = nil
    local _isPlacementMode = false
    local _touchConns      = {}
    -- Whether the floating TouchButton is actively shown.
    -- Starts false — only visible after user explicitly enables it via BindBtn.
    local _touchEnabled    = false
    -- Lazy-build guard: TouchButton DOM is created only the first time it is needed.
    local _touchBtnBuilt   = false

    local function _clearTouchConns()
        for _, c in ipairs(_touchConns) do c:Disconnect() end
        table.clear(_touchConns)
    end
    local function _addTouchConn(conn)
        table.insert(_touchConns, conn)
    end

    local function _enterPlacementMode()
        _isPlacementMode   = true
        BindBtn.Text       = "Lock"
        BindBtn.TextColor3 = ThemeEngine.GetToken("Warning")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Warning"),
        })
        if TouchButton and touchBtnStroke then
            TweenHelper.Tween(touchBtnStroke, TweenHelper.FastInfo, {
                Color = ThemeEngine.GetToken("Warning"),
            })
        end
    end

    local function _exitPlacementMode()
        _isPlacementMode = false
        if TouchButton then
            local pos = Vector2.new(
                TouchButton.Position.X.Offset,
                TouchButton.Position.Y.Offset
            )
            _saveTouchPos(pos)
            if touchBtnStroke then
                TweenHelper.Tween(touchBtnStroke, TweenHelper.FastInfo, {
                    Color = ThemeEngine.GetToken("Border"),
                })
            end
        end
        BindBtn.Text       = keyDisplayName()
        BindBtn.TextColor3 = ThemeEngine.GetToken("Text")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
    end

    local function _buildTouchButton()
        -- Called from ensureTouchButton(), which is only reachable via BindBtn tap or
        -- SetTouchButtonVisible() — both happen after Row is fully parented. Build sync.
        if _destroyed then return end
        local screenGui = _findScreenGui(Row)
        if not screenGui then
            warn("Keybind (" .. title .. "): ScreenGui ancestor not found — TouchButton skipped")
            return
        end

        local initPos = _loadTouchPos()

        TouchButton = ComponentHelper.Create("TextButton", {
            Name             = "KeybindTouch_" .. title,
            Position         = UDim2.fromOffset(initPos.X, initPos.Y),
            Size             = UDim2.fromOffset(TOUCH_BTN_SIZE.X, TOUCH_BTN_SIZE.Y),
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
            Text             = currentKey.Name:sub(1, 4),
            TextColor3       = ThemeEngine.GetToken("Text"),
            TextSize         = 13,
            Font             = Enum.Font.GothamBold,
            AutoButtonColor  = false,
            ZIndex           = 20,
            Visible          = false,  -- hidden until user enables via BindBtn
            Parent           = screenGui,
        })
        ComponentHelper.AddCorner(TouchButton, 10)
        touchBtnStroke = ComponentHelper.AddStroke(
            TouchButton, ThemeEngine.GetToken("Border"), 1.5
        )

        -- Press scale feedback.
        local function _animPress()
            TweenHelper.Tween(TouchButton, TweenHelper.FastInfo, {
                Size = UDim2.fromOffset(TOUCH_BTN_SIZE.X - 6, TOUCH_BTN_SIZE.Y - 6),
            }, "touch_press")
        end
        local function _animRelease()
            TweenHelper.Tween(TouchButton, TweenHelper.FastInfo, {
                Size = UDim2.fromOffset(TOUCH_BTN_SIZE.X, TOUCH_BTN_SIZE.Y),
            }, "touch_press")
        end

        -- Per-touch state.
        local _activeDragInput = nil  -- InputObject that owns the current drag
        local _dragStart       = nil
        local _btnStartPos     = nil
        local _wasDragged      = false

        _addTouchConn(TouchButton.InputBegan:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            if _activeDragInput ~= nil then return end  -- another touch already owns the drag
            -- Claim this InputObject as the owner of the current drag.
            _activeDragInput = input
            _dragStart       = InputAdapter.GetPointerPosition(input)
            _btnStartPos     = Vector2.new(
                TouchButton.Position.X.Offset,
                TouchButton.Position.Y.Offset
            )
            _wasDragged = false
            if not _isPlacementMode then _animPress() end
        end))

        -- Use global UIS.InputChanged instead of GuiObject.InputChanged.
        -- GuiObject events stop firing when the finger leaves the button bounds;
        -- global UIS tracks the same InputObject for its entire lifetime.
        _addTouchConn(UserInputService.InputChanged:Connect(function(input)
            if input ~= _activeDragInput then return end  -- wrong touch, ignore
            if not _dragStart or not _btnStartPos then return end
            local delta = InputAdapter.GetPointerPosition(input) - _dragStart
            if delta.Magnitude > InputAdapter.DRAG_THRESHOLD_TOUCH then
                _wasDragged = true
            end
            -- Only reposition during placement mode.
            if _isPlacementMode and _wasDragged then
                local newPos = _clampPosition(_btnStartPos + delta, TOUCH_BTN_SIZE)
                TouchButton.Position = UDim2.fromOffset(newPos.X, newPos.Y)
            end
        end))

        _addTouchConn(TouchButton.InputEnded:Connect(function(input)
            if input.UserInputType ~= Enum.UserInputType.Touch then return end
            if input ~= _activeDragInput then return end  -- not our touch, ignore
            _animRelease()
            if _isPlacementMode then
                -- Position is saved when the user exits placement mode via BindBtn.
                -- No disk write here — avoids repeated writefile on every finger-lift.
            else
                -- Normal mode: clean tap fires OnActivated.
                if not _wasDragged and enabled then
                    OnActivated:Fire(currentKey)
                end
            end
            _activeDragInput = nil
            _dragStart       = nil
            _btnStartPos     = nil
            _wasDragged      = false
        end))
    end

    -- Lazily build the TouchButton the first time it is needed.
    local function ensureTouchButton()
        if _touchBtnBuilt then return end
        _touchBtnBuilt = true
        _buildTouchButton()
    end

    -- ─── BindBtn click — unified handler ──────────────────────────────────

    BindBtn.MouseButton1Click:Connect(function()
        if not enabled then return end

        if InputAdapter.IsTouch then
            -- Lazy-build on first tap so DOM stays clean until actually needed.
            ensureTouchButton()
            if not TouchButton then return end

            if _isPlacementMode then
                -- Currently dragging — lock position and save.
                _exitPlacementMode()
            elseif _touchEnabled then
                -- Button is visible but not in placement mode → toggle it off.
                _touchEnabled          = false
                TouchButton.Visible    = false
                BindBtn.Text           = keyDisplayName()
                BindBtn.TextColor3     = ThemeEngine.GetToken("Text")
                TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
                    Color = ThemeEngine.GetToken("Border"),
                })
            else
                -- Button is hidden → enable and immediately enter placement mode
                -- so the user can position it before use.
                _touchEnabled       = true
                TouchButton.Visible = true
                _enterPlacementMode()
            end
            return
        end

        -- Desktop: keyboard-listen mode.
        if isListening then
            stopListening()
            return
        end

        isListening = true
        BindBtn.Text       = "..."
        BindBtn.TextColor3 = ThemeEngine.GetToken("Warning")
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Warning"),
        })

        globalConn = UserInputService.InputBegan:Connect(function(input, _gameProcessed)
            -- NOTE: gameProcessed guard intentionally omitted.
            -- DisplayOrder=100 marks inputs as GUI-processed even when window is hidden.
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Escape then
                stopListening()
                return
            end
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                -- Raise the guard BEFORE stopListening() resets isListening,
                -- so _activateConn can't slip through on this same InputBegan.
                _justRebound = true
                currentKey = input.KeyCode
                if TouchButton then
                    TouchButton.Text = currentKey.Name:sub(1, 4)
                end
                OnChanged:Fire(currentKey)
                stopListening()
                -- Lower the guard after the current event cycle fully drains.
                task.defer(function() _justRebound = false end)
            end
        end)
    end)

    -- TouchButton is built lazily on first BindBtn tap (see ensureTouchButton).

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        -- Direct property sets (no tween) so hidden-tab components always
        -- hold the correct color when their PageCanvas becomes Visible again.
        Row.BackgroundColor3     = tokens.Surface
        rowStroke.Color          = tokens.Border
        titleLabel.TextColor3    = tokens.Text
        BindBtn.BackgroundColor3 = tokens.SurfaceActive
        if not isListening and not _isPlacementMode then
            BindBtn.TextColor3 = tokens.Text
            btnStroke.Color    = tokens.Border
        end
        if descLabel then
            descLabel.TextColor3 = tokens.SubText
        end
        if TouchButton and touchBtnStroke then
            TouchButton.BackgroundColor3 = tokens.SurfaceActive
            TouchButton.TextColor3       = tokens.Text
            if not _isPlacementMode then
                touchBtnStroke.Color = tokens.Border
            end
        end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = setmetatable({}, {
        __tostring = function(self) return self:GetDisplay() end,
    })

    function api:Get(): Enum.KeyCode
        return currentKey
    end

    function api:GetDisplay(): string
        return currentKey and currentKey.Name or "None"
    end

    function api:Set(key: Enum.KeyCode)
        if isListening then stopListening() end
        if _isPlacementMode then _exitPlacementMode() end
        currentKey   = key
        BindBtn.Text = keyDisplayName()
        if TouchButton then
            TouchButton.Text = key.Name:sub(1, 4)
        end
        OnChanged:Fire(currentKey)
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
        TweenHelper.Tween(BindBtn, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
            TextColor3       = ThemeEngine.GetToken("Text"),
        })
        TweenHelper.Tween(btnStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Border"),
        })
        if TouchButton then
            TouchButton.Active = true
            TweenHelper.Tween(TouchButton, TweenHelper.FastInfo, {
                BackgroundTransparency = 0,
            })
        end
    end

    function api:Disable()
        enabled = false
        if isListening then stopListening() end
        if _isPlacementMode then _exitPlacementMode() end
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
        if TouchButton then
            TouchButton.Active = false
            TweenHelper.Tween(TouchButton, TweenHelper.FastInfo, {
                BackgroundTransparency = 0.5,
            })
        end
    end

    function api:SetTitle(t: string)
        titleLabel.Text = t
    end

    function api:Show()
        Row.Visible = true
        -- Only restore TouchButton visibility if it was enabled by the user.
        if TouchButton and _touchEnabled then TouchButton.Visible = true end
    end

    function api:Hide()
        Row.Visible = false
        if TouchButton then TouchButton.Visible = false end
    end

    -- Toggle the floating TouchButton from external callers (e.g. a Settings toggle).
    function api:SetTouchButtonVisible(visible: boolean)
        if not InputAdapter.IsTouch then return end
        ensureTouchButton()
        if not TouchButton then return end
        _touchEnabled       = visible == true
        TouchButton.Visible = _touchEnabled
        if not _touchEnabled and _isPlacementMode then
            _exitPlacementMode()
        end
    end

    function api:IsTouchButtonVisible(): boolean
        return _touchEnabled and TouchButton ~= nil and TouchButton.Visible
    end

    -- Convenience alias.
    api.SetTouchEnabled = api.SetTouchButtonVisible

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        if globalConn then globalConn:Disconnect() end
        if timeoutThread then pcall(task.cancel, timeoutThread) end
        _activateConn:Disconnect()
        hoverConn1:Disconnect()
        hoverConn2:Disconnect()
        themeDisconnect()
        _clearTouchConns()
        if TouchButton then
            TouchButton:Destroy()
            TouchButton = nil
        end
        OnChanged:Destroy()
        OnActivated:Destroy()
        Row:Destroy()
    end

    api.Instance    = Row
    api.OnChanged   = OnChanged
    api.OnActivated = OnActivated
    api._debugId    = debugId or nil

    return api
end

return Keybind

end

-- ── Components.Label ──────────────────────────────────────
_Delirium_modules["Components.Label"] = function()
-- Components/Label.lua
-- Inline display label. Left side: name. Right side: optional value.
-- Variants control value color: "default" | "accent" | "positive" | "warning" | "error"
--
-- Usage:
--   Section:CreateLabel({ Title = "Version",  Value = "1.0.0" })
--   Section:CreateLabel({ Title = "Status",   Value = "Active",  Variant = "positive" })
--   Section:CreateLabel({ Title = "Notice",   Value = "Low HP",  Variant = "warning"  })
-- local Root            = script.Parent.Parent
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")

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

    local title    = config.Title or config.Name or config.Text or ""
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

    local hasValue = tostring(value) ~= ""

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = hasValue and UDim2.new(0.55, 0, 1, 0) or UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        Text               = title,
        TextColor3         = hasValue and ThemeEngine.GetToken("SubText") or ThemeEngine.GetToken("Text"),
        TextSize           = 12,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        Parent             = frame,
    })

    local valueLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Value",
        Position           = UDim2.new(0.55, 0, 0, 0),
        Size               = UDim2.new(0.45, 0, 1, 0),
        BackgroundTransparency = 1,
        Text               = tostring(value),
        TextColor3         = ThemeEngine.GetToken(valueToken),
        TextSize           = 12,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Right,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        Visible            = hasValue,
        Parent             = frame,
    })

    local function _updateLayout()
        local curValue = valueLabel.Text
        local isVal = curValue ~= ""
        titleLabel.Size = isVal and UDim2.new(0.55, 0, 1, 0) or UDim2.new(1, 0, 1, 0)
        titleLabel.TextColor3 = isVal and ThemeEngine.GetToken("SubText") or ThemeEngine.GetToken("Text")
        valueLabel.Visible = isVal
    end

    -- ─── Theme updates ───────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        TweenHelper.Tween(frame,       nil, {BackgroundColor3 = tokens.Surface})
        local curValue = valueLabel.Text
        local isVal = curValue ~= ""
        TweenHelper.Tween(titleLabel,  nil, {TextColor3 = isVal and tokens.SubText or tokens.Text})
        TweenHelper.Tween(valueLabel,  nil, {TextColor3 = tokens[valueToken]})
    end)

    -- ─── Public API ──────────────────────────────────────────────────────────

    local _destroyed = false
    local api = {}

    function api:SetTitle(text: string)
        titleLabel.Text = tostring(text)
        _updateLayout()
    end

    function api:SetValue(text: string | number)
        valueLabel.Text = tostring(text)
        _updateLayout()
    end

    function api:SetVariant(v: string)
        variant      = v
        valueToken   = VARIANT_TOKEN[v] or "SubText"
        valueLabel.TextColor3 = ThemeEngine.GetToken(valueToken)
    end

    -- P1-A: Set() alias for SetValue() — consistent with all other stateful components
    function api:Set(text: string | number)
        return self:SetValue(text)
    end

    -- P1-B: Get() — read current value back
    function api:Get(): string
        return valueLabel.Text
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        themeDisconnect()
        frame:Destroy()
    end

    api.Instance = frame
    return api
end

return Label

end

-- ── Components.Paragraph ──────────────────────────────────
_Delirium_modules["Components.Paragraph"] = function()
-- Components/Paragraph.lua
-- Multi-line wrapped text block. Optional bold title above the body.
-- Height grows automatically with content via AutomaticSize.
--
-- Usage:
--   Section:CreateParagraph({
--       Title = "About",  -- optional
--       Content = "Long text that wraps across multiple lines...",
--   })

local TextService     = game:GetService("TextService")
-- local Root            = script.Parent.Parent
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local Maid            = _Delirium_require("Core.Maid")

local Paragraph = {}

function Paragraph.New(parent: Instance, config: table)
    config = config or {}

    local title    = config.Title or config.Name or ""
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

    -- Body text.
    -- ROOT-CAUSE FIX: using AutomaticSize.Y on a TextLabel that is itself inside
    -- an AutomaticSize.Y frame which is inside another AutomaticSize.Y container
    -- creates a 3-level chain. Roblox's layout engine can silently resolve this
    -- to 0 height on some runtime versions (mobile especially). Fix: measure the
    -- text height explicitly via TextService and set a concrete pixel Size.Y.
    -- Recompute whenever the frame width or text changes so wrap rows stay accurate.
    local TEXT_SIZE = 12
    local TEXT_FONT = Enum.Font.Gotham
    local SIDE_PAD  = 24  -- 12px left + 12px right from AddPadding

    local bodyLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Body",
        Size               = UDim2.new(1, 0, 0, TEXT_SIZE + 4),  -- 1-line fallback
        AutomaticSize      = Enum.AutomaticSize.None,             -- measured manually below
        BackgroundTransparency = 1,
        Text               = content,
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = TEXT_SIZE,
        Font               = TEXT_FONT,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextWrapped        = true,
        LayoutOrder        = 1,
        Parent             = frame,
    })
    pcall(function() bodyLabel.LineHeight = 1.4 end)

    -- Measure and apply correct body height.
    local function _measureBody()
        local availW = frame.AbsoluteSize.X - SIDE_PAD
        if availW <= 4 then return end  -- frame not laid out yet

        local txt  = bodyLabel.Text ~= "" and bodyLabel.Text or " "
        local measured = false

        -- Primary: GetTextBoundsAsync (Roblox 2024+ API).
        -- IMPORTANT: params.Font requires a Font OBJECT (Font.fromEnum), NOT an
        -- Enum.Font EnumItem. Assigning an EnumItem throws "Font expected, got EnumItem"
        -- even before the pcall would catch it, so ALL params setup goes inside the pcall.
        local ok, bounds = pcall(function()
            local params = Instance.new("GetTextBoundsParams")
            params.Text  = txt
            params.Font  = Font.fromEnum(TEXT_FONT)  -- Font object required
            params.Size  = TEXT_SIZE
            params.Width = availW
            return TextService:GetTextBoundsAsync(params)
        end)
        if ok and bounds then
            local h = math.max(TEXT_SIZE + 4, math.ceil(bounds.Y))
            bodyLabel.Size = UDim2.new(1, 0, 0, h)
            measured = true
        end

        -- Fallback: GetTextSize (deprecated but still available in most executors)
        if not measured then
            local ok2, sz = pcall(function()
                return TextService:GetTextSize(txt, TEXT_SIZE, TEXT_FONT,
                    Vector2.new(availW, 9999))
            end)
            if ok2 and sz then
                bodyLabel.Size = UDim2.new(1, 0, 0, math.max(TEXT_SIZE + 4, math.ceil(sz.Y)))
            end
        end
    end

    -- Maid must be declared here, before the GiveTask calls below that use it.
    local maid       = Maid.new()
    local _destroyed = false

    -- Re-measure when frame width settles (resolves 1-scale children after parent layout).
    maid:GiveTask(frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(_measureBody))

    -- Re-measure when text changes (SetContent / Append calls update Text synchronously,
    -- so defer one frame to let the frame width be current before measuring).
    maid:GiveTask(bodyLabel:GetPropertyChangedSignal("Text"):Connect(function()
        task.defer(_measureBody)
    end))

    -- Initial measure: defer one frame so the parent container resolves its AbsoluteSize
    -- before we try to read frame.AbsoluteSize.X (which would be 0 if we read it now).
    task.defer(_measureBody)

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
        -- _measureBody fires automatically via bodyLabel.Text signal above
    end

    -- Append text on a new line.
    function api:Append(text: string)
        bodyLabel.Text = bodyLabel.Text .. "\n" .. tostring(text)
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        maid:DoCleaning()
        themeDisconnect()
        frame:Destroy()
    end

    api.Instance = frame
    return api
end

return Paragraph

end

-- ── Components.Slider ─────────────────────────────────────
_Delirium_modules["Components.Slider"] = function()
-- Components/Slider.lua
-- Gesture ownership model:
--   Touch begin  → PENDING (dragging=false, value unchanged)
--   First move   → measure dx vs dy from start position
--   dx > dy*1.5 AND dx > THRESHOLD → HORIZONTAL intent → Slider owns gesture
--   dy > THRESHOLD (and dx not dominant) → VERTICAL intent → yield to page scroll
--   Mouse: immediate drag, no threshold needed
--
-- Key invariant: applyValue is NEVER called during PENDING state.
-- Value only changes after gesture ownership is confirmed (touchDragReady=true).

local UserInputService = game:GetService("UserInputService")
-- local Root             = script.Parent.Parent
local ComponentHelper  = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper      = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine      = _Delirium_require("Core.ThemeEngine")
local Signal           = _Delirium_require("Utilities.Signal")
local InputAdapter     = _Delirium_require("Core.InputAdapter")
local VariantEngine    = _Delirium_require("Core.VariantEngine")

local Slider = {}

-- P3: gesture threshold replaced by InputAdapter.GESTURE_THRESHOLD (= 10, same value).
local HORIZONTAL_DOMINANCE = 1.8 -- dx must be this many times dy to confirm horizontal intent (slider-specific)

-- Fallback defaults for Slider style props.
-- Guards against stale VariantEngine caches (executor reuse across sessions)
-- or consumer-registered variants missing one of these keys.
local SLIDER_STYLE_DEFAULTS = {
    Height = 50,
    Corner = 8,
    PadTop = 8,
    PadBot = 8,
    PadL   = 12,
    PadR   = 12,
    TrackH = 6,
}

function Slider.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style = VariantEngine.Resolve("Slider", config.Variant)
    -- Defensive fill: if Resolve returned an incomplete table (stale cache,
    -- bad RegisterVariant call, etc.) ensure every layout key has a safe value.
    for _k, _v in pairs(SLIDER_STYLE_DEFAULTS) do
        if style[_k] == nil then style[_k] = _v end
    end

    -- P1.1: normalize range defensively. Never divide by zero → NaN.
    local min = tonumber(config.Min) or 0
    local max = tonumber(config.Max) or 100
    if max < min then min, max = max, min end
    if max == min then max = min + 1 end  -- guarantee a non-zero span
    local precision = type(config.Precision) == "number"
        and math.clamp(config.Precision, 0, 6)
        or 0
    local callback  = config.Callback  or function() end
    local enabled   = true
    local _destroyed = false
    local value     = math.clamp(tonumber(config.Default) or min, min, max)

    -- ─── Frames ────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "SliderComponent",
        Size             = UDim2.new(1, 0, 0, style.Height),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, style.Corner)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, style.PadTop, style.PadBot, style.PadL, style.PadR)

    if debugId then
        frame:SetAttribute("DeliriumDebugId", debugId)
    end

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, -60, 0, 18),
        BackgroundTransparency = 1,
        Text               = config.Title or config.Name or config.Text or "Slider",
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 14,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = frame,
    })

    local valueLabel = ComponentHelper.Create("TextLabel", {
        Name               = "ValueLabel",
        Size               = UDim2.new(0, 50, 0, 18),
        Position           = UDim2.new(1, -50, 0, 0),
        BackgroundTransparency = 1,
        Text               = tostring(value),
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 13,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Right,
        Parent             = frame,
    })

    local track = ComponentHelper.Create("Frame", {
        Name             = "Track",
        Size             = UDim2.new(1, 0, 0, style.TrackH),
        Position         = UDim2.new(0, 0, 1, -(style.TrackH + 2)),
        BackgroundColor3 = ThemeEngine.GetToken("SliderTrack"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })
    ComponentHelper.AddCorner(track, math.ceil(style.TrackH / 2))

    local fill = ComponentHelper.Create("Frame", {
        Name             = "Fill",
        Size             = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = ThemeEngine.GetToken("Accent"),
        BorderSizePixel  = 0,
        Parent           = track,
    })
    ComponentHelper.AddCorner(fill, math.ceil(style.TrackH / 2))

    local hitArea = ComponentHelper.Create("TextButton", {
        Name               = "HitArea",
        Size               = UDim2.new(1, 0, 0, 44),  -- taller hit area for mobile
        Position           = UDim2.new(0, 0, 0.5, -22),
        BackgroundTransparency = 1,
        Text               = "",
        Parent             = track,
    })

    -- ─── Signals ───────────────────────────────────────────────────────────

    local OnChanged = Signal.new()

    -- ─── Value logic ───────────────────────────────────────────────────────

    local function computeValue(screenX: number): number
        local pct    = math.clamp((screenX - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local raw    = min + pct * (max - min)
        local factor = 10 ^ precision
        return math.round(raw * factor) / factor
    end

    local lastFireTime  = 0
    local FIRE_THROTTLE = 0.035  -- max ~28 Hz signal fire rate during rapid drag

    local function applyValue(newVal: number, forceFire: boolean?)
        local valueChanged = (newVal ~= value)
        if not valueChanged and not forceFire then return end
        value = newVal
        valueLabel.Text = tostring(value)
        local ratio = (value - min) / (max - min)
        TweenHelper.Tween(fill, TweenHelper.FastInfo, { Size = UDim2.new(ratio, 0, 1, 0) })

        local now = os.clock()
        if forceFire or (valueChanged and (now - lastFireTime >= FIRE_THROTTLE)) then
            lastFireTime = now
            OnChanged:Fire(value)
        end
    end

    -- ─── Gesture state ─────────────────────────────────────────────────────
    --
    -- Three-state touch machine:
    --   IDLE         dragging=false, touchPending=false
    --   PENDING      dragging=false, touchPending=true   ← value NEVER changes here
    --   OWNING       dragging=true,  touchPending=false  ← slider owns gesture
    --   YIELDED      dragging=false, touchPending=false  ← page scroll owns, slider stays idle
    --
    -- Mouse has no PENDING state — immediately enters OWNING on MouseButton1Down.

    local dragging          = false   -- true = slider owns gesture, value updates allowed
    local touchPending      = false   -- true = finger down, intent not yet classified
    local touchStartX       = 0
    local touchStartY       = 0
    local globalConns       = {}
    local activeSliderTouch = nil     -- P3: touch InputObject that started the active gesture
    local pointerOwner      = {}      -- P3: unique table identity for InputAdapter.ClaimPointer

    local function resetGesture()
        if dragging then
            applyValue(value, true)  -- force fire exact final value on release
        end
        dragging          = false
        touchPending      = false
        activeSliderTouch = nil
        -- P3: Release pointer ownership so other components can claim.
        InputAdapter.ReleasePointer(pointerOwner)
    end

    -- Mouse: no threshold, immediate ownership.
    -- M1 fix: MouseButton1Down fires for Touch inputs too (Roblox fires it as a
    -- compatibility alias whenever a finger taps a TextButton). Without this guard,
    -- every finger-down on the Slider immediately calls applyValue and snaps the
    -- knob — bypassing the PENDING → intent-classification pipeline entirely and
    -- changing the value even when the user only intends to scroll the page.
    --
    -- Roblox's event ordering guarantees InputBegan(Touch) fires BEFORE
    -- MouseButton1Down, so GetLastInputType() already returns Touch by the time
    -- this handler runs. Touch ownership is handled by the InputBegan → PENDING
    -- → InputChanged chain; we only want MouseButton1Down for real mouse clicks.
    table.insert(globalConns, hitArea.MouseButton1Down:Connect(function()
        if not enabled then return end
        if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then return end
        -- P3: Claim pointer ownership. Blocks if another component holds it.
        if not InputAdapter.ClaimPointer(pointerOwner) then return end
        dragging     = true
        touchPending = false
        applyValue(computeValue(UserInputService:GetMouseLocation().X))
    end))

    -- Touch begin: enter PENDING, record start position, do NOT change value
    table.insert(globalConns, hitArea.InputBegan:Connect(function(input)
        if not enabled then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        -- P3: Ignore new touches while a gesture is already active on this slider.
        if activeSliderTouch ~= nil then return end
        -- P3: Block if another component already owns the pointer.
        if InputAdapter.GetPointerOwner() ~= nil then return end
        touchStartX       = input.Position.X
        touchStartY       = input.Position.Y
        touchPending      = true
        dragging          = false  -- ownership NOT confirmed yet
        activeSliderTouch = input  -- P3: record which touch started this gesture
    end))

    -- Global move: intent classification + value update
    table.insert(globalConns, UserInputService.InputChanged:Connect(function(input)
        if not enabled then return end

        -- ── Mouse drag ────────────────────────────────────────────────────
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            if dragging then
                applyValue(computeValue(input.Position.X))
            end
            return
        end

        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        -- P3: Touch identity check — only process the touch that started this gesture.
        if input ~= activeSliderTouch then return end

        -- ── Touch: classify intent while PENDING ──────────────────────────
        if touchPending then
            local dx = math.abs(input.Position.X - touchStartX)
            local dy = math.abs(input.Position.Y - touchStartY)
            local totalDelta = math.sqrt(dx * dx + dy * dy)

            if totalDelta >= InputAdapter.GESTURE_THRESHOLD then
                touchPending = false  -- leave PENDING regardless of direction
                if dx >= dy * HORIZONTAL_DOMINANCE then
                    -- Horizontal intent confirmed → slider owns gesture.
                    -- P3: Claim pointer ownership; yield if another component beat us.
                    if not InputAdapter.ClaimPointer(pointerOwner) then
                        dragging = false
                        return
                    end
                    dragging = true
                else
                    -- Vertical or ambiguous → yield to page scroll.
                    -- activeSliderTouch stays set so InputEnded cleans up correctly.
                    dragging = false
                end
            end
            -- Still under threshold: remain PENDING, do nothing
            return
        end

        -- ── Touch: OWNING → update value ──────────────────────────────────
        if dragging then
            applyValue(computeValue(input.Position.X))
        end
    end))

    -- Release: reset gesture for the active input only
    table.insert(globalConns, UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Mouse release always ends slider gesture.
            resetGesture()
        elseif input.UserInputType == Enum.UserInputType.Touch then
            -- P3: Only reset if this is the touch that started the gesture.
            -- An unrelated second finger ending must not cancel the active drag.
            if input == activeSliderTouch then
                resetGesture()
            end
        end
    end))

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        frame.BackgroundColor3  = tokens.Surface
        stroke.Color            = tokens.Border
        titleLabel.TextColor3   = tokens.Text
        valueLabel.TextColor3   = tokens.SubText
        track.BackgroundColor3  = tokens.SliderTrack
        fill.BackgroundColor3   = tokens.Accent
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = setmetatable({}, {
        __tostring = function(self)
            return self:GetDisplay()
        end
    })

    function api:Get(): number
        return value
    end

    function api:GetDisplay(): string
        return tostring(value)
    end

    function api:Set(val: number)
        local clamped = math.clamp(val, min, max)
        local factor  = 10 ^ precision
        clamped = math.round(clamped * factor) / factor
        value = clamped
        valueLabel.Text = tostring(value)
        local ratio = (value - min) / (max - min)
        TweenHelper.Tween(fill, TweenHelper.FastInfo, { Size = UDim2.new(ratio, 0, 1, 0) })
        -- config.Callback is auto-bound to OnChanged via ComponentHelper.BindCallback.
        -- Firing OnChanged is sufficient — do NOT call config.Callback directly
        -- here or the callback would fire twice on every Set().
        OnChanged:Fire(value)
    end

    function api:Enable()
        enabled = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo,
            { TextColor3 = ThemeEngine.GetToken("Text") })
        TweenHelper.Tween(fill, TweenHelper.FastInfo,
            { BackgroundColor3 = ThemeEngine.GetToken("Accent") })
    end

    function api:Disable()
        enabled = false
        resetGesture()
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo,
            { TextColor3 = ThemeEngine.GetToken("DisabledText") })
        TweenHelper.Tween(fill, TweenHelper.FastInfo,
            { BackgroundColor3 = ThemeEngine.GetToken("DisabledText") })
    end

    function api:SetTitle(title: string)
        titleLabel.Text = title
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        resetGesture()
        themeDisconnect()
        for _, conn in ipairs(globalConns) do conn:Disconnect() end
        table.clear(globalConns)
        OnChanged:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnChanged = OnChanged
    api._debugId  = debugId or nil

    return api
end

return Slider

end

-- ── Components.TextBox ────────────────────────────────────
_Delirium_modules["Components.TextBox"] = function()
-- Components/TextBox.lua

local UserInputService = game:GetService("UserInputService")
-- local Root            = script.Parent.Parent
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local InputAdapter    = _Delirium_require("Core.InputAdapter")
local Signal          = _Delirium_require("Utilities.Signal")
local VariantEngine   = _Delirium_require("Core.VariantEngine")

local TextBox = {}

function TextBox.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style       = VariantEngine.Resolve("TextBox", config.Variant)
    local title       = config.Title or config.Name or config.Text or "Input"
    local desc        = config.Description  or ""
    local placeholder = config.Placeholder  or "Type here..."
    local defaultText = config.Default      or ""
    local enabled     = true
    local _destroyed  = false

    local OnChanged = Signal.new()
    local OnSubmit  = Signal.new()

    -- ─── Row ───────────────────────────────────────────────────────────────

    local Row = ComponentHelper.Create("Frame", {
        Name             = "TextBoxRow",
        Size             = UDim2.new(1, 0, 0, style.RowH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        ClipsDescendants = true,
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(Row, style.Corner)
    local rowStroke = ComponentHelper.AddStroke(Row, ThemeEngine.GetToken("Border"), 1)

    if debugId then
        Row:SetAttribute("DeliriumDebugId", debugId)
    end

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
        Position           = UDim2.new(1 - style.InputWScale - 0.03, 0, 0, 6),
        Size               = UDim2.new(style.InputWScale, 0, 0, style.InputH),
        BackgroundColor3   = ThemeEngine.GetToken("InputBackground"),
        Text               = defaultText,
        PlaceholderText    = placeholder,
        PlaceholderColor3  = ThemeEngine.GetToken("SubText"),
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 12,
        Font               = Enum.Font.Gotham,
        TextTruncate       = Enum.TextTruncate.AtEnd,   -- clip long text; never overflow row
        ClearTextOnFocus   = config.ClearOnFocus == true,
        TextEditable       = true,
        Parent             = Row,
    })
    ComponentHelper.AddCorner(InputBox, 6)
    local inputStroke = ComponentHelper.AddStroke(InputBox, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(InputBox, 0, 0, 6, 6)

    -- ─── Mobile expanded editor ────────────────────────────────────────────
    -- On touch devices, tapping a TextBox opens a full-screen modal editor
    -- so the user has a large comfortable editing area with Done/Cancel.
    -- The compact InputBox becomes read-only on mobile; the editor owns text input.
    --
    -- Editor structure (parented to the first ScreenGui ancestor):
    --   Backdrop (TextButton, ZIndex 500) — dims screen, click = cancel
    --     Card (Frame, ZIndex 501)
    --       Header label
    --       MultilineBox (TextBox, multiline)
    --       Button row: Cancel | Done

    -- ─── Mobile editor state ───────────────────────────────────────────────
    -- _fullText: canonical value — may contain \n from multiline editor.
    --            api:Get() returns this; InputBox.Text is display-only (first line).
    -- _toDisplayText: converts multiline to a compact single-line preview.
    -- _returnConn: UserInputService listener for Enter key (M6A); cleaned by _closeEditor.

    local _editorOpen    = false
    local _editorBackdrop = nil
    local _returnConn    = nil
    local _fullText      = defaultText   -- M6: canonical value across open/close cycles

    local function _toDisplayText(text: string): string
        -- Show first line + ellipsis when text is multiline.
        -- Keeps compact InputBox from rendering broken multiline in a 30px box.
        local firstLine = text:match("([^\n]*)")
        if firstLine ~= text then
            return firstLine .. " …"
        end
        return text
    end

    local function _closeEditor(commit: boolean)
        if not _editorOpen then return end
        _editorOpen = false
        -- M6A: disconnect Enter listener so it doesn't fire outside editor lifetime
        if _returnConn then
            _returnConn:Disconnect()
            _returnConn = nil
        end
        if _editorBackdrop then
            _editorBackdrop:Destroy()
            _editorBackdrop = nil
        end
    end

    local function _openEditor()
        if _editorOpen then return end
        if not InputAdapter.IsTouch then return end  -- desktop: let InputBox handle it normally
        _editorOpen = true

        -- Find the root ScreenGui to parent the overlay
        local screenGui = Row:FindFirstAncestorWhichIsA("ScreenGui")
        if not screenGui then
            _editorOpen = false
            return
        end

        -- Backdrop
        local backdrop = ComponentHelper.Create("TextButton", {
            Name                   = "TextBoxEditorBackdrop",
            Size                   = UDim2.fromScale(1, 1),
            Position               = UDim2.fromScale(0, 0),
            BackgroundColor3       = ThemeEngine.GetToken("Overlay"),
            BackgroundTransparency = 0.45,
            Text                   = "",
            AutoButtonColor        = false,
            ZIndex                 = 500,
            Parent                 = screenGui,
        })
        _editorBackdrop = backdrop

        -- Card
        -- M4 fix: 56px total horizontal margin (28px each side) keeps visible
        -- breathing room on narrow phones; cap at 360px avoids over-wide cards
        -- on wider phones. Height is viewport-proportional with a sensible ceiling.
        local CARD_W = math.min(screenGui.AbsoluteSize.X - 56, 360)
        local CARD_H = math.min(math.floor(screenGui.AbsoluteSize.Y * 0.45), 240)
        local card = ComponentHelper.Create("Frame", {
            Name             = "TextBoxEditorCard",
            Size             = UDim2.fromOffset(CARD_W, CARD_H),
            AnchorPoint      = Vector2.new(0.5, 0.5),
            Position         = UDim2.fromScale(0.5, 0.42),  -- slightly above center; keyboard sits below
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
            BorderSizePixel  = 0,
            ZIndex           = 501,
            Parent           = backdrop,
        })
        ComponentHelper.AddCorner(card, 10)
        ComponentHelper.AddStroke(card, ThemeEngine.GetToken("Border"), 1)
        ComponentHelper.AddPadding(card, 14, 14, 14, 14)

        -- Header
        ComponentHelper.Create("TextLabel", {
            Name               = "Header",
            Size               = UDim2.new(1, 0, 0, 20),
            BackgroundTransparency = 1,
            Text               = title,
            TextColor3         = ThemeEngine.GetToken("Text"),
            TextSize           = 13,
            Font               = Enum.Font.GothamBold,
            TextXAlignment     = Enum.TextXAlignment.Left,
            ZIndex             = 502,
            Parent             = card,
        })

        -- Multiline editor box
        -- M5 fix: NO UIPadding on the TextBox itself.
        -- Roblox's cursor rendering ignores UIPadding — cursor draws relative to the
        -- TextBox frame origin, so adding UIPadding shifts text 8px right/down while
        -- the cursor stays at x=0, producing visible misalignment.
        -- Card's own 14px UIPadding already provides visual spacing on all sides.
        local editorBox = ComponentHelper.Create("TextBox", {
            Name               = "EditorBox",
            Position           = UDim2.new(0, 0, 0, 30),
            Size               = UDim2.new(1, 0, 1, -80),
            BackgroundColor3   = ThemeEngine.GetToken("InputBackground"),
            Text               = _fullText,   -- M6: use canonical value, not truncated display
            PlaceholderText    = placeholder,
            PlaceholderColor3  = ThemeEngine.GetToken("SubText"),
            TextColor3         = ThemeEngine.GetToken("Text"),
            TextSize           = 13,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextYAlignment     = Enum.TextYAlignment.Top,
            TextWrapped        = true,
            MultiLine          = true,
            ClearTextOnFocus   = false,
            TextEditable       = enabled,
            ZIndex             = 502,
            Parent             = card,
        })
        ComponentHelper.AddCorner(editorBox, 6)
        ComponentHelper.AddStroke(editorBox, ThemeEngine.GetToken("Accent"), 1)
        -- M5: AddPadding intentionally removed (cursor misalignment — see above)

        -- Button row
        local btnRow = ComponentHelper.Create("Frame", {
            Name               = "BtnRow",
            Position           = UDim2.new(0, 0, 1, -38),
            Size               = UDim2.new(1, 0, 0, 36),
            BackgroundTransparency = 1,
            ZIndex             = 502,
            Parent             = card,
        })
        ComponentHelper.AddListLayout(btnRow, {
            FillDirection       = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Right,
            VerticalAlignment   = Enum.VerticalAlignment.Center,
            Padding             = UDim.new(0, 8),
        })

        local cancelBtn = ComponentHelper.Create("TextButton", {
            Name             = "Cancel",
            Size             = UDim2.fromOffset(80, 32),
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceActive"),
            AutoButtonColor  = false,
            Text             = "Cancel",
            TextColor3       = ThemeEngine.GetToken("SubText"),
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            LayoutOrder      = 1,
            ZIndex           = 503,
            Parent           = btnRow,
        })
        ComponentHelper.AddCorner(cancelBtn, 6)

        local doneBtn = ComponentHelper.Create("TextButton", {
            Name             = "Done",
            Size             = UDim2.fromOffset(80, 32),
            BackgroundColor3 = ThemeEngine.GetToken("Accent"),
            AutoButtonColor  = false,
            Text             = "Done",
            TextColor3       = ThemeEngine.GetToken("AccentText"),
            TextSize         = 12,
            Font             = Enum.Font.GothamBold,
            LayoutOrder      = 2,
            ZIndex           = 503,
            Parent           = btnRow,
        })
        ComponentHelper.AddCorner(doneBtn, 6)

        -- Focus the editor immediately
        task.defer(function()
            if editorBox and editorBox.Parent then
                editorBox:CaptureFocus()
            end
        end)

        -- M6B fix: backdrop tap does NOT close the editor.
        -- User must explicitly choose Cancel or Done.
        -- (backdrop still blocks input to the game below it)
        cancelBtn.MouseButton1Click:Connect(function()
            _closeEditor(false)
        end)

        -- Done: commit text and fire signals
        -- M6 fix: store in _fullText; show compact display preview in InputBox
        -- so multiline \n text doesn't break the 30px single-line compact box.
        doneBtn.MouseButton1Click:Connect(function()
            local text = editorBox.Text
            _fullText      = text
            InputBox.Text  = _toDisplayText(text)
            _closeEditor(true)
            OnChanged:Fire(text)
            OnSubmit:Fire(text)
        end)

        -- M6A fix: Enter = Done for MultiLine TextBox.
        -- FocusLost(enterPressed=true) NEVER fires for MultiLine=true TextBoxes —
        -- Roblox inserts \n on Enter and does not treat it as a submit gesture.
        -- Fix: global UserInputService.InputBegan filtered to Return + focused box.
        -- task.defer runs AFTER Roblox inserts the \n so we can strip it cleanly.
        _returnConn = UserInputService.InputBegan:Connect(function(input, _)
            if input.KeyCode ~= Enum.KeyCode.Return then return end
            if not editorBox:IsFocused() then return end
            task.defer(function()
                if not _editorOpen then return end  -- guard: already closed
                -- Strip the trailing newline Roblox inserted for the Return key
                local t = editorBox.Text
                if t:sub(-1) == "\n" then
                    editorBox.Text = t:sub(1, -2)
                end
                local text = editorBox.Text
                _fullText     = text
                InputBox.Text = _toDisplayText(text)
                _closeEditor(true)
                OnChanged:Fire(text)
                OnSubmit:Fire(text)
            end)
        end)

        -- FocusLost fallback — fires for hardware keyboards on some platforms
        -- when the editor loses focus for reasons other than Enter (e.g. Done button
        -- on iOS virtual keyboard which sets enterPressed=false but still dismisses).
        -- Only commit if the popup is still open (guard against double-commit).
        editorBox.FocusLost:Connect(function(enterPressed)
            if enterPressed and _editorOpen then
                local text = editorBox.Text
                _fullText     = text
                InputBox.Text = _toDisplayText(text)
                _closeEditor(true)
                OnChanged:Fire(text)
                OnSubmit:Fire(text)
            end
        end)
    end

    -- ─── Focus animations ──────────────────────────────────────────────────

    -- BUG-05 fix: scroll the parent PageCanvas so the TextBox stays visible
    -- when the mobile keyboard pushes the viewport upward.
    -- Walks up the ancestor chain to find the first ScrollingFrame (Tab's PageCanvas),
    -- then adjusts CanvasPosition if the Row is below the visible region.
    -- task.defer gives Roblox one frame to resolve AbsolutePosition after focus.
    local function _scrollIntoView()
        task.defer(function()
            if not Row or not Row.Parent then return end
            local canvas = Row:FindFirstAncestorWhichIsA("ScrollingFrame")
            if not canvas then return end

            local rowAbsY    = Row.AbsolutePosition.Y
            local canvasAbsY = canvas.AbsolutePosition.Y
            local scrollY    = canvas.CanvasPosition.Y
            local visibleH   = canvas.AbsoluteSize.Y
            local rowH       = Row.AbsoluteSize.Y

            -- Position of Row relative to canvas content top
            local relTop    = rowAbsY - canvasAbsY + scrollY
            local relBottom = relTop + rowH

            -- If the bottom of the Row is below the visible window, scroll down.
            if relBottom > scrollY + visibleH then
                canvas.CanvasPosition = Vector2.new(0, relBottom - visibleH + 8)
            -- If the top of the Row is above the visible window, scroll up.
            elseif relTop < scrollY then
                canvas.CanvasPosition = Vector2.new(0, relTop - 8)
            end
        end)
    end

    InputBox.Focused:Connect(function()
        if not enabled then
            InputBox:ReleaseFocus()
            return
        end
        -- On touch: release InputBox focus immediately and open expanded editor.
        -- The expanded editor owns all text input; the compact box is display-only.
        if InputAdapter.IsTouch then
            InputBox:ReleaseFocus()
            _openEditor()
            return
        end
        TweenHelper.Tween(inputStroke, TweenHelper.FastInfo, {
            Color = ThemeEngine.GetToken("Accent"),
        })
        TweenHelper.Tween(Row, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        })
        _scrollIntoView()
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
        Row.BackgroundColor3         = tokens.Surface
        rowStroke.Color              = tokens.Border
        titleLabel.TextColor3        = tokens.Text
        InputBox.BackgroundColor3    = tokens.InputBackground
        InputBox.TextColor3          = tokens.Text
        InputBox.PlaceholderColor3   = tokens.SubText
        inputStroke.Color            = tokens.Border
        if descLabel then descLabel.TextColor3 = tokens.SubText end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = setmetatable({}, {
        __tostring = function(self)
            return self:GetDisplay()
        end
    })

    function api:Get(): string
        -- M6: return canonical _fullText, not the truncated display value
        return _fullText
    end

    function api:GetDisplay(): string
        return _fullText
    end

    function api:Set(text: string)
        _fullText     = tostring(text)
        InputBox.Text = _toDisplayText(_fullText)
        OnChanged:Fire(_fullText)
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
        if _destroyed then return end
        _destroyed = true
        _closeEditor(false)   -- dismiss expanded editor if open
        themeDisconnect()
        OnChanged:Destroy()
        OnSubmit:Destroy()
        Row:Destroy()
    end

    api.Instance  = Row
    api.OnChanged = OnChanged
    api.OnSubmit  = OnSubmit
    api._debugId  = debugId or nil

    return api
end

return TextBox

end

-- ── Components.Toggle ─────────────────────────────────────
_Delirium_modules["Components.Toggle"] = function()
-- Components/Toggle.lua
-- local Root            = script.Parent.Parent
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local Signal          = _Delirium_require("Utilities.Signal")
local VariantEngine   = _Delirium_require("Core.VariantEngine")

local Toggle = {}

function Toggle.New(parent: Instance, config: table, debugId: string?)
    config = config or {}
    local style    = VariantEngine.Resolve("Toggle", config.Variant)
    local callback = config.Callback or function() end
    local hasDesc  = config.Description ~= nil and config.Description ~= ""
    local baseH    = hasDesc and style.HeightDesc or style.Height
    local state    = config.Default == true
    local enabled  = true
    local _destroyed = false

    -- ─── Frames ────────────────────────────────────────────────────────────

    local frame = ComponentHelper.Create("Frame", {
        Name             = "ToggleComponent",
        Size             = UDim2.new(1, 0, 0, baseH),
        BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        BorderSizePixel  = 0,
        Parent           = parent,
    })
    ComponentHelper.AddCorner(frame, style.Corner)
    local stroke = ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)
    ComponentHelper.AddPadding(frame, style.PadTop, style.PadBot, style.PadL, style.PadR)

    if debugId then
        frame:SetAttribute("DeliriumDebugId", debugId)
    end

    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, -52, hasDesc and 0.5 or 1, 0),
        BackgroundTransparency = 1,
        Text               = config.Title or config.Name or config.Text or "Toggle",
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = 14,
        Font               = Enum.Font.GothamMedium,
        TextXAlignment     = Enum.TextXAlignment.Left,
        Parent             = frame,
    })

    local descLabel
    if hasDesc then
        descLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Description",
            Size               = UDim2.new(1, -52, 0.5, 0),
            Position           = UDim2.new(0, 0, 0.5, 0),
            BackgroundTransparency = 1,
            Text               = config.Description,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = 11,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            Parent             = frame,
        })
    end

    -- Switch track
    local track = ComponentHelper.Create("Frame", {
        Name             = "Track",
        Size             = UDim2.new(0, style.TrackW, 0, style.TrackH),
        Position         = UDim2.new(1, -style.TrackW, 0.5, -style.TrackH/2),
        BackgroundColor3 = state and ThemeEngine.GetToken("Accent") or ThemeEngine.GetToken("ToggleOff"),
        BorderSizePixel  = 0,
        Parent           = frame,
    })
    ComponentHelper.AddCorner(track, math.ceil(style.TrackH / 2))

    -- Switch knob
    local knobH   = style.KnobSize
    local knobOff = math.floor((style.TrackH - knobH) / 2)  -- vertical centering offset from track edge
    local knob = ComponentHelper.Create("Frame", {
        Name             = "Knob",
        Size             = UDim2.new(0, knobH, 0, knobH),
        Position         = state
            and UDim2.new(1, -(knobH + knobOff), 0.5, -knobH/2)
            or  UDim2.new(0, knobOff,             0.5, -knobH/2),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel  = 0,
        Parent           = track,
    })
    ComponentHelper.AddCorner(knob, math.ceil(knobH / 2))

    local triggerBtn = ComponentHelper.Create("TextButton", {
        Size               = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text               = "",
        Parent             = frame,
    })

    -- ─── Signals ───────────────────────────────────────────────────────────

    local OnChanged = Signal.new()

    -- ─── State management ─────────────────────────────────────────────────

    local function applyState(newState: boolean, animate: boolean)
        state = newState
        local trackColor = state and ThemeEngine.GetToken("Accent") or ThemeEngine.GetToken("ToggleOff")
        local knobPos    = state
            and UDim2.new(1, -(knobH + knobOff), 0.5, -knobH/2)
            or  UDim2.new(0, knobOff,             0.5, -knobH/2)

        if animate then
            TweenHelper.Tween(track, TweenHelper.FastInfo, { BackgroundColor3 = trackColor })
            TweenHelper.Tween(knob,  TweenHelper.SpringInfo, { Position = knobPos })
        else
            track.BackgroundColor3 = trackColor
            knob.Position          = knobPos
        end

        OnChanged:Fire(state)
    end

    triggerBtn.MouseButton1Click:Connect(function()
        if not enabled then return end
        applyState(not state, true)
    end)

    -- Hover feedback
    triggerBtn.MouseEnter:Connect(function()
        if not enabled then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("SurfaceHover"),
        })
    end)
    triggerBtn.MouseLeave:Connect(function()
        if not enabled then return end
        TweenHelper.Tween(frame, TweenHelper.FastInfo, {
            BackgroundColor3 = ThemeEngine.GetToken("Surface"),
        })
    end)

    -- ─── Theme updates ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        frame.BackgroundColor3  = tokens.Surface
        stroke.Color            = tokens.Border
        titleLabel.TextColor3   = tokens.Text
        track.BackgroundColor3  = state and tokens.Accent or tokens.ToggleOff
        if descLabel then descLabel.TextColor3 = tokens.SubText end
    end)

    -- ─── Public API ────────────────────────────────────────────────────────

    local api = setmetatable({}, {
        __tostring = function(self)
            return self:GetDisplay()
        end
    })

    function api:Get(): boolean
        return state
    end

    function api:GetDisplay(): string
        return state and "ON" or "OFF"
    end

    function api:Set(val: boolean)
        applyState(val == true, true)
    end

    function api:Toggle()
        applyState(not state, true)
    end

    function api:Enable()
        enabled = true
        triggerBtn.Active = true
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("Text"),
        })
    end

    function api:Disable()
        enabled = false
        triggerBtn.Active = false
        TweenHelper.Tween(titleLabel, TweenHelper.FastInfo, {
            TextColor3 = ThemeEngine.GetToken("DisabledText"),
        })
    end

    function api:SetTitle(title: string)
        titleLabel.Text = title
    end

    function api:SetDescription(desc: string)
        if descLabel then
            descLabel.Text = desc
        end
    end

    function api:Show()  frame.Visible = true  end
    function api:Hide()  frame.Visible = false end

    function api:Destroy()
        if _destroyed then return end
        _destroyed = true
        themeDisconnect()
        OnChanged:Destroy()
        frame:Destroy()
    end

    api.Instance  = frame
    api.OnChanged = OnChanged
    api._debugId  = debugId or nil

    return api
end

return Toggle

end

-- ── Services.AuthService ──────────────────────────────────
_Delirium_modules["Services.AuthService"] = function()
-- Services/AuthService.lua
-- Client for the Delirium auth backend (Backend/server.js).
--
-- Login gives you a JWT session token. Admin-role tokens can create/list/delete
-- accounts. The token lives in memory only for this session — never persisted
-- to disk by this service (avoids leaking credentials via ConfigService files).
--
-- Setup:
--   AuthService.Configure({ baseUrl = "https://your-backend.example.com" })
--
-- Usage:
--   local ok, err = AuthService.Login("myuser", "mypassword")
--   if ok then
--       if AuthService.IsAdmin() then
--           local ok2, result = AuthService.CreateAccount("newuser", "newpass123", "user")
--       end
--   end

local AuthService = {}

-- ─── State ───────────────────────────────────────────────────────────────────

local _baseUrl  = nil   -- e.g. "https://your-backend.example.com"
local _token    = nil
local _user     = nil   -- { id, username, role, created_at }

-- ─── HTTP transport ──────────────────────────────────────────────────────────
-- Roblox HttpService:RequestAsync is blocked for external hosts on most
-- executors; fall back through common executor request functions.

local HttpService = game:GetService("HttpService")

local function _rawRequest(opts: table)
    local fn = (syn and syn.request)
        or (http and http.request)
        or http_request
        or request
        or (fluxus and fluxus.request)
    if fn then
        local ok, res = pcall(fn, opts)
        if ok then return res end
        return nil, tostring(res)
    end

    -- Fallback to HttpService (works if the game/executor allows it).
    local ok, res = pcall(function()
        return HttpService:RequestAsync({
            Url = opts.Url,
            Method = opts.Method,
            Headers = opts.Headers,
            Body = opts.Body,
        })
    end)
    if ok then return res end
    return nil, tostring(res)
end

local function _request(method: string, path: string, body: table?, useAuth: boolean?)
    if not _baseUrl then
        return false, "AuthService not configured — call AuthService.Configure({ baseUrl = ... }) first"
    end

    local headers = { ["Content-Type"] = "application/json" }
    if useAuth then
        if not _token then
            return false, "not logged in"
        end
        headers["Authorization"] = "Bearer " .. _token
    end

    local res, err = _rawRequest({
        Url = _baseUrl .. path,
        Method = method,
        Headers = headers,
        Body = body and HttpService:JSONEncode(body) or nil,
    })

    if not res then
        return false, "request failed: " .. tostring(err)
    end

    local status = res.StatusCode or res.status_code or res.status
    local rawBody = res.Body or res.body

    local decoded
    if rawBody and #rawBody > 0 then
        local ok, d = pcall(HttpService.JSONDecode, HttpService, rawBody)
        decoded = ok and d or nil
    end

    if not status or status < 200 or status >= 300 then
        local msg = (decoded and decoded.error) or ("HTTP " .. tostring(status))
        return false, msg
    end

    return true, decoded
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Configure the backend URL. Must be called before Login/CreateAccount.
function AuthService.Configure(opts: table)
    assert(type(opts) == "table" and type(opts.baseUrl) == "string" and #opts.baseUrl > 0,
        "AuthService.Configure: opts.baseUrl (string) is required")
    -- Strip trailing slash so path concatenation doesn't produce "//api/..."
    _baseUrl = (opts.baseUrl:gsub("/+$", ""))
end

-- Log in with username + password. Stores the session token in memory on success.
-- Returns true, user  or  false, errorMessage
function AuthService.Login(username: string, password: string)
    local ok, result = _request("POST", "/api/login", { username = username, password = password })
    if not ok then
        return false, result
    end
    _token = result.token
    _user  = result.user
    return true, _user
end

-- Clears the in-memory session.
function AuthService.Logout()
    _token = nil
    _user  = nil
end

function AuthService.IsLoggedIn(): boolean
    return _token ~= nil
end

function AuthService.IsAdmin(): boolean
    return _user ~= nil and _user.role == "admin"
end

-- Returns a copy of the current user's public info, or nil if not logged in.
function AuthService.GetCurrentUser(): table?
    if not _user then return nil end
    local copy = {}
    for k, v in pairs(_user) do copy[k] = v end
    return copy
end

-- Admin-only: create a new account.
-- role: "user" (default) or "admin"
-- Returns true, user  or  false, errorMessage
function AuthService.CreateAccount(username: string, password: string, role: string?)
    if not AuthService.IsAdmin() then
        return false, "only an admin session can create accounts"
    end
    local ok, result = _request("POST", "/api/accounts", {
        username = username,
        password = password,
        role = role,
    }, true)
    if not ok then
        return false, result
    end
    return true, result.user
end

-- Admin-only: list all accounts.
function AuthService.ListAccounts()
    if not AuthService.IsAdmin() then
        return false, "only an admin session can list accounts"
    end
    local ok, result = _request("GET", "/api/accounts", nil, true)
    if not ok then
        return false, result
    end
    return true, result.users
end

-- Admin-only: delete an account by id.
function AuthService.DeleteAccount(userId: number)
    if not AuthService.IsAdmin() then
        return false, "only an admin session can delete accounts"
    end
    local ok, result = _request("DELETE", "/api/accounts/" .. tostring(userId), nil, true)
    if not ok then
        return false, result
    end
    return true
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("AuthService", {
    Reset = function()
        -- Session does NOT survive a re-exec — force re-login for safety.
        _token = nil
        _user  = nil
    end,
}, 20)

return AuthService

end

-- ── Services.ConfigService ────────────────────────────────
_Delirium_modules["Services.ConfigService"] = function()
-- Services/ConfigService.lua
-- Persistent key-value configuration storage.
-- Profiles are singletons — GetProfile("name") always returns the same object.
-- Relies on executor writefile/readfile/delfile (standard exploit environment).
--
-- Usage:
--   local cfg = ConfigService.GetProfile("MyMenu")
--   cfg:Set("volume", 0.8)
--   local vol = cfg:Get("volume", 1.0)  -- 1.0 is the default
--   cfg:Save()
--   cfg:Load()

local ConfigService = {}

-- ─── Constants ────────────────────────────────────────────────────────────────

local FILE_PREFIX = "delirium_cfg_"

-- ─── JSON codec (flat objects only) ──────────────────────────────────────────
-- We don't want a full JSON dep for simple string/number/boolean config data.
--
-- Safety rules (P1.3):
--   * Only string / number / boolean values are persisted.
--   * Unsupported types (tables, functions, userdata) are NEVER silently
--     stringified — the key is skipped with a warning instead. This prevents
--     fabricated/deceptive data from corrupting the config file.
--   * NaN / +/-Inf numbers are skipped (they are not valid JSON).
--   * String keys and values escape ALL control characters (< 0x20), not just
--     quote/backslash/newline, so round-tripping never corrupts text.

local function _jsonEscapeString(s: string): string
    return (s:gsub("[\0-\31\\\"]", function(c)
        local b = c:byte()
        if b == 92 then return "\\\\"       -- backslash
        elseif b == 34 then return "\\\""   -- double quote
        elseif b == 10 then return "\\n"
        elseif b == 13 then return "\\r"
        elseif b == 9  then return "\\t"
        elseif b == 8  then return "\\b"
        elseif b == 12 then return "\\f"
        else return string.format("\\u%04x", b) end
    end))
end

local function _jsonEncode(t: table): string
    local parts = {}
    for k, v in pairs(t) do
        -- JSON keys must be strings (numbers are stringified conventionally).
        local kt = type(k)
        if kt ~= "string" and kt ~= "number" then
            warn("ConfigService: skipping unsupported key type '" .. kt .. "' during encode")
        end
        local ks = (kt == "number")
            and '"' .. _jsonEscapeString(tostring(k)) .. '"'
            or  '"' .. _jsonEscapeString(k) .. '"'

        local vt = type(v)
        local vs
        if vt == "string" then
            vs = '"' .. _jsonEscapeString(v) .. '"'
        elseif vt == "boolean" then
            vs = tostring(v)
        elseif vt == "number" then
            if v ~= v or v == math.huge or v == -math.huge then
                warn("ConfigService: skipping non-finite value for key '" .. tostring(k) .. "' (NaN/Inf is not valid JSON)")
            else
                vs = tostring(v)
            end
        else
            -- Never silently coerce unsupported values to strings.
            warn("ConfigService: skipping unsupported value type '" .. vt .. "' for key '" .. tostring(k) .. "'")
        end

        if vs ~= nil then
            table.insert(parts, ks .. ":" .. vs)
        end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function _jsonDecode(s: string): table
    local result = {}
    -- Strip outer braces
    local inner = s:match("^%s*{(.*)}%s*$")
    if not inner or inner == "" then return result end

    -- Walk the string matching "key": value pairs.
    -- Handles string values (with escapes), booleans, numbers.
    local pos = 1
    local len = #inner

    local function skipWS()
        while pos <= len and inner:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end

    local function readString(): string?
        if inner:sub(pos, pos) ~= '"' then return nil end
        pos = pos + 1
        local out = {}
        while pos <= len do
            local ch = inner:sub(pos, pos)
            if ch == '"' then
                pos = pos + 1
                return table.concat(out)
            elseif ch == '\\' then
                pos = pos + 1
                local esc = inner:sub(pos, pos)
                if esc == '"' then table.insert(out, '"')
                elseif esc == 'n' then table.insert(out, '\n')
                elseif esc == 't' then table.insert(out, '\t')
                elseif esc == 'r' then table.insert(out, '\r')
                elseif esc == 'b' then table.insert(out, '\b')
                elseif esc == 'f' then table.insert(out, '\f')
                elseif esc == '/' then table.insert(out, '/')
                elseif esc == '\\' then table.insert(out, '\\')
                elseif esc == 'u' then
                    -- \uXXXX — decode BMP code point to UTF-8 (best effort).
                    local hex = inner:sub(pos + 1, pos + 4)
                    if #hex == 4 and hex:match("^%x+$") then
                        local cp = tonumber(hex, 16) or 0
                        pos = pos + 4
                        if cp < 0x80 then
                            table.insert(out, string.char(cp))
                        elseif cp < 0x800 then
                            table.insert(out, string.char(
                                0xC0 + math.floor(cp / 0x40),
                                0x80 + (cp % 0x40)
                            ))
                        else
                            table.insert(out, string.char(
                                0xE0 + math.floor(cp / 0x1000),
                                0x80 + (math.floor(cp / 0x40) % 0x40),
                                0x80 + (cp % 0x40)
                            ))
                        end
                    else
                        table.insert(out, 'u')  -- malformed — keep literal
                    end
                else
                    table.insert(out, esc)
                end
                pos = pos + 1
            else
                table.insert(out, ch)
                pos = pos + 1
            end
        end
        return table.concat(out)
    end

    local function readValue(): any
        skipWS()
        local ch = inner:sub(pos, pos)
        if ch == '"' then
            return readString()
        elseif inner:sub(pos, pos + 3) == "true" then
            pos = pos + 4; return true
        elseif inner:sub(pos, pos + 4) == "false" then
            pos = pos + 5; return false
        elseif inner:sub(pos, pos + 3) == "null" then
            pos = pos + 4; return nil
        else
            -- Number
            local numStr = inner:match("^%-?%d+%.?%d*[eE]?[%+%-]?%d*", pos)
            if numStr then
                pos = pos + #numStr
                return tonumber(numStr)
            end
        end
        return nil
    end

    while pos <= len do
        skipWS()
        if pos > len then break end
        -- Expect a key
        local key = readString()
        if not key then break end
        skipWS()
        -- Expect ':'
        if inner:sub(pos, pos) ~= ':' then break end
        pos = pos + 1
        -- Read value
        local val = readValue()
        if key and val ~= nil then
            result[key] = val
        end
        skipWS()
        -- Optional ','
        if inner:sub(pos, pos) == ',' then
            pos = pos + 1
        end
    end

    return result
end

-- ─── File path ───────────────────────────────────────────────────────────────

local function _filepath(name: string): string
    -- Sanitize: lowercase, replace non-alphanumeric/underscore with underscore
    return FILE_PREFIX .. name:lower():gsub("[^%w_%-]", "_") .. ".json"
end

-- ─── Profile ──────────────────────────────────────────────────────────────────

local Profile    = {}
Profile.__index  = Profile

function Profile.new(name: string): table
    local self     = setmetatable({}, Profile)
    self._name     = name
    self._path     = _filepath(name)
    self._data     = {}
    self._dirty    = false
    self:Load()
    return self
end

-- Get a value. Returns `default` if the key is not set.
function Profile:Get(key: string, default: any): any
    local v = self._data[key]
    return v ~= nil and v or default
end

-- Set a value in memory. Does NOT auto-save; call :Save() to persist.
function Profile:Set(key: string, value: any)
    self._data[key] = value
    self._dirty     = true
end

-- Remove a key from memory. Does NOT auto-save.
function Profile:Delete(key: string)
    self._data[key] = nil
    self._dirty     = true
end

-- Reset all keys in memory. Does NOT auto-save.
function Profile:Reset()
    table.clear(self._data)
    self._dirty = true
end

-- Returns true if there are unsaved in-memory changes.
function Profile:IsDirty(): boolean
    return self._dirty
end

-- Persist current in-memory data to disk.
-- Returns true on success.
function Profile:Save(): boolean
    local ok, err = pcall(writefile, self._path, _jsonEncode(self._data))
    if not ok then
        warn(string.format(
            "ConfigService: save failed for profile '%s' — %s",
            self._name, tostring(err)
        ))
        return false
    end
    self._dirty = false
    return true
end

-- Load data from disk into memory, replacing current in-memory state.
-- Silently no-ops if the file doesn't exist yet.
-- Returns true if data was loaded.
function Profile:Load(): boolean
    local ok, content = pcall(readfile, self._path)
    if not ok or not content or #content == 0 then
        return false  -- file doesn't exist yet, first run
    end
    local decoded = _jsonDecode(content)
    self._data  = decoded
    self._dirty = false
    return true
end

-- Returns a shallow copy of all stored key-value pairs.
function Profile:GetAll(): table
    local copy = {}
    for k, v in pairs(self._data) do
        copy[k] = v
    end
    return copy
end

-- Returns the profile name.
function Profile:GetName(): string
    return self._name
end

-- ─── ConfigService API ────────────────────────────────────────────────────────

local _profiles: {[string]: typeof(Profile.new(""))} = {}

-- Get (or create) a named config profile.
-- Profiles are singletons — same name always returns the same object in-session.
-- Data is auto-loaded from disk on first access.
function ConfigService.GetProfile(name: string)
    assert(type(name) == "string" and #name > 0,
        "ConfigService.GetProfile: name must be a non-empty string")
    if not _profiles[name] then
        _profiles[name] = Profile.new(name)
    end
    return _profiles[name]
end

-- Save all active profiles that have unsaved changes.
function ConfigService.SaveAll()
    for _, profile in pairs(_profiles) do
        if profile:IsDirty() then
            profile:Save()
        end
    end
end

-- Force-save all profiles regardless of dirty state.
function ConfigService.SaveAllForce()
    for _, profile in pairs(_profiles) do
        profile:Save()
    end
end

-- Delete a profile's file from disk and evict it from the cache.
--
-- Consistent semantics (P1.4):
--   * The in-memory profile is ALWAYS evicted.
--   * Returns true when there is nothing left on disk for this profile:
--       - file deleted successfully, or
--       - file did not exist (already absent — nothing to delete).
--   * Returns false ONLY when the delete operation genuinely fails
--     (executor error beyond "file not found").
function ConfigService.DeleteProfile(name: string): boolean
    local path = _filepath(name)
    _profiles[name] = nil  -- evict cache regardless of disk outcome

    -- File already absent → already deleted. Deterministic across executors.
    -- pcall(isfile, path) returns (ok, result): ok=true means isfile ran without
    -- error and result is whether the file exists. We must check BOTH: not ok means
    -- isfile itself errored (executor missing the API?), not that the file is absent.
    if type(isfile) == "function" then
        local ok, exists = pcall(isfile, path)
        if ok and not exists then
            return true  -- file not present; nothing to delete
        end
    end

    local ok, err = pcall(delfile, path)
    if not ok then
        warn(string.format(
            "ConfigService: DeleteProfile('%s') failed — %s",
            tostring(name), tostring(err)
        ))
        return false
    end
    return true
end

-- Returns a sorted list of profile names currently in the in-memory cache.
function ConfigService.ListProfiles(): {string}
    local names = {}
    for name in pairs(_profiles) do
        table.insert(names, name)
    end
    table.sort(names)
    return names
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("ConfigService", {
    Reset = function()
        -- On re-exec: evict the in-memory cache so fresh Load() happens next time.
        -- Do NOT wipe disk data — persisted config should survive re-execs.
        table.clear(_profiles)
    end,
}, 20)  -- priority 20 — resets before UI services that consume config

return ConfigService

end

-- ── Services.DialogService ────────────────────────────────
_Delirium_modules["Services.DialogService"] = function()
-- Services/DialogService.lua
-- Single-instance modal confirmation dialogs rendered over the full screen.
--
-- Dynamic and reusable — not tied to any specific window or action.
-- Only one dialog active at a time. Subsequent calls while one is active
-- are rejected with a warning (queue support is a future enhancement).
--
-- Usage:
--   local handle = DialogService.Confirm({
--       Title   = "Close window?",
--       Message = "This action cannot be undone.",   -- optional
--       Type    = "Warning",                          -- Info|Warning|Error|Success
--       Confirm = { Label = "Close",  Callback = function() ... end },
--       Cancel  = { Label = "Cancel", Callback = function() ... end },
--       -- Cancel = nil → no cancel button; backdrop click does nothing
--   })
--   handle:Dismiss()  -- programmatic dismiss (fires Cancel.Callback if set)
-- local Root            = script.Parent.Parent
local ThemeEngine     = _Delirium_require("Core.ThemeEngine")
local AnimationEngine = _Delirium_require("Core.AnimationEngine")
local ComponentHelper = _Delirium_require("Utilities.ComponentHelper")
local TweenHelper     = _Delirium_require("Utilities.TweenHelper")
local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

-- ─── Constants ────────────────────────────────────────────────────────────────

local CARD_W         = 300
local BACKDROP_ALPHA = 0.52

-- Type → accent color token (mirrors NotificationService's TYPE_TOKEN)
local TYPE_TOKEN = {
    Info    = "Accent",
    Warning = "Warning",
    Error   = "Error",
    Success = "Positive",
}

-- ─── State ────────────────────────────────────────────────────────────────────

local DialogService = {}

local _screenGui:  ScreenGui = nil
local _activeDialog          = nil
local _initialized           = false

-- ─── Helper for finding root ScreenGui ───────────────────────────────────────

local function _findScreenGui(): ScreenGui?
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local gui = CoreGui:FindFirstChild("DeliriumUI")
    if not gui and Players.LocalPlayer then
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            gui = playerGui:FindFirstChild("DeliriumUI")
        end
    end
    return gui
end

local function _ensureInit(): boolean
    if _initialized and _screenGui and _screenGui.Parent then
        return true
    end
    _initialized = false
    _screenGui   = nil

    local gui = _findScreenGui()
    if gui then
        DialogService.Init(gui)
        return _initialized and _screenGui ~= nil and _screenGui.Parent ~= nil
    end
    return false
end

-- ─── Init / Reset ─────────────────────────────────────────────────────────────

function DialogService.Init(screenGui: ScreenGui)
    if not screenGui then
        screenGui = _findScreenGui()
    end
    if not screenGui then return end
    if _initialized and _screenGui and _screenGui.Parent then return end

    _screenGui   = screenGui
    _initialized = true
end

function DialogService.Reset()
    if _activeDialog then
        pcall(function() _activeDialog:Dismiss() end)
        _activeDialog = nil
    end
    _screenGui   = nil
    _initialized = false
end

-- ─── Internal builder ─────────────────────────────────────────────────────────

local function _buildDialog(config: table)
    local dialogType = config.Type    or "Info"
    local title      = config.Title   or "Confirm"
    local message    = config.Message
    local confirmCfg = type(config.Confirm) == "table" and config.Confirm or {
        Label    = type(config.Confirm) == "string" and config.Confirm or "Confirm",
        Callback = config.OnConfirm or config.Callback,
    }

    local cancelCfg
    if type(config.Cancel) == "table" then
        cancelCfg = config.Cancel
    elseif config.Cancel then
        cancelCfg = {
            Label    = type(config.Cancel) == "string" and config.Cancel or "Cancel",
            Callback = config.OnCancel,
        }
    end

    local hasMessage = message and message ~= ""
    local hasCancel  = cancelCfg ~= nil

    local accentToken = TYPE_TOKEN[dialogType] or "Accent"

    -- Card uses AutomaticSize.Y so long messages expand the card naturally.
    -- A max height is clamped via UISizeConstraint so it never overflows the screen.
    -- The message area is a ScrollingFrame so very long text stays usable.
    local MSG_MAX_H = 160   -- max scrollable message area height
    local cardH     = nil   -- unused now (AutomaticSize drives height)

    -- ─── Backdrop ─────────────────────────────────────────────────────────────
    -- Clickable if cancel is available so clicking outside dismisses the dialog.

    local backdropClass = hasCancel and "TextButton" or "Frame"
    local backdrop = ComponentHelper.Create(backdropClass, {
        Name                   = "DialogBackdrop",
        Size                   = UDim2.fromScale(1, 1),
        Position               = UDim2.fromScale(0, 0),
        BackgroundColor3       = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 1,   -- animated in
        BorderSizePixel        = 0,
        ZIndex                 = 200,
        Parent                 = _screenGui,
    })
    if backdropClass == "TextButton" then
        backdrop.Text            = ""
        backdrop.AutoButtonColor = false
    end

    -- ─── Card ─────────────────────────────────────────────────────────────────

    local card = ComponentHelper.Create("CanvasGroup", {
        Name                   = "DialogCard",
        Size                   = UDim2.fromOffset(CARD_W, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        AnchorPoint            = Vector2.new(0.5, 0.5),
        Position               = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3       = ThemeEngine.GetToken("Surface"),
        GroupTransparency      = 1,   -- animated in smoothly
        BorderSizePixel        = 0,
        ClipsDescendants       = false,
        ZIndex                 = 201,
        Parent                 = backdrop,
    })
    ComponentHelper.AddCorner(card, 10)
    -- Clamp max height to 80% of screen so the dialog never overflows on small phones
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    ComponentHelper.Create("UISizeConstraint", {
        MaxSize = Vector2.new(CARD_W, math.floor(vp.Y * 0.80)),
        Parent  = card,
    })
    ComponentHelper.AddPadding(card, 14, 14, 16, 16)
    ComponentHelper.Create("UIListLayout", {
        SortOrder        = Enum.SortOrder.LayoutOrder,
        Padding          = UDim.new(0, 10),
        HorizontalAlignment = Enum.HorizontalAlignment.Left,
        VerticalAlignment   = Enum.VerticalAlignment.Top,
        Parent           = card,
    })
    -- BUG-C fix: start stroke fully transparent so it fades in with the card
    -- instead of popping visible while the card's BackgroundTransparency is still 1.
    local cardStroke = ComponentHelper.AddStroke(card, ThemeEngine.GetToken("Border"), 1)
    cardStroke.Transparency = 1  -- animated to 0 in Confirm()

    -- Layout-order children flow vertically via the card's UIListLayout.
    -- This replaces fixed Position-based layout so content expands naturally.

    -- Colored left bar is now a thin top accent band instead of a side bar,
    -- compatible with the vertical flow layout.
    local typeBar = ComponentHelper.Create("Frame", {
        Name             = "TypeBar",
        Size             = UDim2.new(1, 0, 0, 3),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        BorderSizePixel  = 0,
        LayoutOrder      = 0,
        ZIndex           = 202,
        Parent           = card,
    })
    ComponentHelper.AddCorner(typeBar, 2)

    -- Title
    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name                   = "Title",
        Size                   = UDim2.new(1, 0, 0, 0),
        AutomaticSize          = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text                   = title,
        TextColor3             = ThemeEngine.GetToken("Text"),
        TextSize               = 13,
        Font                   = Enum.Font.GothamBold,
        TextXAlignment         = Enum.TextXAlignment.Left,
        TextWrapped            = true,
        LayoutOrder            = 1,
        ZIndex                 = 202,
        Parent                 = card,
    })

    -- Message (optional) — in a ScrollingFrame capped at MSG_MAX_H
    local messageLabel
    local msgScroll
    if hasMessage then
        -- Measure approximate natural height with a throwaway label
        msgScroll = ComponentHelper.Create("ScrollingFrame", {
            Name               = "MessageScroll",
            Size               = UDim2.new(1, 0, 0, MSG_MAX_H),  -- will be shrunk if short
            BackgroundTransparency = 1,
            BorderSizePixel    = 0,
            ScrollBarThickness = 3,
            ScrollingDirection = Enum.ScrollingDirection.Y,
            LayoutOrder        = 2,
            ZIndex             = 202,
            Parent             = card,
        })

        messageLabel = ComponentHelper.Create("TextLabel", {
            Name                   = "Message",
            Size                   = UDim2.new(1, -4, 0, 0),
            AutomaticSize          = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text                   = message,
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextSize               = 11,
            Font                   = Enum.Font.Gotham,
            TextXAlignment         = Enum.TextXAlignment.Left,
            TextWrapped            = true,
            ZIndex                 = 202,
            Parent                 = msgScroll,
        })

        -- Shrink scroll area to natural text height when it's short
        messageLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
            local naturalH = messageLabel.AbsoluteSize.Y
            local cappedH  = math.min(naturalH + 4, MSG_MAX_H)
            msgScroll.Size           = UDim2.new(1, 0, 0, cappedH)
            msgScroll.CanvasSize     = UDim2.new(0, 0, 0, naturalH + 4)
        end)
    end

    -- Action row — flows at the bottom via UIListLayout (36px tall for touch)
    local actionRow = ComponentHelper.Create("Frame", {
        Name                   = "ActionRow",
        Size                   = UDim2.new(1, 0, 0, 36),
        BackgroundTransparency = 1,
        LayoutOrder            = 3,
        ZIndex                 = 202,
        Parent                 = card,
    })
    ComponentHelper.AddListLayout(actionRow, {
        FillDirection       = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment   = Enum.VerticalAlignment.Center,
        Padding             = UDim.new(0, 8),
    })

    -- Cancel button (ghost style) — 36px height for comfortable touch target
    local cancelBtn
    if hasCancel then
        cancelBtn = ComponentHelper.Create("TextButton", {
            Name                   = "CancelBtn",
            Size                   = UDim2.fromOffset(80, 36),
            BackgroundColor3       = ThemeEngine.GetToken("Surface"),
            BackgroundTransparency = 0.4,
            AutoButtonColor        = false,
            Text                   = cancelCfg.Label or "Cancel",
            TextColor3             = ThemeEngine.GetToken("SubText"),
            TextSize               = 11,
            Font                   = Enum.Font.GothamBold,
            ZIndex                 = 203,
            LayoutOrder            = 1,
            Parent                 = actionRow,
        })
        ComponentHelper.AddCorner(cancelBtn, 6)
        ComponentHelper.AddStroke(cancelBtn, ThemeEngine.GetToken("Border"), 1)
    end

    -- Confirm button (colored by type) — 36px height for comfortable touch target
    local confirmBtn = ComponentHelper.Create("TextButton", {
        Name             = "ConfirmBtn",
        Size             = UDim2.fromOffset(80, 36),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        AutoButtonColor  = false,
        Text             = confirmCfg.Label or "Confirm",
        TextColor3       = Color3.fromRGB(255, 255, 255),
        TextSize         = 11,
        Font             = Enum.Font.GothamBold,
        ZIndex           = 203,
        LayoutOrder      = 2,
        Parent           = actionRow,
    })
    ComponentHelper.AddCorner(confirmBtn, 6)

    -- ─── Handle ───────────────────────────────────────────────────────────────

    local handle    = {}
    local _alive    = true
    local themeDisc = nil

    local function _dismiss(onDone)
        if not _alive then return end
        _alive        = false
        _activeDialog = nil

        if themeDisc then themeDisc() end

        AnimationEngine.FadeOut(card, TweenHelper.FastInfo)
        AnimationEngine.Play(backdrop, TweenHelper.FastInfo,
            { BackgroundTransparency = 1 }, "dlg_bg")

        task.delay((TweenHelper.FastInfo.Time or 0.12) + 0.02, function()
            if backdrop and backdrop.Parent then
                backdrop:Destroy()
            end
            if onDone then task.spawn(onDone) end
        end)
    end

    -- Theme listener (ephemeral — only during dialog lifetime)
    themeDisc = ThemeEngine.OnThemeChanged(function(tokens)
        if not _alive then return end
        card.BackgroundColor3       = tokens.Surface
        cardStroke.Color            = tokens.Border
        typeBar.BackgroundColor3    = tokens[accentToken] or tokens.Accent
        titleLabel.TextColor3       = tokens.Text
        if messageLabel then
            messageLabel.TextColor3 = tokens.SubText
        end
        if cancelBtn then
            cancelBtn.BackgroundColor3 = tokens.Surface
        end
    end)

    -- Button hover feedback
    if cancelBtn then
        cancelBtn.MouseEnter:Connect(function()
            TweenHelper.Tween(cancelBtn, TweenHelper.FastInfo,
                { BackgroundTransparency = 0.15 }, "cbhov")
        end)
        cancelBtn.MouseLeave:Connect(function()
            TweenHelper.Tween(cancelBtn, TweenHelper.FastInfo,
                { BackgroundTransparency = 0.4 }, "cbhov")
        end)
    end

    confirmBtn.MouseEnter:Connect(function()
        TweenHelper.Tween(confirmBtn, TweenHelper.FastInfo,
            { BackgroundTransparency = 0.18 }, "cfhov")
    end)
    confirmBtn.MouseLeave:Connect(function()
        TweenHelper.Tween(confirmBtn, TweenHelper.FastInfo,
            { BackgroundTransparency = 0 }, "cfhov")
    end)

    -- Button click wiring
    if cancelBtn then
        cancelBtn.MouseButton1Click:Connect(function()
            _dismiss(cancelCfg.Callback)
        end)
    end

    confirmBtn.MouseButton1Click:Connect(function()
        _dismiss(confirmCfg.Callback)
    end)

    -- Backdrop click = cancel (only when cancel button is present)
    if hasCancel and backdropClass == "TextButton" then
        backdrop.MouseButton1Click:Connect(function()
            _dismiss(cancelCfg.Callback)
        end)
    end

    -- Programmatic dismiss
    function handle:Dismiss()
        _dismiss(cancelCfg and cancelCfg.Callback)
    end

    return handle, backdrop, card, cardStroke
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Show a modal confirmation dialog. Returns a handle with :Dismiss().
-- Only one dialog can be active at a time.
function DialogService.Confirm(config: table)
    if not _initialized or not _screenGui or not _screenGui.Parent then
        _ensureInit()
    end
    if not _initialized or not _screenGui or not _screenGui.Parent then
        warn("[DialogService] Cannot Confirm: Service is not initialized and ScreenGui could not be found.")
        return nil
    end
    assert(type(config) == "table",
        "DialogService.Confirm expects a config table")

    if _activeDialog then
        warn("[DialogService] A dialog is already active — dismiss it before showing another.")
        return nil
    end

    local handle, backdrop, card, cardStroke = _buildDialog(config)
    _activeDialog = handle

    -- Animate backdrop in immediately — it's a plain Frame with no AutomaticSize.
    AnimationEngine.Play(backdrop, TweenHelper.DefaultInfo,
        { BackgroundTransparency = BACKDROP_ALPHA }, "dlg_bg")

    -- M10 fix: defer card animations by one frame.
    --
    -- Root cause of first-show jump:
    --   card uses AutomaticSize.Y. At this point in the call (same frame as
    --   _buildDialog), the layout engine hasn't run yet — card.AbsoluteSize.Y = 0.
    --   SlideIn reads card.Position from an element whose height is 0, starts the
    --   tween, then the NEXT frame Roblox resolves AutomaticSize and the card height
    --   snaps from 0 to its real value while the position tween is already playing.
    --   That height snap is the visible jump.
    --
    -- task.defer yields past the current frame (costs ~1 render cycle, ≈ 16ms)
    --   so AutomaticSize resolves before any animation reads card geometry.
    --   The card starts invisible (BackgroundTransparency = 1 set in _buildDialog)
    --   so there is no flash during the deferred frame.
    task.defer(function()
        -- Guard: dialog may have been dismissed before this frame ran.
        if not backdrop or not backdrop.Parent then return end

        -- Avoid Pop() — it snaps Size explicitly and fights AutomaticSize.Y.
        AnimationEngine.FadeIn(card, 1, TweenHelper.DefaultInfo)
        AnimationEngine.SlideIn(card, "Bottom", 14, TweenHelper.SmoothInfo)
        AnimationEngine.Play(cardStroke, TweenHelper.DefaultInfo,
            { Transparency = 0 }, "fade")
    end)

    return handle
end

-- ─── Self-register ────────────────────────────────────────────────────────────

ServiceRegistry.Register("DialogService", {
    Reset = DialogService.Reset,
    Init  = DialogService.Init,
}, 55)  -- priority 55: after ThemeEngine (10) and NotificationService (50)

return DialogService

end

-- ── Services.NotificationService ──────────────────────────
_Delirium_modules["Services.NotificationService"] = function()
-- Services/NotificationService.lua
-- Stacked toast notifications anchored to the top-right of the screen.
--
-- Types:     Info | Success | Warning | Error
-- Features:  Auto-dismiss timeout, timeout progress bar, action button,
--            persistent mode (no auto-dismiss), runtime update (title/message),
--            max-visible cap with overflow queue.
--
-- Initialization:
--   NotificationService.Init(screenGui)  -- called once from Delirium init
--
-- Usage:
--   local handle = NotificationService.Push({
--       Type        = "Success",           -- "Info"|"Success"|"Warning"|"Error"
--       Title       = "Saved",
--       Message     = "Config saved.",     -- optional
--       Duration    = 4,                   -- seconds (0 or nil = persistent)
--       Action      = { Label = "Undo", Callback = function() end },  -- optional
--   })
--   handle:SetMessage("Updated message")
--   handle:Dismiss()

local TweenService     = game:GetService("TweenService")
local GuiService       = game:GetService("GuiService")
-- local Root             = script.Parent.Parent
local ThemeEngine      = _Delirium_require("Core.ThemeEngine")
local AnimationEngine  = _Delirium_require("Core.AnimationEngine")
local ComponentHelper  = _Delirium_require("Utilities.ComponentHelper")

-- ─── Constants ────────────────────────────────────────────────────────────────

local MAX_VISIBLE     = 4        -- maximum toasts shown at once
local NOTIF_GAP       = 8        -- gap between toasts
local MARGIN          = 14       -- margin from screen edge
local ANIM_IN_OFFSET  = 24       -- pixels right-offset for slide-in

-- Notification sizing — compact on mobile, full on desktop.
-- On narrow phones (< 420px wide) use a slimmed-down 220px toast so the
-- notification never covers more than ~56% of the screen and does not
-- block the UI window underneath. Desktop keeps the original 300px cap.
local function _notifWidth(): number
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    if vp.X < 420 then
        return math.min(220, math.floor(vp.X * 0.56))
    end
    return math.min(300, math.floor(vp.X * 0.80))
end

local function _isMobileViewport(): boolean
    local cam = workspace.CurrentCamera
    local vp  = cam and cam.ViewportSize or Vector2.new(1920, 1080)
    return vp.X < 420
end

local NOTIF_WIDTH = _notifWidth()
local ANIM_SLIDE_INFO = TweenInfo.new(0.28, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out)
local ANIM_OUT_INFO   = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.In)
local ANIM_RESTACK    = TweenInfo.new(0.22, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)

-- Type → accent token mapping
local TYPE_TOKEN = {
    Info    = "Accent",
    Success = "Positive",
    Warning = "Warning",
    Error   = "Error",
}

-- ─── State ────────────────────────────────────────────────────────────────────

local NotificationService = {}

local _container: Frame    = nil   -- UIListLayout parent
local _queue:     table    = {}    -- waiting notifications (overflow)
local _visible:   table    = {}    -- currently shown notification handles
local _initialized         = false
local _sessionToken        = 0     -- bumped on Reset/DismissAll(instant); invalidates stale async callbacks

-- ─── Helper for finding root ScreenGui ───────────────────────────────────────

local function _findScreenGui(): ScreenGui?
    local CoreGui = game:GetService("CoreGui")
    local Players = game:GetService("Players")
    local gui = CoreGui:FindFirstChild("DeliriumUI")
    if not gui and Players.LocalPlayer then
        local playerGui = Players.LocalPlayer:FindFirstChild("PlayerGui")
        if playerGui then
            gui = playerGui:FindFirstChild("DeliriumUI")
        end
    end
    return gui
end

local function _ensureInit(): boolean
    if _initialized and _container and _container.Parent then
        return true
    end
    _initialized = false
    _container   = nil

    local gui = _findScreenGui()
    if gui then
        NotificationService.Init(gui)
        return _initialized and _container ~= nil and _container.Parent ~= nil
    end
    return false
end

-- ─── Initialization ───────────────────────────────────────────────────────────

-- Must be called once with the root ScreenGui before any Push calls.
function NotificationService.Init(screenGui: ScreenGui)
    if not screenGui then
        screenGui = _findScreenGui()
    end
    if not screenGui then return end

    if _initialized and _container and _container.Parent then return end
    _initialized = true

    -- Recompute width at init time (camera may not have been ready at module load).
    NOTIF_WIDTH = _notifWidth()

    -- Respect platform safe area: top inset pushes notifications below the
    -- Roblox topbar / notch; right inset keeps them away from the edge.
    local success, topLeft, bottomRight = pcall(GuiService.GetGuiInset, GuiService)
    if not success or not topLeft or typeof(topLeft) ~= "Vector2" then
        topLeft, bottomRight = Vector2.new(0, 36), Vector2.new(0, 0)
    end
    local topInset   = math.max(topLeft.Y,    MARGIN)
    local rightInset = math.max(bottomRight.X, MARGIN)

    if _container and _container.Parent then
        return
    end

    _container = ComponentHelper.Create("Frame", {
        Name            = "DeliriumNotifications",
        AnchorPoint     = Vector2.new(1, 0),
        Position        = UDim2.new(1, -rightInset, 0, topInset),
        Size            = UDim2.new(0, NOTIF_WIDTH, 1, -(topInset + MARGIN)),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex          = 100,
        Parent          = screenGui,
    })
end

-- ─── Internal helpers ─────────────────────────────────────────────────────────

local function _getRightInset(): number
    local _, bottomRight = GuiService:GetGuiInset()
    return math.max(bottomRight.X, MARGIN)
end

-- Calculate target Y offset for the toast at targetIndex in the visible stack
local function _calculateTargetY(targetIndex: number): number
    local y = 0
    for i = 1, targetIndex - 1 do
        local h = _visible[i]
        if h and h._height then
            y = y + h._height + NOTIF_GAP
        end
    end
    return y
end

-- Restack all visible toasts smoothly by animating their Y position
local function _restack()
    for i, h in ipairs(_visible) do
        if h._alive and h._frame and h._frame.Parent then
            local targetY = _calculateTargetY(i)
            local targetPos = UDim2.new(0, 0, 0, targetY)
            AnimationEngine.Play(h._frame, ANIM_RESTACK, { Position = targetPos }, "restack")
        end
    end
end

-- Remove a handle from the overflow queue.
local function _removeFromQueue(handle)
    for i, h in ipairs(_queue) do
        if h == handle then
            table.remove(_queue, i)
            break
        end
    end
end

-- Drain items from the overflow queue into the visible stack (if room).
local function _drainQueue()
    while #_visible < MAX_VISIBLE and #_queue > 0 do
        local nextHandle = table.remove(_queue, 1)
        if nextHandle and nextHandle._alive then
            nextHandle:_show()
            break
        end
    end
end

-- Remove a handle from the visible list and restack.
local function _removeVisible(handle)
    for i, h in ipairs(_visible) do
        if h == handle then
            table.remove(_visible, i)
            break
        end
    end
    _restack()
    task.defer(_drainQueue)
end

-- ─── Notification handle constructor ─────────────────────────────────────────

local function _buildHandle(config: table)
    local notifType  = config.Type     or "Info"
    local title      = config.Title    or "Notification"
    local rawMessage = config.Message  or ""
    local duration   = config.Duration  -- nil or 0 = persistent
    local action     = config.Action    -- optional {Label, Callback}

    -- Flexible Message parsing: accepts string, number, Component object, or array table of parts.
    -- Example: Message = {"Press ", KB1, " to unhide"} -> automatically becomes "Press K to unhide"
    local message = ""
    if type(rawMessage) == "table" then
        local parts = {}
        for _, part in ipairs(rawMessage) do
            table.insert(parts, tostring(part))
        end
        message = table.concat(parts, "")
    else
        message = tostring(rawMessage)
    end

    local hasMessage = message ~= ""
    local hasAction  = action ~= nil
    local isMobile   = _isMobileViewport()

    -- Compact height on mobile to reduce visual footprint.
    -- Mobile: tighter vertical rhythm (base 40px, +16px message, +28px action).
    -- Desktop: original sizing (52 / +22 / +34).
    local baseH, msgH, actH
    if isMobile then
        baseH = 40
        msgH  = 16
        actH  = 28
    else
        baseH = 52
        msgH  = 22
        actH  = 34
    end
    if hasMessage then baseH += msgH end
    if hasAction  then baseH += actH end

    local titleTextSize = isMobile and 11 or 13
    local msgTextSize   = isMobile and 10 or 11

    local accentToken = TYPE_TOKEN[notifType] or "Accent"

    -- ─── Frame ──────────────────────────────────────────────────────────────

    -- ─── Frame (CanvasGroup for smooth group fade & slide) ───────────────────

    local frame = ComponentHelper.Create("CanvasGroup", {
        Name              = "Notification_" .. notifType,
        Size              = UDim2.new(0, NOTIF_WIDTH, 0, baseH),
        BackgroundColor3  = ThemeEngine.GetToken("Surface"),
        BorderSizePixel   = 0,
        GroupTransparency = 1,
        ClipsDescendants  = true,
        Position          = UDim2.new(0, NOTIF_WIDTH + 40, 0, 0),
        Parent            = _container,
    })
    ComponentHelper.AddCorner(frame, 8)
    ComponentHelper.AddStroke(frame, ThemeEngine.GetToken("Border"), 1)

    -- Colored left bar
    local colorBar = ComponentHelper.Create("Frame", {
        Name             = "ColorBar",
        Size             = UDim2.new(0, 4, 1, 0),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = frame,
    })
    ComponentHelper.AddCorner(colorBar, 2)

    -- Content area (left-padded past the color bar)
    local content = ComponentHelper.Create("Frame", {
        Name               = "Content",
        Position           = UDim2.new(0, 12, 0, 0),
        Size               = UDim2.new(1, -28, 0, baseH),
        BackgroundTransparency = 1,
        Parent             = frame,
    })
    ComponentHelper.AddPadding(content, 10, 10, 0, 28)

    -- Title
    local titleLabel = ComponentHelper.Create("TextLabel", {
        Name               = "Title",
        Size               = UDim2.new(1, 0, 0, 18),
        BackgroundTransparency = 1,
        Text               = title,
        TextColor3         = ThemeEngine.GetToken("Text"),
        TextSize           = titleTextSize,
        Font               = Enum.Font.GothamBold,
        TextXAlignment     = Enum.TextXAlignment.Left,
        TextTruncate       = Enum.TextTruncate.AtEnd,
        ZIndex             = 3,
        Parent             = content,
    })

    -- Message
    local messageLabel
    if hasMessage then
        messageLabel = ComponentHelper.Create("TextLabel", {
            Name               = "Message",
            Position           = UDim2.new(0, 0, 0, isMobile and 16 or 20),
            Size               = UDim2.new(1, 0, 0, msgH),
            BackgroundTransparency = 1,
            Text               = message,
            TextColor3         = ThemeEngine.GetToken("SubText"),
            TextSize           = msgTextSize,
            Font               = Enum.Font.Gotham,
            TextXAlignment     = Enum.TextXAlignment.Left,
            TextTruncate       = Enum.TextTruncate.AtEnd,
            ZIndex             = 3,
            Parent             = content,
        })
    end

    -- Action button
    local actionBtn
    if hasAction then
        local actionY = hasMessage and 44 or 24
        actionBtn = ComponentHelper.Create("TextButton", {
            Name             = "ActionButton",
            Position         = UDim2.new(0, 0, 0, actionY),
            Size             = UDim2.new(0, 80, 0, 22),
            BackgroundColor3 = ThemeEngine.GetToken(accentToken),
            AutoButtonColor  = false,
            Text             = action.Label or "Action",
            TextColor3       = ThemeEngine.GetToken("AccentText"),
            TextSize         = 11,
            Font             = Enum.Font.GothamBold,
            ZIndex           = 3,
            Parent           = content,
        })
        ComponentHelper.AddCorner(actionBtn, 5)
        actionBtn.MouseButton1Click:Connect(function()
            if action.Callback then
                task.spawn(action.Callback)
            end
        end)
    end

    -- Close button (×)
    local closeBtn = ComponentHelper.Create("TextButton", {
        Name               = "CloseBtn",
        AnchorPoint        = Vector2.new(1, 0),
        Position           = UDim2.new(1, -6, 0, 6),
        Size               = UDim2.new(0, 18, 0, 18),
        BackgroundTransparency = 1,
        Text               = "×",
        TextColor3         = ThemeEngine.GetToken("SubText"),
        TextSize           = 16,
        Font               = Enum.Font.GothamBold,
        ZIndex             = 4,
        Parent             = frame,
    })

    -- Timeout progress bar (shrinks width from right to left)
    local progressBg = ComponentHelper.Create("Frame", {
        Name             = "ProgressBg",
        AnchorPoint      = Vector2.new(0, 1),
        Position         = UDim2.new(0, 0, 1, 0),
        Size             = UDim2.new(1, 0, 0, 2),
        BackgroundColor3 = ThemeEngine.GetToken("Border"),
        BorderSizePixel  = 0,
        ZIndex           = 2,
        Parent           = frame,
    })

    local progressFill = ComponentHelper.Create("Frame", {
        Name             = "ProgressFill",
        Size             = UDim2.fromScale(1, 1),
        BackgroundColor3 = ThemeEngine.GetToken(accentToken),
        BorderSizePixel  = 0,
        ZIndex           = 3,
        Parent           = progressBg,
    })

    -- Hide progress bar if persistent
    if not duration or duration <= 0 then
        progressBg.Visible = false
    end

    -- ─── Theme listener ─────────────────────────────────────────────────────

    local themeDisconnect = ThemeEngine.OnThemeChanged(function(tokens)
        frame.BackgroundColor3 = tokens.Surface
        colorBar.BackgroundColor3 = tokens[accentToken]
        titleLabel.TextColor3  = tokens.Text
        if messageLabel then messageLabel.TextColor3 = tokens.SubText end
        progressFill.BackgroundColor3 = tokens[accentToken]
        if actionBtn then actionBtn.BackgroundColor3 = tokens[accentToken] end
    end)

    -- ─── Handle object ──────────────────────────────────────────────────────

    local handle = {}
    handle._frame  = frame
    handle._height = baseH
    handle._alive  = true
    handle._token  = _sessionToken  -- capture current session; stale if Reset() bumps it
    local _timer   = nil

    function handle:_show()
        if not self._alive then return end
        table.insert(_visible, self)

        local targetIndex = #_visible
        local targetY = _calculateTargetY(targetIndex)

        -- Initial position off-screen right
        frame.Position = UDim2.new(0, NOTIF_WIDTH + 40, 0, targetY)
        frame.GroupTransparency = 1

        -- Slide in smoothly to target position + fade in GroupTransparency
        AnimationEngine.Play(frame, ANIM_SLIDE_INFO, {
            Position          = UDim2.new(0, 0, 0, targetY),
            GroupTransparency = 0,
        }, "slide")

        _restack()

        -- Start timeout timer if duration is set.
        if duration and duration > 0 then
            local timerInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
            local t = TweenService:Create(progressFill, timerInfo, {Size = UDim2.new(0, 0, 1, 0)})
            t:Play()

            _timer = task.delay(duration, function()
                _timer = nil
                if self._alive then
                    self:Dismiss()
                end
            end)
        end
    end

    function handle:Dismiss()
        if not self._alive then return end
        self._alive = false
        if _timer then
            pcall(task.cancel, _timer)
            _timer = nil
        end
        themeDisconnect()
        _removeFromQueue(self)

        local _finished = false
        local function _finish()
            if _finished then return end
            _finished = true
            _removeVisible(self)
            -- P1 fix: never fire OnComplete for a notification that was reset
            -- away (or whose session was invalidated) while the dismiss
            -- animation/fallback timer was still running.
            if handle._token == _sessionToken and type(config.OnComplete) == "function" then
                pcall(config.OnComplete)
            end
            pcall(function() frame:Destroy() end)
        end

        if not frame or not frame.Parent then
            _finish()
            return
        end

        -- Slide out smoothly to the right + GroupTransparency fade out
        local currentY = frame.Position.Y.Offset
        local t = AnimationEngine.Play(frame, ANIM_OUT_INFO, {
            Position          = UDim2.new(0, NOTIF_WIDTH + 40, 0, currentY),
            GroupTransparency = 1,
        }, "slide")

        if t then
            t.Completed:Connect(function()
                -- Guard: tween completed only if still the current session.
                if handle._token == _sessionToken then
                    _finish()
                end
            end)
            -- Fallback: ensure _finish always fires even if tween is cancelled/destroyed
            task.delay(ANIM_OUT_INFO.Time + 0.05, function()
                if handle._token == _sessionToken then
                    _finish()
                end
            end)
        else
            _finish()
        end
    end

    -- Runtime update helpers.
    function handle:SetTitle(text: string)
        titleLabel.Text = text
    end

    function handle:SetMessage(text: string)
        if messageLabel then messageLabel.Text = text end
    end

    -- Close button wires to Dismiss.
    closeBtn.MouseButton1Click:Connect(function()
        handle:Dismiss()
    end)

    handle.Destroy = handle.Dismiss

    return handle
end

-- ─── Public API ───────────────────────────────────────────────────────────────

-- Push a notification. Returns a handle with :Dismiss(), :SetTitle(), :SetMessage().
function NotificationService.Push(config: table)
    if not _initialized or not _container or not _container.Parent then
        _ensureInit()
    end
    if not _initialized or not _container or not _container.Parent then
        warn("[NotificationService] Cannot Push notification: Service is not initialized and ScreenGui could not be found.")
        return {
            Dismiss = function() end,
            SetTitle = function() end,
            SetMessage = function() end,
            Destroy = function() end,
        }
    end
    assert(type(config) == "table", "NotificationService.Push expects a config table")

    local handle = _buildHandle(config)

    if #_visible < MAX_VISIBLE then
        handle:_show()
    else
        -- Queue it; it will show automatically once a slot opens.
        table.insert(_queue, handle)
    end

    return handle
end

-- Dismiss every active notification. If instant=true, destroys frames immediately without slide animation.
function NotificationService.DismissAll(instant: boolean?)
    table.clear(_queue)
    local snapshot = {table.unpack(_visible)}
    table.clear(_visible)
    for _, h in ipairs(snapshot) do
        pcall(function()
            if instant then
                -- Instant destroy: invalidate this handle's session so any
                -- in-flight async Dismiss callback (animation-complete /
                -- fallback timer) from before is stale and never fires
                -- OnComplete or touches the destroyed frame.
                h._alive = false
                _sessionToken += 1
                if h._frame and h._frame.Parent then
                    h._frame:Destroy()
                end
            else
                -- Animated dismiss: these are CURRENT handles being dismissed
                -- normally, so their OnComplete should still fire. Do NOT bump
                -- the session token here.
                h:Dismiss()
            end
        end)
    end
end

-- Full reset — called by Bootstrap before creating a new session.
-- Clears all module-level state so Init() can be safely called again.
function NotificationService.Reset()
    -- Invalidate every outstanding async callback/timer from this session.
    _sessionToken += 1
    table.clear(_queue)
    local snapshot = {table.unpack(_visible)}
    table.clear(_visible)
    for _, h in ipairs(snapshot) do
        pcall(function()
            h._alive = false
            if h._frame and h._frame.Parent then
                h._frame:Destroy()
            end
        end)
    end
    -- Hancurkan container juga supaya tidak ada sisa frame nempel di GUI
    -- kalau Reset dipanggil tanpa destroy ScreenGui.
    if _container and _container.Parent then
        pcall(function() _container:Destroy() end)
    end
    _container   = nil
    _initialized = false
end

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")

ServiceRegistry.Register("NotificationService", {
    Reset = NotificationService.Reset,
    Init  = NotificationService.Init,
}, 50)  -- priority 50 — inits after ThemeEngine (10) since it reads theme tokens

return NotificationService

end

-- ── Services.UnloadService ────────────────────────────────
_Delirium_modules["Services.UnloadService"] = function()
-- Services/UnloadService.lua
-- Centralized lifecycle & unload management service for Delirium.
-- Follows BASE.md philosophy: clean, lightweight, predictable, and leak-free.
-- local Root = script.Parent.Parent
local Maid = _Delirium_require("Core.Maid")
local ServiceRegistry = _Delirium_require("Core.ServiceRegistry")
local AnimationEngine = _Delirium_require("Core.AnimationEngine")
local NotificationService = _Delirium_require("Services.NotificationService")

local UnloadService = {}

local _maid        = Maid.new()
local _unloading   = false
local _runtimeRef  = nil
local _unloadToken = 0

function UnloadService.Init(_, runtime)
    _unloadToken += 1  -- invalidate any pending background teardowns from previous session
    _runtimeRef = runtime
    _unloading  = false
end

function UnloadService.Reset()
    _unloadToken += 1
    pcall(function() _maid:DoCleaning() end)
    _maid       = Maid.new()
    _unloading  = false
    _runtimeRef = nil
end

function UnloadService.Register(task)
    return _maid:GiveTask(task)
end
UnloadService.GiveTask = UnloadService.Register

function UnloadService.IsUnloading(): boolean
    return _unloading
end

function UnloadService.Unload(config: table?)
    if _unloading then return end
    _unloading = true

    _unloadToken += 1
    local currentToken  = _unloadToken
    local targetRuntime = _runtimeRef

    config = config or {}
    local duration = config.Duration or 2.0
    local silent   = config.Silent == true

    -- 1. Smoothly animate active windows closing (CanvasGroup GroupTransparency fade + slide down)
    if targetRuntime and targetRuntime._windows then
        local snapshot = {table.unpack(targetRuntime._windows)}
        for _, win in ipairs(snapshot) do
            pcall(function()
                if win.MainFrame and win.MainFrame.Parent then
                    AnimationEngine.CloseWindow(win.MainFrame, function()
                        if win.Destroy then win:Destroy() end
                    end)
                end
                if win._miniIconFrame and win._miniIconFrame.Parent then
                    win._miniIconFrame.Visible = false
                end
            end)
        end
    end

    -- 2. Instantly clear all pre-existing notifications
    NotificationService.DismissAll(true)

    local function _executeTeardown()
        if _unloadToken ~= currentToken then
            -- A new session was started before this teardown completed; guard against wiping new session.
            return
        end
        pcall(function() _maid:DoCleaning() end)
        pcall(function() NotificationService.Reset() end)
        -- Reset all registered services (ThemeEngine listeners, Dialog, Input,
        -- Config cache, etc.) so no stale state survives an Unload.
        pcall(ServiceRegistry.ResetAll)
        if targetRuntime and type(targetRuntime.IsAlive) == "function" and targetRuntime:IsAlive() then
            pcall(function() targetRuntime:Destroy() end)
        end
        local envG = (type(getgenv) == "function" and getgenv()) or _G or {}
        if envG["__DeliriumRuntime"] == targetRuntime then
            envG["__DeliriumRuntime"] = nil
        end
        if envG.Delirium and type(envG.Delirium) == "table" and targetRuntime and not targetRuntime:IsAlive() then
            envG.Delirium = nil
        end
        if type(shared) == "table" and shared.Delirium and type(shared.Delirium) == "table" and targetRuntime and not targetRuntime:IsAlive() then
            shared.Delirium = nil
        end
    end

    if silent then
        _executeTeardown()
        return
    end

    -- 3. Show sleek Unload Progress Toast
    return NotificationService.Push({
        Title      = "Unloading Delirium",
        Message    = "Disconnecting signals, keybinds, and UI...",
        Type       = "Warning",
        Duration   = duration,
        OnComplete = _executeTeardown,
    })
end

ServiceRegistry.Register("UnloadService", {
    Reset = UnloadService.Reset,
}, 10)

return UnloadService

end

-- ── Init (entry point) ──────────────────────────────────
-- Init.lua
-- Delirium entry point.
--
-- Bootstrap flow (per exec):
--   Detect previous Runtime in _G
--     ├── Alive  → Runtime:Destroy() → create new
--     └── Dead   → wipe stale state  → create new
--   (none) → scan for orphan GUI → create new
--
-- Public API: CreateWindow, Notify, SetTheme, RegisterTheme, SetReducedMotion

local CoreGui  = game:GetService("CoreGui")
local Players  = game:GetService("Players")

-- ServiceRegistry required first — services self-register during require()
local ServiceRegistry     = _Delirium_require("Core.ServiceRegistry")

local Runtime             = _Delirium_require("Core.Runtime")
local ThemeEngine         = _Delirium_require("Core.ThemeEngine")
local VariantEngine       = _Delirium_require("Core.VariantEngine")
local AnimationEngine     = _Delirium_require("Core.AnimationEngine")
local NotificationService = _Delirium_require("Services.NotificationService")
local DialogService       = _Delirium_require("Services.DialogService")
local UnloadService       = _Delirium_require("Services.UnloadService")
local Window              = _Delirium_require("Layout.Window")

-- ─── Constants ─────────────────────────────────────────────────────────────

local RUNTIME_KEY = "__DeliriumRuntime"
local GUI_NAME    = "DeliriumUI"

-- ─── Public API Declaration ────────────────────────────────────────────────
-- Declared at file top-level so Delirium is never nil during execution

local Delirium = { Version = "0.3.11" }

-- ─── State ─────────────────────────────────────────────────────────────────

local _runtime: typeof(Runtime.new()) = nil
local _gui: ScreenGui = nil

-- ─── Helpers ───────────────────────────────────────────────────────────────

local function _nukeExistingGui()
    local playerGui = Players.LocalPlayer and Players.LocalPlayer:FindFirstChild("PlayerGui")
    local parents = {
        CoreGui,
        playerGui,
    }
    for _, parent in ipairs(parents) do
        if parent then
            for _, child in ipairs(parent:GetChildren()) do
                if child.Name == GUI_NAME then
                    pcall(function() child:Destroy() end)
                end
            end
        end
    end
end

local function _createGui(): ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name            = GUI_NAME
    gui.ResetOnSpawn    = false
    -- Sibling ZIndexBehavior: ZIndex values are scoped relative to parent containers.
    gui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
    gui.IgnoreGuiInset  = true
    pcall(function() gui.DisplayOrder = 100 end)
    local ok = pcall(function() gui.Parent = CoreGui end)
    if not ok then
        local lp = Players.LocalPlayer
        if not lp then
            -- Bounded wait: never block Bootstrap forever if LocalPlayer is slow.
            -- An unbounded :Wait() here would hang loadstring()() and the library
            -- would never return its API.
            for _ = 1, 120 do
                lp = Players.LocalPlayer
                if lp then break end
                task.wait(0.1)
            end
        end
        if lp then
            gui.Parent = lp:WaitForChild("PlayerGui")
        else
            -- LocalPlayer never resolved within the bounded window.
            -- Leave the GUI unparented rather than erroring on a nil index —
            -- Bootstrap continues and the runtime still initializes cleanly.
            warn("[Delirium] CoreGui parenting failed and LocalPlayer unavailable; GUI left unparented.")
        end
    end
    return gui
end

-- ─── Bootstrap ─────────────────────────────────────────────────────────────

local function Bootstrap()
    print("[Delirium Engine] Bootstrap Step 1: Cleaning previous runtime...")
    local envG = (type(getgenv) == "function" and getgenv()) or _G or {}
    local existing = envG[RUNTIME_KEY]
    if existing and type(existing) == "table" then
        if type(existing.IsAlive) == "function" and existing:IsAlive() then
            pcall(function() existing:Destroy() end)
        else
            -- Dead/stale: just reset services
            ServiceRegistry.ResetAll()
        end
        envG[RUNTIME_KEY] = nil
    end

    print("[Delirium Engine] Bootstrap Step 2: Resetting services...")
    ServiceRegistry.ResetAll()

    print("[Delirium Engine] Bootstrap Step 3: Nuking orphan GUI...")
    _nukeExistingGui()

    print("[Delirium Engine] Bootstrap Step 4: Creating ScreenGui & Runtime...")
    local gui     = _createGui()
    local runtime = Runtime.new()

    -- Runtime owns the ScreenGui instance
    runtime:OwnResource(gui)

    pcall(function() envG[RUNTIME_KEY] = runtime end)
    if type(_G) == "table" then pcall(function() _G[RUNTIME_KEY] = runtime end) end
    _runtime = runtime
    _gui     = gui

    print("[Delirium Engine] Bootstrap Step 5: Initializing services...")
    UnloadService.Init(gui, runtime)
    ServiceRegistry.InitAll(gui)

    runtime.PublicApi = Delirium

    print("[Delirium Engine] Bootstrap complete!")
    return runtime, gui
end

-- Run immediately on require (assigns upvalues directly, no local shadowing)
_runtime, _gui = Bootstrap()

local function _ensureActiveRuntime()
    if not _runtime or not _runtime:IsAlive() then
        _runtime, _gui = Bootstrap()
    end
end

-- ─── Delirium Public API Methods ───────────────────────────────────────────

function Delirium:CreateWindow(config: table)
    assert(config and type(config) == "table",
        "Delirium:CreateWindow expects a configuration table")
    config.Name = config.Name or config.Title or "Delirium"

    _ensureActiveRuntime()

    local win = Window.new(config, _gui)
    _runtime:RegisterWindow(win)
    return win
end

function Delirium:Notify(config: table)
    _ensureActiveRuntime()
    return NotificationService.Push(config)
end

function Delirium:SetTheme(themeName: string)
    ThemeEngine.SetTheme(themeName)
end

function Delirium:RegisterTheme(name: string, tokens: table)
    ThemeEngine.RegisterTheme(name, tokens)
end

function Delirium:SetReducedMotion(enabled: boolean)
    AnimationEngine.ReducedMotion = enabled == true
end

-- Returns the session ID of the current runtime.
function Delirium:GetSessionId(): string
    return _runtime and _runtime.SessionId or ""
end

function Delirium:IsSessionCurrent(sessionId: string): boolean
    return _runtime and _runtime:IsCurrent(sessionId) or false
end

-- Full Unload Handler (delegates to dedicated UnloadService)
function Delirium:Unload(config: table?)
    return UnloadService.Unload(config)
end

-- Register custom cleanup tasks/functions to be executed when Delirium unloads
function Delirium:OnUnload(task)
    return UnloadService.Register(task)
end

-- Expose sub-modules for advanced use
Delirium.Theme     = ThemeEngine
Delirium.Variants  = VariantEngine   -- variant foundation (TASK 01)
Delirium.Animation = AnimationEngine
Delirium.Dialog    = DialogService
Delirium.UnloadSvc = UnloadService

if type(shared) == "table" then pcall(function() shared.Delirium = Delirium end) end
if type(_G) == "table" then pcall(function() _G.Delirium = Delirium end) end
if type(getgenv) == "function" then
    local env = getgenv()
    if type(env) == "table" then env.Delirium = Delirium end
end

return Delirium
