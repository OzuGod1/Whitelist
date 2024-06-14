_G.Sheet = "https://script.google.com/macros/s/AKfycbzvWxhF3atXMU9iXUzQV4n-6zzbjyOot6QLuAMzq7Hp5ZO8qcjf2Xu0bdHnVoy9Qh0/exec"

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
if game.PlaceId ~= 17017769292 then return end
warn("=========================================")
warn("=========== Google Sheet v1.1 ===========")
warn("=========================================")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players and Players.LocalPlayer
local PlayerGui = Player and Player:WaitForChild("PlayerGui"):WaitForChild("HUD")

local function fetchData()
    local success, response = pcall(function()
        return http_request{
            Method = 'GET',
            Url = _G.Sheet .. "?action=read"
        }.Body
    end)
    
    if not success then
        warn("Failed to fetch data: " .. response)
        return nil
    end
    
    return HttpService:JSONDecode(response)
end

local function userExists(data)
    for _, v in pairs(data) do
        if v.Username == Player.Name then
            return true
        end
    end
    return false
end

local function getUserData()
    return {
        Username = Player.Name,
        Level = PlayerGui.Toolbar.XPBar.XPAmount.Text:match("Level (%d+)"),
        Gems = PlayerGui.Toolbar.CurrencyList.Gems.TextLabel.Text:gsub(",", "")
    }
end

local function sendRequest(action)
    local success, response = pcall(function()
        return http_request{
            Method = "GET",
            Url = _G.Sheet .. action,
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(data)
        }
    end)
    
    if not success then
        warn("Failed to send request: " .. response)
    end
end

local function createUser()
    local userData = getUserData()
    sendRequest("?action=insert&user=" .. userData.Username .. "&level=" .. userData.Level .. "&gems=" .. userData.Gems .. "&rr=1")
end

local function updateUser()
    local userData = getUserData()
    sendRequest("?action=update&user=" .. userData.Username .. "&data=" .. HttpService:JSONEncode(userData))
end

local data = fetchData()
if data then
    if userExists(data) then
        updateUser()
    else
        createUser()
    end
else
    warn("No data retrieved, unable to proceed.")
end
