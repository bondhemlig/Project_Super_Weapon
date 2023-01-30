local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local SuperWeaponService = {
    Name = "SuperWeaponService",
    Client = {}
}

local GunClass = require(script.Parent.AtStGunClass)
local GunnerSeat = {}
GunnerSeat.__index = GunnerSeat
setmetatable(GunnerSeat, GunClass)

local function findCharacters()
    local characters, i = {}, 0
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") then
            characters[i] = v.Parent
            i += 1
        end
    end
    return characters
end

local function FindTargets(startCFrame)
    local boxSize = Vector3.new(1000, 1000, 1000)
    local box = startCFrame * CFrame.new(Vector3.new(0, 0, -710)) * CFrame.Angles(0, math.rad(-45), 0)
    local parameters = OverlapParams.new()
    parameters.MaxParts = 0
    parameters.CollisionGroup = "Default"
    parameters.FilterType = Enum.RaycastFilterType.Whitelist
    parameters.FilterDescendantsInstances = findCharacters()
    local objectsInSpace = game:GetService("Workspace"):GetPartBoundsInBox(box,boxSize,parameters)
    return objectsInSpace
end

local function createBeam(start, humanoidRootPart)
    local beam = Instance.new("Beam")
    beam.Attachment0 = start
    beam.Attachment1 = humanoidRootPart and humanoidRootPart:FindFirstChild("RootRigAttachment")
    Debris:AddItem(beam, 5)
    return beam
end

function GunnerSeat.new(seat)
    local newGunnerSeat = GunClass.new(seat)
    setmetatable(newGunnerSeat, GunnerSeat)
    
end

local function createParticleEmitter()
    local emitter = Instance.new("ParticleEmitter")
    -- Number of particles = Rate * Lifetime
    emitter.Rate = 5 -- Particles per second
    emitter.Lifetime = NumberRange.new(1, 1) -- How long the particles should be alive (min, max)
    emitter.Enabled = true

    -- Visual properties
    emitter.Texture = "rbxassetid://1266170131" -- A transparent image of a white ring
    -- For Color, build a ColorSequence using ColorSequenceKeypoint
    local colorKeypoints = {
        -- API: ColorSequenceKeypoint.new(time, color)
        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)), -- At t=0, White
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(17, 0, 255)), -- At t=.5, Orange
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 110, 255)), -- At t=1, Red
    }
    emitter.Color = ColorSequence.new(colorKeypoints)
    local numberKeypoints = {
        -- API: NumberSequenceKeypoint.new(time, size, envelop)
        NumberSequenceKeypoint.new(0, 1), -- At t=0, fully transparent
        NumberSequenceKeypoint.new(0.1, 0), -- At t=.1, fully opaque
        NumberSequenceKeypoint.new(0.5, 0.25), -- At t=.5, mostly opaque
        NumberSequenceKeypoint.new(1, 1), -- At t=1, fully transparent
    }
    emitter.Transparency = NumberSequence.new(numberKeypoints)
    emitter.LightEmission = 1 -- When particles overlap, multiply their color to be brighter
    emitter.LightInfluence = 0 -- Don't be affected by world lighting

    -- Speed properties
    emitter.EmissionDirection = Enum.NormalId.Front -- Emit forwards
    emitter.Speed = NumberRange.new(0, 0) -- Speed of zero
    emitter.Drag = 0 -- Apply no drag to particle motion
    emitter.VelocitySpread = NumberRange.new(0, 0)
    emitter.VelocityInheritance = 0 -- Don't inherit parent velocity
    emitter.Acceleration = Vector3.new(0, 0, 0)
    emitter.LockedToPart = false -- Don't lock the particles to the parent
    emitter.SpreadAngle = Vector2.new(0, 0) -- No spread angle on either axis

    -- Simulation properties
    local numberKeypoints2 = {
        NumberSequenceKeypoint.new(0, 0), -- At t=0, size of 0
        NumberSequenceKeypoint.new(1, 10), -- At t=1, size of 10
    }
    emitter.Size = NumberSequence.new(numberKeypoints2)
    emitter.ZOffset = -1 -- Render slightly behind the actual position
    emitter.Rotation = NumberRange.new(0, 360) -- Start at random rotation
    emitter.RotSpeed = NumberRange.new(0) -- Do not rotate during simulation

    -- Create an attachment so particles emit from the exact same spot (concentric rings)
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 5, 0) -- Move the attachment upwards a little
    attachment.Parent = script.Parent
    emitter.Parent = attachment
    return attachment
end

local FastCast = require(ReplicatedStorage.Packages.FastcastRedux)

function SuperWeaponService:Start()
    self:ConnectClientEvent("Fire", function(player, seat, power)
        local targetedBaseParts = FindTargets(seat.CFrame)

        local rootParts, n = {}, 0
        for _, basePart in ipairs(targetedBaseParts) do
            if basePart.Name == "HumanoidRootPart" then
                local rayOrigin = seat.Position
                local rayDestination = basePart.Position
                local rayDirection = rayDestination - rayOrigin
                local params = RaycastParams.new()
                params.FilterType = Enum.RaycastFilterType.Blacklist
                params.FilterDescendantsInstances = {seat}
                params.IgnoreWater = false
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection)      
                if raycastResult.Result then
                    if raycastResult.Result == basePart or raycastResult.Result.Parent:FindFirstChild(basePart.Name) or raycastResult.Result.Parent.Parent:FindFirstChild(basePart.Name) then
                        rootParts[n] = basePart
                        n += 1
                    end
                end
            end
        end
        n = nil
        targetedBaseParts = nil

        local start = seat:FindFirstChildOfClass("Attachment")

        for i, rootPart in ipairs(rootParts) do
            local humanoid = rootPart.Parent:FindFirstChild("Humanoid")
            self:FireClient("GuiTarget", player, rootPart, humanoid)
            if humanoid then
                humanoid.WalkSpeed = 0
                humanoid.AutoRotate = false
            end

            local beam = createBeam(start, rootPart)
            beam.Parent = rootPart
            beam.Texture = ""

            --Create up force
            local wee = Instance.new("VectorForce")
            wee.Force = Vector3.new(0, math.huge, 0)
            wee.Parent = rootPart
            Debris:AddItem(wee, 3)
            local character = rootPart.Parent
            self:FireAllClients("OnHit", character, power)--Client sided effects.
            if power > 0.5 then
                
                for _, basePart in ipairs(character:GetDescendants()) do
                    if basePart:IsA("BasePart") then
                        if basePart.Name == "Beskar" then
                            basePart.CanCollide = true
                            basePart.Anchored = false
                            Debris:AddItem(basePart, 60)
                        else
                            basePart.Material = Enum.Material.CrackedLava
                            Debris:AddItem(basePart, math.random(3, 5))
                        end
                    elseif basePart:IsA("Hat") or basePart:IsA("Accessory") then
                        Debris:AddItem(basePart, math.random(2, 5))
                    end
                end
            else--stun
                local attachment = createParticleEmitter()
                attachment.Parent = seat
                Debris:AddItem(attachment, 5) --stun duration
                local connection 
                connection = attachment.Destroying:Connect(function()
                    if connection then
                        connection:Disconnect()
                        if humanoid then
                           humanoid.WalkSpeed = 16
                           humanoid.AutoRotate = true 
                        end
                    end
                end)
            end
        end
    end)


    function GunnerSeat.CuntinueOnSeated(player, seat, character, humanoid)
        print(player, SuperWeaponService)

        self:FireClient("Activate", player, seat)
        --:FireClient
    end
    
    function GunnerSeat.CuntinueOnDismount(player)
        self:FireClient("Deactivate", player)
    end
end


function SuperWeaponService:Init()
    self:RegisterClientEvent("Activate")
    self:RegisterClientEvent("Deactivate")
    self:RegisterClientEvent("Fire")
    self:RegisterClientEvent("GuiTarget")
    self:RegisterClientEvent("OnHit")
end

--setup:
local gunnerSeats = {}
local GunnerSeatAddedSignal = CollectionService:GetInstanceAddedSignal(GunClass.TAG_NAME)
local GunnerSeatRemovedSignal = CollectionService:GetInstanceRemovedSignal(GunClass.TAG_NAME)
local function onGunSeatAdded(gunSeat)
    print(gunSeat:IsA("VehicleSeat"))
	if gunSeat:IsA("VehicleSeat") or gunSeat:IsA("Seat") then
		gunnerSeats[gunSeat] = GunnerSeat.new(gunSeat)
	end
end

local function onGunSeatRemoved(gunSeat)
    if gunnerSeats[gunSeat] then
		gunnerSeats[gunSeat]:Cleanup()
		gunnerSeats[gunSeat] = nil
	end
end

-- Listen for existing tags, tag additions and tag removals for the GunClass tag
--load time
task.wait(1)
print(CollectionService:GetTagged(GunClass.TAG_NAME))
for _, inst in pairs(CollectionService:GetTagged(GunClass.TAG_NAME)) do
	onGunSeatAdded(inst)
end
GunnerSeatAddedSignal:Connect(onGunSeatAdded)
GunnerSeatRemovedSignal:Connect(onGunSeatRemoved)


return SuperWeaponService