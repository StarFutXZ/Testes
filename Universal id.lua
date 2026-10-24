-- ============================================================
--  ROBLOX PLACE ID / UNIVERSE ID RESOLVER
--  made by @ronzy.exe on discord
--  join our discord server: https://discord.gg/76tHHGBrfz
-- ============================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer

-- ------------------------------------------------------------
--  HUB (ScreenGui)
-- ------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "LarpIdResolver"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(340, 260)
frame.Position = UDim2.new(0.5, -170, 0.5, -130)
frame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(60, 200, 120)
stroke.Thickness = 1.5
stroke.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "ID RESOLVER"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Parent = frame

-- ------------------------------------------------------------
--  Campo Place ID + botão Resolver
-- ------------------------------------------------------------
local placeBox = Instance.new("TextBox")
placeBox.Size = UDim2.new(1, -40, 0, 34)
placeBox.Position = UDim2.new(0, 20, 0, 50)
placeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
placeBox.BorderSizePixel = 0
placeBox.Font = Enum.Font.Gotham
placeBox.PlaceholderText = "Cole o Place ID aqui..."
placeBox.Text = tostring(game.PlaceId)
placeBox.TextColor3 = Color3.fromRGB(255, 255, 255)
placeBox.TextSize = 14
placeBox.ClearTextOnFocus = false
placeBox.Parent = frame

local placeCorner = Instance.new("UICorner")
placeCorner.CornerRadius = UDim.new(0, 6)
placeCorner.Parent = placeBox

local resolveBtn = Instance.new("TextButton")
resolveBtn.Size = UDim2.new(1, -40, 0, 34)
resolveBtn.Position = UDim2.new(0, 20, 0, 94)
resolveBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
resolveBtn.BorderSizePixel = 0
resolveBtn.Font = Enum.Font.GothamBold
resolveBtn.Text = "RESOLVER"
resolveBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
resolveBtn.TextSize = 14
resolveBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = resolveBtn

-- ------------------------------------------------------------
--  Painel de resultado + botão Copiar
-- ------------------------------------------------------------
local resultFrame = Instance.new("Frame")
resultFrame.Size = UDim2.new(1, -40, 0, 56)
resultFrame.Position = UDim2.new(0, 20, 0, 140)
resultFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
resultFrame.BorderSizePixel = 0
resultFrame.Parent = frame

local resCorner = Instance.new("UICorner")
resCorner.CornerRadius = UDim.new(0, 6)
resCorner.Parent = resultFrame

local resultLabel = Instance.new("TextLabel")
resultLabel.Size = UDim2.new(1, -50, 1, 0)
resultLabel.Position = UDim2.new(0, 10, 0, 0)
resultLabel.BackgroundTransparency = 1
resultLabel.Font = Enum.Font.Code
resultLabel.TextXAlignment = Enum.TextXAlignment.Left
resultLabel.Text = "Place: ...\nUniverse: ..."
resultLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
resultLabel.TextSize = 12
resultLabel.Parent = resultFrame

local copyBtn = Instance.new("TextButton")
copyBtn.Size = UDim2.new(0, 34, 0, 34)
copyBtn.Position = UDim2.new(1, -44, 0.5, -17)
copyBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
copyBtn.BorderSizePixel = 0
copyBtn.Font = Enum.Font.GothamBold
copyBtn.Text = "⧉"
copyBtn.TextColor3 = Color3.fromRGB(10, 10, 10)
copyBtn.TextSize = 16
copyBtn.Parent = resultFrame

local copyCorner = Instance.new("UICorner")
copyCorner.CornerRadius = UDim.new(0, 6)
copyCorner.Parent = copyBtn

-- ------------------------------------------------------------
--  Status bar
-- ------------------------------------------------------------
local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -40, 0, 24)
status.Position = UDim2.new(0, 20, 1, -30)
status.BackgroundTransparency = 1
status.Font = Enum.Font.Gotham
status.Text = ""
status.TextColor3 = Color3.fromRGB(150, 150, 150)
status.TextSize = 11
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

-- ------------------------------------------------------------
--  Lógica: resolver universe id a partir do place id
--  (usa a API pública de games; funciona em ambiente com HttpService)
-- ------------------------------------------------------------
local resolvedPlace, resolvedUniverse

local function setStatus(txt, color)
	status.Text = txt
	status.TextColor3 = color or Color3.fromRGB(150, 150, 150)
end

-- Fallback offline: se o executor tiver acesso ao servidor de módulos,
-- tenta ler o universe id a partir do próprio jogo.
local function localUniverse()
	local ok, uid = pcall(function()
		return game.GameId
	end)
	if ok and uid and uid ~= 0 then
		return uid
	end
	return nil
end

resolveBtn.MouseButton1Click:Connect(function()
	local pid = tonumber(placeBox.Text)
	if not pid then
		setStatus("Place ID inválido, mano.", Color3.fromRGB(220, 80, 80))
		return
	end

	setStatus("Consultando API...", Color3.fromRGB(200, 200, 120))

	local ok, data = pcall(function()
		return HttpService:JSONDecode(
			HttpService:GetAsync(
				("https://games.roblox.com/v1/games/multiget-place-details?placeIds=%d"):format(pid)
			)
		)
	end)

	if ok and type(data) == "table" and data[1] then
		resolvedPlace = pid
		resolvedUniverse = data[1].universeId
	else
		-- fallback: se for o jogo atual, usa GameId
		resolvedPlace = pid
		resolvedUniverse = localUniverse() or 0
	end

	resultLabel.Text = ("Place: %d\nUniverse: %d"):format(resolvedPlace, resolvedUniverse)
	setStatus("Resolvido. Copia aí.", Color3.fromRGB(60, 200, 120))
end)

-- ------------------------------------------------------------
--  Copiar (setclipboard)
-- ------------------------------------------------------------
copyBtn.MouseButton1Click:Connect(function()
	if not resolvedPlace then
		setStatus("Nada pra copiar ainda.", Color3.fromRGB(220, 80, 80))
		return
	end
	local payload = ("PlaceId=%d\nUniverseId=%d"):format(resolvedPlace, resolvedUniverse)
	local ok = pcall(function()
		setclipboard(payload)
	end)
	if ok then
		setStatus("Copiado, join our discord server: https://discord.gg/76tHHGBrfz", Color3.fromRGB(60, 200, 120))
	else
		setStatus("Executor sem setclipboard.", Color3.fromRGB(220, 80, 80))
	end
end)

setStatus("Pronto. Mete o ID e manda ver.", Color3.fromRGB(150, 150, 150))
