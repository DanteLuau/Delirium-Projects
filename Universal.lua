-- ═══════════════════════════════════════════════════════════════
-- Delirium Universal v2.4.0
-- ═══════════════════════════════════════════════════════════════

print("[Delirium DEBUG] [1/25] Waiting for game to load...")
repeat task.wait() until game:IsLoaded()
print("[Delirium DEBUG] [2/25] Game loaded. Buffer 1s...")
task.wait(1)

-- ── LOAD DELIRIUM ──────────────────────────────────────────────
local DELIRIUM_LOCAL_PATHS = {
    "Delirium/dist/Delirium.lua",                          -- cwd = Dev\
    "Delirium\\dist\\Delirium.lua",                        -- cwd = Dev\ (backslash)
    "Dev/Delirium/dist/Delirium.lua",                      -- cwd = Workspace\
    "Dev\\Delirium\\dist\\Delirium.lua",                    -- cwd = Workspace\ (backslash)
    "dist/Delirium.lua",                                   -- cwd = Delirium\
    "dist\\Delirium.lua",                                  -- cwd = Delirium\ (backslash)
    "../dist/Delirium.lua",                                -- cwd = Delirium-Hub\
    "..\\dist\\Delirium.lua",
    "Workspace/Dev/Delirium/dist/Delirium.lua",
    "Workspace\\Dev\\Delirium\\dist\\Delirium.lua",
    "Madium/Workspace/Dev/Delirium/dist/Delirium.lua",
    "Madium\\Workspace\\Dev\\Delirium\\dist\\Delirium.lua",
}
local DELIRIUM_RAW_URL = "https://raw.githubusercontent.com/DanteLuau/Delirium-Projects/refs/heads/main/dist/Delirium.lua"

local src
if type(readfile) == "function" and type(isfile) == "function" then
    for _, path in ipairs(DELIRIUM_LOCAL_PATHS) do
        if isfile(path) then
            local ok, content = pcall(readfile, path)
            if ok and content and #content > 100 then
                src = content
                print("[Delirium] loaded local: " .. path)
                break
            end
        end
    end
end
if not src or #src < 100 then
    print("[Delirium] fetching from GitHub...")
    src = game:HttpGet(DELIRIUM_RAW_URL)
end
assert(src and #src > 100, "[Delirium] failed to load Delirium.lua")

pcall(function()
    local envG = (type(getgenv) == "function" and getgenv()) or _G or {}
    if envG.__DeliriumRuntime then
        pcall(function() envG.__DeliriumRuntime:Destroy() end)
        envG.__DeliriumRuntime = nil
    end
    if type(_G) == "table" and _G.__DeliriumRuntime then
        pcall(function() _G.__DeliriumRuntime:Destroy() end)
        _G.__DeliriumRuntime = nil
    end
end)

print("[Delirium DEBUG] [3/25] Compiling Delirium...")
local _loadFn, _loadErr = loadstring(src)
if not _loadFn then error("[Delirium] compile error: " .. tostring(_loadErr), 2) end
print("[Delirium DEBUG] [4/25] Executing Bootstrap...")
local _ok, _result = pcall(_loadFn)
if not _ok then error("[Delirium] Bootstrap crashed: " .. tostring(_result), 2) end
local Delirium = _result
assert(Delirium and Delirium.CreateWindow, "[Delirium] nil after load")

assert(
    Delirium.Variants and type(Delirium.Variants.RegisterVariant) == "function",
    "[Universal] Delirium.Variants not found — update Delirium.lua"
)
print("[Delirium DEBUG] [5/25] Delirium loaded. Registering variants...")
local Variants = Delirium.Variants

Variants.RegisterVariant("Button", "Subtle", {
    Height=36, HeightDesc=44, Corner=7, PadTop=5, PadBot=5, PadL=10, PadR=10,
})
Variants.RegisterVariantThemeResolver("Button", "Subtle", function(tokens)
    return { ThemeBorderColor = tokens.Border or tokens.Accent }
end)

-- BUG-TOGGLE-NIL: RegisterVariant does a full REPLACE, not a merge.
-- Partial props wipe TrackW/TrackH/KnobSize → Toggle.New crashes on -style.TrackH/2.
-- Fix: always pass the complete prop set when overriding built-in variants.
Variants.RegisterVariant("Toggle", "Compact", {
    Height=36, HeightDesc=44, Corner=6,
    PadTop=4,  PadBot=4,      PadL=10, PadR=10,
    TrackW=32, TrackH=16,    KnobSize=10,
})
Variants.RegisterVariant("Toggle", "Default", {
    Height=44, HeightDesc=52, Corner=8,
    PadTop=6,  PadBot=6,      PadL=12, PadR=12,
    TrackW=38, TrackH=20,    KnobSize=14,
})
Variants.RegisterVariant("Toggle", "Large", {
    Height=52, HeightDesc=60, Corner=10,
    PadTop=8,  PadBot=8,      PadL=14, PadR=14,
    TrackW=44, TrackH=24,    KnobSize=18,
})
-- BUG-SLIDER-NIL: same issue — partial props strip Corner/PadL/PadR from Slider variants.
Variants.RegisterVariant("Slider", "Compact", {
    Height=48, Corner=6, PadTop=6,  PadBot=6,  PadL=10, PadR=10, TrackH=4,
})
Variants.RegisterVariant("Slider", "Default", {
    Height=56, Corner=8, PadTop=8,  PadBot=8,  PadL=12, PadR=12, TrackH=6,
})
Variants.RegisterVariant("Slider", "Large", {
    Height=64, Corner=10, PadTop=10, PadBot=10, PadL=14, PadR=14, TrackH=8,
})

print("[Delirium DEBUG] [6/25] Loading services...")
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local Stats              = game:GetService("Stats")
local Lighting           = game:GetService("Lighting")
local UserInputService   = game:GetService("UserInputService")
local TeleportService    = game:GetService("TeleportService")
local HttpService        = game:GetService("HttpService")
local GuiService         = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local VirtualUser        = nil
pcall(function() VirtualUser = game:GetService("VirtualUser") end)

local LP = Players.LocalPlayer
if not LP then
    for _ = 1, 50 do
        LP = Players.LocalPlayer
        if LP then break end
        task.wait(0.1)
    end
end
print("[Delirium DEBUG] Services loaded. LP = " .. tostring(LP and LP.Name or "nil"))

-- ═══════════════════════════════════════════════════════════════
-- UTILITIES
-- ═══════════════════════════════════════════════════════════════
local function newMaid()
    local m = {_tasks={}, _dead=false}
    function m:Give(t)
        if self._dead then
            pcall(function()
                if typeof(t)=="RBXScriptConnection" then t:Disconnect()
                elseif type(t)=="function" then t()
                elseif type(t)=="table" then
                    if t.Destroy then t:Destroy() elseif t.Disconnect then t:Disconnect() end
                end
            end)
            return
        end
        table.insert(self._tasks, t)
    end
    function m:Clean()
        if self._dead then return end
        self._dead = true
        for i = #self._tasks, 1, -1 do
            pcall(function()
                local t = self._tasks[i]
                if typeof(t)=="RBXScriptConnection" then t:Disconnect()
                elseif type(t)=="function" then t()
                elseif type(t)=="table" then
                    if t.Destroy then t:Destroy() elseif t.Disconnect then t:Disconnect() end
                end
            end)
            self._tasks[i] = nil
        end
        table.clear(self._tasks)
    end
    m.Destroy = m.Clean
    return m
end

local function fmtTime(s)
    local h   = math.floor(s/3600)
    local m   = math.floor((s%3600)/60)
    local sec = math.floor(s%60)
    if h > 0 then return string.format("%02d:%02d:%02d", h, m, sec) end
    return string.format("%02d:%02d", m, sec)
end

local function round(n, d)
    local factor = 10^(d or 0)
    return math.floor(n*factor+0.5)/factor
end

local function copyToClipboard(text)
    pcall(function()
        if setclipboard then setclipboard(text)
        elseif toclipboard then toclipboard(text)
        end
    end)
end

local GRAPH_BLOCKS = {" ","▁","▂","▃","▄","▅","▆","▇","█"}
local function fpsBlock(fps, cap)
    local ratio = math.clamp(fps / (cap or 120), 0, 1)
    return GRAPH_BLOCKS[math.floor(ratio * 8) + 1]
end

-- Robust label text updater — tries every known Delirium Label API
local function setLabelText(lbl, text)
    if not lbl then return end
    pcall(function()
        if type(lbl.SetTitle)  == "function" then lbl:SetTitle(text); return end
        if type(lbl.Set)       == "function" then lbl:Set(text);      return end
        if type(lbl.SetText)   == "function" then lbl:SetText(text);  return end
        if type(lbl.SetValue)  == "function" then lbl:SetValue(text); return end
        -- Fall back to scanning for TextLabel instances
        if lbl.Instance then
            for _, child in ipairs(lbl.Instance:GetDescendants()) do
                if child:IsA("TextLabel") then child.Text = text end
            end
        end
    end)
end

-- Robust textbox value getter
local function getTextboxValue(tb, fallback)
    if not tb then return fallback or "" end
    local v = fallback or ""
    pcall(function()
        if type(tb.Get)        == "function" then v = tb:Get() or v; return end
        if type(tb.GetValue)   == "function" then v = tb:GetValue() or v; return end
        if type(tb.GetText)    == "function" then v = tb:GetText() or v; return end
        if tb._value           ~= nil        then v = tostring(tb._value); return end
    end)
    return v
end

-- Ensure a Lighting post-processing effect exists; returns it
local function ensureLightingEffect(className)
    local eff = Lighting:FindFirstChildOfClass(className)
    if not eff then
        eff = Instance.new(className)
        eff.Parent = Lighting
    end
    return eff
end

-- ═══════════════════════════════════════════════════════════════
-- CORE: Logger
-- ═══════════════════════════════════════════════════════════════
local Logger = {}
Logger._entries    = {}
Logger._maxEntries = 300
Logger.OnLog       = nil

function Logger.log(level, category, message)
    local entry = {
        time     = os.date("%H:%M:%S"),
        level    = level,
        category = category,
        message  = message,
        tick     = tick(),
    }
    table.insert(Logger._entries, entry)
    if #Logger._entries > Logger._maxEntries then
        table.remove(Logger._entries, 1)
    end
    if Logger.OnLog then pcall(Logger.OnLog, entry) end
end

function Logger.Info(cat, msg)  Logger.log("INFO",  cat, msg) end
function Logger.Warn(cat, msg)  Logger.log("WARN",  cat, msg) end
function Logger.Error(cat, msg) Logger.log("ERROR", cat, msg) end
function Logger.Clear()         table.clear(Logger._entries)  end

function Logger.GetAll(filter)
    if not filter or filter == "" then return {table.unpack(Logger._entries)} end
    local out = {}
    local f = filter:lower()
    for _, e in ipairs(Logger._entries) do
        if e.message:lower():find(f,1,true) or e.category:lower():find(f,1,true) then
            table.insert(out, e)
        end
    end
    return out
end

function Logger.Format(entry)
    return string.format("[%s][%s] %s", entry.time, entry.category:sub(1,8), entry.message:sub(1,60))
end

-- ═══════════════════════════════════════════════════════════════
-- CORE: Module Registry
-- ═══════════════════════════════════════════════════════════════
local Registry = {}
Registry._modules = {}

function Registry.Register(mod)
    assert(type(mod)=="table" and mod.Name, "Registry: module must have Name")
    Registry._modules[mod.Name] = mod
    Logger.Info("Registry", "Registered: "..mod.Name)
end

function Registry.Get(name) return Registry._modules[name] end

function Registry.Enable(name)
    local m = Registry._modules[name]
    if not m or m.Status == "ON" then return end
    local ok, err = pcall(function() m:Enable() end)
    if ok then m.Status = "ON"    Logger.Info(name, "Enabled")
    else      m.Status = "ERROR"  Logger.Error(name, "Enable failed: "..tostring(err)) end
end

function Registry.Disable(name)
    local m = Registry._modules[name]
    if not m then return end
    local ok, err = pcall(function() m:Disable() end)
    if ok then m.Status = "OFF" Logger.Info(name, "Disabled")
    else Logger.Error(name, "Disable failed: "..tostring(err)) end
end

function Registry.DestroyAll()
    for _, mod in pairs(Registry._modules) do pcall(function() mod:Destroy() end) end
    table.clear(Registry._modules)
end

-- ═══════════════════════════════════════════════════════════════
-- CORE: Compatibility
-- ═══════════════════════════════════════════════════════════════
local Compat = {}
function Compat.Check(feature)
    local checks = {
        VirtualUser        = function() return pcall(function() return game:GetService("VirtualUser") end) end,
        TeleportService    = function() return pcall(function() return game:GetService("TeleportService") end) end,
        writefile          = function() return writefile ~= nil end,
        readfile           = function() return readfile ~= nil end,
        HttpGet            = function() return game.HttpGet ~= nil end,
        Stats              = function() return pcall(function() Stats:GetTotalMemoryUsageMb() end) end,
        setfpscap          = function() return setfpscap ~= nil end,
        setclipboard       = function() return setclipboard ~= nil or toclipboard ~= nil end,
        loadstring         = function() return loadstring ~= nil end,
        StreamingEnabled   = function() return workspace.StreamingEnabled end,
        getgenv            = function() return getgenv ~= nil end,
        gethiddenproperty  = function() return gethiddenproperty ~= nil end,
        hookfunction       = function() return hookfunction ~= nil end,
        getrawmetatable    = function() return getrawmetatable ~= nil end,
    }
    local reasons = {
        VirtualUser = "VirtualUser restricted", TeleportService = "TeleportService restricted",
        writefile = "writefile not available", readfile = "readfile not available",
        HttpGet = "HttpGet not available", Stats = "Stats restricted",
        setfpscap = "setfpscap not in executor", setclipboard = "no clipboard API",
        loadstring = "loadstring not available", StreamingEnabled = "streaming disabled",
        getgenv = "getgenv not available", gethiddenproperty = "not available",
        hookfunction = "not available", getrawmetatable = "not available",
    }
    local check = checks[feature]
    if not check then return {Status="UNAVAILABLE", Reason="Unknown feature"} end
    local result = check()
    local ok = (result == true) or (type(result)=="boolean" and result)
    if type(result)=="table" then ok = result[1] end -- pcall returns ok, err
    return ok and {Status="SUPPORTED"} or {Status="UNAVAILABLE", Reason=reasons[feature] or "unavailable"}
end

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Session  (internal only — no UI tab)
-- ═══════════════════════════════════════════════════════════════
local SessionModule = {
    Name="Session", Category="Session", Version="2.3.0", Status="OFF",
    _maid=newMaid(), JoinTime=os.clock(), DeathCount=0, RespawnCount=0,
    FpsHistory={}, PingHistory={}, _deathConn=nil, _charConn=nil,
    Description="Internal session tracking", Dependencies={},
}

function SessionModule:Initialize()
    self.JoinTime = os.clock()
    self.DeathCount = 0; self.RespawnCount = 0
    self.FpsHistory = {}; self.PingHistory = {}
end

function SessionModule:_connectCharacter(char)
    if self._deathConn then self._deathConn:Disconnect() end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then hum = char:WaitForChild("Humanoid", 3) end
    if not hum then return end
    self._deathConn = hum.Died:Connect(function()
        self.DeathCount += 1
        Logger.Info("Session", "Death #"..tostring(self.DeathCount))
    end)
    self._maid:Give(self._deathConn)
end

function SessionModule:Enable()
    local char = LP.Character
    if char then self:_connectCharacter(char) end
    self._charConn = LP.CharacterAdded:Connect(function(c)
        self.RespawnCount += 1
        self:_connectCharacter(c)
    end)
    self._maid:Give(self._charConn)
end

function SessionModule:Disable() self._maid:Clean(); self._maid = newMaid() end
function SessionModule:Destroy() self:Disable() end
function SessionModule:IsSupported() return true end
function SessionModule:GetStatus() return self.Status end
function SessionModule:GetDuration() return os.clock() - self.JoinTime end

function SessionModule:GetSummary()
    local dur = self:GetDuration()
    local function avg(t)
        if #t == 0 then return 0 end
        local s = 0; for _, v in ipairs(t) do s += v end
        return round(s/#t, 1)
    end
    return {
        Duration=fmtTime(dur), Deaths=self.DeathCount, Respawns=self.RespawnCount,
        AvgFPS=avg(self.FpsHistory), AvgPing=avg(self.PingHistory),
    }
end

Registry.Register(SessionModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Performance Monitor
-- ═══════════════════════════════════════════════════════════════
local PerfModule = {
    Name="Performance Monitor", Category="Performance", Version="2.3.0", Status="OFF",
    Description="Live FPS, ping, memory, network stats", Dependencies={},
    _maid=newMaid(),
    FPS=0, AvgFPS=0, MinFPS=math.huge, MaxFPS=0,
    Ping=0, AvgPing=0, MaxPing=0,
    MemoryMB=0, NetRecv=0, NetSend=0,
    _fpsHistory={}, _pingHistory={}, _memHistory={},
    _maxSamples=120, _updateConn=nil, OnUpdate=nil,
    FPSCapEnabled=false, FPSCapValue=60,
}

function PerfModule:_push(buf, val)
    table.insert(buf, val)
    if #buf > self._maxSamples then table.remove(buf, 1) end
end

function PerfModule:_avg(buf)
    if #buf == 0 then return 0 end
    local s = 0; for _, v in ipairs(buf) do s += v end
    return round(s/#buf, 1)
end

function PerfModule:Initialize() end

function PerfModule:Enable()
    local updateInterval = 0.5
    local elapsed = 0
    local _frames = 0

    self._updateConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        _frames += 1
        if elapsed < updateInterval then return end

        local fps = round(_frames / math.max(elapsed, 0.001))
        _frames = 0; elapsed = 0
        self.FPS = fps
        self:_push(self._fpsHistory, fps)
        self.AvgFPS = self:_avg(self._fpsHistory)
        if fps < self.MinFPS then self.MinFPS = fps end
        if fps > self.MaxFPS then self.MaxFPS = fps end

        -- Ping — robust multi-path search
        local ping = 0
        pcall(function()
            local net = Stats:FindFirstChild("Network")
            if net then
                local si = net:FindFirstChild("ServerStatsItem")
                if si then
                    local dp = si:FindFirstChild("Data Ping")
                    if dp then ping = math.round(dp.Value) end
                end
            end
        end)
        -- Fallback: scan Stats descendants for any ping stat
        if ping == 0 then
            pcall(function()
                for _, v in ipairs(Stats:GetDescendants()) do
                    if v.Name:lower():find("ping") and v:IsA("StatBase") then
                        ping = math.round(v.Value); break
                    end
                end
            end)
        end
        self.Ping = ping
        self:_push(self._pingHistory, ping)
        self.AvgPing = self:_avg(self._pingHistory)
        if ping > self.MaxPing then self.MaxPing = ping end

        pcall(function() self.MemoryMB = round(Stats:GetTotalMemoryUsageMb(), 1) end)
        self:_push(self._memHistory, self.MemoryMB)

        -- Network throughput — robust FindFirstChild approach
        pcall(function()
            local net = Stats:FindFirstChild("Network")
            if net then
                local r = net:FindFirstChild("Data Received (KB/s)")
                local s = net:FindFirstChild("Data Sent (KB/s)")
                if r then self.NetRecv = round(r.Value, 1) end
                if s then self.NetSend = round(s.Value, 1) end
            end
        end)

        SessionModule.FpsHistory  = self._fpsHistory
        SessionModule.PingHistory = self._pingHistory

        if self.OnUpdate then pcall(self.OnUpdate, self) end
    end)
    self._maid:Give(self._updateConn)
end

function PerfModule:Disable()
    self:SetFPSCap(false)
    if self._updateConn then self._updateConn:Disconnect(); self._updateConn = nil end
    self._maid:Clean(); self._maid = newMaid()
end

function PerfModule:Destroy() self:Disable() end
function PerfModule:IsSupported() return true end
function PerfModule:GetStatus() return self.Status end

-- FPS Cap: disabled → remove executor cap (Roblox reverts to its own limiter)
function PerfModule:SetFPSCap(enabled, value)
    self.FPSCapEnabled = enabled
    if value then self.FPSCapValue = value end
    if not enabled then
        pcall(function() setfpscap(0) end)   -- 0 = remove cap, Roblox handles default
        Logger.Info("Performance", "FPS cap removed")
        return
    end
    local ok = pcall(function() setfpscap(self.FPSCapValue) end)
    if ok then Logger.Info("Performance", "FPS cap: "..tostring(self.FPSCapValue).."fps")
    else Logger.Warn("Performance", "setfpscap unavailable") end
end

Registry.Register(PerfModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Visual
-- ═══════════════════════════════════════════════════════════════
local VisualModule = {
    Name="Visual", Category="Visual", Version="2.3.0", Status="OFF",
    Description="Fullbright, atmosphere, fog, post-processing", Dependencies={},
    _maid=newMaid(), _originals={},
    FogStart=0, FogEnd=300, FogColor=Color3.fromRGB(200,200,210),
}

local LIGHTING_PROPS = {
    "Brightness","Ambient","OutdoorAmbient",
    "ClockTime","FogStart","FogEnd","FogColor","GlobalShadows",
}

function VisualModule:_backup()
    for _, p in ipairs(LIGHTING_PROPS) do
        pcall(function() self._originals[p] = Lighting[p] end)
    end
    local atmo  = Lighting:FindFirstChildOfClass("Atmosphere")
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    local cc    = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    local sun   = Lighting:FindFirstChildOfClass("SunRaysEffect")
    local blur  = Lighting:FindFirstChildOfClass("BlurEffect")
    if atmo  then self._originals._atmoDensity=atmo.Density; self._originals._atmoHaze=atmo.Haze; self._originals._atmoOffset=atmo.Offset end
    if bloom then self._originals._bloomEnabled=bloom.Enabled; self._originals._bloomIntensity=bloom.Intensity; self._originals._bloomSize=bloom.Size end
    if cc    then self._originals._ccEnabled=cc.Enabled; self._originals._ccBrightness=cc.Brightness; self._originals._ccContrast=cc.Contrast; self._originals._ccSaturation=cc.Saturation end
    if sun   then self._originals._sunEnabled=sun.Enabled end
    if blur  then self._originals._blurEnabled=blur.Enabled; self._originals._blurSize=blur.Size end
end

function VisualModule:_restore()
    for _, p in ipairs(LIGHTING_PROPS) do
        if self._originals[p] ~= nil then pcall(function() Lighting[p] = self._originals[p] end) end
    end
    local atmo  = Lighting:FindFirstChildOfClass("Atmosphere")
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    local cc    = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    local sun   = Lighting:FindFirstChildOfClass("SunRaysEffect")
    local blur  = Lighting:FindFirstChildOfClass("BlurEffect")
    if atmo  and self._originals._atmoDensity  ~= nil then pcall(function() atmo.Density=self._originals._atmoDensity; atmo.Haze=self._originals._atmoHaze; atmo.Offset=self._originals._atmoOffset end) end
    if bloom and self._originals._bloomEnabled ~= nil then pcall(function() bloom.Enabled=self._originals._bloomEnabled; bloom.Intensity=self._originals._bloomIntensity end) end
    if cc    and self._originals._ccEnabled    ~= nil then pcall(function() cc.Enabled=self._originals._ccEnabled; cc.Brightness=self._originals._ccBrightness; cc.Contrast=self._originals._ccContrast; cc.Saturation=self._originals._ccSaturation end) end
    if sun   and self._originals._sunEnabled   ~= nil then pcall(function() sun.Enabled=self._originals._sunEnabled end) end
    if blur  and self._originals._blurEnabled  ~= nil then pcall(function() blur.Enabled=self._originals._blurEnabled; blur.Size=self._originals._blurSize end) end
    table.clear(self._originals)
end

function VisualModule:Initialize() self:_backup() end
function VisualModule:Enable() if not next(self._originals) then self:_backup() end end
function VisualModule:Disable() self:_restore() end
function VisualModule:Destroy() self:Disable(); self._maid:Clean() end
function VisualModule:IsSupported() return true end
function VisualModule:GetStatus() return self.Status end

function VisualModule:SetFullbright(enabled)
    if enabled then
        pcall(function()
            Lighting.Brightness=2; Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1); Lighting.GlobalShadows=false
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then atmo.Density=0; atmo.Haze=0 end
        end)
    else
        pcall(function()
            Lighting.Brightness     = self._originals.Brightness or 1
            Lighting.Ambient        = self._originals.Ambient or Color3.fromRGB(127,127,127)
            Lighting.OutdoorAmbient = self._originals.OutdoorAmbient or Color3.fromRGB(127,127,127)
            Lighting.GlobalShadows  = self._originals.GlobalShadows ~= false
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then atmo.Density=self._originals._atmoDensity or 0.3; atmo.Haze=self._originals._atmoHaze or 0 end
        end)
    end
    Logger.Info("Visual", "Fullbright: "..(enabled and "ON" or "OFF"))
end

-- Fog: clean split between apply and restore
function VisualModule:_applyFog()
    pcall(function()
        Lighting.FogStart = self.FogStart
        Lighting.FogEnd   = self.FogEnd
        Lighting.FogColor = self.FogColor or Color3.fromRGB(200, 200, 210)
    end)
end

function VisualModule:_restoreFog()
    pcall(function()
        Lighting.FogStart = self._originals.FogStart or 0
        Lighting.FogEnd   = self._originals.FogEnd   or 100000
    end)
end

function VisualModule:SetFog(enabled, newStart, newEnd)
    if newStart ~= nil then self.FogStart = newStart end
    if newEnd   ~= nil then self.FogEnd   = newEnd   end
    if enabled then self:_applyFog() else self:_restoreFog() end
end

function VisualModule:SetBrightness(val)  pcall(function() Lighting.Brightness    = val end) end
function VisualModule:SetClockTime(val)   pcall(function() Lighting.ClockTime      = val end) end
function VisualModule:SetGlobalShadows(v) pcall(function() Lighting.GlobalShadows  = v   end) end

-- Post-processing: create effect if game doesn't have one
function VisualModule:SetBloom(enabled, intensity)
    pcall(function()
        local bloom = ensureLightingEffect("BloomEffect")
        bloom.Enabled = enabled
        if intensity ~= nil then bloom.Intensity = intensity end
        if intensity ~= nil then bloom.Size      = math.clamp(intensity * 5, 5, 56) end
    end)
end

function VisualModule:SetSunRays(enabled, intensity)
    pcall(function()
        local sun = ensureLightingEffect("SunRaysEffect")
        sun.Enabled = enabled
        if intensity ~= nil then sun.Intensity = intensity end
    end)
end

function VisualModule:SetBlur(enabled, size)
    pcall(function()
        local blur = ensureLightingEffect("BlurEffect")
        blur.Enabled = enabled
        if size ~= nil then blur.Size = size end
    end)
end

function VisualModule:SetColorCorrection(enabled, brightness, contrast, saturation)
    pcall(function()
        local cc = ensureLightingEffect("ColorCorrectionEffect")
        cc.Enabled = enabled
        if brightness ~= nil then cc.Brightness  = brightness  end
        if contrast   ~= nil then cc.Contrast    = contrast    end
        if saturation ~= nil then cc.Saturation  = saturation  end
    end)
end

function VisualModule:SetDepthOfField(enabled, focusDistance, nearIntensity, farIntensity)
    pcall(function()
        local dof = ensureLightingEffect("DepthOfFieldEffect")
        dof.Enabled = enabled
        if focusDistance ~= nil then dof.FocusDistance   = focusDistance   end
        if nearIntensity ~= nil then dof.NearIntensity   = nearIntensity   end
        if farIntensity  ~= nil then dof.FarIntensity    = farIntensity    end
    end)
end

Registry.Register(VisualModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Player
-- ═══════════════════════════════════════════════════════════════
local PlayerModule = {
    Name="Player", Category="Player", Version="2.3.0", Status="OFF",
    Description="Player info and character utilities", Dependencies={},
    _maid=newMaid(),
}

function PlayerModule:Initialize() end
function PlayerModule:Enable()   Logger.Info("Player", "Module enabled") end
function PlayerModule:Disable()  self._maid:Clean(); self._maid = newMaid() end
function PlayerModule:Destroy()  self:Disable() end
function PlayerModule:IsSupported() return true end
function PlayerModule:GetStatus() return self.Status end

function PlayerModule:GetLocalInfo()
    local info = {
        Name=LP.Name, DisplayName=LP.DisplayName,
        UserId=LP.UserId, AccountAge=LP.AccountAge,
        Team=LP.Team and LP.Team.Name or "None",
    }
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        info.Health=round(hum.Health,1); info.MaxHealth=round(hum.MaxHealth,1)
        info.WalkSpeed=hum.WalkSpeed; info.JumpPower=hum.JumpPower
        info.State=hum:GetState().Name
        -- Check stamina attribute (common in games)
        local st = hum:GetAttribute("Stamina") or hum:GetAttribute("stamina") or hum:GetAttribute("Energy")
        if st then info.Stamina = round(st, 1) end
    end
    if root then
        local p = root.Position
        info.Position = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
        local vel = root.AssemblyLinearVelocity
        info.Speed = round(Vector3.new(vel.X, 0, vel.Z).Magnitude, 1)
    end
    return info
end

function PlayerModule:Rejoin()
    pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
end

function PlayerModule:Reset()
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.Health = 0 end
end

function PlayerModule:SetWalkSpeed(val)
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.WalkSpeed = val end) end
end

function PlayerModule:SetJumpPower(val)
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then pcall(function() hum.JumpPower = val end) end
end

function PlayerModule:GetAllPlayers()
    local list = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local char = p.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        table.insert(list, {
            Name     = p.Name,
            Display  = p.DisplayName,
            UserId   = p.UserId,
            Health   = hum and round(hum.Health, 1) or 0,
            MaxHP    = hum and round(hum.MaxHealth, 1) or 0,
            Position = root and root.Position or nil,
            Team     = p.Team and p.Team.Name or "None",
            IsLocal  = p == LP,
        })
    end
    return list
end

Registry.Register(PlayerModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Server
-- ═══════════════════════════════════════════════════════════════
local ServerModule = {
    Name="Server", Category="Server", Version="2.3.0", Status="OFF",
    Description="Server info, job ID, region", Dependencies={},
    _maid=newMaid(), _gameName="Loading...",
}

function ServerModule:Initialize()
    task.spawn(function()
        pcall(function()
            local info = MarketplaceService:GetProductInfo(game.PlaceId)
            self._gameName = info and info.Name or "Unknown"
        end)
    end)
end

function ServerModule:Enable() Logger.Info("Server", "Module enabled") end
function ServerModule:Disable() self._maid:Clean(); self._maid = newMaid() end
function ServerModule:Destroy() self:Disable() end
function ServerModule:IsSupported() return true end
function ServerModule:GetStatus() return self.Status end

function ServerModule:GetRegion()
    local p = PerfModule.Ping
    if p <= 0 then return "Detecting..." end
    if p < 30  then return "NA East (Low Latency)"
    elseif p < 60  then return "NA East"
    elseif p < 100 then return "NA West / EU West"
    elseif p < 140 then return "EU Central"
    elseif p < 180 then return "EU East"
    elseif p < 230 then return "Asia Pacific"
    elseif p < 300 then return "SEA / Asia"
    else return "High Latency" end
end

function ServerModule:GetInfo()
    return {
        JobId       = game.JobId,
        PlaceId     = tostring(game.PlaceId),
        GameName    = self._gameName,
        PlayerCount = #Players:GetPlayers(),
        MaxPlayers  = Players.MaxPlayers,
        Region      = self:GetRegion(),
        Ping        = PerfModule.Ping,
        AvgPing     = PerfModule.AvgPing,
    }
end

function ServerModule:CopyJobId()
    copyToClipboard(game.JobId)
    Logger.Info("Server", "Copied JobId")
end

function ServerModule:CopyPlaceId()
    copyToClipboard(tostring(game.PlaceId))
    Logger.Info("Server", "Copied PlaceId")
end

function ServerModule:Rejoin()
    pcall(function() TeleportService:Teleport(game.PlaceId, LP) end)
end

function ServerModule:HopServer()
    pcall(function()
        local servers = {}
        local ok, data = pcall(function()
            local resp = game:HttpGet(
                "https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?limit=100"
            )
            return HttpService:JSONDecode(resp)
        end)
        if ok and data and data.data then
            for _, s in ipairs(data.data) do
                if s.id ~= game.JobId and s.playing < s.maxPlayers then
                    table.insert(servers, s.id)
                end
            end
        end
        if #servers > 0 then
            local pick = servers[math.random(1, #servers)]
            TeleportService:TeleportToPlaceInstance(game.PlaceId, pick, LP)
        else
            TeleportService:Teleport(game.PlaceId, LP)
        end
    end)
end

Registry.Register(ServerModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Explorer
-- ═══════════════════════════════════════════════════════════════
local ExplorerModule = {
    Name="Explorer", Category="Explorer", Version="2.3.0", Status="OFF",
    Description="Instance inspector and search", Dependencies={},
    _maid=newMaid(), _results={}, _searchRoot=nil, _selectedInst=nil,
}

function ExplorerModule:Initialize() end
function ExplorerModule:Enable() Logger.Info("Explorer", "Module enabled") end
function ExplorerModule:Disable()
    self._maid:Clean(); self._maid = newMaid()
    self._results = {}; self._selectedInst = nil
end
function ExplorerModule:Destroy() self:Disable() end
function ExplorerModule:IsSupported() return true end
function ExplorerModule:GetStatus() return self.Status end

function ExplorerModule:Search(query, root, maxResults, classFilter)
    local q = query:lower()
    local cf = classFilter and classFilter:lower() or ""
    local results = {}
    maxResults = maxResults or 250
    root = root or self._searchRoot or game

    local function scan(inst, depth)
        if #results >= maxResults then return end
        if depth > 10 then return end
        pcall(function()
            local name = inst.Name:lower()
            local cls  = inst.ClassName:lower()
            local nameMatch  = q == "" or name:find(q, 1, true)
            local classMatch = cf == "" or cls:find(cf, 1, true)
            if nameMatch and classMatch then
                table.insert(results, {
                    Name=inst.Name, ClassName=inst.ClassName,
                    Path=inst:GetFullName(), Children=#inst:GetChildren(),
                    Instance=inst,
                })
            end
            for _, child in ipairs(inst:GetChildren()) do
                scan(child, depth + 1)
            end
        end)
    end

    scan(root, 0)
    self._results = results
    return results
end

function ExplorerModule:GetInstanceInfo(inst)
    local info = {}
    pcall(function()
        info.Name      = inst.Name
        info.ClassName = inst.ClassName
        info.Parent    = inst.Parent and inst.Parent.Name or "nil"
        info.Children  = #inst:GetChildren()
        info.FullPath  = inst:GetFullName()
        local attrs    = inst:GetAttributes()
        local attrCount = 0
        for _ in pairs(attrs) do attrCount += 1 end
        info.Attributes = attrCount
        info.Tags = table.concat(inst:GetTags(), ", ")
        -- Try to get common properties
        pcall(function()
            if inst:IsA("BasePart") then
                info.Position = string.format("%.1f, %.1f, %.1f", inst.Position.X, inst.Position.Y, inst.Position.Z)
                info.Size     = string.format("%.1f, %.1f, %.1f", inst.Size.X, inst.Size.Y, inst.Size.Z)
            end
        end)
    end)
    return info
end

function ExplorerModule:GetChildren(inst)
    local out = {}
    pcall(function()
        for _, child in ipairs(inst:GetChildren()) do
            table.insert(out, {
                Name=child.Name, ClassName=child.ClassName,
                Children=#child:GetChildren(), Instance=child,
            })
        end
    end)
    return out
end

Registry.Register(ExplorerModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Automation
-- ═══════════════════════════════════════════════════════════════
local AutoModule = {
    Name="Automation", Category="Automation", Version="2.3.0", Status="OFF",
    Description="Anti-AFK and automation utilities", Dependencies={},
    _maid=newMaid(), _afkConn=nil, _afkTimerConn=nil, _afkEnabled=false,
}

function AutoModule:Initialize() end
function AutoModule:Enable()  Logger.Info("Automation", "Module enabled") end
function AutoModule:Disable() self:SetAntiAFK(false); self._maid:Clean(); self._maid = newMaid() end
function AutoModule:Destroy() self:Disable() end
function AutoModule:IsSupported() return true end
function AutoModule:GetStatus() return self.Status end

function AutoModule:SetAntiAFK(enabled)
    self._afkEnabled = enabled
    if self._afkConn      then self._afkConn:Disconnect();      self._afkConn = nil      end
    if self._afkTimerConn then self._afkTimerConn:Disconnect(); self._afkTimerConn = nil end

    if not enabled then
        Logger.Info("Automation", "AntiAFK disabled")
        return
    end

    local function fireAfk()
        pcall(function()
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.zero, workspace.CurrentCamera.CFrame)
            end
        end)
        Logger.Info("Automation", "AntiAFK fired")
    end

    -- Primary: LP.Idled fires when Roblox detects ~2min idle
    local ok, conn = pcall(function()
        return LP.Idled:Connect(fireAfk)
    end)
    if ok and conn then
        self._afkConn = conn
        self._maid:Give(conn)
    end

    -- Backup timer every 3.5 minutes regardless of Idled event
    local elapsed = 0
    self._afkTimerConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 210 then return end  -- 3.5 minutes
        elapsed = 0
        fireAfk()
    end)
    self._maid:Give(self._afkTimerConn)
    Logger.Info("Automation", "AntiAFK enabled — Idled event + 3.5min timer backup")
end

Registry.Register(AutoModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: HUD
-- ═══════════════════════════════════════════════════════════════
local HUDModule = {
    Name="HUD", Category="HUD", Version="2.3.0", Status="OFF",
    Description="On-screen overlay", Dependencies={"Performance Monitor"},
    _maid=newMaid(), _gui=nil, _frame=nil, _labels={}, _updateConn=nil,
    Config = {
        ShowFPS=true, ShowPing=true, ShowMemory=false, ShowCoords=true,
        ShowPlayers=false, ShowTimer=true, ShowVelocity=false, ShowState=false,
        ShowHealth=false, ShowStamina=false, ShowGraph=false, ShowDeaths=false,
        ShowNet=false,
        TextSize=12, BgTransparency=0.35,
    },
}

function HUDModule:Initialize() end

function HUDModule:Enable()
    local gui = Instance.new("ScreenGui")
    gui.Name="DeliriumHUD"; gui.DisplayOrder=999
    gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
    gui.Parent=LP.PlayerGui
    self._gui=gui; self._maid:Give(gui)

    local frame = Instance.new("Frame")
    frame.Name="HUDFrame"; frame.Size=UDim2.fromOffset(190,20)
    frame.Position=UDim2.new(1,-200,0,10)
    frame.BackgroundColor3=Color3.fromRGB(8,8,14)
    frame.BackgroundTransparency=self.Config.BgTransparency
    frame.BorderSizePixel=0; frame.Parent=gui

    local corner = Instance.new("UICorner"); corner.CornerRadius=UDim.new(0,6); corner.Parent=frame
    local stroke = Instance.new("UIStroke"); stroke.Color=Color3.fromRGB(60,60,90); stroke.Thickness=1; stroke.Parent=frame
    local pad = Instance.new("UIPadding")
    pad.PaddingTop=UDim.new(0,6); pad.PaddingBottom=UDim.new(0,6)
    pad.PaddingLeft=UDim.new(0,8); pad.PaddingRight=UDim.new(0,8)
    pad.Parent=frame
    local layout = Instance.new("UIListLayout")
    layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,1); layout.Parent=frame
    self._frame=frame; self._labels={}

    local function mkLabel(key, order, color)
        local lbl = Instance.new("TextLabel")
        lbl.Name=key; lbl.Size=UDim2.new(1,0,0,self.Config.TextSize+3)
        lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.Code
        lbl.TextSize=self.Config.TextSize
        lbl.TextColor3=color or Color3.fromRGB(210,210,230)
        lbl.TextXAlignment=Enum.TextXAlignment.Left
        lbl.LayoutOrder=order; lbl.Parent=frame
        self._labels[key]=lbl; return lbl
    end

    mkLabel("fps",1); mkLabel("ping",2); mkLabel("mem",3); mkLabel("net",4)
    mkLabel("coords",5); mkLabel("players",6); mkLabel("timer",7)
    mkLabel("velocity",8); mkLabel("state",9); mkLabel("health",10)
    mkLabel("stamina",11); mkLabel("deaths",12)
    mkLabel("graph",13, Color3.fromRGB(100,220,255))

    -- Drag support
    local dragging, ds, sp = false, nil, nil
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=true; ds=inp.Position; sp=frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType==Enum.UserInputType.MouseMovement or inp.UserInputType==Enum.UserInputType.Touch then
            local d=inp.Position-ds
            frame.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 or inp.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)

    local elapsed2 = 0
    self._updateConn = RunService.Heartbeat:Connect(function(dt)
        elapsed2 += dt
        if elapsed2 < 0.25 then return end
        elapsed2 = 0
        pcall(function()
            local cfg  = self.Config
            local lbl  = self._labels
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local ts   = cfg.TextSize

            local function upd(key, visible, text, color)
                local l = lbl[key]
                if not l then return end
                l.Visible = visible
                l.Size = UDim2.new(1,0,0,ts+3)
                l.TextSize = ts
                if visible then
                    l.Text = text or ""
                    if color then l.TextColor3 = color end
                end
            end

            upd("fps", cfg.ShowFPS,
                string.format("FPS %d  avg %d  min %d", PerfModule.FPS, PerfModule.AvgFPS,
                    PerfModule.MinFPS==math.huge and 0 or PerfModule.MinFPS))

            local p = PerfModule.Ping
            local pingColor = p>200 and Color3.fromRGB(220,80,80) or p>100 and Color3.fromRGB(220,180,60) or Color3.fromRGB(80,200,110)
            upd("ping", cfg.ShowPing, string.format("Ping %dms  avg %d", p, PerfModule.AvgPing), pingColor)

            upd("mem",  cfg.ShowMemory,  string.format("RAM  %.1f MB", PerfModule.MemoryMB))
            upd("net",  cfg.ShowNet,     string.format("Net  ↓%.1f ↑%.1f KB/s", PerfModule.NetRecv, PerfModule.NetSend))

            if cfg.ShowCoords then
                if root then
                    local pos = root.Position
                    upd("coords", true, string.format("%.0f  %.0f  %.0f", pos.X, pos.Y, pos.Z))
                else
                    upd("coords", true, "Coords  no char")
                end
            else
                upd("coords", false, "")
            end

            upd("players", cfg.ShowPlayers,
                string.format("Players  %d/%d", #Players:GetPlayers(), Players.MaxPlayers))
            upd("timer",   cfg.ShowTimer, "Time  "..fmtTime(SessionModule:GetDuration()))

            if cfg.ShowVelocity and root then
                local vel = root.AssemblyLinearVelocity
                local spd = round(Vector3.new(vel.X,0,vel.Z).Magnitude, 1)
                upd("velocity", true, string.format("Speed  %.1f st/s", spd))
            else upd("velocity", false, "") end

            upd("state",  cfg.ShowState  and hum ~= nil, hum and ("State  "..hum:GetState().Name) or "")

            if cfg.ShowHealth and hum then
                local ratio = hum.Health / math.max(hum.MaxHealth, 1)
                local hpColor = ratio<0.3 and Color3.fromRGB(220,60,60) or ratio<0.6 and Color3.fromRGB(220,180,60) or Color3.fromRGB(80,200,110)
                if hum.MaxHealth >= 1e14 then
                    upd("health", true, "HP  ∞  (god)", Color3.fromRGB(120,255,180))
                else
                    upd("health", true, string.format("HP  %.0f / %.0f", hum.Health, hum.MaxHealth), hpColor)
                end
            else upd("health", false, "") end

            if cfg.ShowStamina and hum then
                local st = hum:GetAttribute("Stamina") or hum:GetAttribute("stamina") or hum:GetAttribute("Energy")
                upd("stamina", true, st and string.format("Stamina  %.0f", st) or "Stamina  N/A")
            else upd("stamina", false, "") end

            upd("deaths", cfg.ShowDeaths, "Deaths  "..tostring(SessionModule.DeathCount))

            if cfg.ShowGraph then
                local hist = PerfModule._fpsHistory
                if #hist > 0 then
                    local maxFps = math.max(PerfModule.MaxFPS, 60)
                    local startI = math.max(1, #hist-22)
                    local g = ""
                    for i = startI, #hist do g = g..fpsBlock(hist[i], maxFps) end
                    if lbl.graph then lbl.graph.Visible=true; lbl.graph.Text="▕"..g.."▏"; lbl.graph.TextSize=ts end
                end
            else if lbl.graph then lbl.graph.Visible=false end end

            frame.Size = UDim2.fromOffset(190, layout.AbsoluteContentSize.Y+14)
        end)
    end)
    self._maid:Give(self._updateConn)
    Logger.Info("HUD", "Enabled")
end

function HUDModule:SetPosition(preset)
    if not self._frame then return end
    local presets = {
        TopRight    = UDim2.new(1,-200,0,10),
        TopLeft     = UDim2.new(0,10,0,10),
        BottomRight = UDim2.new(1,-200,1,-130),
        BottomLeft  = UDim2.new(0,10,1,-130),
    }
    if presets[preset] then self._frame.Position = presets[preset] end
end

function HUDModule:SetBgTransparency(val)
    self.Config.BgTransparency = val
    if self._frame then self._frame.BackgroundTransparency = val end
end

function HUDModule:SetTextSize(val)
    self.Config.TextSize = val
    if self._frame then
        for _, lbl in pairs(self._labels) do
            if lbl then
                lbl.TextSize = val
                lbl.Size = UDim2.new(1,0,0,val+3)
            end
        end
    end
end

function HUDModule:Disable()
    if self._gui and self._gui.Parent then self._gui:Destroy() end
    self._gui=nil; self._frame=nil; self._labels={}
    self._maid:Clean(); self._maid = newMaid()
    Logger.Info("HUD", "Disabled")
end

function HUDModule:Destroy() self:Disable() end
function HUDModule:IsSupported() return true end
function HUDModule:GetStatus() return self.Status end

Registry.Register(HUDModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Character
-- ═══════════════════════════════════════════════════════════════
local CharacterModule = {
    Name="Character", Category="Character", Version="2.3.0", Status="OFF",
    Description="Movement, fly, noclip, god mode, teleport", Dependencies={},
    _maid=newMaid(),
    AutoSprint=false, AutoJump=false, InfiniteJump=false,
    Noclip=false, Fly=false, GodMode=false, FlySpeed=50,
    _flyBV=nil, _flyBG=nil, _flyConn=nil,
    _noclipConn=nil, _godConn=nil, _jumpConn=nil,
    _infJumpConn=nil, _sprintConn=nil,
    _savedPos=nil, _origWalkSpeed=nil,
    _clickTPTool=nil, _clickTPConn=nil,
}

function CharacterModule:Initialize() end
function CharacterModule:Enable() Logger.Info("Character", "Module enabled") end

function CharacterModule:Disable()
    self:SetFly(false); self:SetNoclip(false); self:SetGodMode(false)
    self:SetInfiniteJump(false); self:SetAutoJump(false); self:SetAutoSprint(false)
    self:RemoveClickTPTool()
    self._maid:Clean(); self._maid = newMaid()
end

function CharacterModule:Destroy() self:Disable() end
function CharacterModule:IsSupported() return true end
function CharacterModule:GetStatus() return self.Status end

function CharacterModule:_getHumanoid()
    local c = LP.Character; return c and c:FindFirstChildOfClass("Humanoid")
end
function CharacterModule:_getRoot()
    local c = LP.Character; return c and c:FindFirstChild("HumanoidRootPart")
end

function CharacterModule:SetAutoSprint(enabled)
    self.AutoSprint = enabled
    if self._sprintConn then self._sprintConn:Disconnect(); self._sprintConn = nil end
    if not enabled then
        local hum = self:_getHumanoid()
        if hum and self._origWalkSpeed then pcall(function() hum.WalkSpeed = self._origWalkSpeed end) end
        self._origWalkSpeed = nil; return
    end
    local hum = self:_getHumanoid()
    if hum then self._origWalkSpeed = hum.WalkSpeed end
    self._sprintConn = RunService.Heartbeat:Connect(function()
        local h = self:_getHumanoid(); if not h then return end
        if not self._origWalkSpeed then self._origWalkSpeed = h.WalkSpeed end
        pcall(function()
            h.WalkSpeed = h.MoveDirection.Magnitude > 0 and self._origWalkSpeed*1.55 or self._origWalkSpeed
        end)
    end)
    self._maid:Give(self._sprintConn)
end

function CharacterModule:SetAutoJump(enabled)
    self.AutoJump = enabled
    if self._jumpConn then self._jumpConn:Disconnect(); self._jumpConn = nil end
    if not enabled then return end
    local last = 0
    self._jumpConn = RunService.Heartbeat:Connect(function()
        local t = tick(); if t-last < 0.32 then return end
        local hum = self:_getHumanoid()
        if hum and hum.FloorMaterial ~= Enum.Material.Air then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
            last = t
        end
    end)
    self._maid:Give(self._jumpConn)
end

function CharacterModule:SetInfiniteJump(enabled)
    self.InfiniteJump = enabled
    if self._infJumpConn then self._infJumpConn:Disconnect(); self._infJumpConn = nil end
    if not enabled then return end
    self._infJumpConn = UserInputService.JumpRequest:Connect(function()
        if not self.InfiniteJump then return end
        local hum = self:_getHumanoid()
        if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
    end)
    self._maid:Give(self._infJumpConn)
end

function CharacterModule:SetNoclip(enabled)
    self.Noclip = enabled
    if self._noclipConn then self._noclipConn:Disconnect(); self._noclipConn = nil end
    if not enabled then
        local char = LP.Character; if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = true end) end
        end
        return
    end
    self._noclipConn = RunService.Stepped:Connect(function()
        local char = LP.Character; if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
        end
    end)
    self._maid:Give(self._noclipConn)
end

-- Fly — fixed: stiffer BodyGyro prevents collision spin
function CharacterModule:SetFly(enabled)
    self.Fly = enabled
    if self._flyBV  then pcall(function() self._flyBV:Destroy()  end); self._flyBV  = nil end
    if self._flyBG  then pcall(function() self._flyBG:Destroy()  end); self._flyBG  = nil end
    if self._flyConn then self._flyConn:Disconnect(); self._flyConn = nil end

    if not enabled then
        local hum = self:_getHumanoid()
        if hum then pcall(function() hum.PlatformStand = false end) end
        Logger.Info("Character", "Fly disabled"); return
    end

    local root = self:_getRoot()
    if not root then Logger.Warn("Character", "Fly: no HumanoidRootPart"); return end

    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Velocity = Vector3.zero; bv.P = 1e5
    bv.Parent = root; self._flyBV = bv; self._maid:Give(bv)

    -- High-stiffness BodyGyro: prevents spin on object collision
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e7,1e7,1e7)  -- very high = collision cant spin you
    bg.P         = 5e5                         -- stiff spring
    bg.D         = 2500                        -- heavy damping
    bg.CFrame    = root.CFrame                 -- init to current orientation
    bg.Parent    = root; self._flyBG = bg; self._maid:Give(bg)

    local cam = workspace.CurrentCamera
    self._flyConn = RunService.RenderStepped:Connect(function()
        if not self.Fly then return end
        local hum = self:_getHumanoid()
        if hum then pcall(function() hum.PlatformStand = true end) end

        local dir = Vector3.zero; local cf = cam.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cf.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis end

        bv.Velocity = dir.Magnitude > 0 and dir.Unit * self.FlySpeed or Vector3.zero

        -- Lock orientation: Y-axis yaw only (no pitch/roll from collisions)
        local yaw = math.atan2(-cf.LookVector.X, -cf.LookVector.Z)
        bg.CFrame  = CFrame.new(root.Position) * CFrame.Angles(0, yaw, 0)
    end)
    self._maid:Give(self._flyConn)
    Logger.Info("Character", "Fly enabled ("..tostring(self.FlySpeed).." speed)")
end

function CharacterModule:SetGodMode(enabled)
    self.GodMode = enabled
    if self._godConn then self._godConn:Disconnect(); self._godConn = nil end
    if not enabled then Logger.Info("Character", "God Mode disabled"); return end
    self._godConn = RunService.Heartbeat:Connect(function()
        if not self.GodMode then return end
        local char = LP.Character; if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() if hum.Health < hum.MaxHealth then hum.Health = hum.MaxHealth end end) end
    end)
    self._maid:Give(self._godConn)
    Logger.Info("Character", "God Mode enabled")
end

-- Click-to-TP Tool: give player an equippable Roblox Tool
function CharacterModule:GiveClickTPTool()
    self:RemoveClickTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "ClickTP"; tool.RequiresHandle = false
    tool.ToolTip = "Equip then click anywhere to teleport"
    tool.Parent = LP.Backpack
    self._clickTPTool = tool

    local conn = tool.Activated:Connect(function()
        local root = self:_getRoot(); if not root then return end
        local mouse = LP:GetMouse()
        if mouse then
            pcall(function()
                root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
            end)
            Logger.Info("Character", "Click-TP fired")
        end
    end)
    self._clickTPConn = conn
    self._maid:Give(tool); self._maid:Give(conn)
    Logger.Info("Character", "Click-TP tool given")
end

function CharacterModule:RemoveClickTPTool()
    if self._clickTPConn then self._clickTPConn:Disconnect(); self._clickTPConn = nil end
    if self._clickTPTool and self._clickTPTool.Parent then
        pcall(function() self._clickTPTool:Destroy() end)
    end
    self._clickTPTool = nil
end

-- TP to Spawn: finds all SpawnLocations, picks random if >1
function CharacterModule:TeleportToSpawn()
    local root = self:_getRoot(); if not root then return end
    local spawns = {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("SpawnLocation") then table.insert(spawns, v) end
    end
    pcall(function()
        if #spawns == 0 then
            root.CFrame = CFrame.new(0, 10, 0)
            Logger.Info("Character", "No SpawnLocations — TP to origin")
        elseif #spawns == 1 then
            root.CFrame = spawns[1].CFrame + Vector3.new(0, 3.5, 0)
            Logger.Info("Character", "TP to single spawn")
        else
            local pick = spawns[math.random(1, #spawns)]
            root.CFrame = pick.CFrame + Vector3.new(0, 3.5, 0)
            Logger.Info("Character", string.format("TP to random spawn (%d/%d)", table.find(spawns,pick) or 0, #spawns))
        end
    end)
end

function CharacterModule:SavePosition()
    local root = self:_getRoot()
    if root then
        self._savedPos = root.CFrame
        Logger.Info("Character", "Position saved")
    end
end

function CharacterModule:LoadPosition()
    local root = self:_getRoot()
    if root and self._savedPos then
        pcall(function() root.CFrame = self._savedPos end)
        Logger.Info("Character", "Position loaded")
    end
end

Registry.Register(CharacterModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Camera
-- ═══════════════════════════════════════════════════════════════
local CameraModule = {
    Name="Camera", Category="Camera", Version="2.3.0", Status="OFF",
    Description="FOV, camera modes, lock, shake disable", Dependencies={},
    _maid=newMaid(), _cam=nil,
    _origFOV=nil, _origMode=nil, _origSubject=nil,
    _origMinZoom=nil, _origMaxZoom=nil,
    _preLockType=nil, _lockCFrame=nil, _lockConn=nil,
    _fpConn=nil,
}

function CameraModule:Initialize() end

function CameraModule:Enable()
    self._cam = workspace.CurrentCamera
    self._origFOV     = self._cam.FieldOfView
    self._origMode    = self._cam.CameraType
    self._origSubject = self._cam.CameraSubject
    self._origMinZoom = LP.CameraMinZoomDistance
    self._origMaxZoom = LP.CameraMaxZoomDistance
    Logger.Info("Camera", "Module enabled")
end

function CameraModule:Disable()
    self:ResetCamera(); self:SetCameraLock(false); self:SetCameraMode("ThirdPerson")
    self._maid:Clean(); self._maid = newMaid()
end

function CameraModule:Destroy() self:Disable() end
function CameraModule:IsSupported() return true end
function CameraModule:GetStatus() return self.Status end

function CameraModule:SetFOV(value)
    self._cam = self._cam or workspace.CurrentCamera
    pcall(function() self._cam.FieldOfView = math.clamp(value, 1, 120) end)
end

-- First Person: lock zoom to 0 every frame so game scripts can't override it
function CameraModule:SetCameraMode(mode)
    self._cam = self._cam or workspace.CurrentCamera
    -- disconnect any existing FP loop
    if self._fpConn then self._fpConn:Disconnect(); self._fpConn = nil end

    if mode == "FirstPerson" then
        if not self._origMinZoom then
            pcall(function()
                self._origMinZoom = LP.CameraMinZoomDistance
                self._origMaxZoom = LP.CameraMaxZoomDistance
            end)
        end
        -- run every RenderStepped to fight game scripts resetting zoom
        self._fpConn = RunService.RenderStepped:Connect(function()
            pcall(function()
                LP.CameraMinZoomDistance = 0
                LP.CameraMaxZoomDistance = 0
            end)
        end)
        self._maid:Give(self._fpConn)
        Logger.Info("Camera", "First Person locked")
    else
        -- ThirdPerson: restore zoom distances
        pcall(function()
            LP.CameraMinZoomDistance = self._origMinZoom or 0.5
            LP.CameraMaxZoomDistance = self._origMaxZoom or 400
            self._cam.CameraType = Enum.CameraType.Custom
            local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
            if hum then self._cam.CameraSubject = hum end
        end)
        self._origMinZoom = nil; self._origMaxZoom = nil
        Logger.Info("Camera", "Third Person restored")
    end
end

-- Camera Lock: Scriptable + enforce CameraType every frame (game scripts can't override)
function CameraModule:SetCameraLock(enabled)
    if self._lockConn then self._lockConn:Disconnect(); self._lockConn = nil end
    if not enabled then
        if self._preLockType then
            pcall(function() self._cam.CameraType = self._preLockType end)
            self._preLockType = nil
        end
        Logger.Info("Camera", "Lock disabled"); return
    end
    self._cam = self._cam or workspace.CurrentCamera
    self._preLockType = self._cam.CameraType
    self._lockCFrame  = self._cam.CFrame
    pcall(function() self._cam.CameraType = Enum.CameraType.Scriptable end)
    self._lockConn = RunService.RenderStepped:Connect(function()
        pcall(function()
            -- keep re-enforcing Scriptable in case game scripts fight it
            if self._cam.CameraType ~= Enum.CameraType.Scriptable then
                self._cam.CameraType = Enum.CameraType.Scriptable
            end
            self._cam.CFrame = self._lockCFrame
        end)
    end)
    self._maid:Give(self._lockConn)
    Logger.Info("Camera", "Lock enabled")
end

function CameraModule:ResetCamera()
    self._cam = self._cam or workspace.CurrentCamera
    if self._fpConn then self._fpConn:Disconnect(); self._fpConn = nil end
    pcall(function()
        self._cam.FieldOfView   = self._origFOV    or 70
        self._cam.CameraType    = self._origMode   or Enum.CameraType.Custom
        self._cam.CameraSubject = self._origSubject
        LP.CameraMinZoomDistance = self._origMinZoom or 0.5
        LP.CameraMaxZoomDistance = self._origMaxZoom or 400
    end)
    Logger.Info("Camera", "Reset to defaults")
end

function CameraModule:DisableShake(enabled)
    if not enabled then return end
    self._cam = self._cam or workspace.CurrentCamera
    pcall(function() self._cam:SetAttribute("ShakeEnabled", false) end)
    pcall(function()
        for _, v in pairs(self._cam:GetDescendants()) do
            if v.Name:lower():find("shake") then v:Destroy() end
        end
    end)
    Logger.Info("Camera", "Shake disable attempted")
end

-- View Distance: streaming radius + quality setting fallback
function CameraModule:SetViewDistance(value)
    local applied = false
    pcall(function()
        if workspace.StreamingEnabled then
            workspace.StreamingTargetRadius = math.clamp(value, 64, 10000)
            workspace.StreamingMinRadius    = math.clamp(value * 0.35, 32, 5000)
            applied = true
        end
    end)
    -- Fallback: UserGameSettings quality level (1–21 scale)
    pcall(function()
        local ugs = UserSettings():GetService("UserGameSettings")
        if ugs then
            local level = math.clamp(math.floor((value / 1000) * 10) + 1, 1, 10)
            ugs.SavedQualityLevel = level
            applied = true
        end
    end)
    local note = applied and "" or " (no effect — streaming off + no quality API)"
    Logger.Info("Camera", "ViewDistance: "..tostring(value)..note)
end

Registry.Register(CameraModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Utility
-- ═══════════════════════════════════════════════════════════════
local UtilityModule = {
    Name="Utility", Category="Utility", Version="2.3.0", Status="OFF",
    Description="Copy utilities, screenshot mode, script loaders", Dependencies={},
    _maid=newMaid(), ScreenshotMode=false,
}

function UtilityModule:Initialize() end
function UtilityModule:Enable()  Logger.Info("Utility", "Module enabled") end
function UtilityModule:Disable()
    if self.ScreenshotMode then self:SetScreenshotMode(false) end
    self._maid:Clean(); self._maid = newMaid()
end
function UtilityModule:Destroy() self:Disable() end
function UtilityModule:IsSupported() return true end
function UtilityModule:GetStatus() return self.Status end

function UtilityModule:CopyCharacterName()
    local c = LP.Character
    if c then copyToClipboard(c.Name); Delirium:Notify({Title="Copied", Message="Char: "..c.Name, Duration=2}) end
end

function UtilityModule:CopyDisplayName()
    copyToClipboard(LP.DisplayName)
    Delirium:Notify({Title="Copied", Message="Display: "..LP.DisplayName, Duration=2})
end

function UtilityModule:SetScreenshotMode(enabled)
    self.ScreenshotMode = enabled
    pcall(function()
        local hud = LP.PlayerGui:FindFirstChild("DeliriumHUD")
        if hud then hud.Enabled = not enabled end
    end)
    Delirium:Notify({Title="Screenshot", Message=enabled and "ON — HUD hidden" or "OFF", Duration=2})
end

function UtilityModule:LoadScript(name, url)
    Delirium:Notify({Title="Loading", Message=name.."...", Duration=2})
    task.spawn(function()
        local ok, err = pcall(function()
            loadstring(game:HttpGet(url))()
        end)
        if ok then
            Logger.Info("Utility", "Loaded: "..name)
            Delirium:Notify({Title=name, Message="Loaded OK", Duration=3})
        else
            Logger.Error("Utility", "Load failed "..name..": "..tostring(err))
            Delirium:Notify({Title="Error", Message=tostring(err):sub(1,80), Duration=5})
        end
    end)
end

Registry.Register(UtilityModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Performance Optimizer
-- ═══════════════════════════════════════════════════════════════
local OptimModule = {
    Name="Performance Optimizer", Category="Performance", Version="2.3.0", Status="OFF",
    Description="Optimization presets: Low, Balanced, Performance", Dependencies={},
    _maid=newMaid(), _applied=false, _stateMap={}, CurrentProfile="BALANCED",
}

local PROFILES = {
    -- LOW: minimal — just kills sun rays + blur
    LOW = {
        DisableBloom=false, DisableAtmo=false, DisableCC=false,
        DisableSunRays=true, DisableBlur=true, ReduceParticles=false, GlobalShadows=true,
    },
    -- BALANCED: moderate — adds particle reduction
    BALANCED = {
        DisableBloom=false, DisableAtmo=false, DisableCC=false,
        DisableSunRays=true, DisableBlur=true, ReduceParticles=true, GlobalShadows=true,
    },
    -- PERFORMANCE: maximum — kills everything expensive
    PERFORMANCE = {
        DisableBloom=true, DisableAtmo=true, DisableCC=false,
        DisableSunRays=true, DisableBlur=true, ReduceParticles=true, GlobalShadows=false,
    },
}

function OptimModule:_saveState(inst, prop)
    if not self._stateMap[inst] then self._stateMap[inst] = {} end
    if self._stateMap[inst][prop] == nil then
        pcall(function() self._stateMap[inst][prop] = inst[prop] end)
    end
end

function OptimModule:_restoreAll()
    for inst, props in pairs(self._stateMap) do
        for prop, val in pairs(props) do pcall(function() inst[prop] = val end) end
    end
    table.clear(self._stateMap)
end

function OptimModule:ApplyProfile(profileName)
    local profile = PROFILES[profileName]
    if not profile then Logger.Warn("Optimizer", "Unknown profile: "..tostring(profileName)); return end
    self.CurrentProfile = profileName
    if self._applied then self:_restoreAll() end
    self._applied = true

    pcall(function()
        for _, eff in ipairs(Lighting:GetChildren()) do
            if eff:IsA("BloomEffect") and profile.DisableBloom then
                self:_saveState(eff, "Enabled"); eff.Enabled = false
            elseif eff:IsA("SunRaysEffect") and profile.DisableSunRays then
                self:_saveState(eff, "Enabled"); eff.Enabled = false
            elseif (eff:IsA("BlurEffect") or eff:IsA("DepthOfFieldEffect")) and profile.DisableBlur then
                self:_saveState(eff, "Enabled"); eff.Enabled = false
            elseif eff:IsA("Atmosphere") and profile.DisableAtmo then
                self:_saveState(eff, "Density"); self:_saveState(eff, "Haze")
                eff.Density = 0; eff.Haze = 0
            end
        end
        if not profile.GlobalShadows then
            self:_saveState(Lighting, "GlobalShadows"); Lighting.GlobalShadows = false
        end
        if profile.ReduceParticles then
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") then
                    self:_saveState(v, "Rate"); self:_saveState(v, "Speed")
                    pcall(function()
                        v.Rate  = math.min(v.Rate, 5)
                        v.Speed = NumberRange.new(v.Speed.Min * 0.5, v.Speed.Max * 0.5)
                    end)
                end
            end
        end
    end)
    Logger.Info("Optimizer", "Applied: "..profileName)
end

function OptimModule:Initialize() end
function OptimModule:Enable()  self:ApplyProfile(self.CurrentProfile) end
function OptimModule:Disable() self:_restoreAll(); self._applied=false; Logger.Info("Optimizer","Restored") end
function OptimModule:Destroy() self:Disable() end
function OptimModule:IsSupported() return true end
function OptimModule:GetStatus() return self.Status end

Registry.Register(OptimModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Configuration
-- ═══════════════════════════════════════════════════════════════
local ConfigModule = {
    Name="Configuration", Category="Configuration", Version="2.3.0", Status="OFF",
    Description="Save/load/import/export config", Dependencies={},
    _maid=newMaid(), _config={},
}

local CONFIG_VERSION = 3

function ConfigModule:Initialize() self:_loadDefaults() end

function ConfigModule:_loadDefaults()
    self._config = {
        Version     = CONFIG_VERSION,
        HUD         = {Enabled=false, ShowFPS=true, ShowPing=true, ShowMemory=false, ShowCoords=true, ShowTimer=true, ShowPlayers=false, ShowVelocity=false, ShowState=false, ShowHealth=false, ShowStamina=false, ShowGraph=false, ShowDeaths=false, ShowNet=false},
        Visual      = {Fullbright=false, GlobalShadows=true},
        Performance = {MonitorEnabled=true, Profile="BALANCED", FPSCap=false, FPSCapValue=60},
        Automation  = {AntiAFK=false, PingThreshold=250},
        Character   = {FlySpeed=50},
        Camera      = {FOV=70},
        UI          = {Density="Default"},
    }
end

function ConfigModule:Get(section, key)
    if not self._config[section] then return nil end
    if key then return self._config[section][key] end
    return self._config[section]
end

function ConfigModule:Set(section, key, value)
    if not self._config[section] then self._config[section] = {} end
    self._config[section][key] = value
end

function ConfigModule:Export()
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self._config)
    if ok then copyToClipboard(encoded); Logger.Info("Config", "Exported"); return encoded end
    Logger.Error("Config", "Export failed: "..tostring(encoded)); return nil
end

function ConfigModule:Import(jsonStr)
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, jsonStr)
    if ok and type(decoded)=="table" then
        for section, data in pairs(decoded) do
            if type(data)=="table" then
                if not self._config[section] then self._config[section] = {} end
                for k, v in pairs(data) do self._config[section][k] = v end
            end
        end
        Logger.Info("Config", "Imported"); return true
    end
    Logger.Error("Config", "Import failed — invalid JSON"); return false
end

function ConfigModule:Reset() self:_loadDefaults(); Logger.Info("Config","Reset") end
function ConfigModule:Enable()  end
function ConfigModule:Disable() end
function ConfigModule:Destroy() end
function ConfigModule:IsSupported() return true end
function ConfigModule:GetStatus() return self.Status end

Registry.Register(ConfigModule)

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZE
-- ═══════════════════════════════════════════════════════════════
print("[Delirium DEBUG] [7/25] Initializing modules...")
for name, mod in pairs(Registry._modules) do
    local ok, err = pcall(function() mod:Initialize() end)
    if ok then mod.Status="OFF"; Logger.Info("Universal","Init OK: "..name)
    else       mod.Status="ERROR"; Logger.Error("Universal","Init fail ["..name.."]: "..tostring(err)) end
end

Registry.Enable("Session")
Registry.Enable("Performance Monitor")
VisualModule:_backup()
Registry.Enable("Character")
Registry.Enable("Camera")
Registry.Enable("Utility")

-- ═══════════════════════════════════════════════════════════════
-- UI CONSTRUCTION
-- ═══════════════════════════════════════════════════════════════
local UI_DENSITY = ConfigModule:Get("UI","Density") or "Default"
if not Variants.HasVariant("Toggle", UI_DENSITY) then
    Logger.Warn("VariantEngine","Unknown density '"..tostring(UI_DENSITY).."'; using Default")
    UI_DENSITY = "Default"
end

print("[Delirium DEBUG] [8/25] Building Window...")
local Win = Delirium:CreateWindow({
    Name="Universal", Subtitle="v2.4.0 — Delirium",
    Size=UDim2.fromOffset(600,420),
})

-- ─────────────────────────────────────────────────────────────
-- TAB: Home
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 1] Home...")
local homeTab = Win:CreateTab({Name="Home"})

local quickSection = homeTab:CreateSection("Quick Actions")
quickSection:CreateButton({Name="Rejoin", Description="Reconnect to this server", Variant="Large",
    Callback=function() PlayerModule:Rejoin() end})
quickSection:CreateButton({Name="Hop Server", Description="Jump to a random different server", Variant="Large",
    Callback=function()
        Delirium:Notify({Title="Server",Message="Hopping...",Duration=2})
        ServerModule:HopServer()
    end})
quickSection:CreateButton({Name="Reset Character", Description="Kill and respawn your character",
    Callback=function()
        Delirium.Dialog.Confirm({
            Title   = "Reset Character?",
            Message = "This will kill your character and trigger a respawn.",
            Type    = "Warning",
            Confirm = { Label = "Reset", Callback = function() PlayerModule:Reset() end },
            Cancel  = { Label = "Cancel" },
        })
    end})
quickSection:CreateButton({Name="Copy Job ID", Variant="Subtle",
    Callback=function() ServerModule:CopyJobId(); Delirium:Notify({Title="Copied",Message="Job ID",Duration=2}) end})
quickSection:CreateButton({Name="Copy Place ID", Variant="Subtle",
    Callback=function() ServerModule:CopyPlaceId(); Delirium:Notify({Title="Copied",Message="Place ID",Duration=2}) end})

local sessionSec = homeTab:CreateSection("Current Session")
local homeSessionLabel = sessionSec:CreateLabel({Name="SessionInfo", Text="Loading..."})
local function refreshHomeSession()
    local s = SessionModule:GetSummary()
    local info = PerfModule
    setLabelText(homeSessionLabel, string.format(
        "Time: %s  |  Deaths: %d  |  Respawns: %d\nFPS: %d  |  Ping: %dms  |  RAM: %.0f MB",
        s.Duration, s.Deaths, s.Respawns, info.FPS, info.Ping, info.MemoryMB
    ))
end
local _homeTimer = 0
RunService.Heartbeat:Connect(function(dt)
    _homeTimer += dt; if _homeTimer < 1 then return end; _homeTimer = 0
    pcall(refreshHomeSession)
end)
task.delay(1, refreshHomeSession)

-- ─────────────────────────────────────────────────────────────
-- TAB: Player
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 2] Player...")
local playerTab = Win:CreateTab({Name="Player"})

local localSec = playerTab:CreateSection("Local Player")
local playerInfoLabel = localSec:CreateLabel({Name="PlayerInfo", Text="Loading..."})

local function refreshPlayerInfo()
    local info = PlayerModule:GetLocalInfo()
    local lines = {
        string.format("%s  (%s)", info.Name, info.DisplayName),
        string.format("ID: %d   Age: %dd   Team: %s", info.UserId, info.AccountAge, info.Team),
    }
    if info.Health    then table.insert(lines, string.format("HP: %.0f / %.0f", info.Health, info.MaxHealth)) end
    if info.WalkSpeed then table.insert(lines, string.format("WalkSpeed: %d   JumpPower: %d", info.WalkSpeed, info.JumpPower)) end
    if info.Speed     then table.insert(lines, string.format("Speed: %.1f st/s", info.Speed)) end
    if info.State     then table.insert(lines, "State: "..info.State) end
    if info.Position  then table.insert(lines, "Pos: "..info.Position) end
    if info.Stamina   then table.insert(lines, string.format("Stamina: %.0f", info.Stamina)) end
    setLabelText(playerInfoLabel, table.concat(lines, "\n"))
end

localSec:CreateButton({Name="Refresh", Callback=refreshPlayerInfo})
localSec:CreateButton({Name="Reset Character", Description="Kill local character",
    Callback=function()
        Delirium.Dialog.Confirm({
            Title   = "Reset Character?",
            Message = "This will kill your character and trigger a respawn.",
            Type    = "Warning",
            Confirm = { Label = "Reset", Callback = function() PlayerModule:Reset() end },
            Cancel  = { Label = "Cancel" },
        })
    end})
localSec:CreateButton({Name="Rejoin", Description="Reconnect to this server",
    Callback=function() PlayerModule:Rejoin() end})
localSec:CreateButton({Name="Copy Username", Variant="Subtle",
    Callback=function() copyToClipboard(LP.Name); Delirium:Notify({Title="Copied",Message=LP.Name,Duration=2}) end})
localSec:CreateButton({Name="Copy User ID", Variant="Subtle",
    Callback=function() copyToClipboard(tostring(LP.UserId)); Delirium:Notify({Title="Copied",Message=tostring(LP.UserId),Duration=2}) end})
localSec:CreateSlider({Name="WalkSpeed Override", Min=0, Max=500, Default=16, Variant=UI_DENSITY,
    Callback=function(v) PlayerModule:SetWalkSpeed(v) end})
localSec:CreateSlider({Name="JumpPower Override", Min=0, Max=500, Default=50, Variant=UI_DENSITY,
    Callback=function(v) PlayerModule:SetJumpPower(v) end})

-- Auto-refresh player info
local _piTimer = 0
RunService.Heartbeat:Connect(function(dt)
    _piTimer += dt; if _piTimer < 3 then return end; _piTimer = 0
    pcall(refreshPlayerInfo)
end)
refreshPlayerInfo()

-- ─────────────────────────────────────────────────────────────
-- TAB: Character
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 3] Character...")
local charTab = Win:CreateTab({Name="Character"})

local moveSec = charTab:CreateSection("Movement")
moveSec:CreateToggle({Name="Auto-Sprint  (1.55x speed)", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule:SetAutoSprint(v) end})
moveSec:CreateToggle({Name="Auto-Jump  (continuous)", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule:SetAutoJump(v) end})
moveSec:CreateToggle({Name="Infinite Jump", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule:SetInfiniteJump(v) end})
moveSec:CreateToggle({Name="Noclip", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule:SetNoclip(v) end})
moveSec:CreateToggle({Name="Fly  [WASD + Space / Shift]", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule:SetFly(v) end})
moveSec:CreateSlider({Name="Fly Speed", Min=5, Max=500, Default=50, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule.FlySpeed = v end})
moveSec:CreateDivider()
moveSec:CreateToggle({Name="God Mode", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CharacterModule:SetGodMode(v) end})

local teleSec = charTab:CreateSection("Teleport")
teleSec:CreateToggle({Name="Click-to-TP Tool  (equip → click to TP)", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        if v then CharacterModule:GiveClickTPTool()
        else CharacterModule:RemoveClickTPTool() end
    end})
teleSec:CreateButton({Name="TP to Spawn", Description="Random spawn point if multiple exist",
    Callback=function()
        CharacterModule:TeleportToSpawn()
        Delirium:Notify({Title="Character",Message="Teleported to spawn",Duration=2})
    end})
teleSec:CreateButton({Name="Save Position", Description="Snapshot current CFrame",
    Callback=function()
        CharacterModule:SavePosition()
        local root = CharacterModule:_getRoot()
        local msg = root and string.format("Saved %.0f, %.0f, %.0f", root.Position.X, root.Position.Y, root.Position.Z) or "No character"
        Delirium:Notify({Title="Character",Message=msg,Duration=2})
    end})
teleSec:CreateButton({Name="Load Position", Description="Return to saved position",
    Callback=function()
        CharacterModule:LoadPosition()
        Delirium:Notify({Title="Character",Message=CharacterModule._savedPos and "Loaded" or "No saved position",Duration=2})
    end})
teleSec:CreateButton({Name="TP to Cursor  (one-shot)", Description="Instantly teleport to mouse position",
    Callback=function()
        local root = CharacterModule:_getRoot(); if not root then return end
        local mouse = LP:GetMouse()
        if mouse then
            pcall(function() root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0,3,0)) end)
            Delirium:Notify({Title="Character",Message="Teleported",Duration=1})
        end
    end})

local keybindSec = charTab:CreateSection("Keybinds")
keybindSec:CreateParagraph({Name="KbHint", Text="Desktop: press the bound key to activate. Mobile: tap the floating button and drag to reposition it."})
local kbFly = keybindSec:CreateKeybind({Name="Toggle Fly", Default=Enum.KeyCode.F, Variant=UI_DENSITY,
    Description="Press to toggle fly on/off"})
kbFly.OnActivated:Connect(function()
    local newState = not CharacterModule.Fly
    CharacterModule:SetFly(newState)
    Delirium:Notify({Title="Fly",Message=newState and "ON" or "OFF",Duration=1})
end)
local kbNoclip = keybindSec:CreateKeybind({Name="Toggle Noclip", Default=Enum.KeyCode.V, Variant=UI_DENSITY,
    Description="Press to toggle noclip on/off"})
kbNoclip.OnActivated:Connect(function()
    local newState = not CharacterModule.Noclip
    CharacterModule:SetNoclip(newState)
    Delirium:Notify({Title="Noclip",Message=newState and "ON" or "OFF",Duration=1})
end)
local kbGod = keybindSec:CreateKeybind({Name="Toggle God Mode", Default=Enum.KeyCode.G, Variant=UI_DENSITY,
    Description="Press to toggle god mode on/off"})
kbGod.OnActivated:Connect(function()
    local newState = not CharacterModule.GodMode
    CharacterModule:SetGodMode(newState)
    Delirium:Notify({Title="God Mode",Message=newState and "ON" or "OFF",Duration=1})
end)

-- ─────────────────────────────────────────────────────────────
-- TAB: Camera
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 4] Camera...")
local camTab = Win:CreateTab({Name="Camera"})

local camSec = camTab:CreateSection("Controls")
camSec:CreateSlider({Name="Field of View", Min=1, Max=120, Default=70, Variant=UI_DENSITY,
    Callback=function(v) CameraModule:SetFOV(v) end})
camSec:CreateDropdown({Name="Camera Mode", Options={"ThirdPerson","FirstPerson"}, Default="ThirdPerson", Variant=UI_DENSITY,
    Callback=function(v) CameraModule:SetCameraMode(v) end})
camSec:CreateToggle({Name="Camera Lock  (freeze view)", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CameraModule:SetCameraLock(v) end})
camSec:CreateToggle({Name="Disable Camera Shake", Default=false, Variant=UI_DENSITY,
    Callback=function(v) CameraModule:DisableShake(v) end})
camSec:CreateSlider({Name="View Distance", Min=64, Max=5000, Default=1000, Variant=UI_DENSITY,
    Callback=function(v) CameraModule:SetViewDistance(v) end})
local streamingNote = "Streaming: "..(workspace.StreamingEnabled and "enabled — view distance active" or "disabled — view distance may have no effect")
camSec:CreateLabel({Name="StreamNote", Text=streamingNote})
camSec:CreateButton({Name="Reset Camera", Description="Restore original FOV, mode, zoom",
    Callback=function()
        CameraModule:ResetCamera()
        Delirium:Notify({Title="Camera",Message="Reset to defaults",Duration=2})
    end})

-- ─────────────────────────────────────────────────────────────
-- TAB: Visual
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 5] Visual...")
local visualTab = Win:CreateTab({Name="Visual"})

local lightSec = visualTab:CreateSection("Lighting")
lightSec:CreateToggle({Name="Fullbright", Default=false, Variant=UI_DENSITY,
    Callback=function(v) VisualModule:SetFullbright(v) end})
lightSec:CreateToggle({Name="Global Shadows", Default=true, Variant=UI_DENSITY,
    Callback=function(v) VisualModule:SetGlobalShadows(v) end})
lightSec:CreateSlider({Name="Brightness", Min=0, Max=10, Default=1, Variant=UI_DENSITY,
    Callback=function(v) VisualModule:SetBrightness(v) end})
lightSec:CreateSlider({Name="Clock Time  (0–24h)", Min=0, Max=24, Default=14, Variant=UI_DENSITY,
    Callback=function(v) VisualModule:SetClockTime(v) end})

local fogSec = visualTab:CreateSection("Fog")
local _fogEnabled = false
fogSec:CreateToggle({Name="Enable Fog", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _fogEnabled = v
        VisualModule:SetFog(v)
    end})
fogSec:CreateSlider({Name="Fog Start", Min=0, Max=5000, Default=0, Variant=UI_DENSITY,
    Callback=function(v)
        VisualModule.FogStart = v
        if _fogEnabled then VisualModule:_applyFog() end
    end})
fogSec:CreateSlider({Name="Fog End", Min=50, Max=10000, Default=300, Variant=UI_DENSITY,
    Callback=function(v)
        VisualModule.FogEnd = v
        if _fogEnabled then VisualModule:_applyFog() end
    end})
fogSec:CreateColorPicker({Name="Fog Color", Default=Color3.fromRGB(200,200,210), Variant=UI_DENSITY,
    Description="Color of the fog — active when fog is enabled",
    Callback=function(c)
        VisualModule.FogColor = c
        if _fogEnabled then pcall(function() Lighting.FogColor = c end) end
    end})

local fxSec = visualTab:CreateSection("Post-Processing")
local _bloomEnabled = true
fxSec:CreateToggle({Name="Bloom", Default=true, Variant=UI_DENSITY,
    Callback=function(v)
        _bloomEnabled = v
        VisualModule:SetBloom(v)
    end})
fxSec:CreateSlider({Name="Bloom Intensity", Min=0, Max=5, Default=1, Variant=UI_DENSITY,
    Callback=function(v)
        if _bloomEnabled then VisualModule:SetBloom(true, v) end
    end})

local _sunEnabled = true
fxSec:CreateToggle({Name="Sun Rays", Default=true, Variant=UI_DENSITY,
    Callback=function(v)
        _sunEnabled = v
        VisualModule:SetSunRays(v)
    end})
fxSec:CreateSlider({Name="Sun Rays Intensity", Min=0, Max=1, Default=1, Variant=UI_DENSITY,
    Callback=function(v)
        if _sunEnabled then VisualModule:SetSunRays(true, v) end
    end})

local _blurEnabled = false
fxSec:CreateToggle({Name="Blur", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _blurEnabled = v
        VisualModule:SetBlur(v)
    end})
fxSec:CreateSlider({Name="Blur Size", Min=0, Max=56, Default=10, Variant=UI_DENSITY,
    Callback=function(v)
        if _blurEnabled then VisualModule:SetBlur(true, v) end
    end})

local _ccEnabled = false
fxSec:CreateToggle({Name="Color Correction", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _ccEnabled = v
        VisualModule:SetColorCorrection(v)
    end})
fxSec:CreateSlider({Name="CC Brightness", Min=-1, Max=1, Default=0, Variant=UI_DENSITY,
    Callback=function(v) if _ccEnabled then VisualModule:SetColorCorrection(true, v, nil, nil) end end})
fxSec:CreateSlider({Name="CC Contrast", Min=-1, Max=1, Default=0, Variant=UI_DENSITY,
    Callback=function(v) if _ccEnabled then VisualModule:SetColorCorrection(true, nil, v, nil) end end})
fxSec:CreateSlider({Name="CC Saturation", Min=-1, Max=1, Default=0, Variant=UI_DENSITY,
    Callback=function(v) if _ccEnabled then VisualModule:SetColorCorrection(true, nil, nil, v) end end})

fxSec:CreateButton({Name="Restore Visual Defaults", Description="Revert all Lighting changes",
    Callback=function()
        VisualModule:_restore(); VisualModule:_backup()
        Delirium:Notify({Title="Visual",Message="Defaults restored",Duration=2})
    end})

-- ─────────────────────────────────────────────────────────────
-- TAB: Performance
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 6] Performance...")
local perfTab = Win:CreateTab({Name="Performance"})

local statsSection = perfTab:CreateSection("Live Stats")
local fpsLabel  = statsSection:CreateLabel({Name="FPS",  Text="FPS: —"})
local pingLabel = statsSection:CreateLabel({Name="Ping", Text="Ping: —"})
local memLabel  = statsSection:CreateLabel({Name="Mem",  Text="Memory: —"})
local netLabel  = statsSection:CreateLabel({Name="Net",  Text="Network: —"})

PerfModule.OnUpdate = function(m)
    setLabelText(fpsLabel,  string.format("FPS: %d   avg %d   min %d   max %d",
        m.FPS, m.AvgFPS, m.MinFPS==math.huge and 0 or m.MinFPS, m.MaxFPS))
    setLabelText(pingLabel, string.format("Ping: %dms   avg %d   max %d",
        m.Ping, m.AvgPing, m.MaxPing))
    setLabelText(memLabel,  string.format("Memory: %.1f MB", m.MemoryMB))
    setLabelText(netLabel,  string.format("Net   ↓ %.1f KB/s   ↑ %.1f KB/s", m.NetRecv, m.NetSend))
end

statsSection:CreateButton({Name="Reset Stats", Description="Clear min/max/avg history",
    Callback=function()
        PerfModule.MinFPS=math.huge; PerfModule.MaxFPS=0; PerfModule.MaxPing=0
        PerfModule._fpsHistory={}; PerfModule._pingHistory={}
        Logger.Info("Performance","Stats reset")
        Delirium:Notify({Title="Performance",Message="Stats reset",Duration=2})
    end})

local fpscapSec = perfTab:CreateSection("FPS Cap")
local _fpscapEnabled = false
fpscapSec:CreateToggle({Name="Enable FPS Cap", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _fpscapEnabled = v
        PerfModule:SetFPSCap(v, PerfModule.FPSCapValue)
        Delirium:Notify({Title="FPS Cap",Message=v and ("Cap: "..tostring(PerfModule.FPSCapValue).."fps") or "Removed — default restored",Duration=2})
    end})
fpscapSec:CreateSlider({Name="FPS Limit", Min=20, Max=240, Default=60, Variant=UI_DENSITY,
    Callback=function(v)
        PerfModule.FPSCapValue = v
        if _fpscapEnabled then PerfModule:SetFPSCap(true, v) end
    end})

local optimSec = perfTab:CreateSection("Optimization")
-- Guard: only apply profile when toggle is ON
local _optimEnabled     = false
local _optimProfile     = "BALANCED"
local _optimInitialized = false
task.defer(function() _optimInitialized = true end)

optimSec:CreateDropdown({Name="Profile", Options={"LOW","BALANCED","PERFORMANCE"}, Default="BALANCED", Variant=UI_DENSITY,
    Callback=function(v)
        _optimProfile = v
        OptimModule.CurrentProfile = v
        if _optimEnabled and _optimInitialized then
            OptimModule:ApplyProfile(v)
            Delirium:Notify({Title="Optimizer",Message="Profile: "..v,Duration=2})
        end
    end})
optimSec:CreateToggle({Name="Enable Optimization", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _optimEnabled = v
        if v then
            OptimModule.CurrentProfile = _optimProfile
            Registry.Enable("Performance Optimizer")
        else
            Registry.Disable("Performance Optimizer")
        end
    end})
optimSec:CreateButton({Name="Restore Original Graphics", Description="Undo all optimization changes",
    Callback=function()
        OptimModule:Disable(); OptimModule._applied = false
        Delirium:Notify({Title="Optimizer",Message="Restored",Duration=2})
    end})

-- ─────────────────────────────────────────────────────────────
-- TAB: Server
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 7] Server...")
local serverTab = Win:CreateTab({Name="Server"})

local srvInfoSec = serverTab:CreateSection("Server Information")
local srvL = {}
srvL.game    = srvInfoSec:CreateLabel({Name="GameName",  Text="Game:    loading..."})
srvL.jobid   = srvInfoSec:CreateLabel({Name="JobId",     Text="Job ID:  "..game.JobId:sub(1,32)})
srvL.placeid = srvInfoSec:CreateLabel({Name="PlaceId",   Text="Place:   "..tostring(game.PlaceId)})
srvL.players = srvInfoSec:CreateLabel({Name="Players",   Text="Players: —"})
srvL.region  = srvInfoSec:CreateLabel({Name="Region",    Text="Region:  detecting..."})
srvL.ping    = srvInfoSec:CreateLabel({Name="Ping",      Text="Ping:    —"})

local function refreshServerInfo()
    local info = ServerModule:GetInfo()
    setLabelText(srvL.game,    "Game:    "..(info.GameName ~= "" and info.GameName or "—"))
    setLabelText(srvL.jobid,   "Job ID:  "..info.JobId:sub(1,32))
    setLabelText(srvL.placeid, "Place:   "..info.PlaceId)
    setLabelText(srvL.players, string.format("Players: %d / %d", info.PlayerCount, info.MaxPlayers))
    setLabelText(srvL.region,  "Region:  "..info.Region)
    setLabelText(srvL.ping,    string.format("Ping:    %dms  (avg %d)", info.Ping, info.AvgPing))
end

srvInfoSec:CreateButton({Name="Refresh", Callback=refreshServerInfo})
srvInfoSec:CreateButton({Name="Copy Job ID", Variant="Subtle",
    Callback=function() ServerModule:CopyJobId(); Delirium:Notify({Title="Copied",Message="Job ID",Duration=2}) end})
srvInfoSec:CreateButton({Name="Copy Place ID", Variant="Subtle",
    Callback=function() ServerModule:CopyPlaceId(); Delirium:Notify({Title="Copied",Message="Place ID",Duration=2}) end})
srvInfoSec:CreateButton({Name="Copy Region", Variant="Subtle",
    Callback=function()
        local r = ServerModule:GetRegion()
        copyToClipboard(r)
        Delirium:Notify({Title="Copied",Message=r,Duration=2})
    end})
srvInfoSec:CreateButton({Name="Rejoin", Callback=function() ServerModule:Rejoin() end})
srvInfoSec:CreateButton({Name="Hop Server", Description="Jump to a different server",
    Callback=function()
        Delirium:Notify({Title="Server",Message="Hopping...",Duration=2})
        ServerModule:HopServer()
    end})

-- Auto-refresh with retry until we have real ping data
local _srvTimer     = 0
local _srvAttempts  = 0
local function trySrvRefresh()
    _srvAttempts += 1
    pcall(refreshServerInfo)
    -- keep retrying every 2s until ping is non-zero (max 15 attempts)
    if PerfModule.Ping == 0 and _srvAttempts < 15 then
        task.delay(2, trySrvRefresh)
    end
end
task.delay(2, trySrvRefresh)

RunService.Heartbeat:Connect(function(dt)
    _srvTimer += dt; if _srvTimer < 15 then return end; _srvTimer = 0
    pcall(refreshServerInfo)
end)

-- ─────────────────────────────────────────────────────────────
-- TAB: Explorer  (remade)
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 8] Explorer...")
local explorerTab = Win:CreateTab({Name="Explorer"})

-- State
local _exResults   = {}
local _exPage      = 1
local _exPageSize  = 8
local _exQuery     = ""
local _exClassFilter = ""

local _exResultLabel = nil
local _exPageLabel   = nil
local _exInfoLabel   = nil

local function exTotalPages() return math.max(1, math.ceil(#_exResults / _exPageSize)) end

local function exRender()
    if not _exResultLabel then return end
    local total = #_exResults
    local tp    = exTotalPages()
    _exPage = math.clamp(_exPage, 1, tp)

    local s = (_exPage-1)*_exPageSize + 1
    local e = math.min(_exPage*_exPageSize, total)
    local lines = {}
    if total == 0 then
        table.insert(lines, "(no results — run a search)")
    else
        for i = s, e do
            local r = _exResults[i]
            if r then
                table.insert(lines, string.format("[%d] %s : %s  [%d ch]",
                    i, r.ClassName:sub(1,20), r.Name:sub(1,28), r.Children))
            end
        end
    end
    setLabelText(_exResultLabel, table.concat(lines, "\n"))
    setLabelText(_exPageLabel,   string.format("Page %d / %d   (%d results)", _exPage, tp, total))
end

local _exSelectValue = ""

-- Search section
local exSearchSec = explorerTab:CreateSection("Search")

local exRootDrop = exSearchSec:CreateDropdown({
    Name="Search Root",
    Options={"game","workspace","Players","Lighting","ReplicatedStorage","StarterGui","CoreGui"},
    Default="game",
    Variant=UI_DENSITY,
    Callback=function(v)
        local roots = {
            game=game, workspace=workspace, Players=Players, Lighting=Lighting,
        }
        local ok, svc = pcall(function() return game:GetService(v) end)
        ExplorerModule._searchRoot = (ok and svc) or roots[v] or game
    end,
})

local exSearchBox = exSearchSec:CreateTextbox({
    Name="Name Filter", Default="", Placeholder="Part, Player, Model...", Variant=UI_DENSITY,
    Callback=function(v) _exQuery = v or "" end,
})
local exClassBox = exSearchSec:CreateTextbox({
    Name="Class Filter", Default="", Placeholder="BasePart, Script, etc. (optional)", Variant=UI_DENSITY,
    Callback=function(v) _exClassFilter = v or "" end,
})

exSearchSec:CreateButton({Name="Search", Description="Find matching instances",
    Callback=function()
        local q = _exQuery ~= "" and _exQuery or getTextboxValue(exSearchBox)
        local cf = _exClassFilter ~= "" and _exClassFilter or getTextboxValue(exClassBox)
        if q == "" and cf == "" then
            Delirium:Notify({Title="Explorer",Message="Enter a name or class filter",Duration=2}); return
        end
        _exResults = ExplorerModule:Search(q, nil, 250, cf)
        _exPage = 1
        exRender()
        Delirium:Notify({Title="Explorer",Message="Found: "..(#_exResults).." results",Duration=2})
        Logger.Info("Explorer","Search '"..q.."': "..(#_exResults).." results")
    end})
exSearchSec:CreateButton({Name="Clear Results", Variant="Subtle",
    Callback=function()
        _exResults = {}; _exPage = 1; exRender()
        if _exInfoLabel then setLabelText(_exInfoLabel,"—") end
    end})

-- Results section
local exResultsSec = explorerTab:CreateSection("Results")
_exResultLabel = exResultsSec:CreateLabel({Name="Results",  Text="(run a search above)"})
_exPageLabel   = exResultsSec:CreateLabel({Name="PageInfo", Text=""})

exResultsSec:CreateButton({Name="◀ Prev", Variant="Subtle",
    Callback=function() _exPage = math.max(1, _exPage-1); exRender() end})
exResultsSec:CreateButton({Name="Next ▶", Variant="Subtle",
    Callback=function() _exPage = math.min(exTotalPages(), _exPage+1); exRender() end})

local exSelectBox = exResultsSec:CreateTextbox({
    Name="Select #", Default="", Placeholder="Result number...", Variant=UI_DENSITY,
    Callback=function(v) _exSelectValue = v or "" end,
})

local function getSelectedResult()
    local raw = _exSelectValue ~= "" and _exSelectValue or getTextboxValue(exSelectBox)
    local idx = tonumber(raw)
    if not idx then Delirium:Notify({Title="Explorer",Message="Enter a number",Duration=2}); return nil end
    local r = _exResults[idx]
    if not r then Delirium:Notify({Title="Explorer",Message="Invalid index",Duration=2}); return nil end
    return r
end

exResultsSec:CreateButton({Name="Show Info", Description="Display selected instance properties",
    Callback=function()
        local r = getSelectedResult(); if not r or not r.Instance then return end
        local info = ExplorerModule:GetInstanceInfo(r.Instance)
        local lines = {
            "Name:      "..tostring(info.Name),
            "Class:     "..tostring(info.ClassName),
            "Parent:    "..tostring(info.Parent),
            "Children:  "..tostring(info.Children),
            "Attrs:     "..tostring(info.Attributes),
            "Path:      "..tostring(info.FullPath):sub(1,70),
        }
        if info.Tags and info.Tags ~= "" then table.insert(lines,"Tags: "..info.Tags) end
        if info.Position then table.insert(lines,"Pos: "..info.Position) end
        if info.Size     then table.insert(lines,"Size: "..info.Size) end
        if _exInfoLabel then setLabelText(_exInfoLabel, table.concat(lines, "\n")) end
    end})
exResultsSec:CreateButton({Name="Copy Path", Variant="Subtle",
    Callback=function()
        local r = getSelectedResult(); if not r then return end
        copyToClipboard(r.Path)
        Delirium:Notify({Title="Copied",Message=r.Path:sub(1,60),Duration=3})
    end})
exResultsSec:CreateButton({Name="Copy Name", Variant="Subtle",
    Callback=function()
        local r = getSelectedResult(); if not r then return end
        copyToClipboard(r.Name)
        Delirium:Notify({Title="Copied",Message=r.Name,Duration=2})
    end})
exResultsSec:CreateButton({Name="Browse Children", Description="List children of selected instance",
    Callback=function()
        local r = getSelectedResult(); if not r or not r.Instance then return end
        local children = ExplorerModule:GetChildren(r.Instance)
        _exResults = children; _exPage = 1
        exRender()
        Delirium:Notify({Title="Explorer",Message=r.Name.." → "..(#children).." children",Duration=2})
    end})
exResultsSec:CreateButton({Name="Set as Search Root", Description="Search inside this instance",
    Callback=function()
        local r = getSelectedResult(); if not r or not r.Instance then return end
        ExplorerModule._searchRoot = r.Instance
        Delirium:Notify({Title="Explorer",Message="Root: "..r.Name,Duration=2})
    end})

local exInfoSec = explorerTab:CreateSection("Instance Info")
_exInfoLabel = exInfoSec:CreateLabel({Name="Info", Text="Select a result and press Show Info"})

-- ─────────────────────────────────────────────────────────────
-- TAB: HUD
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 9] HUD...")
local hudTab = Win:CreateTab({Name="HUD"})

local hudEnSec = hudTab:CreateSection("Enable")
hudEnSec:CreateToggle({Name="Enable HUD", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        if v then Registry.Enable("HUD") else Registry.Disable("HUD") end
    end})

local hudOverlaySec = hudTab:CreateSection("Display")
hudOverlaySec:CreateToggle({Name="FPS",            Default=HUDModule.Config.ShowFPS,      Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowFPS=v end})
hudOverlaySec:CreateToggle({Name="Ping",           Default=HUDModule.Config.ShowPing,     Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowPing=v end})
hudOverlaySec:CreateToggle({Name="Coordinates",    Default=HUDModule.Config.ShowCoords,   Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowCoords=v end})
hudOverlaySec:CreateToggle({Name="Memory",         Default=HUDModule.Config.ShowMemory,   Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowMemory=v end})
hudOverlaySec:CreateToggle({Name="Session Timer",  Default=HUDModule.Config.ShowTimer,    Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowTimer=v end})
hudOverlaySec:CreateToggle({Name="Players",        Default=HUDModule.Config.ShowPlayers,  Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowPlayers=v end})
hudOverlaySec:CreateToggle({Name="Speed",          Default=HUDModule.Config.ShowVelocity, Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowVelocity=v end})
hudOverlaySec:CreateToggle({Name="State",          Default=HUDModule.Config.ShowState,    Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowState=v end})
hudOverlaySec:CreateToggle({Name="Health",         Default=HUDModule.Config.ShowHealth,   Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowHealth=v end})
hudOverlaySec:CreateToggle({Name="Stamina",        Default=HUDModule.Config.ShowStamina,  Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowStamina=v end})
hudOverlaySec:CreateToggle({Name="Death Counter",  Default=HUDModule.Config.ShowDeaths,   Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowDeaths=v end})
hudOverlaySec:CreateToggle({Name="Network",        Default=HUDModule.Config.ShowNet,      Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowNet=v end})
hudOverlaySec:CreateToggle({Name="FPS Graph",      Default=HUDModule.Config.ShowGraph,    Variant=UI_DENSITY, Callback=function(v) HUDModule.Config.ShowGraph=v end})

local hudStyleSec = hudTab:CreateSection("Style")
hudStyleSec:CreateSlider({Name="Text Size", Min=9, Max=18, Default=12, Variant=UI_DENSITY,
    Callback=function(v) HUDModule:SetTextSize(v) end})
hudStyleSec:CreateSlider({Name="Background Transparency", Min=0, Max=100, Default=35, Variant=UI_DENSITY,
    Callback=function(v) HUDModule:SetBgTransparency(v/100) end})
hudStyleSec:CreateDropdown({Name="Position", Options={"TopRight","TopLeft","BottomRight","BottomLeft"}, Default="TopRight", Variant=UI_DENSITY,
    Callback=function(v) HUDModule:SetPosition(v) end})
hudStyleSec:CreateButton({Name="Reset Position", Description="Snap back to top-right corner",
    Callback=function() HUDModule:SetPosition("TopRight") end})

-- ─────────────────────────────────────────────────────────────
-- TAB: Utility
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 10] Utility...")
local utilTab = Win:CreateTab({Name="Utility"})

local utilCopySec = utilTab:CreateSection("Copy")
utilCopySec:CreateButton({Name="Copy Username",
    Callback=function() copyToClipboard(LP.Name); Delirium:Notify({Title="Copied",Message=LP.Name,Duration=2}) end})
utilCopySec:CreateButton({Name="Copy Display Name",
    Callback=function() UtilityModule:CopyDisplayName() end})
utilCopySec:CreateButton({Name="Copy User ID", Variant="Subtle",
    Callback=function() copyToClipboard(tostring(LP.UserId)); Delirium:Notify({Title="Copied",Message=tostring(LP.UserId),Duration=2}) end})
utilCopySec:CreateButton({Name="Copy Character Name", Variant="Subtle",
    Callback=function() UtilityModule:CopyCharacterName() end})
utilCopySec:CreateButton({Name="Copy Job ID", Variant="Subtle",
    Callback=function() ServerModule:CopyJobId(); Delirium:Notify({Title="Copied",Message="Job ID",Duration=2}) end})

local utilRegionSec = utilTab:CreateSection("Region")
local utilRegLabel = utilRegionSec:CreateLabel({Name="RegionDisplay", Text="Region: detecting..."})
local function updateUtilRegion()
    local r = ServerModule:GetRegion()
    setLabelText(utilRegLabel, "Region: "..r)
    return r ~= "Detecting..."
end
utilRegionSec:CreateButton({Name="Refresh Region",
    Callback=function()
        updateUtilRegion()
        local r = ServerModule:GetRegion()
        Delirium:Notify({Title="Region",Message=r,Duration=2})
    end})
utilRegionSec:CreateButton({Name="Copy Region", Variant="Subtle",
    Callback=function()
        local r = ServerModule:GetRegion()
        copyToClipboard(r)
        Delirium:Notify({Title="Copied",Message=r,Duration=2})
    end})

-- Auto-update region label until we have real data
local _utilRegConn
local _utilRegTimer = 0
_utilRegConn = RunService.Heartbeat:Connect(function(dt)
    _utilRegTimer += dt; if _utilRegTimer < 3 then return end; _utilRegTimer = 0
    pcall(function()
        if updateUtilRegion() then _utilRegConn:Disconnect() end
    end)
end)

local utilMiscSec = utilTab:CreateSection("Misc")
utilMiscSec:CreateToggle({Name="Screenshot Mode  (hide HUD)", Default=false, Variant=UI_DENSITY,
    Callback=function(v) UtilityModule:SetScreenshotMode(v) end})

local utilLoaderSec = utilTab:CreateSection("Script Loaders")
utilLoaderSec:CreateParagraph({Name="LoaderNote", Text="Scripts are fetched from third-party sources and executed in your exploiter context. Only load what you trust."})
utilLoaderSec:CreateButton({Name="Load Dex++", Description="Dex Explorer Plus Plus",
    Callback=function()
        UtilityModule:LoadScript("Dex++", "https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua")
    end})
utilLoaderSec:CreateButton({Name="Load Infinite Yield", Description="IY admin commands by Edge",
    Callback=function()
        UtilityModule:LoadScript("Infinite Yield", "https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source")
    end})
utilLoaderSec:CreateButton({Name="Load Cobalt", Description="Cobalt remote spy",
    Callback=function()
        UtilityModule:LoadScript("Cobalt", "https://gitlab.com/upio/cobalt/-/releases/permalink/latest/downloads/Cobalt.luau")
    end})

-- ─────────────────────────────────────────────────────────────
-- TAB: Diagnostics
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 11] Diagnostics...")
local diagTab = Win:CreateTab({Name="Diagnostics"})

local consoleSec = diagTab:CreateSection("Internal Console")
consoleSec:CreateParagraph({Name="ConsoleNote", Text="Internal log stream for all modules. Use the filter to search by keyword or category. Max 10 lines shown — copy all to get the full history."})
local _logDisplay = consoleSec:CreateLabel({Name="Logs", Text="[Console ready]"})
local _logFilter  = ""
local MAX_LOG_LINES = 10  -- cap to prevent window overflow

local function refreshLogs()
    local entries = Logger.GetAll(_logFilter)
    local lines   = {}
    local start   = math.max(1, #entries - MAX_LOG_LINES + 1)
    for i = start, #entries do
        local e = entries[i]
        local line = string.format("[%s][%s] %s",
            e.time, e.level:sub(1,1),
            e.message:sub(1, 52))  -- truncate each line
        table.insert(lines, line)
    end
    setLabelText(_logDisplay, #lines > 0 and table.concat(lines, "\n") or "[empty]")
end

Logger.OnLog = function() pcall(refreshLogs) end

local _logFilterValue = ""
consoleSec:CreateTextbox({Name="Filter", Default="", Placeholder="Filter keyword...", Variant=UI_DENSITY,
    Callback=function(v) _logFilterValue = v or ""; _logFilter = _logFilterValue; refreshLogs() end})
consoleSec:CreateButton({Name="Refresh",     Callback=refreshLogs})
consoleSec:CreateButton({Name="Clear", Variant="Subtle",
    Callback=function() Logger.Clear(); setLabelText(_logDisplay,"[Cleared]") end})
consoleSec:CreateButton({Name="Copy All Logs", Variant="Subtle",
    Callback=function()
        local entries = Logger.GetAll()
        local lines = {}
        for _, e in ipairs(entries) do table.insert(lines, Logger.Format(e)) end
        copyToClipboard(table.concat(lines, "\n"))
        Delirium:Notify({Title="Diagnostics",Message=tostring(#lines).." entries copied",Duration=2})
    end})

local compatSec = diagTab:CreateSection("Compatibility")
local COMPAT_FEATURES = {
    "VirtualUser","TeleportService","writefile","readfile","Stats",
    "setfpscap","setclipboard","loadstring","StreamingEnabled",
    "getgenv","gethiddenproperty","hookfunction","getrawmetatable",
}
for _, f in ipairs(COMPAT_FEATURES) do
    local r = Compat.Check(f)
    local ok = r.Status == "SUPPORTED"
    compatSec:CreateLabel({
        Name=f,
        Text=(ok and "✓ " or "✗ ")..f..": "..r.Status..(r.Reason and "  —  "..r.Reason or ""),
    })
end

local modStatSec = diagTab:CreateSection("Module Status")
for name, mod in pairs(Registry._modules) do
    modStatSec:CreateLabel({Name=name, Text=name..": "..mod.Status})
end

-- ─────────────────────────────────────────────────────────────
-- TAB: Automation
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 12] Automation...")
local autoTab = Win:CreateTab({Name="Automation"})

local afkSec = autoTab:CreateSection("Anti-AFK")
local vuStatus = Compat.Check("VirtualUser").Status
afkSec:CreateLabel({Name="VuStatus", Text="VirtualUser: "..(vuStatus=="SUPPORTED" and "✓ available" or "✗ unavailable — timer fallback active")})
local _afkToggleState = false
afkSec:CreateToggle({Name="Anti-AFK", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _afkToggleState = v
        AutoModule:SetAntiAFK(v)
        Registry.Enable("Automation")
        Delirium:Notify({Title="Anti-AFK",Message=v and "Enabled — Idled event + timer backup" or "Disabled",Duration=2})
    end})
local _afkKbState = false
local kbAfk = afkSec:CreateKeybind({Name="Toggle Anti-AFK", Default=Enum.KeyCode.Unknown, Variant=UI_DENSITY,
    Description="Keybind to toggle Anti-AFK without opening the menu"})
kbAfk.OnActivated:Connect(function()
    _afkKbState = not _afkKbState
    AutoModule:SetAntiAFK(_afkKbState)
    Delirium:Notify({Title="Anti-AFK",Message=_afkKbState and "Enabled" or "Disabled",Duration=2})
end)

local pingWarnSec = autoTab:CreateSection("Ping Monitor")
local _pingWarnEnabled = false
local _pingThreshold   = 250
pingWarnSec:CreateToggle({Name="High Ping Warning  (logs to console)", Default=false, Variant=UI_DENSITY,
    Callback=function(v)
        _pingWarnEnabled = v
    end})
pingWarnSec:CreateSlider({Name="Threshold  (ms)", Min=50, Max=1000, Default=250, Variant=UI_DENSITY,
    Callback=function(v)
        _pingThreshold = v
        ConfigModule:Set("Automation","PingThreshold",v)
    end})

local _pingWarnTimer = 0
RunService.Heartbeat:Connect(function(dt)
    if not _pingWarnEnabled then return end
    _pingWarnTimer += dt; if _pingWarnTimer < 5 then return end; _pingWarnTimer = 0
    if PerfModule.Ping > _pingThreshold and PerfModule.Ping > 0 then
        Logger.Warn("Automation", string.format("High ping: %dms (threshold: %dms)", PerfModule.Ping, _pingThreshold))
    end
end)

-- ─────────────────────────────────────────────────────────────
-- TAB: Settings
-- ─────────────────────────────────────────────────────────────
print("[Delirium DEBUG] [Tab 13] Settings...")
local settingsTab = Win:CreateTab({Name="Settings"})

local themeSec = settingsTab:CreateSection("Theme")
themeSec:CreateDropdown({Name="Theme", Options={"Dark","Light"}, Default="Dark", Variant=UI_DENSITY,
    Callback=function(v)
        Delirium:SetTheme(v)
        Logger.Info("Settings","Theme: "..v)
    end})

local densitySec = settingsTab:CreateSection("UI Density")
local densityOpts = {"Compact","Default","Large"}
densitySec:CreateDropdown({
    Name="Component Density",
    Description="Applied on next execution",
    Options=densityOpts,
    Default=UI_DENSITY,
    Variant=UI_DENSITY,
    Callback=function(v)
        ConfigModule:Set("UI","Density",v)
        Logger.Info("Settings","Density saved: "..v)
        Delirium:Notify({Title="UI Density",Message=v.." — restart to apply",Duration=3})
    end,
})
densitySec:CreateLabel({Name="ActiveDensity", Text="Active now: "..UI_DENSITY})

local accessSec = settingsTab:CreateSection("Accessibility")
accessSec:CreateParagraph({Name="AccessNote", Text="Reduced Motion disables all UI animations and transitions. Takes effect immediately — no restart required."})
accessSec:CreateToggle({Name="Reduced Motion", Default=false, Variant=UI_DENSITY,
    Description="Disable animations for motion sensitivity",
    Callback=function(v) Delirium:SetReducedMotion(v) end})

local configSec = settingsTab:CreateSection("Configuration")
configSec:CreateButton({Name="Export Config", Description="Copy config JSON to clipboard",
    Callback=function()
        ConfigModule:Export()
        Delirium:Notify({Title="Config",Message="Exported to clipboard",Duration=3})
    end})
local _importValue = ""
configSec:CreateTextbox({Name="Import Config", Default="", Placeholder="Paste JSON config here...", Variant=UI_DENSITY,
    Callback=function(v) _importValue = v or "" end})
configSec:CreateButton({Name="Apply Import",
    Callback=function()
        local json = _importValue ~= "" and _importValue or ""
        if #json < 2 then Delirium:Notify({Title="Config",Message="Paste JSON first",Duration=2}); return end
        local ok = ConfigModule:Import(json)
        Delirium:Notify({Title="Config",Message=ok and "Imported" or "Failed — invalid JSON",Duration=3})
    end})
configSec:CreateButton({Name="Reset to Defaults", Description="Restore all defaults",
    Callback=function()
        Delirium.Dialog.Confirm({
            Title   = "Reset to Defaults?",
            Message = "All saved configuration will be wiped and restored to factory defaults.",
            Type    = "Warning",
            Confirm = { Label = "Reset", Callback = function()
                ConfigModule:Reset()
                Delirium:Notify({Title="Config",Message="Reset to defaults",Duration=2})
            end },
            Cancel  = { Label = "Cancel" },
        })
    end})

local modSec = settingsTab:CreateSection("Module Management")
modSec:CreateButton({Name="Disable All Modules", Description="Disable all active modules",
    Callback=function()
        Delirium.Dialog.Confirm({
            Title   = "Disable All Modules?",
            Message = "This will stop all active modules including HUD, Fly, and God Mode.",
            Type    = "Warning",
            Confirm = { Label = "Disable All", Callback = function()
                for name, mod in pairs(Registry._modules) do
                    if mod.Status == "ON" then Registry.Disable(name) end
                end
                Delirium:Notify({Title="Universal",Message="All modules disabled",Duration=3})
            end },
            Cancel  = { Label = "Cancel" },
        })
    end})

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP
-- ═══════════════════════════════════════════════════════════════
Win:OnUnload(function()
    Registry.DestroyAll()
    Logger.Clear()
end)

print("[Delirium DEBUG] [25/25] Universal v2.4.0 ready!")
Logger.Info("Universal","v2.4.0 — keybinds, colorpicker, dialogs, full v0.3.x features")
Delirium:Notify({
    Title   = "Universal",
    Message = "v2.4.0 — keybinds, colorpicker, dialogs, full v0.3.x features",
    Duration = 5,
})
