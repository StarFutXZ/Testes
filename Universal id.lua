
--// ID HUB STANDALONE
--// Place ID + Universal ID + Copy
--// Made by @ronzy.exe on Discord

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local placeId = tostring(game.PlaceId)
local gameId = tostring(game.GameId)

local old = playerGui:FindFirstChild("StandaloneIDHub")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "StandaloneIDHub"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(320, 205)
frame.Position = UDim2.new(0.5, -160, 0.5, -102)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 29)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", frame)
stroke.Color = Color3.fromRGB(139, 92, 246)
stroke.Thickness = 1.5

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

make("TextLabel", {
    Size = UDim2.new(1, -50, 0, 38),
    Position = UDim2.fromOffset(14, 5),
    BackgroundTransparency = 1,
    Text = "ID HUB",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 19,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left
}, frame)

local close = make("TextButton", {
    Size = UDim2.fromOffset(30, 30),
    Position = UDim2.new(1, -38, 0, 8),
    BackgroundColor3 = Color3.fromRGB(55, 43, 66),
    Text = "X",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 14,
    Font = Enum.Font.GothamBold
}, frame)
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 7)
close.Activated:Connect(function() gui:Destroy() end)

local function addRow(y, labelText, value)
    make("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18),
        Position = UDim2.fromOffset(12, y),
        BackgroundTransparency = 1,
        Text = labelText,
        TextColor3 = Color3.fromRGB(175, 175, 195),
        TextSize = 11,
        Font = Enum.Font.GothamMedium,
        TextXAlignment = Enum.TextXAlignment.Left
    }, frame)

    local valueLabel = make("TextLabel", {
        Size = UDim2.new(1, -105, 0, 32),
        Position = UDim2.fromOffset(12, y + 18),
        BackgroundTransparency = 1,
        Text = value,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 15,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd
    }, frame)

    local copy = make("TextButton", {
        Size = UDim2.fromOffset(78, 29),
        Position = UDim2.new(1, -90, 0, y + 19),
        BackgroundColor3 = Color3.fromRGB(124, 76, 220),
        Text = "COPIAR",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 11,
        Font = Enum.Font.GothamBold
    }, frame)
    Instance.new("UICorner", copy).CornerRadius = UDim.new(0, 6)

    copy.Activated:Connect(function()
        local clipboard = setclipboard or toclipboard or set_clipboard
        if type(clipboard) == "function" then
            local ok = pcall(clipboard, value)
            if ok then
                copy.Text = "COPIADO!"
                task.delay(1.2, function()
                    if copy.Parent then copy.Text = "COPIAR" end
                end)
                return
            end
        end

        valueLabel.Text = value
        copy.Text = "SEM CLIPBOARD"
        task.delay(1.5, function()
            if copy.Parent then copy.Text = "COPIAR" end
        end)
    end)
end

addRow(48, "PLACE ID", placeId)
addRow(119, "UNIVERSAL ID / GAME ID", gameId)

make("TextLabel", {
    Size = UDim2.new(1, -20, 0, 15),
    Position = UDim2.new(0, 10, 1, -18),
    BackgroundTransparency = 1,
    Text = "STANDALONE • GAME IDS",
    TextColor3 = Color3.fromRGB(130, 130, 150),
    TextSize = 9,
    Font = Enum.Font.GothamMedium
}, frame)
