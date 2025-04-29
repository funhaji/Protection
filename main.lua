
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService  = game:GetService("TextService")

local allowedHosts = {
    "^www%%.roblox%%.com$",
    "^apis%%.roblox%%.com$",
    "^auth%%.roblox%%.com$",
    "^raw%%.githubusercontent%%.com$",
    "^gist%%.githubusercontent%%.com$",
    "^pastebin%%.com$",
    "^pastebinusercontent%%.com$",
    "^controlc%%.com$",
    "^controlc%%.dev$",
    "^rentry%%.co$",
    "^rentry%%.org$",
    "^api%%.luarmor%%.net$",
    "raw%%.githubusercontent%%.com$",
}

local fakeIP       = "0.0.0.0"
local rateMax      = 5
local rateWindow   = 60 
local requestTimes = {}

local function showNotification(text)
    local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "TaxusNotification"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui
    local label = Instance.new("TextLabel")
    label.Text       = text
    label.TextSize   = 14
    label.Font       = Enum.Font.SourceSans
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)

    local sizeVec = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.new(math.huge, math.huge))
    local paddingX = 20
    local paddingY = 10
    local frameWidth  = sizeVec.X + paddingX
    local frameHeight = sizeVec.Y + paddingY

    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(0, frameWidth, 0, frameHeight)
    frame.Position          = UDim2.new(1, -frameWidth - 10, 1, -frameHeight - 10)
    frame.BackgroundColor3  = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel   = 0
    frame.Parent            = sg

    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent       = frame

    label.Size     = UDim2.new(1, -paddingX, 1, -paddingY)
    label.Position = UDim2.new(0, paddingX/2, 0, paddingY/2)
    label.Parent   = frame

    task.delay(3, function()
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        sg:Destroy()
    end)
end

local origRequest = getgenv().request or function(opts) end

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
            return { Success = false, StatusMessage = "Rate Limited" }
        end
        table.insert(requestTimes, now)

        if url:match("^http://") then
            url = url:gsub("^http://", "https://")
        end

        local host = url:match("^https?://([^/]+)") or ""
        local allowed = false
        for _, pat in ipairs(allowedHosts) do
            if host:match(pat) then
                allowed = true
                break
            end
        end
        if not allowed then
            warn("[Taxus] Blocked disallowed domain:", host)
            showNotification("🛡️ Blocked: " .. host)
            return { Body = fakeIP }
        end

        opts.Url = url
        opts.Headers = opts.Headers or {}
        opts.Headers["User-Agent"]       = "TaxusAPI/RobloxApp"
        opts.Headers["X-Security-Token"] = "TAXUS-" .. math.random(10000,99999)
    end

    local res = origRequest(opts)

    if res and res.Body and res.Body:match("%d+%%.%d+%%.%d+%%.%d+") then
        res.Body = fakeIP
        warn("[Taxus] Sanitized IP in response")
    end

    return res
end
showNotification("🛡️ Taxus Security Active")
print("🛡️ Taxus Security Active")

local q = (syn and syn.queue_on_teleport)
       or queue_on_teleport
       or (taxus and taxus.queue_on_teleport)

if q then
    local scriptText = ([==[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/funhaji/Protection/refs/heads/main/main.lua"))()
    ]==])
    q("loadstring([==[" .. scriptText .. "]==])()")
end
