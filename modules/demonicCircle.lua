local modName = "Demon Portal Range"
local parent = HudMap
local L = LibStub("AceLocale-3.0"):GetLocale("HudMap")
local mod = HudMap:NewModule(modName, "AceEvent-3.0", "AceTimer-3.0")
local db
local demonicCircle = {}
local demonicCircleSummon = GetSpellInfo(48018)
local demonicCircleTeleport = GetSpellInfo(48020)

local options = {
	type = "group",
	name = L["Demonic Circle"],
	args = {
		enable = {
			type = "toggle",
			name = L["Enable"],
			get = function()
				return db.enable
			end,
			set = function(info, v)
				db.enable = v
			end
		}
	}
}

local defaults = {
	profile = {
		enable = true
	}
}

function mod:OnInitialize()
	self.db = parent.db:RegisterNamespace(modName, defaults)
	db = self.db.profile
	parent:RegisterModuleOptions(modName, options, modName)
end

function mod:OnEnable()
	db = self.db.profile
	if (select(2,UnitClass("player")) == "WARLOCK") then
		print("HudMap - Demonic Circle Addon activated - You are a Warlock.");
		self:RegisterEvent("UNIT_AURA")
		self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end

function mod:OnDisable()
	demonicCircle = {}
	if (select(2,UnitClass("player")) == "WARLOCK") then
		self:UnregisterEvent("UNIT_AURA")
		self:UnregisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	end
end

local function MarkDemonicCircleReady()
	demonicCircle.marker:SetColor(0, 1, 0, 1)
end

local function MarkDemonicCircleOnCD()
	demonicCircle.marker:SetColor(1, 0, 0, 1)
end

local function CreateDemonicCircleMarker()
	local x, y = HudMap:GetUnitPosition("player")
	demonicCircle.marker = HudMap:PlaceRangeMarker("radius", x, y, "40yd", nil, 0, 0, 0, 0)
	if GetSpellCooldown(demonicCircleTeleport) == 0 then
		MarkDemonicCircleOnCD()
	else
		MarkDemonicCircleReady()
	end
end

local function RemoveDemonicCircleMarker()
	demonicCircle.marker:Free()
	demonicCircle.marker = nil
end

function mod:DemonicCircleTeleportOffCD()
	demonicCircle.onCooldown = nil
	if demonicCircle.marker then
		MarkDemonicCircleReady()
	end
end

function mod:UNIT_AURA(event, unit)
	if unit ~= "player" then
		return nil
	end
	local _, _, _, _, _, _, demoniceCirclePresent =
		UnitBuff("player", L["Demonic Circle: Summon"])
	if demoniceCirclePresent and not demonicCircle.marker then
		print("Demonic Circle established!")
		CreateDemonicCircleMarker()
	elseif not demoniceCirclePresent and demonicCircle.marker then
		print("Demonic Circle timed out!")
		RemoveDemonicCircleMarker()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(event, unit, name, rank, lineId, spellID)
	if unit == "player" and spellID == 48018 then
		if demonicCircle.marker then
			RemoveDemonicCircleMarker()
		end
		CreateDemonicCircleMarker()
	elseif unit == "player" and spellID == 48020 then
		demonicCircle.onCooldown = 1
		MarkDemonicCircleOnCD()
		self:ScheduleTimer("DemonicCircleTeleportOffCD", 30)
	end
end
