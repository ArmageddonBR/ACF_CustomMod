
AddCSLuaFile()

DEFINE_BASECLASS( "base_wire_entity" )

ENT.PrintName = "ACF Engine"
ENT.WireDebugName = "ACF Engine"

if CLIENT then
	
	local ACFCUSTOM_EngineInfoWhileSeated = CreateClientConVar("ACFCUSTOM_EngineInfoWhileSeated", 0, true, false)
	
	-- copied from base_wire_entity: DoNormalDraw's notip arg isn't accessible from ENT:Draw defined there.
	function ENT:Draw()
	
		local lply = LocalPlayer()
		local hideBubble = not GetConVar("ACFCUSTOM_EngineInfoWhileSeated"):GetBool() and IsValid(lply) and lply:InVehicle()
		
		self.BaseClass.DoNormalDraw(self, false, hideBubble)
		Wire_Render(self)
		
		if self.GetBeamLength and (not self.GetShowBeam or self:GetShowBeam()) then 
			-- Every SENT that has GetBeamLength should draw a tracer. Some of them have the GetShowBeam boolean
			Wire_DrawTracerBeam( self, 1, self.GetBeamHighlight and self:GetBeamHighlight() or false ) 
		end
		
	end
	
	function ACFEngineCustomGUICreate( Table )

		acfmenupanelcustom:CPanelText("Name", Table.name)
		
		acfmenupanelcustom.CData.DisplayModel = vgui.Create( "DModelPanel", acfmenupanelcustom.CustomDisplay )
			acfmenupanelcustom.CData.DisplayModel:SetModel( Table.model )
			acfmenupanelcustom.CData.DisplayModel:SetCamPos( Vector( 250, 500, 250 ) )
			acfmenupanelcustom.CData.DisplayModel:SetLookAt( Vector( 0, 0, 0 ) )
			acfmenupanelcustom.CData.DisplayModel:SetFOV( 20 )
			acfmenupanelcustom.CData.DisplayModel:SetSize(acfmenupanelcustom:GetWide(),acfmenupanelcustom:GetWide())
			acfmenupanelcustom.CData.DisplayModel.LayoutEntity = function( panel, entity ) end
		acfmenupanelcustom.CustomDisplay:AddItem( acfmenupanelcustom.CData.DisplayModel )
		
		acfmenupanelcustom:CPanelText("Desc", Table.desc)
		acfmenupanelcustom:CPanelText("RPM", "Idle : "..(Table.idlerpm).." RPM\nIdeal RPM Range : "..(Table.peakminrpm).."-"..(Table.peakmaxrpm).." RPM\nRedline : "..(Table.limitrpm).." RPM\nWeight : "..(Table.weight).." kg\nFlywheelMass : "..(Table.flywheelmass).." kg\nFuel Type : "..(Table.fuel))
		
		local peakkw
		local peakkwrpm
		local pbmin
		local pbmax
		
		if (Table.iselec == true )then --elecs and turbs get peak power in middle of rpm range
			peakkw = ( Table.torque * ( 1 + Table.peakmaxrpm / Table.limitrpm )) * Table.limitrpm / (4*9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
			peakkwrpm = math.floor(Table.limitrpm / 2)
			pbmin = Table.idlerpm
			pbmax = peakkwrpm
		else	
			peakkw = Table.torque * Table.peakmaxrpm / 9548.8
			peakkwrpm = Table.peakmaxrpm
			pbmin = Table.peakminrpm
			pbmax = Table.peakmaxrpm
		end
		
		TextNeedFuel = vgui.Create( "DLabel" )
		TextNeedFuel:SetText( "When supplied with fuel:")
		TextNeedFuel:SetTextColor(Color(0,150,0,255))
		acfmenupanelcustom.CustomDisplay:AddItem( TextNeedFuel )
		acfmenupanelcustom:CPanelText("WhenFuel2", "Peak Power : "..math.floor(peakkw*ACF.TorqueBoost).." kW / "..math.Round(peakkw*ACF.TorqueBoost*1.34).." HP @ "..peakkwrpm.." RPM\nPeak Torque : "..(Table.torque*ACF.TorqueBoost).." n/m  / "..math.Round(Table.torque*ACF.TorqueBoost*0.73).." ft-lb")
			
		if Table.fuel == "Electric" then
			local cons = ACF.ElecRate * peakkw / ACF.Efficiency[Table.enginetype]
			acfmenupanelcustom:CPanelText("FuelCons", "Peak energy use : "..math.Round(cons,1).." kW / "..math.Round(0.06*cons,1).." MJ/min")
		elseif Table.fuel == "Multifuel" then
			local petrolcons = ACF.FuelRate * ACF.Efficiency[Table.enginetype] * ACF.TorqueBoost * peakkw / (60 * ACF.FuelDensity.Petrol)
			local dieselcons = ACF.FuelRate * ACF.Efficiency[Table.enginetype] * ACF.TorqueBoost * peakkw / (60 * ACF.FuelDensity.Diesel)
			acfmenupanelcustom:CPanelText("FuelConsP", "Petrol Use at "..peakkwrpm.." rpm : "..math.Round(petrolcons,2).." liters/min / "..math.Round(0.264*petrolcons,2).." gallons/min")
			acfmenupanelcustom:CPanelText("FuelConsD", "Diesel Use at "..peakkwrpm.." rpm : "..math.Round(dieselcons,2).." liters/min / "..math.Round(0.264*dieselcons,2).." gallons/min")
		else
			local fuelcons = ACF.FuelRate * ACF.Efficiency[Table.enginetype] * ACF.TorqueBoost * peakkw / (60 * ACF.FuelDensity[Table.fuel])
			acfmenupanelcustom:CPanelText("FuelCons", (Table.fuel).." Use at "..peakkwrpm.." rpm : "..math.Round(fuelcons,2).." liters/min / "..math.Round(0.264*fuelcons,2).." gallons/min")
		end
		
		TextNotFuel = vgui.Create( "DLabel" )
		TextNotFuel:SetText( "When NOT supplied with fuel:")
		TextNotFuel:SetTextColor(Color(200,0,0,255))
		acfmenupanelcustom.CustomDisplay:AddItem( TextNotFuel )
		acfmenupanelcustom:CPanelText("WhenNotFuel2", "Peak Power : "..math.floor(peakkw).." kW / "..math.Round(peakkw*1.34).." HP @ "..peakkwrpm.." RPM\nPeak Torque : "..(Table.torque).." n/m  / "..math.Round(Table.torque*0.73).." ft-lb")
	
	acfmenupanelcustom.CustomDisplay:PerformLayout()	
	
	end
	
	return
	
end

--###################################################
--##### 			END CL_INIT					#####
--###################################################

function ENT:Initialize()

	self.Throttle = 0
	self.Active = false
	self.IsMaster = true
	self.GearLink = {} -- a "Link" has these components: Ent, Rope, RopeLen, ReqTq
	self.FuelLink = {}

	self.LastCheck = 0
	self.LastThink = 0
	self.MassRatio = 1
	self.FuelTank = 0
	self.Legal = true
	self.CanUpdate = true
	self.RequiresFuel = false
	
	self.CutMode = 0
	self.CutRpm = 0
	self.Fuelusing = 0
	self.DisableCut = 0
	self.ExtraLink = {}
	self.RadiatorLink = {}
	self.PeakTorqueExtra = 0
	self.RPMExtra = 0
	self.ExtraUsing = 0
	self.PeakTorqueHealth = 0
	
	self.Outputs = WireLib.CreateSpecialOutputs( self, { "RPM", "Torque", "Power", "Fuel Use", "Entity", "Mass", "Physical Mass" }, { "NORMAL","NORMAL","NORMAL", "NORMAL", "ENTITY", "NORMAL", "NORMAL" } )
	Wire_TriggerOutput( self, "Entity", self )
	self.WireDebugName = "ACF Engine"

end

--###################################################
--##### 			MAKE ENGINE					#####
--###################################################

function MakeACF_Engine(Owner, Pos, Angle, Id)

	if not Owner:CheckLimit("_acf_misc") then return false end

	local Engine = ents.Create( "acf_engine_custom" )
	if not IsValid( Engine ) then return false end
	
	local EID
	local List = list.Get("ACFCUSTOMEnts")
	if List.MobilityCustom[Id] then EID = Id else EID = "5.7-V8" end
	local Lookup = List.MobilityCustom[EID]
	
	Engine:SetAngles(Angle)
	Engine:SetPos(Pos)
	Engine:Spawn()
	Engine:SetPlayer(Owner)
	Engine.Owner = Owner
	Engine.Id = EID
	
	Engine.Model = Lookup.model
	Engine.SoundPath = Lookup.sound
	Engine.Weight = Lookup.weight
	Engine.IdleRPM = Lookup.idlerpm
	Engine.PeakTorque = Lookup.torque
	Engine.PeakTorqueHeld = Lookup.torque
	Engine.PeakMinRPM = Lookup.peakminrpm
	Engine.PeakMaxRPM = Lookup.peakmaxrpm
	Engine.LimitRPM = Lookup.limitrpm
	Engine.Inertia = Lookup.flywheelmass*(3.1416)^2
	Engine.iselec = Lookup.iselec
	Engine.FlywheelOverride = Lookup.flywheeloverride
	Engine.IsTrans = Lookup.istrans -- driveshaft outputs to the side
	Engine.FuelType = Lookup.fuel or "Petrol"
	Engine.EngineType = Lookup.enginetype or "GenericPetrol"
	Engine.SoundPitch = Lookup.pitch or 1
	Engine.SpecialHealth = true
	Engine.SpecialDamage = true
	Engine.TorqueMult = 1
	Engine.FuelTank = 0
	
	Engine:FirstLoadCustom()
	Engine.FlywheelMassValue = Lookup.flywheelmass
	--Creating Wire Inputs
	Engine.CustomLimit = GetConVarNumber("sbox_max_acf_modding")
	local Inputs = {"Active", "Throttle"}
	if Engine.CustomLimit > 0 then
		if Engine.EngineType == "Turbine" or Engine.EngineType == "Electric" then	--Create inputs for Electric&Turbine
			table.insert(Inputs, "TqAdd")
			table.insert(Inputs, "RpmAdd")
			table.insert(Inputs, "FlywheelMass")
			table.insert(Inputs, "Override")
		else		 --Create inputs others engines
			table.insert(Inputs, "TqAdd")
			table.insert(Inputs, "RpmAdd")
			table.insert(Inputs, "FlywheelMass")
			table.insert(Inputs, "Idle")
			table.insert(Inputs, "Disable Cutoff")
		end
	end
	Engine.Inputs = Wire_CreateInputs( Engine, Inputs )
	
	Engine.TorqueScale = ACF.TorqueScale[Engine.EngineType]
	
	--calculate boosted peak kw
	if Engine.EngineType == "Turbine" or Engine.EngineType == "Electric" then
		Engine.DisableCut = 1
		Engine.peakkw = ( Engine.PeakTorque * ( 1 + Engine.PeakMaxRPM / Engine.LimitRPM )) * Engine.LimitRPM / (4*9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		Engine.PeakKwRPM = math.floor(Engine.LimitRPM / 2)
	else
		Engine.peakkw = Engine.PeakTorque * Engine.PeakMaxRPM / 9548.8
		Engine.PeakKwRPM = Engine.PeakMaxRPM
	end
	--calculate base fuel usage
	if Engine.EngineType == "Electric" then
		Engine.FuelUse = ACF.ElecRate / (ACF.Efficiency[Engine.EngineType] * 60 * 60) --elecs use current power output, not max
	else
		Engine.FuelUse = ACF.TorqueBoost * ACF.FuelRate * ACF.Efficiency[Engine.EngineType] * Engine.peakkw / (60 * 60)
	end

	Engine.FlyRPM = 0
	Engine:SetModel( Engine.Model )	
	Engine.Sound = nil
	Engine.RPM = {}

	Engine:PhysicsInit( SOLID_VPHYSICS )      	
	Engine:SetMoveType( MOVETYPE_VPHYSICS )     	
	Engine:SetSolid( SOLID_VPHYSICS )

	Engine.Out = Engine:WorldToLocal(Engine:GetAttachment(Engine:LookupAttachment( "driveshaft" )).Pos)

	local phys = Engine:GetPhysicsObject()  	
	if IsValid( phys ) then
		phys:SetMass( Engine.Weight ) 
	end

	Engine:SetNWString( "WireName", Lookup.name )
	------ GUI ---------
	Engine.FlywheelMassGUI = Engine.FlywheelMassValue
	Engine:UpdateOverlayText()
	
	Owner:AddCount("_acf_engine", Engine)
	Owner:AddCleanup( "acfcustom", Engine )
	
	ACF_Activate( Engine, 0 )

	return Engine
end
list.Set( "ACFCvars", "acf_engine_custom", {"id"} )
duplicator.RegisterEntityClass("acf_engine_custom", MakeACF_Engine, "Pos", "Angle", "Id")

--###################################################
--##### 		UPDATE ENGINE					#####
--###################################################

function ENT:Update( ArgsTable )	
	-- That table is the player data, as sorted in the ACFCvars above, with player who shot, 
	-- and pos and angle of the tool trace inserted at the start

	if self.Active then
		return false, "Turn off the engine before updating it!"
	end
	
	if ArgsTable[1] ~= self.Owner then -- Argtable[1] is the player that shot the tool
		return false, "You don't own that engine!"
	end

	local Id = ArgsTable[4]	-- Argtable[4] is the engine ID
	local Lookup = list.Get("ACFCUSTOMEnts").MobilityCustom[Id]

	if Lookup.model ~= self.Model then
		return false, "The new engine must have the same model!"
	end
	
	local Feedback = ""
	if Lookup.fuel != self.FuelType then
		Feedback = " Fuel type changed, fuel tanks unlinked."
		for Key,Value in pairs(self.FuelLink) do
			table.remove(self.FuelLink,Key)
			--need to remove from tank master?
		end
	end

	self.Id = Id
	self.SoundPath = Lookup.sound
	self.Weight = Lookup.weight
	self.IdleRPM = Lookup.idlerpm
	self.PeakTorque = Lookup.torque
	self.PeakTorqueHeld = Lookup.torque
	self.PeakMinRPM = Lookup.peakminrpm
	self.PeakMaxRPM = Lookup.peakmaxrpm
	self.LimitRPM = Lookup.limitrpm
	self.Inertia = Lookup.flywheelmass*(3.1416)^2
	self.iselec = Lookup.iselec -- is the engine electric?
	self.FlywheelOverride = Lookup.flywheeloverride -- how much power does it output
	self.IsTrans = Lookup.istrans
	self.FuelType = Lookup.fuel
	self.EngineType = Lookup.enginetype
	self.SoundPitch = Lookup.pitch or 1
	self.SpecialHealth = true
	self.SpecialDamage = true
	self.TorqueMult = self.TorqueMult or 1
	self.FuelTank = 0
	
	self:FirstLoadCustom()
	self.FlywheelMassValue = Lookup.flywheelmass
	--Creating Wire Inputs
	self.CustomLimit = GetConVarNumber("sbox_max_acf_modding")
	local Inputs = {"Active", "Throttle"}
	if self.CustomLimit > 0 then
		if self.EngineType == "Turbine" or self.EngineType == "Electric" then	--Create inputs for Electric&Turbine
			table.insert(Inputs, "TqAdd")
			table.insert(Inputs, "RpmAdd")
			table.insert(Inputs, "FlywheelMass")
			table.insert(Inputs, "Override")
		else 		--Create inputs others engines
			table.insert(Inputs, "TqAdd")
			table.insert(Inputs, "RpmAdd")
			table.insert(Inputs, "FlywheelMass")
			table.insert(Inputs, "Idle")
			table.insert(Inputs, "Disable Cutoff")
		end
	end
	self.Inputs = Wire_CreateInputs( self, Inputs )
	
	self.TorqueScale = ACF.TorqueScale[self.EngineType]
	
	--calculate boosted peak kw
	if self.EngineType == "Turbine" or self.EngineType == "Electric" then
		self.DisableCut = 1
		self.peakkw = ( self.PeakTorque * ( 1 + self.PeakMaxRPM / self.LimitRPM )) * self.LimitRPM / (4*9548.8) --adjust torque to 1 rpm maximum, assuming a linear decrease from a max @ 1 rpm to min @ limiter
		self.PeakKwRPM = math.floor(self.LimitRPM / 2)
	else
		self.peakkw = self.PeakTorque * self.PeakMaxRPM / 9548.8
		self.PeakKwRPM = self.PeakMaxRPM
	end
	--calculate base fuel usage
	if self.EngineType == "Electric" then
		self.FuelUse = ACF.ElecRate / (ACF.Efficiency[self.EngineType] * 60 * 60) --elecs use current power output, not max
	else
		self.FuelUse = ACF.TorqueBoost * ACF.FuelRate * ACF.Efficiency[self.EngineType] * self.peakkw / (60 * 60)
	end

	self:SetModel( self.Model )	
	self:SetSolid( SOLID_VPHYSICS )
	self.Out = self:WorldToLocal(self:GetAttachment(self:LookupAttachment( "driveshaft" )).Pos)

	local phys = self:GetPhysicsObject()  	
	if IsValid( phys ) then 
		phys:SetMass( self.Weight ) 
	end
	
	self:SetNWString( "WireName", Lookup.name )
	------ GUI ---------
	self.FlywheelMassGUI = self.FlywheelMassValue
	self:UpdateOverlayText()
	
	ACF_Activate( self, 1 )
	
	return true, "Engine updated successfully!"..Feedback
end

--###################################################
--##### 			FUNCTIONS					#####
--###################################################

function ENT:FirstLoadCustom( )
	self.PeakTorqueNormal = self.PeakTorque
	self.PeakMaxRPMNormal = self.PeakMaxRPM
	self.LimitRPMNormal = self.LimitRPM
	self.FlywheelMassNormal = self.FlywheelMassValue
	self.IdleRPMNormal = self.IdleRPM
	self.FlywheelOverrideNormal = self.FlywheelOverride
	self.CutValue = self.LimitRPM / 20
	self.CutRpm = self.LimitRPM - 100
	self.PeakTorqueAdd = self.PeakTorque
end

function ENT:UpdateOverlayText()

	local pbmin
	local pbmax
	
	if (self.iselec == true )then --elecs and turbs get peak power in middle of rpm range
		pbmin = self.IdleRPM
		pbmax = math.floor(self.LimitRPM / 2)
	else
		pbmin = self.PeakMinRPM
		pbmax = self.PeakMaxRPM
	end
	
	local SpecialBoost = self.RequiresFuel and ACF.TorqueBoost or 1
	self.PowerGUI = self.peakkw*SpecialBoost
	self.TorqueGUI = (self.PeakTorqueAdd+self.PeakTorqueExtra-self.PeakTorqueHealth)*SpecialBoost
	
	local text = "Power: " .. math.Round(self.PowerGUI) .. " kW / " .. math.Round(self.PowerGUI * 1.34) .. " hp\n"
	text = text .. "Torque: " .. math.Round(self.TorqueGUI) .. " Nm / " .. math.Round(self.TorqueGUI * 0.73) .. " ft-lb\n"
	text = text .. "Powerband: " .. pbmin .. " - " .. pbmax .. " RPM\n"
	if self.EngineType == "Turbine" or self.EngineType == "Electric" then
		text = text .. "Override: " .. math.Round(self.FlywheelOverride) .. " RPM\n"
	else
		text = text .. "Idle: " .. math.Round(self.IdleRPM) .. " RPM\n"
	end
	text = text .. "Redline: " .. math.Round((self.LimitRPM+self.RPMExtra)) .. " RPM\n"
	text = text .. "FlywheelMass: " .. math.Round(self.FlywheelMassGUI,3) .. " Kg\n"
	text = text .. "Weight: " .. math.Round(self.Weight) .. "Kg"
	
	self:SetOverlayText( text )
end

function ENT:UpdateEngineConsumption()
	--reload peak and torque
	if self.EngineType == "Turbine" or self.EngineType == "Electric" then
		self.peakkw = (self.PeakTorque+self.PeakTorqueExtra-self.PeakTorqueHealth) * (self.LimitRPM+self.RPMExtra) / (4 * 9548.8)
		self.PeakKwRPM = math.floor((self.LimitRPM+self.RPMExtra) / 2)
	else
		self.peakkw = (self.PeakTorque+self.PeakTorqueExtra-self.PeakTorqueHealth) * (self.PeakMaxRPM+self.RPMExtra) / 9548.8
		self.PeakKwRPM = (self.PeakMaxRPM+self.RPMExtra)
	end
	if self.EngineType == "Electric" then 
		self.FuelUse = ACF.ElecRate / (ACF.Efficiency[self.EngineType] * 60 * 60) --elecs use current power output, not max
	else
		self.FuelUse = ACF.TorqueBoost * ACF.FuelRate * ACF.Efficiency[self.EngineType] * self.peakkw / (60 * 60)
	end
	--update gui final
	self:UpdateOverlayText()
	//self.CanUpdateGui = 0
end

--###################################################
--##### 		TRIGGER INPUTS					#####
--###################################################

function ENT:TriggerInput( iname, value )
	if (iname == "Throttle") then
		self.Throttle = math.Clamp(value,0,100)/100
	elseif (iname == "Active") then
		if (value > 0 and not self.Active) then
			--make sure we have fuel
			local HasFuel
			if not self.RequiresFuel then
				HasFuel = true
			else 
				for _,fueltank in pairs(self.FuelLink) do
					if fueltank.Fuel > 0 and fueltank.Active then HasFuel = true break end
				end
			end
			
			if HasFuel then
				self.RPM = {}
				self.RPM[1] = self.IdleRPM
				self.Active = true
				self.Active2 = true
				self.Sound = CreateSound(self, self.SoundPath)
				self.Sound:PlayEx(0.5,100)
				self:ACFInit()
			end
		elseif (value > 0) then
			local HasFuel
			if not self.RequiresFuel then
				HasFuel = true
			else
				for _,fueltank in pairs(self.FuelLink) do
					if fueltank.Fuel <= 0 or not fueltank.Active then HasFuel = false break end
				end
			end
			if not HasFuel then
				self:TriggerInput( "Active" , 0 )
				self.Active = false
				Wire_TriggerOutput( self, "RPM", 0 )
				Wire_TriggerOutput( self, "Torque", 0 )
				Wire_TriggerOutput( self, "Power", 0 )
				Wire_TriggerOutput( self, "Fuel Use", 0 )
			end
		elseif (value <= 0 and self.Active) then
			self.Active = false
			Wire_TriggerOutput( self, "RPM", 0 )
			Wire_TriggerOutput( self, "Torque", 0 )
			Wire_TriggerOutput( self, "Power", 0 )
			Wire_TriggerOutput( self, "Fuel Use", 0 )
		end
		
	elseif (iname == "TqAdd") then
		if (self.PeakTorqueAdd != self.PeakTorqueNormal+value) then
			self.PeakTorqueAdd = self.PeakTorqueNormal+value
			self:UpdateEngineConsumption()
		end
	elseif (iname == "RpmAdd") then
		if (self.PeakMaxRPM != self.PeakMaxRPMNormal+value) then
			self.PeakMaxRPM = self.PeakMaxRPMNormal+value
			self.LimitRPM = self.LimitRPMNormal+value
			self.CutValue = self.LimitRPM / 20
			self.CutRpm = self.LimitRPM - 100
			self:UpdateEngineConsumption()
		end
	elseif (iname == "FlywheelMass") then
		if (value > 0 and self.FlywheelMassValue != value) then
			self.FlywheelMassValue = value
			self.FlywheelMassGUI = self.FlywheelMassValue
			self:UpdateOverlayText()
		elseif (value <= 0 and self.FlywheelMassValue != self.FlywheelMassNormal) then
			self.FlywheelMassValue = self.FlywheelMassNormal
			self.FlywheelMassGUI = self.FlywheelMassValue
			self:UpdateOverlayText()
		end
	elseif (iname == "Override") then
		if (value > 0 and self.FlywheelOverride != value) then
			self.FlywheelOverride = value
			self:UpdateOverlayText()
		elseif (value <= 0 and self.FlywheelOverride != self.FlywheelOverrideNormal) then
			self.FlywheelOverride = self.FlywheelOverrideNormal
			self:UpdateOverlayText()
		end
	elseif (iname == "Idle") then
		if (value > 0 and self.IdleRPM != value) then
			self.IdleRPM = value
			self:UpdateOverlayText()
		elseif (value <= 0 and self.IdleRPM != self.IdleRPMNormal) then
			self.IdleRPM = self.IdleRPMNormal
			self:UpdateOverlayText()
		end
	elseif (iname == "Disable Cutoff") then
		if (value > 0 and self.DisableCut != 1) then
			self.DisableCut = 1
		elseif (value <= 0 and self.DisableCut != 0) then
			self.DisableCut = 0
		end
	end
end

function ENT:ACF_Activate()
	--Density of steel = 7.8g cm3 so 7.8kg for a 1mx1m plate 1m thick
	local Entity = self
	Entity.ACF = Entity.ACF or {} 
	
	local Count
	local PhysObj = Entity:GetPhysicsObject()
	if PhysObj:GetMesh() then Count = #PhysObj:GetMesh() end
	if PhysObj:IsValid() and Count and Count>100 then

		if not Entity.ACF.Aera then
			Entity.ACF.Aera = (PhysObj:GetSurfaceArea() * 6.45) * 0.52505066107
		end
		--if not Entity.ACF.Volume then
		--	Entity.ACF.Volume = (PhysObj:GetVolume() * 16.38)
		--end
	else
		local Size = Entity.OBBMaxs(Entity) - Entity.OBBMins(Entity)
		if not Entity.ACF.Aera then
			Entity.ACF.Aera = ((Size.x * Size.y)+(Size.x * Size.z)+(Size.y * Size.z)) * 6.45
		end
		--if not Entity.ACF.Volume then
		--	Entity.ACF.Volume = Size.x * Size.y * Size.z * 16.38
		--end
	end
	
	Entity.ACF.Ductility = Entity.ACF.Ductility or 0
	--local Area = (Entity.ACF.Aera+Entity.ACF.Aera*math.Clamp(Entity.ACF.Ductility,-0.8,0.8))
	local Area = (Entity.ACF.Aera)
	--local Armour = (Entity:GetPhysicsObject():GetMass()*1000 / Area / 0.78) / (1 + math.Clamp(Entity.ACF.Ductility, -0.8, 0.8))^(1/2)	--So we get the equivalent thickness of that prop in mm if all it's weight was a steel plate
	local Armour = (Entity:GetPhysicsObject():GetMass()*1000 / Area / 0.78) 
	--local Health = (Area/ACF.Threshold) * (1 + math.Clamp(Entity.ACF.Ductility, -0.8, 0.8))												--Setting the threshold of the prop aera gone
	local Health = (Area/ACF.Threshold)
	
	local Percent = 1 
	
	if Recalc and Entity.ACF.Health and Entity.ACF.MaxHealth then
		Percent = Entity.ACF.Health/Entity.ACF.MaxHealth
	end
	
	Entity.ACF.Health = Health * Percent * ACF.EngineHPMult[self.EngineType]
	Entity.ACF.MaxHealth = Health * ACF.EngineHPMult[self.EngineType]
	Entity.ACF.Armour = Armour * (0.5 + Percent/2)
	Entity.ACF.MaxArmour = Armour * ACF.ArmorMod
	Entity.ACF.Type = nil
	Entity.ACF.Mass = PhysObj:GetMass()
	--Entity.ACF.Density = (PhysObj:GetMass()*1000)/Entity.ACF.Volume
	
	Entity.ACF.Type = "Prop"
	--print(Entity.ACF.Health)
end

function ENT:ACF_OnDamage( Entity, Energy, FrAera, Angle, Inflictor, Bone, Type )	--This function needs to return HitRes

	local Mul = ((Type == "HEAT" and ACF.HEATMulEngine) or 1) --Heat penetrators deal bonus damage to engines
	local HitRes = ACF_PropDamage( Entity, Energy, FrAera * Mul, Angle, Inflictor )	--Calling the standard damage prop function
	
	return HitRes --This function needs to return HitRes
end

function ENT:Think()

	local Time = CurTime()

	if self.Active2 then
		if self.Legal then
			self:CalcRPM()
		end

		if self.LastCheck < CurTime() then
			self:CheckRopes()
			self:CheckFuel()
			self:CheckExtra()
			self:CheckRadiator()
			self:CalcMassRatio()
			self.Legal = self:CheckLegal()

			self.LastCheck = Time + math.Rand(5, 10)
		end
	else
		--SET VALUES FOR RADIATORS
		for Key, Radiator in pairs(self.RadiatorLink) do
			if IsValid( Radiator ) then
				if Radiator.GetRpm == true then
					if not Radiator.Legal then continue end
					Radiator:GetRPM(0, self.LimitRPM, self.Active2)
				end
			end
		end
	end
	
	self:SetRadsInfos()

	self.LastThink = Time
	self:NextThink( Time )
	return true

end

function ENT:CheckLegal()

	--make sure it's not invisible to traces
	if not self:IsSolid() then return false end
	
	-- make sure weight is not below stock
	if self:GetPhysicsObject():GetMass() < self.Weight then return false end
	
	local rootparent = self:GetParent()
	
	-- if it's not parented we're fine
	if not IsValid( rootparent ) then return true end
	
	--find the root parent
	local depth = 0
	while rootparent:GetParent():IsValid() and depth<5 do
		depth = depth + 1
		rootparent = rootparent:GetParent()
	end
	
	--if there's still more parents, it's not legal
	if rootparent:GetParent():IsValid() then return false end
	
	--make sure it's welded to root parent
	for k, v in pairs( constraint.FindConstraints( self, "Weld" ) ) do
		if v.Ent1 == rootparent or v.Ent2 == rootparent then return true end
	end
	
	return false
	
end

function ENT:CalcMassRatio()
	
	local Mass = 0
	local PhysMass = 0
	
	-- get the shit that is physically attached to the vehicle
	local PhysEnts = ACF_GetAllPhysicalConstraints( self )
	
	-- add any parented but not constrained props you sneaky bastards
	local AllEnts = table.Copy( PhysEnts )
	for k, v in pairs( PhysEnts ) do
		
		table.Merge( AllEnts, ACF_GetAllChildren( v ) )
	
	end
	
	for k, v in pairs( AllEnts ) do
		
		if not IsValid( v ) then continue end
		
		local phys = v:GetPhysicsObject()
		if not IsValid( phys ) then continue end
		
		Mass = Mass + phys:GetMass()
		
		if PhysEnts[ v ] then
			PhysMass = PhysMass + phys:GetMass()
		end
		
	end

	self.MassRatio = PhysMass / Mass
	
	Wire_TriggerOutput( self, "Mass", math.Round( Mass, 2 ) )
	Wire_TriggerOutput( self, "Physical Mass", math.Round( PhysMass, 2 ) )
	
end

function ENT:ACFInit()
	
	self:CalcMassRatio()

	self.LastThink = CurTime()
	self.Torque = self.PeakTorqueAdd+self.PeakTorqueExtra-self.PeakTorqueHealth
	self.FlyRPM = self.IdleRPM * 1.5

end

function ENT:CalcRPM()

	local DeltaTime = CurTime() - self.LastThink
	-- local AutoClutch = math.min(math.max(self.FlyRPM-self.IdleRPM,0)/(self.IdleRPM+self.LimitRPM/10),1)
	--local ClutchRatio = math.min(Clutch/math.max(TorqueDiff,0.05),1)
	
	--find next active tank with fuel
	local Tank = nil
	local boost = 1
	local MaxTanks = #self.FuelLink
	
	for i = 1, MaxTanks do
		Tank = self.FuelLink[self.FuelTank+1]
		self.FuelTank = (self.FuelTank + 1) % MaxTanks
		if IsValid(Tank) and Tank.Fuel > 0 and Tank.Active then
			break --return Tank
		end
		Tank = nil
		i = i + 1
	end
	
	--calculate fuel usage
	if Tank then
		local Consumption
		if self.FuelType == "Electric" then
			Consumption = (self.Torque * self.FlyRPM / 9548.8) * self.FuelUse * DeltaTime
		else
			local Load = 0.3 + self.Throttle * 0.7
			Consumption = Load * self.FuelUse * (self.FlyRPM / self.PeakKwRPM) * DeltaTime / ACF.FuelDensity[Tank.FuelType]
		end
		Tank.Fuel = math.max(Tank.Fuel - Consumption,0)
		boost = ACF.TorqueBoost
		Wire_TriggerOutput(self, "Fuel Use", math.Round(60*Consumption/DeltaTime,3))
		self.Fuelusing = math.Round((60*Consumption/DeltaTime),3)
	elseif self.RequiresFuel then
		self:TriggerInput( "Active", 0 ) --shut off if no fuel and requires it
		return 0
	else
		Wire_TriggerOutput(self, "Fuel Use", 0)
	end
	
	--adjusting performance based on damage
	self.TorqueMult = math.Clamp(((1 - self.TorqueScale) / (0.5)) * ((self.ACF.Health/self.ACF.MaxHealth) - 1) + 1, self.TorqueScale, 1)
	self.PeakTorque = (self.PeakTorqueAdd+self.PeakTorqueExtra-self.PeakTorqueHealth) * self.TorqueMult
	
	-- Calculate the current torque from flywheel RPM
	self.Torque = boost * self.Throttle * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM, (self.LimitRPM - self.FlyRPM) / (self.LimitRPM - self.PeakMaxRPM), 1 ), 0 )
	
	local Drag
	local TorqueDiff
	if self.Active then
		if( self.CutMode == 0 ) then
			self.Torque = boost * self.Throttle * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM , ((self.LimitRPM+self.RPMExtra) - self.FlyRPM) / ((self.LimitRPM+self.RPMExtra) - (self.PeakMaxRPM+self.RPMExtra)), 1 ), 0 )
			if self.iselec == true then
				Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / self.FlywheelOverride) * (1 - self.Throttle) / self.Inertia
			else
				Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / (self.PeakMaxRPM+self.RPMExtra)) * ( 1 - self.Throttle) / self.Inertia
			end
		elseif( self.CutMode == 1 ) then
			self.Torque = boost * 0 * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM , ((self.LimitRPM+self.RPMExtra) - self.FlyRPM) / ((self.LimitRPM+self.RPMExtra) - (self.PeakMaxRPM+self.RPMExtra)), 1 ), 0 )
			if self.iselec == true then
				Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / self.FlywheelOverride) * (1 - 0) / self.Inertia
			else
				Drag = self.PeakTorque * (math.max( self.FlyRPM - self.IdleRPM, 0) / (self.PeakMaxRPM+self.RPMExtra)) * ( 1 - 0) / self.Inertia
			end
		end 
		-- Let's accelerate the flywheel based on that torque
		self.FlyRPM = math.max( self.FlyRPM + self.Torque / self.Inertia - Drag, 1 )
		-- This is the presently avaliable torque from the engine
		TorqueDiff = math.max( self.FlyRPM - self.IdleRPM, 0 ) * self.Inertia
	else
		self.Torque = boost * 0 * math.max( self.PeakTorque * math.min( self.FlyRPM / self.PeakMinRPM , ((self.LimitRPM+self.RPMExtra) - self.FlyRPM) / ((self.LimitRPM+self.RPMExtra) - (self.PeakMaxRPM+self.RPMExtra)), 1 ), 0 )
		if self.iselec == true then
			Drag = self.PeakTorque * (math.max( self.FlyRPM - 0, 0) / self.FlywheelOverride) * (1 - 0) / self.Inertia
		else
			Drag = self.PeakTorque * (math.max( self.FlyRPM - 0, 0) / (self.PeakMaxRPM+self.RPMExtra)) * ( 1 - 0) / self.Inertia
		end
		-- Let's accelerate the flywheel based on that torque
		self.FlyRPM = math.max( self.FlyRPM + self.Torque / self.Inertia - Drag, 1 )
		-- This is the presently avaliable torque from the engine
		TorqueDiff = 0
	end
	
	-- The gearboxes don't think on their own, it's the engine that calls them, to ensure consistent execution order
	local Boxes = table.Count( self.GearLink )
	local TotalReqTq = 0
	-- Get the requirements for torque for the gearboxes (Max clutch rating minus any wheels currently spinning faster than the Flywheel)
	for Key, Link in pairs( self.GearLink ) do
		if not Link.Ent.Legal then continue end
		
		Link.ReqTq = Link.Ent:Calc( self.FlyRPM, self.Inertia )
		TotalReqTq = TotalReqTq + Link.ReqTq
	end
	-- Calculate the ratio of total requested torque versus what's avaliable
	local AvailRatio = math.min( TorqueDiff / TotalReqTq / Boxes, 1 )
	-- Split the torque fairly between the gearboxes who need it
	for Key, Link in pairs( self.GearLink ) do
		if not Link.Ent.Legal then continue end
		Link.Ent:Act( Link.ReqTq * AvailRatio * self.MassRatio, DeltaTime, self.MassRatio )
	end

	self.FlyRPM = self.FlyRPM - math.min( TorqueDiff, TotalReqTq ) / self.Inertia
	
	if( self.DisableCut == 0 ) then
		if( self.FlyRPM >= self.CutRpm and self.CutMode == 0 ) then
			self.CutMode = 1
			if self.Sound then
				self.Sound:Stop()
			end
			self.Sound = nil
			local MakeSound = math.random(1,3)
			if MakeSound <= 1 and self.Sound2 and self.Sound2:IsPlaying() then self.Sound2:Stop() end
			if MakeSound <= 1 then
				self.Sound2 = CreateSound(self, "ambient/explosions/explode_4.wav")
				self.Sound2:PlayEx(0.7,100)
			end
		end
		if( self.FlyRPM <= self.CutRpm - self.CutValue and self.CutMode == 1 ) then
			self.CutMode = 0
			self.Sound = CreateSound(self, self.SoundPath)
			self.Sound:PlayEx(0.5,100)
		end
	elseif( self.DisableCut == 1 ) then
		self.CutMode = 0
	end
	if( self.FlyRPM <= 50 and self.Active == false ) then
		self.Active2 = false
		self.FlyRPM = 0
		if self.Sound then
			self.Sound:Stop()
		end
		self.Sound = nil
	end
	
	--Update extras values
	for Key, Extra in pairs(self.ExtraLink) do
		if IsValid(Extra) then
			if self.PeakTorqueExtra != (Extra.TorqueAdd or 0) or self.RPMExtra != (Extra.RPMAdd or 0) then
				self:AddExtraValue()
			end
			if Extra.GetRpm == true then
				if not Extra.Legal then continue end
				local PeakTorqueSend = (self.PeakTorqueAdd-self.PeakTorqueHealth)*self.TorqueMult
				Extra:GetRPM(self.FlyRPM, self.LimitRPM, self.Weight, self.Throttle, self.EngineType, PeakTorqueSend, self.IdleRPM)
			end
		end
	end
	--Update radiator values
	for Key, Radiator in pairs(self.RadiatorLink) do
		if IsValid( Radiator ) then
			if Radiator.GetRpm == true then
				if not Radiator.Legal then continue end
				Radiator:GetRPM(self.FlyRPM, self.LimitRPM, self.Active2)
			end
		end
	end
	
	-- Then we calc a smoothed RPM value for the sound effects
	table.remove( self.RPM, 10 )
	table.insert( self.RPM, 1, self.FlyRPM )
	local SmoothRPM = 0
	for Key, RPM in pairs( self.RPM ) do
		SmoothRPM = SmoothRPM + (RPM or 0)
	end
	SmoothRPM = SmoothRPM / 10

	local Power = self.Torque * SmoothRPM / 9548.8
	Wire_TriggerOutput(self, "Torque", math.floor(self.Torque))
	Wire_TriggerOutput(self, "Power", math.floor(Power))
	Wire_TriggerOutput(self, "RPM", self.FlyRPM)
	
	if self.Sound then
		self.Sound:ChangePitch( math.min( 20 + (SmoothRPM * self.SoundPitch) / 50, 255 ), 0 )
		self.Sound:ChangeVolume( 0.25 + (0.1 + 0.9 * ((SmoothRPM / (self.LimitRPM+self.RPMExtra)) ^ 1.5)) * self.Throttle / 1.5, 0 )
	end
	
	return RPM
end

function ENT:CheckRopes()
	
	for Key, Link in pairs( self.GearLink ) do
		
		local Ent = Link.Ent
		
		local OutPos = self:LocalToWorld( self.Out )
		local InPos = Ent:LocalToWorld( Ent.In )
		
		-- make sure it is not stretched too far
		if OutPos:Distance( InPos ) > Link.RopeLen * 1.5 then
			self:Unlink( Ent )
		end
		
		-- make sure the angle is not excessive
		local Direction
		if self.IsTrans then Direction = -self:GetRight() else Direction = self:GetForward() end
		
		local DrvAngle = ( OutPos - InPos ):GetNormalized():DotProduct( Direction )
		if DrvAngle < 0.7 then
			self:Unlink( Ent )
		end
		
	end
	
end

--unlink fuel tanks out of range
function ENT:CheckFuel()
	for _,tank in pairs(self.FuelLink) do
		if self:GetPos():Distance(tank:GetPos()) > 512 then
			self:Unlink( tank )
			soundstr =  "physics/metal/metal_box_impact_bullet" .. tostring(math.random(1, 3)) .. ".wav"
			self:EmitSound(soundstr,500,100)
		end
	end
end

function ENT:Link( Target )
	--Allowable Target
	if not IsValid( Target ) or not table.HasValue( { "acf_gearbox", "acf_gearboxcvt", "acf_gearboxauto", "acf_fueltank", "acf_chips", "acf_nos", "acf_rads", "acf_turbo", "acf_supercharger" }, Target:GetClass() ) then
		return false, "Can only link to gearboxes, fuel tanks or engine extras!"
	end
	--Fuel Tank Linking
	if Target:GetClass() == "acf_fueltank" then
		return self:LinkFuel( Target )
	end
	--Extra Linking
	if Target:GetClass() == "acf_chips" or Target:GetClass() == "acf_nos" or Target:GetClass() == "acf_turbo" or Target:GetClass() == "acf_supercharger" then
		if self.ExtraUsing == 1 then	--Not link severals Extra Object
			return false, "You CAN'T use more than one Extra!"
		else
			return self:LinkExtra( Target )
		end
	end
	--Radiators Linking
	if Target:GetClass() == "acf_rads" then
		return self:LinkRadiator( Target )
	end
	
	-- Check if target is already linked
	for Key, Link in pairs( self.GearLink ) do
		if Link.Ent == Target then
			return false, "That is already linked to this engine!"
		end
	end
	
	-- make sure the angle is not excessive
	local InPos = Target:LocalToWorld( Target.In )
	local OutPos = self:LocalToWorld( self.Out )
	
	local Direction
	if self.IsTrans then Direction = -self:GetRight() else Direction = self:GetForward() end
	
	local DrvAngle = ( OutPos - InPos ):GetNormalized():DotProduct( Direction )
	if DrvAngle < 0.7 then
		return false, "Cannot link due to excessive driveshaft angle!"
	end
	
	local Rope = nil
	if self.Owner:GetInfoNum( "ACF_MobilityRopeLinks", 1) == 1 then
		Rope = constraint.CreateKeyframeRope( OutPos, 1, "cable/cable2", nil, self, self.Out, 0, Target, Target.In, 0 )
	end
	
	local Link = {
		Ent = Target,
		Rope = Rope,
		RopeLen = ( OutPos - InPos ):Length(),
		ReqTq = 0
	}
	
	table.insert( self.GearLink, Link )
	table.insert( Target.Master, self )
	
	return true, "Link successful!"
end

function ENT:Unlink( Target )
	--unlink fuel tank
	if Target:GetClass() == "acf_fueltank" then
		return self:UnlinkFuel( Target )
	end
	--unlink extra
	if Target:GetClass() == "acf_chips" or Target:GetClass() == "acf_nos" or Target:GetClass() == "acf_turbo" or Target:GetClass() == "acf_supercharger" then
		return self:UnlinkExtra( Target )
	end
	--unlink radiator
	if Target:GetClass() == "acf_rads" then
		return self:UnlinkRadiator( Target )
	end
	--unlink gearboxes
	for Key, Link in pairs( self.GearLink ) do
		
		if Link.Ent == Target then
			
			-- Remove any old physical ropes leftover from dupes
			for Key, Rope in pairs( constraint.FindConstraints( Link.Ent, "Rope" ) ) do
				if Rope.Ent1 == self or Rope.Ent2 == self then
					Rope.Constraint:Remove()
				end
			end
			
			if IsValid( Link.Rope ) then
				Link.Rope:Remove()
			end
			
			table.remove( self.GearLink,Key )
			
			return true, "Unlink successful!"
			
		end
		
	end
	
	return false, "That gearbox is not linked to this engine!"
end
--LINKING FUEL TANK
function ENT:LinkFuel( Target )
	
	if not (self.FuelType == "Multifuel" and not (Target.FuelType == "Electric")) then
		if self.FuelType ~= Target.FuelType then
			return false, "Cannot link because fuel type is incompatible."
		end
	end
	
	if Target.NoLinks then
		return false, "This fuel tank doesn\'t allow linking."
	end
	
	for Key,Value in pairs(self.FuelLink) do
		if Value == Target then 
			return false, "That fuel tank is already linked to this engine!"
		end
	end
	
	if self:GetPos():Distance( Target:GetPos() ) > 512 then
		return false, "Fuel tank is too far away."
	end
	
	table.insert( self.FuelLink, Target )
	table.insert( Target.Master, self )
	
	self.RequiresFuel = true
	self:UpdateOverlayText()
	
	return true, "Link successful! Now Require Fuel"
	
end
--UNLINK FUEL TANK
function ENT:UnlinkFuel( Target )
	
	for Key, Value in pairs( self.FuelLink ) do
		if Value == Target then
			self.RequiresFuel = false
			self:UpdateOverlayText()
			table.remove( self.FuelLink, Key )
			return true, "Unlink successful! Now NOT Require Fuel"
		end
	end
	
	return false, "That fuel tank is not linked to this engine!"
	
end
--LINKING EXTRA
function ENT:LinkExtra( Target )
	
	for Key,Value in pairs(self.ExtraLink) do
		if Value == Target then 
			return false, "It's already linked to this engine!"
		end
	end
	
	if self:GetPos():Distance( Target:GetPos() ) > 512 then
		return false, "The Extra is too far away."
	end
	
	table.insert( self.ExtraLink, Target )
	table.insert( Target.Master, self )
	
	self:AddExtraValue()	--Add Values
	self.ExtraUsing = 1		--Set Using Extra to 1
	
	return true, "Link successful!"
end
--UNLINK EXTRA
function ENT:UnlinkExtra( Target )
	for Key, Value in pairs( self.ExtraLink ) do
		if Value == Target then
			self:RemoveExtraValue( )	--Remove values
			self.ExtraUsing = 0			--Set Using Extra to 0
			table.remove( self.ExtraLink, Key )
			return true, "Unlink successful!"
		end
	end
	
	return false, "That's not linked to this engine!"
end
--UNLINK EXTRA out of range
function ENT:CheckExtra()
	for _,extra in pairs(self.ExtraLink) do
		if self:GetPos():Distance(extra:GetPos()) > 512 then
			self:Unlink( extra )
			self:RemoveExtraValue( )	--Remove values
			self.ExtraUsing = 0			--Set Using Extra to 0
			soundstr =  "physics/metal/metal_box_impact_bullet" .. tostring(math.random(1, 3)) .. ".wav"
			self:EmitSound(soundstr,500,100)
		end
	end
end
--ADD EXTRA SETTINGS FUNCTION
function ENT:AddExtraValue( )
	for Key, Extra in pairs(self.ExtraLink) do
		if IsValid( Extra ) then
			self.PeakTorqueExtra = (Extra.TorqueAdd or 0)
			self.RPMExtra = (Extra.RPMAdd or 0)
			self:UpdateEngineConsumption()
		end
	end
end
--REMOVE EXTRA SETTINGS FUNCTION
function ENT:RemoveExtraValue( )
	self.PeakTorqueExtra = 0
	self.RPMExtra = 0
	self:UpdateEngineConsumption()
end
--LINKING RADIATOR
function ENT:LinkRadiator( Target )
	for Key,Value in pairs(self.RadiatorLink) do
		if Value == Target then 
			return false, "It's already linked to this engine!"
		end
	end
	
	if self:GetPos():Distance( Target:GetPos() ) > 512 then
		return false, "The Radiator is too far away."
	end
	
	table.insert( self.RadiatorLink, Target )
	table.insert( Target.Master, self )
	
	return true, "Link successful!"
end
--UNLINK RADIATOR
function ENT:UnlinkRadiator( Target )
	for Key, Value in pairs( self.RadiatorLink ) do
		if Value == Target then
			self.PeakTorqueHealth = 0
			self:UpdateEngineConsumption()
			table.remove( self.RadiatorLink, Key )
			return true, "Unlink successful!"
		end
	end
	
	return false, "That's not linked to this engine!"
end
--UNLINK Radiator out of range
function ENT:CheckRadiator()
	for _,radiator in pairs(self.RadiatorLink) do
		if self:GetPos():Distance(radiator:GetPos()) > 512 then
			self:Unlink( radiator )
			soundstr =  "physics/metal/metal_box_impact_bullet" .. tostring(math.random(1, 3)) .. ".wav"
			self:EmitSound(soundstr,500,100)
		end
	end
end
--SET Radiator Functions
function ENT:SetRadsInfos()
	local Blowed = false
	
	for Key, Radiator in pairs(self.RadiatorLink) do
		if IsValid( Radiator ) then
			local TorqueBand = (self.PeakTorqueAdd+self.PeakTorqueExtra)/2
			self.PeakTorqueHealth = math.abs(((TorqueBand*(Radiator.HealthVal-100))/-100))
			if Radiator.HealthVal <= 0 then Blowed = true end
			self:UpdateEngineConsumption()
		end
	end
	
	if Blowed then
		self.Active = false
		self:TriggerInput( "Active" , 0 )
	end
end
	
function ENT:PreEntityCopy()

	//Link Saving
	local info = {}
	local entids = {}
	for Key, Link in pairs( self.GearLink ) do					--First clean the table of any invalid entities
		if not IsValid( Link.Ent ) then
			table.remove( self.GearLink, Key )
		end
	end
	for Key, Link in pairs( self.GearLink ) do					--Then save it
		table.insert( entids, Link.Ent:EntIndex() )
	end

	info.entities = entids
	if info.entities then
		duplicator.StoreEntityModifier( self, "GearLink", info )
	end
	
	--fuel tank link saving
	local fuel_info = {}
	local fuel_entids = {}
	for Key, Value in pairs(self.FuelLink) do					--First clean the table of any invalid entities
		if not Value:IsValid() then
			table.remove(self.FuelLink, Value)
		end
	end
	for Key, Value in pairs(self.FuelLink) do					--Then save it
		table.insert(fuel_entids, Value:EntIndex())
	end
	
	fuel_info.entities = fuel_entids
	if fuel_info.entities then
		duplicator.StoreEntityModifier( self, "FuelLink", fuel_info )
	end
	
	--extra link saving
	local extra_info, extra_entids = {}
	for Key, Value in pairs(self.ExtraLink) do
		if not Value:IsValid() then table.remove(self.ExtraLink, Value) end
	end
	for Key, Value in pairs(self.ExtraLink) do table.insert(extra_entids, Value:EntIndex()) end
	
	extra_info.entities = extra_entids
	if extra_info.entities then duplicator.StoreEntityModifier( self, "ExtraLink", extra_info ) end
	
	--radiator link saving
	local rads_info, rads_entids = {}
	for Key, Value in pairs(self.RadiatorLink) do
		if not Value:IsValid() then table.remove(self.RadiatorLink, Value) end
	end
	for Key, Value in pairs(self.RadiatorLink) do table.insert(rads_entids, Value:EntIndex()) end
	
	rads_info.entities = rads_entids
	if rads_info.entities then duplicator.StoreEntityModifier( self, "RadiatorLink", rads_info ) end

	//Wire dupe info
	self.BaseClass.PreEntityCopy( self )

end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities )

	//Link Pasting
	if (Ent.EntityMods) and (Ent.EntityMods.GearLink) and (Ent.EntityMods.GearLink.entities) then
		local GearLink = Ent.EntityMods.GearLink
		if GearLink.entities and table.Count(GearLink.entities) > 0 then
			timer.Simple( 0, function() -- this timer is a workaround for an ad2/makespherical issue https://github.com/nrlulz/ACF/issues/14#issuecomment-22844064
				for _,ID in pairs(GearLink.entities) do
					local Linked = CreatedEntities[ ID ]
					if IsValid( Linked ) then
						self:Link( Linked )
					end
				end
			end )
		end
		Ent.EntityMods.GearLink = nil
	end

	--fuel tank link Pasting
	if (Ent.EntityMods) and (Ent.EntityMods.FuelLink) and (Ent.EntityMods.FuelLink.entities) then
		local FuelLink = Ent.EntityMods.FuelLink
		if FuelLink.entities and table.Count(FuelLink.entities) > 0 then
			for _,ID in pairs(FuelLink.entities) do
				local Linked = CreatedEntities[ ID ]
				if IsValid( Linked ) then
					self.RequiresFuel = true
					self:UpdateOverlayText()
					self:Link( Linked )
				end
			end
		end
		Ent.EntityMods.FuelLink = nil
	end
	
	--Extra link Pasting
	if (Ent.EntityMods) and (Ent.EntityMods.ExtraLink) and (Ent.EntityMods.ExtraLink.entities) then
		local ExtraLink = Ent.EntityMods.ExtraLink
		if ExtraLink.entities and table.Count(ExtraLink.entities) > 0 then
			for _,ID in pairs(ExtraLink.entities) do
				local Linked = CreatedEntities[ ID ]
				if IsValid( Linked ) then self:Link( Linked ) end
			end
		end
		Ent.EntityMods.ExtraLink = nil
	end
	
	--Radiator link Pasting
	if (Ent.EntityMods) and (Ent.EntityMods.RadiatorLink) and (Ent.EntityMods.RadiatorLink.entities) then
		local RadiatorLink = Ent.EntityMods.RadiatorLink
		if RadiatorLink.entities and table.Count(RadiatorLink.entities) > 0 then
			for _,ID in pairs(RadiatorLink.entities) do
				local Linked = CreatedEntities[ ID ]
				if IsValid( Linked ) then self:Link( Linked ) end
			end
		end
		Ent.EntityMods.RadiatorLink = nil
	end
	
	//Wire dupe info
	self.BaseClass.PostEntityPaste( self, Player, Ent, CreatedEntities )

end

function ENT:OnRemove()
	if self.Sound then
		self.Sound:Stop()
	end
end
