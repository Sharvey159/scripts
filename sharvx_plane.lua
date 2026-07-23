--========================================================
-- SHARVEY SCRIPT MANAGER v2.6.0 (Universal Key Edition)
--========================================================
if not game:IsLoaded() then
    game.Loaded:Wait()
    task.wait(5)
end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local BASE_URL = "https://raw.githubusercontent.com/Sharvey159/scripts/main/"
local Config = {} -- Forward declaration for global access

-- ============================================================================
-- CENTRALIZED FAB STACK MANAGER SETUP
-- ============================================================================
local FABManager = _G.FABManager
if not FABManager then
    FABManager = {
        Buttons = {},
        PriorityMap = {
            SharveyManager = 1,
            FruitDropper = 2,
            AutoMail = 3,
            FruitSummary = 4,
            HarvestFruits = 5
        }
    }
    _G.FABManager = FABManager
    
    function FABManager.Update()
        local TweenSvc = game:GetService("TweenService")
        -- Self-heal: Clean up destroyed buttons
        local i = 1
        while i <= #FABManager.Buttons do
            local btnData = FABManager.Buttons[i]
            if not btnData.Button or not btnData.Button.Parent then
                if btnData.Connection then btnData.Connection:Disconnect() end
                table.remove(FABManager.Buttons, i)
            else
                i = i + 1
            end
        end

        local activeButtons = {}
        for _, btnData in ipairs(FABManager.Buttons) do
            if btnData.Visible then
                table.insert(activeButtons, btnData)
            end
        end
        
        local count = #activeButtons
        if count == 0 then return end
        
        local buttonSize = 48
        local spacing = 12
        local totalHeight = (count * buttonSize) + ((count - 1) * spacing)
        local startYOffset = -totalHeight / 2
        
        for idx, btnData in ipairs(activeButtons) do
            local targetYOffset = startYOffset + ((idx - 1) * (buttonSize + spacing)) + (buttonSize / 2)
            local targetPos = UDim2.new(1, -16, 0.5, targetYOffset)
            local targetShadowPos = UDim2.new(1, -14, 0.5, targetYOffset + 2)
            
            local tInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
            
            if btnData.Button and btnData.Button.Parent then
                TweenSvc:Create(btnData.Button, tInfo, {Position = targetPos}):Play()
            end
            if btnData.Shadow and btnData.Shadow.Parent then
                TweenSvc:Create(btnData.Shadow, tInfo, {Position = targetShadowPos}):Play()
            end
        end
    end
    
    function FABManager.Register(id, button, shadow, onClick)
        FABManager.Unregister(id)
        
        local btnData = {
            Id = id,
            Button = button,
            Shadow = shadow,
            Visible = true,
            OnClick = onClick
        }
        
        table.insert(FABManager.Buttons, btnData)
        
        table.sort(FABManager.Buttons, function(a, b)
            local pA = FABManager.PriorityMap[a.Id] or 99
            local pB = FABManager.PriorityMap[b.Id] or 99
            return pA < pB
        end)
        
        if onClick then
            btnData.Connection = button.MouseButton1Click:Connect(onClick)
        end
        
        FABManager.Update()
        return btnData
    end
    
    function FABManager.Unregister(id)
        for idx, btnData in ipairs(FABManager.Buttons) do
            if btnData.Id == id then
                if btnData.Connection then btnData.Connection:Disconnect() end
                table.remove(FABManager.Buttons, idx)
                FABManager.Update()
                break
            end
        end
    end
    
    function FABManager.SetVisible(id, visible)
        for _, btnData in ipairs(FABManager.Buttons) do
            if btnData.Id == id then
                btnData.Visible = visible
                if btnData.Button and btnData.Button.Parent then
                    btnData.Button.Visible = visible
                end
                if btnData.Shadow and btnData.Shadow.Parent then
                    btnData.Shadow.Visible = visible
                end
                FABManager.Update()
                break
            end
        end
    end
end

--========================================================
-- CENTRALIZED SCRIPT REGISTRY
--========================================================
local ScriptRegistry = {
    { Name = "Wis",                      File = "https://api.wishub.cloud/files/loaders/dedcf9be947d43b8ae065ad21200c764.lua", Default = false },
    { Name = "Speed Hub",                File = "SPECIAL_SPEED_HUB",          Default = false },
    { Name = "Auto Remove Small Fruits", File = "auto_remove_small_fruits.txt", Default = false },
    { Name = "Fruit Dropper",            File = "fruit_dropper.txt",          Default = false },
    { Name = "Auto Mail",                File = "auto_mail.txt",              Default = false },
    { Name = "Fruit Summary",            File = "fruit_summary.txt",          Default = false },
    { Name = "Harvest Fruits",           File = "harvest_fruits.txt",         Default = false },
    { Name = "Moon Finder",              File = "moon_finder.txt",            Default = false },
    { Name = "Mutation Watcher",         File = "mutation_watcher.txt",       Default = false },
    { Name = "Water Plant",              File = "water_plant.txt",            Default = false },
    { Name = "Weather Watcher",          File = "weather_watcher.txt",        Default = false },
    { Name = "Fruit Helper",             File = "fruit_helper.txt",           Default = false },
    { Name = "Stock Watcher",            File = "stock_watcher.txt",          Default = false },
    { Name = "Auction Sniper",           File = "auction_sniper.txt",         Default = false },
    { Name = "Shop Watcher",             File = "ShopWatcher.lua",            Default = false },
    { Name = "Bamboo Farm",              File = "bamboo_farm.txt",            Default = false } -- < NEW INTEGRATION
}

--========================================================
-- CONFIG MANAGER MODULE
--========================================================
local ConfigManager = {}
local CENTRAL_CONFIG_FILE = "Sharvey_Central_Config.json"

function ConfigManager.CreateDefaultConfig()
    local config = {}
    for _, scriptInfo in ipairs(ScriptRegistry) do
        local key = string.gsub(scriptInfo.Name, "%s+", "")
        config[key] = scriptInfo.Default
    end
    config.SpeedHubKey = "uWYotjwIyitKVtnUOOXAwfnplhXveqzL" 
    return config
end

function ConfigManager.EncodePrettyJSON(centralConfig)
    local out = "{\n"
    local globalKey = centralConfig.SpeedHubKey or "uWYotjwIyitKVtnUOOXAwfnplhXveqzL"
    out = out .. string.format('    "SpeedHubKey": "%s",\n\n', globalKey)

    local playerNames = {}
    for name in pairs(centralConfig) do 
        if name ~= "SpeedHubKey" then table.insert(playerNames, name) end
    end
    table.sort(playerNames)

    for i, pName in ipairs(playerNames) do
        out = out .. string.format('    "%s": {\n', pName)
        local pConfig = centralConfig[pName]
        local keys = {}
        for k in pairs(pConfig) do table.insert(keys, k) end
        table.sort(keys)

        for j, k in ipairs(keys) do
            local v = pConfig[k]
            local vStr = type(v) == "string" and string.format('"%s"', v) or tostring(v)
            out = out .. string.format('        "%s": %s', k, vStr)
            if j < #keys then out = out .. ",\n" else out = out .. "\n" end
        end

        out = out .. "    }"
        if i < #playerNames then out = out .. ",\n\n" else out = out .. "\n" end
    end
    out = out .. "}"
    return out
end

function ConfigManager.SavePlayerConfig(playerConfigData)
    local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "UnknownPlayer"
    local centralConfig = {}

    if isfile(CENTRAL_CONFIG_FILE) then
        local success, content = pcall(function() return readfile(CENTRAL_CONFIG_FILE) end)
        if success then
            local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if decodeSuccess and type(decoded) == "table" then centralConfig = decoded end
        end
    end

    if playerConfigData.SpeedHubKey then centralConfig.SpeedHubKey = playerConfigData.SpeedHubKey end

    local cleanPlayerData = {}
    for k, v in pairs(playerConfigData) do
        if k ~= "SpeedHubKey" then cleanPlayerData[k] = v end
    end
    centralConfig[playerName] = cleanPlayerData

    local formattedOutput = ConfigManager.EncodePrettyJSON(centralConfig)
    local writeSuccess, err = pcall(function() writefile(CENTRAL_CONFIG_FILE, formattedOutput) end)
    if not writeSuccess then warn("[Sharvey Script Manager] Failed to save config: " .. tostring(err)) end
end

function ConfigManager.MergeWithDefaults(savedConfig, defaultConfig)
    local merged = {}
    for k, v in pairs(savedConfig) do merged[k] = v end
    local changesMade = false
    for k, v in pairs(defaultConfig) do
        if merged[k] == nil then
            merged[k] = v
            changesMade = true
        end
    end
    return merged, changesMade
end

function ConfigManager.LoadPlayerConfig()
    local playerName = Players.LocalPlayer and Players.LocalPlayer.Name or "UnknownPlayer"
    local defaultConfig = ConfigManager.CreateDefaultConfig()
    local centralConfig = {}

    if isfile(CENTRAL_CONFIG_FILE) then
        local success, content = pcall(function() return readfile(CENTRAL_CONFIG_FILE) end)
        if success then
            local decodeSuccess, decoded = pcall(function() return HttpService:JSONDecode(content) end)
            if decodeSuccess and type(decoded) == "table" then centralConfig = decoded end
        end
    end

    local playerConfig = centralConfig[playerName]
    local needsSaving = false

    if type(playerConfig) ~= "table" then
        playerConfig = defaultConfig
        needsSaving = true
    else
        local mergedConfig, changed = ConfigManager.MergeWithDefaults(playerConfig, defaultConfig)
        playerConfig = mergedConfig
        if changed then needsSaving = true end
    end

    playerConfig.SpeedHubKey = centralConfig.SpeedHubKey or "uWYotjwIyitKVtnUOOXAwfnplhXveqzL"
    if needsSaving then ConfigManager.SavePlayerConfig(playerConfig) end
    return playerConfig
end

--========================================================
-- UI MODULE (STANDALONE)
--========================================================
local UI = {}
local Theme = {
    Background = Color3.fromRGB(20, 20, 20),
    TopBar     = Color3.fromRGB(30, 30, 30),
    Panels     = Color3.fromRGB(35, 35, 35),
    Hover      = Color3.fromRGB(50, 50, 50),
    Blue       = Color3.fromRGB(0, 120, 215),
    Red        = Color3.fromRGB(220, 53, 69),
    Text       = Color3.fromRGB(220, 220, 220)
}
local TweenConfig = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local function EnableDragging(handle, target)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function CreateScriptButton(scriptInfo, configKey, loadedConfig, parent, callbacks)
    local hasKeyInput = (scriptInfo.Name == "Speed Hub")
    local containerHeight = hasKeyInput and 68 or 34
    
    local ItemFrame = Instance.new("Frame")
    ItemFrame.Size = UDim2.new(1, 0, 0, containerHeight)
    ItemFrame.BackgroundTransparency = 1
    ItemFrame.Parent = parent

    local BtnWrapper = Instance.new("Frame")
    BtnWrapper.Size = UDim2.new(1, 0, 0, 34)
    BtnWrapper.BackgroundTransparency = 1
    BtnWrapper.Parent = ItemFrame

    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(1, -38, 1, 0)
    Button.BackgroundColor3 = Theme.Panels
    Button.TextColor3 = Theme.Text
    Button.Font = Enum.Font.GothamMedium
    Button.TextSize = 13
    Button.AutoButtonColor = false
    Button.Parent = BtnWrapper
    
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 6)
    Corner.Parent = Button
    
    local UpdateBtn = Instance.new("TextButton")
    UpdateBtn.Size = UDim2.new(0, 34, 1, 0)
    UpdateBtn.Position = UDim2.new(1, -34, 0, 0)
    UpdateBtn.BackgroundColor3 = Theme.Panels
    UpdateBtn.Text = "🔄"
    UpdateBtn.TextColor3 = Theme.Text
    UpdateBtn.Font = Enum.Font.Gotham
    UpdateBtn.TextSize = 14
    UpdateBtn.AutoButtonColor = false
    UpdateBtn.Parent = BtnWrapper

    local Corner2 = Instance.new("UICorner")
    Corner2.CornerRadius = UDim.new(0, 6)
    Corner2.Parent = UpdateBtn

    if hasKeyInput then
        local KeyBox = Instance.new("TextBox")
        KeyBox.Size = UDim2.new(1, 0, 0, 30)
        KeyBox.Position = UDim2.new(0, 0, 0, 38)
        KeyBox.BackgroundColor3 = Theme.Panels
        KeyBox.TextColor3 = Theme.Text
        KeyBox.Font = Enum.Font.Gotham
        KeyBox.TextSize = 12
        KeyBox.PlaceholderText = "Enter Speed Hub Key..."
        KeyBox.Text = loadedConfig.SpeedHubKey or ""
        KeyBox.Parent = ItemFrame
        
        local Corner3 = Instance.new("UICorner")
        Corner3.CornerRadius = UDim.new(0, 6)
        Corner3.Parent = KeyBox
        
        KeyBox.FocusLost:Connect(function()
            if callbacks.OnKeyUpdate then callbacks.OnKeyUpdate("SpeedHubKey", KeyBox.Text) end
        end)
    end

    local isToggled = loadedConfig[configKey] or false
    
    local function UpdateVisuals()
        if isToggled then
            Button.Text = scriptInfo.Name .. " [ON]"
            TweenService:Create(Button, TweenConfig, {BackgroundColor3 = Theme.Blue}):Play()
        else
            Button.Text = scriptInfo.Name
            TweenService:Create(Button, TweenConfig, {BackgroundColor3 = Theme.Panels}):Play()
        end
    end
    
    UpdateVisuals()

    Button.MouseEnter:Connect(function()
        if not isToggled then TweenService:Create(Button, TweenConfig, {BackgroundColor3 = Theme.Hover}):Play() end
    end)
    Button.MouseLeave:Connect(function()
        if not isToggled then TweenService:Create(Button, TweenConfig, {BackgroundColor3 = Theme.Panels}):Play() end
    end)
    UpdateBtn.MouseEnter:Connect(function() TweenService:Create(UpdateBtn, TweenConfig, {BackgroundColor3 = Theme.Hover}):Play() end)
    UpdateBtn.MouseLeave:Connect(function() TweenService:Create(UpdateBtn, TweenConfig, {BackgroundColor3 = Theme.Panels}):Play() end)
    
    Button.MouseButton1Click:Connect(function()
        isToggled = not isToggled
        UpdateVisuals()
        if callbacks.OnToggle then callbacks.OnToggle(configKey, isToggled, scriptInfo) end
    end)

    UpdateBtn.MouseButton1Click:Connect(function()
        if callbacks.ForceUpdate then callbacks.ForceUpdate(scriptInfo) end
    end)
end

function UI.Create(callbacks, registry, loadedConfig)
    local UI_NAME = "SharveyScriptManagerUI"
    if CoreGui:FindFirstChild(UI_NAME) then CoreGui[UI_NAME]:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = UI_NAME
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui
    
    local Wrapper = Instance.new("Frame")
    Wrapper.Size = UDim2.new(0, 280, 0, 400)
    Wrapper.Position = UDim2.new(0.5, -140, 0.5, -200)
    Wrapper.BackgroundTransparency = 1
    Wrapper.Parent = ScreenGui
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(1, 0, 1, 0)
    MainFrame.BackgroundColor3 = Theme.Background
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = Wrapper
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 8)
    MainCorner.Parent = MainFrame
    
    local TopBar = Instance.new("Frame"); TopBar.Size = UDim2.new(1, 0, 0, 35); TopBar.BackgroundColor3 = Theme.TopBar; TopBar.BorderSizePixel = 0; TopBar.Parent = MainFrame
    local TitleLbl = Instance.new("TextLabel"); TitleLbl.Size = UDim2.new(1, -70, 1, 0); TitleLbl.Position = UDim2.new(0, 12, 0, 0); TitleLbl.BackgroundTransparency = 1; TitleLbl.TextColor3 = Theme.Text; TitleLbl.Font = Enum.Font.GothamBold; TitleLbl.TextSize = 13; TitleLbl.TextXAlignment = Enum.TextXAlignment.Left; TitleLbl.Parent = TopBar
    local MinBtn = Instance.new("TextButton"); MinBtn.Size = UDim2.new(0, 35, 0, 35); MinBtn.Position = UDim2.new(1, -70, 0, 0); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "_"; MinBtn.TextColor3 = Theme.Text; MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 14; MinBtn.Parent = TopBar
    local CloseBtn = Instance.new("TextButton"); CloseBtn.Size = UDim2.new(0, 35, 0, 35); CloseBtn.Position = UDim2.new(1, -35, 0, 0); CloseBtn.BackgroundTransparency = 1; CloseBtn.Text = "X"; CloseBtn.TextColor3 = Theme.Text; CloseBtn.Font = Enum.Font.GothamBold; CloseBtn.TextSize = 13; CloseBtn.Parent = TopBar
    
    local ScrollList = Instance.new("ScrollingFrame"); ScrollList.Size = UDim2.new(1, -20, 1, -45); ScrollList.Position = UDim2.new(0, 10, 0, 40); ScrollList.BackgroundTransparency = 1; ScrollList.ScrollBarThickness = 2; ScrollList.BorderSizePixel = 0; ScrollList.Parent = MainFrame
    local Layout = Instance.new("UIListLayout"); Layout.Padding = UDim.new(0, 6); Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; Layout.Parent = ScrollList
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ScrollList.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y) end)
    
    --========================================================
    -- FAB LAYOUT FOR SHARVEY MANAGER (Purple Style)
    --========================================================
    local fabShadow = Instance.new("Frame")
    fabShadow.Size = UDim2.fromOffset(48, 48)
    fabShadow.AnchorPoint = Vector2.new(1, 0.5)
    fabShadow.BackgroundColor3 = Color3.new(0, 0, 0)
    fabShadow.BackgroundTransparency = 0.7
    fabShadow.BorderSizePixel = 0
    fabShadow.Parent = ScreenGui
    Instance.new("UICorner", fabShadow).CornerRadius = UDim.new(0, 12)

    local fabBtn = Instance.new("TextButton")
    fabBtn.Size = UDim2.fromOffset(48, 48)
    fabBtn.AnchorPoint = Vector2.new(1, 0.5)
    fabBtn.BackgroundColor3 = Color3.fromHex("#8B5CF6") -- Distinct Purple theme for script manager
    fabBtn.BackgroundTransparency = 0.15
    fabBtn.BorderSizePixel = 0
    fabBtn.Text = "🛠️"
    fabBtn.TextSize = 24
    fabBtn.Font = Enum.Font.Gotham
    fabBtn.Parent = ScreenGui
    Instance.new("UICorner", fabBtn).CornerRadius = UDim.new(0, 12)

    -- Hover and Click Animations for FAB
    local fabTweenInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fabBaseColor = Color3.fromHex("#8B5CF6")
    local fabHoverColor = Color3.fromHex("#A78BFA")

    fabBtn.MouseEnter:Connect(function()
        TweenService:Create(fabBtn, fabTweenInfo, {Size = UDim2.fromOffset(52, 52), BackgroundColor3 = fabHoverColor}):Play()
        TweenService:Create(fabShadow, fabTweenInfo, {Size = UDim2.fromOffset(52, 52)}):Play()
    end)
    fabBtn.MouseLeave:Connect(function()
        TweenService:Create(fabBtn, fabTweenInfo, {Size = UDim2.fromOffset(48, 48), BackgroundColor3 = fabBaseColor}):Play()
        TweenService:Create(fabShadow, fabTweenInfo, {Size = UDim2.fromOffset(48, 48)}):Play()
    end)
    fabBtn.MouseButton1Down:Connect(function()
        TweenService:Create(fabBtn, fabTweenInfo, {Size = UDim2.fromOffset(44, 44)}):Play()
        TweenService:Create(fabShadow, fabTweenInfo, {Size = UDim2.fromOffset(44, 44)}):Play()
    end)
    fabBtn.MouseButton1Up:Connect(function()
        TweenService:Create(fabBtn, fabTweenInfo, {Size = UDim2.fromOffset(52, 52)}):Play()
        TweenService:Create(fabShadow, fabTweenInfo, {Size = UDim2.fromOffset(52, 52)}):Play()
    end)

    for _, scriptInfo in ipairs(registry) do
        local configKey = string.gsub(scriptInfo.Name, "%s+", "")
        CreateScriptButton(scriptInfo, configKey, loadedConfig, ScrollList, callbacks)
    end
    
    EnableDragging(TopBar, Wrapper)
    
    local windowAPI = { Minimized = false }
    
    function windowAPI:Minimize()
        if self.Minimized then return end
        self.Minimized = true
        Wrapper.Visible = false
        FABManager.SetVisible("SharveyManager", true)
    end
    
    function windowAPI:Restore()
        if not self.Minimized then return end
        self.Minimized = false
        Wrapper.Position = UDim2.new(0.5, -140, 0.5, -200)
        Wrapper.Visible = true
        FABManager.SetVisible("SharveyManager", false)
    end
    
    function windowAPI:Destroy() 
        FABManager.Unregister("SharveyManager")
        ScreenGui:Destroy() 
    end
    
    function windowAPI:SetTitle(text) TitleLbl.Text = text end
    
    MinBtn.MouseButton1Click:Connect(function() windowAPI:Minimize() end)
    CloseBtn.MouseButton1Click:Connect(function() if callbacks.Close then callbacks.Close() end end)
    
    -- Register button with shared manager and default to Minimized
    FABManager.Register("SharveyManager", fabBtn, fabShadow, function() windowAPI:Restore() end)
    Wrapper.Visible = false
    windowAPI.Minimized = true
    FABManager.SetVisible("SharveyManager", true)

    return windowAPI
end

--========================================================
-- FEATURE EXECUTION & SCRIPT CACHING
--========================================================
local function GetSafeFileName(name) return string.gsub(name, "[^%w%-_]", "") .. ".lua" end

local function ExecuteScript(scriptInfo, forceUpdate)
    if scriptInfo.Name == "Speed Hub" then
        task.spawn(function()
            local env = (getgenv and type(getgenv) == "function") and getgenv() or _G
            env.script_key = Config.AutoLoad.SpeedHubKey or ""
            local execSuccess, runErr = pcall(function()
                loadstring(game:HttpGet("https://raw.githubusercontent.com/AhmadV99/Speed-Hub-X/main/Speed%20Hub%20X.lua", true))()
            end)
            if not execSuccess then warn(string.format("[Sharvey] Error in 'Speed Hub':\n%s", tostring(runErr))) end
        end)
        return
    end

    local url = string.match(scriptInfo.File, "^https?://") and scriptInfo.File or (BASE_URL .. scriptInfo.File)
    
    if not isfolder("SharveyCache") then makefolder("SharveyCache") end
    local fileName = "SharveyCache/" .. GetSafeFileName(scriptInfo.Name)
    local scriptContent = ""
    
    if forceUpdate or not isfile(fileName) then
        local finalUrl = url .. (string.find(url, "?") and "&" or "?") .. "t=" .. os.time()
        local success, content = pcall(function() return game:HttpGet(finalUrl) end)
        if success and content then
            writefile(fileName, content)
            scriptContent = content
            if forceUpdate then print("[Sharvey] Successfully force-updated: " .. scriptInfo.Name) end
        else
            warn("[Sharvey] Failed to download script: " .. scriptInfo.Name)
            return
        end
    else
        local success, content = pcall(function() return readfile(fileName) end)
        if success then scriptContent = content else return warn("[Sharvey] Failed to read cache: " .. scriptInfo.Name) end
    end
    
    local func, parseErr = loadstring(scriptContent)
    if not func then
        warn(string.format("[Sharvey] Syntax Error in '%s':\n%s", scriptInfo.Name, tostring(parseErr)))
        return
    end

    task.spawn(function()
        local execSuccess, runErr = pcall(func)
        if not execSuccess then warn(string.format("[Sharvey] Runtime Error in '%s':\n%s", scriptInfo.Name, tostring(runErr))) end
    end)
end

--========================================================
-- REUSABLE TOGGLE FUNCTIONS REGISTRY
--========================================================
local FeatureManager = { Toggles = {} }

for _, scriptInfo in ipairs(ScriptRegistry) do
    local configKey = string.gsub(scriptInfo.Name, "%s+", "")
    local funcName = "Set" .. configKey
    
    FeatureManager.Toggles[funcName] = function(state)
        local env = (getgenv and type(getgenv) == "function") and getgenv() or _G
        env[configKey] = state
        if state then ExecuteScript(scriptInfo, false) end
    end
end

--========================================================
-- INITIALIZATION & CONFIGURATION APPLICATION
--========================================================
Config.AutoLoad = ConfigManager.LoadPlayerConfig()
local activeWindow = nil

local Callbacks = {
    ForceUpdate = function(scriptInfo) ExecuteScript(scriptInfo, true) end,
    OnToggle = function(configKey, state, scriptInfo)
        Config.AutoLoad[configKey] = state
        ConfigManager.SavePlayerConfig(Config.AutoLoad)
        local toggleFunc = FeatureManager.Toggles["Set" .. configKey]
        if toggleFunc then toggleFunc(state) end
    end,
    OnKeyUpdate = function(keyName, value)
        Config.AutoLoad[keyName] = value
        ConfigManager.SavePlayerConfig(Config.AutoLoad)
    end,
    Close = function() if activeWindow then activeWindow:Destroy() end end
}

activeWindow = UI.Create(Callbacks, ScriptRegistry, Config.AutoLoad)
activeWindow:SetTitle("Sharvey Script Manager v2.6.0")

local function ApplySavedConfig(savedConfig)
    print("\n[Sharvey Script Manager] --- Applying Saved Configuration ---")
    for key, state in pairs(savedConfig) do
        if type(state) == "boolean" then
            local toggleFuncName = "Set" .. key
            local toggleFunc = FeatureManager.Toggles[toggleFuncName]
            if toggleFunc then
                local success, err = pcall(function() toggleFunc(state) end)
                if success then
                    print(string.format("  [+] Config applied successfully: %s -> %s", key, tostring(state)))
                else
                    warn(string.format("  [-] Error applying config for '%s': %s", key, tostring(err)))
                end
            end
        end
    end
    print("[Sharvey Script Manager] --- Configuration Complete ---\n")
end

ApplySavedConfig(Config.AutoLoad)