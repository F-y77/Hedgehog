local PorcupineSpawner = Class(function(self, inst)
    self.inst = inst
    self.porcupines = {}
    self.max_porcupines = 4
    self.spawn_period = 480 -- 每20天游戏时间
    self.spawn_variance = 120 -- 有5天的随机变化
    
    self:StartSpawning()
end)

function PorcupineSpawner:StartSpawning()
    if self.task == nil then
        local time_to_spawn = self.spawn_period + math.random(-self.spawn_variance, self.spawn_variance)
        self.task = self.inst:DoTaskInTime(time_to_spawn, function() self:TrySpawnPorcupine() end)
    end
end

function PorcupineSpawner:StopSpawning()
    if self.task ~= nil then
        self.task:Cancel()
        self.task = nil
    end
end

function PorcupineSpawner:TrySpawnPorcupine()
    self.task = nil
    
    -- 检查当前豪猪数量
    local current_count = 0
    for k, v in pairs(self.porcupines) do
        if v:IsValid() then
            current_count = current_count + 1
        else
            self.porcupines[k] = nil
        end
    end
    
    -- 如果豪猪数量未达到上限，尝试生成新的豪猪
    if current_count < self.max_porcupines then
        local player = FindClosestPlayer()
        if player ~= nil then
            local pos = player:GetPosition()
            local offset = FindWalkableOffset(pos, math.random() * 2 * PI, 30, 12, true)
            
            if offset ~= nil then
                local spawn_pos = pos + offset
                local porcupine = SpawnPrefab("porcupine")
                if porcupine ~= nil then
                    porcupine.Transform:SetPosition(spawn_pos.x, spawn_pos.y, spawn_pos.z)
                    table.insert(self.porcupines, porcupine)
                end
            end
        end
    end
    
    -- 安排下一次生成
    self:StartSpawning()
end

return PorcupineSpawner 