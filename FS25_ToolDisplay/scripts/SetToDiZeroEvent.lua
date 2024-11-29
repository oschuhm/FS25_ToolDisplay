-- SetToDiZeroEvent
--
-- Version 1.0
-- Autor Ralf08
--
-- Change log:
-- V1.0 / 17.03.2019 / Ralf08 / first release -> event for adjust to zero



SetToDiZeroEvent = {}
SetToDiZeroEvent_mt = Class(SetToDiZeroEvent, Event)
InitEventClass(SetToDiZeroEvent, "SetToDiZeroEvent")


function SetToDiZeroEvent:emptyNew()
    --print("SetToDiZeroEvent:emptyNew")
	local self = Event.new(SetToDiZeroEvent_mt)
	self.className="SetToDiZeroEvent"
    --print("SetToDiZeroEvent:emptyNew finish")
    return self
end


function SetToDiZeroEvent:new(vehicle, corAngle, corHeight, active)
    --print("SetToDiZeroEvent:new")
	local self = SetToDiZeroEvent:emptyNew()
	self.vehicle = vehicle
    self.corAngle = corAngle
    self.corHeight = corHeight
	self.active = active
    --print("SetToDiZeroEvent:new finish")
    return self
end


function SetToDiZeroEvent:readStream(streamId, connection)
	--print("SetToDiZeroEvent:readStream")
    self.vehicle = NetworkUtil.readNodeObject(streamId)
    self.corAngle = streamReadInt16(streamId)
    self.corHeight = streamReadInt16(streamId)/100
	self.active = streamReadBool(streamId)
    self:run(connection)
end


function SetToDiZeroEvent:writeStream(streamId, connection)
    --print("SetToDiZeroEvent:writeStream")
	NetworkUtil.writeNodeObject(streamId, self.vehicle)
    streamWriteInt16(streamId, self.corAngle)
    streamWriteInt16(streamId, self.corHeight*100)
	streamWriteBool(streamId, self.active)
end


function SetToDiZeroEvent:run(connection)
	--print("SetToDiZeroEvent:run")
	if not connection:getIsServer() then
        g_server:broadcastEvent(SetToDiZeroEvent:new(self.vehicle, self.corAngle, self.corHeight, self.active), nil, connection, self.vehicle)
	end
	self.vehicle:setToDiZero(self.corAngle, self.corHeight, self.active, true)
end

function SetToDiZeroEvent.sendEvent(vehicle, corAngle, corHeight, active, noEventSend)
	--print("SetToDiZeroEvent.sendEvent")
    if noEventSend == nil or noEventSend == false then
        if g_server ~= nil then
            g_server:broadcastEvent(SetToDiZeroEvent:new(vehicle, corAngle, corHeight, active), nil, nil, vehicle);
        else
            g_client:getServerConnection():sendEvent(SetToDiZeroEvent:new(vehicle, corAngle, corHeight, active));
        end;
    end;
    --print("SetToDiZeroEvent.sendEvent finish")
end