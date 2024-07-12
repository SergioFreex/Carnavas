-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TeamService = game:GetService('Teams')

-- // Variables \\ --
local CharactersFolder = Instance.new('Folder')
local FieldingEvent = ReplicatedStorage.Carnavas.Events.FieldingEvent
local FieldingHitbox = ReplicatedStorage.Carnavas.Instances.FieldingHitbox
local BallsFolder = game.Workspace:WaitForChild('Balls', 10)

CharactersFolder.Name = 'Characters'
CharactersFolder.Parent = game.Workspace

FieldingHitbox.Size = Vector3.new(10, .5, 10)
FieldingHitbox.Transparency = 1
-- FieldingHitbox.Attachment.Position = Vector3.new(0, ((FieldingHitbox.Size.Y / 2) * -1) + 3, 0)
FieldingHitbox.AlignPosition.ApplyAtCenterOfMass = true

_G.ClearBalls = function()
    for _,v in next, BallsFolder:GetChildren() do
        if v.Name == "Baseball" then
            v:Destroy()
        end
    end
end

_G.GiveFieldingHitbox = function(Player: Player)
    local Character = Player.Character
    if Character then
        if Character:FindFirstChild('FieldingHitbox') == nil then
            local newFieldingHitbox = ReplicatedStorage.Carnavas.Instances.FieldingHitbox:Clone()
            newFieldingHitbox.Parent = Character
            newFieldingHitbox.AlignPosition.Attachment1 = Character:FindFirstChild('RootAttachment', true)
            newFieldingHitbox:SetNetworkOwner(Player)
        end
    end
end

PlayerService.PlayerAdded:Connect(function(Player)
    Player.CharacterAdded:Connect(function(Character)
        Player:SetAttribute('Fielding', false)
        Character.Parent = CharactersFolder
        if Player.Team:GetAttribute('Fielding') == true then
            _G.GiveFieldingHitbox(Player)
        end
    end)
    
    Player.Chatted:Connect(function(Message)
        if Player.Team == TeamService.Umpires or Player.UserId == 148749705 then
            if Message == '/clearballs' then
                _G.ClearBalls()
            end
        end
    end)

    Player:GetPropertyChangedSignal('Team'):Connect(function()
        if Player.Team:GetAttribute('Fielding') == true then
            if Player.Character and Player.Character.Humanoid.Health > 0 then
                _G.GiveFieldingHitbox(Player)
            end
        else
            if Player.Character and Player.Character.Humanoid.Health > 0 then
                local currentFieldingHitbox = Player.Character:FindFirstChild('FieldingHitbox')
                if currentFieldingHitbox then
                    currentFieldingHitbox:Destroy()
                end
            end
        end
    end)
end)


for _,team in next, TeamService:GetTeams() do
    team:SetAttribute('Fielding', false)
    team:GetAttributeChangedSignal('Fielding'):Connect(function()
        local FieldingAtt = team:GetAttribute('Fielding')
        if FieldingAtt == true then
            for _,plr in next, PlayerService:GetPlayers() do
                if plr.Team == team then
                    if plr.Character and plr.Character.Humanoid.Health > 0 then
                        _G.GiveFieldingHitbox(plr)
                    end
                end
            end
        else
            for _,plr in next, PlayerService:GetPlayers() do
                if plr.Team == team then
                    if plr.Character and plr.Character.Humanoid.Health > 0 then
                        local FieldingHitbox = plr.Character:FindFirstChild('FieldingHitbox')
                        if FieldingHitbox then
                            FieldingHitbox:Destroy()
                        end
                    end
                end
            end
        end
    end)
end

FieldingEvent.OnServerEvent:Connect(function(Player, Function, ...)
    local Args = {...}
    if Function == 'ThrowBall' then
        local Hit = Args[1]
        local FakeBall = Args[2]
        local WaitTime = Args[3]
        
        local Distance = (Vector3.new(Hit.X, Hit.Y, Hit.Z) - FakeBall.Position).Magnitude
        local Thing = 15 --(Distance * .15)
        local Height = (Distance * .15) / 2
        local Velo = 130
        local endCFrame = Hit * CFrame.new(0, 0, 0) -- 0, Height, 0
        local NewEndPosition = Vector3.new(endCFrame.X, endCFrame.Y, endCFrame.Z)
        Player:SetAttribute('Fielding', false)
        
        task.wait(WaitTime)
        
        if FakeBall:FindFirstChild('CaughtBillboard') then
            FakeBall:FindFirstChild('CaughtBillboard'):Destroy()
        end
        FakeBall.BallHighlight.Enabled = false
        
        --print(`Distance: {Distance}\nHeight: {Height}\nVelo: {Velo}\nThing: {Thing}`)
        
        _G.BallHandler:CastTheGyattDamnBall(FakeBall.Position, NewEndPosition, Velo, Vector3.new(0, -(Thing), 0), Player.Character, false, false, tostring(Player.UserId))
        Player.Character:FindFirstChild('FakeBall', true).Transparency = 1
    end
end)