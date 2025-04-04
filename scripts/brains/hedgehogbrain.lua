require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/standstill"
require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

local MIN_FOLLOW_DIST = 2
local TARGET_FOLLOW_DIST = 3
local MAX_FOLLOW_DIST = 6
local WANDER_DIST = 20
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_FOOD_DIST = 10

local HedgehogBrain = Class(Brain, function(self, inst)
    Brain._ctor(self, inst)
end)

local EATFOOD_CANT_TAGS = { "INLIMBO", "outofreach" }
local function EatFoodAction(inst)
    if inst.sg:HasStateTag("busy") then
        return
    elseif inst.components.inventory ~= nil and inst.components.eater ~= nil then
        local target = inst.components.inventory:FindItem(function(item) return inst.components.eater:CanEat(item) end)
        if target ~= nil then
            return BufferedAction(inst, target, ACTIONS.EAT)
        end
    end

    local target = FindEntity(inst,
        SEE_FOOD_DIST,
        function(item)
            return item:GetTimeAlive() >= 8
                and item:IsOnValidGround()
                and inst.components.eater:CanEat(item)
        end,
        nil,
        EATFOOD_CANT_TAGS
    )
    if target ~= nil then
        local ba = BufferedAction(inst, target, ACTIONS.PICKUP)
        ba.distance = 1.5
        return ba
    end
end

local function GoHomeAction(inst)
    local home_pos = inst.components.knownlocations:GetLocation("home")
    if home_pos ~= nil then
        return BufferedAction(inst, nil, ACTIONS.WALKTO, nil, home_pos)
    end
end

local function ShouldGoHome(inst)
    if inst.components.combat.target ~= nil then
        return false
    end
    
    local home_pos = inst.components.knownlocations:GetLocation("home")
    if home_pos == nil then
        return false
    end
    
    local current_time = GetTime()
    if current_time - (inst.last_home_time or 0) < 60 then -- 每分钟检查一次是否要回家
        return false
    end
    
    inst.last_home_time = current_time
    local hx, hy, hz = home_pos:Get()
    local px, py, pz = inst.Transform:GetWorldPosition()
    return distsq(hx, hz, px, pz) > 20*20 -- 如果距离家太远，就回家
end

function HedgehogBrain:OnStart()
    local root = PriorityNode({
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        WhileNode(function() return self.inst.rolled_up end, "RolledUp", StandStill(self.inst)),
        BrainCommon.PanicTrigger(self.inst),
        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        DoAction(self.inst, EatFoodAction, "Get Food", true),
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, GoHomeAction, "Go Home", true)),
        RunAway(self.inst, "scarytoprey", 4, 8),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, WANDER_DIST)
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return HedgehogBrain 