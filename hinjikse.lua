--[[
    Check it Interface
    by hitechboi / nejrio
    github.com/hitechboi
    star my post :p, have fun!
]]

loadstring(game:HttpGet("https://raw.githubusercontent.com/hitechboi/bizzarehijinks/refs/heads/main/Uilib.lua"))()
repeat task.wait() until _G.UILib
local UILib = _G.UILib
local user = game.Players.LocalPlayer.Name
local gameName = getgamename()
local _v1, _v2, _v3, _v4 = false, false, false, false
local _v5, _v6, _v7, _v8 = false, false, false, false
local _v9 = 1
local _va = 1
local _vb = 1
local _vf, _vg, _vh, _vi, _vj, _vk
local _vl, _vm
local _vd = false
local _ve = false

local function _vc()
    pcall(function()
        _vf           = game.Workspace.Live[user].Combat._vf
        _vg     = _vf._vg
        _vh          = _vf._vh
        _vi            = _vf._vi
        _vj = _vf._vj
        _vk            = _vf:FindFirstChild((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,104,97,110,116}))
        _vl        = game.Players[user].Configuration._vl
        _vm         = game.Workspace.Live[user]:FindFirstChild((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({72,117,109,97,110,111,105,100}))
    end)
end
_vc()
spawn(function()
    while not _ve do
        wait(3); _vc()
        if _vm and _vm.Health > 0 then _vd = false end
    end
end)

local win = UILib.Window((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,104,101,99,107,32,105,116}), (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({73,110,116,101,114,102,97,99,101}), gameName)
local combat = win:Tab((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,111,109,98,97,116}))
combat:Div((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,79,77,66,65,84}))
combat:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({78,111,32,69,118,97,115,105,118,101}),   false, function(s) _v1=s end)
combat:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({78,111,32,67,111,109,98,111,87,97,105,116}), false, function(s) _v2=s end)
combat:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({78,111,32,82,97,103,100,111,108,108}),   false, function(s) _v3=s end)
combat:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({78,111,32,83,116,117,110}),      false, function(s) _v4=s end)
local boosts = win:Tab((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({66,111,111,115,116,115}))
boosts:Div((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({66,79,79,83,84,83}))
boosts:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({73,110,102,32,83,112,101,99,105,97,108}),         false, function(s) _v5=s end)
boosts:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({83,116,97,116,101,67,104,101,99,107,101,114,32,66,121,112,97,115,115}), false, function(s) _v6=s end)
boosts:Slider((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({65,98,105,108,105,116,121,32,83,112,101,101,100}), 1, 100, 1,   function(v) _v9=v end, false)
boosts:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({75,79,67,32,67,104,97,110,116,32,76,111,99,107}),      false, function(s) _v7=s end)
local misc = win:Tab((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({77,105,115,99}))
misc:Div((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({77,73,83,67,69,76,76,65,78,69,79,85,83}))
misc:Button((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({65,117,116,111,45,114,101,97,112,112,108,121,58,32,79,78}), Color3.fromRGB(12,26,16), nil, UILib.Colors.GREEN)
misc:Toggle((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({65,110,116,105,45,65,110,116,105,99,104,101,97,116}), false, function(s) _v8=s end)
misc:Slider((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({82,117,110,32,83,112,101,101,100}), 1, 100, 1, function(v) _va=v end, true)
misc:Div((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({73,78,70,79}))
misc:Button((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({118,49,46,49,32,32,124,32,32,103,105,116,104,117,98,46,99,111,109,47,104,105,116,101,99,104,98,111,105}), UILib.Colors.ROWBG, nil, UILib.Colors.GRAY)
local updates = win:Tab((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({85,112,100,97,116,101,115}))
updates:Div((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({85,80,68,65,84,69,32,76,79,71}))
updates:Log({
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({83,84,65,82,32,77,89,32,80,79,83,84,32,33,32,58,68}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,48,32,45,32,73,110,105,116,105,97,108,32,114,101,108,101,97,115,101}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,49,32,45,32,81,79,76,32,102,101,97,116,117,114,101,115,44,32,97,110,100,32,110,101,119,32,109,101,110,117}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,49,32,45,32,78,111,32,83,116,117,110,32,110,111,119,32,99,108,101,97,114,115,32,67,97,110,116,82,117,110}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,49,32,45,32,65,98,105,108,105,116,121,32,83,112,101,101,100,32,115,108,105,100,101,114,32,97,100,100,101,100}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,49,32,45,32,65,110,116,105,45,65,110,116,105,99,104,101,97,116,32,97,100,100,101,100,32,116,111,32,77,105,115,99}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,49,32,45,32,82,117,110,32,83,112,101,101,100,32,115,108,105,100,101,114,32,97,100,100,101,100,32,116,111,32,77,105,115,99}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,49,32,45,32,78,111,32,83,116,117,110,32,114,101,109,111,118,101,100,32,40,115,101,114,118,101,114,115,105,100,101,41}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,118,49,46,50,32,45,32,85,73,76,105,98,32,114,101,102,97,99,116,111,114}),
    (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({62,32,104,105,32,58,112})
}, true)

win:SettingsTab(function()
    _ve = true
    win:Destroy()
end)

if _vg then _vg.Value = 1 end

win:Init((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({85,112,100,97,116,101,115}), function()
    if _vl then
        return (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,114,101,100,105,116,58,32,98,101,115,111,115,109,101,32,32,124,32,32,67,104,97,114,97,99,116,101,114,58,32}).._vl.Value
    end
    return "(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({10,101,110,100,41,10,10,45,45,32,9472,9472,32,103,97,109,101,32,108,111,111,112,32,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,9472,10,119,104,105,108,101,32,110,111,116,32,100,101,115,116,114,111,121,101,100,32,100,111,10,32,32,32,32,116,97,115,107,46,119,97,105,116,40,41,10,10,32,32,32,32,105,102,32,72,117,109,97,110,111,105,100,32,97,110,100,32,72,117,109,97,110,111,105,100,46,72,101,97,108,116,104,32,60,61,32,48,32,116,104,101,110,32,105,115,68,101,97,100,32,61,32,116,114,117,101,32,101,110,100,10,10,32,32,32,32,105,102,32,97,110,116,105,65,67,32,97,110,100,32,72,117,109,97,110,111,105,100,32,97,110,100,32,72,117,109,97,110,111,105,100,46,72,101,97,108,116,104,32,62,32,48,32,116,104,101,110,10,32,32,32,32,32,32,32,32,112,99,97,108,108,40,102,117,110,99,116,105,111,110,40,41,10,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,104,114,112,32,61,32,103,97,109,101,46,87,111,114,107,115,112,97,99,101,46,76,105,118,101,91,117,115,101,114,93,58,70,105,110,100,70,105,114,115,116,67,104,105,108,100,40})HumanoidRootPart(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({41,10,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,104,114,112,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,118,32,61,32,104,114,112,46,65,115,115,101,109,98,108,121,76,105,110,101,97,114,86,101,108,111,99,105,116,121,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,118,46,89,32,62,32,56,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,104,114,112,46,65,115,115,101,109,98,108,121,76,105,110,101,97,114,86,101,108,111,99,105,116,121,32,61,32,86,101,99,116,111,114,51,46,110,101,119,40,118,46,88,44,32,56,44,32,118,46,90,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,101,110,100,41,10,32,32,32,32,101,110,100,10,10,32,32,32,32,105,102,32,110,111,116,32,105,115,68,101,97,100,32,97,110,100,32,83,116,97,116,101,115,32,116,104,101,110,10,32,32,32,32,32,32,32,32,105,102,32,115,116,97,116,101,66,121,112,97,115,115,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,95,44,115,32,105,110,32,112,97,105,114,115,40,83,116,97,116,101,115,58,71,101,116,67,104,105,108,100,114,101,110,40,41,41,32,100,111,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,115,46,67,108,97,115,115,78,97,109,101,61,61})BoolValue(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({32,116,104,101,110,32,115,46,86,97,108,117,101,61,102,97,108,115,101,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,83,116,117,110,115,32,61,32,83,116,97,116,101,115,58,70,105,110,100,70,105,114,115,116,67,104,105,108,100,40})Stuns(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({41,10,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,83,116,117,110,115,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,95,44,115,32,105,110,32,112,97,105,114,115,40,83,116,117,110,115,58,71,101,116,67,104,105,108,100,114,101,110,40,41,41,32,100,111,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,112,99,97,108,108,40,102,117,110,99,116,105,111,110,40,41,32,115,58,68,101,115,116,114,111,121,40,41,32,101,110,100,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,105,102,32,105,110,102,83,112,101,99,105,97,108,32,32,116,104,101,110,32,83,112,101,99,105,97,108,46,86,97,108,117,101,61,49,48,48,32,101,110,100,10,32,32,32,32,32,32,32,32,105,102,32,110,111,101,118,97,115,105,118,101,32,32,32,116,104,101,110,32,83,116,97,116,101,115,46,69,118,97,100,101,67,111,111,108,100,111,119,110,46,86,97,108,117,101,61,102,97,108,115,101,59,32,83,116,97,116,101,115,46,67,97,110,116,69,118,97,100,101,46,86,97,108,117,101,61,102,97,108,115,101,32,101,110,100,10,32,32,32,32,32,32,32,32,105,102,32,110,111,99,111,109,98,111,119,97,105,116,32,116,104,101,110,32,83,116,97,116,101,115,46,67,111,109,98,111,87,97,105,116,46,86,97,108,117,101,61,102,97,108,115,101,32,101,110,100,10,32,32,32,32,32,32,32,32,105,102,32,110,111,114,97,103,100,111,108,108,32,32,32,116,104,101,110,32,83,116,97,116,101,115,46,82,97,103,100,111,108,108,101,100,46,86,97,108,117,101,61,102,97,108,115,101,32,101,110,100,10,32,32,32,32,32,32,32,32,105,102,32,110,111,115,116,117,110,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,95,99,108,101,97,114,61,123})Attacking",(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({66,97,115,101,65,116,116,97,99,107,105,110,103}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,97,110,116,82,117,110}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({66,108,111,99,107,105,110,103}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({68,97,115,104,105,110,103}),
                (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({76,97,110,100,105,110,103}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({80,97,114,107,111,117,114}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({83,108,111,119,87,97,108,107}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({72,111,108,100,105,110,103,73,116,101,109}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({73,110,85,108,116,105,109,97,116,101}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({65,119,97,107,101,110,105,110,103,65,99,116,105,118,101}),
                (function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({72,121,112,101,114,65,114,109,111,114}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,97,110,116,71,114,97,98}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({83,99,97,114,101,100}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({70,114,111,122,101,110}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({67,111,117,110,116,101,114}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({69,109,111,116,105,110,103}),(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({73,70,114,97,109,101,115})}
            for _,name in ipairs(_clear) do
                local s=_vf:FindFirstChild(name)
                if s and s:IsA((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({66,111,111,108,86,97,108,117,101})) then pcall(function() s.Value=false end) end
            end
            local Stuns=_vf:FindFirstChild((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({83,116,117,110,115}))
            if Stuns then
                for _,s in pairs(Stuns:GetChildren()) do
                    pcall(function() s:Destroy() end)
                end
            end
        end
        if _v7 and _vl and _vl.Value==(function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({75,105,110,103,79,102,67,117,114,115,101,115}) then
            if _vk then _vk.Value=3 end
        end
        if _vj then _vj.Value=_vb end
        if _vg then _vg.Value=_v9 end
        local rs=_vf:FindFirstChild((function(t)local s=""for _,c in ipairs(t)do s=s..string.char(c)end;return s end)({82,117,110,110,105,110,103,83,112,101,101,100}))
        if rs then rs.Value=_va end
    end
end
