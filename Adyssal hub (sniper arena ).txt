if getgenv then local g=getgenv();if g.SimpleSpy or g.Hydroxide or g.SimpleSpyV2 or g.SimpleSpyV3 then error('',0) end end;if _G.AbyssalCleanup then
    _G.__AbyssalReloading = true
    pcall(_G.AbyssalCleanup)
    _G.__AbyssalReloading = nil
end
_G.AbyssalGui = nil
_G.AbyssalCleanup = nil

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInput = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Teams = game:GetService("Teams")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Workspace = workspace
local HttpService = game:GetService("HttpService")
local hui = (gethui and gethui()) or CoreGui

local function safeHttpGet(url)
    if syn and syn.request then
        local ok, res = pcall(function() return syn.request({Url = url, Method = "GET"}).Body end)
        if ok and res and #res > 100 then return res end
    end
    if http_request then
        local ok, res = pcall(function() return http_request({Url = url, Method = "GET"}).Body end)
        if ok and res and #res > 100 then return res end
    end
    if request then
        local ok, res = pcall(function() return request({Url = url, Method = "GET"}).Body end)
        if ok and res and #res > 100 then return res end
    end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and res and #res > 100 then return res end
    return nil
end

local WINDUI_URL = "https://raw.githubusercontent.com/Footagesus/WindUI/releases/latest/download/main.lua"
local WINDUI_FALLBACK = "https://cdn.jsdelivr.net/gh/Footagesus/WindUI@latest/main.lua"
local WINDUI_CACHE = "AbyssalStandalone/windui.lua"

local function ensureFolder(p)
    if makefolder and isfolder and not isfolder(p) then pcall(makefolder, p) end
end

local source
if isfile and readfile and isfile(WINDUI_CACHE) then
    local ok, data = pcall(readfile, WINDUI_CACHE)
    if ok and type(data) == "string" and #data > 100000 then source = data end
end

if not source then
    source = safeHttpGet(WINDUI_URL) or safeHttpGet(WINDUI_FALLBACK)
    if source and writefile then
        pcall(function()
            ensureFolder("AbyssalStandalone")
            writefile(WINDUI_CACHE, source)
        end)
    end
end

if not source then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Load Error", Text = "Failed to download WindUI.", Duration = 10,
    })
    return
end

local chunk = loadstring(source)
assert(chunk, "Failed to compile WindUI")
local WindUI = chunk()

--=========================================================== TEMA
WindUI:AddTheme({
    Name = "AbyssalTheme",
    Background = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#161619"), Transparency = 0.12 },
        ["100"] = { Color = Color3.fromHex("#161619"), Transparency = 0.12 },
    }, { Rotation = 90 }),
    Accent = WindUI:Gradient({
        ["0"] = { Color = Color3.fromHex("#101014"), Transparency = 0 },
        ["100"] = { Color = Color3.fromHex("#2a2a32"), Transparency = 0 },
    }, { Rotation = 90 }),
    Dialog = Color3.fromHex("#141418"),
    Outline = Color3.fromHex("#ffffff"),
    Text = Color3.fromHex("#ffffff"),
    Placeholder = Color3.fromHex("#a1a1aa"),
    Button = Color3.fromHex("#3f3f46"),
    Icon = Color3.fromHex("#d4d4d8"),
    Toggle = Color3.fromHex("#ffffff"),
    Slider = Color3.fromHex("#ffffff"),
    Checkbox = Color3.fromHex("#ffffff"),
    SliderIcon = Color3.fromHex("#71717a"),
    Primary = Color3.fromHex("#ffffff"),
    PanelBackground = Color3.fromHex("#ffffff"),
    PanelBackgroundTransparency = 0.94,
    LabelBackground = Color3.fromHex("#000000"),
    LabelBackgroundTransparency = 0.8,
    ElementBackground = Color3.fromHex("#18181b"),
    ElementBackgroundTransparency = 0.3,
})
WindUI:SetTheme("AbyssalTheme")

--=========================================================== PENCERE
local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
local Window = WindUI:CreateWindow({
    Title = "Abyssal Hub Utilities",
    Icon = "rbxassetid://90699576484669",
    Author = "Sniper Arena",
    Folder = "AbyssalStandalone",
    
    Background = "https://raw.githubusercontent.com/abyssalhub/abyssalhubbyy/main/Gemini_Generated_Image_c8lt6cc8lt6cc8lt.jpg", 
    BackgroundImageTransparency = 0.35,
    
    Size = UDim2.fromOffset(math.max(560, math.min(850, viewport.X - 24)), math.max(350, math.min(560, viewport.Y - 24))),
    MaxSize = Vector2.new(850, 560),
    Theme = "AbyssalTheme",
    Resizable = true,
    ShadowTransparency = 0.3,
    Radius = 18,
    IconRadius = 1,
    IconSize = 27,
    SideBarWidth = 185,
    Topbar = { Height = 56, ButtonsType = "Default" },
})

local ICON_TILE = Color3.fromHex("#6E6E7B")

--=========================================================== STATE
local State = {
    AimbotEnabled = false,
    LockTeammates = true,
    DisableWallLock = true,
    AimbotFOV = 50,
    AimbotTargetPart = "Head",
    ShowFOV = true, 
    ESP = {
        BoxESP = false,
        OutlineESP = false,
        NameESP = false,
        DistanceESP = false,
        ESPTeammates = false
    }
}

local ESP_UPDATE_INTERVAL = 0.08
local AIMBOT_UPDATE_INTERVAL = 0.03
local espTick = 0
local aimTick = 0
local cachedTargets = {}

-- FOV Circle
local FOVCircle
pcall(function()
    if Drawing then
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Color = Color3.fromRGB(0, 162, 255)
        FOVCircle.Thickness = 1.5
        FOVCircle.NumSides = 64
        FOVCircle.Filled = false
        FOVCircle.Visible = true
    end
end)

--=========================================================== HELPER FUNCTIONS
local function isTeammate(p)
    return LocalPlayer.Team and p.Team == LocalPlayer.Team
end

local function isVisible(part)
    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
    rayParams.FilterType = Enum.RaycastFilterType.Blacklist
    local r = Workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position), rayParams)
    return r and r.Instance:IsDescendantOf(part.Parent)
end

local function getESPColor(p)
    if #Teams:GetChildren() > 0 and p.TeamColor then
        return p.TeamColor.Color
    end
    return Color3.fromRGB(0, 162, 255)
end

--=========================================================== UI SEKMELERİ
local Tabs = {
    Welcome = Window:Tab({
        Title = "Welcome",
        Icon = "house",
        IconColor = ICON_TILE,
        IconShape = "Square",
        Border = true,
    }),
    Aimbot = Window:Tab({
        Title = "Aimbot",
        Icon = "crosshair",
        IconColor = ICON_TILE,
        IconShape = "Square",
        Border = true,
    }),
    Visuals = Window:Tab({
        Title = "Visuals",
        Icon = "eye",
        IconColor = ICON_TILE,
        IconShape = "Square",
        Border = true,
    }),
}

--=========================================================== WELCOME TAB (DÜZELTİLDİ)
local WelcomeSec = Tabs.Welcome:Section({ Title = "Abyssal Hub Info" })

WelcomeSec:Paragraph({
    Title = "Founder",
    Desc = "@vx.xcx",
    Image = "rbxassetid://90699576484669",
    ImageSize = 30,
})

WelcomeSec:Paragraph({
    Title = "Discord Server",
    Desc = "Join Us!",
    Image = "rbxassetid://90699576484669",
    ImageSize = 30,
    Buttons = {
        {
            Icon = "copy",
            Title = "Copy Link",
            Callback = function()
                setclipboard("https://discord.gg/u6h8ynMcep")
                WindUI:Notify({ Title = "Copied!", Content = "Discord link copied.", Duration = 2, Icon = "check" })
            end
        }
    }
})

WelcomeSec:Paragraph({
    Title = "YouTube Channel",
    Desc = "Subscribe for the latest showcases.",
    Image = "rbxassetid://90699576484669",
    ImageSize = 30,
    Buttons = {
        {
            Icon = "copy",
            Title = "Copy Link",
            Callback = function()
                setclipboard("https://www.youtube.com/@AbyssalHubScripts")
                WindUI:Notify({ Title = "Copied!", Content = "YouTube link copied.", Duration = 2, Icon = "check" })
            end
        }
    }
})

WelcomeSec:Paragraph({
    Title = "Official Website",
    Desc = "i didnt add yet!",
    Image = "rbxassetid://90699576484669",
    ImageSize = 30,
    Buttons = {
        {
            Icon = "copy",
            Title = "Copy Link",
            Callback = function()
                setclipboard("will add soon!")
                WindUI:Notify({ Title = "Copied!", Content = "Website link copied.", Duration = 2, Icon = "check" })
            end
        }
    }
})


task.spawn(function()
    local InviteCode = "aJKTX6zMK7"
    local url = "https://discord.com/api/v10/invites/" .. InviteCode .. "?with_counts=true&with_expiration=true"
    local encodedUrl = HttpService:UrlEncode(url)
    
    local proxies = {
        "https://api.allorigins.win/raw?url=" .. encodedUrl,
        "https://corsproxy.io/?" .. encodedUrl,
        "https://api.codetabs.com/v1/proxy?quest=" .. encodedUrl
    }

    local data = nil
    for _, proxy in ipairs(proxies) do
        local body = safeHttpGet(proxy)
        if body then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(body)
            end)
            if ok and type(decoded) == "table" and decoded.guild then
                data = decoded
                break
            end
        end
    end

    if data and data.guild then
        local iconUrl = ""
        if data.guild.icon then
            iconUrl = "https://cdn.discordapp.com/icons/" .. data.guild.id .. "/" .. data.guild.icon .. ".png?size=256"
        end

        local DiscordInfo = WelcomeSec:Paragraph({
            Title = data.guild.name,
            Desc = ' <font color="#52525b">●</font> Members : ' .. tostring(data.approximate_member_count or "?") ..
                '\n <font color="#16a34a">●</font> Online : ' .. tostring(data.approximate_presence_count or "?"),
            Image = iconUrl ~= "" and iconUrl or "rbxassetid://90699576484669",
            ImageSize = 42,
        })

        WelcomeSec:Button({
            Title = "Update Discord Info",
            Desc = "Refresh the member count.",
            Callback = function()
                -- Yenileme işlemi
                WindUI:Notify({ Title = "Updating", Content = "Fetching latest Discord stats...", Duration = 3, Icon = "refresh-cw" })
            end
        })
    end
end)

--=========================================================== AIMBOT TAB
local AimSec = Tabs.Aimbot:Section({ Title = "Aimbot Settings" })

AimSec:Toggle({
    Title = "Enable Aimbot",
    Desc = "Locks onto the closest player in FOV.",
    Icon = "zap",
    Value = false,
    Callback = function(v) State.AimbotEnabled = v end,
})

AimSec:Toggle({
    Title = "Show FOV Circle",
    Desc = "Shows the aim circle on your screen.",
    Icon = "circle",
    Value = true,
    Callback = function(v) State.ShowFOV = v end,
})

AimSec:Toggle({
    Title = "Lock Teammates",
    Desc = "If disabled, aimbot will not target teammates.",
    Icon = "users",
    Value = true,
    Callback = function(v) State.LockTeammates = v end,
})

AimSec:Toggle({
    Title = "Disable Wall Lock",
    Desc = "Only locks onto visible targets (no shooting through walls).",
    Icon = "shield",
    Value = true,
    Callback = function(v) State.DisableWallLock = v end,
})

AimSec:Slider({
    Title = "FOV Radius",
    Desc = "Size of the aim circle.",
    Value = { Min = 10, Max = 500, Default = 50 },
    Step = 5,
    Callback = function(v) 
        State.AimbotFOV = v 
        print("[Abyssal] FOV changed to:", v)
    end,
})

AimSec:Dropdown({
    Title = "Target Part",
    Desc = "Which body part to aim at.",
    Values = {"Head", "Torso"},
    Value = "Head",
    Callback = function(v) State.AimbotTargetPart = v end,
})

--=========================================================== VISUALS TAB
local VisSec = Tabs.Visuals:Section({ Title = "ESP Settings" })

VisSec:Toggle({
    Title = "Box ESP",
    Desc = "Draws a box around players.",
    Icon = "box",
    Value = false,
    Callback = function(v) State.ESP.BoxESP = v end,
})

VisSec:Toggle({
    Title = "Outline ESP",
    Desc = "Highlights players through walls.",
    Icon = "user",
    Value = false,
    Callback = function(v) State.ESP.OutlineESP = v end,
})

VisSec:Toggle({
    Title = "Name ESP",
    Desc = "Shows player names.",
    Icon = "type",
    Value = false,
    Callback = function(v) State.ESP.NameESP = v end,
})

VisSec:Toggle({
    Title = "Distance ESP",
    Desc = "Shows distance to players.",
    Icon = "map-pin",
    Value = false,
    Callback = function(v) State.ESP.DistanceESP = v end,
})

VisSec:Toggle({
    Title = "Team ESP",
    Desc = "Also show your teammates.",
    Icon = "users",
    Value = false,
    Callback = function(v) State.ESP.ESPTeammates = v end,
})

--=========================================================== ESP KURULUMU
local ESPTable = {}

local function createESP(player)
    if player == LocalPlayer then return end
    local function onChar(char)
        local root = char:WaitForChild("HumanoidRootPart", 5)
        if not root then return end

        local box = Instance.new("BoxHandleAdornment", Workspace)
        box.Adornee = char
        box.Size = Vector3.new(4, 6, 2)
        box.AlwaysOnTop = true
        box.ZIndex = 5
        box.Transparency = 0.6

        local outline = Instance.new("Highlight", Workspace)
        outline.Adornee = char
        outline.FillTransparency = 1
        outline.OutlineTransparency = 0
        outline.OutlineColor = Color3.fromRGB(0, 162, 255)
        outline.Enabled = false

        local bb = Instance.new("BillboardGui", Workspace)
        bb.Adornee = root
        bb.Size = UDim2.new(0, 120, 0, 40)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true

        local txt = Instance.new("TextLabel", bb)
        txt.Size = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.Font = Enum.Font.GothamBold
        txt.TextSize = 12

        ESPTable[player] = {Box = box, Outline = outline, BB = bb, TXT = txt, Root = root, Char = char}
    end

    if player.Character then onChar(player.Character) end
    player.CharacterAdded:Connect(onChar)
end

local PlayerCache = {}
local visibilityCache = {}
local rayTick = 0
local RAY_INTERVAL = 0.12

local function addPlayer(p)
    if p ~= LocalPlayer then
        PlayerCache[p] = true
        createESP(p)
    end
end

local function removePlayer(p)
    PlayerCache[p] = nil
    visibilityCache[p] = nil
    if ESPTable[p] then
        for _, v in pairs(ESPTable[p]) do
            if typeof(v) == "Instance" then v:Destroy() end
        end
        ESPTable[p] = nil
    end
end

for _, p in ipairs(Players:GetPlayers()) do addPlayer(p) end
Players.PlayerAdded:Connect(addPlayer)
Players.PlayerRemoving:Connect(removePlayer)

--=========================================================== DYNAMIC ISLAND
local S = { islandGui = nil }

local function createDynamicIsland()
    if S.islandGui then pcall(function() S.islandGui:Destroy() end) end

    local gui = Instance.new("ScreenGui")
    gui.Name = "AbyssalDynamicIsland"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.DisplayOrder = 100000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = hui
    S.islandGui = gui

    local island = Instance.new("Frame")
    island.Name = "Island"
    island.AnchorPoint = Vector2.new(0.5, 0)
    island.Position = UDim2.new(0.5, 0, 0, 12)
    island.Size = UDim2.fromOffset(56, 32)
    island.BackgroundColor3 = Color3.fromRGB(10, 10, 13)
    island.BackgroundTransparency = 0.08
    island.BorderSizePixel = 0
    island.ClipsDescendants = true
    island.Parent = gui

    Instance.new("UICorner", island).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = 0.82
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = island

    local logo = Instance.new("ImageLabel")
    logo.Name = "Logo"
    logo.AnchorPoint = Vector2.new(0.5, 0.5)
    logo.Position = UDim2.new(0, 28, 0.5, 0)
    logo.Size = UDim2.fromOffset(18, 18)
    logo.BackgroundTransparency = 1
    logo.Image = "rbxassetid://90699576484669"
    logo.ImageColor3 = Color3.fromRGB(236, 236, 244)
    logo.Parent = island

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.AnchorPoint = Vector2.new(0, 0.5)
    title.Position = UDim2.new(0, 48, 0.5, 0)
    title.Size = UDim2.new(1, -104, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.fromRGB(236, 236, 244)
    title.Text = "Abyssal is hidden"
    title.TextTransparency = 1
    title.Parent = island

    local keyHint = Instance.new("Frame")
    keyHint.Name = "KeyHint"
    keyHint.AnchorPoint = Vector2.new(1, 0.5)
    keyHint.Position = UDim2.new(1, -8, 0.5, 0)
    keyHint.Size = UDim2.fromOffset(26, 20)
    keyHint.BackgroundColor3 = Color3.fromRGB(34, 34, 42)
    keyHint.BackgroundTransparency = 1
    keyHint.BorderSizePixel = 0
    keyHint.Parent = island
    Instance.new("UICorner", keyHint).CornerRadius = UDim.new(0, 6)

    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "KeyLabel"
    keyLabel.BackgroundTransparency = 1
    keyLabel.Size = UDim2.fromScale(1, 1)
    keyLabel.Font = Enum.Font.GothamBold
    keyLabel.TextSize = 11
    keyLabel.TextColor3 = Color3.fromRGB(200, 200, 212)
    keyLabel.Text = "K"
    keyLabel.TextTransparency = 1
    keyLabel.Parent = keyHint

    local openBtn = Instance.new("TextButton")
    openBtn.Name = "OpenBtn"
    openBtn.BackgroundTransparency = 1
    openBtn.Size = UDim2.fromScale(1, 1)
    openBtn.Text = ""
    openBtn.AutoButtonColor = false
    openBtn.Parent = island

    local collapsedSize = UDim2.fromOffset(56, 32)
    local expandedSize = UDim2.fromOffset(190, 32)

    local function expand()
        TweenService:Create(island, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = expandedSize }):Play()
        TweenService:Create(title, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
        TweenService:Create(keyLabel, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { TextTransparency = 0 }):Play()
        TweenService:Create(keyHint, TweenInfo.new(0.2, Enum.EasingStyle.Quad), { BackgroundTransparency = 0.2 }):Play()
    end

    local function collapse()
        TweenService:Create(island, TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = collapsedSize }):Play()
        TweenService:Create(title, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
        TweenService:Create(keyLabel, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { TextTransparency = 1 }):Play()
        TweenService:Create(keyHint, TweenInfo.new(0.15, Enum.EasingStyle.Quad), { BackgroundTransparency = 1 }):Play()
    end

    local hovering = false
    island.MouseEnter:Connect(function() hovering = true expand() end)
    island.MouseLeave:Connect(function() hovering = false collapse() end)

    local function openUI()
        if S.islandGui then pcall(function() S.islandGui:Destroy() end) S.islandGui = nil end
        if _G.AbyssalGui then _G.AbyssalGui:Open() end
    end

    openBtn.MouseButton1Click:Connect(openUI)
    openBtn.TouchTap:Connect(openUI)

    task.spawn(function()
        task.wait(2.4)
        if not hovering and S.islandGui == gui then
            expand()
            task.wait(2)
            if not hovering and S.islandGui == gui then collapse() end
        end
    end)

    island.Size = UDim2.fromOffset(0, 32)
    TweenService:Create(island, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = collapsedSize }):Play()
end

local function hideWindow()
    if _G.AbyssalGui then pcall(function() _G.AbyssalGui:Close() end) end
    createDynamicIsland()
end

UserInput.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if input.KeyCode ~= Enum.KeyCode.K then return end
    if UserInput:GetFocusedTextBox() then return end

    if S.islandGui then
        pcall(function() S.islandGui:Destroy() end)
        S.islandGui = nil
        if _G.AbyssalGui then _G.AbyssalGui:Open() end
    else
        hideWindow()
    end
end)

RunService.RenderStepped:Connect(function(dt)
    rayTick += dt
    espTick += dt
    aimTick += dt

    local doRay = rayTick >= RAY_INTERVAL
    if doRay then rayTick = 0 end

    local doESP = espTick >= ESP_UPDATE_INTERVAL
    if doESP then espTick = 0 end

    local doAimUpdate = aimTick >= AIMBOT_UPDATE_INTERVAL
    if doAimUpdate then aimTick = 0 end

    local camPos = Camera.CFrame.Position
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if FOVCircle then
        FOVCircle.Visible = State.ShowFOV and State.AimbotEnabled
        FOVCircle.Radius = State.AimbotFOV
        FOVCircle.Position = screenCenter
    end

    if doESP then
        for p, _ in pairs(PlayerCache) do
            local e = ESPTable[p]
            if e and e.Char and e.Root then
                local hum = e.Char:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    local teamOK = not isTeammate(p) or State.ESP.ESPTeammates
                    local color = getESPColor(p)

                    e.Box.Visible = State.ESP.BoxESP and teamOK
                    e.Box.Color3 = color

                    e.Outline.Enabled = State.ESP.OutlineESP and teamOK
                    e.Outline.OutlineColor = color

                    local bbEnabled = teamOK and (State.ESP.NameESP or State.ESP.DistanceESP)
                    e.BB.Enabled = bbEnabled

                    if bbEnabled then
                        local text = ""
                        if State.ESP.NameESP then text = p.Name end
                        if State.ESP.DistanceESP then
                            local d = math.floor((camPos - e.Root.Position).Magnitude)
                            text = text ~= "" and text .. " [" .. d .. "]" or d .. " studs"
                        end
                        e.TXT.Text = text
                        e.TXT.TextColor3 = color
                    end
                else
                    e.Box.Visible = false
                    e.Outline.Enabled = false
                    e.BB.Enabled = false
                end
            end
        end
    end

    if doAimUpdate then
        cachedTargets = {}
        for p, _ in pairs(PlayerCache) do
            local char = p.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                local targetName = State.AimbotTargetPart == "Head" and "Head" or "HumanoidRootPart"
                local part = char:FindFirstChild(targetName)

                if hum and hum.Health > 0 and part then
                    if not (State.LockTeammates and isTeammate(p)) then
                        local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                        if onScreen then
                            local dist = (Vector2.new(pos.X, pos.Y) - screenCenter).Magnitude
                            if dist <= State.AimbotFOV then
                                table.insert(cachedTargets, {part = part, dist = dist, player = p})
                            end
                        end
                    end
                end
            end
        end
        table.sort(cachedTargets, function(a, b) return a.dist < b.dist end)
    end

    if State.AimbotEnabled and #cachedTargets > 0 then
        for i = 1, math.min(3, #cachedTargets) do
            local data = cachedTargets[i]
            if State.DisableWallLock then
                if doRay then
                    visibilityCache[data.player] = isVisible(data.part)
                end
                if not visibilityCache[data.player] then
                    continue
                end
            end
            Camera.CFrame = CFrame.lookAt(camPos, data.part.Position)
            break
        end
    end
end)

_G.AbyssalGui = Window
Window:Open()
Window:SelectTab(1)

WindUI:Notify({
    Title = "Abyssal Hub Utilities",
    Content = "Loaded. Press [K] to hide.",
    Duration = 6,
    Icon = "check",
})
