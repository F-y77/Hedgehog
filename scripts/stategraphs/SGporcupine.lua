require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.EAT, "eat"),
    ActionHandler(ACTIONS.PICKUP, "pickup"),
}

local events = {
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") then
            local is_moving = inst.sg:HasStateTag("moving")
            local wants_to_move = inst.components.locomotor:WantsToMoveForward()
            
            if is_moving ~= wants_to_move then
                if wants_to_move then
                    inst.sg:GoToState("walk_start")
                else
                    inst.sg:GoToState("walk_stop")
                end
            end
        end
    end),
    
    EventHandler("threatened", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.quills_raised then
            inst.sg:GoToState("threatened")
        end
    end),
    
    EventHandler("unthreatened", function(inst)
        if not inst.sg:HasStateTag("busy") and inst.quills_raised then
            inst.sg:GoToState("unthreatened")
        end
    end),
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst)
            if inst.quills_raised then
                inst.AnimState:PlayAnimation("idle_threatened", true)
            else
                inst.AnimState:PlayAnimation("idle", true)
            end
            inst.Physics:Stop()
        end,
    },
    
    State{
        name = "walk_start",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            if inst.quills_raised then
                inst.AnimState:PlayAnimation("walk_pre_threatened")
            else
                inst.AnimState:PlayAnimation("walk_pre")
            end
            inst.components.locomotor:WalkForward()
        end,
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("walk") end),
        },
    },
    
    State{
        name = "walk",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            if inst.quills_raised then
                inst.AnimState:PlayAnimation("walk_loop_threatened", true)
            else
                inst.AnimState:PlayAnimation("walk_loop", true)
            end
            inst.components.locomotor:WalkForward()
        end,
    },
    
    State{
        name = "walk_stop",
        tags = {"canrotate"},
        
        onenter = function(inst)
            if inst.quills_raised then
                inst.AnimState:PlayAnimation("walk_pst_threatened")
            else
                inst.AnimState:PlayAnimation("walk_pst")
            end
            inst.components.locomotor:StopMoving()
        end,
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "threatened",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("threatened")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/porcupine/threatened")
        end,
        
        timeline = {
            TimeEvent(15*FRAMES, function(inst) 
                inst.quills_raised = true 
            end),
        },
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "unthreatened",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("unthreatened")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/porcupine/unthreatened")
        end,
        
        timeline = {
            TimeEvent(15*FRAMES, function(inst) 
                inst.quills_raised = false 
            end),
        },
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "eat",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("eat_pre")
            inst.AnimState:PushAnimation("eat_loop", true)
        end,
        
        timeline = {
            TimeEvent(10*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "pickup",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("pickup")
        end,
        
        timeline = {
            TimeEvent(10*FRAMES, function(inst) inst:PerformBufferedAction() end),
        },
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "attack",
        tags = {"attack", "busy"},
        
        onenter = function(inst)
            inst.components.combat:StartAttack()
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("attack")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/porcupine/attack")
        end,
        
        timeline = {
            TimeEvent(10*FRAMES, function(inst) inst.components.combat:DoAttack() end),
        },
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "hit",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("hit")
            inst.SoundEmitter:PlaySound("dontstarve/creatures/porcupine/hurt")
        end,
        
        events = {
            EventHandler("animover", function(inst) inst.sg:GoToState("idle") end),
        },
    },
    
    State{
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
            inst.SoundEmitter:PlaySound("dontstarve/creatures/porcupine/death")
        end,
    },
}

CommonStates.AddFrozenStates(states)
CommonStates.AddSleepStates(states)

return StateGraph("porcupine", states, events, "idle", actionhandlers) 