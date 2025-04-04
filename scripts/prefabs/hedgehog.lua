local assets = {
    Asset("ANIM", "anim/hedgehog.zip"),
    --Asset("SOUND", "sound/hedgehog.fsb"),
    
}

local prefabs = {
    "smallmeat",
    "cutgrass",
    "twigs",
}

-- 设置刺猬的常量
local SLEEP_DIST_FROMHOME = 1
local SLEEP_DIST_FROMTHREAT = 20
local MAX_CHASEAWAY_DIST = 30
local MAX_TARGET_SHARES = 3
local SHARE_TARGET_DIST = 30

local hedgehog_brain = require "brains/hedgehogbrain"

local sounds = {
    idle = "dontstarve/creatures/hedgehog/idle",
    hurt = "dontstarve/creatures/hedgehog/hurt",
    death = "dontstarve/creatures/hedgehog/death",
    attack = "dontstarve/creatures/hedgehog/attack",
}

local function KeepTarget(inst, target)
    if not target:IsValid() then
        return false
    end
    local homePos = inst.components.knownlocations:GetLocation("home")
    return homePos ~= nil and target:GetDistanceSqToPoint(homePos) < MAX_CHASEAWAY_DIST * MAX_CHASEAWAY_DIST
end

local function IsHedgehog(dude)
    return dude:HasTag("hedgehog")
end

local function OnAttacked(inst, data)
    local attacker = data ~= nil and data.attacker or nil
    inst.components.combat:SetTarget(attacker)
    inst.components.combat:ShareTarget(attacker, SHARE_TARGET_DIST, IsHedgehog, MAX_TARGET_SHARES)
    
    -- 当被攻击时，刺猬会卷成一个球
    if not inst.rolled_up then
        inst.rolled_up = true
        inst.AnimState:PlayAnimation("roll_up")
        inst.AnimState:PushAnimation("rolled", true)
        inst.components.locomotor:Stop()
        inst:DoTaskInTime(5, function() 
            inst.rolled_up = false
            inst.AnimState:PlayAnimation("roll_down")
            inst.AnimState:PushAnimation("idle", true)
        end)
    -- 如果已经卷成球，则对攻击者造成反伤
    elseif attacker ~= nil and attacker.components.health ~= nil and not attacker:HasTag("hedgehog") then
        -- 反伤伤害为攻击者伤害的一半
        local reflect_damage = math.floor(data.damage * 0.5)
        if reflect_damage > 0 then
            attacker.components.health:DoDelta(-reflect_damage)
            -- 播放受伤特效
            if attacker.components.combat.hiteffectsymbol then
                SpawnPrefab("sparks").Transform:SetPosition(attacker:GetPosition():Get())
            end
            -- 播放刺伤声音
            --inst.SoundEmitter:PlaySound("dontstarve/creatures/hedgehog/attack")
        end
    end
end

local function OnInit(inst)
    inst.components.knownlocations:RememberLocation("home", inst:GetPosition())
end

local function fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddSoundEmitter()
    inst.entity:AddDynamicShadow()
    inst.entity:AddNetwork()

    inst.DynamicShadow:SetSize(1, 0.75)

    inst.Transform:SetFourFaced()

    MakeCharacterPhysics(inst, 30, .3)

    inst.AnimState:SetBank("hedgehog")
    inst.AnimState:SetBuild("hedgehog")

    inst:AddTag("animal")
    inst:AddTag("hedgehog")
    inst:AddTag("smallcreature")

    inst.entity:SetPristine()

    if not TheWorld.ismastersim then
        return inst
    end

    inst:AddComponent("locomotor")
    inst.components.locomotor.walkspeed = TUNING.RABBIT_WALK_SPEED

    inst:SetStateGraph("SGhedgehog")
    inst:SetBrain(hedgehog_brain)

    inst:AddComponent("eater")
    inst.components.eater:SetDiet({ FOODTYPE.VEGGIE }, { FOODTYPE.VEGGIE })

    inst:AddComponent("lootdropper")
    inst.components.lootdropper:SetChanceLootTable('hedgehog')

    inst:AddComponent("inspectable")
    inst:AddComponent("knownlocations")

    inst:DoTaskInTime(0, OnInit)

    inst:AddComponent("combat")
    inst.components.combat.hiteffectsymbol = "body"
    inst.components.combat:SetKeepTargetFunction(KeepTarget)
    inst.components.combat:SetDefaultDamage(TUNING.FROG_DAMAGE)
    inst.components.combat:SetAttackPeriod(TUNING.FROG_ATTACK_PERIOD)
    inst.components.combat:SetRetargetFunction(3, function() return nil end) -- 刺猬不主动攻击

    inst:AddComponent("health")
    inst.components.health:SetMaxHealth(TUNING.RABBIT_HEALTH * 1.5)

    MakeSmallBurnableCharacter(inst, "body")
    MakeSmallFreezableCharacter(inst, "body")
    MakeHauntablePanic(inst)

    inst:ListenForEvent("attacked", OnAttacked)

    inst.rolled_up = false

    return inst
end

--[[ 刺猬刺物品
local function spines_fn()
    local inst = CreateEntity()

    inst.entity:AddTransform()
    inst.entity:AddAnimState()
    inst.entity:AddNetwork()

    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("prickly_spines")
    inst.AnimState:SetBuild("prickly_spines")
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
    inst.components.inventoryitem.imagename = "prickly_spines"
    inst.components.inventoryitem.atlasname = "images/inventoryimages/prickly_spines.xml"

    return inst
end]]

return Prefab("hedgehog", fn, assets, prefabs)--，
       --Prefab("prickly_spines", spines_fn, assets) 