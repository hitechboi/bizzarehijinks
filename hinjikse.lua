--[[
    Check it Interface
    by hitechboi / nejrio
    github.com/hitechboi
    star my post :p have fun.
]]
local user = game.Players.LocalPlayer.Name
local gameName = getgamename()
local noevasive, nocombowait, noragdoll, nostun = false, false, false, false
local infSpecial, stateBypass, chantLock        = false, false, false
local abilitySpeed = 1
local damageMultiplierValue = 1
local mouse = game.Players.LocalPlayer:GetMouse()
-- window
local uiX, uiY       = 300, 200
local uiW, uiH       = 440, 380
local dragging        = false
local dragOffX, dragOffY = 0, 0
local wasClicking     = false
local currentTab      = "Combat"
local menuKey         = 0x70
local listenKey       = false
local isDead          = false
local destroyed       = false
local wasMenuKey      = false
local menuOpen        = true
local menuToggledAt   = os.clock() - 1
local FADE_DUR        = 0.4
local TAB_FADE_DUR    = 0.2
local tabSwitchedAt   = os.clock() - 1
local prevTab         = nil

local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end

local function notif(msg, title, dur)
    pcall(function() notify(msg, title or "Check it Interface", dur or 3) end)
end

-- palette
local C_BG      = Color3.fromRGB(9, 11, 20)
local C_SIDEBAR = Color3.fromRGB(12, 15, 27)
local C_CONTENT = Color3.fromRGB(11, 13, 23)
local C_TOPBAR  = Color3.fromRGB(7, 9, 17)
local C_ACCENT  = Color3.fromRGB(70, 120, 255)
local C_TABSEL  = Color3.fromRGB(20, 35, 85)
local C_WHITE   = Color3.fromRGB(215, 220, 240)
local C_GRAY    = Color3.fromRGB(100, 112, 145)
local C_DIMGRAY = Color3.fromRGB(28, 33, 52)
local C_ON      = Color3.fromRGB(45, 85, 195)
local C_OFF     = Color3.fromRGB(20, 24, 42)
local C_ONDOT   = Color3.fromRGB(175, 198, 255)
local C_OFFDOT  = Color3.fromRGB(55, 65, 95)
local C_GREEN   = Color3.fromRGB(45, 190, 95)
local C_RED     = Color3.fromRGB(210, 55, 55)
local C_BORDER  = Color3.fromRGB(30, 40, 72)
local C_ROWBG   = Color3.fromRGB(14, 18, 33)
local C_DIV     = Color3.fromRGB(22, 27, 48)
local C_SHADOW  = Color3.fromRGB(0, 0, 5)
local C_ORANGE  = Color3.fromRGB(255, 175, 80)

-- layout
local SIDEBAR_W = 128
local TOPBAR_H  = 40
local FOOTER_H  = 22
local ROW_H     = 40
local ROW_PAD   = 10
local TOG_W     = 34
local TOG_H     = 17
local CONTENT_W = uiW - SIDEBAR_W
local HDL_SIZE  = 8

-- refs
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
        wait(3); grabRefs()
        if Humanoid and Humanoid.Health > 0 then isDead = false end
    end
end)

-- ── drawing system ─────────────────────────────────────────────
local allDrawings = {}
local showSet     = {}
local tabSet      = {}

local function mkD(d)
    table.insert(allDrawings, d)
    d.Visible = false
    return d
end

local function setShow(d, yes)
    showSet[d] = yes or nil
    d.Visible  = yes and true or false
end

local function applyFade()
    local mf = 1 - (menuToggledAt - (os.clock() - FADE_DUR)) / FADE_DUR
    if not menuOpen and mf >= 1.1 then
        for _,d in ipairs(allDrawings) do d.Visible = false end
        return
    end
    local mOp = mf < 1.1
        and math.abs((menuOpen and 0 or 1) - clamp(mf,0,1))
        or  (menuOpen and 1 or 0)
    local tp  = clamp((os.clock() - tabSwitchedAt) / TAB_FADE_DUR, 0, 1)
    for _,d in ipairs(allDrawings) do
        if showSet[d] then
            local tOp = tabSet[d]=="next" and tp or tabSet[d]=="prev" and (1-tp) or 1
            local op  = mOp * tOp
            d.Visible      = op > 0.01
            d.Transparency = op
        else
            d.Visible = false
        end
    end
end

-- ── drawing helpers ────────────────────────────────────────────
local function mkSq(x,y,w,h,col,filled,transp,zi,thick,corner)
    local s = Drawing.new("Square")
    s.Position=Vector2.new(x,y); s.Size=Vector2.new(w,h)
    s.Color=col; s.Filled=filled; s.Transparency=transp or 1
    s.ZIndex=zi or 1; s.Visible=true
    if not filled then s.Thickness=thick or 1 end
    if corner and corner>0 then pcall(function() s.Corner=corner end) end
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
    l.Color=col or C_ACCENT; l.Transparency=1
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

-- ── base UI ────────────────────────────────────────────────────
-- drop shadow — same size as UI, offset down-right, no outline
local dShadow  = mkD(mkSq(uiX-2,uiY-2,uiW+4,uiH+4,  C_SHADOW,true,0.5,0,nil,12))
local dMainBg  = mkD(mkSq(uiX,uiY,uiW,uiH,           C_BG,    true,1,1,nil,10))
local dGlow1 = mkD(mkSq(uiX-1,uiY-1,uiW+2,uiH+2, C_ACCENT,false,0.9,1,1,11))
local dGlow2 = mkD(mkSq(uiX-2,uiY-2,uiW+4,uiH+4, C_ACCENT,false,0.35,0,2,12))
local glowLines = {dGlow1,dGlow2}
local glowPhase = {0, math.pi*0.6}
local dBorder  = mkD(mkSq(uiX,uiY,uiW,uiH, C_BORDER,false,0.2,3,1,10))
-- topbar (rounded top only; flat strip squares off the bottom join)
local dTopBar  = mkD(mkSq(uiX+1,uiY+1,uiW-2,TOPBAR_H,      C_TOPBAR,true,1,3,nil,9))
local dTopFill = mkD(mkSq(uiX+1,uiY+TOPBAR_H-5,uiW-2,7,    C_TOPBAR,true,1,3))
local dTopLine = mkD(mkLn(uiX+1,uiY+TOPBAR_H,uiX+uiW-1,uiY+TOPBAR_H, C_BORDER,4,1))
-- title
local dTitleW  = mkD(mkTx("Check it",   uiX+14,      uiY+12, 14,C_WHITE, false,9,true))
local dTitleA  = mkD(mkTx("Interface",  uiX+78,      uiY+12, 14,C_ACCENT,false,9,true))
local dTitleG  = mkD(mkTx(gameName,     uiX+154,     uiY+12, 13,C_ORANGE,false,9,false))
local dKeyLbl  = mkD(mkTx("F1",        uiX+uiW-22, uiY+14, 11,C_GRAY,  false,9))
-- two small indicator dots in topbar
local dDotY    = mkD(mkSq(uiX+uiW-55,uiY+15,8,8, Color3.fromRGB(190,148,0),true,1,9,nil,3))
local dDotR    = mkD(mkSq(uiX+uiW-42,uiY+15,8,8, Color3.fromRGB(170,44,44),true,1,9,nil,3))
-- sidebar & content — flat so mainBg corners show; inset 1px
local dSide    = mkD(mkSq(uiX+1,uiY+TOPBAR_H,SIDEBAR_W-1,uiH-TOPBAR_H-FOOTER_H-1, C_SIDEBAR,true,1,2,nil,8))
local dSideLn  = mkD(mkLn(uiX+SIDEBAR_W,uiY+TOPBAR_H,uiX+SIDEBAR_W,uiY+uiH-FOOTER_H, C_BORDER,4,1))
local dContent = mkD(mkSq(uiX+SIDEBAR_W,uiY+TOPBAR_H,CONTENT_W-1,uiH-TOPBAR_H-FOOTER_H-1, C_CONTENT,true,1,2,nil,8))
-- footer
local dFooter  = mkD(mkSq(uiX+1,uiY+uiH-FOOTER_H,uiW-2,FOOTER_H-1, C_TOPBAR,true,1,3,nil,6))
local dFotLine = mkD(mkLn(uiX+1,uiY+uiH-FOOTER_H,uiX+uiW-1,uiY+uiH-FOOTER_H, C_BORDER,4,1))
local dCharLbl = mkD(mkTx("Character: ...",uiX+SIDEBAR_W+8,uiY+uiH-FOOTER_H+5,10,C_GRAY,false,9))

local baseUI = {
    dShadow,
    dGlow2,dGlow1,
    dMainBg,
    dBorder,
    dTopBar,dTopFill,dTopLine,
    dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR,
    dSide,dSideLn,dContent,
    dFooter,dFotLine,dCharLbl
}
for _,d in ipairs(baseUI) do setShow(d,true) end

-- ── tabs ───────────────────────────────────────────────────────
local tabNames = {"Combat","Boosts","Misc","Updates","Settings"}
local tabObjs  = {}

for i,name in ipairs(tabNames) do
    local relTY = TOPBAR_H + 8 + (i-1)*34
    local isSel = name==currentTab
    local tbg  = mkD(mkSq(uiX+7,uiY+relTY,SIDEBAR_W-14,26, isSel and C_TABSEL or C_SIDEBAR,true,1,3,nil,5))
    local tacc = mkD(mkSq(uiX+7,uiY+relTY,3,26,             isSel and C_ACCENT or C_SIDEBAR, true,1,4,nil,2))
    -- two labels: white (selected) and gray (unselected) — swap on tab change since Text.Color is immutable
    local tlblW = mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C_WHITE,false,8))
    local tlblG = mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C_GRAY, false,8))
    setShow(tbg,true); setShow(tacc,true)
    setShow(tlblW, isSel); setShow(tlblG, not isSel)
    tabObjs[i] = {bg=tbg,acc=tacc,lbl=tlblW,lblG=tlblG,name=name,sel=isSel,lt=isSel and 1 or 0,relTY=relTY}
end

-- ── button system ──────────────────────────────────────────────
local btns = {}

local function bShow(b, yes)
    setShow(b.bg,  yes)
    if not b.isLog then setShow(b.lbl, yes) end
    if b.ln     then setShow(b.ln,     yes) end
    if b.tog    then setShow(b.tog,    yes) end
    if b.dot    then setShow(b.dot,    yes) end
    if b.track  then setShow(b.track,  yes) end
    if b.fill   then setShow(b.fill,   yes) end
    if b.handle then setShow(b.handle, yes) end
    if b.lbls   then for _,l in ipairs(b.lbls) do setShow(l,yes) end end
end

local function bPos(b)
    local ax,ay = uiX+b.rx, uiY+b.ry
    b.bg.Position = Vector2.new(ax,ay)
    if b.isLog then
        for i,lb in ipairs(b.lbls) do
            if b.starFirst and i==1 then
                lb.Position = Vector2.new(ax+b.cw/2, ay+b.pad)
            else
                local offset = b.starFirst and (b.starH+b.pad+(i-2)*b.lineH) or (b.pad+(i-1)*b.lineH)
                lb.Position = Vector2.new(ax+8, ay+offset)
            end
        end
        return
    end
    if b.isDiv then
        b.lbl.Position = Vector2.new(ax+6,ay)
        if b.ln then b.ln.From=Vector2.new(ax,ay+13); b.ln.To=Vector2.new(ax+b.cw,ay+13) end
    elseif b.isAct then
        b.lbl.Position = Vector2.new(ax+b.cw/2,ay+b.ch/2-6)
        b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
    elseif b.isSlider then
        b.lbl.Position = Vector2.new(ax+8,ay+7)
        b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
        local tx=ax+8; local ty=ay+b.ch-11
        b.track.From=Vector2.new(tx,ty); b.track.To=Vector2.new(tx+b.trackW,ty)
        local frac=(b.value-b.minV)/(b.maxV-b.minV)
        local fx=tx+frac*b.trackW
        b.fill.From=Vector2.new(tx,ty); b.fill.To=Vector2.new(fx,ty)
        b.handle.Position=Vector2.new(fx-4,ty-4)
    else
        b.lbl.Position = Vector2.new(ax+10,ay+b.ch/2-6)
        b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
        if b.tog then
            b.tog.Position = Vector2.new(uiX+b.ox,uiY+b.oy)
            b.dot.Position = Vector2.new(uiX+b.ox+2+(TOG_W-TOG_H)*b.lt,uiY+b.oy+2)
        end
    end
end

local function tagBtnFade(b, group)
    tabSet[b.bg]=group
    if not b.isLog then tabSet[b.lbl]=group end
    if b.ln     then tabSet[b.ln]=group     end
    if b.tog    then tabSet[b.tog]=group    end
    if b.dot    then tabSet[b.dot]=group    end
    if b.track  then tabSet[b.track]=group  end
    if b.fill   then tabSet[b.fill]=group   end
    if b.handle then tabSet[b.handle]=group end
    if b.lbls   then for _,l in ipairs(b.lbls) do tabSet[l]=group end end
end

local function showTab(tab)
    for _,b in ipairs(btns) do
        local yes=b.tab==tab; bShow(b,yes)
        if yes then bPos(b) end
    end
end

local function switchTab(name)
    if name==currentTab then return end
    prevTab=currentTab; currentTab=name; tabSwitchedAt=os.clock()
    for _,t in ipairs(tabObjs) do
        t.sel=t.name==name
        -- swap white/gray labels
        setShow(t.lbl,  t.sel)
        setShow(t.lblG, not t.sel)
    end
    for _,d in ipairs(allDrawings) do tabSet[d]=nil end
    for _,b in ipairs(btns) do
        if b.tab==prevTab  then bShow(b,true); bPos(b); tagBtnFade(b,"prev") end
    end
    for _,b in ipairs(btns) do
        if b.tab==name     then bShow(b,true); bPos(b); tagBtnFade(b,"next") end
    end
end

-- ── widget constructors ────────────────────────────────────────
local function addToggle(tab,lbl,relY,init,cb)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY
    local cw=CONTENT_W-ROW_PAD*2; local ch=ROW_H-2
    local ox=rx+cw-TOG_W-8; local oy=ry+ch/2-TOG_H/2
    local bg  = mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C_ROWBG,true,1,3,nil,4))
    local dl  = mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C_DIV,4,1))
    local lb  = mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C_WHITE,false,8))
    local tog = mkD(mkSq(uiX+ox,uiY+oy,TOG_W,TOG_H,init and C_ON or C_OFF,true,1,4,nil,TOG_H))
    local dot = mkD(mkSq(uiX+ox+(init and TOG_W-TOG_H+2 or 2),uiY+oy+2,TOG_H-4,TOG_H-4,init and C_ONDOT or C_OFFDOT,true,1,5,nil,TOG_H))
    local b={tab=tab,isTog=true,state=init,bg=bg,lbl=lb,ln=dl,tog=tog,dot=dot,rx=rx,ry=ry,cw=cw,ch=ch,ox=ox,oy=oy,lt=init and 1 or 0,cb=cb}
    table.insert(btns,b); return #btns
end

local function addDiv(tab,lbl,relY)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY; local cw=CONTENT_W-ROW_PAD*2
    local lb=mkD(mkTx(lbl,uiX+rx+6,uiY+ry,9,C_GRAY,false,8))
    local dl=mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13,C_DIV,4,1))
    table.insert(btns,{tab=tab,isDiv=true,bg=lb,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=14})
    return #btns
end

local function addAct(tab,lbl,relY,col,cb,lblCol)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY
    local cw=CONTENT_W-ROW_PAD*2; local ch=ROW_H-2
    local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,col or C_ROWBG,true,1,3,nil,4))
    local dl=mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C_DIV,4,1))
    local lb=mkD(mkTx(lbl,uiX+rx+cw/2,uiY+ry+ch/2-6,12,lblCol or C_WHITE,true,8))
    local b={tab=tab,isAct=true,bg=bg,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=ch,cb=cb}
    table.insert(btns,b); return #btns
end

local function addSlider(tab,lbl,relY,minV,maxV,initV,cb)
    local rx=SIDEBAR_W+ROW_PAD; local ry=TOPBAR_H+relY
    local cw=CONTENT_W-ROW_PAD*2; local ch=ROW_H+6
    local trackW=cw-16
    local bg  = mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C_ROWBG,true,1,3,nil,4))
    local dl  = mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C_DIV,4,1))
    local lb  = mkD(mkTx(lbl..": "..math.floor(initV),uiX+rx+8,uiY+ry+7,12,C_WHITE,false,8))
    local ty  = uiY+ry+ch-11
    local trk = mkD(mkLn(uiX+rx+8,ty,uiX+rx+8+trackW,ty,C_DIMGRAY,5,3))
    local frac=(initV-minV)/(maxV-minV)
    local fx  = uiX+rx+8+frac*trackW
    local fil = mkD(mkLn(uiX+rx+8,ty,fx,ty,C_ACCENT,6,3))
    local hdl = mkD(mkSq(fx-4,ty-4,HDL_SIZE,HDL_SIZE,C_WHITE,true,1,7,nil,3))
    local b={tab=tab,isSlider=true,bg=bg,lbl=lb,ln=dl,track=trk,fill=fil,handle=hdl,
             rx=rx,ry=ry,cw=cw,ch=ch,trackW=trackW,minV=minV,maxV=maxV,
             value=initV,baseLbl=lbl,dragging=false,cb=cb}
    table.insert(btns,b); return #btns
end


local function addLog(tab, lines, relY, starFirst)
    local rx    = SIDEBAR_W+ROW_PAD
    local cw    = CONTENT_W-ROW_PAD*2
    local lineH = 18
    local starH = starFirst and 26 or 0  -- extra height for star line
    local pad   = 10
    local ch    = starH + (#lines - (starFirst and 1 or 0)) * lineH + pad*2
    local ry    = TOPBAR_H+relY
    local bg    = mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C_ROWBG,true,1,3,nil,6))
    local lbls  = {}
    for i,line in ipairs(lines) do
        local tx = uiX+rx+8
        local ty
        local lb = mkD(Drawing.new("Text"))
        if starFirst and i==1 then
            -- centered gold star line
            ty = uiY+ry+pad
            lb.Text        = line
            lb.Position    = Vector2.new(uiX+rx+cw/2, ty)
            lb.Size        = 14
            lb.Color       = Color3.fromRGB(255, 200, 40)
            lb.Center      = true
            lb.Outline     = true
            lb.Font        = Drawing.Fonts.Minecraft
        else
            local offset = starFirst and (starH + pad + (i-2)*lineH) or (pad + (i-1)*lineH)
            ty = uiY+ry+offset
            lb.Text        = line
            lb.Position    = Vector2.new(tx, ty)
            lb.Size        = 11
            lb.Color       = C_WHITE
            lb.Center      = false
            lb.Outline     = true
            lb.Font        = Drawing.Fonts.Minecraft
        end
        lb.Transparency = 1
        lb.ZIndex       = 8
        lb.Visible      = false
        table.insert(lbls, lb)
    end
    local b = {tab=tab,isLog=true,bg=bg,lbl=bg,ln=nil,lbls=lbls,
               rx=rx,ry=ry,cw=cw,ch=ch,lines=lines,lineH=lineH,pad=pad,
               starFirst=starFirst,starH=starH}
    table.insert(btns,b); return #btns
end
-- ── populate tabs ──────────────────────────────────────────────
-- Combat
addDiv("Combat","COMBAT",6)
addToggle("Combat","No Evasive",   20,false,function(s) noevasive=s
    notif(("No Evasive "..(s and "enabled" or "disabled")), nil, 2)
end)
addToggle("Combat","No ComboWait", 58,false,function(s) nocombowait=s
    notif(("No ComboWait "..(s and "enabled" or "disabled")), nil, 2)
end)
addToggle("Combat","No Ragdoll",   96,false,function(s) noragdoll=s
    notif(("No Ragdoll "..(s and "enabled" or "disabled")), nil, 2)
end)
addToggle("Combat","No Stun",     134,false,function(s) nostun=s
    notif(("No Stun "..(s and "enabled" or "disabled")), nil, 2)
end)

-- Boosts
addDiv("Boosts","BOOSTS",6)
addToggle("Boosts","Inf Special",         20,false,function(s) infSpecial=s
    notif(("Inf Special "..(s and "enabled" or "disabled")), nil, 2)
end)
addToggle("Boosts","StateChecker Bypass", 58,false,function(s) stateBypass=s
    notif(("StateChecker Bypass "..(s and "enabled" or "disabled")), nil, 2)
end)
addSlider("Boosts","Ability Speed",       96,1,100,1,function(v) abilitySpeed=v end)
addToggle("Boosts","KOC Chant Lock",     144,false,function(s) chantLock=s
    notif(("KOC Chant Lock "..(s and "enabled" or "disabled")), nil, 2)
end)

-- Misc
addDiv("Misc","MISCELLANEOUS",6)
addAct("Misc","Auto-reapply: ON",20,Color3.fromRGB(12,26,16),nil,C_GREEN)
addDiv("Misc","INFO",68)
addAct("Misc","v1.0  |  github.com/hitechboi",84,C_ROWBG,nil,C_GRAY)

-- Updates
addDiv("Updates","UPDATE LOG",6)
addLog("Updates", {
    "STAR MY POST ! :D",
    "> v1.0 - Initial release",
    "> v1.1 - QOL features, and new menu",
    "> v1.1 - No Stun now clears CantRun",
    "> v1.1 - Ability Speed slider added",
    "> hi :p"
}, 22, true)

-- Settings
addDiv("Settings","KEYBIND",6)
local iKeyInfo = addAct("Settings","Menu Key: F1",   20,C_ROWBG,nil)
local iKeyBind = addAct("Settings","Click to Rebind",58,Color3.fromRGB(14,20,40),nil)
addDiv("Settings","DANGER",106)
local iDestroy = addAct("Settings","Destroy Menu",  122,Color3.fromRGB(28,7,7),function()
    notif("UI destroyed.", "Check it Interface", 3)
    for _,d in ipairs(allDrawings) do pcall(function() d:Remove() end) end
    destroyed=true
end,C_RED)

showTab("Combat")
notif("Loaded on "..gameName, "Check it Interface", 4)

-- ── update positions (drag) ────────────────────────────────────
local function updatePos()
    dShadow.Position  = Vector2.new(uiX-2,uiY-2)
    dMainBg.Position  = Vector2.new(uiX,uiY)
    dBorder.Position  = Vector2.new(uiX,uiY)
    -- glow border squares
    dGlow1.Position=Vector2.new(uiX-1,uiY-1)
    dGlow2.Position=Vector2.new(uiX-2,uiY-2)
    dTopBar.Position  = Vector2.new(uiX+1,uiY+1)
    dTopFill.Position = Vector2.new(uiX+1,uiY+TOPBAR_H-5)
    dTopLine.From     = Vector2.new(uiX+1,uiY+TOPBAR_H)
    dTopLine.To       = Vector2.new(uiX+uiW-1,uiY+TOPBAR_H)
    dTitleW.Position  = Vector2.new(uiX+14,uiY+12)
    dTitleA.Position  = Vector2.new(uiX+78,uiY+12)
    dTitleG.Position  = Vector2.new(uiX+154,uiY+12)
    dKeyLbl.Position  = Vector2.new(uiX+uiW-22,uiY+14)
    dDotY.Position    = Vector2.new(uiX+uiW-55,uiY+15)
    dDotR.Position    = Vector2.new(uiX+uiW-42,uiY+15)
    dSide.Position    = Vector2.new(uiX+1,uiY+TOPBAR_H)
    dSideLn.From      = Vector2.new(uiX+SIDEBAR_W,uiY+TOPBAR_H)
    dSideLn.To        = Vector2.new(uiX+SIDEBAR_W,uiY+uiH-FOOTER_H)
    dContent.Position = Vector2.new(uiX+SIDEBAR_W,uiY+TOPBAR_H)
    dFooter.Position  = Vector2.new(uiX+1,uiY+uiH-FOOTER_H)
    dFotLine.From     = Vector2.new(uiX+1,uiY+uiH-FOOTER_H)
    dFotLine.To       = Vector2.new(uiX+uiW-1,uiY+uiH-FOOTER_H)
    dCharLbl.Position = Vector2.new(uiX+SIDEBAR_W+8,uiY+uiH-FOOTER_H+5)
    for _,t in ipairs(tabObjs) do
        t.bg.Position   = Vector2.new(uiX+7,uiY+t.relTY)
        t.acc.Position  = Vector2.new(uiX+7,uiY+t.relTY)
        t.lbl.Position  = Vector2.new(uiX+18,uiY+t.relTY+7)
        t.lblG.Position = Vector2.new(uiX+18,uiY+t.relTY+7)
    end
    for _,b in ipairs(btns) do
        if showSet[b.bg] then bPos(b) end
    end
end

-- ── key names ──────────────────────────────────────────────────
local kn={}
for i=0x41,0x5A do kn[i]=string.char(i) end
for i=0x30,0x39 do kn[i]=tostring(i-0x30) end
for i=0x60,0x69 do kn[i]="Num"..tostring(i-0x60) end
kn[0x70]="F1" kn[0x71]="F2" kn[0x72]="F3" kn[0x73]="F4"
kn[0x74]="F5" kn[0x75]="F6" kn[0x76]="F7" kn[0x77]="F8"
kn[0x78]="F9" kn[0x79]="F10" kn[0x7A]="F11" kn[0x7B]="F12"
kn[0x20]="Space" kn[0x09]="Tab" kn[0x0D]="Enter" kn[0x1B]="Esc" kn[0x08]="Back"
kn[0x24]="Home" kn[0x23]="End" kn[0x2E]="Del" kn[0x2D]="Ins"
kn[0x21]="PgUp" kn[0x22]="PgDn"
kn[0x26]="Up" kn[0x28]="Down" kn[0x25]="Left" kn[0x27]="Right"
kn[0xBC]="," kn[0xBE]="." kn[0xBF]="/" kn[0xBA]=";" kn[0xBB]="=" kn[0xBD]="-"
kn[0xDB]="[" kn[0xDD]="]" kn[0xDC]="\\" kn[0xDE]="'" kn[0xC0]="`"
local function kname(k) return kn[k] or ("Key"..k) end

-- ── main loop ──────────────────────────────────────────────────
AbilitySpeed.Value = 1

while true do
    task.wait()
    if destroyed then break end
    local clicking = ismouse1pressed()

    if Humanoid and Humanoid.Health <= 0 then isDead = true end

    -- tab sidebar lerp
    for _,t in ipairs(tabObjs) do
        local tgt = t.sel and 1 or 0
        t.lt = t.lt + (tgt-t.lt)*0.15
        t.bg.Color  = lerpC(C_SIDEBAR,C_TABSEL,t.lt)
        t.acc.Color = lerpC(C_SIDEBAR,C_ACCENT,t.lt)
    end

    -- toggle lerp
    for _,b in ipairs(btns) do
        if b.isTog and b.tog then
            local tgt=b.state and 1 or 0
            b.lt=b.lt+(tgt-b.lt)*0.18
            b.tog.Color=lerpC(C_OFF,   C_ON,   b.lt)
            b.dot.Color=lerpC(C_OFFDOT,C_ONDOT,b.lt)
            b.dot.Position=Vector2.new(uiX+b.ox+2+(TOG_W-TOG_H)*b.lt,uiY+b.oy+2)
        end
    end

    -- animated glow border
    do
        local t = os.clock() * 1.0
        for i, sq in ipairs(glowLines) do
            local p = t + glowPhase[i]
            local r = math.floor(15  + 45  * math.max(0, math.sin(p + 1.0)))
            local g = math.floor(25  + 55  * math.max(0, math.sin(p + 0.4)))
            local b = math.floor(130 + 125 * math.max(0, math.sin(p)))
            sq.Color = Color3.fromRGB(r, g, b)
            sq.Transparency = (i==1 and 0.6 or 0.75) + 0.25 * math.abs(math.sin(p * 0.5))
        end
    end

    -- fade
    applyFade()

    -- clean up prev tab after transition
    if prevTab and (os.clock()-tabSwitchedAt)>=TAB_FADE_DUR then
        for _,b in ipairs(btns) do if b.tab==prevTab then bShow(b,false) end end
        for _,d in ipairs(allDrawings) do if tabSet[d]=="prev" then tabSet[d]=nil end end
        prevTab=nil
    end

    -- click guard
    local mfn  = 1-(menuToggledAt-(os.clock()-FADE_DUR))/FADE_DUR
    local mOp  = math.abs((menuOpen and 0 or 1)-clamp(mfn,0,1))

    if clicking and not wasClicking and mOp>0.5 then
        -- topbar drag
        if inBox(uiX,uiY,uiW,TOPBAR_H) then
            dragging=true; dragOffX=mouse.X-uiX; dragOffY=mouse.Y-uiY
        end
        -- tab switch
        for _,t in ipairs(tabObjs) do
            if inBox(uiX+7,uiY+t.relTY,SIDEBAR_W-14,26) then switchTab(t.name) end
        end
        -- buttons
        for i,b in ipairs(btns) do
            if b.tab==currentTab and not b.isDiv and not b.isSlider then
                if inBox(uiX+b.rx,uiY+b.ry,b.cw,b.ch) then
                    if b.isTog then
                        b.state=not b.state
                        if b.cb then b.cb(b.state) end
                    elseif b.isAct then
                        if i==iKeyBind and not listenKey then
                            listenKey=true
                            btns[iKeyBind].lbl.Text="Press any key..."
                        elseif b.cb then b.cb() end
                    end
                    break
                end
            end
        end
    end

    -- slider drag
    for _,b in ipairs(btns) do
        if b.isSlider and b.tab==currentTab then
            local ax=uiX+b.rx+8; local ay=uiY+b.ry+b.ch-11
            if clicking and not wasClicking then
                if inBox(uiX+b.rx,uiY+b.ry,b.cw,b.ch) then b.dragging=true end
            end
            -- notify on release
            if not clicking and wasClicking and b.dragging then
                notif(b.baseLbl..": "..math.floor(b.value), nil, 2)
            end
            if not clicking then b.dragging=false end
            if b.dragging and clicking then
                local frac=clamp((mouse.X-ax)/b.trackW,0,1)
                b.value=b.minV+frac*(b.maxV-b.minV)
                local fx=ax+frac*b.trackW
                b.fill.To=Vector2.new(fx,ay)
                b.handle.Position=Vector2.new(fx-4,ay-4)
                b.lbl.Text=b.baseLbl..": "..math.floor(b.value)
                if b.cb then b.cb(b.value) end
            end
        end
    end

    if not clicking then dragging=false end
    if dragging and clicking then
        uiX=mouse.X-dragOffX; uiY=mouse.Y-dragOffY
        updatePos()
    end
    wasClicking=clicking

    -- key rebind
    if listenKey then
        for k=0x08,0xDD do
            if iskeypressed(k) and k~=0x01 and k~=0x02 then
                menuKey=k
                local n=kname(k)
                btns[iKeyInfo].lbl.Text="Menu Key: "..n
                btns[iKeyBind].lbl.Text="Click to Rebind"
                dKeyLbl.Text=n
                listenKey=false
                break
            end
        end
    end

    -- menu toggle (fire on press only)
    local keyDown=iskeypressed(menuKey)
    if keyDown and not wasMenuKey then
        menuOpen=not menuOpen; menuToggledAt=os.clock()
    end
    wasMenuKey=keyDown

    -- character label
    if Character then
        dCharLbl.Text="Credit: besosme  |  Character: "..Character.Value
    end

    -- game logic
    if not isDead and States then
        if stateBypass then
            for _,s in pairs(States:GetChildren()) do
                if s.ClassName=="BoolValue" then s.Value=false end
            end
            local Stuns=States:FindFirstChild("Stuns")
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
        if nostun then
            States.Attacking.Value=false
            States.BaseAttacking.Value=false
            States.CantRun.Value=false
            -- clear Stuns folder
            local Stuns=States:FindFirstChild("Stuns")
            if Stuns then
                for _,s in pairs(Stuns:GetChildren()) do
                    if s.ClassName=="BoolValue" then s.Value=false end
                end
            end
        end
        if chantLock and Character and Character.Value=="KingOfCurses" then
            if Chant then Chant.Value=3 end
        end
        DamageMultiplier.Value=damageMultiplierValue
        AbilitySpeed.Value=abilitySpeed
    end
end
