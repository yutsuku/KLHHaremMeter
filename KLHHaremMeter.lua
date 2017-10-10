--! This module references these other modules:
--! table:	raiddata

--! This module is referenced by these other modules:

local mod = klhtm
local me = {}
local update_freq = 0.5
local last_update = 0
local GetTime = GetTime
local UnitName = UnitName

mod.haremmeter = me
me.isenabled = true 
me.pct = 0 

me.gui = {
	["Frame"] = CreateFrame('Frame', nil, KLHTM_Frame),
}
me.gui.texture = me.gui.Frame:CreateTexture(nil, 'ARTWORK')

me.hooks = {
	["KLHTM_TitleButton_OnClick"] = KLHTM_TitleButton_OnClick,
	["KLHTM_OptionsGeneral_OnValueChanged"] = KLHTM_OptionsGeneral_OnValueChanged,
}

function KLHTM_TitleButton_OnClick(btn)
	me.hooks.KLHTM_TitleButton_OnClick(btn)
	
	me.gui.Frame:SetWidth(KLHTM_Frame:GetWidth())
	me.gui.Frame:SetHeight(KLHTM_Frame:GetWidth())
end

function KLHTM_OptionsGeneral_OnValueChanged(value)
	me.hooks.KLHTM_OptionsGeneral_OnValueChanged(value)
	
	me.gui.Frame:SetWidth(KLHTM_Frame:GetWidth())
	me.gui.Frame:SetHeight(KLHTM_Frame:GetWidth())
end

me.gui.Frame:SetWidth(KLHTM_Frame:GetWidth()) -- square, so I don't have to resize textures
me.gui.Frame:SetHeight(KLHTM_Frame:GetWidth())
me.gui.Frame:SetPoint('BOTTOM', KLHTM_Frame, 'TOP', 0, -3)
me.gui.texture:SetAllPoints()

me.gui.Frame:SetScript('OnEvent', function()
	this[event](this)
end)
me.gui.Frame:RegisterEvent('PLAYER_REGEN_DISABLED')
me.gui.Frame:RegisterEvent('PLAYER_REGEN_ENABLED')
me.gui.Frame:RegisterEvent('RAID_ROSTER_UPDATE')
me.gui.Frame:RegisterEvent('PARTY_MEMBERS_CHANGED')

me.gui.Frame.PLAYER_REGEN_DISABLED = function()
	me.isenabled = true
end

me.gui.Frame.PLAYER_REGEN_ENABLED = function()
	me.isenabled = 'false'
	me.gui.Frame:Hide()
end

me.gui.Frame.RAID_ROSTER_UPDATE = function()
	me.playerschanged()
end

me.gui.Frame.PARTY_MEMBERS_CHANGED = function()
	me.playerschanged()
end

me.playerschanged = function()
	local playersRaid = GetNumRaidMembers()
	local playersParty = GetNumPartyMembers()
	local inGroup = false
	
	if playersRaid > 0 then
		inGroup = true
	elseif playersParty > 0 then
		inGroup = true
	end
	
	if not inGroup then
		me.group = false
		me.isenabled = 'false'
		me.gui.Frame:Hide()
	else
		me.group = true
		me.isenabled = true
	end
end

me.onupdate = function()
	if last_update > GetTime()+update_freq then
		return
	end
	me.redraw()
end

me.redraw = function()
	if not UnitAffectingCombat('player') or UnitIsPlayer('target') or not me.group then
		me.gui.Frame:Hide()
		return
	end
	
	local userThreat = mod.table.raiddata[UnitName('player')]
	local data, playerCount, threat100 = KLHTM_GetRaidData()
	local threat = 0
	if userThreat == nil then
		userThreat = 0
	end
	if threat100 == 0 then
		threat = 0
	else
		threat = math.floor(userThreat * 100 / threat100 + 0.5)
	end

	if ( threat and threat ~= 0 ) then
		local path, pct = me.GetThreatStatus(threat)
		if me.pct ~= pct then
			me.gui.texture:SetTexture(path)
			me.pct = pct
		end
		me.gui.Frame:Show()
	else
		me.gui.Frame:Hide()
	end
end

me.GetThreatStatus = function(percentage)
	local path = [[Interface\AddOns\KLHHaremMeter\Images\]]
	
	if not percentage then
		return path..'100-1', 100
	end

	if percentage >= 99 then
		return path..'100-1', 100
	elseif percentage >= 75 then
		return path..'75-'..random(1,3), 75
	elseif percentage >= 50 then
		return path..'50-'..random(1,3), 50
	elseif percentage >= 25 then
		return path..'25-'..random(1,3), 25
	else
		-- below 25%
		return path..'0-'..random(1,3), 1
	end
end