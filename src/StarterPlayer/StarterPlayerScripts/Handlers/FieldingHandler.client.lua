-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')
local UserInputService = game:GetService('UserInputService')

-- // Variables \\ --
local LocalPlayer = PlayerService.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local FieldingEvent = ReplicatedStorage.Carnavas.Events.FieldingEvent
local FieldingAnimations = ReplicatedStorage.Carnavas.Animations.FieldingAnimations

local ThrowTrack = nil

local Connection

local function LoadThrowTrack(Character)
    local ThrowAnimation = FieldingAnimations.Throw_Close
    local Humanoid = Character:FindFirstChildOfClass('Humanoid')
    ThrowTrack = Humanoid.Animator:LoadAnimation(ThrowAnimation)
end

LocalPlayer.CharacterAdded:Connect(function(Character)
    repeat task.wait() until LocalPlayer.Character ~= nil
    repeat task.wait() until Character:FindFirstChildOfClass('Humanoid')
    LoadThrowTrack(Character)
end)

FieldingEvent.OnClientEvent:Connect(function(Function, ...)
    local Args = {...}
    if Function == 'BeginFielding' then
        local TouchScreen = UserInputService.TouchEnabled
        
        Mouse.TargetFilter = game.Workspace.Carnavas.Batting

        if not TouchScreen then
            Connection = Mouse.Button1Up:Connect(function()
                if Mouse.Target ~= nil then
                    local Hit = Mouse.Hit
                    local Character = LocalPlayer.Character
                    if Character then
                        local FakeBall = Character:FindFirstChild('FakeBall', true)
                        if FakeBall then
                            if ThrowTrack then 
                                ThrowTrack:Play(.3) 
                            else
                                LoadThrowTrack(Character)
                                ThrowTrack:Play(.3)
                            end
                            FieldingEvent:FireServer('ThrowBall', Hit, FakeBall, .18)
                            Mouse.TargetFilter = nil
                            Connection:Disconnect()
                            Connection = nil
                        end
                    end
                end
            end)
        else
            Connection = UserInputService.TouchTap:Connect(function(_, GameProcessed)
                if not GameProcessed then
                    if Mouse.Target ~= nil then
                        local Hit = Mouse.Hit
                        local Character = LocalPlayer.Character
                        if Character then
                            local FakeBall = Character:FindFirstChild('FakeBall', true)
                            if FakeBall then
                                if ThrowTrack then 
                                    ThrowTrack:Play(.3) 
                                else
                                    LoadThrowTrack(Character)
                                    ThrowTrack:Play(.3)
                                end
                                FieldingEvent:FireServer('ThrowBall', Hit, FakeBall, .18)
                                Mouse.TargetFilter = nil
                                Connection:Disconnect()
                                Connection = nil
                            end
                        end
                    end
                end
            end)
        end
    end
end)