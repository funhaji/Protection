-- Simplified Taxus Security (default-deny) with dynamic rounded toast notifications
----------------------------------------------------------------
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService  = game:GetService("TextService")

local allowedHosts = {
    "^www%%.roblox%%.com$",
    "^apis%%.roblox%%.com$",
    "^auth%%.roblox%%.com$",

    -- Script hosting domains
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
local rateWindow   = 60    -- seconds
local requestTimes = {}

-- Helper: show a small rounded black toast at bottom-right with dynamic width
local function showNotification(text)
    local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "TaxusNotification"
    sg.ResetOnSpawn = false
    sg.Parent = playerGui

    -- Create label first to measure text size
    local label = Instance.new("TextLabel")
    label.Text       = text
    label.TextSize   = 14
    label.Font       = Enum.Font.SourceSans
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1,1,1)

    -- Measure text bounds
    local sizeVec = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.new(math.huge, math.huge))
    local paddingX = 20
    local paddingY = 10
    local frameWidth  = sizeVec.X + paddingX
    local frameHeight = sizeVec.Y + paddingY

    -- Frame
    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(0, frameWidth, 0, frameHeight)
    frame.Position          = UDim2.new(1, -frameWidth - 10, 1, -frameHeight - 10)
    frame.BackgroundColor3  = Color3.new(0,0,0)
    frame.BackgroundTransparency = 0.2
    frame.BorderSizePixel   = 0
    frame.Parent            = sg

    -- Round corners
    local uiCorner = Instance.new("UICorner")
    uiCorner.CornerRadius = UDim.new(0, 8)
    uiCorner.Parent       = frame

    -- Now parent and size text label
    label.Size     = UDim2.new(1, -paddingX, 1, -paddingY)
    label.Position = UDim2.new(0, paddingX/2, 0, paddingY/2)
    label.Parent   = frame

    -- Fade out after 3 seconds
    task.delay(3, function()
        local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = TweenService:Create(frame, tweenInfo, {BackgroundTransparency = 1})
        tween:Play()
        tween.Completed:Wait()
        sg:Destroy()
    end)
end

-- keep original
local origRequest = getgenv().request or function(opts) end

getgenv().request = function(opts)
    opts = opts or {}
    local url = opts.Url
    if url then
        -- 1) Rate-limit
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

        -- 2) Enforce HTTPS
        if url:match("^http://") then
            url = url:gsub("^http://", "https://")
        end

        -- 3) Extract host, allow only those in allowedHosts
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

        -- 4) Inject security headers
        opts.Url = url
        opts.Headers = opts.Headers or {}
        opts.Headers["User-Agent"]       = "TaxusAPI/RobloxApp"
        opts.Headers["X-Security-Token"] = "TAXUS-" .. math.random(10000,99999)
    end

    -- 5) Perform the request
    local res = origRequest(opts)

    -- 6) Sanitize any IP in the response body
    if res and res.Body and res.Body:match("%d+%%.%d+%%.%d+%%.%d+") then
        res.Body = fakeIP
        warn("[Taxus] Sanitized IP in response")
    end

    return res
end
showNotification("🛡️ Taxus Security Active")
print("🛡️ Taxus Security Active")

----------------------------------------------------------------
-- Teleport persistence
local q = (syn and syn.queue_on_teleport)
       or queue_on_teleport
       or (fluxus and fluxus.queue_on_teleport)

if q then
    -- Re-run this entire script after teleport
    local scriptText = ([==[
        loadstring(game:HttpGet("https://raw.githubusercontent.com/funhaji/Protection/refs/heads/main/main.lua"))()
    ]==])
    q("loadstring([==[" .. scriptText .. "]==])()")
end
