local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Attempt to load modules
local FruitVisualizerController = require(player:WaitForChild("PlayerScripts"):WaitForChild("Controllers"):WaitForChild("FruitVisualizerController"))
local Networking = require(ReplicatedStorage:WaitForChild("SharedModules"):WaitForChild("Networking"))

-- 1. Find Plot
local myPlot
for _, plot in ipairs(workspace.Gardens:GetChildren()) do
    if plot:GetAttribute("OwnerUserId") == player.UserId then
        myPlot = plot
        break
    end
end

if not myPlot then
    warn("Couldn't find your plot!")
    return -- Stops script execution if no plot is found to prevent errors
end

-- 2. Variables
local SHOVEL_NAME = "Shovel"
local harvestPlants = {}
local keptPlants = {}
local shovelPlants = {}
local allPlants = {} -- Added missing declaration

-- 3. Build UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AdminPanel"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(250, 235)
frame.Position = UDim2.fromScale(0.02, 0.25)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

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

local scanButton = createButton("Start Scan", 35)
local shovelButton = createButton("Start Shovel", 85)
local harvestButton = createButton("Start Harvest", 135)

local function setState(text)
    state.Text = "State: " .. text
end

-- 4. Core Logic Functions
local function scanPlants()
    setState("Scanning...")
    table.clear(harvestPlants)
    table.clear(keptPlants)
    table.clear(shovelPlants)
    table.clear(allPlants)

    for _, plant in ipairs(myPlot.Plants:GetChildren()) do
        local fruits = plant:FindFirstChild("Fruits")

        if fruits then
            local plantId = plant:GetAttribute("PlantId") or plant.Name
            if plantId then
                for _, fruit in ipairs(fruits:GetChildren()) do
                    local name = fruit:GetAttribute("CorePartName")
                    local id = fruit:GetAttribute("FruitId")

                    if not id or not name then
                        continue
                    end

                    local mutation = fruit:GetAttribute("Mutation")
                    if not mutation or mutation == "" then
                        mutation = "None"
                    end

                    local weight = FruitVisualizerController:CalculateFruitWeight(fruit)
                    if not weight and FruitVisualizerController.CalculatePlantWeight then
                        weight = FruitVisualizerController:CalculatePlantWeight(fruit)
                    end
                    weight = tonumber(weight) or 0

                    local fruitData = {
                        PlantId = plantId,
                        Id = id,
                        Name = name,
                        Weight = weight,
                        Mutation = mutation,
                        Instance = fruit,
                    }

                    if weight >= 38 then
                        if mutation == "None" then
                            table.insert(keptPlants, fruitData)
                        else
                            table.insert(harvestPlants, fruitData)
                        end
                    else
                        table.insert(shovelPlants, fruitData)
                    end
                end
            end
        end
    end

    setState(("Scan Complete: S:%d H:%d K:%d"):format(#shovelPlants, #harvestPlants, #keptPlants))
    print("===== SCAN COMPLETE =====")
    print("Harvest:", #harvestPlants, "| Shovel:", #shovelPlants, "| Kept:", #keptPlants)
end

local function harvestFruit(fruitInstance)
    if not fruitInstance then return end
    local plantId = fruitInstance.Parent:GetAttribute("PlantId")
    if not plantId then return end
    local fruitId = fruitInstance:GetAttribute("FruitId")
    if not fruitId then return end

    Networking.Garden.CollectFruits.Fire(plantId, fruitId)
end

local function startHarvest()
    local total = #harvestPlants
    if total == 0 then
        setState("No plants to harvest!")
        return
    end

    local processed = 0
    for _, fruit in ipairs(harvestPlants) do
        processed += 1
        setState(("Harvesting... %d/%d"):format(processed, total))
        harvestFruit(fruit.Instance)
        task.wait(0.1)
    end
    setState(("Harvest Complete (%d/%d)"):format(processed, total))
end

local function equipTool(toolName)
    local character = player.Character
    if not character then return false end
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end

    local tool = character:FindFirstChild(toolName) or player.Backpack:FindFirstChild(toolName)
    if not tool then return false end

    humanoid:EquipTool(tool)
    return true
end

local function waitForShovelAck(fruitId)
    return new Promise(function(resolve)
        local conn
        conn = Networking.Shovel.Completed:Connect(function(id)
            if id == fruitId then
                conn:Disconnect()
                resolve()
            end
        end)
    end)

end

local function shovelFruit(fruitInstance)
    if not fruitInstance then return end
    local plantId = fruitInstance.Parent:GetAttribute("PlantId")
    if not plantId then return end
    local fruitId = fruitInstance:GetAttribute("FruitId")
    if not fruitId then return end

    local equippedTool = player.Character and player.Character:FindFirstChildOfClass("Tool")
    if not equippedTool then return end

    local shovelType = equippedTool:GetAttribute("Shovel")
    Networking.Shovel.UseShovel:Fire(plantId, fruitId, shovelType, equippedTool)

         waitForShovelAck(fruitId)

end

local function startShovel(toolName)
    if #shovelPlants == 0 then
        setState("No plants to shovel!")
        return
    end

    if not equipTool(toolName) then
        setState("Failed: Tool missing!")
        warn("Failed to equip shovel!")
        return
    end

    local total = #shovelPlants
    local processed = 0
    for _, fruit in ipairs(shovelPlants) do
        processed += 1
        setState(("Shoveling... %d/%d"):format(processed, total))
        shovelFruit(fruit.Instance)
        task.wait(0.1)
    end
    setState(("Shoveling Complete (%d/%d)"):format(processed, total))
end

-- 5. Wiring the UI Buttons
scanButton.MouseButton1Click:Connect(function()
    scanPlants()
end)

shovelButton.MouseButton1Click:Connect(function()
    startShovel(SHOVEL_NAME)
end)

harvestButton.MouseButton1Click:Connect(function()
    startHarvest()
end)

-- Minimize/Close Logic
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

close.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)