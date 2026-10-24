--// Script para descobrir o ID do Jogo

local GameId = game.GameId
local PlaceId = game.PlaceId
local GameName = game:GetService("MarketplaceService"):GetProductInfo(GameId).Name

local screen = Instance.new("ScreenGui")
screen.Name = "IDFinder"
screen.Parent = game:GetService("CoreGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.Parent = screen

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.Text = "Informações do Jogo"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.Parent = frame

local info = Instance.new("TextLabel")
info.Size = UDim2.new(0.9, 0, 0.6, 0)
info.Position = UDim2.new(0.05, 0, 0.25, 0)
info.BackgroundTransparency = 1
info.TextColor3 = Color3.fromRGB(200, 200, 200)
info.Font = Enum.Font.Code
info.TextSize = 14
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Text = "Nome: " .. GameName .. "\n\nGameId: " .. GameId .. "\nPlaceId: " .. PlaceId
info.Parent = frame

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.4, 0, 0, 30)
btn.Position = UDim2.new(0.3, 0, 0.8, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
btn.Text = "Copiar GameId"
btn.TextColor3 = Color3.fromRGB(255, 255, 255)
btn.Font = Enum.Font.GothamBold
btn.TextSize = 14
btn.Parent = frame

btn.MouseButton1Click:Connect(function()
    if setclipboard then
        setclipboard(tostring(GameId))
        btn.Text = "Copiado!"
        task.wait(2)
        btn.Text = "Copiar GameId"
    end
end)