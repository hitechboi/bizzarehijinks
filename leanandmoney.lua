local RunService = {}
local Render_Step_Priority_Bindings = {}
local Thread_Execution_Active_State = true
local Performance_Last_Tick_Timestamp = os.clock()
local Metrics_Accumulated_Frame_Counter = 0
local Cache_Sorted_Binding_Registry = {}
local Cache_Validated_Bind_Count = 0
local Error_Handling_Max_Threshold_Limit = 10
local Error_Tracking_Current_Count = 0
local function Signal()
    local SignalObject = {}
    SignalObject.ActiveConnections = {}
    function SignalObject:Connect(CallbackFunction)
        local ConnectionObject = {Function = CallbackFunction, Connected = true}
        table.insert(SignalObject.ActiveConnections, ConnectionObject)
        return {
            Disconnect = function()
                ConnectionObject.Connected = false
                ConnectionObject.Function = nil
            end
        }
    end
    function SignalObject:Fire(...)
        local ConnectionIndex = 1
        while ConnectionIndex <= #SignalObject.ActiveConnections do
            local ConnectionObject = SignalObject.ActiveConnections[ConnectionIndex]
            if ConnectionObject.Connected then
                local ExecutionSuccess, ExecutionError = pcall(ConnectionObject.Function, ...)
                if not ExecutionSuccess then
                    Error_Tracking_Current_Count = Error_Tracking_Current_Count + 1
                    if Error_Tracking_Current_Count >= Error_Handling_Max_Threshold_Limit then
                        warn(string.format("[RunService] Maximum errors reached (%d), shutting down", Error_Handling_Max_Threshold_Limit))
                        Thread_Execution_Active_State = false
                        return
                    end
                end
                ConnectionIndex = ConnectionIndex + 1
            else
                table.remove(SignalObject.ActiveConnections, ConnectionIndex)
            end
        end
    end
    function SignalObject:Wait()
        local CurrentThread = coroutine.running()
        local Disconnected = false
        local WaitConnection
        WaitConnection = SignalObject:Connect(function(...)
            if Disconnected then return end
            Disconnected = true
            if WaitConnection then 
                WaitConnection:Disconnect() 
            else
                task.spawn(function()
                    if WaitConnection then WaitConnection:Disconnect() end
                end)
            end
            task.spawn(CurrentThread, ...)
        end)
        return coroutine.yield()
    end
    return SignalObject
end
RunService.Heartbeat = Signal()
RunService.RenderStepped = Signal()
RunService.Stepped = Signal()
function RunService:BindToRenderStep(BindName, BindPriority, BindFunction)
    if type(BindName) ~= "string" or type(BindFunction) ~= "function" then
        return
    end
    Render_Step_Priority_Bindings[BindName] = {Priority = BindPriority or 0, Function = BindFunction}
end
function RunService:UnbindFromRenderStep(BindName)
    Render_Step_Priority_Bindings[BindName] = nil
end
function RunService:IsRunning()
    return Thread_Execution_Active_State
end
local function RunLoopInternal()
    local Timing_Current_Frame_Timestamp = os.clock()
    local _rawDt = Timing_Current_Frame_Timestamp - Performance_Last_Tick_Timestamp
    local Timing_Delta_Frame_Interval = _rawDt < 1 and _rawDt or 1
    Performance_Last_Tick_Timestamp = Timing_Current_Frame_Timestamp
    Metrics_Accumulated_Frame_Counter = Metrics_Accumulated_Frame_Counter + 1
    if Thread_Execution_Active_State then
        RunService.Stepped:Fire(Timing_Current_Frame_Timestamp, Timing_Delta_Frame_Interval)
    end
    if Thread_Execution_Active_State then
        local Binding_Active_Count_Snapshot = 0
        for _ in pairs(Render_Step_Priority_Bindings) do
            Binding_Active_Count_Snapshot = Binding_Active_Count_Snapshot + 1
        end
        if Binding_Active_Count_Snapshot ~= Cache_Validated_Bind_Count then
            Cache_Sorted_Binding_Registry = {}
            for Bind_Name, Bind_Data in pairs(Render_Step_Priority_Bindings) do
                if Bind_Data and type(Bind_Data.Function) == "function" then
                    table.insert(Cache_Sorted_Binding_Registry, Bind_Data)
                end
            end
            table.sort(Cache_Sorted_Binding_Registry, function(Bind_A, Bind_B)
                return Bind_A.Priority < Bind_B.Priority
            end)
            Cache_Validated_Bind_Count = Binding_Active_Count_Snapshot
        end
        for Bind_Index = 1, #Cache_Sorted_Binding_Registry do
            if not Thread_Execution_Active_State then
                break
            end
            local Binding_Current_Execution_Target = Cache_Sorted_Binding_Registry[Bind_Index]
            if Binding_Current_Execution_Target and Binding_Current_Execution_Target.Function then
                pcall(Binding_Current_Execution_Target.Function, Timing_Delta_Frame_Interval)
            end
        end
    end
    if Thread_Execution_Active_State then
        RunService.RenderStepped:Fire(Timing_Delta_Frame_Interval)
    end
    if Thread_Execution_Active_State then
        RunService.Heartbeat:Fire(Timing_Delta_Frame_Interval)
    end
end

task.spawn(function()
    while Thread_Execution_Active_State do
        local Loop_Execution_Success = pcall(RunLoopInternal)
        if not Loop_Execution_Success then
            Error_Tracking_Current_Count = Error_Tracking_Current_Count + 1
            if Error_Tracking_Current_Count >= Error_Handling_Max_Threshold_Limit then
                Thread_Execution_Active_State = false
                break
            end
        else
            local dec = Error_Tracking_Current_Count - 1
            Error_Tracking_Current_Count = dec > 0 and dec or 0
        end
        if Thread_Execution_Active_State then
            task.wait()
        end
    end
end)
local _loadStart = os.clock()
if not _G.UILib then
    local success, result = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/hitechboi/bizzarehijinks/refs/heads/main/leanandmoney.lua")
    end)
    if success and type(result) == "string" and #result > 0 then
        local loadedFunc = loadstring(result)
        if loadedFunc then loadedFunc() end
    end
end
local UILib = _G.UILib
local _loadEnd = os.clock()
print(string.format("[UILib] Loaded in %.3fs", _loadEnd - _loadStart))
if not UILib then 
    warn("[UILib] Failed to load — _G.UILib is nil. Please run dior.lua first or place it in your executor's workspace folder!") 
    return 
end
local gn = type(getgamename) == "function" and getgamename() or "Game Name"
local activeUsersApiUrl = "https://active-users-api.itbcwasdapro.workers.dev" -- Replace with your deployed Worker URL!
local win = UILib.Window(
    "Check",        
    "it",           
    gn     
)
local combat  = win:Tab("Combat")
local visuals = win:Tab("Visuals")
local misc    = win:Tab("Misc")
local activeT = win:Tab("Active Users")
combat:Div("AIM ASSIST")
combat:Toggle("Aimbot", false, function(state)
    print("Aimbot:", state)
end, "Locks aim to nearest target")
combat:Toggle("Silent Aim", false, function(state)
    print("Silent Aim:", state)
end)
combat:Slider("FOV Radius", 30, 500, 120, function(val)
    print("FOV:", math.floor(val))
end, false, "Circle size for aim assist")
combat:Div("FIRE RATE", true)  
combat:Toggle("Instant Fire Rate", false, function(state)
    print("Instant FR:", state)
end)
combat:Toggle("Fast Fire Rate", false, function(state)
    print("Fast FR:", state)
end)
combat:Dropdown("Target Part", {"Head", "Torso", "Random"}, 1, function(opt, idx)
    print("Target:", opt, "index:", idx)
end)
visuals:Div("ESP")
visuals:Toggle("Box ESP", false, function(state)
    print("Box ESP:", state)
end)
visuals:ColorPicker("ESP Color", nil, function(col)
    print("ESP Color:", col.R, col.G, col.B)
end)
visuals:Slider("ESP Distance", 100, 2000, 800, function(val)
    print("ESP Dist:", math.floor(val))
end)
visuals:Div("WORLD")
visuals:Toggle("Fullbright", false, function(state)
    print("Fullbright:", state)
end)
misc:Div("UTILITY")
misc:Button("Rejoin Server", nil, function()
    print("Rejoining...")
end)
misc:Button("Copy Server Link", Color3.fromRGB(14, 20, 40), function()
    pcall(function()
        setclipboard("roblox://placeId=" .. game.PlaceId .. "&gameInstanceId=" .. game.JobId)
    end)
end)
misc:Log({
    "★ Changelog v1.6.0",
    "• Added row hover highlights",
    "• Fixed dropdown layout shifting",
    "• Fixed tooltip cleanup on destroy",
    "• Improved ? badge hover detection",
}, true)

activeT:Div("LIVE PLAYERS", true)
local usersPanel = activeT:UserList(10)

task.spawn(function()
    local username = game.Players.LocalPlayer.Name

    local hasGet = pcall(function() return game.HttpGet end) or (type(HttpGet) == "function")
    local hasPost = pcall(function() return game.HttpPost end) or (type(HttpPost) == "function")
    local req = request or http_request or (syn and syn.request) or (fluxus and fluxus.request)

    if not (hasGet and hasPost) and not req then
        warn("[Check it] Your executor does NOT support HTTP requests! Active Users tab will not work.")
        if usersPanel and usersPanel.SetUsers then usersPanel:SetUsers({"HTTP not supported"}, nil) end
        return
    end

    local safeApiUrl = activeUsersApiUrl:gsub("/+$", "")
    local _avatarCache = {}
    local function fetchAvatar(user, index)
        if _avatarCache[user] then
            if usersPanel and usersPanel.LoadAvatar then
                usersPanel:LoadAvatar(index, _avatarCache[user])
            end
            return
        end
        task.spawn(function()
            local s, code = pcall(function()
                local url = "https://api.luard.co/v1/user?v5=" .. user .. "&res=64"
                if type(game.HttpGet) == "function" then
                    return game:HttpGet(url)
                elseif type(HttpGet) == "function" then
                    return HttpGet(url)
                elseif req then
                    local res = req({Url = "https://api.luard.co/v1/user?v5=" .. user .. "&res=64", Method = "GET"})
                    if res and res.StatusCode == 200 then return res.Body end
                end
                return nil
            end)
            if s and code and #code > 100 then
                local ls, le = pcall(function() loadstring(code)() end)
                if ls and _G.avatar_data and _G.avatar_data.pixels then
                    _avatarCache[user] = _G.avatar_data.pixels
                    if usersPanel and usersPanel.LoadAvatar then
                        usersPanel:LoadAvatar(index, _G.avatar_data.pixels)
                    end
                end
                _G.avatar_data = nil
            end
        end)
    end

    task.spawn(function()
        while Thread_Execution_Active_State do
            local success, err = pcall(function()
                if activeUsersApiUrl ~= "YOUR_CLOUDFLARE_WORKER_URL_HERE" then
                    local url = safeApiUrl .. "/ping?username=" .. username
                    if type(game.HttpGet) == "function" then
                        game:HttpGet(url)
                    elseif type(HttpGet) == "function" then
                        HttpGet(url)
                    elseif req then
                        req({Url = url, Method = "GET"})
                    end
                end
            end)
            if not success then warn("[Check it] Ping failed: " .. tostring(err)) end
            for i=1, 30 do if not Thread_Execution_Active_State then break end task.wait(1) end
        end
    end)

    task.spawn(function()
        while Thread_Execution_Active_State do
            local fetched = false
            local success, err = pcall(function()
                if activeUsersApiUrl ~= "YOUR_CLOUDFLARE_WORKER_URL_HERE" then
                    local url = safeApiUrl .. "/users"
                    local resBody = ""

                    if type(game.HttpGet) == "function" then
                        resBody = game:HttpGet(url)
                    elseif type(HttpGet) == "function" then
                        resBody = HttpGet(url)
                    elseif req then
                        local res = req({ Url = url, Method = "GET" })
                        if res and res.StatusCode == 200 then resBody = res.Body end
                    end

                    if resBody and resBody ~= "" then
                        local names = {}
                        local usersStr = resBody:match('%[(.-)%]')
                        if usersStr then
                            for user in usersStr:gmatch('"(.-)"') do
                                table.insert(names, user)
                            end
                        end
                        if #names == 0 then table.insert(names, "No users online") end
                        if usersPanel and usersPanel.SetUsers then
                            usersPanel:SetUsers(names, username)
                        end
                        for i, user in ipairs(names) do
                            if i <= (usersPanel and usersPanel.GetMaxUsers and usersPanel:GetMaxUsers() or 10) then
                                fetchAvatar(user, i)
                            end
                        end
                        fetched = true
                    end
                end
            end)
            if not success then warn("[Check it] Fetch failed: " .. tostring(err)) end
            if not fetched and activeUsersApiUrl == "YOUR_CLOUDFLARE_WORKER_URL_HERE" then
                if usersPanel and usersPanel.SetUsers then usersPanel:SetUsers({"Waiting for API URL..."}, nil) end
            end
            for i=1, 15 do if not Thread_Execution_Active_State then break end task.wait(1) end
        end
    end)
end)
win:SettingsTab(function()
    Thread_Execution_Active_State = false  
    win:Destroy()
end)
win:Init(
    "Combat",  
    function()  
        local ok, result = pcall(function()
            local char = game.Players.LocalPlayer.Character
            if char then
                local tools = {}
                for _, c in ipairs(char:GetChildren()) do
                    if c.ClassName == "Tool" then table.insert(tools, c.Name) end
                end
                if #tools > 0 then return table.concat(tools, ", ") end
            end
            return ""
        end)
        return ok and result or ""
    end,
    nil  
)
