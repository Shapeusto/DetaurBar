-- DetaurIDFinder.lua
-- Faza 1: Pre kazde ID v offline DB sa spyta servera na nazov -> porovná s ocakavanym
-- Faza 2: Uzivatel moze rucne zaregistrovat spravne ID ked najde item v AH/bagu
--
-- Prikazy:
--   /detaurid scan   - spusti skenovanie (pocka na server responses)
--   /detaurid save   - ulozi vysledky do SavedVariables + /reload
--   /detaurid reg    - registruje item z cursoru (drag item na chat frame) <- TODO
--   /detaurid help

local EXPECTED = {
    [2589]="Linen Cloth",[2996]="Bolt of Linen Cloth",
    [2592]="Wool Cloth",[2997]="Bolt of Wool Cloth",
    [4306]="Silk Cloth",[2320]="Bolt of Silk Cloth",
    [4338]="Mageweave Cloth",[4339]="Bolt of Mageweave Cloth",
    [14047]="Runecloth",[14342]="Bolt of Runecloth",
    [21877]="Netherweave Cloth",[21840]="Bolt of Netherweave Cloth",
    [33470]="Frostweave Cloth",[33472]="Bolt of Frostweave Cloth",
    [33476]="Bolt of Imbued Frostweave Cloth",
    [14344]="Mooncloth",[21845]="Primal Mooncloth",
    [24271]="Spellcloth",[24272]="Shadowcloth",
    [41593]="Ebonweave",[41594]="Spellweave",[41595]="Moonshroud",
    [2770]="Copper Ore",[2840]="Copper Bar",
    [2771]="Tin Ore",[2841]="Tin Bar",[2842]="Bronze Bar",
    [2775]="Silver Ore",[2843]="Silver Bar",
    [2772]="Iron Ore",[3575]="Iron Bar",
    [2776]="Gold Ore",[3577]="Gold Bar",[3859]="Steel Bar",
    [3858]="Mithril Ore",[3860]="Mithril Bar",
    [7911]="Truesilver Ore",[6037]="Truesilver Bar",
    [10620]="Thorium Ore",[12359]="Thorium Bar",[12800]="Arcanite Bar",
    [23424]="Fel Iron Ore",[23445]="Fel Iron Bar",
    [23425]="Adamantite Ore",[23446]="Adamantite Bar",
    [23427]="Eternium Ore",[23426]="Khorium Ore",[23449]="Khorium Bar",
    [23571]="Felsteel Bar",[23573]="Hardened Adamantite Bar",
    [36909]="Cobalt Ore",[36913]="Cobalt Bar",
    [36910]="Saronite Ore",[36916]="Saronite Bar",
    [36912]="Titanium Ore",[41163]="Titanium Bar",[37663]="Titansteel Bar",
    [2447]="Peacebloom",[765]="Silverleaf",[2449]="Earthroot",
    [785]="Mageroyal",[2450]="Briarthorn",[2452]="Swiftthistle",
    [2453]="Bruiseweed",[3355]="Wild Steelbloom",[3356]="Grave Moss",
    [3357]="Kingsblood",[3358]="Liferoot",[3818]="Fadeleaf",
    [3820]="Goldthorn",[3821]="Khadgar's Whisker",[3819]="Wintersbite",
    [4625]="Firebloom",[8831]="Purple Lotus",[8836]="Arthas' Tears",
    [8838]="Sungrass",[8839]="Blindweed",[8845]="Ghost Mushroom",[8846]="Gromsblood",
    [13464]="Golden Sansam",[13463]="Dreamfoil",[13465]="Mountain Silversage",
    [13466]="Plaguebloom",[13467]="Icecap",[13468]="Black Lotus",
    [22785]="Felweed",[22786]="Dreaming Glory",[22787]="Ragveil",
    [22788]="Flame Cap",[22789]="Terocone",[22790]="Ancient Lichen",
    [22793]="Mana Thistle",[22791]="Netherbloom",
    [22792]="Nightmare Seed",[22794]="Fel Lotus",
    [36901]="Goldclover",[36903]="Fire Leaf",[36904]="Tiger Lily",
    [36905]="Adder's Tongue",[36906]="Lichbloom",[36908]="Icethorn",
    [36902]="Frost Lotus",[36907]="Talandra's Rose",
    [2934]="Ruined Leather Scraps",[2318]="Light Leather",
    [2319]="Medium Leather",[4234]="Heavy Leather",
    [4304]="Thick Leather",[8170]="Rugged Leather",
    [21886]="Knothide Leather Scraps",[21887]="Knothide Leather",
    [23793]="Heavy Knothide Leather",
    [33566]="Borean Leather Scraps",[33568]="Borean Leather",
    [33567]="Heavy Borean Leather",[44128]="Arctic Fur",
    [38557]="Nerubian Chitin",[38558]="Icy Dragonscale",
    [36917]="Bloodstone",[36923]="Chalcedony",[36929]="Dark Jade",
    [36930]="Huge Citrine",[36931]="Shadow Crystal",[36932]="Sun Crystal",
    [36918]="Scarlet Ruby",[36924]="Autumn's Glow",[36927]="Monarch Topaz",
    [36928]="Forest Emerald",[36922]="Sky Sapphire",[36933]="Twilight Opal",
    [46849]="Cardinal Ruby",[46845]="King's Amber",[46846]="Ametrine",
    [46848]="Eye of Zul",[46847]="Majestic Zircon",[46844]="Dreadstone",
    [23077]="Living Ruby",[23079]="Noble Topaz",[23081]="Talasite",
    [23082]="Star of Elune",[23084]="Nightseye",[23085]="Dawnstone",
    [10940]="Strange Dust",[11083]="Soul Dust",[11137]="Vision Dust",
    [11176]="Dream Dust",[16204]="Illusion Dust",
    [22445]="Arcane Dust",[34054]="Infinite Dust",
    [10939]="Greater Magic Essence",[10938]="Lesser Magic Essence",
    [10998]="Greater Astral Essence",[10997]="Lesser Astral Essence",
    [11135]="Greater Mystic Essence",[11134]="Lesser Mystic Essence",
    [11175]="Greater Nether Essence",[11174]="Lesser Nether Essence",
    [16203]="Greater Eternal Essence",[16202]="Lesser Eternal Essence",
    [22446]="Greater Planar Essence",[22447]="Lesser Planar Essence",
    [34055]="Greater Cosmic Essence",[34056]="Lesser Cosmic Essence",
    [11177]="Small Radiant Shard",[11178]="Large Radiant Shard",
    [14343]="Small Brilliant Shard",[14344]="Large Brilliant Shard",
    [22448]="Small Prismatic Shard",[22449]="Large Prismatic Shard",
    [34052]="Dream Shard",[34053]="Small Dream Shard",[34057]="Abyss Crystal",
    [37700]="Crystallized Fire",[37701]="Crystallized Water",
    [37702]="Crystallized Earth",[37703]="Crystallized Air",
    [37704]="Crystallized Shadow",[37705]="Crystallized Life",
    [35624]="Eternal Fire",[35622]="Eternal Earth",[35623]="Eternal Water",
    [35625]="Eternal Air",[35627]="Eternal Shadow",[35626]="Eternal Life",
    [43102]="Frozen Orb",[45087]="Runed Orb",
    [47556]="Crusader Orb",[49908]="Primordial Saronite",
    [22451]="Primal Fire",[21884]="Primal Water",[22452]="Primal Earth",
    [22456]="Primal Air",[22457]="Primal Shadow",[22458]="Primal Life",
    [22455]="Primal Mana",[22450]="Primal Might",
    [39115]="Alabaster Pigment",[39116]="Dusky Pigment",
    [39117]="Golden Pigment",[39118]="Emerald Pigment",
    [39119]="Violet Pigment",[39120]="Silvery Pigment",
    [39330]="Nether Pigment",[39331]="Azure Pigment",
    [37101]="Ivory Ink",[39339]="Midnight Ink",[39338]="Lion's Ink",
    [39337]="Jadefire Ink",[39336]="Royal Ink",[39771]="Celestial Ink",
    [43121]="Fiery Ink",[43122]="Shimmering Ink",
    [43123]="Ink of the Sky",[39772]="Ethereal Ink",
    [39773]="Darkflame Ink",[43120]="Ink of the Sea",[43124]="Snowfall Ink",
}

-- Vysledky skenu
local scanResults = {}   -- { id, expectedName, serverName, mismatch }
local pendingIds = {}    -- IDcka co cakaju na server odpoved
local scanDone = false

local scanFrame = CreateFrame("Frame")
scanFrame:Hide()

-- Registruj event na prijimanie item info zo servera
scanFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED")
scanFrame:SetScript("OnEvent", function(self, event, itemId)
    if not pendingIds[itemId] then return end
    local serverName = GetItemInfo(itemId)
    local expectedName = pendingIds[itemId]
    pendingIds[itemId] = nil

    table.insert(scanResults, {
        id = itemId,
        expectedName = expectedName,
        serverName = serverName or "(nil)",
        mismatch = (serverName ~= expectedName),
    })

    -- Skontroluj ci vsetky odpovede prisli
    local remaining = 0
    for _ in pairs(pendingIds) do remaining = remaining + 1 end
    if remaining == 0 and scanDone then
        PrintScanResults()
    end
end)

function PrintScanResults()
    local wrong = 0
    DEFAULT_CHAT_FRAME:AddMessage("|cffFFD700=== DetaurIDFinder - ID overenie ===|r")
    for _, r in ipairs(scanResults) do
        if r.mismatch then
            DEFAULT_CHAT_FRAME:AddMessage(
                "|cffFF4444ZLY ID|r: " .. r.id ..
                "  ocakavane='" .. r.expectedName ..
                "'  server='" .. r.serverName .. "'"
            )
            wrong = wrong + 1
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cffFFD700Hotovo.|r Zlych IDciek: " .. wrong ..
        "  z " .. #scanResults .. " skenovanych."
    )
    if wrong > 0 then
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cff00FF00Zadaj /detaurid save  potom /reload|r"
        )
    end
end

local function DoScan()
    scanResults = {}
    pendingIds = {}
    scanDone = false
    local count = 0

    for id, name in pairs(EXPECTED) do
        local serverName = GetItemInfo(id)
        if serverName then
            -- Uz v cache, porovnaj hned
            table.insert(scanResults, {
                id = id,
                expectedName = name,
                serverName = serverName,
                mismatch = (serverName ~= name),
            })
        else
            -- Nie v cache, cakaj na server
            pendingIds[id] = name
        end
        count = count + 1
    end

    local waiting = 0
    for _ in pairs(pendingIds) do waiting = waiting + 1 end
    scanDone = true

    DEFAULT_CHAT_FRAME:AddMessage(
        "|cffFFD700DetaurIDFinder:|r Skenujem " .. count ..
        " IDciek... (" .. waiting .. " caka na server)"
    )

    if waiting == 0 then
        PrintScanResults()
    else
        -- Timeout: ak server neodpovie do 10s, vypis co mame
        local elapsed = 0
        scanFrame:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            if elapsed >= 10 then
                self:SetScript("OnUpdate", nil)
                local still = 0
                for id, name in pairs(pendingIds) do
                    table.insert(scanResults, {
                        id = id, expectedName = name,
                        serverName = "(timeout)", mismatch = true,
                    })
                    still = still + 1
                end
                pendingIds = {}
                if still > 0 then
                    DEFAULT_CHAT_FRAME:AddMessage(
                        "|cffFF8800" .. still .. " itemov nedostalo odpoved zo servera (timeout)|r"
                    )
                end
                PrintScanResults()
            end
        end)
    end
end

local function SaveScanResults()
    DetaurIDFinderDB = { mismatches = {}, timeout = {} }
    for _, r in ipairs(scanResults) do
        if r.mismatch then
            if r.serverName == "(timeout)" then
                table.insert(DetaurIDFinderDB.timeout, {
                    id = r.id, expectedName = r.expectedName
                })
            else
                table.insert(DetaurIDFinderDB.mismatches, {
                    id = r.id,
                    expectedName = r.expectedName,
                    serverName = r.serverName,
                })
            end
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(
        "|cffFFD700DetaurIDFinder:|r Ulozene " ..
        #DetaurIDFinderDB.mismatches .. " nezhodnych IDciek. Teraz /reload."
    )
end

SLASH_DETAURID1 = "/detaurid"
SlashCmdList["DETAURID"] = function(msg)
    if msg == "scan" then
        DoScan()
    elseif msg == "save" then
        SaveScanResults()
    elseif msg:match("^icon") then
        local _, _, rest = msg:find("^icon%s+(.*)$")
        if rest then
            for id in rest:gmatch("%d+") do
                id = tonumber(id)
                local name = GetItemInfo(id)
                if name then
                    local icon = select(10, GetItemInfo(id))
                    DEFAULT_CHAT_FRAME:AddMessage(
                        "[" .. id .. "] " .. name .. " -> " .. (icon or "(nil)")
                    )
                else
                    DEFAULT_CHAT_FRAME:AddMessage(
                        "[" .. id .. "] Neni v cache, skus neskor"
                    )
                end
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cffFFD700Pouzitie:|r /detaurid icon <id1> <id2> ...")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage(
            "|cffFFD700DetaurIDFinder:|r  /detaurid scan  |  /detaurid save  |  /detaurid icon"
        )
    end
end
