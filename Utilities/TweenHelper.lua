-- Utilities/TweenHelper.lua
-- Thin wrapper kept for backward compatibility with existing component code.
-- All preset TweenInfos mirror AnimationEngine.Preset.
-- New code should prefer AnimationEngine directly.

local TweenService     = game:GetService("TweenService")
local AnimationEngine  = require(script.Parent.Parent.Core.AnimationEngine)

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
