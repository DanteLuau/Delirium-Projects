# Delirium

> A modern, premium, mobile-ready Roblox Script UI Library built for developers who want **Nice Looks, Powerful APIs, and Easy-to-Use components**.

**Status:** V1 Development
**Architecture:** Modular
**Target:** Roblox script environments with desktop and mobile support

---

## Table of Contents

* [Overview](#overview)
* [Goals](#goals)
* [Core Principles](#core-principles)
* [Features](#features)
* [Platform Support](#platform-support)
* [Architecture](#architecture)
* [Project Structure](#project-structure)
* [Installation](#installation)
* [Basic Usage](#basic-usage)
* [API Philosophy](#api-philosophy)
* [Window](#window)
* [Tab](#tab)
* [Section](#section)
* [Components](#components)
* [Runtime Updates](#runtime-updates)
* [Notifications](#notifications)
* [Dialogs](#dialogs)
* [Themes](#themes)
* [Configuration](#configuration)
* [Mobile UX](#mobile-ux)
* [Animation System](#animation-system)
* [Lifecycle and Cleanup](#lifecycle-and-cleanup)
* [Development Workflow](#development-workflow)
* [Testing](#testing)
* [Build and Distribution](#build-and-distribution)
* [Performance](#performance)
* [Architecture Rules](#architecture-rules)
* [Roadmap](#roadmap)
* [Versioning](#versioning)
* [Contributing](#contributing)
* [License](#license)

---

# Overview

Delirium is a Roblox Script UI Library designed around three primary goals:

1. **Nice Looks**
2. **Powerful**
3. **Easy to Use**

The library is designed to provide a polished UI experience without forcing developers to write large amounts of UI code.

Delirium provides:

* Window management
* Tabs
* Sections
* Interactive components
* Notifications
* Dialogs
* Themes
* Animations
* Runtime updates
* Configuration support
* Desktop support
* Mobile and touch support

The project is designed as a modular codebase internally while exposing a simple public API.

---

# Goals

## Primary Goals

Delirium should allow a developer to create a usable and polished interface with a small amount of code.

Example:

```lua
local Window = Library:CreateWindow({
    Title = "My Script",
})

local Main = Window:CreateTab({
    Title = "Main",
})

local Combat = Main:CreateSection({
    Title = "Combat",
})

local Toggle = Combat:CreateToggle({
    Title = "Auto Farm",
    Default = false,

    Callback = function(Value)
        print("Auto Farm:", Value)
    end,
})
```

The API should be understandable even before reading the documentation.

---

# Core Principles

## 1. Nice Looks

Delirium should look good by default.

Developers should not have to manually configure:

* Colors
* Spacing
* Corner radius
* Typography
* Animations
* Component states

The default configuration should already feel polished.

---

## 2. Powerful

Components should support runtime manipulation.

For example:

```lua
Toggle:Set(true)
Toggle:Get()

Slider:Set(50)
Slider:Get()

Textbox:Set("Hello")

Dropdown:Refresh(...)
```

Developers should not need to destroy and recreate components just to change their state.

---

## 3. Easy to Use

The API should remain predictable.

Prefer:

```lua
Toggle:Set(true)
```

over complicated state systems.

Prefer:

```lua
Section:CreateButton(...)
```

over unrelated global factories.

Prefer object references over global flags.

---

# Inspiration

Delirium takes conceptual inspiration from existing Roblox UI libraries.

### Rayfield

Used as inspiration for:

* Simple APIs
* Developer friendliness
* Easy component creation

### Obsidian

Used as inspiration for:

* Runtime updates
* Dynamic component behavior
* Flexible APIs

### Starlight

Used as inspiration for:

* Visual polish
* Animations
* Modern UI design

These projects are references only.

Delirium does not copy their source code, implementation, or API design directly.

---

# Features

## Core

* Modular architecture
* Runtime management
* Signal system
* Cleanup system
* Theme engine
* Input adapter
* Animation system

## Layout

* Window
* Tab
* Section

## Components

* Button
* Toggle
* Slider
* Dropdown
* TextBox
* Keybind
* ColorPicker
* Label
* Paragraph
* Divider

## Services

* Notification Service
* Dialog Service
* Config Service

## UX

* Responsive layout
* Touch support
* Adaptive interactions
* Mobile-safe notifications
* Touch-safe sliders
* Floating mobile reopen control
* Keyboard-aware UI

---

# Platform Support

Delirium is designed for:

* Desktop
* Laptop
* Tablet
* Mobile

Mobile support is a first-class feature.

It is not simply a smaller desktop layout.

The library adapts interaction behavior depending on the available input method.

---

# Architecture

The public hierarchy is:

```text
Library
└── Window
    └── Tab
        └── Section
            └── Component
```

Internal architecture is separated into:

```text
Core
Interface
Components
Services
Utilities
Assets
Internal
```

The goal is to keep each module responsible for one specific area of functionality.

---

# Project Structure

Current development structure:

```text
Delirium/
│
├── Init.lua
│
├── Core/
│   ├── AnimationEngine.lua
│   ├── InputAdapter.lua
│   ├── Maid.lua
│   ├── Runtime.lua
│   ├── ServiceRegistry.lua
│   └── ThemeEngine.lua
│
├── Layout/
│   ├── Window.lua
│   ├── Tab.lua
│   └── Section.lua
│
├── Components/
│   ├── Button.lua
│   ├── ColorPicker.lua
│   ├── Divider.lua
│   ├── Dropdown.lua
│   ├── Keybind.lua
│   ├── Label.lua
│   ├── Paragraph.lua
│   ├── Slider.lua
│   ├── TextBox.lua
│   └── Toggle.lua
│
├── Services/
│   ├── ConfigService.lua
│   ├── DialogService.lua
│   └── NotificationService.lua
│
└── Utilities/
    ├── ComponentHelper.lua
    ├── Signal.lua
    └── TweenHelper.lua
```

The structure may evolve during development, but public API compatibility should be preserved whenever practical.

---

# Installation

There are two primary development workflows.

## Development

During development, keep the library modular.

```text
Delirium/
├── Core/
├── Layout/
├── Components/
├── Services/
└── Utilities/
```

This makes individual modules easier to modify and test.

---

# Distribution

For script execution environments, the recommended distribution format is a generated single-file build.

```text
Source Modules
      ↓
Build
      ↓
dist/Delirium.lua
      ↓
Hosting
      ↓
Executor
```

The source remains modular.

The distributed file is generated from the source.

This prevents developers from having to manually download and assemble multiple modules.

---

# Basic Usage

A typical Delirium script should look similar to:

```lua
local Library = loadstring(game:HttpGet("RAW_URL"))()

local Window = Library:CreateWindow({
    Title = "My Script",
    Subtitle = "Delirium Example",
})

local Main = Window:CreateTab({
    Title = "Main",
})

local General = Main:CreateSection({
    Title = "General",
})

General:CreateButton({
    Title = "Execute",

    Callback = function()
        print("Executed")
    end,
})

General:CreateToggle({
    Title = "Enabled",
    Default = false,

    Callback = function(Value)
        print(Value)
    end,
})
```

The exact distribution URL depends on the release/build system.

---

# API Philosophy

Delirium follows an object-oriented component API.

Every component should return an object representing that component.

Example:

```lua
local Toggle = Section:CreateToggle({
    Title = "Auto Farm",
})
```

The developer can then interact with the returned object.

```lua
Toggle:Set(true)

print(Toggle:Get())

Toggle:Destroy()
```

---

# Object Ownership

Objects belong to their parent.

Example:

```text
Window
 ├── Tab
 │    ├── Section
 │    │    ├── Toggle
 │    │    └── Button
 │    └── Section
 └── Tab
```

Destroying a parent should clean up its children.

For example:

```lua
Window:Destroy()
```

should eventually result in:

```text
Window
 ↓
Tabs
 ↓
Sections
 ↓
Components
 ↓
Connections
 ↓
Tweens
 ↓
Instances
```

being cleaned up.

This cascade cleanup is a core reliability requirement.

---

# Common Component API

Interactive components should use consistent method names where applicable.

```lua
:Set()
:Get()
:Show()
:Hide()
:Enable()
:Disable()
:Destroy()
:Refresh()
```

Not every component needs every method.

For example, a Button does not need a meaningful `:Get()` value.

API consistency should never come at the expense of semantic correctness.

---

# Window

The Window is the primary UI container.

Expected responsibilities include:

* Window title
* Subtitle
* Icon
* Tabs
* Visibility
* Open/close behavior
* Mobile behavior
* Theme integration
* Notifications
* Dialogs
* Cleanup

Example:

```lua
local Window = Library:CreateWindow({
    Title = "Delirium",
    Subtitle = "Example",
})
```

Expected runtime operations:

```lua
Window:SetTitle("New Title")

Window:Show()
Window:Hide()

Window:Open()
Window:Close()

Window:Destroy()
```

---

# Tab

Tabs provide navigation between major sections of the interface.

Example:

```lua
local Main = Window:CreateTab({
    Title = "Main",
})
```

Tabs may support:

* Title
* Icon
* Badge
* Visibility
* Enabled/disabled state
* Selection
* Lazy content behavior

Example:

```lua
Main:SetVisible(false)
Main:SetDisabled(true)
```

---

# Section

Sections organize components inside a tab.

Example:

```lua
local Combat = Main:CreateSection({
    Title = "Combat",
})
```

A section may support:

* Title
* Description
* Icon
* Collapsible behavior
* Visibility

Components are created from the section.

---

# Button

Buttons represent actions.

Example:

```lua
Section:CreateButton({
    Title = "Execute",

    Callback = function()
        print("Clicked")
    end,
})
```

Buttons should support:

* Click
* Disabled state
* Hover
* Press animation
* Loading state
* Success state
* Failure state
* Runtime text updates

---

# Button Loading

Button loading is a signature Delirium interaction.

Instead of placing a traditional spinner beside the text, the button itself becomes the loading indicator.

Conceptually:

```text
Normal
████████████████

Loading
██████░░░░░░░░░

Success
████████████████
```

The fill progresses from left to right.

The final implementation should preserve the button's visual identity while clearly communicating progress.

---

# Toggle

Example:

```lua
local Toggle = Section:CreateToggle({
    Title = "Auto Farm",
    Default = false,

    Callback = function(Value)
        print(Value)
    end,
})
```

Runtime:

```lua
Toggle:Set(true)

local Value = Toggle:Get()
```

Expected behavior:

* Smooth state animation
* Disabled state
* Runtime updates
* Callback/event support
* Theme integration
* Config integration

---

# Slider

Example:

```lua
local Slider = Section:CreateSlider({
    Title = "Walk Speed",
    Min = 0,
    Max = 100,
    Default = 16,
    Step = 1,

    Callback = function(Value)
        print(Value)
    end,
})
```

Runtime:

```lua
Slider:Set(50)

print(Slider:Get())
```

Sliders must be especially careful on mobile.

A user scrolling the interface must not accidentally change the slider value.

Touch gesture detection and scroll priority are therefore part of the component's UX requirements.

---

# Dropdown

Example:

```lua
local Dropdown = Section:CreateDropdown({
    Title = "Mode",

    Items = {
        "Normal",
        "Fast",
        "Extreme",
    },

    Callback = function(Value)
        print(Value)
    end,
})
```

Expected capabilities may include:

* Selection
* Search
* Dynamic refresh
* Multi-select where supported
* Mobile touch interaction
* Keyboard interaction on desktop

---

# TextBox

Example:

```lua
local Textbox = Section:CreateTextbox({
    Title = "Username",
    Placeholder = "Enter username...",

    Callback = function(Text)
        print(Text)
    end,
})
```

Expected operations:

```lua
Textbox:Set("Player")

print(Textbox:Get())

Textbox:Clear()
Textbox:Focus()
```

On mobile, the library must ensure the active textbox remains visible when the virtual keyboard appears.

---

# Keybind

Keybinds are primarily useful on devices with keyboards.

Example:

```lua
Section:CreateKeybind({
    Title = "Toggle UI",
    Key = Enum.KeyCode.K,

    Callback = function()
        Window:Toggle()
    end,
})
```

On touch-only devices, the library must not assume that a physical keyboard exists.

Alternative mobile interactions may include:

* Floating button
* Gesture
* Touch control

The user should never receive a message telling them to press a keyboard key when they are using a touch-only device.

---

# ColorPicker

Example:

```lua
Section:CreateColorPicker({
    Title = "Accent",
    Color = Color3.fromRGB(90, 120, 255),

    Callback = function(Color)
        print(Color)
    end,
})
```

Expected support may include:

* RGB
* HSV
* HEX
* Alpha
* Runtime changes
* Theme integration

---

# Label

Labels provide simple text.

```lua
Section:CreateLabel({
    Text = "Status: Ready",
})
```

---

# Paragraph

Paragraphs are used for larger descriptive content.

```lua
Section:CreateParagraph({
    Title = "Information",
    Content = "This section contains information.",
})
```

---

# Divider

Dividers provide visual separation.

```lua
Section:CreateDivider()
```

They should remain lightweight and should not introduce unnecessary layout complexity.

---

# Runtime Updates

Runtime modification is a major part of Delirium.

A UI should not need to be recreated simply because its state changed.

Examples:

```lua
Toggle:Set(true)

Slider:Set(75)

Textbox:Set("Hello")

Dropdown:Refresh({
    "One",
    "Two",
    "Three",
})
```

Runtime updates should also trigger the appropriate visual state and events.

---

# Notifications

Notifications are handled by the Notification Service.

Example:

```lua
Library:Notify({
    Title = "Success",
    Description = "Operation completed.",
    Duration = 5,
})
```

Notification types:

* Info
* Success
* Warning
* Error
* Loading

Expected features:

* Queue
* Maximum visible notifications
* Progress indicator
* Action button
* Persistent notifications
* Runtime updates
* Dismissal

---

# Adaptive Notifications

Notification content must respect the current input environment.

Bad:

```text
Press K to reopen the UI.
```

when the user is on a touch-only device.

Better:

Desktop:

```text
Press K to reopen the interface.
```

Mobile:

```text
Tap the floating button to reopen the interface.
```

The notification system should handle this automatically.

---

# Dialogs

The Dialog Service handles modal interactions.

Potential dialog types:

* Alert
* Confirm
* Warning
* Error
* Prompt
* Loading
* Progress

Dialog interaction must adapt to the platform.

Desktop keyboard shortcuts may be useful.

Mobile should prioritize explicit touch controls.

---

# Theme System

Delirium uses a centralized theme system.

Components should not contain arbitrary hardcoded colors.

Theme tokens should control:

* Background
* Surface
* Surface hover
* Primary
* Secondary
* Accent
* Border
* Text
* Muted text
* Success
* Warning
* Error
* Info

Themes should be changeable at runtime.

---

# Animation System

Animations should be centralized.

Common animation types:

* Fade
* Scale
* Slide
* Hover
* Press
* Ripple
* Loading
* Success
* Dialog transition
* Notification transition

Components should not independently implement inconsistent tween behavior.

The Animation Engine should provide reusable motion behavior.

---

# Mobile UX

Mobile support is a core requirement.

Delirium should not simply scale the desktop interface down.

It should adapt interaction behavior.

---

## Input Adaptation

The Input Adapter should understand:

* Mouse
* Keyboard
* Touch
* Gamepad where applicable
* Device class
* Orientation
* Screen size
* Safe area
* Current input mode

The goal is to allow components to adapt automatically.

---

## Touch Scrolling

Scrolling must have priority over accidental component interaction when appropriate.

Example:

```text
User swipes vertically
        ↓
Scroll container moves
        ↓
Slider value remains unchanged
```

The slider should only capture the gesture when the user clearly intends to manipulate it.

---

## Tooltip

Desktop:

```text
Hover → Tooltip
```

Mobile:

```text
Tap → Tooltip
```

Hover-only behavior should never be required on touch devices.

---

## Context Menu

Desktop:

```text
Right Click → Context Menu
```

Mobile:

```text
Long Press → Context Menu
```

---

## Reopen UI

Desktop may use a keybind.

Mobile should use a floating touch control.

The floating control should be:

* Easy to reach
* Draggable
* Visually unobtrusive
* Persistent while the main UI is hidden
* Safe around screen edges

---

## Mobile Keyboard

When a mobile textbox is focused:

* The UI should account for the virtual keyboard.
* The textbox should remain visible.
* Dialogs should not place important controls behind the keyboard.
* Scrolling should remain usable.

---

# Lifecycle and Cleanup

Every object has a lifecycle.

Typical lifecycle:

```text
Create
 ↓
Initialize
 ↓
Active
 ↓
Update
 ↓
Hide / Show
 ↓
Destroy
```

Destroying a parent should destroy its descendants.

Cleanup must include:

* Roblox connections
* Signals
* Tweens
* Instances
* Input listeners
* Temporary objects
* References
* Runtime registrations

Memory leaks are considered V1 blockers.

---

# Development Workflow

Development should happen against the modular source tree.

Recommended workflow:

```text
Edit Source
    ↓
Local Preview
    ↓
Unit / Integration Tests
    ↓
Build
    ↓
Desktop Test
    ↓
Mobile Test
    ↓
Regression Test
    ↓
Release
```

Do not use the hosted build as the primary development environment.

---

# Mobile Testing Workflow

For mobile testing, generate the current single-file build and host it from the selected distribution endpoint.

Conceptually:

```text
Source
  ↓
Build
  ↓
dist/Delirium.lua
  ↓
Hosted Raw File
  ↓
Mobile Executor
  ↓
loadstring(HttpGet(...))()
```

This allows the same build to be tested on real mobile hardware.

---

# Testing Requirements

V1 should test:

## Components

* Creation
* State changes
* Callbacks
* Runtime updates
* Visibility
* Disabled state
* Destruction

## Lifecycle

* Window destruction
* Tab destruction
* Section destruction
* Component destruction
* Connection cleanup
* Tween cleanup

## Mobile

* Touch scrolling
* Slider gesture conflicts
* Dropdown scrolling
* Textbox + keyboard
* Safe areas
* Portrait
* Landscape
* Floating reopen control
* Adaptive notifications

## Systems

* Theme switching
* Configuration
* Notifications
* Dialogs
* Animations
* Input adaptation

---

# Performance

Delirium is intended for long-running script sessions.

Avoid:

* Unnecessary polling
* Excessive RenderStepped connections
* Repeated object creation
* Unmanaged tweens
* Uncleaned connections
* Memory leaks

Prefer:

* Reusable helpers
* Centralized services
* Cleanup through Maid
* Controlled signals
* Efficient runtime updates
* Lazy work where practical

Performance should never sacrifice basic usability.

---

# Architecture Rules

## Rule 1 — Single Responsibility

Each module should have one primary responsibility.

## Rule 2 — Centralize Shared Behavior

Do not duplicate:

* Theme logic
* Animation logic
* Input logic
* Cleanup logic
* Notification logic

## Rule 3 — Public API Stability

Avoid breaking public APIs unnecessarily.

## Rule 4 — Runtime First

Prefer runtime updates over recreation.

## Rule 5 — Mobile Is Not an Afterthought

Every new interactive component must consider touch behavior before it is considered complete.

---

# V1 Scope

V1 includes:

### Core

* Runtime
* Service Registry
* Maid
* Signal
* Theme Engine
* Animation Engine
* Input Adapter

### Layout

* Window
* Tab
* Section

### Components

* Button
* Toggle
* Slider
* Dropdown
* TextBox
* Keybind
* ColorPicker
* Label
* Paragraph
* Divider

### Services

* Notification
* Dialog
* Config

### UX

* Desktop support
* Mobile support
* Tablet support
* Responsive layout
* Adaptive input
* Touch-safe interactions
* Signature button loading animation

---

# V1 Non-Goals

The following are intentionally outside the primary V1 scope:

* Plugin marketplace
* Visual UI editor
* Theme editor
* Component marketplace
* Advanced developer tooling
* Large plugin architecture
* Excessive component expansion
* Complex physics-based animation systems

These can be evaluated after V1 stability.

---

# V1 Definition of Done

V1 should not be considered complete merely because every component exists.

The following must also be true:

* [ ] Public API is consistent.
* [ ] Parent-child cleanup works.
* [ ] No known lifecycle leaks.
* [ ] Runtime updates work.
* [ ] Theme switching works.
* [ ] Config save/load works.
* [ ] Notifications work on desktop and mobile.
* [ ] Dialogs work on desktop and mobile.
* [ ] Slider does not interfere with scrolling.
* [ ] Textbox handles mobile keyboard behavior.
* [ ] Reopen UI works without a keyboard on mobile.
* [ ] Desktop behavior is stable.
* [ ] Mobile behavior is stable.
* [ ] Tablet behavior is acceptable.
* [ ] Build process is reproducible.
* [ ] Documentation matches the actual API.
* [ ] Regression tests pass.

---

# Roadmap

## V1.0

Focus on stability and polish.

```text
Core
 ↓
Layout
 ↓
Components
 ↓
Services
 ↓
Mobile UX
 ↓
Testing
 ↓
Performance
 ↓
Documentation
 ↓
Release
```

---

## Post-V1

Future features can include:

* Additional components
* More advanced themes
* More animation options
* Better developer tooling
* Additional customization

Features should only be added when they improve the core product.

---

# Versioning

Delirium should use semantic versioning where practical.

```text
MAJOR.MINOR.PATCH
```

Example:

```text
1.0.0
```

Breaking API changes should require a major version.

Non-breaking features should normally use a minor version.

Bug fixes should use a patch version.

Deprecated APIs should be documented before removal.

---

# Contributing

Before modifying Delirium:

1. Understand the existing architecture.
2. Check whether the feature already exists.
3. Avoid duplicating functionality.
4. Preserve public API compatibility.
5. Test desktop behavior.
6. Test mobile behavior when applicable.
7. Test lifecycle cleanup.
8. Update documentation.

A feature should not be merged simply because it works.

It should fit the design language and architecture of Delirium.

---

# Design Decision Rule

When choosing between two implementations, prefer the implementation that provides the best combination of:

1. Developer Experience
2. User Experience
3. Maintainability
4. Performance
5. Consistency

Do not optimize only for the shortest code.

Do not optimize only for the most features.

---

# Current Development Philosophy

Delirium is currently at the stage where the core feature set is largely established.

The next priority is **hardening**, not endlessly adding components.

Focus on:

* API consistency
* Lifecycle correctness
* Mobile UX
* Touch interaction
* Performance
* Testing
* Documentation
* Visual polish

The goal of V1 is not to have the largest feature list.

The goal is to have a small, polished, reliable library that developers actually enjoy using.

---

# Final Principle

Whenever a development decision is unclear, return to the three fundamental questions:

> **Does this make Delirium look better?**

> **Does this make Delirium more powerful?**

> **Does this make Delirium easier to use?**

If none of these are improved, reconsider the change.
