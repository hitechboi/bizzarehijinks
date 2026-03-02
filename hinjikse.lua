local user = game.Players.LocalPlayer.Name
local noevasive = false
local nocombowait = false
local noragdoll = false
local nostun = false
local infSpecial = false
local stateBypass = false
local abilSpeedOn = false
local chantLock = false
local damageMultiplierValue = 1

local mouse = game.Players.LocalPlayer:GetMouse()

local uiX, uiY = 300, 200
local uiW, uiH = 240, 310
local dragging = false
local dragOffX, dragOffY = 0, 0
local wasClicking = false
local visible = true
local currentTab = "Combat"
local menuKey = 0x24
local listeningForKey = false
local isDead = false

local C_BG     = Color3.fromRGB(5, 8, 25)
local C_PANEL  = Color3.fromRGB(8, 14, 40)
local C_TAB    = Color3.fromRGB(12, 22, 55)
local C_TABSEL = Color3.fromRGB(25, 60, 160)
local C_ACCENT = Color3.fromRGB(40, 100, 255)
local C_BTN    = Color3.fromRGB(10, 18, 50)
local C_WHITE  = Color3.fromRGB(220, 230, 255)
local C_GRAY   = Color3.fromRGB(80, 100, 140)
local C_ON     = Color3.fromRGB(25, 70, 190)
local C_OFF    = Color3.fromRGB(15, 18, 40)
local C_ONDOT  = Color3.fromRGB(70, 150, 255)
local C_OFFDOT = Color3.fromRGB(30, 40, 80)
local C_GREEN  = Color3.fromRGB(0, 200, 80)

local States, AbilitySpeed, Special, Combo, DamageMultiplier, Chant
local BindingVow, Character, Awakening, Awakened, Percent, Humanoid

local function grabRefs()
    States           = game.Workspace.Live[user].Combat.States
    AbilitySpeed     = States.AbilitySpeed
    Special          = States.Special
    Combo            = States.Combo
    DamageMultiplier = States.DamageMultiplier
    Chant            = States:FindFirstChild("Chant")
    BindingVow       = game.Players[user].Variables.BindingVow
    Character        = game.Players[user].Configuration.Character
    Awakening        = game.Players[user].Configuration.Awakening
    Awakened         = game.Players[user].Configuration.Awakened
    Percent          = game.Players[user].PlayerScripts.Engine.Awakening.Percent
    Humanoid         = game.Workspace.Live[user]:FindFirstChild("Humanoid")
end

grabRefs()

local function inRect(x, y, w, h)
    local mx, my = mouse.X, mouse.Y
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local function sq(x, y, w, h, color, filled, transp, zi, thick)
    local s = Drawing.new("Square")
    s.Position = Vector2.new(x, y)
    s.Size = Vector2.new(w, h)
    s.Color = color
    s.Filled = filled
    s.Transparency = transp or 1
    s.ZIndex = zi or 1
    s.Visible = true
    if not filled then s.Thickness = thick or 1 end
    return s
end

local function tx(text, x, y, size, color, centered, zi, bold)
    local t = Drawing.new("Text")
    t.Text = text
    t.Position = Vector2.new(x, y)
    t.Size = size or 13
    t.Color = color or C_WHITE
    t.Center = centered or false
    t.Outline = true
    t.Font = bold and Drawing.Fonts.SystemBold or Drawing.Fonts.System
    t.Transparency = 1
    t.ZIndex = zi or 3
    t.Visible = true
    return t
end

local function ln(x1, y1, x2, y2, color, zi, thick)
    local l = Drawing.new("Line")
    l.From = Vector2.new(x1, y1)
    l.To = Vector2.new(x2, y2)
    l.Color = color or C_ACCENT
    l.Transparency = 1
    l.Thickness = thick or 1
    l.ZIndex = zi or 2
    l.Visible = true
    return l
end

local allDrawings = {}
local function track(d) table.insert(allDrawings, d) return d end

local mainBg     = track(sq(uiX, uiY, uiW, uiH, C_BG, true, 1, 1))
local mainBorder = track(sq(uiX, uiY, uiW, uiH, C_ACCENT, false, 1, 6, 2))
local titleBg    = track(sq(uiX, uiY, uiW, 26, C_PANEL, true, 1, 2))
local titleTx    = track(tx("Bizzare Hinjinks", uiX+uiW/2, uiY+8, 13, C_WHITE, true, 7, true))
local titleDiv   = track(ln(uiX, uiY+26, uiX+uiW, uiY+26, C_ACCENT, 5, 2))

local tabNames = {"Combat", "Boosts", "Settings"}
local tabW = uiW / 3
local tabBgs, tabTxs = {}, {}
for i, name in ipairs(tabNames) do
    local tx_ = uiX + (i-1) * tabW
    local sel = name == currentTab
    tabBgs[i] = track(sq(tx_, uiY+26, tabW, 20, sel and C_TABSEL or C_TAB, true, 1, 3))
    tabTxs[i] = track(tx(name, tx_+tabW/2, uiY+32, 11, sel and C_WHITE or C_GRAY, true, 7))
end
local tabDiv    = track(ln(uiX, uiY+46, uiX+uiW, uiY+46, C_ACCENT, 5, 1))
local contentBg = track(sq(uiX, uiY+46, uiW, uiH-46, C_BG, true, 1, 1))
local charLabel = track(tx("Char: "..Character.Value, uiX+uiW/2, uiY+uiH-14, 11, C_ACCENT, true, 7))

local buttonObjects = {}

local function makeBtn(tab, label, y, initState, isToggle, onToggle)
    local bx = uiX + 8
    local by = uiY + 54 + y
    local bw = uiW - 16
    local bh = 22
    local isVis = tab == currentTab

    local btnBg    = sq(bx, by, bw, bh, C_BTN, true, 1, 3)
    local btnLabel = tx(label, bx+8, by+6, 12, C_WHITE, false, 7)
    btnBg.Visible    = isVis
    btnLabel.Visible = isVis

    local togOuter, togInner, togBorder
    if isToggle then
        local ox = bx + bw - 28
        local oy = by + 4
        togOuter  = sq(ox, oy, 20, 14, initState and C_ON or C_OFF, true, 1, 4)
        togInner  = sq(ox+4, oy+3, 8, 8, initState and C_ONDOT or C_OFFDOT, true, 1, 5)
        togBorder = sq(ox, oy, 20, 14, C_ACCENT, false, 1, 6, 1)
        togOuter.Visible  = isVis
        togInner.Visible  = isVis
        togBorder.Visible = isVis
    end

    local btn = {
        bg=btnBg, label=btnLabel,
        togOuter=togOuter, togInner=togInner, togBorder=togBorder,
        y=y, tab=tab, isToggle=isToggle, state=initState,
        bx=bx, by=by, bw=bw, bh=bh,
        onToggle=onToggle
    }
    table.insert(buttonObjects, btn)
    return #buttonObjects
end

local function setVis(idx, vis)
    local btn = buttonObjects[idx]
    btn.bg.Visible    = vis
    btn.label.Visible = vis
    if btn.togOuter  then btn.togOuter.Visible  = vis end
    if btn.togInner  then btn.togInner.Visible  = vis end
    if btn.togBorder then btn.togBorder.Visible = vis end
end

local function refreshToggle(idx)
    local btn = buttonObjects[idx]
    if not btn.isToggle then return end
    btn.togOuter.Color = btn.state and C_ON or C_OFF
    btn.togInner.Color = btn.state and C_ONDOT or C_OFFDOT
end

local function toggleBtn(idx)
    local btn = buttonObjects[idx]
    if not btn.isToggle then return end
    btn.state = not btn.state
    refreshToggle(idx)
    if btn.onToggle then btn.onToggle(btn.state) end
    return btn.state
end

local function setTabVisible(tab)
    for i, btn in ipairs(buttonObjects) do
        setVis(i, btn.tab == tab)
    end
end

local function switchTab(name)
    currentTab = name
    setTabVisible(name)
    for i, tname in ipairs(tabNames) do
        tabBgs[i].Color = tname == name and C_TABSEL or C_TAB
        tabTxs[i].Color = tname == name and C_WHITE or C_GRAY
    end
end

local function updatePositions()
    mainBg.Position     = Vector2.new(uiX, uiY)
    mainBorder.Position = Vector2.new(uiX, uiY)
    titleBg.Position    = Vector2.new(uiX, uiY)
    titleTx.Position    = Vector2.new(uiX+uiW/2, uiY+8)
    titleDiv.From       = Vector2.new(uiX, uiY+26)
    titleDiv.To         = Vector2.new(uiX+uiW, uiY+26)
    tabDiv.From         = Vector2.new(uiX, uiY+46)
    tabDiv.To           = Vector2.new(uiX+uiW, uiY+46)
    contentBg.Position  = Vector2.new(uiX, uiY+46)
    charLabel.Position  = Vector2.new(uiX+uiW/2, uiY+uiH-14)
    for i in ipairs(tabNames) do
        local tx_ = uiX+(i-1)*tabW
        tabBgs[i].Position = Vector2.new(tx_, uiY+26)
        tabTxs[i].Position = Vector2.new(tx_+tabW/2, uiY+32)
    end
    for _, btn in ipairs(buttonObjects) do
        local bx = uiX+8
        local by = uiY+54+btn.y
        local bw = uiW-16
        btn.bx, btn.by = bx, by
        btn.bg.Position    = Vector2.new(bx, by)
        btn.label.Position = Vector2.new(bx+8, by+6)
        if btn.togOuter then
            btn.togOuter.Position  = Vector2.new(bx+bw-28, by+4)
            btn.togInner.Position  = Vector2.new(bx+bw-24, by+7)
            btn.togBorder.Position = Vector2.new(bx+bw-28, by+4)
        end
    end
end

local keyNames = {
    [0x24]="Home",[0x2E]="Delete",[0x23]="End",
    [0x22]="PgDn",[0x21]="PgUp",[0x2D]="Insert",
    [0x70]="F1",[0x71]="F2",[0x72]="F3",[0x73]="F4",
    [0x74]="F5",[0x75]="F6",[0x76]="F7",[0x77]="F8",
}

-- Combat
local btnNoevasive   = makeBtn("Combat", "No Evasive",   0,  false, true, function(s) noevasive   = s end)
local btnNocombowait = makeBtn("Combat", "No ComboWait", 26, false, true, function(s) nocombowait = s end)
local btnNoragdoll   = makeBtn("Combat", "No Ragdoll",   52, false, true, function(s) noragdoll   = s end)
local btnNostun      = makeBtn("Combat", "No Stun",      78, false, true, function(s) nostun      = s end)

-- Boosts
local btnInfSpecial  = makeBtn("Boosts", "Inf Special",         0,  false, true, function(s) infSpecial  = s end)
local btnStateBypass = makeBtn("Boosts", "StateChecker Bypass", 26, false, true, function(s) stateBypass = s end)
local btnAbilSpeed   = makeBtn("Boosts", "Ability Speed",       52, false, true, function(s) abilSpeedOn = s end)
local btnChantLock   = makeBtn("Boosts", "KOC Chant Lock",      78, false, true, function(s) chantLock   = s end)

-- Settings
local btnMenuKeyInfo = makeBtn("Settings", "Menu Key: Home",   0,  nil, false, nil)
local btnChangeKey   = makeBtn("Settings", "Click to rebind",  26, nil, false, nil)
local btnReapply     = makeBtn("Settings", "Reapply Features", 52, nil, false, nil)
buttonObjects[btnReapply].label.Color = C_GRAY
buttonObjects[btnReapply].bg.Color    = Color3.fromRGB(8, 30, 15)

local function setAllVisible(vis)
    for _, d in ipairs(allDrawings) do d.Visible = vis end
    if vis then
        setTabVisible(currentTab)
    else
        for i in ipairs(buttonObjects) do setVis(i, false) end
    end
end

AbilitySpeed.Value = 100

while true do
    local clicking = ismouse1pressed()

    if Humanoid and Humanoid.Health <= 0 and not isDead then
        isDead = true
        buttonObjects[btnReapply].label.Text  = "Reapply Features !"
        buttonObjects[btnReapply].label.Color = C_GREEN
        buttonObjects[btnReapply].bg.Color    = Color3.fromRGB(8, 40, 20)
    end

    if clicking and not wasClicking and visible then
        if inRect(uiX, uiY, uiW, 26) then
            dragging = true
            dragOffX = mouse.X - uiX
            dragOffY = mouse.Y - uiY
        end

        for i, name in ipairs(tabNames) do
            if inRect(uiX+(i-1)*tabW, uiY+26, tabW, 20) then
                switchTab(name)
            end
        end

        for i, btn in ipairs(buttonObjects) do
            if btn.tab == currentTab and inRect(btn.bx, btn.by, btn.bw, btn.bh) then
                if btn.isToggle then
                    toggleBtn(i)
                elseif i == btnChangeKey and not listeningForKey then
                    listeningForKey = true
                    buttonObjects[btnChangeKey].label.Text  = "Press any key..."
                    buttonObjects[btnChangeKey].label.Color = C_ACCENT
                elseif i == btnReapply then
                    grabRefs()
                    isDead = false
                    buttonObjects[btnReapply].label.Text  = "Reapply Features"
                    buttonObjects[btnReapply].label.Color = C_GRAY
                    buttonObjects[btnReapply].bg.Color    = Color3.fromRGB(8, 30, 15)
                    if abilSpeedOn then AbilitySpeed.Value = 100 end
                end
                break
            end
        end
    end

    if not clicking then dragging = false end
    if dragging and clicking then
        uiX = mouse.X - dragOffX
        uiY = mouse.Y - dragOffY
        updatePositions()
    end
    wasClicking = clicking

    if listeningForKey then
        for key = 0x08, 0x90 do
            if iskeypressed(key) and key ~= 0x01 and key ~= 0x02 then
                menuKey = key
                local name = keyNames[key] or ("Key "..key)
                buttonObjects[btnMenuKeyInfo].label.Text = "Menu Key: "..name
                buttonObjects[btnChangeKey].label.Text   = "Click to rebind"
                buttonObjects[btnChangeKey].label.Color  = C_WHITE
                listeningForKey = false
                break
            end
        end
    end

    if iskeypressed(menuKey) then
        visible = not visible
        setAllVisible(visible)
        task.wait(0.2)
    end

    charLabel.Text = "Char: "..Character.Value

    if not isDead then
        if stateBypass then
            for _, state in pairs(States:GetChildren()) do
                if state.ClassName == "BoolValue" then state.Value = false end
            end
            local Stuns = States:FindFirstChild("Stuns")
            if Stuns then
                for _, stun in pairs(Stuns:GetChildren()) do
                    if stun.ClassName == "BoolValue" then stun.Value = false end
                end
            end
        end

        if infSpecial then Special.Value = 100 end
        if noevasive then
            States.EvadeCooldown.Value = false
            States.CantEvade.Value = false
        end
        if nocombowait then States.ComboWait.Value = false end
        if noragdoll   then States.Ragdolled.Value = false end
        if nostun then
            States.Attacking.Value = false
            States.BaseAttacking.Value = false
        end
        if chantLock and Character.Value == "KingOfCurses" then
            if Chant then Chant.Value = 3 end
        end

        Combo.Value = 1
        DamageMultiplier.Value = damageMultiplierValue

        if abilSpeedOn then
            AbilitySpeed.Value = 100
        else
            AbilitySpeed.Value = 1
        end
    end

    task.wait()
end
