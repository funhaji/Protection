
local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local TextService  = game:GetService("TextService")

local allowedHosts = {
    "^www%.roblox%.com$", "^apis%.roblox%.com$", "^auth%.roblox%.com$",
    "^raw%.githubusercontent%.com$", "^gist%.githubusercontent%.com$",
    "^pastebin%.com$", "^pastebinusercontent%.com$",
    "^controlc%.com$", "^controlc%.dev$",
    "^rentry%.co$", "^rentry%.org$",
    "^api%.luarmor%.net$",
}

local fakeIP, rateMax, rateWindow = "0.0.0.0", 5, 60
local requestTimes = {}

local function showNotification(text)
    local gui = Players.LocalPlayer:WaitForChild("PlayerGui")
    local sg  = Instance.new("ScreenGui", gui)
    sg.Name, sg.ResetOnSpawn = "TaxusNotification", false

    local label = Instance.new("TextLabel")
    label.Text, label.TextSize, label.Font = text, 14, Enum.Font.SourceSans
    label.BackgroundTransparency, label.TextColor3 = 1, Color3.new(1,1,1)

    local sz = TextService:GetTextSize(text, label.TextSize, label.Font, Vector2.new(math.huge,math.huge))
    local padX, padY = 20, 10
    local frame = Instance.new("Frame", sg)
    frame.Size     = UDim2.new(0, sz.X+padX, 0, sz.Y+padY)
    frame.Position = UDim2.new(1, -(sz.X+padX)-10, 1, -(sz.Y+padY)-10)
    frame.BackgroundColor3, frame.BackgroundTransparency = Color3.new(0,0,0), 0.2
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

    label.Size     = UDim2.new(1, -padX, 1, -padY)
    label.Position = UDim2.new(0, padX/2, 0, padY/2)
    label.Parent   = frame

    task.delay(3, function()
        local tween = TweenService:Create(frame, TweenInfo.new(1, Enum.EasingStyle.Quad), {BackgroundTransparency=1})
        tween:Play(); tween.Completed:Wait(); sg:Destroy()
    end)
end

local origRequest = getgenv().request or function(opts) end
getgenv().request = function(opts)
    opts = opts or {}
    local url = opts.Url
    if url then
        -- Rate limiting
        local now = os.time()
        for i=#requestTimes,1,-1 do
            if now - requestTimes[i] > rateWindow then
                table.remove(requestTimes, i)
            end
        end
        if #requestTimes >= rateMax then
            warn("[Taxus] Rate limit exceeded")
            return { Success=false, StatusMessage="Rate Limited" }
        end
        table.insert(requestTimes, now)

        if url:match("^http://") then
            url = url:gsub("^http://", "https://")
        end

        local host = url:match("^https?://([^/]+)") or ""
        local ok = false
        for _,pat in ipairs(allowedHosts) do
            if host:match(pat) then ok = true; break end
        end
        if not ok then
            warn("[Taxus] Blocked:", host)
            showNotification("🛡️ Blocked: "..host)
            return { Body=fakeIP }
        end

        opts.Url = url
        opts.Headers = opts.Headers or {}
        opts.Headers["User-Agent"]       = "TaxusAPI/RobloxApp"
        opts.Headers["X-Security-Token"] = "TAXUS-"..math.random(10000,99999)
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


local function loadProtection()
    print("[Taxus] Loading Protection…")
    loadstring(
      game:HttpGet("https://raw.githubusercontent.com/funhaji/Protection/main/main.lua", true)
    )()
end

Players.LocalPlayer.CharacterAdded:Connect(loadProtection)


local function registerTeleportHook()
    local payload = [[
        print("[Taxus] Running queued Protection…")
        loadstring(
          game:HttpGet("https://raw.githubusercontent.com/funhaji/Protection/main/main.lua", true)
        )()
    ]]
    local q = (syn and syn.queue_on_teleport)
           or queue_on_teleport
           or getgenv().queue_on_teleport
           or (fluxus and fluxus.queue_on_teleport)

    if not q then
        warn("[Taxus] No queue_on_teleport detected; multi-place teleports won’t auto-reload.")
        return
    end

    q(payload)
    print("[Taxus] Protection script queued for next teleport.")
end

registerTeleportHook()
