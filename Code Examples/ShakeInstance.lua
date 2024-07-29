-----------------------------------------------------------
--------------------- TYPE DEFINITION ---------------------
-----------------------------------------------------------

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local ShakeInstance = {}
local ShakeInstance_mt = {__index = ShakeInstance}

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

local random = Random.new()

-----------------------------------------------------------
------------------------- EXPORTS -------------------------
-----------------------------------------------------------

function ShakeInstance.new(Roughness, Magnitude, PositionInfluence, RotationInfluence, FadeInTime, FadeOutTime)
	local Data = {
		Roughness = Roughness,
		Magnitude = Magnitude,
		PositionInfluence = PositionInfluence,
		RotationInfluence = RotationInfluence,
		FadeInTime = FadeInTime,
		FadeOutTime = FadeOutTime,
		
		_Tick = Random.new():NextNumber(-100, 100),
		
		_RoughMod = 1,
		_MagnMod = 1,
		
		_CurrentFadeTime = 0,
		
		_Sustain = false,
		
		IsDead = false,
	}
	
	setmetatable(Data, ShakeInstance_mt)
	
	if FadeInTime > 0 then 
		Data._Sustain = true
	else
		Data._CurrentFadeTime = 1
	end
	
	return Data
end

function ShakeInstance:Update(deltaTime : number)
	local ShakeX = math.noise(self._Tick, 0) * 0.5
	local ShakeY = math.noise(0, self._Tick) * 0.5
	local ShakeZ = math.noise(self._Tick, self._Tick) * 0.5
	
	local ShakeVector = Vector3.new(ShakeX, ShakeY, ShakeZ)
	
	if self.FadeInTime > 0 and self._Sustain then
		if self._CurrentFadeTime < 1 then
			self._CurrentFadeTime += deltaTime / self.FadeInTime
		elseif self.FadeOutTime > 0 then
			self._Sustain = false
		end
	end
	
	if not self._Sustain then
		self._CurrentFadeTime -= deltaTime / self.FadeOutTime
		
		self._Tick += deltaTime * self.Roughness * self._RoughMod * self._CurrentFadeTime
	else
		self._Tick += deltaTime * self.Roughness * self._RoughMod
	end
	
	if self._CurrentFadeTime < 0 then self.IsDead = true end
	
	return ShakeVector * self.Magnitude * self._MagnMod * self._CurrentFadeTime
end

function ShakeInstance:Destroy()
	setmetatable({}, nil)
end

return ShakeInstance
