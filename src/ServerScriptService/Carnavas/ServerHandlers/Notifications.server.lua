-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')

-- // Variables \\ --
local NotificationEvent: RemoteEvent = ReplicatedStorage.Carnavas.Events.NotificationEvent

NotificationEvent.OnServerEvent:Connect(function(Player)
    Player:Kick('Pleae dont exploit that hurts my feelings :(')
end)

_G.SendNotifcation = function(Title, Message, ToWho)
    if ToWho == nil then
        NotificationEvent:FireAllClients(Title, Message)
    else
        if ToWho:IsA('Player') then
            local Success, Error = pcall(function()
                NotificationEvent:FireClient(ToWho, Title, Message)
            end)

            if not Success then
                warn(`{script.Name} :: An error has occured when trying to send a notification to a player. Error: {Error}`)
            end
        end
    end
end