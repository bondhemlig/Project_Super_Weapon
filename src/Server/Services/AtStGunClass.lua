
local GunClass = {}
GunClass.__index = GunClass
GunClass.TAG_NAME = "AT-ST_Gunner_Seat"

function GunClass.new(gunSeat)
	-- Create a table which will act as our new gunSeat object.
	local self = {}
	-- Setting the metatable allows the table to access
	-- the SetOpen, OnTouch and Cleanup methods even if we did not
	-- add all of the functions ourself - this is because the
	-- __index metamethod is set in the GunClass metatable.
	setmetatable(self, GunClass)
	-- Keep track of some gunSeat properties of our own
	self.seat = gunSeat

    -- Initialize a childadded event to call a method of the gunSeat
	self.seatConn = self.seat:GetPropertyChangedSignal("Occupant"):Connect(function(...)
		self:OnSeated(...)
	end)
	-- Initialize the state of the gunSeat
	self:SetOpen(false)

	print("Initialized gunSeat: " .. gunSeat:GetFullName())
	return self
end
function GunClass:SetOpen(isOpen)
	if isOpen then
		self.seat.Transparency = 0
		self.seat.CanCollide = false
	else
		self.seat.Transparency = 0
		self.seat.CanCollide = true
	end
end

function GunClass.CuntinueOnSeated()

end

function GunClass.CuntinueOnDismount()

end

function GunClass:OnSeated()
    if self.seat.Occupant ~= nil then
		local humanoid = self.seat.Occupant
		local character = self.seat.Occupant.Parent
        print(character, "seated on", self.seat)
        print(humanoid)
		local player = game:GetService("Players"):GetPlayerFromCharacter(character)

        --prevent jumping?
		--Char["HumanoidRootPart"].Anchored = true -- Can also set their jump power if wanting, your preference

		if player then
			self.Occupant = player
			--Now I want other functions to cuntinue from here.
			self.CuntinueOnSeated(player, self.seat, humanoid, character)
		end
	elseif self.Occupant then
		print(self.Occupant, "dismount")
		self.CuntinueOnDismount(self.Occupant, self.seat)
		self.Occupant = nil
	end

	
	
end
function GunClass:Cleanup()
	self.seatConn:disconnect()
	self.seatConn = nil
end


return GunClass