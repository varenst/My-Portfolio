-----------------------------------------------------------
--------------------- TYPE DEFINITION ---------------------
-----------------------------------------------------------

-----------------------------------------------------------
-------------------- MODULE DEFINITION --------------------
-----------------------------------------------------------

local CharacterController = {}
CharacterController.CurrentRealBloxBlox = nil :: BasePart
CharacterController.CurrentFakeBloxBlox = nil :: BasePart

CharacterController.IsMovingOnCooldown = false
CharacterController.IsStanding = true
CharacterController.IsCharacterInAir = false

CharacterController.CanUpdateIsCharacterInAirState = true

CharacterController.BloxBloxCharacterParams = RaycastParams.new()
CharacterController.BloxBloxCharacterParams.FilterType = Enum.RaycastFilterType.Exclude

CharacterController.Settings = {
	CooldownTime = 0.2,
	
	MoveTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad),
}

CharacterController.ControlMap = {
	[Enum.KeyCode.W] = {
		MoveVector = Vector3.new(0, 0, 4),
		StateChangedMoveVector = Vector3.new(0, 0, 6),
		MoveRotation = CFrame.Angles(math.rad(90), 0, 0),
	},
	[Enum.KeyCode.S] = {
		MoveVector = Vector3.new(0, 0, -4),
		StateChangedMoveVector = Vector3.new(0, 0, -6),
		MoveRotation = CFrame.Angles(math.rad(-90), 0, 0),
	},
	[Enum.KeyCode.A] = {
		MoveVector = Vector3.new(4, 0, 0),
		StateChangedMoveVector = Vector3.new(6, 0, 0),
		MoveRotation = CFrame.Angles(0, 0, math.rad(-90)),
	},
	[Enum.KeyCode.D] = {
		MoveVector = Vector3.new(-4, 0, 0),
		StateChangedMoveVector = Vector3.new(-6, 0, 0),
		MoveRotation = CFrame.Angles(0, 0, math.rad(90)),
	},
}

-----------------------------------------------------------
----------------------- STATIC DATA -----------------------
-----------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Models = ReplicatedStorage.Models

local FakeBloxBlox = Models.FakeBloxBlox
local RealBloxBlox = Models.BloxBlox

local LastGoalRotationCFrame = RealBloxBlox.CFrame

local LastHitCFrame = nil
local LastHit = nil

-----------------------------------------------------------
------------------------ UTILITIES ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ DEBUGGING ------------------------
-----------------------------------------------------------

-----------------------------------------------------------
------------------------ CORE CODE ------------------------
-----------------------------------------------------------

local function Snap(Position : Vector3, SnapAmount : number)
	local X = math.floor((Position.X + (SnapAmount / 2)) / SnapAmount) * SnapAmount
	local Z = math.floor((Position.Y + (SnapAmount / 2)) / SnapAmount) * SnapAmount

	return math.round(X * 1000) / 1000, math.round( Z * 1000) / 1000
end

local function IsMovedCharacterStanding(CharacterFinalOrientation : CFrame)
	if CharacterController.IsStanding or LastGoalRotationCFrame.UpVector:Dot(CharacterFinalOrientation.UpVector) > 0.9 then
		return false
	else
		return true
	end
end

local function SnapFakeCharacter()
	local BloxBloxPosition = Vector2.new(CharacterController.CurrentRealBloxBlox.Position.X,CharacterController.CurrentRealBloxBlox.Position.Z)
	local FakeBloxBloxPosition = Vector2.new(CharacterController.CurrentFakeBloxBlox.Position.X, CharacterController.CurrentFakeBloxBlox.Position.Z)

	local Direction = BloxBloxPosition - FakeBloxBloxPosition
	local Distance = Direction.Magnitude

	if Distance > 4 then	
		local X, Z = Snap(BloxBloxPosition, 2)

		CharacterController.CurrentFakeBloxBlox.Position = Vector3.new(X, CharacterController.CurrentFakeBloxBlox.Position.Y , Z)
	end
end

local function UpdateCharacterInTheAirState()
	if not CharacterController.CanUpdateIsCharacterInAirState then return end
	
	local BloxBloxSize = CharacterController.CurrentRealBloxBlox.Size
	local BloxBloxWorldPosition = CharacterController.CurrentRealBloxBlox.Position

	local Edge1 = Vector3.new(BloxBloxSize.X/2 - 0.5, 0, 0)
	local Edge2 = Vector3.new(-BloxBloxSize.X/2 + 0.5, 0, 0)
	local Edge3 = Vector3.new(0, 0, BloxBloxSize.Z/2 - 0.5)
	local Edge4 = Vector3.new(0, 0, -BloxBloxSize.Z/2 + 0.5)

	local Results1 = workspace:Raycast(BloxBloxWorldPosition + Edge1, Vector3.new(0,-1,0) * 5.5, CharacterController.BloxBloxCharacterParams)
	local Results2 = workspace:Raycast(BloxBloxWorldPosition + Edge2, Vector3.new(0,-1,0) * 5.5, CharacterController.BloxBloxCharacterParams)
	local Results3 = workspace:Raycast(BloxBloxWorldPosition + Edge3, Vector3.new(0,-1,0) * 5.5, CharacterController.BloxBloxCharacterParams)
	local Results4 = workspace:Raycast(BloxBloxWorldPosition + Edge4, Vector3.new(0,-1,0) * 5.5, CharacterController.BloxBloxCharacterParams)

	local IsOnGround = (Results1 and Results2 and Results3 and Results4)

	if not IsOnGround and not CharacterController.IsCharacterInAir then
		CharacterController.IsCharacterInAir = true

		CharacterController.CurrentRealBloxBlox.AlignOrientation.Enabled = false
		CharacterController.CurrentRealBloxBlox.AlignPosition.Enabled = false
	elseif IsOnGround and CharacterController.IsCharacterInAir then
		CharacterController.IsCharacterInAir = false

		CharacterController.CurrentRealBloxBlox.AlignOrientation.Enabled = true
		CharacterController.CurrentRealBloxBlox.AlignPosition.Enabled = true
	end
end

local function UpdateCharacterMoveWithPlatforms()
	local RayCast = Ray.new(CharacterController.CurrentRealBloxBlox.Position + Vector3.new(0,2,0), Vector3.new(0,-7.5,0))

	local Hit, Position, Normal, Material = workspace:FindPartOnRay(RayCast, CharacterController.CurrentRealBloxBlox)

	if not Hit then LastHitCFrame = nil return end
	
	if LastHitCFrame == nil or LastHit ~= Hit then 
		LastHitCFrame = Hit.CFrame 
	end
	
	local CurrentHitCFrame = Hit.CFrame
	
	local RelativeCFrame = CurrentHitCFrame * LastHitCFrame:inverse()
	
	LastHitCFrame = CurrentHitCFrame
	LastHit = Hit
	
	CharacterController.CurrentFakeBloxBlox.CFrame = RelativeCFrame * CharacterController.CurrentFakeBloxBlox.CFrame
	CharacterController.CurrentRealBloxBlox.CFrame = RelativeCFrame * CharacterController.CurrentRealBloxBlox.CFrame
end
	
-----------------------------------------------------------
------------------------- EXPORTS -------------------------
-----------------------------------------------------------

function CharacterController:Spawn(SpawnPosition)
	CharacterController:DeSpawn()
	
	local ClonedFakeBloxBlox = FakeBloxBlox:Clone()
	
	local ClonedRealBloxBlox = RealBloxBlox:Clone()
	ClonedRealBloxBlox.AlignOrientation.Attachment1 = ClonedFakeBloxBlox.Attachment
	ClonedRealBloxBlox.AlignOrientation.Attachment0 = ClonedRealBloxBlox.Attachment
	ClonedRealBloxBlox.AlignPosition.Attachment1 = ClonedFakeBloxBlox.Attachment
	ClonedRealBloxBlox.AlignPosition.Attachment0 = ClonedRealBloxBlox.Attachment
	
	CharacterController.CurrentRealBloxBlox = ClonedRealBloxBlox
	CharacterController.CurrentFakeBloxBlox = ClonedFakeBloxBlox
	
	ClonedFakeBloxBlox.Position = SpawnPosition + Vector3.new(0, 5, 0)
	ClonedRealBloxBlox.Position = SpawnPosition 
	
	CharacterController.IsMovingOnCooldown = false
	CharacterController.IsStanding = true
	CharacterController.IsCharacterInAir = false
	
	LastGoalRotationCFrame = RealBloxBlox.CFrame
	
	ClonedRealBloxBlox.Parent = workspace
	ClonedFakeBloxBlox.Parent = workspace
	
	CharacterController.BloxBloxCharacterParams.FilterDescendantsInstances = {ClonedRealBloxBlox, ClonedFakeBloxBlox}
end

function CharacterController:OnInput(KeyCode : Enum.KeyCode)
	if CharacterController.IsMovingOnCooldown or not CharacterController.CurrentRealBloxBlox or CharacterController.IsCharacterInAir then return end
	
	local KeyBindSettings = CharacterController.ControlMap[KeyCode]
	
	if not KeyBindSettings then return end
	
	local MoveRotation = KeyBindSettings.MoveRotation
	
	local CharacterAngleX, CharacterAngleY, CharacterAngleZ = CharacterController.CurrentRealBloxBlox.CFrame:ToEulerAnglesXYZ()
	local CharacterRotation = CFrame.Angles(CharacterAngleX, CharacterAngleY, CharacterAngleZ)
	
	local GoalRotation = MoveRotation * CharacterRotation
	
	local WillCharacterStandUp = IsMovedCharacterStanding(GoalRotation)
	
	local CharacterWillStandUp = (not CharacterController.IsStanding and WillCharacterStandUp)
	local CharacterWillProne = (CharacterController.IsStanding and not WillCharacterStandUp)
	
	local MovePosition = (CharacterWillProne or CharacterWillStandUp) and KeyBindSettings.StateChangedMoveVector or KeyBindSettings.MoveVector

	if CharacterWillStandUp then
		MovePosition += Vector3.new(0, 2, 0)
	elseif CharacterWillProne then
		MovePosition -= Vector3.new(0, 2, 0)
	end
	
	CharacterController.IsStanding = WillCharacterStandUp

	local FinalRealBloxBloxCFrame = CFrame.new(CharacterController.CurrentRealBloxBlox.Position + MovePosition) * GoalRotation
	local FinalFakeBloxBloxCFrame = CFrame.new(CharacterController.CurrentFakeBloxBlox.Position + MovePosition) * GoalRotation	

	TweenService:Create(CharacterController.CurrentRealBloxBlox, CharacterController.Settings.MoveTweenInfo, {CFrame = FinalRealBloxBloxCFrame}):Play()
	TweenService:Create(CharacterController.CurrentFakeBloxBlox, CharacterController.Settings.MoveTweenInfo, {CFrame = FinalFakeBloxBloxCFrame}):Play()	
	
	LastGoalRotationCFrame = GoalRotation
		
	CharacterController.IsMovingOnCooldown = true
	
	task.wait(CharacterController.Settings.CooldownTime)
	
	CharacterController.IsMovingOnCooldown = false
end

function CharacterController:OnUpdate(deltaTime : number)
	SnapFakeCharacter()
	UpdateCharacterInTheAirState()
end

function CharacterController:OnHeartBeat()
	UpdateCharacterMoveWithPlatforms()	
end

function CharacterController:DeSpawn()
	if CharacterController.CurrentRealBloxBlox then
		CharacterController.CurrentRealBloxBlox:Destroy()
		CharacterController.CurrentFakeBloxBlox:Destroy()
		
		CharacterController.CurrentRealBloxBlox = nil
		CharacterController.CurrentFakeBloxBlox = nil
	end
end

return CharacterController
