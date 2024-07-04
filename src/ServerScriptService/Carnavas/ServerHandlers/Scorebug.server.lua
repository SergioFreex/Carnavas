-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')

-- // Variables \\ --
local Event = ReplicatedStorage.Carnavas.Events.ScorebugEvent

-- // Game Values \\ --
local GameValues = ReplicatedStorage.Carnavas:WaitForChild('GameInfo')
local HomeValues = GameValues.Home
local AwayValues = GameValues.Away
local MiscValues = GameValues.Misc

Event.OnServerEvent:Connect(function(Player, Function, ...)
    local Args = {...}
    
    -- // Change inning number
    if Function == 'InningNumber' then
        if Args[1] == 'Subtract' then
            local InningInfo = string.split(MiscValues.Inning.Value, ':') -- TopBottom:Number
            if InningInfo[2] - 1 >= 1 then
                MiscValues.Inning.Value = InningInfo[1] .. ':' .. tostring(InningInfo[2] - 1)
            end
        elseif Args[1] == 'Add' then
            local InningInfo = string.split(MiscValues.Inning.Value, ':') -- TopBottom:Number
            MiscValues.Inning.Value = InningInfo[1] .. ':' .. tostring(InningInfo[2] + 1)
        end
        
    -- // Change inning half
    elseif Function == 'ToggleInningHalf' then
        local InningInfo = string.split(MiscValues.Inning.Value, ':') -- TopBottom:Number
        MiscValues.Inning.Value = Args[1] .. ':' .. InningInfo[2]
        
    -- // Toggle baserunners
    elseif Function == 'FirstBase' or Function == 'SecondBase' or Function == 'ThirdBase' then
        local BaseValue = MiscValues:FindFirstChild(Function)
        if BaseValue then
            if BaseValue.Value == false then 
                BaseValue.Value = true 
            else 
                BaseValue.Value = false 
            end
        else
            print('couldnt find basevalue')
        end
        
    -- // Increase or decrease outs
    elseif Function == 'Outs' then
        if Args[1] == 'Subtract' then
            if MiscValues.Outs.Value - 1 >= 0 then
                MiscValues.Outs.Value -= 1
            end
        elseif Args[1] == 'Add' then
            if MiscValues.Outs.Value + 1 <= 3 then
                MiscValues.Outs.Value += 1
            end
        end
        
    -- // Increase or decrease strikes
    elseif Function == 'Strikes' then
        if Args[1] == 'Subtract' then
            if GameValues.Count.Strikes.Value - 1 >= 0 then
                GameValues.Count.Strikes.Value -= 1
            end
        elseif Args[1] == 'Add' then
            if GameValues.Count.Strikes.Value + 1 <= 3 then
                GameValues.Count.Strikes.Value += 1
            end
        end
        
    -- // Increase or decrease balls
    elseif Function == 'Balls' then
        if Args[1] == 'Subtract' then
            if GameValues.Count.Balls.Value - 1 >= 0 then
                GameValues.Count.Balls.Value -= 1
            end
        elseif Args[1] == 'Add' then
            if GameValues.Count.Balls.Value + 1 <= 4 then
                GameValues.Count.Balls.Value += 1
            end
        end
    end
end)