_G.Sheet = "https://sheet.best/api/sheets/f1847a16-b06c-4eeb-bb5b-da7195fe72e3"

repeat task.wait() until game:IsLoaded()
repeat task.wait() until game.Players.LocalPlayer
-- if game.PlaceId ~= 17017769292 then return end

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Player = Players and Players.LocalPlayer
local PlayerGui = Player and Player:WaitForChild("PlayerGui"):WaitForChild("HUD")

local function fetchData()
    local success, response = pcall(function()
        return http_request{
            Method = 'GET',
            Url = _G.Sheet
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

local function sendRequest(method, url, data)
    local success, response = pcall(function()
        return http_request{
            Method = method,
            Url = url,
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
    sendRequest('POST', _G.Sheet, userData)
end

local function updateUser()
    local userData = getUserData()
    sendRequest('PUT', _G.Sheet .. "/Username/" .. Player.Name, userData)
end

-- Main
local data = fetchData()
print(data)
if data then
    if userExists(data) then
        updateUser()
    else
        createUser()
    end
else
    warn("No data retrieved, unable to proceed.")
end
