GLOBAL.setmetatable(env, { __index = function(t, k) return GLOBAL.rawget(GLOBAL, k) end })

PrefabFiles = {
    "porcupine",
}

-- 添加豪猪生成到世界
AddPrefabPostInit("world", function(inst)
    if TheWorld.ismastersim then
        inst:AddComponent("porcupinespawner")
    end
end)

-- 添加豪猪到生物列表
STRINGS.NAMES.PORCUPINE = "豪猪"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PORCUPINE = "一只威风凛凛的豪猪！"
STRINGS.CHARACTERS.WILLOW.DESCRIBE.PORCUPINE = "它的刺看起来很危险，我喜欢。"
STRINGS.CHARACTERS.WOLFGANG.DESCRIBE.PORCUPINE = "刺猪不吓人！但是刺很疼！"
STRINGS.CHARACTERS.WENDY.DESCRIBE.PORCUPINE = "它的刺是对这个残酷世界的完美回应。"
STRINGS.CHARACTERS.WX78.DESCRIBE.PORCUPINE = "带刺的哺乳动物。威胁等级：中等。"
STRINGS.CHARACTERS.WICKERBOTTOM.DESCRIBE.PORCUPINE = "Hystricidae，一种带有坚硬刺的啮齿类动物。"
STRINGS.CHARACTERS.WOODIE.DESCRIBE.PORCUPINE = "这家伙的刺比我的斧头还锋利，得小心点。"
STRINGS.CHARACTERS.MAXWELL.DESCRIBE.PORCUPINE = "一个危险的带刺生物，最好保持距离。"
STRINGS.CHARACTERS.WAGSTAFF.DESCRIBE.PORCUPINE = "这种生物的防御机制非常先进。"
STRINGS.CHARACTERS.WARLY.DESCRIBE.PORCUPINE = "如果能安全地处理它，可能会是不错的食材。"

-- 设置豪猪的掉落物表
SetSharedLootTable('porcupine', {
    {'meat', 1.0},
    {'porcupinequill', 0.75},
    {'porcupinequill', 0.5},
})

-- 添加豪猪刺物品
STRINGS.NAMES.PORCUPINEQUILL = "豪猪刺"
STRINGS.CHARACTERS.GENERIC.DESCRIBE.PORCUPINEQUILL = "锋利的豪猪刺，小心别扎到手。"
