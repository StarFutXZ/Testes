-- Sniper Arena: Interface Atlas + Engine Mario Hub
-- join our discord server: https://discord.gg/76tHHGBrfz
-- made by @ronzy.exe on discord

if not game:IsLoaded() then game.Loaded:Wait() end
if game.GameId ~= 9534705677 then game:GetService("Players").LocalPlayer:Kick("This script is for Sniper Arena only") return end

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local Player = Players.LocalPlayer
local ENV    = (typeof(getgenv) == "function" and getgenv()) or _G
local osClock = os.clock
local alive = true

if ENV.ATLAS_SNIPER then ENV.ATLAS_SNIPER.Library:Unload() end

--// ============================================================
--// ATLAS LIBRARY BOOTSTRAP
--// ============================================================
local Library
do
    local source
    local pre = ENV.ATLAS_PREFETCH
    if type(pre) == "table" then
        local started = os.clock()
        while pre.noir == nil and os.clock() - started < 15 do task.wait() end
        if type(pre.noir) == "string" then source = pre.noir end
    end
    if not source then
        local base = tostring(ENV.ATLAS_BASE or "https://getatlas.lol/lib/")
        local url  = base .. "NOIR.lua?v=" .. tostring(os.time())
        local finished, body = false, nil
        task.spawn(function()
            local send = ENV.request or ENV.http_request or (type(request) == "function" and request)
            local ok, result
            if type(send) == "function" then
                ok, result = pcall(send, {Url = url, Method = "GET", Timeout = 12})
                if ok and type(result) == "table" and tonumber(result.StatusCode) == 200 then body = result.Body end
            end
            if not body then local s, b = pcall(function() return game:HttpGet(url) end); if s then body = b end end
            finished = true
        end)
        local deadline = os.clock() + 15
        repeat task.wait() until finished or os.clock() >= deadline
        if type(body) == "string" and body:find("return Library", 1, true) then source = body end
    end
    assert(source, "Could not download the Atlas UI.")
    local previous = ENV.NOIR_LIB_ONLY
    ENV.NOIR_LIB_ONLY = true
    local ok, result = pcall(function() return assert(loadstring(source, "=NOIR"))() end)
    ENV.NOIR_LIB_ONLY = previous
    assert(ok and type(result) == "table", tostring(result))
    Library = result
end
Library.ScreenGui.Parent = Player.PlayerGui

--// ============================================================
--// MARIO HUB ENGINE (GAMELIB)
--// ============================================================
local GameLib = { Config = {}, Service = {}, Missing = {}, Loaded = false }
local function LoadModules()
    if GameLib.Loaded then return end
    GameLib.Loaded = true
    
    local function req(parent, name)
        local child = parent and parent:FindFirstChild(name) or RS:FindFirstChild(name, true)
        if child and child:IsA("ModuleScript") then
            local ok, mod = pcall(require, child)
            if ok then return mod end
        end
        return nil
    end

    local cfg = RS:FindFirstChild("Config")
    local rem = RS:FindFirstChild("Remote")
    local con = RS:FindFirstChild("Constant")
    local cli = RS:FindFirstChild("Client")

    for _, n in ipairs({"WeaponConfig", "WrapConfig", "QuestConfig"}) do GameLib.Config[n] = req(cfg, n) end
    GameLib.RarityColor = req(con, "RarityColor")
    
    for _, n in ipairs({"StatusService", "GachaService", "WeaponService", "QuestService", "EntityService", "CombatService", "GameService"}) do
        GameLib.Service[n] = req(rem, n)
    end
    GameLib.CameraController = req(cli, "CameraController")
    GameLib.WeaponController = req(cli, "WeaponController")
    GameLib.RoomManager      = req(rem and rem:FindFirstChild("GameService"), "RoomManager")
end
task.spawn(function() task.wait(1) LoadModules() end)

--// ============================================================
--// UTILS & ENTITY HANDLERS
--// ============================================================
local Opt = {
    aim = false, silent = false, showFov = false, ragebot = false, triggerbot = false,
    teamCheck = true, wallCheck = true, aimPart = "Head", radius = 220, smooth = 3, prediction = 60,
    esp = false, names = true, distance = true, health = true, highlights = true, throughWalls = true,
    maxDistance = 1500, speed = false, speedValue = 24, jump = false, jumpValue = 60,
    infiniteJump = false, noclip = false, fastRespawn = false, autoJoin = false, infiniteDash = false,
    skinChanger = false, autoOpen = false, autoSell = false, autoClaim = false, antiAfk = false,
    noRecoil = false, noSpread = false, instantScope = false
}

local function TryCall(obj, m)
    if type(obj) ~= "table" and typeof(obj) ~= "Instance" then return nil, false end
    local fn = obj[m]; if type(fn) ~= "function" then return nil, false end
    local ok, v = pcall(fn, obj); return ok and v or nil, ok
end

local function EntityService() return GameLib.Service.EntityService end
local function ListEntities()
    local s = EntityService(); if not s then return {} end
    local ok, f = pcall(function() return s.WorldManager:GetFocusedEntities() end)
    if not ok or type(f) ~= "table" then return {} end
    return f._items or f.Items or f
end
local function LocalEntity()
    local s = EntityService(); if not s then return nil end
    local ok, e = pcall(function() return s.GetLocalEntity() end)
    if ok and e then return e end
    ok, e = pcall(function() return s:GetLocalEntity() end); return ok and e or nil
end
local function EntityCharacter(e)
    local hum = e and e.Humanoid
    if hum and hum.Parent then return hum.Parent end
    return e and e.Character or nil
end
local function EntityRoot(e)
    local c = EntityCharacter(e); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head") or c.PrimaryPart
end
local function EntityHealth(e)
    if not e then return 0, 0 end
    local h = e.Health or select(1, TryCall(e, "GetHealth")) or 0
    local m = e.MaxHealth or select(1, TryCall(e, "GetMaxHealth")) or 0
    return h, m
end
local function EntityTeam(e)
    local inst = e and e.Instance
    if typeof(inst) == "Instance" then local t = inst:GetAttribute("Team"); if t ~= nil then return tostring(t) end end
    local c = EntityCharacter(e); local t = c and c:GetAttribute("Team"); return t ~= nil and tostring(t) or nil
end
local function EntityFriendly(e)
    local c = EntityCharacter(e); local marks = Workspace:FindFirstChild("Highlight")
    if c and marks then
        local friendly = marks:FindFirstChild("Friendly")
        if friendly and c:IsDescendantOf(friendly) then return true end
        if c:IsDescendantOf(marks) then return false end
    end
    if Player:GetAttribute("combatPaused") ~= false then return false end
    local mine = EntityTeam(LocalEntity()); local theirs = EntityTeam(e)
    return mine ~= nil and mine == theirs
end

--// ============================================================
--// MARIO HUB COMBAT ENGINE (Aimbot & Silent)
--// ============================================================
local savedShooters = setmetatable({}, { __mode = "k" })
local targetModel, targetPart, lastShot = nil, nil, 0
local OriginParams = nil

local function GetShooter()
    local c = GameLib.Service.CombatService
    local w = c and c.GetCurrentWeapon()
    return w, w and w._Shootable
end

local function OriginOverride()
    if OriginParams ~= nil then return OriginParams or nil end
    if not Util.GetUpvalue then return nil end
    local cc = GameLib.CameraController
    if not (cc and cc.GetCombatOriginFn) then OriginParams = false; return nil end
    local ok, holder = pcall(function() return Util.GetUpvalue(cc.GetCombatOriginFn(), 1) end)
    local params = ok and type(holder) == "table" and type(holder.TempParams) == "table" and holder.TempParams
    OriginParams = params or false
    return params or nil
end

local function PredictPos(part)
    local lead = (Opt.prediction or 60) / 1000
    if lead <= 0 then return part.Position end
    return part.Position + part.AssemblyLinearVelocity * lead
end

local function ShootAt(shooter, target, part, opts)
    local params = OriginOverride()
    if not params then return nil end
    local start = Workspace.CurrentCamera.CFrame.Position
    local aim   = PredictPos(part)
    opts = type(opts) == "table" and opts or {}
    opts.Target = target.Instance
    opts.TargetHeadshot = part.Name == "Head" or nil
    local ok, localPos = pcall(function() return target:GetPivot(true):PointToObjectSpace(aim) end)
    if ok then opts.TargetPos = localPos end
    local save = { params.CameraCFrame, params.SubjectDistance, params.MouseLockOffset }
    params.CameraCFrame, params.SubjectDistance, params.MouseLockOffset = CFrame.lookAt(start, aim), 0, Vector3.zero
    local fired, shot = pcall(shooter.Shoot, shooter, start, (aim - start).Unit, opts)
    params.CameraCFrame, params.SubjectDistance, params.MouseLockOffset = save[1], save[2], save[3]
    if not fired then warn("[SniperArena] silent:", shot) end
    return fired and shot or nil
end

local function silentHook(shooter, ...)
    if Opt.silent and targetModel and targetPart and targetPart.Parent then
        local entSvc = EntityService()
        if entSvc then
            local ok, entity = pcall(function() return entSvc:GetEntity(targetModel) end)
            if ok and entity then return ShootAt(shooter, entity, targetPart, ...) end
        end
    end
    return savedShooters[shooter].Fn(shooter, ...)
end

local function applySilentHook()
    local _, shooter = GetShooter()
    if type(shooter) == "table" and shooter.Shoot and not savedShooters[shooter] then
        savedShooters[shooter] = { Raw = rawget(shooter, "LocalShoot"), Fn = shooter.LocalShoot }
        rawset(shooter, "LocalShoot", silentHook)
    end
end
local function restoreSilentHook() for s, v in pairs(savedShooters) do rawset(s, "LocalShoot", v.Raw) end; table.clear(savedShooters) end

local function FireWeapon()
    local now = osClock(); if now - lastShot < 0.12 then return end; lastShot = now
    local _, shooter = GetShooter(); if not shooter then return end
    pcall(shooter.LocalShoot, shooter)
end

--// ============================================================
--// MARIO HUB PLAYER ENGINE (Speed, Respawn, etc)
--// ============================================================
local SelfPlayer = { Character = nil, Humanoid = nil, Root = nil }
local function BindCharacter(char)
    SelfPlayer.Character = char
    SelfPlayer.Humanoid = char:WaitForChild("Humanoid", 10)
    SelfPlayer.Root     = char:WaitForChild("HumanoidRootPart", 10)
end
if Player.Character then BindCharacter(Player.Character) end
Player.CharacterAdded:Connect(function(c) task.defer(function() BindCharacter(c) end) end)

local AntiAfk = { Conn = nil }
local function AntiAfkStart()
    Opt.antiAfk = true
    if not AntiAfk.Conn then
        AntiAfk.Conn = Player.Idled:Connect(function()
            if not Opt.antiAfk then return end
            VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
end
local function AntiAfkStop() Opt.antiAfk = false; if AntiAfk.Conn then AntiAfk.Conn:Disconnect(); AntiAfk.Conn = nil end end

local Respawn = { Fired = false }
local function RespawnStep()
    if not Opt.fastRespawn then return end
    local gs = GameLib.Service.GameService
    if not (gs and gs.IsJoined and gs.IsJoined()) then return end
    local dead = (Player:GetAttribute("State") == "Dead") or (SelfPlayer.Humanoid and SelfPlayer.Humanoid.Health <= 0)
    if not dead then Respawn.Fired = false; return end
    if Respawn.Fired then return end
    Respawn.Fired = true
    if gs.CanFastRespawn and gs.CanFastRespawn() then gs.FastRespawn() return end
    local rem = RS:FindFirstChild("Remote"); local g = rem and rem:FindFirstChild("GameService"); local r = g and g:FindFirstChild("Respawn")
    if r then r:FireServer() end
end

local saveSet = {}
local function updateProps()
    local char = SelfPlayer.Character; local h = char and char:FindFirstChildOfClass("Humanoid")
    if h then
        if Opt.speed then h.WalkSpeed = Opt.speedValue else if saveSet.ws then h.WalkSpeed = saveSet.ws end end
        if Opt.jump then h.JumpPower = Opt.jumpValue else if saveSet.jp then h.JumpPower = saveSet.jp end end
        if Opt.noclip then for _, p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
    end
end

--// ============================================================
--// ATLAS UI RENDER
--// ============================================================
local Overlay = Instance.new("ScreenGui")
Overlay.Name = "AtlasSniperOverlay"; Overlay.ResetOnSpawn = false; Overlay.IgnoreGuiInset = true; Overlay.Parent = Player.PlayerGui
local visuals = {}

local function destroyVisual(plr)
    if visuals[plr] then
        visuals[plr].label:Destroy(); if visuals[plr].highlight then visuals[plr].highlight:Destroy() end
        visuals[plr] = nil
    end
end

local function refreshESP()
    if not Opt.esp then for plr in pairs(visuals) do destroyVisual(plr) end; return end
    local cam = Workspace.CurrentCamera; if not cam then return end
    local seen = {}
    for _, e in pairs(ListEntities()) do
        if not e.IsLocalEntity or not e:IsLocalEntity() then
            local char = EntityCharacter(e); local hrp = EntityRoot(e); local h, m = EntityHealth(e)
            if char and hrp and h > 0 then
                local plr = Players:GetPlayerFromCharacter(char) or char
                local range = (hrp.Position - cam.CFrame.Position).Magnitude
                if range <= Opt.maxDistance then
                    seen[plr] = true
                    local v = visuals[plr]
                    if not v then
                        local label = Instance.new("BillboardGui"); label.Size = UDim2.fromOffset(220, 58); label.StudsOffset = Vector3.new(0, 2.1, 0); label.Parent = Overlay
                        local text = Instance.new("TextLabel"); text.Size = UDim2.new(1,0,0,18); text.BackgroundTransparency = 1; text.Font = Enum.Font.BuilderSansBold; text.TextColor3 = Color3.new(1,1,1); text.Parent = label
                        local metrics = Instance.new("TextLabel"); metrics.Position = UDim2.fromOffset(0, 37); metrics.Size = UDim2.new(1,0,0,18); metrics.BackgroundTransparency = 1; metrics.TextColor3 = Color3.fromRGB(170,184,205); metrics.Parent = label
                        local hl = Instance.new("Highlight"); hl.Parent = Overlay; hl.FillTransparency = 0.88
                        v = {label = label, text = text, metrics = metrics, highlight = hl}
                        visuals[plr] = v
                    end
                    v.label.Adornee = hrp
                    v.highlight.Adornee = char
                    v.text.Text = char.Name; v.text.Visible = Opt.names
                    v.metrics.Text = string.format("%dm", math.floor(range)); v.metrics.Visible = Opt.distance
                    v.label.AlwaysOnTop = Opt.throughWalls
                    v.highlight.Enabled = Opt.highlights
                end
            end
        end
    end
    for plr in pairs(visuals) do if not seen[plr] then destroyVisual(plr) end end
end

local function toggle(sec, name, flag, def, cb) sec:Toggle({Name = name, Flag = flag, Default = def, Callback = cb}) end

local function buildUI()
    local Window = Library:CreateWindow({Title = "Eclipse", Subtitle = "Sniper Arena + Mario Hub", Logo = "peak"})
    
    local Main = Window:Tab({Name = "Main", Icon = "crosshair", Description = "Aimbot & Combat"})
    local aimSec = Main:Section({Name = "Aimbot", Icon = "crosshair", Side = "Left"})
    toggle(aimSec, "Enable Aimbot", "aim", false, function(v) Opt.aim = v end)
    toggle(aimSec, "Show FOV", "showfov", false, function(v) Opt.showFov = v end)
    toggle(aimSec, "Team Check", "team", true, function(v) Opt.teamCheck = v end)
    toggle(aimSec, "Wall Check", "wall", true, function(v) Opt.wallCheck = v end)
    aimSec:Slider({Name = "FOV Radius", Flag = "fovrad", Min = 40, Max = 600, Default = 220, Callback = function(v) Opt.radius = v end})
    aimSec:Slider({Name = "Smoothness", Flag = "smooth", Min = 1, Max = 20, Default = 3, Callback = function(v) Opt.smooth = v end})
    aimSec:Dropdown({Name = "Aim Part", Flag = "part", Options = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = "Head", Callback = function(v) Opt.aimPart = v end})

    local rageSec = Main:Section({Name = "Rage / Silent", Icon = "bomb", Side = "Right"})
    toggle(rageSec, "Silent Aim", "silent", false, function(v) Opt.silent = v; if v then applySilentHook() else restoreSilentHook() end end)
    toggle(rageSec, "Ragebot (Auto Fire)", "ragebot", false, function(v) Opt.ragebot = v end)
    toggle(rageSec, "Triggerbot", "trigger", false, function(v) Opt.triggerbot = v end)

    local EspTab = Window:Tab({Name = "ESP", Icon = "eye", Description = "Visuals"})
    local visSec = EspTab:Section({Name = "Settings", Icon = "eye", Side = "Left"})
    toggle(visSec, "Enable ESP", "esp", false, function(v) Opt.esp = v end)
    toggle(visSec, "Names", "names", true, function(v) Opt.names = v end)
    toggle(visSec, "Distance", "dist", true, function(v) Opt.distance = v end)
    toggle(visSec, "Highlights", "hl", true, function(v) Opt.highlights = v end)
    toggle(visSec, "Through Walls", "tw", true, function(v) Opt.throughWalls = v end)

    local PlayerTab = Window:Tab({Name = "Player", Icon = "user-round", Description = "Movement & Utility"})
    local moveSec = PlayerTab:Section({Name = "Movement", Icon = "gauge", Side = "Left"})
    local spd = toggle(moveSec, "Walk Speed", "speed", false, function(v) Opt.speed = v end):SubOptions()
    spd:Slider({Name = "Speed", Flag = "spdval", Min = 16, Max = 100, Default = 24, Callback = function(v) Opt.speedValue = v end})
    local jmp = toggle(moveSec, "Jump Power", "jump", false, function(v) Opt.jump = v end):SubOptions()
    jmp:Slider({Name = "Jump", Flag = "jmpval", Min = 50, Max = 200, Default = 60, Callback = function(v) Opt.jumpValue = v end})
    toggle(moveSec, "Noclip", "noclip", false, function(v) Opt.noclip = v end)

    local utilSec = PlayerTab:Section({Name = "Utility", Icon = "gear", Side = "Right"})
    toggle(utilSec, "Fast Respawn", "fastres", false, function(v) Opt.fastRespawn = v end)
    toggle(utilSec, "Anti AFK", "antiafk", false, function(v) if v then AntiAfkStart() else AntiAfkStop() end end)

    Window:SelectTab(Main)
    Library:SetOpen(true)
end

--// ============================================================
--// LOOPS
--// ============================================================
local fovCircle = Instance.new("Frame"); fovCircle.AnchorPoint = Vector2.new(0.5,0.5); fovCircle.BackgroundTransparency = 1; fovCircle.Parent = Overlay
local fovCorner = Instance.new("UICorner"); fovCorner.CornerRadius = UDim.new(0.5,0); fovCorner.Parent = fovCircle
local fovStroke = Instance.new("UIStroke"); fovStroke.Color = Color3.new(1,1,1); fovStroke.Parent = fovCircle
local tick = 0

RunService.RenderStepped:Connect(function(dt)
    if not alive then return end
    tick += dt
    if tick >= 0.1 then updateProps(); tick = 0 end

    local cam = Workspace.CurrentCamera
    if not cam then return end

    if Opt.aim or Opt.silent or Opt.ragebot or Opt.triggerbot then
        local origin = cam.ViewportSize / 2
        local best, bestPos, bestScore = nil, nil, Opt.radius
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= Player and (not Opt.teamCheck or not (Player.Team and plr.Team and Player.Team == plr.Team)) then
                local char = plr.Character
                if char and char:FindFirstChild(Opt.aimPart) then
                    local part = char[Opt.aimPart]
                    local pos = part.Position
                    local screenPos, onScreen = cam:WorldToViewportPoint(pos)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - origin).Magnitude
                        if dist < bestScore then
                            local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = {cam, Player.Character}
                            local ray = Workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, params)
                            if not Opt.wallCheck or not ray or ray.Instance:IsDescendantOf(char) then
                                best, bestPos, bestScore = plr, pos, dist
                            end
                        end
                    end
                end
            end
        end
        if best then
            targetModel, targetPart = best.Character, best.Character[Opt.aimPart]
            if Opt.aim and bestPos then
                cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, bestPos), math.clamp(dt * Opt.smooth * 10, 0, 1))
            end
            if Opt.ragebot then FireWeapon() end
            if Opt.triggerbot then
                local ray = Workspace:Raycast(cam.CFrame.Position, cam.CFrame.LookVector * 2000, RaycastParams.new())
                if ray and ray.Instance:IsDescendantOf(targetModel) then FireWeapon() end
            end
        else
            targetModel, targetPart = nil, nil
        end
    end

    if Opt.aim and Opt.showFov then
        fovCircle.Visible = true
        fovCircle.Position = UDim2.fromOffset(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)
        fovCircle.Size = UDim2.fromOffset(Opt.radius * 2, Opt.radius * 2)
    else
        fovCircle.Visible = false
    end
    refreshESP()
end)

task.spawn(function()
    task.wait(0.5)
    buildUI()
end)

Library:OnUnload(function()
    alive = false
    restoreSilentHook()
end)

ENV.ATLAS_SNIPER = { Library = Library, Options = Opt, Stop = function() alive = false; restoreSilentHook() end }