-- name: Fishing DX
-- description: Fishing DX by CrypticTM. Chest shops, standing cast, pole_geo Gold rod.
-- deluxe: true


local VERSION = "1.1.0"

local function sfx(sound, m)
    if sound == nil or m == nil or m.marioObj == nil then
        return
    end
    play_sound(sound, m.marioObj.header.gfx.cameraToObject)
end

local MAX_COINS = 10000

-- Gold rod: actors/pole (pole_geo). Loaded via smlua_model_util_get_id at runtime.
local E_MODEL_POLE_GEO = nil
local function load_gold_pole_model()
    if E_MODEL_POLE_GEO ~= nil then
        return E_MODEL_POLE_GEO
    end
    if smlua_model_util_get_id ~= nil then
                local names = {
            "pole_geo",
            "pole",
            "fishingpole_g_geo",
            "fishingpole_g",
        }
        for i = 1, #names do
            local id = smlua_model_util_get_id(names[i])
            if id ~= nil and id ~= 0 then
                if E_MODEL_NONE == nil or id ~= E_MODEL_NONE then
                    E_MODEL_POLE_GEO = id
                    return E_MODEL_POLE_GEO
                end
            end
        end
    end
    if E_MODEL_WOODEN_POST ~= nil then
        E_MODEL_POLE_GEO = E_MODEL_WOODEN_POST
    else
        E_MODEL_POLE_GEO = E_MODEL_METAL_BOX
    end
    return E_MODEL_POLE_GEO
end

-- Rod tiers. cost = wallet to unlock. luck = rare bias. Gold uses pole_geo.
local ROD_TIERS = {
    {name = "Wood",      body = E_MODEL_BREAKABLE_BOX_SMALL, bx = 0.06, by = 0.72, bz = 0.06, cost = 0,    luck = 0},
    {name = "Metal",     body = E_MODEL_METAL_BOX,           bx = 0.045, by = 0.78, bz = 0.045, cost = 40, luck = 6},
    {name = "Gold",      body = nil,                         bx = 0.20, by = 0.20, bz = 0.20, cost = 100,  luck = 14, useGoldPole = true},
    {name = "Master",    body = E_MODEL_METAL_BOX,           bx = 0.05, by = 0.82, bz = 0.05, cost = 200,  luck = 25},
    {name = "Legendary", body = E_MODEL_METAL_BOX,           bx = 0.055, by = 0.88, bz = 0.055, cost = 1500, luck = 40},
}

local rodTier = 1

local COOK_BOOST_FRAMES = 3000
local cookBoostTimer = 0
local fireObjs = {}
local fireSpawned = false
local fireLevel = -1
local cookPrompt = false
local cookCooldown = 0

local STATE_IDLE = 0
local STATE_CASTING = 1
local STATE_WAITING = 2
local STATE_BITE = 3
local STATE_MINIGAME = 4
local STATE_CATCH = 5

local FISH = {
    {id = 1,  name = "Cheep Cheep",    rarity = 28, value = 5,   minSize = 18, maxSize = 32, minWeight = 1.2, maxWeight = 3.8, difficulty = 1},
    {id = 2,  name = "Blooper",        rarity = 16, value = 12,  minSize = 25, maxSize = 45, minWeight = 2.5, maxWeight = 7.0, difficulty = 1},
    {id = 3,  name = "Goomba Fish",    rarity = 12, value = 8,   minSize = 12, maxSize = 22, minWeight = 0.6, maxWeight = 1.8, difficulty = 1},
    {id = 4,  name = "Unagi",          rarity = 11, value = 22,  minSize = 40, maxSize = 70, minWeight = 4.0, maxWeight = 12.0, difficulty = 2},
    {id = 5,  name = "Spiny Cheep",    rarity = 9,  value = 28,  minSize = 22, maxSize = 38, minWeight = 2.0, maxWeight = 5.5, difficulty = 2},
    {id = 6,  name = "Bob-omb Bass",   rarity = 7,  value = 35,  minSize = 28, maxSize = 48, minWeight = 3.0, maxWeight = 9.0, difficulty = 2},
    {id = 7,  name = "Star Fish",      rarity = 5,  value = 55,  minSize = 15, maxSize = 28, minWeight = 0.8, maxWeight = 2.2, difficulty = 3},
    {id = 8,  name = "Bubba",          rarity = 3,  value = 90,  minSize = 55, maxSize = 95, minWeight = 15.0, maxWeight = 40.0, difficulty = 3},
    {id = 9,  name = "Golden Cheep",   rarity = 2,  value = 120, minSize = 20, maxSize = 36, minWeight = 2.0, maxWeight = 5.0, difficulty = 3},
    {id = 10, name = "Giant Unagi",            rarity = 2,  value = 150, minSize = 50, maxSize = 90, minWeight = 20.0, maxWeight = 45.0, difficulty = 3},
    {id = 11, name = "Onion Sardine",  rarity = 10, value = 18,  minSize = 10, maxSize = 20, minWeight = 0.4, maxWeight = 1.5, difficulty = 1, onlyLevel = LEVEL_CASTLE_GROUNDS},
    -- CCM bottom pond + also catchable on Peach's Slide (no VOID there for these)
    {id = 12, name = "Ice Minnow",     rarity = 14, value = 15,  minSize = 14, maxSize = 26, minWeight = 0.8, maxWeight = 2.4, difficulty = 1, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    {id = 13, name = "Penguin Puffer", rarity = 6,  value = 48,  minSize = 30, maxSize = 52, minWeight = 4.0, maxWeight = 11.0, difficulty = 2, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    {id = 14, name = "Frosty Unagi",   rarity = 4,  value = 75,  minSize = 45, maxSize = 80, minWeight = 8.0, maxWeight = 22.0, difficulty = 3, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    -- VOID fish: Peach's Slide only. Rare, hardest, decays in inventory if not sold in time.
    {id = 15, name = "VOID Fish",      rarity = 3,  value = 220, minSize = 40, maxSize = 70, minWeight = 12.0, maxWeight = 35.0, difficulty = 5, onlyLevel = LEVEL_PSS, isVoid = true, decayFrames = 5400},
    -- Fire fish: Lethal Lava Land only (near lava)
    {id = 16, name = "Magma Cheep",    rarity = 16, value = 20,  minSize = 16, maxSize = 30, minWeight = 1.0, maxWeight = 3.5, difficulty = 1, onlyLevel = LEVEL_LLL},
    {id = 17, name = "Podoboo Piranha",rarity = 10, value = 32,  minSize = 20, maxSize = 36, minWeight = 1.5, maxWeight = 5.0, difficulty = 2, onlyLevel = LEVEL_LLL},
    {id = 18, name = "Lava Eel",       rarity = 7,  value = 55,  minSize = 35, maxSize = 65, minWeight = 4.0, maxWeight = 14.0, difficulty = 2, onlyLevel = LEVEL_LLL},
    {id = 19, name = "Flame Bass",     rarity = 4,  value = 85,  minSize = 28, maxSize = 50, minWeight = 3.5, maxWeight = 10.0, difficulty = 3, onlyLevel = LEVEL_LLL},
    {id = 20, name = "Blargg",         rarity = 2,  value = 140, minSize = 50, maxSize = 90, minWeight = 18.0, maxWeight = 42.0, difficulty = 4, onlyLevel = LEVEL_LLL},
    -- Tower of the Wing Cap: cloudy edge pool (left of red box)
    {id = 21, name = "Angel Fish",     rarity = 14, value = 22,  minSize = 16, maxSize = 28, minWeight = 0.8, maxWeight = 2.5, difficulty = 1, onlyLevel = LEVEL_TOTWC},
    {id = 22, name = "Angel Swimmer",  rarity = 9,  value = 38,  minSize = 22, maxSize = 40, minWeight = 1.5, maxWeight = 4.5, difficulty = 2, onlyLevel = LEVEL_TOTWC},
    {id = 23, name = "Glory Fish",     rarity = 5,  value = 70,  minSize = 25, maxSize = 45, minWeight = 2.0, maxWeight = 6.0, difficulty = 3, onlyLevel = LEVEL_TOTWC},
    {id = 24, name = "Sunmo-rae",      rarity = 2,  value = 160, minSize = 30, maxSize = 55, minWeight = 3.0, maxWeight = 9.0, difficulty = 4, onlyLevel = LEVEL_TOTWC},
}

-- Tiny-Huge Island uses a random mix of these existing fish (by id)
local THI_FISH_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10}
local function is_thi_pool_fish(fishData)
    if fishData == nil then return false end
    for i = 1, #THI_FISH_IDS do
        if THI_FISH_IDS[i] == fishData.id then
            return true
        end
    end
    return false
end

local LEVEL_NAMES = {
    [LEVEL_CASTLE_GROUNDS] = "Castle Grounds",
    [LEVEL_CCM] = "Cool Cool Mountain",
    [LEVEL_PSS] = "Peach Secret Slide",
    [LEVEL_LLL] = "Lethal Lava Land",
    [LEVEL_TOTWC] = "Tower of the Wing Cap",
    [LEVEL_THI] = "Tiny-Huge Island",
    [LEVEL_BOB] = "Bob-omb Battlefield",
    [LEVEL_JRB] = "Jolly Roger Bay",
    [LEVEL_DDD] = "Dire Dire Docks",
}

local function fish_location_text(f)
    if f == nil then return "Unknown" end
    if f.isVoid then
        return "Peach Slide only (sell fast)"
    end
    if f.onlyLevels ~= nil then
        local parts = {}
        for i = 1, #f.onlyLevels do
            local n = LEVEL_NAMES[f.onlyLevels[i]] or ("Level " .. tostring(f.onlyLevels[i]))
            table.insert(parts, n)
        end
        return table.concat(parts, " / ")
    end
    if f.onlyLevel ~= nil then
        return LEVEL_NAMES[f.onlyLevel] or ("Level " .. tostring(f.onlyLevel))
    end
    -- general pool: anywhere with water, plus THI shore mix
    if is_thi_pool_fish(f) then
        return "Any water + THI shores"
    end
    return "Any water stage"
end

local function build_fish_map_lines()
    local lines = {}
    table.insert(lines, {title = true, text = "FISH LOCATION MAP"})
    table.insert(lines, {title = false, text = "Where each fish can be caught"})
    for i = 1, #FISH do
        local f = FISH[i]
        local loc = fish_location_text(f)
        local tag = ""
        if f.isVoid then tag = " [VOID]" end
        table.insert(lines, {
            title = false,
            text = string.format("%s%s", f.name, tag),
            sub = string.format("$%d  |  %s", f.value or 0, loc),
        })
    end
    return lines
end

local FISH_MAP_LINES = nil
local function get_fish_map_lines()
    if FISH_MAP_LINES == nil then
        FISH_MAP_LINES = build_fish_map_lines()
    end
    return FISH_MAP_LINES
end

local function open_fish_map()
    showFishMap = true
    showInventory = false
    fishMapPage = 1
end

local function close_fish_map()
    showFishMap = false
end

local function toggle_fish_map()
    if showFishMap then
        close_fish_map()
    else
        open_fish_map()
    end
end



local MAX_BAIT = 40
local MAX_INVENTORY = 50
local BAIT_AMOUNTS = {1, 5, 10}
local baitBuyIndex = 1
local baitTypeIndex = 1

local BAIT_TYPES = {
    {id = 1, name = "Worm",         cost = 5,  luck = 0,  waitMul = 1.00, desc = "Basic. Steady bites."},
    {id = 2, name = "Cricket",      cost = 12, luck = 8,  waitMul = 0.85, desc = "Faster bites, better luck."},
    {id = 3, name = "Super Mushroom", cost = 18, luck = 14, waitMul = 0.75, desc = "Rare fish magnet."},
    {id = 4, name = "Golden Lure",  cost = 30, luck = 28, waitMul = 0.60, desc = "Top tier rare hunter."},
}

local function get_bait_type(id)
    for i = 1, #BAIT_TYPES do
        if BAIT_TYPES[i].id == id then return BAIT_TYPES[i] end
    end
    return BAIT_TYPES[1]
end

local inventory = {}
local showInventory = false
local showFishMap = false
local fishMapPage = 1
local FISH_MAP_PAGE_SIZE = 8
local shopPrompt = false
local shopCooldown = 0
local catchStreak = 0
local catchDisplayTimer = 0
local lastCaught = {name = "", size = 0, weight = 0, value = 0, isVoid = false}
local currentDifficulty = 1
local biteFlash = 0
local reelPulse = 0
local lockedPos = nil

local personalRecord = {name = "", size = 0, weight = 0}
local prBannerTimer = 0
local prBannerData = {player = "", name = "", size = 0, weight = 0}

local progressLoaded = false
local saveCooldown = 0

local function storage_save_num(key, value)
    if mod_storage_save_number ~= nil then
        mod_storage_save_number(key, value or 0)
    elseif mod_storage_save ~= nil then
        mod_storage_save(key, tostring(value or 0))
    end
end

local function storage_load_num(key, default)
    if mod_storage_load_number ~= nil then
        local v = mod_storage_load_number(key)
        if v ~= nil then return v end
    end
    if mod_storage_load ~= nil then
        local s = mod_storage_load(key)
        if s ~= nil and s ~= "" then
            local n = tonumber(s)
            if n ~= nil then return n end
        end
    end
    return default
end

local function storage_save_str(key, value)
    if mod_storage_save ~= nil then
        mod_storage_save(key, value or "")
    end
end

local function storage_load_str(key, default)
    if mod_storage_load ~= nil then
        local s = mod_storage_load(key)
        if s ~= nil then return s end
    end
    return default or ""
end

local function serialize_inventory()
    local parts = {}
    for i = 1, #inventory do
        local r = inventory[i]
        if r ~= nil then
            local name = tostring(r.name or "Fish"):gsub("[|;]", "")
            local voidFlag = (r.isVoid and 1) or 0
            local decayLeft = r.decayLeft or 0
            table.insert(parts, string.format(
                "%d|%s|%.1f|%.1f|%d|%d|%d",
                r.id or 0, name, r.size or 0, r.weight or 0, r.value or 0, voidFlag, decayLeft
            ))
        end
    end
    return table.concat(parts, ";")
end

local function deserialize_inventory(str)
    inventory = {}
    if str == nil or str == "" then return end
    for row in string.gmatch(str, "[^;]+") do
        local id, name, size, weight, value, voidFlag, decayLeft = string.match(
            row, "^(%d+)|([^|]+)|([%d%.]+)|([%d%.]+)|(%d+)|(%d*)|(%d*)$"
        )
        if id == nil then
            -- backward compat with old 5-field format
            id, name, size, weight, value = string.match(row, "^(%d+)|([^|]+)|([%d%.]+)|([%d%.]+)|(%d+)$")
        end
        if id ~= nil then
            local rec = {
                id = tonumber(id) or 0,
                name = name or "Fish",
                size = tonumber(size) or 0,
                weight = tonumber(weight) or 0,
                value = tonumber(value) or 0,
            }
            if voidFlag ~= nil and voidFlag ~= "" and tonumber(voidFlag) == 1 then
                rec.isVoid = true
                rec.decayLeft = tonumber(decayLeft) or 5400
            end
            table.insert(inventory, rec)
        end
    end
end

local function save_progress()
    local pst = gPlayerSyncTable[0]
    if pst == nil then return end
    storage_save_num("fdx_wallet", pst.wallet or 0)
    storage_save_num("fdx_bait1", pst.bait1 or 0)
    storage_save_num("fdx_bait2", pst.bait2 or 0)
    storage_save_num("fdx_bait3", pst.bait3 or 0)
    storage_save_num("fdx_bait4", pst.bait4 or 0)
    storage_save_num("fdx_activeBait", pst.activeBait or 1)
    storage_save_num("fdx_rodTier", pst.rodTier or 1)
    storage_save_num("fdx_rodMax", pst.rodMaxUnlocked or 1)
    storage_save_str("fdx_inv", serialize_inventory())
    storage_save_str("fdx_pr_name", personalRecord.name or "")
    storage_save_num("fdx_pr_size", personalRecord.size or 0)
    storage_save_num("fdx_pr_weight", personalRecord.weight or 0)
    storage_save_num("fdx_saved", 1)
end

local function queue_save()
    saveCooldown = 30
end

local function load_progress_into_pst(pst)
    if progressLoaded or pst == nil then return end
    progressLoaded = true

    local hasSave = storage_load_num("fdx_saved", 0)
    if hasSave ~= 1 then
        return
    end

    pst.wallet = storage_load_num("fdx_wallet", pst.wallet or 0)
    if pst.wallet > MAX_COINS then pst.wallet = MAX_COINS end
    if pst.wallet < 0 then pst.wallet = 0 end

    pst.bait1 = storage_load_num("fdx_bait1", pst.bait1 or 0)
    pst.bait2 = storage_load_num("fdx_bait2", pst.bait2 or 0)
    pst.bait3 = storage_load_num("fdx_bait3", pst.bait3 or 0)
    pst.bait4 = storage_load_num("fdx_bait4", pst.bait4 or 0)
    pst.activeBait = storage_load_num("fdx_activeBait", 1)
    if pst.activeBait < 1 or pst.activeBait > #BAIT_TYPES then
        pst.activeBait = 1
    end

    pst.rodTier = storage_load_num("fdx_rodTier", 1)
    pst.rodMaxUnlocked = storage_load_num("fdx_rodMax", pst.rodTier or 1)
    if pst.rodTier < 1 then pst.rodTier = 1 end
    if pst.rodTier > #ROD_TIERS then pst.rodTier = #ROD_TIERS end
    if pst.rodMaxUnlocked < pst.rodTier then pst.rodMaxUnlocked = pst.rodTier end
    if pst.rodMaxUnlocked > #ROD_TIERS then pst.rodMaxUnlocked = #ROD_TIERS end

    deserialize_inventory(storage_load_str("fdx_inv", ""))
    personalRecord.name = storage_load_str("fdx_pr_name", "")
    personalRecord.size = storage_load_num("fdx_pr_size", 0)
    personalRecord.weight = storage_load_num("fdx_pr_weight", 0)

    pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
    rodTier = pst.rodTier
end

-- Equip a bait type by id. Works even after rejoin if counts were saved.
local function equip_bait(pst, baitId, silent)
    if pst == nil then return false end
    baitId = math.floor(tonumber(baitId) or 1)
    if baitId < 1 or baitId > #BAIT_TYPES then return false end
    local n = 0
    if baitId == 1 then n = pst.bait1 or 0
    elseif baitId == 2 then n = pst.bait2 or 0
    elseif baitId == 3 then n = pst.bait3 or 0
    elseif baitId == 4 then n = pst.bait4 or 0
    end
    if n <= 0 then
        if not silent then
            local bt = get_bait_type(baitId)
            djui_chat_message_create("No " .. bt.name .. " left. Buy some at a Bait Shop.")
        end
        return false
    end
    pst.activeBait = baitId
    queue_save()
    if not silent then
        local bt = get_bait_type(baitId)
        djui_chat_message_create("Equipped bait: " .. bt.name .. " (x" .. tostring(n) .. ")")
    end
    return true
end

-- If active bait is empty after load/consume, auto-switch to any type with stock
local function fix_active_bait(pst)
    if pst == nil then return end
    local id = pst.activeBait or 1
    local function count(i)
        if i == 1 then return pst.bait1 or 0 end
        if i == 2 then return pst.bait2 or 0 end
        if i == 3 then return pst.bait3 or 0 end
        if i == 4 then return pst.bait4 or 0 end
        return 0
    end
    if count(id) > 0 then
        pst.activeBait = id
        return
    end
    for i = 1, #BAIT_TYPES do
        if count(BAIT_TYPES[i].id) > 0 then
            pst.activeBait = BAIT_TYPES[i].id
            return
        end
    end
    pst.activeBait = 1
end

-- Session-wide largest catch (synced). seq bumps so every client shows banner/chat.
local lastSeenSessionSeq = 0
local lastSeenHotSeq = 0
local hotBannerTimer = 0
local hotBannerText = ""

local HOT_STAGE_POOL = {
    {level = LEVEL_BOB,            name = "Bob-omb Battlefield"},
    {level = LEVEL_JRB,            name = "Jolly Roger Bay"},
    {level = LEVEL_DDD,            name = "Dire Dire Docks"},
    {level = LEVEL_CASTLE_GROUNDS, name = "Castle Grounds"},
}
local function try_add_hot(levelConst, name)
    if levelConst ~= nil then
        table.insert(HOT_STAGE_POOL, {level = levelConst, name = name})
    end
end
try_add_hot(LEVEL_WF, "Whomp's Fortress")
try_add_hot(LEVEL_CCM, "Cool Cool Mountain")
try_add_hot(LEVEL_BBH, "Big Boo's Haunt")
try_add_hot(LEVEL_HMC, "Hazy Maze Cave")
try_add_hot(LEVEL_LLL, "Lethal Lava Land")
try_add_hot(LEVEL_SSL, "Shifting Sand Land")
try_add_hot(LEVEL_SL, "Snowman's Land")
try_add_hot(LEVEL_WDW, "Wet Dry World")
try_add_hot(LEVEL_TTM, "Tall Tall Mountain")
try_add_hot(LEVEL_THI, "Tiny Huge Island")
try_add_hot(LEVEL_TTC, "Tick Tock Clock")
try_add_hot(LEVEL_RR, "Rainbow Ride")
try_add_hot(LEVEL_PSS, "Peach's Secret Slide")
try_add_hot(LEVEL_TOTWC, "Tower of the Wing Cap")

local function level_display_name(levelNum)
    for i = 1, #HOT_STAGE_POOL do
        if HOT_STAGE_POOL[i].level == levelNum then
            return HOT_STAGE_POOL[i].name
        end
    end
    return "Unknown Stage"
end

local function init_session_sync_fields()
    if gGlobalSyncTable.fdxSessionWeight == nil then gGlobalSyncTable.fdxSessionWeight = 0 end
    if gGlobalSyncTable.fdxSessionSize == nil then gGlobalSyncTable.fdxSessionSize = 0 end
    if gGlobalSyncTable.fdxSessionName == nil then gGlobalSyncTable.fdxSessionName = "" end
    if gGlobalSyncTable.fdxSessionPlayer == nil then gGlobalSyncTable.fdxSessionPlayer = "" end
    if gGlobalSyncTable.fdxSessionSeq == nil then gGlobalSyncTable.fdxSessionSeq = 0 end
    if gGlobalSyncTable.fdxHotLevel == nil then gGlobalSyncTable.fdxHotLevel = 0 end
    if gGlobalSyncTable.fdxHotLuck == nil then gGlobalSyncTable.fdxHotLuck = 0 end
    if gGlobalSyncTable.fdxHotSeq == nil then gGlobalSyncTable.fdxHotSeq = 0 end
end

-- Host rolls a hot rare stage and rotates it about every 10 minutes (~18000 frames @ 30fps)
local HOT_ROTATE_FRAMES = 18000
local hotRotateTimer = 0

local function roll_hot_stage(force)
    init_session_sync_fields()
    local isServer = true
    if network_is_server ~= nil then isServer = network_is_server() end
    if not isServer then return end
    if #HOT_STAGE_POOL < 1 then return end

    local prev = gGlobalSyncTable.fdxHotLevel or 0
    local pick = HOT_STAGE_POOL[math.random(1, #HOT_STAGE_POOL)]
    -- Prefer a different stage than the current one when possible
    if #HOT_STAGE_POOL > 1 and not force then
        local tries = 0
        while pick.level == prev and tries < 8 do
            pick = HOT_STAGE_POOL[math.random(1, #HOT_STAGE_POOL)]
            tries = tries + 1
        end
    end
    gGlobalSyncTable.fdxHotLevel = pick.level
    gGlobalSyncTable.fdxHotLuck = math.random(18, 35)
    gGlobalSyncTable.fdxHotSeq = (gGlobalSyncTable.fdxHotSeq or 0) + 1
    hotRotateTimer = HOT_ROTATE_FRAMES
end

local function ensure_hot_stage_rolled()
    init_session_sync_fields()
    local isServer = true
    if network_is_server ~= nil then isServer = network_is_server() end
    if not isServer then return end

    if (gGlobalSyncTable.fdxHotSeq or 0) <= 0 then
        roll_hot_stage(true)
        return
    end

    -- First host frame after join: arm the timer without re-rolling
    if hotRotateTimer <= 0 then
        hotRotateTimer = HOT_ROTATE_FRAMES
        return
    end

    hotRotateTimer = hotRotateTimer - 1
    if hotRotateTimer <= 0 then
        roll_hot_stage(false)
    end
end

local function broadcast_session_record(pname, record)
    init_session_sync_fields()
    gGlobalSyncTable.fdxSessionPlayer = tostring(pname or "Mario")
    gGlobalSyncTable.fdxSessionName = tostring(record.name or "Fish")
    gGlobalSyncTable.fdxSessionSize = record.size or 0
    gGlobalSyncTable.fdxSessionWeight = record.weight or 0
    gGlobalSyncTable.fdxSessionSeq = (gGlobalSyncTable.fdxSessionSeq or 0) + 1
end

local function apply_incoming_session_announcements()
    init_session_sync_fields()
    local sSeq = gGlobalSyncTable.fdxSessionSeq or 0
    if sSeq > lastSeenSessionSeq then
        lastSeenSessionSeq = sSeq
        if sSeq > 0 and (gGlobalSyncTable.fdxSessionWeight or 0) > 0 then
            prBannerData.player = gGlobalSyncTable.fdxSessionPlayer or "Mario"
            prBannerData.name = gGlobalSyncTable.fdxSessionName or "Fish"
            prBannerData.size = gGlobalSyncTable.fdxSessionSize or 0
            prBannerData.weight = gGlobalSyncTable.fdxSessionWeight or 0
            prBannerTimer = 260
            djui_chat_message_create(string.format(
                "[Session PR] %s landed the biggest catch: %s (%.1f cm, %.1f kg)",
                prBannerData.player, prBannerData.name, prBannerData.size, prBannerData.weight
            ))
        end
    end
    local hSeq = gGlobalSyncTable.fdxHotSeq or 0
    if hSeq > lastSeenHotSeq then
        lastSeenHotSeq = hSeq
        if hSeq > 0 and (gGlobalSyncTable.fdxHotLevel or 0) ~= 0 then
            local lname = level_display_name(gGlobalSyncTable.fdxHotLevel)
            local luck = gGlobalSyncTable.fdxHotLuck or 20
            hotBannerText = string.format("HOT STAGE: %s  (+%d rare luck)", lname, luck)
            hotBannerTimer = 360
            djui_chat_message_create(string.format(
                "[Fishing] Rare hotspot: %s (+%d luck). Rotates about every 10 minutes.",
                lname, luck
            ))
        end
    end
end

local rodObj = nil
local rodTipObj = nil
local bobberObj = nil
local aimMarkers = {}
local CAST_DIST = 210
local aimHoldFrames = 0
local AIM_MIN_HOLD = 8
local wasHoldingL = false
local aimActive = false
local fishObj = nil
local shopSignsSpawned = false
local lastShopLevel = -1

-- Load or create per-player fishing fields on gPlayerSyncTable[0] (local player).
-- Always call this before reading/writing bait, wallet, rod, or fishState.
local function ensure_sync()
    local pst = gPlayerSyncTable[0]
    if pst == nil then
        return {
            fishInit = true,
            bait = 8,
            bait1 = 8,
            bait2 = 0,
            bait3 = 0,
            bait4 = 0,
            activeBait = 1,
            fishState = STATE_IDLE,
            fishTimer = 0,
            biteTimer = 0,
            miniProgress = 0,
            caughtId = 0,
            castPrompt = false,
            rodTier = 1,
            rodMaxUnlocked = 1,
            wallet = 0,
        }
    end
    if pst.fishInit ~= true then
        pst.fishInit = true
        pst.bait = 8
        pst.bait1 = 8
        pst.bait2 = 0
        pst.bait3 = 0
        pst.bait4 = 0
        pst.activeBait = 1
        pst.fishState = STATE_IDLE
        pst.fishTimer = 0
        pst.biteTimer = 0
        pst.miniProgress = 0
        pst.caughtId = 0
        pst.castPrompt = false
        pst.rodTier = 1
        pst.rodMaxUnlocked = 1
        -- Fishing wallet: separate from vanilla 999 coin limit
        pst.wallet = 0
    end
    if pst.wallet == nil then pst.wallet = 0 end
    if type(pst.wallet) == "number" then
        if pst.wallet > MAX_COINS then pst.wallet = MAX_COINS end
        if pst.wallet < 0 then pst.wallet = 0 end
    else
        pst.wallet = 0
    end
    if pst.bait1 == nil then pst.bait1 = pst.bait or 8 end
    if pst.bait2 == nil then pst.bait2 = 0 end
    if pst.bait3 == nil then pst.bait3 = 0 end
    if pst.bait4 == nil then pst.bait4 = 0 end
    if pst.activeBait == nil then pst.activeBait = 1 end
    -- total bait for HUD compatibility
    pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
    if pst.fishState == nil then pst.fishState = STATE_IDLE end
    if pst.fishTimer == nil then pst.fishTimer = 0 end
    if pst.biteTimer == nil then pst.biteTimer = 0 end
    if pst.miniProgress == nil then pst.miniProgress = 0 end
    if pst.caughtId == nil then pst.caughtId = 0 end
    if pst.castPrompt == nil then pst.castPrompt = false end
    if pst.rodTier == nil then pst.rodTier = 1 end
    if pst.rodMaxUnlocked == nil then pst.rodMaxUnlocked = pst.rodTier or 1 end
    if type(pst.rodTier) == "number" and pst.rodTier >= 1 and pst.rodTier <= #ROD_TIERS then
        rodTier = math.floor(pst.rodTier)
    else
        rodTier = 1
        pst.rodTier = 1
    end
    if type(pst.rodMaxUnlocked) ~= "number" or pst.rodMaxUnlocked < 1 then
        pst.rodMaxUnlocked = 1
    end
    if pst.rodMaxUnlocked < rodTier then
        pst.rodMaxUnlocked = rodTier
    end
    if pst.rodMaxUnlocked > #ROD_TIERS then
        pst.rodMaxUnlocked = #ROD_TIERS
    end

    -- Load disk save once per session (after fields exist)
    load_progress_into_pst(pst)
    fix_active_bait(pst)
    return pst
end

local function clear_rod_visuals()
    if rodObj ~= nil then
        obj_mark_for_deletion(rodObj)
        rodObj = nil
    end
    if rodTipObj ~= nil then
        obj_mark_for_deletion(rodTipObj)
        rodTipObj = nil
    end
end

local function set_rod_tier(tier, announce)
    local pst = ensure_sync()
    local maxU = pst.rodMaxUnlocked or 1
    if tier < 1 then tier = 1 end
    if tier > maxU then tier = maxU end
    if tier > #ROD_TIERS then tier = #ROD_TIERS end
    if tier == rodTier then
        return false
    end
    rodTier = tier
    pst.rodTier = tier
    clear_rod_visuals()
    queue_save()
    if announce then
        local style = ROD_TIERS[rodTier]
        local name = style and style.name or ("Tier " .. tostring(tier))
        djui_chat_message_create("Rod equipped: " .. name)
    end
    return true
end

local function cycle_rod_left()
    local pst = ensure_sync()
    local maxU = pst.rodMaxUnlocked or 1
    if maxU <= 1 then
        djui_chat_message_create("Only Wood rod unlocked. Upgrade at the Fish Market.")
        return
    end
    local nextTier = rodTier - 1
    if nextTier < 1 then
        nextTier = maxU
    end
    set_rod_tier(nextTier, true)
end

local function cycle_rod_right()
    local pst = ensure_sync()
    local maxU = pst.rodMaxUnlocked or 1
    if maxU <= 1 then
        return
    end
    local nextTier = rodTier + 1
    if nextTier > maxU then
        nextTier = 1
    end
    set_rod_tier(nextTier, true)
end

local function get_bait_count(pst, baitId)
    if baitId == 1 then return pst.bait1 or 0 end
    if baitId == 2 then return pst.bait2 or 0 end
    if baitId == 3 then return pst.bait3 or 0 end
    if baitId == 4 then return pst.bait4 or 0 end
    return 0
end

local function set_bait_count(pst, baitId, n)
    if n < 0 then n = 0 end
    if baitId == 1 then pst.bait1 = n
    elseif baitId == 2 then pst.bait2 = n
    elseif baitId == 3 then pst.bait3 = n
    elseif baitId == 4 then pst.bait4 = n end
    pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
    queue_save()
end

local function total_bait(pst)
    return (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
end

-- Bait id spent on the current cast (0 = none). Refunded if the cast is cancelled.
local castBaitId = 0

local function consume_active_bait(pst)
    fix_active_bait(pst)
    local id = pst.activeBait or 1
    local n = get_bait_count(pst, id)
    if n <= 0 then return false end
    set_bait_count(pst, id, n - 1)
    castBaitId = id
    fix_active_bait(pst)
    queue_save()
    return true
end

local function refund_cast_bait(pst)
    if castBaitId == nil or castBaitId < 1 then
        castBaitId = 0
        return false
    end
    local id = castBaitId
    castBaitId = 0
    local n = get_bait_count(pst, id)
    if n >= MAX_BAIT then
        -- Cap hit: still clear the pending refund so we do not double-refund later
        return false
    end
    set_bait_count(pst, id, n + 1)
    fix_active_bait(pst)
    queue_save()
    return true
end

local function clear_cast_bait()
    castBaitId = 0
end

local function get_rod_style()
    local s = ROD_TIERS[rodTier]
    if s == nil then
        rodTier = 1
        s = ROD_TIERS[1]
    end
    -- Gold rod: bind custom pole_geo mesh when available
    if s.useGoldPole then
        local body = load_gold_pole_model()
        return {
            name = s.name,
            body = body,
            bx = s.bx,
            by = s.by,
            bz = s.bz,
            cost = s.cost,
            luck = s.luck,
            useGoldPole = true,
        }
    end
    return s
end

local function get_next_rod_tier()
    local pst = gPlayerSyncTable[0]
    local maxU = 1
    if pst ~= nil and type(pst.rodMaxUnlocked) == "number" then
        maxU = pst.rodMaxUnlocked
    end
    if maxU >= #ROD_TIERS then
        return nil
    end
    return ROD_TIERS[maxU + 1]
end

local function get_wallet()
    local pst = ensure_sync()
    local w = pst.wallet or 0
    if type(w) ~= "number" then w = 0 end
    if w > MAX_COINS then w = MAX_COINS end
    if w < 0 then w = 0 end
    return w
end

local function set_wallet(amount)
    local pst = ensure_sync()
    if amount == nil then amount = 0 end
    if type(amount) ~= "number" then amount = 0 end
    if amount > MAX_COINS then amount = MAX_COINS end
    if amount < 0 then amount = 0 end
    pst.wallet = amount
    queue_save()
    return pst.wallet
end

-- Returns how much was actually added (may be less near the 10000 cap).
local function add_wallet(amount)
    if amount == nil or amount == 0 then return 0 end
    local before = get_wallet()
    local after = before + amount
    set_wallet(after)
    return get_wallet() - before
end

local function spend_wallet(amount)
    if amount == nil or amount <= 0 then return true end
    local w = get_wallet()
    if w < amount then return false end
    set_wallet(w - amount)
    return true
end

-- One-time migrate: if wallet is empty but Mario has stage coins, seed a little
-- so returning players are not stuck at 0. Does not strip vanilla coins.
local function maybe_seed_wallet_from_coins(m)
    local pst = ensure_sync()
    if pst.walletSeeded == true then return end
    pst.walletSeeded = true
    -- Do not overwrite a loaded save
    if storage_load_num("fdx_saved", 0) == 1 then return end
    if (pst.wallet or 0) > 0 then return end
    if m ~= nil and m.numCoins ~= nil and m.numCoins > 0 then
        set_wallet(m.numCoins)
    end
end

-- Buy the next rod tier with wallet coins. Legendary (1500) is the final tier.
-- Unlocks based on rodMaxUnlocked (not currently equipped), then equips the new rod.
local function try_upgrade_rod(m)
    local pst = ensure_sync()
    local maxU = pst.rodMaxUnlocked or 1
    if maxU >= #ROD_TIERS then
        djui_chat_message_create("Rod is already maxed: Legendary")
        return false
    end
    local newTier = maxU + 1
    local nextStyle = ROD_TIERS[newTier]
    if nextStyle == nil then
        djui_chat_message_create("Rod is already maxed: Legendary")
        return false
    end
    if get_wallet == nil or spend_wallet == nil then
        djui_chat_message_create("Money system failed to load. Re-enable Fishing DX.")
        return false
    end
    local wallet = get_wallet()
    if wallet < nextStyle.cost then
        djui_chat_message_create(string.format(
            "Need $%d for %s rod. You have $%d / $%d.",
            nextStyle.cost, nextStyle.name, wallet, MAX_COINS
        ))
        return false
    end
    if not spend_wallet(nextStyle.cost) then
        return false
    end
    pst.rodMaxUnlocked = newTier
    rodTier = newTier
    pst.rodTier = newTier
    clear_rod_visuals()
    save_progress()
    djui_chat_message_create(string.format(
        "Rod unlocked & equipped: %s! (-$%d)  Balance: $%d / $%d",
        nextStyle.name, nextStyle.cost, get_wallet(), MAX_COINS
    ))
    djui_chat_message_create("Left D-Pad cycles unlocked rods")
    sfx(SOUND_GENERAL_COIN, m)
    return true
end

local function get_player_name()
    local np = gNetworkPlayers[0]
    if np ~= nil and np.name ~= nil and tostring(np.name) ~= "" then
        return tostring(np.name)
    end
    return "Mario"
end

local function get_current_level()
    local np = gNetworkPlayers[0]
    if np ~= nil then
        return np.currLevelNum
    end
    return 0
end


-- Castle Grounds travel boat: placed beside the beach/pond and used as a stage selector.
local travelBoat = nil
local travelBoatLevel = -1
local travelMenuOpen = false
local travelIndex = 1
local travelCooldown = 0

-- Keep this list limited to the fishing destinations already supported by the mod.
local TRAVEL_DESTINATIONS = {
    {level = LEVEL_BOB,   area = 1, act = 1, name = "Broken (WIP)"},
    {level = LEVEL_JRB,   area = 1, act = 1, name = "Jolly Roger Bay"},
    {level = LEVEL_DDD,   area = 1, act = 1, name = "Dire, Dire Docks"},
    {level = LEVEL_CCM,   area = 1, act = 1, name = "Cool, Cool Mountain"},
    {level = LEVEL_LLL,   area = 1, act = 1, name = "Lethal Lava Land"},
    {level = LEVEL_TOTWC, area = 1, act = 1, name = "Tower of the Wing Cap"},
    {level = LEVEL_THI,   area = 1, act = 1, name = "Tiny-Huge Island"},
}

local function travel_boat_is_valid(o)
    return o ~= nil and (obj_is_valid == nil or obj_is_valid(o))
end

local function clear_travel_boat()
    if travel_boat_is_valid(travelBoat) then
        obj_mark_for_deletion(travelBoat)
    end
    travelBoat = nil
    travelBoatLevel = -1
end

local function spawn_travel_boat()
    local level = get_current_level()
    if level ~= LEVEL_CASTLE_GROUNDS then
        clear_travel_boat()
        return
    end
    if travel_boat_is_valid(travelBoat) then
        return
    end

    -- Castle Grounds shoreline, moved away from the bridge and onto the pond/beach edge.
    -- Keep the boat small enough to sit naturally in the water.
    local model = E_MODEL_JRB_SHIP_LEFT_HALF_PART
    if model == nil or (E_MODEL_NONE ~= nil and model == E_MODEL_NONE) then
        model = E_MODEL_JRB_SHIP_RIGHT_HALF_PART
    end
    if model == nil or (E_MODEL_NONE ~= nil and model == E_MODEL_NONE) then
        model = E_MODEL_WOODEN_POST
    end

    local bhv = id_bhvStaticObject
    if bhv == nil then bhv = id_bhvBreakableBox end
    if bhv == nil then bhv = id_bhvYellowCoin end

    -- Push the boat substantially farther forward from the shoreline/bridge and into the pond.
    -- Keep it at the pond water surface.
    travelBoat = spawn_non_sync_object(bhv, model, 2070, -1400, 4200, function(o)
        o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
        o.oInteractType = 0
        o.oIntangibleTimer = -1
        o.oDamageOrCoinValue = 0
        o.oNumLootCoins = 0
        -- Force full opacity so the boat cannot inherit a translucent alpha state.
        o.oOpacity = 350
        o.oFaceAngleYaw = 0x4000
        o.oMoveAngleYaw = 0x4000
        if o.header ~= nil and o.header.gfx ~= nil then
            o.header.gfx.scale.x = 0.76
            o.header.gfx.scale.y = 0.90
            o.header.gfx.scale.z = 1.65
            if o.header.gfx.node ~= nil then
                -- Explicitly keep the object active and clear any inherited transparent rendering state.
                o.header.gfx.node.flags = (o.header.gfx.node.flags | GRAPH_RENDER_ACTIVE) & (~GRAPH_RENDER_INVISIBLE)
            end
        end
    end)
    travelBoatLevel = level
end

local function open_travel_menu()
    travelMenuOpen = true
    travelIndex = 1
    showInventory = false
    showFishMap = false
end

local function close_travel_menu()
    travelMenuOpen = false
end

local function update_travel_boat(m, ctrl)
    if travelCooldown > 0 then travelCooldown = travelCooldown - 1 end
    spawn_travel_boat()

    if travelMenuOpen then
        if (ctrl.buttonPressed & U_JPAD) ~= 0 then
            travelIndex = travelIndex - 1
            if travelIndex < 1 then travelIndex = #TRAVEL_DESTINATIONS end
        elseif (ctrl.buttonPressed & D_JPAD) ~= 0 then
            travelIndex = travelIndex + 1
            if travelIndex > #TRAVEL_DESTINATIONS then travelIndex = 1 end
        elseif (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            close_travel_menu()
        elseif (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            local dst = TRAVEL_DESTINATIONS[travelIndex]
            close_travel_menu()
            travelCooldown = 30
            if warp_to_level ~= nil then
                warp_to_level(dst.level, dst.area, dst.act)
            else
                djui_chat_message_create("Travel warp is unavailable in this build.")
            end
        end
        return
    end

    if travel_boat_is_valid(travelBoat) and travelCooldown <= 0 then
        local dx = m.pos.x - travelBoat.oPosX
        local dy = m.pos.y - travelBoat.oPosY
        local dz = m.pos.z - travelBoat.oPosZ
        if (dx * dx + dy * dy + dz * dz) <= (650 * 650) then
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                open_travel_menu()
            end
        end
    end
end

-- Custom fishable zones + visual water surfaces
local CUSTOM_SPOTS = {
        {level = LEVEL_BOB, name = "Bridge Pool", x1 = -3600, x2 = -1800, y1 = -80, y2 = 520, z1 = 2800, z2 = 4600, waterY = 45},
        {level = LEVEL_BOB, name = "Mud Lake",    x1 = -2900,  x2 = 1800,  y1 = -480, y2 = 650, z1 = -800, z2 = 1600, waterY = 55},
        {level = LEVEL_CASTLE_GROUNDS, name = "Castle Pond", x1 = -900, x2 = 900, y1 = 50, y2 = 500, z1 = 2500, z2 = 3600, waterY = 200},
        {level = LEVEL_CCM, name = "Penguin Pond", x1 = 2500, x2 = 4600, y1 = -5200, y2 = -4200, z1 = 3500, z2 = 5600, waterY = -4600},

        -- Peach's Secret Slide edge pools
                {level = LEVEL_PSS, name = "Slide Pool Start",
        x1 = 5000, x2 = 6200, y1 = 6000, y2 = 6800, z1 = -6800, z2 = -5800, waterY = 6145},
        {level = LEVEL_PSS, name = "Slide Pool Upper",
        x1 = -500, x2 = 2800, y1 = 5400, y2 = 6300, z1 = -6000, z2 = -5200, waterY = 5600},
        {level = LEVEL_PSS, name = "Slide Pool Mid",
        x1 = 1200, x2 = 2600, y1 = -2200, y2 = -800, z1 = -2200, z2 = 2000, waterY = -1450},
        {level = LEVEL_PSS, name = "Slide Pool Lower",
        x1 = 3200, x2 = 5800, y1 = -800, y2 = 200, z1 = 2200, z2 = 5000, waterY = -200},
        {level = LEVEL_PSS, name = "Slide Pool End",
        x1 = -7000, x2 = -5600, y1 = -4800, y2 = -3800, z1 = 5000, z2 = 6600, waterY = -4220},

        -- Lethal Lava Land edges
                {level = LEVEL_LLL, name = "Lava Basin",
        x1 = -6500, x2 = 6500, y1 = -80, y2 = 420, z1 = -6500, z2 = 6500, waterY = 8},
        {level = LEVEL_LLL, name = "Mr I Lava Edge",
        x1 = -4000, x2 = -2000, y1 = 50, y2 = 450, z1 = 2800, z2 = 4200, waterY = 10},

    -- Tower of the Wing Cap cloud pool
    {level = LEVEL_TOTWC, name = "Cloud Pool",
        x1 = -900, x2 = -120, y1 = -2200, y2 = -1850, z1 = -550, z2 = 550, waterY = -2035},

    -- Tiny-Huge Island shores
        {level = LEVEL_THI, area = 1, name = "THI Huge North Shore",
        x1 = -6500, x2 = 6500, y1 = 800, y2 = 1600, z1 = 2500, z2 = 7500, waterY = 1024},
    {level = LEVEL_THI, area = 1, name = "THI Huge South Shore",
        x1 = -6500, x2 = 6500, y1 = 800, y2 = 1600, z1 = -7500, z2 = -2500, waterY = 1024},
    {level = LEVEL_THI, area = 1, name = "THI Huge East Shore",
        x1 = 2500, x2 = 7500, y1 = 800, y2 = 1600, z1 = -6500, z2 = 6500, waterY = 1024},
    {level = LEVEL_THI, area = 1, name = "THI Huge West Shore",
        x1 = -7500, x2 = -2500, y1 = 800, y2 = 1600, z1 = -6500, z2 = 6500, waterY = 1024},
    {level = LEVEL_THI, area = 1, name = "THI Huge Cove",
        x1 = -2000, x2 = 2000, y1 = 900, y2 = 1500, z1 = -500, z2 = 2500, waterY = 1024},
        {level = LEVEL_THI, area = 2, name = "THI Tiny North Shore",
        x1 = -2500, x2 = 2500, y1 = 800, y2 = 1600, z1 = 800, z2 = 3200, waterY = 1024},
    {level = LEVEL_THI, area = 2, name = "THI Tiny South Shore",
        x1 = -2500, x2 = 2500, y1 = 800, y2 = 1600, z1 = -3200, z2 = -800, waterY = 1024},
    {level = LEVEL_THI, area = 2, name = "THI Tiny East Shore",
        x1 = 800, x2 = 3200, y1 = 800, y2 = 1600, z1 = -2500, z2 = 2500, waterY = 1024},
    {level = LEVEL_THI, area = 2, name = "THI Tiny West Shore",
        x1 = -3200, x2 = -800, y1 = 800, y2 = 1600, z1 = -2500, z2 = 2500, waterY = 1024},
}

local lakeDecor = {}
local lakeDecorLevel = -1

local function get_current_area()
    local np = gNetworkPlayers[0]
    if np ~= nil and np.currAreaIndex ~= nil then
        return np.currAreaIndex
    end
    return 1
end

local function in_custom_spot(m)
    local level = get_current_level()
    local area = get_current_area()
    local x, y, z = m.pos.x, m.pos.y, m.pos.z
    for i = 1, #CUSTOM_SPOTS do
        local s = CUSTOM_SPOTS[i]
        if s.level == level and (s.area == nil or s.area == area) then
            if x >= s.x1 and x <= s.x2 and y >= s.y1 and y <= s.y2 and z >= s.z1 and z <= s.z2 then
                return s
            end
        end
    end
    return nil
end


local function get_fishing_water_y(m)
    local spot = in_custom_spot(m)
    if spot ~= nil then
        return spot.waterY
    end
    local waterY = find_water_level(m.pos.x, m.pos.z)
    if waterY ~= nil and waterY > -10000 then
        return waterY
    end
    if m.waterLevel ~= nil and m.waterLevel > -10000 then
        return m.waterLevel
    end
    -- Lethal Lava Land: bobber sits just above the lava plane
    if get_current_level() == LEVEL_LLL then
        return 8
    end
    return nil
end

local function is_near_water(m)
    if in_custom_spot(m) ~= nil then
        return true
    end
    local waterY = find_water_level(m.pos.x, m.pos.z)
    if waterY ~= nil and waterY > -10000 then
        local heightAbove = m.pos.y - waterY
        if heightAbove > -80 and heightAbove < 550 then
            return true
        end
    end
    if m.waterLevel ~= nil and m.waterLevel > -10000 then
        local heightAbove = m.pos.y - m.waterLevel
        if heightAbove > -80 and heightAbove < 550 then
            return true
        end
    end
    if m.floor ~= nil then
        local t = m.floor.type
        -- 0x0D / 0x0E = water; 0x01 = burn/lava (Lethal Lava Land edges)
        if t == 0x000D or t == 0x000E or t == 0x0001 then
            return true
        end
    end
    if get_current_level() == LEVEL_LLL then
        if m.pos.y > -50 and m.pos.y < 420 then
            return true
        end
    end
    -- Tiny-Huge Island: any standing position near real water level counts as an edge
    if get_current_level() == LEVEL_THI then
        local wy = find_water_level(m.pos.x, m.pos.z)
        if wy ~= nil and wy > -10000 then
            local h = m.pos.y - wy
            if h > -60 and h < 500 then
                return true
            end
        end
        if m.waterLevel ~= nil and m.waterLevel > -10000 then
            local h = m.pos.y - m.waterLevel
            if h > -60 and h < 500 then
                return true
            end
        end
    end
    return false
end

local function is_standing_to_fish(m)
    if m == nil or m.action == nil then return false end
    if ACT_FLAG_AIR ~= nil and (m.action & ACT_FLAG_AIR) ~= 0 then
        return false
    end
    if ACT_FLAG_SWIMMING ~= nil and (m.action & ACT_FLAG_SWIMMING) ~= 0 then
        return false
    end
    if ACT_FLAG_ON_POLE ~= nil and (m.action & ACT_FLAG_ON_POLE) ~= 0 then
        return false
    end
    if ACT_FLAG_HANGING ~= nil and (m.action & ACT_FLAG_HANGING) ~= 0 then
        return false
    end
    local a = m.action
    local airActs = {
        ACT_JUMP, ACT_DOUBLE_JUMP, ACT_TRIPLE_JUMP,
        ACT_BACKFLIP, ACT_SIDE_FLIP, ACT_LONG_JUMP,
        ACT_WALL_KICK_AIR, ACT_FREEFALL, ACT_TOP_OF_POLE_JUMP,
    }
    if ACT_STEEP_JUMP ~= nil then table.insert(airActs, ACT_STEEP_JUMP) end
    if ACT_WATER_JUMP ~= nil then table.insert(airActs, ACT_WATER_JUMP) end
    for i = 1, #airActs do
        if airActs[i] ~= nil and a == airActs[i] then
            return false
        end
    end
    if m.floorHeight ~= nil and m.pos.y > m.floorHeight + 24 then
        return false
    end
    return true
end


local function destroy_lake_decor()
    for i = 1, #lakeDecor do
        if lakeDecor[i] ~= nil then
            obj_mark_for_deletion(lakeDecor[i])
        end
    end
    lakeDecor = {}
    lakeDecorLevel = -1
end

local function harden_water_obj(obj, sx, sy, sz)
    if obj == nil then return end
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.oInteractType = 0
    obj.oIntangibleTimer = -1
    obj.oDamageOrCoinValue = 0
    obj.oNumLootCoins = 0
    obj.oVelX = 0
    obj.oVelY = 0
    obj.oVelZ = 0
    if obj.header ~= nil and obj.header.gfx ~= nil then
        obj.header.gfx.scale.x = sx
        obj.header.gfx.scale.y = sy
        obj.header.gfx.scale.z = sz
        if obj.header.gfx.node ~= nil then
            obj.header.gfx.node.flags = obj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
        end
    end
end

local function add_water_piece(model, x, y, z, sx, sy, sz)
    if model == nil then return nil end
    local bhv = id_bhvStaticObject
    if bhv == nil then bhv = id_bhvYellowCoin end
    local o = spawn_non_sync_object(bhv, model, x, y, z, function(obj)
        harden_water_obj(obj, sx, sy, sz)
    end)
    if o ~= nil then
        table.insert(lakeDecor, o)
    end
    return o
end

local function fill_water_surface(x1, x2, z1, z2, y, step)
    step = step or 180
    local x = x1
    while x <= x2 do
        local z = z1
        while z <= z2 do
            -- Primary surface: idle water wave (actual water texture)
            add_water_piece(E_MODEL_IDLE_WATER_WAVE, x, y, z, 3.2, 1.0, 3.2)
            -- Occasional shimmer ring
            if ((math.floor(x / step) + math.floor(z / step)) % 3) == 0 then
                add_water_piece(E_MODEL_WATER_RING, x + 15, y + 3, z + 15, 2.4, 0.55, 2.4)
            end
            z = z + step
        end
        x = x + step
    end
end

local function spawn_lake_decor()
    local level = get_current_level()
    if lakeDecorLevel == level and #lakeDecor > 0 then
        return
    end
    destroy_lake_decor()
    lakeDecorLevel = level

    if level == LEVEL_BOB then
        -- Bridge Pool (south path under first wooden bridge) - clean dense water
        fill_water_surface(-3400, -2000, 3000, 4400, 48, 160)
        for i = 0, 8 do
            local bx = -3300 + (i % 4) * 480
            local bz = 3100 + math.floor(i / 4) * 350
            add_water_piece(E_MODEL_BUBBLE, bx, 52 + (i % 3) * 10, bz, 1.6, 1.6, 1.6)
        end
        -- Soft edge rings
        for i = 0, 7 do
            local ang = i * (math.pi * 2 / 8)
            add_water_piece(E_MODEL_WATER_RING,
                -2700 + math.cos(ang) * 520,
                50,
                3700 + math.sin(ang) * 520,
                2.6, 0.5, 2.6)
        end

        -- Mud Lake (north field where Bob-ombs roam) - wide clean water body
        fill_water_surface(-750, 1650, -650, 1450, 55, 170)
        for i = 0, 11 do
            local bx = -550 + (i % 4) * 450
            local bz = -4500 + math.floor(i / 4) * 450
            add_water_piece(E_MODEL_BUBBLE, bx, 58 + (i % 4) * 8, bz, 1.7, 1.7, 1.7)
        end
        -- Clear outer shoreline rings so the pool reads as real water
        for i = 0, 15 do
            local ang = i * (math.pi * 2 / 16)
            local r = 780 + (i % 2) * 40
            add_water_piece(E_MODEL_WATER_RING,
                450 + math.cos(ang) * r,
                56,
                400 + math.sin(ang) * r,
                2.5, 0.85, 2.5)
        end
        -- A few surface waves for motion at the center
        for i = 0, 5 do
            local ang = i * (math.pi * 2 / 6)
            add_water_piece(E_MODEL_IDLE_WATER_WAVE,
                400 + math.cos(ang) * 220,
                54,
                350 + math.sin(ang) * 220,
                3.5, 1.6, 3.5)
        end

    elseif level == LEVEL_CASTLE_GROUNDS then
        fill_water_surface(-700, 700, 2700, 3400, 205, 150)
        for i = 0, 6 do
            add_water_piece(E_MODEL_BUBBLE, -400 + i * 120, 215, 3000, 1.4, 1.4, 1.4)
        end

    elseif level == LEVEL_CCM then
        -- Penguin pond at the bottom of the mountain
        fill_water_surface(2800, 4300, 3700, 5300, -4600, 160)
        for i = 0, 8 do
            local bx = 3000 + (i % 5) * 250
            local bz = 3900 + math.floor(i / 5) * 400
            add_water_piece(E_MODEL_BUBBLE, bx, -4588 + (i % 3) * 6, bz, 1.5, 1.5, 1.5)
        end

    elseif level == LEVEL_PSS then
        -- Visible water bodies on the edges so fishing reads as intentional
        -- Larger step sizes keep object count safe
        -- Start platform pool (entry room side)
        fill_water_surface(5200, 5900, -6600, -6000, 6145, 180)
        for i = 0, 4 do
            add_water_piece(E_MODEL_BUBBLE, 5250 + i * 140, 6155, -6350, 1.3, 1.3, 1.3)
        end

        -- Upper side ledge pool
        fill_water_surface(200, 2000, -5850, -5450, 5600, 200)
        for i = 0, 3 do
            add_water_piece(E_MODEL_BUBBLE, 400 + i * 400, 5610, -5650, 1.4, 1.4, 1.4)
        end

        -- Mid shelf pool
        fill_water_surface(1500, 2300, -1600, 1400, -1450, 220)
        for i = 0, 5 do
            add_water_piece(E_MODEL_BUBBLE, 1600 + (i % 3) * 250, -1440, -1200 + math.floor(i / 3) * 900, 1.4, 1.4, 1.4)
        end

        -- Lower bend pool
        fill_water_surface(3600, 5400, 2700, 4600, -200, 200)
        for i = 0, 4 do
            add_water_piece(E_MODEL_BUBBLE, 3800 + i * 320, -190, 3000 + (i % 3) * 400, 1.3, 1.3, 1.3)
        end

        -- End chamber pool (near star box) - VOID hotspot look
        fill_water_surface(-6800, -5900, 5300, 6300, -4220, 180)
        for i = 0, 7 do
            local ang = i * (3.14159 * 2 / 8)
            add_water_piece(
                E_MODEL_WATER_RING,
                -6350 + math.cos(ang) * 260,
                -4210,
                5800 + math.sin(ang) * 260,
                2.2, 0.6, 2.2
            )
        end
        for i = 0, 3 do
            add_water_piece(E_MODEL_BUBBLE, -6550 + i * 180, -4205, 5550 + i * 100, 1.5, 1.5, 1.5)
        end

    elseif level == LEVEL_TOTWC then
        -- Cloudy pool on the tower platform, left of the red cap-switch box
        -- Soft, misty look: wide rings + sparse waves (no dense bubbles)
        local cy = -2035
        fill_water_surface(-850, -180, -450, 450, cy, 160)
        for i = 0, 10 do
            local ang = i * (3.14159 * 2 / 11)
            local r = 280 + (i % 3) * 40
            add_water_piece(
                E_MODEL_WATER_RING,
                -500 + math.cos(ang) * r,
                cy + 6,
                math.sin(ang) * r,
                2.6, 0.5, 2.6
            )
        end
        for i = 0, 5 do
            local ang = i * (3.14159 * 2 / 6)
            add_water_piece(
                E_MODEL_IDLE_WATER_WAVE,
                -520 + math.cos(ang) * 180,
                cy + 2,
                math.sin(ang) * 180,
                3.2, 1.0, 3.2
            )
        end

    elseif level == LEVEL_THI then
        local wy = 1024
        for i = 0, 7 do
            local ang = i * (3.14159 * 2 / 8)
            add_water_piece(
                E_MODEL_WATER_RING,
                math.cos(ang) * 4200,
                wy + 4,
                math.sin(ang) * 4200,
                3.0, 0.5, 3.0
            )
        end
    end
end

local function fish_allowed_here(fishData)
    if fishData == nil then return false end
    local level = get_current_level()
    if fishData.onlyLevels ~= nil then
        for i = 1, #fishData.onlyLevels do
            if fishData.onlyLevels[i] == level then return true end
        end
        return false
    end
    if fishData.onlyLevel == nil then return true end
    return level == fishData.onlyLevel
end

local function roll_fish()
    local pst = ensure_sync()
    local luck = get_rod_style().luck or 0
    local bt = get_bait_type(pst.activeBait or 1)
    luck = luck + (bt.luck or 0)

    init_session_sync_fields()
    if (gGlobalSyncTable.fdxHotLevel or 0) ~= 0 and get_current_level() == gGlobalSyncTable.fdxHotLevel then
        luck = luck + (gGlobalSyncTable.fdxHotLuck or 0)
    end

    local pool = {}
    local totalRarity = 0
    local onThi = (get_current_level() == LEVEL_THI)
    for i = 1, #FISH do
        local f = FISH[i]
        if onThi then
            if is_thi_pool_fish(f) then
                table.insert(pool, f)
                totalRarity = totalRarity + f.rarity
            end
        elseif fish_allowed_here(f) then
            table.insert(pool, f)
            totalRarity = totalRarity + f.rarity
        end
    end
    if #pool == 0 then
        return FISH[1]
    end

    local roll = math.random(1, math.max(1, totalRarity))
    -- luck shifts toward rarer entries at the end of the pool
    roll = roll + math.floor(luck * 0.35)
    if roll > totalRarity then roll = totalRarity end

    local acc = 0
    for i = 1, #pool do
        acc = acc + pool[i].rarity
        if roll <= acc then
            return pool[i]
        end
    end
    return pool[#pool]
end

local function make_fish_record(fishData)
    local size = fishData.minSize + math.random() * (fishData.maxSize - fishData.minSize)
    local weight = fishData.minWeight + math.random() * (fishData.maxWeight - fishData.minWeight)
    size = math.floor(size * 10 + 0.5) / 10
    weight = math.floor(weight * 10 + 0.5) / 10
    local rec = {
        id = fishData.id,
        name = fishData.name,
        size = size,
        weight = weight,
        value = fishData.value
    }
    if fishData.isVoid then
        rec.isVoid = true
        -- decayFrames ~180s at 30fps (default 5400); store remaining frames at catch time
        rec.decayLeft = fishData.decayFrames or 5400
    end
    return rec
end

local function get_fish_name(id)
    for i = 1, #FISH do
        if FISH[i].id == id then
            return FISH[i].name
        end
    end
    return "Unknown Fish"
end

local function add_to_inventory(record)
    if #inventory >= MAX_INVENTORY then
        return false
    end
    table.insert(inventory, record)
    queue_save()
    return true
end

local function get_inventory_value()
    local total = 0
    for i = 1, #inventory do
        total = total + (inventory[i].value or 1)
    end
    return total
end

local function sell_all_fish(m)
    local total = get_inventory_value()
    local count = #inventory
    if total <= 0 or count <= 0 then
        return 0, 0
    end
    local gained = add_wallet(total)
    inventory = {}
    save_progress()
    return gained, count
end

local function check_personal_record(record)
    if record == nil or record.weight == nil then
        return false
    end
    local isPersonal = false
    local pname = get_player_name()

    if record.weight > (personalRecord.weight or 0) then
        personalRecord.name = record.name
        personalRecord.size = record.size
        personalRecord.weight = record.weight
        queue_save()
        isPersonal = true
    end

    -- Session largest catch: every player sees this via gGlobalSyncTable
    init_session_sync_fields()
    local sessionBest = gGlobalSyncTable.fdxSessionWeight or 0
    if record.weight > sessionBest then
        broadcast_session_record(pname, record)
    elseif isPersonal then
        djui_chat_message_create(string.format(
            "Personal PR! %s (%.1f cm, %.1f kg)",
            record.name, record.size, record.weight
        ))
    end
    return isPersonal or (record.weight > sessionBest)
end

-- Shop signs: must walk up and press B to open (no free-range auto shop)
-- kind: "bait" or "sell"
local SHOP_SIGNS = {
    {level = LEVEL_CASTLE_GROUNDS, kind = "sell", x = -1400, y = 280, z = 3800, label = "Fish Market"},
    {level = LEVEL_CASTLE_GROUNDS, kind = "bait", x = 100,   y = 280, z = 4000, label = "Bait Shop"},
    {level = LEVEL_JRB,            kind = "sell", x = -5200, y = 120, z = 2800, label = "Fish Market"},
    {level = LEVEL_DDD,            kind = "bait", x = -3000, y = 100, z = 0,    label = "Bait Shop"},
    {level = LEVEL_DDD,            kind = "bait", x = 3500,  y = 100, z = -2000, label = "Bait Shop"},
    {level = LEVEL_BOB,            kind = "bait", x = -2800, y = 320, z = 4550, label = "Bait Shop"},
    {level = LEVEL_BOB,            kind = "sell", x = 200,   y = 80,  z = 300,  label = "Fish Market"},
    -- LLL: sell near the first Mr. I / drawbridge grate (Mr I at -3199, 307, 3456)
    {level = LEVEL_LLL,            kind = "sell", x = -3000, y = 307, z = 3600, label = "Fish Market"},
    -- Castle Courtyard (backyard): bait shop by the central fountain
    {level = LEVEL_CASTLE_COURTYARD, kind = "bait", x = 0, y = 20, z = -1800, label = "Bait Shop"},
}

local activeShopKind = nil  -- nil | "bait" | "sell"
local nearSignInfo = nil
local shopSignObjs = {}

local function dist_to_sign(m, sign)
    local dx = m.pos.x - sign.x
    local dy = m.pos.y - sign.y
    local dz = m.pos.z - sign.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

local function get_nearest_shop_sign(m)
    local level = get_current_level()
    local best = nil
    local bestD = 99999
    for i = 1, #SHOP_SIGNS do
        local s = SHOP_SIGNS[i]
        if s.level == level then
            local d = dist_to_sign(m, s)
            if d < bestD then
                bestD = d
                best = s
            end
        end
    end
    if best ~= nil and bestD < 280 then
        return best, bestD
    end
    return nil, bestD
end

local function near_bait_shop(m)
    return activeShopKind == "bait"
end

local function near_sell_shop(m)
    return activeShopKind == "sell"
end

local function near_fireplace(m)
    local np = gNetworkPlayers[0]
    if np == nil then return false end
    if np.currLevelNum ~= LEVEL_CASTLE then return false end
    if np.currAreaIndex ~= 1 then return false end
    local x, y, z = m.pos.x, m.pos.y, m.pos.z
    if x > -400 and x < 400 and y > -50 and y < 400 and z > -600 and z < 200 then
        return true
    end
    return false
end

local function destroy_fire_objs()
    for i = 1, #fireObjs do
        if fireObjs[i] ~= nil then
            obj_mark_for_deletion(fireObjs[i])
        end
    end
    fireObjs = {}
    fireSpawned = false
end

local function spawn_fireplace()
    local np = gNetworkPlayers[0]
    if np == nil then return end
    if np.currLevelNum ~= LEVEL_CASTLE or np.currAreaIndex ~= 1 then
        destroy_fire_objs()
        fireLevel = -1
        return
    end
    if fireSpawned and fireLevel == LEVEL_CASTLE then
        return
    end
    destroy_fire_objs()
    fireSpawned = true
    fireLevel = LEVEL_CASTLE

    local baseX, baseY, baseZ = 0, 50, -250
    local offsets = {
        {0, 0, 0}, {40, 10, 20}, {-40, 10, 20},
        {20, 25, -10}, {-20, 25, -10}, {0, 40, 10},
    }
    for i = 1, #offsets do
        local o = offsets[i]
        local flame = spawn_non_sync_object(
            id_bhvFlame,
            E_MODEL_RED_FLAME,
            baseX + o[1], baseY + o[2], baseZ + o[3],
            function(obj)
                obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
                obj.oInteractType = 0
                obj.oIntangibleTimer = -1
                obj.header.gfx.scale.x = 1.4
                obj.header.gfx.scale.y = 1.4
                obj.header.gfx.scale.z = 1.4
            end
        )
        table.insert(fireObjs, flame)
    end
end

local function cook_one_fish(m)
    if #inventory <= 0 then return false end
    local bestI = 1
    local bestV = inventory[1].value or 0
    for i = 2, #inventory do
        local v = inventory[i].value or 0
        if v > bestV then
            bestV = v
            bestI = i
        end
    end
    local cooked = inventory[bestI]
    table.remove(inventory, bestI)
    cookBoostTimer = COOK_BOOST_FRAMES
    djui_chat_message_create(string.format("Cooked %s! Speed boost for 100 seconds.", cooked.name or "fish"))
    sfx(SOUND_GENERAL_COIN, m)
    return true
end

local function apply_cook_boost(m)
    if cookBoostTimer <= 0 then return end
    cookBoostTimer = cookBoostTimer - 1
    if m.forwardVel > 8 then
        m.forwardVel = m.forwardVel + 1.15
        if m.forwardVel > 72 then
            m.forwardVel = 72
        end
    end
    if m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP or m.action == ACT_TRIPLE_JUMP then
        if m.vel.y > 0 and m.vel.y < 50 then
            m.vel.y = m.vel.y + 0.35
        end
    end
end

local function destroy_aim_marker()
    for i = 1, #aimMarkers do
        if aimMarkers[i] ~= nil then
            obj_mark_for_deletion(aimMarkers[i])
        end
    end
    aimMarkers = {}
    aimActive = false
end

local function destroy_fishing_objects()
    if rodObj ~= nil then
        obj_mark_for_deletion(rodObj)
        rodObj = nil
    end
    if rodTipObj ~= nil then
        obj_mark_for_deletion(rodTipObj)
        rodTipObj = nil
    end
    if bobberObj ~= nil then
        obj_mark_for_deletion(bobberObj)
        bobberObj = nil
    end
    if fishObj ~= nil then
        obj_mark_for_deletion(fishObj)
        fishObj = nil
    end
    destroy_aim_marker()
end

local function reset_fishing_state(pst)
    if pst ~= nil then
        pst.fishState = STATE_IDLE
        pst.fishTimer = 0
        pst.biteTimer = 0
        pst.miniProgress = 0
        pst.caughtId = 0
        pst.castPrompt = false
    end
    lockedPos = nil
    destroy_fishing_objects()
    -- Caller is responsible for refund_cast_bait before reset when cancelling.
    -- Successful catch / normal end clears the pending refund so bait stays spent.
end

local function obj_is_alive(o)
    return o ~= nil and o.activeFlags ~= nil and o.activeFlags ~= 0
end

local function harden_visual(o, sx, sy, sz)
    if o == nil then return end
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    o.oInteractType = 0
    o.oIntangibleTimer = -1
    o.oDamageOrCoinValue = 0
    o.oHealth = 0
    o.oNumLootCoins = 0
    o.oVelX = 0
    o.oVelY = 0
    o.oVelZ = 0
    o.oForwardVel = 0
    if o.header ~= nil and o.header.gfx ~= nil then
        o.header.gfx.scale.x = sx
        o.header.gfx.scale.y = sy
        o.header.gfx.scale.z = sz
        if o.header.gfx.node ~= nil then
            o.header.gfx.node.flags = o.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
        end
    end
end

-- Safe prop: intangible, zero coin value, no loot. Interaction blocked in HOOK_ALLOW_INTERACT.
local function make_visual_obj(model, x, y, z, sx, sy, sz)
    local bhv = id_bhvStaticObject
    if bhv == nil then bhv = id_bhvYellowCoin end
    local obj = spawn_non_sync_object(bhv, model, x, y, z, function(o)
        harden_visual(o, sx, sy, sz)
        o.oAnimState = 0
        o.oDamageOrCoinValue = 0
        o.oNumLootCoins = 0
        -- Force full opacity so the boat cannot inherit a translucent alpha state.
        o.oOpacity = 255
        o.oInteractType = 0
        o.oIntangibleTimer = -1
        -- Stop coin spin animation from looking like spam/flash
        if o.header ~= nil and o.header.gfx ~= nil and o.header.gfx.animInfo ~= nil then
            o.header.gfx.animInfo.animFrame = 0
        end
    end)
    return obj
end

-- World position where the bobber will land when casting
local function get_cast_aim_pos(m)
    local yaw = m.faceAngle.y
    local s = sins(yaw)
    local c = coss(yaw)
    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 40
    end
    return {
        x = m.pos.x + s * CAST_DIST,
        y = waterY + 10,
        z = m.pos.z + c * CAST_DIST,
    }
end

local function spawn_aim_piece(model, x, y, z, sx, sy, sz)
    if model == nil then return nil end
    local o = make_visual_obj(model, x, y, z, sx, sy, sz)
    if o ~= nil then
        harden_visual(o, sx, sy, sz)
        table.insert(aimMarkers, o)
    end
    return o
end

-- Hold L: flat reticle on the water only (no floating props, no flash)
local function update_cast_aim_preview(m, holdingAim)
    if not holdingAim then
        destroy_aim_marker()
        return
    end
    aimActive = true
    local pos = get_cast_aim_pos(m)

    if #aimMarkers == 0 then
        local ring = E_MODEL_WATER_RING
        local wave = E_MODEL_IDLE_WATER_WAVE
        if ring ~= nil then
            spawn_aim_piece(ring, pos.x, pos.y, pos.z, 3.2, 0.45, 3.2)
            spawn_aim_piece(ring, pos.x, pos.y + 2, pos.z, 2.0, 0.35, 2.0)
        end
        if wave ~= nil then
            spawn_aim_piece(wave, pos.x, pos.y + 1, pos.z, 2.4, 0.5, 2.4)
        end
        -- Fallback if water models missing
        if #aimMarkers == 0 and E_MODEL_YELLOW_COIN ~= nil then
            spawn_aim_piece(E_MODEL_YELLOW_COIN, pos.x, pos.y + 4, pos.z, 0.8, 0.25, 0.8)
        end
    end

    for i = 1, #aimMarkers do
        local o = aimMarkers[i]
        if o ~= nil and obj_is_alive(o) then
            o.oPosX = pos.x
            o.oPosY = pos.y + (i - 1) * 2
            o.oPosZ = pos.z
            o.oDamageOrCoinValue = 0
            o.oNumLootCoins = 0
            o.oInteractType = 0
            o.oIntangibleTimer = -1
            if i == 1 then
                harden_visual(o, 3.2, 0.45, 3.2)
            elseif i == 2 then
                harden_visual(o, 2.0, 0.35, 2.0)
            else
                harden_visual(o, 2.4, 0.5, 2.4)
            end
        end
    end
end

local function spawn_rod_and_bobber(m)
    destroy_fishing_objects()

    local yaw = m.faceAngle.y
    local s = sins(yaw)
    local c = coss(yaw)
    local style = get_rod_style()

    -- Pole only - no tip model (no coin generator)
    -- Gold tier uses actors/pole (pole_geo); other tiers use stock box/post models
    local body = style.body
    if body == nil and style.useGoldPole then
        body = load_gold_pole_model()
    end
    if body == nil then
        body = E_MODEL_METAL_BOX
    end

    local holdX = m.pos.x + s * 40
    local holdY = m.pos.y + 48
    local holdZ = m.pos.z + c * 40
    local pitch = 0x3000
    -- Custom pole mesh is authored upright along Y; tilt forward toward the water
    if style.useGoldPole then
        holdY = m.pos.y + 42
        pitch = 0x2A00
    end

    rodObj = make_visual_obj(
        body,
        holdX,
        holdY,
        holdZ,
        style.bx, style.by, style.bz
    )
    if rodObj ~= nil then
        rodObj.oFaceAnglePitch = pitch
        rodObj.oMoveAnglePitch = pitch
        rodObj.oFaceAngleYaw = yaw
        rodObj.oMoveAngleYaw = yaw
        harden_visual(rodObj, style.bx, style.by, style.bz)
    end

    rodTipObj = nil

    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 80
    end

    bobberObj = make_visual_obj(
        E_MODEL_1UP,
        m.pos.x + s * CAST_DIST,
        waterY + 16,
        m.pos.z + c * CAST_DIST,
        0.55, 0.55, 0.55
    )
    if bobberObj ~= nil then
        harden_visual(bobberObj, 0.55, 0.55, 0.55)
    end
    destroy_aim_marker()
end

local function spawn_fish_near_bobber(m)
    if obj_is_alive(fishObj) then
        return
    end
    if fishObj ~= nil then
        obj_mark_for_deletion(fishObj)
        fishObj = nil
    end

    local yaw = m.faceAngle.y
    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 80
    end

    -- Same safe non-breakable prop behavior as rod/bobber
    fishObj = make_visual_obj(
        E_MODEL_FISH,
        m.pos.x + sins(yaw) * 235,
        waterY - 12,
        m.pos.z + coss(yaw) * 235,
        1.6, 1.6, 1.6
    )
    if fishObj ~= nil then
        harden_visual(fishObj, 1.6, 1.6, 1.6)
        fishObj.oDamageOrCoinValue = 0
        fishObj.oNumLootCoins = 0
        fishObj.oInteractType = 0
        fishObj.oIntangibleTimer = -1
    end
end

local fishRespawnCooldown = 0
local rodRespawnCooldown = 0

local function ensure_fishing_visuals(m)
    local st = ensure_sync().fishState
    if st == STATE_IDLE or st == STATE_CATCH then
        return
    end

    if fishRespawnCooldown > 0 then fishRespawnCooldown = fishRespawnCooldown - 1 end
    if rodRespawnCooldown > 0 then rodRespawnCooldown = rodRespawnCooldown - 1 end

    local needRod = (not obj_is_alive(rodObj)) or (not obj_is_alive(bobberObj))
    if needRod and rodRespawnCooldown <= 0 then
        spawn_rod_and_bobber(m)
        rodRespawnCooldown = 20
    end

    if st == STATE_WAITING or st == STATE_BITE or st == STATE_MINIGAME then
        if not obj_is_alive(fishObj) and fishRespawnCooldown <= 0 then
            spawn_fish_near_bobber(m)
            fishRespawnCooldown = 20
        end
    end
end

local function update_fishing_objects(m)
    ensure_fishing_visuals(m)

    local yaw = m.faceAngle.y
    local s = sins(yaw)
    local c = coss(yaw)
    local t = get_global_timer()
    local st = ensure_sync().fishState
    local style = get_rod_style()

    if obj_is_alive(rodObj) then
        rodObj.oPosX = m.pos.x + s * 40
        rodObj.oPosY = m.pos.y + 48
        rodObj.oPosZ = m.pos.z + c * 40
        rodObj.oFaceAngleYaw = yaw
        rodObj.oMoveAngleYaw = yaw
        rodObj.oFaceAnglePitch = 0x3000
        rodObj.oMoveAnglePitch = 0x3000
        rodObj.oDamageOrCoinValue = 0
        rodObj.oNumLootCoins = 0
        rodObj.oInteractType = 0
        rodObj.oIntangibleTimer = -1
        harden_visual(rodObj, style.bx, style.by, style.bz)
    end

    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 80
    end

    if obj_is_alive(bobberObj) then
        local bob = math.sin(t / 10) * 6
        if st == STATE_BITE or st == STATE_MINIGAME then
            bob = math.sin(t / 3) * 10
        end
        bobberObj.oPosX = m.pos.x + s * CAST_DIST
        bobberObj.oPosY = waterY + 16 + bob
        bobberObj.oPosZ = m.pos.z + c * CAST_DIST
        bobberObj.oDamageOrCoinValue = 0
        bobberObj.oNumLootCoins = 0
        bobberObj.oInteractType = 0
        bobberObj.oIntangibleTimer = -1
        harden_visual(bobberObj, 0.55, 0.55, 0.55)
    end

    if obj_is_alive(fishObj) then
        local shake = 0.5
        if st == STATE_BITE or st == STATE_MINIGAME then
            shake = 1.2
        end
        local tx = m.pos.x + s * 235 + math.sin(t / 12) * 10 * shake
        local ty = waterY - 12 + math.sin(t / 8) * 6 * shake
        local tz = m.pos.z + c * 235 + math.cos(t / 14) * 10 * shake

        fishObj.oPosX = fishObj.oPosX + (tx - fishObj.oPosX) * 0.2
        fishObj.oPosY = fishObj.oPosY + (ty - fishObj.oPosY) * 0.2
        fishObj.oPosZ = fishObj.oPosZ + (tz - fishObj.oPosZ) * 0.2
        fishObj.oFaceAngleYaw = yaw + 0x4000
        fishObj.oMoveAngleYaw = fishObj.oFaceAngleYaw
        fishObj.oVelX = 0
        fishObj.oVelY = 0
        fishObj.oVelZ = 0
        fishObj.oForwardVel = 0
        fishObj.oInteractType = 0
        fishObj.oIntangibleTimer = -1
        fishObj.oDamageOrCoinValue = 0
        fishObj.oNumLootCoins = 0
        harden_visual(fishObj, 1.6, 1.6, 1.6)
    end
end

local function clear_shop_sign_objs()
    for i = 1, #shopSignObjs do
        if shopSignObjs[i] ~= nil then
            obj_mark_for_deletion(shopSignObjs[i])
        end
    end
    shopSignObjs = {}
end

local function add_shop_prop(model, x, y, z, sx, sy, sz, yaw)
    local bhv = id_bhvStaticObject
    if bhv == nil then
        bhv = id_bhvBreakableBox
    end
    if bhv == nil then
        bhv = id_bhvYellowCoin
    end
    local o = spawn_non_sync_object(bhv, model, x, y, z, function(obj)
        obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
        obj.oInteractType = 0
        obj.oIntangibleTimer = -1
        obj.oDamageOrCoinValue = 0
        obj.oNumLootCoins = 0
        obj.oVelY = 0
        obj.oForwardVel = 0
        if yaw ~= nil then
            obj.oFaceAngleYaw = yaw
            obj.oMoveAngleYaw = yaw
        end
        if obj.header ~= nil and obj.header.gfx ~= nil then
            obj.header.gfx.scale.x = sx
            obj.header.gfx.scale.y = sy
            obj.header.gfx.scale.z = sz
        end
    end)
    if o ~= nil then
        o.oPosX = x
        o.oPosY = y
        o.oPosZ = z
        table.insert(shopSignObjs, o)
    end
    return o
end

local function spawn_shop_stall(s)
    local model = E_MODEL_TREASURE_CHEST_BASE
    if model == nil then
        model = E_MODEL_BREAKABLE_BOX
    end
    add_shop_prop(model, s.x, s.y, s.z, 1.35, 1.0, 1.35, 0)
end

local function spawn_shop_signs()
    local level = get_current_level()
    if shopSignsSpawned and lastShopLevel == level then
        return
    end
    shopSignsSpawned = true
    lastShopLevel = level
    clear_shop_sign_objs()
    activeShopKind = nil

    for i = 1, #SHOP_SIGNS do
        local s = SHOP_SIGNS[i]
        if s.level == level then
            spawn_shop_stall(s)
        end
    end
end

local function lock_mario_while_fishing(m)
    m.forwardVel = 0
    m.vel.x = 0
    m.vel.z = 0
    if m.vel.y > 0 then
        m.vel.y = 0
    end
    if lockedPos ~= nil then
        m.pos.x = lockedPos.x
        m.pos.z = lockedPos.z
    end
end

local function cancel_if_needed(m, pst, ctrl)
    if pst.fishState == STATE_IDLE or pst.fishState == STATE_CATCH then
        return
    end
    if (ctrl.buttonPressed & B_BUTTON) ~= 0 then
        local refunded = refund_cast_bait(pst)
        reset_fishing_state(pst)
        if refunded then
            djui_chat_message_create("Cancelled. Bait returned. (" .. total_bait(pst) .. " left)")
        else
            djui_chat_message_create("Reeled in. Fishing cancelled.")
        end
    end
end

local function mario_update(m)
    if m.playerIndex ~= 0 then
        return
    end

    local pst = ensure_sync()
    local ctrl = m.controller
    maybe_seed_wallet_from_coins(m)
    fix_active_bait(pst)
    ensure_hot_stage_rolled()
    apply_incoming_session_announcements()
    if hotBannerTimer > 0 then hotBannerTimer = hotBannerTimer - 1 end

    if saveCooldown > 0 then
        saveCooldown = saveCooldown - 1
        if saveCooldown == 0 then
            save_progress()
        end
    end

    if shopCooldown > 0 then shopCooldown = shopCooldown - 1 end
    if catchDisplayTimer > 0 then catchDisplayTimer = catchDisplayTimer - 1 end
    if biteFlash > 0 then biteFlash = biteFlash - 1 end
    if reelPulse > 0 then reelPulse = reelPulse - 1 end
    if prBannerTimer > 0 then prBannerTimer = prBannerTimer - 1 end

    -- VOID fish decay: tick down every frame; remove when timer hits 0
    do
        local decayed = false
        for i = #inventory, 1, -1 do
            local rec = inventory[i]
            if rec ~= nil and rec.isVoid and rec.decayLeft ~= nil then
                rec.decayLeft = rec.decayLeft - 1
                if rec.decayLeft <= 0 then
                    djui_chat_message_create(string.format("%s decayed into the void...", rec.name or "VOID Fish"))
                    table.remove(inventory, i)
                    decayed = true
                end
            end
        end
        if decayed then
            queue_save()
        end
    end

    local level = get_current_level()
    update_travel_boat(m, ctrl)
    if travelMenuOpen then
        return
    end

    if level == LEVEL_CASTLE_GROUNDS or level == LEVEL_DDD or level == LEVEL_JRB
        or level == LEVEL_BOB or level == LEVEL_LLL or level == LEVEL_CASTLE_COURTYARD then
        spawn_shop_signs()
    else
        shopSignsSpawned = false
        lastShopLevel = -1
    end

    spawn_lake_decor()
    spawn_fireplace()
    apply_cook_boost(m)
    if cookCooldown > 0 then cookCooldown = cookCooldown - 1 end

    -- Fish map pages / close, or inventory toggle (Right D-Pad)
    if showFishMap then
        local lines = get_fish_map_lines()
        local pages = math.max(1, math.ceil(#lines / FISH_MAP_PAGE_SIZE))
        if (ctrl.buttonPressed & L_JPAD) ~= 0 or (ctrl.buttonPressed & U_JPAD) ~= 0 then
            fishMapPage = fishMapPage - 1
            if fishMapPage < 1 then fishMapPage = pages end
        end
        if (ctrl.buttonPressed & R_JPAD) ~= 0 or (ctrl.buttonPressed & D_JPAD) ~= 0 then
            fishMapPage = fishMapPage + 1
            if fishMapPage > pages then fishMapPage = 1 end
        end
        if (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            close_fish_map()
        end
    elseif (ctrl.buttonPressed & R_JPAD) ~= 0 then
        if pst.fishState == STATE_IDLE and not near_bait_shop(m) and not near_sell_shop(m) then
            showInventory = not showInventory
            if showInventory then showFishMap = false end
        end
    end

    -- Left D-Pad: cycle unlocked rod types (when not in bait shop / not mid-fish / map closed)
    if (ctrl.buttonPressed & L_JPAD) ~= 0 and not showFishMap then
        local canSwitch = pst.fishState == STATE_IDLE and not near_bait_shop(m) and not near_sell_shop(m) and not showInventory
        if canSwitch then
            cycle_rod_left()
        end
    end

    -- While inventory is open, Up/Down cycle equipped bait among types you own
    if showInventory and pst.fishState == STATE_IDLE and not near_bait_shop(m) then
        if (ctrl.buttonPressed & U_JPAD) ~= 0 or (ctrl.buttonPressed & D_JPAD) ~= 0 then
            local dir = 1
            if (ctrl.buttonPressed & D_JPAD) ~= 0 then dir = -1 end
            local start = pst.activeBait or 1
            local found = nil
            for step = 1, #BAIT_TYPES do
                local cand = start + dir * step
                while cand < 1 do cand = cand + #BAIT_TYPES end
                while cand > #BAIT_TYPES do cand = cand - #BAIT_TYPES end
                if get_bait_count(pst, cand) > 0 then
                    found = cand
                    break
                end
            end
            if found ~= nil then
                equip_bait(pst, found, false)
            else
                djui_chat_message_create("No bait to equip. Visit a Bait Shop.")
            end
        end
    end

    -- Sign interaction: press B near sign to open our shop UI (not vanilla dialog).
    -- Walk away to close. While open, B buys/sells and A upgrades rods.
    nearSignInfo = nil
    if pst.fishState == STATE_IDLE then
        local sign = get_nearest_shop_sign(m)
        if sign ~= nil then
            nearSignInfo = sign
            if activeShopKind == nil and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
                activeShopKind = sign.kind
                shopCooldown = 12
                djui_chat_message_create(sign.label .. " - ready")
            end
        else
            activeShopKind = nil
        end
    else
        activeShopKind = nil
    end

    local baitPrompt = near_bait_shop(m) and pst.fishState == STATE_IDLE
    local sellPrompt = near_sell_shop(m) and pst.fishState == STATE_IDLE
    cookPrompt = near_fireplace(m) and pst.fishState == STATE_IDLE
    shopPrompt = baitPrompt or sellPrompt or cookPrompt

    if cookPrompt and cookCooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
        if #inventory > 0 then
            if cook_one_fish(m) then
                cookCooldown = 30
            end
        else
            djui_chat_message_create("No fish to cook! Catch some first.")
            cookCooldown = 20
        end
    end

    -- Bait shop: Left/Right = bait type, Up/Down = quantity, A = set active, B = buy
    if baitPrompt then
        if (ctrl.buttonPressed & U_JPAD) ~= 0 then
            baitBuyIndex = baitBuyIndex + 1
            if baitBuyIndex > #BAIT_AMOUNTS then baitBuyIndex = 1 end
        end
        if (ctrl.buttonPressed & D_JPAD) ~= 0 then
            baitBuyIndex = baitBuyIndex - 1
            if baitBuyIndex < 1 then baitBuyIndex = #BAIT_AMOUNTS end
        end
        if (ctrl.buttonPressed & L_JPAD) ~= 0 then
            baitTypeIndex = baitTypeIndex - 1
            if baitTypeIndex < 1 then baitTypeIndex = #BAIT_TYPES end
        end
        if (ctrl.buttonPressed & R_JPAD) ~= 0 then
            baitTypeIndex = baitTypeIndex + 1
            if baitTypeIndex > #BAIT_TYPES then baitTypeIndex = 1 end
        end
        if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            local bt = BAIT_TYPES[baitTypeIndex]
            equip_bait(pst, bt.id, false)
            shopCooldown = 12
        end
    end

    if baitPrompt and shopCooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
        local bt = BAIT_TYPES[baitTypeIndex] or BAIT_TYPES[1]
        local qty = BAIT_AMOUNTS[baitBuyIndex] or 1
        local owned = total_bait(pst)
        local room = MAX_BAIT - owned
        local wallet = get_wallet()
        if room <= 0 then
            djui_chat_message_create("Bait pouch is full!")
            shopCooldown = 18
        else
            if qty > room then qty = room end
            local cost = qty * bt.cost
            if wallet < cost then
                local canAfford = math.floor(wallet / bt.cost)
                if canAfford <= 0 then
                    djui_chat_message_create(string.format(
                        "Need $%d for %s. You have $%d / $%d.",
                        cost, bt.name, wallet, MAX_COINS
                    ))
                    shopCooldown = 18
                else
                    if canAfford > room then canAfford = room end
                    local paid = canAfford * bt.cost
                    spend_wallet(paid)
                    set_bait_count(pst, bt.id, get_bait_count(pst, bt.id) + canAfford)
                    if pst.activeBait == nil or get_bait_count(pst, pst.activeBait) <= 0 then
                        pst.activeBait = bt.id
                    end
                    shopCooldown = 18
                    sfx(SOUND_GENERAL_COIN, m)
                    djui_chat_message_create(string.format(
                        "Bought %dx %s (-$%d). Stock: %d  Balance: $%d / $%d",
                        canAfford, bt.name, paid, get_bait_count(pst, bt.id), get_wallet(), MAX_COINS
                    ))
                end
            else
                spend_wallet(cost)
                set_bait_count(pst, bt.id, get_bait_count(pst, bt.id) + qty)
                if get_bait_count(pst, pst.activeBait or 0) <= 0 then
                    pst.activeBait = bt.id
                end
                shopCooldown = 18
                sfx(SOUND_GENERAL_COIN, m)
                djui_chat_message_create(string.format(
                    "Bought %dx %s (-$%d). Stock: %d  Balance: $%d / $%d",
                    qty, bt.name, cost, get_bait_count(pst, bt.id), get_wallet(), MAX_COINS
                ))
            end
        end
    end

    if sellPrompt and shopCooldown == 0 then
        if (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            if #inventory > 0 then
                local earned, count = sell_all_fish(m)
                shopCooldown = 25
                if earned > 0 then
                    djui_chat_message_create(string.format("Sold %d fish for $%d! Balance: $%d / $%d", count, earned, get_wallet(), MAX_COINS))
                    sfx(SOUND_GENERAL_COIN, m)
                end
            else
                djui_chat_message_create("Nothing to sell. Go catch some fish!")
                shopCooldown = 20
            end
        elseif (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            if try_upgrade_rod(m) then
                shopCooldown = 25
            else
                shopCooldown = 18
            end
        end
    end

    pst.castPrompt = (pst.fishState == STATE_IDLE) and is_near_water(m) and is_standing_to_fish(m) and pst.bait > 0 and not shopPrompt and not cookPrompt

    cancel_if_needed(m, pst, ctrl)

    -- Hold L to aim (outline). Release L after a short hold to cast. No instant press-cast.
    local holdingL = (ctrl.buttonDown & L_TRIG) ~= 0
    local doCast = false

    if pst.castPrompt then
        if holdingL then
            aimHoldFrames = aimHoldFrames + 1
            wasHoldingL = true
            update_cast_aim_preview(m, true)
        else
            if wasHoldingL and aimHoldFrames >= AIM_MIN_HOLD then
                doCast = true
            end
            wasHoldingL = false
            aimHoldFrames = 0
            update_cast_aim_preview(m, false)
        end
    else
        wasHoldingL = false
        aimHoldFrames = 0
        update_cast_aim_preview(m, false)
    end

    if doCast then
        if not consume_active_bait(pst) then
            djui_chat_message_create("No bait left!")
            destroy_aim_marker()
        else
            local bt = get_bait_type(pst.activeBait or 1)
            pst.fishState = STATE_CASTING
            pst.fishTimer = 40
            pst.miniProgress = 0
            pst.caughtId = 0
            lockedPos = {x = m.pos.x, z = m.pos.z}
            destroy_aim_marker()
            spawn_rod_and_bobber(m)
            sfx(SOUND_ACTION_SPIN, m)
            djui_chat_message_create(string.format("Cast with %s! Bait left: %d", bt.name, total_bait(pst)))
        end
    end

    if pst.fishState == STATE_CASTING then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)
        pst.fishTimer = pst.fishTimer - 1
        if pst.fishTimer <= 0 then
            pst.fishState = STATE_WAITING
            local bt = get_bait_type(pst.activeBait or 1)
            local wait = math.random(70, 200) * (bt.waitMul or 1)
            pst.fishTimer = math.floor(wait)
            spawn_fish_near_bobber(m)
        end
    elseif pst.fishState == STATE_WAITING then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)
        pst.fishTimer = pst.fishTimer - 1
        if pst.fishTimer <= 0 then
            pst.fishState = STATE_BITE
            pst.biteTimer = 70
            biteFlash = 22
            sfx(SOUND_GENERAL_PAINTING_EJECT, m)
        end
    elseif pst.fishState == STATE_BITE then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)
        pst.biteTimer = pst.biteTimer - 1
        if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            pst.fishState = STATE_MINIGAME
            -- Fast reaction = easier start on the tension bar
            local reactionBonus = 18
            if pst.biteTimer > 45 then
                reactionBonus = 34
            elseif pst.biteTimer > 25 then
                reactionBonus = 26
            end
            pst.miniProgress = reactionBonus
            local fishData = roll_fish()
            local record = make_fish_record(fishData)
            pst.caughtId = record.id
            lastCaught = record
            currentDifficulty = fishData.difficulty or 1
            reelPulse = 12
            sfx(SOUND_ACTION_SWIM, m)
        elseif pst.biteTimer <= 0 then
            clear_cast_bait()
            reset_fishing_state(pst)
            catchStreak = 0
            djui_chat_message_create("The fish got away...")
        end
    elseif pst.fishState == STATE_MINIGAME then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)

        if currentDifficulty == 1 then
            if (ctrl.buttonDown & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 2.1
                reelPulse = 6
            else
                pst.miniProgress = pst.miniProgress - 0.85
            end
        elseif currentDifficulty == 2 then
            if (ctrl.buttonDown & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 1.35
                reelPulse = 6
            else
                pst.miniProgress = pst.miniProgress - 1.45
            end
        elseif currentDifficulty >= 5 then
            -- VOID: hardest - short presses only, fast drain, tiny gains
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 6.2
                reelPulse = 12
            end
            pst.miniProgress = pst.miniProgress - 1.15
        else
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 9.5
                reelPulse = 10
            end
            pst.miniProgress = pst.miniProgress - 0.75
        end

        if pst.miniProgress >= 100 then
            pst.fishState = STATE_CATCH
            clear_cast_bait()
            pst.fishTimer = 200
            if not add_to_inventory(lastCaught) then
                djui_chat_message_create("Inventory full! Sell fish at a market.")
                catchStreak = 0
            else
                catchStreak = catchStreak + 1
                local streakTxt = ""
                if catchStreak >= 3 then
                    streakTxt = string.format("  Streak x%d!", catchStreak)
                end
                local rareTxt = ""
                if (lastCaught.value or 0) >= 50 then
                    rareTxt = "  RARE!"
                end
                local voidWarn = ""
                if lastCaught.isVoid then
                    voidWarn = "  SELL SOON or it decays!"
                end
                djui_chat_message_create(string.format(
                    "Caught %s!  %.1f cm  %.1f kg  (+$%d)%s%s%s",
                    lastCaught.name or "Fish",
                    lastCaught.size or 0,
                    lastCaught.weight or 0,
                    lastCaught.value or 0,
                    rareTxt,
                    streakTxt,
                    voidWarn
                ))
            end
            check_personal_record(lastCaught)
            catchDisplayTimer = 200
            lockedPos = nil
            destroy_fishing_objects()
            sfx(SOUND_GENERAL_COIN, m)
        elseif pst.miniProgress <= 0 then
            clear_cast_bait()
            reset_fishing_state(pst)
            catchStreak = 0
            sfx(SOUND_OBJ_BOO_LAUGH_LONG, m)
            djui_chat_message_create("It snapped the line!")
        end
    elseif pst.fishState == STATE_CATCH then
        pst.fishTimer = pst.fishTimer - 1
        if pst.fishTimer <= 0 or (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            pst.fishState = STATE_IDLE
            pst.caughtId = 0
            lockedPos = nil
        end
    else
        if rodObj ~= nil or bobberObj ~= nil or fishObj ~= nil or rodTipObj ~= nil then
            destroy_fishing_objects()
        end
        lockedPos = nil
    end

    if pst.fishState ~= STATE_IDLE then
        local a = m.action
        if a == ACT_JUMP or a == ACT_DOUBLE_JUMP or a == ACT_TRIPLE_JUMP
            or a == ACT_LONG_JUMP or a == ACT_SIDE_FLIP or a == ACT_WALL_KICK_AIR
            or a == ACT_BACKFLIP or a == ACT_FREEFALL or a == ACT_STEEP_JUMP
            or a == ACT_GROUND_POUND or a == ACT_GROUND_POUND_LAND then
            set_mario_action(m, ACT_IDLE, 0)
            m.vel.y = 0
            m.forwardVel = 0
            m.vel.x = 0
            m.vel.z = 0
        end
    end
end

local function draw_text_centered(text, y, scale, r, g, b, a)
    local sw = djui_hud_get_screen_width()
    local w = djui_hud_measure_text(text) * scale
    djui_hud_set_color(r, g, b, a)
    djui_hud_print_text(text, (sw - w) * 0.5, y, scale)
end

local function on_hud_render()

    -- Castle Grounds travel boat prompt / destination selector.
    if get_current_level() == LEVEL_CASTLE_GROUNDS and travel_boat_is_valid(travelBoat) then
        local m = gMarioStates[0]
        if m ~= nil and not travelMenuOpen then
            local dx = m.pos.x - travelBoat.oPosX
            local dy = m.pos.y - travelBoat.oPosY
            local dz = m.pos.z - travelBoat.oPosZ
            if (dx * dx + dy * dy + dz * dz) <= (650 * 650) then
                djui_hud_set_color(255, 255, 255, 255)
                djui_hud_print_text("A: Board Boat", 22, 180, 0.5)
            end
        end
    end

    if travelMenuOpen then
        local sw = djui_hud_get_screen_width()
        local sh = djui_hud_get_screen_height()
        djui_hud_set_color(0, 0, 0, 210)
        djui_hud_render_rect(sw * 0.18, sh * 0.16, sw * 0.64, sh * 0.68)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("BOAT DESTINATIONS", sw * 0.25, sh * 0.21, 0.7)
        for i = 1, #TRAVEL_DESTINATIONS do
            local y = sh * 0.29 + (i - 1) * 22
            if i == travelIndex then
                djui_hud_set_color(255, 230, 80, 255)
                djui_hud_print_text("> " .. TRAVEL_DESTINATIONS[i].name, sw * 0.25, y, 0.5)
            else
                djui_hud_set_color(255, 255, 255, 220)
                djui_hud_print_text("  " .. TRAVEL_DESTINATIONS[i].name, sw * 0.25, y, 0.5)
            end
        end
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("Up/Down: Select   A: Travel   B: Cancel", sw * 0.25, sh * 0.78, 0.38)
    end
    local m = gMarioStates[0]
    if m == nil then
        return
    end

    local pst = ensure_sync()
    local sw = djui_hud_get_screen_width()
    local sh = djui_hud_get_screen_height()

    djui_hud_set_resolution(RESOLUTION_DJUI)
    djui_hud_set_font(FONT_MENU)

    if prBannerTimer > 0 then
        local bw = 480
        local bh = 92
        local bx = (sw - bw) * 0.5
        local by = 8

        djui_hud_set_color(0, 0, 0, 120)
        djui_hud_render_rect(bx + 4, by + 4, bw, bh)

        djui_hud_set_color(18, 22, 40, 245)
        djui_hud_render_rect(bx, by, bw, bh)

        djui_hud_set_color(255, 200, 50, 255)
        djui_hud_render_rect(bx, by, bw, 5)
        djui_hud_render_rect(bx, by + bh - 5, bw, 5)

        djui_hud_set_color(200, 170, 60, 255)
        djui_hud_render_rect(bx + 20, 0, 4, by + 5)
        djui_hud_render_rect(bx + bw - 24, 0, 4, by + 5)

        draw_text_centered("SESSION LARGEST CATCH!", by + 10, 0.42, 255, 220, 80, 255)
        draw_text_centered(string.format("%s caught a %s", prBannerData.player, prBannerData.name), by + 36, 0.4, 255, 255, 255, 255)
        draw_text_centered(string.format("%.1f cm   |   %.1f kg", prBannerData.size, prBannerData.weight), by + 60, 0.38, 160, 220, 255, 255)
    end

    if hotBannerTimer > 0 and hotBannerText ~= "" then
        local y = (prBannerTimer > 0) and 108 or 110
        local bw = 520
        local bh = 40
        local bx = (sw - bw) * 0.5
        djui_hud_set_color(40, 10, 50, 230)
        djui_hud_render_rect(bx, y, bw, bh)
        djui_hud_set_color(220, 120, 255, 255)
        djui_hud_render_rect(bx, y, bw, 3)
        draw_text_centered(hotBannerText, y + 10, 0.36, 255, 200, 255, 255)
    end

    init_session_sync_fields()
    if (gGlobalSyncTable.fdxHotLevel or 0) ~= 0 and hotBannerTimer <= 0 then
        local hl = gGlobalSyncTable.fdxHotLevel
        local here = get_current_level() == hl
        local label = "Rare: " .. level_display_name(hl)
        if here then
            label = "RARE HOTSPOT  +" .. tostring(gGlobalSyncTable.fdxHotLuck or 0) .. " luck"
        end
        djui_hud_set_color(here and 255 or 180, here and 140 or 160, 255, 200)
        djui_hud_print_text(label, 22, sh - 36, 0.28)
    end

    if pst.castPrompt then
        local spot = in_custom_spot(m)
        if spot ~= nil then
            draw_text_centered(spot.name, sh * 0.66, 0.42, 160, 220, 255, 230)
        end
        if aimActive then
            draw_text_centered("Release L to cast", sh * 0.72, 0.45, 255, 255, 140, 230)
        else
            draw_text_centered("Hold L to aim, release to cast", sh * 0.72, 0.48, 255, 255, 120, 230)
        end
        draw_text_centered("Press B to cancel while fishing", sh * 0.78, 0.35, 180, 180, 180, 180)
    end

    if showFishMap then
        local lines = get_fish_map_lines()
        local pages = math.max(1, math.ceil(#lines / FISH_MAP_PAGE_SIZE))
        if fishMapPage > pages then fishMapPage = pages end
        if fishMapPage < 1 then fishMapPage = 1 end
        local startI = (fishMapPage - 1) * FISH_MAP_PAGE_SIZE + 1
        local endI = math.min(#lines, startI + FISH_MAP_PAGE_SIZE - 1)

        local boxW = 520
        local boxH = 360
        local boxX = (sw - boxW) * 0.5
        local boxY = (sh - boxH) * 0.5

        djui_hud_set_color(0, 0, 0, 180)
        djui_hud_render_rect(0, 0, sw, sh)
        djui_hud_set_color(12, 18, 32, 250)
        djui_hud_render_rect(boxX, boxY, boxW, boxH)
        djui_hud_set_color(80, 180, 255, 255)
        djui_hud_render_rect(boxX, boxY, boxW, 5)
        djui_hud_render_rect(boxX, boxY + boxH - 5, boxW, 5)

        djui_hud_set_color(255, 220, 90, 255)
        djui_hud_print_text("FISH MAP", boxX + 18, boxY + 16, 0.55)
        djui_hud_set_color(180, 200, 220, 255)
        djui_hud_print_text(string.format("Page %d / %d", fishMapPage, pages), boxX + boxW - 140, boxY + 20, 0.35)

        local y = boxY + 55
        for i = startI, endI do
            local row = lines[i]
            if row ~= nil then
                if row.title then
                    djui_hud_set_color(255, 230, 120, 255)
                    djui_hud_print_text(row.text, boxX + 20, y, 0.4)
                    y = y + 26
                else
                    djui_hud_set_color(255, 255, 255, 255)
                    djui_hud_print_text(row.text, boxX + 20, y, 0.36)
                    y = y + 20
                    if row.sub ~= nil then
                        djui_hud_set_color(140, 200, 255, 255)
                        djui_hud_print_text(row.sub, boxX + 28, y, 0.3)
                        y = y + 22
                    end
                end
            end
        end

        djui_hud_set_color(160, 170, 190, 255)
        djui_hud_print_text("D-Pad: change page   |   B: close", boxX + 18, boxY + boxH - 32, 0.3)
    end

    if cookBoostTimer > 0 then
        local secs = math.ceil(cookBoostTimer / 30)
        djui_hud_set_color(40, 20, 10, 200)
        djui_hud_render_rect(18, 70, 220, 36)
        djui_hud_set_color(255, 160, 60, 255)
        djui_hud_print_text(string.format("Cooked boost: %ds", secs), 26, 78, 0.4)
    end

    -- Prompt when near a shop sign but shop not open yet
    if nearSignInfo ~= nil and activeShopKind == nil and pst.fishState == STATE_IDLE then
        djui_hud_set_color(0, 0, 0, 160)
        djui_hud_render_rect(sw * 0.22, sh * 0.60, sw * 0.56, sh * 0.14)
        draw_text_centered(nearSignInfo.label, sh * 0.62, 0.55, 255, 220, 100, 255)
        draw_text_centered("Press B to open", sh * 0.68, 0.42, 220, 255, 220, 255)
    end

    if shopPrompt then
        local atSell = near_sell_shop(m)
        local atBait = near_bait_shop(m)
        local atCook = near_fireplace(m)
        djui_hud_set_color(0, 0, 0, 170)
        djui_hud_render_rect(sw * 0.18, sh * 0.56, sw * 0.64, sh * 0.26)

        if atCook then
            draw_text_centered("FIREPLACE", sh * 0.58, 0.7, 255, 140, 60, 255)
            if #inventory > 0 then
                draw_text_centered("Press B to cook a fish", sh * 0.66, 0.5, 255, 220, 160, 255)
                draw_text_centered("Gain a 100s speed boost!", sh * 0.72, 0.42, 200, 255, 180, 255)
            else
                draw_text_centered("No fish to cook", sh * 0.66, 0.5, 200, 200, 200, 255)
                draw_text_centered("Catch some first!", sh * 0.72, 0.42, 180, 180, 180, 230)
            end
        elseif atSell then
            local total = get_inventory_value()
            local count = #inventory
            local style = get_rod_style()
            local nextTier = get_next_rod_tier()
            draw_text_centered("FISH MARKET", sh * 0.56, 0.65, 255, 210, 80, 255)
            if count > 0 then
                draw_text_centered("B: sell all fish", sh * 0.63, 0.42, 180, 255, 180, 255)
                draw_text_centered(string.format("%d fish  worth  %d coins", count, total), sh * 0.68, 0.38, 200, 230, 255, 255)
            else
                draw_text_centered("No fish to sell", sh * 0.63, 0.42, 200, 200, 200, 255)
            end
            draw_text_centered("Rod: " .. style.name .. "  |  Left D-Pad switch", sh * 0.73, 0.36, 255, 230, 140, 255)
            if nextTier ~= nil then
                draw_text_centered(string.format("A: unlock %s (%d coins)", nextTier.name, nextTier.cost), sh * 0.78, 0.34, 160, 220, 255, 255)
            else
                draw_text_centered("All rods unlocked", sh * 0.78, 0.34, 180, 255, 180, 255)
            end
        elseif atBait then
            local bt = BAIT_TYPES[baitTypeIndex] or BAIT_TYPES[1]
            local qty = BAIT_AMOUNTS[baitBuyIndex] or 1
            local cost = qty * bt.cost
            local owned = get_bait_count(pst, bt.id)
            local active = get_bait_type(pst.activeBait or 1)
            draw_text_centered("BAIT SHOP", sh * 0.545, 0.55, 255, 220, 80, 255)
            draw_text_centered(bt.name .. "  -  " .. bt.desc, sh * 0.595, 0.36, 200, 240, 255, 255)
            draw_text_centered(string.format("Buy x%d for %d coins  |  Owned: %d", qty, cost, owned), sh * 0.64, 0.38, 180, 255, 180, 255)
            draw_text_centered(string.format("Active: %s   Total bait: %d/%d", active.name, total_bait(pst), MAX_BAIT), sh * 0.685, 0.34, 255, 230, 140, 255)
            draw_text_centered("L/R type  Up/Down qty  A equip  B buy", sh * 0.73, 0.32, 210, 210, 210, 230)
            draw_text_centered(string.format("Balance: $%d / $%d", get_wallet(), MAX_COINS), sh * 0.77, 0.32, 255, 230, 100, 230)
        end
    end

    if biteFlash > 0 then
        local a = math.floor(biteFlash * 10)
        if a > 180 then a = 180 end
        djui_hud_set_color(255, 40, 40, a)
        djui_hud_render_rect(0, 0, sw, sh)
    end

    if pst.fishState == STATE_CASTING then
        draw_text_centered("Casting...", sh * 0.40, 0.7, 200, 220, 255, 255)
    end

    if pst.fishState == STATE_WAITING then
        draw_text_centered("Waiting for a bite...", sh * 0.40, 0.58, 180, 220, 255, 240)
    end

    if pst.fishState == STATE_BITE then
        local pulse = 1.2 + math.sin(get_global_timer() / 3) * 0.25
        draw_text_centered("BITE!", sh * 0.34, pulse, 255, 40, 40, 255)
        draw_text_centered("Press A!", sh * 0.48, 0.7, 255, 230, 80, 255)
    end

    if pst.fishState == STATE_MINIGAME then
        local panelW = 420
        local panelH = 150
        local panelX = (sw - panelW) * 0.5
        local panelY = sh * 0.48

        djui_hud_set_color(10, 14, 28, 230)
        djui_hud_render_rect(panelX, panelY, panelW, panelH)

        djui_hud_set_color(255, 200, 60, 255)
        djui_hud_render_rect(panelX, panelY, panelW, 4)
        djui_hud_render_rect(panelX, panelY + panelH - 4, panelW, 4)
        djui_hud_render_rect(panelX, panelY, 4, panelH)
        djui_hud_render_rect(panelX + panelW - 4, panelY, 4, panelH)

        local diffLabel = "EASY"
        local diffR, diffG, diffB = 120, 255, 140
        if currentDifficulty == 2 then
            diffLabel = "MEDIUM"
            diffR, diffG, diffB = 255, 210, 80
        elseif currentDifficulty == 3 then
            diffLabel = "HARD - SPAM A"
            diffR, diffG, diffB = 255, 90, 90
        end

        draw_text_centered(lastCaught.name or "Fish", panelY + 12, 0.55, 255, 255, 220, 255)
        draw_text_centered(diffLabel, panelY + 42, 0.4, diffR, diffG, diffB, 255)

        local barW = 360
        local barH = 28
        local barX = (sw - barW) * 0.5
        local barY = panelY + 72

        djui_hud_set_color(30, 30, 50, 255)
        djui_hud_render_rect(barX - 3, barY - 3, barW + 6, barH + 6)
        djui_hud_set_color(20, 20, 35, 255)
        djui_hud_render_rect(barX, barY, barW, barH)

        local fill = math.min(100, math.max(0, pst.miniProgress)) / 100
        local fillW = barW * fill
        local r = math.floor(255 * (1 - fill) + 80 * fill)
        local g = math.floor(60 + 180 * fill)
        local b = math.floor(40 + 40 * fill)
        if reelPulse > 0 then
            r = math.min(255, r + 40)
            g = math.min(255, g + 40)
        end
        djui_hud_set_color(r, g, b, 255)
        djui_hud_render_rect(barX, barY, fillW, barH)

        draw_text_centered(string.format("%d%%", math.floor(pst.miniProgress + 0.5)), barY + 4, 0.45, 255, 255, 255, 255)

        if currentDifficulty == 1 then
            draw_text_centered("Hold A to reel", panelY + 112, 0.38, 200, 255, 200, 230)
        elseif currentDifficulty == 2 then
            draw_text_centered("Hold A - don't let go!", panelY + 112, 0.38, 255, 230, 150, 230)
        else
            draw_text_centered("MASH A as fast as you can!", panelY + 112, 0.4, 255, 120, 120, 255)
        end
    end

    if pst.fishState == STATE_CATCH or catchDisplayTimer > 0 then
        local name = lastCaught.name
        if name == nil or name == "" then
            name = get_fish_name(pst.caughtId)
        end

        djui_hud_set_color(0, 0, 0, 180)
        djui_hud_render_rect(0, 0, sw, sh)

        local boxW = 480
        local boxH = 240
        local boxX = (sw - boxW) * 0.5
        local boxY = (sh - boxH) * 0.5

        djui_hud_set_color(25, 20, 12, 250)
        djui_hud_render_rect(boxX, boxY, boxW, boxH)
        djui_hud_set_color(255, 210, 70, 255)
        djui_hud_render_rect(boxX + 4, boxY + 4, boxW - 8, 5)
        djui_hud_render_rect(boxX + 4, boxY + boxH - 9, boxW - 8, 5)

        draw_text_centered("YOU CAUGHT A", boxY + 28, 0.5, 255, 245, 200, 255)
        draw_text_centered(name .. "!", boxY + 68, 0.95, 255, 255, 90, 255)
        draw_text_centered(string.format("Size: %.1f cm", lastCaught.size or 0), boxY + 120, 0.52, 180, 230, 255, 255)
        draw_text_centered(string.format("Weight: %.1f kg", lastCaught.weight or 0), boxY + 152, 0.52, 180, 230, 255, 255)
        draw_text_centered("Press A to continue", boxY + 195, 0.4, 200, 200, 200, 230)
    end

    if showInventory then
        local invW = 400
        local invH = 440
        local invX = sw - invW - 24
        local invY = 28

        djui_hud_set_color(12, 16, 28, 245)
        djui_hud_render_rect(invX, invY, invW, invH)

        -- Keep the inventory header dark so the title is readable and never uses black-on-yellow text.
        djui_hud_set_color(24, 32, 52, 255)
        djui_hud_render_rect(invX, invY, invW, 40)
        djui_hud_set_color(255, 220, 90, 255)
        djui_hud_print_text("FISH INVENTORY", invX + 16, invY + 10, 0.52)

        -- Give the wallet and rod their own rows. This prevents long values/names from overlapping.
        djui_hud_set_color(255, 230, 80, 255)
        djui_hud_print_text(string.format("Balance: $%d / $%d", get_wallet(), MAX_COINS), invX + 16, invY + 50, 0.36)

        local style = get_rod_style()
        local maxU = pst.rodMaxUnlocked or 1
        djui_hud_set_color(255, 200, 120, 255)
        djui_hud_print_text(string.format("Rod: %s (%d/%d)", style.name, rodTier, maxU), invX + 16, invY + 74, 0.34)

        local ab = get_bait_type(pst.activeBait or 1)
        djui_hud_set_color(140, 230, 255, 255)
        djui_hud_print_text(string.format("Bait: %d/%d  Active: %s", total_bait(pst), MAX_BAIT, ab.name), invX + 16, invY + 98, 0.34)
        djui_hud_set_color(160, 200, 220, 255)
        djui_hud_print_text(string.format("W:%d Cr:%d Mu:%d G:%d", pst.bait1 or 0, pst.bait2 or 0, pst.bait3 or 0, pst.bait4 or 0), invX + 16, invY + 118, 0.30)

        djui_hud_set_color(180, 255, 180, 255)
        djui_hud_print_text(string.format("Fish: %d / %d  (value %d)", #inventory, MAX_INVENTORY, get_inventory_value()), invX + 16, invY + 138, 0.36)

        if personalRecord.weight > 0 then
            djui_hud_set_color(255, 220, 100, 255)
            djui_hud_print_text(string.format("PR: %s  %.1f kg", personalRecord.name, personalRecord.weight), invX + 16, invY + 158, 0.34)
        end

        local yOff = 176
        if #inventory == 0 then
            djui_hud_set_color(180, 180, 200, 255)
            djui_hud_print_text("No fish caught yet", invX + 16, invY + yOff, 0.42)
        else
            for i = #inventory, 1, -1 do
                local rec = inventory[i]
                local line = string.format("%s  %.1fcm  %.1fkg", rec.name, rec.size, rec.weight)
                if rec.isVoid and rec.decayLeft ~= nil then
                    local secs = math.max(0, math.floor(rec.decayLeft / 30))
                    line = string.format("%s  %.1fcm  %.1fkg  [%ds]", rec.name, rec.size, rec.weight, secs)
                    if secs <= 30 then
                        djui_hud_set_color(255, 80, 80, 255)
                    else
                        djui_hud_set_color(200, 120, 255, 255)
                    end
                else
                    djui_hud_set_color(255, 255, 255, 255)
                end
                djui_hud_print_text(line, invX + 14, invY + yOff, 0.36)
                yOff = yOff + 24
                if yOff > invH - 55 then
                    djui_hud_set_color(200, 200, 220, 255)
                    djui_hud_print_text("...", invX + 14, invY + yOff, 0.36)
                    break
                end
            end
        end

        djui_hud_set_color(180, 180, 200, 255)
        djui_hud_print_text("Up/Down: equip bait  |  Right: close", invX + 12, invY + invH - 30, 0.32)
    end

    if pst.fishState ~= STATE_IDLE then
        djui_hud_set_color(255, 220, 90, 230)
        djui_hud_print_text("Rod out  |  B cancel", 22, 50, 0.36)
    end

    if pst.fishState == STATE_IDLE and not showInventory then
        djui_hud_set_color(255, 230, 80, 220)
        djui_hud_print_text(string.format("Balance: $%d / $%d", get_wallet(), MAX_COINS), 22, 18, 0.36)
        djui_hud_set_color(255, 255, 255, 210)
        djui_hud_print_text("Bait: " .. tostring(pst.bait), 22, 42, 0.38)
        local style = get_rod_style()
        djui_hud_set_color(200, 220, 255, 180)
        djui_hud_print_text("Rod: " .. style.name, 22, 66, 0.32)

        -- Urgent VOID decay warning on main HUD
        local voidMinLeft = nil
        for i = 1, #inventory do
            local r = inventory[i]
            if r ~= nil and r.isVoid and r.decayLeft ~= nil then
                if voidMinLeft == nil or r.decayLeft < voidMinLeft then
                    voidMinLeft = r.decayLeft
                end
            end
        end
        if voidMinLeft ~= nil then
            local secs = math.max(0, math.floor(voidMinLeft / 30))
            if secs <= 30 then
                djui_hud_set_color(255, 60, 60, 255)
            else
                djui_hud_set_color(200, 100, 255, 230)
            end
            djui_hud_print_text(string.format("VOID decays in %ds - sell for coins!", secs), 22, 90, 0.34)
        end
    end
end

local function before_set_mario_action(m, action)
    if m.playerIndex ~= 0 then
        return
    end
    local pst = ensure_sync()
    if pst.fishState ~= STATE_IDLE and pst.fishState ~= STATE_CATCH then
        if action == ACT_JUMP or action == ACT_DOUBLE_JUMP or action == ACT_TRIPLE_JUMP
            or action == ACT_LONG_JUMP or action == ACT_SIDE_FLIP or action == ACT_WALL_KICK_AIR
            or action == ACT_BACKFLIP or action == ACT_STEEP_JUMP or action == ACT_GROUND_POUND then
            return 1
        end
    end
end

local function on_level_init()
    local pst = ensure_sync()
    reset_fishing_state(pst)
    fix_active_bait(pst)
    shopSignsSpawned = false
    lastShopLevel = -1
    showInventory = false
    destroy_fire_objs()
    destroy_lake_decor()
    clear_shop_sign_objs()
    activeShopKind = nil
    close_travel_menu()
    clear_travel_boat()
    -- Persist on level load so progress is not lost mid-session
    save_progress()
end

local function on_warp()
    local pst = ensure_sync()
    reset_fishing_state(pst)
    fix_active_bait(pst)
    shopSignsSpawned = false
    lastShopLevel = -1
    destroy_fire_objs()
    destroy_lake_decor()
    clear_shop_sign_objs()
    activeShopKind = nil
    close_travel_menu()
    clear_travel_boat()
    save_progress()
end

local function on_fishing_command(msg)
    msg = string.lower(msg or "")
    if msg == "" or msg == "help" then
        djui_chat_message_create("Fishing DX v" .. VERSION .. " by CrypticTM")
        djui_chat_message_create("Hold L aim, release to cast  |  A: bite/reel  |  B: cancel (returns bait) / shop")
        djui_chat_message_create("Mod Menu: Fish Map  |  /fishing map  |  /fishing hot")
        djui_chat_message_create("Market: B sell, A unlock rod  |  Left D-Pad: switch rod")
        djui_chat_message_create("Inventory: Right D-Pad  |  Up/Down equip bait")
        djui_chat_message_create("Rods: Wood>Metal>Gold>Master>Legendary(1500)")
        djui_chat_message_create("Rare hotspot rotates about every 10 minutes")
        djui_chat_message_create("Host: /fishing give <player> <bait> [amount]")
        djui_chat_message_create("VOID Fish decays ~3 min - sell fast")
        return true
    elseif msg == "bait" then
        local pst = ensure_sync()
        fix_active_bait(pst)
        local ab = get_bait_type(pst.activeBait or 1)
        djui_chat_message_create(string.format(
            "Active: %s  |  W:%d Cr:%d Mu:%d G:%d  total %d/%d",
            ab.name, pst.bait1 or 0, pst.bait2 or 0, pst.bait3 or 0, pst.bait4 or 0,
            total_bait(pst), MAX_BAIT
        ))
        return true
    elseif msg == "save" then
        save_progress()
        djui_chat_message_create("Progress saved.")
        return true
    elseif msg == "map" or msg == "fish" or msg == "locations" then
        open_fish_map()
        djui_chat_message_create("Fish map opened (also in Mod Menu).")
        return true
    elseif msg == "hot" or msg == "rare" then
        init_session_sync_fields()
        local hl = gGlobalSyncTable.fdxHotLevel or 0
        if hl == 0 then
            djui_chat_message_create("Hot stage not rolled yet.")
        else
            djui_chat_message_create(string.format(
                "Hot rare stage: %s  (+%d luck)",
                level_display_name(hl), gGlobalSyncTable.fdxHotLuck or 0
            ))
        end
        local swt = gGlobalSyncTable.fdxSessionWeight or 0
        if swt > 0 then
            djui_chat_message_create(string.format(
                "Session PR: %s - %s %.1f kg",
                gGlobalSyncTable.fdxSessionPlayer or "?",
                gGlobalSyncTable.fdxSessionName or "Fish",
                swt
            ))
        else
            djui_chat_message_create("No session largest catch yet.")
        end
        return true
    elseif msg == "pr" or msg == "record" then
        if personalRecord.weight > 0 then
            djui_chat_message_create(string.format("Largest catch: %s (%.1f cm, %.1f kg)", personalRecord.name, personalRecord.size, personalRecord.weight))
        else
            djui_chat_message_create("No personal record yet. Go fish!")
        end
        return true
    elseif msg == "inv" or msg == "inventory" then
        djui_chat_message_create(string.format("Fish in inventory: %d / %d  (value %d coins)", #inventory, MAX_INVENTORY, get_inventory_value()))
        return true
    elseif msg == "rod" then
        local style = get_rod_style()
        local nextTier = get_next_rod_tier()
        if nextTier ~= nil then
            djui_chat_message_create(string.format("Rod: %s  |  Next: %s (%d coins)", style.name, nextTier.name, nextTier.cost))
        else
            djui_chat_message_create("Rod: Master (max)")
        end
        return true
    end

    -- Host only: /fishing give <player> <bait> [amount]
    -- bait: worm/1, cricket/2, mushroom/3, golden/4
    local giveArgs = {}
    for token in string.gmatch(msg, "%S+") do
        table.insert(giveArgs, token)
    end
    if giveArgs[1] == "give" or giveArgs[1] == "givebait" then
        local isServer = true
        if network_is_server ~= nil then isServer = network_is_server() end
        if not isServer then
            djui_chat_message_create("Only the host can give bait.")
            return true
        end
        if #giveArgs < 3 then
            djui_chat_message_create("Usage: /fishing give <player> <bait> [amount]")
            djui_chat_message_create("Bait: worm, cricket, mushroom, golden (or 1-4)")
            return true
        end

        local targetName = giveArgs[2]
        local baitToken = giveArgs[3]
        local amount = tonumber(giveArgs[4] or "5") or 5
        amount = math.floor(amount)
        if amount < 1 then amount = 1 end
        if amount > MAX_BAIT then amount = MAX_BAIT end

        local baitId = nil
        local lower = string.lower(baitToken)
        if lower == "1" or lower == "worm" or lower == "worms" then baitId = 1
        elseif lower == "2" or lower == "cricket" or lower == "crickets" then baitId = 2
        elseif lower == "3" or lower == "mushroom" or lower == "mushrooms" or lower == "super" then baitId = 3
        elseif lower == "4" or lower == "golden" or lower == "gold" or lower == "lure" then baitId = 4
        else
            baitId = tonumber(baitToken)
        end
        if baitId == nil or baitId < 1 or baitId > #BAIT_TYPES then
            djui_chat_message_create("Unknown bait. Use worm, cricket, mushroom, golden (or 1-4).")
            return true
        end

        local function player_name(i)
            local np = gNetworkPlayers[i]
            if np == nil then return nil end
            if np.connected == false then return nil end
            if np.name ~= nil and np.name ~= "" then return np.name end
            return "Player " .. tostring(i)
        end

        local targetIdx = nil
        local tlow = string.lower(targetName)
        -- numeric index
        local asNum = tonumber(targetName)
        if asNum ~= nil then
            local n = math.floor(asNum)
            if gNetworkPlayers[n] ~= nil and gNetworkPlayers[n].connected ~= false then
                targetIdx = n
            end
        end
        if targetIdx == nil then
            for i = 0, (MAX_PLAYERS or 16) - 1 do
                local pname = player_name(i)
                if pname ~= nil and string.find(string.lower(pname), tlow, 1, true) then
                    targetIdx = i
                    break
                end
            end
        end
        if targetIdx == nil then
            djui_chat_message_create("Player not found: " .. targetName)
            return true
        end

        local pst = gPlayerSyncTable[targetIdx]
        if pst == nil then
            djui_chat_message_create("Could not access that player's data.")
            return true
        end

        -- Ensure bait fields exist on their sync table
        if pst.bait1 == nil then pst.bait1 = 0 end
        if pst.bait2 == nil then pst.bait2 = 0 end
        if pst.bait3 == nil then pst.bait3 = 0 end
        if pst.bait4 == nil then pst.bait4 = 0 end

        local function getc(id)
            if id == 1 then return pst.bait1 or 0 end
            if id == 2 then return pst.bait2 or 0 end
            if id == 3 then return pst.bait3 or 0 end
            if id == 4 then return pst.bait4 or 0 end
            return 0
        end
        local function setc(id, n)
            if n < 0 then n = 0 end
            if n > MAX_BAIT then n = MAX_BAIT end
            if id == 1 then pst.bait1 = n
            elseif id == 2 then pst.bait2 = n
            elseif id == 3 then pst.bait3 = n
            elseif id == 4 then pst.bait4 = n end
            pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
        end

        local before = getc(baitId)
        local room = MAX_BAIT - before
        if room <= 0 then
            djui_chat_message_create("That player is already at the bait cap for this type.")
            return true
        end
        local give = amount
        if give > room then give = room end
        setc(baitId, before + give)

        local bt = get_bait_type(baitId)
        local pname = player_name(targetIdx) or ("#" .. tostring(targetIdx))
        djui_chat_message_create(string.format("Gave %s x%d %s (now %d).", pname, give, bt.name, before + give))
        return true
    end

    djui_chat_message_create("Usage: /fishing [help|bait|pr|inv|rod|map|hot|give]")
    return true
end

local function is_fishing_prop(obj)
    if obj == nil then return false end
    if obj == rodObj or obj == rodTipObj or obj == bobberObj or obj == fishObj then
        return true
    end
    for i = 1, #lakeDecor do
        if lakeDecor[i] == obj then return true end
    end
    for i = 1, #shopSignObjs do
        if shopSignObjs[i] == obj then return true end
    end
    return false
end

local function allow_interact(m, obj, interactType)
    if is_fishing_prop(obj) then
        return false
    end
    return true
end
local function on_mod_menu_fish_map(index)
    open_fish_map()
    djui_chat_message_create("Fish map opened. Left/Right D-Pad: pages. Right D-Pad again or menu button to close.")
end

local function on_mod_menu_fish_list_chat(index)
    local lines = get_fish_map_lines()
    djui_chat_message_create("--- Fish Location Map ---")
    for i = 1, #FISH do
        local f = FISH[i]
        djui_chat_message_create(string.format("%s: %s", f.name, fish_location_text(f)))
    end
end

if hook_mod_menu_text ~= nil then
    hook_mod_menu_text("Fishing DX - Fish Map")
    hook_mod_menu_text("Locations for every fish type")
end
if hook_mod_menu_button ~= nil then
    hook_mod_menu_button("Open Fish Map (HUD)", on_mod_menu_fish_map)
    hook_mod_menu_button("Print Fish Map (Chat)", on_mod_menu_fish_list_chat)
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_chat_command("fishing", "[help|bait|pr|inv|rod|map|hot|give] Fishing DX", on_fishing_command)
