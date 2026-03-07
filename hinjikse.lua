--[[
    Check it Interface
    by hitechboi / nejrio
    github.com/hitechboi
    star my post :p, have fun!
]]

if game.GameId ~= 6809578891 then
    notify("Check it", "This script is not supported for this game.", 5)
    return
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/hitechboi/bizzarehijinks/refs/heads/main/rangerover.lua"))()
repeat task.wait() until _G.UILib
local UILib = _G.UILib

local user = game.Players.LocalPlayer.Name
local gameName = getgamename()

local noevasive, nocombowait, noragdoll, nostun = false, false, false, false
local infSpecial, stateBypass, chantLock, antiAC = false, false, false, false
local abilitySpeed = 1
local runSpeed = 1
local damageMultiplierValue = 1

local States, AbilitySpeed, Special, Combo, DamageMultiplier, Chant
local Character, Humanoid
local isDead = false
local destroyed = false

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

local win = UILib.Window("Check it", "Interface", gameName)

local combat = win:Tab("Combat")
combat:Div("COMBAT", true)
combat:Toggle("No Evasive",   false, function(s) noevasive=s end, "Disables evade cooldown")
combat:Toggle("No ComboWait", false, function(s) nocombowait=s end, "Removes delay between combos")
combat:Toggle("No Ragdoll",   false, function(s) noragdoll=s end, "Prevents ragdoll state")
combat:Toggle("No Stun",      false, function(s) nostun=s end, "Clears stun states every frame")

local boosts = win:Tab("Boosts")
boosts:Div("BOOSTS", true)
boosts:Toggle("Inf Special",         false, function(s) infSpecial=s end, "Keeps Special at 100")
boosts:Toggle("StateChecker Bypass", false, function(s) stateBypass=s end, "Clears all BoolValue states")
boosts:Slider("Ability Speed", 1, 100, 1, function(v) abilitySpeed=v end, false, "Multiplies ability animation speed")
boosts:Toggle("KOC Chant Lock",      false, function(s) chantLock=s end, "Locks Chant at 3 for KOC")

local misc = win:Tab("Misc")
misc:Div("MISCELLANEOUS", true)
misc:Button("Auto-reapply: ON", Color3.fromRGB(12,26,16), nil, UILib.Colors.GREEN)
misc:Toggle("Anti-Anticheat", false, function(s) antiAC=s end, "Clamps Y velocity to max 8")
misc:Slider("Run Speed", 1, 100, 1, function(v) runSpeed=v end, true, "Sets RunningSpeed value")
misc:Slider("Damage Multiplier", 1, 10, 1, function(v) damageMultiplierValue=v end, true, "Multiplies outgoing damage")
misc:Div("APPEARANCE")
misc:Dropdown("Theme", {"Check it","Moon","Grass","Light","Dark"}, 1, function(name)
    win:ApplyTheme(name)
end)
misc:Div("INFO")
misc:Button("v1.5.6  |  github.com/hitechboi", UILib.Colors.ROWBG, nil, UILib.Colors.GRAY)

local updates = win:Tab("Updates")
updates:Div("UPDATE LOG")
updates:Log({
    "STAR MY POST !",
    "> v1.5.6 - Dynamic title positioning",
    "> v1.5.2 - Removed resize handle",
    "> v1.5.1 - Matcha tick() fix",
    "> v1.5.0 - Widgets scale with menu",
    "> v1.4.9 - Slider close fix",
    "> v1.4.0 - Smooth collapse + minimize bar",
    "> hi :p"
}, true)

win:SettingsTab(function()
    destroyed = true
    win:Destroy()
end)

if AbilitySpeed then AbilitySpeed.Value = 1 end

win:Init("Updates", function()
    if Character then
        return "Credit: besosme  |  Character: "..Character.Value
    end
    return ""
end)

while not destroyed do
    task.wait()
    if Humanoid and Humanoid.Health <= 0 then isDead = true end
    if antiAC and Humanoid and Humanoid.Health > 0 then
        pcall(function()
            local hrp = game.Workspace.Live[user]:FindFirstChild("HumanoidRootPart")
            if hrp then
                local v = hrp.AssemblyLinearVelocity
                if v.Y > 8 then
                    hrp.AssemblyLinearVelocity = Vector3.new(v.X, 8, v.Z)
                end
            end
        end)
    end
    if not isDead and States then
        if stateBypass then
            for _,s in pairs(States:GetChildren()) do
                if s.ClassName=="BoolValue" then s.Value=false end
            end
            local Stuns = States:FindFirstChild("Stuns")
            if Stuns then
                for _,s in pairs(Stuns:GetChildren()) do pcall(function() s:Destroy() end) end
            end
        end
        if infSpecial  then Special.Value=100 end
        if noevasive   then States.EvadeCooldown.Value=false; States.CantEvade.Value=false end
        if nocombowait then States.ComboWait.Value=false end
        if noragdoll   then States.Ragdolled.Value=false end
        if nostun then
            local _clear={"Attacking","BaseAttacking","CantRun","Blocking","Dashing",
                "Landing","Parkour","SlowWalk","HoldingItem","InUltimate","AwakeningActive",
                "HyperArmor","CantGrab","Scared","Frozen","Counter","Emoting","IFrames"}
            for _,name in ipairs(_clear) do
                local s=States:FindFirstChild(name)
                if s and s:IsA("BoolValue") then pcall(function() s.Value=false end) end
            end
            local Stuns=States:FindFirstChild("Stuns")
            if Stuns then
                for _,s in pairs(Stuns:GetChildren()) do pcall(function() s:Destroy() end) end
            end
        end
        if chantLock and Character and Character.Value=="KingOfCurses" then
            if Chant then Chant.Value=3 end
        end
        if DamageMultiplier then DamageMultiplier.Value=damageMultiplierValue end
        if AbilitySpeed then AbilitySpeed.Value=abilitySpeed end
        local rs=States:FindFirstChild("RunningSpeed")
        if rs then rs.Value=runSpeed end
    end
end
