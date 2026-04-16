-- ================================================================
-- ZENO SUITE - Block + Mini AP + ESP + Grab
-- ================================================================
pcall(function() game:GetService("CoreGui"):FindFirstChild("ZenoSuite"):Destroy() end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local VIM = game:GetService("VirtualInputManager")
local CoreGui = game:GetService("CoreGui")
local lp = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ============ COLORS ============
local C = {
    BG      = Color3.fromRGB(6, 6, 10),
    CARD    = Color3.fromRGB(11, 11, 18),
    CARD2   = Color3.fromRGB(16, 16, 26),
    TEXT    = Color3.fromRGB(240, 238, 255),
    DIM     = Color3.fromRGB(100, 105, 140),
    WHITE   = Color3.new(1, 1, 1),
    BK      = Color3.fromRGB(255, 255, 255),
    BKD     = Color3.fromRGB(18, 18, 28),
    MA      = Color3.fromRGB(0, 225, 255),
    MAD     = Color3.fromRGB(0, 28, 40),
    GRAB    = Color3.fromRGB(80, 255, 110),
    GREEN   = Color3.fromRGB(60, 240, 80),
    RED     = Color3.fromRGB(255, 40, 55),
    ESP     = Color3.fromRGB(185, 80, 255),
    RS      = Color3.fromRGB(255, 195, 0),
    BORD    = Color3.fromRGB(32, 36, 65),
    ON      = Color3.fromRGB(60, 240, 80),
    OFF     = Color3.fromRGB(20, 20, 35),
}

-- ============ UTILS ============
local function tw(o, p, t)
    TweenService:Create(o, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), p):Play()
end
local function co(p, r)
    local c = Instance.new("UICorner", p)
    c.CornerRadius = UDim.new(0, r or 8)
end
local function stk(p, col, t, tr)
    local s = Instance.new("UIStroke", p)
    s.Color = col or C.BORD
    s.Thickness = t or 1
    s.Transparency = tr or 0.3
    return s
end

local touchMoved = false
local touchStartPos = Vector2.zero
UIS.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        touchMoved = false
        touchStartPos = Vector2.new(i.Position.X, i.Position.Y)
    end
end)
UIS.InputChanged:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.Touch then
        if (Vector2.new(i.Position.X, i.Position.Y) - touchStartPos).Magnitude > 14 then
            touchMoved = true
        end
    end
end)
local function safeClick(btn, fn)
    btn.MouseButton1Click:Connect(function()
        if isMobile and touchMoved then return end
        fn()
    end)
end

local function makeDrag(f)
    local dg, dgs, dsp = false, nil, nil
    f.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dg = true dgs = i.Position dsp = f.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then dg = false end
            end)
        end
    end)
    f.InputChanged:Connect(function(i)
        if dg and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local d = i.Position - dgs
            if d.Magnitude > 5 then
                f.Position = UDim2.new(dsp.X.Scale, dsp.X.Offset + d.X, dsp.Y.Scale, dsp.Y.Offset + d.Y)
            end
        end
    end)
end

-- ============ SCREEN GUI ============
local sg = Instance.new("ScreenGui")
sg.Name = "ZenoSuite"
sg.ResetOnSpawn = false
sg.IgnoreGuiInset = true
sg.DisplayOrder = 999
local _ok = pcall(function() sg.Parent = CoreGui end)
if not _ok then sg.Parent = lp:WaitForChild("PlayerGui") end

-- ============ AP CORE ============
local function fireBtn(b)
    pcall(function() for _, c in pairs(getconnections(b.MouseButton1Click)) do c:Fire() end end)
    pcall(function() for _, c in pairs(getconnections(b.Activated)) do c:Fire() end end)
end
local function findAP()
    return lp:WaitForChild("PlayerGui"):FindFirstChild("AdminPanel")
end
local function getBtnKw(ap, kw)
    for _, o in ipairs(ap:GetDescendants()) do
        if o:IsA("TextButton") or o:IsA("ImageButton") then
            local t = ""
            if o:IsA("TextButton") then
                t = o.Text:lower()
            else
                for _, c in ipairs(o:GetDescendants()) do
                    if c:IsA("TextLabel") then t = c.Text:lower() break end
                end
            end
            if t:find(kw:lower()) then return o end
        end
    end
end
local function getPBtn(ap, target)
    for _, o in ipairs(ap:GetDescendants()) do
        if o:IsA("TextButton") or o:IsA("ImageButton") then
            local t = ""
            if o:IsA("TextButton") then
                t = o.Text
            else
                for _, c in ipairs(o:GetDescendants()) do
                    if c:IsA("TextLabel") then t = c.Text break end
                end
            end
            if t == target.Name or t == target.DisplayName then return o end
        end
    end
end
local function runSingle(target, cmd)
    task.spawn(function()
        local ap = findAP() if not ap then return end
        local pb = getPBtn(ap, target) if pb then fireBtn(pb) task.wait(0.08) end
        local cb = getBtnKw(ap, cmd) if cb then fireBtn(cb) task.wait(0.08) end
        local pb2 = getPBtn(ap, target) if pb2 then fireBtn(pb2) end
    end)
end

-- ============ AUTO BLOCK ============
local blockCD = false
local autoBlockSteal = false

local function doBlock(target)
    if blockCD then return end
    blockCD = true
    local tgt = target
    if not tgt then
        local myR = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not myR then blockCD = false return end
        local best, bd = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local r = p.Character:FindFirstChild("HumanoidRootPart")
                if r then
                    local d = (myR.Position - r.Position).Magnitude
                    if d < bd then bd = d best = p end
                end
            end
        end
        tgt = best
    end
    if not tgt then blockCD = false return end
    pcall(function() StarterGui:SetCore("PromptBlockPlayer", tgt) end)
    task.wait(0.25)
    local vp = Camera.ViewportSize
    for i = 1, 3 do
        VIM:SendMouseButtonEvent(vp.X / 2, vp.Y * 0.565, 0, true, game, 1)
        task.wait(0.01)
        VIM:SendMouseButtonEvent(vp.X / 2, vp.Y * 0.565, 0, false, game, 1)
        task.wait(0.03)
    end
    task.wait(1.5)
    blockCD = false
end

local function doBlockAll()
    task.spawn(function()
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                pcall(function() StarterGui:SetCore("PromptBlockPlayer", p) end)
                task.wait(0.25)
                local vp = Camera.ViewportSize
                for i = 1, 3 do
                    VIM:SendMouseButtonEvent(vp.X / 2, vp.Y * 0.565, 0, true, game, 1)
                    task.wait(0.01)
                    VIM:SendMouseButtonEvent(vp.X / 2, vp.Y * 0.565, 0, false, game, 1)
                    task.wait(0.03)
                end
                task.wait(0.2)
            end
        end
    end)
end

-- ============ ANTI RAGDOLL ============
RunService.Heartbeat:Connect(function()
    local c = lp.Character if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local h = c:FindFirstChildOfClass("Humanoid") if not h then return end
    local st = h:GetState()
    if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
        h:ChangeState(Enum.HumanoidStateType.Running)
        Camera.CameraSubject = h
        if hrp then hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end
    end
    for _, o in ipairs(c:GetDescendants()) do
        if o:IsA("Motor6D") and not o.Enabled then o.Enabled = true end
    end
end)

-- ============ TIMER ESP ============
local timerESPs = {}
RunService.RenderStepped:Connect(function()
    local plots = workspace:FindFirstChild("Plots") if not plots then return end
    local function mkTESP(plot, part)
        if timerESPs[plot.Name] then pcall(function() timerESPs[plot.Name].bb:Destroy() end) end
        local bb = Instance.new("BillboardGui")
        bb.Size = UDim2.fromOffset(72, 22)
        bb.StudsOffset = Vector3.new(0, 9, 0)
        bb.AlwaysOnTop = true bb.Adornee = part bb.MaxDistance = 1500 bb.Parent = plot
        local bg2 = Instance.new("Frame", bb)
        bg2.Size = UDim2.new(1, 0, 1, 0) bg2.BackgroundColor3 = Color3.fromRGB(8, 8, 13)
        bg2.BackgroundTransparency = 0.15 bg2.BorderSizePixel = 0 co(bg2, 5) stk(bg2, C.RS, 1.5, 0.2)
        local lbl = Instance.new("TextLabel", bg2)
        lbl.Size = UDim2.new(1, 0, 1, 0) lbl.BackgroundTransparency = 1
        lbl.Font = Enum.Font.GothamBold lbl.TextSize = 11 lbl.TextColor3 = C.RS
        lbl.TextStrokeTransparency = 0.3 lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
        timerESPs[plot.Name] = {bb = bb, lbl = lbl}
    end
    for _, plot in ipairs(plots:GetChildren()) do
        local pur = plot:FindFirstChild("Purchases")
        local pb2 = pur and pur:FindFirstChild("PlotBlock")
        local mp = pb2 and pb2:FindFirstChild("Main")
        local tl = mp and mp:FindFirstChild("BillboardGui") and mp.BillboardGui:FindFirstChild("RemainingTime")
        if tl and mp then
            local e = timerESPs[plot.Name]
            if not e or not e.bb.Parent then mkTESP(plot, mp) e = timerESPs[plot.Name] end
            if e and e.lbl then
                e.lbl.Text = tl.Text
                local m, s = tl.Text:match("(%d+):(%d+)")
                if m and s then
                    local tot = tonumber(m) * 60 + tonumber(s)
                    e.lbl.TextColor3 = tot <= 30 and C.RED or tot <= 60 and C.RS or C.GRAB
                end
            end
        else
            local e = timerESPs[plot.Name]
            if e then pcall(function() e.bb:Destroy() end) timerESPs[plot.Name] = nil end
        end
    end
end)

-- ============ PLAYER ESP ============
local playerESPOn = false
local espConns = {}
local function mkESP(plr)
    if plr == lp then return end
    local char = plr.Character if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or char:FindFirstChild("ZenoESP_Box") then return end
    local box = Instance.new("BoxHandleAdornment", char)
    box.Name = "ZenoESP_Box" box.Adornee = hrp
    box.Size = Vector3.new(4, 6, 2) box.Color3 = C.ESP
    box.Transparency = 0.52 box.ZIndex = 10 box.AlwaysOnTop = true
    local bb = Instance.new("BillboardGui", char)
    bb.Name = "ZenoESP_Name"
    bb.Adornee = char:FindFirstChild("Head") or hrp
    bb.Size = UDim2.fromOffset(160, 34) bb.StudsOffset = Vector3.new(0, 3.5, 0) bb.AlwaysOnTop = true
    local bg2 = Instance.new("Frame", bb)
    bg2.Size = UDim2.new(1, 0, 1, 0) bg2.BackgroundColor3 = Color3.fromRGB(9, 5, 18)
    bg2.BackgroundTransparency = 0.18 bg2.BorderSizePixel = 0 co(bg2, 5) stk(bg2, C.ESP, 1.3, 0.15)
    local nl = Instance.new("TextLabel", bg2)
    nl.Size = UDim2.new(1, 0, 0.6, 0) nl.BackgroundTransparency = 1
    nl.Text = plr.DisplayName nl.Font = Enum.Font.GothamBold nl.TextSize = 11 nl.TextColor3 = C.ESP
    nl.TextStrokeTransparency = 0.35 nl.TextStrokeColor3 = Color3.new(0, 0, 0)
    local ul = Instance.new("TextLabel", bg2)
    ul.Size = UDim2.new(1, 0, 0.4, 0) ul.Position = UDim2.new(0, 0, 0.6, 0)
    ul.BackgroundTransparency = 1 ul.Text = "@" .. plr.Name ul.Font = Enum.Font.Gotham ul.TextSize = 8 ul.TextColor3 = C.DIM
end
local function rmESP(plr)
    if plr.Character then
        local b = plr.Character:FindFirstChild("ZenoESP_Box") if b then b:Destroy() end
        local n = plr.Character:FindFirstChild("ZenoESP_Name") if n then n:Destroy() end
    end
end
local function toggleESP(state)
    playerESPOn = state
    for _, c in ipairs(espConns) do c:Disconnect() end espConns = {}
    if state then
        for _, p in ipairs(Players:GetPlayers()) do if p ~= lp then mkESP(p) end end
        table.insert(espConns, Players.PlayerAdded:Connect(function(p)
            table.insert(espConns, p.CharacterAdded:Connect(function()
                task.wait(0.5) if playerESPOn then mkESP(p) end
            end))
        end))
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp then
                table.insert(espConns, p.CharacterAdded:Connect(function()
                    task.wait(0.5) if playerESPOn then mkESP(p) end
                end))
            end
        end
    else
        for _, p in ipairs(Players:GetPlayers()) do rmESP(p) end
    end
end

-- ============ INSTANT STEAL ============
local isStealing = false
local stealBarFill = nil
local stealBarTxt = nil
local allAnimals = {}
local promptCache = {}
local stealCache = {}
local GRAB_DIST = 4.5
local lastStolenPlayer = nil

local function isMyPlot(n)
    local pl = workspace:FindFirstChild("Plots") if not pl then return false end
    local p = pl:FindFirstChild(n) if not p then return false end
    local sign = p:FindFirstChild("PlotSign")
    if sign then
        local yb = sign:FindFirstChild("YourBase")
        if yb and yb:IsA("BillboardGui") then return yb.Enabled end
    end
    return false
end

local function getPlotOwner(plotName)
    local plots = workspace:FindFirstChild("Plots") if not plots then return nil end
    local plot = plots:FindFirstChild(plotName) if not plot then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= lp and p.Character then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local plotPos = plot:GetPivot().Position
                if (hrp.Position - plotPos).Magnitude < 60 then return p end
            end
        end
    end
    return nil
end

local function scanPlots()
    local plots = workspace:FindFirstChild("Plots") if not plots then return end
    allAnimals = {}
    for _, plot in ipairs(plots:GetChildren()) do
        if not isMyPlot(plot.Name) then
            local pods = plot:FindFirstChild("AnimalPodiums")
            if pods then
                for _, pod in ipairs(pods:GetChildren()) do
                    local base = pod:FindFirstChild("Base")
                    local spn = base and base:FindFirstChild("Spawn")
                    local att = spn and spn:FindFirstChild("PromptAttachment")
                    local wp = att and att.WorldPosition or pod:GetPivot().Position
                    table.insert(allAnimals, {plotName = plot.Name, slot = pod.Name, worldPos = wp, uid = plot.Name .. pod.Name})
                end
            end
        end
    end
end

task.spawn(function() while task.wait(2) do scanPlots() end end)

local function findPrompt(a)
    if promptCache[a.uid] and promptCache[a.uid].Parent then return promptCache[a.uid] end
    local plots = workspace:FindFirstChild("Plots") if not plots then return nil end
    local plot = plots:FindFirstChild(a.plotName) if not plot then return nil end
    local pods = plot:FindFirstChild("AnimalPodiums") if not pods then return nil end
    local pod = pods:FindFirstChild(a.slot) if not pod then return nil end
    local base = pod:FindFirstChild("Base")
    local spn = base and base:FindFirstChild("Spawn")
    local att = spn and spn:FindFirstChild("PromptAttachment") if not att then return nil end
    for _, p in ipairs(att:GetChildren()) do
        if p:IsA("ProximityPrompt") then promptCache[a.uid] = p return p end
    end
end

local function buildCB(prompt)
    if stealCache[prompt] then return end
    local data = {hold = {}, trigger = {}, ready = true}
    local ok1, c1 = pcall(getconnections, prompt.PromptButtonHoldBegan)
    if ok1 and type(c1) == "table" then
        for _, c in ipairs(c1) do if type(c.Function) == "function" then table.insert(data.hold, c.Function) end end
    end
    local ok2, c2 = pcall(getconnections, prompt.Triggered)
    if ok2 and type(c2) == "table" then
        for _, c in ipairs(c2) do if type(c.Function) == "function" then table.insert(data.trigger, c.Function) end end
    end
    stealCache[prompt] = data
end

local function execSteal(prompt, plotName)
    local data = stealCache[prompt]
    if not data or not data.ready or isStealing then return end
    data.ready = false isStealing = true
    if stealBarFill then tw(stealBarFill, {Size = UDim2.new(0.9, 0, 1, 0), BackgroundColor3 = C.GRAB}, 0.04) end
    if stealBarTxt then stealBarTxt.Text = "GRABBING!" end
    task.spawn(function()
        for _, fn in ipairs(data.hold) do task.spawn(fn) end
        local t0 = tick() local dur = 0.08
        while tick() - t0 < dur do
            if stealBarFill then
                stealBarFill.Size = UDim2.new(0.9 + ((tick() - t0) / dur) * 0.1, 0, 1, 0)
                tw(stealBarFill, {BackgroundColor3 = C.GREEN}, 0.03)
            end
            task.wait()
        end
        if stealBarFill then stealBarFill.Size = UDim2.new(1, 0, 1, 0) end
        for _, fn in ipairs(data.trigger) do task.spawn(fn) end
        pcall(function() fireproximityprompt(prompt, 0) end)
        -- AUTO BLOCK STEAL
        if autoBlockSteal and plotName then
            local owner = getPlotOwner(plotName)
            if owner then
                lastStolenPlayer = owner
                task.spawn(function() doBlock(owner) end)
            end
        end
        task.wait(0.1) data.ready = true isStealing = false
        if stealBarFill then tw(stealBarFill, {Size = UDim2.new(0.9, 0, 1, 0), BackgroundColor3 = C.GRAB}, 0.1) end
        if stealBarTxt then stealBarTxt.Text = "READY" end
    end)
end

RunService.Heartbeat:Connect(function()
    local hrp = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if isStealing then return end
    local best, bd = nil, math.huge
    for _, a in ipairs(allAnimals) do
        local d = (hrp.Position - a.worldPos).Magnitude
        if d < bd then bd = d best = a end
    end
    if stealBarFill then
        if not best then
            stealBarFill.Size = UDim2.new(0, 0, 1, 0)
            tw(stealBarFill, {BackgroundColor3 = C.GRAB}, 0.1)
        else
            stealBarFill.Size = UDim2.new(0.9, 0, 1, 0)
            tw(stealBarFill, {BackgroundColor3 = bd <= GRAB_DIST and C.GREEN or C.GRAB}, 0.08)
        end
    end
    if stealBarTxt then
        if not best then stealBarTxt.Text = "NO TARGETS"
        elseif bd <= GRAB_DIST then stealBarTxt.Text = "IN RANGE!"
        else stealBarTxt.Text = string.format("%.1fm  READY", bd) end
    end
    if not best or bd > GRAB_DIST then return end
    local prompt = promptCache[best.uid]
    if not prompt or not prompt.Parent then prompt = findPrompt(best) end
    if not prompt then return end
    buildCB(prompt)
    if stealCache[prompt] then execSteal(prompt, best.plotName) end
end)

-- ============ GRAB BAR (top center) ============
local grabBar = Instance.new("Frame", sg)
grabBar.Size = UDim2.fromOffset(172, 20)
grabBar.AnchorPoint = Vector2.new(0.5, 0)
grabBar.Position = UDim2.new(0.5, 0, 0, 6)
grabBar.BackgroundColor3 = C.BG
grabBar.BackgroundTransparency = 0.2
grabBar.BorderSizePixel = 0
co(grabBar, 8)
stk(grabBar, C.GRAB, 1.5, 0.2)
local gbBg = Instance.new("Frame", grabBar)
gbBg.Size = UDim2.new(0.9, 0, 0, 3)
gbBg.Position = UDim2.new(0.05, 0, 1, -5)
gbBg.BackgroundColor3 = C.CARD2
gbBg.BackgroundTransparency = 0.1
gbBg.BorderSizePixel = 0
co(gbBg, 3)
local gbFill = Instance.new("Frame", gbBg)
gbFill.Size = UDim2.new(0.9, 0, 1, 0)
gbFill.BackgroundColor3 = C.GRAB
gbFill.BorderSizePixel = 0
co(gbFill, 3)
stealBarFill = gbFill
local gbTxt = Instance.new("TextLabel", grabBar)
gbTxt.Size = UDim2.new(1, 0, 0.78, 0)
gbTxt.BackgroundTransparency = 1
gbTxt.Text = "ZENO GRAB"
gbTxt.Font = Enum.Font.GothamBold
gbTxt.TextSize = 8
gbTxt.TextColor3 = C.GRAB
gbTxt.ZIndex = 2
stealBarTxt = gbTxt

-- ============ PILL TOGGLE ============
local function makePill(parent, def, accentCol)
    accentCol = accentCol or C.ON
    local pw, ph = 32, 16
    local pill = Instance.new("Frame", parent)
    pill.Size = UDim2.fromOffset(pw, ph)
    pill.BackgroundColor3 = def and accentCol or C.OFF
    pill.BorderSizePixel = 0
    co(pill, ph)
    local cir = Instance.new("Frame", pill)
    cir.Size = UDim2.fromOffset(ph - 4, ph - 4)
    cir.Position = def and UDim2.new(1, -(ph - 2), 0.5, -(ph - 4) / 2) or UDim2.new(0, 2, 0.5, -(ph - 4) / 2)
    cir.BackgroundColor3 = Color3.new(1, 1, 1)
    cir.BorderSizePixel = 0
    co(cir, ph)
    local function setV(state, sRef)
        tw(pill, {BackgroundColor3 = state and accentCol or C.OFF}, 0.12)
        tw(cir, {Position = state and UDim2.new(1, -(ph - 2), 0.5, -(ph - 4) / 2) or UDim2.new(0, 2, 0.5, -(ph - 4) / 2)}, 0.12, Enum.EasingStyle.Back)
        if sRef then tw(sRef, {Color = state and accentCol or C.BORD, Transparency = state and 0.05 or 0.45}, 0.12) end
    end
    return pill, setV
end

-- ============ BLOCK PANEL ============
-- Main block window
local bkWin = Instance.new("Frame", sg)
bkWin.Name = "BlockWin"
bkWin.Size = UDim2.fromOffset(260, 0)
bkWin.Position = UDim2.new(0.5, -130, 0.5, -80)
bkWin.BackgroundColor3 = Color3.fromRGB(8, 8, 14)
bkWin.BackgroundTransparency = 0.05
bkWin.BorderSizePixel = 0
bkWin.AutomaticSize = Enum.AutomaticSize.Y
bkWin.Active = true
co(bkWin, 14)
stk(bkWin, C.BK, 1.5, 0.55)
makeDrag(bkWin)

-- Header
local bkHdr = Instance.new("Frame", bkWin)
bkHdr.Size = UDim2.new(1, 0, 0, 44)
bkHdr.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
bkHdr.BackgroundTransparency = 0.05
bkHdr.BorderSizePixel = 0
co(bkHdr, 14)
-- Fix bottom corners of header
local bkHdrFix = Instance.new("Frame", bkHdr)
bkHdrFix.Size = UDim2.new(1, 0, 0.5, 0)
bkHdrFix.Position = UDim2.new(0, 0, 0.5, 0)
bkHdrFix.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
bkHdrFix.BackgroundTransparency = 0.05
bkHdrFix.BorderSizePixel = 0

local bkTitle = Instance.new("TextLabel", bkHdr)
bkTitle.Size = UDim2.new(1, -40, 1, 0)
bkTitle.Position = UDim2.fromOffset(14, 0)
bkTitle.BackgroundTransparency = 1
bkTitle.Text = "INSTANT BLOCK"
bkTitle.Font = Enum.Font.GothamBlack
bkTitle.TextSize = 13
bkTitle.TextColor3 = C.WHITE
bkTitle.TextXAlignment = Enum.TextXAlignment.Left

local bkClose = Instance.new("TextButton", bkHdr)
bkClose.Size = UDim2.fromOffset(24, 24)
bkClose.Position = UDim2.new(1, -32, 0.5, -12)
bkClose.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
bkClose.BackgroundTransparency = 0.1
bkClose.BorderSizePixel = 0
bkClose.Text = "x"
bkClose.Font = Enum.Font.GothamBold
bkClose.TextSize = 12
bkClose.TextColor3 = C.RED
bkClose.AutoButtonColor = false
co(bkClose, 6)

-- Divider line under header
local bkHdrLine = Instance.new("Frame", bkWin)
bkHdrLine.Size = UDim2.new(1, 0, 0, 1)
bkHdrLine.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
bkHdrLine.BorderSizePixel = 0

-- Content
local bkCnt = Instance.new("Frame", bkWin)
bkCnt.Size = UDim2.new(1, 0, 0, 0)
bkCnt.AutomaticSize = Enum.AutomaticSize.Y
bkCnt.BackgroundTransparency = 1
bkCnt.BorderSizePixel = 0
local bkPad = Instance.new("UIPadding", bkCnt)
bkPad.PaddingTop = UDim.new(0, 8)
bkPad.PaddingBottom = UDim.new(0, 10)
bkPad.PaddingLeft = UDim.new(0, 10)
bkPad.PaddingRight = UDim.new(0, 10)
local bkLy = Instance.new("UIListLayout", bkCnt)
bkLy.Padding = UDim.new(0, 6)
bkLy.SortOrder = Enum.SortOrder.LayoutOrder
bkLy.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Auto Block Steal row
local absRow = Instance.new("Frame", bkCnt)
absRow.Size = UDim2.new(1, 0, 0, 38)
absRow.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
absRow.BackgroundTransparency = 0.05
absRow.BorderSizePixel = 0
absRow.LayoutOrder = 1
co(absRow, 10)
stk(absRow, Color3.fromRGB(40, 40, 70), 1, 0.5)

local absLbl = Instance.new("TextLabel", absRow)
absLbl.Size = UDim2.new(1, -50, 1, 0)
absLbl.Position = UDim2.fromOffset(12, 0)
absLbl.BackgroundTransparency = 1
absLbl.Text = "AUTO BLOCK STEAL: OFF"
absLbl.Font = Enum.Font.GothamBold
absLbl.TextSize = 11
absLbl.TextColor3 = C.WHITE
absLbl.TextXAlignment = Enum.TextXAlignment.Left

local absPill, absPillSet = makePill(absRow, false, C.GREEN)
absPill.Position = UDim2.new(1, -42, 0.5, -8)

local absBtn = Instance.new("TextButton", absRow)
absBtn.Size = UDim2.new(1, 0, 1, 0)
absBtn.BackgroundTransparency = 1
absBtn.Text = ""
absBtn.ZIndex = 5
safeClick(absBtn, function()
    autoBlockSteal = not autoBlockSteal
    absPillSet(autoBlockSteal, nil)
    absLbl.Text = autoBlockSteal and "AUTO BLOCK STEAL: ON" or "AUTO BLOCK STEAL: OFF"
    absLbl.TextColor3 = autoBlockSteal and C.GREEN or C.WHITE
end)

-- Block All row
local baRow = Instance.new("Frame", bkCnt)
baRow.Size = UDim2.new(1, 0, 0, 38)
baRow.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
baRow.BackgroundTransparency = 0.05
baRow.BorderSizePixel = 0
baRow.LayoutOrder = 2
co(baRow, 10)
stk(baRow, Color3.fromRGB(40, 40, 70), 1, 0.5)

local baLbl = Instance.new("TextLabel", baRow)
baLbl.Size = UDim2.new(0.6, 0, 1, 0)
baLbl.Position = UDim2.fromOffset(12, 0)
baLbl.BackgroundTransparency = 1
baLbl.Text = "BLOCK ALL"
baLbl.Font = Enum.Font.GothamBold
baLbl.TextSize = 11
baLbl.TextColor3 = C.WHITE
baLbl.TextXAlignment = Enum.TextXAlignment.Left

local baHkLbl = Instance.new("TextLabel", baRow)
baHkLbl.Size = UDim2.fromOffset(32, 22)
baHkLbl.Position = UDim2.new(1, -42, 0.5, -11)
baHkLbl.BackgroundColor3 = Color3.fromRGB(22, 22, 36)
baHkLbl.BackgroundTransparency = 0.1
baHkLbl.BorderSizePixel = 0
baHkLbl.Text = "[P]"
baHkLbl.Font = Enum.Font.GothamBold
baHkLbl.TextSize = 9
baHkLbl.TextColor3 = C.DIM
co(baHkLbl, 5)

local baBtn = Instance.new("TextButton", baRow)
baBtn.Size = UDim2.new(1, 0, 1, 0)
baBtn.BackgroundTransparency = 1
baBtn.Text = ""
baBtn.ZIndex = 5
safeClick(baBtn, function()
    baLbl.Text = "blocking..."
    baLbl.TextColor3 = C.DIM
    doBlockAll()
    task.delay(4, function()
        if baLbl.Parent then
            baLbl.Text = "BLOCK ALL"
            baLbl.TextColor3 = C.WHITE
        end
    end)
end)

-- Divider before player list
local bkDiv = Instance.new("Frame", bkCnt)
bkDiv.Size = UDim2.new(1, 0, 0, 1)
bkDiv.BackgroundColor3 = Color3.fromRGB(28, 28, 45)
bkDiv.BackgroundTransparency = 0.3
bkDiv.BorderSizePixel = 0
bkDiv.LayoutOrder = 3

-- Player scroll
local bkScrollFrame = Instance.new("Frame", bkCnt)
bkScrollFrame.Size = UDim2.new(1, 0, 0, 0)
bkScrollFrame.AutomaticSize = Enum.AutomaticSize.Y
bkScrollFrame.BackgroundTransparency = 1
bkScrollFrame.BorderSizePixel = 0
bkScrollFrame.LayoutOrder = 4
bkScrollFrame.ClipsDescendants = true

local bkScroll = Instance.new("ScrollingFrame", bkScrollFrame)
bkScroll.Size = UDim2.new(1, 0, 0, 160)
bkScroll.BackgroundTransparency = 1
bkScroll.BorderSizePixel = 0
bkScroll.ScrollBarThickness = 2
bkScroll.ScrollBarImageColor3 = C.BK
bkScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
bkScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local bkSLy = Instance.new("UIListLayout", bkScroll)
bkSLy.Padding = UDim.new(0, 6)
bkSLy.SortOrder = Enum.SortOrder.LayoutOrder

local function buildBlockList()
    for _, c in ipairs(bkScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local count = 0
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            count = count + 1
            local row = Instance.new("Frame", bkScroll)
            row.Size = UDim2.new(1, -4, 0, 46)
            row.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
            row.BackgroundTransparency = 0.05
            row.BorderSizePixel = 0
            row.LayoutOrder = i
            co(row, 10)
            stk(row, Color3.fromRGB(35, 35, 60), 1, 0.55)

            -- Avatar
            local av = Instance.new("ImageLabel", row)
            av.Size = UDim2.fromOffset(34, 34)
            av.Position = UDim2.new(0, 7, 0.5, -17)
            av.BackgroundColor3 = C.CARD
            av.BorderSizePixel = 0
            co(av, 8)
            av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=48&height=48&format=png"

            -- Name
            local nl = Instance.new("TextLabel", row)
            nl.Size = UDim2.new(0, 100, 0, 16)
            nl.Position = UDim2.fromOffset(48, 7)
            nl.BackgroundTransparency = 1
            nl.Text = p.DisplayName
            nl.Font = Enum.Font.GothamBold
            nl.TextSize = 11
            nl.TextColor3 = C.WHITE
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.TextTruncate = Enum.TextTruncate.AtEnd

            local ul = Instance.new("TextLabel", row)
            ul.Size = UDim2.new(0, 100, 0, 13)
            ul.Position = UDim2.fromOffset(48, 24)
            ul.BackgroundTransparency = 1
            ul.Text = p.Name
            ul.Font = Enum.Font.Gotham
            ul.TextSize = 9
            ul.TextColor3 = C.DIM
            ul.TextXAlignment = Enum.TextXAlignment.Left
            ul.TextTruncate = Enum.TextTruncate.AtEnd

            -- BLOCK button
            local bBtn = Instance.new("TextButton", row)
            bBtn.Size = UDim2.fromOffset(58, 28)
            bBtn.Position = UDim2.new(1, -66, 0.5, -14)
            bBtn.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
            bBtn.BackgroundTransparency = 0.0
            bBtn.BorderSizePixel = 0
            bBtn.Text = "BLOCK"
            bBtn.Font = Enum.Font.GothamBlack
            bBtn.TextSize = 11
            bBtn.TextColor3 = Color3.fromRGB(8, 8, 14)
            bBtn.AutoButtonColor = false
            co(bBtn, 8)

            local cap = p
            safeClick(bBtn, function()
                bBtn.Text = "..."
                bBtn.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
                task.spawn(function()
                    doBlock(cap)
                    if bBtn.Parent then
                        bBtn.Text = "BLOCKED"
                        bBtn.BackgroundColor3 = Color3.fromRGB(60, 240, 80)
                        bBtn.TextColor3 = Color3.fromRGB(8, 8, 14)
                    end
                end)
            end)
        end
    end
    -- Adjust scroll height based on player count
    local h = math.min(count * 52, 200)
    bkScroll.Size = UDim2.new(1, 0, 0, math.max(h, 52))
end

-- Reopen button
local bkReo = Instance.new("TextButton", sg)
bkReo.Size = UDim2.fromOffset(50, 22)
bkReo.Position = UDim2.new(0.5, -25, 0.5, -80)
bkReo.BackgroundColor3 = C.CARD
bkReo.BackgroundTransparency = 0.15
bkReo.BorderSizePixel = 0
bkReo.Text = "BLOCK"
bkReo.Font = Enum.Font.GothamBlack
bkReo.TextSize = 9
bkReo.TextColor3 = C.WHITE
bkReo.Visible = false
bkReo.ZIndex = 20
co(bkReo, 8)
stk(bkReo, C.WHITE, 1.2, 0.4)
safeClick(bkReo, function() bkReo.Visible = false bkWin.Visible = true buildBlockList() end)
safeClick(bkClose, function() bkWin.Visible = false bkReo.Visible = true end)

-- ============ MINI AP PANEL ============
local maWin = Instance.new("Frame", sg)
maWin.Name = "MiniAPWin"
maWin.Size = UDim2.fromOffset(280, 0)
maWin.Position = UDim2.new(0.5, -140, 0.5, 20)
maWin.BackgroundColor3 = Color3.fromRGB(4, 14, 32)
maWin.BackgroundTransparency = 0.05
maWin.BorderSizePixel = 0
maWin.AutomaticSize = Enum.AutomaticSize.Y
maWin.Active = true
co(maWin, 14)
stk(maWin, C.MA, 1.5, 0.35)
makeDrag(maWin)

local maHdr = Instance.new("Frame", maWin)
maHdr.Size = UDim2.new(1, 0, 0, 44)
maHdr.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
maHdr.BackgroundTransparency = 0.05
maHdr.BorderSizePixel = 0
co(maHdr, 14)
local maHdrFix = Instance.new("Frame", maHdr)
maHdrFix.Size = UDim2.new(1, 0, 0.5, 0)
maHdrFix.Position = UDim2.new(0, 0, 0.5, 0)
maHdrFix.BackgroundColor3 = Color3.fromRGB(0, 20, 40)
maHdrFix.BackgroundTransparency = 0.05
maHdrFix.BorderSizePixel = 0

local maTitle = Instance.new("TextLabel", maHdr)
maTitle.Size = UDim2.new(1, -40, 1, 0)
maTitle.Position = UDim2.fromOffset(14, 0)
maTitle.BackgroundTransparency = 1
maTitle.Text = "MINI AP"
maTitle.Font = Enum.Font.GothamBlack
maTitle.TextSize = 13
maTitle.TextColor3 = C.MA
maTitle.TextXAlignment = Enum.TextXAlignment.Left

local maClose = Instance.new("TextButton", maHdr)
maClose.Size = UDim2.fromOffset(24, 24)
maClose.Position = UDim2.new(1, -32, 0.5, -12)
maClose.BackgroundColor3 = Color3.fromRGB(40, 10, 10)
maClose.BackgroundTransparency = 0.1
maClose.BorderSizePixel = 0
maClose.Text = "x"
maClose.Font = Enum.Font.GothamBold
maClose.TextSize = 12
maClose.TextColor3 = C.RED
maClose.AutoButtonColor = false
co(maClose, 6)

local maHdrLine = Instance.new("Frame", maWin)
maHdrLine.Size = UDim2.new(1, 0, 0, 1)
maHdrLine.BackgroundColor3 = Color3.fromRGB(0, 50, 80)
maHdrLine.BorderSizePixel = 0

local maCnt = Instance.new("Frame", maWin)
maCnt.Size = UDim2.new(1, 0, 0, 0)
maCnt.AutomaticSize = Enum.AutomaticSize.Y
maCnt.BackgroundTransparency = 1
maCnt.BorderSizePixel = 0
local maPad = Instance.new("UIPadding", maCnt)
maPad.PaddingTop = UDim.new(0, 6)
maPad.PaddingBottom = UDim.new(0, 8)
maPad.PaddingLeft = UDim.new(0, 8)
maPad.PaddingRight = UDim.new(0, 8)
local maLy = Instance.new("UIListLayout", maCnt)
maLy.Padding = UDim.new(0, 5)
maLy.SortOrder = Enum.SortOrder.LayoutOrder

-- Column headers
local maColHdr = Instance.new("Frame", maCnt)
maColHdr.Size = UDim2.new(1, 0, 0, 18)
maColHdr.BackgroundTransparency = 1
maColHdr.BorderSizePixel = 0
maColHdr.LayoutOrder = 0

local MINI_CMDS = {
    {e = "🎈", k = "balloon",   cd = 29,  col = Color3.fromRGB(55, 115, 255)},
    {e = "🤸",  k = "ragdoll",  cd = 29,  col = Color3.fromRGB(220, 40, 40)},
    {e = "⛓",   k = "jail",     cd = 59,  col = Color3.fromRGB(25, 170, 60)},
    {e = "🚀",  k = "rocket",   cd = 119, col = Color3.fromRGB(220, 120, 20)},
    {e = "🐜",  k = "tiny",     cd = 59,  col = Color3.fromRGB(130, 30, 220)},
}

-- Header labels for commands
local colHdrNameLbl = Instance.new("TextLabel", maColHdr)
colHdrNameLbl.Size = UDim2.fromOffset(80, 18)
colHdrNameLbl.Position = UDim2.fromOffset(46, 0)
colHdrNameLbl.BackgroundTransparency = 1
colHdrNameLbl.Text = "PLAYER"
colHdrNameLbl.Font = Enum.Font.GothamBold
colHdrNameLbl.TextSize = 8
colHdrNameLbl.TextColor3 = C.DIM
colHdrNameLbl.TextXAlignment = Enum.TextXAlignment.Left

local xOffHdr = 140
for _, cmd in ipairs(MINI_CMDS) do
    local lbl = Instance.new("TextLabel", maColHdr)
    lbl.Size = UDim2.fromOffset(30, 18)
    lbl.Position = UDim2.fromOffset(xOffHdr, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = cmd.e
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 11
    lbl.TextColor3 = cmd.col
    lbl.TextXAlignment = Enum.TextXAlignment.Center
    xOffHdr = xOffHdr + 24
end

-- Scroll for players
local maScrollOuter = Instance.new("Frame", maCnt)
maScrollOuter.Size = UDim2.new(1, 0, 0, 160)
maScrollOuter.BackgroundTransparency = 1
maScrollOuter.BorderSizePixel = 0
maScrollOuter.ClipsDescendants = true
maScrollOuter.LayoutOrder = 1

local maScroll = Instance.new("ScrollingFrame", maScrollOuter)
maScroll.Size = UDim2.new(1, 0, 1, 0)
maScroll.BackgroundTransparency = 1
maScroll.BorderSizePixel = 0
maScroll.ScrollBarThickness = 2
maScroll.ScrollBarImageColor3 = C.MA
maScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
maScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
local maSLy = Instance.new("UIListLayout", maScroll)
maSLy.Padding = UDim.new(0, 5)
maSLy.SortOrder = Enum.SortOrder.LayoutOrder

local function buildMiniCards()
    for _, c in ipairs(maScroll:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end
    local count = 0
    for i, p in ipairs(Players:GetPlayers()) do
        if p ~= lp then
            count = count + 1
            -- Separator line between players
            if count > 1 then
                local sep = Instance.new("Frame", maScroll)
                sep.Size = UDim2.new(1, 0, 0, 1)
                sep.BackgroundColor3 = Color3.fromRGB(0, 40, 65)
                sep.BackgroundTransparency = 0.4
                sep.BorderSizePixel = 0
                sep.LayoutOrder = i * 2 - 1
            end

            local row = Instance.new("Frame", maScroll)
            row.Size = UDim2.new(1, -2, 0, 42)
            row.BackgroundColor3 = Color3.fromRGB(5, 18, 35)
            row.BackgroundTransparency = 0.1
            row.BorderSizePixel = 0
            row.LayoutOrder = i * 2
            co(row, 8)

            -- Avatar
            local av = Instance.new("ImageLabel", row)
            av.Size = UDim2.fromOffset(30, 30)
            av.Position = UDim2.new(0, 6, 0.5, -15)
            av.BackgroundColor3 = C.CARD
            av.BorderSizePixel = 0
            co(av, 7)
            av.Image = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. p.UserId .. "&width=48&height=48&format=png"

            -- Display name
            local nl = Instance.new("TextLabel", row)
            nl.Size = UDim2.fromOffset(80, 14)
            nl.Position = UDim2.fromOffset(40, 5)
            nl.BackgroundTransparency = 1
            nl.Text = p.DisplayName
            nl.Font = Enum.Font.GothamBold
            nl.TextSize = 10
            nl.TextColor3 = C.WHITE
            nl.TextXAlignment = Enum.TextXAlignment.Left
            nl.TextTruncate = Enum.TextTruncate.AtEnd

            -- Username
            local ul = Instance.new("TextLabel", row)
            ul.Size = UDim2.fromOffset(80, 12)
            ul.Position = UDim2.fromOffset(40, 20)
            ul.BackgroundTransparency = 1
            ul.Text = "@" .. p.Name
            ul.Font = Enum.Font.Gotham
            ul.TextSize = 8
            ul.TextColor3 = C.DIM
            ul.TextXAlignment = Enum.TextXAlignment.Left
            ul.TextTruncate = Enum.TextTruncate.AtEnd

            -- Command buttons
            local xOff = 128
            for _, cmd in ipairs(MINI_CMDS) do
                local btn = Instance.new("TextButton", row)
                btn.Size = UDim2.fromOffset(22, 22)
                btn.Position = UDim2.new(0, xOff, 0.5, -11)
                btn.BackgroundColor3 = cmd.col
                btn.BackgroundTransparency = 0.1
                btn.BorderSizePixel = 0
                btn.Text = cmd.e
                btn.Font = Enum.Font.GothamBold
                btn.TextSize = 11
                btn.AutoButtonColor = false
                co(btn, 5)

                local cdLbl = Instance.new("TextLabel", btn)
                cdLbl.Size = UDim2.new(1, 0, 1, 0)
                cdLbl.BackgroundTransparency = 1
                cdLbl.Text = ""
                cdLbl.Font = Enum.Font.GothamBold
                cdLbl.TextSize = 7
                cdLbl.TextColor3 = Color3.new(1, 1, 1)
                cdLbl.ZIndex = 2

                local onCD = false
                local captK = cmd.k
                local captP = p
                local captCD = cmd.cd
                local captCol = cmd.col

                safeClick(btn, function()
                    if onCD then return end
                    onCD = true
                    local cdEnd = tick() + captCD
                    btn.BackgroundColor3 = Color3.fromRGB(30, 8, 8)
                    btn.Text = ""
                    runSingle(captP, captK)
                    task.spawn(function()
                        while tick() < cdEnd do
                            if cdLbl.Parent then cdLbl.Text = tostring(math.ceil(cdEnd - tick())) end
                            task.wait(0.5)
                        end
                        if btn.Parent then
                            btn.Text = cmd.e
                            cdLbl.Text = ""
                            btn.BackgroundColor3 = captCol
                        end
                        onCD = false
                    end)
                end)
                xOff = xOff + 26
            end
        end
    end
    -- Adjust scroll
    local h = math.min(count * 47, 200)
    maScrollOuter.Size = UDim2.new(1, 0, 0, math.max(h, 42))
end

local maReo = Instance.new("TextButton", sg)
maReo.Size = UDim2.fromOffset(50, 22)
maReo.Position = UDim2.new(0.5, -25, 0.5, 20)
maReo.BackgroundColor3 = C.CARD
maReo.BackgroundTransparency = 0.15
maReo.BorderSizePixel = 0
maReo.Text = "MINI AP"
maReo.Font = Enum.Font.GothamBlack
maReo.TextSize = 8
maReo.TextColor3 = C.MA
maReo.Visible = false
maReo.ZIndex = 20
co(maReo, 8)
stk(maReo, C.MA, 1.2, 0.4)
safeClick(maReo, function() maReo.Visible = false maWin.Visible = true buildMiniCards() end)
safeClick(maClose, function() maWin.Visible = false maReo.Visible = true end)

-- ============ ESP TOGGLE BAR ============
local espBar = Instance.new("Frame", sg)
espBar.Size = UDim2.fromOffset(160, 28)
espBar.AnchorPoint = Vector2.new(1, 0)
espBar.Position = UDim2.new(1, -6, 0, 6)
espBar.BackgroundColor3 = C.BG
espBar.BackgroundTransparency = 0.2
espBar.BorderSizePixel = 0
co(espBar, 8)
stk(espBar, C.ESP, 1.2, 0.3)
makeDrag(espBar)

local espLbl = Instance.new("TextLabel", espBar)
espLbl.Size = UDim2.new(1, -44, 1, 0)
espLbl.Position = UDim2.fromOffset(8, 0)
espLbl.BackgroundTransparency = 1
espLbl.Text = "Player ESP: OFF"
espLbl.Font = Enum.Font.GothamBold
espLbl.TextSize = 9
espLbl.TextColor3 = C.DIM
espLbl.TextXAlignment = Enum.TextXAlignment.Left

local espPill, espPillSet = makePill(espBar, false, C.ESP)
espPill.Position = UDim2.new(1, -40, 0.5, -8)

local espBtn = Instance.new("TextButton", espBar)
espBtn.Size = UDim2.new(1, 0, 1, 0)
espBtn.BackgroundTransparency = 1
espBtn.Text = ""
safeClick(espBtn, function()
    playerESPOn = not playerESPOn
    espPillSet(playerESPOn, nil)
    espLbl.Text = playerESPOn and "Player ESP: ON" or "Player ESP: OFF"
    espLbl.TextColor3 = playerESPOn and C.ESP or C.DIM
    toggleESP(playerESPOn)
end)

-- ============ BOTTOM OPEN BUTTONS ============
local btnBar = Instance.new("Frame", sg)
btnBar.Size = UDim2.fromOffset(0, 34)
btnBar.Position = UDim2.new(0, 6, 1, -44)
btnBar.BackgroundTransparency = 1
btnBar.AutomaticSize = Enum.AutomaticSize.X
btnBar.BorderSizePixel = 0
local btnLy = Instance.new("UIListLayout", btnBar)
btnLy.FillDirection = Enum.FillDirection.Horizontal
btnLy.Padding = UDim.new(0, 5)
btnLy.VerticalAlignment = Enum.VerticalAlignment.Center

local function bottomBtn(label, col, cb2)
    local f = Instance.new("Frame", btnBar)
    f.Size = UDim2.fromOffset(46, 32)
    f.BackgroundColor3 = C.CARD
    f.BackgroundTransparency = 0.15
    f.BorderSizePixel = 0
    co(f, 10)
    stk(f, col, 1.5, 0.3)
    local b = Instance.new("TextButton", f)
    b.Size = UDim2.new(1, 0, 1, 0)
    b.BackgroundTransparency = 1
    b.Text = label
    b.Font = Enum.Font.GothamBlack
    b.TextSize = 9
    b.TextColor3 = col
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    safeClick(b, cb2)
end

bottomBtn("BL", C.WHITE, function()
    bkWin.Visible = not bkWin.Visible
    bkReo.Visible = false
    if bkWin.Visible then buildBlockList() end
end)
bottomBtn("AP", C.MA, function()
    maWin.Visible = not maWin.Visible
    maReo.Visible = false
    if maWin.Visible then buildMiniCards() end
end)

-- ============ PLAYER UPDATES ============
local function hookPlayer(p)
    if p == lp then return end
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        if playerESPOn then mkESP(p) end
        task.spawn(function()
            task.wait(0.3)
            if bkWin.Visible then buildBlockList() end
            if maWin.Visible then buildMiniCards() end
        end)
    end)
    if p.Character and playerESPOn then task.spawn(function() mkESP(p) end) end
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(function(p)
    hookPlayer(p)
    task.wait(0.5)
    if bkWin.Visible then buildBlockList() end
    if maWin.Visible then buildMiniCards() end
end)
Players.PlayerRemoving:Connect(function(p)
    task.wait(0.2)
    if bkWin.Visible then buildBlockList() end
    if maWin.Visible then buildMiniCards() end
end)

-- Periodic refresh
task.spawn(function()
    while sg.Parent do
        task.wait(6)
        if bkWin.Visible then buildBlockList() end
        if maWin.Visible then buildMiniCards() end
    end
end)

-- [P] hotkey for block all
UIS.InputBegan:Connect(function(inp, gpe)
    if gpe then return end
    if UIS:GetFocusedTextBox() then return end
    if inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode == Enum.KeyCode.P then
        doBlockAll()
    end
end)

-- Initial build
task.spawn(function()
    task.wait(1)
    buildBlockList()
    buildMiniCards()
end)

print("[ZenoSuite] Loaded - Block + Mini AP + ESP + Grab")
