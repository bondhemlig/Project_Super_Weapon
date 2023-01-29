-- on Super Weapon Hit Controller
-- Username
-- January 29, 2023

local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local onSuperWeaponHitController = {}


function onSuperWeaponHitController:Start()
    local SuperWeaponService = self.Services.GunnerService
    SuperWeaponService.OnHit:Connect(function(targetModel)
        --[[
            Play Sounds
            Camera manipulation
            Particle Effects
            Color tweening?
            Set material?
        ]]
        for i, v in ipairs(targetModel:GetDescendants()) do
            if v.Name == "Beskar" then
                Debris:AddItem(v, 60)
            elseif v:IsA("BasePart") then
                Debris:AddItem(v, math.random(2, 5))
                TweenService:Create(v, TweenInfo.new(
                    math.random(1, 2),
                    Enum.EasingStyle.Exponential,
                    Enum.EasingDirection.In
                ), {
                    Color = Color3.fromRGB(255, 153, 0)
                })
                task.wait(0.8)
                v.Material = Enum.Material.CrackedLava
            end
        end
    end)
end


function onSuperWeaponHitController:Init()
	
end


return onSuperWeaponHitController