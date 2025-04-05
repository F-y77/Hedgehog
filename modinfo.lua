name = "豪猪"
description = "为游戏添加一种新生物：豪猪！"
author = "凌"
version = "1.0.0"

api_version = 10    

-- 兼容性
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false

-- 图标
icon_atlas = "modicon.xml"
icon = "modicon.tex"

server_filter_tags = {"porcupine","豪猪","凌"}
-- 配置选项
configuration_options = {
    {
        name = "porcupine_spawn_rate",
        label = "豪猪生成率",
        options = {
            {description = "稀少", data = 0.05},
            {description = "默认", data = 0.1},
            {description = "频繁", data = 0.2}
        },
        default = 0.1
    }
} 