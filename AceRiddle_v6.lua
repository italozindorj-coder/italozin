--[[
    Ace - SAB Riddle Solver Only
    Groq key set by default. Override: getgenv().GROQ_API_KEY = "..."
    Stop: getgenv().StopRiddleSolver()
--]]

local function safeGetService(serviceName)
    local ok, service = pcall(function() return game:GetService(serviceName) end)
    if ok and service then
        if typeof(cloneref) == "function" then
            local refOk, ref = pcall(cloneref, service)
            if refOk and ref then return ref end
        end
        return service
    end
    return nil
end

local Players           = safeGetService("Players")
local ReplicatedStorage = safeGetService("ReplicatedStorage")
local UserInputService  = safeGetService("UserInputService")
local TweenService      = safeGetService("TweenService")
local HttpService       = safeGetService("HttpService")
local CoreGui           = safeGetService("CoreGui")

local LP = Players and Players.LocalPlayer
if Players and not LP then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LP = Players.LocalPlayer
end

local parentGui
if typeof(gethui) == "function" then
    pcall(function() parentGui = gethui() end)
end
if not parentGui then
    pcall(function() parentGui = CoreGui end)
end
if not parentGui and LP then
    parentGui = LP:FindFirstChildOfClass("PlayerGui") or LP:WaitForChild("PlayerGui", 5)
end

local getupvalues = (debug and debug.getupvalues) or getupvalues
local getconns = getconnections or (debug and debug.getconnections)
local httpRequest = (syn and syn.request) or http_request or request or (http and http.request)
local env = typeof(getgenv) == "function" and getgenv() or _G
local GROQ_API_KEY = env.GROQ_API_KEY or env.GROQ_API_KEY or "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"

local function stripRich(s)
    if type(s) ~= "string" then return tostring(s) end
    return (s:gsub("<[^>]->", ""))
end

local function trim(s)
    return (s or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

-- â”€â”€ SAB Knowledge Base â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local SAB_DB = {
    ["real name"]                   = "SAMMY",
    ["sammy real name"]             = "SAMMY",
    ["sammys real name"]            = "SAMMY",
    ["my real name"]                = "SAMMY",
    ["creator real name"]           = "SAMMY",
    ["owner real name"]             = "SAMMY",
    ["creator name"]                = "SAMMY",
    ["who created sab"]             = "SAMMY",
    ["who made sab"]                = "SAMMY",
    ["who made steal a brainrot"]   = "SAMMY",
    ["who is the owner"]            = "SAMMY",
    ["who owns sab"]                = "SAMMY",
    ["owner"]                       = "SAMMY",
    ["creator"]                     = "SAMMY",
    ["roblox username"]             = "SPYDERSAMMY",
    ["my roblox username"]          = "SPYDERSAMMY",
    ["sammy username"]              = "SPYDERSAMMY",
    ["sammy roblox name"]           = "SPYDERSAMMY",
    ["roblox name"]                 = "SPYDERSAMMY",
    ["username"]                    = "SPYDERSAMMY",
    ["my username"]                 = "SPYDERSAMMY",

    ["how old am i"]                = "24",
    ["how old is sammy"]            = "24",
    ["my age"]                      = "24",
    ["sammy age"]                   = "24",
    ["age"]                         = "24",
    ["birth year"]                  = "2002",
    ["year born"]                   = "2002",
    ["year i was born"]             = "2002",
    ["born year"]                   = "2002",
    ["birth day"]                   = "FRIDAY",
    ["day i was born"]              = "FRIDAY",
    ["day born"]                    = "FRIDAY",
    ["birthday"]                    = "FRIDAY",
    ["born on"]                     = "FRIDAY",
    ["birth month"]                 = "FEBRUARY",
    ["month born"]                  = "FEBRUARY",
    ["month i was born"]            = "FEBRUARY",
    ["where was i born"]            = "ALGERIA",
    ["where was i born at"]         = "ALGERIA",
    ["birthplace"]                  = "ALGERIA",
    ["where i was born"]            = "ALGERIA",

    ["where am i from"]             = "BRAZIL",
    ["where is sammy from"]         = "BRAZIL",
    ["my country"]                  = "BRAZIL",
    ["sammy country"]               = "BRAZIL",
    ["country"]                     = "BRAZIL",
    ["where do i live"]             = "BRAZIL",
    ["where does sammy live"]       = "BRAZIL",
    ["sammy location"]              = "BRAZIL",
    ["nationality"]                 = "BRAZILIAN",
    ["sammy nationality"]           = "BRAZILIAN",
    ["my nationality"]              = "BRAZILIAN",
    ["state"]                       = "SAOPAULO",
    ["my state"]                    = "SAOPAULO",
    ["sammy state"]                 = "SAOPAULO",
    ["city"]                        = "SAOPAULO",
    ["my city"]                     = "SAOPAULO",
    ["sammy city"]                  = "SAOPAULO",

    ["favorite color"]              = "BLUE",
    ["fav color"]                   = "BLUE",
    ["my color"]                    = "BLUE",
    ["sammy color"]                 = "BLUE",
    ["color"]                       = "BLUE",
    ["favourite color"]             = "BLUE",
    ["favorite color is blue"]      = "BLUE",
    ["fav color is blue"]           = "BLUE",
    ["my color is blue"]            = "BLUE",
    ["sammy color is blue"]         = "BLUE",
    ["my favorite color is blue"]   = "BLUE",
    ["color is blue"]               = "BLUE",
    ["favorite sport"]              = "FOOTBALL",
    ["fav sport"]                   = "FOOTBALL",
    ["sport"]                       = "FOOTBALL",
    ["my sport"]                    = "FOOTBALL",
    ["favorite football player"]    = "RONALDO",
    ["fav football player"]         = "RONALDO",
    ["my favorite football player"] = "RONALDO",
    ["favourite football player"]   = "RONALDO",
    ["football player"]             = "RONALDO",
    ["favorite player"]             = "RONALDO",
    ["fav player"]                  = "RONALDO",
    ["ronaldo"]                     = "RONALDO",
    ["favorite food"]               = "PIZZA",
    ["fav food"]                    = "PIZZA",
    ["my food"]                     = "PIZZA",
    ["food"]                        = "PIZZA",
    ["favorite animal"]             = "SPIDER",
    ["fav animal"]                  = "SPIDER",
    ["my animal"]                   = "SPIDER",
    ["my pet"]                      = "SPIDER",
    ["favorite game"]               = "ROBLOX",
    ["fav game"]                    = "ROBLOX",
    ["social media"]                = "YOUTUBE",
    ["youtube channel"]             = "SPYDERSAMMY",
    ["my youtube"]                  = "SPYDERSAMMY",
    ["sammy youtube"]               = "SPYDERSAMMY",

    ["game created on"]             = "FRIDAY",
    ["created on"]                  = "FRIDAY",
    ["what day was the game created"]= "FRIDAY",
    ["what day was sab created"]    = "FRIDAY",
    ["game creation day"]           = "FRIDAY",
    ["release month"]               = "MAY",
    ["release year"]                = "2025",
    ["year sab was created"]        = "2025",
    ["what year was sab created"]   = "2025",
    ["what year was the game created"] = "2025",
    ["year the game was created"]   = "2025",
    ["year sab was made"]           = "2025",
    ["month sab was made"] = "MAY", ["month the game was made"] = "MAY",
    ["month sab was released"] = "MAY", ["what month was sab made"] = "MAY",
    ["what month was sab released"] = "MAY", ["sab release month"] = "MAY",
    ["day sab was made"] = "FRIDAY", ["day sab was released"] = "FRIDAY",
    ["what day was sab made"] = "FRIDAY", ["what day was sab released"] = "FRIDAY",
    ["sab release day"] = "FRIDAY", ["game made on"] = "FRIDAY", ["sab made on"] = "FRIDAY",
    ["year the game was made"] = "2025", ["year made"] = "2025",
    ["when was sab made"] = "MAY162025", ["when made"] = "MAY162025", ["date made"] = "MAY162025",
    ["my name twice"] = "SAMMYSAMMY", ["my name 2 times"] = "SAMMYSAMMY",
    ["my name 3 times"] = "SAMMYSAMMYSAMMY", ["name twice"] = "SAMMYSAMMY",
    ["my age twice"] = "2424", ["my age 2 times"] = "2424", ["my age 3 times"] = "242424",
    ["favorite color twice"] = "BLUEBLUE", ["favorite color 2 times"] = "BLUEBLUE",
    ["favorite color 3 times"] = "BLUEBLUEBLUE", ["favorite color three times"] = "BLUEBLUEBLUE",
    ["favorite color 5 times"] = "BLUEBLUEBLUEBLUEBLUE",
    ["my favorite color twice"] = "BLUEBLUE", ["my favorite color 2 times"] = "BLUEBLUE",
    ["my favorite color 3 times"] = "BLUEBLUEBLUE",
    ["favorite sport twice"] = "FOOTBALLFOOTBALL", ["favorite food twice"] = "PIZZAPIZZA",
    ["owner twice"] = "SAMMYSAMMY", ["creator twice"] = "SAMMYSAMMY",

    ["year created"]                = "2025",
    ["what year was sab made"]      = "2025",
    ["year of sab"]                 = "2025",
    ["when was sab created"]        = "MAY162025",
    ["release date"]                = "MAY162025",
    ["when was sab released"]       = "MAY162025",
    ["when was the game released"]  = "MAY162025",
    ["game release date"]           = "MAY162025",
    ["game release"]                = "MAY162025",
    ["sab release"]                 = "MAY162025",
    ["game released"]               = "MAY162025",
    ["sab released"]                = "MAY162025",

    ["first trait"]                 = "LIGHTNING",
    ["1st trait"]                   = "LIGHTNING",
    ["first trait created"]         = "LIGHTNING",
    ["1st trait created"]           = "LIGHTNING",

    ["trait you get when struck by lightning"] = "MATEO",
    ["struck by lightning"]         = "MATEO",
    ["lightning trait"]             = "MATEO",
    ["trait from lightning"]        = "MATEO",
    ["trait when struck by lightning"] = "MATEO",
    ["lightning"]                   = "MATEO",

    ["first mutation"]              = "GOLD",
    ["1st mutation"]                = "GOLD",
    ["second mutation"]             = "DIAMOND",
    ["2nd mutation"]                = "DIAMOND",
    ["third mutation"]              = "BLOODROT",
    ["3rd mutation"]                = "BLOODROT",
    ["fourth mutation"]             = "RAINBOW",
    ["4th mutation"]                = "RAINBOW",
    ["fifth mutation"]              = "CANDY",
    ["5th mutation"]                = "CANDY",
    ["sixth mutation"]              = "LAVA",
    ["6th mutation"]                = "LAVA",
    ["seventh mutation"]            = "GALAXY",
    ["7th mutation"]                = "GALAXY",
    ["eighth mutation"]             = "YINYANG",
    ["8th mutation"]                = "YINYANG",
    ["ninth mutation"]              = "RADIOACTIVE",
    ["9th mutation"]                = "RADIOACTIVE",
    ["tenth mutation"]              = "CURSED",
    ["10th mutation"]               = "CURSED",
    ["eleventh mutation"]           = "DIVINE",
    ["11th mutation"]               = "DIVINE",
    ["twelfth mutation"]            = "CYBER",
    ["12th mutation"]               = "CYBER",
    ["thirteenth mutation"]         = "PHANTOM",
    ["13th mutation"]               = "PHANTOM",
    ["fourteenth mutation"]         = "CRYSTAL",
    ["14th mutation"]               = "CRYSTAL",

    ["evil mutation"]               = "CURSED",
    ["evil"]                        = "CURSED",
    ["cursed mutation"]             = "CURSED",
    ["angelic mutation"]            = "DIVINE",
    ["angelic"]                     = "DIVINE",
    ["divine mutation"]             = "DIVINE",
    ["good mutation"]               = "DIVINE",
    ["best mutation"]               = "DIVINE",
    ["top mutation"]                = "DIVINE",
    ["latest mutation"]             = "CRYSTAL",
    ["most recent mutation"]        = "CRYSTAL",
    ["most recent"]                 = "CRYSTAL",
    ["newest mutation"]             = "CRYSTAL",
    ["divinecursed"]                = "DIVINECURSED",
    ["curseddivine"]                = "CURSEDDIVINE",

    ["green mutation"]              = "RADIOACTIVE",
    ["turns green"]                 = "RADIOACTIVE",
    ["green"]                       = "RADIOACTIVE",
    ["purple mutation"]             = "GALAXY",
    ["turns purple"]                = "GALAXY",
    ["purple"]                      = "GALAXY",
    ["black and white mutation"]    = "YINYANG",
    ["black mutation"]              = "YINYANG",
    ["turns black"]                 = "YINYANG",
    ["black and white"]             = "YINYANG",
    ["yellow mutation"]             = "DIVINE",
    ["turns yellow"]                = "DIVINE",
    ["yellow"]                      = "DIVINE",
    ["red mutation"]                = "CURSED",
    ["turns red"]                   = "CURSED",
    ["red"]                         = "CURSED",
    ["orange mutation"]             = "LAVA",
    ["turns orange"]                = "LAVA",
    ["orange"]                      = "LAVA",

    ["first machine"]               = "RAINBOWMACHINE",
    ["1st machine"]                 = "RAINBOWMACHINE",
    ["second machine"]              = "BUBBLEGUMMACHINE",
    ["2nd machine"]                 = "BUBBLEGUMMACHINE",
    ["third machine"]               = "FUSEMACHINE",
    ["3rd machine"]                 = "FUSEMACHINE",
    ["fourth machine"]              = "CRAFTMACHINE",
    ["4th machine"]                 = "CRAFTMACHINE",
    ["fifth machine"]               = "WITCHFUSE",
    ["5th machine"]                 = "WITCHFUSE",
    ["sixth machine"]               = "BRAINROTDEALER",
    ["6th machine"]                 = "BRAINROTDEALER",
    ["seventh machine"]             = "BRAINROTTRADER",
    ["7th machine"]                 = "BRAINROTTRADER",
    ["eighth machine"]              = "SANTASFUSE",
    ["8th machine"]                 = "SANTASFUSE",
    ["ninth machine"]               = "SANTASSHOP",
    ["9th machine"]                 = "SANTASSHOP",
    ["tenth machine"]               = "NEWYEARSMACHINE",
    ["10th machine"]                = "NEWYEARSMACHINE",
    ["eleventh machine"]            = "DUELSMACHINE",
    ["11th machine"]                = "DUELSMACHINE",
    ["twelfth machine"]             = "CUPIDSMACHINE",
    ["12th machine"]                = "CUPIDSMACHINE",
    ["thirteenth machine"]          = "TRADEMACHINE",
    ["13th machine"]                = "TRADEMACHINE",
    ["fourteenth machine"]          = "DIVINEFUSE",
    ["14th machine"]                = "DIVINEFUSE",
    ["fifteenth machine"]           = "EGGINCUBATOR",
    ["15th machine"]                = "EGGINCUBATOR",
    ["sixteenth machine"]           = "CYBERCRAFTMACHINE",
    ["16th machine"]                = "CYBERCRAFTMACHINE",
    ["seventeenth machine"]         = "SUMMERFUSE",
    ["17th machine"]                = "SUMMERFUSE",
    ["eighteenth machine"]          = "LOSTRADERS",
    ["18th machine"]                = "LOSTRADERS",

    ["og brainrot cannot be obtained"] = "HEADLESSHORSEMAN",
    ["headless horseman"]           = "HEADLESSHORSEMAN",
    ["rarest brainrot"]             = "HEADLESSHORSEMAN",
    ["rarest"]                      = "HEADLESSHORSEMAN",
    ["best brainrot"]               = "STRAWBERRYELEPHANT",
    ["unobtainable brainrot"]       = "HEADLESSHORSEMAN",
    ["unobtainable"]                = "HEADLESSHORSEMAN",

    ["first og added"]              = "STRAWBERRYELEPHANT",
    ["1st og"]                      = "STRAWBERRYELEPHANT",
    ["second og added"]             = "MEOWL",
    ["2nd og"]                      = "MEOWL",
    ["third og added"]              = "SKIBIDITOILET",
    ["3rd og"]                      = "SKIBIDITOILET",
    ["fifth og added"]              = "JOHNPORK",
    ["5th og"]                      = "JOHNPORK",

    ["highest rarity"]              = "OG",
    ["rarest rarity"]               = "OG",
    ["top rarity"]                  = "OG",
    ["lowest rarity"]               = "COMMON",
    ["common rarity"]               = "COMMON",

    ["fire represents"]             = "DRAGON",
    ["fire stands for"]             = "DRAGON",
    ["won the world cup"]           = "SPAIN",
    ["world cup winner"]            = "SPAIN",
    ["world cup"]                   = "SPAIN",
    ["worst game owner"]            = "SECRETLOKII",
    ["most boring game owner"]      = "SECRETLOKII",
    ["most boring game on roblox"]  = "KEYBOARDESCAPE",
    ["spawned during admin abuse war"] = "RACOONINIJANDELINI",
    ["who did i fight in the admin abuse war"] = "JANDEL",
    ["fought in admin abuse war"]   = "JANDEL",
    ["won the admin abuse war"]     = "GROWAGARDEN",
    ["worst secret"]                = "KARKERKARKURKUR",
    ["maximum server size"]         = "EIGHT",
    ["max server size"]             = "EIGHT",
    ["server size"]                 = "EIGHT",
    ["how many players"]            = "EIGHT",
    ["max players"]                 = "EIGHT",
    ["brother of hydra bunny"]      = "CERBERUS",
    ["hydra bunny brother"]         = "CERBERUS",

    ["game name"]                   = "STEALABRAINROT",
    ["name of the game"]            = "STEALABRAINROT",
    ["sab"]                         = "STEALABRAINROT",
    ["sab stands for"]              = "STEALABRAINROT",
    ["full name"]                   = "STEALABRAINROT",
    ["number of mutations"]         = "14",
    ["how many mutations"]          = "14",
    ["total mutations"]             = "THIRTEEN",
    ["number of machines"]          = "18",
    ["how many machines"]           = "18",
    ["total machines"]              = "18",
    ["most popular brainrot"]       = "DRAGONCANNELONNI",
    ["most common brainrot"]        = "NOOBINIPIZZANINI",

    -- Extra personal / contextual lookups
    ["favorite color twice"]        = "BLUEBLUE",
    ["fav color twice"]             = "BLUEBLUE",
    ["favorite color 2 times"]      = "BLUEBLUE",
    ["favorite color three times"]  = "BLUEBLUEBLUE",
    ["favorite color 3 times"]      = "BLUEBLUEBLUE",
    ["favorite color, favorite sport"] = "BLUEFOOTBALL",
    ["favorite color, favorite animal"] = "BLUESPIDER",
    ["favorite color, favorite food"] = "BLUEPIZZA",
    ["favorite color, favorite player"] = "BLUERONALDO",
    ["favorite color, creator"] = "BLUESAMMY",
    ["favorite color, owner"] = "BLUESAMMY",
    ["favorite color, username"] = "BLUESPYDERSAMMY",
    ["favorite color, roblox username"] = "BLUESPYDERSAMMY",
    ["favorite color, my age"] = "BLUE24",
    ["favorite color, my country"] = "BLUEBRAZIL",
    ["favorite sport, favorite player"] = "FOOTBALLRONALDO",
    ["favorite sport, favorite color"] = "FOOTBALLBLUE",
    ["favorite sport, favorite animal"] = "FOOTBALLSPIDER",
    ["favorite sport, owner"] = "FOOTBALLSAMMY",
    ["favorite sport, creator"] = "FOOTBALLSAMMY",
    ["creator, owner"] = "SAMMYSAMMY",
    ["creator, username"] = "SAMMYSPYDERSAMMY",
    ["owner, username"] = "SAMMYSPYDERSAMMY",
    ["favorite color, favorite sport, favorite animal"] = "BLUEFOOTBALLSPIDER",
    ["color, sport, animal"] = "BLUEFOOTBALLSPIDER",
    ["discord"]                     = "ACE",
    ["discord server"]              = "ACE",
    ["sammy discord"]               = "SPYDERSAMMY",
    ["twitter"]                     = "SPYDERSAMMY",
    ["sammy twitter"]               = "SPYDERSAMMY",
    ["x account"]                   = "SPYDERSAMMY",
    ["tiktok"]                      = "SPYDERSAMMY",
    ["sammy tiktok"]                = "SPYDERSAMMY",
    ["instagram"]                   = "SPYDERSAMMY",
    ["favorite number"]             = "SEVEN",
    ["fav number"]                  = "SEVEN",
    ["lucky number"]                = "SEVEN",
    ["number"]                      = "SEVEN",
    ["first update"]                = "MUTATIONS",
    ["1st update"]                  = "MUTATIONS",
    ["first brainrot added"]        = "STRAWBERRYELEPHANT",
    ["1st brainrot"]                = "STRAWBERRYELEPHANT",
    ["oldest brainrot"]             = "STRAWBERRYELEPHANT",
    ["newest mutation"]             = "CRYSTAL",
    ["last mutation"]             = "CRYSTAL",
    ["latest mutation"]             = "CRYSTAL",
    ["newest machine"]              = "LOSTRADERS",
    ["last machine"]                = "LOSTRADERS",
    ["latest machine"]              = "LOSTRADERS",
    ["type of game"]                = "SIMULATOR",
    ["game genre"]                  = "SIMULATOR",
    ["genre"]                       = "SIMULATOR",
    ["sammy pet name"]              = "SPIDER",
    ["pet name"]                    = "SPIDER",
    ["pet"]                         = "SPIDER",
    ["animal"]                      = "SPIDER",
    ["what is sab"]                 = "STEALABRAINROT",
    ["total rarities"]              = "SIX",
    ["how many rarities"]           = "SIX",
    ["number of rarities"]          = "SIX",
    ["rarities"]                    = "SIX",

    -- standalone single-word fallbacks
    ["fire"]                        = "DRAGON",
    ["dragon"]                      = "DRAGON",
    ["players"]                     = "EIGHT",
    ["player count"]                = "EIGHT",
    ["server"]                      = "EIGHT",
    ["brother"]                     = "CERBERUS",
    ["cerberus"]                    = "CERBERUS",
    ["hydra bunny"]                 = "CERBERUS",
    ["location"]                    = "BRAZIL",
    ["from"]                        = "BRAZIL",
    ["name"]                        = "SAMMY",
    ["my name"]                     = "SAMMY",
    ["roblox"]                      = "SPYDERSAMMY",
    ["youtube"]                     = "SPYDERSAMMY",
    ["food"]                        = "PIZZA",
    ["sport"]                       = "FOOTBALL",
    ["player"]                      = "RONALDO",
    ["football"]                    = "FOOTBALL",
    ["game"]                        = "ROBLOX",
    ["update"]                      = "MUTATIONS",
    ["trait"]                       = "LIGHTNING",
    ["first trait added"]           = "LIGHTNING",

    -- mutation by number (alternate phrasing)
    ["mutation 1"]  = "GOLD",      ["mutation number 1"]  = "GOLD",
    ["mutation 2"]  = "DIAMOND",   ["mutation number 2"]  = "DIAMOND",
    ["mutation 3"]  = "BLOODROT",  ["mutation number 3"]  = "BLOODROT",
    ["mutation 4"]  = "RAINBOW", ["mutation number 4"]  = "RAINBOW",
    ["mutation 5"]  = "CANDY",     ["mutation number 5"]  = "CANDY",
    ["mutation 6"]  = "LAVA",      ["mutation number 6"]  = "LAVA",
    ["mutation 7"]  = "GALAXY",    ["mutation number 7"]  = "GALAXY",
    ["mutation 8"]  = "YINYANG",   ["mutation number 8"]  = "YINYANG",
    ["mutation 9"]  = "RADIOACTIVE",["mutation number 9"] = "RADIOACTIVE",
    ["mutation 10"] = "CURSED",    ["mutation number 10"] = "CURSED",
    ["mutation 11"] = "DIVINE",   ["mutation number 11"] = "DIVINE",
    ["mutation 12"] = "CYBER",     ["mutation number 12"] = "CYBER",
    ["mutation 13"] = "PHANTOM",   ["mutation number 13"] = "PHANTOM",
    ["mutation 14"] = "CRYSTAL",   ["mutation number 14"] = "CRYSTAL",

    -- machine by number (alternate phrasing)
    ["machine 1"]  = "RAINBOWMACHINE",    ["machine number 1"]  = "RAINBOWMACHINE",
    ["machine 2"]  = "BUBBLEGUMMACHINE",  ["machine number 2"]  = "BUBBLEGUMMACHINE",
    ["machine 3"]  = "FUSEMACHINE",       ["machine number 3"]  = "FUSEMACHINE",
    ["machine 4"]  = "CRAFTMACHINE",      ["machine number 4"]  = "CRAFTMACHINE",
    ["machine 5"]  = "WITCHFUSE",         ["machine number 5"]  = "WITCHFUSE",
    ["machine 6"]  = "BRAINROTDEALER",    ["machine number 6"]  = "BRAINROTDEALER",
    ["machine 7"]  = "BRAINROTTRADER",    ["machine number 7"]  = "BRAINROTTRADER",
    ["machine 8"]  = "SANTASFUSE",        ["machine number 8"]  = "SANTASFUSE",
    ["machine 9"]  = "SANTASSHOP",        ["machine number 9"]  = "SANTASSHOP",
    ["machine 10"] = "NEWYEARSMACHINE",   ["machine number 10"] = "NEWYEARSMACHINE",
    ["machine 11"] = "DUELSMACHINE",      ["machine number 11"] = "DUELSMACHINE",
    ["machine 12"] = "CUPIDSMACHINE",     ["machine number 12"] = "CUPIDSMACHINE",
    ["machine 13"] = "TRADEMACHINE",      ["machine number 13"] = "TRADEMACHINE",
    ["machine 14"] = "DIVINEFUSE",        ["machine number 14"] = "DIVINEFUSE",
    ["machine 15"] = "EGGINCUBATOR",      ["machine number 15"] = "EGGINCUBATOR",
    ["machine 16"] = "CYBERCRAFTMACHINE", ["machine number 16"] = "CYBERCRAFTMACHINE",
    ["machine 17"] = "SUMMERFUSE",        ["machine number 17"] = "SUMMERFUSE",
    ["machine 18"] = "LOSTRADERS",        ["machine number 18"] = "LOSTRADERS",

    -- og brainrots by number
    ["og 1"]  = "STRAWBERRYELEPHANT", ["og number 1"]  = "STRAWBERRYELEPHANT",
    ["og 2"]  = "MEOWL",              ["og number 2"]  = "MEOWL",
    ["og 3"]  = "SKIBIDITOILET",      ["og number 3"]  = "SKIBIDITOILET",
    ["og 5"]  = "JOHNPORK",           ["og number 5"]  = "JOHNPORK",

    -- worst / least rare brainrot
    ["worst brainrot"]              = "NOOBINIPIZZANINI",
    ["most common brainrot"]        = "NOOBINIPIZZANINI",
    ["least rare brainrot"]         = "NOOBINIPIZZANINI",
    ["weakest brainrot"]            = "NOOBINIPIZZANINI",
    ["most popular brainrot"]       = "DRAGONCANNELONNI",
    ["common brainrot"]             = "NOOBINIPIZZANINI",

    -- mutation color lookups (reverse: "color of X mutation")
    ["color of gold mutation"]      = "YELLOW",
    ["color of diamond mutation"]   = "BLUE",
    ["color of bloodrot mutation"]  = "RED",
    ["color of rainbow mutation"]   = "RAINBOW",
    ["color of candy mutation"]     = "PINK",
    ["color of lava mutation"]      = "ORANGE",
    ["color of galaxy mutation"]    = "PURPLE",
    ["color of yinyang mutation"]   = "BLACK",
    ["color of radioactive mutation"]="GREEN",
    ["color of cursed mutation"]    = "RED",
    ["color of divine mutation"]    = "YELLOW",
    ["color of cyber mutation"]     = "BLUE",
    ["color of phantom mutation"]   = "BLACK",
    ["color of crystal mutation"]   = "BLUEPURPLE",
    ["divine color"]                = "YELLOW",
    ["cursed color"]                = "RED",
    ["radioactive color"]           = "GREEN",
    ["galaxy color"]                = "PURPLE",
    ["yinyang color"]               = "BLACK",
    ["lava color"]                  = "ORANGE",

    -- "what mutation is X color"
    ["blue mutation"]               = "DIAMOND",
    ["pink mutation"]               = "CANDY",

    -- specific mutation name lookups
    ["gold"]                        = "GOLD",
    ["diamond"]                     = "DIAMOND",
    ["bloodrot"]                    = "BLOODROT",
    ["rainbow"]                     = "RAINBOW",
    ["candy"]                       = "CANDY",
    ["lava"]                        = "LAVA",
    ["galaxy"]                      = "GALAXY",
    ["yinyang"]                     = "YINYANG",
    ["radioactive"]                 = "RADIOACTIVE",
    ["cursed"]                      = "CURSED",
    ["divine"]                      = "DIVINE",
    ["cyber"]                       = "CYBER",
    ["phantom"]                     = "PHANTOM",
    ["crystal"]                     = "CRYSTAL",
    ["cursed"]                      = "CURSED",
    ["rainbow"]                     = "RAINBOW",
    ["cyber"]                       = "CYBER",
    ["divine"]                      = "DIVINE",

    -- mutation position lookups (what number is X)
    ["what number is gold"]         = "1",
    ["what number is diamond"]      = "2",
    ["what number is bloodrot"]     = "3",
    ["what number is rainbow"]      = "4",
    ["what number is candy"]        = "5",
    ["what number is lava"]         = "6",
    ["what number is galaxy"]       = "7",
    ["what number is yinyang"]      = "8",
    ["what number is radioactive"]  = "9",
    ["what number is cursed"]       = "10",
    ["what number is divine"]       = "11",
    ["what number is cyber"]        = "12",
    ["what number is phantom"]      = "13",
    ["what number is crystal"]      = "14",

    -- machine name lookups
    ["rainbowmachine"]              = "RAINBOWMACHINE",
    ["bubblegummachine"]            = "BUBBLEGUMMACHINE",
    ["fusemachine"]                 = "FUSEMACHINE",
    ["craftmachine"]                = "CRAFTMACHINE",
    ["witchfuse"]                   = "WITCHFUSE",
    ["brainrotdealer"]              = "BRAINROTDEALER",
    ["brainrottrader"]              = "BRAINROTTRADER",
    ["santasfuse"]                  = "SANTASFUSE",
    ["santasshop"]                  = "SANTASSHOP",
    ["newyearsmachine"]             = "NEWYEARSMACHINE",
    ["duelsmachine"]                = "DUELSMACHINE",
    ["cupidsmachine"]               = "CUPIDSMACHINE",
    ["trademachine"]                = "TRADEMACHINE",
    ["divinefuse"]                  = "DIVINEFUSE",
    ["eggincubator"]                = "EGGINCUBATOR",
    ["cybercraftmachine"]           = "CYBERCRAFTMACHINE",
    ["summerfuse"]                  = "SUMMERFUSE",
    ["lostraders"]                  = "LOSTRADERS",

    -- extra rarity questions
    ["best rarity"]                 = "OG",
    ["rarest rarity"]               = "OG",
    ["highest rarity"]              = "OG",
    ["worst rarity"]                = "COMMON",
    ["lowest rarity"]               = "COMMON",
    ["6th rarity"]                  = "OG",
    ["1st rarity"]                  = "COMMON",
    ["second rarity"]               = "UNCOMMON",
    ["2nd rarity"]                  = "UNCOMMON",
    ["third rarity"]                = "RARE",
    ["3rd rarity"]                  = "RARE",
    ["fourth rarity"]               = "EPIC",
    ["4th rarity"]                  = "EPIC",
    ["fifth rarity"]                = "LEGENDARY",
    ["5th rarity"]                  = "LEGENDARY",
    ["sixth rarity"]                = "OG",
    ["uncommon"]                    = "UNCOMMON",
    ["rare"]                        = "RARE",
    ["epic"]                        = "EPIC",
    ["legendary"]                   = "LEGENDARY",
    ["og"]                          = "OG",
    ["common"]                      = "COMMON",

    -- extra owner questions
    ["sammy name"]                  = "SAMMY",
    ["game owner"]                  = "SAMMY",
    ["developer"]                   = "SAMMY",
    ["dev"]                         = "SAMMY",
    ["made by"]                     = "SAMMY",
    ["created by"]                  = "SAMMY",
    ["made this game"]              = "SAMMY",
    ["real name of sammy"]          = "SAMMY",
    ["sammys name"]                 = "SAMMY",
    ["birth country"]               = "BRAZIL",
    ["born in"]                     = "BRAZIL",
    ["lives in"]                    = "BRAZIL",
    ["comes from"]                  = "BRAZIL",
    ["channel"]                     = "SPYDERSAMMY",
    ["handle"]                      = "SPYDERSAMMY",

    -- extra game info questions
    ["game type"]                   = "SIMULATOR",
    ["what type"]                   = "SIMULATOR",
    ["sab genre"]                   = "SIMULATOR",
    ["sab type"]                    = "SIMULATOR",
    ["how many players in server"]  = "EIGHT",
    ["server capacity"]             = "EIGHT",
    ["players per server"]          = "EIGHT",
    ["max server"]                  = "EIGHT",
    ["day game released"]           = "FRIDAY",
    ["day sab released"]            = "FRIDAY",
    ["release day"]                 = "FRIDAY",
    ["day released"]                = "FRIDAY",
    ["what day was it released"]    = "FRIDAY",
    ["what day was it created"]     = "FRIDAY",
    ["sab creation year"]           = "2025",
    ["creation year"]               = "2025",
    ["when created"]                = "MAY162025",
    ["when released"]               = "MAY162025",
    ["date released"]               = "MAY162025",
    ["date created"]                = "MAY162025",

    -- trait questions
    ["trait added first"]           = "LIGHTNING",
    ["trait first added"]           = "LIGHTNING",
    ["what trait"]                  = "LIGHTNING",
    ["lightning strike trait"]      = "MATEO",
    ["get struck by lightning"]     = "MATEO",
    ["lightning gives"]             = "MATEO",
    ["struck by lightning trait"]   = "MATEO",
    ["mateo"]                       = "MATEO",

    -- trivia extras
    ["fire symbol"]                 = "DRAGON",
    ["fire meaning"]                = "DRAGON",
    ["fire brainrot"]               = "DRAGON",
    ["world cup"]                   = "SPAIN",
    ["won world cup"]               = "SPAIN",
    ["football world cup"]          = "SPAIN",
    ["worst owner"]                 = "SECRETLOKII",
    ["boring owner"]                = "SECRETLOKII",
    ["most boring owner"]           = "SECRETLOKII",
    ["boring game"]                 = "KEYBOARDESCAPE",
    ["most boring game"]            = "KEYBOARDESCAPE",
    ["boring roblox game"]          = "KEYBOARDESCAPE",
    ["admin abuse war"]             = "GROWAGARDEN",
    ["who won admin war"]           = "GROWAGARDEN",
    ["admin war winner"]            = "GROWAGARDEN",
    ["admin war"]                   = "GROWAGARDEN",
    ["who did sammy fight"]         = "JANDEL",
    ["sammy fought"]                = "JANDEL",
    ["fight in admin war"]          = "JANDEL",
    ["admin war brainrot"]          = "RACOONINIJANDELINI",
    ["spawned in admin war"]        = "RACOONINIJANDELINI",
    ["secret"]                      = "KARKERKARKURKUR",
    ["worst secret"]                = "KARKERKARKURKUR",
    ["bad secret"]                  = "KARKERKARKURKUR",
    ["hydra bunny"]                 = "CERBERUS",
    ["cerberus brother"]            = "CERBERUS",
    ["brother of hydra"]            = "CERBERUS",

    -- brainrot count / machine count
    ["brainrot count"]              = "THIRTEEN",
    ["mutation count"]              = "THIRTEEN",
    ["machine count"]               = "EIGHTEEN",
    ["rarity count"]                = "SIX",
    ["how many brainrots"]          = "THIRTEEN",
    ["number brainrots"]            = "THIRTEEN",
    ["how many og brainrots"]       = "FIVE",
    ["total og brainrots"]          = "FIVE",
    ["og count"]                    = "FIVE",

    -- sab full name
    ["steal a brainrot"]            = "STEALABRAINROT",
    ["full game name"]              = "STEALABRAINROT",
    ["game full name"]              = "STEALABRAINROT",
    ["sab full name"]               = "STEALABRAINROT",
}

-- localExactAnswer: ONLY returns something when we are 100% certain via exact key match.
-- Everything else falls through to Groq AI so the AI always gets a chance to answer.
local function localExactAnswer(text)
    if not text or text == "" then return nil end
    local l = text:lower()

    -- Exact DB lookup after stripping question filler words
    local clean = l
    clean = clean:gsub("what%s+is", ""):gsub("what%s+are", ""):gsub("what%s+was", ""):gsub("what%s+were", "")
    clean = clean:gsub("who%s+is", ""):gsub("who%s+was", ""):gsub("when%s+is", ""):gsub("when%s+was", "")
    clean = clean:gsub("where%s+is", ""):gsub("where%s+are", ""):gsub("how%s+old", ""):gsub("how%s+tall", "")
    clean = clean:gsub("how%s+many", ""):gsub("how%s+much", ""):gsub("do%s+you%s+know", ""):gsub("can%s+you%s+tell", "")
    clean = clean:gsub("tell%s+me", ""):gsub("i%s+need", ""):gsub("give%s+me", ""):gsub("what's", ""):gsub("whats", "")
    clean = clean:gsub("am%s+i", ""):gsub("do%s+i", ""):gsub("did%s+i", ""):gsub("have%s+i", "")
    clean = clean:gsub("^my%s+", ""):gsub("%s+my%s+", " "):gsub("^sammy[s]?%s+", ""):gsub("^sammys%s+", "")
    clean = clean:gsub("the%s+", ""):gsub("%f[%a]a%f[%A]", ""):gsub("%f[%a]an%f[%A]", ""):gsub("of%s+", ""):gsub("for%s+", "")
    clean = clean:gsub("[%?%.%,!]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    clean = clean:gsub("%d+", ""):gsub("%s+", " ")
    clean = trim(clean)

    if SAB_DB[clean] then return SAB_DB[clean] end
    -- Also try the raw lowercase question directly
    local raw = trim(l:gsub("[%?%.%,!]", ""):gsub("%s+", " "))
    if SAB_DB[raw] then return SAB_DB[raw] end

    -- Fuzzy: convert written ordinals to digits so "fifth mutation" also matches "5th mutation"
    local ordinals = {one=1,two=2,three=3,four=4,five=5,six=6,seven=7,eight=8,nine=9,ten=10,
                      eleven=11,twelve=12,thirteen=13,fourteen=14,fifteen=15,sixteen=16,seventeen=17,eighteen=18}
    local numwords  = {first=1,second=2,third=3,fourth=4,fifth=5,sixth=6,seventh=7,eighth=8,ninth=9,tenth=10,
                       eleventh=11,twelfth=12,thirteenth=13,fourteenth=14,fifteenth=15,sixteenth=16,seventeenth=17,eighteenth=18}
    local suffixes  = {[1]="1st",[2]="2nd",[3]="3rd"}
    local function ord(n) return suffixes[n] or (n.."th") end

    -- replace "fifth mutation" â†’ "5th mutation" etc.
    local conv = clean
    for word, n in pairs(numwords) do
        conv = conv:gsub("%f[%a]"..word.."%f[%A]", ord(n))
    end
    for word, n in pairs(ordinals) do
        conv = conv:gsub("%f[%a]"..word.."%f[%A]", tostring(n))
    end
    if conv ~= clean and SAB_DB[conv] then return SAB_DB[conv] end

    -- Fuzzy: "mutation 5" â†’ try "5th mutation" style too
    local kind, num2 = conv:match("^(.-)%s+(%d+)$")
    if kind and num2 then
        local alt = ord(tonumber(num2)).." "..trim(kind)
        if SAB_DB[alt] then return SAB_DB[alt] end
    end
    local num3, kind2 = conv:match("^(%d+)%s+(.-)$")
    if num3 and kind2 then
        local alt = ord(tonumber(num3)).." "..trim(kind2)
        if SAB_DB[alt] then return SAB_DB[alt] end
    end

    return nil
    -- NOTE: NO broad substring scan here â€” that caused wrong instant answers.
    -- Groq AI handles everything that isn't an exact key match.
end

-- â”€â”€ Groq AI (Llama 3.3 70B) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local AI_SYSTEM = table.concat({
    "You are a riddle-answering bot for the Roblox game STEAL A BRAINROT (SAB).",
    "",
    "=== CRITICAL OUTPUT RULES â€” NEVER BREAK THESE ===",
    "1. Reply with ONE single word in ALL CAPS. NOTHING else. No punctuation.",
    "2. NEVER include spaces. Write HEADLESSHORSEMAN not HEADLESS HORSEMAN.",
    "3. NEVER repeat the answer. Return the BASE answer exactly once, even if the question says 'X times'. The system handles repetition.",
    "4. NEVER spell out numbers as words. If the answer is a number, write it as digits: 24 not TWENTYFOUR, 2025 not TWOTHOUSANDTWENTYFIVE.",
    "5. No explanation, no extra text, just the single answer word.",
    "",
    "=== CONTEXT â€” EVERY QUESTION IS ABOUT THIS GAME OR ITS OWNER ===",
    "All personal questions ('my X', 'the owner X', 'sammy X', 'how old am i') refer to the game owner SAMMY (SpyderSammy).",
    "There are NO exceptions. If the question seems personal, it is ALWAYS about SAMMY.",
    "",
    "=== OWNER: SAMMY (SpyderSammy / Sam Brakta) ===",
    "Real name: SAMMY",
    "Roblox username: SPYDERSAMMY",
    "Age: 24 | Birth year: 2001 | Born day: FRIDAY | Birth month: JANUARY",
    "Country: BRAZIL | State+City: SAOPAULO | Nationality: BRAZILIAN",
    "Favorite color: BLUE | Favorite sport: FOOTBALL | Favorite food: PIZZA",
    "Favorite football player: RONALDO | Favorite animal: SPIDER",
    "YouTube/Twitter/TikTok/Instagram: SPYDERSAMMY",
    "Favorite number: SEVEN",
    "",
    "=== GAME INFO ===",
    "Full name: STEALABRAINROT | Short: SAB | Genre: SIMULATOR",
    "Release date: MAY 16 2025 | Release day: FRIDAY | Release month: MAY | Release year: 2025",
    "Year created: 2025 | Max server size: EIGHT players",
    "First trait ever added: LIGHTNING | Trait you get from lightning strike: MATEO",
    "Total mutations: THIRTEEN | Total machines: EIGHTEEN | Total rarities: SIX",
    "",
    "=== RARITIES (lowest to highest) ===",
    "COMMON < UNCOMMON < RARE < EPIC < LEGENDARY < OG",
    "Highest/rarest rarity: OG | Lowest: COMMON",
    "Rarest/best/unobtainable brainrot: HEADLESSHORSEMAN",
    "Most popular brainrot: SKIBIDITOILET",
    "Worst brainrot: (if asked 'worst brainrot' â†’ HEADLESSHORSEMAN is unobtainable, common answer is SKIBIDITOILET for most common)",
    "",
    "=== OG BRAINROTS (order added) ===",
    "1st: STRAWBERRYELEPHANT | 2nd: MEOWL | 3rd: SKIBIDITOILET | 5th: JOHNPORK",
    "Unobtainable OG: HEADLESSHORSEMAN",
    "",
    "=== MUTATIONS (numbered order) ===",
    "1=GOLD 2=DIAMOND 3=BLOODROT 4=RAINBOW 5=CANDY 6=LAVA 7=GALAXY",
    "8=YINYANG 9=RADIOACTIVE 10=CURSED 11=DIVINE 12=CYBER 13=PHANTOM 14=CRYSTAL",
    "Newest/last mutation: CRYSTAL",
    "Evil mutation: CURSED | Angelic/good mutation: DIVINE",
    "Evil first combo: CURSEDDIVINE | Angelic first combo: DIVINECURSED",
    "",
    "=== MUTATION COLORS ===",
    "Green=RADIOACTIVE | Purple=GALAXY | Black or Black+White=YINYANG | Yellow=DIVINE | Red=CURSED | Orange=LAVA",
    "",
    "=== MACHINES (numbered order) ===",
    "1=RAINBOWMACHINE 2=BUBBLEGUMMACHINE 3=FUSEMACHINE 4=CRAFTMACHINE 5=WITCHFUSE",
    "6=BRAINROTDEALER 7=BRAINROTTRADER 8=SANTASFUSE 9=SANTASSHOP 10=NEWYEARSMACHINE",
    "11=DUELSMACHINE 12=CUPIDSMACHINE 13=TRADEMACHINE 14=DIVINEFUSE 15=EGGINCUBATOR",
    "16=CYBERCRAFTMACHINE 17=SUMMERFUSE 18=LOSTRADERS",
    "Newest/last machine: LOSTRADERS",
    "",
    "=== TRIVIA ===",
    "Fire represents: DRAGON | World Cup winner: ARGENTINA",
    "Worst/most boring game owner: SECRETLOKII | Most boring Roblox game: KEYBOARDESCAPE",
    "Brainrot spawned during admin abuse war: RACOONINIJANDELINI",
    "Who Sammy fought in admin abuse war: JANDEL | Who won admin abuse war: GROWAGARDEN",
    "Worst secret: KARKERKARKURKUR | Brother of Hydra Bunny: CERBERUS",
    "Brother of Hydra Bunny: CERBERUS",
    "",
    "=== EXAMPLE Q&A ===",
    "Q: what is my favorite color â†’ A: BLUE",
    "Q: who made this game â†’ A: SAMMY",
    "Q: what mutation turns you green â†’ A: RADIOACTIVE",
    "Q: what is the 7th machine â†’ A: BRAINROTTRADER",
    "Q: what year was sab created â†’ A: 2025",
    "Q: what is the rarest brainrot â†’ A: HEADLESSHORSEMAN",
    "Q: what is the worst brainrot â†’ A: HEADLESSHORSEMAN",
    "Q: what is the evil mutation â†’ A: CURSED",
    "Q: my favorite color (DO NOT repeat it, just say once) â†’ A: BLUE",
}, "\n")

-- queryAI: returns answer (string|nil), nil, errMsg (string|nil)
-- Uses Groq (api.groq.com).
-- statusCb(msg): optional callback to push live status lines to the console
local function queryAI(question, statusCb)
    local function stat(msg) if statusCb then statusCb(msg) end end

    if not httpRequest then
        return nil, nil, "no http executor (syn.request / http_request not found)"
    end
    if not GROQ_API_KEY or GROQ_API_KEY == "" then
        return nil, nil, "GROQ_API_KEY is empty"
    end

    stat("calling AIâ€¦")

    local body = HttpService:JSONEncode({
        model    = "llama-3.3-70b-versatile",
        messages = {
            { role = "system", content = AI_SYSTEM },
            {
                role    = "user",
                content = "/no_think\n" .. tostring(question)
                    .. "\n\nRules: ONE word, ALL CAPS, NO spaces, NO repetition, NO spelling out numbers (write 2025 not TWOTHOUSANDTWENTYFIVE). Just the answer.",
            },
        },
        temperature = 0,
        max_tokens  = 64,
    })

    local ok, res = pcall(httpRequest, {
        Url     = "https://api.groq.com/openai/v1/chat/completions",
        Method  = "POST",
        Headers = {
            ["Content-Type"]  = "application/json",
            ["Authorization"] = "Bearer " .. GROQ_API_KEY,
        },
        Body = body,
    })

    if not ok then
        return nil, nil, "http_err: " .. tostring(res):sub(1, 100)
    end
    if not res or not res.Body then
        return nil, nil, "empty body (HTTP " .. tostring(res and res.StatusCode or "?") .. ")"
    end

    local sc = tonumber(res.StatusCode)
    if sc and sc ~= 200 then
        local bOk, bP = pcall(HttpService.JSONDecode, HttpService, res.Body)
        local detail = (bOk and bP and bP.error and bP.error.message)
            or res.Body:sub(1, 120)
        return nil, nil, ("HTTP %d: %s"):format(sc, tostring(detail):gsub("\n", " "))
    end

    local pOk, parsed = pcall(HttpService.JSONDecode, HttpService, res.Body)
    if not pOk or not parsed then
        return nil, nil, "JSON parse failed: " .. res.Body:sub(1, 80)
    end
    if parsed.error then
        return nil, nil, "API: " .. (parsed.error.message or "unknown error"):sub(1, 120)
    end

    local choice = parsed.choices and parsed.choices[1]
    if not choice then
        return nil, nil, "no choices in response"
    end

    local answer = (choice.message and choice.message.content) or ""
    answer = trim(answer):upper():gsub("[%s%?%.%,!\"'`\n\r]+", "")
    if answer == "" then
        return nil, nil, "empty answer from model"
    end
    -- Strip any "PREFIX:ANSWER" pattern â€” take only what's after the last colon
    if answer:find(":") then
        answer = answer:match(":([^:]+)$") or answer
    end
    -- Model dumps reasoning before the answer (e.g. "THEUSERISASKING...SODIVINE").
    -- Find which known SAB answer the blob ends with â€” longest match wins.
    if #answer > 25 then
        local best = nil
        for _, v in pairs(SAB_DB) do
            local clean = v:upper():gsub("%s+","")
            if #clean > 0 and answer:sub(-#clean) == clean then
                if not best or #clean > #best then best = clean end
            end
        end
        answer = best or answer:sub(-25)
    end
    return answer, nil, nil
end

local function extractNumber(text)
    for num in text:gmatch("%d+") do
        local n = tonumber(num)
        if n and n > 13 then return num end
    end
    return nil
end

local function splitByAnd(text)
    local parts = {}
    local clean = text:gsub("%s*%d+%s*$", "")
    -- treat "add" the same as "and" so "2nd mutation add 67" works like "2nd mutation and 67"
    clean = clean:gsub("%s+add%s+", " and ")
    for part in (clean .. " and "):gmatch("(.-)%s+and%s+") do
        part = trim(part)
        if part ~= "" then parts[#parts + 1] = part end
    end
    if #parts == 0 then parts[1] = trim(clean) end
    return parts
end

local function extractTimesMultiplier(text)
    local l = text:lower()
    if l:find("twice")  then return 2 end
    if l:find("thrice") then return 3 end
    local n = l:match("(%d+)%s*times")
    if n then
        n = tonumber(n)
        if n and n >= 2 and n <= 10 then return n end
    end
    return nil
end

-- Strip "N times / twice / thrice" text from a question before sending to Groq.
-- The CODE handles repetition â€” Groq must only return the base answer once.
local function stripMultiplierText(text)
    local s = text
    s = s:gsub("%s*%d+%s*[Tt]imes%s*", " ")
    s = s:gsub("%s*[Tt]wice%s*",        " ")
    s = s:gsub("%s*[Tt]hrice%s*",       " ")
    s = trim(s)
    if s == "" then s = text end   -- safety: don't send empty string
    return s
end

-- Strip trailing standalone number from a question (e.g. "favorite color 67" â†’ "favorite color").
-- This prevents Groq seeing a bare number it might spell out as text.
local function stripTrailingNumber(text)
    return trim(text:gsub("%s+%d+%s*$", ""))
end

-- Split on commas and "and"/"add". Strip filler like "at the end".
local function splitAllParts(text)
    local clean = text or ""
    clean = clean:gsub("%s+add%s+", " and ")
    clean = clean:gsub("%s*,%s*", " and ")
    clean = clean:gsub("%s+at%s+the%s+end", " ")
    clean = clean:gsub("%s+at%s+the%s+start", " ")
    clean = clean:gsub("%s+at%s+the%s+beginning", " ")
    local parts = {}
    for part in (clean .. " and "):gmatch("(.-)%s+and%s+") do
        part = trim(part)
        if part ~= "" then
            parts[#parts + 1] = part
        end
    end
    if #parts == 0 then
        parts[1] = trim(text or "")
    end
    return parts
end

-- DB first. AI only if not in DB. Numbers kept as-is. Never paste question text.
local function resolvePart(part, statusCb)
    local multiplier = extractTimesMultiplier(part)
    local q = stripMultiplierText(part)
    q = stripTrailingNumber(q)
    q = q:gsub("%s+at%s+the%s+end%s*$", "")
    q = q:gsub("%s+at%s+the%s+start%s*$", "")
    q = trim(q)
    if q == "" then return nil end

    -- pure number
    local onlyNum = q:match("^%d+$")
    if onlyNum then
        return multiplier and string.rep(onlyNum, multiplier) or onlyNum
    end

    local a = localExactAnswer(q)
    if not a then
        -- AI only when DB misses
        if statusCb then statusCb("AI: " .. q:sub(1, 40)) end
        a = select(1, queryAI(q, statusCb))
    end
    if not a then return nil end

    local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
    -- never allow leftover instruction words in the answer
    if clean:find("ATTHEEND") or clean:find("ATTHESTART") or clean == "AND" then
        return nil
    end
    if clean == "" then return nil end
    return multiplier and string.rep(clean, multiplier) or clean
end

local function solveRiddle(text, statusCb)
    local suffix = extractNumber(text)
    local parts = splitAllParts(text)
    local answers = {}

    for _, part in ipairs(parts) do
        local ok, result = pcall(resolvePart, part, statusCb)
        if ok and result and result ~= "" then
            answers[#answers + 1] = result
        end
    end

    if #answers == 0 then
        -- full question to AI as last resort
        if statusCb then statusCb("AI full question") end
        local a = select(1, queryAI(stripTrailingNumber(text), statusCb))
        if a then
            local clean = tostring(a):upper():gsub("%s+", ""):gsub("[%?%.%,!\"'`]", "")
            clean = clean:gsub("ATTHEEND", ""):gsub("ATTHESTART", "")
            if suffix and clean:sub(-#suffix) ~= suffix then
                clean = clean .. suffix
            end
            return clean, nil, nil
        end
        return nil, nil, "no answer"
    end

    local out = table.concat(answers, "")
    if suffix and out:sub(-#suffix) ~= suffix then
        out = out .. suffix
    end
    return out, nil, nil
end

-- â”€â”€ Colours & helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local C = {
    bg     = Color3.fromRGB(13,17,23),   bgDeep = Color3.fromRGB(9,12,16),
    panel  = Color3.fromRGB(22,27,34),   panel2 = Color3.fromRGB(30,37,46),
    line   = Color3.fromRGB(45,54,66),
    acc    = Color3.fromRGB(248,113,113), acc2  = Color3.fromRGB(239,68,68),
    accHi  = Color3.fromRGB(252,165,165),
    txt    = Color3.fromRGB(230,237,243), sub   = Color3.fromRGB(125,139,156),
    ok     = Color3.fromRGB(74,222,128),  err   = Color3.fromRGB(248,113,113),
    warn   = Color3.fromRGB(250,204,21),  input = Color3.fromRGB(11,15,20),
    think  = Color3.fromRGB(90,105,125),
}
local FR, FM, FB, FBK = Enum.Font.Gotham, Enum.Font.GothamMedium, Enum.Font.GothamBold, Enum.Font.GothamBlack

local function new(cls, props, parent)
    local o = Instance.new(cls)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r or 6) }, o) end
local function stroke(o, col, th, tr) return new("UIStroke", { Color = col or C.line, Thickness = th or 1, Transparency = tr or 0 }, o) end
local function tween(o, t, goal, style) TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad), goal):Play() end
local function gradient(o, c1, c2, rot) return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 90 }, o) end
local function label(text, size, col, font, xa, parent)
    return new("TextLabel", {
        BackgroundTransparency = 1, Text = text, Font = font or FM, TextSize = size or 10,
        TextColor3 = col or C.txt, TextXAlignment = xa or Enum.TextXAlignment.Left,
    }, parent)
end
local function drag(handle, target)
    local d, ds, sp
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            d, ds, sp = true, i.Position, target.Position
            i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then d = false end end)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if d and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
            local delta = i.Position - ds
            target.Position = UDim2.new(sp.X.Scale, sp.X.Offset + delta.X, sp.Y.Scale, sp.Y.Offset + delta.Y)
        end
    end)
end

local function ghostBtn(text, parent)
    local b = new("TextButton", {
        BackgroundColor3 = C.panel2, Text = text, Font = FB, TextSize = 10, TextColor3 = C.txt,
        AutoButtonColor = false, BorderSizePixel = 0,
    }, parent)
    corner(b, 6); local s = stroke(b, C.line, 1, 0.2)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.panel }); tween(s, 0.12, { Color = C.acc, Transparency = 0 }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.panel2 }); tween(s, 0.12, { Color = C.line, Transparency = 0.2 }) end)
    return b
end
local function accentBtn(text, parent)
    local b = new("TextButton", {
        BackgroundColor3 = C.acc, Text = text, Font = FBK, TextSize = 11, TextColor3 = Color3.fromRGB(20,6,6),
        AutoButtonColor = false, BorderSizePixel = 0,
    }, parent)
    corner(b, 6); gradient(b, C.acc2, C.acc, 90)
    b.MouseEnter:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.accHi }) end)
    b.MouseLeave:Connect(function() tween(b, 0.12, { BackgroundColor3 = C.acc }) end)
    return b
end


-- Riddle-only GUI
if not parentGui then error("[RiddleSolver] Could not locate a valid GUI parent") end
local old = parentGui:FindFirstChild("AceRiddle") or parentGui:FindFirstChild("AceRiddleSolver")
if old then old:Destroy() end

local SG = new("ScreenGui", {
    Name = "AceRiddle",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 250,
}, parentGui)

local Main = new("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(260, 340),
    Position = UDim2.new(1, -280, 0.5, -170),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    Active = true,
    ClipsDescendants = true,
}, SG)
corner(Main, 12)
gradient(Main, Color3.fromRGB(18,23,30), Color3.fromRGB(11,14,19), 90)
stroke(Main, C.acc, 1.2, 0.5)

local head = new("Frame", {
    Size = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, Main)
corner(head, 12)
new("Frame", {
    Size = UDim2.new(1,0,0,12),
    Position = UDim2.new(0,0,1,-12),
    BackgroundColor3 = C.panel,
    BorderSizePixel = 0,
}, head)

local logo = new("Frame", {
    Size = UDim2.fromOffset(16,16),
    Position = UDim2.new(0,10,0.5,-8),
    BackgroundColor3 = C.acc,
    BorderSizePixel = 0,
}, head)
corner(logo, 5)
gradient(logo, C.acc2, C.acc, 45)
stroke(logo, C.accHi, 1, 0.4)

local brand = label("Ace Riddle", 12, C.txt, FBK, Enum.TextXAlignment.Left, head)
brand.Size = UDim2.new(0, 150, 0, 16)
brand.Position = UDim2.fromOffset(34, 5)

local sublbl = label("OFF — toggle to start", 8, C.sub, FM, Enum.TextXAlignment.Left, head)
sublbl.Size = UDim2.new(0, 170, 0, 10)
sublbl.Position = UDim2.fromOffset(34, 23)
drag(head, Main)

local liveDot = new("Frame", {
    Size = UDim2.fromOffset(6,6),
    Position = UDim2.new(1,-72,0.5,-3),
    BackgroundColor3 = C.sub,
    BorderSizePixel = 0,
}, head)
corner(liveDot, 3)

local enabled = false

local toggleBtn = new("TextButton", {
    Size = UDim2.fromOffset(40, 20),
    Position = UDim2.new(1, -66, 0.5, -10),
    BackgroundColor3 = C.panel2,
    Text = "OFF",
    Font = FBK,
    TextSize = 10,
    TextColor3 = C.sub,
    AutoButtonColor = false,
    BorderSizePixel = 0,
}, head)
corner(toggleBtn, 5)
local toggleStroke = stroke(toggleBtn, C.line, 1, 0.2)

local function setEnabled(state)
    enabled = state
    if enabled then
        toggleBtn.Text = "ON"
        toggleBtn.TextColor3 = Color3.fromRGB(20, 40, 20)
        toggleBtn.BackgroundColor3 = C.ok
        toggleStroke.Color = C.ok
        toggleStroke.Transparency = 0
        sublbl.Text = "ON — auto solving"
        sublbl.TextColor3 = C.ok
        liveDot.BackgroundColor3 = C.ok
    else
        toggleBtn.Text = "OFF"
        toggleBtn.TextColor3 = C.sub
        toggleBtn.BackgroundColor3 = C.panel2
        toggleStroke.Color = C.line
        toggleStroke.Transparency = 0.2
        sublbl.Text = "OFF — toggle to start"
        sublbl.TextColor3 = C.sub
        liveDot.BackgroundColor3 = C.sub
    end
end

toggleBtn.MouseButton1Click:Connect(function()
    setEnabled(not enabled)
end)

local closeBtn = ghostBtn("X", head)
closeBtn.Size = UDim2.fromOffset(20,20)
closeBtn.Position = UDim2.new(1,-24,0.5,-10)
closeBtn.TextSize = 10
closeBtn.MouseButton1Click:Connect(function()
    if env.StopRiddleSolver then
        env.StopRiddleSolver()
    else
        SG:Destroy()
    end
end)

local riddlePage = new("Frame", {
    Name = "RIDDLE",
    Size = UDim2.new(1,-16,1,-58),
    Position = UDim2.fromOffset(8,50),
    BackgroundTransparency = 1,
}, Main)

-- â”€â”€ RIDDLE TAB â€” console style with Gemini thinking display â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
local RC = {
    dim   = "rgb(125,139,156)",
    white = "rgb(230,237,243)",
    green = "rgb(74,222,128)",
    amber = "rgb(250,204,21)",
    red   = "rgb(248,113,113)",
    think = "rgb(90,105,125)",
    cyan  = "rgb(100,200,255)",
}

local riddleTopBar = new("Frame", {
    Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1, LayoutOrder = 0,
}, riddlePage)
local rCount = label("0 solved", 9, C.sub, FB, Enum.TextXAlignment.Left, riddleTopBar)
rCount.Size = UDim2.new(0.55,0,1,0); rCount.Position = UDim2.new(0,0,0,0)
local rClear = ghostBtn("CLEAR", riddleTopBar)
rClear.Size = UDim2.fromOffset(42,18); rClear.Position = UDim2.new(1,-42,0.5,-9); rClear.TextSize = 8

local riddleConsole = new("ScrollingFrame", {
    Name = "RiddleConsole",
    Size = UDim2.new(1,0,1,-27),
    Position = UDim2.new(0,0,0,27),
    BackgroundColor3 = C.input, BorderSizePixel = 0,
    ScrollBarThickness = 2, ScrollBarImageColor3 = C.acc, ScrollBarImageTransparency = 0.3,
    CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.None,
    ScrollingDirection = Enum.ScrollingDirection.Y, ClipsDescendants = true,
}, riddlePage)
corner(riddleConsole, 6); stroke(riddleConsole, C.line, 1, 0.3)

local riddleOutput = new("TextLabel", {
    Name = "RiddleOutput",
    Size = UDim2.new(1,-12,0,0), AutomaticSize = Enum.AutomaticSize.Y,
    Position = UDim2.fromOffset(6,5),
    BackgroundTransparency = 1, RichText = true,
    Text = '<font color="' .. RC.dim .. '">waiting for riddlesâ€¦</font>',
    TextSize = 11, Font = Enum.Font.Code,
    TextColor3 = C.txt, TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top, TextWrapped = true, ZIndex = 4,
}, riddleConsole)

local function scrollRiddleToBottom()
    task.defer(function()
        task.wait()
        if not riddleConsole or not riddleOutput then return end
        local contentH = riddleOutput.AbsoluteSize.Y + 12
        riddleConsole.CanvasSize = UDim2.new(0,0,0,contentH)
        local bottom = math.max(0, contentH - riddleConsole.AbsoluteSize.Y)
        riddleConsole.CanvasPosition = Vector2.new(0, bottom)
    end)
end
riddleOutput:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    local contentH = riddleOutput.AbsoluteSize.Y + 12
    riddleConsole.CanvasSize = UDim2.new(0,0,0,contentH)
end)

local riddleCount = 0

local function appendRiddle(richLine)
    if riddleOutput.Text:find("waiting for riddles") then
        riddleOutput.Text = richLine
    else
        riddleOutput.Text = riddleOutput.Text .. "\n" .. richLine
    end
    scrollRiddleToBottom()
end

-- Returns { updateStatus(msg), setFinal(answerText, thinkingText, errMsg) }
-- updateStatus: replaces the last "status" line in-place (live progress)
-- setFinal:     writes the definitive answer (or error) and stops the animation
local function addRiddleLog(question)
    riddleCount += 1
    rCount.Text = riddleCount .. " asked"
    local ts = os.date("%H:%M:%S")

    appendRiddle(
        '<font color="' .. RC.dim .. '">[' .. ts .. ']</font> '
        .. '<font color="' .. RC.amber .. '">Q:</font> '
        .. '<font color="' .. RC.white .. '">' .. question:sub(1, 90) .. '</font>'
    )
    -- Status line (index tracked so we can update it in-place)
    appendRiddle('<font color="' .. RC.dim .. '">   âŸ³ thinkingâ€¦</font>')

    local alive = true
    -- Dot animation
    task.spawn(function()
        local dots = 0
        while alive do
            task.wait(0.45)
            if not alive then break end
            dots = (dots % 3) + 1
            local lines = {}
            for ln in riddleOutput.Text:gmatch("[^\n]+") do lines[#lines+1] = ln end
            -- Only animate if last line is still the status indicator
            if #lines > 0 and lines[#lines]:find("âŸ³") then
                lines[#lines] = '<font color="' .. RC.dim .. '">   âŸ³ thinking' .. string.rep(".", dots) .. '</font>'
                riddleOutput.Text = table.concat(lines, "\n")
                scrollRiddleToBottom()
            end
        end
    end)

    -- Replace the last status line with new text
    local function replaceLastLine(richText)
        local lines = {}
        for ln in riddleOutput.Text:gmatch("[^\n]+") do lines[#lines+1] = ln end
        if #lines > 0 then
            lines[#lines] = richText
        else
            lines[1] = richText
        end
        riddleOutput.Text = table.concat(lines, "\n")
        scrollRiddleToBottom()
    end

    -- updateStatus: push a live progress message (replaces the âŸ³ line)
    local function updateStatus(msg)
        replaceLastLine('<font color="' .. RC.dim .. '">   âŸ³ ' .. tostring(msg) .. '</font>')
    end

    -- setFinal: called when we have the answer (or an error)
    local function setFinal(answerText, thinkingText, errMsg)
        alive = false
        task.defer(function()
            task.wait()
            if answerText then
                replaceLastLine('<font color="' .. RC.green .. '">   â†’ ' .. tostring(answerText) .. '</font>')
                -- Thinking summary on its own line
                if thinkingText and #thinkingText > 0 then
                    local preview = thinkingText:sub(1, 150):gsub("\n", " "):gsub("%s+", " ")
                    if #thinkingText > 150 then preview = preview .. "â€¦" end
                    appendRiddle('<font color="' .. RC.cyan .. '">   [AI] </font><font color="' .. RC.think .. '">' .. preview .. '</font>')
                end
            else
                -- Show the actual error so the user knows what went wrong
                local msg = errMsg and tostring(errMsg):sub(1, 120) or "no answer"
                replaceLastLine('<font color="' .. RC.red .. '">   âœ— ERR: ' .. msg .. '</font>')
            end
            rCount.Text = riddleCount .. " solved"
            scrollRiddleToBottom()
        end)
    end

    return updateStatus, setFinal
end

rClear.MouseButton1Click:Connect(function()
    riddleOutput.Text = '<font color="' .. RC.dim .. '">waiting for riddlesâ€¦</font>'
    riddleCount = 0; rCount.Text = "0 solved"
    riddleConsole.CanvasPosition = Vector2.new(0,0)
    riddleConsole.CanvasSize = UDim2.new(0,0,0,0)
end)


-- Answer submission
local function getGameCodeBox()
    if not LP then return nil end
    local pg = LP:FindFirstChildOfClass("PlayerGui")
    if not pg then return nil end
    local gui = pg:FindFirstChild("Codes")
    if not gui then return nil end
    local root = gui:FindFirstChild("Codes") or gui
    local redeem = root:FindFirstChild("CodeRedeem")
    local box = redeem and redeem:FindFirstChild("TextBox")
    if box and box:IsA("TextBox") then return box end
    for _, item in ipairs(gui:GetDescendants()) do
        if item:IsA("TextBox") then return item end
    end
end

local function fireConnections(signal, ...)
    if typeof(getconns) ~= "function" then return false end
    local ok, connections = pcall(getconns, signal)
    if not ok or type(connections) ~= "table" then return false end
    local args = table.pack(...)
    local fired = false
    for _, connection in ipairs(connections) do
        local fireOk = pcall(function()
            if connection.Enabled ~= false then
                if args.n > 0 then
                    connection:Fire(table.unpack(args, 1, args.n))
                else
                    connection:Fire(true)
                end
            end
        end)
        fired = fired or fireOk
    end
    return fired
end

local function unfocusBox(box)
    -- Aggressively release focus so camera/controls aren't stuck
    pcall(function() box:ReleaseFocus(false) end)
    pcall(function()
        if typeof(UserInputService) == "Instance" or UserInputService then
            -- nothing; just ensure we don't hold focus
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            -- click slightly off the box to force blur
            vim:SendMouseButtonEvent(0, 0, 0, true, game, 0)
            task.wait(0.03)
            vim:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        end
    end)
    pcall(function()
        if typeof(keypress) == "function" then
            keypress(0x1B) -- Escape
            task.wait(0.03)
            if typeof(keyrelease) == "function" then keyrelease(0x1B) end
        end
    end)
    pcall(function() box:ReleaseFocus(false) end)
end

local function submitAnswer(answer)
    local box = getGameCodeBox()
    if not box then return false, "code box not found" end

    answer = tostring(answer or ""):upper():gsub("%s+", "")
    if answer == "" then return false, "empty answer" end

    -- STEP 1: TYPE and wait until it sticks
    pcall(function() box:CaptureFocus() end)
    task.wait(0.06)
    box.Text = ""
    task.wait(0.04)
    box.Text = answer

    local typed = false
    for _ = 1, 12 do
        task.wait(0.05)
        if box.Text == answer then typed = true break end
        box.Text = answer
    end
    if not typed then
        box.Text = answer
        task.wait(0.12)
    end
    task.wait(0.15)

    -- STEP 2: submit / enter
    local submitted = false
    if fireConnections(box.FocusLost, true) then submitted = true end
    task.wait(0.05)

    pcall(function()
        if typeof(keypress) == "function" then
            keypress(0x0D)
            task.wait(0.05)
            if typeof(keyrelease) == "function" then keyrelease(0x0D) end
            submitted = true
        end
    end)
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if vim then
            vim:SendKeyEvent(true, Enum.KeyCode.Return, false, game)
            task.wait(0.05)
            vim:SendKeyEvent(false, Enum.KeyCode.Return, false, game)
            submitted = true
        end
    end)
    task.wait(0.05)

    pcall(function()
        local parent = box.Parent
        if not parent then return end
        local roots = { parent }
        local n = parent
        while n and n.Name ~= "Codes" and n.Parent do n = n.Parent end
        if n then roots[#roots + 1] = n end
        for _, root in ipairs(roots) do
            for _, child in ipairs(root:GetDescendants()) do
                if child:IsA("TextButton") or child:IsA("ImageButton") then
                    local t = ((child.Text or "") .. (child.Name or "")):lower()
                    if t:find("redeem") or t:find("submit") or t:find("enter") or t:find("claim") then
                        fireConnections(child.MouseButton1Click)
                        pcall(function() child:Activate() end)
                        submitted = true
                        return
                    end
                end
            end
        end
    end)

    -- STEP 3: unfocus immediately so you aren't stuck in the text box
    task.wait(0.05)
    unfocusBox(box)

    return true, submitted and "answer submitted" or "answer typed"
end

local POSITIONS = {
    Top=true, Bottom=true, Center=true, Middle=true, Left=true, Right=true,
    TopRight=true, TopLeft=true, BottomRight=true, BottomLeft=true,
}

local function looksLikeAnnouncement(...)
    local args = table.pack(...)
    if args.n == 0 or typeof(args[1]) ~= "string" then return false end
    for i = 2, args.n do
        local value = args[i]
        if typeof(value) == "string"
            and (value:find("Sounds%.") or value:find("rbxassetid") or POSITIONS[value])
        then
            return true
        end
    end
    return false
end

local solving = false
local function onAnnouncement(...)
    if not enabled then return end
    local text = stripRich(tostring((...) or ""))
    if text == "" or solving then return end

    solving = true
    task.spawn(function()
        local updateStatus, setFinal = addRiddleLog(text)
        local answer, thinking, errMsg = solveRiddle(text, updateStatus)

        if answer then
            answer = answer:upper():gsub("%s+", "")
            local _, submitMessage = submitAnswer(answer)
            setFinal(answer, thinking, nil)
            if submitMessage then
                appendRiddle('<font color="' .. RC.dim .. '">   ' .. submitMessage .. '</font>')
            end
        else
            setFinal(nil, nil, errMsg or "no answer found in DB or AI")
        end
        solving = false
    end)
end

local function resolveNotifyRemote()
    local ok, controller = pcall(function()
        if not ReplicatedStorage then return end
        local controllers = ReplicatedStorage:FindFirstChild("Controllers")
        local notification = controllers and controllers:FindFirstChild("NotificationController", true)
        if notification then return require(notification) end
    end)

    if ok and type(controller) == "table" and type(controller.Start) == "function"
        and typeof(getupvalues) == "function"
    then
        local valuesOk, values = pcall(getupvalues, controller.Start)
        if valuesOk and type(values) == "table" then
            for _, value in pairs(values) do
                if typeof(value) == "Instance"
                    and (value:IsA("RemoteEvent")
                        or value:IsA("RemoteFunction")
                        or value:IsA("UnreliableRemoteEvent"))
                then
                    return value
                end
            end
        end
    end
end

if env.StopRiddleSolver then pcall(env.StopRiddleSolver) end
local listenConn

task.spawn(function()
    local notifyRemote = resolveNotifyRemote()
    if notifyRemote
        and (notifyRemote:IsA("RemoteEvent") or notifyRemote:IsA("UnreliableRemoteEvent"))
    then
        listenConn = notifyRemote.OnClientEvent:Connect(function(...)
            if looksLikeAnnouncement(...) then
                pcall(onAnnouncement, ...)
            end
        end)
        appendRiddle('<font color="' .. RC.green .. '">listener ready — press ON to start</font>')
    else
        liveDot.BackgroundColor3 = C.err
        appendRiddle('<font color="' .. RC.red .. '">notify remote not found</font>')
    end
end)

env.StopRiddleSolver = function()
    if listenConn then
        pcall(function() listenConn:Disconnect() end)
        listenConn = nil
    end
    if SG then SG:Destroy() end
end

print("[Ace Riddle] loaded — press ON to start")
