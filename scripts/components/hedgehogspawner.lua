local HedgehogSpawner = Class(function(self, inst)
    self.inst = inst
    self.hedgehogs = {}
    self.max_hedgehogs = 4
    self.spawn_period = 480 -- 每20天游戏时间
    self.spawn_variance = 120 -- 有5天的随机变化
    
    self:StartSpawning()
end)

function HedgehogSpawner:StartSpawning()
    if self.task == nil then
        local time_to_spawn = self.spawn_period + math.random(-self.spawn_variance, self.spawn_variance)
        self.task = self.inst:DoTaskInTime(time_to_spawn, function() self:TrySpawnHedgehog() end)
    end
end

function HedgehogSpawner:StopSpawning()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function HedgehogSpawner:TrySpawnHedgehog()
    self.task = nil
    
    -- 检查当前刺猬数量
    local current_count = 0
    for k, v in pairs(self.hedgehogs) do
        if v:IsValid() then
            current_count = current_count + 1
        else
            self.hedgehogs[k] = nil
        end
    end
    
    -- 如果刺猬数量未达到上限，尝试生成新的刺猬
    if current_count < self.max_hedgehogs then
        local player = FindClosestPlayer()
        if player ~= nil then
            local pos = player:GetPosition()
            local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 30, 12, true)
            
            if offset ~= nil then
                local spawn_pos = pos + offset
                local hedgehog = SpawnPrefab("hedgehog")
                if hedgehog ~= nil then
                    hedgehog.Transform:SetPosition(spawn_pos.x, spawn_pos.y, spawn_pos.z)
                    table.insert(self.hedgehogs, hedgehog)
                end
            end
        end
    end
    
    -- 安排下一次生成
    self:StartSpawning()
end

return HedgehogSpawner 