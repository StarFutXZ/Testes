--[[
    ECLIPSE HUB — UI ONLY
    Reprodução inspirada na referência enviada:
    - Painel preto minimalista com contorno fino
    - Lista de jogos com scroll
    - Cartão de perfil e estado da key
    - Modo compacto/fechado
    - Janela arrastável
    - Sem funções de gameplay incluídas; os botões selecionam o jogo visualmente.

    Instalação: coloca este código num LocalScript em StarterPlayerScripts
    ou StarterGui no Roblox Studio.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then
    return
end

local PLAYER_GUI = player:WaitForChild("PlayerGui")

-- Limpa uma versão anterior do hub
local old = PLAYER_GUI:FindFirstChild("EclipseHubUI")
if old then
    old:Destroy()
end

local THEME = {
    Background = Color3.fromRGB(7, 7, 9),
    Surface = Color3.fromRGB(12, 12, 15),
    SurfaceHover = Color3.fromRGB(22, 22, 26),
    Border = Color3.fromRGB(70, 70, 76),
    BorderSoft = Color3.fromRGB(42, 42, 47),
    Text = Color3.fromRGB(242, 242, 245),
    Muted = Color3.fromRGB(145, 145, 153),
    Accent = Color3.fromRGB(255, 255, 255),
}

local GAMES = {
    "Blade Ball",
    "BloxStrike",
    "Doors",
    "Dead Rails",
    "Rivals",
    "MM2",
    "Sniper Arena",
}

local selectedGame = nil
local isOpen = true
local isDragging = false
local dragStart, startPosition

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function round(parent, radius)
    return make("UICorner", {
        CornerRadius = UDim.new(0, radius or 8)
    }, parent)
end

local function stroke(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or THEME.Border,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, parent)
end

local function tween(object, duration, properties)
    local animation = TweenService:Create(
        object,
        TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        properties
    )
    animation:Play()
    return animation
end

local gui = make("ScreenGui", {
    Name = "EclipseHubUI",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PLAYER_GUI)

-- O contentor principal
local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(330, 410),
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
    ClipsDescendants = true,
}, gui)
round(main, 12)
stroke(main, THEME.Border, 1, 0.08)

-- Cabeçalho
local header = make("Frame", {
    Name = "Header",
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
}, main)

local title = make("TextLabel", {
    Name = "Title",
    Position = UDim2.fromOffset(17, 0),
    Size = UDim2.new(1, -85, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "Eclipse Hub",
    TextColor3 = THEME.Text,
    TextSize = 17,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local closeButton = make("TextButton", {
    Name = "CloseButton",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -14, 0.5, 0),
    Size = UDim2.fromOffset(26, 26),
    BackgroundColor3 = THEME.Surface,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Font = Enum.Font.Gotham,
    Text = "−",
    TextColor3 = THEME.Text,
    TextSize = 20,
}, header)
round(closeButton, 7)
stroke(closeButton, THEME.BorderSoft, 1, 0.1)

local headerLine = make("Frame", {
    Position = UDim2.new(0, 14, 1, -1),
    Size = UDim2.new(1, -28, 0, 1),
    BackgroundColor3 = THEME.BorderSoft,
    BorderSizePixel = 0,
}, header)

-- Área principal
local body = make("Frame", {
    Name = "Body",
    Position = UDim2.fromOffset(14, 65),
    Size = UDim2.new(1, -28, 1, -151),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
}, main)

local sectionTitle = make("TextLabel", {
    Name = "SectionTitle",
    Size = UDim2.new(1, 0, 0, 22),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "Selecionar jogo",
    TextColor3 = THEME.Muted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, body)

local gameList = make("ScrollingFrame", {
    Name = "GameList",
    Position = UDim2.fromOffset(0, 28),
    Size = UDim2.new(1, 0, 1, -28),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = THEME.Border,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollingDirection = Enum.ScrollingDirection.Y,
}, body)

make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, gameList)

make("UIPadding", {
    PaddingRight = UDim.new(0, 3),
    PaddingBottom = UDim.new(0, 3),
}, gameList)

local gameButtons = {}

local function setSelected(gameName)
    selectedGame = gameName
    for name, button in pairs(gameButtons) do
        local active = name == gameName
        tween(button, 0.12, {
            BackgroundColor3 = active and THEME.SurfaceHover or THEME.Surface
        })
        local outline = button:FindFirstChildOfClass("UIStroke")
        if outline then
            tween(outline, 0.12, {
                Color = active and THEME.Text or THEME.BorderSoft,
                Transparency = active and 0.12 or 0.25,
            })
        end
        local indicator = button:FindFirstChild("Indicator")
        if indicator then
            indicator.Visible = active
        end
    end
    statusLabel.Text = gameName and ("Selecionado: " .. gameName) or "Seleciona um jogo"
end

for index, gameName in ipairs(GAMES) do
    local button = make("TextButton", {
        Name = gameName:gsub("%W", "") .. "Button",
        Size = UDim2.new(1, -4, 0, 37),
        BackgroundColor3 = THEME.Surface,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Font = Enum.Font.Gotham,
        Text = "",
        LayoutOrder = index,
    }, gameList)
    round(button, 7)
    stroke(button, THEME.BorderSoft, 1, 0.25)

    make("TextLabel", {
        Name = "GameName",
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -44, 1, 0),
        BackgroundTransparency = 1,
        Font = Enum.Font.Gotham,
        Text = gameName,
        TextColor3 = THEME.Text,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, button)

    local indicator = make("Frame", {
        Name = "Indicator",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(5, 5),
        BackgroundColor3 = THEME.Text,
        BorderSizePixel = 0,
        Visible = false,
    }, button)
    round(indicator, 5)

    button.MouseEnter:Connect(function()
        if selectedGame ~= gameName then
            tween(button, 0.12, {BackgroundColor3 = THEME.SurfaceHover})
        end
    end)
    button.MouseLeave:Connect(function()
        if selectedGame ~= gameName then
            tween(button, 0.12, {BackgroundColor3 = THEME.Surface})
        end
    end)
    button.Activated:Connect(function()
        setSelected(gameName)
    end)

    gameButtons[gameName] = button
end

-- Separador inferior
local footerLine = make("Frame", {
    Name = "FooterLine",
    Position = UDim2.new(0, 14, 1, -77),
    Size = UDim2.new(1, -28, 0, 1),
    BackgroundColor3 = THEME.BorderSoft,
    BorderSizePixel = 0,
}, main)

-- Cartão de perfil
local profile = make("Frame", {
    Name = "ProfileCard",
    Position = UDim2.new(0, 14, 1, -65),
    Size = UDim2.new(1, -28, 0, 50),
    BackgroundColor3 = THEME.Surface,
    BorderSizePixel = 0,
}, main)
round(profile, 8)
stroke(profile, THEME.BorderSoft, 1, 0.18)

local avatar = make("ImageLabel", {
    Name = "Avatar",
    Position = UDim2.fromOffset(9, 8),
    Size = UDim2.fromOffset(32, 32),
    BackgroundColor3 = Color3.fromRGB(28, 28, 32),
    BorderSizePixel = 0,
    Image = "",
}, profile)
round(avatar, 16)

task.spawn(function()
    local ok, image = pcall(function()
        return Players:GetUserThumbnailAsync(
            player.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size100x100
        )
    end)
    if ok and avatar.Parent then
        avatar.Image = image
    end
end)

make("TextLabel", {
    Name = "PlayerName",
    Position = UDim2.fromOffset(50, 7),
    Size = UDim2.new(1, -118, 0, 18),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = player.DisplayName,
    TextColor3 = THEME.Text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, profile)

make("TextLabel", {
    Name = "KeyStatus",
    Position = UDim2.fromOffset(50, 25),
    Size = UDim2.new(1, -118, 0, 14),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Lifetime",
    TextColor3 = THEME.Muted,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, profile)

local profileDot = make("Frame", {
    Name = "StatusDot",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(5, 5),
    BackgroundColor3 = Color3.fromRGB(220, 220, 225),
    BorderSizePixel = 0,
}, profile)
round(profileDot, 5)

-- Estado/seleção: texto pequeno e discreto
local statusLabel = make("TextLabel", {
    Name = "SelectionStatus",
    Position = UDim2.new(0, 14, 1, -91),
    Size = UDim2.new(1, -28, 0, 12),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "Seleciona um jogo",
    TextColor3 = THEME.Muted,
    TextSize = 9,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, main)

-- Cápsula apresentada quando o hub está fechado
local compact = make("TextButton", {
    Name = "CompactHub",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 24),
    Size = UDim2.fromOffset(142, 36),
    BackgroundColor3 = THEME.Background,
    BorderSizePixel = 0,
    AutoButtonColor = false,
    Text = "",
    Visible = false,
    ZIndex = 10,
}, gui)
round(compact, 18)
stroke(compact, THEME.Border, 1, 0.08)

make("Frame", {
    Name = "CompactDot",
    Position = UDim2.fromOffset(12, 14),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = THEME.Text,
    BorderSizePixel = 0,
    ZIndex = 11,
}, compact)
round(compact.CompactDot, 7)

make("TextLabel", {
    Name = "CompactTitle",
    Position = UDim2.fromOffset(26, 0),
    Size = UDim2.new(1, -52, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.GothamMedium,
    Text = "Eclipse Hub",
    TextColor3 = THEME.Text,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Center,
    ZIndex = 11,
}, compact)

make("TextLabel", {
    Name = "CompactExpand",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(10, 16),
    BackgroundTransparency = 1,
    Font = Enum.Font.Gotham,
    Text = "+",
    TextColor3 = THEME.Muted,
    TextSize = 15,
    ZIndex = 11,
}, compact)

local function setOpen(open)
    isOpen = open
    if open then
        compact.Visible = false
        main.Visible = true
        main.Size = UDim2.fromOffset(330, 30)
        tween(main, 0.22, {Size = UDim2.fromOffset(330, 410)})
    else
        tween(main, 0.16, {Size = UDim2.fromOffset(330, 0)})
        task.delay(0.16, function()
            if not isOpen and main.Parent then
                main.Visible = false
                compact.Visible = true
            end
        end)
    end
end

closeButton.Activated:Connect(function()
    setOpen(false)
end)

compact.Activated:Connect(function()
    setOpen(true)
end)

-- Arrastar o painel pelo cabeçalho
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = true
        dragStart = input.Position
        startPosition = main.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDragging and (
        input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch
    ) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        isDragging = false
    end
end)

-- Tecla RightShift alterna o painel no PC
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setOpen(not isOpen)
    end
end)

-- Seleção inicial opcional
setSelected(nil)
