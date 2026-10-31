-- Eclipse Hub | Interface Lua para Roblox
-- Interface visual baseada no desenho fornecido. Os botões de jogos são apenas seletores;
-- liga aqui os teus próprios módulos legítimos em onGameSelected().

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "EclipseHub"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

gui.Parent = player:WaitForChild("PlayerGui")

local C = {
    background = Color3.fromRGB(12, 12, 12),
    panel = Color3.fromRGB(25, 25, 25),
    panel2 = Color3.fromRGB(32, 32, 32),
    stroke = Color3.fromRGB(210, 224, 226),
    text = Color3.fromRGB(245, 245, 245),
    muted = Color3.fromRGB(175, 175, 175),
}

local function round(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = instance
    return corner
end

local function outline(instance, thickness)
    local s = Instance.new("UIStroke")
    s.Color = C.stroke
    s.Thickness = thickness or 1.4
    s.Transparency = 0
    s.Parent = instance
    return s
end

local function makeLabel(parent, text, size, position, font, textSize)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Size = size
    label.Position = position
    label.Font = font or Enum.Font.Garamond
    label.TextSize = textSize or 18
    label.TextColor3 = C.text
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.Parent = parent
    return label
end

local function makeButton(parent, text, size, position, textSize)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = text
    b.Size = size
    b.Position = position
    b.BackgroundColor3 = C.panel2
    b.BackgroundTransparency = 0.1
    b.TextColor3 = C.text
    b.Font = Enum.Font.Garamond
    b.TextSize = textSize or 18
    b.Parent = parent
    round(b, 20)
    outline(b, 1.4)
    b.MouseEnter:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(48,48,48)}):Play()
    end)
    b.MouseLeave:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.12), {BackgroundColor3 = C.panel2}):Play()
    end)
    return b
end

-- Barra pequena que permanece visível quando o hub está fechado.
local pill = Instance.new("Frame")
pill.Name = "EclipseToggle"
pill.Size = UDim2.fromOffset(246, 51)
pill.Position = UDim2.new(0.5, -123, 0, 28)
pill.BackgroundColor3 = C.panel
pill.Parent = gui
round(pill, 26)
outline(pill, 1.5)

makeLabel(pill, "☾", UDim2.fromOffset(28, 42), UDim2.fromOffset(9, 4), Enum.Font.Garamond, 29)
makeLabel(pill, "Eclipse Hub", UDim2.fromOffset(126, 42), UDim2.fromOffset(36, 4), Enum.Font.Garamond, 24)
makeLabel(pill, "|", UDim2.fromOffset(12, 42), UDim2.fromOffset(163, 4), Enum.Font.Garamond, 24)
local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.fromOffset(45, 43)
toggleButton.Position = UDim2.new(1, -48, 0, 4)
toggleButton.BackgroundTransparency = 1
toggleButton.Text = "−"
toggleButton.TextColor3 = C.text
toggleButton.Font = Enum.Font.Gotham
toggleButton.TextSize = 32
toggleButton.Parent = pill

-- Painel principal.
local main = Instance.new("Frame")
main.Name = "MainPanel"
main.Size = UDim2.new(0.78, 0, 0.65, 0)
main.Position = UDim2.new(0.11, 0, 0.19, 0)
main.BackgroundColor3 = C.panel
main.BackgroundTransparency = 0.05
main.Parent = gui
round(main, 14)
outline(main, 1.5)

local sizeConstraint = Instance.new("UISizeConstraint")
sizeConstraint.MinSize = Vector2.new(360, 300)
sizeConstraint.MaxSize = Vector2.new(1200, 650)
sizeConstraint.Parent = main

local sidebar = Instance.new("Frame")
sidebar.Name = "Sidebar"
sidebar.BackgroundTransparency = 1
sidebar.Size = UDim2.new(0, 178, 1, -20)
sidebar.Position = UDim2.fromOffset(10, 10)
sidebar.Parent = main

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0, 2, 1, -116)
divider.Position = UDim2.new(1, -7, 0, 25)
divider.BackgroundColor3 = C.stroke
divider.BorderSizePixel = 0
divider.Parent = sidebar

local games = {"Blade Ball", "BloxStrike", "Doors", "Dead Rails", "Rivals", "MM2", "Sniper Arena"}
local selectedLabel = makeLabel(main, "Seleciona um jogo", UDim2.new(1, -220, 0, 34), UDim2.new(0, 205, 0, 54), Enum.Font.Garamond, 21)
selectedLabel.TextColor3 = C.muted

local hint = makeLabel(main, "O teu conteúdo aparece aqui", UDim2.new(1, -240, 0, 26), UDim2.new(0, 215, 0, 92), Enum.Font.Garamond, 16)
hint.TextColor3 = C.muted

local function onGameSelected(gameName)
    selectedLabel.Text = gameName
    hint.Text = "Espaço reservado para o módulo de " .. gameName
    -- Liga aqui a interface ou funcionalidade legítima correspondente.
end

for i, gameName in ipairs(games) do
    local button = makeButton(sidebar, gameName, UDim2.fromOffset(135, 39), UDim2.fromOffset(12, 10 + (i-1)*53), 18)
    button.Activated:Connect(function()
        onGameSelected(gameName)
    end)
end

-- Espaço extra, igual ao botão vazio do desenho.
local emptyButton = makeButton(sidebar, "", UDim2.fromOffset(135, 39), UDim2.fromOffset(12, 10 + #games*53), 18)
emptyButton.Text = "+"
emptyButton.TextColor3 = C.muted
emptyButton.Activated:Connect(function()
    hint.Text = "Adiciona um jogo à lista no código Lua"
end)

-- Cartão de perfil no canto inferior esquerdo.
local profile = Instance.new("Frame")
profile.Name = "ProfileCard"
profile.Size = UDim2.fromOffset(190, 62)
profile.Position = UDim2.new(0, -2, 1, -67)
profile.BackgroundColor3 = C.panel2
profile.BackgroundTransparency = 0.08
profile.Parent = sidebar
round(profile, 22)
outline(profile, 1.4)

local avatar = Instance.new("ImageLabel")
avatar.Name = "Avatar"
avatar.Size = UDim2.fromOffset(48, 48)
avatar.Position = UDim2.fromOffset(7, 7)
avatar.BackgroundColor3 = C.panel
avatar.Parent = profile
round(avatar, 24)
outline(avatar, 1.2)

-- Usa a miniatura do avatar do jogador atual.
task.spawn(function()
    local ok, imageUrl = pcall(function()
        local image, _ = Players:GetUserThumbnailAsync(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
        return image
    end)
    if ok then avatar.Image = imageUrl end
end)

makeLabel(profile, player.DisplayName, UDim2.new(1, -64, 0, 27), UDim2.fromOffset(58, 7), Enum.Font.Garamond, 17)
makeLabel(profile, "♧  Lifetime", UDim2.new(1, -64, 0, 20), UDim2.fromOffset(58, 32), Enum.Font.Garamond, 13).TextColor3 = C.muted

local minimize = makeButton(main, "−", UDim2.fromOffset(39, 39), UDim2.new(1, -105, 0, 19), 26)
local close = makeButton(main, "×", UDim2.fromOffset(39, 39), UDim2.new(1, -57, 0, 19), 24)

local isOpen = true
local function setOpen(open)
    isOpen = open
    main.Visible = open
    toggleButton.Text = open and "−" or "+"
end

toggleButton.Activated:Connect(function()
    setOpen(not isOpen)
end)
minimize.Activated:Connect(function()
    setOpen(false)
end)
close.Activated:Connect(function()
    setOpen(false)
end)

-- Arrastar a barra superior para reposicionar o hub.
local dragging = false
local dragInput, dragStart, startPos
pill.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = pill.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)
pill.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        pill.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
