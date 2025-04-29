local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService  = game:GetService("TextService")
local HttpService  = game:GetService("HttpService")

repeat task.wait() until game:IsLoaded()
local player    = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

local allowedHosts = {
    "^www%.roblox%.com$",
    "^apis%.roblox%.com$",
    "^auth%.roblox%.com$",
    "^raw%.githubusercontent%.com$",
    "^gist%.githubusercontent%.com$",
    "^pastebin%.com$",
    "^pastebinusercontent%.com$",
    "^controlc%.com$",
    "^controlc%.dev$",
    "^rentry%.co$",
    "^rentry%.org$",
    "^api%.luarmor%.net$",
}

local fakeIP     = "0.0.0.0"
local rateMax    = 5
local rateWindow = 60
local requestTimes = {}

local function showNotification(text)
    local sg = Instance.new("ScreenGui")
    sg.Name = "TaxusNotification"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui

    local label = Instance.new("TextLabel")
    label.Text = text
    label.TextSize = 14
    label.Font = Enum.Font.SourceSans
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)

    local bounds = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.new(math.huge, math.huge))
    local padX, padY = 20, 10
    local fw, fh = bounds.X + padX, bounds.Y + padY

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, fw, 0, fh)
    frame.Position = UDim2.new(1, -fw - 10, 1, -fh - 10)
    frame.BackgroundColor3 = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel = 0
    frame.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = frame

    label.Size = UDim2.new(1, -padX, 1, -padY)
    label.Position = UDim2.new(0, padX/2, 0, padY/2)
    label.Parent = frame

    task.delay(3, function()
        local tween = TweenService:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        sg:Destroy()
    end)
end

local origRequest  = getgenv().request or function(_) end
local origGetAsync = HttpService.GetAsync
local origHttpGet  = game.HttpGet

getgenv().request = function(opts)
    opts = opts or {}
    local url = opts.Url
    if url then
        local now = os.time()
        for i = #requestTimes, 1, -1 do
            if now - requestTimes[i] > rateWindow then
                table.remove(requestTimes, i)
            end
        end
        if #requestTimes >= rateMax then
            warn("[Taxus] Rate limit exceeded")
            return {Success = false, StatusMessage = "Rate Limited"}
        end
        table.insert(requestTimes, now)

        if url:match("^http://") then
            url = url:gsub("^http://", "https://")
        end

        local host = (url:match("^https?://([^/]+)") or ""):lower()
        local ok
        for _, pat in ipairs(allowedHosts) do
            if host:match(pat) then ok = true break end
        end
        if not ok then
            warn("[Taxus] Blocked disallowed domain:", host)
            showNotification("🛡️ Blocked: " .. host)
            return {Body = fakeIP}
        end

        opts.Url = url
        opts.Headers = opts.Headers or {}
        opts.Headers["User-Agent"]       = "TaxusAPI/RobloxApp"
        opts.Headers["X-Security-Token"] = "TAXUS-" .. math.random(10000,99999)
    end

    local res = origRequest(opts)
    if res and res.Body and res.Body:match("%d+%.%d+%.%d+%.%d+") then
        res.Body = fakeIP
        warn("[Taxus] Sanitized IP in response")
    end
    return res
end

function HttpService:GetAsync(url, ...)
    local r = getgenv().request({Url = url})
    if r and r.Body then return r.Body end
    return origGetAsync(self, url, ...)
end

function game:HttpGet(url, ...)
    local r = getgenv().request({Url = url})
    if r and r.Body then return r.Body end
    return origHttpGet(self, url, ...)
end

showNotification("🛡️ Taxus Security Active")
print("🛡️ Taxus Security Active")

repeat task.wait() until Players.LocalPlayer
if game.PlaceId ~= 0 then
    local q = (syn and syn.queue_on_teleport)
           or queue_on_teleport
           or (fluxus and fluxus.queue_on_teleport)
    if q then
        q([[loadstring(game:HttpGet("https://raw.githubusercontent.com/funhaji/Protection/refs/heads/main/main.lua"))()]])
    end
end
