-- name: Fishing DX v1.2.1
-- description: A full fishing mod for sm64coopdx by CrypticTM. Catch fish across stages, upgrade rods, cook meals, and sell your haul. Up to 38 different types of fish. 
-- incompatible: 

local VERSION = "1.2.1"

function sfx(sound, m)
    if sound == nil or m == nil or m.marioObj == nil then
        return
    end
    play_sound(sound, m.marioObj.header.gfx.cameraToObject)
end

local BASE_MAX_COINS = 10000
local BASE_MAX_BAIT = 40
local BASE_MAX_INVENTORY = 50
local MAX_PRESTIGE = 5

function current_prestige()
    local pst = gPlayerSyncTable[0]
    if pst == nil then return 0 end
    local p = math.floor(tonumber(pst.prestige) or 0)
    if p < 0 then p = 0 end
    if p > MAX_PRESTIGE then p = MAX_PRESTIGE end
    return p
end

function get_max_coins()
    return BASE_MAX_COINS + current_prestige() * 5000
end

function get_max_bait()
    return BASE_MAX_BAIT + current_prestige() * 5
end

function get_max_inventory()
    return BASE_MAX_INVENTORY + current_prestige() * 20
end

local DEV_MODE = false
local HARD_MODE_SELL_MULT = 2

-- Castle Grounds fishing guide 
local E_MODEL_FISHING_LUIGI = nil
function load_fishing_luigi_model()
    if E_MODEL_FISHING_LUIGI ~= nil then
        return E_MODEL_FISHING_LUIGI
    end
    if smlua_model_util_get_id ~= nil then
        local names = {
            "luigi_geo",
            "luigi",
        }
        for i = 1, #names do
            local ok, id = pcall(smlua_model_util_get_id, names[i])
            if ok and id ~= nil and id ~= 0 and (E_MODEL_NONE == nil or id ~= E_MODEL_NONE) then
                E_MODEL_FISHING_LUIGI = id
                return E_MODEL_FISHING_LUIGI
            end
        end
    end
    if E_MODEL_LUIGI ~= nil and E_MODEL_LUIGI ~= E_MODEL_NONE then
        E_MODEL_FISHING_LUIGI = E_MODEL_LUIGI
    elseif E_MODEL_MARIO ~= nil then
        E_MODEL_FISHING_LUIGI = E_MODEL_MARIO
    end
    return E_MODEL_FISHING_LUIGI
end



-- Wooden rod: actors/woodrod (GeoLayout woodrod_geo[])
local E_MODEL_WOODROD_GEO = nil
local woodRodAttempts = 0
function load_wood_rod_model()
    if E_MODEL_WOODROD_GEO ~= nil then
        return E_MODEL_WOODROD_GEO
    end

    if smlua_model_util_get_id ~= nil then
        local names = {
            "woodrod_geo",
            "woodrod",
        }
        for i = 1, #names do
            local ok, id = pcall(smlua_model_util_get_id, names[i])
            if ok and id ~= nil and id ~= 0 and (E_MODEL_NONE == nil or id ~= E_MODEL_NONE) then
                E_MODEL_WOODROD_GEO = id
                return E_MODEL_WOODROD_GEO
            end
        end
    end

    woodRodAttempts = woodRodAttempts + 1
    if woodRodAttempts < 90 then
        return E_MODEL_BREAKABLE_BOX_SMALL or E_MODEL_METAL_BOX
    end

    E_MODEL_WOODROD_GEO = E_MODEL_BREAKABLE_BOX_SMALL or E_MODEL_METAL_BOX
    return E_MODEL_WOODROD_GEO
end

local E_MODEL_CAMPFIRE_GEO = nil
local campfireLoadAttempts = 0
function load_campfire_model()
    if E_MODEL_CAMPFIRE_GEO ~= nil then
        return E_MODEL_CAMPFIRE_GEO
    end
    if campfireLoadAttempts > 40 then
        return nil
    end
    campfireLoadAttempts = campfireLoadAttempts + 1
    if smlua_model_util_get_id ~= nil then
        local names = {
            "campfire_geo",
            "campfire",
            "actors/campfire_geo",
            "actors/campfire",
        }
        for i = 1, #names do
            local ok, id = pcall(smlua_model_util_get_id, names[i])
            if ok and id ~= nil and id ~= 0 and (E_MODEL_NONE == nil or id ~= E_MODEL_NONE) then
                E_MODEL_CAMPFIRE_GEO = id
                return E_MODEL_CAMPFIRE_GEO
            end
        end
    end
    return nil
end

-- Legendary rod: actors/fishingrod_legendary (GeoLayout fishingrod_legendary_geo[])
local E_MODEL_FISHINGROD_LEGENDARY_GEO = nil
local legendaryRodAttempts = 0
function load_legendary_rod_model()
    if E_MODEL_FISHINGROD_LEGENDARY_GEO ~= nil then
        return E_MODEL_FISHINGROD_LEGENDARY_GEO
    end

    if smlua_model_util_get_id ~= nil then
        local names = {
            "fishingrod_legendary_geo",
            "fishingrod_legendary",
        }
        for i = 1, #names do
            local ok, id = pcall(smlua_model_util_get_id, names[i])
            if ok and id ~= nil and id ~= 0 and (E_MODEL_NONE == nil or id ~= E_MODEL_NONE) then
                E_MODEL_FISHINGROD_LEGENDARY_GEO = id
                return E_MODEL_FISHINGROD_LEGENDARY_GEO
            end
        end
    end

    legendaryRodAttempts = legendaryRodAttempts + 1
    if legendaryRodAttempts < 90 then
        return E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX_SMALL
    end

    E_MODEL_FISHINGROD_LEGENDARY_GEO = E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX_SMALL
    return E_MODEL_FISHINGROD_LEGENDARY_GEO
end

-- Gold rod: actors/pole (pole_geo). Loaded via smlua_model_util_get_id at runtime.
local E_MODEL_POLE_GEO = nil
function load_gold_pole_model()
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

-- Metal rod: actors/metalpole (GeoLayout metalpole_geo[])
local E_MODEL_METALPOLE_GEO = nil
local metalPoleAttempts = 0
function load_metal_pole_model()
    if E_MODEL_METALPOLE_GEO ~= nil then
        return E_MODEL_METALPOLE_GEO
    end

    if smlua_model_util_get_id ~= nil then
                local names = {
            "metalpole_geo",
            "metalpole",
        }
        for i = 1, #names do
            local ok, id = pcall(smlua_model_util_get_id, names[i])
            if ok and id ~= nil and id ~= 0 and (E_MODEL_NONE == nil or id ~= E_MODEL_NONE) then
                E_MODEL_METALPOLE_GEO = id
                return E_MODEL_METALPOLE_GEO
            end
        end
    end

    metalPoleAttempts = metalPoleAttempts + 1
    if metalPoleAttempts < 90 then
        return E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX_SMALL
    end

    E_MODEL_METALPOLE_GEO = E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX_SMALL
    return E_MODEL_METALPOLE_GEO
end

-- Master rod: actors/masterpole (GeoLayout masterpole_geo[])
local E_MODEL_MASTERPOLE_GEO = nil
local masterPoleAttempts = 0
function load_master_pole_model()
    if E_MODEL_MASTERPOLE_GEO ~= nil then
        return E_MODEL_MASTERPOLE_GEO
    end

    if smlua_model_util_get_id ~= nil then
        local names = {
            "masterpole_geo",
            "masterpole",
        }
        for i = 1, #names do
            local ok, id = pcall(smlua_model_util_get_id, names[i])
            if ok and id ~= nil and id ~= 0 and (E_MODEL_NONE == nil or id ~= E_MODEL_NONE) then
                E_MODEL_MASTERPOLE_GEO = id
                return E_MODEL_MASTERPOLE_GEO
            end
        end
    end

    masterPoleAttempts = masterPoleAttempts + 1
    if masterPoleAttempts < 90 then
        return E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX_SMALL
    end

    E_MODEL_MASTERPOLE_GEO = E_MODEL_METAL_BOX or E_MODEL_BREAKABLE_BOX_SMALL
    return E_MODEL_MASTERPOLE_GEO
end

-- Custom boat mesh: actors/Boat -> GeoLayout Boat_geo[]
local E_MODEL_BOAT_GEO = nil
local boatModelCustom = false
local boatModelRetryTimer = 0
function load_boat_model()
    if E_MODEL_BOAT_GEO ~= nil and boatModelCustom then
        return E_MODEL_BOAT_GEO
    end
    if smlua_model_util_get_id ~= nil then
        local names = {
            "Boat_geo",
            "Boat",
            "boat_geo",
            "boat",
        }
        for i = 1, #names do
            local id = smlua_model_util_get_id(names[i])
            if id ~= nil and id ~= 0 then
                if E_MODEL_NONE == nil or id ~= E_MODEL_NONE then
                    E_MODEL_BOAT_GEO = id
                    boatModelCustom = true
                    return E_MODEL_BOAT_GEO
                end
            end
        end
    end
    -- Visible vanilla fallback (still usable as stage selector)
    if E_MODEL_JRB_SHIP_LEFT_HALF_PART ~= nil then
        E_MODEL_BOAT_GEO = E_MODEL_JRB_SHIP_LEFT_HALF_PART
    elseif E_MODEL_JRB_SHIP_RIGHT_HALF_PART ~= nil then
        E_MODEL_BOAT_GEO = E_MODEL_JRB_SHIP_RIGHT_HALF_PART
    elseif E_MODEL_WOODEN_POST ~= nil then
        E_MODEL_BOAT_GEO = E_MODEL_WOODEN_POST
    else
        E_MODEL_BOAT_GEO = E_MODEL_METAL_BOX
    end
    boatModelCustom = false
    return E_MODEL_BOAT_GEO
end

-- Hollowfin custom catch sprite (textures/hollowfin.png)
local TEX_HOLLOWFIN = nil
local TEX_HOLLOWFIN_TRIED = false
function load_hollowfin_texture()
    if TEX_HOLLOWFIN ~= nil then
        return TEX_HOLLOWFIN
    end
    if TEX_HOLLOWFIN_TRIED and TEX_HOLLOWFIN == nil then
        -- still allow retry a few times in case assets load late
    end
    TEX_HOLLOWFIN_TRIED = true
    if get_texture_info == nil then
        return nil
    end
    local names = {
        "textures/hollowfin",
        "hollowfin",
        "textures/fishA",
        "fishA",
    }
    for i = 1, #names do
        local ok, tex = pcall(get_texture_info, names[i])
        if ok and tex ~= nil then
            TEX_HOLLOWFIN = tex
            return TEX_HOLLOWFIN
        end
    end
    return nil
end

local HOLLOWFIN_ID = 25

function is_hollowfin_active()
    local pst = gPlayerSyncTable[0]
    if pst == nil then return false end
    if (pst.caughtId or 0) == HOLLOWFIN_ID then return true end
    if ui ~= nil and ui.lastCaught ~= nil then
        if ui.lastCaught.id == HOLLOWFIN_ID or ui.lastCaught.isMystery then
            -- only treat as hollowfin during an active fight / catch flash
            if pst.fishState == STATE.MINIGAME or pst.fishState == STATE.CATCH then
                if ui.lastCaught.id == HOLLOWFIN_ID then return true end
            end
        end
    end
    return false
end

-- Rod tiers. cost = wallet to unlock. luck = rare bias. Gold uses pole_geo.
local ROD_TIERS = {
    {name = "Wood",      body = nil,                         bx = 0.20, by = 0.14, bz = 0.07, cost = 0,    luck = 0,  useWoodRod = true},
    {name = "Metal",     body = nil,                         bx = 0.20, by = 0.20, bz = 0.20, cost = 40,   luck = 6,  useMetalPole = true},
    {name = "Steel",     body = nil,                         bx = 0.20, by = 0.20, bz = 0.20, cost = 40,   luck = 5,  useMetalPole = true},
    {name = "Iron",      body = nil,                         bx = 0.20, by = 0.20, bz = 0.20, cost = 80,   luck = 8,  useMetalPole = true},
    {name = "Gold",      body = nil,                         bx = 0.20, by = 0.20, bz = 0.20, cost = 100,  luck = 14, useGoldPole = true},
    {name = "Master",    body = nil,                         bx = 0.20, by = 0.20, bz = 0.20, cost = 200,  luck = 25, useMasterPole = true},
    {name = "Legendary", body = nil,
     -- Keep the legendary mesh compact and bring it forward into Mario's hands.
     bx = 0.0035, by = 0.0035, bz = 0.0035,
     ox = -8.7, oy = 0, oz = -10.0,
     cost = 1500, luck = 40, useLegendaryRod = true},
    -- Uses masterpole geo until a dedicated mesh exists
    {name = "Mythic", body = nil,
     bx = 0.20, by = 0.20, bz = 0.20,
     cost = 3000, luck = 55, useMasterPole = true},
}

local rodTier = 1

local COOK_BOOST_FRAMES = 3000
local cook = {
    boostTimer = 0,
    rareTimer = 0,
    rareBonus = 0,
    luckTimer = 0,
    luckBonus = 0,
    jumpTimer = 0,
    jumpBonus = 0,
    fireObjs = {},
    fireSpawned = false,
    fireLevel = -1,
    campfireObj = nil,
    prompt = false,
    cooldown = 0,
    menuOpen = false,
    selectedIndex = 1,
}

local STATE = {
    IDLE = 0,
    CASTING = 1,
    WAITING = 2,
    BITE = 3,
    MINIGAME = 4,
    CATCH = 5,
}

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
    -- CCM bottom pond + also catchable on Peach's Slide
    {id = 12, name = "Ice Minnow",     rarity = 14, value = 15,  minSize = 14, maxSize = 26, minWeight = 0.8, maxWeight = 2.4, difficulty = 1, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    {id = 13, name = "Penguin Puffer", rarity = 6,  value = 48,  minSize = 30, maxSize = 52, minWeight = 4.0, maxWeight = 11.0, difficulty = 2, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    {id = 14, name = "Frosty Unagi",   rarity = 4,  value = 75,  minSize = 45, maxSize = 80, minWeight = 8.0, maxWeight = 22.0, difficulty = 3, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    -- VOID fish: Peach's Slide only. Rare, hardest, decays in inventory if not sold in time.
    {id = 15, name = "VOID Fish",      rarity = 3,  value = 220, minSize = 40, maxSize = 70, minWeight = 12.0, maxWeight = 35.0, difficulty = 5, onlyLevel = LEVEL_PSS, isVoid = true, decayFrames = 5400},
    -- Fire fish: Lethal Lava Land only
    {id = 16, name = "Magma Cheep",    rarity = 16, value = 22,  minSize = 16, maxSize = 30, minWeight = 1.0, maxWeight = 3.5, difficulty = 1, onlyLevel = LEVEL_LLL},
    {id = 17, name = "Podoboo Piranha",rarity = 10, value = 32,  minSize = 20, maxSize = 36, minWeight = 1.5, maxWeight = 5.0, difficulty = 2, onlyLevel = LEVEL_LLL},
    {id = 18, name = "Lava Eel",       rarity = 7,  value = 55,  minSize = 35, maxSize = 65, minWeight = 4.0, maxWeight = 14.0, difficulty = 2, onlyLevel = LEVEL_LLL},
    {id = 19, name = "Flame Bass",     rarity = 4,  value = 85,  minSize = 28, maxSize = 50, minWeight = 3.5, maxWeight = 10.0, difficulty = 3, onlyLevel = LEVEL_LLL},
    {id = 20, name = "Blargg",         rarity = 2,  value = 140, minSize = 50, maxSize = 90, minWeight = 18.0, maxWeight = 42.0, difficulty = 4, onlyLevel = LEVEL_LLL},
    -- Tower of the Wing Cap: cloudy edge pool
    {id = 21, name = "Angel Fish",     rarity = 14, value = 22,  minSize = 16, maxSize = 28, minWeight = 0.8, maxWeight = 2.5, difficulty = 1, onlyLevel = LEVEL_TOTWC},
    {id = 22, name = "Angel Swimmer",  rarity = 9,  value = 38,  minSize = 22, maxSize = 40, minWeight = 1.5, maxWeight = 4.5, difficulty = 2, onlyLevel = LEVEL_TOTWC},
    {id = 23, name = "Glory Fish",     rarity = 5,  value = 70,  minSize = 25, maxSize = 45, minWeight = 2.0, maxWeight = 6.0, difficulty = 3, onlyLevel = LEVEL_TOTWC},
    {id = 24, name = "Sunmo-rae",      rarity = 2,  value = 160, minSize = 30, maxSize = 55, minWeight = 3.0, maxWeight = 9.0, difficulty = 4, onlyLevel = LEVEL_TOTWC},
    -- Tall Tall Mountain only. 6% bite chance, hardest fight, global announce on catch.
    {id = 25, name = "Hollowfin",      rarity = 1,  value = 300, minSize = 55, maxSize = 95, minWeight = 22.0, maxWeight = 55.0, difficulty = 5, onlyLevel = LEVEL_TTM, isMystery = true},
    -- Dire Dire Docks fish
    {id = 26, name = "Dreadmaw",       rarity = 4,  value = 175, minSize = 60, maxSize = 110, minWeight = 28.0, maxWeight = 65.0, difficulty = 4, onlyLevel = LEVEL_DDD},
    {id = 27, name = "Moonveil Ray",   rarity = 6,  value = 95,  minSize = 45, maxSize = 85,  minWeight = 12.0, maxWeight = 30.0, difficulty = 3, onlyLevel = LEVEL_DDD},
    -- Bob-omb Battlefield
    {id = 28, name = "Koopa Catfish",  rarity = 8,  value = 42,  minSize = 24, maxSize = 44, minWeight = 2.5, maxWeight = 8.0, difficulty = 2, onlyLevel = LEVEL_BOB},
    -- Dire Dire Docks trophy shark
    {id = 29, name = "Henry the Shark", rarity = 2, value = 340, minSize = 70, maxSize = 120, minWeight = 35.0, maxWeight = 80.0, difficulty = 4, onlyLevel = LEVEL_DDD},
    {id = 30, name = "Ga. Fish",    rarity = 4 , value = 200, minSize = 30, maxSize = 100, minWeight = 15.0, maxWeight = 40.0, difficulty = 5, onlyLevel = LEVEL_BOB, isGa = true},
    {id = 31, name = "Bubble Bass",     rarity = 7,  value = 55,  minSize = 28, maxSize = 50, minWeight = 3.0, maxWeight = 10.0, difficulty = 2, onlyLevel = LEVEL_TTC},
    {id = 32, name = "Whippersnapper",  rarity = 5,  value = 80,  minSize = 22, maxSize = 40, minWeight = 2.0, maxWeight = 7.0, difficulty = 3, onlyLevel = LEVEL_TTC},
    {id = 33, name = "Drybones Shark",  rarity = 3,  value = 160, minSize = 55, maxSize = 95, minWeight = 18.0, maxWeight = 42.0, difficulty = 4, onlyLevel = LEVEL_RR},
    {id = 34, name = "Prismwraith",    rarity = 1,  value = 320, minSize = 50, maxSize = 90, minWeight = 20.0, maxWeight = 50.0, difficulty = 5, onlyLevel = LEVEL_RR, isMystery = true},
    {id = 35, name = "Kelp Skipper",     rarity = 18, value = 9,   minSize = 14, maxSize = 26, minWeight = 0.7, maxWeight = 2.2, difficulty = 1},
    {id = 36, name = "Spiny Snapper",    rarity = 11, value = 26,  minSize = 20, maxSize = 38, minWeight = 1.8, maxWeight = 5.5, difficulty = 2},
    {id = 37, name = "Moat Minnow",      rarity = 14, value = 14,  minSize = 10, maxSize = 18, minWeight = 0.4, maxWeight = 1.4, difficulty = 1, onlyLevel = LEVEL_CASTLE_GROUNDS},
    {id = 38, name = "Bay Lantern",      rarity = 8,  value = 48,  minSize = 22, maxSize = 40, minWeight = 2.0, maxWeight = 6.5, difficulty = 2, onlyLevel = LEVEL_JRB},
    {id = 39, name = "Dock Stalker",     rarity = 5,  value = 95,  minSize = 40, maxSize = 75, minWeight = 8.0, maxWeight = 22.0, difficulty = 3, onlyLevel = LEVEL_DDD},
    {id = 40, name = "Battlefield Pike", rarity = 7,  value = 52,  minSize = 28, maxSize = 50, minWeight = 3.0, maxWeight = 9.5, difficulty = 2, onlyLevel = LEVEL_BOB},
    {id = 41, name = "Glacier Trout",    rarity = 9,  value = 38,  minSize = 18, maxSize = 34, minWeight = 1.2, maxWeight = 4.0, difficulty = 2, onlyLevels = {LEVEL_CCM, LEVEL_PSS}},
    {id = 42, name = "Wingcap Wisp",     rarity = 4,  value = 110, minSize = 20, maxSize = 42, minWeight = 1.5, maxWeight = 5.0, difficulty = 3, onlyLevel = LEVEL_TOTWC},

    -- Tick Tock Clock mystery (stage-branded, fixed 6% roll)
    {id = 43, name = "Chronofin",        rarity = 1,  value = 340, minSize = 60, maxSize = 105, minWeight = 24.0, maxWeight = 58.0, difficulty = 5, onlyLevel = LEVEL_TTC, isMystery = true},
}

-- Tiny-Huge Island uses a random mix of these existing fish (by id)
local THI_FISH_IDS = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 30}
function is_thi_pool_fish(fishData)
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
    [LEVEL_BOB] = "BOB lakes",
    [LEVEL_JRB] = "WIP",
    [LEVEL_DDD] = "Dire Dire Docks",
    [LEVEL_TTM] = "Tall Tall Mountain",
    [LEVEL_TTC] = "Tick Tock Clock",
    [LEVEL_RR] = "Rainbow Ride",
}

function fish_location_text(f)
    if f == nil then return "Unknown" end
    if f.isMystery then
        local loc = LEVEL_NAMES[f.onlyLevel] or "Special stage"
        return loc .. " only (mystery)"
    end
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

function fish_can_be_caught_at_level(f, level)
    if f == nil or level == nil then return false end
    if f.onlyLevels ~= nil then
        for i = 1, #f.onlyLevels do
            if f.onlyLevels[i] == level then return true end
        end
        return false
    end
    if f.onlyLevel ~= nil then
        return f.onlyLevel == level
    end
    -- General fish are available in the normal fishing waters. Tiny-Huge Island
    return level == LEVEL_CASTLE_GROUNDS
        or level == LEVEL_JRB
        or level == LEVEL_DDD
        or level == LEVEL_BOB
        or level == LEVEL_THI
end

local FISH_MAP_LOCATIONS = {
    {id = "general", name = "GENERAL WATERS", level = nil, note = "Any stage with fishable water"},
    {id = "cg", name = "CASTLE GROUNDS", level = LEVEL_CASTLE_GROUNDS, note = "Moat + lake. Shops nearby."},
    {id = "jrb", name = "JOLLY ROGER BAY", level = LEVEL_JRB, note = "Bay waters + custom boat dock. Fish Market."},
    {id = "ddd", name = "DIRE DIRE DOCKS", level = LEVEL_DDD, note = "Deep docks. Bait shops + boat."},
    {id = "bob", name = "BOB-OMB BATTLEFIELD", level = LEVEL_BOB, note = "Lakes. Bait + market."},
    {id = "lll", name = "LETHAL LAVA LAND", level = LEVEL_LLL, note = "Lava pool. Fish Market."},
    {id = "ccm", name = "COOL COOL MOUNTAIN", level = LEVEL_CCM, note = "Bottom pond (cold fish)."},
    {id = "pss", name = "PEACH SECRET SLIDE", level = LEVEL_PSS, note = "Slide water. VOID fish decay."},
    {id = "totwc", name = "TOWER OF THE WING CAP", level = LEVEL_TOTWC, note = "Cloud water."},
    {id = "ttm", name = "TALL TALL MOUNTAIN", level = LEVEL_TTM, note = "6% Hollowfin mystery chance."},
    {id = "thi", name = "TINY-HUGE ISLAND", level = LEVEL_THI, note = "Shore mix of general + Ga. Fish."},
    {id = "ttc", name = "TICK TOCK CLOCK", level = LEVEL_TTC, note = "Clock waters. 6% Chronofin mystery chance."},
    {id = "rr", name = "RAINBOW RIDE", level = LEVEL_RR, note = "6% Prismwraith mystery chance."},
}

local function fish_map_tag(f)
    local tags = {}
    if f.isVoid then table.insert(tags, "VOID") end
    if f.isMystery then table.insert(tags, "MYSTERY") end
    if f.isGa then table.insert(tags, "GA") end
    if #tags == 0 then return "" end
    return " [" .. table.concat(tags, "/") .. "]"
end

local function fish_rarity_label(r)
    r = tonumber(r) or 0
    if r >= 20 then return "Common"
    elseif r >= 10 then return "Uncommon"
    elseif r >= 5 then return "Rare"
    elseif r >= 3 then return "Epic"
    else return "Legendary"
    end
end

local function fish_map_row_for(f)
    local hardValue = math.floor((f.value or 0) * HARD_MODE_SELL_MULT)
    local diff = f.difficulty or 1
    local size = string.format("%.0f-%.0f cm", f.minSize or 0, f.maxSize or 0)
    local weight = string.format("%.1f-%.1f kg", f.minWeight or 0, f.maxWeight or 0)
    return {
        title = false,
        text = string.format("%s%s", f.name, fish_map_tag(f)),
        sub = string.format(
            "%s  |  $%d / $%d hard  |  Diff %d  |  %s  |  %s",
            fish_rarity_label(f.rarity),
            f.value or 0,
            hardValue,
            diff,
            size,
            weight
        ),
        rarity = f.rarity or 0,
        difficulty = diff,
        isMystery = f.isMystery == true,
        isVoid = f.isVoid == true,
    }
end

function build_fish_map_lines()
    local lines = {}
    for li = 1, #FISH_MAP_LOCATIONS do
        local loc = FISH_MAP_LOCATIONS[li]
        table.insert(lines, {title = true, text = loc.name})
        if loc.note ~= nil then
            table.insert(lines, {title = false, text = loc.note, note = true})
        end

        local found = 0
        local rows = {}
        for i = 1, #FISH do
            local f = FISH[i]
            local available = false
            if loc.id == "general" then
                available = (f.onlyLevel == nil and f.onlyLevels == nil)
            elseif loc.level == LEVEL_THI then
                available = is_thi_pool_fish(f)
            else
                if fish_can_be_caught_at_level(f, loc.level) then
                    available = true
                elseif f.onlyLevel == nil and f.onlyLevels == nil then
                    -- General fish can bite in any fishable water (matches roll_fish)
                    available = true
                end
            end

            if available then
                found = found + 1
                table.insert(rows, fish_map_row_for(f))
            end
        end

        table.sort(rows, function(a, b)
            if a.isMystery ~= b.isMystery then return a.isMystery end
            if a.isVoid ~= b.isVoid then return a.isVoid end
            if a.rarity ~= b.rarity then return a.rarity < b.rarity end
            return tostring(a.text) < tostring(b.text)
        end)
        for i = 1, #rows do
            table.insert(lines, rows[i])
        end

        if found == 0 then
            table.insert(lines, {title = false, text = "No fish listed for this location."})
        end
    end

    table.insert(lines, {title = true, text = "SHOP SPAWNS"})
    table.insert(lines, {title = false, text = "Castle Grounds - Bait Shop + Fish Market", note = true})
    table.insert(lines, {title = false, text = "Castle Upper Floor (TTM painting) - Fish Market", note = true})
    table.insert(lines, {title = false, text = "Jolly Roger Bay - Fish Market", note = true})
    table.insert(lines, {title = false, text = "Dire Dire Docks - Bait Shops (2)", note = true})
    table.insert(lines, {title = false, text = "Bob-omb Battlefield - Bait Shop + Fish Market", note = true})
    table.insert(lines, {title = false, text = "Lethal Lava Land - Fish Market", note = true})
    table.insert(lines, {title = false, text = "Castle Courtyard - Bait Shop", note = true})

    table.insert(lines, {title = true, text = "MAP NOTES"})
    table.insert(lines, {title = false, text = "No bait still works: only Common / Diff 1 fish bite.", note = true})
    table.insert(lines, {title = false, text = "Hard Mode: harder fights, 2x sell on new catches.", note = true})
    table.insert(lines, {title = false, text = "Prestige raises fight difficulty by rank.", note = true})
    table.insert(lines, {title = false, text = "VOID Fish decay after about 3 minutes - sell fast.", note = true})
    table.insert(lines, {title = false, text = "Mystery fish: fixed 6% roll on their stage only.", note = true})
    table.insert(lines, {title = false, text = "Better bait and rods bias toward rarer fish.", note = true})
    return lines
end

local FISH_MAP_LINES = nil
function get_fish_map_lines()
    if FISH_MAP_LINES == nil then
        FISH_MAP_LINES = build_fish_map_lines()
    end
    return FISH_MAP_LINES
end

function open_fish_map()
    ui.showFishMap = true
    ui.showInventory = false
    ui.fishMapPage = 1
end

function close_fish_map()
    ui.showFishMap = false
end

function toggle_fish_map()
    if ui.showFishMap then
        close_fish_map()
    else
        open_fish_map()
    end
end



local BAIT_AMOUNTS = {1, 5, 10}

local BAIT_TYPES = {
    {id = 1, name = "Worm",         cost = 5,  luck = 0,  waitMul = 1.00, desc = "Basic. Steady bites."},
    {id = 2, name = "Cricket",      cost = 12, luck = 8,  waitMul = 0.85, desc = "Faster bites, better luck."},
    {id = 3, name = "Super Mushroom", cost = 18, luck = 14, waitMul = 0.75, desc = "Rare fish magnet."},
    {id = 4, name = "Golden Lure",  cost = 30, luck = 28, waitMul = 0.60, desc = "Top tier rare hunter."},
    {id = 5, name = "Barbed Hook",  cost = 45, luck = 36, waitMul = 0.50, diffAdd = 2, requireRod = 5, desc = "Gold rod+. More rares, harder reels."},
}

function is_bait_unlocked(bt, pst)
    if bt == nil then return false end
    if bt.requireRod == nil then return true end
    local maxU = 1
    if pst ~= nil then maxU = pst.rodMaxUnlocked or 1 end
    return maxU >= bt.requireRod
end

function get_bait_type(id)
    for i = 1, #BAIT_TYPES do
        if BAIT_TYPES[i].id == id then return BAIT_TYPES[i] end
    end
    return BAIT_TYPES[1]
end

local FISH_MAP_PAGE_SIZE = 10
local ui = {
    inventory = {},
    showInventory = false,
    showFishMap = false,
    fishMapPage = 1,
    shopPrompt = false,
    shopCooldown = 0,
    catchStreak = 0,
    catchDisplayTimer = 0,
    lastCaught = {name = "", size = 0, weight = 0, value = 0, isVoid = false},
    currentDifficulty = 1,
    biteFlash = 0,
    reelPulse = 0,
    lockedPos = nil,
    personalRecord = {name = "", size = 0, weight = 0},
    prBannerTimer = 0,
    prBannerData = {player = "", name = "", size = 0, weight = 0},
    progressLoaded = false,
    saveCooldown = 0,
    baitBuyIndex = 1,
    baitTypeIndex = 1,
    showTutorial = false,
    tutorialCooldown = 0,
    showHardMode = false,
    hardModeCooldown = 0,
    lastResetSeq = 0,
    lastPrestige = 0,
}

function storage_save_num(key, value)
    if mod_storage_save_number ~= nil then
        mod_storage_save_number(key, value or 0)
    elseif mod_storage_save ~= nil then
        mod_storage_save(key, tostring(value or 0))
    end
end

function storage_load_num(key, default)
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

function storage_save_str(key, value)
    if mod_storage_save ~= nil then
        mod_storage_save(key, value or "")
    end
end

function storage_load_str(key, default)
    if mod_storage_load ~= nil then
        local s = mod_storage_load(key)
        if s ~= nil then return s end
    end
    return default or ""
end

function serialize_inventory()
    local parts = {}
    for i = 1, #ui.inventory do
        local r = ui.inventory[i]
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

function deserialize_inventory(str)
    ui.inventory = {}
    if str == nil or str == "" then return end
    for row in string.gmatch(str, "[^;]+") do
        local id, name, size, weight, value, voidFlag, decayLeft = string.match(
            row, "^(%d+)|([^|]+)|([%d%.]+)|([%d%.]+)|(%d+)|(%d*)|(%d*)$"
        )
        if id == nil then
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
            table.insert(ui.inventory, rec)
        end
    end
end

function save_progress()
    local pst = gPlayerSyncTable[0]
    if pst == nil then return end
    storage_save_num("fdx_wallet", pst.wallet or 0)
    storage_save_num("fdx_bait1", pst.bait1 or 0)
    storage_save_num("fdx_bait2", pst.bait2 or 0)
    storage_save_num("fdx_bait3", pst.bait3 or 0)
    storage_save_num("fdx_bait4", pst.bait4 or 0)
    storage_save_num("fdx_bait5", pst.bait5 or 0)
    storage_save_num("fdx_activeBait", pst.activeBait or 1)
    storage_save_num("fdx_rodTier", pst.rodTier or 1)
    storage_save_num("fdx_rodMax", pst.rodMaxUnlocked or 1)
    storage_save_num("fdx_prestige", pst.prestige or 0)
    storage_save_num("fdx_hardMode", pst.hardMode and 1 or 0)
    storage_save_str("fdx_inv", serialize_inventory())
    storage_save_str("fdx_pr_name", ui.personalRecord.name or "")
    storage_save_num("fdx_pr_size", ui.personalRecord.size or 0)
    storage_save_num("fdx_pr_weight", ui.personalRecord.weight or 0)
    storage_save_num("fdx_saved", 1)
end

function queue_save()
    ui.saveCooldown = 30
end

function load_progress_into_pst(pst)
    if ui.progressLoaded or pst == nil then return end
    ui.progressLoaded = true

    local hasSave = storage_load_num("fdx_saved", 0)
    if hasSave ~= 1 then
        return
    end

    pst.wallet = storage_load_num("fdx_wallet", pst.wallet or 0)
    if pst.wallet > get_max_coins() then pst.wallet = get_max_coins() end
    if pst.wallet < 0 then pst.wallet = 0 end

    pst.bait1 = storage_load_num("fdx_bait1", pst.bait1 or 0)
    pst.bait2 = storage_load_num("fdx_bait2", pst.bait2 or 0)
    pst.bait3 = storage_load_num("fdx_bait3", pst.bait3 or 0)
    pst.bait4 = storage_load_num("fdx_bait4", pst.bait4 or 0)
    pst.bait5 = storage_load_num("fdx_bait5", pst.bait5 or 0)
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
    ui.personalRecord.name = storage_load_str("fdx_pr_name", "")
    ui.personalRecord.size = storage_load_num("fdx_pr_size", 0)
    ui.personalRecord.weight = storage_load_num("fdx_pr_weight", 0)

    pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
    rodTier = pst.rodTier
end

function reset_fishing_progress(pst)
    if pst == nil then return end
    pst.wallet = 0
    pst.bait1 = 0
    pst.bait2 = 0
    pst.bait3 = 0
    pst.bait4 = 0
    pst.bait = 0
    pst.activeBait = 1
    pst.rodTier = 1
    pst.rodMaxUnlocked = 1
    pst.prestige = 0
    pst.hardMode = false
    reset_fishing_state(pst)
    ui.inventory = {}
    ui.personalRecord = {name = "", size = 0, weight = 0}
    ui.catchStreak = 0
    ui.lastCaught = {name = "", size = 0, weight = 0, value = 0, isVoid = false}
    ui.showInventory = false
    ui.showFishMap = false
    ui.showTutorial = false
    ui.showHardMode = false
    ui.lockedPos = nil
    ui.lastPrestige = 0
    save_progress()
end

function apply_admin_progress_updates(pst)
    if pst == nil then return end
    local seq = pst.fdxResetSeq or 0
    if seq > (ui.lastResetSeq or 0) then
        ui.lastResetSeq = seq
        reset_fishing_progress(pst)
        djui_chat_message_create("Your Fishing DX progress was reset by the host.")
        return
    end
    local prestige = math.floor(tonumber(pst.prestige) or 0)
    if prestige < 0 then prestige = 0 end
    if prestige > MAX_PRESTIGE then prestige = MAX_PRESTIGE end
    if prestige ~= (ui.lastPrestige or 0) then
        ui.lastPrestige = prestige
        queue_save()
    end
end

function get_fishing_challenge_level(pst, baseDifficulty)
    local d = math.floor(tonumber(baseDifficulty) or 1)
    d = d + math.floor(tonumber(pst and pst.prestige or 0) or 0)
    if pst ~= nil and pst.hardMode then d = d + 1 end
    if pst ~= nil then
        local bt = get_bait_type(pst.activeBait or 1)
        if bt ~= nil and bt.diffAdd ~= nil then
            d = d + math.floor(bt.diffAdd)
        end
    end
    if d > 5 then d = 5 end
    if d < 1 then d = 1 end
    return d
end

function equip_bait(pst, baitId, silent)
    if pst == nil then return false end
    baitId = math.floor(tonumber(baitId) or 1)
    if baitId < 1 or baitId > #BAIT_TYPES then return false end
    local n = 0
    if baitId == 1 then n = pst.bait1 or 0
    elseif baitId == 2 then n = pst.bait2 or 0
    elseif baitId == 3 then n = pst.bait3 or 0
    elseif baitId == 4 then n = pst.bait4 or 0
    elseif baitId == 5 then n = pst.bait5 or 0
    end
    local btCheck = get_bait_type(baitId)
    if not is_bait_unlocked(btCheck, pst) then
        if not silent then
            djui_chat_message_create(btCheck.name .. " unlocks after you get the Gold rod.")
        end
        return false
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

function fix_active_bait(pst)
    if pst == nil then return end
    local id = pst.activeBait or 1
    local function count(i)
        if i == 1 then return pst.bait1 or 0 end
        if i == 2 then return pst.bait2 or 0 end
        if i == 3 then return pst.bait3 or 0 end
        if i == 4 then return pst.bait4 or 0 end
        if i == 5 then return pst.bait5 or 0 end
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

local banners = {
    lastSeenSessionSeq = 0,
    lastSeenHotSeq = 0,
    hotTimer = 0,
    hotText = "",
    lastSeenMysterySeq = 0,
    mysteryTimer = 0,
    mysteryData = {player = "", name = "", size = 0, weight = 0},
    mysteryHookTimer = 0,
    hotRotateTimer = 0,
}

local HOT_STAGE_POOL = {
    {level = LEVEL_BOB,            name = "Bob-omb Battlefield"},
    {level = LEVEL_JRB,            name = "Jolly Roger Bay"},
    {level = LEVEL_DDD,            name = "Dire Dire Docks"},
    {level = LEVEL_CASTLE_GROUNDS, name = "Castle Grounds"},
}
function try_add_hot(levelConst, name)
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

function level_display_name(levelNum)
    for i = 1, #HOT_STAGE_POOL do
        if HOT_STAGE_POOL[i].level == levelNum then
            return HOT_STAGE_POOL[i].name
        end
    end
    return "Unknown Stage"
end

function init_session_sync_fields()
    if gGlobalSyncTable.fdxSessionWeight == nil then gGlobalSyncTable.fdxSessionWeight = 0 end
    if gGlobalSyncTable.fdxSessionSize == nil then gGlobalSyncTable.fdxSessionSize = 0 end
    if gGlobalSyncTable.fdxSessionName == nil then gGlobalSyncTable.fdxSessionName = "" end
    if gGlobalSyncTable.fdxSessionPlayer == nil then gGlobalSyncTable.fdxSessionPlayer = "" end
    if gGlobalSyncTable.fdxSessionSeq == nil then gGlobalSyncTable.fdxSessionSeq = 0 end
    if gGlobalSyncTable.fdxHotLevel == nil then gGlobalSyncTable.fdxHotLevel = 0 end
    if gGlobalSyncTable.fdxHotLuck == nil then gGlobalSyncTable.fdxHotLuck = 0 end
    if gGlobalSyncTable.fdxHotSeq == nil then gGlobalSyncTable.fdxHotSeq = 0 end
    if gGlobalSyncTable.fdxMysterySeq == nil then gGlobalSyncTable.fdxMysterySeq = 0 end
    if gGlobalSyncTable.fdxMysteryPlayer == nil then gGlobalSyncTable.fdxMysteryPlayer = "" end
    if gGlobalSyncTable.fdxMysteryName == nil then gGlobalSyncTable.fdxMysteryName = "" end
    if gGlobalSyncTable.fdxMysterySize == nil then gGlobalSyncTable.fdxMysterySize = 0 end
    if gGlobalSyncTable.fdxMysteryWeight == nil then gGlobalSyncTable.fdxMysteryWeight = 0 end
end

local HOT_ROTATE_FRAMES = 18000

function roll_hot_stage(force)
    init_session_sync_fields()
    local isServer = true
    if network_is_server ~= nil then isServer = network_is_server() end
    if not isServer then return end
    if #HOT_STAGE_POOL < 1 then return end

    local prev = gGlobalSyncTable.fdxHotLevel or 0
    local pick = HOT_STAGE_POOL[math.random(1, #HOT_STAGE_POOL)]
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
    banners.hotRotateTimer = HOT_ROTATE_FRAMES
end

function ensure_hot_stage_rolled()
    init_session_sync_fields()
    local isServer = true
    if network_is_server ~= nil then isServer = network_is_server() end
    if not isServer then return end

    if (gGlobalSyncTable.fdxHotSeq or 0) <= 0 then
        roll_hot_stage(true)
        return
    end

    if banners.hotRotateTimer <= 0 then
        banners.hotRotateTimer = HOT_ROTATE_FRAMES
        return
    end

    banners.hotRotateTimer = banners.hotRotateTimer - 1
    if banners.hotRotateTimer <= 0 then
        roll_hot_stage(false)
    end
end

function broadcast_session_record(pname, record)
    init_session_sync_fields()
    gGlobalSyncTable.fdxSessionPlayer = tostring(pname or "Mario")
    gGlobalSyncTable.fdxSessionName = tostring(record.name or "Fish")
    gGlobalSyncTable.fdxSessionSize = record.size or 0
    gGlobalSyncTable.fdxSessionWeight = record.weight or 0
    gGlobalSyncTable.fdxSessionSeq = (gGlobalSyncTable.fdxSessionSeq or 0) + 1
end

function broadcast_mystery_catch(pname, record)
    init_session_sync_fields()
    gGlobalSyncTable.fdxMysteryPlayer = tostring(pname or "Mario")
    gGlobalSyncTable.fdxMysteryName = tostring(record.name or "Hollowfin")
    gGlobalSyncTable.fdxMysterySize = record.size or 0
    gGlobalSyncTable.fdxMysteryWeight = record.weight or 0
    gGlobalSyncTable.fdxMysterySeq = (gGlobalSyncTable.fdxMysterySeq or 0) + 1
end

function apply_incoming_session_announcements()
    init_session_sync_fields()
    local sSeq = gGlobalSyncTable.fdxSessionSeq or 0
    if sSeq > banners.lastSeenSessionSeq then
        banners.lastSeenSessionSeq = sSeq
        if sSeq > 0 and (gGlobalSyncTable.fdxSessionWeight or 0) > 0 then
            ui.prBannerData.player = gGlobalSyncTable.fdxSessionPlayer or "Mario"
            ui.prBannerData.name = gGlobalSyncTable.fdxSessionName or "Fish"
            ui.prBannerData.size = gGlobalSyncTable.fdxSessionSize or 0
            ui.prBannerData.weight = gGlobalSyncTable.fdxSessionWeight or 0
            ui.prBannerTimer = 260
            djui_chat_message_create(string.format(
                "[Session PR] %s landed the biggest catch: %s (%.1f cm, %.1f kg)",
                ui.prBannerData.player, ui.prBannerData.name, ui.prBannerData.size, ui.prBannerData.weight
            ))
        end
    end
    local hSeq = gGlobalSyncTable.fdxHotSeq or 0
    if hSeq > banners.lastSeenHotSeq then
        banners.lastSeenHotSeq = hSeq
        if hSeq > 0 and (gGlobalSyncTable.fdxHotLevel or 0) ~= 0 then
            local lname = level_display_name(gGlobalSyncTable.fdxHotLevel)
            local luck = gGlobalSyncTable.fdxHotLuck or 20
            banners.hotText = string.format("HOT STAGE: %s  (+%d rare luck)", lname, luck)
            banners.hotTimer = 360
            djui_chat_message_create(string.format(
                "[Fishing] Rare hotspot: %s (+%d luck). Rotates about every 10 minutes.",
                lname, luck
            ))
        end
    end
    local mSeq = gGlobalSyncTable.fdxMysterySeq or 0
    if mSeq > banners.lastSeenMysterySeq then
        banners.lastSeenMysterySeq = mSeq
        if mSeq > 0 and (gGlobalSyncTable.fdxMysteryName or "") ~= "" then
            banners.mysteryData.player = gGlobalSyncTable.fdxMysteryPlayer or "Mario"
            banners.mysteryData.name = gGlobalSyncTable.fdxMysteryName or "Hollowfin"
            banners.mysteryData.size = gGlobalSyncTable.fdxMysterySize or 0
            banners.mysteryData.weight = gGlobalSyncTable.fdxMysteryWeight or 0
            banners.mysteryTimer = 420
            djui_chat_message_create(string.format(
                "[MYSTERY] %s caught the %s! (%.1f cm, %.1f kg)",
                banners.mysteryData.player, banners.mysteryData.name,
                banners.mysteryData.size, banners.mysteryData.weight
            ))
        end
    end
end

local CAST_DIST = 210
local AIM_MIN_HOLD = 8
local vis = {
    rodObj = nil,
    rodTipObj = nil,
    bobberObj = nil,
    aimMarkers = {},
    aimHoldFrames = 0,
    wasHoldingL = false,
    aimActive = false,
    fishObj = nil,
    shopSignsSpawned = false,
    lastShopLevel = -1,
    castBaitId = 0,
    fishRespawnCooldown = 0,
    rodRespawnCooldown = 0,
}

function ensure_sync()
    local pst = gPlayerSyncTable[0]
    if pst == nil then
        return {
            fishInit = true,
            bait = 8,
            bait1 = 8,
            bait2 = 0,
            bait3 = 0,
            bait4 = 0,
            bait5 = 0,
            activeBait = 1,
            fishState = STATE.IDLE,
            fishTimer = 0,
            biteTimer = 0,
            miniProgress = 0,
            caughtId = 0,
            castPrompt = false,
            rodTier = 1,
            rodMaxUnlocked = 1,
            wallet = 0,
            prestige = 0,
            hardMode = false,
            fdxResetSeq = 0,
        }
    end
    if pst.fishInit ~= true then
        pst.fishInit = true
        pst.bait = 8
        pst.bait1 = 8
        pst.bait2 = 0
        pst.bait3 = 0
        pst.bait4 = 0
        pst.bait5 = 0
        pst.activeBait = 1
        pst.fishState = STATE.IDLE
        pst.fishTimer = 0
        pst.biteTimer = 0
        pst.miniProgress = 0
        pst.caughtId = 0
        pst.castPrompt = false
        pst.rodTier = 1
        pst.rodMaxUnlocked = 1
        pst.prestige = 0
        pst.hardMode = false
        pst.fdxResetSeq = 0
        pst.wallet = 0
    end
    if pst.wallet == nil then pst.wallet = 0 end
    if type(pst.wallet) == "number" then
        if pst.wallet > get_max_coins() then pst.wallet = get_max_coins() end
        if pst.wallet < 0 then pst.wallet = 0 end
    else
        pst.wallet = 0
    end
    if pst.bait1 == nil then pst.bait1 = pst.bait or 8 end
    if pst.bait2 == nil then pst.bait2 = 0 end
    if pst.bait3 == nil then pst.bait3 = 0 end
    if pst.bait4 == nil then pst.bait4 = 0 end
    if pst.activeBait == nil then pst.activeBait = 1 end
    pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
    if pst.fishState == nil then pst.fishState = STATE.IDLE end
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

    load_progress_into_pst(pst)
    fix_active_bait(pst)
    return pst
end

function clear_rod_visuals()
    if vis.rodObj ~= nil then
        obj_mark_for_deletion(vis.rodObj)
        vis.rodObj = nil
    end
    if vis.rodTipObj ~= nil then
        obj_mark_for_deletion(vis.rodTipObj)
        vis.rodTipObj = nil
    end
end

function set_rod_tier(tier, announce)
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

function cycle_rod_left()
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

function cycle_rod_right()
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

function get_bait_count(pst, baitId)
    if baitId == 1 then return pst.bait1 or 0 end
    if baitId == 2 then return pst.bait2 or 0 end
    if baitId == 3 then return pst.bait3 or 0 end
    if baitId == 4 then return pst.bait4 or 0 end
    if baitId == 5 then return pst.bait5 or 0 end
    return 0
end

function set_bait_count(pst, baitId, n)
    if n < 0 then n = 0 end
    if baitId == 1 then pst.bait1 = n
    elseif baitId == 2 then pst.bait2 = n
    elseif baitId == 3 then pst.bait3 = n
    elseif baitId == 4 then pst.bait4 = n
    elseif baitId == 5 then pst.bait5 = n end
    pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0) + (pst.bait5 or 0)
    queue_save()
end

function total_bait(pst)
    return (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0) + (pst.bait5 or 0)
end


function consume_active_bait(pst)
    fix_active_bait(pst)
    local id = pst.activeBait or 1
    local n = get_bait_count(pst, id)
    if n <= 0 then return false end
    set_bait_count(pst, id, n - 1)
    vis.castBaitId = id
    fix_active_bait(pst)
    queue_save()
    return true
end

function refund_cast_bait(pst)
    if vis.castBaitId == nil or vis.castBaitId < 1 then
        vis.castBaitId = 0
        return false
    end
    local id = vis.castBaitId
    vis.castBaitId = 0
    local n = get_bait_count(pst, id)
    if n >= get_max_bait() then
        return false
    end
    set_bait_count(pst, id, n + 1)
    fix_active_bait(pst)
    queue_save()
    return true
end

function clear_cast_bait()
    vis.castBaitId = 0
end

function get_rod_style()
    local s = ROD_TIERS[rodTier]
    if s == nil then
        rodTier = 1
        s = ROD_TIERS[1]
    end
    if s.useWoodRod then
        return {
            name = s.name,
            body = load_wood_rod_model(),
            bx = s.bx,
            by = s.by,
            bz = s.bz,
            cost = s.cost,
            luck = s.luck,
            useWoodRod = true,
        }
    end
    if s.useLegendaryRod then
        return {
            name = s.name,
            body = load_legendary_rod_model(),
            bx = s.bx,
            by = s.by,
            bz = s.bz,
            ox = s.ox or 0,
            oy = s.oy or 0,
            oz = s.oz or 0,
            cost = s.cost,
            luck = s.luck,
            useLegendaryRod = true,
        }
    end
    if s.useMetalPole then
        return {
            name = s.name,
            body = load_metal_pole_model(),
            bx = s.bx,
            by = s.by,
            bz = s.bz,
            cost = s.cost,
            luck = s.luck,
            useMetalPole = true,
        }
    end
    if s.useMasterPole then
        return {
            name = s.name,
            body = load_master_pole_model(),
            bx = s.bx,
            by = s.by,
            bz = s.bz,
            cost = s.cost,
            luck = s.luck,
            useMasterPole = true,
        }
    end
    if s.useGoldPole then
        return {
            name = s.name,
            body = load_gold_pole_model(),
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

function get_next_rod_tier()
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

function get_wallet()
    local pst = ensure_sync()
    local w = pst.wallet or 0
    if type(w) ~= "number" then w = 0 end
    if w > get_max_coins() then w = get_max_coins() end
    if w < 0 then w = 0 end
    return w
end

function set_wallet(amount)
    local pst = ensure_sync()
    if amount == nil then amount = 0 end
    if type(amount) ~= "number" then amount = 0 end
    if amount > get_max_coins() then amount = get_max_coins() end
    if amount < 0 then amount = 0 end
    pst.wallet = amount
    queue_save()
    return pst.wallet
end

function add_wallet(amount)
    if amount == nil or amount == 0 then return 0 end
    local before = get_wallet()
    local after = before + amount
    set_wallet(after)
    return get_wallet() - before
end

function spend_wallet(amount)
    if amount == nil or amount <= 0 then return true end
    local w = get_wallet()
    if w < amount then return false end
    set_wallet(w - amount)
    return true
end

function maybe_seed_wallet_from_coins(m)
    local pst = ensure_sync()
    if pst.walletSeeded == true then return end
    pst.walletSeeded = true
    if storage_load_num("fdx_saved", 0) == 1 then return end
    if (pst.wallet or 0) > 0 then return end
    if m ~= nil and m.numCoins ~= nil and m.numCoins > 0 then
        set_wallet(m.numCoins)
    end
end

function try_upgrade_rod(m)
    local pst = ensure_sync()
    local maxU = pst.rodMaxUnlocked or 1
    if maxU >= #ROD_TIERS then
        local top = ROD_TIERS[#ROD_TIERS]
        djui_chat_message_create("Rod is already maxed: " .. (top and top.name or "Max"))
        return false
    end
    local newTier = maxU + 1
    local nextStyle = ROD_TIERS[newTier]
    if nextStyle == nil then
        local top = ROD_TIERS[#ROD_TIERS]
        djui_chat_message_create("Rod is already maxed: " .. (top and top.name or "Max"))
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
            nextStyle.cost, nextStyle.name, wallet, get_max_coins()
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
        nextStyle.name, nextStyle.cost, get_wallet(), get_max_coins()
    ))
    djui_chat_message_create("Left D-Pad cycles unlocked rods")
    sfx(SOUND_GENERAL_COIN, m)
    return true
end

function get_player_name()
    local np = gNetworkPlayers[0]
    if np ~= nil and np.name ~= nil and tostring(np.name) ~= "" then
        return tostring(np.name)
    end
    return "Mario"
end

function get_current_level()
    local np = gNetworkPlayers[0]
    if np ~= nil then
        return np.currLevelNum
    end
    return 0
end


local id_bhvDDDBoatIdle = hook_behavior(nil, OBJ_LIST_DEFAULT, true,
    function(obj)
        obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
        obj.oInteractType = 0
        obj.oIntangibleTimer = -1
        obj.oDamageOrCoinValue = 0
        obj.oNumLootCoins = 0
        obj.oVelX = 0
        obj.oVelY = 0
        obj.oVelZ = 0
        obj.oForwardVel = 0
        obj.oHomeX = obj.oPosX
        obj.oHomeY = obj.oPosY
        obj.oHomeZ = obj.oPosZ
        obj.oFaceAnglePitch = 0x400
        obj.oMoveAnglePitch = 0x400
        obj.oFaceAngleRoll = 0
        obj.oMoveAngleRoll = 0
    end,
    function(obj)
        if obj == nil or obj.activeFlags == nil or obj.activeFlags == 0 then return end

        local t = get_global_timer()
        local bob = math.sin(t / 38.0) * 4.0 + math.sin(t / 73.0 + 1.15) * 1.5
        local pitch = 0x400 + math.floor(math.sin(t / 58.0) * 0x70)
        local roll = math.floor(math.sin(t / 67.0 + 0.8) * 0x90)

        obj.oPosX = obj.oHomeX
        obj.oPosY = obj.oHomeY + bob
        obj.oPosZ = obj.oHomeZ
        obj.oFaceAnglePitch = pitch
        obj.oMoveAnglePitch = pitch
        obj.oFaceAngleRoll = roll
        obj.oMoveAngleRoll = roll
    end,
    "bhvDDDBoatIdle")

local boats = {
    travel = nil,
    travelParts = {},
    travelLevel = -1,
    travelCols = {}, -- invisible solid pads under CG stage-select boat
    menuOpen = false,
    index = 1,
    cooldown = 0,
    ddd = nil,
    dddCols = {},
    dddLevel = 1,
    -- JRB boat
    jrb = nil,
    jrbCols = {},
    jrbLevel = -1,
}

local pendingTravel = {
    active = false,
    level = 0,
    area = 1,
    frames = 0,
    x = 0,
    y = -10,
    z = 0,
    yaw = 0,
}

local travelWarpGuard = {
    active = false,
    level = 0,
    frames = 0,
}

local TRAVEL_DESTINATIONS = {
    -- WIP travel destinations
    -- are always visible in the stage selector.
    {
        level = LEVEL_DDD, area = 1, act = 0, name = "Dire, Dire Docks",
        sx = -3080, sy = 441, sz = 127, yaw = 0x0000,
    },
    {
        level = LEVEL_CCM, area = 1, act = 0, name = "Cool, Cool Mountain",
        sx = -1512, sy = 2560, sz = -1840, yaw = 0x0000,
    },
    {
        level = LEVEL_LLL, area = 1, act = 0, name = "Lethal Lava Land",
        sx = -1173, sy = 154, sz = 443, yaw = 0x0000,
    },
    {
        level = LEVEL_TTM, area = 1, act = 0, name = "Tall Tall Mountain",
        sx = 424, sy = -2384, sz = 6463, yaw = 0x0000,
    },
    {
        level = LEVEL_THI, area = 1, act = 0, name = "Tiny-Huge Island",
        sx = -1822, sy = -720, sz = 1679, yaw = 0x0000,
    },
    {
        level = LEVEL_TOTWC, area = 1, act = 0, name = "Tower of the Wing Cap",
        sx = 0, sy = -2047, sz = 0, yaw = 0x0000,
    },
    {
        level = LEVEL_PSS, area = 1, act = 0, name = "Peach's Secret Slide",
        sx = 0, sy = 6144, sz = -6143, yaw = 0x8000,
    },
}

function travel_boat_is_valid(o)
    if o == nil then return false end
    -- Must be an active object; never trust a stale Lua reference
    if o.activeFlags ~= nil and o.activeFlags == 0 then
        return false
    end
    if obj_is_valid ~= nil then
        return obj_is_valid(o)
    end
    return o.activeFlags ~= nil and o.activeFlags ~= 0
end

function clear_travel_boat()
    if boats.travel ~= nil then
        if travel_boat_is_valid(boats.travel) then
            obj_mark_for_deletion(boats.travel)
        end
    end
    boats.travel = nil
    for i = 1, #boats.travelParts do
        local p = boats.travelParts[i]
        if travel_boat_is_valid(p) then
            obj_mark_for_deletion(p)
        end
    end
    boats.travelParts = {}
    for i = 1, #boats.travelCols do
        local p = boats.travelCols[i]
        if travel_boat_is_valid(p) then
            obj_mark_for_deletion(p)
        end
    end
    boats.travelCols = {}
    boats.travelLevel = -1
end

function clear_ddd_boat()
    if travel_boat_is_valid(boats.ddd) then
        obj_mark_for_deletion(boats.ddd)
    end
    boats.ddd = nil
    for i = 1, #boats.dddCols do
        if travel_boat_is_valid(boats.dddCols[i]) then
            obj_mark_for_deletion(boats.dddCols[i])
        end
    end
    boats.dddCols = {}
    boats.dddLevel = -1
end

function clear_jrb_boat()
    if travel_boat_is_valid(boats.jrb) then
        obj_mark_for_deletion(boats.jrb)
    end
    boats.jrb = nil
    for i = 1, #boats.jrbCols do
        if travel_boat_is_valid(boats.jrbCols[i]) then
            obj_mark_for_deletion(boats.jrbCols[i])
        end
    end
    boats.jrbCols = {}
    boats.jrbLevel = -1
end

function spawn_boat_collision_pad(x, y, z, sx, sy, sz)
    local model = E_MODEL_METAL_BOX
    if model == nil then model = E_MODEL_BREAKABLE_BOX end
    if model == nil then return nil end

    -- Behaviors with real solid collision
    local bhv = id_bhvMetalBox
    if bhv == nil then bhv = id_bhvBreakableBox end
    if bhv == nil then bhv = id_bhvPushableMetalBox end
    if bhv == nil then bhv = id_bhvStaticObject end
    if bhv == nil then return nil end

    local o = spawn_non_sync_object(bhv, model, x, y, z, function(obj)
        obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
        obj.oInteractType = 0
        obj.oIntangibleTimer = -1
        obj.oDamageOrCoinValue = 0
        obj.oNumLootCoins = 0
        obj.oHealth = 99999
        obj.oVelX = 0
        obj.oVelY = 0
        obj.oVelZ = 0
        obj.oForwardVel = 0
        -- Home position so we can lock it every frame
        obj.oHomeX = x
        obj.oHomeY = y
        obj.oHomeZ = z
        if obj.header ~= nil and obj.header.gfx ~= nil then
            obj.header.gfx.scale.x = sx
            obj.header.gfx.scale.y = sy
            obj.header.gfx.scale.z = sz
            if obj.header.gfx.node ~= nil then
                obj.header.gfx.node.flags = obj.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
            end
        end
        -- Attach vanilla metal-box collision when available
        if smlua_collision_util_get ~= nil then
            local col = smlua_collision_util_get("metal_box_seg8_collision_0800A1B8")
            if col == nil then
                col = smlua_collision_util_get("breakable_box_seg8_collision_08012D70")
            end
            if col ~= nil then
                obj.collisionData = col
            end
        end
        if load_object_collision_model ~= nil then
            load_object_collision_model()
        end
    end)
    if o ~= nil then
        o.oPosX = x
        o.oPosY = y
        o.oPosZ = z
        o.oHomeX = x
        o.oHomeY = y
        o.oHomeZ = z
        o.oHealth = 99999
        if o.header ~= nil and o.header.gfx ~= nil then
            o.header.gfx.scale.x = sx
            o.header.gfx.scale.y = sy
            o.header.gfx.scale.z = sz
        end
    end
    return o
end

-- Keep deck collision pads locked in place (no push / no fall)
function update_ddd_boat_collision()
    local function lock_col_list(list)
        for i = 1, #list do
            local o = list[i]
            if o ~= nil and o.activeFlags ~= nil and o.activeFlags ~= 0 then
                if o.oHomeX ~= nil then
                    o.oPosX = o.oHomeX
                    o.oPosY = o.oHomeY
                    o.oPosZ = o.oHomeZ
                end
                o.oVelX = 0
                o.oVelY = 0
                o.oVelZ = 0
                o.oForwardVel = 0
                o.oHealth = 99999
                -- Force collision wood/metal pads to stay invisible
                if o.header ~= nil and o.header.gfx ~= nil and o.header.gfx.node ~= nil
                    and GRAPH_RENDER_INVISIBLE ~= nil then
                    o.header.gfx.node.flags = o.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
                end
            end
        end
    end
    lock_col_list(boats.dddCols)
    lock_col_list(boats.jrbCols)
    lock_col_list(boats.travelCols)
    -- Visual hulls stay visible; only the solid pads are hidden.
end

function spawn_jrb_ship_part(model, x, y, z, yaw, sx, sy, sz)
    if model == nil then return nil end
    local bhv = id_bhvStaticObject
    if bhv == nil then bhv = id_bhvYellowCoin end
    if bhv == nil then return nil end
    local o = spawn_non_sync_object(bhv, model, x, y, z, function(obj)
        obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
        obj.oInteractType = 0
        obj.oIntangibleTimer = -1
        obj.oDamageOrCoinValue = 0
        obj.oNumLootCoins = 0
        obj.oHealth = 0
        obj.oOpacity = 255
        obj.oFaceAngleYaw = yaw
        obj.oMoveAngleYaw = yaw
        if obj.header ~= nil and obj.header.gfx ~= nil then
            obj.header.gfx.scale.x = sx
            obj.header.gfx.scale.y = sy
            obj.header.gfx.scale.z = sz
            if obj.header.gfx.node ~= nil then
                obj.header.gfx.node.flags = (obj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE) & (~GRAPH_RENDER_INVISIBLE)
            end
        end
        if obj_set_model_extended ~= nil then
            obj_set_model_extended(obj, model)
        end
    end)
    if o ~= nil then
        o.oPosX = x
        o.oPosY = y
        o.oPosZ = z
    end
    return o
end

function spawn_travel_boat()
    local level = get_current_level()
    if level ~= LEVEL_CASTLE_GROUNDS then
        clear_travel_boat()
        return
    end

    if travel_boat_is_valid(boats.travel) and boats.travelLevel == level then
        return
    end

    clear_travel_boat()

    -- Center of the Castle Pond water 
    -- going to adjust later
    local bx, by, bz = 3319, -900, 3780
    local yaw = 0x4000
    -- Scaled down so the ship fits the pond
    local sx, sy, sz = 0.42, 0.42, 0.42

    local left = E_MODEL_JRB_SHIP_LEFT_HALF_PART
    local right = E_MODEL_JRB_SHIP_RIGHT_HALF_PART
    -- Small lateral offset so both halves form a full hull
    local halfSep = 55

    if left ~= nil then
        boats.travel = spawn_jrb_ship_part(left, bx - halfSep, by, bz, yaw, sx, sy, sz)
    end
    if right ~= nil then
        local r = spawn_jrb_ship_part(right, bx + halfSep, by, bz, yaw, sx, sy, sz)
        if r ~= nil then
            table.insert(boats.travelParts, r)
        end
        if boats.travel == nil then
            boats.travel = r
        end
    end

    -- some parts of the boat
    local backL = E_MODEL_JRB_SHIP_BACK_LEFT_PART
    local backR = E_MODEL_JRB_SHIP_BACK_RIGHT_PART
    if backL ~= nil then
        local p = spawn_jrb_ship_part(backL, bx - halfSep, by, bz - 40, yaw, sx, sy, sz)
        if p ~= nil then table.insert(boats.travelParts, p) end
    end
    if backR ~= nil then
        local p = spawn_jrb_ship_part(backR, bx + halfSep, by, bz - 40, yaw, sx, sy, sz)
        if p ~= nil then table.insert(boats.travelParts, p) end
    end

    -- Fallback if no ship spawns correctly
    if boats.travel == nil then
        local fb = E_MODEL_WOODEN_POST
        if fb == nil then fb = E_MODEL_METAL_BOX end
        boats.travel = spawn_jrb_ship_part(fb, bx, by + 10, bz, yaw, 2.5, 1.5, 3.5)
    end

    -- Invisible solid collision for the CG travel boat, covering the measured
    -- standable region (same invisible metal/wood pads as JRB/DDD):
    --   from x:2532, y:-396, z:3610  to  x:4391, y:-880, z:3708
    boats.travelCols = {}
    local xmin, xmax = 2532, 4391
    local ymin, ymax = -880, -396
    local zmin, zmax = 3610, 3708
    local zmid = (zmin + zmax) * 0.5
    -- Metal box is ~150 units at scale 1. Step along X so pads overlap solidly.
    local xStep = 200
    local zSpan = math.max(80, zmax - zmin)
    local zScale = zSpan / 150 + 0.35
    -- Walkable top deck near y = -396, plus lower fill toward y = -880
    local yLevels = {
        {y = -396 - 50, sy = 0.70}, -- top deck surface
        {y = -560,      sy = 1.10}, -- mid fill
        {y = -720,      sy = 1.10}, -- lower fill
        {y = -860,      sy = 0.70}, -- bottom
    }
    for x = xmin, xmax, xStep do
        for yi = 1, #yLevels do
            local yl = yLevels[yi]
            local col = spawn_boat_collision_pad(x, yl.y, zmid, 1.55, yl.sy, zScale)
            if col ~= nil then
                if col.header ~= nil and col.header.gfx ~= nil and col.header.gfx.node ~= nil
                    and GRAPH_RENDER_INVISIBLE ~= nil then
                    col.header.gfx.node.flags = col.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
                end
                table.insert(boats.travelCols, col)
            end
        end
        -- Extra pads near the Z edges so the thin Z range stays solid
        local colA = spawn_boat_collision_pad(x, -396 - 50, zmin + 20, 1.55, 0.70, 0.90)
        local colB = spawn_boat_collision_pad(x, -396 - 50, zmax - 20, 1.55, 0.70, 0.90)
        for _, col in ipairs({colA, colB}) do
            if col ~= nil then
                if col.header ~= nil and col.header.gfx ~= nil and col.header.gfx.node ~= nil
                    and GRAPH_RENDER_INVISIBLE ~= nil then
                    col.header.gfx.node.flags = col.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
                end
                table.insert(boats.travelCols, col)
            end
        end
    end

    boats.travelLevel = level
end

function spawn_ddd_boat()
    -- Boat is spawned inside spawn_shop_stall for each DDD bait shop.
    -- Nothing else to do here; shops are refreshed from mario_update.
end

-- JRB custom dock boat (Boat_geo), independent of shops
local JRB_CUSTOM_BOAT = {
    x = -2450.67,
    y = 944,
    z = 5204,
    yaw = 0x4000,
}

function spawn_jrb_custom_boat()
    local level = get_current_level()
    if level ~= LEVEL_JRB then
        clear_jrb_boat()
        return
    end

    if travel_boat_is_valid(boats.jrb) and boats.jrbLevel == level then
        return
    end

    clear_jrb_boat()

    local bx = JRB_CUSTOM_BOAT.x
    local by = JRB_CUSTOM_BOAT.y
    local bz = JRB_CUSTOM_BOAT.z
    local yaw = JRB_CUSTOM_BOAT.yaw

    -- Invisible solid deck / hull collision (same footprint style as DDD)
    local d1 = spawn_boat_collision_pad(bx, by, bz, 1.6, 0.46, 3.2)
    local d2 = spawn_boat_collision_pad(bx + 110, by, bz, 1.8, 0.55, 3.6)
    local d3 = spawn_boat_collision_pad(bx - 105, by, bz, 1.6, 0.55, 3.6)
    if d1 ~= nil then table.insert(boats.jrbCols, d1) end
    if d2 ~= nil then table.insert(boats.jrbCols, d2) end
    if d3 ~= nil then table.insert(boats.jrbCols, d3) end

    local colPads = {
        {0, 12, 0, 5.6, 1.2, 7.2},
        {0, 12, 145, 5.0, 1.2, 3.2},
        {0, 12, -145, 5.0, 1.2, 3.2},
        {165, 12, 0, 2.4, 1.2, 6.2},
        {-165, 12, 0, 2.4, 1.2, 6.2},
        {120, 12, 115, 2.6, 1.2, 3.0},
        {-120, 12, 115, 2.6, 1.2, 3.0},
        {120, 12, -115, 2.6, 1.2, 3.0},
        {-120, 12, -115, 2.6, 1.2, 3.0},
    }
    for i = 1, #colPads do
        local p = colPads[i]
        local col = spawn_boat_collision_pad(bx + p[1], by + p[2], bz + p[3], p[4], p[5], p[6])
        if col ~= nil then
            table.insert(boats.jrbCols, col)
        end
    end

    -- Step up onto the deck
    local stepModel = E_MODEL_BREAKABLE_BOX_SMALL
    if stepModel == nil then stepModel = E_MODEL_METAL_BOX end
    if stepModel == nil then stepModel = E_MODEL_BREAKABLE_BOX end
    if stepModel ~= nil then
        local stepX, stepY, stepZ = bx + 330, by - 12, bz + 145
        -- Solid step only (kept in jrbCols so shop clears cannot delete it)
        local step = spawn_boat_collision_pad(stepX, stepY + 8, stepZ, 1.05, 0.7, 1.05)
        if step ~= nil then table.insert(boats.jrbCols, step) end
        local step2 = spawn_boat_collision_pad(stepX, stepY - 4, stepZ, 1.2, 0.55, 1.2)
        if step2 ~= nil then table.insert(boats.jrbCols, step2) end
    end

    -- Custom boat mesh (Boat_geo)
    local bm = load_boat_model()
    local scx, scy, scz = -52.0, 3.5, 5.2
    if boatModelCustom then
        scx, scy, scz = 4.4, 2.4, 2.8
    elseif E_MODEL_JRB_SHIP_LEFT_HALF_PART ~= nil then
        bm = E_MODEL_JRB_SHIP_LEFT_HALF_PART
        scx, scy, scz = 2.6, 2.0, 3.4
    elseif E_MODEL_TREASURE_CHEST_BASE ~= nil then
        bm = E_MODEL_TREASURE_CHEST_BASE
        scx, scy, scz = 3.5, 2.6, 3.5
    end

    local bhv = id_bhvDDDBoatIdle
    if bhv == nil then
        bhv = id_bhvStaticObject
    end
    if bhv == nil then
        bhv = id_bhvBreakableBox
    end
    if bhv == nil then
        return
    end

    local hull = spawn_non_sync_object(bhv, bm, bx, by + 30, bz, function(obj)
        obj.oFaceAngleYaw = yaw
        obj.oMoveAngleYaw = yaw
        if obj.header ~= nil and obj.header.gfx ~= nil then
            obj.header.gfx.scale.x = scx
            obj.header.gfx.scale.y = scy
            obj.header.gfx.scale.z = scz
        end
    end)
    if hull ~= nil then
        hull.oPosX = bx
        hull.oPosY = by + 30
        hull.oPosZ = bz
        hull.oHomeX = bx
        hull.oHomeY = by + 30
        hull.oHomeZ = bz
        hull.oFaceAngleYaw = yaw
        hull.oMoveAngleYaw = yaw
        hull.oFaceAnglePitch = 0x400
        hull.oMoveAnglePitch = 0x400
        hull.oFaceAngleRoll = 0
        hull.oMoveAngleRoll = 0
        if hull.header ~= nil and hull.header.gfx ~= nil then
            hull.header.gfx.scale.x = scx
            hull.header.gfx.scale.y = scy
            hull.header.gfx.scale.z = scz
        end
        boats.jrb = hull
        boats.jrbLevel = LEVEL_JRB
    end
end

function open_travel_menu()
    boats.menuOpen = true
    boats.index = 1
    ui.showInventory = false
    ui.showFishMap = false
end

function close_travel_menu()
    boats.menuOpen = false
end

function apply_pending_safe_spawn(m)
    if not pendingTravel.active or m == nil then
        return
    end
    local level = get_current_level()
    if level ~= pendingTravel.level then
        return
    end

    -- TTC and RR should use the course's native spawn. Their course cameras and
    -- spawn objects are initialized by the level warp itself; forcing Mario to a
    -- hand-authored coordinate during that transition can leave him suspended in
    -- the sky or lock the camera.
    if level == LEVEL_TTC or level == LEVEL_RR then
        pendingTravel.active = false
        return
    end

    if pendingTravel.frames > 0 then
        pendingTravel.frames = pendingTravel.frames - 1
        return
    end

    local x = pendingTravel.x
    local y = pendingTravel.y
    local z = pendingTravel.z

    if find_floor_height ~= nil then
        local fh = find_floor_height(x, y + 800, z)
        if fh ~= nil and fh > -8000 and fh < 20000 then
            y = fh + 40
        end
    end

    m.pos.x = x
    m.pos.y = y
    m.pos.z = z
    m.vel.x = 0
    m.vel.y = 0
    m.vel.z = 0
    m.forwardVel = 0
    if m.peakHeight ~= nil then
        m.peakHeight = y
    end
    if m.faceAngle ~= nil then
        m.faceAngle.y = pendingTravel.yaw
    end
    if m.marioObj ~= nil and m.marioObj.header ~= nil and m.marioObj.header.gfx ~= nil then
        m.marioObj.header.gfx.pos.x = x
        m.marioObj.header.gfx.pos.y = y
        m.marioObj.header.gfx.pos.z = z
        if m.marioObj.header.gfx.angle ~= nil then
            m.marioObj.header.gfx.angle.y = pendingTravel.yaw
        end
    end
    if set_mario_action ~= nil and ACT_IDLE ~= nil then
        set_mario_action(m, ACT_IDLE, 0)
    end

    if m.area ~= nil and m.area.camera ~= nil then
        m.area.camera.cutscene = 0
        if reset_camera ~= nil then
            reset_camera(m.area.camera)
        end
    end

    pendingTravel.active = false
end


function update_travel_boat(m, ctrl)
    if boats.cooldown > 0 then boats.cooldown = boats.cooldown - 1 end
    spawn_travel_boat()
    spawn_ddd_boat()
    spawn_jrb_custom_boat()
    update_ddd_boat_collision()

    if boats.menuOpen then
        if (ctrl.buttonPressed & U_JPAD) ~= 0 then
            boats.index = boats.index - 1
            if boats.index < 1 then boats.index = #TRAVEL_DESTINATIONS end
        elseif (ctrl.buttonPressed & D_JPAD) ~= 0 then
            boats.index = boats.index + 1
            if boats.index > #TRAVEL_DESTINATIONS then boats.index = 1 end
        elseif (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            close_travel_menu()
        elseif (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            local dst = TRAVEL_DESTINATIONS[boats.index]
            close_travel_menu()
            boats.cooldown = 30
            if dst ~= nil and warp_to_level ~= nil then
                -- Guard the first part of the destination load. Do not touch
                -- Mario, the camera, or custom stage objects while the vanilla
                -- course is still initializing.
                -- TTC is safest when entered exactly like a normal course
                -- selection. Do not install a long Lua-side guard for TTC;
                -- blocking this hook during the native TTC handoff can make
                -- Mario appear frozen even though the level loaded.
                if dst.level == LEVEL_TTC or dst.level == LEVEL_RR then
                    -- Keep a marker only so on_level_init knows this is a custom
                    -- boat transition. The Mario update hook never blocks TTC/RR.
                    travelWarpGuard.active = true
                    travelWarpGuard.level = dst.level
                    travelWarpGuard.frames = 0
                else
                    travelWarpGuard.active = true
                    travelWarpGuard.level = dst.level
                    travelWarpGuard.frames = 45
                end

                pendingTravel.active = true
                pendingTravel.level = dst.level
                pendingTravel.area = dst.area or 1
                if dst.level == LEVEL_TTC or dst.level == LEVEL_RR then
                    -- Let TTC/RR use their native course spawn/camera. No custom
                    -- position is applied after the warp.
                    pendingTravel.frames = 0
                elseif dst.level == LEVEL_BOB or dst.level == LEVEL_JRB then
                    pendingTravel.frames = 45
                else
                    pendingTravel.frames = 10
                end
                pendingTravel.x = dst.sx or 0
                pendingTravel.y = dst.sy or 0
                pendingTravel.z = dst.sz or 0
                pendingTravel.yaw = dst.yaw or 0
                warp_to_level(dst.level, dst.area or 1, dst.act or 1)
            else
                djui_chat_message_create("Travel warp is unavailable.")
            end
        end
        return
    end

    -- Open stage menu when near the Castle Grounds boat
    if get_current_level() == LEVEL_CASTLE_GROUNDS and travel_boat_is_valid(boats.travel) and boats.cooldown <= 0 then
        local dx = m.pos.x - boats.travel.oPosX
        local dy = m.pos.y - boats.travel.oPosY
        local dz = m.pos.z - boats.travel.oPosZ
        -- Wide radius so you can board from the shore
        if (dx * dx + dy * dy + dz * dz) <= (500 * 900) then
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                open_travel_menu()
            end
        end
    end
end

-- Custom fishable zones + visual water surfaces
local CUSTOM_SPOTS = {
        {level = LEVEL_BOB, name = "Bridge Pool", x1 = -3400, x2 = -2000, y1 = -80, y2 = 520, z1 = 3000, z2 = 4400, waterY = 45},
        {level = LEVEL_BOB, name = "Mud Lake",    x1 = -2900,  x2 = 1800,  y1 = -480, y2 = 650, z1 = -800, z2 = 1600, waterY = 55},
        {level = LEVEL_DDD, name = "Docks Water", x1 = -4000, x2 = 4500, y1 = -400, y2 = 500, z1 = -5500, z2 = 500, waterY = 20},
        -- WIP custom spots
        {level = LEVEL_DDD, name = "Bait Shop Boat", x1 = 2800, x2 = 3800, y1 = -50, y2 = 350, z1 = -2800, z2 = -1800, waterY = 50},
        {level = LEVEL_DDD, name = "Boat Slip",   x1 = 1500, x2 = 3800, y1 = -100, y2 = 400, z1 = -3500, z2 = -1500, waterY = 40},
        -- JRB custom Boat_geo dock
        {level = LEVEL_JRB, name = "Fishing boat waters",
            x1 = -2900, x2 = -2000, y1 = 800, y2 = 1200, z1 = 4800, z2 = 5600, waterY = 900},
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
    {level = LEVEL_TTC, name = "Clock Pool",
        x1 = 900, x2 = 1900, y1 = -5100, y2 = -4200, z1 = -1100, z2 = -100, waterY = -4850},
    {level = LEVEL_RR, name = "Rainbow Pool",
        x1 = 2100, x2 = 3100, y1 = -2200, y2 = -1500, z1 = 400, z2 = 1400, waterY = -1830},

    -- Tall Tall Mountain stream / lower water (Hollowfin territory)
    {level = LEVEL_TTM, name = "Mountain Stream",
        x1 = -2500, x2 = 2500, y1 = -500, y2 = 800, z1 = -2500, z2 = 2500, waterY = 100},

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

local lake = { decor = {}, models = {}, level = -1 }

function get_current_area()
    local np = gNetworkPlayers[0]
    if np ~= nil and np.currAreaIndex ~= nil then
        return np.currAreaIndex
    end
    return 1
end

function in_custom_spot(m)
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


function get_fishing_water_y(m)
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

function is_near_water(m)
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

function is_standing_to_fish(m)
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


function destroy_lake_decor()
    for i = 1, #lake.decor do
        if lake.decor[i] ~= nil then
            obj_mark_for_deletion(lake.decor[i])
        end
    end
    lake.decor = {}
    lake.models = {}
    lake.level = -1
end

function get_water_models()
    -- Resolve once; only return meshes that are real water and not enemy/shell IDs
    local wave = E_MODEL_IDLE_WATER_WAVE
    local ring = E_MODEL_WATER_RING
    local bubble = E_MODEL_BUBBLE

    local function is_bad(m)
        if m == nil or m == 0 then return true end
        if E_MODEL_NONE ~= nil and m == E_MODEL_NONE then return true end
        if E_MODEL_KOOPA_WITH_SHELL ~= nil and m == E_MODEL_KOOPA_WITH_SHELL then return true end
        if E_MODEL_KOOPA_WITHOUT_SHELL ~= nil and m == E_MODEL_KOOPA_WITHOUT_SHELL then return true end
        if E_MODEL_KOOPA_SHELL ~= nil and m == E_MODEL_KOOPA_SHELL then return true end
        if E_MODEL_KOOPA_SHELL_UNDERWATER ~= nil and m == E_MODEL_KOOPA_SHELL_UNDERWATER then return true end
        if E_MODEL_YELLOW_COIN ~= nil and m == E_MODEL_YELLOW_COIN then return true end
        if E_MODEL_BLUE_COIN ~= nil and m == E_MODEL_BLUE_COIN then return true end
        if E_MODEL_WOODEN_POST ~= nil and m == E_MODEL_WOODEN_POST then return true end
        if E_MODEL_METAL_BOX ~= nil and m == E_MODEL_METAL_BOX then return true end
        return false
    end

    if is_bad(wave) then wave = nil end
    -- Water ring/bubble model IDs can resolve incorrectly on some builds and
    -- render as Koopa/shell geometry. Keep the pool surface to the verified
    -- idle-water mesh only.
    ring = nil
    bubble = nil
    return wave, ring, bubble
end

function harden_water_obj(obj, sx, sy, sz)
    if obj == nil then return end
    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
    obj.oInteractType = 0
    obj.oIntangibleTimer = -1
    obj.oDamageOrCoinValue = 0
    obj.oNumLootCoins = 0
    obj.oHealth = 0
    obj.oVelX = 0
    obj.oVelY = 0
    obj.oVelZ = 0
    obj.oForwardVel = 0
    if obj.header ~= nil and obj.header.gfx ~= nil then
        obj.header.gfx.scale.x = sx
        obj.header.gfx.scale.y = sy
        obj.header.gfx.scale.z = sz
        if obj.header.gfx.node ~= nil then
            obj.header.gfx.node.flags = (obj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE) & (~GRAPH_RENDER_INVISIBLE)
        end
    end
end

function force_water_model(obj, model)
    if obj == nil or model == nil then return end
    if obj_set_model_extended ~= nil then
        obj_set_model_extended(obj, model)
    elseif obj_set_model ~= nil then
        obj_set_model(obj, model)
    end
end

function add_water_piece(model, x, y, z, sx, sy, sz)
    local wave, ring, bubble = get_water_models()
    -- Absolute allow-list: only the three water meshes
    if model == nil then return nil end
    if model ~= wave and model ~= ring and model ~= bubble then
        return nil
    end

    local bhv = id_bhvStaticObject
    if bhv == nil then return nil end

    local o = spawn_non_sync_object(bhv, model, x, y, z, function(obj)
        harden_water_obj(obj, sx, sy, sz)
        force_water_model(obj, model)
        obj.oDamageOrCoinValue = 0
        obj.oNumLootCoins = 0
        obj.oInteractType = 0
        obj.oIntangibleTimer = -1
        obj.oHealth = 0
    end)

    if o == nil then return nil end

    o.oPosX = x
    o.oPosY = y
    o.oPosZ = z
    force_water_model(o, model)
    harden_water_obj(o, sx, sy, sz)

    table.insert(lake.decor, o)
    table.insert(lake.models, model)
    return o
end

function fill_water_surface(x1, x2, z1, z2, y, step)
    step = step or 180
    local wave, ring, bubble = get_water_models()
    if wave == nil and ring == nil then return end
    local x = x1
    while x <= x2 do
        local z = z1
        while z <= z2 do
            if wave ~= nil then
                add_water_piece(wave, x, y, z, 3.0, 0.9, 3.0)
            end
            if ring ~= nil and ((math.floor(x / step) + math.floor(z / step)) % 4) == 0 then
                add_water_piece(ring, x + 12, y + 2, z + 12, 2.2, 0.45, 2.2)
            end
            z = z + step
        end
        x = x + step
    end
end

function destroy_lake_decor()
    for i = 1, #lake.decor do
        if lake.decor[i] ~= nil then
            obj_mark_for_deletion(lake.decor[i])
        end
    end
    lake.decor = {}
    lake.models = {}
    lake.level = -1
end

-- Every frame: re-force water models so nothing can turn into a koopa/shell geo
function enforce_lake_water_models()
    if #lake.decor == 0 then return end
    local wave, ring, bubble = get_water_models()
    for i = 1, #lake.decor do
        local o = lake.decor[i]
        local model = lake.models[i]
        if o ~= nil and o.activeFlags ~= nil and o.activeFlags ~= 0 then
            if model ~= wave and model ~= ring and model ~= bubble then
                obj_mark_for_deletion(o)
                lake.decor[i] = nil
                lake.models[i] = nil
            else
                force_water_model(o, model)
                o.oDamageOrCoinValue = 0
                o.oNumLootCoins = 0
                o.oInteractType = 0
                o.oIntangibleTimer = -1
                o.oVelX = 0
                o.oVelY = 0
                o.oVelZ = 0
            end
        end
    end
end

function spawn_lake_decor()
    local level = get_current_level()
    if lake.level == level and #lake.decor > 0 then
        return
    end
    destroy_lake_decor()
    lake.level = level

    if level == LEVEL_BOB then
        -- Bob-omb Battlefield: clean, stable water surfaces only.
        -- Keep the bridge pool tightly inside its intended basin so the water
        -- does not overlap the bridge or spill into nearby geometry.
        fill_water_surface(-3400, -2000, 3000, 4400, 45, 160)

        -- Mud Lake: match the fishable area instead of using an offset patch.
        fill_water_surface(-2800, 1600, -600, 1400, 52, 165)

    elseif level == LEVEL_CASTLE_GROUNDS then
        -- Main pond + edge toward the caged cannon shoreline
        fill_water_surface(-700, 950, 2700, 3400, 205, 140)
        for i = 0, 8 do
            add_water_piece(E_MODEL_BUBBLE, -400 + i * 130, 215, 3000, 1.4, 1.4, 1.4)
        end
        for i = 0, 5 do
            add_water_piece(E_MODEL_WATER_RING, 700 + i * 40, 208, 2900 + i * 30, 2.4, 0.5, 2.4)
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

    elseif level == LEVEL_TTC then
        local cy = -4850
        fill_water_surface(1000, 1800, -1000, -200, cy, 160)
        for i = 0, 10 do
            local ang = i * (3.14159 * 2 / 11)
            local r = 280 + (i % 3) * 40
            add_water_piece(
                E_MODEL_WATER_RING,
                1416 + math.cos(ang) * r,
                cy + 6,
                -578 + math.sin(ang) * r,
                2.6, 0.5, 2.6
            )
        end
        for i = 0, 5 do
            local ang = i * (3.14159 * 2 / 6)
            add_water_piece(
                E_MODEL_IDLE_WATER_WAVE,
                1416 + math.cos(ang) * 180,
                cy + 2,
                -578 + math.sin(ang) * 180,
                3.2, 1.0, 3.2
            )
        end

    elseif level == LEVEL_RR then
        -- Rainbow Ride is kept vanilla during course initialization. Custom
        -- static water props here have been observed to trigger native CoopDX
        -- crashes while RR is building its scripted course objects.
        return

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

function fish_allowed_here(fishData)
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

function get_fish_by_id(id)
    for i = 1, #FISH do
        if FISH[i].id == id then return FISH[i] end
    end
    return nil
end

function roll_fish()
    local pst = ensure_sync()
    local noBait = (vis.castBaitId == nil or vis.castBaitId <= 0)
    local luck = get_rod_style().luck or 0
    if not noBait then
        local bt = get_bait_type(vis.castBaitId)
        luck = luck + (bt.luck or 0)
    end

    init_session_sync_fields()
    if (gGlobalSyncTable.fdxHotLevel or 0) ~= 0 and get_current_level() == gGlobalSyncTable.fdxHotLevel then
        luck = luck + (gGlobalSyncTable.fdxHotLuck or 0)
    end

    luck = luck + (cook.luckBonus or 0)

    local level = get_current_level()

    -- No bait: skip mystery fish and only allow low-tier (difficulty 1) catches.
    if not noBait then
        -- Hollowfin: fixed 6% chance on Tall Tall Mountain only
        if level == LEVEL_TTM then
            if math.random(1, 100) <= 6 then
                local mystery = get_fish_by_id(25)
                if mystery ~= nil then
                    return mystery
                end
            end
        end

        -- Prismwraith: fixed 6% chance on Rainbow Ride only
        if level == LEVEL_RR then
            if math.random(1, 100) <= 6 then
                local mystery = get_fish_by_id(34)
                if mystery ~= nil then
                    return mystery
                end
            end
        end

        -- Chronofin: fixed 6% chance on Tick Tock Clock only
        if level == LEVEL_TTC then
            if math.random(1, 100) <= 6 then
                local mystery = get_fish_by_id(43)
                if mystery ~= nil then
                    return mystery
                end
            end
        end
    end

    local pool = {}
    local totalRarity = 0
    local onThi = (level == LEVEL_THI)
    for i = 1, #FISH do
        local f = FISH[i]
        if f.isMystery then
            -- mystery is rolled above, never in the weighted pool
        elseif noBait and (f.difficulty or 1) > 1 then
            -- no bait only yields common / low-tier fish
        elseif onThi then
            if is_thi_pool_fish(f) then
                table.insert(pool, f)
                totalRarity = totalRarity + f.rarity
            end
        elseif fish_allowed_here(f) then
            table.insert(pool, f)
            local weight = f.rarity
            if (not noBait) and cook.rareTimer > 0 and (cook.rareBonus or 0) > 0 and f.rarity <= 5 then
                weight = weight * (1 + (cook.rareBonus / 100))
            end
            f._cookWeight = weight
            totalRarity = totalRarity + weight
        end
    end
    if #pool == 0 then
        return FISH[1]
    end

    totalRarity = math.max(1, math.floor(totalRarity + 0.5))
    local roll = math.random(1, totalRarity)
    if not noBait then
        roll = roll + math.floor(luck * 0.35)
    end
    if roll > totalRarity then roll = totalRarity end

    local acc = 0
    for i = 1, #pool do
        acc = acc + (pool[i]._cookWeight or pool[i].rarity)
        if roll <= acc then
            return pool[i]
        end
    end
    return pool[#pool]
end

function make_fish_record(fishData)
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
        rec.decayLeft = fishData.decayFrames or 5400
    end
    if fishData.isMystery then
        rec.isMystery = true
    end
    return rec
end

function get_fish_name(id)
    for i = 1, #FISH do
        if FISH[i].id == id then
            return FISH[i].name
        end
    end
    return "Unknown Fish"
end

function add_to_inventory(record)
    if #ui.inventory >= get_max_inventory() then
        return false
    end
    table.insert(ui.inventory, record)
    queue_save()
    return true
end

function get_inventory_value()
    local total = 0
    for i = 1, #ui.inventory do
        total = total + (ui.inventory[i].value or 1)
    end
    return total
end

function sell_all_fish(m)
    local total = get_inventory_value()
    local count = #ui.inventory
    if total <= 0 or count <= 0 then
        return 0, 0
    end
    local gained = add_wallet(total)
    ui.inventory = {}
    save_progress()
    return gained, count
end

function check_personal_record(record)
    if record == nil or record.weight == nil then
        return false
    end
    local isPersonal = false
    local pname = get_player_name()

    if record.weight > (ui.personalRecord.weight or 0) then
        ui.personalRecord.name = record.name
        ui.personalRecord.size = record.size
        ui.personalRecord.weight = record.weight
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
    {level = LEVEL_CASTLE_GROUNDS, kind = "bait", x = -1799,   y = 280, z = 4500, label = "Bait Shop"},
    {level = LEVEL_JRB,            kind = "sell", x = -5548, y = 1126, z = 55, label = "Fish Market"},
    {level = LEVEL_DDD,            kind = "bait", x = -3000, y = 100, z = 0,    label = "Bait Shop"},
    {level = LEVEL_DDD,            kind = "bait", x = 3500,  y = 100, z = -2000, label = "Bait Shop"},
    -- BoB shops
    {level = LEVEL_BOB,            kind = "bait", x = -2800, y = 40,  z = 4550, label = "Bait Shop"},
    {level = LEVEL_BOB,            kind = "sell", x = -3400,   y = 50,  z = 6600,  label = "Fish Market"},
    -- LLL shop
    {level = LEVEL_LLL,            kind = "sell", x = -3000, y = 307, z = 3600, label = "Fish Market"},
    -- Castle Courtyard shop
    {level = LEVEL_CASTLE_COURTYARD, kind = "bait", x = 0, y = 20, z = -1800, label = "Bait Shop"},
    -- Castle interior upper floor near the TTM painting
    {level = LEVEL_CASTLE, kind = "sell", x = -1700, y = 1178, z = -550, label = "Fish Market"},
}

local shop = {
    activeKind = nil,
    nearSign = nil,
    objs = {},
}

local TUTORIAL_SIGN = {
    level = LEVEL_CASTLE_GROUNDS,
    x = -2817, y = 260, z = 3673,
}

local tutorial = {
    objs = {},
    near = false,
}

-- Castle Grounds hard-mode signpost, positioned near the existing bridge/guide area.
local HARD_MODE_SIGN = {
    level = LEVEL_CASTLE_GROUNDS,
    x = -2500, y = 260, z = 3673,
}
local hardModeSign = {
    objs = {},
    near = false,
}

-- Between the Castle Grounds bait/sell signs
local FISHING_LUIGI = {
    level = LEVEL_CASTLE_GROUNDS,
    x = -2658, y = 310, z = 3673,
    yaw = 0,
    scale = 1.0,
}
local fishingLuigi = {
    objs = {},
}

function set_fishing_luigi_idle_animation(obj)
    if obj == nil or obj.header == nil or obj.header.gfx == nil then
        return
    end

    local gfx = obj.header.gfx
    local animInfo = gfx.animInfo
    if animInfo == nil then
        return
    end

    local idleId = MARIO_ANIM_IDLE_HEAD_CENTER
    if idleId == nil then
        idleId = MARIO_ANIM_IDLE_WITH_LIGHT_OBJ
    end
    if idleId == nil then
        return
    end

    -- Only initialize the animation when it is not already the requested idle.
    -- Reinitializing every frame would pin the animation to frame 0.
    if animInfo.animID == idleId and animInfo.curAnim ~= nil then
        return
    end

    if get_mario_vanilla_animation ~= nil then
        local ok, anim = pcall(get_mario_vanilla_animation, idleId)
        if ok and anim ~= nil then
            animInfo.curAnim = anim
            animInfo.animID = idleId
            animInfo.prevAnimID = idleId
            animInfo.prevAnimPtr = anim
            animInfo.animFrame = 0
            animInfo.prevAnimFrame = 0
            animInfo.prevAnimFrameTimestamp = 0
            animInfo.animFrameAccelAssist = 0
            animInfo.animAccel = 0x10000
            animInfo.animTimer = 0
            animInfo.animYTrans = 0
            return
        end
    end

    -- Keep the fallback harmless on older builds without the vanilla-animation API.
    animInfo.animID = idleId
    animInfo.animFrame = 0
    animInfo.animAccel = 0x10000
end

function clear_fishing_luigi()
    for i = 1, #fishingLuigi.objs do
        if fishingLuigi.objs[i] ~= nil then
            obj_mark_for_deletion(fishingLuigi.objs[i])
        end
    end
    fishingLuigi.objs = {}
end

function spawn_fishing_luigi()
    if get_current_level() ~= FISHING_LUIGI.level then
        clear_fishing_luigi()
        return
    end
    if #fishingLuigi.objs > 0 then return end

    local model = load_fishing_luigi_model()
    local bhv = id_bhvStaticObject
    if bhv == nil then bhv = id_bhvWoodenPost end
    if bhv == nil then bhv = id_bhvBreakableBox end
    if model == nil or model == E_MODEL_NONE or bhv == nil then return end

    local o = spawn_non_sync_object(bhv, model,
        FISHING_LUIGI.x, FISHING_LUIGI.y, FISHING_LUIGI.z,
        function(obj)
            obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
            obj.oInteractType = 0
            obj.oIntangibleTimer = -1
            obj.oDamageOrCoinValue = 0
            obj.oNumLootCoins = 0
            obj.oVelX = 0
            obj.oVelY = 0
            obj.oVelZ = 0
            obj.oForwardVel = 0
            obj.oFaceAnglePitch = 0
            obj.oMoveAnglePitch = 0
            obj.oFaceAngleRoll = 0
            obj.oMoveAngleRoll = 0
            obj.oFaceAngleYaw = FISHING_LUIGI.yaw
            obj.oMoveAngleYaw = FISHING_LUIGI.yaw
            obj.oHomeX = FISHING_LUIGI.x
            obj.oHomeY = FISHING_LUIGI.y
            obj.oHomeZ = FISHING_LUIGI.z
            if obj.header ~= nil and obj.header.gfx ~= nil then
                obj.header.gfx.scale.x = FISHING_LUIGI.scale
                obj.header.gfx.scale.y = FISHING_LUIGI.scale
                obj.header.gfx.scale.z = FISHING_LUIGI.scale
                obj.header.gfx.angle.x = 0
                obj.header.gfx.angle.y = FISHING_LUIGI.yaw
                obj.header.gfx.angle.z = 0
                set_fishing_luigi_idle_animation(obj)
                if obj.header.gfx.node ~= nil then
                    obj.header.gfx.node.flags = obj.header.gfx.node.flags | GRAPH_RENDER_ACTIVE
                end
            end
        end)

    if o ~= nil then
        o.oPosX = FISHING_LUIGI.x
        o.oPosY = FISHING_LUIGI.y
        o.oPosZ = FISHING_LUIGI.z
        o.oFaceAnglePitch = 0
        o.oMoveAnglePitch = 0
        o.oFaceAngleRoll = 0
        o.oMoveAngleRoll = 0
        o.oFaceAngleYaw = FISHING_LUIGI.yaw
        o.oMoveAngleYaw = FISHING_LUIGI.yaw
        table.insert(fishingLuigi.objs, o)
    end
end

function update_fishing_luigi()
    if get_current_level() ~= FISHING_LUIGI.level then
        clear_fishing_luigi()
        return
    end

    -- This NPC is a permanent prop: never let its behavior, physics, or
    -- player interaction move it. Re-pin both the object and its gfx every
    -- frame so Mario can walk around without carrying/pulling Luigi.
    for i = #fishingLuigi.objs, 1, -1 do
        local obj = fishingLuigi.objs[i]
        if obj == nil or obj.header == nil or obj.header.gfx == nil then
            table.remove(fishingLuigi.objs, i)
        else
            obj.oPosX = FISHING_LUIGI.x
            obj.oPosY = FISHING_LUIGI.y
            obj.oPosZ = FISHING_LUIGI.z
            obj.oVelX = 0
            obj.oVelY = 0
            obj.oVelZ = 0
            obj.oForwardVel = 0
            obj.oFaceAnglePitch = 0
            obj.oMoveAnglePitch = 0
            obj.oFaceAngleYaw = FISHING_LUIGI.yaw
            obj.oMoveAngleYaw = FISHING_LUIGI.yaw
            obj.oFaceAngleRoll = 0
            obj.oMoveAngleRoll = 0
            obj.header.gfx.pos.x = FISHING_LUIGI.x
            obj.header.gfx.pos.y = FISHING_LUIGI.y
            obj.header.gfx.pos.z = FISHING_LUIGI.z
            obj.header.gfx.angle.x = 0
            obj.header.gfx.angle.y = FISHING_LUIGI.yaw
            obj.header.gfx.angle.z = 0
            obj.header.gfx.scale.x = FISHING_LUIGI.scale
            obj.header.gfx.scale.y = FISHING_LUIGI.scale
            obj.header.gfx.scale.z = FISHING_LUIGI.scale
            set_fishing_luigi_idle_animation(obj)
        end
    end

    if #fishingLuigi.objs == 0 then
        spawn_fishing_luigi()
    end
end

local function tutorial_distance(m)
    if m == nil then return 99999 end
    local dx = m.pos.x - TUTORIAL_SIGN.x
    local dy = m.pos.y - TUTORIAL_SIGN.y
    local dz = m.pos.z - TUTORIAL_SIGN.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function clear_tutorial_sign()
    for i = 1, #tutorial.objs do
        if tutorial.objs[i] ~= nil then
            obj_mark_for_deletion(tutorial.objs[i])
        end
    end
    tutorial.objs = {}
    tutorial.near = false
    ui.showTutorial = false
end

function spawn_tutorial_sign()
    if get_current_level() ~= LEVEL_CASTLE_GROUNDS then
        clear_tutorial_sign()
        return
    end
    if #tutorial.objs > 0 then return end

    local signModel = E_MODEL_WOODEN_SIGNPOST
    if signModel == nil or signModel == E_MODEL_NONE then
        signModel = E_MODEL_WOODEN_POST
    end
    if signModel == nil or signModel == E_MODEL_NONE then
        return
    end

    local bhv = id_bhvStaticObject
    if bhv == nil then
        bhv = id_bhvWoodenPost
    end
    if bhv == nil then
        bhv = id_bhvBreakableBox
    end
    if bhv == nil then return end

    local o = spawn_non_sync_object(bhv, signModel,
        TUTORIAL_SIGN.x, TUTORIAL_SIGN.y, TUTORIAL_SIGN.z,
        function(obj)
            obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
            obj.oInteractType = 0
            obj.oIntangibleTimer = -1
            obj.oDamageOrCoinValue = 0
            obj.oNumLootCoins = 0
            obj.oVelX = 0
            obj.oVelY = 0
            obj.oVelZ = 0
            obj.oForwardVel = 0
            obj.oHomeX = TUTORIAL_SIGN.x
            obj.oHomeY = TUTORIAL_SIGN.y
            obj.oHomeZ = TUTORIAL_SIGN.z
            -- Face the sign
            obj.oFaceAngleYaw = 0
            obj.oMoveAngleYaw = 0
            if obj.header ~= nil and obj.header.gfx ~= nil then
                obj.header.gfx.scale.x = 1.0
                obj.header.gfx.scale.y = 1.0
                obj.header.gfx.scale.z = 1.0
            end
        end)

    if o ~= nil then
        o.oPosX = TUTORIAL_SIGN.x
        o.oPosY = TUTORIAL_SIGN.y
        o.oPosZ = TUTORIAL_SIGN.z
        table.insert(tutorial.objs, o)
    end
end


function clear_hard_mode_sign()
    for i = 1, #hardModeSign.objs do
        if hardModeSign.objs[i] ~= nil then
            obj_mark_for_deletion(hardModeSign.objs[i])
        end
    end
    hardModeSign.objs = {}
    hardModeSign.near = false
    ui.showHardMode = false
end

function spawn_hard_mode_sign()
    if get_current_level() ~= LEVEL_CASTLE_GROUNDS then
        clear_hard_mode_sign()
        return
    end
    if #hardModeSign.objs > 0 then return end

    local signModel = E_MODEL_WOODEN_SIGNPOST
    if signModel == nil or signModel == E_MODEL_NONE then signModel = E_MODEL_WOODEN_POST end
    local bhv = id_bhvStaticObject
    if bhv == nil then bhv = id_bhvWoodenPost end
    if bhv == nil then bhv = id_bhvBreakableBox end
    if signModel == nil or signModel == E_MODEL_NONE or bhv == nil then return end

    local o = spawn_non_sync_object(bhv, signModel,
        HARD_MODE_SIGN.x, HARD_MODE_SIGN.y, HARD_MODE_SIGN.z,
        function(obj)
            obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
            obj.oInteractType = 0
            obj.oIntangibleTimer = -1
            obj.oDamageOrCoinValue = 0
            obj.oNumLootCoins = 0
            obj.oVelX = 0
            obj.oVelY = 0
            obj.oVelZ = 0
            obj.oForwardVel = 0
            obj.oHomeX = HARD_MODE_SIGN.x
            obj.oHomeY = HARD_MODE_SIGN.y
            obj.oHomeZ = HARD_MODE_SIGN.z
            obj.oFaceAngleYaw = 0
            obj.oMoveAngleYaw = 0
            if obj.header ~= nil and obj.header.gfx ~= nil then
                obj.header.gfx.scale.x = 1.0
                obj.header.gfx.scale.y = 1.0
                obj.header.gfx.scale.z = 1.0
            end
        end)
    if o ~= nil then
        o.oPosX = HARD_MODE_SIGN.x
        o.oPosY = HARD_MODE_SIGN.y
        o.oPosZ = HARD_MODE_SIGN.z
        table.insert(hardModeSign.objs, o)
    end
end

function hard_mode_distance(m)
    if m == nil then return 99999 end
    local dx = m.pos.x - HARD_MODE_SIGN.x
    local dy = m.pos.y - HARD_MODE_SIGN.y
    local dz = m.pos.z - HARD_MODE_SIGN.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function dist_to_sign(m, sign)
    local dx = m.pos.x - sign.x
    local dy = m.pos.y - sign.y
    local dz = m.pos.z - sign.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end

function get_nearest_shop_sign(m)
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

function near_bait_shop(m)
    return shop.activeKind == "bait"
end

function near_sell_shop(m)
    return shop.activeKind == "sell"
end

function near_fireplace(m)
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

function destroy_fire_objs()
    for i = 1, #cook.fireObjs do
        if cook.fireObjs[i] ~= nil then
            obj_mark_for_deletion(cook.fireObjs[i])
        end
    end
    cook.fireObjs = {}
    cook.fireSpawned = false
    cook.campfireObj = nil
end

function spawn_fireplace()
    local np = gNetworkPlayers[0]
    if np == nil then return end
    if np.currLevelNum ~= LEVEL_CASTLE or np.currAreaIndex ~= 1 then
        destroy_fire_objs()
        cook.fireLevel = -1
        return
    end
    if cook.fireSpawned and cook.fireLevel == LEVEL_CASTLE and cook.campfireObj ~= nil then
        return
    end
    destroy_fire_objs()
    cook.campfireObj = nil
    cook.fireLevel = LEVEL_CASTLE

    local baseX, baseY, baseZ = 0, 0, -220
    local campModel = load_campfire_model()
    if campModel ~= nil then
        local bhv = id_bhvStaticObject
        if bhv == nil then bhv = id_bhvTree end
        if bhv ~= nil then
            local camp = spawn_non_sync_object(
                bhv,
                campModel,
                baseX, baseY, baseZ,
                function(obj)
                    obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
                    obj.oInteractType = 0
                    obj.oIntangibleTimer = -1
                    obj.header.gfx.scale.x = 0.45
                    obj.header.gfx.scale.y = 0.45
                    obj.header.gfx.scale.z = 0.45
                end
            )
            cook.campfireObj = camp
            table.insert(cook.fireObjs, camp)
        end
    end

    local flameY = baseY + 55
    local offsets = {
        {0, 0, 0}, {35, 8, 15}, {-35, 8, 15},
        {18, 20, -8}, {-18, 20, -8}, {0, 32, 8},
    }
    for i = 1, #offsets do
        local o = offsets[i]
        local flame = spawn_non_sync_object(
            id_bhvFlame,
            E_MODEL_RED_FLAME,
            baseX + o[1], flameY + o[2], baseZ + o[3],
            function(obj)
                obj.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE
                obj.oInteractType = 0
                obj.oIntangibleTimer = -1
                obj.header.gfx.scale.x = 1.35
                obj.header.gfx.scale.y = 1.35
                obj.header.gfx.scale.z = 1.35
            end
        )
        table.insert(cook.fireObjs, flame)
    end
    if cook.campfireObj ~= nil then
        cook.fireSpawned = true
    else
        cook.fireSpawned = false
    end
end

function get_cook_recipe(record)
    if record == nil then return nil end
    local id = record.id or 0

    if id == 15 then
        return {name = "VOID FEAST", desc = "Huge rare-spawn chance", speed = 0, luck = 0, rare = 35, jump = 0, seconds = 90}
    elseif id == 25 or id == 34 then
        return {name = "MYSTIC FEAST", desc = "Massive rare-spawn chance", speed = 0, luck = 0, rare = 45, jump = 0, seconds = 90}
    elseif id == 7 or id == 9 or id == 13 or id == 21 or id == 23 or id == 24 or id == 27 then
        return {name = "LUCKY FEAST", desc = "Better rare fish odds", speed = 0, luck = 22, rare = 12, jump = 0, seconds = 90}
    elseif id == 4 or id == 8 or id == 10 or id == 14 or id == 26 or id == 29 or id == 31 or id == 33 then
        return {name = "POWER FEAST", desc = "Speed + stronger jumps", speed = 1, luck = 0, rare = 5, jump = 2, seconds = 100}
    elseif id == 16 or id == 17 or id == 18 or id == 19 or id == 20 then
        return {name = "HOT FEAST", desc = "Fast movement + rare odds", speed = 2, luck = 0, rare = 8, jump = 1, seconds = 90}
    else
        return {name = "SPEED FEAST", desc = "Movement speed boost", speed = 2, luck = 0, rare = 0, jump = 1, seconds = 100}
    end
end

function cook_one_fish(m, index)
    if #ui.inventory <= 0 then return false end
    index = index or 1
    if index < 1 or index > #ui.inventory then index = 1 end

    local cooked = ui.inventory[index]
    local recipe = get_cook_recipe(cooked)
    if cooked == nil or recipe == nil then return false end

    table.remove(ui.inventory, index)
    local frames = recipe.seconds * 30

    if recipe.speed > 0 then cook.boostTimer = math.max(cook.boostTimer, frames) end
    if recipe.rare > 0 then
        cook.rareTimer = math.max(cook.rareTimer, frames)
        cook.rareBonus = recipe.rare
    end
    if recipe.luck > 0 then
        cook.luckTimer = math.max(cook.luckTimer, frames)
        cook.luckBonus = recipe.luck
    end
    if recipe.jump > 0 then
        cook.jumpTimer = math.max(cook.jumpTimer, frames)
        cook.jumpBonus = recipe.jump
    end

    djui_chat_message_create(string.format(
        "Cooked %s: %s (%ds). %s",
        cooked.name or "fish", recipe.name, recipe.seconds, recipe.desc
    ))
    sfx(SOUND_GENERAL_COIN, m)
    save_progress()
    return true
end

function close_cook_menu()
    cook.menuOpen = false
    cook.selectedIndex = 1
end

function open_cook_menu()
    if #ui.inventory <= 0 then return false end
    cook.menuOpen = true
    if cook.selectedIndex < 1 or cook.selectedIndex > #ui.inventory then cook.selectedIndex = 1 end
    return true
end

function apply_cook_boost(m)
    if cook.boostTimer > 0 then
        cook.boostTimer = cook.boostTimer - 1
        if m.forwardVel > 8 then
            m.forwardVel = math.min(72, m.forwardVel + 1.15)
        end
    end

    if cook.rareTimer > 0 then cook.rareTimer = cook.rareTimer - 1 else cook.rareBonus = 0 end
    if cook.luckTimer > 0 then cook.luckTimer = cook.luckTimer - 1 else cook.luckBonus = 0 end

    if cook.jumpTimer > 0 then
        cook.jumpTimer = cook.jumpTimer - 1
        if m.action == ACT_JUMP or m.action == ACT_DOUBLE_JUMP or m.action == ACT_TRIPLE_JUMP then
            if m.vel.y > 0 and m.vel.y < 50 then m.vel.y = m.vel.y + (cook.jumpBonus or 0) * 0.18 end
        end
    else
        cook.jumpBonus = 0
    end
end

function destroy_aim_marker()
    for i = 1, #vis.aimMarkers do
        if vis.aimMarkers[i] ~= nil then
            obj_mark_for_deletion(vis.aimMarkers[i])
        end
    end
    vis.aimMarkers = {}
    vis.aimActive = false
end

function destroy_fishing_objects()
    if vis.rodObj ~= nil then
        obj_mark_for_deletion(vis.rodObj)
        vis.rodObj = nil
    end
    if vis.rodTipObj ~= nil then
        obj_mark_for_deletion(vis.rodTipObj)
        vis.rodTipObj = nil
    end
    if vis.bobberObj ~= nil then
        obj_mark_for_deletion(vis.bobberObj)
        vis.bobberObj = nil
    end
    if vis.fishObj ~= nil then
        obj_mark_for_deletion(vis.fishObj)
        vis.fishObj = nil
    end
    destroy_aim_marker()
end

function reset_fishing_state(pst)
    if pst ~= nil then
        pst.fishState = STATE.IDLE
        pst.fishTimer = 0
        pst.biteTimer = 0
        pst.miniProgress = 0
        pst.caughtId = 0
        pst.castPrompt = false
    end
    ui.lockedPos = nil
    destroy_fishing_objects()
    -- Caller is responsible for refund_cast_bait before reset when cancelling.
    -- Successful catch / normal end clears the pending refund so bait stays spent.
end

function obj_is_alive(o)
    return o ~= nil and o.activeFlags ~= nil and o.activeFlags ~= 0
end

function harden_visual(o, sx, sy, sz)
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
function make_visual_obj(model, x, y, z, sx, sy, sz)
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
function get_cast_aim_pos(m)
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

function spawn_aim_piece(model, x, y, z, sx, sy, sz)
    if model == nil then return nil end
    local o = make_visual_obj(model, x, y, z, sx, sy, sz)
    if o ~= nil then
        harden_visual(o, sx, sy, sz)
        table.insert(vis.aimMarkers, o)
    end
    return o
end

-- Hold L: flat reticle on the water only (no floating props, no flash)
function update_cast_aim_preview(m, holdingAim)
    if not holdingAim then
        destroy_aim_marker()
        return
    end
    vis.aimActive = true
    local pos = get_cast_aim_pos(m)

    if #vis.aimMarkers == 0 then
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
        if #vis.aimMarkers == 0 and E_MODEL_YELLOW_COIN ~= nil then
            spawn_aim_piece(E_MODEL_YELLOW_COIN, pos.x, pos.y + 4, pos.z, 0.8, 0.25, 0.8)
        end
    end

    for i = 1, #vis.aimMarkers do
        local o = vis.aimMarkers[i]
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

function spawn_rod_and_bobber(m)
    destroy_fishing_objects()

    local yaw = m.faceAngle.y
    local s = sins(yaw)
    local c = coss(yaw)
    local style = get_rod_style()

    -- Pole only - no tip model (no coin generator)
    -- Gold: actors/pole (pole_geo). Metal: actors/metalpole (metalpole_geo).
    local body = style.body
    if body == nil and style.useWoodRod then
        body = load_wood_rod_model()
    end
    if body == nil and style.useLegendaryRod then
        body = load_legendary_rod_model()
    end
    if body == nil and style.useGoldPole then
        body = load_gold_pole_model()
    end
    if body == nil and style.useMetalPole then
        body = load_metal_pole_model()
    end
    if body == nil and style.useMasterPole then
        body = load_master_pole_model()
    end
    if body == nil then
        body = E_MODEL_METAL_BOX
    end

    local holdX = m.pos.x + s * 40
    local holdY = m.pos.y + 48
    local holdZ = m.pos.z + c * 40
    local pitch = 0x3000

    if style.useLegendaryRod then
        -- Legendary mesh is authored oversized and off-center.
        -- Correct its local origin so it sits in Mario's hands instead of to his left.
        local ox = style.ox or 0
        local oy = style.oy or 0
        local oz = style.oz or 0
        holdX = holdX + c * ox + s * oz
        holdY = holdY + oy
        holdZ = holdZ - s * ox + c * oz
    end
    -- Custom pole meshes are upright on Y; tilt forward toward the water
    if style.useWoodRod or style.useLegendaryRod or style.useGoldPole or style.useMetalPole or style.useMasterPole then
        holdY = m.pos.y + 36
        pitch = 0x3000
    end

    vis.rodObj = make_visual_obj(
        body,
        holdX,
        holdY,
        holdZ,
        style.bx, style.by, style.bz
    )
    if vis.rodObj ~= nil then
        vis.rodObj.oFaceAnglePitch = pitch
        vis.rodObj.oMoveAnglePitch = pitch
        vis.rodObj.oFaceAngleYaw = yaw
        vis.rodObj.oMoveAngleYaw = yaw
        harden_visual(vis.rodObj, style.bx, style.by, style.bz)
    end

    vis.rodTipObj = nil

    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 80
    end

    vis.bobberObj = make_visual_obj(
        E_MODEL_1UP,
        m.pos.x + s * CAST_DIST,
        waterY + 16,
        m.pos.z + c * CAST_DIST,
        0.55, 0.55, 0.55
    )
    if vis.bobberObj ~= nil then
        harden_visual(vis.bobberObj, 0.55, 0.55, 0.55)
    end
    destroy_aim_marker()
end

function spawn_fish_near_bobber(m)
    if obj_is_alive(vis.fishObj) then
        return
    end
    if vis.fishObj ~= nil then
        obj_mark_for_deletion(vis.fishObj)
        vis.fishObj = nil
    end

    local yaw = m.faceAngle.y
    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 80
    end

    -- Same safe non-breakable prop behavior as rod/bobber
    vis.fishObj = make_visual_obj(
        E_MODEL_FISH,
        m.pos.x + sins(yaw) * 235,
        waterY - 12,
        m.pos.z + coss(yaw) * 235,
        1.6, 1.6, 1.6
    )
    if vis.fishObj ~= nil then
        harden_visual(vis.fishObj, 1.6, 1.6, 1.6)
        vis.fishObj.oDamageOrCoinValue = 0
        vis.fishObj.oNumLootCoins = 0
        vis.fishObj.oInteractType = 0
        vis.fishObj.oIntangibleTimer = -1
    end
end


function ensure_fishing_visuals(m)
    local st = ensure_sync().fishState
    if st == STATE.IDLE or st == STATE.CATCH then
        return
    end

    if vis.fishRespawnCooldown > 0 then vis.fishRespawnCooldown = vis.fishRespawnCooldown - 1 end
    if vis.rodRespawnCooldown > 0 then vis.rodRespawnCooldown = vis.rodRespawnCooldown - 1 end

    local needRod = (not obj_is_alive(vis.rodObj)) or (not obj_is_alive(vis.bobberObj))
    if needRod and vis.rodRespawnCooldown <= 0 then
        spawn_rod_and_bobber(m)
        vis.rodRespawnCooldown = 20
    end

    if st == STATE.WAITING or st == STATE.BITE or st == STATE.MINIGAME then
        if not obj_is_alive(vis.fishObj) and vis.fishRespawnCooldown <= 0 then
            spawn_fish_near_bobber(m)
            vis.fishRespawnCooldown = 20
        end
    end
end

function update_fishing_objects(m)
    ensure_fishing_visuals(m)

    local yaw = m.faceAngle.y
    local s = sins(yaw)
    local c = coss(yaw)
    local t = get_global_timer()
    local st = ensure_sync().fishState
    local style = get_rod_style()

    if obj_is_alive(vis.rodObj) then
        vis.rodObj.oPosX = m.pos.x + s * 40
        vis.rodObj.oPosY = m.pos.y + 48
        vis.rodObj.oPosZ = m.pos.z + c * 40
        vis.rodObj.oFaceAngleYaw = yaw
        vis.rodObj.oMoveAngleYaw = yaw
        vis.rodObj.oFaceAnglePitch = 0x3000
        vis.rodObj.oMoveAnglePitch = 0x3000
        vis.rodObj.oDamageOrCoinValue = 0
        vis.rodObj.oNumLootCoins = 0
        vis.rodObj.oInteractType = 0
        vis.rodObj.oIntangibleTimer = -1
        harden_visual(vis.rodObj, style.bx, style.by, style.bz)
    end

    local waterY = get_fishing_water_y(m)
    if waterY == nil then
        waterY = m.pos.y - 80
    end

    if obj_is_alive(vis.bobberObj) then
        local bob = math.sin(t / 10) * 6
        if st == STATE.BITE or st == STATE.MINIGAME then
            bob = math.sin(t / 3) * 10
        end
        vis.bobberObj.oPosX = m.pos.x + s * CAST_DIST
        vis.bobberObj.oPosY = waterY + 16 + bob
        vis.bobberObj.oPosZ = m.pos.z + c * CAST_DIST
        vis.bobberObj.oDamageOrCoinValue = 0
        vis.bobberObj.oNumLootCoins = 0
        vis.bobberObj.oInteractType = 0
        vis.bobberObj.oIntangibleTimer = -1
        harden_visual(vis.bobberObj, 0.55, 0.55, 0.55)
    end

    if obj_is_alive(vis.fishObj) then
        local shake = 0.5
        if st == STATE.BITE or st == STATE.MINIGAME then
            shake = 1.2
        end
        local tx = m.pos.x + s * 235 + math.sin(t / 12) * 10 * shake
        local ty = waterY - 12 + math.sin(t / 8) * 6 * shake
        local tz = m.pos.z + c * 235 + math.cos(t / 14) * 10 * shake

        vis.fishObj.oPosX = vis.fishObj.oPosX + (tx - vis.fishObj.oPosX) * 0.2
        vis.fishObj.oPosY = vis.fishObj.oPosY + (ty - vis.fishObj.oPosY) * 0.2
        vis.fishObj.oPosZ = vis.fishObj.oPosZ + (tz - vis.fishObj.oPosZ) * 0.2
        vis.fishObj.oFaceAngleYaw = yaw + 0x4000
        vis.fishObj.oMoveAngleYaw = vis.fishObj.oFaceAngleYaw
        vis.fishObj.oVelX = 0
        vis.fishObj.oVelY = 0
        vis.fishObj.oVelZ = 0
        vis.fishObj.oForwardVel = 0
        vis.fishObj.oInteractType = 0
        vis.fishObj.oIntangibleTimer = -1
        vis.fishObj.oDamageOrCoinValue = 0
        vis.fishObj.oNumLootCoins = 0
        -- Hollowfin uses the custom texture billboard instead of the vanilla fish mesh
        if is_hollowfin_active() then
            harden_visual(vis.fishObj, 0.01, 0.01, 0.01)
            if vis.fishObj.header ~= nil and vis.fishObj.header.gfx ~= nil and vis.fishObj.header.gfx.node ~= nil then
                -- keep object alive for position tracking, but fully invisible
                vis.fishObj.header.gfx.node.flags = vis.fishObj.header.gfx.node.flags | GRAPH_RENDER_INVISIBLE
            end
        else
            if vis.fishObj.header ~= nil and vis.fishObj.header.gfx ~= nil and vis.fishObj.header.gfx.node ~= nil then
                vis.fishObj.header.gfx.node.flags = vis.fishObj.header.gfx.node.flags & ~GRAPH_RENDER_INVISIBLE
            end
            harden_visual(vis.fishObj, 1.6, 1.6, 1.6)
        end
    end
end

function clear_shop_sign_objs()
    for i = 1, #shop.objs do
        if shop.objs[i] ~= nil then
            obj_mark_for_deletion(shop.objs[i])
        end
    end
    shop.objs = {}
    clear_tutorial_sign()
    clear_hard_mode_sign()
    clear_fishing_luigi()
    -- Boat props live in the shop object list on DDD
    boats.ddd = nil
    boats.dddCols = {}
    boats.dddLevel = -1
end

function add_shop_prop(model, x, y, z, sx, sy, sz, yaw)
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
        table.insert(shop.objs, o)
    end
    return o
end

function spawn_shop_stall(s)
    local model = E_MODEL_TREASURE_CHEST_BASE
    if model == nil then
        model = E_MODEL_BREAKABLE_BOX
    end
    add_shop_prop(model, s.x, s.y, s.z, 1.35, 1.0, 1.35, 0)

    -- DDD bait shop: fishing boat + solid deck beside the shop
    if s.level == LEVEL_DDD and s.kind == "bait" then
        local bx = s.x - 280
        -- Deck sits lower in the water than the shop counter
        local by = s.y - 70
        local bz = s.z - 300

        -- Invisible wood/deck collision: keep the solid footing, but do NOT render
        -- the wooden posts/planks. The custom boat should remain fully visible.
        -- These use the same footprint/height as the old visible wood pieces.
        local d1 = spawn_boat_collision_pad(bx, by, bz, 1.6, 0.46, 3.2)
        local d2 = spawn_boat_collision_pad(bx + 110, by, bz, 1.8, 0.55, 3.6)
        local d3 = spawn_boat_collision_pad(bx - 105, by, bz, 1.6, 0.55, 3.6)
        if d1 ~= nil then table.insert(boats.dddCols, d1) end
        if d2 ~= nil then table.insert(boats.dddCols, d2) end
        if d3 ~= nil then table.insert(boats.dddCols, d3) end

        -- Full custom-boat collision. These overlapping pads cover the entire hull/deck
        -- footprint instead of leaving the bow, stern, or outer sides without collision.
        local colPads = {
            {0, 12, 0, 5.6, 1.2, 7.2},
            {0, 12, 145, 5.0, 1.2, 3.2},
            {0, 12, -145, 5.0, 1.2, 3.2},
            {165, 12, 0, 2.4, 1.2, 6.2},
            {-165, 12, 0, 2.4, 1.2, 6.2},
            {120, 12, 115, 2.6, 1.2, 3.0},
            {-120, 12, 115, 2.6, 1.2, 3.0},
            {120, 12, -115, 2.6, 1.2, 3.0},
            {-120, 12, -115, 2.6, 1.2, 3.0},
        }
        for i = 1, #colPads do
            local p = colPads[i]
            local col = spawn_boat_collision_pad(bx + p[1], by + p[2], bz + p[3], p[4], p[5], p[6])
            if col ~= nil then
                table.insert(boats.dddCols, col)
            end
        end

        -- random math ahead nobody cares about
        -- It intentionally sits low enough to work as a first step, while its collision is solid.
        local stepModel = E_MODEL_BREAKABLE_BOX_SMALL
        if stepModel == nil then stepModel = E_MODEL_METAL_BOX end
        if stepModel == nil then stepModel = E_MODEL_BREAKABLE_BOX end
        if stepModel ~= nil then
            -- Move the step farther away from the hull so Mario can stand and jump onto it.
            local stepX, stepY, stepZ = bx + 330, by - 12, bz + 145
            local step = add_shop_prop(stepModel, stepX, stepY, stepZ, 0.9, 0.55, 0.9, 0)
            if step ~= nil then table.insert(boats.dddCols, step) end
            local stepCol = spawn_boat_collision_pad(stepX, stepY + 8, stepZ, 1.05, 0.7, 1.05)
            if stepCol ~= nil then table.insert(boats.dddCols, stepCol) end
        end

        -- Boat mesh bigger, flipped upright (not face-down)
        local bm = load_boat_model()
        local scx, scy, scz = -52.0, 3.5, 5.2
        if boatModelCustom then
            scx, scy, scz = 4.4, 2.4, 2.8
        elseif E_MODEL_JRB_SHIP_LEFT_HALF_PART ~= nil then
            bm = E_MODEL_JRB_SHIP_LEFT_HALF_PART
            scx, scy, scz = 2.6, 2.0, 3.4
        elseif E_MODEL_TREASURE_CHEST_BASE ~= nil then
            bm = E_MODEL_TREASURE_CHEST_BASE
            scx, scy, scz = 3.5, 2.6, 3.5
        end

        local hull = spawn_non_sync_object(id_bhvDDDBoatIdle, bm, bx, by + 30, bz, function(obj)
            obj.oFaceAngleYaw = 0x4000
            obj.oMoveAngleYaw = 0x4000
            if obj.header ~= nil and obj.header.gfx ~= nil then
                obj.header.gfx.scale.x = scx
                obj.header.gfx.scale.y = scy
                obj.header.gfx.scale.z = scz
            end
        end)
        if hull ~= nil then
            hull.oPosX = bx
            hull.oPosY = by + 30
            hull.oPosZ = bz
            hull.oHomeX = bx
            hull.oHomeY = by + 30
            hull.oHomeZ = bz
            table.insert(shop.objs, hull)
        end
        if hull ~= nil then
            -- The custom behavior owns the idle bob/rock. Keep the model upright
            -- and leave every collision object completely untouched.
            local pitch = 0x400
            hull.oFaceAnglePitch = pitch
            hull.oMoveAnglePitch = pitch
            hull.oFaceAngleRoll = 0
            hull.oMoveAngleRoll = 0
            hull.oFaceAngleYaw = 0x4000
            hull.oMoveAngleYaw = 0x4000
            if hull.header ~= nil and hull.header.gfx ~= nil then
                hull.header.gfx.scale.x = scx
                hull.header.gfx.scale.y = scy
                hull.header.gfx.scale.z = scz
            end
            boats.ddd = hull
            boats.dddLevel = LEVEL_DDD
        elseif d1 ~= nil then
            boats.ddd = d1
            boats.dddLevel = LEVEL_DDD
        end
    end
end

function spawn_shop_signs()
    local level = get_current_level()
    if vis.shopSignsSpawned and vis.lastShopLevel == level then
        return
    end
    vis.shopSignsSpawned = true
    vis.lastShopLevel = level
    clear_shop_sign_objs()
    shop.activeKind = nil

    for i = 1, #SHOP_SIGNS do
        local s = SHOP_SIGNS[i]
        if s.level == level then
            spawn_shop_stall(s)
        end
    end
    if level == LEVEL_CASTLE_GROUNDS then
        spawn_tutorial_sign()
        spawn_hard_mode_sign()
        spawn_fishing_luigi()
    end
end

function lock_mario_while_fishing(m)
    m.forwardVel = 0
    m.vel.x = 0
    m.vel.z = 0
    if m.vel.y > 0 then
        m.vel.y = 0
    end
    if ui.lockedPos ~= nil then
        m.pos.x = ui.lockedPos.x
        m.pos.z = ui.lockedPos.z
    end
end

function cancel_if_needed(m, pst, ctrl)
    if pst.fishState == STATE.IDLE or pst.fishState == STATE.CATCH then
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

function mario_update(m)
    if m.playerIndex ~= 0 then
        return
    end

    -- Castle Grounds boat warps need a clean handoff to the vanilla course.
    -- In particular, RR can still be constructing its camera/object state for
    -- a number of frames. Keep Fishing DX completely out of the transition.
    if travelWarpGuard.active
        and travelWarpGuard.level ~= LEVEL_TTC
        and travelWarpGuard.level ~= LEVEL_RR then
        local currentLevel = get_current_level()
        if currentLevel == travelWarpGuard.level then
            travelWarpGuard.frames = travelWarpGuard.frames - 1
            if travelWarpGuard.frames <= 0 then
                travelWarpGuard.active = false
                pendingTravel.active = false
            end
        else
            -- Still loading/transitioning; don't run Fishing DX gameplay code.
            travelWarpGuard.frames = travelWarpGuard.frames - 1
            if travelWarpGuard.frames <= 0 then
                travelWarpGuard.active = false
                pendingTravel.active = false
            end
        end
        return
    end

    update_fishing_luigi()
    local pst = ensure_sync()
    local ctrl = m.controller
    apply_admin_progress_updates(pst)
    apply_pending_safe_spawn(m)
    maybe_seed_wallet_from_coins(m)
    fix_active_bait(pst)
    ensure_hot_stage_rolled()
    apply_incoming_session_announcements()
    if banners.hotTimer > 0 then banners.hotTimer = banners.hotTimer - 1 end
    if banners.mysteryTimer > 0 then banners.mysteryTimer = banners.mysteryTimer - 1 end
    if banners.mysteryHookTimer > 0 then banners.mysteryHookTimer = banners.mysteryHookTimer - 1 end

    if ui.saveCooldown > 0 then
        ui.saveCooldown = ui.saveCooldown - 1
        if ui.saveCooldown == 0 then
            save_progress()
        end
    end

    if ui.shopCooldown > 0 then ui.shopCooldown = ui.shopCooldown - 1 end
    if ui.catchDisplayTimer > 0 then ui.catchDisplayTimer = ui.catchDisplayTimer - 1 end
    if ui.biteFlash > 0 then ui.biteFlash = ui.biteFlash - 1 end
    if ui.reelPulse > 0 then ui.reelPulse = ui.reelPulse - 1 end
    if ui.prBannerTimer > 0 then ui.prBannerTimer = ui.prBannerTimer - 1 end

    -- VOID fish decay: tick down every frame; remove when timer hits 0
    do
        local decayed = false
        for i = #ui.inventory, 1, -1 do
            local rec = ui.inventory[i]
            if rec ~= nil and rec.isVoid and rec.decayLeft ~= nil then
                rec.decayLeft = rec.decayLeft - 1
                if rec.decayLeft <= 0 then
                    djui_chat_message_create(string.format("%s decayed into the void...", rec.name or "VOID Fish"))
                    table.remove(ui.inventory, i)
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
    if boats.menuOpen then
        return
    end

    if level == LEVEL_CASTLE_GROUNDS or level == LEVEL_DDD or level == LEVEL_JRB
        or level == LEVEL_BOB or level == LEVEL_LLL or level == LEVEL_CASTLE_COURTYARD
        or level == LEVEL_CASTLE then
        spawn_shop_signs()
    else
        vis.shopSignsSpawned = false
        vis.lastShopLevel = -1
    end

    spawn_lake_decor()
    spawn_fireplace()
    apply_cook_boost(m)
    if cook.cooldown > 0 then cook.cooldown = cook.cooldown - 1 end

    -- Fish map pages / close, or ui.inventory toggle (Right D-Pad)
    if ui.showFishMap then
        local lines = get_fish_map_lines()
        local pages = math.max(1, math.ceil(#lines / FISH_MAP_PAGE_SIZE))
        if (ctrl.buttonPressed & L_JPAD) ~= 0 or (ctrl.buttonPressed & U_JPAD) ~= 0 then
            ui.fishMapPage = ui.fishMapPage - 1
            if ui.fishMapPage < 1 then ui.fishMapPage = pages end
        end
        if (ctrl.buttonPressed & R_JPAD) ~= 0 or (ctrl.buttonPressed & D_JPAD) ~= 0 then
            ui.fishMapPage = ui.fishMapPage + 1
            if ui.fishMapPage > pages then ui.fishMapPage = 1 end
        end
        if (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            close_fish_map()
        end
    elseif (ctrl.buttonPressed & R_JPAD) ~= 0 then
        if pst.fishState == STATE.IDLE and not near_bait_shop(m) and not near_sell_shop(m) then
            ui.showInventory = not ui.showInventory
            if ui.showInventory then ui.showFishMap = false end
        end
    end

    -- Left D-Pad: cycle unlocked rod types (when not in bait shop / not mid-fish / map closed)
    if (ctrl.buttonPressed & L_JPAD) ~= 0 and not ui.showFishMap then
        local canSwitch = pst.fishState == STATE.IDLE and not near_bait_shop(m) and not near_sell_shop(m) and not ui.showInventory
        if canSwitch then
            cycle_rod_left()
        end
    end

    -- While ui.inventory is open, Up/Down cycle equipped bait among types you own
    if ui.showInventory and pst.fishState == STATE.IDLE and not near_bait_shop(m) then
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

    -- Hard mode sign: press B to open/close and A to toggle the player's hard mode.
    hardModeSign.near = false
    if get_current_level() == LEVEL_CASTLE_GROUNDS and pst.fishState == STATE.IDLE then
        local hd = hard_mode_distance(m)
        if hd < 300 then
            hardModeSign.near = true
            if ui.hardModeCooldown > 0 then ui.hardModeCooldown = ui.hardModeCooldown - 1 end
            if not ui.showHardMode and ui.hardModeCooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
                ui.showHardMode = true
                ui.hardModeCooldown = 15
                shop.activeKind = nil
                ui.showTutorial = false
            elseif ui.showHardMode and ui.hardModeCooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
                ui.showHardMode = false
                ui.hardModeCooldown = 15
            end
        else
            ui.showHardMode = false
        end
    else
        ui.showHardMode = false
    end

    if ui.showHardMode then
        if (ctrl.buttonPressed & A_BUTTON) ~= 0 and ui.hardModeCooldown == 0 then
            pst.hardMode = not pst.hardMode
            ui.hardModeCooldown = 15
            queue_save()
            djui_chat_message_create(pst.hardMode and "HARD MODE enabled: catches are harder and fish sell for 2x." or "HARD MODE disabled.")
        end
        -- show hard-mode UI
        return
    end

    -- Fishing guide
    tutorial.near = false
    if get_current_level() == LEVEL_CASTLE_GROUNDS and pst.fishState == STATE.IDLE then
        local td = tutorial_distance(m)
        if td < 300 then
            tutorial.near = true
            if ui.tutorialCooldown > 0 then
                ui.tutorialCooldown = ui.tutorialCooldown - 1
            end
            if not ui.showTutorial and ui.tutorialCooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
                ui.showTutorial = true
                ui.tutorialCooldown = 15
                shop.activeKind = nil
            elseif ui.showTutorial and (ctrl.buttonPressed & B_BUTTON) ~= 0 and ui.tutorialCooldown == 0 then
                ui.showTutorial = false
                ui.tutorialCooldown = 15
            end
        else
            ui.showTutorial = false
        end
    else
        ui.showTutorial = false
    end

    if ui.showHardMode then
        -- Hard-mode UI is rendered from on_hud_render().  Do not draw HUD elements
        -- from mario_update(), since those draw calls are not guaranteed to persist
        -- to the HUD render pass.
        return
    end

    if ui.showTutorial then
        -- show guide
        return
    end

    -- Sign interaction: press B near sign to open ui
    -- Walk away to close. While open, B buys/sells and A upgrades rods.
    shop.nearSign = nil
    if pst.fishState == STATE.IDLE then
        local sign = get_nearest_shop_sign(m)
        if sign ~= nil then
            shop.nearSign = sign
            if shop.activeKind == nil and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
                shop.activeKind = sign.kind
                ui.shopCooldown = 12
                djui_chat_message_create(sign.label .. " - ready")
            end
        else
            shop.activeKind = nil
        end
    else
        shop.activeKind = nil
    end

    if hardModeSign.near and not ui.showHardMode then
        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_font(FONT_MENU)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("B: Read HARD MODE", 22, 190, 0.45)
    end

    if tutorial.near and not ui.showTutorial then
        djui_hud_set_resolution(RESOLUTION_DJUI)
        djui_hud_set_font(FONT_MENU)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("B: Read Fishing Guide", 22, 210, 0.45)
    end

    local baitPrompt = near_bait_shop(m) and pst.fishState == STATE.IDLE
    local sellPrompt = near_sell_shop(m) and pst.fishState == STATE.IDLE
    cook.prompt = near_fireplace(m) and pst.fishState == STATE.IDLE
    ui.shopPrompt = baitPrompt or sellPrompt or cook.prompt

    if cook.menuOpen then
        if not cook.prompt then
            close_cook_menu()
        elseif (ctrl.buttonPressed & U_JPAD) ~= 0 then
            cook.selectedIndex = cook.selectedIndex - 1
            if cook.selectedIndex < 1 then cook.selectedIndex = #ui.inventory end
        elseif (ctrl.buttonPressed & D_JPAD) ~= 0 then
            cook.selectedIndex = cook.selectedIndex + 1
            if cook.selectedIndex > #ui.inventory then cook.selectedIndex = 1 end
        elseif (ctrl.buttonPressed & A_BUTTON) ~= 0 and cook.cooldown == 0 then
            if cook_one_fish(m, cook.selectedIndex) then
                cook.cooldown = 30
                if #ui.inventory == 0 then close_cook_menu()
                elseif cook.selectedIndex > #ui.inventory then cook.selectedIndex = #ui.inventory end
            end
        elseif (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            close_cook_menu()
        end
    elseif cook.prompt and cook.cooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
        if #ui.inventory > 0 then
            open_cook_menu()
        else
            djui_chat_message_create("No fish to cook! Catch some first.")
            cook.cooldown = 20
        end
    end

    -- Bait shop: Left/Right = bait type, Up/Down = quantity, A = set active, B = buy
    if baitPrompt then
        if (ctrl.buttonPressed & U_JPAD) ~= 0 then
            ui.baitBuyIndex = ui.baitBuyIndex + 1
            if ui.baitBuyIndex > #BAIT_AMOUNTS then ui.baitBuyIndex = 1 end
        end
        if (ctrl.buttonPressed & D_JPAD) ~= 0 then
            ui.baitBuyIndex = ui.baitBuyIndex - 1
            if ui.baitBuyIndex < 1 then ui.baitBuyIndex = #BAIT_AMOUNTS end
        end
        if (ctrl.buttonPressed & L_JPAD) ~= 0 then
            ui.baitTypeIndex = ui.baitTypeIndex - 1
            if ui.baitTypeIndex < 1 then ui.baitTypeIndex = #BAIT_TYPES end
        end
        if (ctrl.buttonPressed & R_JPAD) ~= 0 then
            ui.baitTypeIndex = ui.baitTypeIndex + 1
            if ui.baitTypeIndex > #BAIT_TYPES then ui.baitTypeIndex = 1 end
        end
        if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            local bt = BAIT_TYPES[ui.baitTypeIndex]
            equip_bait(pst, bt.id, false)
            ui.shopCooldown = 12
        end
    end

    if baitPrompt and ui.shopCooldown == 0 and (ctrl.buttonPressed & B_BUTTON) ~= 0 then
        local bt = BAIT_TYPES[ui.baitTypeIndex] or BAIT_TYPES[1]
        local qty = BAIT_AMOUNTS[ui.baitBuyIndex] or 1
        local owned = total_bait(pst)
        local room = get_max_bait() - owned
        local wallet = get_wallet()
        if not is_bait_unlocked(bt, pst) then
            djui_chat_message_create(bt.name .. " unlocks after you reach the Gold rod.")
            ui.shopCooldown = 18
        elseif room <= 0 then
            djui_chat_message_create("Bait pouch is full!")
            ui.shopCooldown = 18
        else
            if qty > room then qty = room end
            local cost = qty * bt.cost
            if wallet < cost then
                local canAfford = math.floor(wallet / bt.cost)
                if canAfford <= 0 then
                    djui_chat_message_create(string.format(
                        "Need $%d for %s. You have $%d / $%d.",
                        cost, bt.name, wallet, get_max_coins()
                    ))
                    ui.shopCooldown = 18
                else
                    if canAfford > room then canAfford = room end
                    local paid = canAfford * bt.cost
                    spend_wallet(paid)
                    set_bait_count(pst, bt.id, get_bait_count(pst, bt.id) + canAfford)
                    if pst.activeBait == nil or get_bait_count(pst, pst.activeBait) <= 0 then
                        pst.activeBait = bt.id
                    end
                    ui.shopCooldown = 18
                    sfx(SOUND_GENERAL_COIN, m)
                    djui_chat_message_create(string.format(
                        "Bought %dx %s (-$%d). Stock: %d  Balance: $%d / $%d",
                        canAfford, bt.name, paid, get_bait_count(pst, bt.id), get_wallet(), get_max_coins()
                    ))
                end
            else
                spend_wallet(cost)
                set_bait_count(pst, bt.id, get_bait_count(pst, bt.id) + qty)
                if get_bait_count(pst, pst.activeBait or 0) <= 0 then
                    pst.activeBait = bt.id
                end
                ui.shopCooldown = 18
                sfx(SOUND_GENERAL_COIN, m)
                djui_chat_message_create(string.format(
                    "Bought %dx %s (-$%d). Stock: %d  Balance: $%d / $%d",
                    qty, bt.name, cost, get_bait_count(pst, bt.id), get_wallet(), get_max_coins()
                ))
            end
        end
    end

    if sellPrompt and ui.shopCooldown == 0 then
        if (ctrl.buttonPressed & B_BUTTON) ~= 0 then
            if #ui.inventory > 0 then
                local earned, count = sell_all_fish(m)
                ui.shopCooldown = 25
                if earned > 0 then
                    djui_chat_message_create(string.format("Sold %d fish for $%d! Balance: $%d / $%d", count, earned, get_wallet(), get_max_coins()))
                    sfx(SOUND_GENERAL_COIN, m)
                end
            else
                djui_chat_message_create("Nothing to sell. Go catch some fish!")
                ui.shopCooldown = 20
            end
        elseif (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            if try_upgrade_rod(m) then
                ui.shopCooldown = 25
            else
                ui.shopCooldown = 18
            end
        end
    end

    pst.castPrompt = (pst.fishState == STATE.IDLE) and is_near_water(m) and is_standing_to_fish(m) and not ui.shopPrompt and not cook.prompt

    cancel_if_needed(m, pst, ctrl)

    -- Hold L to aim (outline). Release L after a short hold to cast. No instant press-cast.
    local holdingL = (ctrl.buttonDown & L_TRIG) ~= 0
    local doCast = false

    if pst.castPrompt then
        if holdingL then
            vis.aimHoldFrames = vis.aimHoldFrames + 1
            vis.wasHoldingL = true
            update_cast_aim_preview(m, true)
        else
            if vis.wasHoldingL and vis.aimHoldFrames >= AIM_MIN_HOLD then
                doCast = true
            end
            vis.wasHoldingL = false
            vis.aimHoldFrames = 0
            update_cast_aim_preview(m, false)
        end
    else
        vis.wasHoldingL = false
        vis.aimHoldFrames = 0
        update_cast_aim_preview(m, false)
    end

    if doCast then
        local usedBait = consume_active_bait(pst)
        if not usedBait then
            -- No bait: still allow casting, but only low-tier fish can bite.
            vis.castBaitId = 0
            pst.fishState = STATE.CASTING
            pst.fishTimer = 40
            pst.miniProgress = 0
            pst.caughtId = 0
            ui.lockedPos = {x = m.pos.x, z = m.pos.z}
            destroy_aim_marker()
            spawn_rod_and_bobber(m)
            sfx(SOUND_ACTION_SPIN, m)
            djui_chat_message_create("Cast with no bait! Only common fish will bite.")
        else
            local bt = get_bait_type(pst.activeBait or 1)
            pst.fishState = STATE.CASTING
            pst.fishTimer = 40
            pst.miniProgress = 0
            pst.caughtId = 0
            ui.lockedPos = {x = m.pos.x, z = m.pos.z}
            destroy_aim_marker()
            spawn_rod_and_bobber(m)
            sfx(SOUND_ACTION_SPIN, m)
            djui_chat_message_create(string.format("Cast with %s! Bait left: %d", bt.name, total_bait(pst)))
        end
    end

    if pst.fishState == STATE.CASTING then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)
        pst.fishTimer = pst.fishTimer - 1
        if pst.fishTimer <= 0 then
            pst.fishState = STATE.WAITING
            local waitMul = 1.35
            if vis.castBaitId ~= nil and vis.castBaitId > 0 then
                local bt = get_bait_type(vis.castBaitId)
                waitMul = bt.waitMul or 1
            end
            local wait = math.random(70, 200) * waitMul
            pst.fishTimer = math.floor(wait)
            spawn_fish_near_bobber(m)
        end
    elseif pst.fishState == STATE.WAITING then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)
        pst.fishTimer = pst.fishTimer - 1
        if pst.fishTimer <= 0 then
            pst.fishState = STATE.BITE
            pst.biteTimer = 70
            ui.biteFlash = 22
            sfx(SOUND_GENERAL_PAINTING_EJECT, m)
        end
    elseif pst.fishState == STATE.BITE then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)
        pst.biteTimer = pst.biteTimer - 1
        if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            pst.fishState = STATE.MINIGAME
            local reactionBonus = 18
            if pst.biteTimer > 45 then
                reactionBonus = 34
            elseif pst.biteTimer > 25 then
                reactionBonus = 26
            end
            pst.miniProgress = reactionBonus
            local fishData = roll_fish()
            local record = make_fish_record(fishData)
            if pst.hardMode then
                record.value = math.floor((record.value or 0) * HARD_MODE_SELL_MULT)
            end
            pst.caughtId = record.id
            ui.lastCaught = record
            ui.currentDifficulty = get_fishing_challenge_level(pst, fishData.difficulty or 1)
            ui.reelPulse = 12
            sfx(SOUND_ACTION_SWIM, m)
            if record.isMystery then
                banners.mysteryHookTimer = 200
                djui_chat_message_create("!!! Something ancient takes the line — the Hollowfin !!!")
                sfx(SOUND_MENU_STAR_SOUND, m)
            end
        elseif pst.biteTimer <= 0 then
            clear_cast_bait()
            reset_fishing_state(pst)
            ui.catchStreak = 0
            djui_chat_message_create("The fish got away...")
        end
    elseif pst.fishState == STATE.MINIGAME then
        lock_mario_while_fishing(m)
        update_fishing_objects(m)

        if ui.currentDifficulty == 1 then
            if (ctrl.buttonDown & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 2.1
                ui.reelPulse = 6
            else
                pst.miniProgress = pst.miniProgress - 0.85
            end
        elseif ui.currentDifficulty == 2 then
            if (ctrl.buttonDown & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 1.35
                ui.reelPulse = 6
            else
                pst.miniProgress = pst.miniProgress - 1.45
            end
        elseif ui.currentDifficulty >= 5 then
            -- Maximum challenge: short presses only, fast drain, tiny gains.
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 6.2
                ui.reelPulse = 12
            end
            pst.miniProgress = pst.miniProgress - 1.15
        elseif ui.currentDifficulty == 4 then
            -- Prestige/hard-mode challenge above the normal HARD fish.
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 7.5
                ui.reelPulse = 10
            end
            pst.miniProgress = pst.miniProgress - 0.95
        else
            if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
                pst.miniProgress = pst.miniProgress + 9.5
                ui.reelPulse = 10
            end
            pst.miniProgress = pst.miniProgress - 0.75
        end

        if pst.miniProgress >= 100 then
            pst.fishState = STATE.CATCH
            clear_cast_bait()
            pst.fishTimer = 0
            if not add_to_inventory(ui.lastCaught) then
                djui_chat_message_create("Inventory full! Sell fish at a market.")
                ui.catchStreak = 0
            else
                ui.catchStreak = ui.catchStreak + 1
                local streakTxt = ""
                if ui.catchStreak >= 3 then
                    streakTxt = string.format("  Streak x%d!", ui.catchStreak)
                end
                local rareTxt = ""
                if (ui.lastCaught.value or 0) >= 50 then
                    rareTxt = "  RARE!"
                end
                local voidWarn = ""
                if ui.lastCaught.isVoid then
                    voidWarn = "  SELL SOON or it decays!"
                end
                djui_chat_message_create(string.format(
                    "Caught %s!  %.1f cm  %.1f kg  (+$%d)%s%s%s",
                    ui.lastCaught.name or "Fish",
                    ui.lastCaught.size or 0,
                    ui.lastCaught.weight or 0,
                    ui.lastCaught.value or 0,
                    rareTxt,
                    streakTxt,
                    voidWarn
                ))
            end
            check_personal_record(ui.lastCaught)
            if ui.lastCaught.isMystery then
                broadcast_mystery_catch(get_player_name(), ui.lastCaught)
            end
            ui.catchDisplayTimer = 0
            ui.lockedPos = nil
            destroy_fishing_objects()
            sfx(SOUND_GENERAL_COIN, m)
        elseif pst.miniProgress <= 0 then
            clear_cast_bait()
            reset_fishing_state(pst)
            ui.catchStreak = 0
            sfx(SOUND_OBJ_BOO_LAUGH_LONG, m)
            djui_chat_message_create("It snapped the line!")
        end
    elseif pst.fishState == STATE.CATCH then
        if (ctrl.buttonPressed & A_BUTTON) ~= 0 then
            pst.fishState = STATE.IDLE
            pst.caughtId = 0
            pst.fishTimer = 0
            ui.lockedPos = nil
            ui.catchDisplayTimer = 0
        end
    else
        if vis.rodObj ~= nil or vis.bobberObj ~= nil or vis.fishObj ~= nil or vis.rodTipObj ~= nil then
            destroy_fishing_objects()
        end
        ui.lockedPos = nil
    end

    if pst.fishState ~= STATE.IDLE then
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

function draw_text_centered(text, y, scale, r, g, b, a)
    local sw = djui_hud_get_screen_width()
    local w = djui_hud_measure_text(text) * scale
    djui_hud_set_color(r, g, b, a)
    djui_hud_print_text(text, (sw - w) * 0.5, y, scale)
end


function game_is_paused()
    if is_game_paused ~= nil then
        return is_game_paused()
    end
    if djui_is_pause_menu_showing ~= nil then
        return djui_is_pause_menu_showing()
    end
    return false
end

function count_bits_u32(flags)
    local n = 0
    local v = flags or 0
    while v > 0 do
        if (v % 2) == 1 then n = n + 1 end
        v = math.floor(v / 2)
    end
    return n
end

function get_pause_star_info()
    local course = 0
    local np = gNetworkPlayers[0]
    if np ~= nil and np.currCourseNum ~= nil then
        course = np.currCourseNum
    elseif get_current_course_num ~= nil then
        course = get_current_course_num()
    end

    local fileIndex = 0
    if get_current_save_file_num ~= nil then
        fileIndex = get_current_save_file_num() - 1
        if fileIndex < 0 then fileIndex = 0 end
    end

    local courseStars = 0
    local courseMax = 7
    if course ~= nil and course > 0 then
        if save_file_get_course_star_count ~= nil then
            courseStars = save_file_get_course_star_count(fileIndex, course - 1) or 0
        elseif save_file_get_star_flags ~= nil then
            local flags = save_file_get_star_flags(fileIndex, course - 1) or 0
            courseStars = count_bits_u32(flags)
            if courseStars > courseMax then courseStars = courseMax end
        end
    end

    local totalStars = 0
    local m = gMarioStates[0]
    if m ~= nil and m.numStars ~= nil then
        totalStars = m.numStars
    elseif hud_get_value ~= nil and HUD_DISPLAY_STARS ~= nil then
        totalStars = hud_get_value(HUD_DISPLAY_STARS) or 0
    elseif save_file_get_total_star_count ~= nil then
        totalStars = save_file_get_total_star_count(fileIndex, 0, 24) or 0
    end

    local levelName = LEVEL_NAMES[get_current_level()] or "Current Level"
    return levelName, course, courseStars, courseMax, totalStars
end

function draw_fishing_dx_pause_menu()
    if not game_is_paused() then return end

    djui_hud_set_resolution(RESOLUTION_DJUI)
    local sw = djui_hud_get_screen_width()
    local sh = djui_hud_get_screen_height()

    djui_hud_set_color(5, 12, 20, 185)
    djui_hud_render_rect(0, 0, sw, sh)

    -- Keep Fishing DX in a compact top-center panel so the normal SM64 pause
    -- menu remains visible underneath it.
    local pw = math.min(760, sw - 20)
    local ph = math.min(300, sh - 20)
    local px = (sw - pw) * 0.5
    local py = 10

    djui_hud_set_color(0, 0, 0, 100)
    djui_hud_render_rect(px + 8, py + 9, pw, ph)
    djui_hud_set_color(12, 31, 43, 220)
    djui_hud_render_rect(px, py, pw, ph)

    djui_hud_set_color(42, 177, 198, 255)
    djui_hud_render_rect(px, py, pw, 6)
    djui_hud_render_rect(px, py + ph - 6, pw, 6)
    djui_hud_render_rect(px, py, 6, ph)
    djui_hud_render_rect(px + pw - 6, py, 6, ph)

    djui_hud_set_font(FONT_MENU)
    local title = "FISHING DX"
    local ts = 1.15
    local tw = djui_hud_measure_text(title) * ts
    djui_hud_set_color(128, 232, 255, 255)
    djui_hud_print_text(title, px + (pw - tw) * 0.5, py + 20, ts)

    djui_hud_set_font(FONT_NORMAL)
    local sub = "ANGLERS  |  v1.1"
    local ss = 0.42
    local swt = djui_hud_measure_text(sub) * ss
    djui_hud_set_color(151, 215, 206, 235)
    djui_hud_print_text(sub, px + (pw - swt) * 0.5, py + 58, ss)

    local levelName, course, courseStars, courseMax, totalStars = get_pause_star_info()
    djui_hud_set_color(25, 91, 108, 255)
    djui_hud_render_rect(px + 20, py + 88, pw - 40, 2)

    djui_hud_set_color(255, 230, 120, 255)
    djui_hud_print_text("LEVEL", px + 28, py + 100, 0.40)
    djui_hud_set_color(230, 245, 250, 255)
    djui_hud_print_text(tostring(levelName), px + 100, py + 100, 0.40)

    local starLine
    if course ~= nil and course > 0 then
        starLine = string.format("Course Stars:  %d / %d", courseStars, courseMax)
    else
        starLine = "Course Stars:  --"
    end
    djui_hud_set_color(255, 220, 90, 255)
    djui_hud_print_text(starLine, px + 28, py + 128, 0.44)
    djui_hud_set_color(200, 230, 240, 255)
    djui_hud_print_text(string.format("Total Stars:  %d", totalStars), px + 28, py + 156, 0.44)

    djui_hud_set_color(25, 91, 108, 255)
    djui_hud_render_rect(px + 20, py + 188, pw - 40, 2)

    djui_hud_set_color(65, 197, 191, 255)
    djui_hud_print_text("PLAYERS IN SESSION", px + 28, py + 202, 0.42)

    local y = py + 232
    local row = 0
    local maxPlayers = 16
    if MAX_PLAYERS ~= nil then maxPlayers = MAX_PLAYERS end
    local rowH = 30

    for i = 0, maxPlayers - 1 do
        local np = gNetworkPlayers[i]
        if np ~= nil and np.connected then
            local name = np.name
            if name == nil or name == "" then name = "Player " .. tostring(i) end

            if row % 2 == 0 then
                djui_hud_set_color(20, 56, 70, 175)
            else
                djui_hud_set_color(16, 46, 59, 135)
            end
            djui_hud_render_rect(px + 24, y - 3, pw - 48, rowH)

            djui_hud_set_color(48, 177, 198, 255)
            djui_hud_render_rect(px + 24, y - 3, 5, rowH)

            if i == 0 then
                djui_hud_set_color(255, 219, 116, 255)
            else
                djui_hud_set_color(224, 239, 242, 245)
            end
            local label = name .. (i == 0 and "  (you)" or "")
            djui_hud_print_text(label, px + 40, y + 4, 0.42)

            row = row + 1
            y = y + rowH
            if y > py + ph - 56 then break end
        end
    end

    if row == 0 then
        djui_hud_set_color(155, 180, 188, 210)
        djui_hud_print_text("No players connected", px + 40, y + 4, 0.40)
    end

    djui_hud_set_color(78, 132, 146, 220)
    djui_hud_render_rect(px + 24, py + ph - 48, pw - 48, 2)
    djui_hud_set_color(135, 177, 185, 220)
    djui_hud_print_text("PAUSED  |  Resume with B", px + 28, py + ph - 34, 0.36)
end

function draw_hard_mode()
    if not ui.showHardMode then return end

    djui_hud_set_resolution(RESOLUTION_DJUI)
    local sw = djui_hud_get_screen_width()
    local sh = djui_hud_get_screen_height()

    local pw = math.min(650, sw - 28)
    local ph = math.min(300, sh - 24)
    local px = (sw - pw) * 0.5
    local py = (sh - ph) * 0.5

    -- Match the Fishing Guide signpost presentation so B opens a proper panel
    -- and A is the action button for the toggle.
    djui_hud_set_color(0, 0, 0, 160)
    djui_hud_render_rect(0, 0, sw, sh)
    djui_hud_set_color(40, 18, 24, 255)
    djui_hud_render_rect(px, py, pw, ph)

    djui_hud_set_color(220, 70, 70, 255)
    djui_hud_render_rect(px, py, pw, 6)
    djui_hud_render_rect(px, py + ph - 6, pw, 6)
    djui_hud_render_rect(px, py, 6, ph)
    djui_hud_render_rect(px + pw - 6, py, 6, ph)
    djui_hud_set_color(100, 42, 48, 255)
    djui_hud_render_rect(px + 18, py + 70, pw - 36, 2)

    djui_hud_set_font(FONT_MENU)
    local title = "HARD MODE"
    local titleScale = 0.70
    local titleW = djui_hud_measure_text(title) * titleScale
    djui_hud_set_color(255, 105, 105, 255)
    djui_hud_print_text(title, px + (pw - titleW) * 0.5, py + 16, titleScale)
    djui_hud_set_font(FONT_NORMAL)

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Harder fish fights", px + 42, py + 100, 0.45)
    djui_hud_print_text("Fish sell for 2x their normal value", px + 42, py + 132, 0.45)

    if gPlayerSyncTable[0] ~= nil and gPlayerSyncTable[0].hardMode then
        djui_hud_set_color(120, 255, 140, 255)
        djui_hud_print_text("STATUS: ENABLED", px + 42, py + 174, 0.48)
    else
        djui_hud_set_color(220, 220, 220, 255)
        djui_hud_print_text("STATUS: DISABLED", px + 42, py + 174, 0.48)
    end

    djui_hud_set_color(210, 230, 235, 255)
    djui_hud_print_text("A: Toggle Hard Mode", px + 42, py + ph - 58, 0.40)
    djui_hud_set_color(160, 180, 185, 255)
    djui_hud_print_text("B: Close", px + pw - 130, py + ph - 58, 0.40)
end

function draw_fishing_tutorial()
    if not ui.showTutorial then return end

    djui_hud_set_resolution(RESOLUTION_DJUI)
    local sw = djui_hud_get_screen_width()
    local sh = djui_hud_get_screen_height()

    -- Centered panel for readability
    local pw = math.min(720, sw - 32)
    local ph = math.min(520, sh - 28)
    local px = (sw - pw) * 0.5
    local py = (sh - ph) * 0.5

    djui_hud_set_color(0, 0, 0, 180)
    djui_hud_render_rect(0, 0, sw, sh)

    -- Dark panel + high-contrast white text
    djui_hud_set_color(8, 18, 28, 255)
    djui_hud_render_rect(px, py, pw, ph)

    djui_hud_set_color(70, 210, 230, 255)
    djui_hud_render_rect(px, py, pw, 5)
    djui_hud_render_rect(px, py + ph - 5, pw, 5)
    djui_hud_render_rect(px, py, 5, ph)
    djui_hud_render_rect(px + pw - 5, py, 5, ph)

    djui_hud_set_color(30, 90, 110, 255)
    djui_hud_render_rect(px + 16, py + 58, pw - 32, 2)

    djui_hud_set_font(FONT_MENU)
    local title = "FISHING DX GUIDE"
    local titleScale = 0.78
    local titleW = djui_hud_measure_text(title) * titleScale
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text(title, px + (pw - titleW) * 0.5, py + 14, titleScale)
    djui_hud_set_font(FONT_NORMAL)

    djui_hud_set_color(230, 245, 255, 255)
    djui_hud_print_text("How to fish, bait, shops, and tips.", px + 28, py + 40, 0.40)

    local leftX = px + 28
    local rightX = px + pw * 0.52
    local y = py + 72

    -- HOW TO FISH
    djui_hud_set_color(90, 230, 220, 255)
    djui_hud_print_text("HOW TO FISH", leftX, y, 0.50)
    y = y + 26
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("1. Bait is optional. Equip bait for better fish.", leftX + 6, y, 0.42)
    y = y + 22
    djui_hud_print_text("2. Near water, hold L to aim, release to cast.", leftX + 6, y, 0.42)
    y = y + 22
    djui_hud_print_text("3. Wait for a bite, then press A and reel.", leftX + 6, y, 0.42)
    y = y + 22
    djui_hud_print_text("4. Press B to cancel a cast (bait is returned).", leftX + 6, y, 0.42)
    y = y + 22
    djui_hud_set_color(255, 240, 180, 255)
    djui_hud_print_text("No bait = only common / low-tier fish.", leftX + 6, y, 0.40)

    -- BAIT
    y = y + 32
    djui_hud_set_color(90, 230, 220, 255)
    djui_hud_print_text("BAIT", leftX, y, 0.50)
    y = y + 26
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Worm - $5  |  Steady bites", leftX + 6, y, 0.40)
    y = y + 20
    djui_hud_print_text("Cricket - $12  |  Faster, better luck", leftX + 6, y, 0.40)
    y = y + 20
    djui_hud_print_text("Super Mushroom - $18  |  More rares", leftX + 6, y, 0.40)
    y = y + 20
    djui_hud_print_text("Golden Lure - $30  |  Strong rare bonus", leftX + 6, y, 0.40)
    y = y + 20
    djui_hud_print_text("Barbed Hook - $45  |  Gold rod+, hard reels", leftX + 6, y, 0.40)

    -- SHOPS (right column) - full location list
    local ry = py + 72
    djui_hud_set_color(90, 230, 220, 255)
    djui_hud_print_text("WHERE TO FIND SHOPS", rightX, ry, 0.50)
    ry = ry + 26
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Castle Grounds", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Bait Shop and Fish Market", rightX + 4, ry, 0.36)
    ry = ry + 22
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Jolly Roger Bay", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Fish Market", rightX + 4, ry, 0.36)
    ry = ry + 22
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Dire Dire Docks", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Bait Shops", rightX + 4, ry, 0.36)
    ry = ry + 22
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Bob-omb Battlefield", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Bait Shop and Fish Market", rightX + 4, ry, 0.36)
    ry = ry + 22
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Lethal Lava Land", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Fish Market", rightX + 4, ry, 0.36)
    ry = ry + 22
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Castle Courtyard", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Bait Shop", rightX + 4, ry, 0.36)
    ry = ry + 22
    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_print_text("Castle Upper (TTM painting)", rightX + 4, ry, 0.42)
    ry = ry + 18
    djui_hud_set_color(210, 230, 240, 255)
    djui_hud_print_text("  Fish Market", rightX + 4, ry, 0.36)

    djui_hud_set_color(180, 210, 220, 255)
    djui_hud_print_text("B: Close Guide", px + 28, py + ph - 28, 0.42)
end

function draw_cook_menu()
    if not cook.menuOpen then return end
    djui_hud_set_resolution(RESOLUTION_DJUI)
    local sw = djui_hud_get_screen_width()
    local sh = djui_hud_get_screen_height()
    local pw = math.min(760, sw - 24)
    local ph = math.min(500, sh - 24)
    local px = (sw - pw) * 0.5
    local py = (sh - ph) * 0.5

    djui_hud_set_color(0, 0, 0, 190)
    djui_hud_render_rect(0, 0, sw, sh)
    djui_hud_set_color(32, 18, 10, 255)
    djui_hud_render_rect(px, py, pw, ph)
    djui_hud_set_color(255, 150, 55, 255)
    djui_hud_render_rect(px, py, pw, 6)
    djui_hud_render_rect(px, py + ph - 6, pw, 6)
    djui_hud_render_rect(px, py, 6, ph)
    djui_hud_render_rect(px + pw - 6, py, 6, ph)

    djui_hud_set_font(FONT_MENU)
    local title = "FIREPLACE COOKING"
    local ts = 0.82
    local tw = djui_hud_measure_text(title) * ts
    djui_hud_set_color(255, 220, 130, 255)
    djui_hud_print_text(title, px + (pw - tw) * 0.5, py + 18, ts)
    djui_hud_set_font(FONT_NORMAL)
    djui_hud_set_color(220, 190, 150, 230)
    djui_hud_print_text("Choose a fish. Each fish creates a different meal.", px + 34, py + 58, 0.42)
    djui_hud_set_color(180, 220, 190, 220)
    djui_hud_print_text("Meals: Speed / Power / Lucky / Hot / Void / Mystic", px + 34, py + 78, 0.34)

    local visible = math.min(8, #ui.inventory)
    local first = math.max(1, cook.selectedIndex - 3)
    if first + visible - 1 > #ui.inventory then first = math.max(1, #ui.inventory - visible + 1) end
    local rowY = py + 94
    for i = first, first + visible - 1 do
        local rec = ui.inventory[i]
        local recipe = get_cook_recipe(rec)
        if i == cook.selectedIndex then
            djui_hud_set_color(100, 58, 25, 240)
            djui_hud_render_rect(px + 24, rowY - 5, pw - 48, 42)
            djui_hud_set_color(255, 220, 120, 255)
            djui_hud_print_text("> " .. (rec.name or "Fish"), px + 38, rowY + 2, 0.48)
        else
            djui_hud_set_color(235, 230, 220, 235)
            djui_hud_print_text("  " .. (rec.name or "Fish"), px + 38, rowY + 2, 0.48)
        end
        djui_hud_set_color(190, 165, 145, 220)
        djui_hud_print_text(string.format("%s - %ds", recipe.name, recipe.seconds), px + pw * 0.48, rowY + 3, 0.40)
        rowY = rowY + 45
    end

    local rec = ui.inventory[cook.selectedIndex]
    if rec ~= nil then
        local recipe = get_cook_recipe(rec)
        local infoY = py + ph - 108
        djui_hud_set_color(255, 190, 90, 255)
        djui_hud_print_text("MEAL: " .. recipe.name, px + 34, infoY, 0.46)
        djui_hud_set_color(235, 225, 215, 240)
        djui_hud_print_text(recipe.desc, px + 34, infoY + 26, 0.40)
        if recipe.rare > 0 then
            djui_hud_print_text("Rare spawn bonus: +" .. tostring(recipe.rare) .. "% weight for " .. tostring(recipe.seconds) .. "s", px + 34, infoY + 50, 0.38)
        end
    end
    djui_hud_set_color(190, 175, 165, 230)
    djui_hud_print_text("Up/Down: Choose Fish   A: Cook   B: Close", px + 34, py + ph - 30, 0.40)
end


function draw_hollowfin_on_line()
    if not is_hollowfin_active() then return end
    local tex = load_hollowfin_texture()
    if tex == nil then return end
    if djui_hud_render_texture == nil then return end

    local pst = ensure_sync()
    if pst.fishState ~= STATE.MINIGAME and pst.fishState ~= STATE.CATCH and pst.fishState ~= STATE.BITE then
        return
    end

    local m = gMarioStates[0]
    if m == nil then return end

    local x, y, z
    if obj_is_alive(vis.fishObj) then
        x = vis.fishObj.oPosX
        y = vis.fishObj.oPosY
        z = vis.fishObj.oPosZ
    elseif obj_is_alive(vis.bobberObj) then
        x = vis.bobberObj.oPosX
        y = vis.bobberObj.oPosY - 20
        z = vis.bobberObj.oPosZ
    else
        local yaw = m.faceAngle.y
        local waterY = get_fishing_water_y(m) or (m.pos.y - 80)
        x = m.pos.x + sins(yaw) * 235
        y = waterY - 12
        z = m.pos.z + coss(yaw) * 235
    end

    djui_hud_set_resolution(RESOLUTION_DJUI)
    local sx, sy = nil, nil
    if djui_hud_world_pos_to_screen_pos ~= nil then
        local out = { x = 0, y = 0, z = 0 }
        local ok = djui_hud_world_pos_to_screen_pos({ x = x, y = y, z = z }, out)
        if ok and out.z ~= nil and out.z > -0.01 then
            -- behind camera
            return
        end
        if ok then
            sx = out.x
            sy = out.y
        end
    end

    -- Fallback: approximate on-screen position near bobber HUD area
    if sx == nil or sy == nil then
        local sw = djui_hud_get_screen_width()
        local sh = djui_hud_get_screen_height()
        sx = sw * 0.55
        sy = sh * 0.58
    end

    local pulse = 1.0 + 0.08 * math.sin(get_global_timer() / 6)
    local scale = 3.2 * pulse
    local tw = 32 * scale
    local th = 32 * scale

    djui_hud_set_color(255, 255, 255, 255)
    djui_hud_render_texture(tex, sx - tw * 0.5, sy - th * 0.5, scale, scale)
end

function on_hud_render()
    -- Custom Hollowfin sprite on the line during mystery fights
    draw_hollowfin_on_line()

    -- Custom pause overlay (Fishing DX branding + angler list)
    draw_fishing_dx_pause_menu()
    draw_hard_mode()
    draw_fishing_tutorial()
    draw_cook_menu()

    -- Castle Grounds travel boat prompt / destination selector.
    if get_current_level() == LEVEL_CASTLE_GROUNDS and travel_boat_is_valid(boats.travel) then
        local m = gMarioStates[0]
        if m ~= nil and not boats.menuOpen then
            local dx = m.pos.x - boats.travel.oPosX
            local dy = m.pos.y - boats.travel.oPosY
            local dz = m.pos.z - boats.travel.oPosZ
            if (dx * dx + dy * dy + dz * dz) <= (900 * 900) then
                djui_hud_set_resolution(RESOLUTION_DJUI)
                djui_hud_set_font(FONT_MENU)
                djui_hud_set_color(255, 255, 255, 255)
                djui_hud_print_text("A: Board Boat - Stage Select", 22, 180, 0.5)
            end
        end
    end

    if boats.menuOpen then
        local sw = djui_hud_get_screen_width()
        local sh = djui_hud_get_screen_height()
        djui_hud_set_color(0, 0, 0, 225)
        djui_hud_render_rect(sw * 0.15, sh * 0.10, sw * 0.70, sh * 0.80)
        djui_hud_set_color(255, 220, 120, 255)
        djui_hud_print_text("CASTLE GROUNDS BOAT - STAGE SELECT", sw * 0.22, sh * 0.14, 0.62)
        djui_hud_set_color(190, 210, 230, 255)
        djui_hud_print_text("Choose a fishing destination", sw * 0.22, sh * 0.20, 0.38)

        -- Scrolling list: keeps the current choice visible on all resolutions.
        local visibleCount = math.max(5, math.floor((sh * 0.57) / 25))
        if visibleCount > #TRAVEL_DESTINATIONS then visibleCount = #TRAVEL_DESTINATIONS end
        local first = math.max(1, boats.index - math.floor(visibleCount / 2))
        if first + visibleCount - 1 > #TRAVEL_DESTINATIONS then
            first = math.max(1, #TRAVEL_DESTINATIONS - visibleCount + 1)
        end
        for row = 1, visibleCount do
            local i = first + row - 1
            if i > #TRAVEL_DESTINATIONS then break end
            local y = sh * 0.27 + (row - 1) * 25
            if i == boats.index then
                djui_hud_set_color(255, 230, 80, 255)
                djui_hud_print_text("> " .. TRAVEL_DESTINATIONS[i].name, sw * 0.22, y, 0.48)
            else
                djui_hud_set_color(255, 255, 255, 225)
                djui_hud_print_text("  " .. TRAVEL_DESTINATIONS[i].name, sw * 0.22, y, 0.48)
            end
        end
        djui_hud_set_color(200, 200, 200, 255)
        djui_hud_print_text("Up/Down: Select   A: Travel   B: Cancel", sw * 0.22, sh * 0.84, 0.38)
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

    if ui.prBannerTimer > 0 then
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
        draw_text_centered(string.format("%s caught a %s", ui.prBannerData.player, ui.prBannerData.name), by + 36, 0.4, 255, 255, 255, 255)
        draw_text_centered(string.format("%.1f cm   |   %.1f kg", ui.prBannerData.size, ui.prBannerData.weight), by + 60, 0.38, 160, 220, 255, 255)
    end

    if banners.mysteryTimer > 0 then
        local bw = 520
        local bh = 100
        local bx = (sw - bw) * 0.5
        local by = (ui.prBannerTimer > 0) and 110 or 8

        djui_hud_set_color(0, 0, 0, 140)
        djui_hud_render_rect(bx + 4, by + 4, bw, bh)
        djui_hud_set_color(20, 8, 35, 250)
        djui_hud_render_rect(bx, by, bw, bh)
        djui_hud_set_color(180, 80, 255, 255)
        djui_hud_render_rect(bx, by, bw, 5)
        djui_hud_render_rect(bx, by + bh - 5, bw, 5)

        draw_text_centered("MYSTERY CATCH!", by + 12, 0.48, 220, 140, 255, 255)
        draw_text_centered(string.format("%s landed the Hollowfin", banners.mysteryData.player), by + 42, 0.42, 255, 255, 255, 255)
        draw_text_centered(string.format("%.1f cm   |   %.1f kg", banners.mysteryData.size, banners.mysteryData.weight), by + 68, 0.38, 200, 180, 255, 255)
    end

    if banners.mysteryHookTimer > 0 then
        local pulse = 200 + math.floor((banners.mysteryHookTimer % 20) * 2)
        if pulse > 255 then pulse = 255 end
        draw_text_centered("THE HOLLOWFIN HAS TAKEN THE BAIT", sh * 0.28, 0.55, 220, 120, 255, pulse)
        draw_text_centered("This will not be easy", sh * 0.34, 0.38, 180, 160, 220, pulse)
    end

    if banners.hotTimer > 0 and banners.hotText ~= "" then
        local y = (ui.prBannerTimer > 0) and 108 or 110
        local bw = 520
        local bh = 40
        local bx = (sw - bw) * 0.5
        djui_hud_set_color(40, 10, 50, 230)
        djui_hud_render_rect(bx, y, bw, bh)
        djui_hud_set_color(220, 120, 255, 255)
        djui_hud_render_rect(bx, y, bw, 3)
        draw_text_centered(banners.hotText, y + 10, 0.36, 255, 200, 255, 255)
    end

    init_session_sync_fields()
    if (gGlobalSyncTable.fdxHotLevel or 0) ~= 0 and banners.hotTimer <= 0 then
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
        if vis.aimActive then
            draw_text_centered("Release L to cast", sh * 0.72, 0.45, 255, 255, 140, 230)
        else
            draw_text_centered("Hold L to aim, release to cast", sh * 0.72, 0.48, 255, 255, 120, 230)
        end
        draw_text_centered("Press B to cancel while fishing", sh * 0.78, 0.35, 180, 180, 180, 180)
    end

    if ui.showFishMap then
        local lines = get_fish_map_lines()
        local pages = math.max(1, math.ceil(#lines / FISH_MAP_PAGE_SIZE))
        if ui.fishMapPage > pages then ui.fishMapPage = pages end
        if ui.fishMapPage < 1 then ui.fishMapPage = 1 end
        local startI = (ui.fishMapPage - 1) * FISH_MAP_PAGE_SIZE + 1
        local endI = math.min(#lines, startI + FISH_MAP_PAGE_SIZE - 1)

        local boxW = math.min(760, sw - 20)
        local boxH = math.min(500, sh - 16)
        local boxX = (sw - boxW) * 0.5
        local boxY = (sh - boxH) * 0.5

        djui_hud_set_color(0, 0, 0, 190)
        djui_hud_render_rect(0, 0, sw, sh)

        djui_hud_set_color(8, 14, 26, 255)
        djui_hud_render_rect(boxX, boxY, boxW, boxH)

        djui_hud_set_color(70, 170, 255, 255)
        djui_hud_render_rect(boxX, boxY, boxW, 5)
        djui_hud_render_rect(boxX, boxY + boxH - 5, boxW, 5)
        djui_hud_render_rect(boxX, boxY, 5, boxH)
        djui_hud_render_rect(boxX + boxW - 5, boxY, 5, boxH)

        djui_hud_set_color(16, 36, 64, 255)
        djui_hud_render_rect(boxX + 5, boxY + 5, boxW - 10, 48)

        djui_hud_set_font(FONT_MENU)
        djui_hud_set_color(255, 255, 255, 255)
        djui_hud_print_text("FISHING MAP", boxX + 18, boxY + 12, 0.62)
        djui_hud_set_font(FONT_NORMAL)
        djui_hud_set_color(180, 210, 255, 255)
        djui_hud_print_text(
            string.format("Page %d / %d   |   Stages, spawns, values, difficulty", ui.fishMapPage, pages),
            boxX + 18, boxY + 36, 0.34
        )

        local y = boxY + 62
        for i = startI, endI do
            local row = lines[i]
            if row ~= nil then
                if row.title then
                    djui_hud_set_color(28, 56, 92, 255)
                    djui_hud_render_rect(boxX + 12, y - 2, boxW - 24, 24)
                    djui_hud_set_color(255, 220, 100, 255)
                    djui_hud_print_text(row.text, boxX + 20, y + 2, 0.42)
                    y = y + 28
                elseif row.note then
                    djui_hud_set_color(160, 190, 210, 255)
                    djui_hud_print_text(row.text, boxX + 22, y, 0.34)
                    y = y + 18
                else
                    if row.isMystery then
                        djui_hud_set_color(255, 140, 255, 255)
                    elseif row.isVoid then
                        djui_hud_set_color(180, 120, 255, 255)
                    elseif (row.rarity or 99) <= 2 then
                        djui_hud_set_color(255, 210, 90, 255)
                    elseif (row.rarity or 99) <= 5 then
                        djui_hud_set_color(255, 255, 255, 255)
                    else
                        djui_hud_set_color(220, 235, 255, 255)
                    end
                    djui_hud_print_text(row.text, boxX + 22, y, 0.40)
                    y = y + 18
                    if row.sub ~= nil then
                        djui_hud_set_color(120, 190, 255, 255)
                        djui_hud_print_text(row.sub, boxX + 30, y, 0.30)
                        y = y + 18
                    end
                end
            end
        end

        djui_hud_set_color(20, 40, 60, 255)
        djui_hud_render_rect(boxX + 5, boxY + boxH - 36, boxW - 10, 31)
        djui_hud_set_color(200, 220, 240, 255)
        djui_hud_print_text("D-Pad: pages   |   B: close map", boxX + 18, boxY + boxH - 26, 0.36)
    end

    if cook.boostTimer > 0 or cook.rareTimer > 0 or cook.luckTimer > 0 then
        local secs = math.ceil(math.max(cook.boostTimer, cook.rareTimer, cook.luckTimer) / 30)
        djui_hud_set_color(40, 20, 10, 200)
        djui_hud_render_rect(18, 70, 330, 58)
        djui_hud_set_color(255, 160, 60, 255)
        djui_hud_print_text(string.format("Cooked buffs: %ds", secs), 26, 78, 0.4)
        if cook.rareTimer > 0 then
            djui_hud_set_color(255, 205, 100, 255)
            djui_hud_print_text("Rare spawn +" .. tostring(cook.rareBonus) .. "%", 26, 98, 0.34)
        elseif cook.luckTimer > 0 then
            djui_hud_set_color(150, 220, 255, 255)
            djui_hud_print_text("Luck +" .. tostring(cook.luckBonus), 26, 98, 0.34)
        end
    end

    -- Prompt when near a shop sign but shop not open yet
    if shop.nearSign ~= nil and shop.activeKind == nil and pst.fishState == STATE.IDLE then
        djui_hud_set_color(0, 0, 0, 160)
        djui_hud_render_rect(sw * 0.22, sh * 0.60, sw * 0.56, sh * 0.14)
        draw_text_centered(shop.nearSign.label, sh * 0.62, 0.55, 255, 220, 100, 255)
        draw_text_centered("Press B to open", sh * 0.68, 0.42, 220, 255, 220, 255)
    end

    if ui.shopPrompt and not cook.menuOpen then
        local atSell = near_sell_shop(m)
        local atBait = near_bait_shop(m)
        local atCook = near_fireplace(m)
        djui_hud_set_color(0, 0, 0, 170)
        djui_hud_render_rect(sw * 0.18, sh * 0.56, sw * 0.64, sh * 0.26)

        if atCook then
            draw_text_centered("FIREPLACE", sh * 0.58, 0.7, 255, 140, 60, 255)
            if #ui.inventory > 0 then
                draw_text_centered("Press B to choose a fish and cook it", sh * 0.66, 0.5, 255, 220, 160, 255)
                draw_text_centered("Different fish create different temporary buffs!", sh * 0.72, 0.42, 200, 255, 180, 255)
            else
                draw_text_centered("No fish to cook", sh * 0.66, 0.5, 200, 200, 200, 255)
                draw_text_centered("Catch some first!", sh * 0.72, 0.42, 180, 180, 180, 230)
            end
        elseif atSell then
            local total = get_inventory_value()
            local count = #ui.inventory
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
            local bt = BAIT_TYPES[ui.baitTypeIndex] or BAIT_TYPES[1]
            local qty = BAIT_AMOUNTS[ui.baitBuyIndex] or 1
            local cost = qty * bt.cost
            local owned = get_bait_count(pst, bt.id)
            local active = get_bait_type(pst.activeBait or 1)
            draw_text_centered("BAIT SHOP", sh * 0.545, 0.55, 255, 220, 80, 255)
            draw_text_centered(bt.name .. "  -  " .. bt.desc, sh * 0.595, 0.36, 200, 240, 255, 255)
            draw_text_centered(string.format("Buy x%d for %d coins  |  Owned: %d", qty, cost, owned), sh * 0.64, 0.38, 180, 255, 180, 255)
            draw_text_centered(string.format("Active: %s   Total bait: %d/%d", active.name, total_bait(pst), get_max_bait()), sh * 0.685, 0.34, 255, 230, 140, 255)
            draw_text_centered("L/R type  Up/Down qty  A equip  B buy", sh * 0.73, 0.32, 210, 210, 210, 230)
            draw_text_centered(string.format("Balance: $%d / $%d", get_wallet(), get_max_coins()), sh * 0.77, 0.32, 255, 230, 100, 230)
        end
    end

    if ui.biteFlash > 0 then
        local a = math.floor(ui.biteFlash * 10)
        if a > 180 then a = 180 end
        djui_hud_set_color(255, 40, 40, a)
        djui_hud_render_rect(0, 0, sw, sh)
    end

    if pst.fishState == STATE.CASTING then
        draw_text_centered("Casting...", sh * 0.40, 0.7, 200, 220, 255, 255)
    end

    if pst.fishState == STATE.WAITING then
        draw_text_centered("Waiting for a bite...", sh * 0.40, 0.58, 180, 220, 255, 240)
    end

    if pst.fishState == STATE.BITE then
        local pulse = 1.2 + math.sin(get_global_timer() / 3) * 0.25
        draw_text_centered("BITE!", sh * 0.34, pulse, 255, 40, 40, 255)
        draw_text_centered("Press A!", sh * 0.48, 0.7, 255, 230, 80, 255)
    end

    if pst.fishState == STATE.MINIGAME then
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
        if ui.currentDifficulty == 2 then
            diffLabel = "MEDIUM"
            diffR, diffG, diffB = 255, 210, 80
        elseif ui.currentDifficulty == 3 then
            diffLabel = "HARD - SPAM A"
            diffR, diffG, diffB = 255, 90, 90
        elseif ui.currentDifficulty == 4 then
            diffLabel = "VERY HARD"
            diffR, diffG, diffB = 255, 70, 160
        elseif ui.currentDifficulty >= 5 then
            diffLabel = "EXTREME"
            diffR, diffG, diffB = 255, 50, 50
        end

        draw_text_centered(ui.lastCaught.name or "Fish", panelY + 12, 0.55, 255, 255, 220, 255)
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
        if ui.reelPulse > 0 then
            r = math.min(255, r + 40)
            g = math.min(255, g + 40)
        end
        djui_hud_set_color(r, g, b, 255)
        djui_hud_render_rect(barX, barY, fillW, barH)

        draw_text_centered(string.format("%d%%", math.floor(pst.miniProgress + 0.5)), barY + 4, 0.45, 255, 255, 255, 255)

        if ui.currentDifficulty == 1 then
            draw_text_centered("Hold A to reel", panelY + 112, 0.38, 200, 255, 200, 230)
        elseif ui.currentDifficulty == 2 then
            draw_text_centered("Hold A - don't let go!", panelY + 112, 0.38, 255, 230, 150, 230)
        elseif ui.currentDifficulty == 3 then
            draw_text_centered("MASH A as fast as you can!", panelY + 112, 0.4, 255, 120, 120, 255)
        elseif ui.currentDifficulty == 4 then
            draw_text_centered("FAST MASH - line drains quickly!", panelY + 112, 0.38, 255, 120, 180, 255)
        else
            draw_text_centered("SHORT, RAPID A PRESSES!", panelY + 112, 0.4, 255, 90, 90, 255)
        end
    end

    if pst.fishState == STATE.CATCH then
        local name = ui.lastCaught.name
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
        draw_text_centered(string.format("Size: %.1f cm", ui.lastCaught.size or 0), boxY + 120, 0.52, 180, 230, 255, 255)
        draw_text_centered(string.format("Weight: %.1f kg", ui.lastCaught.weight or 0), boxY + 152, 0.52, 180, 230, 255, 255)
        draw_text_centered("Press A to continue", boxY + 195, 0.4, 200, 200, 200, 230)
    end

    if ui.showInventory then
        local invW = 400
        local invH = 440
        local invX = sw - invW - 24
        local invY = 28

        djui_hud_set_color(12, 16, 28, 245)
        djui_hud_render_rect(invX, invY, invW, invH)

        -- Keep the ui.inventory header dark so the title is readable and never uses black-on-yellow text.
        djui_hud_set_color(24, 32, 52, 255)
        djui_hud_render_rect(invX, invY, invW, 40)
        djui_hud_set_color(255, 220, 90, 255)
        djui_hud_print_text("FISH INVENTORY", invX + 16, invY + 10, 0.52)

        -- Give the wallet and rod their own rows. This prevents long values/names from overlapping.
        djui_hud_set_color(255, 230, 80, 255)
        djui_hud_print_text(string.format("Balance: $%d / $%d", get_wallet(), get_max_coins()), invX + 16, invY + 50, 0.36)

        local style = get_rod_style()
        local maxU = pst.rodMaxUnlocked or 1
        djui_hud_set_color(255, 200, 120, 255)
        djui_hud_print_text(string.format("Rod: %s (%d/%d)", style.name, rodTier, maxU), invX + 16, invY + 74, 0.34)

        local ab = get_bait_type(pst.activeBait or 1)
        djui_hud_set_color(140, 230, 255, 255)
        djui_hud_print_text(string.format("Bait: %d/%d  Active: %s", total_bait(pst), get_max_bait(), ab.name), invX + 16, invY + 98, 0.34)
        djui_hud_set_color(160, 200, 220, 255)
        djui_hud_print_text(string.format("W:%d Cr:%d Mu:%d G:%d", pst.bait1 or 0, pst.bait2 or 0, pst.bait3 or 0, pst.bait4 or 0), invX + 16, invY + 118, 0.30)

        djui_hud_set_color(180, 255, 180, 255)
        djui_hud_print_text(string.format("Fish: %d / %d  (value %d)", #ui.inventory, get_max_inventory(), get_inventory_value()), invX + 16, invY + 138, 0.36)

        if ui.personalRecord.weight > 0 then
            djui_hud_set_color(255, 220, 100, 255)
            djui_hud_print_text(string.format("PR: %s  %.1f kg", ui.personalRecord.name, ui.personalRecord.weight), invX + 16, invY + 158, 0.34)
        end

        local yOff = 176
        if #ui.inventory == 0 then
            djui_hud_set_color(180, 180, 200, 255)
            djui_hud_print_text("No fish caught yet", invX + 16, invY + yOff, 0.42)
        else
            for i = #ui.inventory, 1, -1 do
                local rec = ui.inventory[i]
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

    if pst.fishState ~= STATE.IDLE then
        djui_hud_set_color(255, 220, 90, 230)
        djui_hud_print_text("Rod out  |  B cancel", 22, 50, 0.36)
    end

    if pst.fishState == STATE.IDLE and not ui.showInventory then
        djui_hud_set_color(255, 230, 80, 220)
        djui_hud_print_text(string.format("Balance: $%d / $%d", get_wallet(), get_max_coins()), 22, 18, 0.36)
        djui_hud_set_color(255, 255, 255, 210)
        djui_hud_print_text("Bait: " .. tostring(pst.bait), 22, 42, 0.38)
        local style = get_rod_style()
        djui_hud_set_color(200, 220, 255, 180)
        djui_hud_print_text("Rod: " .. style.name, 22, 66, 0.32)

        -- Urgent VOID decay warning on main HUD
        local voidMinLeft = nil
        for i = 1, #ui.inventory do
            local r = ui.inventory[i]
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

function before_set_mario_action(m, action)
    if m.playerIndex ~= 0 then
        return
    end
    local pst = ensure_sync()
    if pst.fishState ~= STATE.IDLE and pst.fishState ~= STATE.CATCH then
        if action == ACT_JUMP or action == ACT_DOUBLE_JUMP or action == ACT_TRIPLE_JUMP
            or action == ACT_LONG_JUMP or action == ACT_SIDE_FLIP or action == ACT_WALL_KICK_AIR
            or action == ACT_BACKFLIP or action == ACT_STEEP_JUMP or action == ACT_GROUND_POUND then
            return 1
        end
    end
end

function on_level_init()
    -- custom pole load
    E_MODEL_WOODROD_GEO = nil
    woodRodAttempts = 0
    E_MODEL_FISHINGROD_LEGENDARY_GEO = nil
    legendaryRodAttempts = 0
    E_MODEL_METALPOLE_GEO = nil
    metalPoleAttempts = 0
    E_MODEL_MASTERPOLE_GEO = nil
    masterPoleAttempts = 0

    local pst = ensure_sync()
    reset_fishing_state(pst)
    fix_active_bait(pst)
    vis.shopSignsSpawned = false
    vis.lastShopLevel = -1
    ui.showInventory = false
    close_cook_menu()
    destroy_fire_objs()
    destroy_lake_decor()
    clear_shop_sign_objs()
    shop.activeKind = nil
    clear_travel_boat()
    clear_ddd_boat()
    clear_jrb_boat()
    close_travel_menu()
    if not travelWarpGuard.active then
        save_progress()
    end
    -- The destination course is initialized now; the boat-transition marker is
    -- no longer needed.
    travelWarpGuard.active = false
    travelWarpGuard.level = 0
    travelWarpGuard.frames = 0
end

function on_warp()
    -- HOOK_ON_WARP can run while the destination course is still tearing down
    -- and constructing its areas. Keep this hook lightweight. In particular,
    -- do not delete objects, save, or open the fish map during RR's transition.
    pendingTravel.active = false
    close_cook_menu()
    close_travel_menu()
    ui.showInventory = false
    ui.showFishMap = false
end

function on_fishing_command(msg)
    msg = string.lower(msg or "")
    if msg == "dev" or msg == "dev on" or msg == "dev off" then
        local isServer = true
        if network_is_server ~= nil then isServer = network_is_server() end
        if not isServer then
            djui_chat_message_create("Only the host can enable Fishing DX developer commands.")
            return true
        end
        if msg == "dev off" then
            DEV_MODE = false
        elseif msg == "dev on" then
            DEV_MODE = true
        else
            DEV_MODE = not DEV_MODE
        end
        djui_chat_message_create(DEV_MODE and "Fishing DX developer commands ENABLED." or "Fishing DX developer commands disabled.")
        return true
    elseif msg == "" or msg == "help" then
        djui_chat_message_create("Fishing DX v" .. VERSION .. " by CrypticTM")
        djui_chat_message_create("Hold L aim, release to cast  |  A: bite/reel  |  B: cancel (returns bait) / shop")
        djui_chat_message_create("Mod Menu: Fish Map  |  /fishing map  |  /fishing hot")
        djui_chat_message_create("Market: B sell, A unlock rod  |  Left D-Pad: switch rod")
        djui_chat_message_create("Inventory: Right D-Pad  |  Up/Down equip bait")
        djui_chat_message_create("Rods: Wood>Metal>Gold>Master>Legendary(1500)")
        djui_chat_message_create("Rare hotspot rotates about every 10 minutes")
        djui_chat_message_create("Host: /fishing give <player> <bait> [amount]")
        djui_chat_message_create("/fishing prestige  (all rods unlocked + $5000)")
        djui_chat_message_create("Host dev tools: /fishing dev  |  /fv reset <player>  |  /fv prestige [player]")
        djui_chat_message_create("VOID Fish decays ~3 min - sell fast")
        return true
    elseif msg == "bait" then
        local pst = ensure_sync()
        fix_active_bait(pst)
        local ab = get_bait_type(pst.activeBait or 1)
        djui_chat_message_create(string.format(
            "Active: %s  |  W:%d Cr:%d Mu:%d G:%d Bh:%d  total %d/%d",
            ab.name, pst.bait1 or 0, pst.bait2 or 0, pst.bait3 or 0, pst.bait4 or 0, pst.bait5 or 0,
            total_bait(pst), get_max_bait()
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
        if ui.personalRecord.weight > 0 then
            djui_chat_message_create(string.format("Largest catch: %s (%.1f cm, %.1f kg)", ui.personalRecord.name, ui.personalRecord.size, ui.personalRecord.weight))
        else
            djui_chat_message_create("No personal record yet. Go fish!")
        end
        return true
    elseif msg == "inv" or msg == "ui.inventory" then
        djui_chat_message_create(string.format("Fish in ui.inventory: %d / %d  (value %d coins)", #ui.inventory, get_max_inventory(), get_inventory_value()))
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
        if amount > get_max_bait() then amount = get_max_bait() end

        local baitId = nil
        local lower = string.lower(baitToken)
        if lower == "1" or lower == "worm" or lower == "worms" then baitId = 1
        elseif lower == "2" or lower == "cricket" or lower == "crickets" then baitId = 2
        elseif lower == "3" or lower == "mushroom" or lower == "mushrooms" or lower == "super" then baitId = 3
        elseif lower == "4" or lower == "golden" or lower == "gold" or lower == "lure" then baitId = 4
        elseif lower == "5" or lower == "barbed" or lower == "hook" or lower == "barbedhook" then baitId = 5
        else
            baitId = tonumber(baitToken)
        end
        if baitId == nil or baitId < 1 or baitId > #BAIT_TYPES then
            djui_chat_message_create("Unknown bait. Use worm, cricket, mushroom, golden, barbed (or 1-5).")
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
            if n > get_max_bait() then n = get_max_bait() end
            if id == 1 then pst.bait1 = n
            elseif id == 2 then pst.bait2 = n
            elseif id == 3 then pst.bait3 = n
            elseif id == 4 then pst.bait4 = n end
            pst.bait = (pst.bait1 or 0) + (pst.bait2 or 0) + (pst.bait3 or 0) + (pst.bait4 or 0)
        end

        local before = getc(baitId)
        local room = get_max_bait() - before
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

    if msg == "prestige" then
        local pst = ensure_sync()
        local maxU = pst.rodMaxUnlocked or 1
        local wallet = get_wallet()
        local prest = pst.prestige or 0
        if maxU < #ROD_TIERS then
            djui_chat_message_create(string.format(
                "Prestige needs every rod unlocked (%d / %d).", maxU, #ROD_TIERS
            ))
            return true
        end
        if wallet < 5000 then
            djui_chat_message_create(string.format(
                "Prestige needs $5000. You have $%d.", wallet
            ))
            return true
        end
        if prest >= MAX_PRESTIGE then
            djui_chat_message_create("You are already at max prestige (" .. tostring(MAX_PRESTIGE) .. ").")
            return true
        end
        if not spend_wallet(5000) then
            djui_chat_message_create("Could not take $5000 for prestige.")
            return true
        end
        pst.prestige = prest + 1
        ui.lastPrestige = pst.prestige
        save_progress()
        djui_chat_message_create(string.format(
            "Prestiged to rank %d! Fights are harder. Balance $%d.",
            pst.prestige, get_wallet()
        ))
        djui_chat_message_create(string.format(
            "Limits up: wallet $%d  |  bait %d  |  inventory %d",
            get_max_coins(), get_max_bait(), get_max_inventory()
        ))
        return true
    end

    djui_chat_message_create("Usage: /fishing [help|bait|pr|inv|rod|map|hot|give|prestige]")
    return true
end

function on_fv_command(msg)
    msg = string.lower(msg or "")
    if not DEV_MODE then
        djui_chat_message_create("Fishing DX dev commands are disabled. Host: /fishing dev")
        return true
    end

    local isServer = true
    if network_is_server ~= nil then isServer = network_is_server() end
    if not isServer then
        djui_chat_message_create("Only the host can use /fv developer commands.")
        return true
    end

    local args = {}
    for token in string.gmatch(msg, "%S+") do table.insert(args, token) end
    local sub = args[1] or "help"

    local function player_name(i)
        local np = gNetworkPlayers[i]
        if np == nil or np.connected == false then return nil end
        return (np.name ~= nil and np.name ~= "") and np.name or ("Player " .. tostring(i))
    end

    local function find_player(token)
        if token == nil or token == "" then return 0 end
        local n = tonumber(token)
        if n ~= nil then
            n = math.floor(n)
            if gNetworkPlayers[n] ~= nil and gNetworkPlayers[n].connected ~= false then return n end
        end
        local low = string.lower(token)
        for i = 0, (MAX_PLAYERS or 16) - 1 do
            local name = player_name(i)
            if name ~= nil and string.find(string.lower(name), low, 1, true) then return i end
        end
        return nil
    end

    if sub == "reset" then
        local idx = find_player(args[2])
        if idx == nil then
            djui_chat_message_create("Player not found: " .. tostring(args[2] or ""))
            return true
        end
        local pst = gPlayerSyncTable[idx]
        if pst == nil then
            djui_chat_message_create("Could not access that player's fishing data.")
            return true
        end
        if idx == 0 then
            reset_fishing_progress(pst)
        else
            pst.fdxResetSeq = (pst.fdxResetSeq or 0) + 1
            -- The target client receives this sync field and saves the reset locally.
            pst.prestige = 0
            pst.hardMode = false
            pst.bait = 0
            pst.bait1 = 0
            pst.bait2 = 0
            pst.bait3 = 0
            pst.bait4 = 0
            pst.activeBait = 1
            pst.rodTier = 1
            pst.rodMaxUnlocked = 1
            pst.wallet = 0
        end
        djui_chat_message_create("Reset Fishing DX progress for " .. (player_name(idx) or ("Player " .. tostring(idx))) .. ".")
        return true
    elseif sub == "prestige" then
        local idx = find_player(args[2])
        if idx == nil then
            djui_chat_message_create("Player not found: " .. tostring(args[2] or ""))
            return true
        end
        local pst = gPlayerSyncTable[idx]
        if pst == nil then
            djui_chat_message_create("Could not access that player's fishing data.")
            return true
        end
        local amount = tonumber(args[3])
        if amount ~= nil then
            amount = math.floor(amount)
            if amount < 0 then amount = 0 end
            if amount > MAX_PRESTIGE then amount = MAX_PRESTIGE end
            pst.prestige = amount
        else
            pst.prestige = math.min(MAX_PRESTIGE, (pst.prestige or 0) + 1)
        end
        if idx == 0 then
            ui.lastPrestige = pst.prestige
            save_progress()
        end
        djui_chat_message_create(string.format("%s is now Prestige %d/%d. Fish are harder to catch.",
            player_name(idx) or ("Player " .. tostring(idx)), pst.prestige, MAX_PRESTIGE))
        return true
    elseif sub == "help" then
        djui_chat_message_create("/fv reset <player> - reset Fishing DX progress")
        djui_chat_message_create("/fv prestige [player] [0-5] - increase/set fishing difficulty")
        return true
    end

    djui_chat_message_create("Usage: /fv reset <player> | /fv prestige [player] [0-5]")
    return true
end

function is_fishing_prop(obj)
    if obj == nil then return false end
    if obj == vis.rodObj or obj == vis.rodTipObj or obj == vis.bobberObj or obj == vis.fishObj then
        return true
    end
    if obj == boats.travel or obj == boats.ddd then
        return true
    end
    for i = 1, #boats.travelParts do
        if boats.travelParts[i] == obj then return true end
    end
    for i = 1, #boats.travelCols do
        if boats.travelCols[i] == obj then return true end
    end
    for i = 1, #boats.dddCols do
        if boats.dddCols[i] == obj then return true end
    end
    if obj == boats.jrb then return true end
    for i = 1, #boats.jrbCols do
        if boats.jrbCols[i] == obj then return true end
    end
    for i = 1, #lake.decor do
        if lake.decor[i] == obj then return true end
    end
    for i = 1, #shop.objs do
        if shop.objs[i] == obj then return true end
    end
    for i = 1, #tutorial.objs do
        if tutorial.objs[i] == obj then return true end
    end
    for i = 1, #hardModeSign.objs do
        if hardModeSign.objs[i] == obj then return true end
    end
    for i = 1, #fishingLuigi.objs do
        if fishingLuigi.objs[i] == obj then return true end
    end
    return false
end

function allow_interact(m, obj, interactType)
    if is_fishing_prop(obj) then
        return false
    end
    return true
end
function on_mod_menu_fish_map(index)
    open_fish_map()
    djui_chat_message_create("Fish map opened. Left/Right D-Pad: pages. Right D-Pad again or menu button to close.")
end

function on_mod_menu_fish_list_chat(index)
    local lines = get_fish_map_lines()
    djui_chat_message_create("--- Fish Location Map ---")
    for i = 1, #FISH do
        local f = FISH[i]
        djui_chat_message_create(string.format("%s: %s", f.name, fish_location_text(f)))
    end
end

if hook_mod_menu_text ~= nil then
    pcall(hook_mod_menu_text, "Fishing DX - Fish Map")
    pcall(hook_mod_menu_text, "Complete fish locations, values, and difficulty")
end
if hook_mod_menu_button ~= nil then
    pcall(hook_mod_menu_button, "Open Complete Fishing Map", on_mod_menu_fish_map)
    pcall(hook_mod_menu_button, "Print Fish Map (Chat)", on_mod_menu_fish_list_chat)
end

hook_event(HOOK_MARIO_UPDATE, mario_update)
hook_event(HOOK_ON_HUD_RENDER, on_hud_render)
hook_event(HOOK_BEFORE_SET_MARIO_ACTION, before_set_mario_action)
hook_event(HOOK_ON_LEVEL_INIT, on_level_init)
hook_event(HOOK_ON_WARP, on_warp)
hook_event(HOOK_ALLOW_INTERACT, allow_interact)
hook_chat_command("fishing", "[help|bait|pr|inv|rod|map|hot|give|prestige|dev] Fishing DX", on_fishing_command)
hook_chat_command("fv", "[reset|prestige] Fishing DX developer commands", on_fv_command)
