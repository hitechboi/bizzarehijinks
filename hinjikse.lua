local user = game.Players.LocalPlayer.Name
local noevasive, nocombowait, noragdoll, nostun = false, false, false, false
local infSpecial, stateBypass, abilSpeedOn, chantLock = false, false, false, false
local damageMultiplierValue = 1
local mouse = game.Players.LocalPlayer:GetMouse()

local uiX, uiY   = 300, 200
local uiW, uiH   = 420, 360
local dragging    = false
local dragOffX, dragOffY = 0, 0
local wasClicking = false
local currentTab  = "Combat"
local menuKey     = 0x70
local listenKey   = false
local isDead      = false
local destroyed   = false
local menuOpen    = true

local C_BG      = Color3.fromRGB(10,12,22)
local C_SIDEBAR = Color3.fromRGB(14,17,30)
local C_CONTENT = Color3.fromRGB(12,15,26)
local C_TOPBAR  = Color3.fromRGB(8,10,18)
local C_ACCENT2 = Color3.fromRGB(80,130,255)
local C_TABSEL  = Color3.fromRGB(25,40,90)
local C_WHITE   = Color3.fromRGB(210,215,235)
local C_GRAY    = Color3.fromRGB(110,120,150)
local C_DIMGRAY = Color3.fromRGB(30,35,55)
local C_ON      = Color3.fromRGB(50,90,200)
local C_OFF     = Color3.fromRGB(22,26,45)
local C_ONDOT   = Color3.fromRGB(180,200,255)
local C_OFFDOT  = Color3.fromRGB(60,70,100)
local C_GREEN   = Color3.fromRGB(50,200,100)
local C_RED     = Color3.fromRGB(220,60,60)
local C_BORDER  = Color3.fromRGB(35,45,80)
local C_ROWBG   = Color3.fromRGB(16,20,36)
local C_DIV     = Color3.fromRGB(25,30,52)

local SIDEBAR_W = 130
local TOPBAR_H  = 38
local ROW_H     = 42
local ROW_PAD   = 10
local TOG_W     = 36
local TOG_H     = 18
local CONTENT_W = uiW - SIDEBAR_W

local States, AbilitySpeed, Special, Combo, DamageMultiplier, Chant
local Character, Humanoid

local function grabRefs()
    pcall(function()
        States           = game.Workspace.Live[user].Combat.States
        AbilitySpeed     = States.AbilitySpeed
        Special          = States.Special
        Combo            = States.Combo
        DamageMultiplier = States.DamageMultiplier
        Chant            = States:FindFirstChild("Chant")
        Character        = game.Players[user].Configuration.Character
        Humanoid         = game.Workspace.Live[user]:FindFirstChild("Humanoid")
    end)
end
grabRefs()
spawn(function()
    while not destroyed do
        wait(3)
        grabRefs()
        if Humanoid and Humanoid.Health > 0 then isDead = false end
    end
end)

-- ============================================================
-- DRAWING
-- allDrawings = every object, showSet = should be visible
-- ============================================================
local allDrawings = {}
local showSet     = {}

local function mkD(d)
    table.insert(allDrawings, d)
    d.Visible = false
    return d
end

local function setShow(d, yes)
    showSet[d] = yes or nil
    d.Visible  = yes and menuOpen or false
end

local function setAllVisible(vis)
    for _, d in ipairs(allDrawings) do
        d.Visible = vis and showSet[d] and true or false
    end
end

local function mkSq(x,y,w,h,col,filled,transp,zi,thick,corner)
    local s = Drawing.new("Square")
    s.Position = Vector2.new(x,y); s.Size = Vector2.new(w,h)
    s.Color = col; s.Filled = filled; s.Transparency = transp or 1
    s.ZIndex = zi or 1; s.Visible = true
    if not filled then s.Thickness = thick or 1 end
    if corner and corner > 0 then pcall(function() s.Corner = corner end) end
    return s
end

local function mkTx(txt,x,y,sz,col,ctr,zi,bold)
    local t = Drawing.new("Text")
    t.Text=txt; t.Position=Vector2.new(x,y); t.Size=sz or 13
    t.Color=col or C_WHITE; t.Center=ctr or false; t.Outline=false
    t.Font=bold and Drawing.Fonts.SystemBold or Drawing.Fonts.System
    t.Transparency=1; t.ZIndex=zi or 3; t.Visible=true
    return t
end

local function mkLn(x1,y1,x2,y2,col,zi,thick)
    local l = Drawing.new("Line")
    l.From=Vector2.new(x1,y1); l.To=Vector2.new(x2,y2)
    l.Color=col or C_ACCENT2; l.Transparency=1
    l.Thickness=thick or 1; l.ZIndex=zi or 2; l.Visible=true
    return l
end

local function inBox(x,y,w,h)
    return mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+h
end

local function lerpC(a,b,t)
    return Color3.fromRGB(
        math.floor(a.R*255+(b.R*255-a.R*255)*t),
        math.floor(a.G*255+(b.G*255-a.G*255)*t),
        math.floor(a.B*255+(b.B*255-a.B*255)*t))
end

-- ============================================================
-- BASE UI
-- mainBg handles all rounded corners (Corner=10)
-- inner panels are flat squares inset 1px so corners show
-- ============================================================
local dShadow  = mkD(mkSq(uiX+6,uiY+6,uiW,uiH,         Color3.fromRGB(0,0,6),true,0.5,0,nil,10))
local dMainBg  = mkD(mkSq(uiX,uiY,uiW,uiH,              C_BG,   true,1,1,nil,10))
local dBorder  = mkD(mkSq(uiX,uiY,uiW,uiH,              C_BORDER,false,1,2,1,10))
local dTopBar  = mkD(mkSq(uiX+1,uiY+1,uiW-2,TOPBAR_H,   C_TOPBAR,true,1,3,nil,9))
local dTopFill = mkD(mkSq(uiX+1,uiY+TOPBAR_H-4,uiW-2,6, C_TOPBAR,true,1,3))
local dTopLine = mkD(mkLn(uiX+1,uiY+TOPBAR_H,uiX+uiW-1,uiY+TOPBAR_H, C_BORDER,4,1))
local dTitleW  = mkD(mkTx("Check it",  uiX+14,    uiY+11,14,C_WHITE,  false,9,true))
local dTitleA  = mkD(mkTx("Interface", uiX+76,    uiY+11,14,C_ACCENT2,false,9,true))
local dKeyLbl  = mkD(mkTx("F1",        uiX+uiW-20,uiY+13,11,C_GRAY,   false,9))
local dDotY    = mkD(mkSq(uiX+uiW-54,uiY+14,9,9, Color3.fromRGB(200,160,0),true,1,9,nil,3))
local dDotR    = mkD(mkSq(uiX+uiW-40,uiY+14,9,9, Color3.fromRGB(180,50,50),true,1,9,nil,3))
local dSide    = mkD(mkSq(uiX+1,uiY+TOPBAR_H,SIDEBAR_W-1,uiH-TOPBAR_H-1, C_SIDEBAR,true,1,2))
local dSideLn  = mkD(mkLn(uiX+SIDEBAR_W,uiY+TOPBAR_H,uiX+SIDEBAR_W,uiY+uiH-1, C_BORDER,4,1))
local dContent = mkD(mkSq(uiX+SIDEBAR_W,uiY+TOPBAR_H,CONTENT_W-1,uiH-TOPBAR_H-1, C_CONTENT,true,1,2))
local dBotDiv  = mkD(mkLn(uiX+1,uiY+uiH-20,uiX+uiW-1,uiY+uiH-20, C_DIMGRAY,4,1))
local dCharLbl = mkD(mkTx("Character: ...",uiX+SIDEBAR_W+8,uiY+uiH-14,10,C_GRAY,false,9))

local baseUI = {dShadow,dMainBg,dBorder,dTopBar,dTopFill,dTopLine,
                dTitleW,dTitleA,dKeyLbl,dDotY,dDotR,
                dSide,dSideLn,dContent,dBotDiv,dCharLbl}
for _,d in ipairs(baseUI) do setShow(d,true) end

-- ============================================================
-- TABS
-- ============================================================
local tabNames = {"Combat","Boosts","Settings"}
local tabObjs  = {}

for i,name in ipairs(tabNames) do
    local relTY = TOPBAR_H+10+(i-1)*38
    local isSel = name==currentTab
    local tbg  = mkD(mkSq(uiX+8,uiY+relTY,SIDEBAR_W-16,28, isSel and C_TABSEL or C_SIDEBAR,true,1,3,nil,6))
    local tacc = mkD(mkSq(uiX+8,uiY+relTY,3,28, isSel and C_ACCENT2 or C_SIDEBAR,true,1,4,nil,2))
    local tlbl = mkD(mkTx(name,uiX+20,uiY+relTY+8,12, isSel and C_WHITE or C_GRAY,false,8))
    setShow(tbg,true); setShow(tacc,true); setShow(tlbl,true)
    tabObjs[i] = {bg=tbg,acc=tacc,lbl=tlbl,name=name,sel=isSel,lt=isSel and 1 or 0,relTY=relTY}
end

-- ============================================================
-- BUTTONS
-- ============================================================
local btns = {}

local function bShow(b, yes)
    setShow(b.bg,  yes)
    setShow(b.lbl, yes)
    if b.ln  then setShow(b.ln,  yes) end
    if b.tog then setShow(b.tog, yes) end
    if b.dot then setShow(b.dot, yes) end
end

local function bPos(b)
    local ax,ay = uiX+b.rx, uiY+b.ry
    b.bg.Position = Vector2.new(ax,ay)
    if b.isDiv then
        b.lbl.Position = Vector2.new(ax+4,ay)
        b.ln.From=Vector2.new(ax,ay+13); b.ln.To=Vector2.new(ax+b.cw,ay+13)
    elseif b.isAct then
        b.lbl.Position = Vector2.new(ax+b.cw/2,ay+b.ch/2-6)
        b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
    else
        b.lbl.Position = Vector2.new(ax+10,ay+b.ch/2-6)
        b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
        if b.tog then
            b.tog.Position = Vector2.new(uiX+b.ox,uiY+b.oy)
            b.dot.Position = Vector2.new(uiX+b.ox+2+(TOG_W-TOG_H)*b.lt,uiY+b.oy+2)
        end
    end
end

local function showTab(tab)
    for _,b in ipairs(btns) do
        local yes = b.tab==tab
        bShow(b,yes)
        if yes then bPos(b) end
    end
end

local function switchTab(name)
    if name==currentTab then return end
    currentTab=name
    for _,t in ipairs(tabObjs) do t.sel=t.name==name end
    showTab(name)
end

local function addToggle(tab,lbl,relY,init,cb)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY
    local cw=CONTENT_W-ROW_PAD*2; local ch=ROW_H-4
    local ox=rx+cw-TOG_W-8; local oy=ry+ch/2-TOG_H/2
    local bg  = mkD(mkSq(uiX+rx,uiY+ry,cw,ch, C_ROWBG,true,1,3,nil,5))
    local dl  = mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch, C_DIV,3,1))
    local lb  = mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C_WHITE,false,8))
    local tog = mkD(mkSq(uiX+ox,uiY+oy,TOG_W,TOG_H, init and C_ON or C_OFF,true,1,4,nil,TOG_H))
    local dot = mkD(mkSq(uiX+ox+(init and TOG_W-TOG_H+2 or 2),uiY+oy+2,TOG_H-4,TOG_H-4, init and C_ONDOT or C_OFFDOT,true,1,5,nil,TOG_H))
    local b={tab=tab,isTog=true,state=init,bg=bg,lbl=lb,ln=dl,tog=tog,dot=dot,rx=rx,ry=ry,cw=cw,ch=ch,ox=ox,oy=oy,lt=init and 1 or 0,cb=cb}
    table.insert(btns,b); return #btns
end

local function addDiv(tab,lbl,relY)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY; local cw=CONTENT_W-ROW_PAD*2
    local lb = mkD(mkTx(lbl,uiX+rx+4,uiY+ry,10,C_GRAY,false,8))
    local dl = mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13, C_DIV,3,1))
    table.insert(btns,{tab=tab,isDiv=true,bg=lb,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=14})
    return #btns
end

local function addAct(tab,lbl,relY,col,cb)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY
    local cw=CONTENT_W-ROW_PAD*2; local ch=ROW_H-4
    local bg = mkD(mkSq(uiX+rx,uiY+ry,cw,ch, col or C_ROWBG,true,1,3,nil,5))
    local dl = mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch, C_DIV,3,1))
    local lb = mkD(mkTx(lbl,uiX+rx+cw/2,uiY+ry+ch/2-6,12,C_WHITE,true,8))
    local b  = {tab=tab,isAct=true,bg=bg,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=ch,cb=cb}
    table.insert(btns,b); return #btns
end

-- Combat
addDiv("Combat","COMBAT",6)
addToggle("Combat","No Evasive",  22, false,function(s) noevasive   =s end)
addToggle("Combat","No ComboWait",62, false,function(s) nocombowait =s end)
addToggle("Combat","No Ragdoll",  102,false,function(s) noragdoll   =s end)
addToggle("Combat","No Stun",     142,false,function(s) nostun      =s end)

-- Boosts
addDiv("Boosts","BOOSTS",6)
addToggle("Boosts","Inf Special",        22, false,function(s) infSpecial  =s end)
addToggle("Boosts","StateChecker Bypass",62, false,function(s) stateBypass =s end)
addToggle("Boosts","Ability Speed",      102,false,function(s) abilSpeedOn =s end)
addToggle("Boosts","KOC Chant Lock",     142,false,function(s) chantLock   =s end)

-- Settings
addDiv("Settings","KEYBIND",6)
local iKeyInfo = addAct("Settings","Menu Key: F1",    22,C_ROWBG,nil)
local iKeyBind = addAct("Settings","Click to Rebind", 62,Color3.fromRGB(16,22,42),nil)
addDiv("Settings","MISC",106)
local iStatus  = addAct("Settings","Auto-reapply: ON",122,Color3.fromRGB(14,28,18),nil)
local iDestroy = addAct("Settings","Destroy Menu",    164,Color3.fromRGB(30,8,8),function()
    for _,d in ipairs(allDrawings) do pcall(function() d:Remove() end) end
    destroyed = true
end)
btns[iStatus].lbl.Color  = C_GREEN
btns[iDestroy].lbl.Color = C_RED

showTab("Combat")

-- ============================================================
-- UPDATE POSITIONS (drag)
-- ============================================================
local function updatePos()
    dShadow.Position  = Vector2.new(uiX+6,uiY+6)
    dMainBg.Position  = Vector2.new(uiX,uiY)
    dBorder.Position  = Vector2.new(uiX,uiY)
    dTopBar.Position  = Vector2.new(uiX+1,uiY+1)
    dTopFill.Position = Vector2.new(uiX+1,uiY+TOPBAR_H-4)
    dTopLine.From     = Vector2.new(uiX+1,uiY+TOPBAR_H)
    dTopLine.To       = Vector2.new(uiX+uiW-1,uiY+TOPBAR_H)
    dTitleW.Position  = Vector2.new(uiX+14,uiY+11)
    dTitleA.Position  = Vector2.new(uiX+76,uiY+11)
    dKeyLbl.Position  = Vector2.new(uiX+uiW-20,uiY+13)
    dDotY.Position    = Vector2.new(uiX+uiW-54,uiY+14)
    dDotR.Position    = Vector2.new(uiX+uiW-40,uiY+14)
    dSide.Position    = Vector2.new(uiX+1,uiY+TOPBAR_H)
    dSideLn.From      = Vector2.new(uiX+SIDEBAR_W,uiY+TOPBAR_H)
    dSideLn.To        = Vector2.new(uiX+SIDEBAR_W,uiY+uiH-1)
    dContent.Position = Vector2.new(uiX+SIDEBAR_W,uiY+TOPBAR_H)
    dBotDiv.From      = Vector2.new(uiX+1,uiY+uiH-20)
    dBotDiv.To        = Vector2.new(uiX+uiW-1,uiY+uiH-20)
    dCharLbl.Position = Vector2.new(uiX+SIDEBAR_W+8,uiY+uiH-14)
    for _,t in ipairs(tabObjs) do
        t.bg.Position  = Vector2.new(uiX+8,uiY+t.relTY)
        t.acc.Position = Vector2.new(uiX+8,uiY+t.relTY)
        t.lbl.Position = Vector2.new(uiX+20,uiY+t.relTY+8)
    end
    for _,b in ipairs(btns) do
        if showSet[b.bg] then bPos(b) end
    end
end

-- ============================================================
-- KEY NAMES
-- ============================================================
local kn = {}
for i=0x41,0x5A do kn[i]=string.char(i) end
for i=0x30,0x39 do kn[i]=tostring(i-0x30) end
for i=0x60,0x69 do kn[i]="Num"..tostring(i-0x60) end
kn[0x70]="F1"  kn[0x71]="F2"  kn[0x72]="F3"  kn[0x73]="F4"
kn[0x74]="F5"  kn[0x75]="F6"  kn[0x76]="F7"  kn[0x77]="F8"
kn[0x78]="F9"  kn[0x79]="F10" kn[0x7A]="F11" kn[0x7B]="F12"
kn[0x20]="Space" kn[0x09]="Tab" kn[0x0D]="Enter" kn[0x1B]="Esc" kn[0x08]="Back"
kn[0x24]="Home" kn[0x23]="End" kn[0x2E]="Del" kn[0x2D]="Ins"
kn[0x21]="PgUp" kn[0x22]="PgDn"
kn[0x26]="Up" kn[0x28]="Down" kn[0x25]="Left" kn[0x27]="Right"
kn[0xBC]="," kn[0xBE]="." kn[0xBF]="/" kn[0xBA]=";" kn[0xBB]="=" kn[0xBD]="-"
kn[0xDB]="[" kn[0xDD]="]" kn[0xDC]="\\" kn[0xDE]="'" kn[0xC0]="`"
local function kname(k) return kn[k] or ("Key"..k) end

-- ============================================================
-- MAIN LOOP
-- ============================================================
AbilitySpeed.Value = 100

while true do
    task.wait()
    if destroyed then break end

    local clicking = ismouse1pressed()

    -- ---- DEATH ----
    if Humanoid and Humanoid.Health <= 0 then isDead = true end

    -- ---- TAB LERP ----
    for _,t in ipairs(tabObjs) do
        local tgt = t.sel and 1 or 0
        t.lt = t.lt + (tgt-t.lt)*0.15
        t.bg.Color  = lerpC(C_SIDEBAR,C_TABSEL, t.lt)
        t.acc.Color = lerpC(C_SIDEBAR,C_ACCENT2,t.lt)
        t.lbl.Color = lerpC(C_GRAY,   C_WHITE,  t.lt)
    end

    -- ---- TOGGLE LERP ----
    for _,b in ipairs(btns) do
        if b.isTog and b.tog then
            local tgt = b.state and 1 or 0
            b.lt = b.lt + (tgt-b.lt)*0.18
            b.tog.Color = lerpC(C_OFF,   C_ON,   b.lt)
            b.dot.Color = lerpC(C_OFFDOT,C_ONDOT,b.lt)
            b.dot.Position = Vector2.new(uiX+b.ox+2+(TOG_W-TOG_H)*b.lt, uiY+b.oy+2)
        end
    end

    -- ---- CLICKS ----
    if clicking and not wasClicking and menuOpen then
        if inBox(uiX,uiY,uiW,TOPBAR_H) then
            dragging=true; dragOffX=mouse.X-uiX; dragOffY=mouse.Y-uiY
        end
        for _,t in ipairs(tabObjs) do
            if inBox(uiX+8,uiY+t.relTY,SIDEBAR_W-16,28) then switchTab(t.name) end
        end
        for i,b in ipairs(btns) do
            if b.tab==currentTab and not b.isDiv then
                if inBox(uiX+b.rx,uiY+b.ry,b.cw,b.ch) then
                    if b.isTog then
                        b.state=not b.state
                        if b.cb then b.cb(b.state) end
                    elseif b.isAct then
                        if i==iKeyBind and not listenKey then
                            listenKey=true
                            btns[iKeyBind].lbl.Text  = "Press any key..."
                            btns[iKeyBind].lbl.Color = C_ACCENT2
                        elseif b.cb then b.cb() end
                    end
                    break
                end
            end
        end
    end

    if not clicking then dragging=false end
    if dragging and clicking then
        uiX=mouse.X-dragOffX; uiY=mouse.Y-dragOffY
        updatePos()
    end
    wasClicking = clicking

    -- ---- KEY REBIND ----
    if listenKey then
        for k=0x08,0xDD do
            if iskeypressed(k) and k~=0x01 and k~=0x02 then
                menuKey=k
                local n=kname(k)
                btns[iKeyInfo].lbl.Text  = "Menu Key: "..n
                btns[iKeyBind].lbl.Text  = "Click to Rebind"
                btns[iKeyBind].lbl.Color = C_WHITE
                dKeyLbl.Text = n
                listenKey=false
                break
            end
        end
    end

    -- ---- MENU TOGGLE ----
    if iskeypressed(menuKey) then
        menuOpen = not menuOpen
        setAllVisible(menuOpen)
        wait(0.2)
    end

    -- ---- LABELS ----
    if Character then dCharLbl.Text = "Character: "..Character.Value end

    -- ---- GAME LOGIC ----
    if not isDead and States then
        if stateBypass then
            for _,s in pairs(States:GetChildren()) do
                if s.ClassName=="BoolValue" then s.Value=false end
            end
            local Stuns = States:FindFirstChild("Stuns")
            if Stuns then
                for _,s in pairs(Stuns:GetChildren()) do
                    if s.ClassName=="BoolValue" then s.Value=false end
                end
            end
        end
        if infSpecial  then Special.Value=100 end
        if noevasive   then States.EvadeCooldown.Value=false States.CantEvade.Value=false end
        if nocombowait then States.ComboWait.Value=false end
        if noragdoll   then States.Ragdolled.Value=false end
        if nostun      then States.Attacking.Value=false States.BaseAttacking.Value=false end
        if chantLock and Character and Character.Value=="KingOfCurses" then
            if Chant then Chant.Value=3 end
        end
        Combo.Value=1; DamageMultiplier.Value=damageMultiplierValue
        AbilitySpeed.Value = abilSpeedOn and 100 or 1
    end
end
