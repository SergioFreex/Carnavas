-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')

-- local StrikeZone = game.Workspace:FindFirstChild('StrikeZone', true)
local Count = ReplicatedStorage.Carnavas.GameInfo.Count

local Balls = Count.Balls
local Strikes = Count.Strikes

local Debounce = {false, 2}

local module = {}

function SetFalse()
    Debounce[1] = false
    print('set debounce to false')
end

function module.HandleCount(IsStrike: boolean)
    if _G.BatterOn[1] then
        if not Debounce[1] then
            if IsStrike then
                Debounce[1] = true
                Strikes.Value += 1
                Strikes.Value = math.clamp(Strikes.Value, 0, 3)
                task.delay(Debounce[2], SetFalse)
                print('Strike! The count is now ' .. Balls.Value .. '-' .. Strikes.Value)
            else
                Debounce[1] = true
                Balls.Value += 1
                Balls.Value = math.clamp(Balls.Value, 0, 4)
                task.delay(Debounce[2], SetFalse)
            end
        else
            print("debounced rn not gonna check that one og.")
        end
    end
end

return module