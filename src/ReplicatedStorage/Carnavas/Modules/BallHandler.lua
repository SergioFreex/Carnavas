-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local DebrisService = game:GetService('Debris')
local ServerScriptService = game:GetService('ServerScriptService')

-- // Variables \\ --
local FastCast = require(ReplicatedStorage.Carnavas.Modules.FastCastRedux)

FastCast.VisualizeCasts = false

local BallEvent = ReplicatedStorage.Carnavas.Events.BallEvent
local CasterEvents = nil

local CountBindEvent = ReplicatedStorage.Carnavas.Events.CountBindEvent
local BallsFolder = game.Workspace:WaitForChild('Balls', 10)
local GloveSounds = ReplicatedStorage.Carnavas.Sounds.Glove

local ClientCasters = {}
local ServerCasters = {}

local RayHit_Connections = {}
local HitBall_MarkerCaster = FastCast.new()

local module = {}

local SZ_Debounce = {false, 3}

-- // Handing balls and strikes on pitched ball
local function StrikeZone_PierceFunction(Raycast, Result, SegmentVelocity)
    local instance: Instance = Result.Instance
    local StrikeOrNah = false

    if instance:FindFirstAncestor('Batting') then
        if SZ_Debounce[1] then
            return true
        end

        SZ_Debounce[1] = true
        task.delay(SZ_Debounce[2], function()
            SZ_Debounce[1] = false
        end)

        if instance.Name:lower() == "strikezone" or instance.Parent.Name:lower() == 'strikezone' then
            if RunService:IsClient() then
                local BallPos = Result.Position
                local fakeBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
                fakeBall.Name = 'SZ_Ball'
                fakeBall.Anchored = true
                fakeBall.Parent = BallsFolder
                fakeBall.Position = BallPos
                fakeBall.Transparency = 0
                fakeBall.Highlight.Enabled = false
                fakeBall.StrikeZoneHighlight.Enabled = true
                fakeBall.StrikeZoneHighlight.FillTransparency = 0

                fakeBall.CanCollide = false
                fakeBall.CanQuery = false
                fakeBall.CanTouch = false

                DebrisService:AddItem(fakeBall, 4)
            end
            StrikeOrNah = true
        elseif instance.Name == 'ExtendedHitbox' then
            if RunService:IsClient() then
                local BallPos = Result.Position
                local fakeBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
                fakeBall.Name = 'SZ_Ball'
                fakeBall.Anchored = true
                fakeBall.Parent = BallsFolder
                fakeBall.Position = BallPos
                fakeBall.Transparency = 0
                fakeBall.Highlight.Enabled = false
                fakeBall.StrikeZoneHighlight.Enabled = true
                fakeBall.StrikeZoneHighlight.FillTransparency = 1

                fakeBall.CanCollide = false
                fakeBall.CanQuery = false
                fakeBall.CanTouch = false

                DebrisService:AddItem(fakeBall, 4)
            end
        end

        if RunService:IsClient() then
            CountBindEvent:Fire(StrikeOrNah)
            print(StrikeOrNah)
        end

        return true
    end

    return false
end

-- // Create a new caster function
local function CreateCaster(CastID)
    if RunService:IsClient() then
        local Caster = FastCast.new()
        local NewBindableEvent = Instance.new('BindableEvent', CasterEvents)
        NewBindableEvent.Name = tostring(CastID) -- i don't really need to use tostring() but i feel more safe that way
        NewBindableEvent.Parent = CasterEvents

        ClientCasters[tostring(CastID)] = {Caster, NewBindableEvent}
    elseif RunService:IsServer() then
        local Caster = FastCast.new()
        local NewBindableEvent = Instance.new('BindableEvent', CasterEvents)
        NewBindableEvent.Name = tostring(CastID) -- i don't really need to use tostring() but i feel more safe that way
        NewBindableEvent.Parent = CasterEvents

        ServerCasters[tostring(CastID)] = {Caster, NewBindableEvent}
    end
end

-- // Creating a new caster on player join
if RunService:IsClient() then
    CasterEvents = Instance.new('Folder', ReplicatedStorage.Carnavas)
    CasterEvents.Name = 'CasterEvents'
    for _,plr in next, PlayerService:GetPlayers() do
        if ClientCasters[tostring(plr.UserId)] == nil then
            CreateCaster(tostring(plr.UserId))
        end
    end

    if ClientCasters['Server'] == nil then
        CreateCaster('Server')
    end

    PlayerService.PlayerAdded:Connect(function(Plr)
        if Plr ~= PlayerService.LocalPlayer then
            local FindPreviousCaster = ClientCasters[tostring(Plr.UserId)]
            if not FindPreviousCaster then
                CreateCaster(tostring(Plr.UserId))
            end
        end
    end)
elseif RunService:IsServer() then
    CasterEvents = Instance.new('Folder', ServerScriptService.Carnavas)
    CasterEvents.Name = 'CasterEvents'
    CreateCaster('Server')

    PlayerService.PlayerAdded:Connect(function(Plr)
        local FindPreviousCaster = ClientCasters[tostring(Plr.UserId)]
        if not FindPreviousCaster then
            CreateCaster(tostring(Plr.UserId))
        end
    end)
end

-- // Check if a ball was caught by a player on the fielding team
local function CaughtByPlayer(instance)
    local Player = false
    if instance.Parent then
        if instance.Parent:FindFirstChildOfClass('Humanoid') then
            if PlayerService:GetPlayerFromCharacter(instance.Parent) then
                return PlayerService:GetPlayerFromCharacter(instance.Parent)
            end
        end
        if instance:FindFirstAncestorOfClass('Model') then
            local Parent = instance:FindFirstAncestorOfClass('Model')
            if Parent:FindFirstChildOfClass('Humanoid') then
                if PlayerService:GetPlayerFromCharacter(Parent) then
                    return PlayerService:GetPlayerFromCharacter(Parent)
                end
            end
        end
    end
    return nil
end

-- // Create ignore list for cast raycast params
local function CreateIgnoreList(Receive)
    local IgnoreList = {BallsFolder}

    for _,v in next, Receive do
        table.insert(IgnoreList, v)
    end

    for _,team in next, game.Teams:GetTeams() do
        if not team:GetAttribute('Fielding') then
            for _,plr in next, PlayerService:GetPlayers() do
                if plr.Team == team then
                    if plr.Character then
                        table.insert(IgnoreList, plr.Character)
                    end
                end
            end
            break
        end
    end
    return IgnoreList
end

-- // Find the caster with the ID given
local function GetCaster(CasterID)
    if RunService:IsServer() then
        for key,cast in next, ServerCasters do
            if tostring(key) == tostring(CasterID) then
                return ServerCasters[tostring(key)]
            end
        end
    elseif RunService:IsClient() then
        for key,cast in next, ClientCasters do
            if tostring(key) == tostring(CasterID) then
                return ClientCasters[tostring(key)]
            end
        end
    end
    return nil
end

-- // Castng the ball
function module:CastTheGyattDamnBall(...)
    local Args = {...}
    local StartPosition = Args[1]
    local EndPosition = Args[2]
    local Speed = Args[3]
    local Drop = Args[4]
    local Playa = Args[5]
    local DeleteOnTouch = Args[6]
    local PitchingBall = Args[7]
    local CasterName = Args[8]

    if not GetCaster(CasterName) then print('couldn\'t find caster.') return end

    local RayHitConnection = nil
    local LengthChangedConnection = nil

    if RunService:IsServer() then
        BallEvent:FireAllClients(...)
    end

    -- // Fastcast Things
    local CasterInfo = GetCaster(CasterName)
    local Caster = CasterInfo[1]
    local Behavior = FastCast.newBehavior()
    local Direction = (EndPosition - StartPosition).Unit
    local raycastParams = RaycastParams.new()

    raycastParams.FilterType = Enum.RaycastFilterType.Exclude

    local InitialBall
    if not PitchingBall then
        local Send = {Playa, game.Workspace.Carnavas.Batting}
        raycastParams.FilterDescendantsInstances = CreateIgnoreList(Send)
        InitialBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
    else
        local Send = {Playa}
        Behavior.CanPierceFunction = StrikeZone_PierceFunction
        raycastParams.FilterDescendantsInstances = CreateIgnoreList(Send)
        InitialBall = ReplicatedStorage.Carnavas.Balls.PitchedBall:Clone()
    end

    Behavior.RaycastParams = raycastParams
    Behavior.Acceleration = Drop
    Behavior.MaxDistance = math.huge

    CasterInfo[1]:Fire(StartPosition, Direction, Speed, Behavior)

    if RunService:IsServer() then
        if ReplicatedStorage.Carnavas.ClientVisuals.Value == true then
            InitialBall.Parent = game.ServerStorage
        else
            InitialBall.Parent = BallsFolder
            InitialBall.Position = StartPosition
            LengthChangedConnection = CasterInfo[1].LengthChanged:Connect(function(Cast, LastPoint, Dir, Length)
                local HalfSize = InitialBall.Size.Z / 2
                local Offset = CFrame.new(0, 0, -(Length - HalfSize))
                InitialBall.CFrame = CFrame.lookAt(LastPoint, LastPoint+Dir):ToWorldSpace(Offset)
            end)
        end
    elseif RunService:IsClient() then
        InitialBall.Parent = BallsFolder
        InitialBall.Position = StartPosition
        LengthChangedConnection = CasterInfo[1].LengthChanged:Connect(function(Cast, LastPoint, Dir, Length)
            local HalfSize = InitialBall.Size.Z / 2
            local Offset = CFrame.new(0, 0, -(Length - HalfSize))
            InitialBall.CFrame = CFrame.lookAt(LastPoint, LastPoint+Dir):ToWorldSpace(Offset)
        end)
    end

    RayHitConnection = CasterInfo[1].RayHit:Connect(function(Cast, Results)
        CasterInfo[2]:Fire()

        if RunService:IsServer() then

            if not DeleteOnTouch then
                if Results then
                    local Plr = CaughtByPlayer(Results.Instance)
                    if not Plr then
                        local IsActive = true
                        local Connection
                        local NewBall = ReplicatedStorage.Carnavas.Balls.Baseball:Clone()
                        local NewHitbox = Instance.new('Part')
                        -- local Weld = Instance.new('Weld', NewHitbox)
                        local a = Instance.new('Attachment')
                        local ap = Instance.new('AlignPosition')
                        InitialBall:Destroy()

                        NewBall.Position = Results.Position
                        NewBall.Massless = true
                        NewBall.Anchored = false
                        NewBall.CanCollide = true
                        NewBall.CanQuery = true
                        NewBall.CanTouch = false
                        NewBall.Parent = BallsFolder

                        local Distance = (StartPosition - Results.Position).Magnitude

                        if Distance >= 220 then
                            NewBall:ApplyImpulse((Vector3.new(Direction.X, math.rad(15), Direction.Z)) * (Speed / 25))
                        else
                            NewBall:ApplyImpulse((Vector3.new(Direction.X, math.rad(15), Direction.Z)) * (Speed / 15))
                        end


                        NewHitbox.Size = Vector3.new(_G.Configs.BallHitboxSize, _G.Configs.BallHitboxSize, _G.Configs.BallHitboxSize)
                        NewHitbox.Transparency = 1
                        NewHitbox.Massless = true
                        NewHitbox.Position = Results.Position
                        NewHitbox.Anchored = false
                        NewHitbox.CanCollide = false
                        NewHitbox.CanQuery = false
                        NewHitbox.CanTouch = true

                        a.Parent = NewHitbox
                        ap.Parent = NewHitbox
                        ap.Attachment0 = a
                        ap.Attachment1 = NewBall.Attachment0

                        ap.MaxForce = math.huge
                        ap.Responsiveness = math.huge

                        NewHitbox.Parent = NewBall

                        task.spawn(function()
                            if InitialBall.Name == 'HitBall' then
                                if _G.Configs.UseRawPower then
                                    task.wait(Speed / 100)
                                else
                                    local actualSpeed = Speed * _G.Configs.DividePowerBy
                                    task.wait(actualSpeed / 100)
                                end
                            else
                                task.wait(Speed / 140)
                            end
                            task.delay(4, function()
                                IsActive = false
                            end)
                            repeat
                                NewBall.AssemblyLinearVelocity = 0.6 * NewBall.AssemblyLinearVelocity
                                NewBall.AssemblyAngularVelocity = 0.6 * NewBall.AssemblyAngularVelocity

                                task.wait(.3)
                            until not IsActive
                        end)

                        if not NewBall or not NewBall.Parent then return end

                        local KeepListening = true
                        Connection = NewHitbox.Touched:Connect(function(BasePart)
                            local Plr_1 = CaughtByPlayer(BasePart)
                            if Plr_1 then
                                if Plr_1:GetAttribute('Fielding') == false and Plr_1.Team:GetAttribute('Fielding') == true and Plr_1 ~= Playa then
                                    local Character = Plr_1.Character
                                    if not Character then return end
                                    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
                                    if Humanoid.Health > 0 then
                                        KeepListening = false
                                        NewBall:Destroy()
                                        ReplicatedStorage.Carnavas.Events.FieldingEvent:FireClient(Plr_1, 'BeginFielding')
                                        if Character:FindFirstChild('FakeBall', true) then
                                            local FakeBall = Character:FindFirstChild('FakeBall', true)
                                            local GloveFielded_Sound = GloveSounds.Fielded:Clone()
                                            FakeBall.BallHighlight.Enabled = true
                                            FakeBall.Transparency = 0
                                            GloveFielded_Sound.Parent = FakeBall
                                            GloveFielded_Sound:Play()
                                            DebrisService:AddItem(GloveFielded_Sound, GloveFielded_Sound.TimeLength)
                                        end
                                        Plr_1:SetAttribute('Fielding', true)
                                        Connection:Disconnect()
                                    end
                                end
                            end
                        end)

                        if _G.Configs.AutoDeleteBalls then
                            DebrisService:AddItem(NewBall, _G.Configs.DeleteBallsDuration)
                        end
                    else
                        if Plr:GetAttribute('Fielding') == false and Plr.Team:GetAttribute('Fielding') == true then
                            local Character = Plr.Character
                            if not Character then return end
                            local Humanoid = Character:FindFirstChildOfClass('Humanoid')
                            if Humanoid.Health > 0 then
                                local CaughtBillboard = ReplicatedStorage.Carnavas.Instances.CaughtBillboard:Clone()
                                InitialBall:Destroy()
                                ReplicatedStorage.Carnavas.Events.FieldingEvent:FireClient(Plr, 'BeginFielding')
                                if Character:FindFirstChild('FakeBall', true) then
                                    local FakeBall = Character:FindFirstChild('FakeBall', true)
                                    local GloveCaught_Sound = GloveSounds.Caught:Clone()
                                    FakeBall.BallHighlight.Enabled = true
                                    CaughtBillboard.Parent = FakeBall
                                    FakeBall.Transparency = 0
                                    GloveCaught_Sound.Parent = FakeBall
                                    GloveCaught_Sound:Play()
                                    DebrisService:AddItem(GloveCaught_Sound, GloveCaught_Sound.TimeLength)
                                    DebrisService:AddItem(CaughtBillboard, 5)
                                end
                                Plr:SetAttribute('Fielding', true)
                            end
                        end
                    end
                end
            else
                InitialBall:Destroy()
            end
        elseif RunService:IsClient() then
            InitialBall:Destroy()
        end
    end)

    CasterInfo[2].Event:Once(function()
        if RunService:IsClient() or ReplicatedStorage.Carnavas.ClientVisuals.Value == false then LengthChangedConnection:Disconnect() end
        RayHitConnection:Disconnect()
    end)

    return InitialBall
end

-- // On a hit ball, find out where the ball will land
if RunService:IsServer() then
    function module:GetCastHitPosition(...)
        local Args = {...}
        local StartPosition = Args[1]
        local EndPosition = Args[2]
        local Speed = Args[3]
        local Drop = Args[4]
        local Playa = Args[5]
        local CasterIDCheck = GetCaster(Args[6])

        if not CasterIDCheck then return end

        local CasterToReference = CasterIDCheck[1]
        local BindableEvent = CasterIDCheck[2]
        local OnLengthChanged = nil
        local RayHitConnection
        local Southernplayalisticadillacmuzik = nil
        local HitPosition = nil
        local NewLandingMarker = nil

        -- // Fastcast Things
        local Behavior = FastCast.newBehavior()
        local Direction = (EndPosition - StartPosition).Unit
        local raycastParams = RaycastParams.new()

        raycastParams.FilterType = Enum.RaycastFilterType.Exclude

        local Send = {Playa, game.Workspace.Carnavas.Batting}
        raycastParams.FilterDescendantsInstances = CreateIgnoreList(Send)

        Behavior.RaycastParams = raycastParams
        Behavior.Acceleration = Drop * 100
        Behavior.MaxDistance = math.huge

        HitBall_MarkerCaster:Fire(StartPosition, Direction, Speed * 10, Behavior)

        -- // Create ball landing marker
        Southernplayalisticadillacmuzik = HitBall_MarkerCaster.RayHit:Connect(function(_, Results)
            if Results then
                local DistanceFromHitPosition = (StartPosition - Results.Position).Magnitude
                local FinalSize = math.clamp(ReplicatedStorage.Carnavas.Balls.Baseball.Size.X + 4 * (DistanceFromHitPosition / 25), 0, 28)
                NewLandingMarker = ReplicatedStorage.Carnavas.Instances.LandingSpot:Clone()
                NewLandingMarker.Parent = BallsFolder
                NewLandingMarker.Position = Results.Position + Vector3.new(0, NewLandingMarker.Size.X / 2, 0)

                HitPosition = Results.Position
            end
        end)

        task.spawn(function()
            HitBall_MarkerCaster.RayHit:Wait()
            Southernplayalisticadillacmuzik:Disconnect()
        end)

        BindableEvent.Event:Once(function()
            if NewLandingMarker then
                NewLandingMarker:Destroy()
            end
        end)

        -- // Resize landing marker on length changed
        OnLengthChanged = CasterToReference.LengthChanged:Connect(function(Cast, LastPoint, Dir, Length)
            if HitPosition and NewLandingMarker then
                local DistanceFromHitPosition = (LastPoint - HitPosition).Magnitude
                local FinalSize = math.clamp(ReplicatedStorage.Carnavas.Balls.Baseball.Size.X + 4 * (DistanceFromHitPosition / 25), 10, 28)
                NewLandingMarker.Size = Vector3.new(.75, FinalSize, FinalSize)
            end
        end)

        task.spawn(function()
            CasterToReference.RayHit:Wait()
            OnLengthChanged:Disconnect()
            RayHitConnection:Disconnect()
        end)
    end
end

-- // Cast the ball on the client if client-side visuals is set to true
if RunService:IsClient() then
    BallEvent.OnClientEvent:Connect(function(...)
        if ReplicatedStorage.Carnavas.ClientVisuals.Value == true then
            module:CastTheGyattDamnBall(...)
        end
    end)
end

return module