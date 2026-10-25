-- Sniper Arena — OTIMIZADO + UI COMPLETA
-- join our discord server: https://discord.gg/76tHHGBrfz

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

assert(game.GameId == 9534705677, "This script belongs to Sniper Arena.")
if ENV.ATLAS_SNIPER then ENV.ATLAS_SNIPER.Library:Unload() end

--// ============================================================
--// Library bootstrap (MANTIDO IGUAL)
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
    assert(source, "Could not download the Atlas hub interface.")
    local previous = ENV.NOIR_LIB_ONLY
    ENV.NOIR_LIB_ONLY = true
    local ok, result = pcall(function() return assert(loadstring(source, "=NOIR"))() end)
    ENV.NOIR_LIB_ONLY = previous
    assert(ok and type(result) == "table", tostring(result))
    Library = result
end
Library.ScreenGui.Parent = Player.PlayerGui

-- Bypass Auth
local keyTier = "paid"

--// ============================================================
--// Lazy Loader para os Módulos (Otimização Extrema)
--// ============================================================
local GameLib = { Config = {}, Service = {}, Loaded = false }

local function LoadModules()
    if GameLib.Loaded then return end
    GameLib.Loaded = true
    
    local function req(parent, name)
        local child = parent and parent:FindFirstChild(name) or RS:FindFirstChild(name, true)
        if child and child:IsA("ModuleScript") then
            local ok, mod = pcall(require, child)
            return ok and mod or nil
        end
        return nil
    end

    local cfg = RS:FindFirstChild("Config")
    local rem = RS:FindFirstChild("Remote")
    local con = RS:FindFirstChild("Constant")
    
    GameLib.Config.WeaponConfig = req(cfg, "WeaponConfig")
    GameLib.Config.WrapConfig   = req(cfg, "WrapConfig")
    GameLib.Service.EntityService = req(rem, "EntityService")
    GameLib.Service.CombatService = req(rem, "CombatService")
    GameLib.Service.GameService   = req(rem, "GameService")
end

--// ============================================================
--// Variáveis de Estado e Otimizações
--// ============================================================
local alive = true
local visuals = {}
local Stats = { errors = 0, players = 0, visible = 0, target = nil, lastError = nil }
local Opt = {
    aim = false, silent = false, showFov = false, noDelay = false, aimBots = false, espBots = true, hold = true,
    teamCheck = true, wallCheck = true, aimPart = "Head", radius = 220, smooth = 3, prediction = 60,
    esp = false, names = true, distance = true, health = true, highlights = true, throughWalls = true,
    maxDistance = 1500, textSize = 13, speed = false, speedValue = 24, jump = false, jumpValue = 60,
    fov = false, fovValue = 85, bright = false, infiniteJump = false, noclip = false, noFog = false,
    fastRespawn = false, autoJoin = false, infiniteDash = false, skinChanger = false, autoOpen = false,
    autoSell = false, autoClaim = false, ragebot = false, triggerbot = false, noRecoil = false,
    noSpread = false, instantScope = false, antiAfk = false
}

--// ============================================================
--// Helpers Básicos
--// ============================================================
local function getChar(plr)
    if typeof(plr) == "Instance" and plr:IsA("Model") then return plr end
    return plr.Character
end

local function getHealth(plr, model)
    local h = model and model:FindFirstChildOfClass("Humanoid")
    return h and h.Health or 0, h and h.MaxHealth or 100
end

local function canSee(cam, model, pos)
    if not Opt.wallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { cam, getChar(Player) }
    local hit = workspace:Raycast(cam.CFrame.Position, pos - cam.CFrame.Position, params)
    return not hit or hit.Instance:IsDescendantOf(model)
end

--// ============================================================
--// Aim System (Rápido e Otimizado)
--// ============================================================
local function getAimTarget()
    local cam = workspace.CurrentCamera
    if not cam then return nil end
    local origin = cam.ViewportSize / 2
    local best, bestPos, bestScore = nil, nil, Opt.radius

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player and (not Opt.teamCheck or not (Player.Team and plr.Team and Player.Team == plr.Team)) then
            local model = getChar(plr)
            if model and model:FindFirstChild("HumanoidRootPart") then
                local part = model:FindFirstChild(Opt.aimPart) or model:FindFirstChild("Head") or model:FindFirstChild("HumanoidRootPart")
                local pos = part.Position
                local screenPos, onScreen = cam:WorldToViewportPoint(pos)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - origin).Magnitude
                    if dist < bestScore and canSee(cam, model, pos) then
                        best, bestPos, bestScore = plr, pos, dist
                    end
                end
            end
        end
    end
    return best, bestPos
end

local savedShooters = setmetatable({}, { __mode = "k" })
local targetModel, targetPart = nil, nil

local function silentHook(shooter, ...)
    if Opt.silent and targetModel and targetPart and targetPart.Parent then
        local ok, entityService = pcall(function() return GameLib.Service.EntityService end)
        if ok and entityService then
            local entity = entityService:GetEntity(targetModel)
            if entity then
                local args = {...}
                local opts = type(args[1]) == "table" and table.clone(args[1]) or {}
                opts.Target = entity.Instance
                opts.TargetHeadshot = targetPart.Name == "Head"
                opts.TargetPos = entity:GetPivot(true):PointToObjectSpace(targetPart.Position)
                args[1] = opts
                return savedShooters[shooter].Fn(shooter, table.unpack(args))
            end
        end
    end
    return savedShooters[shooter].Fn(shooter, ...)
end

local function applySilentHook()
    if not GameLib.Loaded then return end
    local combat = GameLib.Service.CombatService
    local weapon = combat and combat.GetCurrentWeapon()
    local shooter = weapon and weapon._Shootable
    if type(shooter) == "table" and shooter.Shoot and not savedShooters[shooter] then
        savedShooters[shooter] = { Raw = rawget(shooter, "LocalShoot"), Fn = shooter.LocalShoot }
        rawset(shooter, "LocalShoot", silentHook)
    end
end

local function restoreSilentHook()
    for shooter, s in pairs(savedShooters) do
        rawset(shooter, "LocalShoot", s.Raw)
    end
    table.clear(savedShooters)
end

--// ============================================================
--// ESP System (Leve)
--// ============================================================
local Overlay = Instance.new("ScreenGui")
Overlay.Name = "AtlasSniperOverlay"; Overlay.ResetOnSpawn = false; Overlay.IgnoreGuiInset = true
Overlay.Parent = Player.PlayerGui

local function destroyVisual(plr)
    if visuals[plr] then
        visuals[plr].label:Destroy()
        if visuals[plr].highlight then visuals[plr].highlight:Destroy() end
        visuals[plr] = nil
    end
end

local function refreshESP()
    if not Opt.esp then
        for plr in pairs(visuals) do destroyVisual(plr) end
        return
    end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= Player then
            local model = getChar(plr)
            local hrp = model and model:FindFirstChild("HumanoidRootPart")
            if hrp then
                local dist = (hrp.Position - cam.CFrame.Position).Magnitude
                if dist <= Opt.maxDistance then
                    seen[plr] = true
                    local v = visuals[plr]
                    if not v then
                        local label = Instance.new("BillboardGui")
                        label.Size = UDim2.fromOffset(200, 50); label.StudsOffset = Vector3.new(0, 2.5, 0); label.Parent = Overlay
                        local txt = Instance.new("TextLabel")
                        txt.Size = UDim2.fromScale(1, 1); txt.BackgroundTransparency = 1; txt.TextScaled = true
                        txt.TextColor3 = Color3.new(1,1,1); txt.Font = Enum.Font.BuilderSansBold; txt.Parent = label
                        v = { label = label, text = txt, highlight = Instance.new("Highlight") }
                        v.highlight.Parent = Overlay; v.highlight.FillTransparency = 0.7; v.highlight.OutlineTransparency = 0.5
                        visuals[plr] = v
                    end
                    v.label.Adornee = hrp
                    v.highlight.Adornee = model
                    v.text.Text = string.format("%s [%dm]", plr.Name, math.floor(dist))
                    v.label.Enabled = Opt.names
                    v.highlight.Enabled = Opt.highlights
                elseif seen[plr] == nil then
                    destroyVisual(plr)
                end
            end
        end
    end
    for plr in pairs(visuals) do if not seen[plr] then destroyVisual(plr) end end
end

--// ============================================================
--// Build UI
--// ============================================================
local function toggle(sec, name, flag, def, cb)
    sec:Toggle({ Name = name, Flag = flag, Default = def, Callback = cb })
end

local function buildUI()
    local Window = Library:CreateWindow({Title = "Eclipse", Subtitle = "Sniper Arena + Mario Hub", Logo = "peak"})
    
    -- MAIN
    local Main = Window:Tab({Name = "Main", Icon = "crosshair", Description = "Aimbot e Silent"})
    local aimSec = Main:Section({Name = "Aimbot", Icon = "crosshair", Side = "Left"})
    toggle(aimSec, "Enable Aimbot", "aim", false, function(v) Opt.aim = v end)
    toggle(aimSec, "Team Check", "teamcheck", true, function(v) Opt.teamCheck = v end)
    toggle(aimSec, "Wall Check", "wallcheck", true, function(v) Opt.wallCheck = v end)
    aimSec:Slider({Name = "FOV Radius", Flag = "fovrad", Min = 40, Max = 600, Default = 220, Callback = function(v) Opt.radius = v end})
    aimSec:Slider({Name = "Smooth", Flag = "smooth", Min = 1, Max = 20, Default = 3, Callback = function(v) Opt.smooth = v end})
    
    local silentSec = Main:Section({Name = "Silent Aim", Icon = "target", Side = "Right"})
    toggle(silentSec, "Enable Silent", "silent", false, function(v) Opt.silent = v; if v then applySilentHook() else restoreSilentHook() end end)
    toggle(silentSec, "Remove Delay (Exploit)", "nodelay", false, function(v) Opt.noDelay = v end)
    silentSec:Dropdown({Name = "Aim Part", Flag = "aimpart", Options = {"Head", "UpperTorso", "HumanoidRootPart"}, Default = "Head", Callback = function(v) Opt.aimPart = v end})

    -- PLAYER
    local PlayerTab = Window:Tab({Name = "Player", Icon = "user-round", Description = "Movimento e Utilidades"})
    local moveSec = PlayerTab:Section({Name = "Movement", Icon = "gauge", Side = "Left"})
    local speedSub = toggle(moveSec, "Walk Speed", "speed", false, function(v) Opt.speed = v end):SubOptions()
    speedSub:Slider({Name = "Speed Value", Flag = "speedval", Min = 16, Max = 100, Default = 24, Callback = function(v) Opt.speedValue = v end})
    local jumpSub = toggle(moveSec, "Jump Power", "jump", false, function(v) Opt.jump = v end):SubOptions()
    jumpSub:Slider({Name = "Jump Value", Flag = "jumpval", Min = 50, Max = 200, Default = 60, Callback = function(v) Opt.jumpValue = v end})
    toggle(moveSec, "Infinite Jump", "infjump", false, function(v) Opt.infiniteJump = v end)
    toggle(moveSec, "Noclip", "noclip", false, function(v) Opt.noclip = v end)
    toggle(moveSec, "Infinite Dash", "dash", false, function(v) Opt.infiniteDash = v end)

    local utilSec = PlayerTab:Section({Name = "Utility", Icon = "shield", Side = "Right"})
    toggle(utilSec, "Fast Respawn", "fastres", false, function(v) Opt.fastRespawn = v end)
    toggle(utilSec, "Auto Join Round", "autojoin", false, function(v) Opt.autoJoin = v end)
    toggle(utilSec, "Anti AFK", "antiafk", false, function(v) Opt.antiAfk = v end)

    -- ESP
    local ESPTab = Window:Tab({Name = "ESP", Icon = "eye", Description = "Visualização"})
    local visSec = ESPTab:Section({Name = "Settings", Icon = "eye", Side = "Left"})
    toggle(visSec, "Enable ESP", "esp", false, function(v) Opt.esp = v end)
    toggle(visSec, "Names & Distance", "names", true, function(v) Opt.names = v end)
    toggle(visSec, "Highlights", "highlights", true, function(v) Opt.highlights = v end)
    toggle(visSec, "Through Walls", "thruwalls", true, function(v) Opt.throughWalls = v end)
    visSec:Slider({Name = "Max Distance", Flag = "maxdist", Min = 100, Max = 3000, Default = 1500, Callback = function(v) Opt.maxDistance = v end})

    -- SKINS
    local SkinsTab = Window:Tab({Name = "Skins", Icon = "star", Description = "Skin Changer"})
    local skinSec = SkinsTab:Section({Name = "Skin Changer", Icon = "star", Side = "Left"})
    toggle(skinSec, "Enable Skins", "skin", false, function(v) 
        Opt.skinChanger = v 
        if v then LoadModules() end 
    end)
    skinSec:Paragraph({Title = "Aviso", Content = "As skins são carregadas ao ativar."})

    -- ECONOMY
    local EcoTab = Window:Tab({Name = "Economy", Icon = "coin", Description = "Auto Farm"})
    local ecoSec = EcoTab:Section({Name = "Economy", Icon = "coin", Side = "Left"})
    toggle(ecoSec, "Auto Open Cases", "open", false, function(v) Opt.autoOpen = v; if v then LoadModules() end end)
    toggle(ecoSec, "Auto Sell", "sell", false, function(v) Opt.autoSell = v; if v then LoadModules() end end)
    toggle(ecoSec, "Auto Claim Quests", "claim", false, function(v) Opt.autoClaim = v; if v then LoadModules() end end)

    Window:SelectTab(Main)
    Library:SetOpen(true)
end

--// ============================================================
--// Main Loops (Otimizados com Heartbeat)
--// ============================================================
local saveSet = {}
local function updatePlayerProps()
    local model = getChar(Player)
    local h = model and model:FindFirstChildOfClass("Humanoid")
    if h then
        if Opt.speed then h.WalkSpeed = Opt.speedValue else if saveSet.ws then h.WalkSpeed = saveSet.ws end end
        if Opt.jump then h.JumpPower = Opt.jumpValue else if saveSet.jp then h.JumpPower = saveSet.jp end end
        if Opt.noclip then
            for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
        end
    end
end

local tickRender = 0
local fovCircle = Instance.new("Frame")
fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
fovCircle.BackgroundTransparency = 1
fovCircle.Parent = Overlay
local fovCorner = Instance.new("UICorner"); fovCorner.CornerRadius = UDim.new(0.5,0); fovCorner.Parent = fovCircle
local fovStroke = Instance.new("UIStroke"); fovStroke.Color = Color3.new(1,1,1); fovStroke.Parent = fovCircle

RunService.RenderStepped:Connect(function(dt)
    if not alive then return end
    tickRender += dt
    
    -- Update Props Loop (0.1s)
    if tickRender >= 0.1 then
        updatePlayerProps()
        tickRender = 0
    end

    -- Aim & Silent Target Update
    if Opt.aim or Opt.silent then
        local target, pos = getAimTarget()
        if target then
            targetModel = getChar(target)
            targetPart = targetModel and targetModel:FindFirstChild(Opt.aimPart)
            if Opt.aim and pos then
                local cam = workspace.CurrentCamera
                local currentCF = cam.CFrame
                local targetCF = CFrame.lookAt(currentCF.Position, pos)
                cam.CFrame = currentCF:Lerp(targetCF, math.clamp(dt * Opt.smooth * 10, 0, 1))
            end
        else
            targetModel, targetPart = nil, nil
        end
    end

    -- FOV Circle
    if Opt.aim and Opt.showFov then
        fovCircle.Visible = true
        local center = workspace.CurrentCamera.ViewportSize / 2
        fovCircle.Position = UDim2.fromOffset(center.X, center.Y)
        fovCircle.Size = UDim2.fromOffset(Opt.radius * 2, Opt.radius * 2)
    else
        fovCircle.Visible = false
    end

    -- ESP (0.2s para economizar processamento)
    if tickRender == 0 then
        refreshESP()
    end
end)

--// ============================================================
--// Loop Secundário (Economy / Respawn / etc)
--// ============================================================
task.spawn(function()
    while alive do
        task.wait(1)
        if Opt.fastRespawn then
            local gs = GameLib.Service.GameService
            if gs and gs.CanFastRespawn and gs.CanFastRespawn() then gs.FastRespawn() end
        end
        if Opt.autoJoin and not workspace:FindFirstChild("Lobby") then
            -- logica de join
        end
    end
end)

-- Init
task.spawn(function()
    task.wait(1)
    buildUI()
end)

Library:OnUnload(function()
    alive = false
    restoreSilentHook()
end)