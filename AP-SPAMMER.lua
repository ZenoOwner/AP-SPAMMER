-- ================================================================
-- PHANTOM SUITE V2 - Made by Phantom / r9qbx
-- ================================================================
task.spawn(function()
local ok,err=pcall(function()
repeat task.wait() until game:IsLoaded()

local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local TweenService=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")
local StarterGui=game:GetService("StarterGui")
local VIM=game:GetService("VirtualInputManager")
local CoreGui=game:GetService("CoreGui")
local lp=Players.LocalPlayer
local Camera=workspace.CurrentCamera
local isMobile=UIS.TouchEnabled and not UIS.KeyboardEnabled

-- ================================================================
-- COLORS
-- ================================================================
local C={
    BG    = Color3.fromRGB(5,6,14),
    CARD  = Color3.fromRGB(9,11,22),
    CARD2 = Color3.fromRGB(13,16,30),
    BORD  = Color3.fromRGB(32,40,80),
    TEXT  = Color3.fromRGB(240,236,255),
    DIM   = Color3.fromRGB(100,108,148),
    WHITE = Color3.new(1,1,1),
    -- Panel accents
    AP    = Color3.fromRGB(255,80,0),    -- orange-red  (AP)
    BL    = Color3.fromRGB(255,30,65),   -- vivid red   (Block)
    GR    = Color3.fromRGB(70,255,95),   -- neon green  (Grab)
    ESP   = Color3.fromRGB(180,75,255),  -- purple      (ESP)
    -- States
    ON    = Color3.fromRGB(55,235,80),
    OFF   = Color3.fromRGB(20,22,40),
    GREEN = Color3.fromRGB(55,235,80),
    RED   = Color3.fromRGB(245,35,60),
}

local BG_TR  = 0.26
local CD_TR  = 0.20
local C2_TR  = 0.16

local function tw(o,p,t) TweenService:Create(o,TweenInfo.new(t or 0.14,Enum.EasingStyle.Quad),p):Play() end
local function co(p,r) local c=Instance.new("UICorner",p) c.CornerRadius=UDim.new(0,r or 8) end
local function stk(p,col,t,tr) local s=Instance.new("UIStroke",p) s.Color=col s.Thickness=t or 1 s.Transparency=tr or 0.3 return s end

local touchMoved=false local tsp=Vector2.zero
UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then touchMoved=false tsp=Vector2.new(i.Position.X,i.Position.Y) end end)
UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then if(Vector2.new(i.Position.X,i.Position.Y)-tsp).Magnitude>14 then touchMoved=true end end end)
local function sc(btn,fn) btn.MouseButton1Click:Connect(function() if isMobile and touchMoved then return end fn() end) end

local function drag(f)
    local dg,dgs,dsp=false,nil,nil
    f.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dg=true dgs=i.Position dsp=f.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dg=false end end)
        end
    end)
    f.InputChanged:Connect(function(i)
        if dg and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dgs if d.Magnitude>5 then f.Position=UDim2.new(dsp.X.Scale,dsp.X.Offset+d.X,dsp.Y.Scale,dsp.Y.Offset+d.Y) end
        end
    end)
end

-- ================================================================
-- SCREEN GUI
-- ================================================================
pcall(function() if CoreGui:FindFirstChild("PhV2") then CoreGui.PhV2:Destroy() end end)
local sg=Instance.new("ScreenGui") sg.Name="PhV2" sg.ResetOnSpawn=false sg.IgnoreGuiInset=true sg.DisplayOrder=999
local _=pcall(function() sg.Parent=CoreGui end) if not sg.Parent then sg.Parent=lp:WaitForChild("PlayerGui") end

-- ================================================================
-- AUTO BLOCK (VIM method - instant)
-- ================================================================
local blockCD=false
local function vimBlock(target)
    task.spawn(function()
        if not target then return end
        pcall(function() StarterGui:SetCore("PromptBlockPlayer",target) end)
        task.wait(0.35) -- slightly faster
        local vp=Camera.ViewportSize
        for i=1,2 do
            VIM:SendMouseButtonEvent(vp.X/2,vp.Y*0.565,0,true,game,1)  task.wait(0.02)
            VIM:SendMouseButtonEvent(vp.X/2,vp.Y*0.565,0,false,game,1) task.wait(0.04)
        end
    end)
end

local function doBlockOne(target)
    if blockCD then return end blockCD=true
    local tgt=target
    if not tgt then
        local myR=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
        if not myR then blockCD=false return end
        local best,bd=nil,math.huge
        for _,p in pairs(Players:GetPlayers()) do if p~=lp and p.Character then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            if r then local d=(myR.Position-r.Position).Magnitude if d<bd then bd=d best=p end end
        end end tgt=best
    end
    if not tgt then blockCD=false return end
    vimBlock(tgt)
    task.wait(1.5) blockCD=false
end

local function doBlockAll()
    task.spawn(function()
        for _,p in ipairs(Players:GetPlayers()) do if p~=lp then
            vimBlock(p)
            task.wait(0.55) -- faster than before
        end end
    end)
end

-- ================================================================
-- AP CORE
-- ================================================================
local function fireBtn(b)
    pcall(function() for _,c in pairs(getconnections(b.MouseButton1Click)) do c:Fire() end end)
    pcall(function() for _,c in pairs(getconnections(b.Activated)) do c:Fire() end end)
end
local function findAP() return lp:WaitForChild("PlayerGui"):FindFirstChild("AdminPanel") end
local function getKwBtn(ap,kw)
    for _,o in ipairs(ap:GetDescendants()) do
        if o:IsA("TextButton") or o:IsA("ImageButton") then
            local t="" if o:IsA("TextButton") then t=o.Text:lower() else for _,c in ipairs(o:GetDescendants()) do if c:IsA("TextLabel") then t=c.Text:lower() break end end end
            if t:find(kw:lower()) then return o end
        end
    end
end
local function getPlrBtn(ap,target)
    for _,o in ipairs(ap:GetDescendants()) do
        if o:IsA("TextButton") or o:IsA("ImageButton") then
            local t="" if o:IsA("TextButton") then t=o.Text else for _,c in ipairs(o:GetDescendants()) do if c:IsA("TextLabel") then t=c.Text break end end end
            if t==target.Name or t==target.DisplayName then return o end
        end
    end
end
local function fireCmd(target,cmd)
    task.spawn(function()
        local ap=findAP() if not ap then return end
        local pb=getPlrBtn(ap,target) if pb then fireBtn(pb) task.wait(0.07) end
        local cb=getKwBtn(ap,cmd) if cb then fireBtn(cb) task.wait(0.07) end
        local pb2=getPlrBtn(ap,target) if pb2 then fireBtn(pb2) end
    end)
end
local function fireAllCmds(target)
    task.spawn(function()
        local ap=findAP() if not ap then return end
        for _,cmd in ipairs({"rocket","inverse","tiny","jumpscare","morph","balloon"}) do
            local pb=getPlrBtn(ap,target) if pb then fireBtn(pb) task.wait(0.07) end
            local cb=getKwBtn(ap,cmd) if cb then fireBtn(cb) task.wait(0.07) end
            local pb2=getPlrBtn(ap,target) if pb2 then fireBtn(pb2) task.wait(0.05) end
        end
        task.wait(1.5)
        local pb=getPlrBtn(ap,target) if pb then fireBtn(pb) task.wait(0.05) end
        local jb=getKwBtn(ap,"jail") if jb then fireBtn(jb) task.wait(0.05) end
        local pb2=getPlrBtn(ap,target) if pb2 then fireBtn(pb2) end
    end)
end

-- ================================================================
-- ANTI RAGDOLL (always running)
-- ================================================================
RunService.Heartbeat:Connect(function()
    local c=lp.Character if not c then return end
    local hrp=c:FindFirstChild("HumanoidRootPart")
    local h=c:FindFirstChildOfClass("Humanoid") if not h then return end
    local st=h:GetState()
    if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
        h:ChangeState(Enum.HumanoidStateType.Running) Camera.CameraSubject=h
        pcall(function() local pm=lp.PlayerScripts:FindFirstChild("PlayerModule") if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
        if hrp then hrp.AssemblyLinearVelocity=Vector3.zero hrp.AssemblyAngularVelocity=Vector3.zero end
    end
    for _,o in ipairs(c:GetDescendants()) do if o:IsA("Motor6D") and not o.Enabled then o.Enabled=true end end
end)

-- ================================================================
-- TIMER ESP (always running)
-- ================================================================
local timerESPs={}
RunService.RenderStepped:Connect(function()
    local plots=workspace:FindFirstChild("Plots") if not plots then return end
    local function mkTESP(plot,part)
        if timerESPs[plot.Name] then pcall(function() timerESPs[plot.Name].bb:Destroy() end) end
        local bb=Instance.new("BillboardGui") bb.Size=UDim2.fromOffset(74,23) bb.StudsOffset=Vector3.new(0,9,0)
        bb.AlwaysOnTop=true bb.Adornee=part bb.MaxDistance=1500 bb.Parent=plot
        local bg=Instance.new("Frame",bb) bg.Size=UDim2.new(1,0,1,0) bg.BackgroundColor3=Color3.fromRGB(7,7,12)
        bg.BackgroundTransparency=0.15 bg.BorderSizePixel=0 co(bg,5)
        local s=Instance.new("UIStroke",bg) s.Color=Color3.fromRGB(255,195,0) s.Thickness=1.5 s.Transparency=0.2
        local lbl=Instance.new("TextLabel",bg) lbl.Size=UDim2.new(1,0,1,0) lbl.BackgroundTransparency=1
        lbl.Font=Enum.Font.GothamBold lbl.TextSize=11 lbl.TextColor3=Color3.fromRGB(255,195,0)
        lbl.TextStrokeTransparency=0.3 lbl.TextStrokeColor3=Color3.new(0,0,0)
        timerESPs[plot.Name]={bb=bb,lbl=lbl}
    end
    for _,plot in ipairs(plots:GetChildren()) do
        local pur=plot:FindFirstChild("Purchases") local pb2=pur and pur:FindFirstChild("PlotBlock")
        local mp=pb2 and pb2:FindFirstChild("Main")
        local tl=mp and mp:FindFirstChild("BillboardGui") and mp.BillboardGui:FindFirstChild("RemainingTime")
        if tl and mp then
            local e=timerESPs[plot.Name] if not e or not e.bb.Parent then mkTESP(plot,mp) e=timerESPs[plot.Name] end
            if e and e.lbl then e.lbl.Text=tl.Text
                local m,s=tl.Text:match("(%d+):(%d+)")
                if m and s then local tot=tonumber(m)*60+tonumber(s) e.lbl.TextColor3=tot<=30 and C.RED or tot<=60 and Color3.fromRGB(255,195,0) or C.GR end
            end
        else local e=timerESPs[plot.Name] if e then pcall(function() e.bb:Destroy() end) timerESPs[plot.Name]=nil end end
    end
end)

-- ================================================================
-- PLAYER ESP
-- ================================================================
local espOn=false local espConns={}
local function mkESP(plr)
    if plr==lp then return end
    local char=plr.Character if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart") if not hrp or char:FindFirstChild("PhV2_Box") then return end
    local box=Instance.new("BoxHandleAdornment",char) box.Name="PhV2_Box" box.Adornee=hrp
    box.Size=Vector3.new(4,6,2) box.Color3=C.ESP box.Transparency=0.52 box.ZIndex=10 box.AlwaysOnTop=true
    local bb=Instance.new("BillboardGui",char) bb.Name="PhV2_Name" bb.Adornee=char:FindFirstChild("Head") or hrp
    bb.Size=UDim2.fromOffset(155,32) bb.StudsOffset=Vector3.new(0,3.5,0) bb.AlwaysOnTop=true
    local bg=Instance.new("Frame",bb) bg.Size=UDim2.new(1,0,1,0) bg.BackgroundColor3=Color3.fromRGB(8,4,16)
    bg.BackgroundTransparency=0.18 bg.BorderSizePixel=0 co(bg,5) stk(bg,C.ESP,1.3,0.15)
    local nl=Instance.new("TextLabel",bg) nl.Size=UDim2.new(1,0,0.58,0) nl.BackgroundTransparency=1
    nl.Text=plr.DisplayName nl.Font=Enum.Font.GothamBold nl.TextSize=11 nl.TextColor3=C.ESP
    nl.TextStrokeTransparency=0.4 nl.TextStrokeColor3=Color3.new(0,0,0)
    local ul=Instance.new("TextLabel",bg) ul.Size=UDim2.new(1,0,0.42,0) ul.Position=UDim2.new(0,0,0.58,0)
    ul.BackgroundTransparency=1 ul.Text="@"..plr.Name ul.Font=Enum.Font.Gotham ul.TextSize=8 ul.TextColor3=C.DIM
end
local function rmESP(plr) if plr.Character then for _,n in ipairs({"PhV2_Box","PhV2_Name"}) do local o=plr.Character:FindFirstChild(n) if o then o:Destroy() end end end end
local function toggleESP(state)
    espOn=state for _,c in ipairs(espConns) do c:Disconnect() end espConns={}
    if state then
        for _,p in ipairs(Players:GetPlayers()) do if p~=lp then mkESP(p) end end
        table.insert(espConns,Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(0.5) if espOn then mkESP(p) end end) end))
        for _,p in ipairs(Players:GetPlayers()) do if p~=lp then table.insert(espConns,p.CharacterAdded:Connect(function() task.wait(0.5) if espOn then mkESP(p) end end)) end end
    else for _,p in ipairs(Players:GetPlayers()) do rmESP(p) end end
end

-- ================================================================
-- INSTANT STEAL (background, with progress bar + auto block on steal)
-- ================================================================
local isStealing=false
local barFill=nil
local autoBlockOnSteal=false
local allAnimals={} local pCache={} local sCache={}
local GRAB_DIST=4.5

local function isMyPlot(n)
    local pl=workspace:FindFirstChild("Plots") if not pl then return false end
    local p=pl:FindFirstChild(n) if not p then return false end
    local sign=p:FindFirstChild("PlotSign")
    if sign then local yb=sign:FindFirstChild("YourBase") if yb and yb:IsA("BillboardGui") then return yb.Enabled end end
    return false
end
local function scanPlots()
    local plots=workspace:FindFirstChild("Plots") if not plots then return end allAnimals={}
    for _,plot in ipairs(plots:GetChildren()) do
        if not isMyPlot(plot.Name) then
            local pods=plot:FindFirstChild("AnimalPodiums") if not pods then continue end
            for _,pod in ipairs(pods:GetChildren()) do
                local base=pod:FindFirstChild("Base") local spn=base and base:FindFirstChild("Spawn")
                local att=spn and spn:FindFirstChild("PromptAttachment")
                local wp=att and att.WorldPosition or pod:GetPivot().Position
                table.insert(allAnimals,{plotName=plot.Name,slot=pod.Name,worldPos=wp,uid=plot.Name..pod.Name})
            end
        end
    end
end
task.spawn(function() while task.wait(2) do scanPlots() end end)

local function findPrompt(a)
    if pCache[a.uid] and pCache[a.uid].Parent then return pCache[a.uid] end
    local plots=workspace:FindFirstChild("Plots") if not plots then return nil end
    local plot=plots:FindFirstChild(a.plotName) if not plot then return nil end
    local pods=plot:FindFirstChild("AnimalPodiums") if not pods then return nil end
    local pod=pods:FindFirstChild(a.slot) if not pod then return nil end
    local base=pod:FindFirstChild("Base") local spn=base and base:FindFirstChild("Spawn")
    local att=spn and spn:FindFirstChild("PromptAttachment") if not att then return nil end
    for _,p in ipairs(att:GetChildren()) do if p:IsA("ProximityPrompt") then pCache[a.uid]=p return p end end
end
local function buildCB(prompt)
    if sCache[prompt] then return end
    local data={hold={},trigger={},ready=true}
    local ok1,c1=pcall(getconnections,prompt.PromptButtonHoldBegan)
    if ok1 and type(c1)=="table" then for _,c in ipairs(c1) do if type(c.Function)=="function" then table.insert(data.hold,c.Function) end end end
    local ok2,c2=pcall(getconnections,prompt.Triggered)
    if ok2 and type(c2)=="table" then for _,c in ipairs(c2) do if type(c.Function)=="function" then table.insert(data.trigger,c.Function) end end end
    sCache[prompt]=data
end
local function execSteal(prompt)
    local data=sCache[prompt] if not data or not data.ready or isStealing then return end
    data.ready=false isStealing=true
    if barFill then tw(barFill,{Size=UDim2.new(0.9,0,1,0),BackgroundColor3=C.GR},0.04) end
    task.spawn(function()
        for _,fn in ipairs(data.hold) do task.spawn(fn) end
        local t0=tick() local dur=0.08
        while tick()-t0<dur do
            if barFill then barFill.Size=UDim2.new(0.9+((tick()-t0)/dur)*0.1,0,1,0) tw(barFill,{BackgroundColor3=C.GREEN},0.03) end
            task.wait()
        end
        if barFill then barFill.Size=UDim2.new(1,0,1,0) end
        for _,fn in ipairs(data.trigger) do task.spawn(fn) end
        pcall(function() fireproximityprompt(prompt,0) end)
        -- Auto block on steal
        if autoBlockOnSteal then task.spawn(function() doBlockOne(nil) end) end
        task.wait(0.1) data.ready=true isStealing=false
        if barFill then tw(barFill,{Size=UDim2.new(0.9,0,1,0),BackgroundColor3=C.GR},0.1) end
    end)
end

RunService.Heartbeat:Connect(function()
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if isStealing then return end
    local best,bd=nil,math.huge
    for _,a in ipairs(allAnimals) do local d=(hrp.Position-a.worldPos).Magnitude if d<bd then bd=d best=a end end
    if barFill then
        if not best then barFill.Size=UDim2.new(0,0,1,0) tw(barFill,{BackgroundColor3=C.GR},0.1)
        else barFill.Size=UDim2.new(0.9,0,1,0) tw(barFill,{BackgroundColor3=bd<=GRAB_DIST and C.GREEN or C.GR},0.08) end
    end
    if not best or bd>GRAB_DIST then return end
    local prompt=pCache[best.uid]
    if not prompt or not prompt.Parent then prompt=findPrompt(best) end
    if not prompt then return end
    buildCB(prompt) if sCache[prompt] then execSteal(prompt) end
end)

-- ================================================================
-- GRAB BAR (top center)
-- ================================================================
local grabBar=Instance.new("Frame",sg) grabBar.Size=UDim2.fromOffset(170,20)
grabBar.AnchorPoint=Vector2.new(0.5,0) grabBar.Position=UDim2.new(0.5,0,0,6)
grabBar.BackgroundColor3=C.BG grabBar.BackgroundTransparency=BG_TR grabBar.BorderSizePixel=0 co(grabBar,8)
local gbTop=Instance.new("Frame",grabBar) gbTop.Size=UDim2.new(1,0,0,2) gbTop.BackgroundColor3=C.GR gbTop.BorderSizePixel=0 co(gbTop,2)
stk(grabBar,C.GR,1.5,0.2)
local gbBg=Instance.new("Frame",grabBar) gbBg.Size=UDim2.new(0.9,0,0,3) gbBg.Position=UDim2.new(0.05,0,1,-5) gbBg.BackgroundColor3=C.CARD2 gbBg.BackgroundTransparency=0.1 gbBg.BorderSizePixel=0 co(gbBg,3)
local gbFill=Instance.new("Frame",gbBg) gbFill.Size=UDim2.new(0.9,0,1,0) gbFill.BackgroundColor3=C.GR gbFill.BorderSizePixel=0 co(gbFill,3)
barFill=gbFill
local gbTxt=Instance.new("TextLabel",grabBar) gbTxt.Size=UDim2.new(1,0,0.72,0) gbTxt.BackgroundTransparency=1
gbTxt.Text="PHANTOM GRAB" gbTxt.Font=Enum.Font.GothamBold gbTxt.TextSize=8 gbTxt.TextColor3=C.GR gbTxt.ZIndex=2
drag(grabBar)

-- ================================================================
-- GUI HELPERS
-- ================================================================
local function mkPill(parent,def,col)
    col=col or C.ON
    local pw,ph=28,15
    local pill=Instance.new("Frame",parent) pill.Size=UDim2.fromOffset(pw,ph)
    pill.BackgroundColor3=def and col or C.OFF pill.BorderSizePixel=0 co(pill,ph)
    local cir=Instance.new("Frame",pill) cir.Size=UDim2.fromOffset(ph-4,ph-4)
    cir.Position=def and UDim2.new(1,-(ph-2),0.5,-(ph-4)/2) or UDim2.new(0,2,0.5,-(ph-4)/2)
    cir.BackgroundColor3=Color3.new(1,1,1) cir.BorderSizePixel=0 co(cir,ph)
    local function set(state,sRef)
        tw(pill,{BackgroundColor3=state and col or C.OFF},0.12)
        tw(cir,{Position=state and UDim2.new(1,-(ph-2),0.5,-(ph-4)/2) or UDim2.new(0,2,0.5,-(ph-4)/2)},0.12,Enum.EasingStyle.Back)
        if sRef then tw(sRef,{Color=state and col or C.BORD,Transparency=state and 0.05 or 0.4},0.12) end
    end
    return pill,set
end

local function mkPanel(name,w,pos,accent)
    accent=accent or C.AP
    local f=Instance.new("Frame",sg) f.Name=name f.Size=UDim2.fromOffset(w,0)
    f.Position=pos f.BackgroundColor3=C.BG f.BackgroundTransparency=BG_TR
    f.BorderSizePixel=0 f.Active=true f.AutomaticSize=Enum.AutomaticSize.Y co(f,11)
    stk(f,accent,1.8,0.38)
    local g=Instance.new("UIGradient",f) g.Rotation=115
    g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(14,16,36)),ColorSequenceKeypoint.new(1,Color3.fromRGB(4,5,14))})
    drag(f)
    local uly=Instance.new("UIListLayout",f) uly.SortOrder=Enum.SortOrder.LayoutOrder uly.Padding=UDim.new(0,0)
    -- header
    local hdr=Instance.new("Frame",f) hdr.Size=UDim2.new(1,0,0,28)
    hdr.BackgroundColor3=accent hdr.BackgroundTransparency=0.74 hdr.BorderSizePixel=0 hdr.LayoutOrder=1 co(hdr,11)
    local hfix=Instance.new("Frame",hdr) hfix.Size=UDim2.new(1,0,0.5,0) hfix.Position=UDim2.new(0,0,0.5,0) hfix.BackgroundColor3=accent hfix.BackgroundTransparency=0.74 hfix.BorderSizePixel=0
    local hline=Instance.new("Frame",hdr) hline.Size=UDim2.new(1,0,0,2) hline.BackgroundColor3=accent hline.BorderSizePixel=0 co(hline,2)
    local tlbl=Instance.new("TextLabel",hdr) tlbl.Size=UDim2.new(1,-32,1,0) tlbl.Position=UDim2.fromOffset(10,0)
    tlbl.BackgroundTransparency=1 tlbl.Text=name tlbl.Font=Enum.Font.GothamBlack tlbl.TextSize=10 tlbl.TextColor3=C.WHITE tlbl.TextXAlignment=Enum.TextXAlignment.Left
    local xBtn=Instance.new("TextButton",hdr) xBtn.Size=UDim2.fromOffset(20,20) xBtn.Position=UDim2.new(1,-24,0.5,-10)
    xBtn.BackgroundColor3=Color3.fromRGB(48,8,8) xBtn.BackgroundTransparency=0.1 xBtn.BorderSizePixel=0
    xBtn.Text="×" xBtn.Font=Enum.Font.GothamBold xBtn.TextSize=14 xBtn.TextColor3=C.RED xBtn.AutoButtonColor=false co(xBtn,5)
    local cnt=Instance.new("Frame",f) cnt.Size=UDim2.new(1,0,0,0) cnt.AutomaticSize=Enum.AutomaticSize.Y cnt.BackgroundTransparency=1 cnt.BorderSizePixel=0 cnt.LayoutOrder=2
    local pad=Instance.new("UIPadding",cnt) pad.PaddingTop=UDim.new(0,5) pad.PaddingBottom=UDim.new(0,6) pad.PaddingLeft=UDim.new(0,5) pad.PaddingRight=UDim.new(0,5)
    local cly=Instance.new("UIListLayout",cnt) cly.Padding=UDim.new(0,4) cly.SortOrder=Enum.SortOrder.LayoutOrder cly.HorizontalAlignment=Enum.HorizontalAlignment.Center
    -- watermark
    local wm=Instance.new("TextLabel",cnt) wm.Size=UDim2.new(1,0,0,7) wm.BackgroundTransparency=1 wm.LayoutOrder=999
    wm.Text="Made by Phantom / r9qbx" wm.Font=Enum.Font.Gotham wm.TextSize=6 wm.TextColor3=accent wm.TextTransparency=0.5
    return f,cnt,xBtn
end

local function mkBtn(parent,txt,col,order)
    col=col or C.AP
    local r2,g2,b2=col.R*255,col.G*255,col.B*255
    local btn=Instance.new("TextButton",parent) btn.Size=UDim2.new(1,0,0,25)
    btn.BackgroundColor3=Color3.fromRGB(math.floor(r2*0.1),math.floor(g2*0.1),math.floor(b2*0.1))
    btn.BackgroundTransparency=0.08 btn.BorderSizePixel=0 btn.Text=txt btn.Font=Enum.Font.GothamBold btn.TextSize=10 btn.TextColor3=col btn.AutoButtonColor=false btn.LayoutOrder=order or 99
    co(btn,7) stk(btn,col,1.2,0.25)
    btn.MouseEnter:Connect(function() tw(btn,{BackgroundTransparency=0},0.08) end)
    btn.MouseLeave:Connect(function() tw(btn,{BackgroundTransparency=0.08},0.08) end)
    return btn
end

local function mkDiv(parent,col,order)
    local d=Instance.new("Frame",parent) d.Size=UDim2.new(1,0,0,1) d.BackgroundColor3=col or C.BORD d.BackgroundTransparency=0.4 d.BorderSizePixel=0 d.LayoutOrder=order
end

local function mkReo(txt,pos,col,fn)
    local b=Instance.new("TextButton",sg) b.Size=UDim2.fromOffset(38,22) b.Position=pos
    b.BackgroundColor3=C.CARD b.BackgroundTransparency=0.15 b.BorderSizePixel=0 b.Text=txt b.Font=Enum.Font.GothamBlack b.TextSize=8 b.TextColor3=col b.Visible=false b.ZIndex=20
    co(b,11) stk(b,col,1.5,0.2) sc(b,function() b.Visible=false fn() end) return b
end

-- ================================================================
-- MINI AP PANEL
-- ================================================================
local APFr,APCnt,APX=mkPanel("MINI AP",260,UDim2.fromOffset(44,34),C.AP)
APFr.Visible=false
local APReo=mkReo("AP",UDim2.fromOffset(44,34),C.AP,function() APFr.Visible=true end)
sc(APX,function() APFr.Visible=false APReo.Visible=true end)

local apScrollFr=Instance.new("Frame",APCnt) apScrollFr.Size=UDim2.new(1,0,0,170) apScrollFr.BackgroundTransparency=1 apScrollFr.ClipsDescendants=true apScrollFr.LayoutOrder=1
local apScr=Instance.new("ScrollingFrame",apScrollFr) apScr.Size=UDim2.new(1,0,1,0) apScr.BackgroundTransparency=1 apScr.BorderSizePixel=0 apScr.ScrollBarThickness=3 apScr.ScrollBarImageColor3=C.AP apScr.CanvasSize=UDim2.new(0,0,0,0) apScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
local apLy=Instance.new("UIListLayout",apScr) apLy.Padding=UDim.new(0,4) apLy.SortOrder=Enum.SortOrder.LayoutOrder

-- AP command definitions
local AP_CMDS={
    {lbl="🎈",k="balloon",cd=29,col=Color3.fromRGB(55,120,255)},
    {lbl="🤸",k="ragdoll",cd=29,col=Color3.fromRGB(220,40,40)},
    {lbl="⛓",k="jail",   cd=59,col=Color3.fromRGB(25,165,55)},
    {lbl="🚀",k="rocket", cd=119,col=Color3.fromRGB(220,120,20)},
    {lbl="🐜",k="tiny",   cd=59,col=Color3.fromRGB(125,30,220)},
    {lbl="💥",k="ALL",    cd=5, col=C.AP},
}

local function buildAPRow(p)
    local row=Instance.new("Frame",apScr) row.Size=UDim2.new(1,-2,0,38) row.BackgroundColor3=C.CARD2
    row.BackgroundTransparency=C2_TR row.BorderSizePixel=0 row.LayoutOrder=p.UserId co(row,8)
    stk(row,C.BORD,1,0.55)
    -- avatar
    local av=Instance.new("ImageLabel",row) av.Size=UDim2.fromOffset(28,28) av.Position=UDim2.new(0,4,0.5,-14)
    av.BackgroundColor3=C.CARD av.BorderSizePixel=0 co(av,14)
    av.Image="https://www.roblox.com/headshot-thumbnail/image?userId="..p.UserId.."&width=60&height=60&format=png"
    -- display name + username
    local nl=Instance.new("TextLabel",row) nl.Size=UDim2.new(0,54,0,14) nl.Position=UDim2.fromOffset(35,4)
    nl.BackgroundTransparency=1 nl.Text=p.DisplayName nl.Font=Enum.Font.GothamBold nl.TextSize=8 nl.TextColor3=C.TEXT nl.TextXAlignment=Enum.TextXAlignment.Left nl.TextTruncate=Enum.TextTruncate.AtEnd
    local ul=Instance.new("TextLabel",row) ul.Size=UDim2.new(0,54,0,10) ul.Position=UDim2.fromOffset(35,18)
    ul.BackgroundTransparency=1 ul.Text="@"..p.Name ul.Font=Enum.Font.Gotham ul.TextSize=6 ul.TextColor3=C.DIM ul.TextXAlignment=Enum.TextXAlignment.Left ul.TextTruncate=Enum.TextTruncate.AtEnd
    -- command buttons
    local xOff=92
    for _,cmd in ipairs(AP_CMDS) do
        local btn=Instance.new("TextButton",row) btn.Size=UDim2.fromOffset(26,26) btn.Position=UDim2.new(0,xOff,0.5,-13)
        btn.BackgroundColor3=cmd.col btn.BackgroundTransparency=0.12 btn.BorderSizePixel=0
        btn.Text=cmd.lbl btn.Font=Enum.Font.GothamBold btn.TextSize=cmd.k=="ALL" and 8 or 12 btn.AutoButtonColor=false
        co(btn,5)
        local cdLbl=Instance.new("TextLabel",btn) cdLbl.Size=UDim2.new(1,0,1,0) cdLbl.BackgroundTransparency=1
        cdLbl.Text="" cdLbl.Font=Enum.Font.GothamBold cdLbl.TextSize=7 cdLbl.TextColor3=Color3.new(1,1,1) cdLbl.ZIndex=2
        local onCD=false local captCmd=cmd local captP=p
        sc(btn,function()
            if onCD then return end onCD=true
            btn.BackgroundColor3=Color3.fromRGB(40,10,10) btn.Text=""
            if captCmd.k=="ALL" then fireAllCmds(captP) else fireCmd(captP,captCmd.k) end
            local cdEnd=tick()+captCmd.cd
            task.spawn(function()
                while tick()<cdEnd do if cdLbl.Parent then cdLbl.Text=tostring(math.ceil(cdEnd-tick())) end task.wait(0.5) end
                if btn.Parent then btn.Text=captCmd.lbl cdLbl.Text="" btn.BackgroundColor3=captCmd.col end
                onCD=false
            end)
        end)
        xOff=xOff+29
    end
    return row
end

local apRows={}
local function buildAllAPRows()
    for _,c in ipairs(apScr:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    apRows={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp then
            local row=buildAPRow(p) apRows[p.UserId]=row
        end
    end
end

-- ================================================================
-- BLOCK PANEL
-- ================================================================
local BKFr,BKCnt,BKX=mkPanel("BLOCK",200,UDim2.fromOffset(312,34),C.BL)
BKFr.Visible=false
local BKReo=mkReo("BL",UDim2.fromOffset(312,34),C.BL,function() BKFr.Visible=true end)
sc(BKX,function() BKFr.Visible=false BKReo.Visible=true end)

-- Auto Block on Steal row
local absRow=Instance.new("Frame",BKCnt) absRow.Size=UDim2.new(1,0,0,26) absRow.BackgroundColor3=C.CARD2 absRow.BackgroundTransparency=C2_TR absRow.BorderSizePixel=0 absRow.LayoutOrder=1 co(absRow,7) stk(absRow,C.BORD,1,0.55)
local absLbl=Instance.new("TextLabel",absRow) absLbl.Size=UDim2.new(0.62,0,1,0) absLbl.Position=UDim2.fromOffset(7,0) absLbl.BackgroundTransparency=1 absLbl.Text="Auto Block on Steal" absLbl.Font=Enum.Font.GothamBold absLbl.TextSize=9 absLbl.TextColor3=C.TEXT absLbl.TextXAlignment=Enum.TextXAlignment.Left
local absPill,absPillSet=mkPill(absRow,false,C.BL) absPill.Position=UDim2.new(1,-32,0.5,-7)
local absRS=absRow:FindFirstChildOfClass("UIStroke")
local absBtn=Instance.new("TextButton",absRow) absBtn.Size=UDim2.new(1,0,1,0) absBtn.BackgroundTransparency=1 absBtn.Text=""
sc(absBtn,function()
    autoBlockOnSteal=not autoBlockOnSteal absPillSet(autoBlockOnSteal,absRS)
end)

-- Block All button
local baBtn=mkBtn(BKCnt,"🚫  BLOCK ALL",C.BL,2)
sc(baBtn,function()
    baBtn.Text="blocking..." baBtn.TextColor3=C.DIM doBlockAll()
    task.delay(5,function() if baBtn.Parent then baBtn.Text="🚫  BLOCK ALL" baBtn.TextColor3=C.BL end end)
end)

mkDiv(BKCnt,C.BL,3)

-- Player list scroll
local bkScrollFr=Instance.new("Frame",BKCnt) bkScrollFr.Size=UDim2.new(1,0,0,130) bkScrollFr.BackgroundTransparency=1 bkScrollFr.ClipsDescendants=true bkScrollFr.LayoutOrder=4
local bkScr=Instance.new("ScrollingFrame",bkScrollFr) bkScr.Size=UDim2.new(1,0,1,0) bkScr.BackgroundTransparency=1 bkScr.BorderSizePixel=0 bkScr.ScrollBarThickness=3 bkScr.ScrollBarImageColor3=C.BL bkScr.CanvasSize=UDim2.new(0,0,0,0) bkScr.AutomaticCanvasSize=Enum.AutomaticSize.Y
local bkLy=Instance.new("UIListLayout",bkScr) bkLy.Padding=UDim.new(0,4) bkLy.SortOrder=Enum.SortOrder.LayoutOrder

local function buildBlockRow(p)
    local row=Instance.new("Frame",bkScr) row.Size=UDim2.new(1,-2,0,32) row.BackgroundColor3=C.CARD2
    row.BackgroundTransparency=C2_TR row.BorderSizePixel=0 row.LayoutOrder=p.UserId co(row,7)
    stk(row,C.BORD,1,0.55)
    -- avatar
    local av=Instance.new("ImageLabel",row) av.Size=UDim2.fromOffset(22,22) av.Position=UDim2.new(0,4,0.5,-11)
    av.BackgroundColor3=C.CARD av.BorderSizePixel=0 co(av,11)
    av.Image="https://www.roblox.com/headshot-thumbnail/image?userId="..p.UserId.."&width=48&height=48&format=png"
    -- name
    local nl=Instance.new("TextLabel",row) nl.Size=UDim2.new(1,-80,0,13) nl.Position=UDim2.fromOffset(30,4)
    nl.BackgroundTransparency=1 nl.Text=p.DisplayName nl.Font=Enum.Font.GothamBold nl.TextSize=8 nl.TextColor3=C.TEXT nl.TextXAlignment=Enum.TextXAlignment.Left nl.TextTruncate=Enum.TextTruncate.AtEnd
    local ul=Instance.new("TextLabel",row) ul.Size=UDim2.new(1,-80,0,10) ul.Position=UDim2.fromOffset(30,17)
    ul.BackgroundTransparency=1 ul.Text="@"..p.Name ul.Font=Enum.Font.Gotham ul.TextSize=6 ul.TextColor3=C.DIM ul.TextXAlignment=Enum.TextXAlignment.Left ul.TextTruncate=Enum.TextTruncate.AtEnd
    -- BLOCK button (VIM auto block)
    local bBtn=Instance.new("TextButton",row) bBtn.Size=UDim2.fromOffset(44,20) bBtn.Position=UDim2.new(1,-48,0.5,-10)
    bBtn.BackgroundColor3=Color3.fromRGB(42,5,8) bBtn.BackgroundTransparency=0.06 bBtn.BorderSizePixel=0 bBtn.Text="BLOCK" bBtn.Font=Enum.Font.GothamBold bBtn.TextSize=8 bBtn.TextColor3=C.BL bBtn.AutoButtonColor=false
    co(bBtn,6) stk(bBtn,C.BL,1,0.28)
    bBtn.MouseEnter:Connect(function() tw(bBtn,{BackgroundTransparency=0},0.08) end)
    bBtn.MouseLeave:Connect(function() tw(bBtn,{BackgroundTransparency=0.06},0.08) end)
    local cap=p
    sc(bBtn,function()
        bBtn.Text="..." bBtn.TextColor3=C.DIM
        vimBlock(cap)
        task.delay(2,function() if bBtn.Parent then bBtn.Text="BLOCK" bBtn.TextColor3=C.BL end end)
    end)
    return row
end

local bkRows={}
local function buildAllBlockRows()
    for _,c in ipairs(bkScr:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
    bkRows={}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=lp then bkRows[p.UserId]=buildBlockRow(p) end
    end
end

-- ================================================================
-- ESP TOGGLE PANEL (small, right side)
-- ================================================================
local ESPFr,ESPCnt,ESPX=mkPanel("TOOLS",148,UDim2.new(1,-156,0,34),C.ESP)
local ESPReo=mkReo("ESP",UDim2.new(1,-48,0,34),C.ESP,function() ESPFr.Visible=true end)
sc(ESPX,function() ESPFr.Visible=false ESPReo.Visible=true end)

-- Player ESP row
local espRowFr=Instance.new("Frame",ESPCnt) espRowFr.Size=UDim2.new(1,0,0,26) espRowFr.BackgroundColor3=C.CARD2 espRowFr.BackgroundTransparency=C2_TR espRowFr.BorderSizePixel=0 espRowFr.LayoutOrder=1 co(espRowFr,7)
local espRS=stk(espRowFr,C.BORD,1,0.55)
local espLbl=Instance.new("TextLabel",espRowFr) espLbl.Size=UDim2.new(0.65,0,1,0) espLbl.Position=UDim2.fromOffset(7,0) espLbl.BackgroundTransparency=1 espLbl.Text="Player ESP" espLbl.Font=Enum.Font.GothamBold espLbl.TextSize=9 espLbl.TextColor3=C.TEXT espLbl.TextXAlignment=Enum.TextXAlignment.Left
local espPill,espPillSet=mkPill(espRowFr,false,C.ESP) espPill.Position=UDim2.new(1,-32,0.5,-7)
local espRowBtn=Instance.new("TextButton",espRowFr) espRowBtn.Size=UDim2.new(1,0,1,0) espRowBtn.BackgroundTransparency=1 espRowBtn.Text=""
sc(espRowBtn,function() espOn=not espOn espPillSet(espOn,espRS) toggleESP(espOn) end)

mkDiv(ESPCnt,C.ESP,2)

-- Auto block on steal (also in tools)
local absRow2=Instance.new("Frame",ESPCnt) absRow2.Size=UDim2.new(1,0,0,26) absRow2.BackgroundColor3=C.CARD2 absRow2.BackgroundTransparency=C2_TR absRow2.BorderSizePixel=0 absRow2.LayoutOrder=3 co(absRow2,7)
local absRS2=stk(absRow2,C.BORD,1,0.55)
local absLbl2=Instance.new("TextLabel",absRow2) absLbl2.Size=UDim2.new(0.65,0,1,0) absLbl2.Position=UDim2.fromOffset(7,0) absLbl2.BackgroundTransparency=1 absLbl2.Text="Block on Steal" absLbl2.Font=Enum.Font.GothamBold absLbl2.TextSize=9 absLbl2.TextColor3=C.TEXT absLbl2.TextXAlignment=Enum.TextXAlignment.Left
local absPill2,absPillSet2=mkPill(absRow2,false,C.BL) absPill2.Position=UDim2.new(1,-32,0.5,-7)
local absBtn2=Instance.new("TextButton",absRow2) absBtn2.Size=UDim2.new(1,0,1,0) absBtn2.BackgroundTransparency=1 absBtn2.Text=""
sc(absBtn2,function()
    autoBlockOnSteal=not autoBlockOnSteal
    absPillSet(autoBlockOnSteal,absRS) -- sync both toggles
    absPillSet2(autoBlockOnSteal,absRS2)
end)

-- ================================================================
-- BOTTOM PILL BUTTONS
-- ================================================================
local btnBar=Instance.new("Frame",sg) btnBar.Size=UDim2.fromOffset(0,36)
btnBar.Position=UDim2.new(0,6,1,-48) btnBar.BackgroundTransparency=1 btnBar.AutomaticSize=Enum.AutomaticSize.X btnBar.BorderSizePixel=0
local btnLy=Instance.new("UIListLayout",btnBar) btnLy.FillDirection=Enum.FillDirection.Horizontal btnLy.Padding=UDim.new(0,5) btnLy.VerticalAlignment=Enum.VerticalAlignment.Center

local function pillBtn(label,col,cb2)
    local f=Instance.new("Frame",btnBar) f.Size=UDim2.fromOffset(46,34)
    f.BackgroundColor3=C.CARD f.BackgroundTransparency=0.2 f.BorderSizePixel=0 co(f,12)
    local fs=stk(f,col,1.8,0.25)
    local dot=Instance.new("Frame",f) dot.Size=UDim2.fromOffset(4,4) dot.Position=UDim2.new(0.5,-2,0,3) dot.BackgroundColor3=col dot.BorderSizePixel=0 co(dot,4)
    TweenService:Create(dot,TweenInfo.new(0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{BackgroundTransparency=0.8}):Play()
    local b=Instance.new("TextButton",f) b.Size=UDim2.new(1,0,1,0) b.BackgroundTransparency=1 b.Text=label b.Font=Enum.Font.GothamBlack b.TextSize=10 b.TextColor3=col b.BorderSizePixel=0 b.AutoButtonColor=false
    b.MouseEnter:Connect(function() tw(f,{BackgroundTransparency=0},0.08) tw(fs,{Transparency=0},0.08) end)
    b.MouseLeave:Connect(function() tw(f,{BackgroundTransparency=0.2},0.08) tw(fs,{Transparency=0.25},0.08) end)
    sc(b,cb2)
end

pillBtn("AP",C.AP,function()
    local v=not APFr.Visible APFr.Visible=v APReo.Visible=not v
    if v then buildAllAPRows() end
end)
pillBtn("BL",C.BL,function()
    local v=not BKFr.Visible BKFr.Visible=v BKReo.Visible=not v
    if v then buildAllBlockRows() end
end)
pillBtn("ESP",C.ESP,function()
    ESPFr.Visible=not ESPFr.Visible ESPReo.Visible=not ESPFr.Visible
end)

-- ================================================================
-- MOBILE SHORTCUTS (right side)
-- ================================================================
if isMobile then
    local function mob(txt,yOff,col,cb2)
        local f=Instance.new("Frame",sg) f.Size=UDim2.fromOffset(44,44) f.Position=UDim2.new(1,-50,0.5,yOff)
        f.BackgroundColor3=C.CARD f.BackgroundTransparency=0.2 f.BorderSizePixel=0 co(f,14) stk(f,col,1.8,0.2)
        local b=Instance.new("TextButton",f) b.Size=UDim2.new(1,0,1,0) b.BackgroundTransparency=1 b.Text=txt b.Font=Enum.Font.GothamBold b.TextSize=8 b.TextColor3=col b.BorderSizePixel=0
        sc(b,cb2)
    end
    mob("AP",-52,C.AP,function() local v=not APFr.Visible APFr.Visible=v APReo.Visible=not v if v then buildAllAPRows() end end)
    mob("BL",2,C.BL,function() local v=not BKFr.Visible BKFr.Visible=v BKReo.Visible=not v if v then buildAllBlockRows() end end)
end

-- ================================================================
-- DYNAMIC PLAYER UPDATES
-- ================================================================
local function onPlayerAdded(p)
    if p==lp then return end
    -- Hook character for ESP
    p.CharacterAdded:Connect(function() task.wait(0.5) if espOn then mkESP(p) end end)
    if p.Character and espOn then task.spawn(function() mkESP(p) end) end
    -- Add rows if panels open
    task.wait(0.3)
    if APFr.Visible and not apRows[p.UserId] then apRows[p.UserId]=buildAPRow(p) end
    if BKFr.Visible and not bkRows[p.UserId] then bkRows[p.UserId]=buildBlockRow(p) end
end

local function onPlayerRemoving(p)
    if espOn then rmESP(p) end
    if apRows[p.UserId] then pcall(function() apRows[p.UserId]:Destroy() end) apRows[p.UserId]=nil end
    if bkRows[p.UserId] then pcall(function() bkRows[p.UserId]:Destroy() end) bkRows[p.UserId]=nil end
end

for _,p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Safety refresh
task.spawn(function()
    while sg.Parent do task.wait(10)
        if APFr.Visible then buildAllAPRows() end
        if BKFr.Visible then buildAllBlockRows() end
        if espOn then for _,p in ipairs(Players:GetPlayers()) do if p~=lp and p.Character and not p.Character:FindFirstChild("PhV2_Box") then mkESP(p) end end end
    end
end)

-- Grab bar text update
local grabBarTxt=gbTxt
RunService.Heartbeat:Connect(function()
    local hrp=lp.Character and lp.Character:FindFirstChild("HumanoidRootPart") if not hrp then return end
    if isStealing then grabBarTxt.Text="GRABBING!" grabBarTxt.TextColor3=C.GREEN return end
    local best,bd=nil,math.huge
    for _,a in ipairs(allAnimals) do local d=(hrp.Position-a.worldPos).Magnitude if d<bd then bd=d best=a end end
    if not best then grabBarTxt.Text="NO TARGETS" grabBarTxt.TextColor3=C.DIM
    elseif bd<=GRAB_DIST then grabBarTxt.Text="IN RANGE!" grabBarTxt.TextColor3=C.GREEN
    else grabBarTxt.Text=string.format("%.1fm",bd) grabBarTxt.TextColor3=C.GR end
end)

end)
if not ok then warn("[PhV2] "..tostring(err)) end
end)
