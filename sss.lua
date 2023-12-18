repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer and game.CreatorId
repeat task.wait() until game.Workspace:FindFirstChild(game.Players.LocalPlayer.Name)
-- Service
local vim = game:GetService("VirtualInputManager")
local players = game:GetService("Players")
local replicatedstorage = game:GetService("ReplicatedStorage")
local runservice = game:GetService("RunService")
-- Variable
local lp = players.LocalPlayer
local character = lp.Character
local playergui = lp.PlayerGui
local profile_data = { equipped_units = {}, stats_units = require(replicatedstorage.src.Data.Units) };

do -- Utility
    for _, v in pairs(getgc(true)) do
        if typeof(v) == "table" then
            if rawget(v, "equipped_slot") then
                table.insert(profile_data.equipped_units, v)
            end
        end
    end
end

local function player_in_map()
    if not game.PlaceId then return end
    if game.PlaceId ~= 8304191830 then
        return true
    end
    return false
end

local function join_inf()
    for _,v in pairs(workspace._LOBBIES.Story:GetChildren()) do
        local owner = v:FindFirstChild("Owner")
        if owner and owner.Value == nil then
            local args = v.Name
            replicatedstorage.endpoints.client_to_server.request_join_lobby:InvokeServer(args)
            task.wait()
            replicatedstorage.endpoints.client_to_server.request_lock_level:InvokeServer(args, "namek_infinite", true, "Hard")
            replicatedstorage.endpoints.client_to_server.request_start_game:InvokeServer(args)
            break
        end
    end
end

local function format_name(name)
    if name:find("aot_generic") or name:find("metal_knight_drone") then
        return
    end

    return name:match("(%l+)")
end

local function get_mob()
    local largest = -math.huge
    local mob = nil

    for _,v in pairs(workspace._UNITS:GetChildren()) do
        local m_stats = v:WaitForChild("_stats")
        local m_owner = m_stats and m_stats:WaitForChild("player")
        local m_last = m_stats and m_stats:WaitForChild("last_reached_bend")

        if (m_stats and m_owner and m_last) then
            local m_last_value = m_last.Value.Name

            if (m_last_value ~= "spawn" and m_last_value ~= "final") then
                if (tonumber(m_last_value) > largest) then
                    largest = tonumber(m_last_value)
                    mob = v
                end
            end
        end
    end

    return mob
end

local function get_real_name(name)
    for _, unit in pairs(profile_data.equipped_units) do
        if (unit.unit_id:find(name)) then
            return unit.unit_id
        end
    end

    return nil
end

local function get_stats(name)
    return profile_data.stats_units[name]
end

local function get_max_upgrade(unit)
    -- print(profile_data.stats_units)
    return #get_stats(get_real_name(unit)).upgrade + 1
end

local function get_upgrade_unit()
    local cheapest = math.huge
    local unit = nil

    for _,v in pairs(workspace._UNITS:GetChildren()) do
        local m_stats = v:FindFirstChild("_stats")
        local m_owner = m_stats and m_stats:FindFirstChild("player")
        local m_upgrade = m_stats and m_stats:FindFirstChild("upgrade")

        if (m_stats and m_owner and m_upgrade) then
            local name = format_name(v.Name)

            if (name and m_owner.Value == lp) then
                -- print("Name:", v.Name)
                if (m_upgrade.Value + 1 < get_max_upgrade(name)) then
                    local cost = get_stats(get_real_name(name)).upgrade[m_upgrade.Value+1].cost
                    local money = lp._stats.resource.Value

                    if (money >= cost) then
                        if (cost < cheapest) then
                            cheapest = cost
                            unit = v
                        end
                    end
                end
            end
        end
    end

    return unit
end

local function has_enough_money(unit)
    local stats = get_stats(unit.unit_id)
    local money = lp._stats.resource.Value

    if (money >= stats.cost) then
        return true
    else
        return false
    end
end

local function is_max(unit)
    local stats = get_stats(unit.unit_id)
    local name = format_name(unit.unit_id)

    local temp = {}
    for _,v in pairs(workspace._UNITS:GetChildren()) do
        if v.Name:find(name) then
            table.insert(temp, v)
        end
    end

    if #temp == stats.spawn_cap then
        return true
    else
        return false
    end
end

local function get_place_unit()
    local uuid = nil

    for _,v in pairs(profile_data.equipped_units) do
        local maxed = is_max(v)
        local has_money = has_enough_money(v)

        if (not maxed and has_money) then
            uuid = v.uuid
        end
    end

    return uuid
end

local function get_land_place(total)
    return workspace._BASES.pve.LANES["1"][tonumber(total) + 1].Position
end

local function place_unit(uuid, position)
    replicatedstorage.endpoints.client_to_server.spawn_unit:InvokeServer(uuid, CFrame.new(position + Vector3.new(math.random(-5, 5), 0, math.random(-5, 5))))
end

local function upgrade_unit(unit)
    replicatedstorage.endpoints.client_to_server.upgrade_unit_ingame:InvokeServer(unit)
end

coroutine.resume(coroutine.create(function()
    pcall(function()
        if player_in_map() then
            local _wave = workspace:WaitForChild("_wave_num")
            if (_wave) then
                _wave:GetPropertyChangedSignal("Value"):Connect(function()
                    if (_wave.Value) then
                        repeat task.wait() until _wave.Value >= 24
                        for _,v in pairs(workspace._UNITS:GetChildren()) do
                            local stats = v:FindFirstChild("_stats")
                            local owner = stats:FindFirstChild("player")
                            if (stats and owner and owner.Value == lp) then
                                replicatedstorage.endpoints.client_to_server.sell_unit_ingame:InvokeServer(v)
                            end
                        end
                    end
                end)
            end
        end
    end)
end))

task.spawn(function()
    while (task.wait(3)) do
        pcall(function()
            if player_in_map() then
                local target = get_mob()

                if (target) then
                    local m_root = target:FindFirstChild("HumanoidRootPart")
                    local m_place = get_land_place(target._stats.last_reached_bend.Value.Name)
                    local distance = (m_place - m_root.Position).magnitude

                    if (distance <= 5) then
                        local unit_will_place = get_place_unit()

                        if (unit_will_place) then
                            place_unit(unit_will_place, m_place)
                        else
                            local unit_will_upgrade = get_upgrade_unit()

                            if (unit_will_upgrade) then
                                upgrade_unit(unit_will_upgrade)
                            end
                        end
                    else
                        local m_place = get_land_place(math.random(1, 2))
                        local action = math.random(1, 2)

                        if action == 1 then
                            local unit_will_place = get_place_unit()

                            if (unit_will_place) then
                                place_unit(unit_will_place, m_place)
                            else
                                local unit_will_upgrade = get_upgrade_unit()

                                if (unit_will_upgrade) then
                                    upgrade_unit(unit_will_upgrade)
                                end
                            end
                        elseif action == 2 then
                            local unit_will_upgrade = get_upgrade_unit()

                            if (unit_will_upgrade) then
                                upgrade_unit(unit_will_upgrade)
                            end
                        end
                    end
                end
            end
        end)
    end
end)

task.spawn(function()
    while (task.wait()) do
        if player_in_map() then
            local vote = playergui:WaitForChild("VoteStart")
            if (vote and vote.Enabled) then
                replicatedstorage:WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("vote_start"):InvokeServer()
            end

            local results = playergui:WaitForChild("ResultsUI")
            if (results and results.Enabled) then
                replicatedstorage:WaitForChild("endpoints"):WaitForChild("client_to_server"):WaitForChild("set_game_finished_vote"):InvokeServer("replay")
                break
            end
        end
    end
end)

task.spawn(function()
    if not player_in_map() then
        while (task.wait(0.5)) do
            task.wait(0.5)
            join_inf()
        end
    end
end)

runservice:Set3dRenderingEnabled(false)
lp.Idled:connect(function()
    vim:SendKeyEvent(true, "W", false, game)
    task.wait()
    vim:SendKeyEvent(false, "W", false, game)
end)
