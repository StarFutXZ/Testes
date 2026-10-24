--[[
    Game/Place ID Finder + Copy Hub
    - Descobre UniverseId (Game ID) e PlaceId do jogo atual
    - Hub com botões pra copiar cada ID
    - Funciona em executors (Synapse/Delta/etc) ou via LocalScript em StarterPlayerScripts
]]

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- ========== API ==========
local function getPlaceId()
    return game.PlaceId
end

local function getUniverseIdFromPlace(placeId)
    local url = ("https://apis.roblox.com/universes/v1/places/%d/universe"):format(placeId)
    local ok, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not ok or not res then return nil, "HttpService bloqueado/erro" end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data then return nil, "JSON inválido" end
    return data.universeId
end

local function getUniverseIdFromGame(gameId)
    local url = ("https://games.roblox.com/v1/games?universeIds=%d"):format(gameId)
    local ok, res = pcall(function()
        return HttpService:GetAsync(url)
    end)
    if not ok or not res then return nil end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res) end)
    if not ok2 or not data or not data.data or not data.data[1] then return nil end
    return data.data[1].id
end

-- ========== UI ==========
local function makeHub()
    local old = player.PlayerGui:FindFirstChild("IDFinderHub")
    if old then old:Destroy() end

    local gui = Instance.new("ScreenGui")
    gui.Name = "IDFinderHub"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = player.PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 340, 0, 260)
    frame.Position = UDim2.new(0.5, -170, 0.5, -130)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    frame.BorderSizePixel = 0
    frame.Active = true
    frame.Draggable = true
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Thickness = 2
    stroke.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "ID FINDER HUB"
    title.TextColor3 = Color3.fromRGB(0, 200, 255)
    title.Font = Enum.Font.GothamBlack
    title.TextSize = 20
    title.Parent = frame

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.Text = "X"
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.BorderSizePixel = 0
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,6); cc.Parent = close
    close.Parent = frame
    close.MouseButton1Click:Connect(function() gui:Destroy() end)

    local function makeRow(labelText, yOffset, valueProvider)
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 200, 0, 22)
        lbl.Position = UDim2.new(0, 15, 0, yOffset)
        lbl.BackgroundTransparency = 1
        lbl.Text = labelText
        lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
        lbl.Font = Enum.Font.GothamSemibold
        lbl.TextSize = 14
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = frame

        local val = Instance.new("TextLabel")
        val.Size = UDim2.new(0, 300, 0, 22)
        val.Position = UDim2.new(0, 15, 0, yOffset + 22)
        val.BackgroundTransparency = 1
        val.Text = "..."
        val.TextColor3 = Color3.fromRGB(255, 255, 255)
        val.Font = Enum.Font.Code
        val.TextSize = 14
        val.TextXAlignment = Enum.TextXAlignment.Left
        val.Parent = frame

        local copy = Instance.new("TextButton")
        copy.Size = UDim2.new(0, 80, 0, 26)
        copy.Position = UDim2.new(1, -95, 0, yOffset + 20)
        copy.BackgroundColor3 = Color3.fromRGB(0, 150, 90)
        copy.Text = "COPIAR"
        copy.TextColor3 = Color3.new(1,1,1)
        copy.Font = Enum.Font.GothamBold
        copy.TextSize = 12
        copy.BorderSizePixel = 0
        local c2 = Instance.new("UICorner"); c2.CornerRadius = UDim.new(0,6); c2.Parent = copy
        copy.Parent = frame

        copy.MouseButton1Click:Connect(function()
            local v = valueProvider()
            if not v or v == "" then
                copy.Text = "VAZIO"
                task.wait(1); copy.Text = "COPIAR"; return
            end
            if setclipboard then
                setclipboard(tostring(v))
                copy.Text = "OK!"
            else
                copy.Text = "N/A"
            end
            task.wait(1); copy.Text = "COPIAR"
        end)

        return val, function(v) val.Text = tostring(v) end
    end

    local placeLabel, setPlace = makeRow("PLACE ID:", 55, function() return game.PlaceId end)
    local uniLabel,   setUni   = makeRow("UNIVERSE (GAME) ID:", 115, function() return uniLabel.Text end)

    -- resolve IDs
    setPlace(game.PlaceId)

    task.spawn(function()
        local uni = getUniverseIdFromPlace(game.PlaceId)
        if not uni then
            uni = getUniverseIdFromGame(game.PlaceId)
        end
        if uni then
            setUni(uni)
        else
            setUni("Não foi possível obter (HttpService/API).")
        end
    end)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -30, 0, 20)
    info.Position = UDim2.new(0, 15, 1, -30)
    info.BackgroundTransparency = 1
    info.Text = "Made by @ronzy.exe | discord.gg/76tHHGBrfz"
    info.TextColor3 = Color3.fromRGB(120, 120, 140)
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = frame

    return gui
end

-- ========== RUN ==========
local ok, err = pcall(makeHub)
if not ok then
    warn("[ID Finder] falhou: " .. tostring(err))
end

-- ========== API global opcional ==========
_G.IDFinder = {
    placeId = game.PlaceId,
    getUniverseId = getUniverseIdFromPlace,
}