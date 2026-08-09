local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

print("Script carregado com sucesso!")
print("Aguardando 2 segundos...")
task.wait(2)

-- Botão flutuante
local screenGui = Instance.new("ScreenGui")
screenGui.Parent = player:WaitForChild("PlayerGui")

local toggleButton = Instance.new("TextButton")
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(0, 20, 1, -80)
toggleButton.Text = "⚡"
toggleButton.TextSize = 30
toggleButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleButton

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 150)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -75)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 2
mainFrame.BorderColor3 = Color3.fromRGB(120, 80, 255)
mainFrame.Visible = false
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 12)
mainCorner.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.Text = "⚡ GXD Control"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.new(0, 30, 0, 30)
closeButton.Position = UDim2.new(1, -35, 0, 5)
closeButton.Text = "✕"
closeButton.TextColor3 = Color3.fromRGB(255, 100, 100)
closeButton.BackgroundTransparency = 1
closeButton.TextSize = 18
closeButton.Parent = mainFrame

closeButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

local testButton = Instance.new("TextButton")
testButton.Size = UDim2.new(0.8, 0, 0, 45)
testButton.Position = UDim2.new(0.1, 0, 0, 50)
testButton.Text = "✅ Teste"
testButton.TextColor3 = Color3.fromRGB(255, 255, 255)
testButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
testButton.BorderColor3 = Color3.fromRGB(120, 80, 255)
testButton.BorderSizePixel = 1
testButton.TextSize = 15
testButton.Font = Enum.Font.Gotham
testButton.Parent = mainFrame

local testCorner = Instance.new("UICorner")
testCorner.CornerRadius = UDim.new(0, 8)
testCorner.Parent = testButton

testButton.MouseButton1Click:Connect(function()
    testButton.Text = "✅ Funciona!"
    testButton.BackgroundColor3 = Color3.fromRGB(60, 180, 60)
    print("Botão funcionou!")
end)

local isOpen = false

toggleButton.MouseButton1Click:Connect(function()
    isOpen = not isOpen
    mainFrame.Visible = isOpen
    if isOpen then
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    else
        toggleButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    end
end)

print("✅ Script teste carregado com sucesso!")
print("📱 Clique no ícone ⚡ para abrir")
