local Players = game:GetService("Players")
local player = Players.LocalPlayer

local SHOVEL_NAME = "Shovel"

task.spawn(function()
	while task.wait(0.1) do
		local character = player.Character
		if not character then
			continue
		end

		local humanoid = character:FindFirstChild("Humanoid")
		if not humanoid then
			continue
		end

		local tool = player.Backpack:FindFirstChild(SHOVEL_NAME)
		if tool then
			humanoid:EquipTool(tool)
		end
	end
end)

local function shovelFruit(plantModel)
	if not plantModel then
		return
	end

	-- Verify the plant has a PlantId
	local plantId = plantModel:GetAttribute("PlantId") or plantModel.Name
	if not plantId then
		return
	end

	-- Find the Fruits folder
	local fruits = plantModel:FindFirstChild("Fruits")
	if not fruits then
		return
	end

	-- Find the first fruit model
	local fruitModel

	for _, child in ipairs(fruits:GetChildren()) do
		if child:IsA("Model") then
			fruitModel = child
			break
		end
	end

	if not fruitModel then
		return
	end

	-- Mock-up only
	print("Would shovel fruit:")
	print("PlantId:", plantId)
	print("Fruit:", fruitModel.Name)

	-- Placeholder for the real shovel action.
	-- Example:
	-- UseShovel(plantId, fruitId, equippedShovel)
	local equippedTool = player.Character and player.Character:FindFirstChildOfClass("Tool")

	if not equippedTool then
		warn("No equipped tool found.")
		return
	end

	local shovelType = equippedTool:GetAttribute("Shovel")

	Networking.Shovel.UseShovel:Fire(plantId, fruitId, shovelType, equippedTool)
end

local plot = workspace.Gardens:WaitForChild("Plot1")

local plant

for _, child in ipairs(plot.Plants:GetChildren()) do
	if child:IsA("Model") then
		plant = child
		break
	end
end

if plant then
	shovelFruit(plant)
else
	warn("No plant found in Plot1")
end

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

-- Main Frame
local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(250, 235) -- Increased height
frame.Position = UDim2.fromScale(0.02, 0.25)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Title Bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
titleBar.BorderSizePixel = 0
titleBar.Parent = frame

Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -60, 1, 0)
title.Position = UDim2.fromOffset(8, 0)
title.Font = Enum.Font.GothamBold
title.Text = "Admin Panel"
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.new(1, 1, 1)
title.Parent = titleBar

-- Minimize Button
local minimize = Instance.new("TextButton")
minimize.Size = UDim2.fromOffset(25, 25)
minimize.Position = UDim2.new(1, -55, 0, 2)
minimize.BackgroundColor3 = Color3.fromRGB(90, 90, 90)
minimize.Text = "-"
minimize.Font = Enum.Font.GothamBold
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.TextSize = 18
minimize.Parent = titleBar
Instance.new("UICorner", minimize).CornerRadius = UDim.new(0, 4)

-- Close Button
local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(25, 25)
close.Position = UDim2.new(1, -28, 0, 2)
close.BackgroundColor3 = Color3.fromRGB(170, 50, 50)
close.Text = "X"
close.Font = Enum.Font.GothamBold
close.TextColor3 = Color3.new(1, 1, 1)
close.TextSize = 14
close.Parent = titleBar
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 4)

-- Content
local content = Instance.new("Frame")
content.BackgroundTransparency = 1
content.Position = UDim2.fromOffset(0, 30)
content.Size = UDim2.new(1, 0, 1, -30)
content.Parent = frame

local state = Instance.new("TextLabel")
state.Size = UDim2.new(1, 0, 0, 25)
state.BackgroundTransparency = 1
state.Font = Enum.Font.Gotham
state.Text = "State: Idle"
state.TextSize = 14
state.TextColor3 = Color3.fromRGB(220, 220, 220)
state.Parent = content

local function createButton(text, y)
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -20, 0, 40)
	button.Position = UDim2.new(0, 10, 0, y)
	button.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	button.Text = text
	button.Font = Enum.Font.GothamBold
	button.TextSize = 15
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Parent = content

	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 6)

	return button
end

-- Buttons
local scanButton = createButton("Start Scan", 35)
local shovelButton = createButton("Start Shovel", 85)
local harvestButton = createButton("Start Harvest", 135)

local function setState(text)
	state.Text = "State: " .. text
end

scanButton.MouseButton1Click:Connect(function()
	setState("Scanning...")
	print("Start Scanning")
	-- scanFunction()
end)

shovelButton.MouseButton1Click:Connect(function()
	setState("Shoveling...")
	print("Start Shovel")
	-- shovelFunction()
end)

harvestButton.MouseButton1Click:Connect(function()
	setState("Harvesting...")
	print("Start Harvest")
	-- harvestFunction()
end)

-- Minimize
local minimized = false
local expandedSize = frame.Size

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized

	if minimized then
		content.Visible = false
		frame.Size = UDim2.fromOffset(expandedSize.X.Offset, 30)
		minimize.Text = "+"
	else
		content.Visible = true
		frame.Size = expandedSize
		minimize.Text = "-"
	end
end)

-- Close
close.MouseButton1Click:Connect(function()
	screenGui:Destroy()
end)
