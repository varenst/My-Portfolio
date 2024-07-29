-----------------------------------------------------------
--------------------- TYPE DEFINITION ---------------------
-----------------------------------------------------------

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local Particle = {}
local Particle_mt = {__index = Particle}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ DEBUGGING ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ CORE CODE ------------------------
-----------------------------------------------------------

local function SumOfForces(Forces : {{Value : Vector3}})
	local SumOfForces = Vector3.new()
	
	for Index, Force in pairs(Forces) do
		Force:Update()
			
		SumOfForces += Force.Value
	end
	
	return SumOfForces
end

-----------------------------------------------------------
------------------------- EXPORTS -------------------------
-----------------------------------------------------------

function Particle.new(Object : BasePart)
	local Data = {
		Object = Object,
		LastPosition = Object.Position,
		Velocity = Object.LinearVelocity :: LinearVelocity,
		Acceleration = Vector3.new(0, 0, 0),
		Forces = {},
		LimitVelocity = 1000,
	}
	
	setmetatable(Data,Particle_mt)
	
	return Data
end

function Particle:AddForces(...)
	local AddedForces = {...}
	
	for Index, Force in pairs(AddedForces) do
		table.insert(self.Forces, Force)
	end
	
	self.Acceleration = SumOfForces(self.Forces)
end

function Particle:ApplyImpulse(ImpulseVector : Vector3)
	self.Velocity.VectorVelocity += ImpulseVector
end

function Particle:OnUpdate(deltaTime : number)
	self.LastPosition = self.Object.Position
	
	self.Velocity.VectorVelocity += self.Acceleration * deltaTime

	local VelocityXZ = Vector3.new(self.Velocity.VectorVelocity.X, 0, self.Velocity.VectorVelocity.Z)
	local VelocityY = Vector3.new(0, self.Velocity.VectorVelocity.Y, 0)
	
	local VelocityXZMagnitude = VelocityXZ.Magnitude
	
	if VelocityXZMagnitude > self.LimitVelocity then self.Velocity.VectorVelocity = VelocityXZ.Unit * self.LimitVelocity + VelocityY end
	
	--self.Object.Position += self.Velocity.VectorVelocity * deltaTime
	
	self.Acceleration = SumOfForces(self.Forces)
end

return Particle
