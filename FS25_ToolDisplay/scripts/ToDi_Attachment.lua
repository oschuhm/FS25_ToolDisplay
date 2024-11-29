-- ToDi_Attachment
--
-- Version 2.0
-- Autor Ralf08, LS-Farmers
--
-- Change log:
-- LS19 - V1.0 / 27.01.2019 / Ralf08 / first release -> replacment for LS17 FrontloaderDisplay
-- LS19 - V1.1 / 17.03.2019 / Ralf08 / save to XML; synchronize in multiplayer; event for adjust to zero; on off; tool active deactive; fix for multiplayer onAttached changed to onActivate
-- LS19 - V1.2 / 20.07.2020 / Ralf08 / inserted new in all Attachable; logic for enable the function added
-- LS22 - V2.0 / 01.04.2022 / LS-Farmers / in den LS22 geholt

--local FirstRun
ToDi_Attachment = {}
source(g_currentModDirectory .. "scripts/SetToDiZeroEvent.lua")


function ToDi_Attachment.prerequisitesPresent(specializations)
	return true
end


function ToDi_Attachment.registerFunctions(vehicleType)
    SpecializationUtil.registerFunction(vehicleType, "setToDiZero", ToDi_Attachment.setToDiZero)
end


function ToDi_Attachment.registerEventListeners(vehicleType)
	for i, v in ipairs({"onLoad","onPostLoad","onActivate","onDeactivate","onUpdate","onRegisterActionEvents","saveToXMLFile","onReadStream","onWriteStream"}) do
		SpecializationUtil.registerEventListener(vehicleType, v, ToDi_Attachment)
	end
end


function ToDi_Attachment:onLoad()
	self.ToDi_A = {}
	self.ToDi_A.corAngle = 0
	self.ToDi_A.corHeight = 0
	self.ToDi_A.active = false
	self.ToDi_A.latch = false
	self.ToDi_A.parentVehicle = nil
	self.ToDi_A.xL = 0
	self.ToDi_A.yL = 0
	self.ToDi_A.zL = 0
	self.ToDi_A.dir = 1
	
	
    -- Reference Node for calculationg
    self.ToDi_A.node = self.rootNode
	
	--Dischargeable
	if SpecializationUtil.hasSpecialization(Dischargeable, self.specializations) then
        if SpecializationUtil.hasSpecialization(Shovel, self.specializations) then
            if self.spec_shovel.shovelDischargeInfo.node ~= nil then
               self.ToDi_A.node = self.spec_shovel.shovelDischargeInfo.node
            end
        end
	--stumpCutter
	elseif SpecializationUtil.hasSpecialization(StumpCutter, self.specializations) then
		-- print("ToDi stumpCutter")
		if self.i3dMappings.cutNdeRefFrame ~= nil then
			-- print("ToDi cutNdeRefFrame")
			self.ToDi_A.node = I3DUtil.indexToObject(self.components,self.i3dMappings.cutNdeRefFrame)
		elseif self.i3dMappings.cutNodeRefFrame ~= nil then
			-- print("ToDi cutNodeRefFrame")
			self.ToDi_A.node = I3DUtil.indexToObject(self.components,self.i3dMappings.cutNodeRefFrame)
		elseif self.i3dMappings.cutNode ~= nil then
			-- print("ToDi cutNode")
			self.ToDi_A.node = I3DUtil.indexToObject(self.components,self.i3dMappings.cutNode)
		end
	--TreeSaw
	elseif SpecializationUtil.hasSpecialization(TreeSaw, self.specializations) then
		-- print("ToDi TREESAW")
		if self.spec_treeSaw.cutNode ~= nil then
			-- print("ToDi cutNode")
			self.ToDi_A.node = self.spec_treeSaw.cutNode
		end
	end
	
	local __,yX,__ = localDirectionToLocal(self.ToDi_A.node,self.components[1].node, 1, 0, 0)
	local __,yY,__ = localDirectionToLocal(self.ToDi_A.node,self.components[1].node, 0, 1, 0)
	local __,yZ,__ = localDirectionToLocal(self.ToDi_A.node,self.components[1].node, 0, 0, 1)
	
	yX = math.abs(yX) - 1
	yY = math.abs(yY) - 1
	yZ = math.abs(yZ) - 1
	
	if yX > yY and yX > yZ then
		-- print("xL")
		self.ToDi_A.xL = 1
	elseif yY > yX and yY > yZ then
		-- print("yL")
		self.ToDi_A.yL = 1
	elseif yZ > yX and yZ > yY then
		-- print("zL")
		self.ToDi_A.zL = 1
	else
		-- print("ToDi Error, standard configuration")
		self.ToDi_A.zL = 1
	end


    --activate if attacherJointControl or implement for frontloader/teleloader/skidsteer/wheelloader
	
    --if SpecializationUtil.hasSpecialization(AttacherJointControl, self.specializations) then
	if SpecializationUtil.hasSpecialization(frontloaderAttacher, self.specializations) then
		self.ToDi_A.active = true
    else
        for _, joint in pairs (self.spec_attachable.inputAttacherJoints) do
			if joint.jointType == 6 or joint.jointType == 5 or joint.jointType == 17 or joint.jointType == 12 then
                self.ToDi_A.active = true
                break
            end
        end
    end
end


function ToDi_Attachment:onPostLoad(savegame)
	if savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key = savegame.key ..".ToDi_Attachment"
		
        self.ToDi_A.corAngle = Utils.getNoNil(xmlFile:getInt(key.."#corAngle"),0)
		self.ToDi_A.corHeight = Utils.getNoNil(xmlFile:getFloat(key.."#corHeight"),0)
		self.ToDi_A.active = Utils.getNoNil(xmlFile:getBool(key.."#active"),false)
	end
end


function ToDi_Attachment:onUpdate(dt, isActiveForInput)
	if isActiveForInput and ToDi_Vehicle.ToDi_OnOff and self.ToDi_A.active and self.ToDi_A.parentVehicle ~= nil then
		local x,y,z = localToLocal(self.ToDi_A.node,self.ToDi_A.parentVehicle.components[1].node, 0, 0, 0)
		local xD,yD,zD = localDirectionToLocal(self.ToDi_A.node,self.ToDi_A.parentVehicle.components[1].node, self.ToDi_A.xL, self.ToDi_A.yL, self.ToDi_A.zL)
						
		self.ToDi_A.parentVehicle.ToDi.ToDi_HoT = round((y + self.ToDi_A.corHeight)*100)/100
		self.ToDi_A.parentVehicle.ToDi.ToDi_ang = self.ToDi_A.dir * (round(math.deg(math.atan2(yD,zD))) - 90 + self.ToDi_A.corAngle)
				
		self.ToDi_A.parentVehicle.ToDi.show = true
		self.ToDi_A.latch = true
	elseif self.ToDi_A.latch and self.ToDi_A.parentVehicle ~= nil then	
		self.ToDi_A.parentVehicle.ToDi.show = false
		self.ToDi_A.latch = false
	end
end


function ToDi_Attachment:onActivate()
	self.ToDi_A.parentVehicle = self:getRootVehicle()
	local __,__,z = localToLocal(self.ToDi_A.node,self.ToDi_A.parentVehicle.components[1].node, 0, 0, 0)
	if z > 0 then
		self.ToDi_A.dir = 1
	else
		self.ToDi_A.dir = -1
	end
end


function ToDi_Attachment:onDeactivate()
	if self.ToDi_A.parentVehicle ~= nil and self.ToDi_A.parentVehicle.ToDi ~= nil then
		self.ToDi_A.parentVehicle.ToDi.show = false
	end
	self.ToDi_A.latch = false
	self.ToDi_A.parentVehicle = nil
	self.ToDi_A.dir = 1
end


function ToDi_Attachment:onRegisterActionEvents(isActiveForInputIgnoreSelection)
	local spec = self.spec_ToDi_Attachment
	if self.isClient then
		self:clearActionEventsTable(spec.actionEvents)
		if isActiveForInputIgnoreSelection then
			local actionEventId
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_OnOff, self, ToDi_Attachment.actionEventOnOff, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_SetHeight, self, ToDi_Attachment.actionEventSetHeight, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_SetAngle, self, ToDi_Attachment.actionEventSetAngle, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_Active, self, ToDi_Attachment.actionEventActive, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)

			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_PLUS, self, ToDi_Attachment.actionEventPLUS, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
			
			_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_MINUS, self, ToDi_Attachment.actionEventMINUS, false, true, false, true, nil)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
        end
	end
end


function ToDi_Attachment:saveToXMLFile(xmlFile, key)
	xmlFile:setInt(key.."#corAngle", self.ToDi_A.corAngle)
	xmlFile:setFloat(key.."#corHeight", self.ToDi_A.corHeight)
	xmlFile:setBool(key.."#active", self.ToDi_A.active)
end


function ToDi_Attachment.actionEventSetHeight(self, actionName, inputValue, callbackState, isAnalog)
 	if ToDi_Vehicle.ToDi_OnOff and self.ToDi_A.parentVehicle ~= nil then
		if self.ToDi_A.parentVehicle.ToDi.ToDi_HoT ~= 0 then
			local corHeight = round((self.ToDi_A.corHeight - self.ToDi_A.parentVehicle.ToDi.ToDi_HoT)*100)/100
			self:setToDiZero(self.ToDi_A.corAngle, corHeight, self.ToDi_A.active)
		end
	end
end


function ToDi_Attachment.actionEventSetAngle(self, actionName, inputValue, callbackState, isAnalog)
	if ToDi_Vehicle.ToDi_OnOff and self.ToDi_A.parentVehicle ~= nil then
		if self.ToDi_A.parentVehicle.ToDi.ToDi_ang ~= 0 then
			local corAngle = round(self.ToDi_A.corAngle - (self.ToDi_A.dir*self.ToDi_A.parentVehicle.ToDi.ToDi_ang))
			self:setToDiZero(corAngle, self.ToDi_A.corHeight, self.ToDi_A.active)
		end
	end
end


function ToDi_Attachment.actionEventActive(self, actionName, inputValue, callbackState, isAnalog)
	if ToDi_Vehicle.ToDi_OnOff then
		local active = not self.ToDi_A.active
		self:setToDiZero(self.ToDi_A.corAngle, self.ToDi_A.corHeight, active)
	else
		ToDi_Vehicle.ToDi_OnOff = true
		if not self.ToDi_A.active then
			self:setToDiZero(self.ToDi_A.corAngle, self.ToDi_A.corHeight, true)
		end
	end
end

function ToDi_Attachment.actionEventPLUS(self, actionName, inputValue, callbackState, isAnalog)
	if ToDi_Vehicle.ToDi_OnOff then
		ToDi_Vehicle.ToDi_size = ToDi_Vehicle.ToDi_size * 1.1
	end
end


function ToDi_Attachment.actionEventMINUS(self, actionName, inputValue, callbackState, isAnalog)
	if ToDi_Vehicle.ToDi_OnOff then
		ToDi_Vehicle.ToDi_size = ToDi_Vehicle.ToDi_size / 1.1
	end
end

function ToDi_Attachment.actionEventOnOff(self, actionName, inputValue, callbackState, isAnalog)
	if self.ToDi_A.active then
		ToDi_Vehicle.ToDi_OnOff = not ToDi_Vehicle.ToDi_OnOff
	else
		self:setToDiZero(self.ToDi_A.corAngle, self.ToDi_A.corHeight, true)
		if not ToDi_Vehicle.ToDi_OnOff then
			ToDi_Vehicle.ToDi_OnOff = true
		end
	end
end


function ToDi_Attachment:onReadStream(streamId, connection)
	self.ToDi_A.corAngle = streamReadInt16(streamId)
	self.ToDi_A.corHeight = streamReadInt16(streamId)/100
end


function ToDi_Attachment:onWriteStream(streamId, connection)
    streamWriteInt16(streamId, math.floor(self.ToDi_A.corAngle))
    streamWriteInt16(streamId, math.floor(self.ToDi_A.corHeight*100))
end


function ToDi_Attachment:setToDiZero(corAngle, corHeight, active, noEventSend)
	SetToDiZeroEvent.sendEvent(self, corAngle, corHeight, active, noEventSend)
	
	local spec = self.spec_ToDi_Attachment

	if corAngle ~= nil then
		self.ToDi_A.corAngle = corAngle
	end
	if corHeight ~= nil then
		self.ToDi_A.corHeight = corHeight
	end
	if active ~= nil then
		self.ToDi_A.active = active
	end
end


function round(n)
	return math.floor(n+0.5)
end
