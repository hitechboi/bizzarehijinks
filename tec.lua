--[[
    Feel like we back in action, let's make it happen.
    made by nejrio/aka/besosme
]]
local UILib = {}
local _collapseSections = {}

local THEMES = {
    ["Check it"] = {
        ACCENT=Color3.fromRGB(70,120,255),  BG=Color3.fromRGB(9,11,20),
        SIDEBAR=Color3.fromRGB(12,15,27),   CONTENT=Color3.fromRGB(11,13,23),
        TOPBAR=Color3.fromRGB(7,9,17),      BORDER=Color3.fromRGB(30,40,72),
        ROWBG=Color3.fromRGB(14,18,33),     TABSEL=Color3.fromRGB(20,35,85),
        WHITE=Color3.fromRGB(215,220,240),  GRAY=Color3.fromRGB(100,112,145),
        DIMGRAY=Color3.fromRGB(28,33,52),
        ON=Color3.fromRGB(45,85,195),       OFF=Color3.fromRGB(20,24,42),
        ONDOT=Color3.fromRGB(175,198,255),  OFFDOT=Color3.fromRGB(55,65,95),
        DIV=Color3.fromRGB(22,27,48),     MINIBAR=Color3.fromRGB(11,13,22),
    },
    ["Moon"] = {
        ACCENT=Color3.fromRGB(160,130,255), BG=Color3.fromRGB(10,9,18),
        SIDEBAR=Color3.fromRGB(14,12,26),   CONTENT=Color3.fromRGB(12,11,22),
        TOPBAR=Color3.fromRGB(7,6,14),      BORDER=Color3.fromRGB(45,35,80),
        ROWBG=Color3.fromRGB(16,14,30),     TABSEL=Color3.fromRGB(35,25,70),
        WHITE=Color3.fromRGB(210,205,240),  GRAY=Color3.fromRGB(110,100,155),
        DIMGRAY=Color3.fromRGB(30,25,55),
        ON=Color3.fromRGB(90,60,200),       OFF=Color3.fromRGB(22,18,45),
        ONDOT=Color3.fromRGB(200,180,255),  OFFDOT=Color3.fromRGB(60,50,100),
        DIV=Color3.fromRGB(28,22,52),     MINIBAR=Color3.fromRGB(13,11,24),
    },
    ["Grass"] = {
        ACCENT=Color3.fromRGB(60,200,100),  BG=Color3.fromRGB(8,14,10),
        SIDEBAR=Color3.fromRGB(10,18,13),   CONTENT=Color3.fromRGB(9,16,11),
        TOPBAR=Color3.fromRGB(6,11,8),      BORDER=Color3.fromRGB(25,55,35),
        ROWBG=Color3.fromRGB(11,20,14),     TABSEL=Color3.fromRGB(18,45,25),
        WHITE=Color3.fromRGB(200,235,210),  GRAY=Color3.fromRGB(90,130,105),
        DIMGRAY=Color3.fromRGB(20,40,28),
        ON=Color3.fromRGB(30,140,65),       OFF=Color3.fromRGB(15,30,20),
        ONDOT=Color3.fromRGB(150,240,180),  OFFDOT=Color3.fromRGB(45,80,58),
        DIV=Color3.fromRGB(18,35,24),     MINIBAR=Color3.fromRGB(10,18,13),
    },
    ["Light"] = {
        ACCENT=Color3.fromRGB(50,100,255),  BG=Color3.fromRGB(230,233,245),
        SIDEBAR=Color3.fromRGB(215,220,235),CONTENT=Color3.fromRGB(220,224,238),
        TOPBAR=Color3.fromRGB(200,205,225), BORDER=Color3.fromRGB(170,178,210),
        ROWBG=Color3.fromRGB(210,214,230),  TABSEL=Color3.fromRGB(190,205,240),
        WHITE=Color3.fromRGB(25,30,60),     GRAY=Color3.fromRGB(90,100,140),
        DIMGRAY=Color3.fromRGB(180,185,210),
        ON=Color3.fromRGB(60,120,255),      OFF=Color3.fromRGB(180,185,210),
        ONDOT=Color3.fromRGB(255,255,255),  OFFDOT=Color3.fromRGB(130,140,175),
        DIV=Color3.fromRGB(185,190,215),  MINIBAR=Color3.fromRGB(205,210,228),
    },
    ["Dark"] = {
        ACCENT=Color3.fromRGB(180,180,180), BG=Color3.fromRGB(4,4,6),
        SIDEBAR=Color3.fromRGB(6,6,9),      CONTENT=Color3.fromRGB(5,5,8),
        TOPBAR=Color3.fromRGB(3,3,5),       BORDER=Color3.fromRGB(20,20,28),
        ROWBG=Color3.fromRGB(7,7,10),       TABSEL=Color3.fromRGB(15,15,22),
        WHITE=Color3.fromRGB(190,190,195),  GRAY=Color3.fromRGB(80,80,90),
        DIMGRAY=Color3.fromRGB(15,15,20),
        ON=Color3.fromRGB(100,100,110),     OFF=Color3.fromRGB(12,12,16),
        ONDOT=Color3.fromRGB(220,220,225),  OFFDOT=Color3.fromRGB(45,45,55),
        DIV=Color3.fromRGB(14,14,18),     MINIBAR=Color3.fromRGB(6,6,8),
    },
}
UILib.Themes = THEMES
_G.UILib = UILib

print("[UILib] v1.6.0 loaded")

local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function lerpC(a,b,t)
    return Color3.fromRGB(
        math.floor(a.R*255+(b.R*255-a.R*255)*t),
        math.floor(a.G*255+(b.G*255-a.G*255)*t),
        math.floor(a.B*255+(b.B*255-a.B*255)*t))
end
local function getViewport()
    local ok,vp = pcall(function() return workspace.CurrentCamera.ViewportSize end)
    if ok and vp then return vp.X, vp.Y end
    return 1920, 1080
end
local function mkTri(x1,y1,x2,y2,x3,y3,col,filled,zi)
    local t = Drawing.new("Triangle")
    t.PointA=Vector2.new(x1,y1); t.PointB=Vector2.new(x2,y2); t.PointC=Vector2.new(x3,y3)
    t.Color=col or C.GRAY; t.Filled=filled~=false; t.Transparency=1
    t.ZIndex=zi or 8; t.Visible=true
    return t
end
local function setTriDir(tri,cx,cy,dir)
    -- dir: "v"=down, "^"=up, ">"=right
    if dir=="v" then
        tri.PointA=Vector2.new(cx-4,cy-3); tri.PointB=Vector2.new(cx+4,cy-3); tri.PointC=Vector2.new(cx,cy+3)
    elseif dir=="^" then
        tri.PointA=Vector2.new(cx-4,cy+3); tri.PointB=Vector2.new(cx+4,cy+3); tri.PointC=Vector2.new(cx,cy-3)
    elseif dir==">" then
        tri.PointA=Vector2.new(cx-3,cy-4); tri.PointB=Vector2.new(cx-3,cy+4); tri.PointC=Vector2.new(cx+3,cy)
    end
end

local C = {
    BG      = Color3.fromRGB(9,  11, 20),
    SIDEBAR = Color3.fromRGB(12, 15, 27),
    CONTENT = Color3.fromRGB(11, 13, 23),
    TOPBAR  = Color3.fromRGB(7,  9,  17),
    ACCENT  = Color3.fromRGB(70, 120,255),
    TABSEL  = Color3.fromRGB(20, 35, 85),
    WHITE   = Color3.fromRGB(215,220,240),
    GRAY    = Color3.fromRGB(100,112,145),
    DIMGRAY = Color3.fromRGB(28, 33, 52),
    ON      = Color3.fromRGB(45, 85, 195),
    OFF     = Color3.fromRGB(20, 24, 42),
    ONDOT   = Color3.fromRGB(175,198,255),
    OFFDOT  = Color3.fromRGB(55, 65, 95),
    GREEN   = Color3.fromRGB(45, 190,95),
    RED     = Color3.fromRGB(210,55, 55),
    BORDER  = Color3.fromRGB(30, 40, 72),
    ROWBG   = Color3.fromRGB(14, 18, 33),
    DIV     = Color3.fromRGB(22, 27, 48),
    SHADOW  = Color3.fromRGB(0,  0,  5),
    ORANGE  = Color3.fromRGB(255,175,80),
    YELLOW  = Color3.fromRGB(190,148,0),
    MINIBAR = Color3.fromRGB(11, 13, 22),
}
UILib.Colors = C

local L = {
    W        = 440, H        = 400,
    SIDEBAR  = 128, TOPBAR   = 40,
    FOOTER   = 22,  ROW_H    = 40,
    ROW_PAD  = 10,  TOG_W    = 34,
    TOG_H    = 17,  HDL      = 8,
    MINI_H   = 86,
}
L.CONTENT_W = L.W - L.SIDEBAR

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
    t.Color=col or C.WHITE; t.Center=ctr or false; t.Outline=false
    t.Font=bold and Drawing.Fonts.SystemBold or Drawing.Fonts.System
    t.Transparency=1; t.ZIndex=zi or 3; t.Visible=true
    return t
end
local function mkLn(x1,y1,x2,y2,col,zi,thick)
    local l = Drawing.new("Line")
    l.From=Vector2.new(x1,y1); l.To=Vector2.new(x2,y2)
    l.Color=col or C.ACCENT; l.Transparency=1
    l.Thickness=thick or 1; l.ZIndex=zi or 2; l.Visible=true
    return l
end

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

-- Window constructor
function UILib.Window(titleA, titleB, gameName)
    local win = {}
    local mouse = game.Players.LocalPlayer:GetMouse()

    -- state
    local uiX, uiY       = 300, 200
    local dragging        = false
    local dragOffX, dragOffY = 0, 0
    local wasClicking     = false
    local currentTab      = nil
    local menuKey         = 0x70
    local listenKey       = false
    local destroyed       = false
    local isLoading       = true
    local wasMenuKey      = false
    local menuOpen        = true
    local menuToggledAt   = tick() - 1
    local FADE_DUR        = 0.4
    local TAB_FADE_DUR    = 0.2
    local tabSwitchedAt   = tick() - 1
    local prevTab         = nil
    local minimized       = false
    local miniClosed      = false
    local miniDragging    = false
    local miniDragOffX, miniDragOffY = 0, 0
    local miniFadeIn    = false
    local miniFadeOut   = false
    local miniFadedAt   = tick()-1
    local MINI_FADE_DUR = 0.25
    local glowPhase       = {0, math.pi*0.6}

    -- drawing registry
    local allDrawings = {}
    local showSet     = {}
    local tabSet      = {}
    local baseUI      = {}
    local tabObjs     = {}
    local btns        = {}
    local miniDrawings= {}
    local miniActiveLbls = {}
    local miniActivePulse= {}
    local MAX_MINI_LBLS  = 12
    for i=1,MAX_MINI_LBLS do
        local lb = mkTx("",0,0,13,C.WHITE,false,9,false)
        lb.Outline=true
        lb.Visible=false
        lb.Transparency=1
        table.insert(miniActiveLbls,lb)
        table.insert(miniActivePulse,i*0.7)
    end

    local function mkD(d)
        table.insert(allDrawings,d)
        d.Visible=false
        return d
    end
    local function setShow(d,yes)
        showSet[d]=yes or nil
        d.Visible=yes and true or false
    end
    local function inBox(x,y,w,h)
        return mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+h
    end

    local uiTargetH = L.H
    local uiCurrentH = L.H

    local function applyFade()
        if minimized then
            for _,d in ipairs(allDrawings) do d.Visible=false end
            return
        end
        if not minimized then
            for _,lb in ipairs(miniActiveLbls) do lb.Visible=false end
        end
        local mf=1-(menuToggledAt-(tick()-FADE_DUR))/FADE_DUR
        if not menuOpen and mf>=1.1 then
            for _,d in ipairs(allDrawings) do d.Visible=false end
            return
        end
        local mOp=mf<1.1
            and math.abs((menuOpen and 0 or 1)-clamp(mf,0,1))
            or  (menuOpen and 1 or 0)
        local tp=clamp((tick()-tabSwitchedAt)/TAB_FADE_DUR,0,1)
        for _,d in ipairs(allDrawings) do
            if showSet[d] then
                local tOp=tabSet[d]=="next" and tp or tabSet[d]=="prev" and (1-tp) or 1
                local op=mOp*tOp
                d.Visible=op>0.01
                d.Transparency=op
            else
                d.Visible=false
            end
        end
    end

    local function bShow(b,yes)
        setShow(b.bg,yes)
        if not b.isLog then setShow(b.lbl,yes) end
        if b.ln     then setShow(b.ln,    yes) end
        if b.tog    then setShow(b.tog,   yes) end
        if b.dot    then setShow(b.dot,   yes) end
        if b.track  then setShow(b.track, yes) end
        if b.fill   then setShow(b.fill,  yes) end
        if b.handle then setShow(b.handle,yes) end
        if b.lbls   then for _,l in ipairs(b.lbls) do setShow(l,yes) end end
        if b.qbg    then setShow(b.qbg,  yes) end
        if b.qlb    then setShow(b.qlb,  yes) end
        if b.dlb    then setShow(b.dlb,  yes) end
        if b.arrow  then setShow(b.arrow, yes) end
        if b.valLbl  then setShow(b.valLbl, yes) end
        if b.swatches then
            for _,sw in ipairs(b.swatches) do setShow(sw.sq,yes); setShow(sw.border,yes) end
        end
    end

    local function bPos(b)
        -- use animated currentRY if available, else ry
        local animY = b.currentRY ~= nil and b.currentRY or b.ry
        local ax,ay=uiX+b.rx,uiY+animY
        b.bg.Position=Vector2.new(ax,ay)
        if b.isLog then
            for i,lb in ipairs(b.lbls) do
                if b.starFirst and i==1 then
                    lb.Position=Vector2.new(ax+b.cw/2,ay+b.pad)
                else
                    local off=b.starFirst and (b.starH+b.pad+(i-2)*b.lineH) or (b.pad+(i-1)*b.lineH)
                    lb.Position=Vector2.new(ax+8,ay+off)
                end
            end
            return
        end
        if b.isDiv then
            b.lbl.Position=Vector2.new(ax+6,ay)
            if b.ln then b.ln.From=Vector2.new(ax,ay+13); b.ln.To=Vector2.new(ax+b.cw,ay+13) end
            if b.arrow then
                b.arrow.Position=Vector2.new(ax+b.cw-6,ay)
                b.arrow.Text=_collapseSections[b.sectionName] and ">" or "v"
            end
        elseif b.isAct then
            b.lbl.Position=Vector2.new(ax+b.cw/2,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
        elseif b.isDropdown then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.valLbl.Position=Vector2.new(ax+b.cw-60,ay+b.ch/2-6)
            b.arrow.Position=Vector2.new(ax+b.cw-14,ay+b.ch/2-6)
            b.arrow.Text=b.open and "^" or "v"
            for i,o in ipairs(b.optBgs) do
                local oy2=ay+b.ch+((i-1)*b.ch)
                o.bg.Position=Vector2.new(ax,oy2); o.bg.Size=Vector2.new(b.cw,b.ch)
                o.ln.From=Vector2.new(ax,oy2+b.ch); o.ln.To=Vector2.new(ax+b.cw,oy2+b.ch)
                o.lb.Position=Vector2.new(ax+10,oy2+b.ch/2-6)
                o.ry=b.ry+b.ch+((i-1)*b.ch)
            end
        elseif b.isColorPicker then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            local totalW=(#b.swatches*19)-5
            local startX=ax+b.cw-totalW-10
            for i,sw in ipairs(b.swatches) do
                local sx=startX+(i-1)*19; local sy=ay+b.ch/2-7
                sw.sq.Position=Vector2.new(sx,sy)
                sw.border.Position=Vector2.new(sx-1,sy-1)
                sw.x=sx; sw.y=sy
            end
        elseif b.isSlider then
            b.lbl.Position=Vector2.new(ax+8,ay+7)
            if b.dlb then b.dlb.Position=Vector2.new(ax+8,ay+21) end
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            local tx=ax+8; local ty=ay+b.ch-11
            b.track.From=Vector2.new(tx,ty); b.track.To=Vector2.new(tx+b.trackW,ty)
            local frac=(b.value-b.minV)/(b.maxV-b.minV)
            local fx=tx+frac*b.trackW
            b.fill.From=Vector2.new(tx,ty); b.fill.To=Vector2.new(fx,ty)
            b.handle.Position=Vector2.new(fx-4,ty-4)
        else
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            if b.tog then
                local dox=b.rx+b.cw-L.TOG_W-8
                local doy=b.ry+b.ch/2-L.TOG_H/2
                local dcy=b.currentRY or b.ry
                b.tog.Position=Vector2.new(uiX+dox, uiY+dcy+b.ch/2-L.TOG_H/2)
                b.dot.Position=Vector2.new(uiX+dox+2+(L.TOG_W-L.TOG_H)*b.lt, uiY+dcy+b.ch/2-L.TOG_H/2+2)
            end
            if b.qbg then
                local dox2=b.rx+b.cw-L.TOG_W-8
                local qx=uiX+dox2-22; local qy=uiY+(b.currentRY or b.ry)+b.ch/2-7
                b.qbg.Position=Vector2.new(qx,qy)
                if b.qlb then b.qlb.Position=Vector2.new(qx+7,qy+2) end
            end
        end
    end

    local function tagBtnFade(b,group)
        tabSet[b.bg]=group
        if not b.isLog then tabSet[b.lbl]=group end
        if b.ln     then tabSet[b.ln]=group    end
        if b.tog    then tabSet[b.tog]=group   end
        if b.dot    then tabSet[b.dot]=group   end
        if b.track  then tabSet[b.track]=group end
        if b.fill   then tabSet[b.fill]=group  end
        if b.handle then tabSet[b.handle]=group end
        if b.lbls   then for _,l in ipairs(b.lbls) do tabSet[l]=group end end
        if b.qbg    then tabSet[b.qbg]=group end
        if b.qlb    then tabSet[b.qlb]=group end
        if b.dlb    then tabSet[b.dlb]=group end
        if b.arrow  then tabSet[b.arrow]=group end
        if b.valLbl  then tabSet[b.valLbl]=group end
        -- optBgs are managed manually, not through applyFade
        if b.swatches then
            for _,sw in ipairs(b.swatches) do tabSet[sw.sq]=group; tabSet[sw.border]=group end
        end
    end

    local function showTab(tab)
        for _,b in ipairs(btns) do
            local yes=b.tab==tab; bShow(b,yes)
            if yes then bPos(b) end
        end
    end

    local function switchTab(name)
        if name==currentTab then return end
        prevTab=currentTab; currentTab=name; tabSwitchedAt=tick()
        for _,t in ipairs(tabObjs) do
            t.sel=t.name==name
            setShow(t.lbl,t.sel); setShow(t.lblG,not t.sel)
        end
        for _,d in ipairs(allDrawings) do tabSet[d]=nil end
        for _,b in ipairs(btns) do
            if b.tab==prevTab then bShow(b,true); bPos(b); tagBtnFade(b,"prev") end
        end
        -- reset collapse state for incoming tab so arrows show correctly
        for _,b in ipairs(btns) do
            if b.tab==name then
                if b.isDiv and b.collapsible and b.sectionName then
                    _collapseSections[b.sectionName]=false
                    if b.arrow then b.arrow.Text="v" end
                end
                b.ry=b.baseRY; b.currentRY=b.baseRY; b._collapsing=false; b._collapseTarget=nil  -- snap on tab switch
                bShow(b,true); bPos(b); tagBtnFade(b,"next")
            end
        end
    end

    local dShadow,dMainBg,dGlow1,dGlow2,dBorder
    local dTopBar,dTopFill,dTopLine
    local dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR
    local dSide,dSideLn,dContent,dFooter,dFotLine,dCharLbl
    local glowLines
    -- mini
    local dMiniShadow,dMiniBg,dMiniGlow1,dMiniGlow2,dMiniBorder
    local dMiniTopBar,dMiniTitleW,dMiniTitleA,dMiniTitleG
    local dMiniKeyLbl,dMiniDotG,dMiniDotR,dMiniDivLn,dMiniActiveBg
    local miniGlowLines
    -- settings btns
    local iKeyInfo, iKeyBind
    -- tooltip
    local tipBg, tipLbl, tipDesc
    local hoveredBtn = nil
    local tipFadeIn = false
    local tipFadeOut = false
    local tipFadedAt = tick()-1
    local TIP_FADE = 0.35

    local function updatePos()
        local curH = uiCurrentH  -- use animated/current height not fixed L.H
        dShadow.Position  =Vector2.new(uiX-2,uiY-2)
        dMainBg.Position  =Vector2.new(uiX,uiY)
        dBorder.Position  =Vector2.new(uiX,uiY)
        dGlow1.Position   =Vector2.new(uiX-1,uiY-1)
        dGlow2.Position   =Vector2.new(uiX-2,uiY-2)
        dTopBar.Position  =Vector2.new(uiX+1,uiY+1)
        dTopFill.Position =Vector2.new(uiX+1,uiY+L.TOPBAR-5)
        dTopLine.From     =Vector2.new(uiX+1,uiY+L.TOPBAR)
        dTopLine.To       =Vector2.new(uiX+L.W-1,uiY+L.TOPBAR)
        dTitleW.Position  =Vector2.new(uiX+14,uiY+12)
        dTitleA.Position  =Vector2.new(uiX+14+(#titleA*9)+6,uiY+12)
        dTitleG.Position  =Vector2.new(uiX+14+(#titleA*9)+6+(#titleB*9)-24,uiY+12)
        dKeyLbl.Position  =Vector2.new(uiX+L.W-22,uiY+14)
        dDotY.Position    =Vector2.new(uiX+L.W-55,uiY+15)
        dDotR.Position    =Vector2.new(uiX+L.W-42,uiY+15)
        dSide.Position    =Vector2.new(uiX+1,uiY+L.TOPBAR)
        dSideLn.From      =Vector2.new(uiX+L.SIDEBAR,uiY+L.TOPBAR)
        dSideLn.To        =Vector2.new(uiX+L.SIDEBAR,uiY+curH-L.FOOTER)
        dContent.Position =Vector2.new(uiX+L.SIDEBAR,uiY+L.TOPBAR)
        dFooter.Position  =Vector2.new(uiX+1,uiY+curH-L.FOOTER)
        dFotLine.From     =Vector2.new(uiX+1,uiY+curH-L.FOOTER)
        dFotLine.To       =Vector2.new(uiX+L.W-1,uiY+curH-L.FOOTER)
        dCharLbl.Position =Vector2.new(uiX+L.SIDEBAR+8,uiY+curH-L.FOOTER+5)
        -- update sizes for width changes
        dTopBar.Size  =Vector2.new(L.W-2,L.TOPBAR)
        dTopFill.Size =Vector2.new(L.W-2,7)
        dSide.Size    =Vector2.new(L.SIDEBAR-1,curH-L.TOPBAR-L.FOOTER-1)
        dContent.Size =Vector2.new(L.CONTENT_W-1,curH-L.TOPBAR-L.FOOTER-1)
        dFooter.Size  =Vector2.new(L.W-2,L.FOOTER-1)
        for _,t in ipairs(tabObjs) do
            t.bg.Position =Vector2.new(uiX+7,uiY+t.relTY)
            t.acc.Position=Vector2.new(uiX+7,uiY+t.relTY)
            t.lbl.Position=Vector2.new(uiX+18,uiY+t.relTY+7)
            t.lblG.Position=Vector2.new(uiX+18,uiY+t.relTY+7)
        end
        for _,b in ipairs(btns) do
            if showSet[b.bg] then bPos(b) end
        end
    end

    local function updateMiniPos()
        dMiniShadow.Position =Vector2.new(uiX-2,uiY-2)
        dMiniShadow.Size     =Vector2.new(L.W+4,L.MINI_H+4)
        dMiniBg.Position     =Vector2.new(uiX,uiY)
        dMiniBg.Size         =Vector2.new(L.W,L.MINI_H)
        dMiniGlow1.Position  =Vector2.new(uiX-1,uiY-1)
        dMiniGlow1.Size      =Vector2.new(L.W+2,L.MINI_H+2)
        dMiniGlow2.Position  =Vector2.new(uiX-2,uiY-2)
        dMiniGlow2.Size      =Vector2.new(L.W+4,L.MINI_H+4)
        dMiniBorder.Position =Vector2.new(uiX,uiY)
        dMiniBorder.Size     =Vector2.new(L.W,L.MINI_H)
        dMiniTopBar.Position =Vector2.new(uiX+1,uiY+1)
        dMiniTitleW.Position =Vector2.new(uiX+14,uiY+12)
        dMiniTitleA.Position =Vector2.new(uiX+14+(#titleA*9)+6,uiY+12)
        dMiniTitleG.Position =Vector2.new(uiX+14+(#titleA*9)+6+(#titleB*9)-24,uiY+12)
        dMiniKeyLbl.Position =Vector2.new(uiX+L.W-22,uiY+14)
        dMiniDotG.Position   =Vector2.new(uiX+L.W-55,uiY+15)
        dMiniDotR.Position   =Vector2.new(uiX+L.W-42,uiY+15)
        dMiniDivLn.From      =Vector2.new(uiX+1,uiY+L.TOPBAR)
        dMiniDivLn.To        =Vector2.new(uiX+L.W-1,uiY+L.TOPBAR)
        dMiniActiveBg.Position=Vector2.new(uiX+1,uiY+L.TOPBAR)
        dMiniActiveBg.Size   =Vector2.new(L.W-2,L.MINI_H-L.TOPBAR-1)
        -- reposition labels
        local PAD=10; local SEP=14; local charW=7
        local ROW_H2=18
        local ROW1_Y=uiY+L.TOPBAR+6
        local ROW2_Y=uiY+L.TOPBAR+6+ROW_H2
        local curX=uiX+PAD; local row=1
        for _,lb in ipairs(miniActiveLbls) do
            if lb.Visible and lb.Text~="" then
                local w=#lb.Text*charW
                if curX+w>uiX+L.W-PAD then
                    if row==1 then row=2; curX=uiX+PAD else break end
                end
                lb.Position=Vector2.new(curX,row==1 and ROW1_Y or ROW2_Y)
                curX=curX+w+SEP
            end
        end
    end

    local function showMiniUI(show)
        if show then
            for _,d in ipairs(miniDrawings) do d.Visible=true; d.Transparency=1 end
            for _,l in ipairs(miniActiveLbls) do if l.Text~="" then l.Visible=true; l.Transparency=1 end end
        else
            for _,d in ipairs(miniDrawings) do d.Visible=false end
            for _,l in ipairs(miniActiveLbls) do l.Visible=false end
        end
        miniFadeIn=false; miniFadeOut=false
    end

    local function refreshMiniLabels()
        local active={}
        for _,b in ipairs(btns) do
            if b.isTog and b.state then table.insert(active,b.toggleName) end
        end
        if #active==0 then
            miniActiveLbls[1].Text="no active toggles"
            miniActiveLbls[1].Position=Vector2.new(uiX+10, uiY+L.TOPBAR+6)
            miniActiveLbls[1].Visible=true
            for i=2,MAX_MINI_LBLS do miniActiveLbls[i].Text=""; miniActiveLbls[i].Visible=false end
            return
        end
        local PAD=10; local SEP=14; local charW=7
        local ROW_H2=18
        local ROW1_Y=uiY+L.TOPBAR+6
        local ROW2_Y=uiY+L.TOPBAR+6+ROW_H2
        local slots={}
        local curX=uiX+PAD; local row=1
        for _,name in ipairs(active) do
            local w=#name*charW
            if curX+w>uiX+L.W-PAD then
                if row==1 then row=2; curX=uiX+PAD else break end
            end
            table.insert(slots,{name=name,x=curX,y=(row==1 and ROW1_Y or ROW2_Y)})
            curX=curX+w+SEP
        end
        for i,lb in ipairs(miniActiveLbls) do
            if slots[i] then
                lb.Text=slots[i].name
                lb.Position=Vector2.new(slots[i].x,slots[i].y)
                lb.Visible=true
            else
                lb.Text=""; lb.Visible=false
            end
        end
    end

    local function restoreFullMenu()
        minimized=false; miniClosed=false
        showMiniUI(false)
        for _,d in ipairs(allDrawings) do d.Visible=false end
        for _,d in ipairs(allDrawings) do tabSet[d]=nil end
        for _,d in ipairs(baseUI) do setShow(d,true) end
        for _,t in ipairs(tabObjs) do
            setShow(t.bg,true); setShow(t.acc,true)
            setShow(t.lbl,t.sel); setShow(t.lblG,not t.sel)
        end
        showTab(currentTab)
        updatePos()
        menuOpen=true; menuToggledAt=tick()-FADE_DUR-0.01
    end

    local function addToggle(tab,lbl,relY,init,cb,desc)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local ox=rx+cw-L.TOG_W-8; local oy=ry+ch/2-L.TOG_H/2
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local tog =mkD(mkSq(uiX+ox,uiY+oy,L.TOG_W,L.TOG_H,init and C.ON or C.OFF,true,1,4,nil,L.TOG_H))
        local dot =mkD(mkSq(uiX+ox+(init and L.TOG_W-L.TOG_H+2 or 2),uiY+oy+2,L.TOG_H-4,L.TOG_H-4,init and C.ONDOT or C.OFFDOT,true,1,5,nil,L.TOG_H))
        -- ? badge (only if desc provided)
        local qbg, qlb
        if desc then
            local qx=uiX+ox-22; local qy=uiY+ry+ch/2-7 -- ? badge Y: change ch/2-7 to raise/lower
            qbg=mkD(mkSq(qx,qy,14,14,Color3.fromRGB(16,20,38),true,1,6,nil,3))
            qlb=mkD(mkTx("?",qx+7,qy+2,9,C.GRAY,true,7,true))
        end
        local b={tab=tab,isTog=true,state=init,bg=bg,lbl=lb,ln=dl,tog=tog,dot=dot,
                 rx=rx,ry=ry,baseRY=ry,currentRY=ry,cw=cw,ch=ch,ox=ox,oy=oy,lt=init and 1 or 0,cb=cb,toggleName=lbl,
                 desc=desc,qbg=qbg,qlb=qlb,qox=ox-22,qch=ch}
        table.insert(btns,b); return #btns
    end

    local function addDiv(tab,lbl,relY,collapsible)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2
        local lb=mkD(mkTx(lbl,uiX+rx+6,uiY+ry,9,C.GRAY,false,8))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13,C.DIV,4,1))
        local arrow
        if collapsible then
            arrow=mkD(mkTx("v",uiX+rx+cw-6,uiY+ry,9,C.GRAY,false,8))
            if _collapseSections[lbl]==nil then _collapseSections[lbl]=false end
        end
        local db={tab=tab,isDiv=true,bg=lb,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=14,
                  collapsible=collapsible,sectionName=lbl,arrow=arrow,currentRY=ry,baseRY=ry}
        table.insert(btns,db); return #btns
    end

    local function addAct(tab,lbl,relY,col,cb,lblCol)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,col or C.ROWBG,true,1,3,nil,4))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb=mkD(mkTx(lbl,uiX+rx+cw/2,uiY+ry+ch/2-6,12,lblCol or C.WHITE,true,8))
        local b={tab=tab,isAct=true,bg=bg,lbl=lb,ln=dl,rx=rx,ry=ry,baseRY=ry,currentRY=ry,cw=cw,ch=ch,cb=cb}
        table.insert(btns,b); return #btns
    end

    local function addSlider(tab,lbl,relY,minV,maxV,initV,cb,isFloat,desc)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H+6
        local trackW=cw-16
        local initLbl=isFloat and string.format("%.1f",initV) or math.floor(initV)
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl..": "..initLbl,uiX+rx+8,uiY+ry+7,12,C.WHITE,false,8))
        local dlb = desc and mkD(mkTx(desc,uiX+rx+8,uiY+ry+21,9,C.GRAY,false,8)) or nil
        local ty  =uiY+ry+ch-11
        local trk =mkD(mkLn(uiX+rx+8,ty,uiX+rx+8+trackW,ty,C.DIMGRAY,5,3))
        local frac=(initV-minV)/(maxV-minV)
        local fx  =uiX+rx+8+frac*trackW
        local fil =mkD(mkLn(uiX+rx+8,ty,fx,ty,C.ACCENT,6,3))
        local hdl =mkD(mkSq(fx-4,ty-4,L.HDL,L.HDL,C.WHITE,true,1,7,nil,3))
        local b={tab=tab,isSlider=true,bg=bg,lbl=lb,ln=dl,track=trk,fill=fil,handle=hdl,
                 rx=rx,ry=ry,baseRY=ry,currentRY=ry,cw=cw,ch=ch,trackW=trackW,minV=minV,maxV=maxV,
                 value=initV,baseLbl=lbl,dragging=false,cb=cb,isFloat=isFloat or false,dlb=dlb}
        table.insert(btns,b); return #btns
    end

    local function addColorPicker(tab,lbl,relY,initCol,cb)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local swatchW=14; local swatchH=14; local swatchPad=5
        local swatches={
            Color3.fromRGB(70,120,255),  -- blue (accent)
            Color3.fromRGB(210,55,55),   -- red
            Color3.fromRGB(45,190,95),   -- green
            Color3.fromRGB(255,175,80),  -- orange
            Color3.fromRGB(180,80,255),  -- purple
            Color3.fromRGB(215,220,240), -- white
        }
        local totalW=(#swatches*(swatchW+swatchPad))-swatchPad
        local startX=uiX+rx+cw-totalW-10
        local swatchBgs={}
        local selected=1
        for i,col in ipairs(swatches) do
            local sx=startX+(i-1)*(swatchW+swatchPad)
            local sy=uiY+ry+ch/2-swatchH/2
            local s=mkD(mkSq(sx,sy,swatchW,swatchH,col,true,1,6,nil,3))
            local border=mkD(mkSq(sx-1,sy-1,swatchW+2,swatchH+2,i==1 and C.WHITE or C.BORDER,false,1,7,1,3))
            table.insert(swatchBgs,{sq=s,border=border,col=col,x=sx,y=sy})
        end
        local b={tab=tab,isColorPicker=true,bg=bg,lbl=lb,ln=dl,
                 rx=rx,ry=ry,baseRY=ry,currentRY=ry,cw=cw,ch=ch,swatches=swatchBgs,
                 selected=selected,value=swatches[1],cb=cb}
        table.insert(btns,b); return #btns
    end




    local openDropdown = nil
    local UI_RESIZE_SPD = 12 -- lerp speed

    local function applyWindowH(h)
        if not dMainBg then return end
        dMainBg.Size=Vector2.new(L.W,h)
        dShadow.Size=Vector2.new(L.W+4,h+4)
        dGlow1.Size=Vector2.new(L.W+2,h+2)
        dGlow2.Size=Vector2.new(L.W+4,h+4)
        dBorder.Size=Vector2.new(L.W,h)
        dSide.Size=Vector2.new(L.SIDEBAR-1,h-L.TOPBAR-L.FOOTER-1)
        dContent.Size=Vector2.new(L.CONTENT_W-1,h-L.TOPBAR-L.FOOTER-1)
        dFooter.Position=Vector2.new(uiX+1,uiY+h-L.FOOTER)
        dFotLine.From=Vector2.new(uiX+1,uiY+h-L.FOOTER)
        dFotLine.To=Vector2.new(uiX+L.W-1,uiY+h-L.FOOTER)
        dSideLn.To=Vector2.new(uiX+L.SIDEBAR,uiY+h-L.FOOTER)
        dCharLbl.Position=Vector2.new(uiX+L.SIDEBAR+8,uiY+h-L.FOOTER+5)
    end

    local function resizeForDropdown(dd, expanding)
        local extra = expanding and (#dd.options * dd.ch) or 0
        uiTargetH = L.H + extra
    end

    local function addDropdown(tab,lbl,relY,options,initIdx,cb)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local valIdx=initIdx or 1
        local val=mkD(mkTx(options[valIdx] or "",uiX+rx+cw-60,uiY+ry+ch/2-6,11,C.ACCENT,false,8))
        local arrow=mkD(mkTx("v",uiX+rx+cw-14,uiY+ry+ch/2-6,9,C.GRAY,false,8))
        local optBgs={}
        for i,opt in ipairs(options) do
            local oy2=ry+ch+((i-1)*ch)
            -- use raw drawings (not mkD) so applyFade doesn't touch them
            local obg=mkSq(uiX+rx,uiY+oy2,cw,ch,C.ROWBG,true,0,10,nil,0)
            local oln=mkLn(uiX+rx,uiY+oy2+ch,uiX+rx+cw,uiY+oy2+ch,C.DIV,11,1)
            local olb=mkTx(opt,uiX+rx+14,uiY+oy2+ch/2-6,11,i==valIdx and C.ACCENT or C.WHITE,false,11)
            obg.Visible=false; oln.Visible=false; olb.Visible=false
            table.insert(optBgs,{bg=obg,ln=oln,lb=olb,ry=oy2,alpha=0,targetAlpha=0})
        end
        local b={tab=tab,isDropdown=true,bg=bg,lbl=lb,ln=dl,valLbl=val,arrow=arrow,currentRY=ry,baseRY=ry,
                 rx=rx,ry=ry,cw=cw,ch=ch,options=options,optBgs=optBgs,
                 selected=valIdx,open=false,openedAt=0,cb=cb}
        table.insert(btns,b); return #btns
    end

    local function addLog(tab,lines,relY,starFirst)
        local rx=L.SIDEBAR+L.ROW_PAD
        local cw=L.CONTENT_W-L.ROW_PAD*2
        local lineH=18; local starH=starFirst and 26 or 0; local pad=10
        local ch=starH+(#lines-(starFirst and 1 or 0))*lineH+pad*2
        local ry=L.TOPBAR+relY
        local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,6))
        local lbls={}
        for i,line in ipairs(lines) do
            local lb=mkD(Drawing.new("Text"))
            if starFirst and i==1 then
                lb.Text=line; lb.Position=Vector2.new(uiX+rx+cw/2,uiY+ry+pad)
                lb.Size=14; lb.Color=Color3.fromRGB(255,200,40); lb.Center=true
                lb.Outline=true; lb.Font=Drawing.Fonts.Minecraft
            else
                local off=starFirst and (starH+pad+(i-2)*lineH) or (pad+(i-1)*lineH)
                lb.Text=line; lb.Position=Vector2.new(uiX+rx+8,uiY+ry+off)
                lb.Size=11; lb.Color=C.WHITE; lb.Center=false
                lb.Outline=true; lb.Font=Drawing.Fonts.Minecraft
            end
            lb.Transparency=1; lb.ZIndex=8; lb.Visible=false
            table.insert(lbls,lb)
        end
        local b={tab=tab,isLog=true,bg=bg,lbl=bg,ln=nil,lbls=lbls,
                 rx=rx,ry=ry,baseRY=ry,currentRY=ry,cw=cw,ch=ch,lines=lines,lineH=lineH,pad=pad,
                 starFirst=starFirst,starH=starH}
        table.insert(btns,b); return #btns
    end

    local tabAPI = {}
    local tabRowY = {}  -- tracks current Y offset per tab
    local tabScroll = {}  -- scroll offset per tab (pixels)
    local function CONTENT_H() return uiCurrentH - L.TOPBAR - L.FOOTER end

    local function getTabAPI(tabName)
        if tabAPI[tabName] then return tabAPI[tabName] end
        local api = {}
        tabRowY[tabName] = 6

        local function nextY(h)
            local y = tabRowY[tabName]
            tabRowY[tabName] = y + h
            return y
        end

        function api:Div(lbl, collapsible)
            local idx = addDiv(tabName, lbl, nextY(20), collapsible)
            if collapsible then
                -- track which btns belong to this section
                btns[idx]._sectionStart = idx
            end
        end
        function api:Toggle(lbl, init, cb, desc)
            local y = nextY(L.ROW_H + 2)
            addToggle(tabName, lbl, y, init, cb, desc)
        end
        function api:Slider(lbl, minV, maxV, initV, cb, isFloat, desc)
            local y = nextY(L.ROW_H + 8)
            addSlider(tabName, lbl, y, minV, maxV, initV, cb, isFloat, desc)
        end
        function api:Button(lbl, col, cb, lblCol)
            local y = nextY(L.ROW_H + 2)
            return addAct(tabName, lbl, y, col, cb, lblCol)
        end
        function api:ColorPicker(lbl, initCol, cb)
            local y = nextY(L.ROW_H + 2)
            addColorPicker(tabName, lbl, y, initCol, cb)
        end
        function api:Dropdown(lbl, options, initIdx, cb)
            local y = nextY(L.ROW_H + 2)
            addDropdown(tabName, lbl, y, options, initIdx, cb)
        end
        function api:Log(lines, starFirst)
            local lineH = 18
            local starH = starFirst and 26 or 0
            local h = starH + (#lines - (starFirst and 1 or 0)) * lineH + 20 + 6
            local y = nextY(h)
            addLog(tabName, lines, y, starFirst)
        end
        tabAPI[tabName] = api
        return api
    end

    local function applyTheme(name)
        local t=THEMES[name]; if not t then return end
        C.ACCENT=t.ACCENT;  C.BG=t.BG;       C.SIDEBAR=t.SIDEBAR
        C.CONTENT=t.CONTENT; C.TOPBAR=t.TOPBAR; C.BORDER=t.BORDER
        C.ROWBG=t.ROWBG;    C.TABSEL=t.TABSEL
        if t.WHITE   then C.WHITE=t.WHITE     end
        if t.GRAY    then C.GRAY=t.GRAY       end
        if t.DIMGRAY then C.DIMGRAY=t.DIMGRAY end
        if t.ON      then C.ON=t.ON           end
        if t.OFF     then C.OFF=t.OFF         end
        if t.ONDOT   then C.ONDOT=t.ONDOT     end
        if t.OFFDOT  then C.OFFDOT=t.OFFDOT   end
        if t.DIV     then C.DIV=t.DIV         end
        if t.MINIBAR then C.MINIBAR=t.MINIBAR   end
        if dMainBg then
            -- main window
            dMainBg.Color=C.BG;     dMiniBg.Color=C.BG
            dTopBar.Color=C.TOPBAR; dMiniTopBar.Color=C.TOPBAR
            dSide.Color=C.SIDEBAR;  dContent.Color=C.CONTENT
            dFooter.Color=C.TOPBAR
            dBorder.Color=C.BORDER; dMiniBorder.Color=C.BORDER
            dTopLine.Color=C.BORDER; dMiniDivLn.Color=C.BORDER
            dSideLn.Color=C.BORDER; dFotLine.Color=C.BORDER
            -- title text
            dTitleA.Color=C.ACCENT;     dMiniTitleA.Color=C.ACCENT
            dTitleW.Color=C.WHITE;      dMiniTitleW.Color=C.WHITE
            dTitleG.Color=C.ORANGE;     dMiniTitleG.Color=C.ORANGE
            dKeyLbl.Color=C.GRAY;       dMiniKeyLbl.Color=C.GRAY
            dCharLbl.Color=C.GRAY
            -- mini bar active bg
            if dMiniActiveBg then dMiniActiveBg.Color=C.MINIBAR end
            -- mini active labels
            for _,lb in ipairs(miniActiveLbls) do lb.Color=C.WHITE end
            -- tabs
            for _,t2 in ipairs(tabObjs) do
                t2.bg.Color=t2.sel and C.TABSEL or C.SIDEBAR
                t2.acc.Color=t2.sel and C.ACCENT or C.SIDEBAR
                t2.lbl.Color=C.WHITE; t2.lblG.Color=C.GRAY
            end
            -- widgets
            for _,b in ipairs(btns) do
                if b.bg and not b.isDiv then b.bg.Color=C.ROWBG end
                if b.ln then b.ln.Color=C.DIV end
                if b.isTog then
                    b.lbl.Color=C.WHITE
                    b.tog.Color=b.state and C.ON or C.OFF
                    b.dot.Color=b.state and C.ONDOT or C.OFFDOT
                    if b.qlb  then b.qlb.Color=C.GRAY end
                    if b.qbg  then b.qbg.Color=Color3.fromRGB(16,20,38) end
                elseif b.isSlider then
                    b.lbl.Color=C.WHITE
                    if b.dlb   then b.dlb.Color=C.GRAY end
                    if b.track then b.track.Color=C.DIMGRAY end
                elseif b.isAct then
                    -- button color stays as set, only update if default
                elseif b.isDiv then
                    b.lbl.Color=C.GRAY
                    if b.ln    then b.ln.Color=C.DIV end
                    if b.arrow then b.arrow.Color=C.GRAY end
                elseif b.isDropdown then
                    b.lbl.Color=C.WHITE
                    b.arrow.Color=C.GRAY
                    b.valLbl.Color=C.ACCENT
                    for j,o in ipairs(b.optBgs) do
                        o.bg.Color=C.ROWBG
                        o.ln.Color=C.DIV
                        o.lb.Color=j==b.selected and C.ACCENT or C.WHITE
                    end
                elseif b.isColorPicker then
                    b.lbl.Color=C.WHITE
                elseif b.isLog then
                    -- log colors stay as-is
                end
            end
        end
    end

    function win:Init(defaultTab, charLabelFn, notifFn)
        local notif = notifFn or function(msg,title,dur)
            pcall(function() notify(msg, title or titleA.." "..titleB, dur or 3) end)
        end

        -- build base UI
        dShadow  = mkD(mkSq(uiX-2,uiY-2,L.W+4,L.H+4,   C.SHADOW,true,0.5,0,nil,12))
        dMainBg  = mkD(mkSq(uiX,uiY,L.W,L.H,            C.BG,    true,1,1,nil,10))
        dGlow1   = mkD(mkSq(uiX-1,uiY-1,L.W+2,L.H+2,   C.ACCENT,false,0.9,1,1,11))
        dGlow2   = mkD(mkSq(uiX-2,uiY-2,L.W+4,L.H+4,   C.ACCENT,false,0.35,0,2,12))
        glowLines= {dGlow1,dGlow2}
        dBorder  = mkD(mkSq(uiX,uiY,L.W,L.H,            C.BORDER,false,0.2,3,1,10))
        dTopBar  = mkD(mkSq(uiX+1,uiY+1,L.W-2,L.TOPBAR, C.TOPBAR,true,1,3,nil,9))
        dTopFill = mkD(mkSq(uiX+1,uiY+L.TOPBAR-5,L.W-2,7,C.TOPBAR,true,1,3))
        dTopLine = mkD(mkLn(uiX+1,uiY+L.TOPBAR,uiX+L.W-1,uiY+L.TOPBAR,C.BORDER,4,1))
        dTitleW  = mkD(mkTx(titleA,  uiX+14,     uiY+12,14,C.WHITE, false,9,true))
        dTitleA  = mkD(mkTx(titleB,  uiX+14+(#titleA*9)+6, uiY+12,14,C.ACCENT,false,9,true))
        local gameNameShort = gameName or ""
        local titlesEndX = 14+(#titleA*9)+6+(#titleB*9)-24
        dTitleG  = mkD(mkTx(gameNameShort,uiX+titlesEndX, uiY+12,13,C.ORANGE,false,9,false))
        dKeyLbl  = mkD(mkTx("F1",    uiX+L.W-22, uiY+14,11,C.GRAY,  false,9))
        dDotY    = mkD(mkSq(uiX+L.W-55,uiY+15,8,8,C.YELLOW,true,1,9,nil,3))
        dDotR    = mkD(mkSq(uiX+L.W-42,uiY+15,8,8,Color3.fromRGB(170,44,44),true,1,9,nil,3))
        dSide    = mkD(mkSq(uiX+1,uiY+L.TOPBAR,L.SIDEBAR-1,L.H-L.TOPBAR-L.FOOTER-1,C.SIDEBAR,true,1,2,nil,8))
        dSideLn  = mkD(mkLn(uiX+L.SIDEBAR,uiY+L.TOPBAR,uiX+L.SIDEBAR,uiY+L.H-L.FOOTER,C.BORDER,4,1))
        dContent = mkD(mkSq(uiX+L.SIDEBAR,uiY+L.TOPBAR,L.CONTENT_W-1,L.H-L.TOPBAR-L.FOOTER-1,C.CONTENT,true,1,2,nil,8))
        dFooter  = mkD(mkSq(uiX+1,uiY+L.H-L.FOOTER,L.W-2,L.FOOTER-1,C.TOPBAR,true,1,3,nil,6))
        dFotLine = mkD(mkLn(uiX+1,uiY+L.H-L.FOOTER,uiX+L.W-1,uiY+L.H-L.FOOTER,C.BORDER,4,1))
        dCharLbl = mkD(mkTx("",uiX+L.SIDEBAR+8,uiY+L.H-L.FOOTER+5,10,C.GRAY,false,9))


        -- tooltip drawings (above everything, zi=12)
        tipBg   = mkSq(0,0,10,10,Color3.fromRGB(10,13,24),true,1,12,nil,4)
        pcall(function() tipBg.Corner=4 end)
        tipBg.Visible=false
        local tipBorder=mkSq(0,0,10,10,C.ACCENT,false,0.7,12,1,4)
        pcall(function() tipBorder.Corner=4 end)
        tipBorder.Visible=false
        tipLbl  = mkTx("",0,0,11,Color3.fromRGB(70,120,255),false,13,true)
        tipLbl.Visible=false
        tipDesc = mkTx("",0,0,10,Color3.fromRGB(130,140,170),false,13,false)
        tipDesc.Visible=false

        baseUI={dShadow,dGlow2,dGlow1,dMainBg,dBorder,dTopBar,dTopFill,dTopLine,
                dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR,dSide,dSideLn,dContent,
                dFooter,dFotLine,dCharLbl}
        for _,d in ipairs(baseUI) do setShow(d,true) end

        -- build tabs in sidebar
        local tabNames = {}
        for name,_ in pairs(tabAPI) do table.insert(tabNames,name) end
        for i,name in ipairs(win._tabOrder) do
            local relTY=L.TOPBAR+8+(i-1)*34
            local isSel=name==defaultTab
            local tbg =mkD(mkSq(uiX+7,uiY+relTY,L.SIDEBAR-14,26,isSel and C.TABSEL or C.SIDEBAR,true,1,3,nil,5))
            local tacc=mkD(mkSq(uiX+7,uiY+relTY,3,26,isSel and C.ACCENT or C.SIDEBAR,true,1,4,nil,2))
            local tlW =mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C.WHITE,false,8))
            local tlG =mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C.GRAY, false,8))
            setShow(tbg,true); setShow(tacc,true)
            setShow(tlW,isSel); setShow(tlG,not isSel)
            table.insert(tabObjs,{bg=tbg,acc=tacc,lbl=tlW,lblG=tlG,name=name,sel=isSel,lt=isSel and 1 or 0,relTY=relTY})
        end

        -- mini UI
        dMiniShadow  = mkSq(uiX-2,uiY-2,L.W+4,L.MINI_H+4,C.SHADOW,true,0.5,0,nil,12)
        dMiniBg      = mkSq(uiX,uiY,L.W,L.MINI_H,         C.BG,    true,1,1,nil,10)
        dMiniGlow1   = mkSq(uiX-1,uiY-1,L.W+2,L.MINI_H+2, C.ACCENT,false,0.9,1,1,11)
        dMiniGlow2   = mkSq(uiX-2,uiY-2,L.W+4,L.MINI_H+4, C.ACCENT,false,0.35,0,2,12)
        miniGlowLines= {dMiniGlow1,dMiniGlow2}
        dMiniBorder  = mkSq(uiX,uiY,L.W,L.MINI_H,         C.BORDER,false,0.2,3,1,10)
        dMiniTopBar  = mkSq(uiX+1,uiY+1,L.W-2,L.TOPBAR,   C.TOPBAR,true,1,3,nil,9)
        dMiniTitleW  = mkTx(titleA,  uiX+14,    uiY+12,14,C.WHITE, false,9,true)
        dMiniTitleA  = mkTx(titleB,  uiX+14+(#titleA*9)+6, uiY+12,14,C.ACCENT,false,9,true)
        dMiniTitleG  = mkTx(gameNameShort,uiX+titlesEndX,  uiY+12,13,C.ORANGE,false,9,false)
        dMiniKeyLbl  = mkTx("F1",    uiX+L.W-22,uiY+14,11,C.GRAY,  false,9)
        dMiniDotG    = mkSq(uiX+L.W-55,uiY+15,8,8,C.GREEN,true,1,9,nil,3)
        dMiniDotR    = mkSq(uiX+L.W-42,uiY+15,8,8,Color3.fromRGB(170,44,44),true,1,9,nil,3)
        dMiniDivLn   = mkLn(uiX+1,uiY+L.TOPBAR,uiX+L.W-1,uiY+L.TOPBAR,C.BORDER,4,1)
        dMiniActiveBg= mkSq(uiX+1,uiY+L.TOPBAR,L.W-2,L.MINI_H-L.TOPBAR-1,C.MINIBAR,true,1,2,nil,8)
        pcall(function() dMiniShadow.Corner=12 end)
        pcall(function() dMiniBg.Corner=10 end)
        pcall(function() dMiniGlow1.Corner=11 end)
        pcall(function() dMiniGlow2.Corner=12 end)
        pcall(function() dMiniBorder.Corner=10 end)
        miniDrawings={dMiniShadow,dMiniBg,dMiniGlow2,dMiniGlow1,dMiniBorder,
                      dMiniTopBar,dMiniTitleW,dMiniTitleA,dMiniTitleG,
                      dMiniKeyLbl,dMiniDotG,dMiniDotR,dMiniDivLn,dMiniActiveBg}
        for _,d in ipairs(miniDrawings) do d.Visible=false end

        currentTab=defaultTab
        showTab(defaultTab)
        notif("Loaded on "..(gameName or ""),"Check it Interface",4)

        -- Init loader (Appealing Animated Version)
        spawn(function()
            local dBg = Drawing.new("Square")
            dBg.Filled=true; dBg.ZIndex=15; dBg.Color=C.BG
            
            local dTxt = Drawing.new("Text")
            dTxt.Size=14; dTxt.Color=C.WHITE; dTxt.Center=true; dTxt.Outline=true; dTxt.ZIndex=16
            pcall(function() dTxt.Font=Drawing.Fonts.UI end)
            
            local dBarBg = Drawing.new("Square")
            dBarBg.Filled=true; dBarBg.ZIndex=16; dBarBg.Color=Color3.fromRGB(20, 20, 25)

            local dBarFg = Drawing.new("Square")
            dBarFg.Filled=true; dBarFg.ZIndex=17; dBarFg.Color=C.ACCENT
            
            local function setLoadPos(alpha, text, fillAmt)
                dBg.Position = Vector2.new(uiX, uiY); dBg.Size = Vector2.new(L.W, L.H)
                dBg.Transparency = alpha
                
                dTxt.Position = Vector2.new(uiX + L.W/2, uiY + L.H/2 - 20)
                dTxt.Text = text
                dTxt.Transparency = alpha
                
                local bw = 200; local bh = 4
                local bx = uiX + L.W/2 - bw/2; local by = uiY + L.H/2 + 5
                
                dBarBg.Position = Vector2.new(bx, by); dBarBg.Size = Vector2.new(bw, bh)
                dBarBg.Transparency = alpha
                
                dBarFg.Position = Vector2.new(bx, by); dBarFg.Size = Vector2.new(bw * fillAmt, bh)
                dBarFg.Transparency = alpha

                dBg.Visible = alpha>0; dTxt.Visible = alpha>0
                dBarBg.Visible = alpha>0; dBarFg.Visible = alpha>0
            end

            -- Fade In
            local t0 = tick(); local durIn = 0.2
            while tick()-t0 < durIn and not destroyed do
                task.wait()
                setLoadPos((tick()-t0)/durIn, "Preparing...", 0)
            end

            -- Loading Bar Animation
            local t1 = tick(); local durLoad = 1.2
            while tick()-t1 < durLoad and not destroyed do
                task.wait()
                local ext = math.floor((tick()*3)%4)
                setLoadPos(1, "Loading "..(gameName or "Check it")..string.rep(".", ext), (tick()-t1)/durLoad)
            end

            -- Fade Out
            local t2 = tick(); local durOut = 0.3
            while tick()-t2 < durOut and not destroyed do
                task.wait()
                setLoadPos(1 - ((tick()-t2)/durOut), "Ready!", 1)
            end
            
            pcall(function() dBg:Remove() end)
            pcall(function() dTxt:Remove() end)
            pcall(function() dBarBg:Remove() end)
            pcall(function() dBarFg:Remove() end)
            isLoading = false
        end)

        spawn(function()
        while not destroyed do
            task.wait()
            local _rbxOk, _rbxActive = pcall(function() return isrbxactive() end)
            if not _rbxOk or _rbxActive then
                local clicking=ismouse1pressed()

            local keyDown=iskeypressed(menuKey)
            if keyDown and not wasMenuKey then
                if miniClosed then
                    miniClosed=false
                    refreshMiniLabels()
                    showMiniUI(true)
                    updateMiniPos()
                    for _,lb in ipairs(miniActiveLbls) do if lb.Text~="" then lb.Visible=true end end
                elseif minimized then
                    showMiniUI(false)
                    miniClosed=true
                    for _,d in ipairs(allDrawings) do d.Visible=false end
                else
                    menuOpen=not menuOpen; menuToggledAt=tick()
                    pcall(function() setrobloxinput(not menuOpen) end)
                end
            end
            wasMenuKey=keyDown

            -- mini UI mode
            if minimized and not miniClosed then
                -- animate mini glow
                local t=tick()*1.0
                for i,sq in ipairs(miniGlowLines) do
                    local p=t+glowPhase[i]
                    local r=math.floor(15+45*math.max(0,math.sin(p+1.0)))
                    local g=math.floor(25+55*math.max(0,math.sin(p+0.4)))
                    local b=math.floor(130+125*math.max(0,math.sin(p)))
                    sq.Color=Color3.fromRGB(r,g,b)
                    sq.Transparency=(i==1 and 0.6 or 0.75)+0.25*math.abs(math.sin(p*0.5))
                end
                -- pulse active labels
                local pt=tick()*0.8
                for i,lb in ipairs(miniActiveLbls) do
                    if lb.Text~="" then
                        lb.Visible=true
                        local f=(math.sin(pt+miniActivePulse[i])+1)/2
                        lb.Color=lerpC(Color3.fromRGB(30,50,160),C.WHITE,f)
                    else
                        lb.Visible=false
                    end
                end
                -- mini clicks
                local miniOp=clamp((tick()-miniFadedAt)/MINI_FADE_DUR,0,1)
                if clicking and not wasClicking and (not miniFadeIn or miniOp>0.8) and not miniFadeOut then
                    if inBox(uiX+L.W-46,uiY+11,12,12) then
                        -- red: close mini
                        miniClosed=true
                        for _,d in ipairs(miniDrawings) do d.Visible=false end
                        for _,l in ipairs(miniActiveLbls) do l.Visible=false end
                        miniFadeIn=false; miniFadeOut=false
                        for _,d in ipairs(allDrawings) do d.Visible=false end
                    elseif inBox(uiX+L.W-59,uiY+11,12,12) then
                        -- green: restore full
                        restoreFullMenu()
                    else
                        miniDragging=true
                        miniDragOffX=mouse.X-uiX; miniDragOffY=mouse.Y-uiY
                    end
                end
                if not clicking then miniDragging=false end
                if miniDragging and clicking and not miniFadeOut then
                    local vpW,vpH=getViewport()
                    uiX=clamp(mouse.X-miniDragOffX, 0, vpW-L.W)
                    uiY=clamp(mouse.Y-miniDragOffY, 0, vpH-L.MINI_H)
                    updateMiniPos()
                end
                wasClicking=clicking
            end
            if not minimized then
                -- full menu mode
                for _,lb in ipairs(miniActiveLbls) do lb.Visible=false end
                -- tab lerp
                for _,t in ipairs(tabObjs) do
                    local tgt=t.sel and 1 or 0
                    t.lt=t.lt+(tgt-t.lt)*0.15
                    t.bg.Color =lerpC(C.SIDEBAR,C.TABSEL,t.lt)
                    t.acc.Color=lerpC(C.SIDEBAR,C.ACCENT,t.lt)
                end
                -- toggle lerp
                for _,b in ipairs(btns) do
                    if b.isTog and b.tog and b.tab==currentTab then
                        local tgt=b.state and 1 or 0
                        b.lt=b.lt+(tgt-b.lt)*0.18
                        b.tog.Color=lerpC(C.OFF,   C.ON,   b.lt)
                        b.dot.Color=lerpC(C.OFFDOT,C.ONDOT,b.lt)
                        local dox=b.rx+b.cw-L.TOG_W-8
                        local dcy=b.currentRY or b.ry
                        b.tog.Position=Vector2.new(uiX+dox, uiY+dcy+b.ch/2-L.TOG_H/2)
                        b.dot.Position=Vector2.new(uiX+dox+2+(L.TOG_W-L.TOG_H)*b.lt, uiY+dcy+b.ch/2-L.TOG_H/2+2)
                    end
                end
                -- glow animation
                do
                    local t=tick()*1.0
                    for i,sq in ipairs(glowLines) do
                        local p=t+glowPhase[i]
                        local r=math.floor(15+45*math.max(0,math.sin(p+1.0)))
                        local g=math.floor(25+55*math.max(0,math.sin(p+0.4)))
                        local b=math.floor(130+125*math.max(0,math.sin(p)))
                        sq.Color=Color3.fromRGB(r,g,b)
                        sq.Transparency=(i==1 and 0.6 or 0.75)+0.25*math.abs(math.sin(p*0.5))
                    end
                end
                -- tooltip fade
                if tipBg then
                    local prog=clamp((tick()-tipFadedAt)/TIP_FADE,0,1)
                    local op=tipFadeIn and prog or (tipFadeOut and (1-prog) or (tipFadeIn and 1 or 0))
                    if tipFadeOut and prog>=1 then
                        tipBg.Visible=false; tipBorder.Visible=false
                        tipLbl.Visible=false; tipDesc.Visible=false
                        tipFadeOut=false
                    elseif tipBg.Visible then
                        tipBg.Transparency=op; tipBorder.Transparency=op*0.7
                        tipLbl.Transparency=op; tipDesc.Transparency=op
                    end
                end
                -- ? badge glow on hover
                for _,b in ipairs(btns) do
                    if b.tab==currentTab and b.qbg and b.qlb and showSet[b.qbg] then
                        if showSet[b.bg] and inBox(uiX+(b.rx+b.cw-L.TOG_W-8)-22,uiY+(b.currentRY or b.ry)+b.ch/2-7,14,14) then
                            b.qbg.Color=Color3.fromRGB(16,30,80)
                            b.qlb.Color=Color3.fromRGB(70,120,255)
                        else
                            b.qbg.Color=Color3.fromRGB(16,20,38)
                            b.qlb.Color=C.GRAY
                        end
                    end
                end

                applyFade()
                -- animate widget positions (collapse/expand)
                for _,b in ipairs(btns) do
                    if b.currentRY ~= nil and b.tab==currentTab then
                        if b._collapsing and b._collapseTarget then
                            local diff = b._collapseTarget - b.currentRY
                            if math.abs(diff) > 0.5 then
                                b.currentRY = b.currentRY + diff * 0.18
                                bPos(b)
                            else
                                b.currentRY = b._collapseTarget
                                b._collapsing=false; b._collapseTarget=nil
                                bShow(b,false)
                            end
                        else
                            local diff = b.ry - b.currentRY
                            if math.abs(diff) > 0.3 then
                                b.currentRY = b.currentRY + diff * 0.15
                                if showSet[b.bg] then bPos(b) end
                            elseif b.currentRY ~= b.ry then
                                b.currentRY = b.ry
                                if showSet[b.bg] then bPos(b) end
                            end
                        end

                    end
                end
                -- animate window height for dropdown
                if math.abs(uiCurrentH - uiTargetH) > 0.5 then
                    uiCurrentH = uiCurrentH + (uiTargetH - uiCurrentH) * 0.08
                    applyWindowH(math.floor(uiCurrentH))
                elseif uiCurrentH ~= uiTargetH then
                    uiCurrentH = uiTargetH
                    applyWindowH(uiTargetH)
                end
                -- animate dropdown rows
                for _,b in ipairs(btns) do
                    if b.isDropdown then
                        for _,o in ipairs(b.optBgs) do
                            local diff=o.targetAlpha-o.alpha
                            if math.abs(diff)>0.01 then
                                o.alpha=o.alpha+diff*0.25  -- smooth lerp
                                local vis=o.alpha>0.02
                                o.bg.Visible=vis; o.ln.Visible=vis; o.lb.Visible=vis
                                if vis then
                                    o.bg.Transparency=o.alpha
                                    o.ln.Transparency=o.alpha
                                    o.lb.Transparency=o.alpha
                                end
                            elseif o.targetAlpha==0 and o.alpha<0.02 then
                                o.alpha=0
                                o.bg.Visible=false; o.ln.Visible=false; o.lb.Visible=false
                            elseif o.targetAlpha==1 and o.alpha>0.98 then
                                o.alpha=1
                                o.bg.Transparency=1; o.ln.Transparency=1; o.lb.Transparency=1
                            end
                        end
                    end
                end
                -- tooltip hover
                if tipBg then
                    local hov=nil
                    for _,b in ipairs(btns) do
                        if b.tab==currentTab and b.desc and b.qbg and showSet[b.qbg] then
                            if showSet[b.bg] and inBox(uiX+b.ox-22,uiY+(b.currentRY or b.ry)+b.ch/2-7,14,14) then hov=b; break end
                        end
                    end
                    if hov~=hoveredBtn then
                        hoveredBtn=hov
                        if hov then
                            local bx=uiX+hov.rx; local by=uiY+hov.ry
                            local tw=math.max(#hov.toggleName,#hov.desc)*6+16
                            tipBg.Position=Vector2.new(bx, by-32)
                            tipBg.Size=Vector2.new(tw,28)
                            tipBorder.Position=Vector2.new(bx,by-32)
                            tipBorder.Size=Vector2.new(tw,28)
                            tipLbl.Text=hov.toggleName
                            tipLbl.Position=Vector2.new(bx+8, by-30)
                            tipDesc.Text=hov.desc
                            tipDesc.Position=Vector2.new(bx+8, by-17)
                            tipFadeIn=true; tipFadeOut=false; tipFadedAt=tick()
                            tipBg.Visible=true; tipBorder.Visible=true
                            tipLbl.Visible=true; tipDesc.Visible=true
                        else
                            tipFadeOut=true; tipFadeIn=false; tipFadedAt=tick()
                        end
                    end
                end
                -- prev tab cleanup
                if prevTab and (tick()-tabSwitchedAt)>=TAB_FADE_DUR then
                    for _,b in ipairs(btns) do if b.tab==prevTab then bShow(b,false) end end
                    for _,d in ipairs(allDrawings) do if tabSet[d]=="prev" then tabSet[d]=nil end end
                    prevTab=nil
                end
                local mfn=1-(menuToggledAt-(tick()-FADE_DUR))/FADE_DUR
                local mOp=math.abs((menuOpen and 0 or 1)-clamp(mfn,0,1))
                if clicking and not wasClicking and mOp>0.5 and not isLoading then
                    -- yellow dot: minimize
                    if inBox(uiX+L.W-59,uiY+11,12,12) then
                        minimized=true; miniClosed=false
                        menuOpen=false
                        pcall(function() setrobloxinput(true) end)
                        for _,d in ipairs(allDrawings) do d.Visible=false end
                        refreshMiniLabels(); showMiniUI(true); updateMiniPos()
                        for _,lb in ipairs(miniActiveLbls) do if lb.Text~="" then lb.Visible=true end end
                    -- red dot: close
                    elseif inBox(uiX+L.W-46,uiY+11,12,12) then
                        menuOpen=false; menuToggledAt=tick()

                    elseif inBox(uiX,uiY,L.W,L.TOPBAR) then
                        dragging=true; dragOffX=mouse.X-uiX; dragOffY=mouse.Y-uiY
                    end
                    -- tabs
                    for _,t in ipairs(tabObjs) do
                        if inBox(uiX+7,uiY+t.relTY,L.SIDEBAR-14,26) then switchTab(t.name) end
                    end
                    -- buttons
                    for i,b in ipairs(btns) do
                        if b.tab==currentTab and not b.isSlider and showSet[b.bg] then
                            if inBox(uiX+b.rx,uiY+(b.currentRY or b.ry),b.cw,b.ch) then
                                if b.isTog then
                                    b.state=not b.state
                                    if b.cb then b.cb(b.state) end
                                    notif(b.toggleName.." "..(b.state and "enabled" or "disabled"),nil,2)
                                    refreshMiniLabels()
                                    if minimized and not miniClosed then updateMiniPos() end
                                elseif b.isAct then
                                    if iKeyBind and i==iKeyBind and not listenKey then
                                        listenKey=true
                                        btns[iKeyBind].lbl.Text="Press any key..."
                                    elseif b.cb then b.cb() end
                                elseif b.isDropdown then
                                    -- close any other open dropdown first
                                    if openDropdown and openDropdown~=b then
                                        openDropdown.open=false
                                        setTriDir(openDropdown.arrow, uiX+openDropdown.rx+openDropdown.cw-12, uiY+openDropdown.ry+openDropdown.ch/2, "v")
                                        for _,o in ipairs(openDropdown.optBgs) do
                                            o.targetAlpha=0
                                        end
                                        resizeForDropdown(openDropdown,false)
                                        openDropdown=nil
                                    end
                                    b.open=not b.open
                                    setTriDir(b.arrow, uiX+b.rx+b.cw-12, uiY+b.ry+b.ch/2, b.open and "^" or "v")
                                    b.openedAt=tick()
                                    openDropdown=b.open and b or nil
                                    resizeForDropdown(b, b.open)
                                    if b.open then
                                        -- position options correctly first
                                        local ax=uiX+b.rx; local ay=uiY+b.ry
                                        for i,o in ipairs(b.optBgs) do
                                            local oy2=ay+b.ch+((i-1)*b.ch)
                                            o.bg.Position=Vector2.new(ax,oy2); o.bg.Size=Vector2.new(b.cw,b.ch)
                                            o.ln.From=Vector2.new(ax,oy2+b.ch); o.ln.To=Vector2.new(ax+b.cw,oy2+b.ch)
                                            o.lb.Position=Vector2.new(ax+14,oy2+b.ch/2-6)
                                            o.ry=b.ry+b.ch+((i-1)*b.ch)
                                            o.alpha=0; o.targetAlpha=1
                                            o.bg.Transparency=0; o.ln.Transparency=0; o.lb.Transparency=0
                                            o.bg.Visible=true; o.ln.Visible=true; o.lb.Visible=true
                                        end
                                    else
                                        for _,o in ipairs(b.optBgs) do
                                            o.targetAlpha=0
                                        end
                                    end
                                elseif b.isColorPicker then
                                    local ax2=uiX+b.rx; local ay2=uiY+b.ry
                                    local totalW=(#b.swatches*19)-5
                                    local startX=ax2+b.cw-totalW-10
                                    for j,sw in ipairs(b.swatches) do
                                        local sx=startX+(j-1)*19; local sy=ay2+b.ch/2-7
                                        if inBox(sx,sy,14,14) then
                                            b.selected=j; b.value=sw.col
                                            sw.x=sx; sw.y=sy
                                            for k,sw2 in ipairs(b.swatches) do
                                                sw2.border.Color=k==j and C.WHITE or C.DIMGRAY
                                            end
                                            if b.cb then b.cb(sw.col) end
                                            break
                                        end
                                    end
                                elseif b.isDiv and b.collapsible and b.sectionName then
                                    local sec=b.sectionName
                                    _collapseSections[sec]=not _collapseSections[sec]
                                    b.arrow.Text=_collapseSections[sec] and ">" or "v"
                                    local collapsing=_collapseSections[sec]
                                    local divRef=b
                                    -- collect section members and measure height
                                    local members={}
                                    local sectionH=0
                                    local inSec=false
                                    for _,cb2 in ipairs(btns) do
                                        if cb2==divRef then inSec=true
                                        elseif inSec then
                                            if cb2.isDiv and cb2.tab==currentTab then break end
                                            if cb2.tab==currentTab then
                                                table.insert(members,cb2)
                                                sectionH=sectionH+cb2.ch+2
                                            end
                                        end
                                    end
                                    -- show/hide members
                                    for _,m in ipairs(members) do
                                        if collapsing then
                                            -- slide up into the div then hide
                                            m._collapseTarget=divRef.ry+14
                                            m._collapsing=true
                                            bShow(m,true)
                                        else
                                            -- restore to base position and show
                                            m._collapseTarget=nil
                                            m._collapsing=false
                                            m.ry=m.baseRY
                                            m.currentRY=divRef.ry+14
                                            bShow(m,true)
                                        end
                                    end
                                    -- shift all same-tab widgets below the section
                                    inSec=false
                                    local pastSection=false
                                    for _,cb2 in ipairs(btns) do
                                        if cb2==divRef then inSec=true
                                        elseif inSec and cb2.tab==currentTab then
                                            if cb2.isDiv then inSec=false; pastSection=true end
                                        end
                                        if pastSection and cb2.tab==currentTab then
                                            cb2.ry=collapsing and cb2.baseRY-sectionH or cb2.baseRY
                                        end
                                    end
                                end
                                break
                            end
                        end
                    end
                end
                -- sliders
                for _,b in ipairs(btns) do
                    if b.isSlider and b.tab==currentTab and menuOpen then
                        local ax=uiX+b.rx+8; local ay=uiY+b.ry+b.ch-11
                        if clicking and not wasClicking then
                            if inBox(uiX+b.rx,uiY+b.ry,b.cw,b.ch) and b.bg.Visible then b.dragging=true end
                        end
                        if not clicking and wasClicking and b.dragging then
                            local disp=b.isFloat and string.format("%.1f",b.value) or math.floor(b.value)
                            notif(b.baseLbl..": "..disp,nil,2)
                        end
                        if not clicking then b.dragging=false end
                        if b.dragging and clicking then
                            local frac=clamp((mouse.X-ax)/b.trackW,0,1)
                            b.value=b.minV+frac*(b.maxV-b.minV)
                            local fx=ax+frac*b.trackW
                            b.fill.To=Vector2.new(fx,ay)
                            b.handle.Position=Vector2.new(fx-4,ay-4)
                            local disp=b.isFloat and string.format("%.1f",b.value) or math.floor(b.value)
                            b.lbl.Text=b.baseLbl..": "..disp
                            if b.cb then b.cb(b.value) end
                        end
                    end
                end
                -- dropdown option clicks
                if clicking and not wasClicking and openDropdown and not isLoading then
                    local bd=openDropdown
                    for i,o in ipairs(bd.optBgs) do
                        local ox=uiX+bd.rx; local oy=uiY+o.ry
                        if inBox(ox,oy,bd.cw,bd.ch) then
                            bd.selected=i
                            bd.valLbl.Text=bd.options[i]
                            for j,o2 in ipairs(bd.optBgs) do
                                o2.lb.Color=j==i and C.ACCENT or C.WHITE
                                o2.targetAlpha=0
                            end
                            bd.open=false; bd.arrow.Text="v"
                            openDropdown=nil
                            resizeForDropdown(bd,false)
                            if bd.cb then bd.cb(bd.options[i],i) end
                            break
                        end
                    end
                end
                -- scroll (mousewheel)
                pcall(function()
                    if isLoading then return end
                    local uis=game:GetService("UserInputService")
                    local wh=uis:GetLastInputObject(Enum.UserInputType.MouseWheel,true)
                    if wh and inBox(uiX+L.SIDEBAR,uiY+L.TOPBAR,L.CONTENT_W,CONTENT_H()) then
                        local sc=(tabScroll[currentTab] or 0)-wh.Position.Z*28
                        local maxSc=math.max(0,(tabRowY[currentTab] or 0)-CONTENT_H()+20)
                        tabScroll[currentTab]=clamp(sc,0,maxSc)

                    end
                end)
                -- drag
                if not clicking then
                    dragging=false

                end

                if dragging and clicking then
                    local vpW,vpH=getViewport()
                    uiX=clamp(mouse.X-dragOffX, 0, vpW-L.W)
                    uiY=clamp(mouse.Y-dragOffY, 0, vpH-uiCurrentH)
                    updatePos()
                end
                wasClicking=clicking
                -- key rebind
                if listenKey then
                    for k=0x08,0xDD do
                        if iskeypressed(k) and k~=0x01 and k~=0x02 then
                            menuKey=k
                            local n=kname(k)
                            if iKeyInfo then btns[iKeyInfo].lbl.Text="Menu Key: "..n end
                            if iKeyBind then btns[iKeyBind].lbl.Text="Click to Rebind" end
                            dKeyLbl.Text=n; dMiniKeyLbl.Text=n
                            listenKey=false; break
                        end
                    end
                end
                -- char label
                if charLabelFn then dCharLbl.Text=charLabelFn() end
            end
            end -- isrbxactive
        end
        end) -- spawn
    end -- Init

    -- Tab factory
    win._tabOrder = {}
    function win:Tab(name)
        table.insert(win._tabOrder, name)
        return getTabAPI(name)
    end

    function win:SettingsTab(destroyCb)
        local s = self:Tab("Settings")
        s:Div("KEYBIND")
        iKeyInfo = s:Button("Menu Key: F1",   C.ROWBG, nil, nil)
        iKeyBind = s:Button("Click to Rebind", Color3.fromRGB(14,20,40), nil, nil)
        s:Div("DANGER")
        s:Button("Destroy Menu", Color3.fromRGB(28,7,7), destroyCb, C.RED)
        return s
    end

    function win:Destroy()
        for _,b in ipairs(btns) do
            if b.isDropdown then
                for _,o in ipairs(b.optBgs) do
                    pcall(function() o.bg:Remove() end)
                    pcall(function() o.ln:Remove() end)
                    pcall(function() o.lb:Remove() end)
                end
            end
        end
        destroyed=true
        pcall(function() notify("UI destroyed.", titleA.." "..titleB, 3) end)
        for _,d in ipairs(allDrawings) do pcall(function() d:Remove() end) end
        for _,d in ipairs(miniDrawings) do pcall(function() d:Remove() end) end
        for _,l in ipairs(miniActiveLbls) do pcall(function() l:Remove() end) end
    end

    function win:ApplyTheme(name) applyTheme(name) end
    UILib.applyTheme = function(name) applyTheme(name) end

    return win
end
