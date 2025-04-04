require("stategraphs/commonstates")

local actionhandlers = {
    ActionHandler(ACTIONS.EAT, "eat"),
}

local events = {
    CommonHandlers.OnSleep(),
    CommonHandlers.OnFreeze(),
    CommonHandlers.OnAttack(),
    CommonHandlers.OnAttacked(),
    CommonHandlers.OnDeath(),
    
    EventHandler("locomote", function(inst)
        if not inst.sg:HasStateTag("busy") and not inst.rolled_up then
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
}

local states = {
    State{
        name = "idle",
        tags = {"idle", "canrotate"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("idle", true)
            inst.Physics:Stop()
        end,
    },
    
    State{
        name = "walk_start",
        tags = {"moving", "canrotate"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pre")
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
            inst.AnimState:PlayAnimation("walk_loop", true)
            inst.components.locomotor:WalkForward()
        end,
    },
    
    State{
        name = "walk_stop",
        tags = {"canrotate"},
        
        onenter = function(inst)
            inst.AnimState:PlayAnimation("walk_pst")
            inst.components.locomotor:StopMoving()
        end,
        
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
        name = "death",
        tags = {"busy"},
        
        onenter = function(inst)
            inst.Physics:Stop()
            inst.AnimState:PlayAnimation("death")
            inst.components.locomotor:StopMoving()
        end,
    },
}

CommonStates.AddFrozenStates(states)
CommonStates.AddSleepStates(states)
CommonStates.AddCombatStates(states, 
{
    hittimeline = {
        TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/hedgehog/hurt") end),
    },
    deathtimeline = {
        TimeEvent(0, function(inst) inst.SoundEmitter:PlaySound("dontstarve/creatures/hedgehog/death") end),
    },
})

return StateGraph("hedgehog", states, events, "idle", actionhandlers) 