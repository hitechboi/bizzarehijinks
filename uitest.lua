heres my ui lib --[[
    uilib.lua :3
    by hitechboi / nejrio >_<
    updated: dropdown, textinput, keybind rows,
    colorpicker, collapsible sections, tooltips,
    search bar, profiles, tab badges
    fixes: no character ref, dropdowns expand inline (no scroll needed),
    all user interactions use notify()
]]

local UILib = {}

local function clamp(v,lo,hi) return math.max(lo,math.min(hi,v)) end
local function lerpC(a,b,t)
    return Color3.fromRGB(
        math.floor(a.R*255+(b.R*255-a.R*255)*t),
        math.floor(a.G*255+(b.G*255-a.G*255)*t),
        math.floor(a.B*255+(b.B*255-a.B*255)*t))
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
    COLSEL  = Color3.fromRGB(18, 22, 40),
    OPTROW  = Color3.fromRGB(16, 20, 36),
    OPTSEL  = Color3.fromRGB(22, 32, 70),
}
UILib.Colors = C

local L = {
    W        = 440, H        = 380,
    SIDEBAR  = 128, TOPBAR   = 40,
    FOOTER   = 22,  ROW_H    = 40,
    ROW_PAD  = 10,  TOG_W    = 34,
    TOG_H    = 17,  HDL      = 8,
    MINI_H   = 86,  SEARCH_H = 24,
    OPT_H    = 22,  CP_H     = 72,
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
kn[0x70]="F1"  kn[0x71]="F2"  kn[0x72]="F3"  kn[0x73]="F4"
kn[0x74]="F5"  kn[0x75]="F6"  kn[0x76]="F7"  kn[0x77]="F8"
kn[0x78]="F9"  kn[0x79]="F10" kn[0x7A]="F11" kn[0x7B]="F12"
kn[0x20]="Space" kn[0x09]="Tab" kn[0x0D]="Enter" kn[0x1B]="Esc" kn[0x08]="Back"
kn[0x24]="Home" kn[0x23]="End" kn[0x2E]="Del" kn[0x2D]="Ins"
kn[0x21]="PgUp" kn[0x22]="PgDn"
kn[0x26]="Up"   kn[0x28]="Down" kn[0x25]="Left" kn[0x27]="Right"
kn[0xBC]="," kn[0xBE]="." kn[0xBF]="/" kn[0xBA]=";" kn[0xBB]="=" kn[0xBD]="-"
kn[0xDB]="[" kn[0xDD]="]" kn[0xDC]="\\" kn[0xDE]="'" kn[0xC0]="`"
local function kname(k) return kn[k] or ("Key"..k) end

-- ============================================================
function UILib.Window(titleA, titleB, gameName)
    local win = {}
    local mouse = game.Players.LocalPlayer:GetMouse()

    local uiX, uiY           = 300, 200
    local dragging            = false
    local dragOffX, dragOffY  = 0, 0
    local wasClicking         = false
    local currentTab          = nil
    local menuKey             = 0x70
    local listenMenuKey       = false
    local destroyed           = false
    local wasMenuKey          = false
    local menuOpen            = true
    local menuToggledAt       = os.clock() - 1
    local FADE_DUR            = 0.4
    local TAB_FADE_DUR        = 0.2
    local tabSwitchedAt       = os.clock() - 1
    local prevTab             = nil
    local minimized           = false
    local miniClosed          = false
    local miniDragging        = false
    local miniDragOffX, miniDragOffY = 0, 0
    local glowPhase           = {0, math.pi*0.6}
    local searchText          = ""
    local searchActive        = false
    local profiles            = {}
    local listenKeybindIdx    = nil
    -- openInlineIdx: index into btns of currently expanded dropdown or colorpicker
    local openInlineIdx       = nil
    local openCollapse        = {}

    local allDrawings  = {}
    local showSet      = {}
    local tabSet       = {}
    local baseUI       = {}
    local tabObjs      = {}
    local btns         = {}
    local miniDrawings = {}
    local miniActiveLbls  = {}
    local miniActivePulse = {}
    local MAX_MINI_LBLS   = 12
    for i=1,MAX_MINI_LBLS do
        local lb=mkTx("",0,0,13,C.WHITE,false,9,false)
        lb.Outline=true; lb.Visible=false; lb.Transparency=1
        table.insert(miniActiveLbls,lb); table.insert(miniActivePulse,i*0.7)
    end

    -- tooltip (shared single instance)
    local ttBg,ttBdr,ttTx
    local function buildTooltip()
        ttBg  = mkSq(0,0,80,20,C.COLSEL,true,1,40,nil,4)
        ttBdr = mkSq(0,0,80,20,C.BORDER,false,0.5,40,1,4)
        ttTx  = mkTx("",0,0,10,C.GRAY,false,41)
        ttBg.Visible=false; ttBdr.Visible=false; ttTx.Visible=false
    end
    local function showTT(text,x,y)
        if not ttBg then return end
        local w=math.max(70,#text*6+16)
        ttBg.Size=Vector2.new(w,20); ttBdr.Size=Vector2.new(w,20)
        ttBg.Position=Vector2.new(x-w-6,y-10); ttBdr.Position=Vector2.new(x-w-6,y-10)
        ttTx.Position=Vector2.new(x-w+2,y-7); ttTx.Text=text
        ttBg.Visible=true; ttBdr.Visible=true; ttTx.Visible=true
    end
    local function hideTT()
        if ttBg then ttBg.Visible=false; ttBdr.Visible=false; ttTx.Visible=false end
    end

    -- search bar
    local sBg,sLn,sLbl
    local function buildSearch()
        local sx=uiX+L.SIDEBAR; local sy=uiY+L.TOPBAR
        sBg  = mkSq(sx,sy,L.CONTENT_W-1,L.SEARCH_H,Color3.fromRGB(10,12,22),true,1,4)
        sLn  = mkLn(sx,sy+L.SEARCH_H,sx+L.CONTENT_W-1,sy+L.SEARCH_H,C.BORDER,5,1)
        sLbl = mkTx("/ search...",sx+8,sy+6,10,C.GRAY,false,5)
        sBg.Visible=false; sLn.Visible=false; sLbl.Visible=false
    end
    local function updateSearchPos()
        if not sBg then return end
        local sx=uiX+L.SIDEBAR; local sy=uiY+L.TOPBAR
        sBg.Position=Vector2.new(sx,sy); sBg.Size=Vector2.new(L.CONTENT_W-1,L.SEARCH_H)
        sLn.From=Vector2.new(sx,sy+L.SEARCH_H); sLn.To=Vector2.new(sx+L.CONTENT_W-1,sy+L.SEARCH_H)
        sLbl.Position=Vector2.new(sx+8,sy+6)
    end

    local CONT_OFF = L.SEARCH_H  -- content rows always offset by search bar height

    local function mkD(d) table.insert(allDrawings,d); d.Visible=false; return d end
    local function setShow(d,yes) showSet[d]=yes or nil; d.Visible=yes and true or false end
    local function inBox(x,y,w,h) return mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+h end

    -- extra Y shift from an open inline widget that sits above index bIdx in the same tab
    local function extraAbove(bIdx)
        if not openInlineIdx or openInlineIdx==bIdx then return 0 end
        local ob=btns[openInlineIdx]
        if ob and ob.tab==btns[bIdx].tab and openInlineIdx<bIdx then
            return ob.expandH or 0
        end
        return 0
    end
    local function screenY(b,bIdx) return uiY+b.ry+CONT_OFF+extraAbove(bIdx) end

    -- -- FADE
    local function applyFade()
        if minimized then for _,d in ipairs(allDrawings) do d.Visible=false end; return end
        for _,lb in ipairs(miniActiveLbls) do lb.Visible=false end
        local mf=1-(menuToggledAt-(os.clock()-FADE_DUR))/FADE_DUR
        if not menuOpen and mf>=1.1 then for _,d in ipairs(allDrawings) do d.Visible=false end; return end
        local mOp=mf<1.1 and math.abs((menuOpen and 0 or 1)-clamp(mf,0,1)) or (menuOpen and 1 or 0)
        local tp=clamp((os.clock()-tabSwitchedAt)/TAB_FADE_DUR,0,1)
        for _,d in ipairs(allDrawings) do
            if showSet[d] then
                local tOp=tabSet[d]=="next" and tp or tabSet[d]=="prev" and (1-tp) or 1
                local op=mOp*tOp; d.Visible=op>0.01; d.Transparency=op
            else d.Visible=false end
        end
        if sBg then
            local vis=menuOpen and mOp>0.5
            sBg.Visible=vis; sLn.Visible=vis; sLbl.Visible=vis
        end
    end

    local function bAllDrawings(b)
        local t={b.bg}
        if not b.isLog then t[#t+1]=b.lbl end
        for _,k in ipairs({"ln","tog","dot","track","fill","handle","valLbl","arrow","kbBadge","kbLbl","ttIcon","cpBg","cpSwatch"}) do
            if b[k] then t[#t+1]=b[k] end
        end
        if b.lbls then for _,l in ipairs(b.lbls) do t[#t+1]=l end end
        if b.inlineRows then for _,ir in ipairs(b.inlineRows) do t[#t+1]=ir.bg; t[#t+1]=ir.lbl end end
        if b.cpRows then for _,row in ipairs(b.cpRows) do for _,d in ipairs(row) do t[#t+1]=d end end end
        return t
    end

    local function bShow(b,yes)
        local inlineOpen=(openInlineIdx==b._selfIdx)
        setShow(b.bg,yes)
        if not b.isLog then setShow(b.lbl,yes) end
        for _,k in ipairs({"ln","tog","dot","track","fill","handle","valLbl","arrow","kbBadge","kbLbl","ttIcon"}) do
            if b[k] then setShow(b[k],yes) end
        end
        if b.lbls then for _,l in ipairs(b.lbls) do setShow(l,yes) end end
        -- inline rows only visible if this widget is the open one
        if b.inlineRows then
            for _,ir in ipairs(b.inlineRows) do
                setShow(ir.bg,yes and inlineOpen); setShow(ir.lbl,yes and inlineOpen)
            end
        end
        if b.cpBg     then setShow(b.cpBg,    yes and inlineOpen) end
        if b.cpSwatch then setShow(b.cpSwatch,yes and inlineOpen) end
        if b.cpRows then
            for _,row in ipairs(b.cpRows) do
                for _,d in ipairs(row) do setShow(d,yes and inlineOpen) end
            end
        end
    end

    local function bPos(b,bIdx)
        local ax=uiX+b.rx; local ay=screenY(b,bIdx)
        b.bg.Position=Vector2.new(ax,ay)
        if b.isLog then
            for i,lb in ipairs(b.lbls) do
                local off=b.starFirst and i==1 and b.pad
                    or b.starFirst and (b.starH+b.pad+(i-2)*b.lineH)
                    or (b.pad+(i-1)*b.lineH)
                if b.starFirst and i==1 then lb.Position=Vector2.new(ax+b.cw/2,ay+b.pad)
                else lb.Position=Vector2.new(ax+8,ay+off) end
            end
            return
        end
        if b.isDiv or b.isCollapse then
            b.lbl.Position=Vector2.new(ax+6,ay)
            if b.arrow then b.arrow.Position=Vector2.new(ax+b.cw-14,ay) end
            if b.ln then b.ln.From=Vector2.new(ax,ay+13); b.ln.To=Vector2.new(ax+b.cw,ay+13) end
        elseif b.isAct then
            b.lbl.Position=Vector2.new(ax+b.cw/2,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
        elseif b.isSlider then
            b.lbl.Position=Vector2.new(ax+8,ay+7)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            local tx=ax+8; local ty=ay+b.ch-11
            b.track.From=Vector2.new(tx,ty); b.track.To=Vector2.new(tx+b.trackW,ty)
            local frac=(b.value-b.minV)/(b.maxV-b.minV)
            local fx=tx+frac*b.trackW
            b.fill.From=Vector2.new(tx,ty); b.fill.To=Vector2.new(fx,ty)
            b.handle.Position=Vector2.new(fx-4,ty-4)
        elseif b.isDropdown then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.valLbl.Position=Vector2.new(ax+b.cw-54,ay+b.ch/2-6)
            b.arrow.Position=Vector2.new(ax+b.cw-14,ay+b.ch/2-7)
            if b.inlineRows then
                for i,ir in ipairs(b.inlineRows) do
                    ir.bg.Position=Vector2.new(ax,ay+b.ch+(i-1)*L.OPT_H)
                    ir.bg.Size=Vector2.new(b.cw,L.OPT_H-1)
                    ir.lbl.Position=Vector2.new(ax+10,ay+b.ch+(i-1)*L.OPT_H+4)
                end
            end
        elseif b.isColorPicker then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.valLbl.Position=Vector2.new(ax+b.cw-26,ay+b.ch/2-8)
            b.arrow.Position=Vector2.new(ax+b.cw-12,ay+b.ch/2-7)
            if b.cpBg then
                local ey=ay+b.ch
                b.cpBg.Position=Vector2.new(ax,ey); b.cpBg.Size=Vector2.new(b.cw,L.CP_H)
                if b.cpSwatch then b.cpSwatch.Position=Vector2.new(ax+10,ey+10) end
                local lx=ax+L.ROW_PAD+26; local tw=b.cw-L.ROW_PAD*2-30
                for ci=1,3 do
                    local ry2=ey+6+(ci-1)*20
                    local row=b.cpRows[ci]
                    row[1].Position=Vector2.new(lx-16,ry2+1)
                    row[2].From=Vector2.new(lx,ry2+5); row[2].To=Vector2.new(lx+tw,ry2+5)
                    local frac2=b.chanVals[ci]/255; local fx2=lx+frac2*tw
                    row[3].From=Vector2.new(lx,ry2+5); row[3].To=Vector2.new(fx2,ry2+5)
                    row[4].Position=Vector2.new(fx2-4,ry2+1)
                end
            end
        elseif b.isTextInput then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.valLbl.Position=Vector2.new(ax+b.cw/2+10,ay+b.ch/2-6)
        elseif b.isKeybind then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.kbBadge.Position=Vector2.new(ax+b.cw-48,ay+b.ch/2-9)
            b.kbLbl.Position=Vector2.new(ax+b.cw-28,ay+b.ch/2-6)
        else -- toggle
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            if b.tog then
                local togX=ax+b.togOffX; local togY=ay+b.ch/2-L.TOG_H/2
                b.tog.Position=Vector2.new(togX,togY)
                b.dot.Position=Vector2.new(togX+2+(L.TOG_W-L.TOG_H)*b.lt,togY+2)
            end
            if b.ttIcon then b.ttIcon.Position=Vector2.new(ax+b.cw-20,ay+b.ch/2-5) end
        end
    end

    local function tagFade(b,group)
        for _,d in ipairs(bAllDrawings(b)) do tabSet[d]=group end
    end

    local function closeInline()
        if not openInlineIdx then return end
        local b=btns[openInlineIdx]
        if b then
            if b.arrow then b.arrow.Text="v" end
            if b.inlineRows then for _,ir in ipairs(b.inlineRows) do ir.bg.Visible=false; ir.lbl.Visible=false end end
            if b.cpBg     then b.cpBg.Visible=false end
            if b.cpSwatch then b.cpSwatch.Visible=false end
            if b.cpRows then for _,row in ipairs(b.cpRows) do for _,d in ipairs(row) do d.Visible=false end end end
        end
        openInlineIdx=nil
    end

    local function reposTab(tab)
        for i,b in ipairs(btns) do
            if b.tab==tab and showSet[b.bg] then bPos(b,i) end
        end
    end

    local function showTab(tab)
        closeInline()
        for i,b in ipairs(btns) do
            local yes=b.tab==tab
            if b.isCollapse then bShow(b,yes)
            elseif b.parentCollapse then bShow(b, yes and (openCollapse[b.parentCollapse] or false))
            else bShow(b,yes) end
            if yes then bPos(b,i) end
        end
    end

    local function applySearch()
        if searchText=="" then showTab(currentTab); return end
        local q=searchText:lower()
        for i,b in ipairs(btns) do
            if b.tab==currentTab then
                local name=((b.toggleName or b.baseLbl or b.sectionName or "")):lower()
                bShow(b, name:find(q,1,true)~=nil)
                if showSet[b.bg] then bPos(b,i) end
            end
        end
    end

    local function updateBadges()
        for _,t in ipairs(tabObjs) do
            if t.badge then
                local has=false
                for _,b in ipairs(btns) do if b.tab==t.name and b.isTog and b.state then has=true; break end end
                t.badge.Color=has and C.GREEN or C.DIMGRAY
            end
        end
    end

    local function switchTab(name)
        if name==currentTab then return end
        closeInline()
        prevTab=currentTab; currentTab=name; tabSwitchedAt=os.clock()
        searchText=""; searchActive=false
        if sLbl then sLbl.Text="/ search..." end
        for _,t in ipairs(tabObjs) do t.sel=t.name==name; setShow(t.lbl,t.sel); setShow(t.lblG,not t.sel) end
        updateBadges()
        for _,d in ipairs(allDrawings) do tabSet[d]=nil end
        if prevTab then for i,b in ipairs(btns) do if b.tab==prevTab then bShow(b,true); bPos(b,i); tagFade(b,"prev") end end end
        for i,b in ipairs(btns) do if b.tab==name then bShow(b,true); bPos(b,i); tagFade(b,"next") end end
    end

    -- -- drawing refs
    local dShadow,dMainBg,dGlow1,dGlow2,dBorder,dTopBar,dTopFill,dTopLine
    local dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR
    local dSide,dSideLn,dContent,dFooter,dFotLine,dFooterLbl,glowLines
    local dMiniShadow,dMiniBg,dMiniGlow1,dMiniGlow2,dMiniBorder,dMiniTopBar
    local dMiniTitleW,dMiniTitleA,dMiniTitleG,dMiniKeyLbl,dMiniDotG,dMiniDotR
    local dMiniDivLn,dMiniActiveBg,miniGlowLines
    local iKeyInfo,iKeyBind

    local function updatePos()
        dShadow.Position=Vector2.new(uiX-2,uiY-2)
        dMainBg.Position=Vector2.new(uiX,uiY); dBorder.Position=Vector2.new(uiX,uiY)
        dGlow1.Position=Vector2.new(uiX-1,uiY-1); dGlow2.Position=Vector2.new(uiX-2,uiY-2)
        dTopBar.Position=Vector2.new(uiX+1,uiY+1)
        dTopFill.Position=Vector2.new(uiX+1,uiY+L.TOPBAR-5)
        dTopLine.From=Vector2.new(uiX+1,uiY+L.TOPBAR); dTopLine.To=Vector2.new(uiX+L.W-1,uiY+L.TOPBAR)
        dTitleW.Position=Vector2.new(uiX+14,uiY+12); dTitleA.Position=Vector2.new(uiX+78,uiY+12)
        dTitleG.Position=Vector2.new(uiX+154,uiY+12); dKeyLbl.Position=Vector2.new(uiX+L.W-22,uiY+14)
        dDotY.Position=Vector2.new(uiX+L.W-55,uiY+15); dDotR.Position=Vector2.new(uiX+L.W-42,uiY+15)
        dSide.Position=Vector2.new(uiX+1,uiY+L.TOPBAR)
        dSideLn.From=Vector2.new(uiX+L.SIDEBAR,uiY+L.TOPBAR); dSideLn.To=Vector2.new(uiX+L.SIDEBAR,uiY+L.H-L.FOOTER)
        dContent.Position=Vector2.new(uiX+L.SIDEBAR,uiY+L.TOPBAR)
        dFooter.Position=Vector2.new(uiX+1,uiY+L.H-L.FOOTER)
        dFotLine.From=Vector2.new(uiX+1,uiY+L.H-L.FOOTER); dFotLine.To=Vector2.new(uiX+L.W-1,uiY+L.H-L.FOOTER)
        dFooterLbl.Position=Vector2.new(uiX+L.SIDEBAR+8,uiY+L.H-L.FOOTER+5)
        for _,t in ipairs(tabObjs) do
            t.bg.Position=Vector2.new(uiX+7,uiY+t.relTY); t.acc.Position=Vector2.new(uiX+7,uiY+t.relTY)
            t.lbl.Position=Vector2.new(uiX+18,uiY+t.relTY+7); t.lblG.Position=Vector2.new(uiX+18,uiY+t.relTY+7)
            if t.badge then t.badge.Position=Vector2.new(uiX+L.SIDEBAR-16,uiY+t.relTY+9) end
        end
        for i,b in ipairs(btns) do if showSet[b.bg] then bPos(b,i) end end
        updateSearchPos()
    end

    local function updateMiniPos()
        dMiniShadow.Position=Vector2.new(uiX-2,uiY-2); dMiniShadow.Size=Vector2.new(L.W+4,L.MINI_H+4)
        dMiniBg.Position=Vector2.new(uiX,uiY);          dMiniBg.Size=Vector2.new(L.W,L.MINI_H)
        dMiniGlow1.Position=Vector2.new(uiX-1,uiY-1);  dMiniGlow1.Size=Vector2.new(L.W+2,L.MINI_H+2)
        dMiniGlow2.Position=Vector2.new(uiX-2,uiY-2);  dMiniGlow2.Size=Vector2.new(L.W+4,L.MINI_H+4)
        dMiniBorder.Position=Vector2.new(uiX,uiY);      dMiniBorder.Size=Vector2.new(L.W,L.MINI_H)
        dMiniTopBar.Position=Vector2.new(uiX+1,uiY+1)
        dMiniTitleW.Position=Vector2.new(uiX+14,uiY+12); dMiniTitleA.Position=Vector2.new(uiX+78,uiY+12)
        dMiniTitleG.Position=Vector2.new(uiX+154,uiY+12); dMiniKeyLbl.Position=Vector2.new(uiX+L.W-22,uiY+14)
        dMiniDotG.Position=Vector2.new(uiX+L.W-55,uiY+15); dMiniDotR.Position=Vector2.new(uiX+L.W-42,uiY+15)
        dMiniDivLn.From=Vector2.new(uiX+1,uiY+L.TOPBAR); dMiniDivLn.To=Vector2.new(uiX+L.W-1,uiY+L.TOPBAR)
        dMiniActiveBg.Position=Vector2.new(uiX+1,uiY+L.TOPBAR); dMiniActiveBg.Size=Vector2.new(L.W-2,L.MINI_H-L.TOPBAR-1)
        local PAD=10; local SEP=14; local CW=7; local RH=18
        local R1=uiY+L.TOPBAR+6; local R2=R1+RH; local cx=uiX+PAD; local row=1
        for _,lb in ipairs(miniActiveLbls) do
            if lb.Visible and lb.Text~="" then
                local w=#lb.Text*CW
                if cx+w>uiX+L.W-PAD then if row==1 then row=2; cx=uiX+PAD else break end end
                lb.Position=Vector2.new(cx,row==1 and R1 or R2); cx=cx+w+SEP
            end
        end
    end

    local function showMiniUI(show)
        for _,d in ipairs(miniDrawings) do d.Visible=show end
        if not show then for _,l in ipairs(miniActiveLbls) do l.Visible=false end
        else for _,l in ipairs(miniActiveLbls) do if l.Text~="" then l.Visible=true end end end
    end

    local function refreshMini()
        local active={}
        for _,b in ipairs(btns) do if b.isTog and b.state then table.insert(active,b.toggleName) end end
        if #active==0 then
            miniActiveLbls[1].Text="no active toggles"; miniActiveLbls[1].Position=Vector2.new(uiX+10,uiY+L.TOPBAR+6); miniActiveLbls[1].Visible=true
            for i=2,MAX_MINI_LBLS do miniActiveLbls[i].Text=""; miniActiveLbls[i].Visible=false end; return
        end
        local PAD=10; local SEP=14; local CW=7; local RH=18
        local R1=uiY+L.TOPBAR+6; local R2=R1+RH; local slots={}; local cx=uiX+PAD; local row=1
        for _,name in ipairs(active) do
            local w=#name*CW
            if cx+w>uiX+L.W-PAD then if row==1 then row=2; cx=uiX+PAD else break end end
            table.insert(slots,{name=name,x=cx,y=(row==1 and R1 or R2)}); cx=cx+w+SEP
        end
        for i,lb in ipairs(miniActiveLbls) do
            if slots[i] then lb.Text=slots[i].name; lb.Position=Vector2.new(slots[i].x,slots[i].y); lb.Visible=true
            else lb.Text=""; lb.Visible=false end
        end
    end

    local function restoreFullMenu()
        minimized=false; miniClosed=false; showMiniUI(false)
        for _,d in ipairs(allDrawings) do d.Visible=false; tabSet[d]=nil end
        for _,d in ipairs(baseUI) do setShow(d,true) end
        for _,t in ipairs(tabObjs) do
            setShow(t.bg,true); setShow(t.acc,true); setShow(t.lbl,t.sel); setShow(t.lblG,not t.sel)
            if t.badge then setShow(t.badge,true) end
        end
        showTab(currentTab); updatePos(); menuOpen=true; menuToggledAt=os.clock()-FADE_DUR-0.01
    end

    -- profiles
    local function saveProfile(name)
        local p={}
        for _,b in ipairs(btns) do
            if b.isTog     then p["t_"..b.toggleName]=b.state end
            if b.isSlider  then p["s_"..b.baseLbl]=b.value end
            if b.isDropdown then p["d_"..b.baseLbl]=b.value end
        end
        profiles[name]=p
        pcall(function() notify("Profile '"..name.."' saved","Profiles",3) end)
    end
    local function loadProfile(name)
        local p=profiles[name]; if not p then pcall(function() notify("No profile '"..name.."' found","Profiles",3) end); return end
        for i,b in ipairs(btns) do
            if b.isTog then local v=p["t_"..b.toggleName]; if v~=nil then b.state=v; if b.cb then pcall(b.cb,v) end end end
            if b.isSlider then
                local v=p["s_"..b.baseLbl]
                if v~=nil then
                    b.value=v; local frac=(v-b.minV)/(b.maxV-b.minV)
                    local ax=uiX+b.rx+8; local ty=screenY(b,i)+b.ch-11
                    local fx=ax+frac*b.trackW; b.fill.To=Vector2.new(fx,ty); b.handle.Position=Vector2.new(fx-4,ty-4)
                    b.lbl.Text=b.baseLbl..": "..(b.isFloat and string.format("%.1f",v) or math.floor(v))
                    if b.cb then pcall(b.cb,v) end
                end
            end
            if b.isDropdown then local v=p["d_"..b.baseLbl]; if v~=nil then b.value=v; b.valLbl.Text=v; if b.cb then pcall(b.cb,v) end end end
        end
        refreshMini(); updateBadges()
        pcall(function() notify("Profile '"..name.."' loaded","Profiles",3) end)
    end
    UILib.saveProfile=saveProfile; UILib.loadProfile=loadProfile

    -- -- WIDGET BUILDERS
    local function addToggle(tab,lbl,relY,init,cb,tooltip,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local hasTT=tooltip and #tooltip>0
        local togOffX=cw-L.TOG_W-8-(hasTT and 22 or 0)
        local togX=uiX+rx+togOffX; local togY=uiY+ry+ch/2-L.TOG_H/2
        local bg =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local tog=mkD(mkSq(togX,togY,L.TOG_W,L.TOG_H,init and C.ON or C.OFF,true,1,4,nil,L.TOG_H))
        local dot=mkD(mkSq(togX+2+(init and L.TOG_W-L.TOG_H or 0),togY+2,L.TOG_H-4,L.TOG_H-4,init and C.ONDOT or C.OFFDOT,true,1,5,nil,L.TOG_H))
        local tti=hasTT and mkD(mkTx("?",uiX+rx+cw-16,uiY+ry+ch/2-5,9,C.GRAY,false,8)) or nil
        local b={tab=tab,isTog=true,state=init,bg=bg,lbl=lb,ln=dl,tog=tog,dot=dot,
                 rx=rx,ry=ry,cw=cw,ch=ch,togOffX=togOffX,lt=init and 1 or 0,cb=cb,
                 toggleName=lbl,tooltip=tooltip,ttIcon=tti,parentCollapse=parentSec}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    local function addDiv(tab,lbl,relY)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2
        local lb=mkD(mkTx(lbl,uiX+rx+6,uiY+ry,9,C.GRAY,false,8))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13,C.DIV,4,1))
        local b={tab=tab,isDiv=true,bg=lb,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=14}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    local function addCollapse(tab,lbl,relY,startsOpen)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2
        openCollapse[lbl]=startsOpen~=false
        local lb =mkD(mkTx(lbl,uiX+rx+6,uiY+ry,9,startsOpen~=false and C.WHITE or C.GRAY,false,8))
        local arw=mkD(mkTx(startsOpen~=false and "v" or ">",uiX+rx+cw-14,uiY+ry,9,C.GRAY,false,8))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13,C.DIV,4,1))
        local b={tab=tab,isCollapse=true,sectionName=lbl,bg=lb,lbl=lb,arrow=arw,ln=dl,rx=rx,ry=ry,cw=cw,ch=14,children={}}
        table.insert(btns,b); b._selfIdx=#btns; return #btns,lbl
    end

    local function addAct(tab,lbl,relY,col,cb,lblCol)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,col or C.ROWBG,true,1,3,nil,4))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb=mkD(mkTx(lbl,uiX+rx+cw/2,uiY+ry+ch/2-6,12,lblCol or C.WHITE,true,8))
        local b={tab=tab,isAct=true,bg=bg,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=ch,cb=cb,baseLbl=lbl}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    local function addSlider(tab,lbl,relY,minV,maxV,initV,cb,isFloat,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H+6
        local trackW=cw-16; local frac=(initV-minV)/(maxV-minV)
        local initD=isFloat and string.format("%.1f",initV) or math.floor(initV)
        local ty=uiY+ry+ch-11; local fx=uiX+rx+8+frac*trackW
        local bg =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb =mkD(mkTx(lbl..": "..initD,uiX+rx+8,uiY+ry+7,12,C.WHITE,false,8))
        local trk=mkD(mkLn(uiX+rx+8,ty,uiX+rx+8+trackW,ty,C.DIMGRAY,5,3))
        local fil=mkD(mkLn(uiX+rx+8,ty,fx,ty,C.ACCENT,6,3))
        local hdl=mkD(mkSq(fx-4,ty-4,L.HDL,L.HDL,C.WHITE,true,1,7,nil,3))
        local b={tab=tab,isSlider=true,bg=bg,lbl=lb,ln=dl,track=trk,fill=fil,handle=hdl,
                 rx=rx,ry=ry,cw=cw,ch=ch,trackW=trackW,minV=minV,maxV=maxV,
                 value=initV,baseLbl=lbl,dragging=false,cb=cb,isFloat=isFloat or false,parentCollapse=parentSec}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    -- Dropdown: options expand inline below header row; rows below shift by expandH
    local function addDropdown(tab,lbl,relY,options,initVal,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local val=initVal or options[1] or ""
        local bg =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local vl =mkD(mkTx(val,uiX+rx+cw-54,uiY+ry+ch/2-6,11,C.ACCENT,false,8))
        local arw=mkD(mkTx("v",uiX+rx+cw-14,uiY+ry+ch/2-7,9,C.GRAY,false,8))
        local inlineRows={}
        for i,opt in ipairs(options) do
            local oy=uiY+ry+ch+(i-1)*L.OPT_H
            local ibg=mkD(mkSq(uiX+rx,oy,cw,L.OPT_H-1,(opt==val) and C.OPTSEL or C.OPTROW,true,1,6,nil,0))
            local ilb=mkD(mkTx(opt,uiX+rx+10,oy+4,11,(opt==val) and C.ACCENT or C.GRAY,false,7))
            table.insert(inlineRows,{bg=ibg,lbl=ilb,option=opt,drawings={ibg,ilb}})
        end
        local b={tab=tab,isDropdown=true,bg=bg,lbl=lb,ln=dl,valLbl=vl,arrow=arw,
                 rx=rx,ry=ry,cw=cw,ch=ch,options=options,value=val,
                 baseLbl=lbl,cb=cb,parentCollapse=parentSec,
                 inlineRows=inlineRows,expandH=#options*L.OPT_H}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    local function addTextInput(tab,lbl,relY,placeholder,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local ph=placeholder or "click to type..."
        local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb=mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local vl=mkD(mkTx(ph,uiX+rx+cw/2+10,uiY+ry+ch/2-6,11,C.GRAY,false,8))
        local b={tab=tab,isTextInput=true,bg=bg,lbl=lb,ln=dl,valLbl=vl,
                 rx=rx,ry=ry,cw=cw,ch=ch,text="",placeholder=ph,focused=false,cb=cb,baseLbl=lbl,parentCollapse=parentSec}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    local function addKeybind(tab,lbl,relY,initKey,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg   =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl   =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb   =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local badge=mkD(mkSq(uiX+rx+cw-48,uiY+ry+ch/2-9,42,18,C.DIMGRAY,true,1,4,nil,3))
        local bLbl =mkD(mkTx(kname(initKey),uiX+rx+cw-27,uiY+ry+ch/2-6,10,C.ACCENT,true,5))
        local b={tab=tab,isKeybind=true,bg=bg,lbl=lb,ln=dl,kbBadge=badge,kbLbl=bLbl,
                 rx=rx,ry=ry,cw=cw,ch=ch,key=initKey,cb=cb,baseLbl=lbl,listening=false,parentCollapse=parentSec}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    -- ColorPicker: inline panel with R/G/B sliders below header; expandH = CP_H
    local function addColorPicker(tab,lbl,relY,initR,initG,initB,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY; local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local sw =mkD(mkSq(uiX+rx+cw-26,uiY+ry+ch/2-8,16,16,Color3.fromRGB(initR,initG,initB),true,1,4,nil,3))
        local arw=mkD(mkTx("v",uiX+rx+cw-12,uiY+ry+ch/2-7,9,C.GRAY,false,8))
        local ey=uiY+ry+ch
        local cpBg=mkD(mkSq(uiX+rx,ey,cw,L.CP_H,C.COLSEL,true,1,5,nil,0))
        local cpSw=mkD(mkSq(uiX+rx+10,ey+10,16,50,Color3.fromRGB(initR,initG,initB),true,1,6,nil,3))
        local lx=uiX+rx+L.ROW_PAD+26; local tw=cw-L.ROW_PAD*2-30
        local chanCols={Color3.fromRGB(200,60,60),Color3.fromRGB(60,190,60),Color3.fromRGB(60,130,255)}
        local initVals={initR,initG,initB}
        local cpRows={}
        for ci=1,3 do
            local ry2=ey+6+(ci-1)*20
            local frac2=initVals[ci]/255; local fx2=lx+frac2*tw
            local cl =mkD(mkTx(ci==1 and "R" or ci==2 and "G" or "B",lx-16,ry2+1,9,chanCols[ci],false,7))
            local trk=mkD(mkLn(lx,ry2+5,lx+tw,ry2+5,C.DIMGRAY,6,3))
            local fil=mkD(mkLn(lx,ry2+5,fx2,ry2+5,chanCols[ci],7,3))
            local hdl=mkD(mkSq(fx2-4,ry2+1,L.HDL,L.HDL,C.WHITE,true,1,8,nil,3))
            table.insert(cpRows,{cl,trk,fil,hdl})
        end
        local b={tab=tab,isColorPicker=true,bg=bg,lbl=lb,ln=dl,valLbl=sw,arrow=arw,
                 rx=rx,ry=ry,cw=cw,ch=ch,chanVals={initR,initG,initB},cb=cb,
                 baseLbl=lbl,draggingChan=nil,parentCollapse=parentSec,
                 cpBg=cpBg,cpSwatch=cpSw,cpRows=cpRows,expandH=L.CP_H}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    local function addLog(tab,lines,relY,starFirst)
        local rx=L.SIDEBAR+L.ROW_PAD; local cw=L.CONTENT_W-L.ROW_PAD*2
        local lineH=18; local starH=starFirst and 26 or 0; local pad=10
        local ch=starH+(#lines-(starFirst and 1 or 0))*lineH+pad*2; local ry=L.TOPBAR+relY
        local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,6))
        local lbls={}
        for i,line in ipairs(lines) do
            local lb=mkD(Drawing.new("Text"))
            if starFirst and i==1 then
                lb.Text=line; lb.Position=Vector2.new(uiX+rx+cw/2,uiY+ry+pad); lb.Size=14
                lb.Color=Color3.fromRGB(255,200,40); lb.Center=true; lb.Outline=true; lb.Font=Drawing.Fonts.Minecraft
            else
                local off=starFirst and (starH+pad+(i-2)*lineH) or (pad+(i-1)*lineH)
                lb.Text=line; lb.Position=Vector2.new(uiX+rx+8,uiY+ry+off); lb.Size=11
                lb.Color=C.WHITE; lb.Center=false; lb.Outline=true; lb.Font=Drawing.Fonts.Minecraft
            end
            lb.Transparency=1; lb.ZIndex=8; lb.Visible=false; table.insert(lbls,lb)
        end
        local b={tab=tab,isLog=true,bg=bg,lbl=bg,ln=nil,lbls=lbls,
                 rx=rx,ry=ry,cw=cw,ch=ch,lines=lines,lineH=lineH,pad=pad,starFirst=starFirst,starH=starH}
        table.insert(btns,b); b._selfIdx=#btns; return #btns
    end

    -- -- TAB API
    local tabAPI={}; local tabRowY={}

    local function getTabAPI(tabName)
        if tabAPI[tabName] then return tabAPI[tabName] end
        local api={}; tabRowY[tabName]=6
        local curSec=nil; local curSecIdx=nil
        local function nextY(h) local y=tabRowY[tabName]; tabRowY[tabName]=y+h; return y end
        function api:Div(lbl) curSec=nil; curSecIdx=nil; addDiv(tabName,lbl,nextY(20)) end
        function api:Section(lbl,open)
            local idx,name=addCollapse(tabName,lbl,nextY(20),open); curSec=name; curSecIdx=idx
        end
        function api:Toggle(lbl,init,cb,tooltip)
            local idx=addToggle(tabName,lbl,nextY(L.ROW_H+2),init,cb,tooltip,curSec)
            if curSecIdx then table.insert(btns[curSecIdx].children,idx) end
        end
        function api:Slider(lbl,minV,maxV,initV,cb,isFloat)
            local idx=addSlider(tabName,lbl,nextY(L.ROW_H+8),minV,maxV,initV,cb,isFloat,curSec)
            if curSecIdx then table.insert(btns[curSecIdx].children,idx) end
        end
        function api:Button(lbl,col,cb,lblCol) return addAct(tabName,lbl,nextY(L.ROW_H+2),col,cb,lblCol) end
        function api:Dropdown(lbl,options,initVal,cb)
            local idx=addDropdown(tabName,lbl,nextY(L.ROW_H+2),options,initVal,cb,curSec)
            if curSecIdx then table.insert(btns[curSecIdx].children,idx) end
        end
        function api:TextInput(lbl,placeholder,cb)
            local idx=addTextInput(tabName,lbl,nextY(L.ROW_H+2),placeholder,cb,curSec)
            if curSecIdx then table.insert(btns[curSecIdx].children,idx) end
        end
        function api:Keybind(lbl,initKey,cb)
            local idx=addKeybind(tabName,lbl,nextY(L.ROW_H+2),initKey,cb,curSec)
            if curSecIdx then table.insert(btns[curSecIdx].children,idx) end
        end
        function api:ColorPicker(lbl,r,g,b,cb)
            local idx=addColorPicker(tabName,lbl,nextY(L.ROW_H+2),r,g,b,cb,curSec)
            if curSecIdx then table.insert(btns[curSecIdx].children,idx) end
        end
        function api:Log(lines,starFirst)
            local lH=18; local sH=starFirst and 26 or 0
            addLog(tabName,lines,nextY(sH+(#lines-(starFirst and 1 or 0))*lH+26),starFirst)
            curSec=nil; curSecIdx=nil
        end
        tabAPI[tabName]=api; return api
    end

    -- -- INIT
    function win:Init(defaultTab, footerFn)
        dShadow =mkD(mkSq(uiX-2,uiY-2,L.W+4,L.H+4,C.SHADOW,true,0.5,0,nil,12))
        dMainBg =mkD(mkSq(uiX,uiY,L.W,L.H,C.BG,true,1,1,nil,10))
        dGlow1  =mkD(mkSq(uiX-1,uiY-1,L.W+2,L.H+2,C.ACCENT,false,0.9,1,1,11))
        dGlow2  =mkD(mkSq(uiX-2,uiY-2,L.W+4,L.H+4,C.ACCENT,false,0.35,0,2,12))
        glowLines={dGlow1,dGlow2}
        dBorder =mkD(mkSq(uiX,uiY,L.W,L.H,C.BORDER,false,0.2,3,1,10))
        dTopBar =mkD(mkSq(uiX+1,uiY+1,L.W-2,L.TOPBAR,C.TOPBAR,true,1,3,nil,9))
        dTopFill=mkD(mkSq(uiX+1,uiY+L.TOPBAR-5,L.W-2,7,C.TOPBAR,true,1,3))
        dTopLine=mkD(mkLn(uiX+1,uiY+L.TOPBAR,uiX+L.W-1,uiY+L.TOPBAR,C.BORDER,4,1))
        dTitleW =mkD(mkTx(titleA, uiX+14,    uiY+12,14,C.WHITE, false,9,true))
        dTitleA =mkD(mkTx(titleB, uiX+78,    uiY+12,14,C.ACCENT,false,9,true))
        dTitleG =mkD(mkTx(gameName,uiX+154,  uiY+12,13,C.ORANGE,false,9,false))
        dKeyLbl =mkD(mkTx("F1",  uiX+L.W-22, uiY+14,11,C.GRAY,  false,9))
        dDotY   =mkD(mkSq(uiX+L.W-55,uiY+15,8,8,C.YELLOW,true,1,9,nil,3))
        dDotR   =mkD(mkSq(uiX+L.W-42,uiY+15,8,8,Color3.fromRGB(170,44,44),true,1,9,nil,3))
        dSide   =mkD(mkSq(uiX+1,uiY+L.TOPBAR,L.SIDEBAR-1,L.H-L.TOPBAR-L.FOOTER-1,C.SIDEBAR,true,1,2,nil,8))
        dSideLn =mkD(mkLn(uiX+L.SIDEBAR,uiY+L.TOPBAR,uiX+L.SIDEBAR,uiY+L.H-L.FOOTER,C.BORDER,4,1))
        dContent=mkD(mkSq(uiX+L.SIDEBAR,uiY+L.TOPBAR,L.CONTENT_W-1,L.H-L.TOPBAR-L.FOOTER-1,C.CONTENT,true,1,2,nil,8))
        dFooter =mkD(mkSq(uiX+1,uiY+L.H-L.FOOTER,L.W-2,L.FOOTER-1,C.TOPBAR,true,1,3,nil,6))
        dFotLine=mkD(mkLn(uiX+1,uiY+L.H-L.FOOTER,uiX+L.W-1,uiY+L.H-L.FOOTER,C.BORDER,4,1))
        dFooterLbl=mkD(mkTx("",uiX+L.SIDEBAR+8,uiY+L.H-L.FOOTER+5,10,C.GRAY,false,9))
        baseUI={dShadow,dGlow2,dGlow1,dMainBg,dBorder,dTopBar,dTopFill,dTopLine,
                dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR,dSide,dSideLn,dContent,dFooter,dFotLine,dFooterLbl}
        for _,d in ipairs(baseUI) do setShow(d,true) end

        for i,name in ipairs(win._tabOrder) do
            local relTY=L.TOPBAR+8+(i-1)*34; local isSel=name==defaultTab
            local tbg  =mkD(mkSq(uiX+7,uiY+relTY,L.SIDEBAR-14,26,isSel and C.TABSEL or C.SIDEBAR,true,1,3,nil,5))
            local tacc =mkD(mkSq(uiX+7,uiY+relTY,3,26,isSel and C.ACCENT or C.SIDEBAR,true,1,4,nil,2))
            local tlW  =mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C.WHITE,false,8))
            local tlG  =mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C.GRAY, false,8))
            local tbadge=mkD(mkSq(uiX+L.SIDEBAR-16,uiY+relTY+9,6,6,C.DIMGRAY,true,1,8,nil,3))
            setShow(tbg,true); setShow(tacc,true); setShow(tlW,isSel); setShow(tlG,not isSel); setShow(tbadge,true)
            table.insert(tabObjs,{bg=tbg,acc=tacc,lbl=tlW,lblG=tlG,badge=tbadge,name=name,sel=isSel,lt=isSel and 1 or 0,relTY=relTY})
        end

        dMiniShadow =mkSq(uiX-2,uiY-2,L.W+4,L.MINI_H+4,C.SHADOW,true,0.5,0,nil,12)
        dMiniBg     =mkSq(uiX,uiY,L.W,L.MINI_H,C.BG,true,1,1,nil,10)
        dMiniGlow1  =mkSq(uiX-1,uiY-1,L.W+2,L.MINI_H+2,C.ACCENT,false,0.9,1,1,11)
        dMiniGlow2  =mkSq(uiX-2,uiY-2,L.W+4,L.MINI_H+4,C.ACCENT,false,0.35,0,2,12)
        miniGlowLines={dMiniGlow1,dMiniGlow2}
        dMiniBorder =mkSq(uiX,uiY,L.W,L.MINI_H,C.BORDER,false,0.2,3,1,10)
        dMiniTopBar =mkSq(uiX+1,uiY+1,L.W-2,L.TOPBAR,C.TOPBAR,true,1,3,nil,9)
        dMiniTitleW =mkTx(titleA,uiX+14,uiY+12,14,C.WHITE,false,9,true)
        dMiniTitleA =mkTx(titleB,uiX+78,uiY+12,14,C.ACCENT,false,9,true)
        dMiniTitleG =mkTx(gameName,uiX+154,uiY+12,13,C.ORANGE,false,9,false)
        dMiniKeyLbl =mkTx("F1",uiX+L.W-22,uiY+14,11,C.GRAY,false,9)
        dMiniDotG   =mkSq(uiX+L.W-55,uiY+15,8,8,C.GREEN,true,1,9,nil,3)
        dMiniDotR   =mkSq(uiX+L.W-42,uiY+15,8,8,Color3.fromRGB(170,44,44),true,1,9,nil,3)
        dMiniDivLn  =mkLn(uiX+1,uiY+L.TOPBAR,uiX+L.W-1,uiY+L.TOPBAR,C.BORDER,4,1)
        dMiniActiveBg=mkSq(uiX+1,uiY+L.TOPBAR,L.W-2,L.MINI_H-L.TOPBAR-1,C.MINIBAR,true,1,2,nil,8)
        miniDrawings={dMiniShadow,dMiniBg,dMiniGlow2,dMiniGlow1,dMiniBorder,dMiniTopBar,
                      dMiniTitleW,dMiniTitleA,dMiniTitleG,dMiniKeyLbl,dMiniDotG,dMiniDotR,dMiniDivLn,dMiniActiveBg}
        for _,d in ipairs(miniDrawings) do d.Visible=false end

        buildTooltip(); buildSearch()
        currentTab=defaultTab; showTab(defaultTab)
        pcall(function() notify("Loaded on "..(gameName or ""),titleA.." "..titleB,4) end)

        local focusedInputIdx=nil

        spawn(function()
        while not destroyed do
            task.wait()
            local clicking=ismouse1pressed()

            -- menu key
            local keyDown=iskeypressed(menuKey)
            if keyDown and not wasMenuKey then
                if miniClosed then
                    miniClosed=false; refreshMini(); showMiniUI(true); updateMiniPos()
                    for _,lb in ipairs(miniActiveLbls) do if lb.Text~="" then lb.Visible=true end end
                elseif minimized then
                    showMiniUI(false); miniClosed=true
                    for _,d in ipairs(allDrawings) do d.Visible=false end
                else
                    menuOpen=not menuOpen; menuToggledAt=os.clock()
                    if not menuOpen then closeInline() end
                end
            end
            wasMenuKey=keyDown

            -- keybind row listener
            if listenKeybindIdx then
                for k=0x08,0xDD do
                    if iskeypressed(k) and k~=0x01 and k~=0x02 and k~=menuKey then
                        local b=btns[listenKeybindIdx]
                        if b then
                            b.key=k; b.kbLbl.Text=kname(k); b.kbLbl.Color=C.ACCENT
                            b.kbBadge.Color=C.DIMGRAY; b.listening=false
                            if b.cb then pcall(b.cb,k) end
                            pcall(function() notify(b.baseLbl..": "..kname(k),"Keybind",3) end)
                        end
                        listenKeybindIdx=nil; break
                    end
                end
            end

            -- text input keyboard
            if focusedInputIdx then
                local b=btns[focusedInputIdx]
                if b then
                    for k=0x08,0xDD do
                        if iskeypressed(k) then
                            if k==0x08 then if #b.text>0 then b.text=b.text:sub(1,-2) end
                            elseif k==0x0D or k==0x1B then
                                b.bg.Color=C.ROWBG; focusedInputIdx=nil
                                if b.cb then pcall(b.cb,b.text) end
                                pcall(function() notify(b.baseLbl..": "..(b.text~="" and b.text or "(empty)"),nil,2) end)
                                break
                            elseif kn[k] then b.text=b.text..kn[k]:lower() end
                            b.valLbl.Text=#b.text>0 and b.text or b.placeholder
                            b.valLbl.Color=#b.text>0 and C.WHITE or C.GRAY
                            task.wait(0.07); break
                        end
                    end
                end
            end

            -- search keyboard
            if searchActive then
                for k=0x08,0xDD do
                    if iskeypressed(k) then
                        if k==0x08 then if #searchText>0 then searchText=searchText:sub(1,-2) end
                        elseif k==0x1B then searchText=""; searchActive=false
                        elseif kn[k] then searchText=searchText..kn[k]:lower() end
                        sLbl.Text="/ "..(searchText=="" and "search..." or searchText)
                        applySearch(); task.wait(0.07); break
                    end
                end
            end

            -- MINI MODE
            if minimized and not miniClosed then
                local t2=os.clock()
                for i,sq in ipairs(miniGlowLines) do
                    local p=t2+glowPhase[i]
                    local r=math.floor(15+45*math.max(0,math.sin(p+1.0)))
                    local g=math.floor(25+55*math.max(0,math.sin(p+0.4)))
                    local bl=math.floor(130+125*math.max(0,math.sin(p)))
                    sq.Color=Color3.fromRGB(r,g,bl); sq.Transparency=(i==1 and 0.6 or 0.75)+0.25*math.abs(math.sin(p*0.5))
                end
                local pt=os.clock()*0.8
                for i,lb in ipairs(miniActiveLbls) do
                    if lb.Text~="" then lb.Visible=true; lb.Color=lerpC(Color3.fromRGB(30,50,160),C.WHITE,(math.sin(pt+miniActivePulse[i])+1)/2)
                    else lb.Visible=false end
                end
                if clicking and not wasClicking then
                    if inBox(uiX+L.W-46,uiY+11,12,12) then showMiniUI(false); miniClosed=true; for _,d in ipairs(allDrawings) do d.Visible=false end
                    elseif inBox(uiX+L.W-59,uiY+11,12,12) then restoreFullMenu()
                    else miniDragging=true; miniDragOffX=mouse.X-uiX; miniDragOffY=mouse.Y-uiY end
                end
                if not clicking then miniDragging=false end
                if miniDragging and clicking then uiX=mouse.X-miniDragOffX; uiY=mouse.Y-miniDragOffY; updateMiniPos() end
                wasClicking=clicking
            end

            if not minimized then
                for _,lb in ipairs(miniActiveLbls) do lb.Visible=false end
                -- tab lerp
                for _,t in ipairs(tabObjs) do
                    local tgt=t.sel and 1 or 0; t.lt=t.lt+(tgt-t.lt)*0.15
                    t.bg.Color=lerpC(C.SIDEBAR,C.TABSEL,t.lt); t.acc.Color=lerpC(C.SIDEBAR,C.ACCENT,t.lt)
                end
                -- toggle lerp
                for i,b in ipairs(btns) do
                    if b.isTog and b.tog and showSet[b.tog] then
                        local tgt=b.state and 1 or 0; b.lt=b.lt+(tgt-b.lt)*0.18
                        b.tog.Color=lerpC(C.OFF,C.ON,b.lt); b.dot.Color=lerpC(C.OFFDOT,C.ONDOT,b.lt)
                        local ay2=screenY(b,i); local togY2=ay2+b.ch/2-L.TOG_H/2; local togX2=uiX+b.rx+b.togOffX
                        b.dot.Position=Vector2.new(togX2+2+(L.TOG_W-L.TOG_H)*b.lt,togY2+2)
                    end
                end
                -- glow anim
                do
                    local t2=os.clock()
                    for i,sq in ipairs(glowLines) do
                        local p=t2+glowPhase[i]
                        local r=math.floor(15+45*math.max(0,math.sin(p+1.0)))
                        local g=math.floor(25+55*math.max(0,math.sin(p+0.4)))
                        local bl=math.floor(130+125*math.max(0,math.sin(p)))
                        sq.Color=Color3.fromRGB(r,g,bl); sq.Transparency=(i==1 and 0.6 or 0.75)+0.25*math.abs(math.sin(p*0.5))
                    end
                end
                applyFade()

                -- prev tab cleanup
                if prevTab and (os.clock()-tabSwitchedAt)>=TAB_FADE_DUR then
                    for _,b in ipairs(btns) do if b.tab==prevTab then bShow(b,false) end end
                    for _,d in ipairs(allDrawings) do if tabSet[d]=="prev" then tabSet[d]=nil end end
                    prevTab=nil
                end

                local mfn=1-(menuToggledAt-(os.clock()-FADE_DUR))/FADE_DUR
                local mOp=math.abs((menuOpen and 0 or 1)-clamp(mfn,0,1))

                -- tooltip hover
                if mOp>0.5 then
                    local tip=nil
                    for i,b in ipairs(btns) do
                        if b.tab==currentTab and b.ttIcon and showSet[b.ttIcon] then
                            if inBox(uiX+b.rx+b.cw-22,screenY(b,i),18,b.ch) then tip=b.tooltip; break end
                        end
                    end
                    if tip then showTT(tip,mouse.X,mouse.Y) else hideTT() end
                else hideTT() end

                if clicking and not wasClicking and mOp>0.5 then
                    -- search bar click
                    if inBox(uiX+L.SIDEBAR,uiY+L.TOPBAR,L.CONTENT_W-1,L.SEARCH_H) then
                        searchActive=true
                        if focusedInputIdx then btns[focusedInputIdx].bg.Color=C.ROWBG; focusedInputIdx=nil end
                    else searchActive=false end

                    -- dots
                    if inBox(uiX+L.W-59,uiY+11,12,12) then       -- yellow: minimize
                        minimized=true; miniClosed=false; menuOpen=false; closeInline()
                        for _,d in ipairs(allDrawings) do d.Visible=false end
                        refreshMini(); showMiniUI(true); updateMiniPos()
                        for _,lb in ipairs(miniActiveLbls) do if lb.Text~="" then lb.Visible=true end end
                    elseif inBox(uiX+L.W-46,uiY+11,12,12) then    -- red: close
                        menuOpen=false; menuToggledAt=os.clock(); closeInline()
                    elseif inBox(uiX,uiY,L.W,L.TOPBAR) then       -- topbar drag
                        dragging=true; dragOffX=mouse.X-uiX; dragOffY=mouse.Y-uiY
                    end

                    -- sidebar tabs
                    for _,t in ipairs(tabObjs) do
                        if inBox(uiX+7,uiY+t.relTY,L.SIDEBAR-14,26) then
                            switchTab(t.name)
                            if focusedInputIdx then btns[focusedInputIdx].bg.Color=C.ROWBG; focusedInputIdx=nil end
                        end
                    end

                    -- content row clicks
                    local clickHandled=false
                    for i,b in ipairs(btns) do
                        if clickHandled then break end
                        if b.tab==currentTab and showSet[b.bg] then
                            local ax=uiX+b.rx; local ay=screenY(b,i)

                            -- dropdown option click (when this dropdown is open)
                            if not clickHandled and b.isDropdown and openInlineIdx==i and b.inlineRows then
                                for oi,ir in ipairs(b.inlineRows) do
                                    local oy=ay+b.ch+(oi-1)*L.OPT_H
                                    if inBox(ax,oy,b.cw,L.OPT_H) then
                                        b.value=ir.option; b.valLbl.Text=ir.option
                                        for _,ir2 in ipairs(b.inlineRows) do
                                            ir2.bg.Color=(ir2.option==b.value) and C.OPTSEL or C.OPTROW
                                            ir2.lbl.Color=(ir2.option==b.value) and C.ACCENT or C.GRAY
                                        end
                                        if b.cb then pcall(b.cb,b.value) end
                                        pcall(function() notify(b.baseLbl..": "..b.value,nil,2) end)
                                        closeInline(); reposTab(currentTab); clickHandled=true; break
                                    end
                                end
                            end

                            -- main row click
                            if not clickHandled and inBox(ax,ay,b.cw,b.ch) then
                                if b.isTog then
                                    b.state=not b.state
                                    if b.cb then pcall(b.cb,b.state) end
                                    pcall(function() notify(b.toggleName.." "..(b.state and "enabled" or "disabled"),nil,2) end)
                                    refreshMini(); updateBadges()
                                elseif b.isAct then
                                    if iKeyBind and i==iKeyBind and not listenMenuKey then
                                        listenMenuKey=true; btns[iKeyBind].lbl.Text="Press any key..."
                                    elseif b.cb then
                                        pcall(b.cb)
                                        pcall(function() if b.baseLbl and b.baseLbl~="" then notify(b.baseLbl,"Action",2) end end)
                                    end
                                elseif b.isDropdown then
                                    if openInlineIdx==i then closeInline(); reposTab(currentTab)
                                    else
                                        closeInline(); openInlineIdx=i; b.arrow.Text="^"
                                        for _,ir in ipairs(b.inlineRows) do ir.bg.Visible=true; ir.lbl.Visible=true end
                                        reposTab(currentTab)
                                    end
                                elseif b.isColorPicker then
                                    if openInlineIdx==i then closeInline(); reposTab(currentTab)
                                    else
                                        closeInline(); openInlineIdx=i; b.arrow.Text="^"
                                        b.cpBg.Visible=true; b.cpSwatch.Visible=true
                                        for _,row in ipairs(b.cpRows) do for _,d in ipairs(row) do d.Visible=true end end
                                        reposTab(currentTab)
                                    end
                                elseif b.isTextInput then
                                    if focusedInputIdx then btns[focusedInputIdx].bg.Color=C.ROWBG end
                                    focusedInputIdx=i; b.bg.Color=C.TABSEL; closeInline(); reposTab(currentTab)
                                elseif b.isKeybind then
                                    if listenKeybindIdx then
                                        local pb=btns[listenKeybindIdx]; if pb then pb.kbBadge.Color=C.DIMGRAY; pb.listening=false end
                                    end
                                    if listenKeybindIdx==i then
                                        listenKeybindIdx=nil; b.listening=false; b.kbBadge.Color=C.DIMGRAY
                                    else
                                        listenKeybindIdx=i; b.listening=true
                                        b.kbBadge.Color=C.TABSEL; b.kbLbl.Text="..."; b.kbLbl.Color=C.WHITE
                                        pcall(function() notify("Press any key to bind "..b.baseLbl,nil,2) end)
                                    end
                                elseif b.isCollapse then
                                    openCollapse[b.sectionName]=not openCollapse[b.sectionName]
                                    local isOpen=openCollapse[b.sectionName]
                                    b.arrow.Text=isOpen and "v" or ">"
                                    b.lbl.Color=isOpen and C.WHITE or C.GRAY
                                    for _,ci in ipairs(b.children) do
                                        if btns[ci] then bShow(btns[ci],isOpen); if isOpen then bPos(btns[ci],ci) end end
                                    end
                                    pcall(function() notify(b.sectionName.." "..(isOpen and "expanded" or "collapsed"),nil,2) end)
                                end
                                clickHandled=true
                            end
                        end
                    end
                end

                -- sliders drag
                for i,b in ipairs(btns) do
                    if b.isSlider and b.tab==currentTab and showSet[b.bg] then
                        local ax=uiX+b.rx+8; local ay=screenY(b,i); local ty=ay+b.ch-11
                        if clicking and not wasClicking then
                            if inBox(uiX+b.rx,ay,b.cw,b.ch) then b.dragging=true end
                        end
                        if not clicking and wasClicking and b.dragging then
                            pcall(function() notify(b.baseLbl..": "..(b.isFloat and string.format("%.1f",b.value) or math.floor(b.value)),nil,2) end)
                        end
                        if not clicking then b.dragging=false end
                        if b.dragging and clicking then
                            local frac=clamp((mouse.X-ax)/b.trackW,0,1)
                            b.value=b.minV+frac*(b.maxV-b.minV); local fx=ax+frac*b.trackW
                            b.track.From=Vector2.new(ax,ty); b.track.To=Vector2.new(ax+b.trackW,ty)
                            b.fill.From=Vector2.new(ax,ty);  b.fill.To=Vector2.new(fx,ty)
                            b.handle.Position=Vector2.new(fx-4,ty-4)
                            b.lbl.Text=b.baseLbl..": "..(b.isFloat and string.format("%.1f",b.value) or math.floor(b.value))
                            if b.cb then pcall(b.cb,b.value) end
                        end
                    end
                end

                -- colorpicker drag
                for i,b in ipairs(btns) do
                    if b.isColorPicker and b.tab==currentTab and openInlineIdx==i and showSet[b.bg] then
                        local ax=uiX+b.rx; local ay=screenY(b,i)
                        local lx=ax+L.ROW_PAD+26; local tw=b.cw-L.ROW_PAD*2-30
                        local ey=ay+b.ch
                        for ci=1,3 do
                            local ry2=ey+6+(ci-1)*20+5
                            if clicking and not wasClicking then
                                if inBox(lx,ry2-6,tw,12) then b.draggingChan=ci end
                            end
                            if not clicking then
                                if b.draggingChan then
                                    pcall(function() notify(b.baseLbl.." color updated",nil,2) end)
                                end
                                b.draggingChan=nil
                            end
                            if b.draggingChan==ci and clicking then
                                local frac=clamp((mouse.X-lx)/tw,0,1)
                                b.chanVals[ci]=math.floor(frac*255)
                                local newCol=Color3.fromRGB(b.chanVals[1],b.chanVals[2],b.chanVals[3])
                                b.valLbl.Color=newCol; b.cpSwatch.Color=newCol
                                local row=b.cpRows[ci]
                                local fx2=lx+frac*tw
                                row[2].From=Vector2.new(lx,ry2); row[2].To=Vector2.new(lx+tw,ry2)
                                row[3].From=Vector2.new(lx,ry2); row[3].To=Vector2.new(fx2,ry2)
                                row[4].Position=Vector2.new(fx2-4,ry2-4)
                                if b.cb then pcall(b.cb,newCol) end
                            end
                        end
                    end
                end

                -- drag window
                if not clicking then dragging=false end
                if dragging and clicking then uiX=mouse.X-dragOffX; uiY=mouse.Y-dragOffY; updatePos() end
                wasClicking=clicking

                -- menu key rebind
                if listenMenuKey then
                    for k=0x08,0xDD do
                        if iskeypressed(k) and k~=0x01 and k~=0x02 then
                            menuKey=k; local n=kname(k)
                            if iKeyInfo then btns[iKeyInfo].lbl.Text="Menu Key: "..n end
                            if iKeyBind then btns[iKeyBind].lbl.Text="Click to Rebind" end
                            dKeyLbl.Text=n; dMiniKeyLbl.Text=n; listenMenuKey=false
                            pcall(function() notify("Menu key set to "..n,"Keybind",3) end)
                            break
                        end
                    end
                end

                if footerFn then dFooterLbl.Text=footerFn() end
            end
        end
        end)
    end

    win._tabOrder={}
    function win:Tab(name) table.insert(win._tabOrder,name); return getTabAPI(name) end

    function win:SettingsTab(destroyCb)
        local s=self:Tab("Settings")
        s:Div("KEYBIND")
        iKeyInfo=s:Button("Menu Key: F1",   C.ROWBG,nil,nil)
        iKeyBind=s:Button("Click to Rebind",Color3.fromRGB(14,20,40),nil,nil)
        s:Div("PROFILES")
        s:Button("Save Profile",C.ROWBG,function() saveProfile("Default") end,C.ACCENT)
        s:Button("Load Profile",C.ROWBG,function() loadProfile("Default") end,C.WHITE)
        s:Div("DANGER")
        s:Button("Destroy Menu",Color3.fromRGB(28,7,7),destroyCb,C.RED)
        return s
    end

    function win:Destroy()
        destroyed=true
        pcall(function() notify("UI destroyed.",titleA.." "..titleB,3) end)
        for _,d in ipairs(allDrawings) do pcall(function() d:Remove() end) end
        for _,d in ipairs(miniDrawings) do pcall(function() d:Remove() end) end
        for _,l in ipairs(miniActiveLbls) do pcall(function() l:Remove() end) end
        for _,d in ipairs({ttBg,ttBdr,ttTx,sBg,sLn,sLbl}) do if d then pcall(function() d:Remove() end) end end
    end

    return win
end

_G.UILib = UILib
