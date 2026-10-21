-- Services
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- Remove existing GUI if present
local oldGui = CoreGui:FindFirstChild("LarpIDHub")
if oldGui then oldGui:Destroy() end

-- Create ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LarpIDHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(80, 80, 80)
UIStroke.Thickness = 1.5
UIStroke.Parent = MainFrame

-- Title
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundTransparency = 1
Title.Text = "ID Hub"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = MainFrame

-- User ID Label
local UserIdLabel = Instance.new("TextLabel")
UserIdLabel.Size = UDim2.new(0.8, 0, 0, 30)
UserIdLabel.Position = UDim2.new(0.1, 0, 0.25, 0)
UserIdLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
UserIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
UserIdLabel.Font = Enum.Font.Gotham
UserIdLabel.TextSize = 14
UserIdLabel.Text = "Universal ID: " .. tostring(LocalPlayer.UserId)
UserIdLabel.Parent = MainFrame

local UICorner1 = Instance.new("UICorner")
UICorner1.CornerRadius = UDim.new(0, 5)
UICorner1.Parent = UserIdLabel

-- Place ID Label
local PlaceIdLabel = Instance.new("TextLabel")
PlaceIdLabel.Size = UDim2.new(0.8, 0, 0, 30)
PlaceIdLabel.Position = UDim2.new(0.1, 0, 0.45, 0)
PlaceIdLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PlaceIdLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
PlaceIdLabel.Font = Enum.Font.Gotham
PlaceIdLabel.TextSize = 14
PlaceIdLabel.Text = "Place ID: " .. tostring(game.PlaceId)
PlaceIdLabel.Parent = MainFrame

local UICorner2 = Instance.new("UICorner")
UICorner2.CornerRadius = UDim.new(0, 5)
UICorner2.Parent = PlaceIdLabel

-- Copy Button (User ID)
local CopyUserBtn = Instance.new("TextButton")
CopyUserBtn.Size = UDim2.new(0.35, 0, 0, 30)
CopyUserBtn.Position = UDim2.new(0.1, 0, 0.7, 0)
CopyUserBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
CopyUserBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyUserBtn.Font = Enum.Font.GothamBold
CopyUserBtn.TextSize = 14
CopyUserBtn.Text = "Copy UID"
CopyUserBtn.Parent = MainFrame

local UICorner3 = Instance.new("UICorner")
UICorner3.CornerRadius = UDim.new(0, 5)
UICorner3.Parent = CopyUserBtn

-- Copy Button (Place ID)
local CopyPlaceBtn = Instance.new("TextButton")
CopyPlaceBtn.Size = UDim2.new(0.35, 0, 0, 30)
CopyPlaceBtn.Position = UDim2.new(0.55, 0, 0.7, 0)
CopyPlaceBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
CopyPlaceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CopyPlaceBtn.Font = Enum.Font.GothamBold
CopyPlaceBtn.TextSize = 14
CopyPlaceBtn.Text = "Copy PID"
CopyPlaceBtn.Parent = MainFrame

local UICorner4 = Instance.new("UICorner")
UICorner4.CornerRadius = UDim.new(0, 5)
UICorner4.Parent = CopyPlaceBtn

-- Copy Functionality
local function copyToClipboard(text)
    local success = pcall(function()
        if setclipboard then
            setclipboard(tostring(text))
        elseif tostring then
            tostring(text)
        end
    end)
end

CopyUserBtn.MouseButton1Click:Connect(function()
    copyToClipboard(LocalPlayer.UserId)
    CopyUserBtn.Text = "Copied!"
    task.wait(1)
    CopyUserBtn.Text = "Copy UID"
end)

CopyPlaceBtn.MouseButton1Click:Connect(function()
    copyToClipboard(game.PlaceId)
    CopyPlaceBtn.Text = "Copied!"
    task.wait(1)
    CopyPlaceBtn.Text = "Copy PID"
end)
