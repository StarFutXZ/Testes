--// Script para descobrir o ID do Jogo (hub bonitão)
--// join our discord server: https://discord.gg/76tHHGBrfz
--// made by @ronzy.exe on discord

local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local GameId  = game.GameId
local PlaceId = game.PlaceId
local UniverseId = GameId
local GameName = "Desconhecido"

pcall(function()
	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(GameId)
	end)
	if ok and info and info.Name then
		GameName = info.Name
	end
end)

pcall(function()
	local raw = HttpService:GetAsync(
		("https://games.roblox.com/v1/games/multiget-place-details?placeIds=%d"):format(PlaceId)
	)
	local data = HttpService:JSONDecode(raw)
	if type(data) == "table" and data[1] and data[1].universeId then
		UniverseId = data[1].universeId
	end
end)

--// helpers de estilo
local function corner(parent, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 8)
	c.Parent = parent
	return c
end

local function stroke(parent, color, thickness)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(0, 120, 255)
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

local function gradient(parent, c1, c2, rot)
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(c1, c2)
	g.Rotation = rot or 90
	g.Parent = parent
	return g
end

local function padding(parent, p)
	local u = Instance.new("UIPadding")
	u.PaddingTop = UDim.new(0, p)
	u.PaddingBottom = UDim.new(0, p)
	u.PaddingLeft = UDim.new(0, p)
	u.PaddingRight = UDim.new(0, p)
	u.Parent = parent
	return u
end

--// UI
local screen = Instance.new("ScreenGui")
screen.Name = "IDFinder"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.IgnoreGuiInset = true
pcall(function() screen.Parent = game:GetService("CoreGui") end)
if not screen.Parent then
	screen.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
end

-- container principal
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 340, 0, 230)
frame.Position = UDim2.new(0.5, -170, 0.5, -115)
frame.BackgroundColor3 = Color3.fromRGB(22, 24, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.ClipsDescendants = true
frame.Parent = screen

corner(frame, 14)
stroke(frame, Color3.fromRGB(50, 140, 255), 1.5)
gradient(frame, Color3.fromRGB(30, 34, 44), Color3.fromRGB(16, 18, 24), 90)

-- sombra
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
shadow.Size = UDim2.new(1, 60, 1, 60)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://1316045217"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.55
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = 0
shadow.Parent = frame

-- barra de topo
local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
topBar.BackgroundTransparency = 1
topBar.Parent = frame
gradient(topBar, Color3.fromRGB(40, 90, 200), Color3.fromRGB(20, 40, 90), 0)

local dot = Instance.new("Frame")
dot.Size = UDim2.fromOffset(10, 10)
dot.Position = UDim2.new(0, 14, 0.5, -5)
dot.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
dot.Parent = topBar
corner(dot, 5)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 30, 0, 0)
title.BackgroundTransparency = 1
title.Text = "ID FINDER"
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 15
title.Parent = topBar

-- nome do jogo
local nameLabel = Instance.new("TextLabel")
nameLabel.Size = UDim2.new(1, -40, 0, 24)
nameLabel.Position = UDim2.new(0, 20, 0, 50)
nameLabel.BackgroundTransparency = 1
nameLabel.Text = GameName
nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
nameLabel.TextXAlignment = Enum.TextXAlignment.Left
nameLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
nameLabel.Font = Enum.Font.GothamMedium
nameLabel.TextSize = 13
nameLabel.Parent = frame

-- card de info
local card = Instance.new("Frame")
card.Size = UDim2.new(1, -40, 0, 60)
card.Position = UDim2.new(0, 20, 0, 80)
card.BackgroundColor3 = Color3.fromRGB(30, 34, 42)
card.BorderSizePixel = 0
card.Parent = frame
corner(card, 10)
stroke(card, Color3.fromRGB(70, 80, 100), 1)
padding(card, 10)

local info = Instance.new("TextLabel")
info.Size = UDim2.new(1, 0, 1, 0)
info.BackgroundTransparency = 1
info.Text = ("PlaceId: %d\nUniverseId: %d"):format(PlaceId, UniverseId)
info.TextColor3 = Color3.fromRGB(220, 220, 220)
info.Font = Enum.Font.Code
info.TextSize = 13
info.TextXAlignment = Enum.TextXAlignment.Left
info.TextYAlignment = Enum.TextYAlignment.Top
info.Parent = card

-- botões
local function makeBtn(text, icon, x, color1, color2, getValue)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.44, 0, 0, 36)
	btn.Position = UDim2.new(x, 0, 0, 152)
	btn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = false
	btn.Text = ""
	btn.Parent = frame
	corner(btn, 8)
	local g = gradient(btn, color1, color2, 90)

	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text = icon .. "  " .. text
	lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
	lbl.Font = Enum.Font.GothamBold
	lbl.TextSize = 12
	lbl.Parent = btn

	btn.MouseEnter:Connect(function()
		TweenService:Create(g, TweenInfo.new(0.15), {
			Color = ColorSequence.new(color1:Lerp(Color3.new(1,1,1), 0.2),
			                          color2:Lerp(Color3.new(1,1,1), 0.2))
		}):Play()
	end)
	btn.MouseLeave:Connect(function()
		TweenService:Create(g, TweenInfo.new(0.15), {
			Color = ColorSequence.new(color1, color2)
		}):Play()
	end)

	btn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(tostring(getValue()))
			lbl.Text = "✓  Copiado!"
			task.wait(1.5)
			lbl.Text = icon .. "  " .. text
		end
	end)
end

-- Botão 1: Place ID (azul)
makeBtn("Copiar PlaceId", "📍", 0.03,
	Color3.fromRGB(0, 120, 255), Color3.fromRGB(0, 70, 180),
	function() return PlaceId end)

-- Botão 2: Universe ID (verde)
makeBtn("Copiar UniverseId", "🌐", 0.53,
	Color3.fromRGB(60, 200, 120), Color3.fromRGB(30, 140, 80),
	function() return UniverseId end)

-- rodapé
local footer = Instance.new("TextLabel")
footer.Size = UDim2.new(1, -40, 0, 20)
footer.Position = UDim2.new(0, 20, 1, -26)
footer.BackgroundTransparency = 1
footer.Text = "join our discord server: discord.gg/76tHHGBrfz  •  @ronzy.exe"
footer.TextXAlignment = Enum.TextXAlignment.Center
footer.TextColor3 = Color3.fromRGB(90, 100, 120)
footer.Font = Enum.Font.Gotham
footer.TextSize = 10
footer.Parent = frame
