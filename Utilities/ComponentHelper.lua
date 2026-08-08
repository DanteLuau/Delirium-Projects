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

return ComponentHelper
