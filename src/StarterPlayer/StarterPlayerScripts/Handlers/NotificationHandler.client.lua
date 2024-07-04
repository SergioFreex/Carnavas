-- // Services \\ --
local PlayerService = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local DebrisService = game:GetService('Debris')

-- // Variables \\ --
local NotificationEvent = ReplicatedStorage.Carnavas.Events.NotificationEvent
local NotificationsFrame = PlayerService.LocalPlayer.PlayerGui:WaitForChild('Carnavas', 10).Notifications

--[[
    Checkered Floor - Silversun Pickups

    Winded through monotone
    One foot on checkered floor
    Head hung, but still watching
    One dimlit figurine

    Conceal, pass it on
    Appeal, play along
    Please don't stop singing
    Cohorts are empty jars
    Conceal, pass it on
    Appeal, play along

    Meanwhile (meanwhile), another scene, yeah (scene)
    Tracking mud (tracking mud), while blood-letting
    (We've been so proud)

    Watch how our star behaves
    We'll all roll in our graves
    Sink with every word
    While all their backs were turned

    Meanwhile (meanwhile), our little gem, yeah (gem)
    Sleep with (sleep with), phsycopants
    (We've been so proud)
    But now and then (now and then), we're joining in
    (We've been so proud)
    Tracking mud (tracking mud), while blood letting
    (We've been so proud)

    (We've been so proud)
    (We've been so proud)
    (We've been so proud)

    Ooooh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh, Oh-oh-oh-oh-oooh
    Ooooh-oh-oh
]]


NotificationEvent.OnClientEvent:Connect(function(Title: string, Message: string)
    local NotificationTemplate = NotificationsFrame.NotificationTemplate:Clone()
    local Info = NotificationTemplate.Info
    NotificationTemplate.Parent = NotificationsFrame
    Info.Body.Text = Message
    Info.Title.Text = Title

    local TextBoundsY = Info.Body.TextBounds.Y
    Info.Body.Size = UDim2.new(1, 0, 0, TextBoundsY)
    
    local CombinedSizeY = Info.Body.Size.Y.Offset + Info.Title.Size.Y.Offset + (Info.UIListLayout.Padding.Offset * 2)
    NotificationTemplate.Size = UDim2.new(1, 0, 0, CombinedSizeY + 20)
    NotificationTemplate.Visible = true
    DebrisService:AddItem(NotificationTemplate, 8)
end)