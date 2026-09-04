-- ============================================================
-- NC PERSONAL HUD companion v10 (CET Lua)
-- Right-aligned stacked lines:
--   station (amber) / song / artist / album
-- Apple info comes from media.json; newlines from scraped
-- vanilla track text are honoured as line breaks.
-- ============================================================

local LOG_FILE = "NCPersonal4.log"
local MARK_LOAD = "marker_load.txt"
local MARK_INIT = "marker_init.txt"
local MARK_UPD  = "marker_upd.txt"
local MEDIA_FILE = "media.json"
local STATION_NAME = '94.7 Piers "Piercer" Random Radio'

local info = { title = "", artist = "", album = "", playing = false }
local lastRaw = ""
local accTime = 0.0
local lastReadT = -1.0
local lastLogT = -1.0
local updCount = 0
local vanillaTrack = ""
-- radio power state machine: 0=off,1=on
local curStationName = ""
local prevMounted = false
local prevPocket = false
local auxArmed = false   -- 94.7 selected & music expected to run
local CMD_FILE = "cmd.json"
local cmdCounter = 0
local lastArmT = -10.0
local zHandling = false
local lastNativeT = -10.0
local diagNativeIdx = -999
local nativeOn = false
local musicOn = false
local READ_EVERY = 0.35
local LOG_EVERY = 1.0

local function logf(msg)
    local line = "[" .. os.date("%H:%M:%S") .. "] " .. tostring(msg)
    print("[NCPersonal] " .. line)
    local ok, fh = pcall(io.open, LOG_FILE, "a")
    if ok and fh then
        fh:write(line .. "\n")
        fh:close()
    end
end

local function writeMarker(name)
    local ok, fh = pcall(io.open, name, "w")
    if ok and fh then
        fh:write(os.date("%Y-%m-%d %H:%M:%S") .. " " .. name .. "\n")
        fh:close()
    end
end

writeMarker(MARK_LOAD)

local function mountedVehicle()
    if not GetPlayer() then return nil end
    local ok, veh = pcall(GetMountedVehicle, GetPlayer())
    if not ok or veh == nil then return nil end
    return veh
end

local function pocketRadioOn()
    if not GetPlayer() then return false end
    local ok, pr = pcall(function() return GetPlayer():GetPocketRadio() end)
    if not ok or not pr then return false end
    local ok2, on = pcall(function() return pr.isOn end)
    return ok2 and on == true
end

local function portableModActive()
    local ok, m = pcall(GetMod, "portableRadio")
    if not ok or not m or not m.runtimeData then return false end
    return m.runtimeData.radioActive == true
end

local function readMedia()
    local fh = io.open(MEDIA_FILE, "r")
    if not fh then return end
    local raw = fh:read("*a")
    fh:close()
    if raw == lastRaw then return end
    lastRaw = raw
    local ok, data = pcall(json.decode, raw)
    if not ok or type(data) ~= "table" then
        lastRaw = ""
        return
    end
    info.title = data.title or ""
    info.artist = data.artist or ""
    info.album = data.album or ""
    info.playing = (data.playing == true)
end

-- replace every control char with a space (single-line text)
-- ask the media helper (SMTC) to play/pause via cmd.json
local function sendCmd(cmd)
    cmdCounter = cmdCounter + 1
    local ok, fh = pcall(io.open, CMD_FILE, "w")
    if ok and fh then
        fh:write(json.encode({ cmd = cmd, id = cmdCounter }))
        fh:close()
    end
end

-- pause external music whenever the radio goes off
local function ensureRadioOff()
    -- skip if 94.7 was just selected (popup select also fires pocket events)
    if (accTime - lastArmT) < 1.2 then return end
    sendCmd("pause")
    auxArmed = false
end

-- pause music but keep the HUD (we switched to a vanilla station)
local function pauseMusicOnly()
    if info.playing then
        sendCmd("pause")
    end
    auxArmed = false
end

local function stationDisplay(rec)
    if not rec then return "" end
    local ok, dn = pcall(function() return rec:DisplayName() end)
    if not ok or dn == nil then return "" end
    -- RadioExt-style: localized display name first
    local ok0, loc0 = pcall(function() return GetLocalizedText(dn) end)
    if ok0 and loc0 and tostring(loc0) ~= "" then
        return tostring(loc0)
    end
    local ok2, loc = pcall(function() return GetLocalizedTextByKey(dn) end)
    if ok2 and loc and tostring(loc) ~= "" then
        return tostring(loc)
    end
    local ok3, nm = pcall(function() return Game.NameToString(dn) end)
    if ok3 and nm and tostring(nm) ~= "" then
        local s = tostring(nm)
        if not (s:find("ToCName") or s:find("{")) then return s end
    end
    -- last resort: whatever DisplayName gave, as long as it is not an object dump
    local raw = tostring(dn)
    if raw ~= "" and not (raw:find("ToCName") or raw:find("{")) then
        return raw
    end
    return ""
end

local function oneline(s)
    if type(s) ~= "string" then return "" end
    return (s:gsub("[%c]", " "))
end

-- text scraped from the game: convert EVERY newline flavour to a real line feed
local function keepNewlines(s)
    if type(s) ~= "string" then return "" end
    s = (s:gsub("\\r\\n", "\n"))  -- literal "\r\n"
    s = (s:gsub("\\n", "\n"))     -- literal "\n"
    s = (s:gsub("\r\n", "\n"))    -- real CRLF
    s = (s:gsub("\r", "\n"))      -- lone CR
    s = (s:gsub("\t", " "))       -- tabs -> space
    return s
end

-- convert a track CName to a displayable string; never raw-tostring CName
local function safeTrackName(arg)
    if not arg then return "" end
    local okLoc, loc = pcall(function() return GetLocalizedTextByKey(arg) end)
    if okLoc and loc and tostring(loc) ~= "" then
        return tostring(loc)
    end
    local okNm, nm = pcall(function() return Game.NameToString(arg) end)
    if okNm and nm and tostring(nm) ~= "" then
        local s = tostring(nm)
        if s:find("ToCName") or s:find("{") then return "" end
        return s
    end
    return ""
end

-- split Apple's merged "artist — album" when album field is empty
local function splitInfo()
    local title = oneline(info.title)
    local artist = oneline(info.artist)
    local album = oneline(info.album)
    if album == "" and artist ~= "" then
        local a, b = artist:match("^(.-)%s*—%s*(.+)$")
        if a and b then
            artist, album = a, b
        end
    end
    return title, artist, album
end

-- true if popup's highlighted item is our station (index -2)
local function isAuxItem(ctl)
    if not ctl then return false end
    local ok1, sel = pcall(function() return ctl.selectedItem end)
    if not ok1 or not sel then return false end
    local ok2, sd = pcall(function() return sel:GetStationData() end)
    if not ok2 or not sd then return false end
    local ok3, rec = pcall(function() return sd.record end)
    if not ok3 or not rec then return false end
    local ok4, idx = pcall(function() return rec:Index() end)
    return ok4 and idx == -2
end

local function applyPopupText(ctl)
    if not isAuxItem(ctl) then return end
    if info.title == "" then return end
    local s, a, al = splitInfo()
    local line = s
    if a ~= "" then line = line .. " — " .. a end
    if al ~= "" then line = line .. " — " .. al end
    pcall(function()
        ctl.trackName:SetText(line)
        ctl.trackName:SetVisible(true)
    end)
end

-- The overlay shows whatever station is live:
--   94.7 playing -> full song info; vanilla station -> its name;
--   radio off   -> nothing.
local function overlayState()
    local veh = mountedVehicle()

    -- 94.7 context: full card
    local myStation = (curStationName == STATION_NAME) or auxArmed
    if myStation then
        if info.title ~= "" then
            local s, a, al = splitInfo()
            return { line1 = STATION_NAME, song = s, artist = a, album = al }
        end
        return { line1 = STATION_NAME, song = "", artist = "", album = "" }
    end

    -- native/vanilla station active: track-only (no reliable station name)
    local songline = ""
    if nativeOn and vanillaTrack ~= "" then
        if not (vanillaTrack:find("ToCName") or vanillaTrack:find("{")) then
            songline = vanillaTrack
        end
    end
    if songline == "" then return nil end
    return { line1 = "", song = songline, artist = "", album = "" }
end

local FONT_H_RATIO = 0.022
local REGION_W_RATIO = 0.60
local MARGIN_R = 0.015
local POS_Y_RATIO = 0.52
local AMBER = { 1.00, 0.82, 0.30, 1.00 }
local SONG_C = { 0.95, 0.95, 0.95, 1.00 }
local ART_C  = { 0.62, 0.80, 0.96, 1.00 }
local ALB_C  = { 0.55, 0.72, 0.60, 1.00 }

-- live vehicle station name (covers hotkey/native switching, not just popup)
-- match a station record index to its display name; set cur/aux accordingly
local function applyNativeIndex(idx)
    if type(idx) ~= "number" or idx < 0 or idx > 40 then
        -- invalid / no station
        if idx == -1 and curStationName ~= "" then curStationName = "" end
        return
    end
    local okL, list = pcall(function() return VehiclesManagerDataHelper.GetRadioStations(GetPlayer()) end)
    if not okL or not list then return end
    for _, st in pairs(list) do
        local ok2, rIdx = pcall(function() return st.record:Index() end)
        if ok2 and rIdx == idx then
            local nm = stationDisplay(st.record)
            if nm ~= "" and nm ~= STATION_NAME then
                curStationName = nm
                auxArmed = false
            end
            return
        end
    end
end

local function updateNativeStation()
    -- light polling fallback; primary source is the VehicleRadioEvent hook
    local veh = mountedVehicle()
    if not veh then return end
    if (accTime - lastArmT) < 1.2 then return end
    if (auxArmed or curStationName == STATION_NAME) and info.playing then return end
    local okI, idx = pcall(function() return veh:GetCurrentRadioIndex() end)
    if okI and type(idx) == "number" and idx >= 0 and idx <= 40 then
        applyNativeIndex(idx)
    end
end

local function drawOverlay()
    if not GetPlayer() then return end
    if portableModActive() then return end

    local card = overlayState()
    if not card then return end

    local station = oneline(card.line1)
    local song = card.song or ""
    local artist = card.artist or ""
    local album = card.album or ""
    if station:find("ToCName") or station:find("{") then station = "" end
    if station == "" and song == "" then return end

    local wWidth, wHeight = GetDisplayResolution()

    local baseFont = 16
    local okF, fz = pcall(function() return ImGui.GetFontSize() end)
    if okF and type(fz) == "number" and fz > 0 then baseFont = fz end

    local regW = wWidth * REGION_W_RATIO
    local regH = wHeight * 0.30
    local px = wWidth - wWidth * MARGIN_R - regW
    local py = wHeight * POS_Y_RATIO

    local winFlags = bit32.bor(ImGuiWindowFlags.NoTitleBar,
                               ImGuiWindowFlags.NoSavedSettings,
                               ImGuiWindowFlags.NoFocusOnAppearing)
    local okNB, nb = pcall(function() return ImGuiWindowFlags.NoBackground end)
    if okNB and nb ~= nil then winFlags = bit32.bor(winFlags, nb) end

    ImGui.SetNextWindowPos(px, py)
    ImGui.SetNextWindowSize(regW, regH)
    ImGui.Begin("ncp_radio_hud", true, winFlags)
    ImGui.PushStyleColor(ImGuiCol.WindowBg, 0, 0, 0, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowBorderSize, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 0, 0)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 2)

    local scale = (wHeight * FONT_H_RATIO) / baseFont
    ImGui.SetWindowFontScale(scale)

    -- build right-aligned rows; split embedded newlines
    local rows = { { text = string.upper(station), col = AMBER } }
    local function addRow(text, col)
        if text == "" then return end
        for part in text:gmatch("[^\n]*") do
            if part ~= "" then
                rows[#rows + 1] = { text = part, col = col }
            end
        end
    end
    addRow(song, SONG_C)
    addRow(artist, ART_C)
    addRow(album, ALB_C)

    -- ensure every single line fits the region width
    local maxW = 0
    for _, r in ipairs(rows) do
        local w = ImGui.CalcTextSize(r.text)
        if w > maxW then maxW = w end
    end
    if maxW > regW then
        scale = scale * (regW / maxW)
        ImGui.SetWindowFontScale(scale)
    end

    -- draw right-aligned
    for _, r in ipairs(rows) do
        local w = ImGui.CalcTextSize(r.text)
        ImGui.SetCursorPosX(regW - w)
        ImGui.PushStyleColor(ImGuiCol.Text, r.col[1], r.col[2], r.col[3], r.col[4])
        ImGui.Text(r.text)
        ImGui.PopStyleColor()
    end

    ImGui.End()
    ImGui.PopStyleVar(3)
    ImGui.PopStyleColor()
end

registerForEvent("onInit", function()
    writeMarker(MARK_INIT)
    logf("=== companion v11.2 loaded, station: " .. STATION_NAME)

    local ok1, err1 = pcall(function()
        ObserveAfter("VehicleRadioPopupGameController", "SetTrackName", function(this)
            applyPopupText(this)
        end)
    end)
    logf("hook SetTrackName: " .. (ok1 and "ok" or ("ERR " .. tostring(err1))))

    local ok2, err2 = pcall(function()
        ObserveAfter("VehicleRadioPopupGameController", "SetupData", function(this)
            applyPopupText(this)
        end)
    end)
    logf("hook SetupData: " .. (ok2 and "ok" or ("ERR " .. tostring(err2))))
    -- station select popup
    local okP, errP = pcall(function()
        ObserveAfter("VehicleRadioPopupGameController", "Activate", function(this)
            local idx = -99
            local ok1, sel = pcall(function() return this.selectedItem end)
            if ok1 and sel then
                local ok2, sd = pcall(function() return sel:GetStationData() end)
                if ok2 and sd then
                    local ok3, rec = pcall(function() return sd.record end)
                    if ok3 and rec then
                        local ok4, ix = pcall(function() return rec:Index() end)
                        if ok4 then idx = ix end
                    end
                end
            end
            if idx == -2 then
                auxArmed = true
                curStationName = STATION_NAME
                lastArmT = accTime
                musicOn = true
                logf("popup select: 94.7 (aux armed)")
            elseif idx == -1 then
                curStationName = ""
                musicOn = false
                nativeOn = false
                vanillaTrack = ""
                ensureRadioOff()
                logf("popup select: no station")
            else
                -- vanilla station: pause our music, keep the HUD showing its name
                pauseMusicOnly()
                local okA, rec = pcall(function() return this.selectedItem:GetStationData().record end)
                curStationName = okA and stationDisplay(rec) or "Radio"
                logf("popup select native: idx=" .. tostring(idx) .. " cur=" .. tostring(curStationName))
            end
        end)
    end)
    logf("hook popup activate: " .. (okP and "ok" or ("ERR " .. tostring(errP))))
    -- native radio switching: update HUD station name from the radio event
    local okN, errN = pcall(function()
        ObserveAfter("VehicleComponent", "OnVehicleRadioEvent", function(this, evt)
            if (accTime - lastArmT) < 1.2 then return end
            if not evt then return end
            local ok, idx = pcall(function() return evt.radioIndex end)
            if ok and type(idx) == "number" then
                if idx == -1 then
                    if (auxArmed or curStationName == STATION_NAME) and info.playing then return end
                    curStationName = ""
                    if auxArmed then
                        sendCmd("pause")
                        auxArmed = false
                    end
                elseif idx >= 0 and idx <= 40 then
                    if not ((auxArmed or curStationName == STATION_NAME) and info.playing) then
                        applyNativeIndex(idx)
                    end
                end
            end
        end)
    end)
    logf("hook native radio event: " .. (okN and "ok" or ("ERR " .. tostring(errN))))

    -- Z acts as 94.7 play/pause toggle when our station is the context
    local okZ, errZ = pcall(function()
        ObserveAfter("PocketRadio", "TurnOff", function()
            if zHandling then return end
            nativeOn = false
            vanillaTrack = ""
        end)
    end)
    logf("hook pocket turnoff: " .. (okZ and "ok" or ("ERR " .. tostring(errZ))))

    local okT2, errT2 = pcall(function()
        ObserveAfter("PocketRadio", "TurnOn", function(this)
            if curStationName == STATION_NAME or auxArmed then
                -- silence the native pocket audio that just started
                zHandling = true
                local okP, pr = pcall(function() return GetPlayer():GetPocketRadio() end)
                if okP and pr then
                    pcall(function() pr:TurnOff(true) end)
                end
                zHandling = false
                musicOn = not musicOn
                if musicOn then
                    sendCmd("play")
                    auxArmed = true
                    curStationName = STATION_NAME
                else
                    sendCmd("pause")
                end
            end
        end)
    end)
    logf("hook pocket turnon: " .. (okT2 and "ok" or ("ERR " .. tostring(errT2))))
    -- capture track title pushed for vanilla stations (shown under the station name)
    local okT, errT = pcall(function()
        ObserveAfter("VehicleRadioPopupGameController", "SetTrackName", function(this, trackArg)
            if isAuxItem(this) then return end
            if trackArg then
                local s = keepNewlines(safeTrackName(trackArg))
                local off = (s:find("无曲目") ~= nil) or (s:find("No Track") ~= nil) or (s:find("LocKey") ~= nil)
                if off then
                    nativeOn = false
                    vanillaTrack = ""
                else
                    nativeOn = true
                    vanillaTrack = s
                end
                if s ~= "" then logf("vanilla track sample: " .. s) end
            end
        end)
    end)
    logf("hook vanilla track: " .. (okT and "ok" or ("ERR " .. tostring(errT))))

end)

registerForEvent("onUpdate", function(delta)
    delta = delta or 0.016
    updCount = updCount + 1
    if updCount == 3 then writeMarker(MARK_UPD) end

    accTime = accTime + delta
    if accTime - lastReadT >= READ_EVERY then
        lastReadT = accTime
        readMedia()
    end

    -- clear stale aux flag when we leave the vehicle or fold the pocket radio
    local mv = mountedVehicle()
    local pk = pocketRadioOn()
    if (prevMounted and not mv) or (prevPocket and not pk) then
        auxArmed = false
        nativeOn = false
        vanillaTrack = ""
    end
    prevMounted = (mv ~= nil)
    prevPocket = pk

    if accTime - lastNativeT >= 0.5 then
        lastNativeT = accTime
        updateNativeStation()
    end

    if accTime - lastLogT >= LOG_EVERY then
        lastLogT = accTime
        logf(string.format("status m=%s p=%s aux=%s cur=%q play=%s title=%q",
            tostring(mountedVehicle() ~= nil), tostring(pocketRadioOn()),
            tostring(auxArmed), tostring(curStationName),
            tostring(info.playing), tostring(info.title)))
    end
end)

registerForEvent("onDraw", function()
    drawOverlay()
end)
