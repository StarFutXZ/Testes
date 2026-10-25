-- Sniper Arena — Atlas adapter + Mario Hub feature graft
-- merged build. join our discord server: https://discord.gg/76tHHGBrfz
-- original Atlas adapter by Atlas; features from Mario Hub by xDTaraZ

local Players           = game:GetService("Players")
local RS                = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local UserInputService  = game:GetService("UserInputService")
local VirtualUser       = game:GetService("VirtualUser")
local StarterGui        = game:GetService("StarterGui")
local Lighting          = game:GetService("Lighting")
local HttpService       = game:GetService("HttpService")

local Player = Players.LocalPlayer
local ENV    = (typeof(getgenv) == "function" and getgenv()) or _G
local osClock = os.clock

assert(game.GameId == 9534705677, "This script belongs to Sniper Arena.")

if ENV.ATLAS_SNIPER then ENV.ATLAS_SNIPER.Library:Unload() end

--// ============================================================
--// Library bootstrap (unchanged from your Atlas adapter)
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
        local token = tostring(ENV.ATLAS_TOKEN or "")
        if token ~= "" then url ..= "&token=" .. HttpService:UrlEncode(token) end
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
    assert(source, "Could not download the Atlas hub interface. Run the loader again.")
    local previous = ENV.NOIR_LIB_ONLY
    ENV.NOIR_LIB_ONLY = true
    local ok, result = pcall(function() return assert(loadstring(source, "=NOIR"))() end)
    ENV.NOIR_LIB_ONLY = previous
    assert(ok and type(result) == "table", tostring(result))
    Library = result
end
Library.ScreenGui.Parent = Player.PlayerGui

--// brand patch block omitted: keep the one from your file.
--   (Library.CreateWindow is patched there; we don't duplicate it.)

--// ============================================================
--// Auth gate — your unlock override preserved
--// ============================================================
local atlasAccess = { valid = true, type = "paid", session_token = "atlas_unlocked" }
if not atlasAccess then return end
local keyTier = "paid"

--// ============================================================
--// Resolve (executor capability surface)
--// ============================================================
local function Resolve(...)
    for i = 1, select("#", ...) do
        local c = select(i, ...)
        if type(c) == "function" then return c end
    end
    return nil
end

local Util = {
    Request       = Resolve(request, http_request, syn and syn.request, http and http.request),
    SetClipboard  = Resolve(setclipboard, toclipboard),
    GetHui        = Resolve(gethui, get_hidden_gui),
    GetUpvalue    = Resolve(getupvalue, debug.getupvalue),
    GetUpvalues   = Resolve(getupvalues, debug.getupvalues),
    GetRawMeta    = Resolve(getrawmetatable),
    MouseMove     = Resolve(ENV.mousemoverel, mousemoverel),
    Hook          = Resolve(ENV.hookfunction, hookfunction),
    Restore       = Resolve(ENV.restorefunction, restorefunction),
}

--// ============================================================
--// Faults + Scheduler (from Mario Hub)
--// ============================================================
local Faults = { Streaks = {}, Said = {} }
local FailWindow, MaxFails = 10, 5

local function wanted(toggles)
    for _, k in ipairs(toggles) do if Opt and Opt[k] then return true end end
    return false
end

local function say(name, err)
    local text, now = tostring(err), osClock()
    local last = Faults.Said[name]
    if last and last[1] == text and now - last[2] < FailWindow then return end
    Faults.Said[name] = { text, now }
    warn("[SniperArena] " .. name .. ": " .. text)
end

local function report(name, err, toggles, restore)
    local now = osClock()
    local st = Faults.Streaks[name]
    if not st or (st.Halted and wanted(toggles)) then
        st = { Count = 0, First = now, Warned = false, Halted = false }
        Faults.Streaks[name] = st
    end
    st.Count += 1
    if st.Count == 1 then say(name, err) end
    if st.Warned then return st.Halted end
    if st.Count < MaxFails or now - st.First < FailWindow then return false end
    st.Warned = true
    if #toggles == 0 then warn("[SniperArena] " .. name .. " keeps failing: " .. tostring(err)); return false end
    st.Halted = true
    warn("[SniperArena] " .. name .. " stopped: " .. tostring(err))
    for _, k in ipairs(toggles) do Opt[k] = false end
    if restore then pcall(restore) end
    return true
end

local Scheduler = { Jobs = {}, Booted = false }

function Scheduler.Every(name, interval, fn, toggles, restore)
    Scheduler.Jobs[name] = { Interval = interval, Fn = fn, Last = 0, Running = false,
                             Toggles = toggles or {}, Restore = restore }
end

function Scheduler.Step()
    if not alive then return end
    local now = osClock()
    for name, job in pairs(Scheduler.Jobs) do
        if job.Running then continue end
        if job.Error ~= nil then
            local err = job.Error; job.Error = nil
            job.Halted = report(name, err, job.Toggles, job.Restore)
        end
        if job.Halted then
            if not wanted(job.Toggles) then continue end
            job.Halted = false; Faults.Streaks[name] = nil
        end
        if now - job.Last < job.Interval then continue end
        job.Last = now; job.Running = true
        task.spawn(function()
            local ok, err = pcall(job.Fn)
            job.Error = (not ok) and tostring(err) or false
            job.Running = false
        end)
    end
end

--// ============================================================
--// GameLib: require configs + services (from Mario Hub)
--// ============================================================
local alive, connections, originals, visuals = true, {}, {}, {}
local GameLib = { Config = {}, Service = {}, Missing = {} }

local function requireTimed(module, timeout)
    local done, ok, loaded = false, false, nil
    task.spawn(function()
        ok, loaded = pcall(require, module); done = true
    end)
    local deadline = osClock() + (timeout or 5)
    while not done and osClock() < deadline do task.wait() end
    return done, ok, loaded
end

local function requireChild(parent, name)
    local child = parent and parent:FindFirstChild(name)
    if not (child and child:IsA("ModuleScript")) then child = RS:FindFirstChild(name, true) end
    if not (child and child:IsA("ModuleScript")) then
        GameLib.Missing[name] = "Absent"
        warn("[SniperArena] module " .. name .. " not found")
        return nil
    end
    local done, ok, mod = requireTimed(child, 5)
    if ok then return mod end
    GameLib.Missing[name] = done and tostring(mod) or "timeout"
    warn("[SniperArena] require " .. name .. ": " .. tostring(GameLib.Missing[name]))
    return nil
end

do
    local cfg = RS:FindFirstChild("Config")
    local rem = RS:FindFirstChild("Remote")
    local con = RS:FindFirstChild("Constant")
    local cli = RS:FindFirstChild("Client")

    for _, n in ipairs({ "WeaponConfig", "WrapConfig", "QuestConfig" }) do
        GameLib.Config[n] = requireChild(cfg, n)
    end
    GameLib.RarityColor = requireChild(con, "RarityColor")
    GameLib.Status      = requireChild(con, "Status")

    for _, n in ipairs({ "StatusService", "GachaService", "WeaponService", "QuestService",
                         "EntityService", "CombatService", "GameService" }) do
        GameLib.Service[n] = requireChild(rem, n)
    end
    GameLib.CameraController = requireChild(cli, "CameraController")
    GameLib.WeaponController = requireChild(cli, "WeaponController")
    GameLib.RoomManager      = requireChild(rem and rem:FindFirstChild("GameService"), "RoomManager")
end

--// ============================================================
--// Entity helpers (from Mario Hub)
--// ============================================================
local function TryCall(obj, m)
    if type(obj) ~= "table" and typeof(obj) ~= "Instance" then return nil, false end
    local fn = obj[m]
    if type(fn) ~= "function" then return nil, false end
    local ok, v = pcall(fn, obj)
    return ok and v or nil, ok
end

local function EntityService() return GameLib.Service.EntityService end

local function ListEntities()
    local s = EntityService()
    if not s then return {} end
    local ok, f = pcall(function() return s.WorldManager:GetFocusedEntities() end)
    if not ok or type(f) ~= "table" then return {} end
    return f._items or f.Items or f
end

local function LocalEntity()
    local s = EntityService()
    if not s then return nil end
    local ok, e = pcall(function() return s.GetLocalEntity() end)
    if ok and e then return e end
    ok, e = pcall(function() return s:GetLocalEntity() end)
    return ok and e or nil
end

local function IsLocalEntity(e)
    local v, called = TryCall(e, "IsLocalEntity")
    if called then return v == true end
    return e == LocalEntity()
end

local function EntityTeam(e)
    local inst = e and e.Instance
    if typeof(inst) == "Instance" then
        local t = inst:GetAttribute("Team")
        if t ~= nil then return tostring(t) end
    end
    local c = EntityCharacter(e)
    local t = c and c:GetAttribute("Team")
    return t ~= nil and tostring(t) or nil
end

local function EntityFriendly(e)
    local c = EntityCharacter(e)
    local marks = Workspace:FindFirstChild("Highlight")
    if c and marks then
        local friendly = marks:FindFirstChild("Friendly")
        if friendly and c:IsDescendantOf(friendly) then return true end
        if c:IsDescendantOf(marks) then return false end
    end
    if not InRound() then return false end
    local mine   = EntityTeam(LocalEntity())
    local theirs = EntityTeam(e)
    return mine ~= nil and mine == theirs
end

local function EntityHealth(e)
    if not e then return 0, 0 end
    local h = e.Health or select(1, TryCall(e, "GetHealth")) or 0
    local m = e.MaxHealth or select(1, TryCall(e, "GetMaxHealth")) or 0
    return h, m
end

local function EntityCharacter(e)
    local hum = e and e.Humanoid
    if hum and hum.Parent then return hum.Parent end
    return e and e.Character or nil
end

local function EntityRoot(e)
    local c = EntityCharacter(e)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Head") or c.PrimaryPart
end

--// backwards-compat wrappers so your old refreshESP / chooseTarget still work
local EntityAPI = EntityService()
local function characterOf(p)
    if typeof(p) == "Instance" and p:IsA("Model") then return p end
    if EntityAPI and type(EntityAPI.GetEntity) == "function" then
        local ok, model = pcall(function()
            local e = EntityAPI.GetEntity(p); return e and e:GetModel()
        end)
        if ok and typeof(model) == "Instance" and model:IsA("Model") then return model end
    end
    return p.Character
end
local function healthOf(p, model)
    local h, m = EntityHealth(EntityService() and p)
    if h > 0 or m > 0 then return math.max(0, h), math.max(1, m) end
    local hum = model and model:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health or 0, hum and hum.MaxHealth or 100
end
local function friendly(p, tc)
    if tc == false then return false end
    local e = EntityService() and p
    if e then return EntityFriendly(e) end
    return Player.Team ~= nil and p.Team ~= nil and Player.Team == p.Team
end
local function sameRoom(p)
    local own = Player:GetAttribute("GameRoom") or Player:GetAttribute("World")
    local oth = p:GetAttribute("GameRoom") or p:GetAttribute("World")
    return not (own and oth and own ~= oth)
end
local function InRound()
    return Player:GetAttribute("combatPaused") == false
end

--// ============================================================
--// Match helpers (from Mario Hub)
--// ============================================================
local function MatchInfo()
    local rm = GameLib.RoomManager
    local ok, r = pcall(function() return rm and rm.GetFocusedRoom() end)
    if not ok or type(r) ~= "table" then return nil, nil end
    return r.Mode, r.Map
end
local function MatchModeSet()
    local rm = GameLib.RoomManager
    local ok, r = pcall(function() return rm and rm.GetFocusedRoom() end)
    return ok and type(r) == "table" and r.ModeSet or nil
end

--// ============================================================
--// Player helpers (Anti AFK / Respawn / Join — from Mario Hub)
--// ============================================================
local SelfPlayer = { Character = nil, Humanoid = nil, Root = nil }

local function BindCharacter(char)
    SelfPlayer.Character = char
    SelfPlayer.Humanoid = char:WaitForChild("Humanoid", 10)
    SelfPlayer.Root     = char:WaitForChild("HumanoidRootPart", 10)
end
if Player.Character then BindCharacter(Player.Character) end

Player.CharacterAdded:Connect(function(c)
    task.defer(function() BindCharacter(c) end)
end)

local function IsAlive()
    return SelfPlayer.Humanoid and SelfPlayer.Humanoid.Health > 0
       and SelfPlayer.Root and SelfPlayer.Root.Parent
end

local AntiAfk = { Conn = nil, Status = "Off" }
local function AntiAfkStart()
    Opt.AntiAfk = true
    if not AntiAfk.Conn then
        AntiAfk.Conn = Player.Idled:Connect(function()
            if not Opt.AntiAfk then return end
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.zero)
        end)
    end
    AntiAfk.Status = "Armed"
end
local function AntiAfkStop()
    Opt.AntiAfk = false
    if AntiAfk.Conn then AntiAfk.Conn:Disconnect(); AntiAfk.Conn = nil end
    AntiAfk.Status = "Off"
end

local Respawn = { Fired = false, Count = 0 }
local function RespawnIsDead()
    local s = Player:GetAttribute("State")
    if s == "Dead" or s == "Died" then return true end
    return SelfPlayer.Humanoid and SelfPlayer.Humanoid.Health <= 0
end
local function RespawnFire()
    local gs = GameLib.Service.GameService
    if gs and gs.CanFastRespawn and gs.CanFastRespawn() then gs.FastRespawn(); return end
    local rem = RS:FindFirstChild("Remote")
    local g   = rem and rem:FindFirstChild("GameService")
    local r   = g and g:FindFirstChild("Respawn")
    if r then r:FireServer() end
end
local function RespawnStep()
    if not Opt.FastRespawn then return end
    local gs = GameLib.Service.GameService
    if not (gs and gs.IsJoined and gs.IsJoined()) then return end
    if not RespawnIsDead() then Respawn.Fired = false; return end
    if Respawn.Fired then return end
    Respawn.Fired = true; Respawn.Count += 1; RespawnFire()
end

local Join = { LastTry = 0 }
local function JoinPad()
    local lobby = Workspace:FindFirstChild("Lobby")
    local start = lobby and lobby:FindFirstChild("Start")
    local pad = start and start:FindFirstChild("Touch", true)
    if not (pad and pad:IsA("BasePart")) then return nil end
    for _, l in ipairs(start:GetDescendants()) do
        if l:IsA("TextLabel") and l.Text:find("Touch to Join", 1, true) then return pad end
    end
    return nil
end
local function JoinStep()
    local root = SelfPlayer.Root
    local pad  = JoinPad()
    if not (root and root.Parent and pad) then return end
    if (root.Position - pad.Position).Magnitude > 400 then return end
    if osClock() - Join.LastTry < 3 then return end
    Join.LastTry = osClock()
    firetouchinterest(root, pad, 0); task.wait(0.1); firetouchinterest(root, pad, 1)
end

--// ============================================================
--// ESP (using Mario Hub provider, painted by your Atlas renderer)
--// ============================================================
local Esp = { Rows = {}, Snapshot = {}, Count = 0 }

local function EspKeyOf(e, char)
    local inst = e.Instance
    if typeof(inst) == "Instance" then return inst end
    return char or e
end

local function EspRow(e)
    if type(e) ~= "table" or IsLocalEntity(e) then return nil end
    local char = EntityCharacter(e)
    local h, m = EntityHealth(e)
    if not char or h <= 0 then return nil end
    local plr = Players:GetPlayerFromCharacter(char)
    return {
        Model = char,
        Name  = plr and plr.DisplayName or char.Name,
        Health = h, MaxHealth = m > 0 and m or 100,
        Friendly = EntityFriendly(e),
        Root = EntityRoot(e),
    }
end

local function EspStep()
    local now, seen = osClock(), {}
    for _, e in pairs(ListEntities()) do
        local row = EspRow(e)
        if row then
            local key = EspKeyOf(e, row.Model)
            local held = Esp.Rows[key]
            if not row.Root and held then row.Root = held.Row.Root end
            seen[key] = true
            Esp.Rows[key] = { Row = row, Seen = now }
        end
    end
    for key, held in pairs(Esp.Rows) do
        if not seen[key] then
            local r = held.Row
            local live = r.Model.Parent and r.Root and r.Root.Parent
            if now - held.Seen > 1 or not live then Esp.Rows[key] = nil end
        end
    end
    local snap = {}
    for _, h in pairs(Esp.Rows) do table.insert(snap, h.Row) end
    Esp.Snapshot = snap
    Esp.Count = #snap
end

--// old refreshESP now reads from Esp.Snapshot instead of scanning itself
local function refreshESP()
    if not Opt.esp then
        for pl in pairs(visuals) do destroyVisual(pl) end
        Stats.visible = 0; return
    end
    local cam = workspace.CurrentCamera; if not cam then return end
    local seen, count = {}, 0
    for _, row in ipairs(Esp.Snapshot) do
        local player = Players:GetPlayerFromCharacter(row.Model) or row.Model
        local range = row.Root and (row.Root.Position - cam.CFrame.Position).Magnitude or 0
        if row.Root and range <= Opt.maxDistance then
            seen[player] = true
            local v = visualFor(player, row.Model, row.Root)
            local color = row.Friendly and Color3.fromRGB(82,197,148) or Color3.fromRGB(74,146,255)
            local ratio = math.clamp(row.Health / row.MaxHealth, 0, 1)
            v.text.Text = row.Name .. (Players:GetPlayerFromCharacter(row.Model) and "" or " [BOT]")
            v.text.Visible = Opt.names; v.text.TextSize = Opt.textSize
            v.track.Visible = Opt.health; v.fill.Size = UDim2.fromScale(ratio, 1)
            v.fill.BackgroundColor3 = ratio <= 0.25 and Color3.fromRGB(240,90,102)
                or ratio <= 0.5 and Color3.fromRGB(238,182,73) or Color3.fromRGB(82,197,148)
            v.metrics.Text = tostring(math.floor(range + 0.5)) .. " studs"; v.metrics.Visible = Opt.distance
            v.label.Enabled = Opt.names or Opt.health or Opt.distance
            v.label.AlwaysOnTop = Opt.throughWalls
            if Opt.highlights and count < 24 then
                count += 1
                if not v.highlight then
                    local hl = Instance.new("Highlight"); hl.Name = "AtlasSniperHighlight"; hl.Parent = Overlay; v.highlight = hl
                end
                v.highlight.Adornee = row.Model
                v.highlight.FillColor = color; v.highlight.OutlineColor = color
                v.highlight.FillTransparency = 0.88; v.highlight.OutlineTransparency = 0.12
                v.highlight.DepthMode = Opt.throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            elseif v.highlight then v.highlight:Destroy(); v.highlight = nil end
        end
    end
    Stats.visible = 0; Stats.players = #Players:GetPlayers()
    for pl in pairs(visuals) do
        if not seen[pl] then destroyVisual(pl) else Stats.visible += 1 end
    end
end

--// ============================================================
--// Combat: silent aim sourced from Mario Hub's Combat module
--// (YOUR original chooseTarget/canSee/aimOrigin are kept and re-used)
-- ============================================================
-- Mario Hub silent: patch shooter.LocalShoot and CameraController.GetCFrame
-- We keep your chooseTarget() and only route the result into Mario Hub's shooter.

local CombatSaved  = setmetatable({}, { __mode = "k" })
local LookSaved    = setmetatable({}, { __mode = "k" })
local OriginParams = nil
local lastShot     = 0

local function Shooter()
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
    local start = workspace.CurrentCamera.CFrame.Position
    local aim   = PredictPos(part)
    opts = type(opts) == "table" and opts or {}
    opts.Target = target
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

local SilentChoice = nil

local function SilentShoot(shooter, opts)
    local saved = CombatSaved[shooter]
    if not (Opt.silent and SilentChoice and OriginOverride()) then return saved.Fn(shooter, opts) end
    local bone = math.random(100) <= 100 and "Head" or "Body"
    local model = SilentChoice.model
    local collider = model:FindFirstChild("Collider")
    local part = (collider and collider:FindFirstChild(bone)) or model:FindFirstChild(bone) or model:FindFirstChild("Head")
    if not (part and part.Parent) then return saved.Fn(shooter, opts) end
    local ent = EntityService() and EntityService().GetEntity
    local e = ent and select(2, pcall(ent, model))
    if not e then return saved.Fn(shooter, opts) end
    return ShootAt(shooter, e, part, opts)
end

local function ApplySilent()
    local _, shooter = Shooter()
    if type(shooter) ~= "table" or rawget(shooter, "LocalShoot") == SilentShoot then return end
    if type(shooter.Shoot) ~= "function" then return end
    CombatSaved[shooter] = { Raw = rawget(shooter, "LocalShoot"), Fn = shooter.LocalShoot }
    rawset(shooter, "LocalShoot", SilentShoot)
end

local function RestoreSilent()
    for shooter, s in pairs(CombatSaved) do rawset(shooter, "LocalShoot", s.Raw) end
    table.clear(CombatSaved)
end

-- ReportedLook hook (used by Mario's look-spoof path; we mirror it)
local LookSource, LookHolders
local function ReportedLook(...)
    local look = LookSource(...)
    if typeof(look) ~= "CFrame" or not (Opt.silent and SilentChoice) then return look end
    local part = SilentChoice.part
    if not (part and part.Parent) then return look end
    return CFrame.lookAt(look.Position, PredictPos(part))
end

local function LookTables()
    local cc = GameLib.CameraController
    local list = {}
    if type(cc) ~= "table" then return list end
    if rawget(cc, "GetCFrame") and not table.isfrozen(cc) then list[1] = cc end
    local meta = Util.GetRawMeta and Util.GetRawMeta(cc)
    local idx  = type(meta) == "table" and rawget(meta, "__index")
    if type(idx) == "table" then idx = { idx }
    elseif type(idx) == "function" and Util.GetUpvalues then idx = Util.GetUpvalues(idx) else idx = {} end
    for _, h in pairs(idx) do
        if type(h) == "table" and type(rawget(h, "GetCFrame")) == "function" and not table.isfrozen(h) then
            list[#list + 1] = h
        end
    end
    return list
end

local function ApplyLook()
    if LookSource ~= nil then return end
    local list = LookTables()
    if #list == 0 then LookSource = false; return end
    LookSource = rawget(list[1], "GetCFrame")
    LookHolders = list
    for _, h in ipairs(list) do rawset(h, "GetCFrame", ReportedLook) end
end

local function RestoreLook()
    if not LookSource then LookSource = nil; return end
    for _, h in ipairs(LookHolders or {}) do
        if rawget(h, "GetCFrame") == ReportedLook then rawset(h, "GetCFrame", LookSource) end
    end
    LookSource, LookHolders = nil, nil
end

-- full silent step: pick a target from your chooseTarget, keep it in SilentChoice
local silentTarget, silentPart
local function SilentStep()
    if not Opt.silent then
        if next(CombatSaved) then RestoreSilent() end
        RestoreLook()
        return
    end
    ApplySilent(); ApplyLook()
    if not InRound() then SilentChoice = nil; return end
    local t, pos, part = chooseTarget(Opt, true)
    if t and part then
        local model = characterOf(t)
        SilentChoice = { model = model, part = part, position = pos }
    else
        SilentChoice = nil
    end
end

-- ragebot / triggerbot fire path (uses Mario Hub Fire)
local function Fire()
    local now = osClock()
    if now - lastShot < 0.12 then return false end
    lastShot = now
    local _, shooter = Shooter()
    if not shooter then return false end
    local ok, fired = pcall(shooter.LocalShoot, shooter)
    if not ok then warn("[SniperArena] shoot:", fired) end
    return ok and fired ~= nil
end

--// ============================================================
--// Skin changer (from Mario Hub, pruned to what we need)
--// ============================================================
local Skin = {
    Catalog = {}, Rarities = {}, Chosen = {},
    Saved = setmetatable({}, { __mode = "k" }), Status = "Off",
    RarityRank = { Common = 1, UnCommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mystic = 6 },
    Hidden = { Charm = true },
}

local function SkinClassify(cfg)
    if type(cfg) ~= "table" then return nil end
    local ok, kind, fam = pcall(function() return cfg.WeaponType, cfg.Family end)
    if not ok or type(kind) ~= "string" or type(fam) ~= "string" then return nil end
    if Skin.Hidden[kind] or fam:find("^Base") then return nil end
    return kind, fam
end

do
    for key, cfg in pairs(GameLib.Config.WeaponConfig or {}) do
        if type(key) ~= "string" then continue end
        local kind, fam = SkinClassify(cfg)
        if kind then
            Skin.Catalog[kind] = Skin.Catalog[kind] or {}
            Skin.Catalog[kind][fam] = Skin.Catalog[kind][fam] or {}
            table.insert(Skin.Catalog[kind][fam], key)
        end
    end
end

local function SkinCarried()
    local c = GameLib.Service.CombatService
    local ok, list = pcall(function() return c.GetWeapons() end)
    local out = {}
    if ok and type(list) == "table" then
        for _, w in pairs(list) do if type(w) == "table" and w.Name then out[#out+1] = w end end
    end
    local held = c and c.GetCurrentWeapon()
    if held and not table.find(out, held) then out[#out+1] = held end
    return out
end

local function SkinApply(weapon, key)
    local cfg = GameLib.Config.WeaponConfig[key]
    if not cfg then return end
    if not Skin.Saved[weapon] then Skin.Saved[weapon] = { weapon.Name, weapon.Config } end
    weapon.Name, weapon.Config = key, cfg
    local wc = GameLib.WeaponController
    local ent = GameLib.Service.EntityService.LocalEntity
    if wc and ent and weapon.Controller then
        weapon.Controller:Destroy()
        wc.Create(ent, weapon)
    end
end

local function SkinRevert(weapon)
    local s = Skin.Saved[weapon]; if not s then return end
    weapon.Name, weapon.Config = s[1], s[2]
    Skin.Saved[weapon] = nil
    local wc = GameLib.WeaponController
    local ent = GameLib.Service.EntityService.LocalEntity
    if wc and ent and weapon.Controller then
        weapon.Controller:Destroy(); wc.Create(ent, weapon)
    end
end

local function SkinStep()
    if not Opt.skinChanger then
        if next(Skin.Saved) then for w in pairs(Skin.Saved) do SkinRevert(w) end end
        Skin.Status = "Off"; return
    end
    local n = 0
    for _, w in ipairs(SkinCarried()) do
        local saved = Skin.Saved[w]
        local cfg = saved and saved[2] or w.Config
        local _, fam = SkinClassify(cfg)
        local key = fam and Skin.Chosen[fam]
        if key then
            if w.Name ~= key then SkinApply(w, key) end
            n += 1
        elseif saved then SkinRevert(w) end
    end
    Skin.Status = n > 0 and (n .. " skinned") or "Pick a skin"
end

--// ============================================================
--// Economy: cases / sell / quests (from Mario Hub)
--// ============================================================
local Shop = { Status = "Off" }
local function ShopCases()
    local g = GameLib.Service.GachaService
    local st = g and g.LocalGachaStore
    local d = st and st.Data
    if type(d) ~= "table" then return {} end
    local k = {}
    for key, ent in pairs(d) do
        local owned = type(ent) == "table" and ent.Owned or ent
        if tonumber(owned) and owned > 0 then k[#k+1] = tostring(key) end
    end
    table.sort(k); return k
end
local function ShopOwned(k)
    local g = GameLib.Service.GachaService
    if not g then return 0 end
    local ok, n = pcall(function() return g.GetGachaCount(k) end)
    return ok and tonumber(n) or 0
end
local function ShopOpen(k, n)
    local g = GameLib.Service.GachaService
    if not g then return 0 end
    local before = ShopOwned(k)
    n = math.min(n, before)
    if n < 1 then return 0 end
    local ok, err = pcall(function() return g.Gacha(k, n) end)
    if not ok then warn("[SniperArena] open "..k..": "..tostring(err)); return 0 end
    task.wait(1)
    return math.max(before - ShopOwned(k), 0)
end
local function ShopStep()
    if not Opt.autoOpen then Shop.Status = "Off"; return end
    local n = 0
    for _, k in ipairs(ShopCases()) do
        local owned = ShopOwned(k)
        if owned > 0 then n += ShopOpen(k, math.min(owned, Opt.openCount or 1)); task.wait(0.6) end
    end
    Shop.Status = n > 0 and (n .. " opened") or "none"
end

local Sell = { Status = "Off" }
local function SellRarityOf(name)
    local skin = tostring(name):match("%.(.+)$")
    local w = skin and type(GameLib.Config.WrapConfig) == "table" and GameLib.Config.WrapConfig[skin]
    return type(w) == "table" and w.Rarity or nil
end
local function SellRarities()
    local seen = {}
    for _, e in pairs(GameLib.Config.WrapConfig or {}) do
        if type(e) == "table" and e.Rarity then seen[tostring(e.Rarity)] = true end
    end
    local out = {}
    for k in pairs(seen) do out[#out+1] = k end
    table.sort(out); return out
end
local function SellStep()
    if not Opt.autoSell then Sell.Status = "Off"; return end
    local ws = GameLib.Service.WeaponService
    if not ws then return end
    local ok, content = pcall(function() return ws.GetContent() end)
    if not ok or type(content) ~= "table" then return end
    local uids, n = {}, 0
    for uid, w in pairs(content) do
        if type(w) == "table" then
            local r = SellRarityOf(w.Name or "")
            if r and not table.find(Opt.sellKeepRarities or {}, r) and (tonumber(w.Price) or 0) <= (Opt.maxSellPrice or 500) then
                uids[#uids+1] = uid; n += 1
            end
        end
    end
    if n == 0 then Sell.Status = "nothing to sell"; return end
    local ok2, err = pcall(function() return ws.Sell(uids) end)
    Sell.Status = ok2 and (n .. " sold") or ("fail: " .. tostring(err))
end

local Collect = { Status = "Off" }
local function CollectStep()
    if not Opt.autoClaim then Collect.Status = "Off"; return end
    local q = GameLib.Service.QuestService
    local qc = GameLib.Config.QuestConfig
    if not (q and type(qc) == "table") then return end
    local n = 0
    for id in pairs(qc) do
        local ok1, done = pcall(function() return q.IsFinished(id) end)
        local ok2, claimed = pcall(function() return q.IsClaimed(id) end)
        if ok1 and done and ok2 and not claimed then
            if pcall(function() return q.ClaimReward(id) end) then n += 1 end
            task.wait(0.5)
        end
    end
    Collect.Status = n > 0 and (n .. " claimed") or "none"
end

--// ============================================================
--// Options — union of your Opt and Mario Hub's keys
--// ============================================================
Opt = {
    -- your Atlas aim
    aim = false, silent = false, showFov = false, noDelay = false,
    aimBots = false, espBots = true, hold = true, teamCheck = true, wallCheck = true,
    aimPart = "Head", radius = 220, smooth = 3, prediction = 60,
    -- ESP
    esp = false, names = true, distance = true, health = true, highlights = true,
    throughWalls = true, maxDistance = 1500, textSize = 13,
    -- Movement / view
    speed = false, speedValue = 24, jump = false, jumpValue = 60,
    fov = false, fovValue = 85, bright = false, infiniteJump = false, noclip = false, noFog = false,
    -- new (Mario Hub)
    antiAfk = false, fastRespawn = false, autoJoin = false, infiniteDash = false,
    skinChanger = false, autoOpen = false, openCount = 1,
    autoSell = false, maxSellPrice = 500, sellKeepRarities = {},
    autoClaim = false,
    ragebot = false, triggerbot = false, noRecoil = false, noSpread = false, instantScope = false,
}
Stats = { errors = 0, players = 0, visible = 0, target = nil, lastError = nil }

--// ============================================================
--// Overlay + UI wiring (keep your existing tabs; add new ones)
--// ============================================================
-- Everything below is unchanged from your file EXCEPT the tab builders.
-- We append new sections to your existing tabs.

Library:OnUnload(function() alive = false end)

local Window = Library:CreateWindow({Title = "Eclipse", Subtitle = "Sniper Arena + Mario Hub", Logo = "peak"})
local Main     = Window:Tab({Name = "Main",     Icon = "crosshair", Description = "Aim and shot pipeline."})
local ESPTab   = Window:Tab({Name = "ESP",      Icon = "eye",       Description = "Visibility."})
local PlayerTab= Window:Tab({Name = "Player",   Icon = "user-round", Description = "Movement, respawn, anti-afk."})
local SkinsTab = Window:Tab({Name = "Skins",    Icon = "star",       Description = "Per-weapon skins."})
local EcoTab   = Window:Tab({Name = "Economy",  Icon = "coin",       Description = "Cases, selling, quests."})
local Config   = Window:Tab({Name = "Config",   Icon = "settings",   Description = "Save your preferences."})

-- keep your existing UI builders below...
-- (toggle(...) calls for aim/ESP/movement stay exactly as they were)

-- NEW: Rage / Silent extra options
local rage = Main:Section({Name = "Rage / Silent", Icon = "bomb", Side = "Right"})
rage:Toggle({Name = "Ragebot", Flag = "sniper_ragebot", Callback = function(v) Opt.ragebot = v end})
rage:Toggle({Name = "Trigger bot", Flag = "sniper_trigger", Callback = function(v) Opt.triggerbot = v end})
rage:Toggle({Name = "Fast scope",  Flag = "sniper_scope",  Callback = function(v) Opt.instantScope = v end})
rage:Toggle({Name = "No recoil",   Flag = "sniper_recoil", Callback = function(v) Opt.noRecoil = v end})
rage:Toggle({Name = "No spread",   Flag = "sniper_spread", Callback = function(v) Opt.noSpread = v end})
rage:Slider({Name = "Prediction (ms)", Flag = "sniper_pred", Min = 0, Max = 200, Default = 60, Increment = 1,
              Callback = function(v) Opt.prediction = v end})

-- NEW: Player tab additions
local utilTab = PlayerTab:Section({Name = "Utility", Icon = "gear", Side = "Left"})
utilTab:Toggle({Name = "Fast respawn", Flag = "sniper_fastrespawn", Callback = function(v) Opt.fastRespawn = v end})
utilTab:Toggle({Name = "Auto join round", Flag = "sniper_autojoin", Callback = function(v) Opt.autoJoin = v end})
utilTab:Toggle({Name = "Anti AFK", Flag = "sniper_antiafk", Callback = function(v)
    Opt.antiAfk = v
    if v then AntiAfkStart() else AntiAfkStop() end
end})
local moveTab = PlayerTab:Section({Name = "Movement+", Icon = "zap", Side = "Right"})
moveTab:Toggle({Name = "Infinite dash", Flag = "sniper_dash", Callback = function(v) Opt.infiniteDash = v end})

-- NEW: Skins tab
local skinSec = SkinsTab:Section({Name = "Skin changer", Icon = "star", Side = "Left"})
skinSec:Toggle({Name = "Enable", Flag = "sniper_skin", Callback = function(v) Opt.skinChanger = v end})
local skinRarities = {}
for k in pairs(GameLib.Config.WeaponConfig or {}) do
    local cfg = GameLib.Config.WeaponConfig[k]
    local _, fam = SkinClassify(cfg)
    if fam and not skinRarities[fam] then skinRarities[fam] = {} end
    if fam then table.insert(skinRarities[fam], k) end
end
for fam, list in pairs(skinRarities) do
    skinSec:Dropdown({Name = fam, Flag = "sniper_skin_"..fam, Options = list,
        Callback = function(v) Skin.Chosen[fam] = v end})
end

-- NEW: Economy tab
local caseSec = EcoTab:Section({Name = "Cases", Icon = "qblock", Side = "Left"})
caseSec:Toggle({Name = "Auto open owned", Flag = "sniper_autoopen", Callback = function(v) Opt.autoOpen = v end})
caseSec:Slider({Name = "Open per case", Flag = "sniper_opencount", Min = 1, Max = 10, Default = 1,
                Callback = function(v) Opt.openCount = v end})
local sellSec = EcoTab:Section({Name = "Sell", Icon = "shop", Side = "Right"})
sellSec:Toggle({Name = "Auto sell", Flag = "sniper_autosell", Callback = function(v) Opt.autoSell = v end})
sellSec:Slider({Name = "Max price", Flag = "sniper_maxprice", Min = 0, Max = 100000, Default = 500,
                Callback = function(v) Opt.maxSellPrice = v end})
local questSec = EcoTab:Section({Name = "Quests", Icon = "key", Side = "Left"})
questSec:Toggle({Name = "Auto claim", Flag = "sniper_autoquest", Callback = function(v) Opt.autoClaim = v end})

Library:AddConfigSections(Config, {Scope = "SniperArena"})

--// ============================================================
--// Boot scheduler jobs
--// ============================================================
Scheduler.Every("Combat",       0.03, SilentStep)
Scheduler.Every("ESP",          0.15, EspStep)
Scheduler.Every("Fast respawn", 0.10, RespawnStep, {"fastRespawn"})
Scheduler.Every("Auto join",    1.00, JoinStep,    {"autoJoin"})
Scheduler.Every("Skin",         0.50, SkinStep,    {"skinChanger"})
Scheduler.Every("Cases",        1.00, ShopStep,    {"autoOpen"})
Scheduler.Every("Sell",         1.00, SellStep,    {"autoSell"})
Scheduler.Every("Quests",       1.00, CollectStep, {"autoClaim"})

Scheduler.Booted = true
RunService.Heartbeat:Connect(Scheduler.Step)

-- keep your existing RenderStepped aim + drawFOV pipeline; it runs in parallel
-- (your old chooseTarget / aimOrigin / canSee are still the aim brain)

Window:SelectTab(Main); Library:SetOpen(true)

ENV.ATLAS_SNIPER = {
    Library = Library, Window = Window, Options = Opt, Stats = Stats,
    Stop = function() alive = false; RestoreSilent(); RestoreLook() end,
}
return { ready = true, game = "Sniper Arena", tabs = #Window.Tabs, keyRequired = true, tier = keyTier }