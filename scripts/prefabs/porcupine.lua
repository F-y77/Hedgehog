local assets = {
    Asset("ANIM", "anim/porcupine.zip"),
}

local prefabs = {
    "meat",
    "porcupinequill",
}

-- 设置豪猪的常量
local SLEEP_DIST_FROMHOME = 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST = 30
local MAX_TARGET_SHARES = 3
local SHARE_TARGET_DIST = 30
local QUILL_ATTACK_DAMAGE = 10
local QUILL_RAISE_TIME = 8

local porcupine_brain = require "brains/porcupinebrain"

local sounds = {
    idle = "dontstarve/creatures/porcupine/idle",
    hurt = "dontstarve/creatures/porcupine/hurt",
    death = "dontstarve/creatures/porcupine/death",
    attack = "dontstarve/creatures/porcupine/attack",
}

local function KeepTarget(inst, target)
    if not target:IsValid() then
        return false
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and target:GetDistanceSqToPoint(homePos) < MAX_CHASEAWAY_DIST * MAX_CHASEAWAY_DIST
end

local function IsPorcupine(dude)
    return dude:HasTag("porcupine")
end

local function UpdateQuillState(inst)
    -- 检查附近是否有威胁
    local player = FindClosestPlayer(inst:GetPosition(), 10)
    local threatNearby = player ~= nil and not inst.quills_raised
    
    if threatNearby then
        -- 触发threatened事件，而不是直接修改动画
        inst:PushEvent("threatened")
    end
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsPorcupine, MAX_TARGET_SHARES)
    
    -- 当被攻击时，豪猪会竖起刺
    if not inst.quills_raised then
        -- 触发threatened事件，而不是直接修改动画
        inst:PushEvent("threatened")
        
        -- 如果攻击者靠得太近，会受到刺伤
        if attacker ~= nil and attacker.components.health ~= nil and 
           not attacker:HasTag("porcupine") and attacker:GetDistanceSqToInst(inst) < 2*2 then
            attacker.components.health:DoDelta(-QUILL_ATTACK_DAMAGE)
            -- 播放受伤特效
            SpawnPrefab("sparks").Transform:SetPosition(attacker:GetPosition():Get())
            -- 播放刺伤声音
            inst.SoundEmitter:PlaySound(sounds.attack)
        end
        
        -- 取消之前的计时器
        if inst.quill_timer ~= nil then
            inst.quill_timer:Cancel()
            inst.quill_timer = nil
        end
        
        -- 一段时间后恢复正常
        inst.quill_timer = inst:DoTaskInTime(QUILL_RAISE_TIME, function() 
            if inst.quills_raised and inst:IsValid() then
                -- 触发unthreatened事件，而不是直接修改动画
                inst:PushEvent("unthreatened")
            end
        end)
    end
    
    -- 如果已经竖起刺，则对攻击者造成反伤
    elseif attacker ~= nil and attacker.components.health ~= nil and 
           not attacker:HasTag("porcupine") and attacker:GetDistanceSqToInst(inst) < 3*3 then
        -- 反伤伤害
        attacker.components.health:DoDelta(-QUILL_ATTACK_DAMAGE)
        -- 播放受伤特效
        SpawnPrefab("sparks").Transform:SetPosition(attacker:GetPosition():Get())
        -- 播放刺伤声音
        inst.SoundEmitter:PlaySound(sounds.attack)
    end
end

local function OnInit(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
    -- 开始定期检查周围是否有威胁
    inst:DoPeriodicTask(1, UpdateQuillState)
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1.5, 1.0)

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 50, .5)

    inst.AnimState:SetBank("porcupine")
    inst.AnimState:SetBuild("porcupine")
    inst.AnimState:PlayAnimation("idle", true)

    inst:AddTag("animal")
    inst:AddTag("porcupine")
    inst:AddTag("hostile")
    inst:AddTag("scarytoprey")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.PERD_WALK_SPEED
    inst.components.locomotor.runspeed = TUNING.PERD_RUN_SPEED

    inst:SetStateGraph("SGporcupine")
    inst:SetBrain(porcupine_brain)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('porcupine')

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:DoTaskInTime(0, OnInit)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetDefaultDamage(TUNING.PERD_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.PERD_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, function() 
        -- 只有当豪猪竖起刺时才会主动攻击
        if inst.quills_raised then
            return FindEntity(
                inst,
                TUNING.PERD_TARGET_DIST,
                function(guy)
                    return inst.components.combat:CanTarget(guy) and 
                           not guy:HasTag("porcupine")
                end,
                nil,
                nil,
                {"player", "character"}
            )
        end
        return nil
    end)

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.CATCOON_HEALTH)

    MakeMediumBurnableCharacter(inst, "body")
    MakeMediumFreezableCharacter(inst, "body")
    MakeHauntablePanic(inst)

    inst:ListenForEvent("attacked", OnAttacked)

    inst.quills_raised = false
    inst.quill_timer = nil

    return inst
end

-- 豪猪刺物品
local function quill_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("porcupinequill")
    inst.AnimState:SetBuild("porcupinequill")
    inst.AnimState:PlayAnimation("idle")

    inst:AddTag("sharp")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("stackable")
    inst.components.stackable.maxsize = TUNING.STACK_SIZE_SMALLITEM

    inst:AddComponent("inspectable")

    inst:AddComponent("inventoryitem")
    
    inst:AddComponent("weapon")
    inst.components.weapon:SetDamage(TUNING.SPEAR_DAMAGE / 2)
    
    return inst
end

return Prefab("porcupine", fn, assets, prefabs),
       Prefab("porcupinequill", quill_fn, assets) 