--[[
    uilib.lua :3
    by hitechboi / nejrio >_<
    updated with: dropdown, textinput, keybind rows,
    colorpicker, collapsible sections, tooltips,
    search bar, profiles, tab badges, notif queue
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
}
UILib.Colors = C

local L = {
    W        = 440, H        = 380,
    SIDEBAR  = 128, TOPBAR   = 40,
    FOOTER   = 22,  ROW_H    = 40,
    ROW_PAD  = 10,  TOG_W    = 34,
    TOG_H    = 17,  HDL      = 8,
    MINI_H   = 86,
    SEARCH_H = 24,
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

-- key name table
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

-- ============================================================
-- WINDOW
-- ============================================================
function UILib.Window(titleA, titleB, gameName)
    local win = {}
    local mouse = game.Players.LocalPlayer:GetMouse()

    -- state
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

    -- search
    local searchText          = ""
    local searchActive        = false

    -- notif queue
    local notifQueue          = {}
    local notifShowing        = false
    local notifUntil          = 0

    -- profiles
    local profiles            = {}   -- { name -> { toggleName -> bool, sliderName -> number } }
    local activeProfile       = nil

    -- keybind listen
    local listenKeybindBtn    = nil  -- button index that is waiting for key

    -- open dropdown / colorpicker (only one at a time)
    local openDropdown        = nil
    local openColorPicker     = nil
    local openCollapse        = {}   -- sectionName -> bool (true = open)

    -- drawing registry
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
        local lb = mkTx("",0,0,13,C.WHITE,false,9,false)
        lb.Outline=true; lb.Visible=false; lb.Transparency=1
        table.insert(miniActiveLbls,lb)
        table.insert(miniActivePulse,i*0.7)
    end

    -- notif drawings (persistent, managed separately)
    local nBg, nBorder, nTitle, nMsg, nBar
    local function buildNotifDrawings()
        local nx=uiX+L.W+10; local ny=uiY
        nBg     = mkSq(nx,ny,200,44,C.ROWBG,true,1,20,nil,6)
        nBorder = mkSq(nx,ny,200,44,C.ACCENT,false,0.4,21,1,6)
        nBar    = mkSq(nx,ny,3,44,C.ACCENT,true,1,22,nil,3)
        nTitle  = mkTx("",nx+10,ny+7,9,C.ACCENT,false,23)
        nMsg    = mkTx("",nx+10,ny+20,11,C.WHITE,false,23)
        nBg.Visible=false; nBorder.Visible=false
        nBar.Visible=false; nTitle.Visible=false; nMsg.Visible=false
    end
    local function updateNotifPos()
        if not nBg then return end
        local nx=uiX+L.W+10; local ny=uiY+50
        nBg.Position=Vector2.new(nx,ny)
        nBorder.Position=Vector2.new(nx,ny)
        nBar.Position=Vector2.new(nx,ny)
        nTitle.Position=Vector2.new(nx+10,ny+7)
        nMsg.Position=Vector2.new(nx+10,ny+20)
    end
    local function showNotifDrawing(title,msg)
        if not nBg then return end
        nTitle.Text=title; nMsg.Text=msg
        nBg.Visible=true; nBorder.Visible=true
        nBar.Visible=true; nTitle.Visible=true; nMsg.Visible=true
    end
    local function hideNotifDrawing()
        if not nBg then return end
        nBg.Visible=false; nBorder.Visible=false
        nBar.Visible=false; nTitle.Visible=false; nMsg.Visible=false
    end

    -- tooltip drawing
    local ttBg, ttTx
    local ttVisible = false
    local function buildTooltipDrawings()
        ttBg = mkSq(0,0,120,22,C.COLSEL,true,1,30,nil,4)
        ttTx = mkTx("",0,0,10,C.GRAY,false,31)
        ttBg.Visible=false; ttTx.Visible=false
    end
    local function showTooltip(text,x,y)
        if not ttBg then return end
        local w=math.max(80,#text*7+16)
        ttBg.Size=Vector2.new(w,20)
        ttBg.Position=Vector2.new(x-w-4,y-10)
        ttTx.Position=Vector2.new(x-w+4,y-7)
        ttTx.Text=text
        ttBg.Visible=true; ttTx.Visible=true
        ttVisible=true
    end
    local function hideTooltip()
        if ttBg then ttBg.Visible=false; ttTx.Visible=false end
        ttVisible=false
    end

    -- search bar drawings
    local sBg, sLbl, sCursor
    local function buildSearchDrawings()
        local sx=uiX+L.SIDEBAR; local sy=uiY+L.TOPBAR
        sBg    = mkSq(sx,sy,L.CONTENT_W-1,L.SEARCH_H,C.TOPBAR,true,1,4,nil,0)
        sLbl   = mkTx("Search: _",sx+8,sy+6,10,C.GRAY,false,5)
        sCursor= mkLn(sx+8,sy+16,sx+9,sy+16,C.ACCENT,6,1)
        sBg.Visible=false; sLbl.Visible=false; sCursor.Visible=false
    end
    local function updateSearchPos()
        if not sBg then return end
        local sx=uiX+L.SIDEBAR; local sy=uiY+L.TOPBAR
        sBg.Position=Vector2.new(sx,sy)
        sBg.Size=Vector2.new(L.CONTENT_W-1,L.SEARCH_H)
        sLbl.Position=Vector2.new(sx+8,sy+6)
        sCursor.From=Vector2.new(sx+8,sy+16)
        sCursor.To=Vector2.new(sx+9,sy+16)
    end

    -- dropdown drawing pool
    local ddBg, ddOpts = nil, {}
    local DD_MAX = 8
    local function buildDropdownDrawings()
        ddBg = mkSq(0,0,10,10,C.COLSEL,true,1,25,nil,4)
        ddBg.Visible=false
        for i=1,DD_MAX do
            local bg  = mkSq(0,0,10,16,C.COLSEL,true,1,26,nil,0)
            local lbl = mkTx("",0,0,11,C.GRAY,false,27)
            bg.Visible=false; lbl.Visible=false
            table.insert(ddOpts,{bg=bg,lbl=lbl,selected=false})
        end
    end
    local function hideDropdown()
        if ddBg then ddBg.Visible=false end
        for _,o in ipairs(ddOpts) do o.bg.Visible=false; o.lbl.Visible=false end
        openDropdown=nil
    end
    local function showDropdown(b)
        hideDropdown()
        openDropdown=b
        local ax=uiX+b.rx; local ay=uiY+b.ry+b.ch
        local w=b.cw; local oh=18
        local totalH=#b.options*oh+4
        ddBg.Position=Vector2.new(ax,ay); ddBg.Size=Vector2.new(w,totalH)
        ddBg.Visible=true
        for i,opt in ipairs(b.options) do
            local oBg =ddOpts[i] and ddOpts[i].bg
            local oLbl=ddOpts[i] and ddOpts[i].lbl
            if oBg and oLbl then
                oBg.Position=Vector2.new(ax,ay+2+(i-1)*oh)
                oBg.Size=Vector2.new(w,oh-1)
                oBg.Color= (opt==b.value) and C.TABSEL or C.COLSEL
                oBg.Visible=true
                oLbl.Text=opt
                oLbl.Position=Vector2.new(ax+8,ay+5+(i-1)*oh)
                oLbl.Color=(opt==b.value) and C.ACCENT or C.GRAY
                oLbl.Visible=true
                ddOpts[i].selected=(opt==b.value)
                ddOpts[i].option=opt
                ddOpts[i].index=i
            end
        end
    end

    -- colorpicker drawing
    local cpBg, cpR_track, cpR_fill, cpR_hdl
    local cpG_track, cpG_fill, cpG_hdl
    local cpB_track, cpB_fill, cpB_hdl
    local cpSwatch, cpLblR, cpLblG, cpLblB
    local cpAllDrawings = {}
    local function buildColorPickerDrawings()
        cpBg       = mkSq(0,0,10,10,C.COLSEL,true,1,25,nil,4)
        cpSwatch   = mkSq(0,0,16,16,C.WHITE,true,1,27,nil,3)
        cpLblR     = mkTx("R",0,0,10,Color3.fromRGB(210,80,80),false,27)
        cpLblG     = mkTx("G",0,0,10,Color3.fromRGB(80,190,80),false,27)
        cpLblB     = mkTx("B",0,0,10,Color3.fromRGB(80,140,255),false,27)
        cpR_track  = mkLn(0,0,10,0,C.DIMGRAY,26,3)
        cpR_fill   = mkLn(0,0,10,0,Color3.fromRGB(210,80,80),27,3)
        cpR_hdl    = mkSq(0,0,L.HDL,L.HDL,C.WHITE,true,1,28,nil,3)
        cpG_track  = mkLn(0,0,10,0,C.DIMGRAY,26,3)
        cpG_fill   = mkLn(0,0,10,0,Color3.fromRGB(80,190,80),27,3)
        cpG_hdl    = mkSq(0,0,L.HDL,L.HDL,C.WHITE,true,1,28,nil,3)
        cpB_track  = mkLn(0,0,10,0,C.DIMGRAY,26,3)
        cpB_fill   = mkLn(0,0,10,0,Color3.fromRGB(80,140,255),27,3)
        cpB_hdl    = mkSq(0,0,L.HDL,L.HDL,C.WHITE,true,1,28,nil,3)
        cpAllDrawings={cpBg,cpSwatch,cpLblR,cpLblG,cpLblB,
                       cpR_track,cpR_fill,cpR_hdl,
                       cpG_track,cpG_fill,cpG_hdl,
                       cpB_track,cpB_fill,cpB_hdl}
        for _,d in ipairs(cpAllDrawings) do d.Visible=false end
    end
    local function hideColorPicker()
        for _,d in ipairs(cpAllDrawings) do d.Visible=false end
        openColorPicker=nil
    end
    local function updateColorPickerDrawings(b)
        if not b then return end
        local ax=uiX+b.rx; local ay=uiY+b.ry+b.ch
        local w=b.cw; local pad=10; local trackW=w-pad*2-20
        cpBg.Position=Vector2.new(ax,ay); cpBg.Size=Vector2.new(w,68)
        cpBg.Visible=true
        cpSwatch.Position=Vector2.new(ax+pad,ay+8)
        cpSwatch.Color=Color3.fromRGB(b.r,b.g,b.b); cpSwatch.Visible=true
        local lx=ax+pad+24; local rows={ay+11,ay+30,ay+49}
        local chans={
            {cpLblR,cpR_track,cpR_fill,cpR_hdl,b.r,Color3.fromRGB(210,80,80)},
            {cpLblG,cpG_track,cpG_fill,cpG_hdl,b.g,Color3.fromRGB(80,190,80)},
            {cpLblB,cpB_track,cpB_fill,cpB_hdl,b.b,Color3.fromRGB(80,140,255)},
        }
        for i,ch in ipairs(chans) do
            local ry=rows[i]
            ch[1].Position=Vector2.new(lx,ry-2); ch[1].Visible=true
            local tx=lx+14; local tx2=tx+trackW
            ch[2].From=Vector2.new(tx,ry+4); ch[2].To=Vector2.new(tx2,ry+4); ch[2].Visible=true
            local frac=ch[5]/255
            local fx=tx+frac*trackW
            ch[3].From=Vector2.new(tx,ry+4); ch[3].To=Vector2.new(fx,ry+4); ch[3].Color=ch[6]; ch[3].Visible=true
            ch[4].Position=Vector2.new(fx-4,ry); ch[4].Visible=true
        end
    end
    local function showColorPicker(b)
        hideColorPicker()
        openColorPicker=b
        updateColorPickerDrawings(b)
    end

    local function mkD(d)
        table.insert(allDrawings,d); d.Visible=false; return d
    end
    local function setShow(d,yes)
        showSet[d]=yes or nil; d.Visible=yes and true or false
    end
    local function inBox(x,y,w,h)
        return mouse.X>=x and mouse.X<=x+w and mouse.Y>=y and mouse.Y<=y+h
    end

    -- ── FADE / SHOW
    local function applyFade()
        if minimized then
            for _,d in ipairs(allDrawings) do d.Visible=false end
            return
        end
        if not minimized then for _,lb in ipairs(miniActiveLbls) do lb.Visible=false end end
        local mf=1-(menuToggledAt-(os.clock()-FADE_DUR))/FADE_DUR
        if not menuOpen and mf>=1.1 then
            for _,d in ipairs(allDrawings) do d.Visible=false end
            return
        end
        local mOp=mf<1.1
            and math.abs((menuOpen and 0 or 1)-clamp(mf,0,1))
            or  (menuOpen and 1 or 0)
        local tp=clamp((os.clock()-tabSwitchedAt)/TAB_FADE_DUR,0,1)
        for _,d in ipairs(allDrawings) do
            if showSet[d] then
                local tOp=tabSet[d]=="next" and tp or tabSet[d]=="prev" and (1-tp) or 1
                local op=mOp*tOp
                d.Visible=op>0.01; d.Transparency=op
            else
                d.Visible=false
            end
        end
        -- search bar visibility
        if sBg then
            local vis=menuOpen and mOp>0.5
            sBg.Visible=vis; sLbl.Visible=vis; sCursor.Visible=vis and searchActive
        end
    end

    local function bShow(b,yes)
        setShow(b.bg,yes)
        if not b.isLog then setShow(b.lbl,yes) end
        if b.ln       then setShow(b.ln,    yes) end
        if b.tog      then setShow(b.tog,   yes) end
        if b.dot      then setShow(b.dot,   yes) end
        if b.track    then setShow(b.track, yes) end
        if b.fill     then setShow(b.fill,  yes) end
        if b.handle   then setShow(b.handle,yes) end
        if b.lbls     then for _,l in ipairs(b.lbls) do setShow(l,yes) end end
        if b.valLbl   then setShow(b.valLbl,yes) end
        if b.arrow    then setShow(b.arrow, yes) end
        if b.kbBadge  then setShow(b.kbBadge,yes) end
        if b.ttIcon   then setShow(b.ttIcon, yes) end
        -- collapsible children
        if b.isCollapse then
            local sectionOpen = openCollapse[b.sectionName]
            if b.children then
                for _,ci in ipairs(b.children) do
                    if btns[ci] then bShow(btns[ci], yes and sectionOpen) end
                end
            end
        end
    end

    local SEARCH_CONTENT_OFFSET = L.SEARCH_H  -- content starts lower when search shown

    local function bPos(b)
        local extraY = SEARCH_CONTENT_OFFSET
        local ax=uiX+b.rx; local ay=uiY+b.ry+extraY
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
            b.valLbl.Position=Vector2.new(ax+b.cw-50,ay+b.ch/2-6)
            b.arrow.Position=Vector2.new(ax+b.cw-14,ay+b.ch/2-6)
        elseif b.isColorPicker then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.valLbl.Position=Vector2.new(ax+b.cw-24,ay+b.ch/2-8)
            b.arrow.Position=Vector2.new(ax+b.cw-12,ay+b.ch/2-6)
        elseif b.isTextInput then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.valLbl.Position=Vector2.new(ax+b.cw/2+10,ay+b.ch/2-6)
        elseif b.isKeybind then
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            b.kbBadge.Position=Vector2.new(ax+b.cw-46,ay+b.ch/2-8)
        else -- toggle
            b.lbl.Position=Vector2.new(ax+10,ay+b.ch/2-6)
            b.ln.From=Vector2.new(ax,ay+b.ch); b.ln.To=Vector2.new(ax+b.cw,ay+b.ch)
            if b.tog then
                b.tog.Position=Vector2.new(uiX+b.ox,uiY+b.oy+extraY)
                b.dot.Position=Vector2.new(uiX+b.ox+2+(L.TOG_W-L.TOG_H)*b.lt,uiY+b.oy+2+extraY)
            end
            if b.ttIcon then b.ttIcon.Position=Vector2.new(ax+b.cw-20,ay+b.ch/2-5) end
        end
    end

    local function tagBtnFade(b,group)
        tabSet[b.bg]=group
        if not b.isLog then tabSet[b.lbl]=group end
        if b.ln      then tabSet[b.ln]=group     end
        if b.tog     then tabSet[b.tog]=group    end
        if b.dot     then tabSet[b.dot]=group    end
        if b.track   then tabSet[b.track]=group  end
        if b.fill    then tabSet[b.fill]=group   end
        if b.handle  then tabSet[b.handle]=group end
        if b.valLbl  then tabSet[b.valLbl]=group end
        if b.arrow   then tabSet[b.arrow]=group  end
        if b.kbBadge then tabSet[b.kbBadge]=group end
        if b.ttIcon  then tabSet[b.ttIcon]=group end
        if b.lbls    then for _,l in ipairs(b.lbls) do tabSet[l]=group end end
    end

    local function showTab(tab)
        for _,b in ipairs(btns) do
            local yes = b.tab==tab
            if b.isCollapse then
                bShow(b,yes)
            elseif b.parentCollapse then
                -- only show if parent section is open
                local sec = b.parentCollapse
                bShow(b, yes and (openCollapse[sec] or false))
            else
                bShow(b,yes)
            end
            if yes then bPos(b) end
        end
    end

    local function applySearch()
        if searchText=="" then
            showTab(currentTab); return
        end
        local q=searchText:lower()
        for _,b in ipairs(btns) do
            if b.tab==currentTab then
                local name=(b.toggleName or b.baseLbl or b.sectionName or ""):lower()
                local match=name:find(q,1,true)
                bShow(b, match~=nil)
                if match then bPos(b) end
            end
        end
    end

    local function switchTab(name)
        if name==currentTab then return end
        prevTab=currentTab; currentTab=name; tabSwitchedAt=os.clock()
        searchText=""; searchActive=false
        if sLbl then sLbl.Text="Search: _" end
        for _,t in ipairs(tabObjs) do
            t.sel=t.name==name
            setShow(t.lbl,t.sel); setShow(t.lblG,not t.sel)
            -- update badge color: green if active toggles, accent accent
            if t.badge then
                local hasActive=false
                for _,b in ipairs(btns) do
                    if b.tab==t.name and b.isTog and b.state then hasActive=true; break end
                end
                t.badge.Color = hasActive and C.GREEN or C.DIMGRAY
            end
        end
        for _,d in ipairs(allDrawings) do tabSet[d]=nil end
        if prevTab then
            for _,b in ipairs(btns) do if b.tab==prevTab then bShow(b,true); bPos(b); tagBtnFade(b,"prev") end end
        end
        for _,b in ipairs(btns) do if b.tab==name then bShow(b,true); bPos(b); tagBtnFade(b,"next") end end
        if openDropdown then hideDropdown() end
        if openColorPicker then hideColorPicker() end
    end

    local function updateTabBadges()
        for _,t in ipairs(tabObjs) do
            if t.badge then
                local hasActive=false
                for _,b in ipairs(btns) do
                    if b.tab==t.name and b.isTog and b.state then hasActive=true; break end
                end
                t.badge.Color = hasActive and C.GREEN or C.DIMGRAY
            end
        end
    end

    -- ── POSITION UPDATE
    local dShadow,dMainBg,dGlow1,dGlow2,dBorder
    local dTopBar,dTopFill,dTopLine
    local dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR
    local dSide,dSideLn,dContent,dFooter,dFotLine,dCharLbl
    local glowLines
    local dMiniShadow,dMiniBg,dMiniGlow1,dMiniGlow2,dMiniBorder
    local dMiniTopBar,dMiniTitleW,dMiniTitleA,dMiniTitleG
    local dMiniKeyLbl,dMiniDotG,dMiniDotR,dMiniDivLn,dMiniActiveBg
    local miniGlowLines
    local iKeyInfo, iKeyBind

    local function updatePos()
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
        dTitleA.Position  =Vector2.new(uiX+78,uiY+12)
        dTitleG.Position  =Vector2.new(uiX+154,uiY+12)
        dKeyLbl.Position  =Vector2.new(uiX+L.W-22,uiY+14)
        dDotY.Position    =Vector2.new(uiX+L.W-55,uiY+15)
        dDotR.Position    =Vector2.new(uiX+L.W-42,uiY+15)
        dSide.Position    =Vector2.new(uiX+1,uiY+L.TOPBAR)
        dSideLn.From      =Vector2.new(uiX+L.SIDEBAR,uiY+L.TOPBAR)
        dSideLn.To        =Vector2.new(uiX+L.SIDEBAR,uiY+L.H-L.FOOTER)
        dContent.Position =Vector2.new(uiX+L.SIDEBAR,uiY+L.TOPBAR)
        dFooter.Position  =Vector2.new(uiX+1,uiY+L.H-L.FOOTER)
        dFotLine.From     =Vector2.new(uiX+1,uiY+L.H-L.FOOTER)
        dFotLine.To       =Vector2.new(uiX+L.W-1,uiY+L.H-L.FOOTER)
        dCharLbl.Position =Vector2.new(uiX+L.SIDEBAR+8,uiY+L.H-L.FOOTER+5)
        for _,t in ipairs(tabObjs) do
            t.bg.Position =Vector2.new(uiX+7,uiY+t.relTY)
            t.acc.Position=Vector2.new(uiX+7,uiY+t.relTY)
            t.lbl.Position=Vector2.new(uiX+18,uiY+t.relTY+7)
            t.lblG.Position=Vector2.new(uiX+18,uiY+t.relTY+7)
            if t.badge then t.badge.Position=Vector2.new(uiX+L.SIDEBAR-16,uiY+t.relTY+9) end
        end
        for _,b in ipairs(btns) do
            if showSet[b.bg] then bPos(b) end
        end
        updateSearchPos()
        updateNotifPos()
        if openDropdown then showDropdown(openDropdown) end
        if openColorPicker then updateColorPickerDrawings(openColorPicker) end
    end

    local function updateMiniPos()
        dMiniShadow.Position =Vector2.new(uiX-2,uiY-2); dMiniShadow.Size=Vector2.new(L.W+4,L.MINI_H+4)
        dMiniBg.Position     =Vector2.new(uiX,uiY);     dMiniBg.Size=Vector2.new(L.W,L.MINI_H)
        dMiniGlow1.Position  =Vector2.new(uiX-1,uiY-1); dMiniGlow1.Size=Vector2.new(L.W+2,L.MINI_H+2)
        dMiniGlow2.Position  =Vector2.new(uiX-2,uiY-2); dMiniGlow2.Size=Vector2.new(L.W+4,L.MINI_H+4)
        dMiniBorder.Position =Vector2.new(uiX,uiY);     dMiniBorder.Size=Vector2.new(L.W,L.MINI_H)
        dMiniTopBar.Position =Vector2.new(uiX+1,uiY+1)
        dMiniTitleW.Position =Vector2.new(uiX+14,uiY+12)
        dMiniTitleA.Position =Vector2.new(uiX+78,uiY+12)
        dMiniTitleG.Position =Vector2.new(uiX+154,uiY+12)
        dMiniKeyLbl.Position =Vector2.new(uiX+L.W-22,uiY+14)
        dMiniDotG.Position   =Vector2.new(uiX+L.W-55,uiY+15)
        dMiniDotR.Position   =Vector2.new(uiX+L.W-42,uiY+15)
        dMiniDivLn.From      =Vector2.new(uiX+1,uiY+L.TOPBAR)
        dMiniDivLn.To        =Vector2.new(uiX+L.W-1,uiY+L.TOPBAR)
        dMiniActiveBg.Position=Vector2.new(uiX+1,uiY+L.TOPBAR)
        dMiniActiveBg.Size   =Vector2.new(L.W-2,L.MINI_H-L.TOPBAR-1)
        local PAD=10; local SEP=14; local charW=7; local ROW_H2=18
        local ROW1_Y=uiY+L.TOPBAR+6; local ROW2_Y=uiY+L.TOPBAR+6+ROW_H2
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
        for _,d in ipairs(miniDrawings) do d.Visible=show end
        if not show then for _,l in ipairs(miniActiveLbls) do l.Visible=false end
        else for _,l in ipairs(miniActiveLbls) do if l.Text~="" then l.Visible=true end end end
    end

    local function refreshMiniLabels()
        local active={}
        for _,b in ipairs(btns) do if b.isTog and b.state then table.insert(active,b.toggleName) end end
        if #active==0 then
            miniActiveLbls[1].Text="no active toggles"; miniActiveLbls[1].Position=Vector2.new(uiX+10,uiY+L.TOPBAR+6)
            miniActiveLbls[1].Visible=true
            for i=2,MAX_MINI_LBLS do miniActiveLbls[i].Text=""; miniActiveLbls[i].Visible=false end
            return
        end
        local PAD=10; local SEP=14; local charW=7; local ROW_H2=18
        local ROW1_Y=uiY+L.TOPBAR+6; local ROW2_Y=uiY+L.TOPBAR+6+ROW_H2
        local slots={}; local curX=uiX+PAD; local row=1
        for _,name in ipairs(active) do
            local w=#name*charW
            if curX+w>uiX+L.W-PAD then
                if row==1 then row=2; curX=uiX+PAD else break end
            end
            table.insert(slots,{name=name,x=curX,y=(row==1 and ROW1_Y or ROW2_Y)})
            curX=curX+w+SEP
        end
        for i,lb in ipairs(miniActiveLbls) do
            if slots[i] then lb.Text=slots[i].name; lb.Position=Vector2.new(slots[i].x,slots[i].y); lb.Visible=true
            else lb.Text=""; lb.Visible=false end
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
            if t.badge then setShow(t.badge,true) end
        end
        showTab(currentTab)
        updatePos()
        menuOpen=true; menuToggledAt=os.clock()-FADE_DUR-0.01
    end

    -- ── NOTIFICATIONS QUEUE
    local function pushNotif(msg, title, dur)
        table.insert(notifQueue,{msg=msg,title=title or (titleA.." "..titleB),dur=dur or 2.5})
    end

    -- ── PROFILE SAVE / LOAD
    local function saveProfile(name)
        local p={}
        for _,b in ipairs(btns) do
            if b.isTog    then p["t_"..b.toggleName]=b.state end
            if b.isSlider then p["s_"..b.baseLbl]=b.value end
            if b.isDropdown then p["d_"..b.baseLbl]=b.value end
        end
        profiles[name]=p
        pushNotif("Profile '"..name.."' saved","Profiles",2)
    end
    local function loadProfile(name)
        local p=profiles[name]; if not p then return end
        activeProfile=name
        for _,b in ipairs(btns) do
            if b.isTog then
                local v=p["t_"..b.toggleName]
                if v~=nil then b.state=v; if b.cb then pcall(b.cb,v) end end
            end
            if b.isSlider then
                local v=p["s_"..b.baseLbl]
                if v~=nil then
                    b.value=v
                    local frac=(v-b.minV)/(b.maxV-b.minV)
                    local ax=uiX+b.rx+8; local ty=uiY+b.ry+b.ch-11
                    local fx=ax+frac*b.trackW
                    b.fill.To=Vector2.new(fx,ty); b.handle.Position=Vector2.new(fx-4,ty-4)
                    local disp=b.isFloat and string.format("%.1f",v) or math.floor(v)
                    b.lbl.Text=b.baseLbl..": "..disp
                    if b.cb then pcall(b.cb,v) end
                end
            end
            if b.isDropdown then
                local v=p["d_"..b.baseLbl]
                if v~=nil then b.value=v; b.valLbl.Text=v; if b.cb then pcall(b.cb,v) end end
            end
        end
        refreshMiniLabels(); updateTabBadges()
        pushNotif("Profile '"..name.."' loaded","Profiles",2)
    end
    UILib.saveProfile=saveProfile
    UILib.loadProfile=loadProfile

    -- ── WIDGET BUILDERS
    local function addToggle(tab,lbl,relY,init,cb,tooltip,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local ox=rx+cw-L.TOG_W-8-(tooltip and 22 or 0); local oy=ry+ch/2-L.TOG_H/2
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local tog =mkD(mkSq(uiX+ox,uiY+oy,L.TOG_W,L.TOG_H,init and C.ON or C.OFF,true,1,4,nil,L.TOG_H))
        local dot =mkD(mkSq(uiX+ox+(init and L.TOG_W-L.TOG_H+2 or 2),uiY+oy+2,L.TOG_H-4,L.TOG_H-4,init and C.ONDOT or C.OFFDOT,true,1,5,nil,L.TOG_H))
        local tti
        if tooltip then
            tti=mkD(mkTx("?",uiX+rx+cw-16,uiY+ry+ch/2-5,9,C.GRAY,false,8))
        end
        local b={tab=tab,isTog=true,state=init,bg=bg,lbl=lb,ln=dl,tog=tog,dot=dot,
                 rx=rx,ry=ry,cw=cw,ch=ch,ox=ox,oy=oy,lt=init and 1 or 0,cb=cb,
                 toggleName=lbl,tooltip=tooltip,ttIcon=tti,parentCollapse=parentSec}
        table.insert(btns,b); return #btns
    end

    local function addDiv(tab,lbl,relY)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2
        local lb=mkD(mkTx(lbl,uiX+rx+6,uiY+ry,9,C.GRAY,false,8))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13,C.DIV,4,1))
        table.insert(btns,{tab=tab,isDiv=true,bg=lb,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=14})
        return #btns
    end

    local function addCollapsibleSection(tab,lbl,relY,startsOpen)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2
        openCollapse[lbl]=startsOpen~=false
        local col=startsOpen~=false and C.WHITE or C.GRAY
        local lb  =mkD(mkTx(lbl,uiX+rx+6,uiY+ry,9,col,false,8))
        local arw =mkD(mkTx(startsOpen~=false and "v" or ">",uiX+rx+cw-14,uiY+ry,9,C.GRAY,false,8))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+13,uiX+rx+cw,uiY+ry+13,C.DIV,4,1))
        local b={tab=tab,isCollapse=true,sectionName=lbl,bg=lb,lbl=lb,arrow=arw,ln=dl,
                 rx=rx,ry=ry,cw=cw,ch=14,children={}}
        table.insert(btns,b); return #btns, lbl
    end

    local function addAct(tab,lbl,relY,col,cb,lblCol)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg=mkD(mkSq(uiX+rx,uiY+ry,cw,ch,col or C.ROWBG,true,1,3,nil,4))
        local dl=mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb=mkD(mkTx(lbl,uiX+rx+cw/2,uiY+ry+ch/2-6,12,lblCol or C.WHITE,true,8))
        local b={tab=tab,isAct=true,bg=bg,lbl=lb,ln=dl,rx=rx,ry=ry,cw=cw,ch=ch,cb=cb}
        table.insert(btns,b); return #btns
    end

    local function addSlider(tab,lbl,relY,minV,maxV,initV,cb,isFloat,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H+6
        local trackW=cw-16
        local initLbl=isFloat and string.format("%.1f",initV) or math.floor(initV)
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl..": "..initLbl,uiX+rx+8,uiY+ry+7,12,C.WHITE,false,8))
        local ty  =uiY+ry+ch-11
        local trk =mkD(mkLn(uiX+rx+8,ty,uiX+rx+8+trackW,ty,C.DIMGRAY,5,3))
        local frac=(initV-minV)/(maxV-minV)
        local fx  =uiX+rx+8+frac*trackW
        local fil =mkD(mkLn(uiX+rx+8,ty,fx,ty,C.ACCENT,6,3))
        local hdl =mkD(mkSq(fx-4,ty-4,L.HDL,L.HDL,C.WHITE,true,1,7,nil,3))
        local b={tab=tab,isSlider=true,bg=bg,lbl=lb,ln=dl,track=trk,fill=fil,handle=hdl,
                 rx=rx,ry=ry,cw=cw,ch=ch,trackW=trackW,minV=minV,maxV=maxV,
                 value=initV,baseLbl=lbl,dragging=false,cb=cb,isFloat=isFloat or false,
                 parentCollapse=parentSec}
        table.insert(btns,b); return #btns
    end

    local function addDropdown(tab,lbl,relY,options,initVal,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local vl  =mkD(mkTx(initVal or options[1] or "",uiX+rx+cw-50,uiY+ry+ch/2-6,11,C.ACCENT,false,8))
        local arw =mkD(mkTx("v",uiX+rx+cw-14,uiY+ry+ch/2-6,9,C.GRAY,false,8))
        local b={tab=tab,isDropdown=true,bg=bg,lbl=lb,ln=dl,valLbl=vl,arrow=arw,
                 rx=rx,ry=ry,cw=cw,ch=ch,options=options,value=initVal or options[1],
                 baseLbl=lbl,cb=cb,parentCollapse=parentSec}
        table.insert(btns,b); return #btns
    end

    local function addTextInput(tab,lbl,relY,placeholder,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local vl  =mkD(mkTx(placeholder or "",uiX+rx+cw/2+10,uiY+ry+ch/2-6,11,C.GRAY,false,8))
        local b={tab=tab,isTextInput=true,bg=bg,lbl=lb,ln=dl,valLbl=vl,
                 rx=rx,ry=ry,cw=cw,ch=ch,text="",placeholder=placeholder or "",
                 focused=false,cb=cb,baseLbl=lbl,parentCollapse=parentSec}
        table.insert(btns,b); return #btns
    end

    local function addKeybind(tab,lbl,relY,initKey,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local badge=mkD(mkSq(uiX+rx+cw-46,uiY+ry+ch/2-8,40,16,C.DIMGRAY,true,1,4,nil,3))
        local bLbl=mkD(mkTx(kname(initKey),uiX+rx+cw-26,uiY+ry+ch/2-6,10,C.ACCENT,true,5))
        local b={tab=tab,isKeybind=true,bg=bg,lbl=lb,ln=dl,kbBadge=badge,kbLbl=bLbl,
                 rx=rx,ry=ry,cw=cw,ch=ch,key=initKey,cb=cb,baseLbl=lbl,
                 listening=false,parentCollapse=parentSec}
        table.insert(btns,b); return #btns
    end

    local function addColorPicker(tab,lbl,relY,initR,initG,initB,cb,parentSec)
        local rx=L.SIDEBAR+L.ROW_PAD; local ry=L.TOPBAR+relY
        local cw=L.CONTENT_W-L.ROW_PAD*2; local ch=L.ROW_H-2
        local bg  =mkD(mkSq(uiX+rx,uiY+ry,cw,ch,C.ROWBG,true,1,3,nil,4))
        local dl  =mkD(mkLn(uiX+rx,uiY+ry+ch,uiX+rx+cw,uiY+ry+ch,C.DIV,4,1))
        local lb  =mkD(mkTx(lbl,uiX+rx+10,uiY+ry+ch/2-6,12,C.WHITE,false,8))
        local sw  =mkD(mkSq(uiX+rx+cw-24,uiY+ry+ch/2-8,16,16,Color3.fromRGB(initR,initG,initB),true,1,4,nil,3))
        local arw =mkD(mkTx("v",uiX+rx+cw-12,uiY+ry+ch/2-6,9,C.GRAY,false,8))
        local b={tab=tab,isColorPicker=true,bg=bg,lbl=lb,ln=dl,valLbl=sw,arrow=arw,
                 rx=rx,ry=ry,cw=cw,ch=ch,r=initR,g=initG,b=initB,cb=cb,
                 baseLbl=lbl,draggingChan=nil,parentCollapse=parentSec}
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
                 rx=rx,ry=ry,cw=cw,ch=ch,lines=lines,lineH=lineH,pad=pad,
                 starFirst=starFirst,starH=starH}
        table.insert(btns,b); return #btns
    end

    -- ── TAB API
    local tabAPI    = {}
    local tabRowY   = {}

    local function getTabAPI(tabName)
        if tabAPI[tabName] then return tabAPI[tabName] end
        local api = {}
        tabRowY[tabName] = 6
        local function nextY(h)
            local y=tabRowY[tabName]; tabRowY[tabName]=y+h; return y
        end
        local currentSection = nil  -- active collapsible section name
        local currentSectionIdx = nil

        function api:Div(lbl)
            currentSection=nil; currentSectionIdx=nil
            addDiv(tabName,lbl,nextY(20))
        end
        function api:Section(lbl,startsOpen)
            local idx,name=addCollapsibleSection(tabName,lbl,nextY(20),startsOpen)
            currentSection=name; currentSectionIdx=idx
        end
        function api:Toggle(lbl,init,cb,tooltip)
            local y=nextY(L.ROW_H+2)
            local idx=addToggle(tabName,lbl,y,init,cb,tooltip,currentSection)
            if currentSectionIdx then
                table.insert(btns[currentSectionIdx].children,idx)
            end
        end
        function api:Slider(lbl,minV,maxV,initV,cb,isFloat)
            local y=nextY(L.ROW_H+8)
            local idx=addSlider(tabName,lbl,y,minV,maxV,initV,cb,isFloat,currentSection)
            if currentSectionIdx then table.insert(btns[currentSectionIdx].children,idx) end
        end
        function api:Button(lbl,col,cb,lblCol)
            local y=nextY(L.ROW_H+2)
            return addAct(tabName,lbl,y,col,cb,lblCol)
        end
        function api:Dropdown(lbl,options,initVal,cb)
            local y=nextY(L.ROW_H+2)
            local idx=addDropdown(tabName,lbl,y,options,initVal,cb,currentSection)
            if currentSectionIdx then table.insert(btns[currentSectionIdx].children,idx) end
        end
        function api:TextInput(lbl,placeholder,cb)
            local y=nextY(L.ROW_H+2)
            local idx=addTextInput(tabName,lbl,y,placeholder,cb,currentSection)
            if currentSectionIdx then table.insert(btns[currentSectionIdx].children,idx) end
        end
        function api:Keybind(lbl,initKey,cb)
            local y=nextY(L.ROW_H+2)
            local idx=addKeybind(tabName,lbl,y,initKey,cb,currentSection)
            if currentSectionIdx then table.insert(btns[currentSectionIdx].children,idx) end
        end
        function api:ColorPicker(lbl,r,g,b,cb)
            local y=nextY(L.ROW_H+2)
            local idx=addColorPicker(tabName,lbl,y,r,g,b,cb,currentSection)
            if currentSectionIdx then table.insert(btns[currentSectionIdx].children,idx) end
        end
        function api:Log(lines,starFirst)
            local lineH=18; local starH=starFirst and 26 or 0
            local h=starH+(#lines-(starFirst and 1 or 0))*lineH+20+6
            addLog(tabName,lines,nextY(h),starFirst)
            currentSection=nil; currentSectionIdx=nil
        end
        tabAPI[tabName]=api; return api
    end

    -- ── INIT
    function win:Init(defaultTab,charLabelFn,notifFn)
        local notif=notifFn or function(msg,title,dur)
            pushNotif(msg,title,dur)
            pcall(function() notify(msg,title or titleA.." "..titleB,dur or 3) end)
        end

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
        dTitleA  = mkD(mkTx(titleB,  uiX+78,     uiY+12,14,C.ACCENT,false,9,true))
        dTitleG  = mkD(mkTx(gameName,uiX+154,    uiY+12,13,C.ORANGE,false,9,false))
        dKeyLbl  = mkD(mkTx("F1",    uiX+L.W-22, uiY+14,11,C.GRAY,  false,9))
        dDotY    = mkD(mkSq(uiX+L.W-55,uiY+15,8,8,C.YELLOW,true,1,9,nil,3))
        dDotR    = mkD(mkSq(uiX+L.W-42,uiY+15,8,8,Color3.fromRGB(170,44,44),true,1,9,nil,3))
        dSide    = mkD(mkSq(uiX+1,uiY+L.TOPBAR,L.SIDEBAR-1,L.H-L.TOPBAR-L.FOOTER-1,C.SIDEBAR,true,1,2,nil,8))
        dSideLn  = mkD(mkLn(uiX+L.SIDEBAR,uiY+L.TOPBAR,uiX+L.SIDEBAR,uiY+L.H-L.FOOTER,C.BORDER,4,1))
        dContent = mkD(mkSq(uiX+L.SIDEBAR,uiY+L.TOPBAR,L.CONTENT_W-1,L.H-L.TOPBAR-L.FOOTER-1,C.CONTENT,true,1,2,nil,8))
        dFooter  = mkD(mkSq(uiX+1,uiY+L.H-L.FOOTER,L.W-2,L.FOOTER-1,C.TOPBAR,true,1,3,nil,6))
        dFotLine = mkD(mkLn(uiX+1,uiY+L.H-L.FOOTER,uiX+L.W-1,uiY+L.H-L.FOOTER,C.BORDER,4,1))
        dCharLbl = mkD(mkTx("",uiX+L.SIDEBAR+8,uiY+L.H-L.FOOTER+5,10,C.GRAY,false,9))

        baseUI={dShadow,dGlow2,dGlow1,dMainBg,dBorder,dTopBar,dTopFill,dTopLine,
                dTitleW,dTitleA,dTitleG,dKeyLbl,dDotY,dDotR,dSide,dSideLn,dContent,
                dFooter,dFotLine,dCharLbl}
        for _,d in ipairs(baseUI) do setShow(d,true) end

        -- build tabs in sidebar
        for i,name in ipairs(win._tabOrder) do
            local relTY=L.TOPBAR+8+(i-1)*34
            local isSel=name==defaultTab
            local tbg =mkD(mkSq(uiX+7,uiY+relTY,L.SIDEBAR-14,26,isSel and C.TABSEL or C.SIDEBAR,true,1,3,nil,5))
            local tacc=mkD(mkSq(uiX+7,uiY+relTY,3,26,isSel and C.ACCENT or C.SIDEBAR,true,1,4,nil,2))
            local tlW =mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C.WHITE,false,8))
            local tlG =mkD(mkTx(name,uiX+18,uiY+relTY+7,11,C.GRAY, false,8))
            -- tab badge (small dot)
            local tbadge=mkD(mkSq(uiX+L.SIDEBAR-16,uiY+relTY+9,6,6,C.DIMGRAY,true,1,8,nil,3))
            setShow(tbg,true); setShow(tacc,true)
            setShow(tlW,isSel); setShow(tlG,not isSel); setShow(tbadge,true)
            table.insert(tabObjs,{bg=tbg,acc=tacc,lbl=tlW,lblG=tlG,badge=tbadge,
                                   name=name,sel=isSel,lt=isSel and 1 or 0,relTY=relTY})
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
        dMiniTitleA  = mkTx(titleB,  uiX+78,    uiY+12,14,C.ACCENT,false,9,true)
        dMiniTitleG  = mkTx(gameName,uiX+154,   uiY+12,13,C.ORANGE,false,9,false)
        dMiniKeyLbl  = mkTx("F1",    uiX+L.W-22,uiY+14,11,C.GRAY,  false,9)
        dMiniDotG    = mkSq(uiX+L.W-55,uiY+15,8,8,C.GREEN,true,1,9,nil,3)
        dMiniDotR    = mkSq(uiX+L.W-42,uiY+15,8,8,Color3.fromRGB(170,44,44),true,1,9,nil,3)
        dMiniDivLn   = mkLn(uiX+1,uiY+L.TOPBAR,uiX+L.W-1,uiY+L.TOPBAR,C.BORDER,4,1)
        dMiniActiveBg= mkSq(uiX+1,uiY+L.TOPBAR,L.W-2,L.MINI_H-L.TOPBAR-1,C.MINIBAR,true,1,2,nil,8)
        miniDrawings={dMiniShadow,dMiniBg,dMiniGlow2,dMiniGlow1,dMiniBorder,
                      dMiniTopBar,dMiniTitleW,dMiniTitleA,dMiniTitleG,
                      dMiniKeyLbl,dMiniDotG,dMiniDotR,dMiniDivLn,dMiniActiveBg}
        for _,d in ipairs(miniDrawings) do d.Visible=false end

        buildNotifDrawings()
        buildTooltipDrawings()
        buildSearchDrawings()
        buildDropdownDrawings()
        buildColorPickerDrawings()

        currentTab=defaultTab
        showTab(defaultTab)
        notif("Loaded on "..(gameName or ""),"Check it Interface",4)

        -- focused text input
        local focusedInput=nil

        spawn(function()
        while not destroyed do
            task.wait()
            local clicking=ismouse1pressed()

            -- notif queue processor
            if not notifShowing and #notifQueue>0 then
                local n=table.remove(notifQueue,1)
                showNotifDrawing(n.title,n.msg)
                notifShowing=true
                notifUntil=os.clock()+n.dur
            elseif notifShowing and os.clock()>=notifUntil then
                hideNotifDrawing(); notifShowing=false
            end

            -- menu key toggle
            local keyDown=iskeypressed(menuKey)
            if keyDown and not wasMenuKey then
                if miniClosed then
                    miniClosed=false; refreshMiniLabels(); showMiniUI(true); updateMiniPos()
                    for _,lb in ipairs(miniActiveLbls) do if lb.Text~="" then lb.Visible=true end end
                elseif minimized then
                    showMiniUI(false); miniClosed=true
                    for _,d in ipairs(allDrawings) do d.Visible=false end
                else
                    menuOpen=not menuOpen; menuToggledAt=os.clock()
                    if not menuOpen and openDropdown then hideDropdown() end
                    if not menuOpen and openColorPicker then hideColorPicker() end
                end
            end
            wasMenuKey=keyDown

            -- keybind listener (for keybind rows)
            if listenKeybindBtn then
                for k=0x08,0xDD do
                    if iskeypressed(k) and k~=0x01 and k~=0x02 and k~=menuKey then
                        local b=btns[listenKeybindBtn]
                        if b then
                            b.key=k; b.kbLbl.Text=kname(k); b.kbLbl.Color=C.ACCENT
                            b.kbBadge.Color=C.DIMGRAY; b.listening=false
                            if b.cb then pcall(b.cb,k) end
                            pushNotif(b.baseLbl..": "..kname(k),"Keybind",2)
                        end
                        listenKeybindBtn=nil; break
                    end
                end
            end

            -- text input keyboard
            if focusedInput then
                local b=btns[focusedInput]
                if b then
                    for k=0x08,0xDD do
                        if iskeypressed(k) then
                            if k==0x08 then -- backspace
                                if #b.text>0 then b.text=b.text:sub(1,-2) end
                            elseif k==0x0D or k==0x1B then -- enter/esc
                                b.bg.Color=C.ROWBG; focusedInput=nil
                                if b.cb then pcall(b.cb,b.text) end
                                break
                            elseif kn[k] then
                                b.text=b.text..kn[k]:lower()
                            end
                            local disp=#b.text>0 and b.text or b.placeholder
                            b.valLbl.Text=disp
                            b.valLbl.Color=#b.text>0 and C.WHITE or C.GRAY
                            task.wait(0.07)
                            break
                        end
                    end
                end
            end

            -- search bar keyboard
            if searchActive then
                for k=0x08,0xDD do
                    if iskeypressed(k) then
                        if k==0x08 then
                            if #searchText>0 then searchText=searchText:sub(1,-2) end
                        elseif k==0x1B then
                            searchText=""; searchActive=false; sCursor.Visible=false
                        elseif kn[k] then
                            searchText=searchText..kn[k]:lower()
                        end
                        sLbl.Text="Search: "..(searchText=="" and "_" or searchText)
                        applySearch()
                        task.wait(0.07)
                        break
                    end
                end
            end

            -- MINI UI MODE
            if minimized and not miniClosed then
                local t2=os.clock()*1.0
                for i,sq in ipairs(miniGlowLines) do
                    local p=t2+glowPhase[i]
                    local r=math.floor(15+45*math.max(0,math.sin(p+1.0)))
                    local g=math.floor(25+55*math.max(0,math.sin(p+0.4)))
                    local b=math.floor(130+125*math.max(0,math.sin(p)))
                    sq.Color=Color3.fromRGB(r,g,b)
                    sq.Transparency=(i==1 and 0.6 or 0.75)+0.25*math.abs(math.sin(p*0.5))
                end
                local pt=os.clock()*0.8
                for i,lb in ipairs(miniActiveLbls) do
                    if lb.Text~="" then
                        lb.Visible=true
                        local f=(math.sin(pt+miniActivePulse[i])+1)/2
                        lb.Color=lerpC(Color3.fromRGB(30,50,160),C.WHITE,f)
                    else lb.Visible=false end
                end
                if clicking and not wasClicking then
                    if inBox(uiX+L.W-46,uiY+11,12,12) then
                        showMiniUI(false); miniClosed=true
                        for _,d in ipairs(allDrawings) do d.Visible=false end
                    elseif inBox(uiX+L.W-59,uiY+11,12,12) then
                        restoreFullMenu()
                    else
                        miniDragging=true; miniDragOffX=mouse.X-uiX; miniDragOffY=mouse.Y-uiY
                    end
                end
                if not clicking then miniDragging=false end
                if miniDragging and clicking then
                    uiX=mouse.X-miniDragOffX; uiY=mouse.Y-miniDragOffY; updateMiniPos()
                end
                wasClicking=clicking
            end

            if not minimized then
                for _,lb in ipairs(miniActiveLbls) do lb.Visible=false end

                -- tab lerp
                for _,t in ipairs(tabObjs) do
                    local tgt=t.sel and 1 or 0; t.lt=t.lt+(tgt-t.lt)*0.15
                    t.bg.Color =lerpC(C.SIDEBAR,C.TABSEL,t.lt)
                    t.acc.Color=lerpC(C.SIDEBAR,C.ACCENT,t.lt)
                end
                -- toggle lerp
                for _,b in ipairs(btns) do
                    if b.isTog and b.tog then
                        local tgt=b.state and 1 or 0; b.lt=b.lt+(tgt-b.lt)*0.18
                        b.tog.Color=lerpC(C.OFF,   C.ON,   b.lt)
                        b.dot.Color=lerpC(C.OFFDOT,C.ONDOT,b.lt)
                        b.dot.Position=Vector2.new(uiX+b.ox+2+(L.TOG_W-L.TOG_H)*b.lt,uiY+b.oy+2+SEARCH_CONTENT_OFFSET)
                    end
                end
                -- glow animation
                do
                    local t2=os.clock()*1.0
                    for i,sq in ipairs(glowLines) do
                        local p=t2+glowPhase[i]
                        local r=math.floor(15+45*math.max(0,math.sin(p+1.0)))
                        local g=math.floor(25+55*math.max(0,math.sin(p+0.4)))
                        local b=math.floor(130+125*math.max(0,math.sin(p)))
                        sq.Color=Color3.fromRGB(r,g,b)
                        sq.Transparency=(i==1 and 0.6 or 0.75)+0.25*math.abs(math.sin(p*0.5))
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

                -- tooltip hover check
                local hoveredTip=nil
                if mOp>0.5 then
                    for _,b in ipairs(btns) do
                        if b.tab==currentTab and b.ttIcon and showSet[b.ttIcon] then
                            local ax=uiX+b.rx; local ay=uiY+b.ry+SEARCH_CONTENT_OFFSET
                            if inBox(ax+b.cw-22,ay,18,b.ch) then
                                hoveredTip=b.tooltip; break
                            end
                        end
                    end
                end
                if hoveredTip then showTooltip(hoveredTip,mouse.X,mouse.Y)
                else hideTooltip() end

                if clicking and not wasClicking and mOp>0.5 then
                    -- search bar click
                    if inBox(uiX+L.SIDEBAR,uiY+L.TOPBAR,L.CONTENT_W-1,L.SEARCH_H) then
                        searchActive=true; sCursor.Visible=true
                        if focusedInput then btns[focusedInput].bg.Color=C.ROWBG; focusedInput=nil end
                        if openDropdown then hideDropdown() end
                        if openColorPicker then hideColorPicker() end
                    else
                        searchActive=false
                        if sCursor then sCursor.Visible=false end
                    end

                    -- yellow: minimize
                    if inBox(uiX+L.W-59,uiY+11,12,12) then
                        minimized=true; miniClosed=false; menuOpen=false
                        for _,d in ipairs(allDrawings) do d.Visible=false end
                        refreshMiniLabels(); showMiniUI(true); updateMiniPos()
                        for _,lb in ipairs(miniActiveLbls) do if lb.Text~="" then lb.Visible=true end end
                    -- red: close
                    elseif inBox(uiX+L.W-46,uiY+11,12,12) then
                        menuOpen=false; menuToggledAt=os.clock()
                        if openDropdown then hideDropdown() end
                        if openColorPicker then hideColorPicker() end
                    -- topbar drag
                    elseif inBox(uiX,uiY,L.W,L.TOPBAR) then
                        dragging=true; dragOffX=mouse.X-uiX; dragOffY=mouse.Y-uiY
                    end

                    -- dropdown option click
                    if openDropdown then
                        local dd=openDropdown
                        local ax=uiX+dd.rx; local ay=uiY+dd.ry+dd.ch+SEARCH_CONTENT_OFFSET
                        local oh=18
                        for i,opt in ipairs(ddOpts) do
                            if opt.lbl.Visible and inBox(ax,ay+2+(i-1)*oh,dd.cw,oh-1) then
                                dd.value=opt.option
                                dd.valLbl.Text=opt.option
                                if dd.cb then pcall(dd.cb,opt.option) end
                                pushNotif(dd.baseLbl..": "..opt.option,nil,2)
                                hideDropdown(); break
                            end
                        end
                        if inBox(uiX+dd.rx,uiY+dd.ry+SEARCH_CONTENT_OFFSET,dd.cw,dd.ch) then
                            -- clicked header again = close
                        end
                    end

                    -- colorpicker channel drag check happens below in drag section

                    -- tabs
                    for _,t in ipairs(tabObjs) do
                        if inBox(uiX+7,uiY+t.relTY,L.SIDEBAR-14,26) then
                            switchTab(t.name)
                            if focusedInput then btns[focusedInput].bg.Color=C.ROWBG; focusedInput=nil end
                        end
                    end

                    -- buttons / toggles / dropdowns / collapsibles
                    for i,b in ipairs(btns) do
                        if b.tab==currentTab and not b.isDiv and not b.isSlider and not b.isLog then
                            local ax=uiX+b.rx; local ay=uiY+b.ry+SEARCH_CONTENT_OFFSET
                            if inBox(ax,ay,b.cw,b.ch) and showSet[b.bg] then
                                if b.isTog then
                                    b.state=not b.state
                                    if b.cb then pcall(b.cb,b.state) end
                                    pushNotif(b.toggleName.." "..(b.state and "enabled" or "disabled"),nil,2)
                                    refreshMiniLabels(); updateTabBadges()
                                elseif b.isAct then
                                    if iKeyBind and i==iKeyBind and not listenMenuKey then
                                        listenMenuKey=true
                                        btns[iKeyBind].lbl.Text="Press any key..."
                                    elseif b.cb then pcall(b.cb) end
                                elseif b.isDropdown then
                                    if openDropdown==b then hideDropdown()
                                    else showDropdown(b) end
                                    if openColorPicker then hideColorPicker() end
                                elseif b.isColorPicker then
                                    if openColorPicker==b then hideColorPicker()
                                    else showColorPicker(b) end
                                    if openDropdown then hideDropdown() end
                                elseif b.isTextInput then
                                    if focusedInput then btns[focusedInput].bg.Color=C.ROWBG end
                                    focusedInput=i; b.bg.Color=C.TABSEL
                                    if openDropdown then hideDropdown() end
                                elseif b.isKeybind then
                                    if listenKeybindBtn then
                                        local pb=btns[listenKeybindBtn]
                                        if pb then pb.kbBadge.Color=C.DIMGRAY; pb.listening=false end
                                    end
                                    if listenKeybindBtn==i then
                                        listenKeybindBtn=nil; b.listening=false; b.kbBadge.Color=C.DIMGRAY
                                    else
                                        listenKeybindBtn=i; b.listening=true
                                        b.kbBadge.Color=C.TABSEL; b.kbLbl.Text="..."
                                        b.kbLbl.Color=C.WHITE
                                    end
                                elseif b.isCollapse then
                                    openCollapse[b.sectionName]=not openCollapse[b.sectionName]
                                    local isOpen=openCollapse[b.sectionName]
                                    b.arrow.Text=isOpen and "v" or ">"
                                    b.lbl.Color=isOpen and C.WHITE or C.GRAY
                                    for _,ci in ipairs(b.children) do
                                        if btns[ci] then bShow(btns[ci],isOpen); if isOpen then bPos(btns[ci]) end end
                                    end
                                end
                                break
                            end
                        end
                    end
                end

                -- sliders
                for _,b in ipairs(btns) do
                    if b.isSlider and b.tab==currentTab and showSet[b.bg] then
                        local ax=uiX+b.rx+8; local ay=uiY+b.ry+b.ch-11+SEARCH_CONTENT_OFFSET
                        if clicking and not wasClicking then
                            if inBox(uiX+b.rx,uiY+b.ry+SEARCH_CONTENT_OFFSET,b.cw,b.ch) then b.dragging=true end
                        end
                        if not clicking and wasClicking and b.dragging then
                            local disp=b.isFloat and string.format("%.1f",b.value) or math.floor(b.value)
                            pushNotif(b.baseLbl..": "..disp,nil,2)
                        end
                        if not clicking then b.dragging=false end
                        if b.dragging and clicking then
                            local frac=clamp((mouse.X-ax)/b.trackW,0,1)
                            b.value=b.minV+frac*(b.maxV-b.minV)
                            local fx=ax+frac*b.trackW
                            b.fill.To=Vector2.new(fx,ay); b.handle.Position=Vector2.new(fx-4,ay-4)
                            local disp=b.isFloat and string.format("%.1f",b.value) or math.floor(b.value)
                            b.lbl.Text=b.baseLbl..": "..disp
                            if b.cb then pcall(b.cb,b.value) end
                        end
                    end
                end

                -- color picker channel dragging
                if openColorPicker then
                    local b=openColorPicker
                    local ax=uiX+b.rx; local ay=uiY+b.ry+b.ch+SEARCH_CONTENT_OFFSET
                    local pad=10; local lx=ax+pad+24; local trackW=b.cw-pad*2-20
                    local chans={"r","g","b"}
                    local rowY={ay+11+4,ay+30+4,ay+49+4}
                    for ci,chan in ipairs(chans) do
                        local tx=lx+14
                        if clicking and not wasClicking then
                            if inBox(tx,rowY[ci]-6,trackW,12) then b.draggingChan=chan end
                        end
                        if not clicking then b.draggingChan=nil end
                        if b.draggingChan==chan and clicking then
                            local frac=clamp((mouse.X-tx)/trackW,0,1)
                            b[chan]=math.floor(frac*255)
                            b.valLbl.Color=Color3.fromRGB(b.r,b.g,b.b)
                            updateColorPickerDrawings(b)
                            if b.cb then pcall(b.cb,Color3.fromRGB(b.r,b.g,b.b)) end
                        end
                    end
                end

                -- drag window
                if not clicking then dragging=false end
                if dragging and clicking then
                    uiX=mouse.X-dragOffX; uiY=mouse.Y-dragOffY; updatePos()
                end
                wasClicking=clicking

                -- menu key rebind listener
                if listenMenuKey then
                    for k=0x08,0xDD do
                        if iskeypressed(k) and k~=0x01 and k~=0x02 then
                            menuKey=k; local n=kname(k)
                            if iKeyInfo then btns[iKeyInfo].lbl.Text="Menu Key: "..n end
                            if iKeyBind then btns[iKeyBind].lbl.Text="Click to Rebind" end
                            dKeyLbl.Text=n; dMiniKeyLbl.Text=n
                            listenMenuKey=false; break
                        end
                    end
                end

                -- char label
                if charLabelFn then dCharLbl.Text=charLabelFn() end
            end
        end
        end) -- spawn
    end -- Init

    -- Tab factory
    win._tabOrder = {}
    function win:Tab(name)
        table.insert(win._tabOrder,name); return getTabAPI(name)
    end

    function win:SettingsTab(destroyCb)
        local s=self:Tab("Settings")
        s:Div("KEYBIND")
        iKeyInfo=s:Button("Menu Key: F1",   C.ROWBG,nil,nil)
        iKeyBind=s:Button("Click to Rebind",Color3.fromRGB(14,20,40),nil,nil)
        s:Div("PROFILES")
        s:Button("Save Profile 'Default'", C.ROWBG, function() saveProfile("Default") end, C.ACCENT)
        s:Button("Load Profile 'Default'", C.ROWBG, function() loadProfile("Default") end, C.WHITE)
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
        for _,o in ipairs(ddOpts) do pcall(function() o.bg:Remove(); o.lbl:Remove() end) end
        for _,d in ipairs(cpAllDrawings) do pcall(function() d:Remove() end) end
        if nBg then pcall(function() nBg:Remove(); nBorder:Remove(); nBar:Remove(); nTitle:Remove(); nMsg:Remove() end) end
        if ttBg then pcall(function() ttBg:Remove(); ttTx:Remove() end) end
        if sBg  then pcall(function() sBg:Remove(); sLbl:Remove(); sCursor:Remove() end) end
    end

    return win
end

_G.UILib = UILib
