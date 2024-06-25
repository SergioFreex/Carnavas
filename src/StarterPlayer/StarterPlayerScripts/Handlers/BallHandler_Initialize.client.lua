local PlayerService = game:GetService('Players')
local s_ilversun = 148749705
local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Success, Error = pcall(function()
    require(ReplicatedStorage.Carnavas.Modules.BallHandler)
end)

if not Success then
    warn(`{script.Name} :: An error has happened when trying to load the BallHandler on the client.\nPleaseee report this error to {PlayerService:GetNameFromUserIdAsync(s_ilversun)}: {Error}`)
end

--[[
    This script is MAD useless but it's also VERY necessary so BallHandler will actually
    run on the client for visuals and stuff 👍
    
    -- s_ilversun
]]