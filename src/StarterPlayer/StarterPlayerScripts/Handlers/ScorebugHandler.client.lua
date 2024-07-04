-- // Services \\ --
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local PlayerService = game:GetService('Players')

-- // Variables \\ --
local LocalPlayer = PlayerService.LocalPlayer
repeat task.wait() until LocalPlayer:FindFirstChild('PlayerGui')
--local Scorebug = LocalPlayer.PlayerGui.Scorebug
local Scorebug = LocalPlayer.PlayerGui:FindFirstChild('Scorebug')

if not Scorebug then return end

-- // Scorebug Variables \\ --
local Main = Scorebug.Main
local HomeTeam = Main.HomeTeam
local AwayTeam = Main.AwayTeam
local Misc = Main.Misc

local OutsFrame = Misc.Outs

-- // Game Values \\ --
local GameValues = ReplicatedStorage.Carnavas:WaitForChild('GameInfo')
local HomeValues = GameValues.Home
local AwayValues = GameValues.Away
local MiscValues = GameValues.Misc

local OutsValue = MiscValues.Outs

-- // Functions
function UpdateInning()
    local InningInfo = string.split(MiscValues.Inning.Value, ':')

    if InningInfo[1] == 'Top' then
        Misc.Inning.Top.ImageTransparency = 0
        Misc.Inning.Bottom.ImageTransparency = .75
    else
        Misc.Inning.Top.ImageTransparency = .75
        Misc.Inning.Bottom.ImageTransparency = 0
    end
    Misc.Inning.Number.Text = InningInfo[2]
end

-- // Startup Things \\ --
function OnStartup()
    local InningInfo = string.split(MiscValues.Inning.Value, ':')
    
    HomeTeam.TeamName.Text = HomeValues.TeamName.Value
    AwayTeam.TeamName.Text = AwayValues.TeamName.Value
    
    for _,v in next, Misc.Bases:GetChildren() do
        if v:IsA('ImageLabel') then
            local BaseValue = MiscValues:FindFirstChild(v.Name .. 'Base')
            if BaseValue then
                if BaseValue.Value == false then
                    v.ImageTransparency = .75
                else
                    v.ImageTransparency = 0
                end
            end
        end
    end
    
    -- // Outs
    if OutsValue.Value == 0 then
        for _,v in next, OutsFrame:GetChildren() do
            if v:IsA('Frame') then
                v.BackgroundTransparency = .75
            end
        end
    else
        for _,v in next, OutsFrame:GetChildren() do
            if v:IsA('Frame') then
                v.BackgroundTransparency = .75
            end
        end

        for i = 1, OutsValue.Value, 1 do
            local OutCircle: Frame = OutsFrame:FindFirstChild('Out' .. i)
            if OutCircle then
                OutCircle.BackgroundTransparency = 0
            end
        end
    end
    
    Misc.CountText.Text = `{ReplicatedStorage.Carnavas.GameInfo.Count.Balls.Value}-{ReplicatedStorage.Carnavas.GameInfo.Count.Strikes.Value}`
    
    UpdateInning()
end

OnStartup()

Main.BroadcastLogo.ImageButton.MouseButton1Click:Connect(function()
    if LocalPlayer.Team.Name == 'Umpires' then
        if Scorebug.Umpire.Visible then
            Scorebug.Umpire.Visible = false
        else
            Scorebug.Umpire.Visible = true
        end
    end
end)

OutsValue:GetPropertyChangedSignal('Value'):Connect(function()
    if OutsValue.Value == 0 then
        for _,v in next, OutsFrame:GetChildren() do
            if v:IsA('Frame') then
                v.BackgroundTransparency = .75
            end
        end
    else
        for _,v in next, OutsFrame:GetChildren() do
            if v:IsA('Frame') then
                v.BackgroundTransparency = .75
            end
        end
        
        for i = 1, OutsValue.Value, 1 do
            local OutCircle: Frame = OutsFrame:FindFirstChild('Out' .. i)
            if OutCircle then
                OutCircle.BackgroundTransparency = 0
            end
        end
    end
end)

MiscValues.Inning:GetPropertyChangedSignal('Value'):Connect(UpdateInning)

HomeValues.TeamName:GetPropertyChangedSignal('Value'):Connect(function()
    HomeTeam.TeamName.Text = HomeValues.TeamName.Value
end)

AwayValues.TeamName:GetPropertyChangedSignal('Value'):Connect(function()
    AwayTeam.TeamName.Text = AwayValues.TeamName.Value
end)

for _,v in next, Misc.Bases:GetChildren() do
    if v:IsA('ImageLabel') then
        local BaseValue = MiscValues:FindFirstChild(v.Name .. 'Base')
        if BaseValue then
            BaseValue:GetPropertyChangedSignal('Value'):Connect(function()
                if BaseValue.Value == false then
                    v.ImageTransparency = .75
                else
                    v.ImageTransparency = 0
                end
            end)
        end
    end
end

for _,v in next, GameValues.Count:GetChildren() do
    v:GetPropertyChangedSignal('Value'):Connect(function()
        Misc.CountText.Text = `{ReplicatedStorage.Carnavas.GameInfo.Count.Balls.Value}-{ReplicatedStorage.Carnavas.GameInfo.Count.Strikes.Value}`
    end)
end

-- // Scorebug setter and stuff
local Event = ReplicatedStorage.Carnavas.Events.ScorebugEvent
local UmpireFrame = Scorebug.Umpire
local UmpireMiscFrame = UmpireFrame.Misc

for _,v in next, UmpireMiscFrame.Inning:GetChildren() do
    if v:IsA('TextButton') then
        v.MouseButton1Click:Connect(function()
            Event:FireServer('InningNumber', v.Name)
        end)
    end
end

for _,v in next, UmpireMiscFrame.TopBotInning:GetChildren() do
    if v:IsA('TextButton') then
        v.MouseButton1Click:Connect(function()
            Event:FireServer('ToggleInningHalf', v.Name)
        end)
    end
end

for _,v in next, UmpireMiscFrame.Bases:GetChildren() do
    if v:IsA('ImageButton') then
        v.MouseButton1Click:Connect(function()
            Event:FireServer(v.Name .. 'Base')
        end)
    end
end

for _,v in next, UmpireMiscFrame.Strikes:GetChildren() do
    if v:IsA('TextButton') then
        v.MouseButton1Click:Connect(function()
            Event:FireServer('Strikes', v.Name)
        end)
    end
end

for _,v in next, UmpireMiscFrame.Balls:GetChildren() do
    if v:IsA('TextButton') then
        v.MouseButton1Click:Connect(function()
            Event:FireServer('Balls', v.Name)
        end)
    end
end

for _,v in next, UmpireMiscFrame.Outs:GetChildren() do
    if v:IsA('TextButton') then
        v.MouseButton1Click:Connect(function()
            Event:FireServer('Outs', v.Name)
        end)
    end
end