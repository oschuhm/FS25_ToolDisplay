-- ToDi_Forklift
--
-- Version 1.0
-- Autor Ralf08, LS-Farmers
--
-- Change log:
-- LS19: V1.0 / 20.07.2020 / Ralf08 / new release; tooldisplay for standard forklift
-- LS22: V1.0 / 01.04.2022 / LSFarmers / in den LS22 geholt


--local FirstRun
ToDi_Forklift = {}
source(g_currentModDirectory .. "scripts/SetToDiZeroEvent.lua")


function ToDi_Forklift.prerequisitesPresent(specializations)
	-- print("ToDi_Forklift.prerequisitesPresent(specializations)")
	return true
end


function ToDi_Forklift.registerFunctions(vehicleType)
	-- print("ToDi_Forklift.registerFunctions")
    SpecializationUtil.registerFunction(vehicleType, "setToDiZero", ToDi_Forklift.setToDiZero)
end


function ToDi_Forklift.registerEventListeners(vehicleType)
	-- print("ToDi_Forklift.registerEventListeners(vehicleType)")
	for i, v in ipairs({"onLoad","onPostLoad","onUpdate","onRegisterActionEvents","saveToXMLFile","onReadStream","onWriteStream"}) do
		SpecializationUtil.registerEventListener(vehicleType, v, ToDi_Forklift)
	end
end


function ToDi_Forklift:onLoad()
	-- print("ToDi_Forklift:onLoad")
	-- print(self.typeName)
	self.ToDi_F = {}
	self.ToDi_F.corAngle = 0
	self.ToDi_F.corHeight = 0
	self.ToDi_F.Fork = false
	self.ToDi_F.active = false
	self.ToDi_F.latch = false
	self.ToDi_F.xL = 0
	self.ToDi_F.yL = 0
	self.ToDi_F.zL = 0
	self.ToDi_F.dir = 1
	
	
    -- active only if reference node and not teleloader
    if SpecializationUtil.hasSpecialization(DynamicMountAttacher, self.specializations) then
        if self.spec_dynamicMountAttacher.dynamicMountAttacherNode ~= nil then
            self.ToDi_F.node = self.spec_dynamicMountAttacher.dynamicMountAttacherNode
            	
            -- teleloader
			local tele = false
            for _, joint in pairs (self.spec_attacherJoints.attacherJoints) do
                if joint.jointType == 4 then
                    tele = true
                    break
                end
            end
            if not tele then
                self.ToDi_F.Fork = true
				self.ToDi_F.active = true

                local __,yX,__ = localDirectionToLocal(self.ToDi_F.node,self.components[1].node, 1, 0, 0)
                local __,yY,__ = localDirectionToLocal(self.ToDi_F.node,self.components[1].node, 0, 1, 0)
                local __,yZ,__ = localDirectionToLocal(self.ToDi_F.node,self.components[1].node, 0, 0, 1)
	
                yX = math.abs(yX) - 1
                yY = math.abs(yY) - 1
                yZ = math.abs(yZ) - 1
	
                if yX > yY and yX > yZ then
                    -- print("xL")
                    self.ToDi_F.xL = 1
                elseif yY > yX and yY > yZ then
                    -- print("yL")
                    self.ToDi_F.yL = 1
                elseif yZ > yX and yZ > yY then
                    -- print("zL")
                    self.ToDi_F.zL = 1
                else
                    -- print("ToDi Error, standard configuration")
                    self.ToDi_F.zL = 1
                end

                local __,__,z = localToLocal(self.ToDi_F.node,self.components[1].node, 0, 0, 0)
                if z > 0 then
                    self.ToDi_F.dir = 1
                else
                    self.ToDi_F.dir = -1
                end
            end
        end
    end
end


function ToDi_Forklift:onPostLoad(savegame)
	-- print("ToDi_Forklift:onPostLoad")
	if self.ToDi_F.Fork and savegame ~= nil then
		local xmlFile = savegame.xmlFile
		local key = savegame.key ..".ToDi_Forklift"
		
		--self.ToDi_F.corAngle = Utils.getNoNil(getXMLInt(xmlFile, key.."#corAngle"),0)
		--self.ToDi_F.corHeight = Utils.getNoNil(getXMLFloat(xmlFile, key.."#corHeight"),0)
		--self.ToDi_F.active = Utils.getNoNil(getXMLBool(xmlFile, key.."#active"),false)

        self.ToDi_F.corAngle = Utils.getNoNil(xmlFile:getInt(key.."#corAngle"),0)
		self.ToDi_F.corHeight = Utils.getNoNil(xmlFile:getFloat(key.."#corHeight"),0)
		self.ToDi_F.active = Utils.getNoNil(xmlFile:getBool(key.."#active"),false)

	end
end


function ToDi_Forklift:onUpdate(dt, isActiveForInput, isActiveForInputIgnoreSelection, isSelected)
	if self.isClient and self.getIsEntered ~= nil and self:getIsEntered() and self:getIsActiveForInput(true, true) and self.ToDi_F.Fork and ToDi_Vehicle.ToDi_OnOff and self.ToDi_F.active then
        -- print("ToDi_Forklift:onUpdate() "..self.typeName.." "..dt) end
        local x,y,z = localToLocal(self.ToDi_F.node,self.components[1].node, 0, 0, 0)
        local xD,yD,zD = localDirectionToLocal(self.ToDi_F.node,self.components[1].node, self.ToDi_F.xL, self.ToDi_F.yL, self.ToDi_F.zL)
						
        self.ToDi.ToDi_HoT = round((y + self.ToDi_F.corHeight)*100)/100
        self.ToDi.ToDi_ang = self.ToDi_F.dir * (round(math.deg(math.atan2(yD,zD))) - 90 + self.ToDi_F.corAngle)
				
        self.ToDi.show = true
        self.ToDi_F.latch = true
		
    elseif self.ToDi_F.latch then	
        self.ToDi.show = false
        self.ToDi_F.latch = false
    end
end


function ToDi_Forklift:onRegisterActionEvents(isActiveForInputIgnoreSelection)
    -- print("ToDi_Forklift:onRegisterActionEvents")
	if self.ToDi_F.Fork then
		local spec = self.spec_ToDi_Forklift
		if self.isClient then
			self:clearActionEventsTable(spec.actionEvents)
			if isActiveForInputIgnoreSelection then
				local actionEventId
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_OnOff, self, ToDi_Forklift.actionEventOnOff, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_SetHeight, self, ToDi_Forklift.actionEventSetHeight, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
				
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_SetAngle, self, ToDi_Forklift.actionEventSetAngle, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
			
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_Active, self, ToDi_Forklift.actionEventActive, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_LOW)
	
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_PLUS, self, ToDi_Forklift.actionEventPLUS, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
				
				_, actionEventId = self:addActionEvent(spec.actionEvents, InputAction.ToDi_MINUS, self, ToDi_Forklift.actionEventMINUS, false, true, false, true, nil)
				g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_VERY_LOW)
			end
		end
	end
end


function ToDi_Forklift:saveToXMLFile(xmlFile, key)
	--print("ToDi_Forklift:saveToXMLFile")
	if self.ToDi_F.Fork then
		xmlFile:setInt(key.."#corAngle", self.ToDi_F.corAngle)
		xmlFile:setFloat(key.."#corHeight", self.ToDi_F.corHeight)
		xmlFile:setBool(key.."#active", self.ToDi_F.active)
	end
end


function ToDi_Forklift.actionEventSetHeight(self, actionName, inputValue, callbackState, isAnalog)
	-- print("ToDi_Forklift.actionEventSetHeight")
 	if ToDi_Vehicle.ToDi_OnOff then
		if self.ToDi.ToDi_HoT ~= 0 then
			local corHeight = round((self.ToDi_F.corHeight - self.ToDi.ToDi_HoT)*100)/100
			self:setToDiZero(self.ToDi_F.corAngle, corHeight, self.ToDi_F.active)
		end
	end
end


function ToDi_Forklift.actionEventSetAngle(self, actionName, inputValue, callbackState, isAnalog)
	-- print("ToDi_Forklift.actionEventSetAngle")
	if ToDi_Vehicle.ToDi_OnOff then
		if self.ToDi.ToDi_ang ~= 0 then
			local corAngle = round(self.ToDi_F.corAngle - (self.ToDi_F.dir*self.ToDi.ToDi_ang))
			self:setToDiZero(corAngle, self.ToDi_F.corHeight, self.ToDi_F.active)
		end
	end
end


function ToDi_Forklift.actionEventActive(self, actionName, inputValue, callbackState, isAnalog)
	-- print("ToDi_Forklift.actionEventSetAngle")
	if ToDi_Vehicle.ToDi_OnOff then
		local active = not self.ToDi_F.active
		self:setToDiZero(self.ToDi_F.corAngle, self.ToDi_F.corHeight, active)
	else
		ToDi_Vehicle.ToDi_OnOff = true
		if not self.ToDi_F.active then
			self:setToDiZero(self.ToDi_F.corAngle, self.ToDi_F.corHeight, true)
		end
	end
end

function ToDi_Forklift.actionEventPLUS(self, actionName, inputValue, callbackState, isAnalog)
	-- print("ToDi_Forklift.actionEventPLUS")
	if ToDi_Vehicle.ToDi_OnOff then
		ToDi_Vehicle.ToDi_size = ToDi_Vehicle.ToDi_size * 1.1
	end
end


function ToDi_Forklift.actionEventMINUS(self, actionName, inputValue, callbackState, isAnalog)
	-- print("ToDi_Forklift.actionEventMINUS")
	if ToDi_Vehicle.ToDi_OnOff then
		ToDi_Vehicle.ToDi_size = ToDi_Vehicle.ToDi_size / 1.1
	end
end

function ToDi_Forklift.actionEventOnOff(self, actionName, inputValue, callbackState, isAnalog)
	-- print("ToolDisplay:ToolDisplay_OnOff")
	if self.ToDi_F.active then
		ToDi_Vehicle.ToDi_OnOff = not ToDi_Vehicle.ToDi_OnOff
	else
		self:setToDiZero(self.ToDi_F.corAngle, self.ToDi_F.corHeight, true)
		if not ToDi_Vehicle.ToDi_OnOff then
			ToDi_Vehicle.ToDi_OnOff = true
		end
	end
end


function ToDi_Forklift:onReadStream(streamId, connection)
    -- print("ToDi_Forklift:onReadStream")
	self.ToDi_F.corAngle = streamReadInt16(streamId)
	self.ToDi_F.corHeight = streamReadInt16(streamId)/100
end


function ToDi_Forklift:onWriteStream(streamId, connection)
	-- print("ToDi_Forklift:onWriteStream")
    streamWriteInt16(streamId, math.floor(self.ToDi_F.corAngle))
    streamWriteInt16(streamId, math.floor(self.ToDi_F.corHeight*100))
end


function ToDi_Forklift:setToDiZero(corAngle, corHeight, active, noEventSend)
	-- print("ToDi_Forklift:setToDiZero")
	SetToDiZeroEvent.sendEvent(self, corAngle, corHeight, active, noEventSend)
	
	local spec = self.spec_ToDi_Forklift

	if corAngle ~= nil then
		self.ToDi_F.corAngle = corAngle
	end
	if corHeight ~= nil then
		self.ToDi_F.corHeight = corHeight
	end
	if active ~= nil then
		self.ToDi_F.active = active
	end
end


function round(n)
	-- print("round")
	return math.floor(n+0.5)
end
