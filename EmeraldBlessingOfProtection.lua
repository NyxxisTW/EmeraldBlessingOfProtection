-- by using this addon you agree to offer your soul to player named Nyxxis at Turtle WoW
-- https://armory.turtle-wow.org/#!/character/Nyxxis
-- https://github.com/NyxxisTW

local Addon = CreateFrame("FRAME")
local DeltaTime = 0
local OldTime = GetTime()
local IconLifeSpan = 0
local BoPTarget = nil
local BoPTargetName = nil
local BoPRank = nil
local RemainingCDPosted = false

local DEFAULT_SCALE = 1.0
local DEFAULT_ALPHA = 0.8
local DEFAULT_PASSWORD = "BoP me now!"
local DEFAULT_RESPONSE = "BoP used!"

EmeraldBlessingOfProtection_Config = {
	Scale = DEFAULT_SCALE,
	Alpha = DEFAULT_ALPHA,
	Password = DEFAULT_PASSWORD,
	Response = DEFAULT_RESPONSE,
}


----- COMMUNICATION -----

local START_COLOR = "\124CFF"
local END_COLOR = "\124r"

local function Print(msg)
	DEFAULT_CHAT_FRAME:AddMessage("[EBoP]: "..tostring(msg))
end

local function Error(msg)
	local COLOR = "FF0000"
	DEFAULT_CHAT_FRAME:AddMessage("[EBoP]: "..START_COLOR..COLOR..tostring(msg)..END_COLOR)
end

----- UTILITY -----

local function SetScale(frame, scale)
	local prevScale = frame:GetScale()
	local point, _, _, xOfs, yOfs = frame:GetPoint()
	frame:SetScale(scale)
	frame:ClearAllPoints()
	frame:SetPoint(point, xOfs / (scale / prevScale), yOfs / (scale / prevScale))
end

local function Round(value, precision)
	return tonumber(string.format("%."..precision.."f", value))
end

local function GetBoPSpell()
	local spell = 1
	local maxRank = -1
	local spellName, rank
	local success = false
	while true do
		spellName, rank = GetSpellName(spell, BOOKTYPE_SPELL)
		if (not spellName) then return end
		rank = tonumber(strsub(rank, 6))
		if (spellName == "Blessing of Protection" and rank > maxRank) then
			success = true
			maxRank = rank
		elseif (maxRank ~= -1) then spell = spell - 1 break end
		spell = spell + 1
	end
	BoPRank = maxRank
	if (success) then return spell end
end

function string.empty(str)
	if (str == nil) then return true end
	if (str == "") then return true end
	local i = 1
	while i <= strlen(str) do
		local char = strsub(str, i, i)
		if (char ~= " ") then
			return false
		end
		i = i + 1
	end
	return true
end

local function NotEnoughMana()
	local mana = UnitMana("player")
	local required = 105
	if (BoPRank == 1) then required = 25
	elseif (BoPRank == 2) then required = 45 end
	return (mana < required)
end

----- COMMANDS -----

local function CommandBoP(msg, msglower)
	if (msglower == "bop" or msglower == "blessing of protection") then
		EmeraldBlessingOfProtection()
		return true
	end
	return false
end

local function CommandShow(msg, msglower)
	if (msglower == "show") then
		EmeraldBlessingOfProtection_BoPIcon:Show()
		EmeraldBlessingOfProtection_BoPIcon:EnableMouse(true)
		return true
	end
	return false
end

local function CommandHide(msg, msglower)
	if (msglower == "hide") then
		EmeraldBlessingOfProtection_BoPIcon:Hide()
		EmeraldBlessingOfProtection_BoPIcon:EnableMouse(false)
		return true
	end
	return false
end

local function CommandScale(msg, msglower)
	if (strsub(msglower, 1, 5) == "scale") then
		local value = string.sub(msg, 7)
		local scale = tonumber(value)
		if (not scale) then
			Error("Invalid value ("..value..").")
			return true
		end 
		SetScale(EmeraldBlessingOfProtection_BoPIcon, scale)
		EmeraldBlessingOfProtection_Config.Scale = scale
		Print("Icon's scale set to \""..START_COLOR.."00AA00"..scale..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandAlpha(msg, msglower)
	if (strsub(msglower, 1, 5) == "alpha") then
		local value = string.sub(msg, 7)
		local alpha = tonumber(value)
		if (not alpha) then
			Error("Invalid value ("..value..").")
			return true
		end
		EmeraldBlessingOfProtection_BoPIcon:SetAlpha(alpha)
		EmeraldBlessingOfProtection_Config.Alpha = alpha
		Print("Icon's alpha channel set to \""..START_COLOR.."00AA00"..alpha..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandPW(msg, msglower)
	local password = nil
	if (strsub(msglower, 1, 14) == "trigger message") then
		password = strsub(msg, 16)
	elseif (strsub(msglower, 1, 10) == "trigger msg") then
		password = strsub(msg, 12)
	elseif (strsub(msglower, 1, 8) == "password") then
		password = strsub(msg, 10)
	elseif (strsub(msglower, 1, 2) == "pw" or strsub(msglower, 1, 2) == "tm") then
		password = strsub(msg, 4)
	end
	if (not password) then return false end
	if (string.empty(password)) then
		Error("Invalid value ("..password..").")
		return true
	end
	EmeraldBlessingOfProtection_Config.Password = password
	Print("Trigger message set to \""..START_COLOR.."00AA00"..password..END_COLOR.."\"")
	return true
end

local function CommandRes(msg, msglower)
	local response = nil
	if (strsub(msglower, 1, 8) == "response") then
		response = strsub(msg, 10)
	elseif (strsub(msglower, 1, 3) == "res") then
		response = strsub(msg, 5)
	end
	if (not response) then return false end
	if (string.empty(response)) then
		Error("Invalid value ("..response..").")
		return true
	end
	EmeraldBlessingOfProtection_Config.Response = response
	Print("Message sent while casting BoP set to \""..START_COLOR.."00AA00"..response..END_COLOR.."\"")
	return true
end

local function CommandPrintPW(msg, msglower)
	if (msglower == "printpw" or
		msglower == "print pw" or
		msglower == "printpassword" or
		msglower == "print password" or
		msglower == "printtm" or
		msglower == "print tm" or
		msglower == "printtriggermsg" or
		msglower == "print trigger msg" or
		msglower == "print triggermsg" or
		msglower == "printtriggermessage" or
		msglower == "print trigger message" or
		msglower == "print triggermessage") then
		Print("Current trigger message: \""..START_COLOR.."00AA00"..EmeraldBlessingOfProtection_Config.Password..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandPrintRes(msg, msglower)
	if (msglower == "printres" or
		msglower == "print res" or
		msglower == "printresponse" or
		msglower == "print response") then
		Print("Current message sent while casting BoP: \""..START_COLOR.."00AA00"..EmeraldBlessingOfProtection_Config.Response..END_COLOR.."\"")
		return true
	end
	return false
end

local function CommandHelp(msg, msglower, force)
	if (msglower == "help" or force) then
		local COLOR = "FFFF99"
		Print("Commands:")
		Print(START_COLOR..COLOR.."/run EmeraldBlessingOfProtection()"..END_COLOR.." or "
			..START_COLOR..COLOR.."/ebop bop"..END_COLOR.." - macro to cast Blessing of Protection.")
		Print(START_COLOR..COLOR.."/ebop show"..END_COLOR.." - sets status of BoP icon to visible and allows mouse dragging.")
		Print(START_COLOR..COLOR.."/ebop hide"..END_COLOR.." - hides BoP icon.")
		Print(START_COLOR..COLOR.."/ebop scale \"number\""..END_COLOR.." - set BoP icon's scale to given number.")
		Print(START_COLOR..COLOR.."/ebop alpha \"number\""..END_COLOR.." - sets BoP icon's alpha channel to given number.")
		Print(START_COLOR..COLOR.."/ebop pw \"text\""..END_COLOR.." - sets text of trigger message.")
		Print(START_COLOR..COLOR.."/ebop res \"text\""..END_COLOR.." - sets text of message sent while casting BoP.")
		Print(START_COLOR..COLOR.."/ebop print pw"..END_COLOR.." - prints in chat current trigger message.")
		Print(START_COLOR..COLOR.."/ebop print res"..END_COLOR.." - prints in chat message sent while casting BoP.")
		return true
	end
	return false
end

SLASH_EMERALDBLESSINGOFPROTECTION1 = "/ebop"
SlashCmdList["EMERALDBLESSINGOFPROTECTION"] = function(msg)
	local msglower = strlower(msg)
	if (CommandBoP(msg, msglower)) then return end
	if (CommandShow(msg, msglower)) then return end
	if (CommandHide(msg, msglower)) then return end
	if (CommandScale(msg, msglower)) then return end
	if (CommandAlpha(msg, msglower)) then return end
	if (CommandPW(msg, msglower)) then return end
	if (CommandRes(msg, msglower)) then return end
	if (CommandPrintPW(msg, msglower)) then return end
	if (CommandPrintRes(msg, msglower)) then return end
	if (CommandHelp(msg, msglower, true)) then return end
end

----- EVENT HANDLING -----

local function OnEvent()
	if (event == "VARIABLES_LOADED") then
		if (not EmeraldBlessingOfProtection_Config.Scale) then
			EmeraldBlessingOfProtection_Config.Scale = DEFAULT_SCALE
		end
		if (not EmeraldBlessingOfProtection_Config.Alpha) then
			EmeraldBlessingOfProtection_Config.Alpha = DEFAULT_ALPHA
		end
		if (not EmeraldBlessingOfProtection_Config.Password) then
			EmeraldBlessingOfProtection_Config.Password = DEFAULT_PASSWORD
		end
		if (not EmeraldBlessingOfProtection_Config.Response) then
			EmeraldBlessingOfProtection_Config.Response = DEFAULT_RESPONSE
		end
		SetScale(EmeraldBlessingOfProtection_BoPIcon, EmeraldBlessingOfProtection_Config.Scale)
		EmeraldBlessingOfProtection_BoPIcon:SetAlpha(EmeraldBlessingOfProtection_Config.Alpha)
	elseif (event == "CHAT_MSG_WHISPER") then
		if (arg1 == EmeraldBlessingOfProtection_Config.Password) then
			local spell = GetBoPSpell()
			if (not spell) then
				SendChatMessage("I don't have this spell.", "WHISPER", "Common", arg2)
				return
			end
			local CD, CDvalue = GetSpellCooldown(spell, BOOKTYPE_SPELL)
			if (CD and CD ~= 0) then
				local remainingCD = CDvalue - (GetTime() - CD)
				SendChatMessage("BoP ready in "..Round(remainingCD, 0).." sec.", "WHISPER", "Common", arg2)
			elseif (GetNumRaidMembers() > 0) then
				local unit
				for i = 1, GetNumRaidMembers() do
					unit = "raid"..i
					if (arg2 == UnitName(unit)) then
						BoPTarget = unit
						BoPTargetName = arg2
						EmeraldBlessingOfProtection_BoPIcon:Show()
						EmeraldBlessingOfProtection_BoPIcon:EnableMouse(false)
						IconLifeSpan = 15
						break
					end
				end
			elseif (GetNumPartyMembers() > 0) then
				for i = 1, GetNumPartyMembers() do
					unit = "party"..i
					if (arg2 == UnitName(unit)) then
						BoPTarget = unit
						BoPTargetName = arg2
						EmeraldBlessingOfProtection_BoPIcon:Show()
						EmeraldBlessingOfProtection_BoPIcon:EnableMouse(false)
						IconLifeSpan = 15
						break
					end
				end
			end
		end
	end
end

----- UPDATE HANDLING -----

local function OnUpdate()
	local newTime = GetTime()
	DeltaTime = newTime - OldTime
	OldTime = newTime
	if (IconLifeSpan > 0) then
		IconLifeSpan = IconLifeSpan - DeltaTime
		if (IconLifeSpan <= 0) then
			EmeraldBlessingOfProtection_BoPIcon:Hide()
			BoPTarget = nil
		end
	end
	local spell = GetBoPSpell()
	if (spell) then
		local start, duration = GetSpellCooldown(spell, BOOKTYPE_SPELL)
		local remaining = (start + duration) - GetTime()
		if (start ~= 0 and BoPTarget and EmeraldBlessingOfProtection_BoPIcon:IsShown()) then
			SendChatMessage(EmeraldBlessingOfProtection_Config.Response, "WHISPER", "Common", BoPTargetName)
			EmeraldBlessingOfProtection_BoPIcon:Hide()
			BoPTarget = nil
		elseif (BoPTargetName and (RemainingCDPosted == false) and (remaining <= 30) and (remaining > 25)) then
			SendChatMessage("BoP ready in 30 sec.", "WHISPER", "Common", BoPTargetName)
			RemainingCDPosted = true
		elseif ((start == 0) and (BoPTargetName) and (not BoPTarget)) then
			SendChatMessage("BoP ready!", "WHISPER", "Common", BoPTargetName)
			BoPTargetName = nil
			RemainingCDPosted = false
		end
	end
end


local function OnLoad()
	if (UnitClass("player") ~= "Paladin") then return end
	Addon:RegisterEvent("VARIABLES_LOADED")
	Addon:RegisterEvent("CHAT_MSG_WHISPER")
	Addon:SetScript("OnEvent", OnEvent)
	Addon:SetScript("OnUpdate", OnUpdate)
end
OnLoad()

----- IN GAME MACRO -----

function EmeraldBlessingOfProtection()
	if (not BoPTarget) then
		local COLOR = "FFAA00"
		Print(START_COLOR..COLOR.."No target."..END_COLOR)
		return
	end
	local spell = GetBoPSpell()
	if (not spell) then
		local COLOR = "FF0000"
		Print(START_COLOR..COLOR.."Spell not found."..END_COLOR)
		return
	end
	if (GetSpellCooldown(spell, BOOKTYPE_SPELL) ~= 0) then
		local COLOR = "FFAA00"
		Print(START_COLOR..COLOR.."Cooldown."..END_COLOR)
		return
	end

	if (NotEnoughMana()) then
		local COLOR = "FFAA00"
		Print(START_COLOR..COLOR.."Not enough mana."..END_COLOR)
		return
	end


	local targetingFriend = UnitIsFriend("player", "target")
	if (targetingFriend) then
		ClearTarget()
	end

	local autoSelfCast = GetCVar("autoSelfCast")
	SetCVar("autoSelfCast", 0)
	CastSpell(spell, BOOKTYPE_SPELL)
	if (not SpellCanTargetUnit(BoPTarget)) then
		SpellStopTargeting()
		SetCVar("autoSelfCast", autoSelfCast)
		return
	end
	SpellTargetUnit(BoPTarget)
	SpellStopTargeting()
	if (targetingFriend) then TargetLastTarget() end
	SetCVar("autoSelfCast", autoSelfCast)
end