local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Módulo de Utilidades
local Utils = {}
function Utils:GetNPCS()
    local npcs = {}
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Model") and v:FindFirstChild("Humanoid") and not v:FindFirstChild("HumanoidRootPart") then
            if v.Name:lower():find("dummy") or v.Name:lower():find("npc") or v:FindFirstChild("Head") then
                table.insert(npcs, v)
            end
        end
    end
    return npcs
end

function Utils:GetClosestNPCToCenter(npcs)
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closest = nil
    local closestDist = math.huge
    
    for _, npc in pairs(npcs) do
        local rootPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
        if rootPart then
            local screenPos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
            if onScreen then
                local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = npc
                end
            end
        end
    end
    
    return closest, closestDist
end

-- Classe Aimbot
local Aimbot = {}
Aimbot.__index = Aimbot

function Aimbot.new()
    local self = setmetatable({}, Aimbot)
    self.enabled = false
    self.fovSize = 200
    self.smoothness = 5
    self.target = nil
    self.circle = nil
    self.connections = {}
    return self
end

function Aimbot:CreateFOVCircle()
    if self.circle then
        self.circle:Destroy()
        self.circle = nil
    end
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AimbotFOV"
    screenGui.Parent = player:WaitForChild("PlayerGui")
    screenGui.Enabled = self.enabled
    
    local circle = Instance.new("Frame")
    circle.Name = "FOVCircle"
    circle.Size = UDim2.new(0, self.fovSize, 0, self.fovSize)
    circle.Position = UDim2.new(0.5, -self.fovSize/2, 0.5, -self.fovSize/2)
    circle.BackgroundTransparency = 1
    circle.BorderSizePixel = 2
    circle.BorderColor3 = Color3.fromRGB(120, 80, 255)
    circle.Parent = screenGui
    circle.ZIndex = 999
    circle.Visible = self.enabled
    
    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(1, 0, 1, 0)
    glow.Position = UDim2.new(0, 0, 0, 0)
    glow.BackgroundTransparency = 0.85
    glow.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
    glow.BorderSizePixel = 0
    glow.Parent = circle
    
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 4, 0, 4)
    dot.Position = UDim2.new(0.5, -2, 0.5, -2)
    dot.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    dot.BackgroundTransparency = 0.3
    dot.BorderSizePixel = 0
    dot.Parent = circle
    
    self.circle = screenGui
    return screenGui
end

function Aimbot:Toggle(state)
    self.enabled = state
    if state then
        self:CreateFOVCircle()
        self:StartAimbot()
    else
        if self.circle then
            self.circle:Destroy()
            self.circle = nil
        end
        self:StopAimbot()
    end
end

function Aimbot:StartAimbot()
    if self.aimbotConnection then return end
    
    self.aimbotConnection = RunService.RenderStepped:Connect(function()
        if not self.enabled then return end
        
        local npcs = Utils:GetNPCS()
        local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        
        if self.circle then
            local circleFrame = self.circle:FindFirstChild("FOVCircle")
            if circleFrame then
                circleFrame.Size = UDim2.new(0, self.fovSize, 0, self.fovSize)
                circleFrame.Position = UDim2.new(0.5, -self.fovSize/2, 0.5, -self.fovSize/2)
            end
        end
        
        local closest, closestDist = Utils:GetClosestNPCToCenter(npcs)
        
        if closest and closestDist <= self.fovSize/2 then
            self.target = closest
            local head = closest:FindFirstChild("Head")
            if head then
                local targetPos = head.Position
                local currentPos = Camera.CFrame.Position
                local direction = (targetPos - currentPos).Unit
                
                local smoothFactor = math.max(0.1, 1 / self.smoothness)
                local newCFrame = CFrame.lookAt(
                    currentPos,
                    currentPos + (direction * 10),
                    Vector3.new(0, 1, 0)
                )
                
                Camera.CFrame = Camera.CFrame:Lerp(newCFrame, smoothFactor)
            end
        else
            self.target = nil
        end
    end)
end

function Aimbot:StopAimbot()
    if self.aimbotConnection then
        self.aimbotConnection:Disconnect()
        self.aimbotConnection = nil
    end
    self.target = nil
end

function Aimbot:Destroy()
    self:StopAimbot()
    if self.circle then
        self.circle:Destroy()
        self.circle = nil
    end
end

-- Classe ESP
local ESP = {}
ESP.__index = ESP

function ESP.new()
    local self = setmetatable({}, ESP)
    self.enabled = false
    self.espObjects = {}
    self.connections = {}
    return self
end

function ESP:CreateESPLine(startPos, endPos, color)
    local line = Drawing.new("Line")
    line.From = startPos
    line.To = endPos
    line.Color = color or Color3.fromRGB(120, 80, 255)
    line.Thickness = 1.5
    line.Transparency = 0.7
    line.Visible = true
    return line
end

function ESP:CreateText(text, position, color)
    local textObj = Drawing.new("Text")
    textObj.Text = text
    textObj.Position = position
    textObj.Color = color or Color3.fromRGB(255, 255, 255)
    textObj.Size = 14
    textObj.Center = true
    textObj.Outline = true
    textObj.OutlineColor = Color3.fromRGB(0, 0, 0)
    textObj.Visible = true
    return textObj
end

function ESP:Toggle(state)
    self.enabled = state
    if state then
        self:StartESP()
    else
        self:StopESP()
    end
end

function ESP:StartESP()
    if self.espConnection then return end
    
    self.espConnection = RunService.RenderStepped:Connect(function()
        if not self.enabled then return end
        
        for _, obj in pairs(self.espObjects) do
            if obj.Remove then
                obj:Remove()
            end
        end
        self.espObjects = {}
        
        local npcs = Utils:GetNPCS()
        
        for _, npc in pairs(npcs) do
            local rootPart = npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChild("Torso")
            local head = npc:FindFirstChild("Head")
            
            if rootPart and head then
                local pos, onScreen = Camera:WorldToViewportPoint(rootPart.Position)
                local headPos, headOnScreen = Camera:WorldToViewportPoint(head.Position)
                
                if onScreen and headOnScreen then
                    local line = self:CreateESPLine(
                        Vector2.new(pos.X, pos.Y),
                        Vector2.new(headPos.X, headPos.Y),
                        Color3.fromRGB(120, 80, 255)
                    )
                    table.insert(self.espObjects, line)
                    
                    local nameText = self:CreateText(
                        npc.Name,
                        Vector2.new(pos.X, pos.Y - 30),
                        Color3.fromRGB(255, 255, 255)
                    )
                    table.insert(self.espObjects, nameText)
                    
                    local distance = (Camera.CFrame.Position - rootPart.Position).Magnitude
                    local distText = self:CreateText(
                        string.format("%.1fm", distance),
                        Vector2.new(pos.X, pos.Y + 20),
                        Color3.fromRGB(120, 255, 120)
                    )
                    table.insert(self.espObjects, distText)
                    
                    local size = 3
                    local boxPoints = {
                        Vector2.new(pos.X - size, pos.Y - size),
                        Vector2.new(pos.X + size, pos.Y - size),
                        Vector2.new(pos.X + size, pos.Y + size),
                        Vector2.new(pos.X - size, pos.Y + size)
                    }
                    
                    for i = 1, #boxPoints do
                        local nextIndex = i % #boxPoints + 1
                        local boxLine = self:CreateESPLine(
                            boxPoints[i],
                            boxPoints[nextIndex],
                            Color3.fromRGB(80, 200, 255)
                        )
                        table.insert(self.espObjects, boxLine)
                    end
                end
            end
        end
    end)
end

function ESP:StopESP()
    if self.espConnection then
        self.espConnection:Disconnect()
        self.espConnection = nil
    end
    
    for _, obj in pairs(self.espObjects) do
        if obj.Remove then
            obj:Remove()
        end
    end
    self.espObjects = {}
end

function ESP:Destroy()
    self:StopESP()
end

-- Criar instâncias
local aimbot = Aimbot.new()
local esp = ESP.new()

-- Criar GUI principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainUIController"
screenGui.Parent = player:WaitForChild("PlayerGui")

-- ========== BOTÃO FLUTUANTE PARA ABRIR/FECHAR ==========
local toggleButton = Instance.new("ImageButton")
toggleButton.Name = "ToggleButton"
toggleButton.Size = UDim2.new(0, 60, 0, 60)
toggleButton.Position = UDim2.new(0, 20, 1, -80)
toggleButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
toggleButton.BackgroundTransparency = 0.1
toggleButton.BorderSizePixel = 0
toggleButton.Image = "rbxassetid://6031091071"
toggleButton.ImageColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.ScaleType = Enum.ScaleType.Fit
toggleButton.Parent = screenGui

local glowButton = Instance.new("Frame")
glowButton.Size = UDim2.new(1.3, 0, 1.3, 0)
glowButton.Position = UDim2.new(-0.15, 0, -0.15, 0)
glowButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
glowButton.BackgroundTransparency = 0.8
glowButton.BorderSizePixel = 0
glowButton.Parent = toggleButton

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = toggleButton

local cornerGlow = Instance.new("UICorner")
cornerGlow.CornerRadius = UDim.new(1, 0)
cornerGlow.Parent = glowButton

-- ========== MENU PRINCIPAL ==========
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 280, 0, 400)
mainFrame.Position = UDim2.new(0.5, -140, 0.5, -200)
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
title.Size = UDim2.new(1, 0, 0, 45)
title.Position = UDim2.new(0, 0, 0, 0)
title.Text = "⚡ GXD Control Center"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

local closeMenuButton = Instance.new("TextButton")
closeMenuButton.Size = UDim2.new(0, 30, 0, 30)
closeMenuButton.Position = UDim2.new(1, -35, 0, 8)
closeMenuButton.Text = "✕"
closeMenuButton.TextColor3 = Color3.fromRGB(255, 100, 100)
closeMenuButton.BackgroundTransparency = 1
closeMenuButton.TextSize = 18
closeMenuButton.Font = Enum.Font.GothamBold
closeMenuButton.Parent = mainFrame

closeMenuButton.MouseButton1Click:Connect(function()
    mainFrame.Visible = false
end)

local divider = Instance.new("Frame")
divider.Size = UDim2.new(0.9, 0, 0, 1)
divider.Position = UDim2.new(0.05, 0, 0, 45)
divider.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
divider.BackgroundTransparency = 0.5
divider.BorderSizePixel = 0
divider.Parent = mainFrame

local aimbotButton = Instance.new("TextButton")
aimbotButton.Size = UDim2.new(0.8, 0, 0, 45)
aimbotButton.Position = UDim2.new(0.1, 0, 0, 60)
aimbotButton.Text = "🔍 Aimbot: OFF"
aimbotButton.TextColor3 = Color3.fromRGB(255, 255, 255)
aimbotButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
aimbotButton.BorderColor3 = Color3.fromRGB(120, 80, 255)
aimbotButton.BorderSizePixel = 1
aimbotButton.TextSize = 15
aimbotButton.Font = Enum.Font.Gotham
aimbotButton.Parent = mainFrame

local aimbotCorner = Instance.new("UICorner")
aimbotCorner.CornerRadius = UDim.new(0, 8)
aimbotCorner.Parent = aimbotButton

aimbotButton.MouseButton1Click:Connect(function()
    aimbot:Toggle(not aimbot.enabled)
    aimbotButton.Text = aimbot.enabled and "🔍 Aimbot: ON" or "🔍 Aimbot: OFF"
    aimbotButton.BackgroundColor3 = aimbot.enabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(40, 40, 55)
end)

local espButton = Instance.new("TextButton")
espButton.Size = UDim2.new(0.8, 0, 0, 45)
espButton.Position = UDim2.new(0.1, 0, 0, 115)
espButton.Text = "👁️ ESP: OFF"
espButton.TextColor3 = Color3.fromRGB(255, 255, 255)
espButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
espButton.BorderColor3 = Color3.fromRGB(120, 80, 255)
espButton.BorderSizePixel = 1
espButton.TextSize = 15
espButton.Font = Enum.Font.Gotham
espButton.Parent = mainFrame

local espCorner = Instance.new("UICorner")
espCorner.CornerRadius = UDim.new(0, 8)
espCorner.Parent = espButton

espButton.MouseButton1Click:Connect(function()
    esp:Toggle(not esp.enabled)
    espButton.Text = esp.enabled and "👁️ ESP: ON" or "👁️ ESP: OFF"
    espButton.BackgroundColor3 = esp.enabled and Color3.fromRGB(60, 180, 60) or Color3.fromRGB(40, 40, 55)
end)

local fovLabel = Instance.new("TextLabel")
fovLabel.Size = UDim2.new(0.5, 0, 0, 25)
fovLabel.Position = UDim2.new(0.1, 0, 0, 175)
fovLabel.Text = "FOV: 200"
fovLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
fovLabel.BackgroundTransparency = 1
fovLabel.TextSize = 14
fovLabel.Font = Enum.Font.Gotham
fovLabel.TextXAlignment = Enum.TextXAlignment.Left
fovLabel.Parent = mainFrame

local fovSlider = Instance.new("TextBox")
fovSlider.Size = UDim2.new(0.3, 0, 0, 30)
fovSlider.Position = UDim2.new(0.6, 0, 0, 172)
fovSlider.Text = "200"
fovSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
fovSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
fovSlider.BorderColor3 = Color3.fromRGB(120, 80, 255)
fovSlider.BorderSizePixel = 1
fovSlider.TextSize = 14
fovSlider.Font = Enum.Font.Gotham
fovSlider.Parent = mainFrame

local fovSliderCorner = Instance.new("UICorner")
fovSliderCorner.CornerRadius = UDim.new(0, 6)
fovSliderCorner.Parent = fovSlider

fovSlider.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(fovSlider.Text)
        if value and value >= 50 and value <= 500 then
            aimbot.fovSize = value
            fovLabel.Text = "FOV: " .. value
        else
            fovSlider.Text = tostring(aimbot.fovSize)
        end
    end
end)

local smoothLabel = Instance.new("TextLabel")
smoothLabel.Size = UDim2.new(0.5, 0, 0, 25)
smoothLabel.Position = UDim2.new(0.1, 0, 0, 220)
smoothLabel.Text = "Smooth: 5"
smoothLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
smoothLabel.BackgroundTransparency = 1
smoothLabel.TextSize = 14
smoothLabel.Font = Enum.Font.Gotham
smoothLabel.TextXAlignment = Enum.TextXAlignment.Left
smoothLabel.Parent = mainFrame

local smoothSlider = Instance.new("TextBox")
smoothSlider.Size = UDim2.new(0.3, 0, 0, 30)
smoothSlider.Position = UDim2.new(0.6, 0, 0, 217)
smoothSlider.Text = "5"
smoothSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
smoothSlider.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
smoothSlider.BorderColor3 = Color3.fromRGB(120, 80, 255)
smoothSlider.BorderSizePixel = 1
smoothSlider.TextSize = 14
smoothSlider.Font = Enum.Font.Gotham
smoothSlider.Parent = mainFrame

local smoothSliderCorner = Instance.new("UICorner")
smoothSliderCorner.CornerRadius = UDim.new(0, 6)
smoothSliderCorner.Parent = smoothSlider

smoothSlider.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        local value = tonumber(smoothSlider.Text)
        if value and value >= 1 and value <= 20 then
            aimbot.smoothness = value
            smoothLabel.Text = "Smooth: " .. value
        else
            smoothSlider.Text = tostring(aimbot.smoothness)
        end
    end
end)

local closeScriptButton = Instance.new("TextButton")
closeScriptButton.Size = UDim2.new(0.8, 0, 0, 45)
closeScriptButton.Position = UDim2.new(0.1, 0, 0, 270)
closeScriptButton.Text = "❌ Fechar Script"
closeScriptButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeScriptButton.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
closeScriptButton.BorderColor3 = Color3.fromRGB(255, 50, 50)
closeScriptButton.BorderSizePixel = 1
closeScriptButton.TextSize = 15
closeScriptButton.Font = Enum.Font.Gotham
closeScriptButton.Parent = mainFrame

local closeScriptCorner = Instance.new("UICorner")
closeScriptCorner.CornerRadius = UDim.new(0, 8)
closeScriptCorner.Parent = closeScriptButton

closeScriptButton.MouseButton1Click:Connect(function()
    aimbot:Destroy()
    esp:Destroy()
    screenGui:Destroy()
end)

local credits = Instance.new("TextLabel")
credits.Size = UDim2.new(1, 0, 0, 25)
credits.Position = UDim2.new(0, 0, 1, -30)
credits.Text = "🔮 GXD Scripts v2.0"
credits.TextColor3 = Color3.fromRGB(100, 100, 120)
credits.BackgroundTransparency = 1
credits.TextSize = 12
credits.Font = Enum.Font.Gotham
credits.Parent = mainFrame

local isMenuOpen = false

toggleButton.MouseButton1Click:Connect(function()
    isMenuOpen = not isMenuOpen
    mainFrame.Visible = isMenuOpen
    
    if isMenuOpen then
        toggleButton.Size = UDim2.new(0, 50, 0, 50)
        toggleButton.Position = UDim2.new(0, 10, 1, -70)
        toggleButton.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
        toggleButton.Image = "rbxassetid://6031087828"
    else
        toggleButton.Size = UDim2.new(0, 60, 0, 60)
        toggleButton.Position = UDim2.new(0, 20, 1, -80)
        toggleButton.BackgroundColor3 = Color3.fromRGB(120, 80, 255)
        toggleButton.Image = "rbxassetid://6031091071"
    end
end)

local dragging = false
local dragStart = nil
local startPos = nil

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local buttonDragging = false
local buttonDragStart = nil
local buttonStartPos = nil

toggleButton.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        buttonDragging = true
        buttonDragStart = input.Position
        buttonStartPos = toggleButton.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if buttonDragging and inpu
