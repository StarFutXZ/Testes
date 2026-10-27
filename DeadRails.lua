if getgenv().DaraHubExecuted then
    NotifyToast({
        title = "WARNING!",
        content = "Script Is Already Loaded, rejoin if you want to re-execute.",
        duration = 8,
        icon = "triangle-exclamation",
        iconColor = "#FFFF00",
    })
    return
end
getgenv().DaraHubExecuted = true

local BaseURL = "https://darahub.pages.dev"
WindUI = loadstring(game:HttpGet(BaseURL .. "/Module/Library/GUI/WindUI-Moded/main.lua"))()
loadstring(game:HttpGet(BaseURL .. "/Module/Library/GUI/LoadAll.lua"))()

Window = WindUI:CreateWindow({
    Title = "Darahub | Dead Rail (Game)",
    Icon = BaseURL .. "/icon.png",
    Author = "Made By Pnsdg",
    Folder = "Darahub/DeadRail-Game",
    Size = UDim2.fromOffset(580, 490),
    Theme = "Dark",
    HidePanelBackground = false,
    NewElements = true,
    Acrylic = false,
    HideSearchBar = false,
    SideBarWidth = 200,
    OpenButton = { ShowIconOnly = true },
})
WindUI.TransparencyValue = 0.7
Window:ToggleTransparency(true)
Window:DisableTopbarButtons({ "Fullscreen" })
executor = identifyexecutor()
if type(executor) == "string" then
    Window:Tag({ Title = executor })
end
Window:Tag({ Title = "v1" })

Tabs = {
    Main = Window:Tab({ Title = "Main", Icon = "layout-grid" }),
    Player = Window:Tab({ Title = "Player", Icon = "user" }),
    Visuals = Window:Tab({ Title = "Visuals", Icon = "camera" }),
    ESP = Window:Tab({ Title = "ESP", Icon = "eye" }),
    Combat = Window:Tab({ Title = "Combat", Icon = "swords" }),
    Misc = Window:Tab({ Title = "Misc", Icon = "wrench" }),
    Teleport = Window:Tab({ Title = "Teleport", Icon = "navigation" }),
    Settings = Window:Tab({ Title = "Settings", Icon = "settings" }),
    info = Window:Tab({ Title = "info", Icon = "info" }),
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Character
local Humanoid
local HumanoidRootPart

local function setupCharacter(character)
    Character = character
    Humanoid = character:FindFirstChildOfClass("Humanoid")
    HumanoidRootPart = character:FindFirstChild("HumanoidRootPart")
end

if LocalPlayer.Character then
    setupCharacter(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(setupCharacter)

function RunEvery(interval, fn)
    local acc, busy = 0, false
    return RunService.Heartbeat:Connect(function(dt)
        if busy then
            return
        end
        acc += dt
        local wait = type(interval) == "function" and interval() or interval
        if acc < wait then
            return
        end
        acc = 0
        busy = true
        pcall(fn)
        busy = false
    end)
end

socialsModule = loadstring(game:HttpGet(BaseURL .. "/Module/info.lua"))()
socialsModule(Tabs)

local jobId, placeId, StartTime = game.JobId, game.PlaceId, tick()
local EngineTargetMegaBytes = 3000
local FrameCount, LastTime, CurrentFPS = 0, tick(), 0
RunService.RenderStepped:Connect(function()
    FrameCount += 1
    local now = tick()
    if now - LastTime >= 1 then
        CurrentFPS = FrameCount
        FrameCount = 0
        LastTime = now
    end
end)

local function loadECS()
    local ok, result = pcall(function()
        local universe = ReplicatedStorage.Shared.Universe
        return {
            world = require(universe.ECS.world),
            comps = require(universe.ECS.components),
            replicator = require(ReplicatedStorage.Client.Universe.Replication.clientReplicator),
            remotes = require(universe.Remotes),
            actionable = universe.Network.RemoteEvent.Actionable,
            pickup = universe.Network.RemoteEvent.Pickup,
        }
    end)
    if not ok then
        return nil
    end
    local shopOk, shopFn = pcall(function()
        return require(ReplicatedStorage.Shared.Game.Shop.isShopItem)
    end)
    result.isShopItem = shopOk and shopFn or function()
        return false
    end
    return result
end

local ECS = loadECS()
local function ecsGet(id, comp)
    if not ECS then
        return nil
    end
    local ok, v = pcall(ECS.world.get, ECS.world, id, comp)
    return ok and v or nil
end
local function ecsHas(id, comp)
    if not ECS then
        return false
    end
    local ok, v = pcall(ECS.world.has, ECS.world, id, comp)
    return ok and v or false
end
local function ecsMyPosition()
    if not ECS then
        return nil
    end
    local state = ECS.world:get_resource(ECS.comps.ClientStateResource)
    local char = state and state.localCharacter
    if not char then
        return nil
    end
    local t = ecsGet(char, ECS.comps.Transform)
    if not t then
        return nil
    end
    return t.Position or t.p
end

function convertToDetailedTime(S, ms)
    local y = math.floor(S / 31536000)
    S %= 31536000
    local mo = math.floor(S / 2592000)
    S %= 2592000
    local w = math.floor(S / 604800)
    S %= 604800
    local d = math.floor(S / 86400)
    S %= 86400
    local h = math.floor(S / 3600)
    S %= 3600
    local m = math.floor(S / 60)
    local s = S % 60
    return { Years = y, Months = mo, Weeks = w, Days = d, Hours = h, Minutes = m, Seconds = s, Milliseconds = ms or 0 }
end
function GetServerUptimeString()
    local t = time()
    local ms = math.floor((t - math.floor(t)) * 1000)
    local u = convertToDetailedTime(math.floor(t), ms)
    return string.format(
        "<font color='#FFD700'>%dY</font> <font color='#FFA500'>%dMth</font> <font color='#FF8C00'>%dW</font> <font color='#32CD32'>%dD</font> <font color='#00CED1'>%dH</font> <font color='#1E90FF'>%dMin</font> <font color='#9370DB'>%dSec</font> <font color='#FF69B4'>%dMS</font>",
        u.Years,
        u.Months,
        u.Weeks,
        u.Days,
        u.Hours,
        u.Minutes,
        u.Seconds,
        u.Milliseconds
    )
end
function GetLastJoinedString()
    local c = os.time()
    local j = c - math.floor(time())
    local jt = os.date("*t", j)
    local ap = jt.hour >= 12 and "PM" or "AM"
    local h12 = jt.hour % 12
    if h12 == 0 then
        h12 = 12
    end
    local ms = math.floor((time() - math.floor(time())) * 1000)
    local mn = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
    return string.format(
        "<font color='#87CEEB'>%02d:%02d:%02d.%03d %s</font> - <font color='#98FB98'>%s %d, %d</font>",
        h12,
        jt.min,
        jt.sec,
        ms,
        ap,
        mn[jt.month],
        jt.day,
        jt.year
    )
end
function GetScriptRuntime()
    local e = tick() - StartTime
    local ms = math.floor((e - math.floor(e)) * 1000)
    local r = convertToDetailedTime(math.floor(e), ms)
    return string.format(
        "<font color='#FFD700'>%dY</font> <font color='#FFA500'>%dMth</font> <font color='#FF8C00'>%dW</font> <font color='#32CD32'>%dD</font> <font color='#00CED1'>%dH</font> <font color='#1E90FF'>%dMin</font> <font color='#9370DB'>%dSec</font> <font color='#FF69B4'>%dMS</font>",
        r.Years,
        r.Months,
        r.Weeks,
        r.Days,
        r.Hours,
        r.Minutes,
        r.Seconds,
        r.Milliseconds
    )
end
function GetExecutedSince()
    return string.format("<font color='#87CEEB'>%s</font>", os.date("%I:%M:%S %p", StartTime))
end
function GetOSClock()
    local n = os.date("*t")
    local ap = n.hour >= 12 and "PM" or "AM"
    local h12 = n.hour % 12
    if h12 == 0 then
        h12 = 12
    end
    return string.format("<font color='#FFD700'>%02d:%02d:%02d %s</font>", h12, n.min, n.sec, ap)
end
function GetCalendarDate()
    local n = os.date("*t")
    local mn = {
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December",
    }
    local sf = "th"
    if n.day == 1 or n.day == 21 or n.day == 31 then
        sf = "st"
    elseif n.day == 2 or n.day == 22 then
        sf = "nd"
    elseif n.day == 3 or n.day == 23 then
        sf = "rd"
    end
    return string.format("<font color='#98FB98'>%s %d%s, %d</font>", mn[n.month], n.day, sf, n.year)
end
function GetGPUInfo()
    local v = string.format("%.2f", Stats.RenderGPUFrameTime * 1000)
    local c = tonumber(v) < 10 and "#32CD32" or (tonumber(v) < 30 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%s ms</font>", c, v)
end
function GetCPUInfo()
    local v = string.format("%.2f", Stats.RenderCPUFrameTime * 1000)
    local c = tonumber(v) < 10 and "#32CD32" or (tonumber(v) < 30 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%s ms</font>", c, v)
end
function GetRAMInfo()
    local r = Stats:GetTotalMemoryUsageMb()
    local p = math.floor((r / EngineTargetMegaBytes) * 100)
    local c = p < 50 and "#32CD32" or (p < 80 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%.2f MB / %d MB (%d%%)</font>", c, r, EngineTargetMegaBytes, p)
end
function GetNetworkSent()
    local s = Stats.DataSendKbps
    local c = s < 100 and "#32CD32" or (s < 500 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%.2f KB/s</font>", c, s)
end
function GetNetworkReceived()
    local s = Stats.DataReceiveKbps
    local c = s < 100 and "#32CD32" or (s < 500 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%.2f KB/s</font>", c, s)
end
function GetPing()
    local p = math.clamp(Stats.Network.ServerStatsItem["Data Ping"]:GetValue(), 10, 700)
    local c = p < 100 and "#32CD32" or (p < 200 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%d ms</font>", c, math.floor(p))
end
function GetFPS()
    local c = CurrentFPS >= 60 and "#32CD32" or (CurrentFPS >= 30 and "#FFD700" or "#FF6666")
    return string.format("<font color='%s'>%d fps</font>", c, CurrentFPS)
end

local TotalFriends, OnlineFriends, OfflineFriends = 0, 0, 0
function UpdateFriendData()
    pcall(function()
        local total, online = 0, 0
        local list = Players:GetFriendsAsync(LocalPlayer.UserId)
        for _ = 1, 200 do
            for _ in list:GetCurrentPage() do
                total += 1
            end
            if list.IsFinished then
                break
            end
            list:AdvanceToNextPageAsync()
        end
        for _ in pairs(LocalPlayer:GetFriendsOnline()) do
            online += 1
        end
        TotalFriends, OnlineFriends, OfflineFriends = total, online, total - online
    end)
end
Tabs.Main:Section({ Title = "FE Bypass", TextSize = 20 })
Tabs.Main:Button({
    Title = "Load ServerSide ExecutionorNadol",
    Callback = function()
        loadstring(game:HttpGet("https://darahub.pages.dev/MrRobot/loader.lua"))()
    end,
})
Tabs.Main:Section({ Title = "Server Information", TextSize = 20 })
Tabs.Main:Divider()
ServerInfoParagraph = Tabs.Main:Paragraph({ Title = "In Server For", Desc = GetServerUptimeString() })
RunEvery(0, function()
    ServerInfoParagraph:SetDesc(GetServerUptimeString())
end)
Tabs.Main:Paragraph({ Title = "Joinned Started", Desc = GetLastJoinedString() })
local placeName = "Unknown"
pcall(function()
    local p = MarketplaceService:GetProductInfo(placeId)
    if p and p.Name then
        placeName = p.Name
    end
end)
Tabs.Main:Paragraph({ Title = "Game", Desc = placeName })
local maxPlayers = Players.MaxPlayers
CurrentPlayersParagraph =
    Tabs.Main:Paragraph({ Title = "Current Players", Desc = #Players:GetPlayers() .. " / " .. maxPlayers })
RunEvery(1, function()
    CurrentPlayersParagraph:SetDesc(#Players:GetPlayers() .. " / " .. maxPlayers)
end)
Tabs.Main:Paragraph({ Title = "Server ID", Desc = string.sub(jobId, 1, 30) .. "..." })
Tabs.Main:Space()
Tabs.Main:Section({ Title = "Client Information", TextSize = 20 })
Tabs.Main:Divider()
ScriptRuntimeParagraph = Tabs.Main:Paragraph({ Title = "Script Running For", Desc = GetScriptRuntime() })
RunEvery(0, function()
    ScriptRuntimeParagraph:SetDesc(GetScriptRuntime())
end)
Tabs.Main:Paragraph({ Title = "Executed Since", Desc = GetExecutedSince() })
Tabs.Main:Space()
Tabs.Main:Section({ Title = "System Information", TextSize = 20 })
Tabs.Main:Divider()
OSClockParagraph = Tabs.Main:Paragraph({ Title = "OS Clock", Desc = GetOSClock() })
RunEvery(0, function()
    OSClockParagraph:SetDesc(GetOSClock())
end)
CalendarParagraph = Tabs.Main:Paragraph({ Title = "Calendar", Desc = GetCalendarDate() })
RunEvery(60, function()
    CalendarParagraph:SetDesc(GetCalendarDate())
end)
GPUParagraph = Tabs.Main:Paragraph({ Title = "GPU", Desc = GetGPUInfo() })
CPUParagraph = Tabs.Main:Paragraph({ Title = "CPU", Desc = GetCPUInfo() })
RAMParagraph = Tabs.Main:Paragraph({ Title = "RAM", Desc = GetRAMInfo() })
SentParagraph = Tabs.Main:Paragraph({ Title = "Sent", Desc = GetNetworkSent() })
ReceivedParagraph = Tabs.Main:Paragraph({ Title = "Received", Desc = GetNetworkReceived() })
PingParagraph = Tabs.Main:Paragraph({ Title = "Ping", Desc = GetPing() })
FPSParagraph = Tabs.Main:Paragraph({ Title = "FPS", Desc = GetFPS() })
RunEvery(0.2, function()
    GPUParagraph:SetDesc(GetGPUInfo())
    CPUParagraph:SetDesc(GetCPUInfo())
    RAMParagraph:SetDesc(GetRAMInfo())
    SentParagraph:SetDesc(GetNetworkSent())
    ReceivedParagraph:SetDesc(GetNetworkReceived())
    PingParagraph:SetDesc(GetPing())
    FPSParagraph:SetDesc(GetFPS())
end)
Tabs.Main:Space()
Tabs.Main:Section({ Title = "Player Information", TextSize = 20 })
Tabs.Main:Divider()
Tabs.Main:Paragraph({ Title = "Username", Desc = LocalPlayer.Name })
Tabs.Main:Paragraph({ Title = "Display Name", Desc = LocalPlayer.DisplayName })
Tabs.Main:Paragraph({ Title = "User ID", Desc = tostring(LocalPlayer.UserId) })
local accStr = "Unknown"
pcall(function()
    local a = LocalPlayer.AccountAge
    if a then
        accStr = os.date("%B %d, %Y", os.time() - a * 86400)
    end
end)
Tabs.Main:Paragraph({ Title = "Account Created", Desc = accStr })
Tabs.Main:Space()
Tabs.Main:Section({ Title = "Friends Data", TextSize = 20 })
Tabs.Main:Divider()
FriendsOnlineParagraph = Tabs.Main:Paragraph({ Title = "Online Friends", Desc = "0" })
FriendsOfflineParagraph = Tabs.Main:Paragraph({ Title = "Offline Friends", Desc = "0" })
FriendsTotalParagraph = Tabs.Main:Paragraph({ Title = "Total Friends", Desc = "0" })
local function refreshFriendParagraphs()
    UpdateFriendData()
    FriendsOnlineParagraph:SetDesc(tostring(OnlineFriends))
    FriendsOfflineParagraph:SetDesc(tostring(OfflineFriends))
    FriendsTotalParagraph:SetDesc(tostring(TotalFriends))
end
task.spawn(function()
    pcall(refreshFriendParagraphs)
end)
RunEvery(30, refreshFriendParagraphs)
Tabs.Main:Space()
Tabs.Main:Section({ Title = "Server Tools", TextSize = 20 })
Tabs.Main:Divider()
Tabs.Main:Button({
    Title = "Advanced Server Hop",
    Icon = "server",
    Callback = function()
        pcall(function()
            loadstring(game:HttpGet("https://darahub.pages.dev/raw-script/Tools/Advanced%20Server%20Hop.lua"))()
        end)
        WindUI:Notify({ Title = "Success", Content = "Advanced Server Hop Loaded", Duration = 3 })
    end,
})
Tabs.Main:Space()
Tabs.Main:Section({ Title = "Party", TextSize = 20 })
Tabs.Main:Divider()
do
    local PARTY_CACHE_FOLDERS = { "Darahub", "Darahub/Cache", "Darahub/Cache/DeadRail" }
    local PARTY_CACHE_FILE = "Darahub/Cache/DeadRail/LastPartyID.txt"
    local LOBBY_PLACE_ID = 116495829188952

    local function readPartyId()
        local ok, label = pcall(function()
            return LocalPlayer.PlayerGui.TopbarStandard.Holders.Left.Widget.IconButton.Menu.IconSpot.Contents.IconLabelContainer.IconLabel
        end)
        if not ok or not label then
            return nil
        end
        local id = label.Text:match("Party Id:%s*(.+)")
        return id and id:gsub("%s+$", "") or nil
    end

    Tabs.Main:Button({
        Title = "Rejoin Party",
        Desc = "Saves your party ID and goes back to the lobby, then rejoins the same party (needs 2+ players)",
        Icon = "door-open",
        Callback = function()
            if #Players:GetPlayers() <= 1 then
                task.spawn(error, "required 2 player", 0)
                WindUI:Notify({ Title = "Rejoin Party", Content = "Required 2 players", Duration = 3 })
                return
            end
            if not (writefile and makefolder) then
                WindUI:Notify({ Title = "Rejoin Party", Content = "Your executor does not support files", Duration = 3 })
                return
            end
            local partyId = readPartyId()
            if not partyId or partyId == "" then
                WindUI:Notify({ Title = "Rejoin Party", Content = "Party ID not found", Duration = 3 })
                return
            end
            for _, f in ipairs(PARTY_CACHE_FOLDERS) do
                pcall(makefolder, f)
            end
            if not pcall(writefile, PARTY_CACHE_FILE, partyId) then
                WindUI:Notify({ Title = "Rejoin Party", Content = "Could not save the party ID", Duration = 3 })
                return
            end
            WindUI:Notify({ Title = "Rejoin Party", Content = "Saved party " .. partyId .. ", going to lobby", Duration = 3 })
            game:GetService("TeleportService"):Teleport(LOBBY_PLACE_ID, LocalPlayer)
        end,
    })
    Tabs.Main:Space()
end

Tabs.Player:Section({ Title = "Movement", TextSize = 20 })
Tabs.Player:Divider()
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local doubleJumpAvailable, doubleJumpGroundedAt = true, 0
local doubleJumpRequestConnection, doubleJumpGroundConnection
local function stopDoubleJump()
    if doubleJumpRequestConnection then
        doubleJumpRequestConnection:Disconnect()
        doubleJumpRequestConnection = nil
    end
    if doubleJumpGroundConnection then
        doubleJumpGroundConnection:Disconnect()
        doubleJumpGroundConnection = nil
    end
end
local function startDoubleJump()
    stopDoubleJump()
    doubleJumpAvailable = true
    doubleJumpGroundedAt = tick()
    doubleJumpGroundConnection = RunService.Heartbeat:Connect(function()
        if Humanoid and Humanoid.FloorMaterial ~= Enum.Material.Air then
            doubleJumpAvailable = true
            doubleJumpGroundedAt = tick()
        end
    end)
    doubleJumpRequestConnection = UserInputService.JumpRequest:Connect(function()
        if
            Humanoid
            and doubleJumpAvailable
            and Humanoid.FloorMaterial == Enum.Material.Air
            and tick() - doubleJumpGroundedAt > 0.2
        then
            doubleJumpAvailable = false
            Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end
DoubleJumpToggle = Tabs.Player:Toggle({
    Title = "Double Jump",
    Flag = "DoubleJumpToggle",
    Value = false,
    Callback = function(s)
        if s then
            startDoubleJump()
        else
            stopDoubleJump()
        end
    end,
})
Tabs.Player:Space()

local noclipConnection
local function setNoclip(state)
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if state then
        noclipConnection = RunService.Stepped:Connect(function()
            if Character then
                for _, p in ipairs(Character:GetChildren()) do
                    if p:IsA("BasePart") then
                        p.CanCollide = false
                    end
                end
            end
        end)
    else
        if Character then
            for _, p in ipairs(Character:GetChildren()) do
                if p:IsA("BasePart") then
                    p.CanCollide = true
                end
            end
        end
    end
end
NoclipToggle = Tabs.Player:Toggle({
    Title = "Noclip",
    Flag = "NoclipToggle",
    Value = false,
    Callback = function(s)
        setNoclip(s)
    end,
})

Tabs.Player:Space()

local isOnMobile = false
pcall(function()
    isOnMobile = table.find({ Enum.Platform.Android, Enum.Platform.IOS }, UserInputService:GetPlatform()) ~= nil
end)
local vflySpeed, vflyQE = 5, false
local vflyConnection, vflyKeyDown, vflyKeyUp, vflyControlModule
local vflyKeys, vflyUp, vflyDown = {}, false, false
local vflyVelocityName = "VFlyVelocity_" .. math.random(1000, 9999)
local vflyGyroName = "VFlyGyro_" .. math.random(1000, 9999)
local mobileConnections, mobileJumpButton, mobileJumpRect, downButton = {}, nil, nil, nil

local function destroyMobileButtons()
    for _, c in ipairs(mobileConnections) do
        c:Disconnect()
    end
    table.clear(mobileConnections)
    if mobileJumpButton and mobileJumpButton.Parent and mobileJumpRect then
        mobileJumpButton.ImageRectOffset = mobileJumpRect
    end
    mobileJumpButton, mobileJumpRect = nil, nil
    if downButton then
        downButton:Destroy()
        downButton = nil
    end
    vflyUp, vflyDown = false, false
end

local function createMobileButtons()
    destroyMobileButtons()
    local tg = PlayerGui:FindFirstChild("TouchGui") or PlayerGui:WaitForChild("TouchGui", 5)
    local cf = tg and tg:FindFirstChild("TouchControlFrame")
    local jb = cf and cf:FindFirstChild("JumpButton")
    if not jb then
        return
    end
    mobileJumpButton = jb
    mobileJumpRect = jb.ImageRectOffset
    local pressed = Vector2.new(146, 146)
    local b = Instance.new("ImageButton")
    b.Name = "DownWardJumpBtn"
    b.Size = jb.Size
    b.Image = jb.Image
    b.ImageRectOffset = mobileJumpRect
    b.ImageRectSize = jb.ImageRectSize
    b.BackgroundTransparency = 1
    b.AnchorPoint = Vector2.new(1, 0)
    b.AutoButtonColor = false
    b.Position = UDim2.new(1, 0, jb.Position.Y.Scale, jb.Position.Y.Offset)
    b.Rotation = 180
    b.Parent = cf
    downButton = b
    local function align()
        if not b.Parent or not jb.Parent then
            return
        end
        local d = b.AbsolutePosition.X - (jb.AbsolutePosition.X + jb.AbsoluteSize.X)
        b.Position = UDim2.new(1, b.Position.X.Offset + (d - 1), b.Position.Y.Scale, b.Position.Y.Offset)
    end
    local function bind(t, dn, up)
        table.insert(mobileConnections, t.MouseButton1Down:Connect(dn))
        table.insert(mobileConnections, t.MouseButton1Up:Connect(up))
        table.insert(mobileConnections, t.MouseLeave:Connect(up))
    end
    bind(jb, function()
        vflyUp = true
        jb.ImageRectOffset = pressed
    end, function()
        vflyUp = false
        jb.ImageRectOffset = mobileJumpRect or jb.ImageRectOffset
    end)
    bind(b, function()
        vflyDown = true
        b.ImageRectOffset = pressed
    end, function()
        vflyDown = false
        b.ImageRectOffset = mobileJumpRect or b.ImageRectOffset
    end)
    table.insert(mobileConnections, b:GetPropertyChangedSignal("AbsoluteSize"):Connect(align))
    if workspace.CurrentCamera then
        table.insert(mobileConnections, workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(align))
    end
    align()
end

local function getVFlyBodies(root)
    local v = root:FindFirstChild(vflyVelocityName)
    if not v then
        v = Instance.new("BodyVelocity")
        v.Name = vflyVelocityName
        v.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        v.Velocity = Vector3.zero
        v.Parent = root
    end
    local g = root:FindFirstChild(vflyGyroName)
    if not g then
        g = Instance.new("BodyGyro")
        g.Name = vflyGyroName
        g.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        g.P = 9e4
        g.CFrame = root.CFrame
        g.Parent = root
    end
    return v, g
end

local function stopVFly()
    if vflyConnection then
        vflyConnection:Disconnect()
        vflyConnection = nil
    end
    if vflyKeyDown then
        vflyKeyDown:Disconnect()
        vflyKeyDown = nil
    end
    if vflyKeyUp then
        vflyKeyUp:Disconnect()
        vflyKeyUp = nil
    end
    table.clear(vflyKeys)
    vflyControlModule = nil
    if HumanoidRootPart then
        local v = HumanoidRootPart:FindFirstChild(vflyVelocityName)
        if v then
            v:Destroy()
        end
        local g = HumanoidRootPart:FindFirstChild(vflyGyroName)
        if g then
            g:Destroy()
        end
    end
    destroyMobileButtons()
end

local function startVFly()
    stopVFly()
    if not HumanoidRootPart then
        return false
    end
    if isOnMobile then
        pcall(function()
            local pm = LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 5)
            vflyControlModule = require(pm:WaitForChild("ControlModule", 5))
        end)
        createMobileButtons()
    else
        vflyKeyDown = UserInputService.InputBegan:Connect(function(i, p)
            if not p then
                vflyKeys[i.KeyCode] = true
            end
        end)
        vflyKeyUp = UserInputService.InputEnded:Connect(function(i)
            vflyKeys[i.KeyCode] = nil
        end)
    end
    vflyConnection = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if not HumanoidRootPart or not cam then
            return
        end
        local velocity = getVFlyBodies(HumanoidRootPart)
        local ccf = cam.CFrame
        local move = Vector3.zero
        local up, down = vflyUp, vflyDown
        if isOnMobile then
            if vflyControlModule then
                local d = vflyControlModule:GetMoveVector()
                move = ccf.RightVector * d.X - ccf.LookVector * d.Z
            end
        else
            local x = (vflyKeys[Enum.KeyCode.D] and 1 or 0) - (vflyKeys[Enum.KeyCode.A] and 1 or 0)
            local z = (vflyKeys[Enum.KeyCode.W] and 1 or 0) - (vflyKeys[Enum.KeyCode.S] and 1 or 0)
            move = ccf.RightVector * x + ccf.LookVector * z
            if vflyQE then
                up = up or vflyKeys[Enum.KeyCode.E] == true
                down = down or vflyKeys[Enum.KeyCode.Q] == true
            end
        end
        local speed = vflySpeed * 50
        local vert = (up and 1 or 0) - (down and 1 or 0)
        velocity.Velocity = move * speed + Vector3.new(0, vert * speed, 0)
    end)
    return true
end

VehicleFlyToggle = Tabs.Player:Toggle({
    Title = "Vehicle Fly",
    Flag = "VehicleFlyToggle",
    Desc = "Fly while seated in a vehicle or on foot",
    Value = false,
    Callback = function(s)
        if s then
            if not startVFly() then
                VehicleFlyToggle:Set(false)
            end
        else
            stopVFly()
        end
    end,
})
VehicleFlySpeedInput = Tabs.Player:Input({
    Title = "Vehicle Fly Speed",
    Flag = "VehicleFlySpeedInput",
    Placeholder = "Enter speed value",
    Value = tostring(vflySpeed),
    NumbersOnly = true,
    Callback = function(v)
        local n = tonumber(v)
        if n and n > 0 then
            vflySpeed = n
        end
    end,
})
VehicleQEflyToggle = Tabs.Player:Toggle({
    Title = "Q/E Vertical Fly",
    Flag = "VehicleQEflyToggle",
    Desc = "E to go up, Q to go down (PC)",
    Value = false,
    Callback = function(s)
        vflyQE = s
    end,
})

LocalPlayer.CharacterAdded:Connect(function()
    if vflyConnection then
        stopVFly()
        if VehicleFlyToggle then
            VehicleFlyToggle:Set(false)
        end
    end
end)

Tabs.Combat:Section({ Title = "Auto Swing", TextSize = 20 })
Tabs.Combat:Divider()
local SWING_RANGE = 15
local swingPerTime = 1
local trackedNPCs = {}
local swingConnection, descendantConnection
function getSwingRemote()
    local ok, r = pcall(function()
        return ReplicatedStorage.Shared.Universe.Network.RemoteEvent.SwingMelee
    end)
    return ok and r or nil
end
local descendantUsers = 0
local function normalizeName(n)
    return (string.lower(n):gsub("[%s_]", ""))
end
local function getMeleeNames()
    local ok, f = pcall(function()
        return ReplicatedStorage.Assets.Tools.Weapon.Melee
    end)
    if not ok or not f then
        return nil, 0
    end
    local names, c = {}, 0
    for _, t in ipairs(f:GetChildren()) do
        names[normalizeName(t.Name)] = true
        c += 1
    end
    return names, c
end
local function findMeleeTool(names)
    if not Character then
        return nil
    end
    for _, ch in ipairs(Character:GetChildren()) do
        if ch:IsA("Tool") and names[normalizeName(ch.Name)] then
            return ch
        end
    end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if bp then
        for _, ch in ipairs(bp:GetChildren()) do
            if ch:IsA("Tool") and names[normalizeName(ch.Name)] then
                return ch
            end
        end
    end
    return nil
end
local function trackNPC(h)
    local m = h.Parent
    if m and m:IsA("Model") and not trackedNPCs[m] and not Players:GetPlayerFromCharacter(m) then
        trackedNPCs[m] = h
    end
end
local function startNPCTracking()
    descendantUsers += 1
    if descendantUsers > 1 then
        return
    end
    for _, o in ipairs(workspace:GetDescendants()) do
        if o:IsA("Humanoid") then
            trackNPC(o)
        end
    end
    descendantConnection = workspace.DescendantAdded:Connect(function(o)
        if o:IsA("Humanoid") then
            trackNPC(o)
        end
    end)
end
local function stopNPCTracking()
    if descendantUsers == 0 then
        return
    end
    descendantUsers -= 1
    if descendantUsers > 0 then
        return
    end
    if descendantConnection then
        descendantConnection:Disconnect()
        descendantConnection = nil
    end
    table.clear(trackedNPCs)
end
local function getClosestNPCId()
    if not HumanoidRootPart then
        return nil
    end
    local pos = HumanoidRootPart.Position
    local bestId, bestDist
    for m, h in pairs(trackedNPCs) do
        if not m.Parent then
            trackedNPCs[m] = nil
        elseif h.Health > 0 then
            local id = m:GetAttribute("ServerEntityId")
            local nr = m:FindFirstChild("HumanoidRootPart") or m.PrimaryPart
            if id and nr then
                local d = (nr.Position - pos).Magnitude
                if d <= SWING_RANGE and (not bestDist or d < bestDist) then
                    bestId, bestDist = id, d
                end
            end
        end
    end
    return bestId
end
local autoSwingTracking = false
local stopAutoSwing, startAutoSwing
do
    local swingTool, swingRun = nil, 0
    local toolConnections = {}
    local function clearToolConnections()
        for _, c in ipairs(toolConnections) do
            c:Disconnect()
        end
        table.clear(toolConnections)
    end
    local function watchTools(names, run)
        clearToolConnections()
        local function refresh()
            if swingRun == run then
                swingTool = findMeleeTool(names)
            end
        end
        local function watch(container)
            if not container then
                return
            end
            table.insert(
                toolConnections,
                container.ChildAdded:Connect(function(ch)
                    if ch:IsA("Tool") then
                        refresh()
                    end
                end)
            )
            table.insert(
                toolConnections,
                container.ChildRemoved:Connect(function(ch)
                    if ch:IsA("Tool") then
                        task.defer(refresh)
                    end
                end)
            )
        end
        watch(Character)
        watch(LocalPlayer:FindFirstChildOfClass("Backpack"))
        table.insert(
            toolConnections,
            LocalPlayer.CharacterAdded:Connect(function()
                task.spawn(function()
                    LocalPlayer:WaitForChild("Backpack", 5)
                    if swingRun == run then
                        watchTools(names, run)
                    end
                end)
            end)
        )
        refresh()
    end
    stopAutoSwing = function()
        swingRun += 1
        clearToolConnections()
        swingTool = nil
        if swingConnection then
            swingConnection:Disconnect()
            swingConnection = nil
        end
        if autoSwingTracking then
            autoSwingTracking = false
            stopNPCTracking()
        end
    end
    startAutoSwing = function()
        stopAutoSwing()
        local R = getSwingRemote()
        if not R then
            WindUI:Notify({ Title = "Auto Swing", Content = "SwingMelee remote not found", Duration = 3 })
            return false
        end
        local names, count = getMeleeNames()
        if not names or count == 0 then
            WindUI:Notify({ Title = "Auto Swing", Content = "No melee weapons found", Duration = 3 })
            return false
        end
        autoSwingTracking = true
        startNPCTracking()
        watchTools(names, swingRun)
        swingConnection = RunService.Heartbeat:Connect(function()
            local w = swingTool
            if not w or not w.Parent then
                return
            end
            local id = getClosestNPCId()
            if id then
                for _ = 1, swingPerTime do
                    R:FireServer(w, 0, id)
                end
            end
        end)
        return true
    end
end
AutoSwingToggle = Tabs.Combat:Toggle({
    Title = "Auto Swing",
    Flag = "AutoSwingToggle",
    Value = false,
    Callback = function(s)
        if s then
            if not startAutoSwing() then
                AutoSwingToggle:Set(false)
            end
        else
            stopAutoSwing()
        end
    end,
})
SwingPerTimeInput = Tabs.Combat:Input({
    Title = "Swing Per Time",
    Flag = "SwingPerTimeInput",
    Desc = "How many swings are fired per frame",
    Icon = "swords",
    Placeholder = "1",
    Value = tostring(swingPerTime),
    Callback = function(v)
        local n = tonumber(v)
        if n then
            swingPerTime = math.max(math.floor(n), 1)
        end
    end,
})
Tabs.Combat:Space()

Tabs.Combat:Section({ Title = "OP Swing", TextSize = 20 })
Tabs.Combat:Divider()
local opSwingDelay, opSwingsPerDelay = 0.05, 2
local opHolding, opLoopId, ClientMeleeHandler, originalMeleeHandler = false, 0, nil, nil
local opCharacterConnection, opTracking, opSwingEnabled, opHookFn, opInputBegan, opInputEnded
local function stopOpHolding()
    opHolding = false
    opLoopId += 1
    if OpHoldConnection then
        OpHoldConnection:Disconnect()
        OpHoldConnection = nil
    end
end
local function startOpHolding()
    if not Character then
        return
    end
    local tool = Character:FindFirstChildWhichIsA("Tool")
    if not tool then
        return
    end
    local R = getSwingRemote()
    if not R then
        return
    end
    local at = workspace:GetServerTimeNow()
    local mouse = LocalPlayer:GetMouse()
    local lv = mouse.Hit and mouse.Hit.LookVector or Character:GetPivot().LookVector
    stopOpHolding()
    opHolding = true
    OpHoldConnection = RunEvery(function()
        return opSwingDelay
    end, function()
        if not opHolding or tool.Parent ~= Character then
            stopOpHolding()
            return
        end
        local tid = getClosestNPCId()
        if tid then
            for _ = 1, opSwingsPerDelay do
                R:FireServer(tool, at, lv)
                R:FireServer(tool, 0, tid)
            end
        end
    end)
end
local function stopOpSwing()
    opSwingEnabled = false
    stopOpHolding()
    if ClientMeleeHandler and opHookFn and ClientMeleeHandler._meleeActionHandler == opHookFn then
        ClientMeleeHandler._meleeActionHandler = originalMeleeHandler
    end
    if opTracking then
        opTracking = false
        stopNPCTracking()
    end
    if opCharacterConnection then
        opCharacterConnection:Disconnect()
        opCharacterConnection = nil
    end
    if opInputBegan then
        opInputBegan:Disconnect()
        opInputBegan = nil
    end
    if opInputEnded then
        opInputEnded:Disconnect()
        opInputEnded = nil
    end
end
local function rebindMeleeInput()
    local t = Character and Character:FindFirstChildWhichIsA("Tool")
    if Humanoid and t then
        Humanoid:UnequipTools()
        task.wait(0.15)
        if opSwingEnabled then
            Humanoid:EquipTool(t)
        end
    end
end
local function startOpSwing()
    stopOpSwing()
    local ok, mod = pcall(function()
        return require(ReplicatedStorage.Client.Game.Melee.ClientMeleeHandler)
    end)
    if not ok or type(mod) ~= "table" then
        WindUI:Notify({ Title = "OP Swing", Content = "ClientMeleeHandler not found", Duration = 3 })
        return false
    end
    ClientMeleeHandler = mod
    if not originalMeleeHandler and mod._meleeActionHandler ~= opHookFn then
        originalMeleeHandler = mod._meleeActionHandler
    end
    if not opHookFn then
        opHookFn = function(name, state, obj)
            if opSwingEnabled then
                if state == Enum.UserInputState.Begin then
                    startOpHolding()
                elseif state == Enum.UserInputState.End then
                    stopOpHolding()
                end
            end
            if originalMeleeHandler then
                return originalMeleeHandler(name, state, obj)
            end
        end
    end
    mod._meleeActionHandler = opHookFn
    opSwingEnabled = true
    opTracking = true
    startNPCTracking()
    opCharacterConnection = LocalPlayer.CharacterAdded:Connect(stopOpHolding)
    opInputBegan = UserInputService.InputBegan:Connect(function(i, p)
        if not p and i.UserInputType == Enum.UserInputType.MouseButton1 then
            startOpHolding()
        end
    end)
    opInputEnded = UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            stopOpHolding()
        end
    end)
    task.spawn(rebindMeleeInput)
    return true
end
OpSwingToggle = Tabs.Combat:Toggle({
    Title = "OP Swing",
    Flag = "OpSwingToggle",
    Value = false,
    Callback = function(s)
        if s then
            if not startOpSwing() then
                OpSwingToggle:Set(false)
            end
        else
            stopOpSwing()
        end
    end,
})
OpSwingDelayInput = Tabs.Combat:Input({
    Title = "OP Swing Delay",
    Flag = "OpSwingDelayInput",
    Desc = "Seconds to wait between bursts (0 = every frame)",
    Icon = "timer",
    Placeholder = "0.05",
    Value = tostring(opSwingDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n then
            opSwingDelay = math.max(n, 0)
        end
    end,
})
OpSwingsPerDelayInput = Tabs.Combat:Input({
    Title = "OP Swings Per Delay",
    Flag = "OpSwingsPerDelayInput",
    Desc = "How many swings are fired in each burst",
    Icon = "swords",
    Placeholder = "2",
    Value = tostring(opSwingsPerDelay),
    Callback = function(v)
        local n = tonumber(v)
        if n then
            opSwingsPerDelay = math.max(math.floor(n), 1)
        end
    end,
})

Tabs.Visuals:Section({ Title = "Lighting", TextSize = 20 })
Tabs.Visuals:Divider()
local fogOriginal, fogConnection
local function stopLoopNoFog()
    if fogConnection then
        fogConnection:Disconnect()
        fogConnection = nil
    end
    if fogOriginal then
        Lighting.FogStart = fogOriginal.FogStart
        Lighting.FogEnd = fogOriginal.FogEnd
        local a = Lighting:FindFirstChildOfClass("Atmosphere")
        if a and fogOriginal.Density then
            a.Density = fogOriginal.Density
            a.Haze = fogOriginal.Haze
        end
        fogOriginal = nil
    end
end
local function startLoopNoFog()
    stopLoopNoFog()
    local a = Lighting:FindFirstChildOfClass("Atmosphere")
    fogOriginal =
        { FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd, Density = a and a.Density, Haze = a and a.Haze }
    fogConnection = RunService.Heartbeat:Connect(function()
        Lighting.FogStart = 100000
        Lighting.FogEnd = 100000
        local c = Lighting:FindFirstChildOfClass("Atmosphere")
        if c then
            c.Density = 0
            c.Haze = 0
        end
    end)
end
LoopNoFogToggle = Tabs.Visuals:Toggle({
    Title = "Loop Remove Fog",
    Flag = "LoopNoFogToggle",
    Value = false,
    Callback = function(s)
        if s then
            startLoopNoFog()
        else
            stopLoopNoFog()
        end
    end,
})
Tabs.Visuals:Space()

local fbOriginal, fbConnection
local function stopLoopFullBright()
    if fbConnection then
        fbConnection:Disconnect()
        fbConnection = nil
    end
    if fbOriginal then
        Lighting.Brightness = fbOriginal.Brightness
        Lighting.Ambient = fbOriginal.Ambient
        Lighting.OutdoorAmbient = fbOriginal.OutdoorAmbient
        Lighting.ColorShift_Top = fbOriginal.ColorShift_Top
        Lighting.ColorShift_Bottom = fbOriginal.ColorShift_Bottom
        fbOriginal = nil
    end
end
local function startLoopFullBright()
    stopLoopFullBright()
    fbOriginal = {
        Brightness = Lighting.Brightness,
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ColorShift_Top = Lighting.ColorShift_Top,
        ColorShift_Bottom = Lighting.ColorShift_Bottom,
    }
    local w = Color3.fromRGB(255, 255, 255)
    fbConnection = RunService.Heartbeat:Connect(function()
        Lighting.Brightness = 1
        Lighting.Ambient = w
        Lighting.OutdoorAmbient = w
        Lighting.ColorShift_Top = w
        Lighting.ColorShift_Bottom = w
    end)
end
LoopFullBrightToggle = Tabs.Visuals:Toggle({
    Title = "Loop Full Bright",
    Flag = "LoopFullBrightToggle",
    Value = false,
    Callback = function(s)
        if s then
            startLoopFullBright()
        else
            stopLoopFullBright()
        end
    end,
})
Tabs.Visuals:Space()
Tabs.Visuals:Divider()
Tabs.Visuals:Section({ Title = "Camera", TextSize = 20 })
Tabs.Visuals:Divider()

local stretchHorizontal, stretchVertical = 0.8, 0.8
local cameraStretchConnection
local function stopCameraStretch()
    if cameraStretchConnection then
        cameraStretchConnection:Disconnect()
        cameraStretchConnection = nil
    end
end
local function startCameraStretch()
    stopCameraStretch()
    cameraStretchConnection = RunService.RenderStepped:Connect(function()
        local cam = workspace.CurrentCamera
        if cam then
            cam.CFrame = cam.CFrame * CFrame.new(0, 0, 0, stretchHorizontal, 0, 0, 0, stretchVertical, 0, 0, 0, 1)
        end
    end)
end
CameraStretchToggle = Tabs.Visuals:Toggle({
    Title = "Camera Stretch",
    Flag = "CameraStretchToggle",
    Value = false,
    Callback = function(s)
        if s then
            startCameraStretch()
        else
            stopCameraStretch()
        end
    end,
})
CameraStretchHorizontalInput = Tabs.Visuals:Input({
    Title = "Camera Stretch Horizontal",
    Flag = "CameraStretchHorizontalInput",
    Placeholder = "0.80",
    Value = tostring(stretchHorizontal),
    Callback = function(v)
        local n = tonumber(v)
        if n then
            stretchHorizontal = n
        end
    end,
})
CameraStretchVerticalInput = Tabs.Visuals:Input({
    Title = "Camera Stretch Vertical",
    Flag = "CameraStretchVerticalInput",
    Placeholder = "0.80",
    Value = tostring(stretchVertical),
    Callback = function(v)
        local n = tonumber(v)
        if n then
            stretchVertical = n
        end
    end,
})

do
local shakePatches = {}
local shakeProxied = {}
local shakeCharacterConnection

local function shakeFind(root, ...)
    local node = root
    for _, name in ipairs({ ... }) do
        node = node and node:FindFirstChild(name)
    end
    return node
end

local function shakeRequireModule(inst)
    if not inst then
        return nil
    end
    local ok, m = pcall(require, inst)
    return ok and type(m) == "table" and m or nil
end

local function shakePatch(tbl, key, fn)
    if type(tbl) ~= "table" or type(tbl[key]) ~= "function" then
        return false
    end
    pcall(setreadonly, tbl, false)
    local original = tbl[key]
    if pcall(function()
        tbl[key] = fn
    end) then
        table.insert(shakePatches, { tbl = tbl, key = key, original = original })
        return true
    end
    return false
end

local function shakeProxyLayer(layer)
    if type(layer) ~= "table" or shakeProxied[layer] ~= nil then
        return false
    end
    pcall(setreadonly, layer, false)
    local okMeta, original = pcall(getmetatable, layer)
    original = okMeta and type(original) == "table" and original or nil
    local originalIndex = original and original.__index
    local originalNewIndex = original and original.__newindex
    local mt = {}
    if original then
        for k, v in pairs(original) do
            mt[k] = v
        end
    end
    mt.__index = function(t, k)
        if k == "CameraShake" then
            return Vector3.zero
        end
        if type(originalIndex) == "function" then
            return originalIndex(t, k)
        end
        if type(originalIndex) == "table" then
            return originalIndex[k]
        end
        return nil
    end
    mt.__newindex = function(t, k, v)
        if k == "CameraShake" then
            return
        end
        if type(originalNewIndex) == "function" then
            return originalNewIndex(t, k, v)
        end
        if type(originalNewIndex) == "table" then
            originalNewIndex[k] = v
            return
        end
        rawset(t, k, v)
    end
    rawset(layer, "CameraShake", nil)
    if pcall(setmetatable, layer, mt) then
        shakeProxied[layer] = original or false
        return true
    end
    return false
end

local function blockGameCameraLayers()
    local cameraModule = shakeRequireModule(shakeFind(ReplicatedStorage, "Shared", "Universe", "Camera"))
    if not cameraModule then
        return 0
    end
    local ok, singleton = pcall(function()
        return cameraModule:GetSingleton()
    end)
    if not ok or type(singleton) ~= "table" then
        return 0
    end
    local count = 0
    if shakeProxyLayer(singleton.Rotations) then
        count += 1
    end
    if shakeProxyLayer(singleton.Positions) then
        count += 1
    end
    return count
end

local function startBlockCameraShake()
    local count = blockGameCameraLayers()

    local forgeEffect = shakeRequireModule(
        shakeFind(
            ReplicatedStorage,
            "Packages",
            "_Index",
            "zilibobi_forge-vfx@2.4.0",
            "forge-vfx",
            "effects",
            "camera_shake"
        )
    )
    if forgeEffect and shakePatch(forgeEffect, "emit", function() end) then
        count += 1
    end

    local shaker = shakeRequireModule(shakeFind(ReplicatedStorage, "Packages", "CameraShaker"))
    if shaker then
        local originalUpdate = shaker.Update
        if
            type(originalUpdate) == "function"
            and shakePatch(shaker, "Update", function(self, dt)
                originalUpdate(self, dt)
                return CFrame.identity
            end)
        then
            count += 1
        end
    end

    if shakeCharacterConnection then
        shakeCharacterConnection:Disconnect()
    end
    shakeCharacterConnection = LocalPlayer.CharacterAdded:Connect(function()
        blockGameCameraLayers()
    end)

    if count == 0 then
        WindUI:Notify({
            Title = "Block Camera Shake",
            Content = "No camera shake source found yet. Toggle again after the camera loads",
            Duration = 4,
        })
    end
end

local function stopBlockCameraShake()
    if shakeCharacterConnection then
        shakeCharacterConnection:Disconnect()
        shakeCharacterConnection = nil
    end
    for i = #shakePatches, 1, -1 do
        local p = shakePatches[i]
        pcall(function()
            p.tbl[p.key] = p.original
        end)
        shakePatches[i] = nil
    end
    for layer, original in pairs(shakeProxied) do
        pcall(setmetatable, layer, original or nil)
        shakeProxied[layer] = nil
    end
end

Tabs.Visuals:Space()
BlockCameraShakeToggle = Tabs.Visuals:Toggle({
    Title = "Block Camera Shake",
    Flag = "BlockCameraShakeToggle",
    Desc = "Stops explosion, lightning, tesla and effect camera shake",
    Value = false,
    Callback = function(s)
        if s then
            startBlockCameraShake()
        else
            stopBlockCameraShake()
        end
    end,
})
end

Tabs.Visuals:Space()
Tabs.Visuals:Divider()
Tabs.Visuals:Section({ Title = "Clock Display", TextSize = 20 })
Tabs.Visuals:Divider()

do
    local clockGui, clockFrame, clockLabel, clockValueConnection, clockAddedConnection
    local clockScale = 1

    local function findClockValue()
        local v = ReplicatedStorage:FindFirstChild("TimeHour")
        if v and v:IsA("ValueBase") then
            return v
        end
        return nil
    end

    local function destroyClockDisplay()
        if clockAddedConnection then
            clockAddedConnection:Disconnect()
            clockAddedConnection = nil
        end
        if clockValueConnection then
            clockValueConnection:Disconnect()
            clockValueConnection = nil
        end
        if clockGui then
            clockGui:Destroy()
        end
        clockGui, clockFrame, clockLabel = nil, nil, nil
    end

    local function applyClockScale()
        if clockFrame then
            clockFrame.Size = UDim2.fromOffset(180 * clockScale, 50 * clockScale)
        end
    end

    local function buildClockDisplay(source)
        clockGui = Instance.new("ScreenGui")
        clockGui.Name = "DaraClockDisplay"
        clockGui.ResetOnSpawn = false
        clockGui.IgnoreGuiInset = true
        clockGui.DisplayOrder = 10
        clockGui.Parent = PlayerGui

        clockFrame = Instance.new("Frame")
        clockFrame.Name = "ClockFrame"
        clockFrame.AnchorPoint = Vector2.new(0.5, 0)
        clockFrame.Position = UDim2.new(0.5, 0, 0, 12)
        clockFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        clockFrame.BackgroundTransparency = 0.35
        clockFrame.BorderSizePixel = 0
        clockFrame.Active = true
        clockFrame.Draggable = true
        clockFrame.Parent = clockGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = clockFrame

        local pad = Instance.new("UIPadding")
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
        pad.PaddingTop = UDim.new(0, 4)
        pad.PaddingBottom = UDim.new(0, 4)
        pad.Parent = clockFrame

        clockLabel = Instance.new("TextLabel")
        clockLabel.Name = "ClockText"
        clockLabel.Size = UDim2.fromScale(1, 1)
        clockLabel.BackgroundTransparency = 1
        clockLabel.Font = Enum.Font.GothamBold
        clockLabel.TextScaled = true
        clockLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        clockLabel.Text = tostring(source.Value)
        clockLabel.Parent = clockFrame

        applyClockScale()

        clockValueConnection = source.Changed:Connect(function()
            if clockLabel then
                clockLabel.Text = tostring(source.Value)
            end
        end)
    end

    local function startClockDisplay()
        destroyClockDisplay()
        local found = findClockValue()
        if found then
            buildClockDisplay(found)
            return
        end
        clockAddedConnection = ReplicatedStorage.ChildAdded:Connect(function(child)
            if child.Name == "TimeHour" and child:IsA("ValueBase") then
                clockAddedConnection:Disconnect()
                clockAddedConnection = nil
                buildClockDisplay(child)
            end
        end)
    end

    Tabs.Visuals:Toggle({
        Title = "Clock Display",
        Flag = "ClockDisplayToggle",
        Desc = "Shows the in-game time on screen. Drag it to move",
        Value = false,
        Callback = function(s)
            if s then
                startClockDisplay()
            else
                destroyClockDisplay()
            end
        end,
    })
    Tabs.Visuals:Slider({
        Title = "Clock Size",
        Flag = "ClockDisplaySizeSlider",
        Step = 0.05,
        Value = { Min = 0.5, Max = 4, Default = 1 },
        Callback = function(v)
            clockScale = tonumber(v) or 1
            applyClockScale()
        end,
    })
end

local mobColor = Color3.fromRGB(255, 255, 0)
local espSettings = {
    Player = {
        Names = false,
        Boxes = false,
        BoxType = "2D",
        Distance = false,
        Health = false,
        State = false,
        Highlights = false,
        Tracers = false,
    },
    Mob = {
        Names = false,
        Boxes = false,
        BoxType = "2D",
        Distance = false,
        Health = false,
        State = false,
        Highlights = false,
        Tracers = false,
    },
    Item = { Names = false, Boxes = false, BoxType = "2D", Distance = false, Highlights = false, Tracers = false },
}
local espElements = { Player = {}, Mob = {} }
local tracerEntries, tracerGui, espConnection = {}, nil, nil
local mobTrackingActive = false

local function getDistanceFromCamera(pos)
    local cam = workspace.CurrentCamera
    if not cam then
        return 0
    end
    return (pos - cam.CFrame.Position).Magnitude
end
local function calculateBoxScale(d)
    if d <= 17 then
        return 1
    end
    return math.max(17 / d, 0.013)
end
local function getCharacterState(c)
    local h = c:FindFirstChildOfClass("Humanoid")
    if not h then
        return "Unknown"
    end
    if h.Health <= 0 then
        return "Dead"
    end
    if h.MoveDirection.Magnitude > 0 then
        return "Moving"
    end
    return "Idle"
end
local function getHealthColor(h, m)
    local p = h / math.max(m, 1)
    if p > 0.6 then
        return "#00ff00"
    elseif p > 0.3 then
        return "#ffa500"
    end
    return "#ff0000"
end
local PLAYER_ALIVE_COLOR = Color3.fromRGB(0, 255, 0)
local PLAYER_DEAD_COLOR = Color3.fromRGB(255, 0, 0)
local function getPlayerESPColor(h)
    if h and h.Health <= 0 then
        return PLAYER_DEAD_COLOR
    end
    return PLAYER_ALIVE_COLOR
end
local function destroyESPChild(c, n)
    local d = c:FindFirstChild(n)
    if d then
        d:Destroy()
    end
    local r = c:FindFirstChild("HumanoidRootPart")
    local ir = r and r:FindFirstChild(n)
    if ir then
        ir:Destroy()
    end
end
local function create2DBox(c, col, sc)
    destroyESPChild(c, "ESP_2DBox")
    local r = c:FindFirstChild("HumanoidRootPart")
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_2DBox"
    bb.Adornee = r or c
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 80 * sc, 0, 100 * sc)
    bb.StudsOffset = Vector3.zero
    bb.ClipsDescendants = false
    bb.Parent = r or c
    local f = Instance.new("Frame")
    f.Name = "BoxFrame"
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = bb
    local st = Instance.new("UIStroke")
    st.Thickness = math.max(2.5 * sc, 2)
    st.Transparency = 0
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Color = col
    st.Parent = f
    return { billboard = bb, stroke = st }
end
local function update2DBox(b, col, sc)
    b.stroke.Color = col
    b.stroke.Thickness = math.max(2.5 * sc, 2)
    b.billboard.Size = UDim2.new(0, 80 * sc, 0, 100 * sc)
end
local function remove2DBox(c)
    destroyESPChild(c, "ESP_2DBox")
end
local function create3DBox(c, col, sz)
    local r = c:FindFirstChild("HumanoidRootPart")
    if not r then
        return nil
    end
    local e = c:FindFirstChild("ESP_3DBox")
    if e then
        e:Destroy()
    end
    local f = Instance.new("Folder")
    f.Name = "ESP_3DBox"
    f.Parent = c
    local x, y, z = sz.X / 2, sz.Y / 2, sz.Z / 2
    local edges = {
        { Vector3.new(0, y, z), Vector3.new(sz.X, 0.1, 0.1) },
        { Vector3.new(0, y, -z), Vector3.new(sz.X, 0.1, 0.1) },
        { Vector3.new(-x, y, 0), Vector3.new(0.1, 0.1, sz.Z) },
        { Vector3.new(x, y, 0), Vector3.new(0.1, 0.1, sz.Z) },
        { Vector3.new(0, -y, z), Vector3.new(sz.X, 0.1, 0.1) },
        { Vector3.new(0, -y, -z), Vector3.new(sz.X, 0.1, 0.1) },
        { Vector3.new(-x, -y, 0), Vector3.new(0.1, 0.1, sz.Z) },
        { Vector3.new(x, -y, 0), Vector3.new(0.1, 0.1, sz.Z) },
        { Vector3.new(-x, 0, z), Vector3.new(0.1, sz.Y, 0.1) },
        { Vector3.new(x, 0, z), Vector3.new(0.1, sz.Y, 0.1) },
        { Vector3.new(-x, 0, -z), Vector3.new(0.1, sz.Y, 0.1) },
        { Vector3.new(x, 0, -z), Vector3.new(0.1, sz.Y, 0.1) },
    }
    for _, e2 in ipairs(edges) do
        local a = Instance.new("BoxHandleAdornment")
        a.Adornee = r
        a.Size = e2[2]
        a.CFrame = CFrame.new(e2[1])
        a.Color3 = col
        a.Transparency = 0.2
        a.ZIndex = 10
        a.AlwaysOnTop = true
        a.Parent = f
    end
    return f
end
local function update3DBoxColor(c, col)
    local f = c:FindFirstChild("ESP_3DBox")
    if f then
        for _, a in ipairs(f:GetChildren()) do
            a.Color3 = col
        end
    end
end
local function remove3DBox(c)
    local f = c:FindFirstChild("ESP_3DBox")
    if f then
        f:Destroy()
    end
end
local function createHighlight(c, col)
    local e = c:FindFirstChild("ESP_Highlight")
    if e then
        e:Destroy()
    end
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_Highlight"
    hl.Adornee = c
    hl.FillColor = col
    hl.OutlineColor = col
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.3
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = c
    return hl
end
local function updateHighlight(hl, col)
    hl.FillColor = col
    hl.OutlineColor = col
end
local function removeHighlight(c)
    local hl = c:FindFirstChild("ESP_Highlight")
    if hl then
        hl:Destroy()
    end
end
local function createBillboard(c, col)
    destroyESPChild(c, "ESP_Billboard")
    local r = c:FindFirstChild("HumanoidRootPart")
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_Billboard"
    bb.Adornee = r or c
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 350, 0, 100)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.ClipsDescendants = false
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bb.Parent = r or c
    local tl = Instance.new("TextLabel")
    tl.Name = "InfoLabel"
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text = ""
    tl.TextColor3 = col
    tl.TextSize = 10
    tl.Font = Enum.Font.GothamBold
    tl.RichText = true
    tl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    tl.TextStrokeTransparency = 0
    tl.TextXAlignment = Enum.TextXAlignment.Center
    tl.TextYAlignment = Enum.TextYAlignment.Top
    tl.TextWrapped = true
    tl.LineHeight = 1.2
    tl.Parent = bb
    return { billboard = bb, textLabel = tl }
end
local function updateBillboard(d, name, dist, col, hp, mhp, state)
    local lines = {}
    if name then
        table.insert(lines, name)
    end
    local details = {}
    if hp and mhp then
        table.insert(
            details,
            string.format('<font color="%s">Health: %.0f / %.0f</font>', getHealthColor(hp, mhp), hp, mhp)
        )
    end
    if dist then
        table.insert(details, "Distance: " .. string.format("%.0f", dist))
    end
    if state then
        table.insert(details, "State: " .. state)
    end
    if #details > 0 then
        table.insert(lines, table.concat(details, " | "))
    end
    d.textLabel.Text = table.concat(lines, "\n")
    d.textLabel.TextColor3 = col
end
local function removeTargetESP(c, esp)
    if esp.box2D then
        remove2DBox(c)
    end
    if esp.box3D then
        remove3DBox(c)
    end
    if esp.highlight then
        removeHighlight(c)
    end
    if esp.billboard then
        destroyESPChild(c, "ESP_Billboard")
    end
end

local ItemESP = {
    entries = {},
    active = false,
    color = Color3.fromRGB(0, 255, 255),
    connection = nil,
}

local function iecCreateLabel(part)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_ItemLabel"
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 2, 0)
    bb.ClipsDescendants = false
    bb.Parent = part
    local tl = Instance.new("TextLabel")
    tl.Name = "InfoLabel"
    tl.Size = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.TextColor3 = ItemESP.color
    tl.TextSize = 10
    tl.Font = Enum.Font.GothamBold
    tl.TextStrokeTransparency = 0
    tl.TextWrapped = true
    tl.Parent = bb
    return bb
end
local function iecCreateHighlight(inst)
    local hl = Instance.new("Highlight")
    hl.Name = "ESP_ItemHighlight"
    hl.Adornee = inst
    hl.FillColor = ItemESP.color
    hl.OutlineColor = ItemESP.color
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0.3
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = inst
    return hl
end
local function iecCreate2DBox(part)
    local bb = Instance.new("BillboardGui")
    bb.Name = "ESP_ItemBox2D"
    bb.Adornee = part
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromScale(3, 3)
    bb.ClipsDescendants = false
    bb.Parent = part
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 1, 0)
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Parent = bb
    local st = Instance.new("UIStroke")
    st.Thickness = 2
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Color = ItemESP.color
    st.Parent = f
    return bb
end

local function iecRender(entry, settings, dist, name)
    local esp = entry.esp or {}
    entry.esp = esp
    local part = entry.part
    if not part or not part.Parent then
        return
    end
    local function drop(k)
        if esp[k] then
            esp[k]:Destroy()
            esp[k] = nil
        end
    end
    if settings.Boxes then
        if not esp.box2D or not esp.box2D.Parent then
            esp.box2D = iecCreate2DBox(part)
        end
    else
        drop("box2D")
    end
    if settings.Highlights then
        if not esp.highlight or not esp.highlight.Parent then
            esp.highlight = iecCreateHighlight(entry.model)
        end
    else
        drop("highlight")
    end
    if settings.Names or settings.Distance then
        if not esp.label or not esp.label.Parent then
            esp.label = iecCreateLabel(part)
        end
        local lines = {}
        if settings.Names then
            table.insert(lines, name)
        end
        if settings.Distance then
            table.insert(lines, string.format("Distance: %.0f", dist))
        end
        esp.label.InfoLabel.Text = table.concat(lines, "\n")
    else
        drop("label")
    end
end

local function iecClear(entry)
    if entry.esp then
        for _, inst in pairs(entry.esp) do
            inst:Destroy()
        end
    end
    entry.esp = nil
end

local function iecUpdate()
    if not ECS then
        return
    end
    local settings = espSettings.Item
    local myPos = ecsMyPosition()
    local alive = {}
    for id in ECS.world:query(ECS.comps.Storable, ECS.comps.ObjectId, ECS.comps.ModelInstance) do
        local model = ecsGet(id, ECS.comps.ModelInstance)
        if model and model.Parent then
            local name = ecsGet(id, ECS.comps.ObjectId)
            local t = ecsGet(id, ECS.comps.Transform)
            local pos = t and (t.Position or t.p) or model:GetPivot().Position
            local part = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true) or model
            local dist = myPos and (pos - myPos).Magnitude or getDistanceFromCamera(pos)
            alive[model] = true
            local entry = ItemESP.entries[model]
            if not entry then
                entry = { model = model, part = part }
                ItemESP.entries[model] = entry
            else
                entry.part = part
            end
            iecRender(entry, settings, dist, name or model.Name)
        end
    end
    for model, entry in pairs(ItemESP.entries) do
        if not alive[model] then
            iecClear(entry)
            ItemESP.entries[model] = nil
        end
    end
end

local function iecClearAll()
    for _, entry in pairs(ItemESP.entries) do
        iecClear(entry)
    end
    ItemESP.entries = {}
end

local function iecStart()
    if ItemESP.active then
        return
    end
    ItemESP.active = true
    ItemESP.connection = RunService.RenderStepped:Connect(function()
        pcall(iecUpdate)
    end)
end
local function iecStop()
    if not ItemESP.active then
        return
    end
    ItemESP.active = false
    if ItemESP.connection then
        ItemESP.connection:Disconnect()
        ItemESP.connection = nil
    end
    iecClearAll()
end

local function cleanupKind(kind)
    for c, esp in pairs(espElements[kind]) do
        removeTargetESP(c, esp)
    end
    espElements[kind] = {}
end
local function cleanupTracerESP()
    for _, d in pairs(tracerEntries) do
        if d.pivot then
            d.pivot:Destroy()
        end
    end
    tracerEntries = {}
    if tracerGui then
        tracerGui:Destroy()
        tracerGui = nil
    end
end
local function cleanupAllESP()
    cleanupKind("Player")
    cleanupKind("Mob")
    iecClearAll()
    cleanupTracerESP()
end
local function getTracerGui()
    if tracerGui and tracerGui.Parent then
        return tracerGui
    end
    local g = Instance.new("ScreenGui")
    g.Name = "Tracer GUI"
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.DisplayOrder = -2147483648
    g.Parent = PlayerGui
    tracerGui = g
    return g
end
local function ensureTracer(key, col)
    local d = tracerEntries[key]
    if d and d.pivot and d.pivot.Parent then
        d.line.BackgroundColor3 = col
        return d
    end
    local pivot = Instance.new("Frame")
    pivot.Name = "Tracer"
    pivot.AnchorPoint = Vector2.new(0.5, 0.5)
    pivot.Position = UDim2.fromScale(0.5, 1)
    pivot.Size = UDim2.fromOffset(1, 1)
    pivot.BackgroundTransparency = 1
    pivot.Visible = false
    pivot.ZIndex = -2147483648
    pivot.Parent = getTracerGui()
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.AnchorPoint = Vector2.new(0.5, 1)
    line.Position = UDim2.fromScale(0.5, 0.5)
    line.Size = UDim2.fromOffset(2, 0)
    line.BackgroundColor3 = col
    line.BorderSizePixel = 0
    line.ZIndex = -2147483648
    line.Parent = pivot
    d = { pivot = pivot, line = line, lastPos = d and d.lastPos or nil }
    tracerEntries[key] = d
    return d
end
local function drawTracer(d, wp, col)
    local cam = workspace.CurrentCamera
    if not cam or not wp then
        d.pivot.Visible = false
        return
    end
    d.line.BackgroundColor3 = col
    local sp = cam:WorldToViewportPoint(wp)
    local vp = cam.ViewportSize
    local dx = sp.X - vp.X * 0.5
    local dy = sp.Y - vp.Y
    if sp.Z < 0 then
        dx = -dx
        dy = -dy
    end
    if dx ~= dx or dy ~= dy then
        d.pivot.Visible = false
        return
    end
    d.pivot.Visible = true
    d.pivot.Rotation = math.deg(math.atan2(dx, -dy))
    d.line.Size = UDim2.fromOffset(2, math.sqrt(dx * dx + dy * dy))
end
local function updateTracerESP()
    local pT, mT, iT = espSettings.Player.Tracers, espSettings.Mob.Tracers, espSettings.Item.Tracers
    if not pT and not mT and not iT then
        if next(tracerEntries) or tracerGui then
            cleanupTracerESP()
        end
        return
    end
    local alive = {}
    if pT then
        for _, pl in ipairs(Players:GetPlayers()) do
            if pl ~= LocalPlayer then
                alive[pl] = true
                local col = getPlayerESPColor(pl.Character and pl.Character:FindFirstChildOfClass("Humanoid"))
                local d = ensureTracer(pl, col)
                local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    d.lastPos = r.Position
                end
                if d.lastPos then
                    drawTracer(d, d.lastPos, col)
                else
                    d.pivot.Visible = false
                end
            end
        end
    end
    if mT then
        for m, h in pairs(trackedNPCs) do
            if m.Parent and h.Health > 0 then
                alive[m] = true
                local d = ensureTracer(m, mobColor)
                local r = m:FindFirstChild("HumanoidRootPart")
                if r then
                    d.lastPos = r.Position
                end
                if d.lastPos then
                    drawTracer(d, d.lastPos, mobColor)
                else
                    d.pivot.Visible = false
                end
            end
        end
    end
    if iT then
        for model, entry in pairs(ItemESP.entries) do
            if model.Parent and entry.part and entry.part.Parent then
                alive[model] = true
                local d = ensureTracer(model, ItemESP.color)
                d.lastPos = entry.part.Position
                drawTracer(d, entry.part.Position, ItemESP.color)
            end
        end
    end
    for k, d in pairs(tracerEntries) do
        if not alive[k] then
            d.pivot:Destroy()
            tracerEntries[k] = nil
        end
    end
end

local function updateTarget(kind, c, root, hum, col, dispName)
    local settings = espSettings[kind]
    local esp = espElements[kind][c]
    if not esp then
        esp = {}
        espElements[kind][c] = esp
    end
    local d = getDistanceFromCamera(root.Position)
    local sc = calculateBoxScale(d)
    local hp, mhp = hum.Health, hum.MaxHealth

    if settings.Boxes then
        if settings.BoxType == "2D" then
            if not esp.box2D or not esp.box2D.billboard.Parent then
                esp.box2D = create2DBox(c, col, sc)
            end
            update2DBox(esp.box2D, col, sc)
            if esp.box3D then
                remove3DBox(c)
                esp.box3D = nil
            end
        else
            if not esp.box3D or not esp.box3D.Parent then
                esp.box3D = create3DBox(c, col, Vector3.new(2, hum.HipHeight + 5, 2))
            end
            update3DBoxColor(c, col)
            if esp.box2D then
                remove2DBox(c)
                esp.box2D = nil
            end
        end
    else
        if esp.box2D then
            remove2DBox(c)
            esp.box2D = nil
        end
        if esp.box3D then
            remove3DBox(c)
            esp.box3D = nil
        end
    end
    if settings.Highlights then
        if not esp.highlight or not esp.highlight.Parent then
            esp.highlight = createHighlight(c, col)
        end
        updateHighlight(esp.highlight, col)
    elseif esp.highlight then
        removeHighlight(c)
        esp.highlight = nil
    end
    if settings.Names or settings.Distance or settings.Health or settings.State then
        if not esp.billboard or not esp.billboard.billboard.Parent then
            esp.billboard = createBillboard(c, col)
        end
        updateBillboard(
            esp.billboard,
            settings.Names and dispName or nil,
            settings.Distance and d or nil,
            col,
            settings.Health and hp or nil,
            settings.Health and mhp or nil,
            settings.State and getCharacterState(c) or nil
        )
    elseif esp.billboard then
        destroyESPChild(c, "ESP_Billboard")
        esp.billboard = nil
    end
end
local function sweepKind(kind, curr)
    for c, esp in pairs(espElements[kind]) do
        if not curr[c] then
            removeTargetESP(c, esp)
            espElements[kind][c] = nil
        end
    end
end
local function updatePlayerESP()
    local curr = {}
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer then
            local c = pl.Character
            local r = c and c:FindFirstChild("HumanoidRootPart")
            local h = c and c:FindFirstChildOfClass("Humanoid")
            if r and h then
                curr[c] = true
                updateTarget("Player", c, r, h, getPlayerESPColor(h), pl.Name)
            end
        end
    end
    sweepKind("Player", curr)
end
local function updateMobESP()
    local curr = {}
    for m, h in pairs(trackedNPCs) do
        if not m.Parent then
            trackedNPCs[m] = nil
        else
            local r = m:FindFirstChild("HumanoidRootPart")
            if r and h.Health > 0 then
                curr[m] = true
                updateTarget("Mob", m, r, h, mobColor, m:GetAttribute("EntityName") or m.Name)
            end
        end
    end
    sweepKind("Mob", curr)
end
local function hasEnabledOption(s)
    for k, v in pairs(s) do
        if k ~= "BoxType" and v then
            return true
        end
    end
    return false
end
local function onESPRenderStepped()
    if not workspace.CurrentCamera then
        return
    end
    if hasEnabledOption(espSettings.Player) then
        updatePlayerESP()
    else
        cleanupKind("Player")
    end
    if hasEnabledOption(espSettings.Mob) then
        updateMobESP()
    else
        cleanupKind("Mob")
    end
    updateTracerESP()
end
local function refreshESP()
    local mobNeeded = hasEnabledOption(espSettings.Mob)
    if mobNeeded and not mobTrackingActive then
        mobTrackingActive = true
        startNPCTracking()
    elseif not mobNeeded and mobTrackingActive then
        mobTrackingActive = false
        stopNPCTracking()
        cleanupKind("Mob")
    end

    local itemNeeded = hasEnabledOption(espSettings.Item)
    if itemNeeded then
        iecStart()
    else
        iecStop()
    end

    local anyEnabled = mobNeeded or itemNeeded or hasEnabledOption(espSettings.Player)
    if anyEnabled and not espConnection then
        espConnection = RunService.RenderStepped:Connect(onESPRenderStepped)
    elseif not anyEnabled and espConnection then
        espConnection:Disconnect()
        espConnection = nil
        cleanupAllESP()
    end
end
local function stopESP()
    for _, s in pairs(espSettings) do
        for k in pairs(s) do
            if k ~= "BoxType" then
                s[k] = false
            end
        end
    end
    refreshESP()
    cleanupAllESP()
end
local function addESPToggle(kind, key, title, flag, desc)
    return Tabs.ESP:Toggle({
        Title = title,
        Flag = flag,
        Desc = desc,
        Value = false,
        Callback = function(s)
            espSettings[kind][key] = s
            refreshESP()
        end,
    })
end
local function addESPBoxType(kind, title, flag)
    return Tabs.ESP:Dropdown({
        Title = title,
        Flag = flag,
        Values = { "2D", "3D" },
        Value = "2D",
        Callback = function(v)
            espSettings[kind].BoxType = v
        end,
    })
end

local tracerWarning = "Warning: this may hurt performance and make the game laggy."

Tabs.ESP:Section({ Title = "Player ESP", TextSize = 20 })
Tabs.ESP:Divider()
addESPToggle("Player", "Names", "Player Names", "PlayerNames")
addESPToggle("Player", "Boxes", "Player Boxes", "PlayerBoxes")
addESPBoxType("Player", "Player Box Type", "PlayerBoxType")
addESPToggle("Player", "Distance", "Player Distance", "PlayerDistance")
addESPToggle("Player", "Health", "Player Health", "PlayerHealth")
addESPToggle("Player", "State", "Player State", "PlayerState")
addESPToggle("Player", "Highlights", "Player Highlights", "PlayerHighlights")
addESPToggle("Player", "Tracers", "Player Tracers", "PlayerTracerESP", tracerWarning)

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "Mob ESP", TextSize = 20 })
Tabs.ESP:Divider()
addESPToggle("Mob", "Names", "Mob Names", "MobNames")
addESPToggle("Mob", "Boxes", "Mob Boxes", "MobBoxes")
addESPBoxType("Mob", "Mob Box Type", "MobBoxType")
addESPToggle("Mob", "Distance", "Mob Distance", "MobDistance")
addESPToggle("Mob", "Health", "Mob Health", "MobHealth")
addESPToggle("Mob", "State", "Mob State", "MobState")
addESPToggle("Mob", "Highlights", "Mob Highlights", "MobHighlights")
addESPToggle("Mob", "Tracers", "Mob Tracers", "MobTracerESP", tracerWarning)

Tabs.ESP:Divider()
Tabs.ESP:Section({ Title = "Item ESP", TextSize = 20 })
Tabs.ESP:Divider()
addESPToggle("Item", "Names", "Item Names", "ItemNames")
addESPToggle("Item", "Boxes", "Item Boxes", "ItemBoxes")
addESPToggle("Item", "Distance", "Item Distance", "ItemDistance")
addESPToggle("Item", "Highlights", "Item Highlights", "ItemHighlights")
addESPToggle("Item", "Tracers", "Item Tracers", "ItemTracerESP", tracerWarning)

local cameraCleanup
do
    local CAMERA_FOV_KEY = "DaraHubFov"
    local cameraModule
    local function getCameraController()
        if cameraModule == nil then
            local ok, m = pcall(function()
                return require(ReplicatedStorage.Shared.Universe.Camera)
            end)
            cameraModule = ok and m or false
        end
        return cameraModule and cameraModule.Instance or nil
    end
    Tabs.Visuals:Space()
    Tabs.Visuals:Divider()
    Tabs.Visuals:Section({ Title = "Game Camera", TextSize = 20 })
    Tabs.Visuals:Divider()

    local thirdPersonConnection, thirdPersonActive, thirdPersonOriginal
    local function stopThirdPerson()
        if thirdPersonConnection then
            thirdPersonConnection:Disconnect()
            thirdPersonConnection = nil
        end
        if thirdPersonActive then
            thirdPersonActive = false
            workspace:SetAttribute("IsThirdpersonAllowed", thirdPersonOriginal)
            local c = getCameraController()
            if c then
                c:DoZoom(0, true)
            end
        end
    end
    local function startThirdPerson()
        stopThirdPerson()
        local c = getCameraController()
        if not c then
            return false
        end
        thirdPersonActive = true
        thirdPersonOriginal = workspace:GetAttribute("IsThirdpersonAllowed")
        workspace:SetAttribute("IsThirdpersonAllowed", true)
        if c.Zoom < c.MinZoom then
            c:DoZoom(12, true)
        end
        thirdPersonConnection = RunService.Heartbeat:Connect(function()
            if workspace:GetAttribute("IsThirdpersonAllowed") ~= true then
                workspace:SetAttribute("IsThirdpersonAllowed", true)
            end
        end)
        return true
    end
    ForceThirdPersonToggle = Tabs.Visuals:Toggle({
        Title = "Force Third Person",
        Flag = "ForceThirdPersonToggle",
        Value = false,
        Callback = function(s)
            if s then
                if not startThirdPerson() then
                    WindUI:Notify({ Title = "Third Person", Content = "Game camera not found", Duration = 3 })
                    ForceThirdPersonToggle:Set(false)
                end
            else
                stopThirdPerson()
            end
        end,
    })

    local fovEnabled, fovTarget, fovConnection = false, 70, nil
    local function stopFov()
        if fovConnection then
            fovConnection:Disconnect()
            fovConnection = nil
        end
        local c = getCameraController()
        if c and c.fov then
            c.fov[CAMERA_FOV_KEY] = nil
        end
    end
    local function startFov()
        stopFov()
        fovConnection = RunService.RenderStepped:Connect(function()
            local c = getCameraController()
            if not c or not c.fov then
                return
            end
            local own = c.fov[CAMERA_FOV_KEY]
            if type(own) ~= "number" then
                own = 0
            end
            local others = c:GetFovAll() - own
            c:SetFov(CAMERA_FOV_KEY, fovTarget - others)
        end)
    end
    CustomFovToggle = Tabs.Visuals:Toggle({
        Title = "Custom FOV",
        Flag = "CustomFovToggle",
        Value = false,
        Callback = function(s)
            fovEnabled = s
            if s then
                startFov()
            else
                stopFov()
            end
        end,
    })
    CustomFovSlider = Tabs.Visuals:Slider({
        Title = "Field of View",
        Flag = "CustomFovSlider",
        Step = 1,
        Value = { Min = 1, Max = 120, Default = 70 },
        Callback = function(v)
            fovTarget = tonumber(v) or 70
        end,
    })

    local SENSITIVITY_KEY = "DaraHubSensitivity"
    local sensitivityValue, sensitivityConnection = 1, nil
    local function stopSensitivity()
        if sensitivityConnection then
            sensitivityConnection:Disconnect()
            sensitivityConnection = nil
        end
        local c = getCameraController()
        if c and c.sensitivities then
            c.sensitivities[SENSITIVITY_KEY] = nil
        end
    end
    local function startSensitivity()
        stopSensitivity()
        sensitivityConnection = RunService.Heartbeat:Connect(function()
            local c = getCameraController()
            if c and c.sensitivities and c.sensitivities[SENSITIVITY_KEY] ~= sensitivityValue then
                c.sensitivities[SENSITIVITY_KEY] = sensitivityValue
            end
        end)
    end
    local aim = {
        enabled = false,
        part = "Head",
        types = { Mob = true },
        smoothness = 10,
        maxDistance = 1000,
        wallCheck = false,
        showFov = false,
        fovRadius = 100,
        fovColor = Color3.fromRGB(0, 255, 0),
        tracking = false,
        bound = false,
    }
    local fovGui, fovCircle, fovStroke
    local function updateFovCircle()
        if not aim.showFov then
            if fovGui then
                fovGui.Enabled = false
            end
            return
        end
        if not fovGui or not fovGui.Parent then
            fovGui = Instance.new("ScreenGui")
            fovGui.Name = "DaraAimbotFOV"
            fovGui.ResetOnSpawn = false
            fovGui.IgnoreGuiInset = true
            fovGui.Parent = PlayerGui
            fovCircle = Instance.new("Frame")
            fovCircle.AnchorPoint = Vector2.new(0.5, 0.5)
            fovCircle.Position = UDim2.fromScale(0.5, 0.5)
            fovCircle.BackgroundTransparency = 1
            fovCircle.BorderSizePixel = 0
            fovCircle.Parent = fovGui
            local cr = Instance.new("UICorner")
            cr.CornerRadius = UDim.new(1, 0)
            cr.Parent = fovCircle
            fovStroke = Instance.new("UIStroke")
            fovStroke.Thickness = 2
            fovStroke.Parent = fovCircle
        end
        fovGui.Enabled = true
        fovCircle.Size = UDim2.fromOffset(aim.fovRadius * 2, aim.fovRadius * 2)
        fovStroke.Color = aim.fovColor
    end
    local function syncAimbotTracking()
        local needed = aim.enabled and aim.types.Mob == true
        if needed and not aim.tracking then
            aim.tracking = true
            startNPCTracking()
        elseif not needed and aim.tracking then
            aim.tracking = false
            stopNPCTracking()
        end
    end
    local function selectAimPart(c)
        if aim.part == "Head" then
            return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
        elseif aim.part == "Legs" then
            return c:FindFirstChild("LowerTorso")
                or c:FindFirstChild("Left Leg")
                or c:FindFirstChild("HumanoidRootPart")
        end
        return c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso") or c:FindFirstChild("Torso")
    end
    local function isVisible(cam, part, c)
        if not aim.wallCheck then
            return true
        end
        local ignore = { c }
        if Character then
            table.insert(ignore, Character)
        end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = ignore
        local o = cam.CFrame.Position
        return workspace:Raycast(o, part.Position - o, params) == nil
    end
    local function evaluate(cam, center, c, h)
        if not h or h.Health <= 0 then
            return nil
        end
        local p = selectAimPart(c)
        if not p then
            return nil
        end
        if (p.Position - cam.CFrame.Position).Magnitude > aim.maxDistance then
            return nil
        end
        local s, on = cam:WorldToViewportPoint(p.Position)
        if not on then
            return nil
        end
        local d = (Vector2.new(s.X, s.Y) - center).Magnitude
        if d > aim.fovRadius then
            return nil
        end
        if not isVisible(cam, p, c) then
            return nil
        end
        return p, d
    end
    local function aimStep(dt)
        if not aim.enabled then
            return
        end
        local ctrl = getCameraController()
        local cam = workspace.CurrentCamera
        if not ctrl or not cam or not ctrl.Rotations or not ctrl.Rotations.MouseLook then
            return
        end
        if not Humanoid or Humanoid.Health <= 0 then
            return
        end
        local center = cam.ViewportSize / 2
        local bestPart, bestDist
        if aim.types.Mob then
            for m, h in pairs(trackedNPCs) do
                if m.Parent then
                    local p, d = evaluate(cam, center, m, h)
                    if p and (not bestDist or d < bestDist) then
                        bestPart, bestDist = p, d
                    end
                end
            end
        end
        if not bestPart then
            return
        end
        local dir = bestPart.Position - ctrl:GetPositionCharacter()
        if dir.Magnitude < 0.001 then
            return
        end
        dir = dir.Unit
        local tPitch = math.deg(math.asin(math.clamp(dir.Y, -1, 1)))
        local tYaw = math.deg(math.atan2(-dir.X, -dir.Z))
        local cur = ctrl.Rotations.MouseLook
        local dYaw = ((tYaw - cur.Y + 180) % 360) - 180
        local dPitch = tPitch - cur.X
        local f = math.clamp(1 - (aim.smoothness / 20), 0.001, 1)
        local a = math.clamp(f * math.min(dt * 60, 1), 0, 1)
        ctrl.Rotations.MouseLook = Vector3.new(math.clamp(cur.X + dPitch * a, -80, 80), cur.Y + dYaw * a, cur.Z)
    end
    local function startAimbot()
        if aim.bound then
            return
        end
        aim.bound = true
        RunService:BindToRenderStep("DaraHubAimbot", Enum.RenderPriority.Camera.Value - 2, aimStep)
    end
    local function stopAimbot()
        if aim.bound then
            aim.bound = false
            pcall(function()
                RunService:UnbindFromRenderStep("DaraHubAimbot")
            end)
        end
    end

    Tabs.Combat:Space()
    Tabs.Combat:Section({ Title = "Aimbot", TextSize = 20 })
    Tabs.Combat:Divider()
    AimbotToggle = Tabs.Combat:Toggle({
        Title = "Aimbot",
        Flag = "AimbotToggle",
        Value = false,
        Callback = function(s)
            if s and not getCameraController() then
                WindUI:Notify({ Title = "Aimbot", Content = "Game camera not found", Duration = 3 })
                AimbotToggle:Set(false)
                return
            end
            aim.enabled = s
            if s then
                startAimbot()
            else
                stopAimbot()
            end
            syncAimbotTracking()
        end,
    })
    Tabs.Combat:Dropdown({
        Title = "Aim Part",
        Flag = "AimPartDropdown",
        Values = { "Head", "Body", "Legs" },
        Value = "Head",
        Callback = function(v)
            aim.part = v
        end,
    })
    Tabs.Combat:Slider({
        Title = "Smoothness",
        Flag = "AimSmoothnessSlider",
        Desc = "Higher = smoother aim",
        Step = 0.01,
        Value = { Min = 0.01, Max = 20, Default = 10 },
        Callback = function(v)
            aim.smoothness = tonumber(v) or 10
        end,
    })
    Tabs.Combat:Input({
        Title = "Aimbot Max Distance",
        Flag = "AimMaxDistanceInput",
        Placeholder = "1000",
        Value = tostring(aim.maxDistance),
        Callback = function(v)
            local n = tonumber(v)
            if n and n > 0 then
                aim.maxDistance = n
            end
        end,
    })
    Tabs.Combat:Toggle({
        Title = "Wall Check",
        Flag = "AimWallCheckToggle",
        Value = false,
        Callback = function(s)
            aim.wallCheck = s
        end,
    })
    Tabs.Combat:Space()
    Tabs.Combat:Section({ Title = "Aimbot FOV", TextSize = 20 })
    Tabs.Combat:Divider()
    Tabs.Combat:Toggle({
        Title = "Show FOV Circle",
        Flag = "AimShowFovToggle",
        Value = false,
        Callback = function(s)
            aim.showFov = s
            updateFovCircle()
        end,
    })
    Tabs.Combat:Slider({
        Title = "FOV Radius",
        Flag = "AimFovRadiusSlider",
        Step = 1,
        Value = { Min = 10, Max = 800, Default = 100 },
        Callback = function(v)
            aim.fovRadius = tonumber(v) or 100
            updateFovCircle()
        end,
    })
    Tabs.Combat:Colorpicker({
        Title = "FOV Circle Color",
        Flag = "AimFovColorPicker",
        Default = aim.fovColor,
        Callback = function(c)
            aim.fovColor = c
            updateFovCircle()
        end,
    })

    cameraCleanup = function()
        stopAimbot()
        aim.enabled = false
        syncAimbotTracking()
        if fovGui then
            fovGui:Destroy()
            fovGui = nil
        end
        stopThirdPerson()
        stopFov()
        stopSensitivity()
    end
end

Tabs.Misc:Section({ Title = "Utility", TextSize = 20 })
Tabs.Misc:Divider()
local antiAfkConnection
local function stopAntiAfk()
    if antiAfkConnection then
        antiAfkConnection:Disconnect()
        antiAfkConnection = nil
    end
end
AntiAfkToggle = Tabs.Misc:Toggle({
    Title = "Anti AFK",
    Flag = "AntiAfkToggle",
    Value = false,
    Callback = function(s)
        stopAntiAfk()
        if s then
            antiAfkConnection = LocalPlayer.Idled:Connect(function()
                local cam = workspace.CurrentCamera
                VirtualUser:Button2Down(Vector2.new(0, 0), cam.CFrame)
                task.wait(1)
                VirtualUser:Button2Up(Vector2.new(0, 0), cam.CFrame)
            end)
        end
    end,
})

Tabs.Misc:Space()
Tabs.Misc:Section({ Title = "Auto Pilot", TextSize = 20 })
Tabs.Misc:Divider()

local autopilot = {
    enabled = false,
    keybind = Enum.KeyCode.RightShift,
}

local autopilotControls
local autopilotPatched = setmetatable({}, { __mode = "k" })

local function isSitting()
    return Humanoid ~= nil and Humanoid.Health > 0 and Humanoid.Sit and Humanoid.SeatPart ~= nil
end

local function patchAutopilotController(controller)
    if not controller or autopilotPatched[controller] then
        return
    end
    autopilotPatched[controller] = true

    local originalGetMoveVector = controller.GetMoveVector
    controller.GetMoveVector = function(self, ...)
        local moveVector = originalGetMoveVector(self, ...)
        if not autopilot.enabled or not isSitting() then
            return moveVector
        end
        if not self:IsMoveVectorCameraRelative() then
            return moveVector
        end
        if moveVector.Magnitude > 0 then
            return moveVector
        end
        return Vector3.new(0, 0, -1)
    end
end

local function stopAutopilot()
    autopilot.enabled = false
    pcall(function()
        RunService:UnbindFromRenderStep("DaraHubAutoPilot")
    end)
end

local function startAutopilot()
    if not autopilotControls then
        local ok, controls = pcall(function()
            local pm = LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule", 5)
            return require(pm):GetControls()
        end)
        if not ok or not controls then
            return false
        end
        autopilotControls = controls
    end
    pcall(function()
        RunService:UnbindFromRenderStep("DaraHubAutoPilot")
    end)
    RunService:BindToRenderStep("DaraHubAutoPilot", Enum.RenderPriority.Input.Value - 1, function()
        patchAutopilotController(autopilotControls:GetActiveController())
    end)
    autopilot.enabled = true
    return true
end

local function setAutopilot(state)
    stopAutopilot()
    if state and not startAutopilot() then
        WindUI:Notify({ Title = "Auto Pilot", Content = "Could not load the control module", Duration = 3 })
        if AutoPilotToggle then
            AutoPilotToggle:Set(false)
        end
    end
end

AutoPilotToggle = Tabs.Misc:Toggle({
    Title = "Auto Pilot",
    Flag = "AutoPilotToggle",
    Value = false,
    Callback = function(s)
        setAutopilot(s)
    end,
})

if Tabs.Misc.Keybind then
    Tabs.Misc:Keybind({
        Title = "Auto Pilot Keybind",
        Flag = "AutoPilotKeybind",
        Desc = "Press this key to toggle Auto Pilot",
        Value = "RightShift",
        Callback = function(key)
            local ok, code = pcall(function()
                return Enum.KeyCode[key]
            end)
            if ok and code then
                autopilot.keybind = code
            end
        end,
    })
end

ShowAutoPilotButtonToggle = Tabs.Misc:Toggle({
    Title = "Show Auto Pilot Button",
    Flag = "ShowAutoPilotButton",
    Value = false,
    Callback = function(state)
        if ButtonLib and ButtonLib.AutoPilotToggle then
            ButtonLib.AutoPilotToggle:SetVisible(state)
        end
    end,
})

function ScanObjectEntries(folder, requires)
    local entries, all = {}, {}
    if not folder then
        return entries
    end
    if not ECS then
        ECS = loadECS()
    end
    local compNames, hasNames = {}, false
    if ECS and type(ECS.comps) == "table" then
        for k, v in pairs(ECS.comps) do
            local t = type(v)
            if t == "table" or t == "function" or t == "userdata" or t == "number" then
                compNames[v] = tostring(k)
                hasNames = true
            end
        end
    end

    local function buildPath(module)
        local parts = {}
        local node = module.Parent
        while node and node ~= folder do
            table.insert(parts, 1, node.Name)
            node = node.Parent
        end
        if #parts == 0 then
            return nil
        end
        return table.concat(parts, " / ")
    end

    local function describe(module)
        local okR, data = pcall(require, module)
        if not okR or type(data) ~= "table" or type(data.components) ~= "table" then
            return nil, buildPath(module), nil
        end
        local displayName
        local caps = {}
        for comp, val in pairs(data.components) do
            local cname = compNames[comp]
            if cname then
                caps[cname] = true
                if cname == "Name" then
                    displayName = tostring(val)
                end
            end
        end
        if type(data.tags) == "table" then
            for _, tag in pairs(data.tags) do
                local tname = compNames[tag]
                if tname then
                    caps[tname] = true
                end
            end
        end
        return displayName, buildPath(module), caps
    end

    local seen, usedTitles, count = {}, {}, 0
    for _, d in ipairs(folder:GetDescendants()) do
        if d:IsA("ModuleScript") then
            local key = d:GetFullName()
            if not seen[key] then
                seen[key] = true
                local displayName, details, caps = describe(d)
                local title = displayName or d.Name
                if usedTitles[title] then
                    title = title .. " (" .. details .. ")"
                end
                if usedTitles[title] then
                    title = title .. " #" .. tostring(count)
                end
                usedTitles[title] = true
                local e = { Title = title, Id = d.Name, Desc = details }
                table.insert(all, e)
                local matches = true
                if requires and next(requires) ~= nil and caps and hasNames then
                    matches = false
                    for _, r in ipairs(requires) do
                        if caps[r] then
                            matches = true
                            break
                        end
                    end
                end
                if matches then
                    table.insert(entries, e)
                end
            end
            count += 1
            if count % 40 == 0 then
                task.wait()
            end
        end
    end
    if #entries == 0 then
        entries = all
    end
    table.sort(entries, function(x, y)
        return x.Title < y.Title
    end)
    return entries
end

function CreateListFilter(opts)
    local titleToId, idToTitle, selected = {}, {}, {}
    local dropdown

    local function toSet(values)
        local set = {}
        if type(values) == "table" then
            for _, n in ipairs(values) do
                local title = type(n) == "table" and n.Title or n
                if title ~= nil then
                    set[titleToId[tostring(title)] or tostring(title)] = true
                end
            end
        end
        return set
    end

    dropdown = opts.Tab:Dropdown({
        Title = opts.Title,
        Flag = opts.Flag,
        Desc = opts.Desc or "Empty = everything",
        Values = {},
        Value = {},
        Multi = true,
        AllowNone = true,
        SearchBarEnabled = true,
        Callback = function(v)
            selected = toSet(v)
            opts.OnChange(selected)
        end,
    })

    opts.Tab:Button({
        Title = "Refresh " .. opts.Title,
        Callback = function()
            local entries = opts.Scan()
            if #entries == 0 then
                WindUI:Notify({ Title = opts.Title, Content = "No items found", Duration = 3 })
                return
            end
            table.clear(titleToId)
            table.clear(idToTitle)
            local view = {}
            for _, e in ipairs(entries) do
                titleToId[e.Title] = e.Id
                idToTitle[e.Id] = e.Title
                table.insert(view, { Title = e.Title, Desc = e.Desc })
            end
            local sel = {}
            for id in pairs(selected) do
                if idToTitle[id] then
                    table.insert(sel, idToTitle[id])
                end
            end
            if dropdown and dropdown.Refresh then
                dropdown:Refresh(view, sel)
            end
            WindUI:Notify({ Title = opts.Title, Content = #entries .. " found", Duration = 3 })
        end,
    })

    return dropdown
end

local farmCleanup
do
    local farm = {
        collectAll = false,
        bond = false,
        minDistance = 15,
        filters = { bring = {}, nearby = {}, pickup = {} },
        filterNorm = { bring = {}, nearby = {}, pickup = {} },
        nearby = false,
        pickup = false,
        moneyBag = false,
        moneyBagDistance = 15,
        auraRange = 15,
        nearbyDistance = 15,
        delay = 0.25,
        bringDelay = 0.1,
        nearbyDelay = 0.1,
        pickupDelay = 0.1,
        bondDelay = 0.1,
        collectRun = 0,
        autoRetry = false,
        emptyPasses = 0,
        lastRetry = 0,
    }

    local function getMyPos()
        return ecsMyPosition()
    end

    local function retryRun()
        pcall(function()
            ReplicatedStorage.Shared.Universe.Network.RemoteEvent.ResetCharacter:FireServer()
        end)
        pcall(funct…