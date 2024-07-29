-----------------------------------------------------------
--------------------- TYPE DEFINITION ---------------------
-----------------------------------------------------------

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local ShakeContainer = {}
local ShakeContainer_mt = {__index = ShakeContainer}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------

local ShakeInstanceModule = require(script.ShakeInstance)

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ DEBUGGING ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ CORE CODE ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------- EXPORTS -------------------------
-----------------------------------------------------------

function ShakeContainer.new()
	local Data = {
		Shakes = {},
	}

	setmetatable(Data, ShakeContainer_mt)

	return Data
end

function ShakeContainer:Update(deltaTime : number)
	local ShakePositionVector = Vector3.new()
	local ShakeRotationVector = Vector3.new()
	
	for Index, ShakeInstance in pairs(self.Shakes) do
		if ShakeInstance.IsDead then ShakeInstance:Destroy() table.remove(self.Shakes, Index) continue end
		
		ShakePositionVector += ShakeInstance:Update(deltaTime) * ShakeInstance.PositionInfluence
		ShakeRotationVector += ShakeInstance:Update(deltaTime) * ShakeInstance.RotationInfluence
	end
	
	return CFrame.new(ShakePositionVector) 
		* CFrame.Angles(0, math.rad(ShakeRotationVector.Y), 0)
		* CFrame.Angles(math.rad(ShakeRotationVector.X), 0, math.rad(ShakeRotationVector.Z))
end

function ShakeContainer:AddShake(Roughness : number, Magnitude : number, PositionInfluence : Vector3, RotationInfluence : Vector3, FadeInTime : number, FadeOutTime : number)
	local Shake = ShakeInstanceModule.new(Roughness, Magnitude, PositionInfluence, RotationInfluence, FadeInTime, FadeOutTime)
	
	table.insert(self.Shakes, Shake)
end


function ShakeContainer:Clear()
	for Index, ShakeInstance in pairs(self.Shakes) do
		ShakeInstance:Destroy()
	end
	
	table.clear(self.Shakes)
end

function ShakeContainer:Destroy()
	setmetatable({}, nil)
end

return ShakeContainer
