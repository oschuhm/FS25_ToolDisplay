-- ToDi_Attachment
--
-- Version 2.0
-- Autor Ralf08, LS-Farmers
--
-- Change log:
-- LS19 - 27.01.2019 / Ralf08 / first release -> replacment for LS17 FrontloaderDisplay
-- LS19 - 17.03.2019 / Ralf08 / on off; smaller font size
-- LS22 - 01.04.2022 / LS-Farmers / ANpassungen für LS22

--local FirstRun
ToDi_Vehicle = {};

ToDi_Vehicle.ToDi_size = 0
ToDi_Vehicle.ToDi_OnOff = true


function ToDi_Vehicle.prerequisitesPresent(specializations)
	-- print("ToDi_Vehicle.prerequisitesPresent(specializations)")
	return true
end;

function ToDi_Vehicle.registerEventListeners(vehicleType)
	-- print("ToDi_Vehicle.registerEventListeners(vehicleType)")
	for i, v in ipairs({"onLoad","onDraw"}) do
		SpecializationUtil.registerEventListener(vehicleType, v, ToDi_Vehicle);
	end;
end;


function ToDi_Vehicle:onLoad()
	-- print("ToDi_Vehicle:onLoad()")
	-- print(self.typeName)
	self.ToDi = {}
	self.ToDi.ToDi_HoT = nil
	self.ToDi.ToDi_ang = nil
	self.ToDi.show = false
	if ToDi_Vehicle.ToDi_size == 0 then
		ToDi_Vehicle.ToDi_size = g_currentMission.hud.speedMeter.cruiseControlTextSize * 1.2
	end;
end;


function ToDi_Vehicle:onDraw(isActiveForInput, isSelectable)
	-- -- print("ToDi_Vehicle:onDraw()"..self.typeName)
	if self.ToDi.show and ToDi_Vehicle.ToDi_OnOff and isSelectable then
		setTextAlignment(RenderText.ALIGN_CENTER)
		setTextColor(1,1,1,1)
		setTextBold(true)
		renderText(0.5,0.01,ToDi_Vehicle.ToDi_size, string.format("%.2f", self.ToDi.ToDi_HoT) .." " .. g_i18n:getText("METRE","FS22_ToolDisplay") .. " / " .. self.ToDi.ToDi_ang .. " " .. g_i18n:getText("DEGREE","FS22_ToolDisplay"));
	end;
end;
