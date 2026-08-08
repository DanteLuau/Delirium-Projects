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
local Signal           = require(script.Parent.Parent.Utilities.Signal)
local Maid             = require(script.Parent.Maid)

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

local function classifyDevice(): string
    if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
        return DeviceType.Console
    end
    if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
        local camera   = workspace.CurrentCamera
        local viewport = camera and camera.ViewportSize or Vector2.new(1920, 1080)
        return math.min(viewport.X, viewport.Y) >= 600 and DeviceType.Tablet or DeviceType.Phone
    end
    return DeviceType.Desktop
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

    -- Orientation tracking via camera viewport changes
    local camera = workspace.CurrentCamera
    if camera then
        local function checkOrientation()
            local vp  = camera.ViewportSize
            local ori = vp.X >= vp.Y and "Landscape" or "Portrait"
            if ori ~= InputAdapter.CurrentOrientation then
                InputAdapter.CurrentOrientation = ori
                InputAdapter.OrientationChanged:Fire(ori)
            end
        end
        _maid:GiveTask(
            camera:GetPropertyChangedSignal("ViewportSize"):Connect(checkOrientation)
        )
        -- Sync initial value
        local vp  = camera.ViewportSize
        InputAdapter.CurrentOrientation = vp.X >= vp.Y and "Landscape" or "Portrait"
    end
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

-- ─── Self-register ────────────────────────────────────────────────────────────

local ServiceRegistry = require(script.Parent.ServiceRegistry)

ServiceRegistry.Register("InputAdapter", {
    Reset = InputAdapter.Reset,
}, 5)  -- priority 5 — resets first (other services may use InputAdapter)

return InputAdapter
