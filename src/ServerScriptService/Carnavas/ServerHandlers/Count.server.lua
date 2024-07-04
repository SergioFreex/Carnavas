-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')
local yeah = nil

-- // Variables \\ --
local CountEvent: RemoteEvent = ReplicatedStorage.Carnavas.Events.CountEvent
local CountFolder = ReplicatedStorage.Carnavas.GameInfo.Count

CountEvent.OnServerEvent:Connect(function(Player, Strike)
    if not _G.BatterOn[1] then return end
    if Player.UserId ~= _G.BatterOn[2] then print(`{Player.DisplayName} ({Player.Name}) fired the count event even though they aren't the batter. They MIGHT be an exploiter :100:`) return end
    if Strike then
        CountFolder.Strikes.Value = math.clamp(CountFolder.Strikes.Value + 1, 0, 3)
        if CountFolder.Strikes.Value == 3 then
            _G.SendNotifcation('Strikeout!', Player.Name .. ' has struck out.')
            CountFolder.Strikes.Value = 0
            CountFolder.Balls.Value = 0
        else
            _G.SendNotifcation('Strike!', `Strike {CountFolder.Strikes.Value}! The count is {CountFolder.Balls.Value}-{CountFolder.Strikes.Value}`)
        end
    else
        CountFolder.Balls.Value = math.clamp(CountFolder.Balls.Value + 1, 0, 4)
        if CountFolder.Balls.Value == 4 then
            _G.SendNotifcation('Walk.', `That's ball 4! Take your base.`)
        else
            _G.SendNotifcation('Ball.', `Ball {CountFolder.Balls.Value}. The count is {CountFolder.Balls.Value}-{CountFolder.Strikes.Value}`)
            CountFolder.Strikes.Value = 0
            CountFolder.Balls.Value = 0
        end
    end
    print(`{CountFolder.Balls.Value}-{CountFolder.Strikes.Value}`)
end)