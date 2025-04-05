require "behaviours/wander"
require "behaviours/runaway"
require "behaviours/doaction"
require "behaviours/panic"
require "behaviours/standstill"
require "behaviours/chaseandattack"
local BrainCommon = require("brains/braincommon")

local WANDER_DIST = 20
local MAX_CHASE_TIME = 10
local MAX_CHASE_DIST = 30
local SEE_FOOD_DIST = 10
local SEE_PLAYER_DIST = 5

local PorcupineBrain = Class(Brain, function(self, inst)
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
        -- 检查食物附近是否有威胁
        local predator = FindEntity(target, SEE_PLAYER_DIST, function(ent) 
            return ent:HasTag("player") or ent:HasTag("monster") 
        end)
        
        if predator == nil then
            local ba = BufferedAction(inst, target, ACTIONS.PICKUP)
            ba.distance = 1.5
            return ba
        end
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

function PorcupineBrain:OnStart()
    local root = PriorityNode({
        -- 着火时逃跑
        WhileNode(function() return self.inst.components.health.takingfiredamage end, "OnFire", Panic(self.inst)),
        
        -- 当豪猪竖起刺时，会站在原地或攻击
        WhileNode(function() return self.inst.quills_raised end, "QuillsRaised", 
            PriorityNode({
                -- 如果有目标并且目标靠近，则攻击
                ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
                
                -- 否则站在原地
                StandStill(self.inst)
            }, .25)),
        
        -- 一般状态下的行为
        ChaseAndAttack(self.inst, MAX_CHASE_TIME, MAX_CHASE_DIST),
        DoAction(self.inst, EatFoodAction, "Get Food", true),
        WhileNode(function() return ShouldGoHome(self.inst) end, "ShouldGoHome",
            DoAction(self.inst, GoHomeAction, "Go Home", true)),
        Wander(self.inst, function() return self.inst.components.knownlocations:GetLocation("home") end, WANDER_DIST)
    }, .25)
    
    self.bt = BT(self.inst, root)
end

return PorcupineBrain 