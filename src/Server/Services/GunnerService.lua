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

local function FindTargets(GunnerSeat)
    --local complexRegions = require(ReplicatedStorage.Packages.ComplexRegions)
    --My hitbox part:
    --hitbox.Size = Vector3.new(1000,1000,1000)
    --hitbox.CFrame = script.Parent.CFrame * CFrame.new(Vector3.new(0,0,-700 ))
	--hitbox.Orientation = Vector3.new(0, -45, 0)
   
    local boxSize = Vector3.new(1000, 1000, 1000)
    local box = GunnerSeat.CFrame * CFrame.new(Vector3.new(0, 0, -710)) * CFrame.Angles(0, math.rad(-45), 0)
  
    --game.Workspace:FindPartsInRegion3WithWhiteList() 
    --local region = Region3.new(Vector3.new(spawner.Position.X - spawner.Size.X/2, spawner.Position.Y + spawner.Size.Y/2, spawner.Position.Z - spawner.Size.Z/2),
    --Vector3.new(spawner.Position.X + spawner.Size.X/2, spawner.Position.Y + 4, spawner.Position.Z + spawner.Size.Z/2))
    --local regionZone = Region3.new(Vector3.new(box.Position.X - 500, box.Position.Y + 500, box.Position.Z - 500), Vector3.new(box.Position.X + 500, box.Position.Y + 500, box.Position.Z + 500))
    local parameters = OverlapParams.new()
    parameters.MaxParts = 0
    parameters.CollisionGroup = "Default"
    parameters.FilterType = Enum.RaycastFilterType.Whitelist
    parameters.FilterDescendantsInstances = findCharacters()
    local objectsInSpace = game:GetService("Workspace"):GetPartBoundsInBox(box,boxSize,parameters)
    --local objectsInPart = game:GetService("Workspace"):GetPartsInPart(test, parameters)
    --local objectsInSphere = game:GetService("Workspace"):GetPartBoundsInRadius(box.Position, boxSize.Z, parameters)
    --print("Objects in sphere", objectsInSphere)
    print("Baseparts in box:", objectsInSpace)
    --print("Objects in test part", objectsInPart)


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


function SuperWeaponService:Start()
    print("Start")
    self:ConnectClientEvent("Fire", function(player, seat, power)
        print("GO!")
        local targetedBaseParts = FindTargets(seat)

        local start = seat:FindFirstChildOfClass("Attachment")
        for i, basePart in ipairs(targetedBaseParts) do
            --no targetting system right now?
            --local thread = coroutine.create(function()
            if basePart.Name == "Beskar" then
                Debris:AddItem(basePart, 60)
                basePart.Anchored = false
            elseif basePart.Name == "HumanoidRootPart" then
                self:FireClient("GuiTarget", player, basePart)
                local beam = createBeam(start, basePart)
                local wee = Instance.new("VectorForce")
                wee.Force = Vector3.new(0, math.huge, 0)
                wee.Parent = basePart
                Debris:AddItem(wee, 2)
                --run the rest on the client sides.
                self:FireAllClients("OnHit", basePart.Parent)
                print("ONHIT!!!!")
            else
                Debris:AddItem(basePart, math.random(3, 5))
            end
           --end)
            --coroutine.resume(thread)
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