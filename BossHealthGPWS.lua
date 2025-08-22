local ADDON_NAME = "BossHealthGPWS"

-- Saved setting
BossHealthGPWS_SoundEnabled = BossHealthGPWS_SoundEnabled ~= false -- default true

-- Percent thresholds to announce
local THRESHOLDS = {50, 40, 30, 20, 10, 5}

local BOSSES = {
    -- Nerub-ar Palace
	[2902] = true, [2917] = true, [2898] = true, [2918] = true,
    [2919] = true, [2920] = true, [2921] = true, [2922] = true,
	-- Liberation of Undermine
    [3009] = true, [3010] = true, [3011] = true, [3012] = true,
    [3013] = true, [3014] = true, [3015] = true, [3016] = true,
    -- Manaforge Omega
    [3129] = true, [3131] = true, [3130] = true, [3132] = true,
    [3122] = true, [3133] = true, [3134] = true, [3135] = true,
}

local currentEncounter = nil
local seenThresholds = {}

local function GetHealthPercent(unit)
    local maxHP = UnitHealthMax(unit)
    if not maxHP or maxHP <= 0 then return 100 end
    local curHP = UnitHealth(unit)
    local pct = math.floor((curHP / maxHP) * 100 + 0.5)
    return math.max(0, math.min(100, pct))
end

local function Announce(threshold)
    local msg = string.format("Boss at %d%%", threshold)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[HP]|r " .. msg)
    if BossHealthGPWS_SoundEnabled then
        PlaySoundFile("Interface\\AddOns\\BossHealthGPWS\\" .. threshold .. ".mp3", "master")
    end
end

local function CheckBossUnits()
    if not currentEncounter then return end
    for _, threshold in ipairs(THRESHOLDS) do
        if not seenThresholds[threshold] then
            for i = 1, 5 do
                local unit = "boss" .. i
                if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDeadOrGhost(unit) then
                    local hp = GetHealthPercent(unit)
                    if hp <= threshold then
                        seenThresholds[threshold] = true
                        Announce(threshold)
                        return
                    end
                end
            end
        end
    end
end

local function OnEncounterStart(_, encounterID)
    if BOSSES[encounterID] then
		if BossHealthGPWS_SoundEnabled then
			PlaySoundFile("Interface\\AddOns\\BossHealthGPWS\\plus100.mp3", "master")
		end
        currentEncounter = encounterID
        wipe(seenThresholds)
    end
end

local function OnEncounterEnd(_, encounterID)
    if currentEncounter == encounterID then
        currentEncounter = nil
        wipe(seenThresholds)
    end
end

-- Slash command
SLASH_GPWS1 = "/gpws"
SlashCmdList["GPWS"] = function(msg)
    msg = msg and msg:lower()
    if msg == "on" then
        BossHealthGPWS_SoundEnabled = true
        print("|cff00ff00[GPWS]|r Sound alerts |cff00ff00ENABLED|r")
    elseif msg == "off" then
        BossHealthGPWS_SoundEnabled = false
        print("|cff00ff00[GPWS]|r Sound alerts |cffff0000DISABLED|r")
    elseif msg == "help" then
        print("|cff00ff00[GPWS]|r Commands:")
        print("  |cff00ff00/gpws|r           - Toggle sound alerts on/off")
        print("  |cff00ff00/gpws on|r        - Enable sound alerts")
        print("  |cff00ff00/gpws off|r       - Disable sound alerts")
        print("  |cff00ff00/gpws help|r      - Show this help message")
    else
        BossHealthGPWS_SoundEnabled = not BossHealthGPWS_SoundEnabled
        if BossHealthGPWS_SoundEnabled then
            print("|cff00ff00[GPWS]|r Sound alerts |cff00ff00ENABLED|r")
        else
            print("|cff00ff00[GPWS]|r Sound alerts |cffff0000DISABLED|r")
        end
    end
end

-- Event handling
local f = CreateFrame("Frame")
f:RegisterEvent("ENCOUNTER_START")
f:RegisterEvent("ENCOUNTER_END")
f:RegisterEvent("UNIT_HEALTH")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "ENCOUNTER_START" then
        OnEncounterStart(_, arg1, ...)
    elseif event == "ENCOUNTER_END" then
        OnEncounterEnd(_, arg1, ...)
    elseif event == "UNIT_HEALTH" and currentEncounter then
        local unit = arg1
        if unit and unit:match("^boss%d$") then
            CheckBossUnits()
        end
    elseif event == "ADDON_LOADED" and arg1 == ADDON_NAME then
        if BossHealthGPWS_SoundEnabled then
            print("|cff00ff00[GPWS]|r Sound alerts are currently |cff00ff00ENABLED|r")
        else
            print("|cff00ff00[GPWS]|r Sound alerts are currently |cffff0000DISABLED|r")
        end
    end
end)