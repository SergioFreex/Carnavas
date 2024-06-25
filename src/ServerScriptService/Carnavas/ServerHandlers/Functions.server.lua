-- // Services \\ --
local PlayerService = game:GetService('Players')
local Nil = nil

_G.GetPlayerWithUserID = function(UserID: number)
    for _,player in next, PlayerService:GetPlayers() do
        if player.UserId == tonumber(UserID) then
            return player
        end
    end
    return nil
end