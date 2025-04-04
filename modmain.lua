GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

PrefabFiles = {
    "hedgehog",
}

-- 添加刺猬生成到世界
AddPrefabPostInit("world", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("hedgehogspawner")
    end
end)

-- 添加刺猬到生物列表
STRINGS.NAMES.HEDGEHOG = "刺猬"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.HEDGEHOG = "一只可爱的小刺猬！"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.HEDGEHOG = "它的刺看起来很锋利。"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.HEDGEHOG = "小刺球不吓人！"
STRINGS.CHARACTERS.WENDY.DESCRIBE.HEDGEHOG = "它蜷缩成球来保护自己免受这个残酷世界的伤害。"
STRINGS.CHARACTERS.WX78.DESCRIBE.HEDGEHOG = "带刺的哺乳动物。无威胁。"
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.HEDGEHOG = "Erinaceinae，一种带刺的夜行性哺乳动物。"
STRINGS.CHARACTERS.WOODIE.DESCRIBE.HEDGEHOG = "嘿，小家伙，小心别扎到自己。"
STRINGS.CHARACTERS.MAXWELL.DESCRIBE.HEDGEHOG = "一个带刺的小麻烦。"
STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.HEDGEHOG = "这种生物的防御机制相当有效。"
STRINGS.CHARACTERS.WARLY.DESCRIBE.HEDGEHOG = "太小了，不值得做成一顿饭。"

-- 设置刺猬的掉落物表
SetSharedLootTable('hedgehog', {
    {'smallmeat', 1.0},
    {'cutgrass', 0.5},
    {'twigs', 0.3},
})
