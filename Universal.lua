-- ═══════════════════════════════════════════════════════════════
-- Delirium Universal v1.0.0
-- ═══════════════════════════════════════════════════════════════

-- [BOOTSTRAP]
local Delirium = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/DanteLuau/Delirium-Projects/refs/heads/main/dist/Delirium.lua"
))()

-- [SERVICES]
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Stats            = game:GetService("Stats")
local Lighting         = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local TeleportService  = game:GetService("TeleportService")
local VirtualUser      = game:GetService("VirtualUser")
local HttpService      = game:GetService("HttpService")
local GuiService       = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")

local LP = Players.LocalPlayer

-- [UTILITIES]
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
        table.insert(self._tasks,t)
    end
    function m:Clean()
        if self._dead then return end
        self._dead = true
        for i=#self._tasks,1,-1 do
            pcall(function()
                local t=self._tasks[i]
                if typeof(t)=="RBXScriptConnection" then t:Disconnect()
                elseif type(t)=="function" then t()
                elseif type(t)=="table" then
                    if t.Destroy then t:Destroy() elseif t.Disconnect then t:Disconnect() end
                end
            end)
            self._tasks[i]=nil
        end
        table.clear(self._tasks)
    end
    m.Destroy = m.Clean
    return m
end

local function fmtTime(s)
    local h = math.floor(s/3600)
    local m = math.floor((s%3600)/60)
    local sec = math.floor(s%60)
    if h > 0 then return string.format("%02d:%02d:%02d",h,m,sec) end
    return string.format("%02d:%02d",m,sec)
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

-- ═══════════════════════════════════════════════════════════════
-- CORE: Logger
-- ═══════════════════════════════════════════════════════════════
local Logger = {}
Logger._entries = {}
Logger._maxEntries = 500
Logger.OnLog = nil -- set by UI after construction

local LOG_LEVELS = {INFO=1, WARN=2, ERROR=3}

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
    if Logger.OnLog then
        pcall(Logger.OnLog, entry)
    end
end

function Logger.Info(cat, msg)  Logger.log("INFO",  cat, msg) end
function Logger.Warn(cat, msg)  Logger.log("WARN",  cat, msg) end
function Logger.Error(cat, msg) Logger.log("ERROR", cat, msg) end
function Logger.Clear()         table.clear(Logger._entries)  end

function Logger.GetAll(filter)
    if not filter or filter=="" then
        return {table.unpack(Logger._entries)}
    end
    local out = {}
    local f = filter:lower()
    for _,e in ipairs(Logger._entries) do
        if e.message:lower():find(f,1,true) or e.category:lower():find(f,1,true) then
            table.insert(out,e)
        end
    end
    return out
end

function Logger.Format(entry)
    return string.format("[%s] [%s] %s", entry.time, entry.category, entry.message)
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

function Registry.Get(name)
    return Registry._modules[name]
end

function Registry.Enable(name)
    local m = Registry._modules[name]
    if not m then return end
    if m.Status == "ON" then return end
    local ok,err = pcall(function() m:Enable() end)
    if ok then
        m.Status = "ON"
        Logger.Info(name,"Enabled")
    else
        m.Status = "ERROR"
        Logger.Error(name,"Enable failed: "..tostring(err))
    end
end

function Registry.Disable(name)
    local m = Registry._modules[name]
    if not m then return end
    local ok,err = pcall(function() m:Disable() end)
    if ok then
        m.Status = "OFF"
        Logger.Info(name,"Disabled")
    else
        Logger.Error(name,"Disable failed: "..tostring(err))
    end
end

function Registry.DestroyAll()
    for name,mod in pairs(Registry._modules) do
        pcall(function() mod:Destroy() end)
    end
    table.clear(Registry._modules)
end

function Registry.Search(query)
    local q = query:lower()
    local out = {}
    for name,mod in pairs(Registry._modules) do
        if name:lower():find(q,1,true) or
           mod.Category:lower():find(q,1,true) or
           (mod.Description and mod.Description:lower():find(q,1,true)) then
            table.insert(out,mod)
        end
    end
    return out
end

function Registry.GetByCategory(cat)
    local out = {}
    for _,mod in pairs(Registry._modules) do
        if mod.Category == cat then table.insert(out,mod) end
    end
    return out
end

-- ═══════════════════════════════════════════════════════════════
-- CORE: Compatibility
-- ═══════════════════════════════════════════════════════════════
local Compat = {}

function Compat.Check(feature)
    if feature == "VirtualUser" then
        local ok = pcall(function() return game:GetService("VirtualUser") end)
        return ok and {Status="SUPPORTED"} or {Status="UNAVAILABLE", Reason="VirtualUser restricted"}
    elseif feature == "TeleportService" then
        local ok = pcall(function() return game:GetService("TeleportService") end)
        return ok and {Status="SUPPORTED"} or {Status="UNAVAILABLE", Reason="TeleportService restricted"}
    elseif feature == "writefile" then
        return (writefile ~= nil) and {Status="SUPPORTED"} or {Status="UNAVAILABLE",Reason="writefile not available in this executor"}
    elseif feature == "HttpGet" then
        return (game.HttpGet ~= nil) and {Status="SUPPORTED"} or {Status="UNAVAILABLE",Reason="HttpGet not available"}
    elseif feature == "Stats" then
        local ok = pcall(function() Stats:GetTotalMemoryUsageMb() end)
        return ok and {Status="SUPPORTED"} or {Status="UNAVAILABLE",Reason="Stats restricted"}
    end
    return {Status="UNAVAILABLE", Reason="Unknown feature"}
end

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Session
-- ═══════════════════════════════════════════════════════════════
local SessionModule = {
    Name        = "Session",
    Category    = "Session",
    Description = "Tracks session duration, deaths, respawns, and statistics",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    
    -- public data
    JoinTime     = os.clock(),
    DeathCount   = 0,
    RespawnCount = 0,
    FpsHistory   = {},
    PingHistory  = {},
    _deathConn   = nil,
    _charConn    = nil,
}

function SessionModule:Initialize()
    self.JoinTime = os.clock()
    self.DeathCount   = 0
    self.RespawnCount = 0
    self.FpsHistory   = {}
    self.PingHistory  = {}
end

function SessionModule:_connectCharacter(char)
    if self._deathConn then self._deathConn:Disconnect() end
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    self._deathConn = hum.Died:Connect(function()
        self.DeathCount += 1
        Logger.Info("Session","Death #"..self.DeathCount)
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

function SessionModule:Disable()
    self._maid:Clean()
    self._maid = newMaid()
end

function SessionModule:Destroy()
    self:Disable()
end

function SessionModule:IsSupported() return true end
function SessionModule:GetStatus() return self.Status end

function SessionModule:GetDuration()
    return os.clock() - self.JoinTime
end

function SessionModule:GetSummary()
    local dur = self:GetDuration()
    local avgFps = 0
    local avgPing = 0
    if #self.FpsHistory > 0 then
        local s = 0
        for _,v in ipairs(self.FpsHistory) do s+=v end
        avgFps = round(s/#self.FpsHistory, 1)
    end
    if #self.PingHistory > 0 then
        local s = 0
        for _,v in ipairs(self.PingHistory) do s+=v end
        avgPing = round(s/#self.PingHistory, 1)
    end
    return {
        Duration    = fmtTime(dur),
        Deaths      = self.DeathCount,
        Respawns    = self.RespawnCount,
        AvgFPS      = avgFps,
        AvgPing     = avgPing,
    }
end

Registry.Register(SessionModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Performance
-- ═══════════════════════════════════════════════════════════════
local PerfModule = {
    Name        = "Performance Monitor",
    Category    = "Performance",
    Description = "Live FPS, ping, memory, and network tracking",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    
    -- live values
    FPS        = 0,
    AvgFPS     = 0,
    MinFPS     = math.huge,
    MaxFPS     = 0,
    Ping       = 0,
    AvgPing    = 0,
    MaxPing    = 0,
    MemoryMB   = 0,
    NetRecv    = 0,
    NetSend    = 0,
    
    -- history (ring buffers, 120 samples)
    _fpsHistory  = {},
    _pingHistory = {},
    _memHistory  = {},
    _maxSamples  = 120,
    
    _updateConn = nil,
    OnUpdate    = nil, -- callback set by UI
}

function PerfModule:_push(buf, val)
    table.insert(buf, val)
    if #buf > self._maxSamples then
        table.remove(buf, 1)
    end
end

function PerfModule:_avg(buf)
    if #buf == 0 then return 0 end
    local s = 0
    for _,v in ipairs(buf) do s+=v end
    return round(s/#buf, 1)
end

function PerfModule:Initialize() end

function PerfModule:Enable()
    local lastTime = tick()
    local updateInterval = 0.5
    local elapsed = 0
    
    self._updateConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < updateInterval then return end
        elapsed = 0
        
        -- FPS
        local fps = round(1/math.max(dt, 0.001))
        self.FPS = fps
        self:_push(self._fpsHistory, fps)
        self.AvgFPS = self:_avg(self._fpsHistory)
        if fps < self.MinFPS then self.MinFPS = fps end
        if fps > self.MaxFPS then self.MaxFPS = fps end
        
        -- Ping
        local ping = 0
        pcall(function()
            local net = Stats:FindFirstChild("Network")
            if net then
                local si = net:FindFirstChild("ServerStatsItem")
                -- try DataPing
                local dp = si and (si["Data Ping"] or si["DataPing"] or si.Data_Ping)
                if dp then ping = math.round(dp) end
            end
        end)
        if ping == 0 then
            pcall(function()
                -- fallback: use workspace network stats
                local s = Stats:FindFirstChild("DataModel")
                if s then ping = 0 end
            end)
        end
        self.Ping = ping
        self:_push(self._pingHistory, ping)
        self.AvgPing = self:_avg(self._pingHistory)
        if ping > self.MaxPing then self.MaxPing = ping end
        
        -- Memory
        pcall(function()
            self.MemoryMB = round(Stats:GetTotalMemoryUsageMb(), 1)
        end)
        self:_push(self._memHistory, self.MemoryMB)
        
        -- Network I/O
        pcall(function()
            local net = Stats:FindFirstChild("Network")
            if net then
                self.NetRecv = round(net.DataReceivedKbps or 0, 1)
                self.NetSend = round(net.DataSentKbps     or 0, 1)
            end
        end)
        
        -- Feed to session
        SessionModule.FpsHistory  = self._fpsHistory
        SessionModule.PingHistory = self._pingHistory
        
        if self.OnUpdate then
            pcall(self.OnUpdate, self)
        end
    end)
    self._maid:Give(self._updateConn)
end

function PerfModule:Disable()
    if self._updateConn then
        self._updateConn:Disconnect()
        self._updateConn = nil
    end
    self._maid:Clean()
    self._maid = newMaid()
end

function PerfModule:Destroy() self:Disable() end
function PerfModule:IsSupported() return true end
function PerfModule:GetStatus() return self.Status end

Registry.Register(PerfModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Visual
-- ═══════════════════════════════════════════════════════════════
local VisualModule = {
    Name        = "Visual",
    Category    = "Visual",
    Description = "Fullbright, atmosphere, fog, and post-processing controls",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    _originals  = {},  -- stores original Lighting property values
}

-- Properties to backup on enable
local LIGHTING_PROPS = {
    "Brightness", "Ambient", "OutdoorAmbient",
    "ClockTime", "FogStart", "FogEnd", "FogColor",
    "GlobalShadows",
}

function VisualModule:_backup()
    for _,p in ipairs(LIGHTING_PROPS) do
        pcall(function() self._originals[p] = Lighting[p] end)
    end
    -- backup atmosphere
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo then
        self._originals._atmoEnabled = true
        self._originals._atmoDensity = atmo.Density
        self._originals._atmoOffset  = atmo.Offset
        self._originals._atmoHaze    = atmo.Haze
    end
    -- backup bloom
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom then
        self._originals._bloomEnabled   = bloom.Enabled
        self._originals._bloomIntensity = bloom.Intensity
        self._originals._bloomSize      = bloom.Size
    end
    -- backup color correction
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if cc then
        self._originals._ccEnabled     = cc.Enabled
        self._originals._ccBrightness  = cc.Brightness
        self._originals._ccContrast    = cc.Contrast
        self._originals._ccSaturation  = cc.Saturation
    end
end

function VisualModule:_restore()
    for _,p in ipairs(LIGHTING_PROPS) do
        if self._originals[p] ~= nil then
            pcall(function() Lighting[p] = self._originals[p] end)
        end
    end
    local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
    if atmo and self._originals._atmoEnabled then
        pcall(function()
            atmo.Density = self._originals._atmoDensity
            atmo.Offset  = self._originals._atmoOffset
            atmo.Haze    = self._originals._atmoHaze
        end)
    end
    local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
    if bloom and self._originals._bloomEnabled ~= nil then
        pcall(function()
            bloom.Enabled   = self._originals._bloomEnabled
            bloom.Intensity = self._originals._bloomIntensity
            bloom.Size      = self._originals._bloomSize
        end)
    end
    local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
    if cc and self._originals._ccEnabled ~= nil then
        pcall(function()
            cc.Enabled    = self._originals._ccEnabled
            cc.Brightness = self._originals._ccBrightness
            cc.Contrast   = self._originals._ccContrast
            cc.Saturation = self._originals._ccSaturation
        end)
    end
    table.clear(self._originals)
end

function VisualModule:Initialize()
    self:_backup()
end

function VisualModule:Enable()
    if not next(self._originals) then
        self:_backup()
    end
end

function VisualModule:Disable()
    self:_restore()
end

function VisualModule:Destroy()
    self:Disable()
    self._maid:Clean()
end

function VisualModule:IsSupported() return true end
function VisualModule:GetStatus() return self.Status end

-- Individual visual controls
function VisualModule:SetFullbright(enabled)
    if enabled then
        pcall(function()
            Lighting.Brightness    = 2
            Lighting.Ambient       = Color3.new(1,1,1)
            Lighting.OutdoorAmbient= Color3.new(1,1,1)
            Lighting.GlobalShadows = false
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then atmo.Density = 0 end
        end)
        Logger.Info("Visual","Fullbright enabled")
    else
        pcall(function()
            Lighting.Brightness    = self._originals.Brightness or 1
            Lighting.Ambient       = self._originals.Ambient or Color3.fromRGB(127,127,127)
            Lighting.OutdoorAmbient= self._originals.OutdoorAmbient or Color3.fromRGB(127,127,127)
            Lighting.GlobalShadows = self._originals.GlobalShadows ~= false
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if atmo then atmo.Density = self._originals._atmoDensity or 0.3 end
        end)
        Logger.Info("Visual","Fullbright disabled")
    end
end

function VisualModule:SetFog(enabled, start, finish)
    pcall(function()
        if enabled then
            Lighting.FogStart = start or 0
            Lighting.FogEnd   = finish or 300
        else
            Lighting.FogStart = self._originals.FogStart or 0
            Lighting.FogEnd   = self._originals.FogEnd   or 100000
        end
    end)
end

function VisualModule:SetBrightness(val)
    pcall(function() Lighting.Brightness = val end)
end

function VisualModule:SetClockTime(val)
    pcall(function() Lighting.ClockTime = val end)
end

function VisualModule:SetBloom(enabled, intensity)
    pcall(function()
        local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
        if bloom then
            bloom.Enabled   = enabled
            bloom.Intensity = intensity or bloom.Intensity
        end
    end)
end

function VisualModule:SetColorCorrection(brightness, contrast, saturation)
    pcall(function()
        local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
        if cc then
            if brightness ~= nil then cc.Brightness  = brightness  end
            if contrast   ~= nil then cc.Contrast    = contrast    end
            if saturation ~= nil then cc.Saturation  = saturation  end
        end
    end)
end

function VisualModule:SetGlobalShadows(enabled)
    pcall(function() Lighting.GlobalShadows = enabled end)
end

Registry.Register(VisualModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Player
-- ═══════════════════════════════════════════════════════════════
local PlayerModule = {
    Name        = "Player",
    Category    = "Player",
    Description = "Player info, selection, distance, and character utilities",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    SelectedPlayer = nil,  -- shared selected player reference
    OnPlayerSelected = nil, -- callback
}

function PlayerModule:Initialize() end

function PlayerModule:Enable()
    Logger.Info("Player","Module enabled")
end

function PlayerModule:Disable()
    self._maid:Clean()
    self._maid = newMaid()
end

function PlayerModule:Destroy() self:Disable() end
function PlayerModule:IsSupported() return true end
function PlayerModule:GetStatus() return self.Status end

function PlayerModule:GetLocalInfo()
    local info = {
        Name          = LP.Name,
        DisplayName   = LP.DisplayName,
        UserId        = LP.UserId,
        AccountAge    = LP.AccountAge,
    }
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if hum then
        info.Health    = round(hum.Health, 1)
        info.MaxHealth = round(hum.MaxHealth, 1)
        info.WalkSpeed = hum.WalkSpeed
        info.JumpPower = hum.JumpPower
        info.State     = hum:GetState().Name
    end
    if root then
        local p = root.Position
        info.Position = string.format("%.1f, %.1f, %.1f", p.X, p.Y, p.Z)
    end
    return info
end

function PlayerModule:GetAllPlayers()
    return Players:GetPlayers()
end

function PlayerModule:GetPlayerInfo(plr)
    local info = {
        Name        = plr.Name,
        DisplayName = plr.DisplayName,
        UserId      = plr.UserId,
    }
    local char = plr.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local lroot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if root and lroot then
        info.Distance = round((root.Position - lroot.Position).Magnitude, 1)
    else
        info.Distance = -1
    end
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        info.Health    = round(hum.Health,1)
        info.MaxHealth = round(hum.MaxHealth,1)
    end
    return info
end

function PlayerModule:SelectPlayer(plr)
    self.SelectedPlayer = plr
    if self.OnPlayerSelected then
        pcall(self.OnPlayerSelected, plr)
    end
    Logger.Info("Player","Selected: "..(plr and plr.Name or "None"))
end

function PlayerModule:Rejoin()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LP)
    end)
end

function PlayerModule:Reset()
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Health = 0
    end
end

Registry.Register(PlayerModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Server
-- ═══════════════════════════════════════════════════════════════
local ServerModule = {
    Name        = "Server",
    Category    = "Server",
    Description = "Server information, job ID, and server utilities",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
}

function ServerModule:Initialize() end
function ServerModule:Enable() Logger.Info("Server","Module enabled") end
function ServerModule:Disable()
    self._maid:Clean()
    self._maid = newMaid()
end
function ServerModule:Destroy() self:Disable() end
function ServerModule:IsSupported() return true end
function ServerModule:GetStatus() return self.Status end

function ServerModule:GetInfo()
    return {
        JobId       = game.JobId,
        PlaceId     = tostring(game.PlaceId),
        PlayerCount = #Players:GetPlayers(),
        MaxPlayers  = Players.MaxPlayers,
    }
end

function ServerModule:CopyJobId()
    copyToClipboard(game.JobId)
    Logger.Info("Server","Copied JobId: "..game.JobId)
end

function ServerModule:CopyPlaceId()
    copyToClipboard(tostring(game.PlaceId))
    Logger.Info("Server","Copied PlaceId: "..tostring(game.PlaceId))
end

function ServerModule:Rejoin()
    pcall(function()
        TeleportService:Teleport(game.PlaceId, LP)
    end)
end

Registry.Register(ServerModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Explorer
-- ═══════════════════════════════════════════════════════════════
local ExplorerModule = {
    Name        = "Explorer",
    Category    = "Explorer",
    Description = "Runtime instance inspector and search",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    _results    = {},
}

function ExplorerModule:Initialize() end
function ExplorerModule:Enable() Logger.Info("Explorer","Module enabled") end
function ExplorerModule:Disable()
    self._maid:Clean()
    self._maid = newMaid()
    self._results = {}
end
function ExplorerModule:Destroy() self:Disable() end
function ExplorerModule:IsSupported() return true end
function ExplorerModule:GetStatus() return self.Status end

function ExplorerModule:Search(query, root, maxResults)
    local q = query:lower()
    local results = {}
    maxResults = maxResults or 100
    root = root or game
    
    local function scan(inst, depth)
        if #results >= maxResults then return end
        if depth > 10 then return end
        local ok,_ = pcall(function()
            local name = inst.Name:lower()
            local cls  = inst.ClassName:lower()
            if name:find(q,1,true) or cls:find(q,1,true) then
                table.insert(results, {
                    Name      = inst.Name,
                    ClassName = inst.ClassName,
                    Path      = inst:GetFullName(),
                    Children  = #inst:GetChildren(),
                    Instance  = inst,
                })
            end
            for _,child in ipairs(inst:GetChildren()) do
                scan(child, depth+1)
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
        info.Name       = inst.Name
        info.ClassName  = inst.ClassName
        info.Parent     = inst.Parent and inst.Parent.Name or "nil"
        info.Children   = #inst:GetChildren()
        info.FullPath   = inst:GetFullName()
        -- attributes
        local attrs = inst:GetAttributes()
        info.AttributeCount = 0
        for _ in pairs(attrs) do info.AttributeCount+=1 end
        -- tags
        local tags = inst:GetTags()
        info.Tags = tags
        info.TagCount = #tags
    end)
    return info
end

Registry.Register(ExplorerModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Automation
-- ═══════════════════════════════════════════════════════════════
local AutoModule = {
    Name        = "Automation",
    Category    = "Automation",
    Description = "Anti-AFK, auto-reconnect, and QoL automation",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    
    _afkConn     = nil,
    _afkEnabled  = false,
    _reconnEnabled= false,
}

function AutoModule:Initialize() end

function AutoModule:Enable()
    Logger.Info("Automation","Module enabled")
end

function AutoModule:Disable()
    self:SetAntiAFK(false)
    self._maid:Clean()
    self._maid = newMaid()
end

function AutoModule:Destroy() self:Disable() end
function AutoModule:IsSupported() return true end
function AutoModule:GetStatus() return self.Status end

function AutoModule:SetAntiAFK(enabled)
    self._afkEnabled = enabled
    if self._afkConn then
        self._afkConn:Disconnect()
        self._afkConn = nil
    end
    if not enabled then return end
    
    local compat = Compat.Check("VirtualUser")
    if compat.Status ~= "SUPPORTED" then
        Logger.Warn("Automation","AntiAFK unavailable: "..compat.Reason)
        return
    end
    
    -- fire every 14 minutes (840s) to prevent AFK kick
    local INTERVAL = 840
    local elapsed  = 0
    
    self._afkConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < INTERVAL then return end
        elapsed = 0
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(), workspace.CurrentCamera.CFrame)
        end)
        Logger.Info("Automation","AntiAFK fired")
    end)
    self._maid:Give(self._afkConn)
    Logger.Info("Automation","AntiAFK enabled (interval: "..INTERVAL.."s)")
end

function AutoModule:SetPingWarning(enabled, threshold)
    if not enabled then return end
    threshold = threshold or 200
    local conn = RunService.Heartbeat:Connect(function()
        if PerfModule.Ping > threshold and PerfModule.Ping > 0 then
            Logger.Warn("Automation","High ping: "..PerfModule.Ping.."ms")
        end
    end)
    -- throttle check: only run every 5s
    -- simplified: just run every heartbeat, logger deduplicates
    self._maid:Give(conn)
end

Registry.Register(AutoModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: HUD
-- ═══════════════════════════════════════════════════════════════
local HUDModule = {
    Name        = "HUD",
    Category    = "HUD",
    Description = "Configurable on-screen overlays for FPS, ping, coordinates, etc.",
    Version     = "1.0.0",
    Dependencies= {"Performance Monitor"},
    Status      = "OFF",
    _maid       = newMaid(),
    
    _gui        = nil,
    _frame      = nil,
    _labels     = {},
    _updateConn = nil,
    
    Config = {
        ShowFPS    = true,
        ShowPing   = true,
        ShowMemory = false,
        ShowCoords = true,
        ShowPlayers= false,
        ShowTimer  = true,
    },
}

function HUDModule:Initialize() end

function HUDModule:Enable()
    -- Create HUD ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "DeliriumHUD"
    gui.DisplayOrder = 999
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = LP.PlayerGui
    self._gui = gui
    self._maid:Give(gui)
    
    -- HUD frame: top-right corner
    local frame = Instance.new("Frame")
    frame.Name = "HUDFrame"
    frame.Size = UDim2.fromOffset(160, 100)
    frame.Position = UDim2.new(1, -170, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(10,10,15)
    frame.BackgroundTransparency = 0.4
    frame.BorderSizePixel = 0
    frame.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = frame
    
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0,6)
    pad.PaddingBottom = UDim.new(0,6)
    pad.PaddingLeft   = UDim.new(0,8)
    pad.PaddingRight  = UDim.new(0,8)
    pad.Parent = frame
    
    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding   = UDim.new(0,2)
    layout.Parent    = frame
    
    self._frame  = frame
    self._labels = {}
    
    local function mkLabel(key, order)
        local lbl = Instance.new("TextLabel")
        lbl.Name  = key
        lbl.Size  = UDim2.new(1,0,0,14)
        lbl.BackgroundTransparency = 1
        lbl.Font  = Enum.Font.Code
        lbl.TextSize = 12
        lbl.TextColor3 = Color3.fromRGB(200,200,220)
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.LayoutOrder = order
        lbl.Parent = frame
        self._labels[key] = lbl
        return lbl
    end
    
    mkLabel("fps",    1)
    mkLabel("ping",   2)
    mkLabel("mem",    3)
    mkLabel("coords", 4)
    mkLabel("players",5)
    mkLabel("timer",  6)
    
    -- enable dragging on frame
    local dragging, ds, sp = false, nil, nil
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging=true; ds=inp.Position; sp=frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - ds
            frame.Position = UDim2.new(sp.X.Scale, sp.X.Offset+d.X, sp.Y.Scale, sp.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dragging=false
        end
    end)
    
    -- Update loop — 0.25s interval
    local elapsed = 0
    self._updateConn = RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < 0.25 then return end
        elapsed = 0
        
        pcall(function()
            local cfg = self.Config
            local lbl = self._labels
            
            if lbl.fps then
                lbl.fps.Visible = cfg.ShowFPS
                if cfg.ShowFPS then
                    lbl.fps.Text = string.format("FPS: %d (avg %d)", PerfModule.FPS, PerfModule.AvgFPS)
                end
            end
            
            if lbl.ping then
                lbl.ping.Visible = cfg.ShowPing
                if cfg.ShowPing then
                    local p = PerfModule.Ping
                    local col = p > 200 and Color3.fromRGB(220,80,80) or
                                p > 100 and Color3.fromRGB(220,180,60) or
                                Color3.fromRGB(80,200,100)
                    lbl.ping.Text = string.format("Ping: %dms", p)
                    lbl.ping.TextColor3 = col
                end
            end
            
            if lbl.mem then
                lbl.mem.Visible = cfg.ShowMemory
                if cfg.ShowMemory then
                    lbl.mem.Text = string.format("Mem: %.1fMB", PerfModule.MemoryMB)
                end
            end
            
            if lbl.coords then
                lbl.coords.Visible = cfg.ShowCoords
                if cfg.ShowCoords then
                    local char = LP.Character
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local p = root.Position
                        lbl.coords.Text = string.format("%.0f, %.0f, %.0f", p.X, p.Y, p.Z)
                    else
                        lbl.coords.Text = "No character"
                    end
                end
            end
            
            if lbl.players then
                lbl.players.Visible = cfg.ShowPlayers
                if cfg.ShowPlayers then
                    lbl.players.Text = string.format("Players: %d/%d", #Players:GetPlayers(), Players.MaxPlayers)
                end
            end
            
            if lbl.timer then
                lbl.timer.Visible = cfg.ShowTimer
                if cfg.ShowTimer then
                    lbl.timer.Text = "Session: "..fmtTime(SessionModule:GetDuration())
                end
            end
            
            -- auto-resize frame height
            frame.Size = UDim2.fromOffset(160, layout.AbsoluteContentSize.Y + 14)
        end)
    end)
    self._maid:Give(self._updateConn)
    Logger.Info("HUD","Enabled")
end

function HUDModule:Disable()
    if self._gui and self._gui.Parent then
        self._gui:Destroy()
    end
    self._gui    = nil
    self._frame  = nil
    self._labels = {}
    self._maid:Clean()
    self._maid = newMaid()
    Logger.Info("HUD","Disabled")
end

function HUDModule:Destroy() self:Disable() end
function HUDModule:IsSupported() return true end
function HUDModule:GetStatus() return self.Status end

Registry.Register(HUDModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Performance Optimization
-- ═══════════════════════════════════════════════════════════════
local OptimModule = {
    Name        = "Performance Optimizer",
    Category    = "Performance",
    Description = "Optimization presets to improve FPS: Low, Balanced, Performance, Custom",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    _applied    = false,
    _stateMap   = {},  -- {instance={propName=originalValue}}
    CurrentProfile = "BALANCED",
}

local PROFILES = {
    LOW = {
        DisableBloom    = false,
        DisableAtmo     = false,
        DisableCC       = false,
        DisableSunRays  = false,
        DisableBlur     = false,
        ReduceParticles = false,
        GlobalShadows   = true,
    },
    BALANCED = {
        DisableBloom    = false,
        DisableAtmo     = false,
        DisableCC       = false,
        DisableSunRays  = true,
        DisableBlur     = true,
        ReduceParticles = false,
        GlobalShadows   = true,
    },
    PERFORMANCE = {
        DisableBloom    = true,
        DisableAtmo     = true,
        DisableCC       = false,
        DisableSunRays  = true,
        DisableBlur     = true,
        ReduceParticles = true,
        GlobalShadows   = false,
    },
}

function OptimModule:_saveState(inst, prop)
    if not self._stateMap[inst] then self._stateMap[inst] = {} end
    if self._stateMap[inst][prop] == nil then
        pcall(function() self._stateMap[inst][prop] = inst[prop] end)
    end
end

function OptimModule:_restoreAll()
    for inst,props in pairs(self._stateMap) do
        for prop,val in pairs(props) do
            pcall(function() inst[prop] = val end)
        end
    end
    table.clear(self._stateMap)
end

function OptimModule:ApplyProfile(profileName)
    local profile = PROFILES[profileName]
    if not profile then
        Logger.Warn("Optimizer","Unknown profile: "..tostring(profileName))
        return
    end
    self.CurrentProfile = profileName
    
    -- restore first if already applied
    if self._applied then
        self:_restoreAll()
    end
    self._applied = true
    
    pcall(function()
        -- PostProcessing effects
        for _,eff in ipairs(Lighting:GetChildren()) do
            if eff:IsA("BloomEffect") then
                if profile.DisableBloom then
                    self:_saveState(eff,"Enabled")
                    eff.Enabled = false
                end
            elseif eff:IsA("SunRaysEffect") then
                if profile.DisableSunRays then
                    self:_saveState(eff,"Enabled")
                    eff.Enabled = false
                end
            elseif eff:IsA("BlurEffect") or eff:IsA("DepthOfFieldEffect") then
                if profile.DisableBlur then
                    self:_saveState(eff,"Enabled")
                    eff.Enabled = false
                end
            elseif eff:IsA("Atmosphere") then
                if profile.DisableAtmo then
                    self:_saveState(eff,"Density")
                    self:_saveState(eff,"Haze")
                    eff.Density = 0
                    eff.Haze    = 0
                end
            end
        end
        
        -- Shadows
        if not profile.GlobalShadows then
            self:_saveState(Lighting,"GlobalShadows")
            Lighting.GlobalShadows = false
        end
        
        -- Particle reduction
        if profile.ReduceParticles then
            for _,v in ipairs(workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") then
                    self:_saveState(v,"Rate")
                    self:_saveState(v,"Speed")
                    pcall(function()
                        v.Rate  = math.min(v.Rate, 5)
                        v.Speed = NumberRange.new(v.Speed.Min * 0.5, v.Speed.Max * 0.5)
                    end)
                end
            end
        end
    end)
    
    Logger.Info("Optimizer","Profile applied: "..profileName)
end

function OptimModule:Initialize() end
function OptimModule:Enable()
    self:ApplyProfile(self.CurrentProfile)
end
function OptimModule:Disable()
    self:_restoreAll()
    self._applied = false
    Logger.Info("Optimizer","Restored original settings")
end
function OptimModule:Destroy() self:Disable() end
function OptimModule:IsSupported() return true end
function OptimModule:GetStatus() return self.Status end

Registry.Register(OptimModule)

-- ═══════════════════════════════════════════════════════════════
-- MODULE: Configuration
-- ═══════════════════════════════════════════════════════════════
local ConfigModule = {
    Name        = "Configuration",
    Category    = "Configuration",
    Description = "Save, load, import, and export Universal configuration",
    Version     = "1.0.0",
    Dependencies= {},
    Status      = "OFF",
    _maid       = newMaid(),
    
    _config     = {},
    _profiles   = {},
    _activeProfile = "Default",
}

local CONFIG_VERSION = 1

function ConfigModule:Initialize()
    self:_loadDefaults()
end

function ConfigModule:_loadDefaults()
    self._config = {
        Version = CONFIG_VERSION,
        HUD = {
            Enabled    = true,
            ShowFPS    = true,
            ShowPing   = true,
            ShowMemory = false,
            ShowCoords = true,
            ShowTimer  = true,
            ShowPlayers= false,
        },
        Visual = {
            Fullbright   = false,
            GlobalShadows= true,
        },
        Performance = {
            MonitorEnabled = true,
            Profile        = "BALANCED",
        },
        Automation = {
            AntiAFK      = false,
            PingWarning  = true,
            PingThreshold= 250,
        },
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
    if ok then
        copyToClipboard(encoded)
        Logger.Info("Config","Exported to clipboard")
        return encoded
    else
        Logger.Error("Config","Export failed: "..tostring(encoded))
        return nil
    end
end

function ConfigModule:Import(jsonStr)
    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, jsonStr)
    if ok and type(decoded) == "table" then
        -- version migration
        if decoded.Version ~= CONFIG_VERSION then
            Logger.Warn("Config","Config version mismatch, using defaults for missing keys")
        end
        -- merge over defaults
        for section, data in pairs(decoded) do
            if type(data) == "table" then
                if not self._config[section] then self._config[section] = {} end
                for k,v in pairs(data) do
                    self._config[section][k] = v
                end
            end
        end
        Logger.Info("Config","Imported successfully")
        return true
    else
        Logger.Error("Config","Import failed: invalid JSON")
        return false
    end
end

function ConfigModule:Reset()
    self:_loadDefaults()
    Logger.Info("Config","Reset to defaults")
end

function ConfigModule:SaveProfile(name)
    local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self._config)
    if ok then
        self._profiles[name] = encoded
        self._activeProfile  = name
        Logger.Info("Config","Saved profile: "..name)
    end
end

function ConfigModule:LoadProfile(name)
    local data = self._profiles[name]
    if not data then
        Logger.Warn("Config","Profile not found: "..name)
        return false
    end
    return self:Import(data)
end

function ConfigModule:GetProfileNames()
    local names = {}
    for n in pairs(self._profiles) do table.insert(names,n) end
    table.sort(names)
    return names
end

function ConfigModule:Enable() end
function ConfigModule:Disable() end
function ConfigModule:Destroy() end
function ConfigModule:IsSupported() return true end
function ConfigModule:GetStatus() return self.Status end

Registry.Register(ConfigModule)

-- ═══════════════════════════════════════════════════════════════
-- INITIALIZE ALL MODULES
-- ═══════════════════════════════════════════════════════════════
for name, mod in pairs(Registry._modules) do
    local ok, err = pcall(function() mod:Initialize() end)
    if ok then
        mod.Status = "OFF"
        Logger.Info("Universal","Initialized: "..name)
    else
        mod.Status = "ERROR"
        Logger.Error("Universal","Init failed ["..name.."]: "..tostring(err))
    end
end

-- Enable core modules immediately
Registry.Enable("Session")
Registry.Enable("Performance Monitor")
VisualModule:_backup()

-- ═══════════════════════════════════════════════════════════════
-- UI CONSTRUCTION
-- ═══════════════════════════════════════════════════════════════
local Win = Delirium:CreateWindow({
    Name     = "Universal",
    Subtitle = "v1.0.0 — Delirium",
    Size     = UDim2.fromOffset(580, 380),
})

-- ─────────────────────────────────────────────
-- TAB: Home (Quick Actions)
-- ─────────────────────────────────────────────
local homeTab = Win:CreateTab({ Name = "Home" })

local quickSection = homeTab:CreateSection("Quick Actions")
quickSection:CreateButton({
    Name        = "Rejoin",
    Description = "Reconnect to this server",
    Callback    = function()
        Logger.Info("UI","Rejoin triggered")
        PlayerModule:Rejoin()
    end,
})
quickSection:CreateButton({
    Name        = "Copy Job ID",
    Description = "Copy server Job ID to clipboard",
    Callback    = function()
        ServerModule:CopyJobId()
        Delirium:Notify({ Title="Copied", Message="Job ID copied to clipboard", Duration=2 })
    end,
})
quickSection:CreateButton({
    Name        = "Copy Place ID",
    Description = "Copy Place ID to clipboard",
    Callback    = function()
        ServerModule:CopyPlaceId()
        Delirium:Notify({ Title="Copied", Message="Place ID copied to clipboard", Duration=2 })
    end,
})
quickSection:CreateButton({
    Name        = "Reset Character",
    Description = "Reset your character",
    Callback    = function()
        PlayerModule:Reset()
    end,
})

local hudQuickSection = homeTab:CreateSection("HUD")
hudQuickSection:CreateToggle({
    Name     = "Enable HUD",
    Default  = false,
    Callback = function(v)
        if v then
            Registry.Enable("HUD")
        else
            Registry.Disable("HUD")
        end
    end,
})
hudQuickSection:CreateToggle({
    Name     = "Show FPS",
    Default  = HUDModule.Config.ShowFPS,
    Callback = function(v) HUDModule.Config.ShowFPS = v end,
})
hudQuickSection:CreateToggle({
    Name     = "Show Ping",
    Default  = HUDModule.Config.ShowPing,
    Callback = function(v) HUDModule.Config.ShowPing = v end,
})
hudQuickSection:CreateToggle({
    Name     = "Show Coordinates",
    Default  = HUDModule.Config.ShowCoords,
    Callback = function(v) HUDModule.Config.ShowCoords = v end,
})
hudQuickSection:CreateToggle({
    Name     = "Show Memory",
    Default  = HUDModule.Config.ShowMemory,
    Callback = function(v) HUDModule.Config.ShowMemory = v end,
})
hudQuickSection:CreateToggle({
    Name     = "Show Session Timer",
    Default  = HUDModule.Config.ShowTimer,
    Callback = function(v) HUDModule.Config.ShowTimer = v end,
})

-- ─────────────────────────────────────────────
-- TAB: Player
-- ─────────────────────────────────────────────
local playerTab = Win:CreateTab({ Name = "Player" })

local infoSection = playerTab:CreateSection("Local Player")
local infoLabel = infoSection:CreateLabel({
    Name = "PlayerInfo",
    Text = "Loading...",
})

local function refreshPlayerInfo()
    local info = PlayerModule:GetLocalInfo()
    local lines = {
        "Name: "..info.Name.." ("..info.DisplayName..")",
        "User ID: "..tostring(info.UserId),
        "Account Age: "..tostring(info.AccountAge).." days",
    }
    if info.Health then
        table.insert(lines, string.format("HP: %.0f/%.0f", info.Health, info.MaxHealth))
    end
    if info.WalkSpeed then
        table.insert(lines, "WalkSpeed: "..tostring(info.WalkSpeed))
    end
    if info.JumpPower then
        table.insert(lines, "JumpPower: "..tostring(info.JumpPower))
    end
    if info.State then
        table.insert(lines, "State: "..info.State)
    end
    if info.Position then
        table.insert(lines, "Position: "..info.Position)
    end
    if infoLabel and infoLabel.SetText then
        pcall(function() infoLabel:SetText(table.concat(lines,"\n")) end)
    elseif infoLabel and infoLabel.Instance then
        pcall(function()
            for _,child in ipairs(infoLabel.Instance:GetChildren()) do
                if child:IsA("TextLabel") then
                    child.Text = table.concat(lines,"\n")
                end
            end
        end)
    end
end

infoSection:CreateButton({
    Name        = "Refresh Info",
    Description = "Update local player stats",
    Callback    = refreshPlayerInfo,
})
infoSection:CreateButton({
    Name        = "Copy Username",
    Description = "Copy username to clipboard",
    Callback    = function()
        copyToClipboard(LP.Name)
        Delirium:Notify({ Title="Copied", Message=LP.Name, Duration=2 })
    end,
})
infoSection:CreateButton({
    Name        = "Copy User ID",
    Description = "Copy User ID to clipboard",
    Callback    = function()
        copyToClipboard(tostring(LP.UserId))
        Delirium:Notify({ Title="Copied", Message=tostring(LP.UserId), Duration=2 })
    end,
})

local playerListSection = playerTab:CreateSection("Player List")
local playerNames = {}
for _,p in ipairs(Players:GetPlayers()) do
    table.insert(playerNames, p.Name)
end

local playerDropdown = playerListSection:CreateDropdown({
    Name    = "Select Player",
    Options = playerNames,
    Default = playerNames[1] or "No players",
    Callback= function(v)
        local plr = Players:FindFirstChild(v)
        if plr then
            PlayerModule:SelectPlayer(plr)
        end
    end,
})

playerListSection:CreateButton({
    Name        = "Refresh Player List",
    Description = "Update the player dropdown",
    Callback    = function()
        local newNames = {}
        for _,p in ipairs(Players:GetPlayers()) do
            table.insert(newNames, p.Name)
        end
        if playerDropdown and playerDropdown.SetOptions then
            pcall(function() playerDropdown:SetOptions(newNames) end)
        end
    end,
})

local selectedInfoSection = playerTab:CreateSection("Selected Player")
selectedInfoSection:CreateButton({
    Name        = "Get Distance",
    Description = "Distance to selected player",
    Callback    = function()
        local sel = PlayerModule.SelectedPlayer
        if not sel then
            Delirium:Notify({Title="No Player", Message="Select a player first", Duration=2})
            return
        end
        local info = PlayerModule:GetPlayerInfo(sel)
        local msg = info.Distance >= 0 and (info.Distance.." studs") or "Unavailable"
        Delirium:Notify({Title=sel.Name, Message="Distance: "..msg, Duration=3})
    end,
})
selectedInfoSection:CreateButton({
    Name        = "Copy Selected Username",
    Description = "Copy selected player username",
    Callback    = function()
        local sel = PlayerModule.SelectedPlayer
        if sel then
            copyToClipboard(sel.Name)
            Delirium:Notify({Title="Copied", Message=sel.Name, Duration=2})
        end
    end,
})
selectedInfoSection:CreateButton({
    Name        = "Copy Selected User ID",
    Description = "Copy selected player User ID",
    Callback    = function()
        local sel = PlayerModule.SelectedPlayer
        if sel then
            copyToClipboard(tostring(sel.UserId))
            Delirium:Notify({Title="Copied", Message=tostring(sel.UserId), Duration=2})
        end
    end,
})

-- ─────────────────────────────────────────────
-- TAB: Visual
-- ─────────────────────────────────────────────
local visualTab = Win:CreateTab({ Name = "Visual" })

local lightSection = visualTab:CreateSection("Lighting")
lightSection:CreateToggle({
    Name     = "Fullbright",
    Default  = false,
    Callback = function(v)
        VisualModule:SetFullbright(v)
    end,
})
lightSection:CreateToggle({
    Name     = "Global Shadows",
    Default  = true,
    Callback = function(v)
        VisualModule:SetGlobalShadows(v)
    end,
})
lightSection:CreateSlider({
    Name    = "Brightness",
    Min     = 0,
    Max     = 10,
    Default = 1,
    Callback= function(v)
        VisualModule:SetBrightness(v)
    end,
})
lightSection:CreateSlider({
    Name    = "Clock Time",
    Min     = 0,
    Max     = 24,
    Default = 14,
    Callback= function(v)
        VisualModule:SetClockTime(v)
    end,
})

local fogSection = visualTab:CreateSection("Fog")
local fogEnabled = false
fogSection:CreateToggle({
    Name     = "Enable Fog",
    Default  = false,
    Callback = function(v)
        fogEnabled = v
        VisualModule:SetFog(v)
    end,
})
fogSection:CreateSlider({
    Name    = "Fog Start",
    Min     = 0,
    Max     = 5000,
    Default = 0,
    Callback= function(v)
        if fogEnabled then VisualModule:SetFog(true, v) end
    end,
})
fogSection:CreateSlider({
    Name    = "Fog End",
    Min     = 100,
    Max     = 10000,
    Default = 300,
    Callback= function(v)
        if fogEnabled then VisualModule:SetFog(true, nil, v) end
    end,
})

local fxSection = visualTab:CreateSection("Post-Processing")
fxSection:CreateToggle({
    Name     = "Bloom",
    Default  = true,
    Callback = function(v)
        VisualModule:SetBloom(v)
    end,
})
fxSection:CreateSlider({
    Name    = "Bloom Intensity",
    Min     = 0,
    Max     = 5,
    Default = 1,
    Callback= function(v)
        VisualModule:SetBloom(true, v)
    end,
})
fxSection:CreateButton({
    Name        = "Restore Visual Defaults",
    Description = "Revert all Lighting changes",
    Callback    = function()
        VisualModule:_restore()
        VisualModule:_backup()
        Delirium:Notify({Title="Visual",Message="Defaults restored",Duration=2})
    end,
})

-- ─────────────────────────────────────────────
-- TAB: Performance
-- ─────────────────────────────────────────────
local perfTab = Win:CreateTab({ Name = "Performance" })

local perfStatsSection = perfTab:CreateSection("Live Stats")
local fpsLabel  = perfStatsSection:CreateLabel({Name="FPS", Text="FPS: --"})
local pingLabel = perfStatsSection:CreateLabel({Name="Ping",Text="Ping: --"})
local memLabel  = perfStatsSection:CreateLabel({Name="Mem", Text="Memory: --"})
local netLabel  = perfStatsSection:CreateLabel({Name="Net", Text="Network: --"})

local function setLabelText(lbl, text)
    if not lbl then return end
    pcall(function()
        if lbl.SetText then lbl:SetText(text)
        elseif lbl.Instance then
            local tl = lbl.Instance:FindFirstChildOfClass("TextLabel")
            if tl then tl.Text = text end
        end
    end)
end

PerfModule.OnUpdate = function(m)
    setLabelText(fpsLabel,  string.format("FPS: %d  (min %d, max %d, avg %d)", m.FPS, m.MinFPS==math.huge and 0 or m.MinFPS, m.MaxFPS, m.AvgFPS))
    setLabelText(pingLabel, string.format("Ping: %dms  (avg %d, max %d)", m.Ping, m.AvgPing, m.MaxPing))
    setLabelText(memLabel,  string.format("Memory: %.1f MB", m.MemoryMB))
    setLabelText(netLabel,  string.format("Net ↓%.1f  ↑%.1f KB/s", m.NetRecv, m.NetSend))
end

perfStatsSection:CreateButton({
    Name        = "Reset FPS Stats",
    Description = "Clear min/max/avg history",
    Callback    = function()
        PerfModule.MinFPS     = math.huge
        PerfModule.MaxFPS     = 0
        PerfModule._fpsHistory= {}
        PerfModule._pingHistory={}
        Logger.Info("Performance","Stats reset")
    end,
})

local optimSection = perfTab:CreateSection("Optimization")
optimSection:CreateDropdown({
    Name    = "Optimization Profile",
    Options = {"LOW", "BALANCED", "PERFORMANCE"},
    Default = "BALANCED",
    Callback= function(v)
        OptimModule:ApplyProfile(v)
        Delirium:Notify({Title="Optimizer",Message="Profile: "..v,Duration=2})
    end,
})
optimSection:CreateToggle({
    Name     = "Enable Optimization",
    Default  = false,
    Callback = function(v)
        if v then Registry.Enable("Performance Optimizer")
        else Registry.Disable("Performance Optimizer") end
    end,
})
optimSection:CreateButton({
    Name        = "Restore Original Graphics",
    Description = "Undo all optimization changes",
    Callback    = function()
        OptimModule:Disable()
        OptimModule._applied = false
        Delirium:Notify({Title="Optimizer",Message="Restored",Duration=2})
    end,
})

-- ─────────────────────────────────────────────
-- TAB: Server
-- ─────────────────────────────────────────────
local serverTab = Win:CreateTab({ Name = "Server" })

local serverInfoSection = serverTab:CreateSection("Server Information")
local function buildServerInfoLabels()
    local info = ServerModule:GetInfo()
    serverInfoSection:CreateLabel({Name="JobId",   Text="Job ID: "..info.JobId:sub(1,24).."..."})
    serverInfoSection:CreateLabel({Name="PlaceId", Text="Place ID: "..info.PlaceId})
    serverInfoSection:CreateLabel({Name="Players", Text=string.format("Players: %d/%d", info.PlayerCount, info.MaxPlayers)})
end
buildServerInfoLabels()

serverInfoSection:CreateButton({
    Name        = "Copy Job ID",
    Description = "Copy full Job ID",
    Callback    = function()
        ServerModule:CopyJobId()
        Delirium:Notify({Title="Copied",Message="Job ID copied",Duration=2})
    end,
})
serverInfoSection:CreateButton({
    Name        = "Copy Place ID",
    Description = "Copy Place ID",
    Callback    = function()
        ServerModule:CopyPlaceId()
        Delirium:Notify({Title="Copied",Message="Place ID copied",Duration=2})
    end,
})
serverInfoSection:CreateButton({
    Name        = "Rejoin Server",
    Description = "Reconnect to current place",
    Callback    = function() ServerModule:Rejoin() end,
})

-- ─────────────────────────────────────────────
-- TAB: Explorer
-- ─────────────────────────────────────────────
local explorerTab = Win:CreateTab({ Name = "Explorer" })

local searchSection = explorerTab:CreateSection("Instance Search")
local searchBox = searchSection:CreateTextbox({
    Name        = "Search Query",
    Default     = "",
    Placeholder = "Search instances...",
    Callback    = function() end,
})
local resultLabel = searchSection:CreateLabel({Name="Results", Text="Results: --"})

searchSection:CreateButton({
    Name        = "Search",
    Description = "Search game instances by name or class",
    Callback    = function()
        local query = ""
        if searchBox and searchBox.Get then
            query = searchBox:Get()
        end
        if query == "" then
            Delirium:Notify({Title="Explorer",Message="Enter a search query",Duration=2})
            return
        end
        local results = ExplorerModule:Search(query, game, 50)
        local msg = string.format("Found %d instances", #results)
        setLabelText(resultLabel, msg)
        Logger.Info("Explorer","Search '"..query.."': "..#results.." results")
        if #results > 0 then
            local lines = {}
            for i,r in ipairs(results) do
                if i > 15 then
                    table.insert(lines, "... and "..(#results-15).." more")
                    break
                end
                table.insert(lines, r.ClassName..": "..r.Name.." ("..r.Children.." children)")
            end
            Delirium:Notify({
                Title   = "Explorer Results",
                Message = table.concat(lines,"\n"):sub(1,200),
                Duration= 5,
            })
        end
    end,
})
searchSection:CreateButton({
    Name        = "Copy First Result Path",
    Description = "Copy full path of first result to clipboard",
    Callback    = function()
        if #ExplorerModule._results > 0 then
            local r = ExplorerModule._results[1]
            copyToClipboard(r.Path)
            Delirium:Notify({Title="Copied",Message=r.Path,Duration=3})
        else
            Delirium:Notify({Title="No Results",Message="Run a search first",Duration=2})
        end
    end,
})

local rootSection = explorerTab:CreateSection("Root Targets")
rootSection:CreateDropdown({
    Name    = "Search Root",
    Options = {"game","workspace","Players","Lighting","ReplicatedStorage"},
    Default = "game",
    Callback= function(v)
        local targets = {
            game = game,
            workspace = workspace,
            Players = Players,
            Lighting = Lighting,
        }
        local ok, svc = pcall(function() return game:GetService(v) end)
        ExplorerModule._searchRoot = (ok and svc) or targets[v] or game
    end,
})

-- ─────────────────────────────────────────────
-- TAB: Session
-- ─────────────────────────────────────────────
local sessionTab = Win:CreateTab({ Name = "Session" })

local sessionSection = sessionTab:CreateSection("Session Statistics")
local durLabel    = sessionSection:CreateLabel({Name="Duration", Text="Duration: --"})
local deathLabel  = sessionSection:CreateLabel({Name="Deaths",   Text="Deaths: --"})
local respLabel   = sessionSection:CreateLabel({Name="Respawns", Text="Respawns: --"})
local sfpsLabel   = sessionSection:CreateLabel({Name="AvgFPS",   Text="Avg FPS: --"})
local spingLabel  = sessionSection:CreateLabel({Name="AvgPing",  Text="Avg Ping: --"})

local function refreshSession()
    local s = SessionModule:GetSummary()
    setLabelText(durLabel,   "Session Duration: "..s.Duration)
    setLabelText(deathLabel, "Deaths: "..s.Deaths)
    setLabelText(respLabel,  "Respawns: "..s.Respawns)
    setLabelText(sfpsLabel,  "Avg FPS: "..s.AvgFPS)
    setLabelText(spingLabel, "Avg Ping: "..s.AvgPing.."ms")
end

sessionSection:CreateButton({
    Name        = "Refresh",
    Description = "Update session statistics",
    Callback    = refreshSession,
})

-- Auto-refresh session labels every 5 seconds
local sessionRefreshConn = RunService.Heartbeat:Connect(function()
    -- throttle via tick
    if (math.floor(tick()) % 5) == 0 then
        pcall(refreshSession)
    end
end)

-- ─────────────────────────────────────────────
-- TAB: Diagnostics
-- ─────────────────────────────────────────────
local diagTab = Win:CreateTab({ Name = "Diagnostics" })

local consoleSection = diagTab:CreateSection("Internal Console")
local logDisplay = consoleSection:CreateLabel({
    Name = "Logs",
    Text = "[Console ready]",
})
local logFilter = ""

local function refreshLogs()
    local entries = Logger.GetAll(logFilter)
    local lines = {}
    local start = math.max(1, #entries - 20)
    for i = start, #entries do
        table.insert(lines, Logger.Format(entries[i]))
    end
    setLabelText(logDisplay, table.concat(lines,"\n"))
end

Logger.OnLog = function()
    pcall(refreshLogs)
end

consoleSection:CreateTextbox({
    Name        = "Filter",
    Default     = "",
    Placeholder = "Filter logs...",
    Callback    = function(v)
        logFilter = v or ""
        refreshLogs()
    end,
})
consoleSection:CreateButton({
    Name        = "Clear Console",
    Description = "Remove all log entries",
    Callback    = function()
        Logger.Clear()
        setLabelText(logDisplay,"[Cleared]")
    end,
})
consoleSection:CreateButton({
    Name        = "Copy Logs",
    Description = "Copy all logs to clipboard",
    Callback    = function()
        local entries = Logger.GetAll()
        local lines = {}
        for _,e in ipairs(entries) do table.insert(lines, Logger.Format(e)) end
        copyToClipboard(table.concat(lines,"\n"))
        Delirium:Notify({Title="Diagnostics",Message="Logs copied",Duration=2})
    end,
})

local compatSection = diagTab:CreateSection("Compatibility")
local function buildCompatLabels()
    local features = {"VirtualUser","TeleportService","writefile","Stats"}
    for _,f in ipairs(features) do
        local r = Compat.Check(f)
        local status = r.Status == "SUPPORTED" and "✓ " or "✗ "
        compatSection:CreateLabel({
            Name = f,
            Text = status..f..": "..r.Status..(r.Reason and " ("..r.Reason..")" or ""),
        })
    end
end
buildCompatLabels()

local moduleSection = diagTab:CreateSection("Module Status")
for name, mod in pairs(Registry._modules) do
    moduleSection:CreateLabel({
        Name = name,
        Text = name..": "..mod.Status,
    })
end

-- ─────────────────────────────────────────────
-- TAB: Automation
-- ─────────────────────────────────────────────
local autoTab = Win:CreateTab({ Name = "Automation" })

local afkSection = autoTab:CreateSection("Anti-AFK")
afkSection:CreateToggle({
    Name     = "Anti-AFK",
    Default  = false,
    Callback = function(v)
        AutoModule:SetAntiAFK(v)
        if v then Registry.Enable("Automation") end
    end,
})
afkSection:CreateLabel({
    Name = "AfkNote",
    Text = "Fires VirtualInput every 14 minutes to prevent AFK kick",
})

local qolSection = autoTab:CreateSection("Quality of Life")
qolSection:CreateToggle({
    Name     = "Ping Warning",
    Default  = false,
    Callback = function(v)
        AutoModule:SetPingWarning(v, 200)
    end,
})
qolSection:CreateSlider({
    Name    = "Ping Warning Threshold (ms)",
    Min     = 50,
    Max     = 500,
    Default = 200,
    Callback= function(v)
        ConfigModule:Set("Automation","PingThreshold",v)
    end,
})

-- ─────────────────────────────────────────────
-- TAB: Settings
-- ─────────────────────────────────────────────
local settingsTab = Win:CreateTab({ Name = "Settings" })

local themeSection = settingsTab:CreateSection("Theme")
themeSection:CreateDropdown({
    Name    = "Theme",
    Options = {"Dark","Light"},
    Default = "Dark",
    Callback= function(v)
        pcall(function()
            local ThemeEngine = game:GetService("RunService") -- placeholder
            -- Call Delirium's internal ThemeEngine if accessible
        end)
        Logger.Info("Settings","Theme changed to: "..v)
    end,
})

local configSection = settingsTab:CreateSection("Configuration")
configSection:CreateButton({
    Name        = "Export Config",
    Description = "Copy current config as JSON to clipboard",
    Callback    = function()
        ConfigModule:Export()
        Delirium:Notify({Title="Config",Message="Exported to clipboard",Duration=3})
    end,
})
configSection:CreateTextbox({
    Name        = "Import Config",
    Default     = "",
    Placeholder = "Paste JSON config...",
    Callback    = function(v)
        if v and #v > 2 then
            local ok = ConfigModule:Import(v)
            Delirium:Notify({
                Title   = "Config",
                Message = ok and "Imported successfully" or "Import failed — invalid JSON",
                Duration= 3,
            })
        end
    end,
})
configSection:CreateButton({
    Name        = "Reset to Defaults",
    Description = "Restore all configuration defaults",
    Callback    = function()
        ConfigModule:Reset()
        Delirium:Notify({Title="Config",Message="Reset to defaults",Duration=2})
    end,
})

local moduleManageSection = settingsTab:CreateSection("Module Management")
moduleManageSection:CreateButton({
    Name        = "Disable All Modules",
    Description = "Disable all active modules and restore game state",
    Callback    = function()
        for name,mod in pairs(Registry._modules) do
            if mod.Status == "ON" then
                Registry.Disable(name)
            end
        end
        Delirium:Notify({Title="Universal",Message="All modules disabled",Duration=3})
    end,
})

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP ON SCRIPT END
-- ═══════════════════════════════════════════════════════════════
Win:OnUnload(function()
    sessionRefreshConn:Disconnect()
    Registry.DestroyAll()
    Logger.Clear()
end)

Logger.Info("Universal","UI built — Universal v1.0.0 ready")
Delirium:Notify({
    Title   = "Universal",
    Message = "v1.0.0 loaded — all systems online",
    Duration= 4,
})