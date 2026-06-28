local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Networking = require(ReplicatedStorage.SharedModules.Networking)

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")
local backpack = player:WaitForChild("Backpack")

local TARGET_NAMES = { "000022226666", "SharvxPlayz" }
local SPRINKLERS = { "Common Sprinkler", "Uncommon Sprinkler", "Rare Sprinkler", "Legendary Sprinkler" }
local GAP = 3 -- studs from center
local DELAY = 1 -- seconds between placements

local function findTargetPlayer()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Name == TARGET_NAMES[2] or tostring(p.UserId) == TARGET_NAMES[1] then
			return p
		end
	end
	return nil
end

local function findPlotForUser(userId)
	local gardens = workspace:FindFirstChild("Gardens")
	if not gardens then
		return nil
	end
	for _, plot in ipairs(gardens:GetChildren()) do
		local owner = plot:GetAttribute("OwnerUserId")
		if owner and tostring(owner) == tostring(userId) then
			return plot
		end
	end
	return nil
end

local function getPlantPosition(plant)
	if not plant then
		return nil
	end
	if plant:IsA("Model") then
		if plant.PrimaryPart then
			return plant.PrimaryPart.Position
		end
		if plant.GetPivot then
			local ok, pivot = pcall(function()
				return plant:GetPivot()
			end)
			if ok and pivot then
				return pivot.Position
			end
		end
	elseif plant:IsA("BasePart") then
		return plant.Position
	end
	-- try to find any BasePart child
	for _, c in ipairs(plant:GetDescendants()) do
		if c:IsA("BasePart") then
			return c.Position
		end
	end
	return nil
end

local function raycastToGround(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local start = pos + Vector3.new(0, 10, 0)
	local dir = Vector3.new(0, -100, 0)
	local result = workspace:Raycast(start, dir, params)
	if result and result.Position then
		return result.Position
	end
	return pos
end

-- main
local target = findTargetPlayer()
if not target then
	warn("Target player not found: ", TARGET_NAMES)
	return
end

local targetId = target.UserId
local plot = findPlotForUser(targetId)
if not plot then
	warn("Plot for user not found. UserId:", targetId)
	return
end

local plotId = tonumber(plot.Name:match("%d+")) or 1
local plantsFolder = plot:FindFirstChild("Plants")
if not plantsFolder then
	warn("No Plants folder in plot:", plot.Name)
	return
end

local plants = plantsFolder:GetChildren()
if #plants == 0 then
	warn("No plants found under plot:", plot.Name)
	return
end

local plant = plants[1]
local centerPos = getPlantPosition(plant)
if not centerPos then
	warn("Couldn't determine plant position for:", plant:GetFullName())
	return
end

-- build 8-point octagon offsets
local offsets = {}
do
	for k = 1, 8 do
		local angle = (k - 1) * (2 * math.pi / 8)
		local x = math.cos(angle) * GAP
		local z = math.sin(angle) * GAP
		offsets[k] = Vector3.new(x, 0, z)
	end
end

local currentIndex = 1
for i, name in ipairs(SPRINKLERS) do
	local placed = false
	for attempt = 0, 7 do
		local idx = ((currentIndex - 1 + attempt) % 8) + 1
		local desired = centerPos + offsets[idx]
		local groundPos = raycastToGround(desired)

		print(string.format("Attempting position %d for %s (attempt %d)", idx, name, attempt + 1))

		local tool = backpack:FindFirstChild(name) or character:FindFirstChild(name)
		if not tool then
			warn(string.format("Failed at position %d for %s: tool not found, trying next pos...", idx, name))
			-- try next position
			task.wait(0.1)
			goto continue_attempt
		end

		if tool.Parent ~= character then
			humanoid:EquipTool(tool)
			local timeout = tick() + 2
			repeat
				task.wait()
			until tool.Parent == character or tick() > timeout
		end

		-- fire placement
		Networking.Place.PlaceSprinkler:Fire(groundPos, name, tool, plotId)
		print(string.format("Placed %s at position %d for plot %s", name, idx, plot.Name))
		placed = true
		-- next sprinkler should start at the next slot after this one
		currentIndex = (idx % 8) + 1
		task.wait(DELAY)
		break

		::continue_attempt::
	end

	if not placed then
		warn(string.format("Could not place %s after trying 8 positions; moving to next sprinkler." , name))
		-- advance start index to avoid retrying same cluster
		currentIndex = (currentIndex % 8) + 1
	end
end

print("Finished placing sprinklers for plot", plot.Name)
