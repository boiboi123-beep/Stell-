local UIRefs={} -- UI references share one top-level register.
-- Starfire MM2: standalone client UI using standard Roblox APIs.
-- Role discovery observes replicated Knife/Gun tools; it cannot reveal unreplicated roles.
-- No downloaded code or runtime installation. Optional silent aim needs nonstandard hooks; knife sweep uses normal Tool activation.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
assert(player, "Starfire must run on the client")
local playerGui = player:WaitForChild("PlayerGui")
local previous = playerGui:FindFirstChild("StarfireMM2")
if previous then
    local event = previous:FindFirstChild("Cleanup")
    if event and event:IsA("BindableEvent") then event:Fire() end
    previous:Destroy()
end

local colors = {
    background = Color3.fromRGB(25, 26, 37), panel = Color3.fromRGB(34, 35, 45),
    raised = Color3.fromRGB(28, 29, 39), purple = Color3.fromRGB(190, 85, 255),
    text = Color3.fromRGB(250, 250, 255), muted = Color3.fromRGB(212, 212, 225),
    border = Color3.fromRGB(53, 53, 66), hover = Color3.fromRGB(42, 40, 56),
    accentPanel = Color3.fromRGB(38, 35, 52), headerGlow = Color3.fromRGB(31, 32, 41),
    murderer = Color3.fromRGB(255, 80, 108), sheriff = Color3.fromRGB(71, 158, 255),
    innocent = Color3.fromRGB(84, 225, 143),
}
local settings = {
    droppedGunESP = true, sheriffDeathNotify = true, murdererESP = true, sheriffESP = true, innocentESP = true, names = true, throughWalls = true,
    opacity = 0.38, aim = false, fov = 220, responsiveness = 12, snapAim = true,
    freeGunCamera = true, silentAim = false, silentHitChance = 100, wallCheck = true, showFov = true, loopEmote = true, emoteSpeed = 1,
    coinCollect = false, collectSpeed = 40, collectDepth = 14, cursorTP = true, attackInterval = 0.6,
    noMurd = true, murdererDistance = 35, fullBagAction = false, useBagCapacity = false, bagCapacity = 50,
    knifeDodge = false, dodgeRadius = 12, proximityDodge = false, proximityDodgeRadius = 15,
    visualSpin = false, spinSpeed = 5,
    fly = false, flySpeed = 50, noclip = false,
    flingStrength = 360,
    candySweep = false, spawnRadius = 120,
    ghost = false, ghostOpacity = 0.42,
    ghostFloat = true, ghostFloatHeight = 0.8,
    ghostAnimationSpeed = 1,
    ghostBundleId = "100631627459825",
    scareSpeed = 30,
    avatarClone = false,
    gunCircle = true, gunCircleRadius = 28, gunCircleOpacity = 0.9,
    gunCircleRed = 190, gunCircleGreen = 85, gunCircleBlue = 255,
    speedEnabled = false, walkSpeed = 24,
    bubbleShot = false, bubbleShotVolume = 2, bubbleReloadVolume = 1.5,
    bulletTracers = false, tracerLife = 3, tracerWidth = 0.07, tracerRed = 190, tracerGreen = 85, tracerBlue = 255,
    gunViewSize = .45, gunMatchSize = true, contourOpacity = 1, contourRed = 8, contourGreen = 9, contourBlue = 12, wireContours = true, wireArms = false, wireKnife = false, wireRed = 255, wireGreen = 255, wireBlue = 255, wireWidth = 1, knifeSize = 1, knifeOffsetX = -0.08, knifeOffsetY = -0.03, knifeOffsetZ = 0, knifeSkin = 1, voidglassInventory = true, voidglassPitch = 90, voidglassYaw = 0, voidglassRoll = 70,
    pshade = false, pshadePreset = "midday", pshadeSky = "midday", pshadeReflectance = 0.15,
    pshadeBlur = false, pshadeMotion = false, pshadeDepth = false,
    glossyShaders = false, glossyReflectance = 0.65, glossyPlastic = false, glossyBloom = 0.3, glossySpecular = 1,
    ambience = false, ambienceTime = 18, ambienceBrightness = 2, ambienceExposure = 0,
    ambienceFog = true, ambienceFogStart = 40, ambienceFogEnd = 450,
    ambienceRed = 190, ambienceGreen = 85, ambienceBlue = 255,
    ambienceAtmosphere = true, ambienceDensity = 0.25, ambienceHaze = 1,
    ambienceBloom = true, ambienceBloomIntensity = 0.35,
    ambienceGrade = true, ambienceSaturation = 0.1, ambienceContrast = 0.1,
    ambienceSunRays = true, ambienceRayIntensity = 0.08,
    ambienceDepth = false, ambienceFocus = 45, ambienceFarBlur = 0.12,
    ambienceStars = 3000, ambienceCelestial = true,
    bunnyHop = false, bunnyGain = 5, bunnyMax = 80, jumpTrajectory = false, jumpTrailLife = 2.5,
    customArms = false, customArmX = 0, customArmY = 0, customArmZ = 0,
    gripArms = false, gripScale = 1, gripOffsetX = 0, gripOffsetY = -0.35, gripOffsetZ = 0.1,
    skinChanger = false, skinAssetId = "13913933689", skinKind = "Gun", skinScale = 1,
    skinPitch = 0, skinYaw = 0, skinRoll = 0, skinOffsetX = 0, skinOffsetY = 0, skinOffsetZ = 0,
}
local function manualGunMode()
    local character=player.Character
    local gun=character and character:FindFirstChild("Gun")
    return settings.freeGunCamera and gun and gun:IsA("Tool") or false
end
local defaultSettings = table.clone(settings)
local settingLimits, stateAppliers = {}, {}
local connections, entries, gunDrops = {}, {}, {}
local running, menuOpen, aiming = true, true, false
local track, animation, selectedTarget, drag, activeSlider
local cleanup
local stopCollecting
local Automation
local Evade
local Fling
local Scare
local AvatarClone
local Skins
local Inspect
local Voidglass
local GunAudio
local Ambience
local Glossy
local PShade
local BunnyHop
local GripArms
local JumpMotion
local GunViewmodel
local SilentAim
local WireStyle
local Tracers
local stopSweep
local sweepState
local stateRefreshers = {}
local collectibles = {}
local aimKey = Enum.UserInputType.MouseButton2
local captureAim = false
local aimBindButton
local gunKey, captureGun = Enum.KeyCode.O, false
local refreshGunBind
local responseKey, captureResponse = Enum.KeyCode.G, false
local refreshResponseBind
local ghostAnimationStatus
local cameraBinding = "StarfireMM2Camera_" .. tostring(player.UserId)
local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end
local function make(class, props, parent)
    local instance = Instance.new(class)
    for key, value in pairs(props or {}) do instance[key] = value end
    instance.Parent = parent
    return instance
end
local uiTweens = setmetatable({}, {__mode = "k"})
local function animate(object, properties, duration)
    if uiTweens[object] then uiTweens[object]:Cancel() end
    local tween = TweenService:Create(object, TweenInfo.new(duration or 0.18,
        Enum.EasingStyle.Quart, Enum.EasingDirection.Out), properties)
    uiTweens[object] = tween
    tween:Play()
    return tween
end
local function round(parent, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end
local function stroke(parent, color, transparency)
    return make("UIStroke", {Color = color or colors.raised, Thickness = 1,
        Transparency = transparency or 0}, parent)
end
local function label(parent, text, size, color)
    return make("TextLabel", {BackgroundTransparency = 1, Text = text,
        TextColor3 = color or colors.text, Font = Enum.Font.GothamBold,
        TextSize = size or 13, TextXAlignment = Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 22)}, parent)
end

local gui = make("ScreenGui", {Name = "StarfireMM2", ResetOnSpawn = false,
    IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 30}, playerGui)
local cleanupEvent = make("BindableEvent", {Name = "Cleanup"}, gui)
local effects = make("Folder", {Name = "StarfireMM2Effects_" .. player.UserId}, Workspace)
local fovCircle = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(440, 440),
    BackgroundTransparency = 1, Visible = false}, gui)
round(fovCircle, 10000)
stroke(fovCircle, colors.purple, 0.35)
local gunCircle = make("Frame", {Name = "GunTrackingCircle", AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(56, 56), BackgroundTransparency = 1, Visible = false}, gui)
round(gunCircle, 10000)
local gunCircleStroke = stroke(gunCircle, colors.purple, 0.1)
gunCircleStroke.Thickness = 2

local dodgeIndicator = make("TextLabel", {Name = "DodgeIndicator",
    AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.fromScale(0.5, 0.16),
    Size = UDim2.fromOffset(280, 40), BackgroundColor3 = colors.background,
    BackgroundTransparency = 0.12, BorderSizePixel = 0, Text = "knife dodge · at hub",
    Font = Enum.Font.GothamBold, TextSize = 15, TextColor3 = colors.purple,
    Visible = false, ZIndex = 20}, gui)
round(dodgeIndicator, 12)
stroke(dodgeIndicator, colors.purple, 0.25)

local window = make("CanvasGroup", {AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(760, 540),
    BackgroundColor3 = colors.background, BackgroundTransparency = 0.07, GroupTransparency = 1,
    BorderSizePixel = 0, ClipsDescendants = true}, gui)
round(window, 14)
stroke(window, colors.border, 0.92)
local scale = make("UIScale", {Scale = 1}, window)
local header = make("Frame", {Size = UDim2.new(1, 0, 0, 60),
    BackgroundColor3 = colors.headerGlow, BorderSizePixel = 0, Active = true}, window)
local logo = make("TextLabel", {Text = "✦", Font = Enum.Font.GothamBold, TextSize = 25,
    TextColor3 = colors.purple, BackgroundColor3 = colors.accentPanel, BorderSizePixel = 0,
    Position = UDim2.fromOffset(21, 16), Size = UDim2.fromOffset(36, 36)}, header)
logo.Text, logo.BackgroundTransparency = "", 1
logo.Position, logo.Size = UDim2.fromOffset(20, 15), UDim2.fromOffset(26, 30)
UIRefs.flameBase = make("Frame", {Position = UDim2.fromOffset(3, 9), Size = UDim2.fromOffset(20, 21),
    BackgroundColor3 = colors.purple, BorderSizePixel = 0}, logo)
round(UIRefs.flameBase, 10)
UIRefs.flameTip = make("Frame", {Position = UDim2.fromOffset(9, 0), Size = UDim2.fromOffset(10, 22),
    Rotation = 30, BackgroundColor3 = colors.purple, BorderSizePixel = 0}, logo)
round(UIRefs.flameTip, 6)
UIRefs.flameCutout = make("Frame", {Position = UDim2.fromOffset(11, 20), Size = UDim2.fromOffset(8, 13),
    Rotation = 22, BackgroundColor3 = colors.headerGlow, BorderSizePixel = 0}, logo)
round(UIRefs.flameCutout, 5)
UIRefs.brand = label(header, "Starfire", 15)
UIRefs.brand.Position, UIRefs.brand.Size = UDim2.fromOffset(53, 18), UDim2.fromOffset(210, 25)
UIRefs.subtitle = label(header, "MM2", 11, colors.purple)
UIRefs.subtitle.Position, UIRefs.subtitle.Size = UDim2.new(1, -148, 0, 25), UDim2.fromOffset(44, 20)
UIRefs.subtitle.Visible = false
make("Frame", {Size = UDim2.new(1, -40, 0, 1), Position = UDim2.new(0, 20, 1, -1),
    BackgroundColor3 = colors.purple, BackgroundTransparency = 0.88, BorderSizePixel = 0}, header)

local function smallButton(text, x, callback)
    local button = make("TextButton", {Text = text, Font = Enum.Font.GothamBold,
        TextSize = 20, TextColor3 = colors.muted, BackgroundTransparency = 1,
        Position = UDim2.new(1, x, 0, 17), Size = UDim2.fromOffset(34, 34), AutoButtonColor = false}, header)
    round(button, 10)
    connect(button.MouseEnter, function() animate(button, {BackgroundTransparency = 0, BackgroundColor3 = colors.raised, TextColor3 = colors.text}) end)
    connect(button.MouseLeave, function() animate(button, {BackgroundTransparency = 1, TextColor3 = colors.muted}) end)
    connect(button.Activated, callback)
end
local reopen = make("TextButton", {Text = "✦", TextSize = 26,
    Font = Enum.Font.GothamBold, TextColor3 = colors.purple,
    BackgroundColor3 = colors.background, Position = UDim2.fromOffset(18, 100),
    Size = UDim2.fromOffset(48, 48), Visible = false}, gui)
round(reopen, 13); stroke(reopen)
local menuVersion = 0
local function toggleMenu()
    menuOpen = not menuOpen
    menuVersion = menuVersion + 1
    local version = menuVersion
    drag, activeSlider = nil, nil
    reopen.Visible = not menuOpen
    if menuOpen then
        window.Visible = true
        animate(window, {GroupTransparency = 0}, 0.24)
    else
        animate(window, {GroupTransparency = 1}, 0.16)
        task.delay(0.17, function()
            if running and version == menuVersion and not menuOpen then window.Visible = false end
        end)
    end
end
smallButton("−", -82, toggleMenu)
smallButton("×", -44, function() if cleanup then cleanup() end end)
connect(reopen.Activated, toggleMenu)

local sidebar = make("Frame", {Position = UDim2.fromOffset(0, 60),
    Size = UDim2.new(0, 172, 1, -60), BackgroundColor3 = colors.background,
    BorderSizePixel = 0}, window)
local navList = make("ScrollingFrame", {Position = UDim2.fromOffset(0, 10),
    Size = UDim2.new(1, -3, 1, -62), BackgroundTransparency = 1, BorderSizePixel = 0,
    CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 2,
    ScrollBarImageColor3 = colors.purple, ScrollingDirection = Enum.ScrollingDirection.Y}, sidebar)
make("Frame", {Position = UDim2.new(1, -1, 0, 16), Size = UDim2.new(0, 1, 1, -38),
    BackgroundColor3 = colors.purple, BackgroundTransparency = 0.91, BorderSizePixel = 0}, sidebar)
local content = make("Frame", {Position = UDim2.fromOffset(184, 86),
    Size = UDim2.new(1, -206, 1, -150), BackgroundTransparency = 1}, window)
content.Position, content.Size = UDim2.fromOffset(184, 74), UDim2.new(1, -196, 1, -88)
local pageTitle = label(window, "Visuals", 22, colors.text)
pageTitle.Position, pageTitle.Size = UDim2.fromOffset(188, 88), UDim2.fromOffset(260, 32)
pageTitle.Visible = false
local search = make("TextBox", {Text = "", PlaceholderText = "Search everything…", ClearTextOnFocus = false,
    Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
    TextXAlignment = Enum.TextXAlignment.Left, BackgroundColor3 = colors.panel, BorderSizePixel = 0,
    Position = UDim2.new(1, -260, 0, 15), Size = UDim2.fromOffset(160, 30)}, window)
round(search, 10); stroke(search, colors.purple, 0.88)
make("UIPadding", {PaddingLeft = UDim.new(0, 13), PaddingRight = UDim.new(0, 13)}, search)
connect(search.Focused, function() animate(search, {BackgroundColor3 = colors.raised}) end)
connect(search.FocusLost, function() animate(search, {BackgroundColor3 = colors.panel}) end)
UIRefs.menuHint = label(sidebar, "right shift", 11, colors.muted)
UIRefs.menuHint.Position, UIRefs.menuHint.Size = UDim2.new(0, 22, 1, -42), UDim2.fromOffset(120, 22)
UIRefs.menuHint.Visible = false
local status = label(window, "Ready · roles appear when tools are observed", 11, colors.muted)
status.Position, status.Size = UDim2.new(0, 190, 1, -45), UDim2.new(1, -218, 0, 32)
status.TextWrapped = true
status.Visible = false
local noticeVersion = 0
local function notify(text, failed)
    if not running then return end
    status.Text = text
    noticeVersion = noticeVersion + 1
    local version = noticeVersion
    status.Visible = true
    status.TextColor3 = failed and colors.murderer or colors.muted
    status.TextTransparency = 0.5
    animate(status, {TextTransparency = 0}, 0.22)
    task.delay(failed and 8 or 4, function()
        if running and noticeVersion == version then status.Visible = false end
    end)
end

local pages, navigation, pageIndices, pageColumns = {}, {}, {}, {}
local navPositions = {Aim = 28, Guns = 56, Knife = 84, Dodge = 112, Visuals = 172,
    Appearance = 200, Skins = 228, Ambience = 256, Movement = 316, Collect = 344, Players = 372, Emotes = 400, Configs = 428, Settings = 456}
for _, entry in ipairs({{"Combat", 0}, {"Visuals", 144}, {"Miscellaneous", 288}}) do
    local heading = label(navList, entry[1], 12, colors.text)
    heading.Position, heading.Size = UDim2.fromOffset(15, entry[2]), UDim2.fromOffset(142, 25)
end
local selectPage
local selectedPage = "Aim"
local searchResults = make("ScrollingFrame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
    BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ScrollBarThickness = 3, ScrollBarImageColor3 = colors.purple, Visible = false}, content)
make("UIListLayout", {Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder}, searchResults)
make("UIPadding", {PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8)}, searchResults)
UIRefs.emptySearch = label(content, "No matching controls", 14, colors.muted)
UIRefs.emptySearch.Position, UIRefs.emptySearch.Size = UDim2.fromScale(0, 0.32), UDim2.new(1, 0, 0, 32)
UIRefs.emptySearch.TextXAlignment, UIRefs.emptySearch.Visible, UIRefs.emptySearch.ZIndex = Enum.TextXAlignment.Center, false, 3
local function filterControls()
    local query = string.lower(search.Text):match("^%s*(.-)%s*$")
    for _, result in ipairs(searchResults:GetChildren()) do if result:IsA("GuiObject") then result:Destroy() end end
    for title, host in pairs(pages) do host.Visible = query == "" and title == selectedPage end
    searchResults.Visible = query ~= ""
    pageTitle.Text = query == "" and selectedPage or "Search results"
    UIRefs.emptySearch.Visible = false
    if query == "" then return end
    local matches = 0
    for title, host in pairs(pages) do
        for _, view in ipairs(pageColumns[title]) do
        for _, item in ipairs(view:GetChildren()) do
            if item:IsA("GuiObject") and not item:GetAttribute("SectionHeader") and item ~= ghostAnimationStatus then
                local text = item:GetAttribute("SearchText") or ""
                if item:IsA("TextButton") and item.Text ~= "" then text = item.Text end
                if item:IsA("TextBox") then text = item.PlaceholderText end
                if text ~= "" and string.find(string.lower(title .. " " .. text), query, 1, true) then
                    matches = matches + 1
                    local destination, control = title, item
                    local result = make("TextButton", {Text = "  " .. title .. "  ›  " .. text,
                        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = colors.text,
                        BackgroundColor3 = colors.raised, BorderSizePixel = 0, AutoButtonColor = false,
                        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
                        Size = UDim2.new(1, -2, 0, 44), LayoutOrder = pageIndices[title] * 1000 + matches}, searchResults)
                    round(result, 10)
                    result.Activated:Connect(function() selectPage(destination, control) end)
                end
            end
        end
        end
    end
    searchResults.CanvasPosition = Vector2.zero
    UIRefs.emptySearch.Visible = query ~= "" and matches == 0
end
connect(search:GetPropertyChangedSignal("Text"), filterControls)
UIRefs.navMarker = make("Frame", {Position = UDim2.fromOffset(15, 40), Size = UDim2.fromOffset(4, 4),
    BackgroundColor3 = colors.purple, BorderSizePixel = 0}, navList)
round(UIRefs.navMarker, 3)
selectPage = function(title, control)
    selectedPage = title
    search.Text = ""
    filterControls()
    activeSlider = nil
    animate(UIRefs.navMarker, {Position = UDim2.fromOffset(15, navPositions[title] + 12)}, 0.2)
    for key, item in pairs(pages) do
        item.Visible = key == title
        animate(navigation[key], {BackgroundTransparency = 1,
            TextColor3 = key == title and colors.purple or colors.muted})
    end
    local host = pages[title]
    host.GroupTransparency, host.Position = 1, UDim2.fromOffset(0, 6)
    animate(host, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, 0.2)
    if control then
        task.spawn(function()
            RunService.RenderStepped:Wait()
            if not running or not control.Parent or selectedPage ~= title then return end
            local view = control.Parent
            view.CanvasPosition = Vector2.new(0, math.max(0, control.AbsolutePosition.Y - view.AbsolutePosition.Y + view.CanvasPosition.Y - 10))
        end)
    end
end
local function page(title, index)
    local host = make("CanvasGroup", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
        GroupTransparency = 0, Visible = false}, content)
    local view = make("ScrollingFrame", {Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
        ScrollBarImageColor3 = colors.purple, CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = true, ScrollingDirection = Enum.ScrollingDirection.Y,
        ElasticBehavior = Enum.ElasticBehavior.WhenScrollable}, host)
    make("UIPadding", {PaddingLeft = UDim.new(0, 3), PaddingRight = UDim.new(0, 10),
        PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 18)}, view)
    make("UIListLayout", {Padding = UDim.new(0, 16),
        SortOrder = Enum.SortOrder.LayoutOrder}, view)
    local right = view:Clone()
    right.Parent = host
    view.Position, view.Size = UDim2.fromOffset(10, 36), UDim2.new(0.5, -25, 1, -48)
    right.Position, right.Size = UDim2.new(0.5, 15, 0, 36), UDim2.new(0.5, -25, 1, -48)
    pageColumns[title] = {view, right}
    for columnIndex, column in ipairs({view, right}) do
        local card = make("Frame", {Position = UDim2.new((columnIndex - 1) * 0.5, columnIndex == 1 and 0 or 5, 0, 0),
            Size = UDim2.new(0.5, -5, 1, 0), BackgroundColor3 = colors.panel, BackgroundTransparency = 0.05,
            BorderSizePixel = 0, ZIndex = 1}, host)
        round(card, 6)
        local heading = label(card, (columnIndex == 1 and "Main " or "More ") .. title .. " Config", 14, colors.purple)
        heading.Position, heading.Size = UDim2.fromOffset(14, 11), UDim2.new(1, -24, 0, 20)
        column.ZIndex = 2
    end
    local nav = make("TextButton", {Text = "  " .. title, TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = colors.muted,
        BackgroundColor3 = colors.accentPanel, BackgroundTransparency = 1, AutoButtonColor = false,
        BorderSizePixel = 0, Position = UDim2.fromOffset(20, navPositions[title]),
        Size = UDim2.fromOffset(142, 26)}, navList)
    round(nav, 7)
    local icon = make("TextLabel", {Text = title:sub(1, 1), Font = Enum.Font.GothamBold,
        TextSize = 11, TextColor3 = colors.purple, BackgroundColor3 = colors.accentPanel,
        BorderSizePixel = 0, Position = UDim2.fromOffset(8, 5), Size = UDim2.fromOffset(22, 22)}, nav)
    round(icon, 7)
    icon.Visible = false
    pages[title], navigation[title] = host, nav
    pageIndices[title] = index
    connect(nav.MouseEnter, function()
        if selectedPage ~= title then animate(nav, {TextColor3 = colors.text}) end
    end)
    connect(nav.MouseLeave, function()
        if selectedPage ~= title then animate(nav, {BackgroundTransparency = 1, TextColor3 = colors.muted}) end
    end)
    connect(nav.Activated, function()
        if selectedPage ~= title or search.Text ~= "" then selectPage(title) end
    end)
    return view
end
local function button(parent, text, callback)
    local item = make("TextButton", {Text = text, TextColor3 = colors.text,
        Font = Enum.Font.GothamBold, TextSize = 14, BackgroundColor3 = colors.raised,
        Size = UDim2.new(1, -2, 0, 40), BorderSizePixel = 0, AutoButtonColor = false,
        TextTruncate = Enum.TextTruncate.AtEnd}, parent)
    round(item, 3)
    item:SetAttribute("SearchText", text)
    local border = stroke(item, colors.border, 0.95)
    local pressScale = make("UIScale", {Scale = 1}, item)
    connect(item.MouseEnter, function()
        animate(item, {BackgroundColor3 = colors.hover}, 0.15)
        animate(border, {Transparency = 0.35}, 0.15)
    end)
    connect(item.MouseLeave, function()
        animate(item, {BackgroundColor3 = colors.raised}, 0.2)
        animate(border, {Transparency = 0.8}, 0.2)
        animate(pressScale, {Scale = 1}, 0.15)
    end)
    connect(item.MouseButton1Down, function() animate(pressScale, {Scale = 0.985}, 0.09) end)
    connect(item.MouseButton1Up, function() animate(pressScale, {Scale = 1}, 0.16) end)
    connect(item.Activated, callback)
    return item
end
local function toggle(parent, text, key, onChanged)
    local row = button(parent, text, function() end)
    row.Text = ""
    row.BackgroundTransparency = 1
    local caption = label(row, text, 14, colors.muted)
    caption.Position, caption.Size = UDim2.fromOffset(0, 0), UDim2.new(1, -30, 1, 0)
    caption.TextTruncate = Enum.TextTruncate.AtEnd
    local pill = make("Frame", {AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0), Size = UDim2.fromOffset(20, 20), BorderSizePixel = 0}, row)
    round(pill, 2)
    local knob = make("Frame", {BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, pill)
    local checkShort = make("Frame", {Position = UDim2.fromOffset(4, 11), Size = UDim2.fromOffset(5, 2),
        Rotation = 45, BorderSizePixel = 0, BackgroundColor3 = colors.text}, knob)
    local checkLong = make("Frame", {Position = UDim2.fromOffset(7, 9), Size = UDim2.fromOffset(9, 2),
        Rotation = -45, BorderSizePixel = 0, BackgroundColor3 = colors.text}, knob)
    local function refresh()
        animate(pill, {BackgroundColor3 = settings[key] and colors.purple or colors.background}, 0.18)
        animate(checkShort, {BackgroundTransparency = settings[key] and 0 or 1}, 0.15)
        animate(checkLong, {BackgroundTransparency = settings[key] and 0 or 1}, 0.15)
    end
    stateAppliers[key] = function(value)
        settings[key] = value
        refresh()
        if key == "loopEmote" and track then track.Looped = settings.loopEmote end
        if onChanged then onChanged(settings[key]) end
    end
    connect(row.Activated, function() stateAppliers[key](not settings[key]) end)
    stateRefreshers[key] = refresh
    refresh()
end
local function slider(parent, text, key, low, high, format, onChanged)
    settingLimits[key] = {low, high}
    local row = make("Frame", {Size = UDim2.new(1, -2, 0, 66), BackgroundTransparency = 1,
        BorderSizePixel = 0}, parent)
    round(row, 10)
    row:SetAttribute("SearchText", text)
    local caption = label(row, text, 14, colors.muted)
    caption.Position = UDim2.new(0, 0, 0.2, 0)
    caption.Size = UDim2.new(0.6, 0, 0, 18)
    caption.TextTruncate = Enum.TextTruncate.AtEnd
    local value = label(row, "", 14, colors.muted)
    value.Position, value.Size = UDim2.fromScale(0.6, 0.2), UDim2.new(0.4, 0, 0, 18)
    value.TextTruncate = Enum.TextTruncate.AtEnd
    value.TextXAlignment = Enum.TextXAlignment.Right
    local bar = make("TextButton", {Text = "", Position = UDim2.fromScale(0, 0.7),
        Size = UDim2.new(1, 0, 0, 5), BackgroundColor3 = colors.background,
        BorderSizePixel = 0, AutoButtonColor = false}, row)
    round(bar, 5)
    local fill = make("Frame", {BackgroundColor3 = colors.purple, BackgroundTransparency = 0.6, BorderSizePixel = 0,
        Size = UDim2.fromScale(0, 1)}, bar)
    round(fill, 5)
    local thumb = make("Frame", {AnchorPoint = Vector2.new(0.5, 0.5),
        Size = UDim2.fromOffset(12, 12), Position = UDim2.fromScale(0, 0.5),
        BackgroundColor3 = colors.text, BorderSizePixel = 0}, bar)
    round(thumb, 10)
    local hit = make("TextButton", {Text = "", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, -10), Size = UDim2.new(1, 0, 0, 26)}, bar)
    local function refresh()
        local fraction = (settings[key] - low) / (high - low)
        animate(fill, {Size = UDim2.fromScale(fraction, 1)}, 0.065)
        animate(thumb, {Position = UDim2.fromScale(fraction, 0.5)}, 0.065)
        value.Text = format(settings[key])
    end
    local function update(x)
        if bar.AbsoluteSize.X <= 0 then return end
        local fraction = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        settings[key] = low + (high - low) * fraction
        refresh()
        if onChanged then onChanged(settings[key]) end
    end
    connect(hit.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = {update = update, input = input}
            update(input.Position.X)
        end
    end)
    stateRefreshers[key] = refresh
    refresh()
end
local function section(parent, title)
    local heading = label(parent, title, 13, colors.purple)
    heading.Size = UDim2.new(1, 0, 0, 22)
    heading.TextYAlignment = Enum.TextYAlignment.Bottom
    heading:SetAttribute("SectionHeader", true)
    make("Frame", {Position = UDim2.new(0, 130, 1, -5), Size = UDim2.new(1, -135, 0, 1),
        BackgroundColor3 = colors.purple, BackgroundTransparency = 0.9, BorderSizePixel = 0}, heading)
end
UIRefs.visuals = page("Visuals", 1)
function UIRefs.ColourPicker(parent,title,keys)
    local row=make("Frame",{BackgroundTransparency=1,Size=UDim2.new(1,-2,0,42)},parent)
    row:SetAttribute("SearchText",title)
    local text=label(row,title,13,colors.text);text.Size=UDim2.new(1,-60,0,40)
    local swatch=make("TextButton",{Text="",BorderSizePixel=0,Position=UDim2.new(1,-48,0,6),Size=UDim2.fromOffset(44,28)},row)
    round(swatch,5)
    local panel=make("Frame",{Visible=false,BackgroundColor3=colors.panel,BorderSizePixel=0,Position=UDim2.fromOffset(0,44),Size=UDim2.new(1,0,0,180)},row)
    round(panel,5)
    local sv=make("TextButton",{Text="",BorderSizePixel=0,Position=UDim2.fromOffset(8,8),Size=UDim2.new(1,-16,0,112),BackgroundColor3=Color3.new(1,1,1)},panel)
    local saturation=make("UIGradient",{},sv)
    local shade=make("Frame",{Active=false,BorderSizePixel=0,BackgroundColor3=Color3.new(0,0,0),Size=UDim2.fromScale(1,1)},sv)
    make("UIGradient",{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})},shade)
    local cursor=make("Frame",{AnchorPoint=Vector2.new(.5,.5),Size=UDim2.fromOffset(7,7),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=3},sv)
    round(cursor,9);stroke(cursor,Color3.new(1,1,1),0)
    local hue=make("TextButton",{Text="",BorderSizePixel=0,BackgroundColor3=Color3.new(1,1,1),Position=UDim2.fromOffset(8,128),Size=UDim2.new(1,-16,0,16)},panel)
    local stops={}
    for i=0,6 do table.insert(stops,ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1))) end
    make("UIGradient",{Color=ColorSequence.new(stops)},hue)
    local hex=make("TextBox",{ClearTextOnFocus=false,Font=Enum.Font.GothamBold,TextSize=12,TextColor3=colors.text,BackgroundColor3=colors.background,BorderSizePixel=0,Position=UDim2.fromOffset(8,151),Size=UDim2.new(1,-16,0,24)},panel)
    local h,sat,v=0,0,1
    local dragging,activeTouch
    local function refresh()
        local c=Color3.fromRGB(settings[keys[1]],settings[keys[2]],settings[keys[3]])
        h,sat,v=c:ToHSV();swatch.BackgroundColor3=c;hex.Text="#"..c:ToHex():upper()
        saturation.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromHSV(h,1,1))
        cursor.Position=UDim2.fromScale(sat,1-v)
    end
    local function apply(c)
        settings[keys[1]]=math.floor(c.R*255+.5);settings[keys[2]]=math.floor(c.G*255+.5);settings[keys[3]]=math.floor(c.B*255+.5)
        local keep=h;refresh();if sat==0 or v==0 then h=keep end
        saturation.Color=ColorSequence.new(Color3.new(1,1,1),Color3.fromHSV(h,1,1))
    end
    local function update(position)
        local area=dragging=="hue" and hue or sv
        local x=math.clamp((position.X-area.AbsolutePosition.X)/math.max(1,area.AbsoluteSize.X),0,1)
        if dragging=="hue" then h=x else sat=x;v=1-math.clamp((position.Y-area.AbsolutePosition.Y)/math.max(1,area.AbsoluteSize.Y),0,1) end
        apply(Color3.fromHSV(h,sat,v))
    end
    for _,entry in ipairs({{sv,"sv"},{hue,"hue"}}) do
        connect(entry[1].InputBegan,function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                dragging=entry[2];activeTouch=input.UserInputType==Enum.UserInputType.Touch and input or nil;update(input.Position)
            end
        end)
    end
    connect(UIS.InputChanged,function(input)
        if dragging and (input==activeTouch or not activeTouch and input.UserInputType==Enum.UserInputType.MouseMovement) then update(input.Position) end
    end)
    connect(UIS.InputEnded,function(input)
        if input==activeTouch or input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=nil;activeTouch=nil end
    end)
    connect(swatch.MouseButton1Click,function() panel.Visible=not panel.Visible;row.Size=UDim2.new(1,-2,0,panel.Visible and 230 or 42);dragging=nil end)
    connect(hex.FocusLost,function()
        local value=hex.Text:gsub("#",""):gsub("%s","")
        if #value==6 and value:match("^%x+$") then apply(Color3.fromHex(value)) else refresh() end
    end)
    for _,key in ipairs(keys) do stateRefreshers[key]=refresh end
    refresh()
    return row
end
toggle(UIRefs.visuals, "Dropped gun ESP", "droppedGunESP")
toggle(UIRefs.visuals, "Sheriff death notification", "sheriffDeathNotify")
toggle(UIRefs.visuals, "Murderer · red chams", "murdererESP")
toggle(UIRefs.visuals, "Sheriff · blue chams", "sheriffESP")
toggle(UIRefs.visuals, "Innocents / unknown · green chams", "innocentESP")
toggle(UIRefs.visuals, "Player names and roles", "names")
toggle(UIRefs.visuals, "Show through walls", "throughWalls")
slider(UIRefs.visuals, "Chams opacity", "opacity", 0.05, 0.85, function(v) return math.floor(v * 100 + 0.5) .. "%" end)
UIRefs.assistance = page("Aim", 2)
toggle(UIRefs.assistance, "Aim at murderer · hold bound key", "aim")
local function aimKeyName()
    if aimKey == Enum.UserInputType.MouseButton1 then return "Left Mouse" end
    if aimKey == Enum.UserInputType.MouseButton2 then return "Right Mouse" end
    if aimKey == Enum.UserInputType.MouseButton3 then return "Middle Mouse" end
    return aimKey.Name
end
local function refreshAimBind()
    aimBindButton.Text = captureAim and "Press a key or mouse button · Esc cancels" or "Aim key: " .. aimKeyName() .. " · click to change"
end
local function matchesAimKey(input)
    return input.KeyCode == aimKey or input.UserInputType == aimKey
end
aimBindButton = button(UIRefs.assistance, "", function()
    captureResponse = false
    if refreshResponseBind then refreshResponseBind() end
    captureGun = false
    if refreshGunBind then refreshGunBind() end
    captureAim, aiming, selectedTarget = true, false, nil
    refreshAimBind()
    notify("Choose an aim key · B, " .. gunKey.Name .. " and Right Shift are reserved")
end)
refreshAimBind()
toggle(UIRefs.assistance, "Check line of sight", "wallCheck")
toggle(UIRefs.assistance, "Show aim FOV", "showFov")
slider(UIRefs.assistance, "FOV radius", "fov", 40, 600, function(v) return math.floor(v) .. " px" end)
slider(UIRefs.assistance, "Aim response", "responsiveness", 2, 30, function(v) return string.format("%.1f", v) end)
toggle(UIRefs.assistance, "Snap aim · instant camera lock", "snapAim")
UIRefs.movementPage = page("Movement", 3)
UIRefs.appearancePage = page("Appearance", 4)
UIRefs.gunsPage = page("Guns", 5)
UIRefs.automationPage = page("Collect", 6)
UIRefs.knifePage = page("Knife", 7)
UIRefs.playersPage = page("Players", 8)
UIRefs.dodgePage = page("Dodge", 9)
UIRefs.configsPage = page("Configs", 11)
UIRefs.utility = page("Settings", 12)
UIRefs.skinsPage = page("Skins", 13)
UIRefs.ambiencePage = page("Ambience", 14)
UIRefs.unloadButton = button(UIRefs.utility, "Turn off script", function()
    if cleanup then cleanup() end
end)
UIRefs.unloadButton.TextColor3 = colors.murderer
UIRefs.emotes = page("Emotes", 10)

local function living(character)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0 and character:FindFirstChild("HumanoidRootPart") ~= nil
end
local MovementSpeed = (function()
    local api, humanoid, original = {}, nil, nil
    function api.Reset()
        if humanoid and humanoid.Parent then humanoid.WalkSpeed = original end
        humanoid, original = nil, nil
    end
    function api.Step()
        local character = player.Character
        if not settings.speedEnabled or not living(character) then api.Reset(); return end
        local current = character:FindFirstChildOfClass("Humanoid")
        if current ~= humanoid then
            api.Reset()
            humanoid, original = current, current.WalkSpeed
        end
        humanoid.WalkSpeed = settings.walkSpeed
    end
    return api
end)()
toggle(UIRefs.movementPage, "Movement speed", "speedEnabled", function(enabled)
    if not enabled then MovementSpeed.Reset() end
end)
slider(UIRefs.movementPage, "Walk speed", "walkSpeed", 8, 1000, function(v) return string.format("%.0f studs/s", v) end)
-- Rotate the root without changing its position, movement input or camera.
local VisualSpin = (function()
    local api, root, humanoid, autoRotate, character, angle = {}, nil, nil, nil, nil, 0
    function api.Reset()
        if humanoid and humanoid.Parent then humanoid.AutoRotate = autoRotate end
        root, humanoid, autoRotate, character, angle = nil, nil, nil, nil, 0
    end
    function api.Step(dt)
        local current = player.Character
        if not settings.visualSpin or not living(current) then api.Reset(); return end
        if settings.coinCollect or sweepState or (Scare and Scare.Busy()) or (Fling and Fling.Busy()) or (Evade and Evade.Busy()) or (Automation and Automation.Busy()) then
            api.Reset(); return
        end
        local currentHumanoid = current:FindFirstChildOfClass("Humanoid")
        if currentHumanoid.Sit or currentHumanoid.PlatformStand then api.Reset(); return end
        if character ~= current or not root or not root.Parent or humanoid ~= currentHumanoid then
            api.Reset()
            root, humanoid, character = current:FindFirstChild("HumanoidRootPart"), currentHumanoid, current
            autoRotate = humanoid.AutoRotate
            local _, yaw = root.CFrame:ToOrientation()
            angle = yaw
        end
        if root.Anchored then api.Reset(); return end
        humanoid.AutoRotate = false
        angle = (angle + math.pi * 2 * settings.spinSpeed * dt) % (math.pi * 2)
        root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, angle, 0)
    end
    return api
end)()
connect(RunService.PostSimulation, function(dt)
    if running then VisualSpin.Step(dt) end
end)
toggle(UIRefs.movementPage, "Character spin", "visualSpin", function(enabled)
    if not enabled then VisualSpin.Reset() end
end)
slider(UIRefs.movementPage, "Spin speed", "spinSpeed", 0.25, 20, function(v)
    return string.format("%.2f turns/s", v)
end)
local Mobility = (function()
    local api, character, attachment, velocity = {}, nil, nil, nil
    local collisions = {}
    function api.Reset()
        local wasFlying = velocity ~= nil
        if velocity then velocity:Destroy(); velocity = nil end
        if attachment then attachment:Destroy(); attachment = nil end
        for part, original in pairs(collisions) do
            if part.Parent then part.CanCollide = original end
        end
        table.clear(collisions)
        if character and character == player.Character and wasFlying then
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.zero end
        end
        character = nil
    end
    function api.Step()
        local current = player.Character
        if not living(current) or settings.coinCollect or sweepState or (Scare and Scare.Busy()) or (Fling and Fling.Busy())
            or (Evade and Evade.Busy()) or (Automation and Automation.Busy()) then
            api.Reset(); return
        end
        if character ~= current then api.Reset(); character = current end
        local root = current:FindFirstChild("HumanoidRootPart")
        local humanoid = current:FindFirstChildOfClass("Humanoid")
        if root.Anchored or humanoid.Sit then api.Reset(); return end
        if settings.noclip then
            for _, part in ipairs(current:GetDescendants()) do
                if part:IsA("BasePart") then
                    if collisions[part] == nil then collisions[part] = part.CanCollide end
                    part.CanCollide = false
                end
            end
        else
            for part, original in pairs(collisions) do
                if part.Parent then part.CanCollide = original end
            end
            table.clear(collisions)
        end
        if not settings.fly then
            if velocity then
                velocity:Destroy(); velocity = nil
                root.AssemblyLinearVelocity = Vector3.zero
            end
            if attachment then attachment:Destroy(); attachment = nil end
            return
        end
        if not velocity or not velocity.Parent or not attachment or not attachment.Parent then
            if velocity then velocity:Destroy() end
            if attachment then attachment:Destroy() end
            attachment = make("Attachment", {Name = "StarfireFlightAttachment"}, root)
            velocity = make("LinearVelocity", {Name = "StarfireFlightVelocity", Attachment0 = attachment,
                RelativeTo = Enum.ActuatorRelativeTo.World, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
                ForceLimitsEnabled = false, VectorVelocity = Vector3.zero}, root)
        end
        local direction = Vector3.zero
        local camera = Workspace.CurrentCamera
        if camera and not UIS:GetFocusedTextBox() then
            if UIS:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.yAxis end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl) then
                direction = direction - Vector3.yAxis
            end
        end
        velocity.VectorVelocity = direction.Magnitude > 0 and direction.Unit * settings.flySpeed or Vector3.zero
    end
    return api
end)()
toggle(UIRefs.movementPage, "Fly", "fly", function(enabled)
    Mobility.Reset()
    if enabled then
        notify(settings.coinCollect and "Fly paused: turn off coin collection first" or "Fly: WASD · Space up · Ctrl down · works with the menu open")
    end
end)
slider(UIRefs.movementPage, "Fly speed", "flySpeed", 10, 200, function(v) return string.format("%.0f studs/s", v) end)
toggle(UIRefs.movementPage, "Noclip", "noclip", function() Mobility.Reset() end)
connect(RunService.PreSimulation, function() if running then Mobility.Step() end end)

local WeaponVisuals = (function()
    local api, character, hidden = {}, nil, {}
    local function weaponObject(object)
        local node = object
        while node and node ~= character do
            local name = string.lower(node.Name)
            if name:find("knife", 1, true) then return true end
            node = node.Parent
        end
        return false
    end
    local function restore(object, saved)
        if object.Parent then for property, value in pairs(saved) do object[property] = value end end
    end
    function api.Reset()
        for object, saved in pairs(hidden) do restore(object, saved) end
        table.clear(hidden); character = nil
    end
    function api.Original(object, property)
        local saved = hidden[object]
        if saved and saved[property] ~= nil then return saved[property] end
        return object[property]
    end
    function api.Managed(object) return hidden[object] ~= nil end
    function api.IsGunVisual(object, owner)
        local node = object
        while node and node ~= owner do
            if string.lower(node.Name):find("gun", 1, true) then return true end
            node = node.Parent
        end
        return false
    end
    function api.Step()
        if character ~= player.Character then api.Reset(); character = player.Character end
        if not character then return end
        for object, saved in pairs(hidden) do
            if not object:IsDescendantOf(character) or not weaponObject(object) then
                restore(object, saved); hidden[object] = nil
            end
        end
        for _, object in ipairs(character:GetDescendants()) do
            if weaponObject(object) then
                local property, value
                if object:IsA("BasePart") then property, value = "LocalTransparencyModifier", 1
                elseif object:IsA("Decal") or object:IsA("Texture") then property, value = "Transparency", 1
                elseif object:IsA("Trail") or object:IsA("Beam") or object:IsA("ParticleEmitter")
                    or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
                    property, value = "Enabled", false
                end
                if property then
                    if not hidden[object] then hidden[object] = {[property] = object[property]} end
                    object[property] = value
                end
            end
        end
    end
    return api
end)()

local Ghost = (function()
    local api, character = {}, nil
    local originals, blocks, decals, emitters = {}, {}, {}, {}
    local floatBlend, motionBlend, phase, stridePhase, sideBlend = 0, 0, 0, 0, 0
    local launchTime, wasMoving = 1, false
    local ghostTrack, animationAttempted, animationStarted, animationNotice, packMessage, activeMode
    local ghostTracks, ghostAnimations = {}, {}
    local nextAnimationRetry = 0
    local packAssets = {idle = 135055120827684, walk = 76189697399044, run = 115080665168960}
    local neutral = {}
    local sourceAliases = {Head = "Head", Torso = "UpperTorso", ["Left Arm"] = "LeftUpperArm",
        ["Right Arm"] = "RightUpperArm", ["Left Leg"] = "LeftUpperLeg", ["Right Leg"] = "RightUpperLeg"}
    local body = {
        {"Head", Vector3.new(1.4, 0.9, 0.8), Vector3.new(0, 1.3, 0)},
        {"Torso", Vector3.new(1.2, 1.7, 0.65), Vector3.zero},
        {"Left Arm", Vector3.new(0.55, 1.8, 0.6), Vector3.new(-0.875, -0.05, 0)},
        {"Right Arm", Vector3.new(0.55, 1.8, 0.6), Vector3.new(0.875, -0.05, 0)},
        {"Left Leg", Vector3.new(0.55, 1.9, 0.6), Vector3.new(-0.3, -1.8, 0)},
        {"Right Leg", Vector3.new(0.55, 1.9, 0.6), Vector3.new(0.3, -1.8, 0)},
    }
    function api.Reset()
        if ghostAnimationStatus then ghostAnimationStatus.Visible = false end
        for _, value in pairs(ghostTracks) do pcall(function() value:Stop(0.15); value:Destroy() end) end
        for _, value in pairs(ghostAnimations) do value:Destroy() end
        table.clear(ghostTracks); table.clear(ghostAnimations)
        nextAnimationRetry = 0
        ghostTrack, animationAttempted, animationStarted, animationNotice, packMessage, activeMode = nil, nil, nil, nil, nil, nil
        table.clear(neutral)
        for part, value in pairs(originals) do
            if part.Parent then part.LocalTransparencyModifier = WeaponVisuals.Managed(part) and 1 or value end
        end
        for decal, value in pairs(decals) do
            if decal.Parent then decal.Transparency = WeaponVisuals.Managed(decal) and 1 or value end
        end
        for emitter, value in pairs(emitters) do
            if emitter.Parent then emitter.Enabled = not WeaponVisuals.Managed(emitter) and value or false end
        end
        for _, block in pairs(blocks) do block:Destroy() end
        table.clear(originals); table.clear(blocks); table.clear(decals); table.clear(emitters)
        floatBlend, motionBlend, phase, stridePhase, sideBlend = 0, 0, 0, 0, 0
        launchTime, wasMoving = 1, false
        character = nil
    end
    function api.Refresh()
        if not settings.ghost or not living(player.Character) then api.Reset(); return end
        if character ~= player.Character then api.Reset(); character = player.Character end
        local root = character:FindFirstChild("HumanoidRootPart")
        if not animationAttempted and os.clock() >= nextAnimationRetry then
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local animator = humanoid:FindFirstChildOfClass("Animator")
            if animator then
                animationAttempted, animationStarted = true, os.clock()
                local ok, err = pcall(function()
                    local description = humanoid:GetAppliedDescription()
                    local animateScript = character:FindFirstChild("Animate")
                    if not animateScript or description.IdleAnimation ~= packAssets.idle
                        or description.WalkAnimation ~= packAssets.walk or description.RunAnimation ~= packAssets.run then
                        error("Equip Ghost Animation Pack idle/walk/run on your Roblox avatar, respawn, then enable Ghost mode")
                    end
                    for _, mode in ipairs({"idle", "walk", "run"}) do
                        local slot = animateScript:FindFirstChild(mode)
                        local source = slot and slot:FindFirstChildWhichIsA("Animation", true)
                        if not source or source.AnimationId == "" then error("Avatar Animate script has no resolved " .. mode .. " animation") end
                        local sourceId = source.AnimationId:match("%d+")
                        if sourceId == tostring(packAssets[mode]) then error("The " .. mode .. " animation has not resolved to its playable asset yet") end
                        local animation = make("Animation", {AnimationId = source.AnimationId})
                        ghostAnimations[mode] = animation
                        local loaded = animator:LoadAnimation(animation)
                        loaded.Looped, loaded.Priority = true, Enum.AnimationPriority.Action
                        ghostTracks[mode] = loaded
                    end
                    ghostTrack, activeMode = ghostTracks.idle, "idle"
                    ghostTrack:Play(0.2, 1, settings.ghostAnimationSpeed)
                    animationNotice, packMessage = false, nil
                end)
                if not ok then
                    local previousMessage = packMessage
                    animationNotice, packMessage = true, tostring(err)
                    for _, value in pairs(ghostTracks) do pcall(function() value:Stop(); value:Destroy() end) end
                    table.clear(ghostTracks); ghostTrack = nil
                    for _, value in pairs(ghostAnimations) do value:Destroy() end
                    table.clear(ghostAnimations)
                    animationAttempted, nextAnimationRetry = false, os.clock() + 3
                    if previousMessage ~= packMessage then notify("Ghost pack: " .. packMessage, true) end
                end
            end
        end
        if not neutral[root] then
            neutral[root] = CFrame.new()
            for _ = 1, 20 do
                local changed = false
                for _, joint in ipairs(character:GetDescendants()) do
                    if joint:IsA("Motor6D") and joint.Part0 and joint.Part1
                        and neutral[joint.Part0] and not neutral[joint.Part1] then
                        neutral[joint.Part1] = neutral[joint.Part0] * joint.C0 * joint.C1:Inverse()
                        changed = true
                    end
                end
                if not changed then break end
            end
        end
        -- Always use classic six-part proportions, including on R15 avatars.
        for _, specification in ipairs(body) do
            local name, size, offset = specification[1], specification[2], specification[3]
            if not blocks[name] then
                local block = make("Part", {Name = "Ghost_" .. name, Size = size,
                    CFrame = root.CFrame * CFrame.new(offset), Anchored = true, CanCollide = false,
                    CanTouch = false, CanQuery = false, CastShadow = false,
                    Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(28, 32, 39),
                    Transparency = 1 - settings.ghostOpacity,
                    TopSurface = Enum.SurfaceType.Smooth, BottomSurface = Enum.SurfaceType.Smooth}, effects)
                blocks[name] = block
                if name == "Head" then
                    make("SpecialMesh", {MeshType = Enum.MeshType.Head, Scale = Vector3.new(0.875, 1.125, 1)}, block)
                end
            end
        end
        for _, object in ipairs(character:GetDescendants()) do
            if not WeaponVisuals.IsGunVisual(object, character) then
            if object:IsA("BasePart") then
                if originals[object] == nil then originals[object] = WeaponVisuals.Original(object, "LocalTransparencyModifier") end
            elseif object:IsA("Decal") or object:IsA("Texture") then
                if decals[object] == nil then decals[object] = WeaponVisuals.Original(object, "Transparency") end
            elseif object:IsA("Trail") or object:IsA("Beam") or object:IsA("ParticleEmitter")
                or object:IsA("Fire") or object:IsA("Smoke") or object:IsA("Sparkles") then
                if emitters[object] == nil then emitters[object] = WeaponVisuals.Original(object, "Enabled") end
            end
            end
        end
    end
    function api.Step(dt)
        if not settings.ghost or not living(player.Character) then api.Reset(); return end
        api.Refresh()
        local camera = Workspace.CurrentCamera
        local ownerRoot = character:FindFirstChild("HumanoidRootPart")
        local ownerHumanoid = character:FindFirstChildOfClass("Humanoid")
        local ownerVelocity = ownerRoot.AssemblyLinearVelocity
        local horizontalSpeed = Vector3.new(ownerVelocity.X, 0, ownerVelocity.Z).Magnitude
        local mode = (horizontalSpeed < 0.5 and ownerHumanoid.MoveDirection.Magnitude < 0.1) and "idle"
            or (horizontalSpeed < ownerHumanoid.WalkSpeed * 0.65 and horizontalSpeed > 0.5 and "walk" or "run")
        if ghostTracks[mode] and activeMode ~= mode then
            if ghostTrack then ghostTrack:Stop(0.2) end
            ghostTrack, activeMode = ghostTracks[mode], mode
            ghostTrack:Play(0.2, 1, settings.ghostAnimationSpeed)
            animationStarted = os.clock()
        end
        local assetPlaying = ghostTrack and ghostTrack.IsPlaying and ghostTrack.Length > 0
        if ghostAnimationStatus then
            ghostAnimationStatus.Visible = not assetPlaying
            local failed = animationNotice or (animationStarted and os.clock() - animationStarted > 8)
            ghostAnimationStatus.Text = failed
                and (packMessage or "Ghost pack did not load — check avatar animation access and rig compatibility.")
                or (animationAttempted and "Loading equipped Ghost Animation Pack…" or "Waiting for the character Animator…")
            ghostAnimationStatus.TextColor3 = failed and colors.murderer or colors.muted
        end
        if animationAttempted and not animationNotice and os.clock() - animationStarted > 8 and not assetPlaying then
            animationNotice = true
            packMessage = "Ghost pack did not load — check avatar animation access and rig compatibility."
            notify(packMessage, true)
        end
        dt = math.clamp(dt or 1 / 60, 0, 0.1)
        phase = phase + dt * settings.ghostAnimationSpeed
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local floating = settings.ghostFloat and not humanoid.Sit and not humanoid.PlatformStand
        local response = 1 - math.exp(-10 * dt)
        floatBlend = floatBlend + ((floating and 1 or 0) - floatBlend) * response
        local velocity = root.AssemblyLinearVelocity
        local travel = Vector3.new(velocity.X, 0, velocity.Z).Magnitude / math.max(1, humanoid.WalkSpeed)
        local moveDirection = (Scare and Scare.Direction()) or humanoid.MoveDirection
        local movement = math.min(1, math.max(moveDirection.Magnitude, travel))
        local moving = floating and movement > 0.15
        if moving and not wasMoving then launchTime = 0 end
        wasMoving = moving
        launchTime = math.min(1, launchTime + dt * settings.ghostAnimationSpeed)
        local motionResponse = 1 - math.exp(-(movement > motionBlend and 8 or 5) * dt)
        motionBlend = motionBlend + (movement - motionBlend) * motionResponse
        local localMove = root.CFrame:VectorToObjectSpace(moveDirection)
        sideBlend = sideBlend + (localMove.X - sideBlend) * (1 - math.exp(-6 * dt))
        -- Integrate cadence instead of multiplying total time by changing speed.
        stridePhase = stridePhase + dt * settings.ghostAnimationSpeed * (3.2 + 5.2 * motionBlend)
        local sway = math.sin(phase * 1.8)
        local poseBlend = motionBlend * motionBlend * (3 - 2 * motionBlend)
        local launch = math.sin(math.pi * math.min(1, launchTime / 0.55)) * (moving and 1 or 0)
        local bob = sway * (0.08 - 0.05 * poseBlend)
        local floatRoot = root.CFrame * CFrame.new(0, settings.ghostFloatHeight + 0.55 * poseBlend + 0.3 * launch + bob, 0)
            * CFrame.Angles(math.rad(-29 * poseBlend - 5 * launch), 0,
                math.rad(-6 * sideBlend * poseBlend + sway * 0.6))
        for part, value in pairs(originals) do
            if part:IsDescendantOf(character) and not WeaponVisuals.IsGunVisual(part, character) then part.LocalTransparencyModifier = 1
            else
                if part.Parent then part.LocalTransparencyModifier = value end
                originals[part] = nil
            end
        end
        for decal, value in pairs(decals) do
            if decal:IsDescendantOf(character) and not WeaponVisuals.IsGunVisual(decal, character) then decal.Transparency = 1
            else if decal.Parent then decal.Transparency = value end; decals[decal] = nil end
        end
        for emitter, value in pairs(emitters) do
            if emitter:IsDescendantOf(character) and not WeaponVisuals.IsGunVisual(emitter, character) then emitter.Enabled = false
            else if emitter.Parent then emitter.Enabled = value end; emitters[emitter] = nil end
        end
        for _, specification in ipairs(body) do
            local name, size, offset = specification[1], specification[2], specification[3]
            local block = blocks[name]
            local pitch, roll = 0, 0
            local side = name:find("Left", 1, true) and -1 or 1
            if name:find("Arm", 1, true) then
                pitch = math.rad((side < 0 and 48 or 60) * poseBlend + 6 * launch) * floatBlend
                roll = math.rad(side * (4 + 6 * poseBlend)) * floatBlend
            elseif name:find("Leg", 1, true) then
                pitch = math.rad((side < 0 and 60 or 43) * poseBlend + 8 * launch) * floatBlend
                roll = math.rad(side * 2 * poseBlend) * floatBlend
            elseif name == "Head" then
                pitch = math.rad(24 * poseBlend + 4 * launch) * floatBlend
                roll = math.rad(4 * sideBlend * poseBlend - sway * 0.6) * floatBlend
            end
            local base = root.CFrame:Lerp(floatRoot, floatBlend)
            block.CFrame = base * CFrame.new(offset) * CFrame.new(0, size.Y * 0.5, 0)
                * CFrame.Angles(pitch, 0, roll) * CFrame.new(0, -size.Y * 0.5, 0)
            if assetPlaying then
                local source = character:FindFirstChild(name) or character:FindFirstChild(sourceAliases[name])
                local rest = source and neutral[source]
                if rest then
                    local animated = root.CFrame:ToObjectSpace(source.CFrame)
                    local delta = rest:ToObjectSpace(animated)
                    local translation = delta.Position
                    block.CFrame = root.CFrame * CFrame.new(offset) * rest.Rotation
                        * CFrame.new(translation.X * 0.6, translation.Y * 0.9, translation.Z * 0.6) * delta.Rotation
                end
            end
            local nearCamera = camera and (camera.CFrame.Position - block.Position).Magnitude < 1
            block.Transparency = nearCamera and 1 or (1 - settings.ghostOpacity)
        end
    end
    return api
end)()
section(UIRefs.appearancePage, "Ghost")
toggle(UIRefs.appearancePage, "Ghost mode", "ghost", function(enabled)
    if enabled and AvatarClone then AvatarClone.Stop() end
    settings.ghostFloat = enabled
    if enabled then Ghost.Refresh(); Ghost.Step() else Ghost.Reset() end
end)
slider(UIRefs.appearancePage, "Ghost opacity", "ghostOpacity", 0.1, 0.8, function(v) return string.format("%.0f%%", v * 100) end)
ghostAnimationStatus = label(UIRefs.appearancePage, "", 12, colors.muted)
ghostAnimationStatus.Size, ghostAnimationStatus.TextWrapped = UDim2.new(1, -8, 0, 40), true
ghostAnimationStatus.Visible = false
ghostAnimationStatus:SetAttribute("SearchText", "Ghost animation status")

AvatarClone = (function()
    local api, state, generation = {}, nil, 0
    local function refreshToggle()
        if stateRefreshers.avatarClone then stateRefreshers.avatarClone() end
    end
    local function restore(object, saved)
        if not object.Parent then return end
        for property, value in pairs(saved) do
            if WeaponVisuals.Managed(object) then
                if property == "Enabled" then object[property] = false else object[property] = 1 end
            else object[property] = value end
        end
    end
    function api.Stop()
        generation = generation + 1
        local old = state
        state = nil
        settings.avatarClone = false
        refreshToggle()
        if not old then return end
        for object, saved in pairs(old.hidden) do restore(object, saved) end
        old.model:Destroy()
        if old.character == player.Character then
            local root = old.character:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
        end
    end
    function api.Load(username)
        username = username:match("^%s*@?([%w_]+)%s*$")
        if not username or #username > 20 then
            api.Stop(); notify("Enter a Roblox username, not a display name", true); return
        end
        if not living(player.Character) then api.Stop(); notify("Spawn before cloning an avatar", true); return end
        api.Stop()
        settings.avatarClone = true
        refreshToggle()
        local token, character = generation, player.Character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rigType = humanoid.RigType
        notify("Loading @" .. username .. "'s avatar…")
        task.spawn(function()
            local model, description
            local ok, err = pcall(function()
                local userId = Players:GetUserIdFromNameAsync(username)
                if not running or token ~= generation or player.Character ~= character then return end
                description = Players:GetHumanoidDescriptionFromUserIdAsync(userId)
                if not running or token ~= generation or player.Character ~= character then return end
                model = Players:CreateHumanoidModelFromDescriptionAsync(description, rigType)
                if not running or token ~= generation or player.Character ~= character or not living(character) then return end
                for _, object in ipairs(model:GetDescendants()) do
                    if object:IsA("Script") or object:IsA("LocalScript") then object:Destroy()
                    elseif object:IsA("BasePart") then
                        object.CanCollide, object.CanTouch, object.CanQuery, object.Massless = false, false, false, true
                        object.Anchored = object.Name == "HumanoidRootPart"
                    end
                end
                local cloneHumanoid = model:FindFirstChildOfClass("Humanoid")
                if cloneHumanoid then
                    cloneHumanoid.EvaluateStateMachine = false
                    cloneHumanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                    cloneHumanoid.AutoRotate = false
                end
                local cloneRoot = model:FindFirstChild("HumanoidRootPart")
                if not cloneRoot then error("Avatar model has no movement root") end
                model.PrimaryPart = cloneRoot
                local sources = {}
                for _, joint in ipairs(character:GetDescendants()) do
                    if joint:IsA("Motor6D") and joint.Part1 then sources[joint.Part1.Name] = joint end
                end
                local joints, parts = {}, {}
                for _, object in ipairs(model:GetDescendants()) do
                    if object:IsA("Motor6D") and object.Part1 and sources[object.Part1.Name] then
                        table.insert(joints, {target = object, source = sources[object.Part1.Name]})
                    elseif object:IsA("BasePart") then
                        table.insert(parts, {part = object, original = object.LocalTransparencyModifier})
                    end
                end
                settings.ghost = false
                Ghost.Reset()
                if stateRefreshers.ghost then stateRefreshers.ghost() end
                model.Name = "StarfireLocalAvatar_" .. username
                model:PivotTo(character:GetPivot())
                model.Parent = effects
                state = {character = character, model = model, root = cloneRoot, humanoid = cloneHumanoid,
                    joints = joints, parts = parts, hidden = {}}
                model = nil
                local sourceRoot = character:FindFirstChild("HumanoidRootPart")
                if sourceRoot then sourceRoot.AssemblyLinearVelocity, sourceRoot.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
                api.Step()
                notify("Local avatar: @" .. username .. " · visible only to you")
            end)
            if description then description:Destroy() end
            if model then model:Destroy() end
            if not ok and token == generation and running then api.Stop(); notify("Avatar clone failed: " .. tostring(err), true) end
        end)
    end
    function api.SyncJoints()
        if not state then return end
        if state.humanoid and state.humanoid.Parent then state.humanoid.EvaluateStateMachine = false end
        for _, entry in ipairs(state.parts) do
            local part = entry.part
            if part.Parent then
                part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, true
                part.Anchored = part == state.root
                part.AssemblyLinearVelocity, part.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
            end
        end
        for _, pair in ipairs(state.joints) do
            if pair.target.Parent and pair.source.Parent then pair.target.Transform = pair.source.Transform end
        end
    end
    function api.Step()
        local current = state
        if not current then return end
        if current.character ~= player.Character or not living(current.character) or not current.model.Parent then api.Stop(); return end
        api.SyncJoints()
        for object, saved in pairs(current.hidden) do
            if not object:IsDescendantOf(current.character) or WeaponVisuals.IsGunVisual(object, current.character) then
                restore(object, saved); current.hidden[object] = nil
            end
        end
        for _, object in ipairs(current.character:GetDescendants()) do
            if not WeaponVisuals.IsGunVisual(object, current.character) then
            local property, value
            if object:IsA("BasePart") then property, value = "LocalTransparencyModifier", 1
            elseif object:IsA("Decal") or object:IsA("Texture") then property, value = "Transparency", 1
            elseif object:IsA("Trail") or object:IsA("Beam") or object:IsA("ParticleEmitter") then property, value = "Enabled", false end
            if property then
                if not current.hidden[object] then current.hidden[object] = {[property] = WeaponVisuals.Original(object, property)} end
                object[property] = value
            end
            end
        end
        current.model:PivotTo(current.character:GetPivot())
        local camera = Workspace.CurrentCamera
        local head = current.character:FindFirstChild("Head")
        local firstPerson = camera and head and (camera.CFrame.Position - head.Position).Magnitude < 1
        for _, entry in ipairs(current.parts) do
            if entry.part.Parent then
                entry.part.LocalTransparencyModifier = (firstPerson or entry.part == current.root) and 1 or entry.original
            end
        end
    end
    return api
end)()
section(UIRefs.appearancePage, "Avatar clone")
UIRefs.avatarUsername = make("TextBox", {Text = "", PlaceholderText = "Roblox username (not display name)",
    ClearTextOnFocus = false, TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
    BackgroundColor3 = colors.panel, BorderSizePixel = 0, Font = Enum.Font.GothamBold, TextSize = 12,
    Size = UDim2.new(1, -2, 0, 42)}, UIRefs.appearancePage)
round(UIRefs.avatarUsername, 3)
toggle(UIRefs.appearancePage, "Avatar clone · local appearance", "avatarClone", function(enabled)
    if enabled then AvatarClone.Load(UIRefs.avatarUsername.Text) else AvatarClone.Stop() end
end)
button(UIRefs.appearancePage, "Apply username", function() AvatarClone.Load(UIRefs.avatarUsername.Text) end)
connect(UIRefs.avatarUsername.FocusLost, function(enter) if enter then AvatarClone.Load(UIRefs.avatarUsername.Text) end end)
connect(RunService.PreSimulation, function() if running then AvatarClone.SyncJoints() end end)

-- Prefer explicit replicated round flags; the saved hub is a spatial fallback.
UIRefs.roundState={drops={},sheriffs={},pickupBusy=false}
function UIRefs.roundState.InHub(other)
    local character=other.Character
    for _,object in ipairs({other,character}) do
        if object then
            for _,name in ipairs({"InLobby","InSpawn","Lobby"}) do
                if object:GetAttribute(name)==true then return true end
                local flag=object:FindFirstChild(name)
                if flag and flag:IsA("BoolValue") and flag.Value then return true end
            end
            local round=object:GetAttribute("InRound")
            if round==false then return true end
        end
    end
    local root=character and character:FindFirstChild("HumanoidRootPart")
    local hub=Evade and Evade.HubPosition()
    return root and hub and (Vector2.new(root.Position.X-hub.X,root.Position.Z-hub.Z)).Magnitude<=settings.spawnRadius or false
end
local function observedRole(other)
    for _, container in ipairs({other.Character, other:FindFirstChildOfClass("Backpack")}) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") then
                    local toolName = string.lower(item.Name)
                    if toolName == "knife" then return "murderer" end
                    if toolName == "gun" then return "sheriff" end
                end
            end
        end
    end
    return nil
end
local function destroyEntry(other)
    local entry = entries[other]
    if not entry then return end
    if entry.highlight then entry.highlight:Destroy() end
    if entry.tag then entry.tag:Destroy() end
    entries[other] = nil
end
local function refreshPlayer(other)
    if other == player then return end
    local character = other.Character
    local entry = entries[other]
    if not character or not living(character) then
        if entry and entry.role=="sheriff" and settings.sheriffDeathNotify and living(player.Character)
            and not observedRole(player) and not UIRefs.roundState.InHub(player) then
            notify(other.DisplayName .. " · sheriff died; watch for the dropped gun")
        end
        destroyEntry(other); return
    end
    local inHub=UIRefs.roundState.InHub(other) or UIRefs.roundState.InHub(player)
    if entry and entry.character ~= character then destroyEntry(other); entry = nil end
    if not entry then
        entry = {character = character}
        entries[other] = entry
    end
    local role = observedRole(other)
    if role then entry.role = role end
    local enabled = settings[entry.role == "murderer" and "murdererESP"
        or entry.role == "sheriff" and "sheriffESP" or "innocentESP"]
    if not entry.highlight then
        entry.highlight = make("Highlight", {Adornee = character, Enabled = false}, effects)
    end
    local color = colors[entry.role] or colors.innocent
    entry.highlight.FillColor, entry.highlight.OutlineColor = color, color:Lerp(Color3.new(1, 1, 1), 0.28)
    entry.highlight.FillTransparency, entry.highlight.OutlineTransparency = 1 - settings.opacity, 0.05
    entry.highlight.DepthMode = settings.throughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    entry.highlight.Enabled = enabled and not inHub
    local head = character:FindFirstChild("Head")
    if head and not entry.tag then
        entry.tag = make("BillboardGui", {Adornee = head, Size = UDim2.fromOffset(190, 40),
            StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0), AlwaysOnTop = true,
            MaxDistance = 1500, ResetOnSpawn = false}, playerGui)
        local text = label(entry.tag, "", 12, color)
        text.Size, text.TextXAlignment = UDim2.fromScale(1, 1), Enum.TextXAlignment.Center
        text.TextStrokeTransparency = 0.25
        entry.tagText = text
    end
    if entry.tag then
        entry.tag.Enabled = enabled and settings.names and not inHub
        entry.tag.AlwaysOnTop = settings.throughWalls
        entry.tagText.TextColor3 = color
        entry.tagText.Text = other.DisplayName .. (entry.role and ("\n" .. string.upper(entry.role)) or "")
    end
end
button(UIRefs.utility, "Clear observed roles", function()
    for other in pairs(entries) do destroyEntry(other) end
    selectedTarget = nil
    notify("Role cache cleared; waiting for visible tools")
end)
local function inspectDrop(instance)
    if string.lower(instance.Name) == "gundrop" and (instance:IsA("BasePart") or instance:IsA("Model") or instance:IsA("Tool")) then
        gunDrops[instance] = true
    end
end
local function collectibleName(instance)
    local name = string.lower(instance.Name):gsub("[%s_]", "")
    return name == "coin" or name == "coinserver" or name == "candy" or name == "candyserver"
end
local function inspectCollectible(instance)
    if not collectibleName(instance) or not (instance:IsA("BasePart") or instance:IsA("Model")) then return end
    local ancestor = instance.Parent
    while ancestor and ancestor ~= Workspace do
        if ancestor:IsA("Tool") or (ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid")) then return end
        if collectibleName(ancestor) then return end
        ancestor = ancestor.Parent
    end
    collectibles[instance] = true
    if Automation then Automation.Observe(instance) end
end
local function inspectWorldItem(instance)
    inspectDrop(instance)
    inspectCollectible(instance)
end
for _, instance in ipairs(Workspace:GetDescendants()) do inspectWorldItem(instance) end
connect(Workspace.DescendantAdded, inspectWorldItem)
connect(Workspace.DescendantRemoving, function(instance)
    if Automation then Automation.Forget(instance) end
    gunDrops[instance], collectibles[instance] = nil, nil
end)
local function dropPart(instance)
    if instance:IsA("BasePart") then return instance end
    return instance:FindFirstChildWhichIsA("BasePart", true)
end
local function teleportToGun()
    if Scare then Scare.Stop(true) end
    if Fling then Fling.Stop(true) end
    if Evade then Evade.Stop(true) end
    if not living(player.Character) then notify("You need a living character", true); return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    local nearest, distance
    for instance in pairs(gunDrops) do
        if instance:IsDescendantOf(Workspace) then
            local part = dropPart(instance)
            if part then
                local d = (root.Position - part.Position).Magnitude
                if not distance or d < distance then nearest, distance = part, d end
            end
        end
    end
    if not nearest then notify("No replicated GunDrop found", true); return end
    if stopCollecting then stopCollecting(true) end
    if Automation then Automation.StopBag(true) end
    if stopSweep then stopSweep(true) end
    if UIRefs.roundState.pickupBusy then return end
    UIRefs.roundState.pickupBusy=true
    local character=player.Character
    local origin=character:GetPivot()
    task.spawn(function()
        local ok,err=pcall(function()
            character:PivotTo(CFrame.new(nearest.Position+Vector3.new(0,1.5,0))*root.CFrame.Rotation)
            local deadline=os.clock()+2
            repeat
                task.wait(.05)
                local backpack=player:FindFirstChildOfClass("Backpack")
                if character:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun")) then break end
            until not running or player.Character~=character or not living(character) or os.clock()>=deadline
        end)
        local backpack=player:FindFirstChildOfClass("Backpack")
        local acquired=character:FindFirstChild("Gun") or (backpack and backpack:FindFirstChild("Gun"))
        if player.Character==character and living(character) then
            character:PivotTo(origin)
            root.AssemblyLinearVelocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero
        end
        UIRefs.roundState.pickupBusy=false
        notify(not ok and tostring(err) or acquired and "Gun collected · returned" or "Pickup not confirmed · returned",not ok or not acquired)
    end)
end
UIRefs.gunActionButton = button(UIRefs.gunsPage, "Teleport to dropped gun · O", teleportToGun)
local gunBindButton
refreshGunBind = function()
    UIRefs.gunActionButton.Text = "Teleport to dropped gun · " .. gunKey.Name
    if gunBindButton then
        gunBindButton.Text = captureGun and "Press a keyboard key · Esc cancels" or "Pickup gun key: " .. gunKey.Name .. " · click to change"
    end
end
gunBindButton = button(UIRefs.gunsPage, "Pickup gun key: O · click to change", function()
    captureResponse = false
    if refreshResponseBind then refreshResponseBind() end
    captureGun, captureAim, aiming = true, false, false
    refreshAimBind()
    refreshGunBind()
    notify("Choose a pickup gun key · B, Right Shift and your aim key are reserved")
end)
refreshGunBind()

local function zeroVelocity(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then root.AssemblyLinearVelocity, root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero end
end
Automation = (function()
    local api = {}
    local collectState, collectGeneration = nil, 0
    local bagState, bagGeneration, bagConsumed, retryBagAt = nil, 0, false, 0
    local tracked = setmetatable({}, {__mode = "k"})
    local cachedBag, nextBagRead, nextNotice = {full = false, known = false, reason = "bag HUD not identified"}, 0, 0
    local function announce(message, failed)
        if os.clock() >= nextNotice then notify(message, failed); nextNotice = os.clock() + 2 end
    end
    local function ownedTool(name)
        for _, container in pairs({player.Character, player:FindFirstChildOfClass("Backpack")}) do
            if container then
                for _, item in ipairs(container:GetChildren()) do
                    if item:IsA("Tool") and string.lower(item.Name) == name then return item end
                end
            end
        end
    end
    local function murdererPositions()
        local result = {}
        for other, entry in pairs(entries) do
            if other ~= player and entry.role == "murderer" and living(entry.character) then
                local root = entry.character:FindFirstChild("HumanoidRootPart")
                if root then table.insert(result, root.Position) end
            end
        end
        return result
    end
    local function horizontal(a, b)
        local d = a - b
        return math.sqrt(d.X * d.X + d.Z * d.Z)
    end
    local function segmentDistance(from, to, point)
        local a, b, p = Vector2.new(from.X, from.Z), Vector2.new(to.X, to.Z), Vector2.new(point.X, point.Z)
        local d = b - a
        local t = d:Dot(d) > 0.001 and math.clamp((p - a):Dot(d) / d:Dot(d), 0, 1) or 0
        return (p - (a + d * t)).Magnitude
    end
    local function pointSafe(position)
        if not settings.noMurd then return true end
        for _, threat in ipairs(murdererPositions()) do
            if horizontal(position, threat) < settings.murdererDistance then return false end
        end
        return true
    end
    local function routeSafe(from, to, escape)
        if not settings.noMurd then return true end
        for _, threat in ipairs(murdererPositions()) do
            local before, after = horizontal(from, threat), horizontal(to, threat)
            if before < settings.murdererDistance then
                if not escape or after < before - 0.05 then return false end
            elseif segmentDistance(from, to, threat) < settings.murdererDistance then
                return false
            end
        end
        return true
    end
    local function renderable(part)
        return part:IsA("BasePart") and part.Transparency < 0.98 and part.LocalTransparencyModifier < 0.98
    end
    local function collectiblePart(instance)
        local part = dropPart(instance)
        if not part or not instance:IsDescendantOf(Workspace) or not part.CanTouch then return nil end
        for _, key in ipairs({"Collected", "PickedUp", "IsCollected", "Disabled"}) do
            if instance:GetAttribute(key) == true then return nil end
            local flag = instance:FindFirstChild(key)
            if flag and flag:IsA("BoolValue") and flag.Value then return nil end
        end
        if instance:GetAttribute("Active") == false or instance:GetAttribute("Enabled") == false then return nil end
        if part.Position.Y <= Workspace.FallenPartsDestroyHeight + 16 then return nil end
        local visible = renderable(part)
        if not visible then
            for _, item in ipairs(instance:GetDescendants()) do
                if renderable(item) then visible = true; break end
            end
        end
        return visible and part or nil
    end
    local function refreshObject(instance)
        local data = tracked[instance]
        if not data then return nil end
        local part = collectiblePart(instance)
        local active = part ~= nil
        if active then
            local moved = data.position and (part.Position - data.position).Magnitude > 3
            if data.active == false or moved then data.attempted = false end
            data.position = part.Position
        end
        data.active, data.part = active, part
        return active and not data.attempted and part or nil
    end
    function api.Forget(instance)
        local data = tracked[instance]
        if data then
            for _, connection in ipairs(data.connections) do connection:Disconnect() end
            tracked[instance] = nil
        end
    end
    function api.Observe(instance)
        if tracked[instance] then return end
        local data = {connections = {}, watched = {}, attempted = false}
        tracked[instance] = data
        local function watch(part)
            if not part:IsA("BasePart") or data.watched[part] then return end
            data.watched[part] = true
            for _, property in ipairs({"Transparency", "LocalTransparencyModifier", "CanTouch", "Position"}) do
                table.insert(data.connections, part:GetPropertyChangedSignal(property):Connect(function() refreshObject(instance) end))
            end
        end
        watch(instance)
        for _, item in ipairs(instance:GetDescendants()) do watch(item) end
        table.insert(data.connections, instance.AttributeChanged:Connect(function() refreshObject(instance) end))
        table.insert(data.connections, instance.DescendantAdded:Connect(function(item) watch(item); refreshObject(instance) end))
        table.insert(data.connections, instance.DescendantRemoving:Connect(function()
            task.defer(function() if running then refreshObject(instance) end end)
        end))
        refreshObject(instance)
    end
    local function available(instance)
        if not tracked[instance] then api.Observe(instance) end
        return refreshObject(instance)
    end
    local function nearestCollectible(character)
        local from = character:GetPivot().Position
        local nearest, part, best
        for instance in pairs(collectibles) do
            local candidate = available(instance)
            if candidate and pointSafe(candidate.Position) and routeSafe(from, candidate.Position, false) then
                local distance = (from - candidate.Position).Magnitude
                if not best or distance < best then nearest, part, best = instance, candidate, distance end
            end
        end
        return nearest, part
    end
    local function release(state, surface)
        if not state or state.released then return end
        state.released = true
        if surface and state.character == player.Character and living(state.character) and state.safe then
            pcall(function() state.character:PivotTo(state.safe); zeroVelocity(state.character) end)
        end
        for part, collision in pairs(state.collisions) do
            if part.Parent then pcall(function() part.CanCollide = collision end) end
        end
        if state.humanoid.Parent then state.humanoid.AutoRotate = state.autoRotate end
    end
    function api.StopCollect(surface, keepEnabled)
        collectGeneration = collectGeneration + 1
        if not keepEnabled then settings.coinCollect = false end
        if stateRefreshers.coinCollect then stateRefreshers.coinCollect() end
        local state = collectState
        collectState = nil
        release(state, surface ~= false)
    end
    local function validCollect(state, token)
        return running and settings.coinCollect and collectState == state and token == collectGeneration
            and player.Character == state.character and living(state.character) and not bagState and not sweepState
    end
    local function passThrough(state)
        for _, part in ipairs(state.character:GetDescendants()) do
            if part:IsA("BasePart") then
                if state.collisions[part] == nil then state.collisions[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
        state.humanoid.AutoRotate = false
        zeroVelocity(state.character)
    end
    local function hold(state, token, seconds)
        local elapsed = 0
        while elapsed < seconds and validCollect(state, token) do
            elapsed = elapsed + RunService.Heartbeat:Wait()
            if not validCollect(state, token) then return false end
            if state.holdPivot then
                if not pointSafe(state.holdPivot.Position) then return false end
                passThrough(state)
                state.character:PivotTo(state.holdPivot)
            end
        end
        return validCollect(state, token)
    end
    local function move(state, token, destination, target, escape)
        local from = state.character:GetPivot().Position
        if not routeSafe(from, destination, escape) then return false end
        local distance, traveled = (destination - from).Magnitude, 0
        while traveled < distance do
            local dt = RunService.Heartbeat:Wait()
            if not validCollect(state, token) or (target and not available(target)) then return false end
            local nextDistance = math.min(distance, traveled + settings.collectSpeed * math.min(dt, 0.05))
            local nextPosition = from:Lerp(destination, nextDistance / distance)
            if not routeSafe(state.character:GetPivot().Position, nextPosition, escape) then return false end
            passThrough(state)
            state.holdPivot = CFrame.new(nextPosition) * state.rotation
            state.character:PivotTo(state.holdPivot)
            traveled = nextDistance
        end
        return validCollect(state, token)
    end
    local function escapeMurderer(state, token)
        local from = state.character:GetPivot().Position
        if pointSafe(from) then return true end
        local goal, best
        for index = 0, 15 do
            local angle = index * math.pi / 8
            local candidate = from + Vector3.new(math.cos(angle), 0, math.sin(angle)) * (settings.murdererDistance * 2 + 12)
            if pointSafe(candidate) and routeSafe(from, candidate, true) then
                local score = math.huge
                for _, threat in ipairs(murdererPositions()) do score = math.min(score, horizontal(candidate, threat)) end
                if not best or score > best then goal, best = candidate, score end
            end
        end
        if not goal then announce("No murd: waiting for a safe escape route", true); return false end
        local y = math.max(Workspace.FallenPartsDestroyHeight + 20, from.Y - (state.holdPivot and 0 or settings.collectDepth))
        if not move(state, token, Vector3.new(from.X, y, from.Z), nil, true) then return false end
        announce("No murd: moving away from observed murderer")
        return move(state, token, Vector3.new(goal.X, y, goal.Z), nil, true)
    end
    local function visibleHUD(object)
        local node = object
        while node and node ~= playerGui do
            if node:IsA("GuiObject") and not node.Visible then return false end
            if node:IsA("ScreenGui") and not node.Enabled then return false end
            node = node.Parent
        end
        return node == playerGui
    end
    local function bagContext(object)
        local node = object
        while node and node ~= playerGui do
            local name = string.lower(node.Name):gsub("[%s_]", "")
            if name:find("coinbag", 1, true) or name:find("candybag", 1, true) then return true end
            node = node.Parent
        end
        return false
    end
    function api.BagStatus(force)
        if not force and os.clock() < nextBagRead then return cachedBag end
        nextBagRead = os.clock() + 0.6
        for _, key in ipairs({"CoinBagFull", "CandyBagFull", "BagFull"}) do
            local value = player:GetAttribute(key)
            if type(value) == "boolean" then
                cachedBag = {known = true, full = value, reason = "player attribute " .. key}
                return cachedBag
            end
        end
        local counted
        for _, object in ipairs(playerGui:GetDescendants()) do
            if object:IsA("GuiObject") and visibleHUD(object) and bagContext(object) then
                if object:IsA("TextLabel") or object:IsA("TextButton") then
                    local text = object.Text:gsub("<.->", "")
                    local lowered = string.lower(text)
                    if lowered:match("^%s*full!?%s*$") or lowered:find("bag is full", 1, true) then
                        cachedBag = {known = true, full = true, reason = "visible full indicator"}
                        return cachedBag
                    end
                    local count, capacity = text:match("(%d+)%s*/%s*(%d+)")
                    if count and tonumber(capacity) > 0 then
                        counted = {known = true, full = tonumber(count) >= tonumber(capacity), count = tonumber(count),
                            capacity = tonumber(capacity), reason = "visible bag ratio"}
                        if counted.full then cachedBag = counted; return cachedBag end
                    elseif settings.useBagCapacity then
                        local name = string.lower(object.Name)
                        local number = text:match("^%s*(%d+)%s*$")
                        if number and (name:find("amount", 1, true) or name:find("count", 1, true) or name:find("collected", 1, true)) then
                            counted = {known = true, full = tonumber(number) >= settings.bagCapacity, count = tonumber(number),
                                capacity = settings.bagCapacity, reason = "configured capacity fallback"}
                        end
                    end
                elseif object:IsA("ImageLabel") and string.lower(object.Name) == "full" and object.ImageTransparency < 0.98 then
                    cachedBag = {known = true, full = true, reason = "visible bag full icon"}
                    return cachedBag
                end
            end
        end
        cachedBag = counted or {known = false, full = false, reason = "bag HUD not identified"}
        return cachedBag
    end
    function api.CandyCount()
        -- Read current bag HUD independently of boolean "full" attributes.
        local result
        for _, object in ipairs(playerGui:GetDescendants()) do
            if (object:IsA("TextLabel") or object:IsA("TextButton")) and visibleHUD(object) and bagContext(object) then
                local text = object.Text:gsub("<.->", "")
                local count, capacity = text:match("^%s*(%d+)%s*/%s*(%d+)%s*$")
                local number
                if count and tonumber(capacity) > 0 and tonumber(count) <= tonumber(capacity) then
                    number = tonumber(count)
                else
                    local name = string.lower(object.Name)
                    if name:find("amount", 1, true) or name:find("count", 1, true) or name:find("collected", 1, true) then
                        number = tonumber(text:match("^%s*(%d+)%s*$"))
                    end
                end
                if number then
                    if result ~= nil and result ~= number then return nil end
                    result = number
                end
            end
        end
        return result
    end
    function api.StartCollect()
        if Scare and Scare.Busy() then return end
        if Fling and Fling.Busy() then return end
        VisualSpin.Reset()
        if Evade and Evade.Busy() then return end
        if collectState or bagState or sweepState or not settings.coinCollect or not living(player.Character) then return end
        local bag = api.BagStatus()
        if bag.known and bag.full then return end
        collectGeneration = collectGeneration + 1
        local token = collectGeneration
        local character = player.Character
        local state = {character = character, humanoid = character:FindFirstChildOfClass("Humanoid"),
            safe = character:GetPivot(), rotation = character:GetPivot().Rotation, collisions = {}}
        state.autoRotate = state.humanoid.AutoRotate
        collectState = state
        task.spawn(function()
            local ok, err = pcall(function()
                while validCollect(state, token) do
                    if not escapeMurderer(state, token) then
                        RunService.Heartbeat:Wait()
                    else
                        local target, part = nearestCollectible(character)
                        if not target or not part then
                            announce(settings.noMurd and "Waiting for unattempted collectibles on a safe route" or "Waiting for unattempted collectibles")
                            hold(state, token, 0.25)
                        else
                            local y = part.Position.Y - settings.collectDepth
                            if y <= Workspace.FallenPartsDestroyHeight + 12 then
                                tracked[target].attempted = true
                            else
                                local from = character:GetPivot().Position
                                local reached = move(state, token, Vector3.new(from.X, y, from.Z), target, false)
                                    and move(state, token, Vector3.new(part.Position.X, y, part.Position.Z), target, false)
                                part = reached and available(target) or nil
                                if part and pointSafe(part.Position) and validCollect(state, token) then
                                    local head = character:FindFirstChild("Head")
                                    if head then
                                        local offset = character:GetPivot():PointToObjectSpace(head.Position)
                                        local destination = part.Position - state.rotation:VectorToWorldSpace(offset)
                                        if move(state, token, destination, target, false) then
                                            tracked[target].attempted = true
                                            state.safe = CFrame.new(part.Position + Vector3.new(0, 4, 0)) * state.rotation
                                            hold(state, token, 0.2)
                                            if validCollect(state, token) and pointSafe(character:GetPivot().Position) then
                                                local current = character:GetPivot().Position
                                                move(state, token, Vector3.new(current.X, y, current.Z), nil, false)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end)
            if collectState == state and token == collectGeneration then
                api.StopCollect(true, true)
                if not ok then announce("Collector paused: " .. tostring(err), true) end
            else
                release(state, false)
            end
        end)
    end
    local function knownMurderer()
        local closest, character, distance
        local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for other, entry in pairs(entries) do
            if other ~= player and entry.role == "murderer" and living(entry.character) then
                local root = entry.character:FindFirstChild("HumanoidRootPart")
                local d = mine and (mine.Position - root.Position).Magnitude or 0
                if not distance or d < distance then closest, character, distance = other, entry.character, d end
            end
        end
        return closest, character
    end
    local function nearestGun()
        local mine = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        local selected, part, best
        for instance in pairs(gunDrops) do
            if instance:IsDescendantOf(Workspace) then
                local candidate = dropPart(instance)
                if candidate then
                    local d = mine and (mine.Position - candidate.Position).Magnitude or 0
                    if not best or d < best then selected, part, best = instance, candidate, d end
                end
            end
        end
        return selected, part
    end
    function api.StopBag(surface)
        bagGeneration = bagGeneration + 1
        local state = bagState
        bagState = nil
        if not state then return end
        if state.gun and state.gun.Parent then pcall(function() state.gun:Deactivate() end) end
        if state.character == player.Character and living(state.character) then
            state.humanoid.AutoRotate = state.autoRotate
            if surface and state.start then pcall(function() state.character:PivotTo(state.start); zeroVelocity(state.character) end) end
        end
    end
    local function validBag(state, token)
        local bag = api.BagStatus()
        local enabled = state.manual or (settings.coinCollect and settings.fullBagAction and not (bag.known and not bag.full))
        return running and enabled and bagState == state and token == bagGeneration
            and player.Character == state.character and living(state.character) and not sweepState
            and not ownedTool("knife")
    end
    local function startBagAction(manual)
        VisualSpin.Reset()
        if bagState or (not manual and not settings.fullBagAction) or ownedTool("knife") then return false end
        local murderer = knownMurderer()
        local drop, part = nearestGun()
        if not murderer or (not ownedTool("gun") and not part) then return end
        api.StopCollect(true, true)
        bagGeneration = bagGeneration + 1
        local token = bagGeneration
        local character = player.Character
        local state = {character = character, humanoid = character:FindFirstChildOfClass("Humanoid"), start = character:GetPivot(), manual = manual == true}
        state.autoRotate = state.humanoid.AutoRotate
        bagState = state
        task.spawn(function()
            local completed = false
            local ok, err = pcall(function()
                local gun = ownedTool("gun")
                if not gun then
                    notify("Bag full: moving to dropped gun; waiting for inventory confirmation")
                    local deadline = os.clock() + 3
                    while validBag(state, token) and not gun and os.clock() < deadline do
                        if not drop or not drop:IsDescendantOf(Workspace) or not part or not part.Parent then break end
                        character:PivotTo(CFrame.new(part.Position + Vector3.new(0, 2, 0)) * character:GetPivot().Rotation)
                        zeroVelocity(character)
                        RunService.Heartbeat:Wait()
                        gun = ownedTool("gun")
                    end
                end
                if not gun or not validBag(state, token) then
                    announce("Gun pickup not confirmed; murderer teleport cancelled", true)
                    return
                end
                state.gun = gun
                state.humanoid:EquipTool(gun)
                RunService.Heartbeat:Wait()
                if ownedTool("gun") ~= gun or gun.Parent ~= character or not validBag(state, token) then
                    announce("Gun is not equipped; attack cancelled", true)
                    return
                end
                local target, victim = knownMurderer()
                if not target or not living(victim) then announce("Gun confirmed; murderer has not been observed"); return end
                notify("Gun confirmed: approaching " .. target.DisplayName)
                local deadline, nextShot = os.clock() + 4, 0
                while validBag(state, token) and ownedTool("gun") == gun and target.Character == victim and living(victim) and os.clock() < deadline do
                    if gun.Parent ~= character then state.humanoid:EquipTool(gun) end
                    if gun.Parent ~= character then break end
                    local root = victim:FindFirstChild("HumanoidRootPart")
                    local torso = victim:FindFirstChild("UpperTorso") or victim:FindFirstChild("Torso")
                        or victim:FindFirstChild("LowerTorso") or root
                    if not root or not torso then break end
                    if state.aimPart ~= torso then state.aimPart, state.aimFrames = torso, 0 end
                    state.humanoid.AutoRotate = false
                    local position = (root.CFrame * CFrame.new(0, 0, 8)).Position
                    character:PivotTo(CFrame.lookAt(position, Vector3.new(root.Position.X, position.Y, root.Position.Z)))
                    if not state.firstApproachAt then
                        state.firstApproachAt = os.clock()
                        if state.manual then nextShot = state.firstApproachAt + 1 end
                    end
                    zeroVelocity(character)
                    local handle = gun:FindFirstChild("Handle")
                    local origin = handle and handle:IsA("BasePart") and handle.Position
                        or (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")).Position
                    local params = RaycastParams.new()
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    params.FilterDescendantsInstances = {character, Workspace.CurrentCamera, effects}
                    params.IgnoreWater = true
                    local hit = Workspace:Raycast(origin, torso.Position - origin, params)
                    local clear = not hit or hit.Instance:IsDescendantOf(victim)
                    if clear and (state.aimFrames or 0) >= 2 and gun.Enabled and os.clock() >= nextShot then
                        nextShot = os.clock() + 1.1
                        gun:Activate()
                        task.delay(0.12, function()
                            if bagState == state and token == bagGeneration and gun.Parent then pcall(function() gun:Deactivate() end) end
                        end)
                    end
                    RunService.Heartbeat:Wait()
                end
                completed = target.Character == victim and not living(victim)
                if completed then notify("Murderer observed down; collection stays enabled for the next round")
                else announce("Gun attack attempt ended; no elimination confirmed", true) end
            end)
            if bagState == state and token == bagGeneration then
                api.StopBag(true)
                bagConsumed = completed
                retryBagAt = os.clock() + 4
                if not ok then announce("Bag action stopped: " .. tostring(err), true) end
            end
        end)
        return true
    end
    function api.ManualGunResponse()
        if not living(player.Character) then notify("You need a living character", true); return false end
        if ownedTool("knife") then notify("Gun response is for a non-murderer role", true); return false end
        if bagState then notify("Gun response is already running"); return false end
        if not knownMurderer() then notify("No observed murderer to target", true); return false end
        local _, part = nearestGun()
        if not ownedTool("gun") and not part then notify("No owned gun or dropped gun found", true); return false end
        if Scare then Scare.Stop(true) end
        if Fling then Fling.Stop(true) end
        if Evade then Evade.Stop(true) end
        if stopSweep then stopSweep(true) end
        Mobility.Reset()
        return startBagAction(true)
    end
    function api.Busy() return bagState ~= nil end
    function api.AimBagCamera(camera)
        if manualGunMode() or settings.silentAim then if bagState then bagState.aimFrames=(bagState.aimFrames or 0)+1 end;return end
        local state = bagState
        local part = state and state.aimPart
        if not camera or not part or not part.Parent or not living(state.character) then return end
        if (part.Position - camera.CFrame.Position).Magnitude <= 0.1 then return end
        camera.CFrame = CFrame.lookAt(camera.CFrame.Position, part.Position)
        state.aimFrames = (state.aimFrames or 0) + 1
    end
    function api.ResetRound()
        api.StopCollect(false, true)
        api.StopBag(false)
        bagConsumed, retryBagAt, nextBagRead = false, 0, 0
        for _, data in pairs(tracked) do data.attempted = false end
        for other in pairs(entries) do destroyEntry(other) end
    end
    function api.Rescan()
        for instance, data in pairs(tracked) do data.attempted = false; refreshObject(instance) end
        notify("Rescanned available collectible spawns")
    end
    function api.Update()
        if not running or not settings.coinCollect then return end
        if Scare and Scare.Busy() then return end
        if Fling and Fling.Busy() then return end
        if Evade and Evade.Busy() then return end
        if not living(player.Character) then
            if collectState then api.StopCollect(false, true) end
            if bagState then api.StopBag(false) end
            return
        end
        if sweepState or bagState then return end
        local bag = api.BagStatus()
        if bag.known and not bag.full then bagConsumed = false end
        if bag.known and bag.full then
            if collectState then api.StopCollect(true, true) end
            if settings.fullBagAction and not bagConsumed and os.clock() >= retryBagAt then
                if ownedTool("knife") then announce("Bag full: gun response requires a non-murderer role")
                elseif not knownMurderer() then announce("Bag full: waiting for an observed murderer")
                else
                    local _, part = nearestGun()
                    if ownedTool("gun") or part then startBagAction()
                    else announce("Bag full: waiting for the dropped gun") end
                end
            elseif not settings.fullBagAction then announce("Bag full: collection remains enabled; waiting for bag reset") end
            return
        end
        if not collectState then api.StartCollect() end
    end
    function api.Cleanup()
        api.StopCollect(true, false)
        api.StopBag(true)
        local objects = {}
        for instance in pairs(tracked) do table.insert(objects, instance) end
        for _, instance in ipairs(objects) do api.Forget(instance) end
    end
    for instance in pairs(collectibles) do api.Observe(instance) end
    return api
end)()
stopCollecting = function(surface, keepEnabled) Automation.StopCollect(surface, keepEnabled) end
section(UIRefs.gunsPage, "Manual response")
UIRefs.responseAction = button(UIRefs.gunsPage, "Grab gun → shoot murderer · G", function() Automation.ManualGunResponse() end)
local responseBindButton
refreshResponseBind = function()
    UIRefs.responseAction.Text = "Grab gun → shoot murderer · " .. responseKey.Name
    if responseBindButton then
        responseBindButton.Text = captureResponse and "Press a keyboard key · Esc cancels"
            or "Gun response key: " .. responseKey.Name .. " · click to change"
    end
end
responseBindButton = button(UIRefs.gunsPage, "Gun response key: G · click to change", function()
    captureResponse, captureAim, captureGun, aiming = true, false, false, false
    refreshAimBind(); refreshGunBind(); refreshResponseBind()
    notify("Choose a gun response key · avoid your aim, pickup and menu keys")
end)
button(UIRefs.gunsPage, "Stop gun response and return", function() Automation.StopBag(true) end)
refreshResponseBind()
section(UIRefs.gunsPage, "Gun tracking circle")
toggle(UIRefs.gunsPage, "Gun tracking circle", "gunCircle")
slider(UIRefs.gunsPage, "Circle radius", "gunCircleRadius", 5, 45, function(v) return string.format("%.0f px", v) end)
slider(UIRefs.gunsPage, "Circle opacity", "gunCircleOpacity", 0.1, 1, function(v) return string.format("%.0f%%", v * 100) end)
UIRefs.ColourPicker(UIRefs.gunsPage,"Circle colour",{"gunCircleRed","gunCircleGreen","gunCircleBlue"})
toggle(UIRefs.automationPage, "Collect coins / candy underground", "coinCollect", function(enabled)
    Mobility.Reset()
    if enabled then Automation.StartCollect() else Automation.StopCollect(true, false); Automation.StopBag(true) end
end)
toggle(UIRefs.automationPage, "No murd · avoid observed murderer", "noMurd")
slider(UIRefs.automationPage, "Murderer avoidance radius", "murdererDistance", 15, 90, function(v) return math.floor(v) .. " studs" end)
slider(UIRefs.automationPage, "Collect movement speed", "collectSpeed", 16, 90, function(v) return math.floor(v) .. " studs/s" end)
slider(UIRefs.automationPage, "Underground depth", "collectDepth", 8, 40, function(v) return math.floor(v) .. " studs" end)
toggle(UIRefs.gunsPage, "Bag full → gun → murderer", "fullBagAction", function(enabled)
    if not enabled then Automation.StopBag(true) end
end)
toggle(UIRefs.automationPage, "Use manual bag capacity fallback", "useBagCapacity")
slider(UIRefs.automationPage, "Fallback bag capacity", "bagCapacity", 10, 100, function(v) return tostring(math.floor(v + 0.5)) end)
button(UIRefs.automationPage, "Check bag detector", function()
    local bag = Automation.BagStatus(true)
    notify((bag.full and "Bag full" or bag.known and "Bag not full" or "Bag state unknown") .. " · " .. bag.reason)
end)
button(UIRefs.automationPage, "Rescan skipped collectibles", function() Automation.Rescan() end)

toggle(UIRefs.movementPage, "Cursor teleport · B", "cursorTP")
local function teleportToCursor()
    if Scare then Scare.Stop(true) end
    if Fling then Fling.Stop(true) end
    if Evade then Evade.Stop(true) end
    if not settings.cursorTP then return end
    if not living(player.Character) then notify("You need a living character", true); return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local mouse = UIS:GetMouseLocation()
    local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, camera, effects}
    params.IgnoreWater, params.RespectCanCollide = true, true
    local hit = Workspace:Raycast(ray.Origin, ray.Direction * 2500, params)
    if not hit then notify("Point at a solid surface to teleport", true); return end
    stopCollecting(true)
    if Automation then Automation.StopBag(true) end
    if stopSweep then stopSweep(true) end
    local character = player.Character
    local destination = hit.Position + hit.Normal * 2 + Vector3.new(0, 3, 0)
    local ok, err = pcall(function()
        character:PivotTo(CFrame.new(destination) * character:GetPivot().Rotation)
        zeroVelocity(character)
    end)
    notify(ok and "Teleported to cursor surface" or tostring(err), not ok)
end


local sweepGeneration, sweepButton = 0, nil
local function localKnife()
    local character = player.Character
    local backpack = player:FindFirstChildOfClass("Backpack")
    for _, container in pairs({character, backpack}) do
        if container then
            for _, item in ipairs(container:GetChildren()) do
                if item:IsA("Tool") and string.lower(item.Name) == "knife" then return item end
            end
        end
    end
    return nil
end
stopSweep = function(returnToStart)
    sweepGeneration = sweepGeneration + 1
    local state = sweepState
    sweepState = nil
    if sweepButton then sweepButton.Text = "Kill all · murderer sweep" end
    if not state then return end
    if state.knife and state.knife.Parent then pcall(function() state.knife:Deactivate() end) end
    if state.character == player.Character and living(state.character) then
        state.humanoid.AutoRotate = state.autoRotate
        if returnToStart ~= false then
            pcall(function() state.character:PivotTo(state.start); zeroVelocity(state.character) end)
        end
    end
end
local function validSweep(state, token)
    return running and sweepState == state and token == sweepGeneration
        and player.Character == state.character and living(state.character)
        and localKnife() == state.knife
end
local function outsideSpawn(position, allowUnmarked)
    local hub = Evade and Evade.HubPosition()
    if not hub then return allowUnmarked == true end
    local delta = Vector2.new(position.X - hub.X, position.Z - hub.Z)
    -- Horizontal exclusion covers players above/below the hub as well as knife reach.
    return delta.Magnitude > settings.spawnRadius + 10
end
local function sweepTargetAllowed(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    return living(character) and root ~= nil and outsideSpawn(root.Position, true)
end
local function startSweep(automatic)
    if Scare and Scare.Busy() then notify("Stop the scare pass first", true); return false end
    if Fling and Fling.Busy() then notify("Stop the fling attempt first", true); return false end
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot or not outsideSpawn(myRoot.Position, true) then
        notify("Knife sweep blocked inside the protected spawn area", true); return false
    end
    VisualSpin.Reset()
    if Evade then Evade.Stop(true) end
    if sweepState then notify("Sweep already running · use Stop to cancel"); return end
    if not living(player.Character) then notify("You need a living character", true); return end
    local knife = localKnife()
    if not knife then notify("Murderer sweep requires your Knife tool", true); return end
    stopCollecting(true, automatic == true)
    if Automation then Automation.StopBag(true) end
    local character = player.Character
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local targets = {}
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and sweepTargetAllowed(other.Character) then table.insert(targets, other) end
    end
    if #targets == 0 then notify("No living targets outside protected spawn", true); return false end
    local state = {character = character, humanoid = humanoid, knife = knife,
        start = character:GetPivot(), autoRotate = humanoid.AutoRotate}
    sweepGeneration = sweepGeneration + 1
    local token = sweepGeneration
    sweepState = state
    sweepButton.Text = "Sweep running…"
    aiming, selectedTarget = false, nil
    task.spawn(function()
        local attempted, observedDead = 0, 0
        local ok, err = pcall(function()
            humanoid:EquipTool(knife)
            task.wait(0.15)
            for index, target in ipairs(targets) do
                if not validSweep(state, token) then break end
                local victim = target.Character
                if sweepTargetAllowed(victim) then
                    attempted = attempted + 1
                    local deadline, nextAttack = os.clock() + 3, 0
                    notify("Sweep " .. index .. "/" .. #targets .. " · " .. target.DisplayName)
                    while validSweep(state, token) and target.Character == victim and sweepTargetAllowed(victim) and os.clock() < deadline do
                        local targetRoot = victim:FindFirstChild("HumanoidRootPart")
                        if not targetRoot then break end
                        humanoid.AutoRotate = false
                        local position = (targetRoot.CFrame * CFrame.new(0, 0, 2.5)).Position
                        if not outsideSpawn(position, true) then break end
                        local facing = Vector3.new(targetRoot.Position.X, position.Y, targetRoot.Position.Z)
                        character:PivotTo(CFrame.lookAt(position, facing))
                        zeroVelocity(character)
                        if knife.Parent ~= character then humanoid:EquipTool(knife) end
                        if knife.Enabled and os.clock() >= nextAttack and sweepTargetAllowed(victim)
                            and outsideSpawn(character:GetPivot().Position, true) then
                            nextAttack = os.clock() + settings.attackInterval
                            knife:Activate()
                            task.delay(0.12, function()
                                if validSweep(state, token) and knife.Parent then pcall(function() knife:Deactivate() end) end
                            end)
                        end
                        RunService.Heartbeat:Wait()
                    end
                    if target.Character == victim and not living(victim) then observedDead = observedDead + 1 end
                end
            end
        end)
        if sweepState == state and token == sweepGeneration then
            stopSweep(true)
            if ok then
                notify("Sweep finished · " .. attempted .. " visited; " .. observedDead .. " observed down")
            else
                notify("Sweep stopped: " .. tostring(err), true)
            end
        end
    end)
    return true
end
sweepButton = button(UIRefs.knifePage, "Kill all · murderer sweep", startSweep)
sweepButton.TextColor3 = colors.murderer
button(UIRefs.knifePage, "Stop murderer sweep", function() stopSweep(true); notify("Sweep stopped") end)
slider(UIRefs.knifePage, "Knife attack interval", "attackInterval", 0.35, 1.5, function(v) return string.format("%.2f s", v) end)

local CandySweep = (function()
    local api, consumed, retryAt = {}, false, 0
    function api.Reset() consumed, retryAt = false, 0 end
    function api.Update()
        if not settings.candySweep or not living(player.Character) then return end
        if Scare and Scare.Busy() then return end
        if Fling and Fling.Busy() then return end
        local count = Automation.CandyCount()
        if count == 0 then consumed = false end
        if not count or count < 50 or consumed or os.clock() < retryAt then return end
        if not localKnife() or sweepState or (Evade and Evade.Busy()) then return end
        retryAt = os.clock() + 3
        if startSweep(true) then consumed = true end
    end
    return api
end)()
section(UIRefs.knifePage, "Candy response")
toggle(UIRefs.knifePage, "Knife sweep at 50 candies · murderer", "candySweep")
slider(UIRefs.knifePage, "Protected spawn radius", "spawnRadius", 30, 300, function(v)
    return string.format("%.0f studs", v)
end)
button(UIRefs.knifePage, "Check candy counter", function()
    local count = Automation.CandyCount()
    notify(count and ("Current bag count: " .. count) or "No unambiguous numeric bag count found", count == nil)
end)

-- Bounded local collision attempt; never writes another character's physics properties.
Fling = (function()
    local api, state = {}, nil
    function api.Busy() return state ~= nil end
    function api.Stop(returnToStart)
        local old = state
        state = nil
        if not old then return end
        for _, object in ipairs(old.objects) do object:Destroy() end
        for _, connection in ipairs(old.connections) do connection:Disconnect() end
        for part, original in pairs(old.collisions) do
            if part.Parent then part.CanCollide = original end
        end
        if old.humanoid.Parent then
            old.humanoid.AutoRotate, old.humanoid.PlatformStand = old.autoRotate, old.platformStand
        end
        if old.character == player.Character and living(old.character) then
            if returnToStart then old.character:PivotTo(old.origin) end
            zeroVelocity(old.character)
        end
    end
    function api.Start(target)
        if Scare then Scare.Stop(true) end
        api.Stop(true)
        if not target or target == player or target.Parent ~= Players or not living(target.Character) then
            notify("Select another living player", true); return false
        end
        local victim = target.Character
        local targetRoot = victim:FindFirstChild("HumanoidRootPart")
        if not living(player.Character) or not targetRoot or targetRoot.Anchored then
            notify("Both characters must be available and unanchored", true); return false
        end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if root.Anchored or humanoid.Sit or not outsideSpawn(root.Position, true) or not outsideSpawn(targetRoot.Position, true) then
            notify("Fling blocked: stand up, use an unanchored character and stay outside any marked spawn area", true); return false
        end
        VisualSpin.Reset(); Mobility.Reset()
        if Evade then Evade.Stop(true) end
        stopCollecting(true, true)
        Automation.StopBag(true)
        if stopSweep then stopSweep(true) end
        state = {character = player.Character, root = root, humanoid = humanoid, target = target,
            victim = victim, origin = player.Character:GetPivot(), autoRotate = humanoid.AutoRotate,
            platformStand = humanoid.PlatformStand, started = os.clock(), deadline = os.clock() + 3,
            collisions = {}, objects = {}, connections = {}, contacts = 0}
        local ok, err = pcall(function()
            humanoid.AutoRotate, humanoid.PlatformStand = false, true
            local attachment = make("Attachment", {Name = "StarfireFlingAttachment"}, root)
            table.insert(state.objects, attachment)
            local angular = make("AngularVelocity", {Name = "StarfireFlingAngular", Attachment0 = attachment,
                RelativeTo = Enum.ActuatorRelativeTo.World, MaxTorque = 5000000,
                AngularVelocity = Vector3.new(1, 1, 1).Unit * settings.flingStrength}, root)
            table.insert(state.objects, angular)
            local linear = make("LinearVelocity", {Name = "StarfireFlingLinear", Attachment0 = attachment,
                RelativeTo = Enum.ActuatorRelativeTo.World, VelocityConstraintMode = Enum.VelocityConstraintMode.Vector,
                ForceLimitsEnabled = true, MaxForce = 300000, VectorVelocity = Vector3.zero}, root)
            table.insert(state.objects, linear)
            state.linear, state.angular = linear, angular
            local position = targetRoot.Position + Vector3.new(1.5, 0, 0)
            if not outsideSpawn(position, true) then error("Target moved into protected spawn") end
            state.character:PivotTo(CFrame.new(position))
        end)
        if not ok then api.Stop(true); notify("Fling stopped: " .. tostring(err), true); return false end
        notify("Fling attempt: " .. target.DisplayName .. " · 3 seconds")
        return true
    end
    function api.Step()
        local current = state
        if not current then return end
        local targetRoot = current.victim:FindFirstChild("HumanoidRootPart")
        if not running or current.character ~= player.Character or not living(current.character)
            or current.target.Parent ~= Players or current.target.Character ~= current.victim
            or not living(current.victim) or not targetRoot or targetRoot.Anchored or current.root.Anchored
            or os.clock() >= current.deadline or not outsideSpawn(targetRoot.Position, true)
            or not outsideSpawn(current.root.Position, true) then
            local contacts = current.contacts
            api.Stop(true)
            notify(contacts > 0 and "Fling ended · player contact observed"
                or "Fling ended · no player contact detected; collision rules may prevent it", contacts == 0)
            return
        end
        for _, part in ipairs(current.character:GetDescendants()) do
            if part:IsA("BasePart") then
                if current.collisions[part] == nil then
                    current.collisions[part] = part.CanCollide
                    if part.Touched then
                        table.insert(current.connections, part.Touched:Connect(function(hit)
                            if state == current and hit:IsDescendantOf(current.victim) then current.contacts = current.contacts + 1 end
                        end))
                    end
                end
                part.CanCollide = true
            end
        end
        local delta = targetRoot.Position - current.root.Position
        if delta.Magnitude > 40 then api.Stop(true); notify("Fling stopped: target out of reach"); return end
        local elapsed = os.clock() - current.started
        local velocity = targetRoot.AssemblyLinearVelocity or Vector3.zero
        local lead = velocity * 0.08
        if lead.Magnitude > 4 then lead = lead.Unit * 4 end
        local contactOffset = Vector3.new(math.sin(elapsed * 12) * 0.65, math.sin(elapsed * 18) * 0.25, math.cos(elapsed * 12) * 0.65)
        local steering = targetRoot.Position + lead + contactOffset - current.root.Position
        current.linear.VectorVelocity = steering.Magnitude > 0.1 and steering.Unit * math.min(70, steering.Magnitude * 35) or Vector3.zero
        current.angular.AngularVelocity = Vector3.new(1, 1, 1).Unit * settings.flingStrength
    end
    return api
end)()
local flingTarget
local flingSelector
local function chooseFlingTarget()
    local candidates = {}
    for _, other in ipairs(Players:GetPlayers()) do if other ~= player then table.insert(candidates, other) end end
    table.sort(candidates, function(a, b) return a.Name < b.Name end)
    local index = table.find(candidates, flingTarget) or 0
    flingTarget = candidates[index % math.max(1, #candidates) + 1]
    flingSelector.Text = flingTarget and ("Target: " .. flingTarget.DisplayName .. " (@" .. flingTarget.Name .. ")") or "Target: no other players"
end
section(UIRefs.playersPage, "Fling")
flingSelector = button(UIRefs.playersPage, "Select fling target · click to cycle", chooseFlingTarget)
slider(UIRefs.playersPage, "Fling strength", "flingStrength", 80, 720, function(v) return string.format("%.0f rad/s", v) end)
button(UIRefs.playersPage, "Fling selected player · 3 second attempt", function() Fling.Start(flingTarget) end)
button(UIRefs.playersPage, "Stop fling and return", function() Fling.Stop(true) end)
connect(RunService.PreSimulation, function()
    if not running then return end
    local ok, err = pcall(Fling.Step)
    if not ok then Fling.Stop(true); notify("Fling stopped: " .. tostring(err), true) end
end)

-- React only to identifiable replicated attacks, never arbitrary movement animations.
Scare = (function()
    local api, state = {}, nil
    function api.Busy() return state ~= nil end
    function api.Direction() return state and state.direction end
    function api.Stop(returnToStart)
        local old = state
        state = nil
        if not old then return end
        for part, original in pairs(old.collisions) do if part.Parent then part.CanCollide = original end end
        if old.humanoid.Parent then old.humanoid.AutoRotate = old.autoRotate end
        if player.Character == old.character and living(old.character) then
            if returnToStart then old.character:PivotTo(old.origin) end
            zeroVelocity(old.character)
        end
    end
    function api.Start(target)
        api.Stop(true)
        if not target or target == player or target.Parent ~= Players or not living(target.Character) or not living(player.Character) then
            notify("Select another living player for Scare", true); return false
        end
        local character = player.Character
        local root = character:FindFirstChild("HumanoidRootPart")
        local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if root.Anchored or humanoid.Sit or not targetRoot then notify("Stand up with a movable character first", true); return false end
        Fling.Stop(true); Evade.Stop(true)
        if stopSweep then stopSweep(true) end
        stopCollecting(true, true); Automation.StopBag(true)
        Mobility.Reset(); VisualSpin.Reset()
        local forward = Vector3.new(targetRoot.CFrame.LookVector.X, 0, targetRoot.CFrame.LookVector.Z)
        if forward.Magnitude < 0.01 then notify("Target facing direction unavailable", true); return false end
        forward = forward.Unit
        local centre = targetRoot.Position + Vector3.new(0, 1.5, 0)
        state = {character = character, root = root, humanoid = humanoid, target = target,
            victim = target.Character, origin = character:GetPivot(), autoRotate = humanoid.AutoRotate,
            from = centre - forward * 10, direction = forward, travelled = 0, collisions = {}, elapsed = 0}
        humanoid.AutoRotate = false
        local ok, err = pcall(function()
            api.Step(0)
        end)
        if not ok then api.Stop(true); notify("Scare stopped: " .. tostring(err), true); return false end
        notify("Scare pass · " .. target.DisplayName)
        return true
    end
    function api.Step(dt)
        local current = state
        if not current then return end
        current.elapsed = current.elapsed + math.max(0, dt)
        if not running or player.Character ~= current.character or not living(current.character)
            or current.target.Parent ~= Players or current.target.Character ~= current.victim
            or not living(current.victim) or current.root.Anchored or current.humanoid.Sit or current.elapsed > 6 then
            api.Stop(true); return
        end
        for _, part in ipairs(current.character:GetDescendants()) do
            if part:IsA("BasePart") then
                if current.collisions[part] == nil then current.collisions[part] = part.CanCollide end
                part.CanCollide = false
            end
        end
        current.travelled = math.min(20, current.travelled + settings.scareSpeed * math.clamp(dt, 0, 0.1))
        local position = current.from + current.direction * current.travelled
        current.character:PivotTo(CFrame.lookAt(position, position + current.direction))
        zeroVelocity(current.character)
        if current.travelled >= 20 then api.Stop(false); notify("Scare pass finished") end
    end
    return api
end)()
section(UIRefs.playersPage, "Scare")
local scareTarget, scareSelector
scareSelector = button(UIRefs.playersPage, "Select scare target · click to cycle", function()
    local candidates = {}
    for _, other in ipairs(Players:GetPlayers()) do if other ~= player then table.insert(candidates, other) end end
    table.sort(candidates, function(a, b) return a.Name < b.Name end)
    local index = table.find(candidates, scareTarget) or 0
    scareTarget = candidates[index % math.max(1, #candidates) + 1]
    scareSelector.Text = scareTarget and ("Scare: " .. scareTarget.DisplayName .. " (@" .. scareTarget.Name .. ")") or "Scare: no other players"
end)
slider(UIRefs.playersPage, "Scare glide speed", "scareSpeed", 5, 100, function(v) return string.format("%.0f studs/s", v) end)
button(UIRefs.playersPage, "Scare · glide past selected player", function() Scare.Start(scareTarget) end)
button(UIRefs.playersPage, "Stop scare and return", function() Scare.Stop(true) end)
connect(RunService.PreSimulation, function(dt)
    local ok, err = pcall(Scare.Step, dt)
    if not ok then Scare.Stop(true); notify("Scare stopped: " .. tostring(err), true) end
end)

-- Replicated swing detection for the separate knife-dodge feature.
Evade = (function()
    local api, hub, state = {}, nil, nil
    local watchers, attacks, explicitIds = {}, {}, {}
    local projectiles,projectileScan={},false
    local function candidate(part)
        if not part:IsA("BasePart") or part:IsDescendantOf(effects) then return false end
        local node,named=part,false
        for i=1,5 do
            if not node or node==Workspace then break end
            if node:IsA("Tool") or (node:IsA("Model") and Players:GetPlayerFromCharacter(node)) then return false end
            local name=node.Name:lower()
            if name:find("knife",1,true) then named=true end
            node=node.Parent
        end
        if not named then return false end
        for _,key in ipairs({"Owner","Thrower","Player"}) do
            local owner=part:GetAttribute(key)
            local value=part:FindFirstChild(key)
            if value and value:IsA("ObjectValue") then owner=value.Value end
            if owner then
                for other,entry in pairs(entries) do
                    if owner==other or owner==other.Character or owner==other.Name or owner==other.UserId then
                        return other~=player and entry.role=="murderer"
                    end
                end
                return false
            end
        end
        local cached=projectiles[part]
        if cached and cached.owner then
            local entry=entries[cached.owner]
            return entry and entry.role=="murderer" and living(entry.character) or false
        end
        return false
    end
    local function watchProjectile(part)
        if not settings.knifeDodge or not part:IsA("BasePart") or part:IsDescendantOf(effects) then return end
        if candidate(part) then projectiles[part]={position=part.Position,time=os.clock()};return end
        if part:FindFirstAncestorOfClass("Tool") then return end
        local node=part
        local named=false
        for _=1,4 do
            if not node or node==Workspace then break end
            if node:IsA("Model") and Players:GetPlayerFromCharacter(node) then return end
            if node.Name:lower():find("knife",1,true) then named=true end
            node=node.Parent
        end
        if not named then return end
        for other,entry in pairs(entries) do
            local root=entry.character and entry.character:FindFirstChild("HumanoidRootPart")
            if entry.role=="murderer" and root and living(entry.character) and (part.Position-root.Position).Magnitude<8 then
                projectiles[part]={position=part.Position,time=os.clock(),owner=other};return
            end
        end
    end
    connect(Workspace.DescendantAdded,function(part)
        if settings.knifeDodge and part:IsA("BasePart") then task.defer(function() if part.Parent then watchProjectile(part) end end) end
    end)
    local function incoming(position,velocity,target,targetVelocity,radius)
        if velocity.Magnitude<18 then return false end
        local relative=position-target
        if relative:Dot(velocity)>=0 then return false end
        local motion=velocity-targetVelocity
        local speed2=motion:Dot(motion)
        if speed2<144 or relative:Dot(motion)>=0 then return false end
        local time=-relative:Dot(motion)/speed2
        if time<0 or time>.45 then return false end
        return (relative+motion*time).Magnitude<=radius
    end
    local function thrownThreat(position,root)
        if not projectileScan then
            projectileScan=true
            -- Only newly replicated throws are watched; existing map knives are ignored.
        end
        local now=os.clock()
        for part,sample in pairs(projectiles) do
            if not part.Parent or not candidate(part) then projectiles[part]=nil
            else
                local location=part.Position
                local elapsed=now-sample.time
                local velocity=part.AssemblyLinearVelocity
                if elapsed>.008 and elapsed<.25 then
                    local measured=(location-sample.position)/elapsed
                    if measured.Magnitude>velocity.Magnitude then velocity=measured end
                end
                sample.position=location;sample.time=now
                if (location-position).Magnitude<=math.max(45,settings.dodgeRadius*4)
                    and incoming(location,velocity,position,state and Vector3.zero or root.AssemblyLinearVelocity,
                        3+math.min(part.Size.Magnitude*.5,1)) then return true end
            end
        end
        return false
    end
    local readyAt = 0
    local statusText, lastUnrecognised = "Disabled", nil
    local lastEvent="No threat detected yet"
    local function equippedKnife(character)
        local knife = character and (character:FindFirstChild("Knife") or character:FindFirstChild("knife"))
        return knife and knife:IsA("Tool") and knife or nil
    end
    local function attackAnimation(track)
        local animationObject = track.Animation
        if not animationObject then return false end
        local id = animationObject.AnimationId:match("%d+")
        if id and explicitIds[id] then return true end
        local name = string.lower(track.Name .. " " .. animationObject.Name)
        if name:find("idle", 1, true) or name:find("equip", 1, true) then return false end
        local named = name:find("slash", 1, true) ~= nil or name:find("stab", 1, true) ~= nil
            or name:find("swing", 1, true) ~= nil or name:find("attack", 1, true) ~= nil
        if named then return true end
        local priority = track.Priority
        return priority ~= nil and priority.Value >= Enum.AnimationPriority.Action.Value and not track.Looped
    end
    function api.Busy() return state ~= nil end
    function api.HubPosition() return hub and hub.Position end
    function api.Status()
        local count,nearest=0,nil
        local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        for _,entry in pairs(entries) do
            local enemyRoot=entry.character and entry.character:FindFirstChild("HumanoidRootPart")
            if entry.role=="murderer" and enemyRoot and root and living(entry.character) then
                count=count+1
                local distance=(enemyRoot.Position-(state and state.origin.Position or root.Position)).Magnitude
                nearest=not nearest and distance or math.min(nearest,distance)
            end
        end
        return statusText.."\nMurderers observed: "..count..(nearest and string.format(" · nearest %.1f studs",nearest) or "").."\n"..lastEvent
    end
    function api.Stop(returnToOrigin)
        local old = state
        state = nil
        if not old then return end
        if old.camera == Workspace.CurrentCamera then
            old.camera.CFrame, old.camera.Focus = old.view, old.focus
            old.camera.CameraSubject, old.camera.CameraType = old.subject, old.cameraType
        end
        if player.Character == old.character and living(old.character) then
            if returnToOrigin then old.character:PivotTo(old.origin); zeroVelocity(old.character) end
            old.humanoid.AutoRotate = old.autoRotate
        end
        readyAt = os.clock() + 0.15
    end
    local function beginDodge()
        if Scare and Scare.Busy() then statusText="Blocked · scare is active";return end
        if Fling and Fling.Busy() then statusText="Blocked · fling is active";return end
        if not hub then statusText = "Set a hub destination first"; return false end
        if state or not (settings.knifeDodge or settings.proximityDodge) or os.clock() < readyAt then return false end
        local character, camera = player.Character, Workspace.CurrentCamera
        if not camera or not living(character) then return end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        VisualSpin.Reset()
        -- Pause competing writers before recording the return point; preserve collector intention.
        Automation.StopCollect(false, true)
        Automation.StopBag(true)
        Mobility.Reset()
        if stopSweep then stopSweep(true) end
        state = {character = character, humanoid = humanoid, origin = character:GetPivot(),
            camera = camera, view = camera.CFrame, focus = camera.Focus,
            subject = camera.CameraSubject, cameraType = camera.CameraType,
            autoRotate = humanoid.AutoRotate, quietSince = nil}
        humanoid.AutoRotate = false
        camera.CameraType = Enum.CameraType.Scriptable
        character:PivotTo(hub)
        zeroVelocity(character)
        statusText = "Dodging · at saved hub"
        lastEvent="Teleport requested · "..os.date("%H:%M:%S")
        task.defer(function()
            if state and player.Character==character then
                local actual=character:GetPivot().Position
                if (actual-hub.Position).Magnitude>8 then lastEvent="Teleport did not reach saved hub" end
            end
        end)
        return true
    end
    local function threatened()
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if not root then return false end
        local position = state and state.origin.Position or root.Position
        if settings.proximityDodge then
            local radius=settings.proximityDodgeRadius + (state and 2 or 0)
            for other,entry in pairs(entries) do
                local enemy=entry.character
                local enemyRoot=enemy and enemy:FindFirstChild("HumanoidRootPart")
                if other~=player and enemyRoot and living(enemy)
                    and entry.role=="murderer" and not UIRefs.roundState.InHub(other)
                    and (enemyRoot.Position-position).Magnitude<=radius then return true end
            end
        end
        if not settings.knifeDodge then return false end
        if thrownThreat(position,root) then lastEvent="Incoming thrown knife detected";return true end
        -- Recheck active tracks: an animation may start before role discovery or watcher setup.
        for other,entry in pairs(entries) do
            local enemy=entry.character
            local enemyRoot=enemy and enemy:FindFirstChild("HumanoidRootPart")
            if entry.role=="murderer" and enemyRoot and living(enemy) and equippedKnife(enemy)
                and not UIRefs.roundState.InHub(other) and (enemyRoot.Position-position).Magnitude<=settings.dodgeRadius then
                local humanoid=enemy:FindFirstChildOfClass("Humanoid")
                local animator=humanoid and humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    for _,track in ipairs(animator:GetPlayingAnimationTracks()) do
                        if track.IsPlaying and attackAnimation(track) then
                            lastEvent="Murderer swing detected";return true
                        end
                    end
                end
            end
        end
        for animationTrack, attack in pairs(attacks) do
            local entry = entries[attack.owner]
            local victim = entry and entry.character
            local knife = equippedKnife(victim)
            local enemyRoot = victim and victim:FindFirstChild("HumanoidRootPart")
            if not animationTrack.IsPlaying or not entry or victim ~= attack.character or not living(victim) then
                attacks[animationTrack] = nil
            elseif entry.role=="murderer" and not UIRefs.roundState.InHub(attack.owner) and knife and knife:IsA("Tool") and enemyRoot
                and (enemyRoot.Position - position).Magnitude <= settings.dodgeRadius then
                return true
            end
        end
        return false
    end
    local function observeTrack(other, character, animationTrack)
        if not entries[other] or entries[other].role~="murderer" or not equippedKnife(character) then return end
        if not attackAnimation(animationTrack) then
            local animation = animationTrack.Animation
            lastUnrecognised = animation and (animation.AnimationId:match("%d+") or animationTrack.Name) or animationTrack.Name
            return
        end
        lastUnrecognised = nil
        attacks[animationTrack] = {owner = other, character = character}
        if threatened() then beginDodge() end
    end
    function api.Refresh()
        for other, watch in pairs(watchers) do
            local entry = entries[other]
            if not entry or entry.character ~= watch.character or not watch.animator.Parent then
                watch.connection:Disconnect(); watchers[other] = nil
            end
        end
        for other, entry in pairs(entries) do
            if not watchers[other] then
                local humanoid = entry.character:FindFirstChildOfClass("Humanoid")
                local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
                if animator then
                    local character = entry.character
                    watchers[other] = {character = character, animator = animator,
                        connection = animator.AnimationPlayed:Connect(function(animationTrack)
                            observeTrack(other, character, animationTrack)
                        end)}
                    for _, animationTrack in ipairs(animator:GetPlayingAnimationTracks()) do
                        observeTrack(other, character, animationTrack)
                    end
                end
            end
        end
    end
    function api.Step()
        if not (settings.knifeDodge or settings.proximityDodge) then api.Stop(true);projectileScan=false;table.clear(projectiles); statusText = "Disabled"; return end
        if not living(player.Character) then api.Stop(false); statusText = "Waiting for a living character"; return end
        if not hub then api.Stop(false); statusText = "Set a hub destination first"; return end
        if state and (player.Character ~= state.character or Workspace.CurrentCamera ~= state.camera) then
            api.Stop(false); return
        end
        local danger = threatened() or (state and state.testUntil and os.clock() < state.testUntil)
        if danger then beginDodge() end
        if not state then
            statusText = lastUnrecognised and ("Unrecognised knife animation: " .. lastUnrecognised .. " · add its ID below")
                or (settings.proximityDodge and "Ready · watching murderer proximity" or "Ready · watching swings and incoming thrown knives")
            return
        end
        statusText = danger and "Dodging · at saved hub" or "Area clear · returning shortly"
        if danger then state.quietSince = nil
        elseif not state.quietSince then state.quietSince = os.clock()
        elseif os.clock() - state.quietSince >= 0.2 then api.Stop(true); return end
        state.character:PivotTo(hub)
        zeroVelocity(state.character)
    end
    function api.Camera()
        if state then state.camera.CFrame, state.camera.Focus = state.view, state.focus end
    end
    function api.SetHub()
        if state then notify("Stop the dodge before setting the hub", true); return end
        if not living(player.Character) then notify("Set the hub while alive in the lobby", true); return end
        hub = player.Character:GetPivot()
        notify("Hub saved at your current position · set this while in the lobby")
    end
    function api.Test()
        if not (settings.knifeDodge or settings.proximityDodge) then notify("Enable a dodge option before testing", true); return false end
        if not hub then notify("Set a hub destination before testing", true); return false end
        if beginDodge() then state.testUntil = os.clock() + 0.6; return true end
        notify("Dodge test could not start; stop other movement actions first", true); return false
    end
    function api.SetIds(text)
        explicitIds = {}
        for id in text:gmatch("%d+") do explicitIds[id] = true end
        notify("Swing IDs updated; named slash/stab/swing/attack animations also detected")
    end
    function api.Cleanup()
        api.Stop(true)
        for _, watch in pairs(watchers) do watch.connection:Disconnect() end
        table.clear(watchers); table.clear(attacks);table.clear(projectiles);projectileScan=false
    end
    return api
end)()
toggle(UIRefs.dodgePage, "Knife dodge · experimental", "knifeDodge", function(enabled)
    if not enabled and not settings.proximityDodge then Evade.Stop(true) end
    if enabled and not Evade.HubPosition() then notify("Knife dodge needs a destination: stand in the lobby and click Set hub", true) end
end)
toggle(UIRefs.dodgePage,"Proximity dodge · murderer nearby","proximityDodge",function(enabled)
    if not enabled and not settings.knifeDodge then Evade.Stop(true) end
    if enabled and not Evade.HubPosition() then notify("Set a hub destination before using proximity dodge",true) end
end)
slider(UIRefs.dodgePage,"Proximity dodge distance","proximityDodgeRadius",5,50,function(v) return string.format("%.0f studs",v) end)
button(UIRefs.dodgePage, "Set hub to current position", function() Evade.SetHub() end)
button(UIRefs.dodgePage, "Test dodge · teleport and return", function() Evade.Test() end)
UIRefs.dodgeStatus = label(UIRefs.dodgePage, "Disabled", 13, colors.text)
UIRefs.dodgeStatus.Size, UIRefs.dodgeStatus.TextWrapped = UDim2.new(1, -4, 0, 90), true
UIRefs.dodgeStatus:SetAttribute("SearchText", "Knife dodge status")
slider(UIRefs.dodgePage, "Knife detection radius", "dodgeRadius", 5, 25, function(v) return string.format("%.0f studs", v) end)
UIRefs.swingIds = make("TextBox", {Text = "", PlaceholderText = "Optional swing animation IDs, separated by commas",
    ClearTextOnFocus = false, TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
    BackgroundColor3 = colors.background, Size = UDim2.new(1, -2, 0, 42),
    Font = Enum.Font.GothamBold, TextSize = 12, BorderSizePixel = 0}, UIRefs.dodgePage)
round(UIRefs.swingIds, 3)
connect(UIRefs.swingIds.FocusLost, function() Evade.SetIds(UIRefs.swingIds.Text) end)
button(UIRefs.dodgePage, "Stop dodge and return", function() Evade.Stop(true) end)
connect(RunService.Heartbeat, function()
    local ok,err=pcall(Evade.Step)
    UIRefs.dodgeStatus.Text=ok and Evade.Status() or ("Dodge error: "..tostring(err))
end)

UIRefs.emoteId = make("TextBox", {Text = "", PlaceholderText = "Animation ID or equipped emote ID",
    ClearTextOnFocus = false, TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
    BackgroundColor3 = colors.background, Size = UDim2.new(1, -2, 0, 42),
    Font = Enum.Font.GothamBold, TextSize = 13, BorderSizePixel = 0}, UIRefs.emotes)
round(UIRefs.emoteId, 3); stroke(UIRefs.emoteId)
local loadingEmote, emoteVersion = false, 0
local function stopEmote()
    emoteVersion = emoteVersion + 1
    loadingEmote = false
    if track then pcall(function() track:Stop(0.15); track:Destroy() end); track = nil end
    if animation then animation:Destroy(); animation = nil end
end
toggle(UIRefs.emotes, "Loop emote", "loopEmote")
slider(UIRefs.emotes, "Animation speed", "emoteSpeed", 0.1, 3, function(v)
    return string.format("%.2f×", v)
end, function(speed)
    if track then
        local ok, err = pcall(function() track:AdjustSpeed(speed) end)
        if not ok then notify("Could not change animation speed: " .. tostring(err), true) end
    end
end)
button(UIRefs.emotes, "Play animation / equipped emote", function()
    if loadingEmote then return end
    local id = UIRefs.emoteId.Text:match("^%s*(%d+)%s*$") or UIRefs.emoteId.Text:match("^rbxassetid://(%d+)$")
    if not id or tonumber(id) == 0 then notify("Enter a numeric animation or equipped emote ID", true); return end
    if not living(player.Character) then notify("You need a living character", true); return end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    if not animator then notify("Your character has no replicated Animator", true); return end
    stopEmote()
    loadingEmote = true
    local version = emoteVersion
    notify("Loading animation…")
    task.spawn(function()
        local function reportError(message)
            if running and version == emoteVersion then loadingEmote = false; notify(message, true) end
        end
        local registeredName
        pcall(function()
            local description = humanoid:GetAppliedDescription()
            for name, ids in pairs(description:GetEmotes()) do
                for _, value in ipairs(ids) do
                    if tostring(value) == id then registeredName = name end
                end
            end
            description:Destroy()
        end)
        local item, result
        if registeredName then
            local before, captured = {}, {}
            for _, existing in ipairs(animator:GetPlayingAnimationTracks()) do before[existing] = true end
            local listener = connect(animator.AnimationPlayed, function(value)
                if not before[value] then table.insert(captured, value) end
            end)
            local ok, played = pcall(function() return humanoid:PlayEmoteAsync(registeredName) end)
            RunService.Heartbeat:Wait()
            listener:Disconnect()
            if not ok or not played then reportError("Equipped emote failed: " .. tostring(played)); return end
            for _, value in ipairs(captured) do
                if value.IsPlaying then
                    if result and result ~= value then
                        reportError("Several animations started; stop other animations and retry")
                        return
                    end
                    result = value
                end
            end
            if not result then reportError("Emote started, but its animation track could not be identified"); return end
        else
            if id == "115616157608620" then
                reportError("Spin (Loop) is a catalogue emote. Equip it on your avatar, respawn, then retry.")
                return
            end
            item = Instance.new("Animation")
            item.AnimationId = "rbxassetid://" .. id
            local ok, loaded = pcall(function() return animator:LoadAnimation(item) end)
            if not ok then item:Destroy(); reportError("Animation failed: " .. tostring(loaded)); return end
            result = loaded
        end
        if not running or version ~= emoteVersion then
            pcall(function() result:Stop(); result:Destroy() end)
            if item then item:Destroy() end
            return
        end
        loadingEmote = false
        animation, track = item, result
        track.Looped, track.Priority = settings.loopEmote, Enum.AnimationPriority.Action
        local played, err = pcall(function()
            if track.IsPlaying then track:AdjustSpeed(settings.emoteSpeed)
            else track:Play(0.15, 1, settings.emoteSpeed) end
        end)
        if not played then stopEmote(); notify(tostring(err), true); return end
        local deadline = os.clock() + 10
        while running and version == emoteVersion and track == result and result.Length == 0 and os.clock() < deadline do
            task.wait(0.1)
        end
        if running and version == emoteVersion and track == result then
            if result.Length == 0 then
                stopEmote()
                notify("Roblox did not load this animation; check permissions, rig, or use an equipped emote ID", true)
            else
                notify("Playing " .. (registeredName or id) .. " · " .. string.format("%.2f×", settings.emoteSpeed))
            end
        end
    end)
end)
button(UIRefs.emotes, "Stop emote", function() stopEmote(); notify("Emote stopped") end)

local function aimTarget(camera, requireSight)
    local character = player.Character
    if not living(character) then return nil end
    local center = camera.ViewportSize / 2
    local best, part, bestDistance
    for other, entry in pairs(entries) do
        if entry.role == "murderer" and living(entry.character) then
            local targetPart = entry.character:FindFirstChild("UpperTorso") or entry.character:FindFirstChild("Torso")
                or entry.character:FindFirstChild("LowerTorso") or entry.character:FindFirstChild("HumanoidRootPart")
            if targetPart then
                local screen, visible = camera:WorldToViewportPoint(targetPart.Position)
                local distance = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                if visible and screen.Z > 0 and distance <= settings.fov and (not bestDistance or distance < bestDistance) then
                    local clear = true
                    if settings.wallCheck or requireSight then
                        local params = RaycastParams.new()
                        params.FilterType = Enum.RaycastFilterType.Exclude
                        params.FilterDescendantsInstances = {character, camera}
                        params.IgnoreWater = true
                        local hit = Workspace:Raycast(camera.CFrame.Position, targetPart.Position - camera.CFrame.Position, params)
                        clear = not hit or hit.Instance:IsDescendantOf(entry.character)
                    end
                    if clear then best, part, bestDistance = other, targetPart, distance end
                end
            end
        end
    end
    return best, part
end
-- Optional gun-scoped adaptation of the supplied universal hook approach.
-- Requires nonstandard runtime hook APIs; standard Roblox clients cannot install it.
-- MM2-specific remote-call adaptation; reference: Aluxis/MM2-Utilities main.lua.
-- Independently implemented: only the equipped gun's existing ShootGun call is amended.
SilentAim=(function()
    local api,installed,remote,gun,point,expires={},false,nil,nil,nil,0
    local status="Off"
    local resolvedGun,resolvedRemote,nextLookup=nil,nil,0
    function api.Stop() remote=nil;gun=nil;point=nil;expires=0 end
    function api.Install()
        if installed then return true end
        if type(hookmetamethod)~="function" or type(getnamecallmethod)~="function" then
            status="Unavailable · remote hook APIs missing";return false
        end
        local wrap=type(newcclosure)=="function" and newcclosure or function(fn) return fn end
        local previous
        local ok=pcall(function()
            previous=hookmetamethod(game,"__namecall",wrap(function(object,...)
                -- No camera, mouse, raycast or unrelated remote interception.
                if running and settings.silentAim and object==remote and getnamecallmethod()=="InvokeServer" then
                    local args=table.pack(...)
                    local safe,redirected=pcall(function()
                        if not gun or gun.Parent~=player.Character or not point or os.clock()>expires then return false end
                        if type(checkcaller)=="function" and checkcaller() then return false end
                        if args.n<2 or typeof(args[2])~="Vector3" then status="Gun arguments differ · original shot preserved";return false end
                        if math.random()*100>settings.silentHitChance then return false end
                        args[2]=point
                        return true
                    end)
                    if safe and redirected then return previous(object,table.unpack(args,1,args.n)) end
                end
                return previous(object,...)
            end))
        end)
        if not ok then status="Remote hook installation failed";return false end
        installed=true;status="Installed · equip a gun";return true
    end
    local function resolveGunRemote(held)
        local localRemote=held:FindFirstChild("ShootGun",true)
        if localRemote and localRemote:IsA("RemoteFunction") then return localRemote end
        if resolvedGun==held and os.clock()<nextLookup then
            return resolvedRemote and resolvedRemote.Parent and resolvedRemote or nil
        end
        resolvedGun=held;resolvedRemote=nil;nextLookup=os.clock()+3
        local shared=game:GetService("ReplicatedStorage")
        local found,count=nil,0
        for _,object in ipairs(shared:GetDescendants()) do
            if object:IsA("RemoteFunction") and object.Name:lower()=="shootgun" then found=object;count=count+1 end
        end
        if count==1 then resolvedRemote=found;return found end
        if count>1 then status="Multiple ShootGun remotes · normal shots preserved"
        else status="ShootGun not found in gun/shared storage · normal shots preserved" end
        return nil
    end
    function api.Step()
        api.Stop()
        if not settings.silentAim then status="Off";return end
        if not installed then status="Unavailable · hooks not installed";return end
        local character,camera=player.Character,Workspace.CurrentCamera
        local held=character and character:FindFirstChild("Gun")
        if not held or not held:IsA("Tool") or not camera or not living(character) then status="Equip a gun while alive";return end
        local shoot=resolveGunRemote(held)
        if not shoot then return end
        local _,target=aimTarget(camera,true)
        if not target then status="Waiting · visible murderer in FOV";return end
        gun=held;remote=shoot;point=target.Position+target.AssemblyLinearVelocity*.025;expires=os.clock()+.15
        status="Ready · MM2 ShootGun redirection"
    end
    function api.Status() return status end
    return api
end)()
toggle(UIRefs.assistance,"Silent aim · gun only","silentAim",function(enabled)
    if enabled and not SilentAim.Install() then
        settings.silentAim=false
        if stateRefreshers.silentAim then stateRefreshers.silentAim() end
        notify(SilentAim.Status(),true)
    end
    if enabled and settings.silentAim and stateAppliers.aim then stateAppliers.aim(false) end
    if not enabled then SilentAim.Stop() end
end)
slider(UIRefs.assistance,"Silent aim hit chance","silentHitChance",0,100,function(v) return string.format("%.0f%%",v) end)
toggle(UIRefs.assistance,"Free camera while holding a gun","freeGunCamera")
UIRefs.silentStatus=label(UIRefs.assistance,"Off",12,colors.muted)
UIRefs.silentStatus.TextWrapped=true;UIRefs.silentStatus.Size=UDim2.new(1,-2,0,44)
UIRefs.silentStatus:SetAttribute("SearchText","Silent aim status")
local GunMarker = (function()
    local api, blend, lastTargetPosition, tracked = {}, 0, nil, nil
    local function muzzlePosition(gun)
        for _, object in ipairs(gun:GetDescendants()) do
            local name = string.lower(object.Name):gsub("[%s_]", "")
            if object:IsA("Attachment") and (name:find("muzzle", 1, true) or name:find("firepoint", 1, true)
                or name:find("bulletorigin", 1, true) or name == "barreltip") then return object.WorldPosition end
        end
        for _, object in ipairs(gun:GetDescendants()) do
            local name = string.lower(object.Name)
            if object:IsA("BasePart") and (name == "muzzle" or name == "tip" or name == "barrel") then
                return (object.CFrame * CFrame.new(0, 0, -object.Size.Z * 0.5)).Position
            end
        end
        local handle = gun:FindFirstChild("Handle")
        if handle and handle:IsA("BasePart") then return (handle.CFrame * CFrame.new(0, 0, -handle.Size.Z * 0.5)).Position end
    end
    function api.Step(camera, dt)
        gunCircle.Visible = false
        if not settings.gunCircle or not camera or not living(player.Character) then
            blend, lastTargetPosition, tracked = 0, nil, nil; return
        end
        local gun
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and string.lower(tool.Name) == "gun" then gun = tool; break end
        end
        if not gun then blend, lastTargetPosition, tracked = 0, nil, nil; return end
        local muzzle = muzzlePosition(gun)
        if not muzzle then return end
        local visibleFrame=GunViewmodel and GunViewmodel.Frame(camera)
        local handle=gun:FindFirstChild("Handle")
        if visibleFrame and handle then
            visibleFrame=Inspect and Inspect.Transform(visibleFrame) or visibleFrame
            muzzle=visibleFrame:PointToWorldSpace(handle.CFrame:PointToObjectSpace(muzzle)*settings.gunViewSize)
        end
        local muzzleScreen, muzzleVisible = camera:WorldToViewportPoint(muzzle)
        local target, part = aimTarget(camera, true)
        if part then
            if tracked ~= target then blend = 0 end
            tracked, lastTargetPosition = target, part.Position
        end
        blend = blend + ((part and 1 or 0) - blend) * (1 - math.exp(-14 * math.clamp(dt, 0, 0.1)))
        local destination = muzzleScreen
        if lastTargetPosition and blend > 0.001 then
            local screen, visible = camera:WorldToViewportPoint(lastTargetPosition)
            if visible and screen.Z > 0 then destination = muzzleScreen:Lerp(screen, blend)
            else blend, lastTargetPosition, tracked = 0, nil, nil end
        end
        if not muzzleVisible or muzzleScreen.Z <= 0 then
            if not part or blend < 0.95 then return end
            destination = camera:WorldToViewportPoint(part.Position)
        end
        gunCircle.Position = UDim2.fromOffset(destination.X, destination.Y)
        gunCircle.Size = UDim2.fromOffset(settings.gunCircleRadius * 2, settings.gunCircleRadius * 2)
        gunCircleStroke.Color = Color3.fromRGB(settings.gunCircleRed, settings.gunCircleGreen, settings.gunCircleBlue)
        gunCircleStroke.Transparency = 1 - settings.gunCircleOpacity
        gunCircle.Visible = true
    end
    return api
end)()
-- Cached wire adornments follow their visual parts without adding physical geometry.
-- Two shared wire batches, anchored to the camera independently of hidden source parts.
WireStyle=(function()
    local api,entries,groups={},{},{}
    local function restore(part,entry)
        if not part.Parent then return end
        part.LocalTransparencyModifier=entry.original;part.Transparency=entry.transparency
        part.Material=entry.material;part.Color=entry.color;entry.active=false
    end
    local function clear(group)
        if group.core then group.core:Destroy();group.core=nil end
        group.anchor=nil;group.signature=nil
    end
    function api.Register(part,kind,key)
        if entries[part] then return end
        key=key or part
        local group=groups[key]
        if not group then group={parts={},kind=kind,dirty=true};groups[key]=group end
        local entry={original=part.LocalTransparencyModifier,transparency=part.Transparency,material=part.Material,color=part.Color,group=group}
        entries[part]=entry;group.parts[part]=entry;group.dirty=true
    end
    function api.Remove(part)
        local entry=entries[part]
        if not entry then return end
        restore(part,entry);entry.group.parts[part]=nil;entry.group.dirty=true;entries[part]=nil
    end
    local nativeParts,nativeTool={},nil
    local function nativeKnife()
        local character,camera=player.Character,Workspace.CurrentCamera
        local held=character and character:FindFirstChildOfClass("Tool")
        local target=held and held.Name:lower()=="knife" and camera
            and (camera.CFrame.Position-camera.Focus.Position).Magnitude<1.2 and held or nil
        if target~=nativeTool then
            for part in pairs(nativeParts) do api.Remove(part) end
            table.clear(nativeParts);nativeTool=target
            if target then for _,part in ipairs(target:GetDescendants()) do
                if part:IsA("BasePart") then api.Register(part,"knife",target);nativeParts[part]=true end
            end end
        end
    end
    local function geometry(part)
        local result={}
        local size=part.Size*.5
        local function line(a,b) table.insert(result,a);table.insert(result,b) end
        if part:FindFirstChildOfClass("SpecialMesh") then
            for axis=1,2 do
                for i=0,11 do
                    local a,b=i*math.pi/6,(i+1)*math.pi/6
                    local function point(t)
                        if axis==1 then return Vector3.new(math.cos(t)*size.X,math.sin(t)*size.Y,0) end
                        if axis==2 then return Vector3.new(math.cos(t)*size.X,0,math.sin(t)*size.Z) end
                        return Vector3.new(0,math.cos(t)*size.Y,math.sin(t)*size.Z)
                    end
                    line(point(a),point(b))
                end
            end
        elseif part:IsA("WedgePart") then
            local v={Vector3.new(-size.X,-size.Y,-size.Z),Vector3.new(size.X,-size.Y,-size.Z),
                Vector3.new(-size.X,-size.Y,size.Z),Vector3.new(size.X,-size.Y,size.Z),
                Vector3.new(-size.X,size.Y,size.Z),Vector3.new(size.X,size.Y,size.Z)}
            for _,e in ipairs({{1,3},{3,5},{1,5}}) do line(v[e[1]],v[e[2]]) end
        else
            for _,x in ipairs({-1,1}) do
                for _,y in ipairs({-1,1}) do line(Vector3.new(x*size.X,y*size.Y,-size.Z),Vector3.new(x*size.X,y*size.Y,size.Z)) end
            end
            for _,z in ipairs({-1,1}) do
                for _,x in ipairs({-1,1}) do line(Vector3.new(x*size.X,-size.Y,z*size.Z),Vector3.new(x*size.X,size.Y,z*size.Z)) end
                for _,y in ipairs({-1,1}) do line(Vector3.new(-size.X,y*size.Y,z*size.Z),Vector3.new(size.X,y*size.Y,z*size.Z)) end
            end
        end
        return result
    end
    local function contours(part)
        local points={}
        if not part:FindFirstChildOfClass("SpecialMesh") then return points end
        local h=part.Size*.5
        local function surface(x,y,face)
            local depth=h.Z*math.sqrt(math.max(.02,1-(x/h.X)^2-(y/h.Y)^2))
            return Vector3.new(x,y,face*(depth+.001))
        end
        local function curve(x0,y0,cx,cy,x1,y1,face)
            local previous
            for i=0,10 do
                local t=i/10;local u=1-t
                local p=surface(u*u*x0+2*u*t*cx+t*t*x1,u*u*y0+2*u*t*cy+t*t*y1,face)
                if previous then table.insert(points,previous);table.insert(points,p) end
                previous=p
            end
        end
        return points
    end
    function api.Step()
        nativeKnife()
        local color=Color3.fromRGB(settings.wireRed,settings.wireGreen,settings.wireBlue)
        local signature=string.format("%.0f/%.0f/%.0f/%.2f",settings.wireRed,settings.wireGreen,settings.wireBlue,settings.wireWidth)..tostring(settings.wireContours)
        for key,group in pairs(groups) do
            local anchor
            for part,entry in pairs(group.parts) do
                if not part.Parent then group.parts[part]=nil;entries[part]=nil;group.dirty=true
                elseif not anchor and part:IsDescendantOf(Workspace) then anchor=part end
            end
            local enabled=anchor and ((group.kind=="arms" and settings.wireArms) or (group.kind=="knife" and settings.wireKnife))
            if enabled then
                if group.dirty or not group.core or not group.anchor or not group.anchor.Parent then
                    clear(group);group.anchor=anchor
                    local lines,seen={},{}
                    for part in pairs(group.parts) do
                        local points=geometry(part)
                        for i=1,#points,2 do
                            local a=anchor.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(points[i]))
                            local b=anchor.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(points[i+1]))
                            local ka=string.format("%.3f,%.3f,%.3f",a.X,a.Y,a.Z)
                            local kb=string.format("%.3f,%.3f,%.3f",b.X,b.Y,b.Z)
                            local edge=ka<kb and ka.."/"..kb or kb.."/"..ka
                            if not seen[edge] then seen[edge]=true;table.insert(lines,a);table.insert(lines,b) end
                        end
                    end
                    -- Bound dense imported meshes and triangle-built knives to a fixed line budget.
                    if #lines>1200 then
                        local reduced={};local stride=math.ceil(#lines/1200)
                        for i=1,#lines,2*stride do table.insert(reduced,lines[i]);table.insert(reduced,lines[i+1]) end
                        lines=reduced
                    end
                    group.lines=lines;group.contours={};group.dirty=false
                    if group.kind=="arms" then
                        for part in pairs(group.parts) do
                            for _,point in ipairs(contours(part)) do
                                table.insert(group.contours,anchor.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(point)))
                            end
                        end
                    end
                    group.core=make("WireframeHandleAdornment",{Name="StarfireWire",Adornee=anchor,AlwaysOnTop=true,ZIndex=2},effects)
                end
                if group.signature~=signature then
                    group.core:Clear();group.core.Color3=color;group.core.Thickness=settings.wireWidth
                    group.core.Transparency=0
                    if group.kind~="arms" or not settings.wireContours then group.core:AddLines(group.lines) end
                    if settings.wireContours and group.kind=="arms" and #group.contours>0 then
                        group.core.Color3=Color3.fromRGB(8,9,12)
                        group.core.Thickness=math.max(.8,settings.wireWidth*1.15)
                        group.core:AddLines(group.contours)
                    end
                    group.signature=signature
                end
                for part,entry in pairs(group.parts) do
                    if not entry.active then part.Transparency=.88;part.Material=Enum.Material.Neon;entry.active=true end
                    part.LocalTransparencyModifier=0;part.Color=color
                end
            else
                for part,entry in pairs(group.parts) do if entry.active then restore(part,entry) end end
                clear(group)
                if not next(group.parts) then groups[key]=nil end
            end
        end
    end
    function api.Destroy()
        for part,entry in pairs(entries) do restore(part,entry) end
        for _,group in pairs(groups) do clear(group) end
        table.clear(entries);table.clear(groups)
    end
    return api
end)()
-- A camera-space gun anchor keeps gun and knife hands at the same apparent scale.
GunViewmodel=(function()
    local api,tool,rotation,model,parts,hidden={},nil,nil,nil,{},{}
    local rotations=setmetatable({},{__mode="k"})
    function api.Reset()
        for part,value in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=value end end
        table.clear(hidden);table.clear(parts)
        if model then model:Destroy();model=nil end
        tool=nil;rotation=nil
    end
    function api.Frame(camera)
        local character=player.Character
        local held=character and character:FindFirstChildOfClass("Tool")
        local handle=held and held.Name:lower()=="gun" and held:FindFirstChild("Handle")
        if not settings.customArms or not camera or not handle or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 then return nil end
        if tool~=held then
            api.Reset();tool=held
            local root=character:FindFirstChild("HumanoidRootPart")
            rotation=rotations[held] or held.Grip.Rotation
            rotations[held]=rotation
        end
        return camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())*CFrame.new(.52,-.25,-1.05)*rotation
    end
    function api.Step()
        local camera=Workspace.CurrentCamera
        local frame=api.Frame(camera)
        if not frame then api.Reset();return end
        local custom=settings.skinChanger and settings.skinKind=="Gun" and Skins and Skins.HasModel()
        if custom then if model then model.Parent=nil end;return end
        local handle=tool:FindFirstChild("Handle")
        if not model then
            model=make("Model",{Name="StarfireStableGun"},effects)
            for _,source in ipairs(tool:GetDescendants()) do
                if source:IsA("BasePart") then
                    local copy=source:Clone()
                    for _,child in ipairs(copy:GetChildren()) do
                        if not (child:IsA("DataModelMesh") or child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy() end
                    end
                    copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false;copy.Massless=true
                    copy.LocalTransparencyModifier=0;copy.Parent=model
                    local scale=settings.gunViewSize
                    copy.Size=source.Size*scale
                    local mesh=copy:FindFirstChildOfClass("SpecialMesh")
                    if mesh and mesh.MeshType==Enum.MeshType.FileMesh then mesh.Scale=mesh.Scale*scale;mesh.Offset=mesh.Offset*scale end
                    local relative=handle.CFrame:ToObjectSpace(source.CFrame)
                    parts[copy]=CFrame.new(relative.Position*scale)*relative.Rotation
                    hidden[source]=source.LocalTransparencyModifier
                end
            end
        end
        model.Parent=effects
        frame=Inspect and Inspect.Transform(frame) or frame
        for copy,relative in pairs(parts) do copy.CFrame=frame*relative end
        for part in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=1 end end
    end
    return api
end)()
-- Shared cosmetic jump spring, sampled once before knife and hands render.
JumpMotion = (function()
    local api,current,previousGrounded,y,velocity,fallSpeed={},nil,nil,0,0,0
    function api.Step(dt)
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        local root=character and character:FindFirstChild("HumanoidRootPart")
        if current~=character or not humanoid or not root or humanoid.Health<=0 then
            current=character;previousGrounded=nil;y=0;velocity=0;fallSpeed=0
            return
        end
        local grounded=humanoid.FloorMaterial~=Enum.Material.Air
        if previousGrounded~=nil then
            if previousGrounded and not grounded and root.AssemblyLinearVelocity.Y>2 then velocity=velocity+1.75 end
            if not previousGrounded and grounded then
                velocity=velocity-math.clamp(fallSpeed/22,1.1,2.6)
                fallSpeed=0
            end
        end
        if not grounded then fallSpeed=math.max(fallSpeed,-root.AssemblyLinearVelocity.Y) end
        previousGrounded=grounded
        local remaining=math.min(dt or 1/60,.1)
        while remaining>0 do
            local step=math.min(remaining,1/120)
            velocity=velocity+(-135*y-12*velocity)*step
            y=math.clamp(y+velocity*step,-.17,.13)
            remaining=remaining-step
        end
    end
    function api.Frame() return CFrame.new(0,y,0)*CFrame.Angles(-y*1.15,0,0) end
    return api
end)()
local bobHumanoid,bobOffset
local function restoreCameraBob()
    if bobHumanoid and bobHumanoid.Parent and bobOffset then bobHumanoid.CameraOffset=bobOffset end
    bobHumanoid=nil;bobOffset=nil
end
RunService:BindToRenderStep(cameraBinding.."NoBob",Enum.RenderPriority.Camera.Value-1,function()
    local camera=Workspace.CurrentCamera
    local character=player.Character
    local humanoid=character and character:FindFirstChildOfClass("Humanoid")
    if camera and humanoid and humanoid.Health>0 and (camera.CFrame.Position-camera.Focus.Position).Magnitude<1.2 then
        if bobHumanoid~=humanoid then restoreCameraBob();bobHumanoid=humanoid;bobOffset=humanoid.CameraOffset end
        humanoid.CameraOffset=Vector3.zero
    else restoreCameraBob() end
end)
local wasManualGun=false
RunService:BindToRenderStep(cameraBinding, Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not running then return end
    if Ambience then Ambience.Step() end
    if Glossy then Glossy.Step() end
    if PShade then PShade.Step(dt) end
    if Tracers then Tracers.Step() end
    if GunAudio then GunAudio.Step() end
    MovementSpeed.Step()
    if BunnyHop then BunnyHop.Step() end
    WeaponVisuals.Step()
    AvatarClone.Step()
    Ghost.Step(dt)
    JumpMotion.Step(dt)
    if Voidglass then Voidglass.Step() end
    if Inspect then Inspect.Step() end
    if Skins then Skins.Step() end
    GunViewmodel.Step()
    if GripArms then GripArms.Step(dt) end
    WireStyle.Step()
    SilentAim.Step();UIRefs.silentStatus.Text=SilentAim.Status()
    local manual=manualGunMode()
    if manual then
        if Automation then Automation.StopBag(true) end
        local camera=Workspace.CurrentCamera
        local character=player.Character
        local humanoid=character and character:FindFirstChildOfClass("Humanoid")
        if camera and humanoid and not wasManualGun and not Evade.Busy() then
            camera.CameraSubject=humanoid;camera.CameraType=Enum.CameraType.Custom
        end
    end
    wasManualGun=manual and true or false
    local camera = Workspace.CurrentCamera
    GunMarker.Step(camera, dt)
    fovCircle.Visible = camera ~= nil and (settings.aim or settings.silentAim) and settings.showFov and living(player.Character) == true
    Automation.AimBagCamera(camera)
    fovCircle.Size = UDim2.fromOffset(settings.fov * 2, settings.fov * 2)
    selectedTarget = nil
    dodgeIndicator.Visible = Evade.Busy()
    if Evade.Busy() then Evade.Camera(); return end
    if not camera or sweepState or Scare.Busy() or Fling.Busy() or (Automation and Automation.Busy()) or manualGunMode() or settings.silentAim or not settings.aim or not aiming or UIS:GetFocusedTextBox() or camera.CameraType == Enum.CameraType.Scriptable then return end
    local target, part = aimTarget(camera)
    if target and part then
        selectedTarget = target
        local wanted = CFrame.lookAt(camera.CFrame.Position, part.Position)
        if settings.snapAim then
            camera.CFrame = wanted
        else
            camera.CFrame = camera.CFrame:Lerp(wanted, 1 - math.exp(-settings.responsiveness * math.min(dt, 0.1)))
        end
    end
end)

connect(UIS.InputBegan, function(input, processed)
    if captureResponse then
        if input.KeyCode == Enum.KeyCode.Escape then
            captureResponse = false; refreshResponseBind(); notify("Gun response key unchanged"); return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode == Enum.KeyCode.Unknown then return end
        if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.RightShift
            or input.KeyCode == aimKey or input.KeyCode == gunKey then
            notify("That key is already used. Choose another gun response key.", true); return
        end
        responseKey, captureResponse = input.KeyCode, false
        refreshResponseBind(); notify("Gun response key set to " .. responseKey.Name); return
    end
    if captureGun then
        if input.KeyCode == Enum.KeyCode.Escape then
            captureGun = false; refreshGunBind(); notify("Pickup gun key unchanged"); return
        end
        if input.UserInputType ~= Enum.UserInputType.Keyboard or input.KeyCode == Enum.KeyCode.Unknown then return end
        if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == aimKey or input.KeyCode == responseKey then
            notify("That key is already used. Choose another pickup gun key.", true); return
        end
        gunKey, captureGun = input.KeyCode, false
        refreshGunBind()
        notify("Pickup gun key set to " .. gunKey.Name)
        return
    end
    if captureAim then
        if input.KeyCode == Enum.KeyCode.Escape then
            captureAim = false
            refreshAimBind()
            notify("Aim key unchanged")
            return
        end
        if input.KeyCode == Enum.KeyCode.B or input.KeyCode == gunKey or input.KeyCode == responseKey or input.KeyCode == Enum.KeyCode.RightShift then
            notify("That key is used by cursor teleport, gun pickup/response, or the menu. Choose another key.", true)
            return
        end
        local chosen
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            chosen = input.KeyCode
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            chosen = input.UserInputType
        end
        if chosen then
            aimKey, captureAim, aiming = chosen, false, false
            refreshAimBind()
            notify("Aim key set to " .. aimKeyName() .. " · release, then hold it to aim")
        end
        return
    end
    if UIS:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.RightShift then toggleMenu(); return end
    if processed then return end
    if input.KeyCode == responseKey then Automation.ManualGunResponse(); return end
    if input.KeyCode == gunKey then teleportToGun(); return end
    if input.KeyCode == Enum.KeyCode.B then teleportToCursor(); return end
    if matchesAimKey(input) then aiming = true end
end)
connect(UIS.InputEnded, function(input)
    if matchesAimKey(input) then aiming = false end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or (activeSlider and input == activeSlider.input) then activeSlider = nil end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or (drag and input == drag.input) then drag = nil end
end)
connect(UIS.WindowFocusReleased, function()
    aiming, drag, activeSlider = false, nil, nil
    if captureAim then captureAim = false; refreshAimBind() end
    if captureGun then captureGun = false; refreshGunBind() end
    if captureResponse then captureResponse = false; refreshResponseBind() end
end)
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        drag = {input = input, from = input.Position, position = window.Position}
    end
end)
connect(UIS.InputChanged, function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseMovement and input.UserInputType ~= Enum.UserInputType.Touch then return end
    if activeSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input == activeSlider.input) then
        activeSlider.update(input.Position.X)
    elseif drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input == drag.input) then
        local delta = input.Position - drag.from
        local camera = Workspace.CurrentCamera
        local position = drag.position
        if camera then
            local half = Vector2.new(380, 270) * scale.Scale
            local center = Vector2.new(position.X.Scale * camera.ViewportSize.X + position.X.Offset + delta.X,
                position.Y.Scale * camera.ViewportSize.Y + position.Y.Offset + delta.Y)
            center = Vector2.new(math.clamp(center.X, half.X, math.max(half.X, camera.ViewportSize.X - half.X)),
                math.clamp(center.Y, half.Y, math.max(half.Y, camera.ViewportSize.Y - half.Y)))
            window.Position = UDim2.fromOffset(center.X, center.Y)
        end
    end
end)
connect(Players.PlayerRemoving, destroyEntry)
connect(player.CharacterAdded, function()
    aiming, selectedTarget = false, nil
    AvatarClone.Stop()
    Scare.Stop(false)
    Ghost.Reset()
    WeaponVisuals.Reset()
    Fling.Stop(false)
    Mobility.Reset()
    VisualSpin.Reset()
    CandySweep.Reset()
    Evade.Stop(false)
    Automation.ResetRound()
    if stopSweep then stopSweep(false) end
    stopEmote()
end)
local elapsed = 0
connect(RunService.Heartbeat, function(dt)
    elapsed = elapsed + dt
    if elapsed < 0.2 then return end
    elapsed = 0
    local camera = Workspace.CurrentCamera
    if camera then scale.Scale = math.clamp(math.min((camera.ViewportSize.X - 28) / 760, (camera.ViewportSize.Y - 28) / 540), 0.3, 1) end
    for _, other in ipairs(Players:GetPlayers()) do refreshPlayer(other) end
    for instance in pairs(gunDrops) do
        local part=instance.Parent and dropPart(instance)
        if part and settings.droppedGunESP then
            local mark=UIRefs.roundState.drops[instance]
            if not mark then
                local highlight=make("Highlight",{Adornee=instance,FillColor=colors.sheriff,OutlineColor=Color3.new(1,1,1),FillTransparency=.35,DepthMode=Enum.HighlightDepthMode.AlwaysOnTop},effects)
                local tag=make("BillboardGui",{Adornee=part,Size=UDim2.fromOffset(160,32),StudsOffsetWorldSpace=Vector3.new(0,1.2,0),AlwaysOnTop=true},playerGui)
                local text=label(tag,"DROPPED GUN",14,colors.sheriff)
                text.Size=UDim2.fromScale(1,1);text.TextXAlignment=Enum.TextXAlignment.Center
                mark={highlight,tag};UIRefs.roundState.drops[instance]=mark
            end
        end
    end
    for instance,mark in pairs(UIRefs.roundState.drops) do
        if not gunDrops[instance] or not instance.Parent or not settings.droppedGunESP then
            for _,object in ipairs(mark) do object:Destroy() end
            UIRefs.roundState.drops[instance]=nil
        end
    end
    Ghost.Refresh()
    Evade.Refresh()
    CandySweep.Update()
    if Automation then Automation.Update() end
end)

cleanup = function()
    if not running then return end
    running, aiming = false, false
    for _,mark in pairs(UIRefs.roundState.drops) do
        for _,object in ipairs(mark) do object:Destroy() end
    end
    table.clear(UIRefs.roundState.drops)
    if PShade then PShade.Reset() end
    if Ambience then Ambience.Reset() end
    if Glossy then Glossy.Reset() end
    MovementSpeed.Reset()
    if BunnyHop then BunnyHop.Reset() end
    if Tracers then Tracers.Reset() end
    if GunAudio then GunAudio.Reset() end
    if Voidglass then Voidglass.Reset() end
    if Inspect then Inspect.Reset() end
    if Skins then Skins.Reset() end
    if SilentAim then SilentAim.Stop() end
    if WireStyle then WireStyle.Destroy() end
    if GunViewmodel then GunViewmodel.Reset() end
    if GripArms then GripArms.Destroy() end
    AvatarClone.Stop()
    Scare.Stop(true)
    Ghost.Reset()
    WeaponVisuals.Reset()
    for _, tween in pairs(uiTweens) do tween:Cancel() end
    table.clear(uiTweens)
    Fling.Stop(true)
    Mobility.Reset()
    VisualSpin.Reset()
    Evade.Cleanup()
    Automation.Cleanup()
    if stopSweep then stopSweep(true) end
    RunService:UnbindFromRenderStep(cameraBinding)
    RunService:UnbindFromRenderStep(cameraBinding.."NoBob")
    restoreCameraBob()
    stopEmote()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for other in pairs(entries) do destroyEntry(other) end
    effects:Destroy()
    gui:Destroy()
end
connect(cleanupEvent.Event, cleanup)
connect(gui.AncestryChanged, function()
    if running and not gui:IsDescendantOf(playerGui) then cleanup() end
end)
-- Original Voidglass geometry, built locally with wedge surfaces; cosmetic inventory tool only.
Voidglass = (function()
local triangles={{1,-0.15,0.035,0,-0.205,0.1,0,0,0.1,0.068},{1,-0.15,0.035,0,0,0.1,0.068,0,0.035,0.06},{1,0,0.035,0.06,0,0.1,0.068,0.205,0.1,0},{1,0,0.035,0.06,0.205,0.1,0,0.15,0.035,0},{1,0.15,0.035,0,0.205,0.1,0,0,0.1,-0.068},{1,0.15,0.035,0,0,0.1,-0.068,0,0.035,-0.06},{1,0,0.035,-0.06,0,0.1,-0.068,-0.205,0.1,0},{1,0,0.035,-0.06,-0.205,0.1,0,-0.15,0.035,0},{1,-0.205,0.1,0,-0.235,0.18,0,0,0.18,0.073},{1,-0.205,0.1,0,0,0.18,0.073,0,0.1,0.068},{1,0,0.1,0.068,0,0.18,0.073,0.235,0.18,0},{1,0,0.1,0.068,0.235,0.18,0,0.205,0.1,0},{1,0.205,0.1,0,0.235,0.18,0,0,0.18,-0.073},{1,0.205,0.1,0,0,0.18,-0.073,0,0.1,-0.068},{1,0,0.1,-0.068,0,0.18,-0.073,-0.235,0.18,0},{1,0,0.1,-0.068,-0.235,0.18,0,-0.205,0.1,0},{1,-0.235,0.18,0,-0.245,0.3,0,0,0.3,0.075},{1,-0.235,0.18,0,0,0.3,0.075,0,0.18,0.073},{1,0,0.18,0.073,0,0.3,0.075,0.245,0.3,0},{1,0,0.18,0.073,0.245,0.3,0,0.235,0.18,0},{1,0.235,0.18,0,0.245,0.3,0,0,0.3,-0.075},{1,0.235,0.18,0,0,0.3,-0.075,0,0.18,-0.073},{1,0,0.18,-0.073,0,0.3,-0.075,-0.245,0.3,0},{1,0,0.18,-0.073,-0.245,0.3,0,-0.235,0.18,0},{1,-0.245,0.3,0,-0.18,1.25,0,0,1.25,0.055},{1,-0.245,0.3,0,0,1.25,0.055,0,0.3,0.075},{1,0,0.3,0.075,0,1.25,0.055,0.18,1.25,0},{1,0,0.3,0.075,0.18,1.25,0,0.245,0.3,0},{1,0.245,0.3,0,0.18,1.25,0,0,1.25,-0.055},{1,0.245,0.3,0,0,1.25,-0.055,0,0.3,-0.075},{1,0,0.3,-0.075,0,1.25,-0.055,-0.18,1.25,0},{1,0,0.3,-0.075,-0.18,1.25,0,-0.245,0.3,0},{1,-0.18,1.25,0,-0.055,1.78,0,0,1.78,0.018},{1,-0.18,1.25,0,0,1.78,0.018,0,1.25,0.055},{1,0,1.25,0.055,0,1.78,0.018,0.055,1.78,0},{1,0,1.25,0.055,0.055,1.78,0,0.18,1.25,0},{1,0.18,1.25,0,0.055,1.78,0,0,1.78,-0.018},{1,0.18,1.25,0,0,1.78,-0.018,0,1.25,-0.055},{1,0,1.25,-0.055,0,1.78,-0.018,-0.055,1.78,0},{1,0,1.25,-0.055,-0.055,1.78,0,-0.18,1.25,0},{1,-0.055,1.78,0,0,1.94,0,0,1.78,0.018},{1,0,1.78,0.018,0,1.94,0,0.055,1.78,0},{1,0.055,1.78,0,0,1.94,0,0,1.78,-0.018},{1,0,1.78,-0.018,0,1.94,0,-0.055,1.78,0}}
    local api, tool, baseGrip, started, activation, previewConnection = {}, nil, nil, nil, nil, nil
    local stabStarted,stabKind,shakeStarted
    local palmRoll=0
    local viewModel,viewCopies,authored,viewHidden=nil,{},{},{}
    local authoredComponents,viewComponents,viewWireGroups={},{},{}
    local inspectPose=CFrame.new()
    local function clearFirstPerson()
        for part,value in pairs(viewHidden) do if part.Parent then part.LocalTransparencyModifier=value end end
        table.clear(viewHidden);table.clear(viewCopies);table.clear(viewComponents);table.clear(viewWireGroups)
        if viewModel then viewModel:Destroy();viewModel=nil end
        inspectPose=CFrame.new()
    end
    local colors={Color3.fromRGB(46,51,56),Color3.fromRGB(161,173,184),Color3.fromRGB(128,128,128),Color3.fromRGB(41,19,9),Color3.fromRGB(224,232,237)}
    local knifeSkins={
        {name="REALISTIC DAGGER",triangles=triangles,colors=colors,solidGrip=true},
        {name="EMBER DAGGER",triangles={{0,-0.2844,0.1872,0.09,0.2844,0.1872,0.09,0.4187,0.414,0.09},{0,0.4187,0.414,-0.09,0.2844,0.1872,-0.09,-0.2844,0.1872,-0.09},{0,-0.2844,0.1872,0.09,0.4187,0.414,0.09,0.316,1.002,0.09},{0,0.316,1.002,-0.09,0.4187,0.414,-0.09,-0.2844,0.1872,-0.09},{0,-0.2844,0.1872,0.09,0.316,1.002,0.09,0.0,1.758,0.09},{0,0.0,1.758,-0.09,0.316,1.002,-0.09,-0.2844,0.1872,-0.09},{0,-0.2844,0.1872,0.09,0.0,1.758,0.09,-0.316,1.002,0.09},{0,-0.316,1.002,-0.09,0.0,1.758,-0.09,-0.2844,0.1872,-0.09},{0,-0.316,1.002,0.09,-0.4187,0.414,0.09,-0.2844,0.1872,0.09},{0,-0.2844,0.1872,-0.09,-0.4187,0.414,-0.09,-0.316,1.002,-0.09},{0,0.2844,0.1872,-0.09,0.4187,0.414,-0.09,0.4187,0.414,0.09},{0,0.2844,0.1872,-0.09,0.4187,0.414,0.09,0.2844,0.1872,0.09},{0,0.4187,0.414,-0.09,0.316,1.002,-0.09,0.316,1.002,0.09},{0,0.4187,0.414,-0.09,0.316,1.002,0.09,0.4187,0.414,0.09},{0,0.316,1.002,-0.09,0.0,1.758,-0.09,0.0,1.758,0.09},{0,0.316,1.002,-0.09,0.0,1.758,0.09,0.316,1.002,0.09},{0,0.0,1.758,-0.09,-0.316,1.002,-0.09,-0.316,1.002,0.09},{0,0.0,1.758,-0.09,-0.316,1.002,0.09,0.0,1.758,0.09},{0,-0.316,1.002,-0.09,-0.4187,0.414,-0.09,-0.4187,0.414,0.09},{0,-0.316,1.002,-0.09,-0.4187,0.414,0.09,-0.316,1.002,0.09},{0,-0.4187,0.414,-0.09,-0.2844,0.1872,-0.09,-0.2844,0.1872,0.09},{0,-0.4187,0.414,-0.09,-0.2844,0.1872,0.09,-0.4187,0.414,0.09},{0,-0.2844,0.1872,-0.09,0.2844,0.1872,-0.09,0.2844,0.1872,0.09},{0,-0.2844,0.1872,-0.09,0.2844,0.1872,0.09,-0.2844,0.1872,0.09},{2,-0.36,0.08,-0.1,-0.53,0.35,-0.1,-0.4187,0.414,-0.1},{2,-0.36,0.08,-0.1,-0.4187,0.414,-0.1,-0.2844,0.1872,-0.1},{2,-0.36,0.08,0.1,-0.53,0.35,0.1,-0.4187,0.414,0.1},{2,-0.36,0.08,0.1,-0.4187,0.414,0.1,-0.2844,0.1872,0.1},{2,-0.36,0.08,-0.1,-0.53,0.35,-0.1,-0.53,0.35,0.1},{2,-0.36,0.08,-0.1,-0.53,0.35,0.1,-0.36,0.08,0.1},{2,-0.53,0.35,-0.1,-0.4,1.05,-0.1,-0.316,1.002,-0.1},{2,-0.53,0.35,-0.1,-0.316,1.002,-0.1,-0.4187,0.414,-0.1},{2,-0.53,0.35,0.1,-0.4,1.05,0.1,-0.316,1.002,0.1},{2,-0.53,0.35,0.1,-0.316,1.002,0.1,-0.4187,0.414,0.1},{2,-0.53,0.35,-0.1,-0.4,1.05,-0.1,-0.4,1.05,0.1},{2,-0.53,0.35,-0.1,-0.4,1.05,0.1,-0.53,0.35,0.1},{2,-0.4,1.05,-0.1,0,1.95,-0.1,0.0,1.758,-0.1},{2,-0.4,1.05,-0.1,0.0,1.758,-0.1,-0.316,1.002,-0.1},{2,-0.4,1.05,0.1,0,1.95,0.1,0.0,1.758,0.1},{2,-0.4,1.05,0.1,0.0,1.758,0.1,-0.316,1.002,0.1},{2,-0.4,1.05,-0.1,0,1.95,-0.1,0,1.95,0.1},{2,-0.4,1.05,-0.1,0,1.95,0.1,-0.4,1.05,0.1},{2,0,1.95,-0.1,0.4,1.05,-0.1,0.316,1.002,-0.1},{2,0,1.95,-0.1,0.316,1.002,-0.1,0.0,1.758,-0.1},{2,0,1.95,0.1,0.4,1.05,0.1,0.316,1.002,0.1},{2,0,1.95,0.1,0.316,1.002,0.1,0.0,1.758,0.1},{2,0,1.95,-0.1,0.4,1.05,-0.1,0.4,1.05,0.1},{2,0,1.95,-0.1,0.4,1.05,0.1,0,1.95,0.1},{2,0.4,1.05,-0.1,0.53,0.35,-0.1,0.4187,0.414,-0.1},{2,0.4,1.05,-0.1,0.4187,0.414,-0.1,0.316,1.002,-0.1},{2,0.4,1.05,0.1,0.53,0.35,0.1,0.4187,0.414,0.1},{2,0.4,1.05,0.1,0.4187,0.414,0.1,0.316,1.002,0.1},{2,0.4,1.05,-0.1,0.53,0.35,-0.1,0.53,0.35,0.1},{2,0.4,1.05,-0.1,0.53,0.35,0.1,0.4,1.05,0.1},{2,0.53,0.35,-0.1,0.36,0.08,-0.1,0.2844,0.1872,-0.1},{2,0.53,0.35,-0.1,0.2844,0.1872,-0.1,0.4187,0.414,-0.1},{2,0.53,0.35,0.1,0.36,0.08,0.1,0.2844,0.1872,0.1},{2,0.53,0.35,0.1,0.2844,0.1872,0.1,0.4187,0.414,0.1},{2,0.53,0.35,-0.1,0.36,0.08,-0.1,0.36,0.08,0.1},{2,0.53,0.35,-0.1,0.36,0.08,0.1,0.53,0.35,0.1},{2,0.36,0.08,-0.1,-0.36,0.08,-0.1,-0.2844,0.1872,-0.1},{2,0.36,0.08,-0.1,-0.2844,0.1872,-0.1,0.2844,0.1872,-0.1},{2,0.36,0.08,0.1,-0.36,0.08,0.1,-0.2844,0.1872,0.1},{2,0.36,0.08,0.1,-0.2844,0.1872,0.1,0.2844,0.1872,0.1},{2,0.36,0.08,-0.1,-0.36,0.08,-0.1,-0.36,0.08,0.1},{2,0.36,0.08,-0.1,-0.36,0.08,0.1,0.36,0.08,0.1},{1,0.075,0.2,0.115,0,1.67,0.115,-0.075,0.2,0.115},{1,-0.075,0.2,-0.115,0,1.67,-0.115,0.075,0.2,-0.115},{1,0.075,0.2,-0.115,0,1.67,-0.115,0,1.67,0.115},{1,0.075,0.2,-0.115,0,1.67,0.115,0.075,0.2,0.115},{1,0,1.67,-0.115,-0.075,0.2,-0.115,-0.075,0.2,0.115},{1,0,1.67,-0.115,-0.075,0.2,0.115,0,1.67,0.115},{1,-0.075,0.2,-0.115,0.075,0.2,-0.115,0.075,0.2,0.115},{1,-0.075,0.2,-0.115,0.075,0.2,0.115,-0.075,0.2,0.115},{2,-0.04,0.4,-0.118,0.065,0.29,-0.118,0.13,0.51,-0.118},{2,0.13,0.51,-0.128,0.065,0.29,-0.128,-0.04,0.4,-0.128},{2,-0.13,0.36,-0.118,-0.04,0.4,-0.118,0.13,0.51,-0.118},{2,0.13,0.51,-0.128,-0.04,0.4,-0.128,-0.13,0.36,-0.128},{2,0.13,0.51,-0.118,-0.035,0.67,-0.118,0.01,0.51,-0.118},{2,0.01,0.51,-0.128,-0.035,0.67,-0.128,0.13,0.51,-0.128},{2,0.13,0.51,-0.118,0.01,0.51,-0.118,-0.13,0.36,-0.118},{2,-0.13,0.36,-0.128,0.01,0.51,-0.128,0.13,0.51,-0.128},{2,-0.04,0.4,-0.128,0.065,0.29,-0.128,0.065,0.29,-0.118},{2,-0.04,0.4,-0.128,0.065,0.29,-0.118,-0.04,0.4,-0.118},{2,0.065,0.29,-0.128,0.13,0.51,-0.128,0.13,0.51,-0.118},{2,0.065,0.29,-0.128,0.13,0.51,-0.118,0.065,0.29,-0.118},{2,0.13,0.51,-0.128,-0.035,0.67,-0.128,-0.035,0.67,-0.118},{2,0.13,0.51,-0.128,-0.035,0.67,-0.118,0.13,0.51,-0.118},{2,-0.035,0.67,-0.128,0.01,0.51,-0.128,0.01,0.51,-0.118},{2,-0.035,0.67,-0.128,0.01,0.51,-0.118,-0.035,0.67,-0.118},{2,0.01,0.51,-0.128,-0.13,0.36,-0.128,-0.13,0.36,-0.118},{2,0.01,0.51,-0.128,-0.13,0.36,-0.118,0.01,0.51,-0.118},{2,-0.13,0.36,-0.128,-0.04,0.4,-0.128,-0.04,0.4,-0.118},{2,-0.13,0.36,-0.128,-0.04,0.4,-0.118,-0.13,0.36,-0.118},{2,-0.04,0.4,0.128,0.065,0.29,0.128,0.13,0.51,0.128},{2,0.13,0.51,0.118,0.065,0.29,0.118,-0.04,0.4,0.118},{2,-0.13,0.36,0.128,-0.04,0.4,0.128,0.13,0.51,0.128},{2,0.13,0.51,0.118,-0.04,0.4,0.118,-0.13,0.36,0.118},{2,0.13,0.51,0.128,-0.035,0.67,0.128,0.01,0.51,0.128},{2,0.01,0.51,0.118,-0.035,0.67,0.118,0.13,0.51,0.118},{2,0.13,0.51,0.128,0.01,0.51,0.128,-0.13,0.36,0.128},{2,-0.13,0.36,0.118,0.01,0.51,0.118,0.13,0.51,0.118},{2,-0.04,0.4,0.118,0.065,0.29,0.118,0.065,0.29,0.128},{2,-0.04,0.4,0.118,0.065,0.29,0.128,-0.04,0.4,0.128},{2,0.065,0.29,0.118,0.13,0.51,0.118,0.13,0.51,0.128},{2,0.065,0.29,0.118,0.13,0.51,0.128,0.065,0.29,0.128},{2,0.13,0.51,0.118,-0.035,0.67,0.118,-0.035,0.67,0.128},{2,0.13,0.51,0.118,-0.035,0.67,0.128,0.13,0.51,0.128},{2,-0.035,0.67,0.118,0.01,0.51,0.118,0.01,0.51,0.128},{2,-0.035,0.67,0.118,0.01,0.51,0.128,-0.035,0.67,0.128},{2,0.01,0.51,0.118,-0.13,0.36,0.118,-0.13,0.36,0.128},{2,0.01,0.51,0.118,-0.13,0.36,0.128,0.01,0.51,0.128},{2,-0.13,0.36,0.118,-0.04,0.4,0.118,-0.04,0.4,0.128},{2,-0.13,0.36,0.118,-0.04,0.4,0.128,-0.13,0.36,0.128},{0,0,-0.13,0.14,0,-0.03,0.14,-0.42,0.03,0.14},{0,-0.42,0.03,-0.14,0,-0.03,-0.14,0,-0.13,-0.14},{0,-0.42,0.03,0.14,-0.64,0.34,0.14,-0.61,-0.06,0.14},{0,-0.61,-0.06,-0.14,-0.64,0.34,-0.14,-0.42,0.03,-0.14},{0,0,-0.13,0.14,-0.42,0.03,0.14,-0.61,-0.06,0.14},{0,-0.61,-0.06,-0.14,-0.42,0.03,-0.14,0,-0.13,-0.14},{0,-0.61,-0.06,0.14,-0.32,-0.2,0.14,0,-0.13,0.14},{0,0,-0.13,-0.14,-0.32,-0.2,-0.14,-0.61,-0.06,-0.14},{0,0,-0.03,-0.14,-0.42,0.03,-0.14,-0.42,0.03,0.14},{0,0,-0.03,-0.14,-0.42,0.03,0.14,0,-0.03,0.14},{0,-0.42,0.03,-0.14,-0.64,0.34,-0.14,-0.64,0.34,0.14},{0,-0.42,0.03,-0.14,-0.64,0.34,0.14,-0.42,0.03,0.14},{0,-0.64,0.34,-0.14,-0.61,-0.06,-0.14,-0.61,-0.06,0.14},{0,-0.64,0.34,-0.14,-0.61,-0.06,0.14,-0.64,0.34,0.14},{0,-0.61,-0.06,-0.14,-0.32,-0.2,-0.14,-0.32,-0.2,0.14},{0,-0.61,-0.06,-0.14,-0.32,-0.2,0.14,-0.61,-0.06,0.14},{0,-0.32,-0.2,-0.14,0,-0.13,-0.14,0,-0.13,0.14},{0,-0.32,-0.2,-0.14,0,-0.13,0.14,-0.32,-0.2,0.14},{0,0,-0.13,-0.14,0,-0.03,-0.14,0,-0.03,0.14},{0,0,-0.13,-0.14,0,-0.03,0.14,0,-0.13,0.14},{2,-0.28,-0.13,0.15,-0.22,-0.05,0.15,-0.43,0.04,0.15},{2,-0.43,0.04,-0.15,-0.22,-0.05,-0.15,-0.28,-0.13,-0.15},{2,-0.43,0.04,0.15,-0.56,0.2,0.15,-0.46,-0.05,0.15},{2,-0.46,-0.05,-0.15,-0.56,0.2,-0.15,-0.43,0.04,-0.15},{2,-0.43,0.04,0.15,-0.46,-0.05,0.15,-0.28,-0.13,0.15},{2,-0.28,-0.13,-0.15,-0.46,-0.05,-0.15,-0.43,0.04,-0.15},{2,-0.22,-0.05,-0.15,-0.43,0.04,-0.15,-0.43,0.04,0.15},{2,-0.22,-0.05,-0.15,-0.43,0.04,0.15,-0.22,-0.05,0.15},{2,-0.43,0.04,-0.15,-0.56,0.2,-0.15,-0.56,0.2,0.15},{2,-0.43,0.04,-0.15,-0.56,0.2,0.15,-0.43,0.04,0.15},{2,-0.56,0.2,-0.15,-0.46,-0.05,-0.15,-0.46,-0.05,0.15},{2,-0.56,0.2,-0.15,-0.46,-0.05,0.15,-0.56,0.2,0.15},{2,-0.46,-0.05,-0.15,-0.28,-0.13,-0.15,-0.28,-0.13,0.15},{2,-0.46,-0.05,-0.15,-0.28,-0.13,0.15,-0.46,-0.05,0.15},{2,-0.28,-0.13,-0.15,-0.22,-0.05,-0.15,-0.22,-0.05,0.15},{2,-0.28,-0.13,-0.15,-0.22,-0.05,0.15,-0.28,-0.13,0.15},{0,0,-0.03,0.14,0,-0.13,0.14,0.32,-0.2,0.14},{0,0.32,-0.2,-0.14,0,-0.13,-0.14,0,-0.03,-0.14},{0,0,-0.03,0.14,0.32,-0.2,0.14,0.61,-0.06,0.14},{0,0.61,-0.06,-0.14,0.32,-0.2,-0.14,0,-0.03,-0.14},{0,0.61,-0.06,0.14,0.64,0.34,0.14,0.42,0.03,0.14},{0,0.42,0.03,-0.14,0.64,0.34,-0.14,0.61,-0.06,-0.14},{0,0.61,-0.06,0.14,0.42,0.03,0.14,0,-0.03,0.14},{0,0,-0.03,-0.14,0.42,0.03,-0.14,0.61,-0.06,-0.14},{0,0,-0.13,-0.14,0.32,-0.2,-0.14,0.32,-0.2,0.14},{0,0,-0.13,-0.14,0.32,-0.2,0.14,0,-0.13,0.14},{0,0.32,-0.2,-0.14,0.61,-0.06,-0.14,0.61,-0.06,0.14},{0,0.32,-0.2,-0.14,0.61,-0.06,0.14,0.32,-0.2,0.14},{0,0.61,-0.06,-0.14,0.64,0.34,-0.14,0.64,0.34,0.14},{0,0.61,-0.06,-0.14,0.64,0.34,0.14,0.61,-0.06,0.14},{0,0.64,0.34,-0.14,0.42,0.03,-0.14,0.42,0.03,0.14},{0,0.64,0.34,-0.14,0.42,0.03,0.14,0.64,0.34,0.14},{0,0.42,0.03,-0.14,0,-0.03,-0.14,0,-0.03,0.14},{0,0.42,0.03,-0.14,0,-0.03,0.14,0.42,0.03,0.14},{0,0,-0.03,-0.14,0,-0.13,-0.14,0,-0.13,0.14},{0,0,-0.03,-0.14,0,-0.13,0.14,0,-0.03,0.14},{2,0.22,-0.05,0.15,0.28,-0.13,0.15,0.46,-0.05,0.15},{2,0.46,-0.05,-0.15,0.28,-0.13,-0.15,0.22,-0.05,-0.15},{2,0.46,-0.05,0.15,0.56,0.2,0.15,0.43,0.04,0.15},{2,0.43,0.04,-0.15,0.56,0.2,-0.15,0.46,-0.05,-0.15},{2,0.46,-0.05,0.15,0.43,0.04,0.15,0.22,-0.05,0.15},{2,0.22,-0.05,-0.15,0.43,0.04,-0.15,0.46,-0.05,-0.15},{2,0.28,-0.13,-0.15,0.46,-0.05,-0.15,0.46,-0.05,0.15},{2,0.28,-0.13,-0.15,0.46,-0.05,0.15,0.28,-0.13,0.15},{2,0.46,-0.05,-0.15,0.56,0.2,-0.15,0.56,0.2,0.15},{2,0.46,-0.05,-0.15,0.56,0.2,0.15,0.46,-0.05,0.15},{2,0.56,0.2,-0.15,0.43,0.04,-0.15,0.43,0.04,0.15},{2,0.56,0.2,-0.15,0.43,0.04,0.15,0.56,0.2,0.15},{2,0.43,0.04,-0.15,0.22,-0.05,-0.15,0.22,-0.05,0.15},{2,0.43,0.04,-0.15,0.22,-0.05,0.15,0.43,0.04,0.15},{2,0.22,-0.05,-0.15,0.28,-0.13,-0.15,0.28,-0.13,0.15},{2,0.22,-0.05,-0.15,0.28,-0.13,0.15,0.22,-0.05,0.15},{3,0.17,-1.1,0.0,0.18,-0.07,0.0,0.155885,-0.07,0.09},{3,0.17,-1.1,0.0,0.155885,-0.07,0.09,0.147224,-1.1,0.085},{3,0,-1.1,0,0.17,-1.1,0.0,0.147224,-1.1,0.085},{3,0,-0.07,0,0.155885,-0.07,0.09,0.18,-0.07,0.0},{3,0.147224,-1.1,0.085,0.155885,-0.07,0.09,0.09,-0.07,0.155885},{3,0.147224,-1.1,0.085,0.09,-0.07,0.155885,0.085,-1.1,0.147224},{3,0,-1.1,0,0.147224,-1.1,0.085,0.085,-1.1,0.147224},{3,0,-0.07,0,0.09,-0.07,0.155885,0.155885,-0.07,0.09},{3,0.085,-1.1,0.147224,0.09,-0.07,0.155885,0.0,-0.07,0.18},{3,0.085,-1.1,0.147224,0.0,-0.07,0.18,0.0,-1.1,0.17},{3,0,-1.1,0,0.085,-1.1,0.147224,0.0,-1.1,0.17},{3,0,-0.07,0,0.0,-0.07,0.18,0.09,-0.07,0.155885},{3,0.0,-1.1,0.17,0.0,-0.07,0.18,-0.09,-0.07,0.155885},{3,0.0,-1.1,0.17,-0.09,-0.07,0.155885,-0.085,-1.1,0.147224},{3,0,-1.1,0,0.0,-1.1,0.17,-0.085,-1.1,0.147224},{3,0,-0.07,0,-0.09,-0.07,0.155885,0.0,-0.07,0.18},{3,-0.085,-1.1,0.147224,-0.09,-0.07,0.155885,-0.155885,-0.07,0.09},{3,-0.085,-1.1,0.147224,-0.155885,-0.07,0.09,-0.147224,-1.1,0.085},{3,0,-1.1,0,-0.085,-1.1,0.147224,-0.147224,-1.1,0.085},{3,0,-0.07,0,-0.155885,-0.07,0.09,-0.09,-0.07,0.155885},{3,-0.147224,-1.1,0.085,-0.155885,-0.07,0.09,-0.18,-0.07,0.0},{3,-0.147224,-1.1,0.085,-0.18,-0.07,0.0,-0.17,-1.1,0.0},{3,0,-1.1,0,-0.147224,-1.1,0.085,-0.17,-1.1,0.0},{3,0,-0.07,0,-0.18,-0.07,0.0,-0.155885,-0.07,0.09},{3,-0.17,-1.1,0.0,-0.18,-0.07,0.0,-0.155885,-0.07,-0.09},{3,-0.17,-1.1,0.0,-0.155885,-0.07,-0.09,-0.147224,-1.1,-0.085},{3,0,-1.1,0,-0.17,-1.1,0.0,-0.147224,-1.1,-0.085},{3,0,-0.07,0,-0.155885,-0.07,-0.09,-0.18,-0.07,0.0},{3,-0.147224,-1.1,-0.085,-0.155885,-0.07,-0.09,-0.09,-0.07,-0.155885},{3,-0.147224,-1.1,-0.085,-0.09,-0.07,-0.155885,-0.085,-1.1,-0.147224},{3,0,-1.1,0,-0.147224,-1.1,-0.085,-0.085,-1.1,-0.147224},{3,0,-0.07,0,-0.09,-0.07,-0.155885,-0.155885,-0.07,-0.09},{3,-0.085,-1.1,-0.147224,-0.09,-0.07,-0.155885,-0.0,-0.07,-0.18},{3,-0.085,-1.1,-0.147224,-0.0,-0.07,-0.18,-0.0,-1.1,-0.17},{3,0,-1.1,0,-0.085,-1.1,-0.147224,-0.0,-1.1,-0.17},{3,0,-0.07,0,-0.0,-0.07,-0.18,-0.09,-0.07,-0.155885},{3,-0.0,-1.1,-0.17,-0.0,-0.07,-0.18,0.09,-0.07,-0.155885},{3,-0.0,-1.1,-0.17,0.09,-0.07,-0.155885,0.085,-1.1,-0.147224},{3,0,-1.1,0,-0.0,-1.1,-0.17,0.085,-1.1,-0.147224},{3,0,-0.07,0,0.09,-0.07,-0.155885,-0.0,-0.07,-0.18},{3,0.085,-1.1,-0.147224,0.09,-0.07,-0.155885,0.155885,-0.07,-0.09},{3,0.085,-1.1,-0.147224,0.155885,-0.07,-0.09,0.147224,-1.1,-0.085},{3,0,-1.1,0,0.085,-1.1,-0.147224,0.147224,-1.1,-0.085},{3,0,-0.07,0,0.155885,-0.07,-0.09,0.09,-0.07,-0.155885},{3,0.147224,-1.1,-0.085,0.155885,-0.07,-0.09,0.18,-0.07,-0.0},{3,0.147224,-1.1,-0.085,0.18,-0.07,-0.0,0.17,-1.1,-0.0},{3,0,-1.1,0,0.147224,-1.1,-0.085,0.17,-1.1,-0.0},{3,0,-0.07,0,0.18,-0.07,-0.0,0.155885,-0.07,-0.09},{0,0.18,-1.02,0.0,0.183,-0.975,0.0,0.158483,-0.975,0.0915},{0,0.18,-1.02,0.0,0.158483,-0.975,0.0915,0.155885,-1.02,0.09},{0,0,-1.02,0,0.18,-1.02,0.0,0.155885,-1.02,0.09},{0,0,-0.975,0,0.158483,-0.975,0.0915,0.183,-0.975,0.0},{0,0.155885,-1.02,0.09,0.158483,-0.975,0.0915,0.0915,-0.975,0.158483},{0,0.155885,-1.02,0.09,0.0915,-0.975,0.158483,0.09,-1.02,0.155885},{0,0,-1.02,0,0.155885,-1.02,0.09,0.09,-1.02,0.155885},{0,0,-0.975,0,0.0915,-0.975,0.158483,0.158483,-0.975,0.0915},{0,0.09,-1.02,0.155885,0.0915,-0.975,0.158483,0.0,-0.975,0.183},{0,0.09,-1.02,0.155885,0.0,-0.975,0.183,0.0,-1.02,0.18},{0,0,-1.02,0,0.09,-1.02,0.155885,0.0,-1.02,0.18},{0,0,-0.975,0,0.0,-0.975,0.183,0.0915,-0.975,0.158483},{0,0.0,-1.02,0.18,0.0,-0.975,0.183,-0.0915,-0.975,0.158483},{0,0.0,-1.02,0.18,-0.0915,-0.975,0.158483,-0.09,-1.02,0.155885},{0,0,-1.02,0,0.0,-1.02,0.18,-0.09,-1.02,0.155885},{0,0,-0.975,0,-0.0915,-0.975,0.158483,0.0,-0.975,0.183},{0,-0.09,-1.02,0.155885,-0.0915,-0.975,0.158483,-0.158483,-0.975,0.0915},{0,-0.09,-1.02,0.155885,-0.158483,-0.975,0.0915,-0.155885,-1.02,0.09},{0,0,-1.02,0,-0.09,-1.02,0.155885,-0.155885,-1.02,0.09},{0,0,-0.975,0,-0.158483,-0.975,0.0915,-0.0915,-0.975,0.158483},{0,-0.155885,-1.02,0.09,-0.158483,-0.975,0.0915,-0.183,-0.975,0.0},{0,-0.155885,-1.02,0.09,-0.183,-0.975,0.0,-0.18,-1.02,0.0},{0,0,-1.02,0,-0.155885,-1.02,0.09,-0.18,-1.02,0.0},{0,0,-0.975,0,-0.183,-0.975,0.0,-0.158483,-0.975,0.0915},{0,-0.18,-1.02,0.0,-0.183,-0.975,0.0,-0.158483,-0.975,-0.0915},{0,-0.18,-1.02,0.0,-0.158483,-0.975,-0.0915,-0.155885,-1.02,-0.09},{0,0,-1.02,0,-0.18,-1.02,0.0,-0.155885,-1.02,-0.09},{0,0,-0.975,0,-0.158483,-0.975,-0.0915,-0.183,-0.975,0.0},{0,-0.155885,-1.02,-0.09,-0.158483,-0.975,-0.0915,-0.0915,-0.975,-0.158483},{0,-0.155885,-1.02,-0.09,-0.0915,-0.975,-0.158483,-0.09,-1.02,-0.155885},{0,0,-1.02,0,-0.155885,-1.02,-0.09,-0.09,-1.02,-0.155885},{0,0,-0.975,0,-0.0915,-0.975,-0.158483,-0.158483,-0.975,-0.0915},{0,-0.09,-1.02,-0.155885,-0.0915,-0.975,-0.158483,-0.0,-0.975,-0.183},{0,-0.09,-1.02,-0.155885,-0.0,-0.975,-0.183,-0.0,-1.02,-0.18},{0,0,-1.02,0,-0.09,-1.02,-0.155885,-0.0,-1.02,-0.18},{0,0,-0.975,0,-0.0,-0.975,-0.183,-0.0915,-0.975,-0.158483},{0,-0.0,-1.02,-0.18,-0.0,-0.975,-0.183,0.0915,-0.975,-0.158483},{0,-0.0,-1.02,-0.18,0.0915,-0.975,-0.158483,0.09,-1.02,-0.155885},{0,0,-1.02,0,-0.0,-1.02,-0.18,0.09,-1.02,-0.155885},{0,0,-0.975,0,0.0915,-0.975,-0.158483,-0.0,-0.975,-0.183},{0,0.09,-1.02,-0.155885,0.0915,-0.975,-0.158483,0.158483,-0.975,-0.0915},{0,0.09,-1.02,-0.155885,0.158483,-0.975,-0.0915,0.155885,-1.02,-0.09},{0,0,-1.02,0,0.09,-1.02,-0.155885,0.155885,-1.02,-0.09},{0,0,-0.975,0,0.158483,-0.975,-0.0915,0.0915,-0.975,-0.158483},{0,0.155885,-1.02,-0.09,0.158483,-0.975,-0.0915,0.183,-0.975,-0.0},{0,0.155885,-1.02,-0.09,0.183,-0.975,-0.0,0.18,-1.02,-0.0},{0,0,-1.02,0,0.155885,-1.02,-0.09,0.18,-1.02,-0.0},{0,0,-0.975,0,0.183,-0.975,-0.0,0.158483,-0.975,-0.0915},{0,0.18,-0.83,0.0,0.183,-0.785,0.0,0.158483,-0.785,0.0915},{0,0.18,-0.83,0.0,0.158483,-0.785,0.0915,0.155885,-0.83,0.09},{0,0,-0.83,0,0.18,-0.83,0.0,0.155885,-0.83,0.09},{0,0,-0.785,0,0.158483,-0.785,0.0915,0.183,-0.785,0.0},{0,0.155885,-0.83,0.09,0.158483,-0.785,0.0915,0.0915,-0.785,0.158483},{0,0.155885,-0.83,0.09,0.0915,-0.785,0.158483,0.09,-0.83,0.155885},{0,0,-0.83,0,0.155885,-0.83,0.09,0.09,-0.83,0.155885},{0,0,-0.785,0,0.0915,-0.785,0.158483,0.158483,-0.785,0.0915},{0,0.09,-0.83,0.155885,0.0915,-0.785,0.158483,0.0,-0.785,0.183},{0,0.09,-0.83,0.155885,0.0,-0.785,0.183,0.0,-0.83,0.18},{0,0,-0.83,0,0.09,-0.83,0.155885,0.0,-0.83,0.18},{0,0,-0.785,0,0.0,-0.785,0.183,0.0915,-0.785,0.158483},{0,0.0,-0.83,0.18,0.0,-0.785,0.183,-0.0915,-0.785,0.158483},{0,0.0,-0.83,0.18,-0.0915,-0.785,0.158483,-0.09,-0.83,0.155885},{0,0,-0.83,0,0.0,-0.83,0.18,-0.09,-0.83,0.155885},{0,0,-0.785,0,-0.0915,-0.785,0.158483,0.0,-0.785,0.183},{0,-0.09,-0.83,0.155885,-0.0915,-0.785,0.158483,-0.158483,-0.785,0.0915},{0,-0.09,-0.83,0.155885,-0.158483,-0.785,0.0915,-0.155885,-0.83,0.09},{0,0,-0.83,0,-0.09,-0.83,0.155885,-0.155885,-0.83,0.09},{0,0,-0.785,0,-0.158483,-0.785,0.0915,-0.0915,-0.785,0.158483},{0,-0.155885,-0.83,0.09,-0.158483,-0.785,0.0915,-0.183,-0.785,0.0},{0,-0.155885,-0.83,0.09,-0.183,-0.785,0.0,-0.18,-0.83,0.0},{0,0,-0.83,0,-0.155885,-0.83,0.09,-0.18,-0.83,0.0},{0,0,-0.785,0,-0.183,-0.785,0.0,-0.158483,-0.785,0.0915},{0,-0.18,-0.83,0.0,-0.183,-0.785,0.0,-0.158483,-0.785,-0.0915},{0,-0.18,-0.83,0.0,-0.158483,-0.785,-0.0915,-0.155885,-0.83,-0.09},{0,0,-0.83,0,-0.18,-0.83,0.0,-0.155885,-0.83,-0.09},{0,0,-0.785,0,-0.158483,-0.785,-0.0915,-0.183,-0.785,0.0},{0,-0.155885,-0.83,-0.09,-0.158483,-0.785,-0.0915,-0.0915,-0.785,-0.158483},{0,-0.155885,-0.83,-0.09,-0.0915,-0.785,-0.158483,-0.09,-0.83,-0.155885},{0,0,-0.83,0,-0.155885,-0.83,-0.09,-0.09,-0.83,-0.155885},{0,0,-0.785,0,-0.0915,-0.785,-0.158483,-0.158483,-0.785,-0.0915},{0,-0.09,-0.83,-0.155885,-0.0915,-0.785,-0.158483,-0.0,-0.785,-0.183},{0,-0.09,-0.83,-0.155885,-0.0,-0.785,-0.183,-0.0,-0.83,-0.18},{0,0,-0.83,0,-0.09,-0.83,-0.155885,-0.0,-0.83,-0.18},{0,0,-0.785,0,-0.0,-0.785,-0.183,-0.0915,-0.785,-0.158483},{0,-0.0,-0.83,-0.18,-0.0,-0.785,-0.183,0.0915,-0.785,-0.158483},{0,-0.0,-0.83,-0.18,0.0915,-0.785,-0.158483,0.09,-0.83,-0.155885},{0,0,-0.83,0,-0.0,-0.83,-0.18,0.09,-0.83,-0.155885},{0,0,-0.785,0,0.0915,-0.785,-0.158483,-0.0,-0.785,-0.183},{0,0.09,-0.83,-0.155885,0.0915,-0.785,-0.158483,0.158483,-0.785,-0.0915},{0,0.09,-0.83,-0.155885,0.158483,-0.785,-0.0915,0.155885,-0.83,-0.09},{0,0,-0.83,0,0.09,-0.83,-0.155885,0.155885,-0.83,-0.09},{0,0,-0.785,0,0.158483,-0.785,-0.0915,0.0915,-0.785,-0.158483},{0,0.155885,-0.83,-0.09,0.158483,-0.785,-0.0915,0.183,-0.785,-0.0},{0,0.155885,-0.83,-0.09,0.183,-0.785,-0.0,0.18,-0.83,-0.0},{0,0,-0.83,0,0.155885,-0.83,-0.09,0.18,-0.83,-0.0},{0,0,-0.785,0,0.183,-0.785,-0.0,0.158483,-0.785,-0.0915},{0,0.18,-0.64,0.0,0.183,-0.595,0.0,0.158483,-0.595,0.0915},{0,0.18,-0.64,0.0,0.158483,-0.595,0.0915,0.155885,-0.64,0.09},{0,0,-0.64,0,0.18,-0.64,0.0,0.155885,-0.64,0.09},{0,0,-0.595,0,0.158483,-0.595,0.0915,0.183,-0.595,0.0},{0,0.155885,-0.64,0.09,0.158483,-0.595,0.0915,0.0915,-0.595,0.158483},{0,0.155885,-0.64,0.09,0.0915,-0.595,0.158483,0.09,-0.64,0.155885},{0,0,-0.64,0,0.155885,-0.64,0.09,0.09,-0.64,0.155885},{0,0,-0.595,0,0.0915,-0.595,0.158483,0.158483,-0.595,0.0915},{0,0.09,-0.64,0.155885,0.0915,-0.595,0.158483,0.0,-0.595,0.183},{0,0.09,-0.64,0.155885,0.0,-0.595,0.183,0.0,-0.64,0.18},{0,0,-0.64,0,0.09,-0.64,0.155885,0.0,-0.64,0.18},{0,0,-0.595,0,0.0,-0.595,0.183,0.0915,-0.595,0.158483},{0,0.0,-0.64,0.18,0.0,-0.595,0.183,-0.0915,-0.595,0.158483},{0,0.0,-0.64,0.18,-0.0915,-0.595,0.158483,-0.09,-0.64,0.155885},{0,0,-0.64,0,0.0,-0.64,0.18,-0.09,-0.64,0.155885},{0,0,-0.595,0,-0.0915,-0.595,0.158483,0.0,-0.595,0.183},{0,-0.09,-0.64,0.155885,-0.0915,-0.595,0.158483,-0.158483,-0.595,0.0915},{0,-0.09,-0.64,0.155885,-0.158483,-0.595,0.0915,-0.155885,-0.64,0.09},{0,0,-0.64,0,-0.09,-0.64,0.155885,-0.155885,-0.64,0.09},{0,0,-0.595,0,-0.158483,-0.595,0.0915,-0.0915,-0.595,0.158483},{0,-0.155885,-0.64,0.09,-0.158483,-0.595,0.0915,-0.183,-0.595,0.0},{0,-0.155885,-0.64,0.09,-0.183,-0.595,0.0,-0.18,-0.64,0.0},{0,0,-0.64,0,-0.155885,-0.64,0.09,-0.18,-0.64,0.0},{0,0,-0.595,0,-0.183,-0.595,0.0,-0.158483,-0.595,0.0915},{0,-0.18,-0.64,0.0,-0.183,-0.595,0.0,-0.158483,-0.595,-0.0915},{0,-0.18,-0.64,0.0,-0.158483,-0.595,-0.0915,-0.155885,-0.64,-0.09},{0,0,-0.64,0,-0.18,-0.64,0.0,-0.155885,-0.64,-0.09},{0,0,-0.595,0,-0.158483,-0.595,-0.0915,-0.183,-0.595,0.0},{0,-0.155885,-0.64,-0.09,-0.158483,-0.595,-0.0915,-0.0915,-0.595,-0.158483},{0,-0.155885,-0.64,-0.09,-0.0915,-0.595,-0.158483,-0.09,-0.64,-0.155885},{0,0,-0.64,0,-0.155885,-0.64,-0.09,-0.09,-0.64,-0.155885},{0,0,-0.595,0,-0.0915,-0.595,-0.158483,-0.158483,-0.595,-0.0915},{0,-0.09,-0.64,-0.155885,-0.0915,-0.595,-0.158483,-0.0,-0.595,-0.183},{0,-0.09,-0.64,-0.155885,-0.0,-0.595,-0.183,-0.0,-0.64,-0.18},{0,0,-0.64,0,-0.09,-0.64,-0.155885,-0.0,-0.64,-0.18},{0,0,-0.595,0,-0.0,-0.595,-0.183,-0.0915,-0.595,-0.158483},{0,-0.0,-0.64,-0.18,-0.0,-0.595,-0.183,0.0915,-0.595,-0.158483},{0,-0.0,-0.64,-0.18,0.0915,-0.595,-0.158483,0.09,-0.64,-0.155885},{0,0,-0.64,0,-0.0,-0.64,-0.18,0.09,-0.64,-0.155885},{0,0,-0.595,0,0.0915,-0.595,-0.158483,-0.0,-0.595,-0.183},{0,0.09,-0.64,-0.155885,0.0915,-0.595,-0.158483,0.158483,-0.595,-0.0915},{0,0.09,-0.64,-0.155885,0.158483,-0.595,-0.0915,0.155885,-0.64,-0.09},{0,0,-0.64,0,0.09,-0.64,-0.155885,0.155885,-0.64,-0.09},{0,0,-0.595,0,0.158483,-0.595,-0.0915,0.0915,-0.595,-0.158483},{0,0.155885,-0.64,-0.09,0.158483,-0.595,-0.0915,0.183,-0.595,-0.0},{0,0.155885,-0.64,-0.09,0.183,-0.595,-0.0,0.18,-0.64,-0.0},{0,0,-0.64,0,0.155885,-0.64,-0.09,0.18,-0.64,-0.0},{0,0,-0.595,0,0.183,-0.595,-0.0,0.158483,-0.595,-0.0915},{0,0.18,-0.45,0.0,0.183,-0.405,0.0,0.158483,-0.405,0.0915},{0,0.18,-0.45,0.0,0.158483,-0.405,0.0915,0.155885,-0.45,0.09},{0,0,-0.45,0,0.18,-0.45,0.0,0.155885,-0.45,0.09},{0,0,-0.405,0,0.158483,-0.405,0.0915,0.183,-0.405,0.0},{0,0.155885,-0.45,0.09,0.158483,-0.405,0.0915,0.0915,-0.405,0.158483},{0,0.155885,-0.45,0.09,0.0915,-0.405,0.158483,0.09,-0.45,0.155885},{0,0,-0.45,0,0.155885,-0.45,0.09,0.09,-0.45,0.155885},{0,0,-0.405,0,0.0915,-0.405,0.158483,0.158483,-0.405,0.0915},{0,0.09,-0.45,0.155885,0.0915,-0.405,0.158483,0.0,-0.405,0.183},{0,0.09,-0.45,0.155885,0.0,-0.405,0.183,0.0,-0.45,0.18},{0,0,-0.45,0,0.09,-0.45,0.155885,0.0,-0.45,0.18},{0,0,-0.405,0,0.0,-0.405,0.183,0.0915,-0.405,0.158483},{0,0.0,-0.45,0.18,0.0,-0.405,0.183,-0.0915,-0.405,0.158483},{0,0.0,-0.45,0.18,-0.0915,-0.405,0.158483,-0.09,-0.45,0.155885},{0,0,-0.45,0,0.0,-0.45,0.18,-0.09,-0.45,0.155885},{0,0,-0.405,0,-0.0915,-0.405,0.158483,0.0,-0.405,0.183},{0,-0.09,-0.45,0.155885,-0.0915,-0.405,0.158483,-0.158483,-0.405,0.0915},{0,-0.09,-0.45,0.155885,-0.158483,-0.405,0.0915,-0.155885,-0.45,0.09},{0,0,-0.45,0,-0.09,-0.45,0.155885,-0.155885,-0.45,0.09},{0,0,-0.405,0,-0.158483,-0.405,0.0915,-0.0915,-0.405,0.158483},{0,-0.155885,-0.45,0.09,-0.158483,-0.405,0.0915,-0.183,-0.405,0.0},{0,-0.155885,-0.45,0.09,-0.183,-0.405,0.0,-0.18,-0.45,0.0},{0,0,-0.45,0,-0.155885,-0.45,0.09,-0.18,-0.45,0.0},{0,0,-0.405,0,-0.183,-0.405,0.0,-0.158483,-0.405,0.0915},{0,-0.18,-0.45,0.0,-0.183,-0.405,0.0,-0.158483,-0.405,-0.0915},{0,-0.18,-0.45,0.0,-0.158483,-0.405,-0.0915,-0.155885,-0.45,-0.09},{0,0,-0.45,0,-0.18,-0.45,0.0,-0.155885,-0.45,-0.09},{0,0,-0.405,0,-0.158483,-0.405,-0.0915,-0.183,-0.405,0.0},{0,-0.155885,-0.45,-0.09,-0.158483,-0.405,-0.0915,-0.0915,-0.405,-0.158483},{0,-0.155885,-0.45,-0.09,-0.0915,-0.405,-0.158483,-0.09,-0.45,-0.155885},{0,0,-0.45,0,-0.155885,-0.45,-0.09,-0.09,-0.45,-0.155885},{0,0,-0.405,0,-0.0915,-0.405,-0.158483,-0.158483,-0.405,-0.0915},{0,-0.09,-0.45,-0.155885,-0.0915,-0.405,-0.158483,-0.0,-0.405,-0.183},{0,-0.09,-0.45,-0.155885,-0.0,-0.405,-0.183,-0.0,-0.45,-0.18},{0,0,-0.45,0,-0.09,-0.45,-0.155885,-0.0,-0.45,-0.18},{0,0,-0.405,0,-0.0,-0.405,-0.183,-0.0915,-0.405,-0.158483},{0,-0.0,-0.45,-0.18,-0.0,-0.405,-0.183,0.0915,-0.405,-0.158483},{0,-0.0,-0.45,-0.18,0.0915,-0.405,-0.158483,0.09,-0.45,-0.155885},{0,0,-0.45,0,-0.0,-0.45,-0.18,0.09,-0.45,-0.155885},{0,0,-0.405,0,0.0915,-0.405,-0.158483,-0.0,-0.405,-0.183},{0,0.09,-0.45,-0.155885,0.0915,-0.405,-0.158483,0.158483,-0.405,-0.0915},{0,0.09,-0.45,-0.155885,0.158483,-0.405,-0.0915,0.155885,-0.45,-0.09},{0,0,-0.45,0,0.09,-0.45,-0.155885,0.155885,-0.45,-0.09},{0,0,-0.405,0,0.158483,-0.405,-0.0915,0.0915,-0.405,-0.158483},{0,0.155885,-0.45,-0.09,0.158483,-0.405,-0.0915,0.183,-0.405,-0.0},{0,0.155885,-0.45,-0.09,0.183,-0.405,-0.0,0.18,-0.45,-0.0},{0,0,-0.45,0,0.155885,-0.45,-0.09,0.18,-0.45,-0.0},{0,0,-0.405,0,0.183,-0.405,-0.0,0.158483,-0.405,-0.0915},{0,0.18,-0.26,0.0,0.183,-0.215,0.0,0.158483,-0.215,0.0915},{0,0.18,-0.26,0.0,0.158483,-0.215,0.0915,0.155885,-0.26,0.09},{0,0,-0.26,0,0.18,-0.26,0.0,0.155885,-0.26,0.09},{0,0,-0.215,0,0.158483,-0.215,0.0915,0.183,-0.215,0.0},{0,0.155885,-0.26,0.09,0.158483,-0.215,0.0915,0.0915,-0.215,0.158483},{0,0.155885,-0.26,0.09,0.0915,-0.215,0.158483,0.09,-0.26,0.155885},{0,0,-0.26,0,0.155885,-0.26,0.09,0.09,-0.26,0.155885},{0,0,-0.215,0,0.0915,-0.215,0.158483,0.158483,-0.215,0.0915},{0,0.09,-0.26,0.155885,0.0915,-0.215,0.158483,0.0,-0.215,0.183},{0,0.09,-0.26,0.155885,0.0,-0.215,0.183,0.0,-0.26,0.18},{0,0,-0.26,0,0.09,-0.26,0.155885,0.0,-0.26,0.18},{0,0,-0.215,0,0.0,-0.215,0.183,0.0915,-0.215,0.158483},{0,0.0,-0.26,0.18,0.0,-0.215,0.183,-0.0915,-0.215,0.158483},{0,0.0,-0.26,0.18,-0.0915,-0.215,0.158483,-0.09,-0.26,0.155885},{0,0,-0.26,0,0.0,-0.26,0.18,-0.09,-0.26,0.155885},{0,0,-0.215,0,-0.0915,-0.215,0.158483,0.0,-0.215,0.183},{0,-0.09,-0.26,0.155885,-0.0915,-0.215,0.158483,-0.158483,-0.215,0.0915},{0,-0.09,-0.26,0.155885,-0.158483,-0.215,0.0915,-0.155885,-0.26,0.09},{0,0,-0.26,0,-0.09,-0.26,0.155885,-0.155885,-0.26,0.09},{0,0,-0.215,0,-0.158483,-0.215,0.0915,-0.0915,-0.215,0.158483},{0,-0.155885,-0.26,0.09,-0.158483,-0.215,0.0915,-0.183,-0.215,0.0},{0,-0.155885,-0.26,0.09,-0.183,-0.215,0.0,-0.18,-0.26,0.0},{0,0,-0.26,0,-0.155885,-0.26,0.09,-0.18,-0.26,0.0},{0,0,-0.215,0,-0.183,-0.215,0.0,-0.158483,-0.215,0.0915},{0,-0.18,-0.26,0.0,-0.183,-0.215,0.0,-0.158483,-0.215,-0.0915},{0,-0.18,-0.26,0.0,-0.158483,-0.215,-0.0915,-0.155885,-0.26,-0.09},{0,0,-0.26,0,-0.18,-0.26,0.0,-0.155885,-0.26,-0.09},{0,0,-0.215,0,-0.158483,-0.215,-0.0915,-0.183,-0.215,0.0},{0,-0.155885,-0.26,-0.09,-0.158483,-0.215,-0.0915,-0.0915,-0.215,-0.158483},{0,-0.155885,-0.26,-0.09,-0.0915,-0.215,-0.158483,-0.09,-0.26,-0.155885},{0,0,-0.26,0,-0.155885,-0.26,-0.09,-0.09,-0.26,-0.155885},{0,0,-0.215,0,-0.0915,-0.215,-0.158483,-0.158483,-0.215,-0.0915},{0,-0.09,-0.26,-0.155885,-0.0915,-0.215,-0.158483,-0.0,-0.215,-0.183},{0,-0.09,-0.26,-0.155885,-0.0,-0.215,-0.183,-0.0,-0.26,-0.18},{0,0,-0.26,0,-0.09,-0.26,-0.155885,-0.0,-0.26,-0.18},{0,0,-0.215,0,-0.0,-0.215,-0.183,-0.0915,-0.215,-0.158483},{0,-0.0,-0.26,-0.18,-0.0,-0.215,-0.183,0.0915,-0.215,-0.158483},{0,-0.0,-0.26,-0.18,0.0915,-0.215,-0.158483,0.09,-0.26,-0.155885},{0,0,-0.26,0,-0.0,-0.26,-0.18,0.09,-0.26,-0.155885},{0,0,-0.215,0,0.0915,-0.215,-0.158483,-0.0,-0.215,-0.183},{0,0.09,-0.26,-0.155885,0.0915,-0.215,-0.158483,0.158483,-0.215,-0.0915},{0,0.09,-0.26,-0.155885,0.158483,-0.215,-0.0915,0.155885,-0.26,-0.09},{0,0,-0.26,0,0.09,-0.26,-0.155885,0.155885,-0.26,-0.09},{0,0,-0.215,0,0.158483,-0.215,-0.0915,0.0915,-0.215,-0.158483},{0,0.155885,-0.26,-0.09,0.158483,-0.215,-0.0915,0.183,-0.215,-0.0},{0,0.155885,-0.26,-0.09,0.183,-0.215,-0.0,0.18,-0.26,-0.0},{0,0,-0.26,0,0.155885,-0.26,-0.09,0.18,-0.26,-0.0},{0,0,-0.215,0,0.183,-0.215,-0.0,0.158483,-0.215,-0.0915},{0,0.235,-1.19,0.0,0.19,-1.04,0.0,0.164545,-1.04,0.095},{0,0.235,-1.19,0.0,0.164545,-1.04,0.095,0.203516,-1.19,0.1175},{0,0,-1.19,0,0.235,-1.19,0.0,0.203516,-1.19,0.1175},{0,0,-1.04,0,0.164545,-1.04,0.095,0.19,-1.04,0.0},{0,0.203516,-1.19,0.1175,0.164545,-1.04,0.095,0.095,-1.04,0.164545},{0,0.203516,-1.19,0.1175,0.095,-1.04,0.164545,0.1175,-1.19,0.203516},{0,0,-1.19,0,0.203516,-1.19,0.1175,0.1175,-1.19,0.203516},{0,0,-1.04,0,0.095,-1.04,0.164545,0.164545,-1.04,0.095},{0,0.1175,-1.19,0.203516,0.095,-1.04,0.164545,0.0,-1.04,0.19},{0,0.1175,-1.19,0.203516,0.0,-1.04,0.19,0.0,-1.19,0.235},{0,0,-1.19,0,0.1175,-1.19,0.203516,0.0,-1.19,0.235},{0,0,-1.04,0,0.0,-1.04,0.19,0.095,-1.04,0.164545},{0,0.0,-1.19,0.235,0.0,-1.04,0.19,-0.095,-1.04,0.164545},{0,0.0,-1.19,0.235,-0.095,-1.04,0.164545,-0.1175,-1.19,0.203516},{0,0,-1.19,0,0.0,-1.19,0.235,-0.1175,-1.19,0.203516},{0,0,-1.04,0,-0.095,-1.04,0.164545,0.0,-1.04,0.19},{0,-0.1175,-1.19,0.203516,-0.095,-1.04,0.164545,-0.164545,-1.04,0.095},{0,-0.1175,-1.19,0.203516,-0.164545,-1.04,0.095,-0.203516,-1.19,0.1175},{0,0,-1.19,0,-0.1175,-1.19,0.203516,-0.203516,-1.19,0.1175},{0,0,-1.04,0,-0.164545,-1.04,0.095,-0.095,-1.04,0.164545},{0,-0.203516,-1.19,0.1175,-0.164545,-1.04,0.095,-0.19,-1.04,0.0},{0,-0.203516,-1.19,0.1175,-0.19,-1.04,0.0,-0.235,-1.19,0.0},{0,0,-1.19,0,-0.203516,-1.19,0.1175,-0.235,-1.19,0.0},{0,0,-1.04,0,-0.19,-1.04,0.0,-0.164545,-1.04,0.095},{0,-0.235,-1.19,0.0,-0.19,-1.04,0.0,-0.164545,-1.04,-0.095},{0,-0.235,-1.19,0.0,-0.164545,-1.04,-0.095,-0.203516,-1.19,-0.1175},{0,0,-1.19,0,-0.235,-1.19,0.0,-0.203516,-1.19,-0.1175},{0,0,-1.04,0,-0.164545,-1.04,-0.095,-0.19,-1.04,0.0},{0,-0.203516,-1.19,-0.1175,-0.164545,-1.04,-0.095,-0.095,-1.04,-0.164545},{0,-0.203516,-1.19,-0.1175,-0.095,-1.04,-0.164545,-0.1175,-1.19,-0.203516},{0,0,-1.19,0,-0.203516,-1.19,-0.1175,-0.1175,-1.19,-0.203516},{0,0,-1.04,0,-0.095,-1.04,-0.164545,-0.164545,-1.04,-0.095},{0,-0.1175,-1.19,-0.203516,-0.095,-1.04,-0.164545,-0.0,-1.04,-0.19},{0,-0.1175,-1.19,-0.203516,-0.0,-1.04,-0.19,-0.0,-1.19,-0.235},{0,0,-1.19,0,-0.1175,-1.19,-0.203516,-0.0,-1.19,-0.235},{0,0,-1.04,0,-0.0,-1.04,-0.19,-0.095,-1.04,-0.164545},{0,-0.0,-1.19,-0.235,-0.0,-1.04,-0.19,0.095,-1.04,-0.164545},{0,-0.0,-1.19,-0.235,0.095,-1.04,-0.164545,0.1175,-1.19,-0.203516},{0,0,-1.19,0,-0.0,-1.19,-0.235,0.1175,-1.19,-0.203516},{0,0,-1.04,0,0.095,-1.04,-0.164545,-0.0,-1.04,-0.19},{0,0.1175,-1.19,-0.203516,0.095,-1.04,-0.164545,0.164545,-1.04,-0.095},{0,0.1175,-1.19,-0.203516,0.164545,-1.04,-0.095,0.203516,-1.19,-0.1175},{0,0,-1.19,0,0.1175,-1.19,-0.203516,0.203516,-1.19,-0.1175},{0,0,-1.04,0,0.164545,-1.04,-0.095,0.095,-1.04,-0.164545},{0,0.203516,-1.19,-0.1175,0.164545,-1.04,-0.095,0.19,-1.04,-0.0},{0,0.203516,-1.19,-0.1175,0.19,-1.04,-0.0,0.235,-1.19,-0.0},{0,0,-1.19,0,0.203516,-1.19,-0.1175,0.235,-1.19,-0.0},{0,0,-1.04,0,0.19,-1.04,-0.0,0.164545,-1.04,-0.095},{2,0,-1.09,-0.19,0.09,-1.14,-0.19,0,-0.97,-0.19},{2,0,-0.97,-0.2,0.09,-1.14,-0.2,0,-1.09,-0.2},{2,0,-1.09,-0.19,0,-0.97,-0.19,-0.09,-1.14,-0.19},{2,-0.09,-1.14,-0.2,0,-0.97,-0.2,0,-1.09,-0.2},{2,0,-1.09,-0.2,0.09,-1.14,-0.2,0.09,-1.14,-0.19},{2,0,-1.09,-0.2,0.09,-1.14,-0.19,0,-1.09,-0.19},{2,0.09,-1.14,-0.2,0,-0.97,-0.2,0,-0.97,-0.19},{2,0.09,-1.14,-0.2,0,-0.97,-0.19,0.09,-1.14,-0.19},{2,0,-0.97,-0.2,-0.09,-1.14,-0.2,-0.09,-1.14,-0.19},{2,0,-0.97,-0.2,-0.09,-1.14,-0.19,0,-0.97,-0.19},{2,-0.09,-1.14,-0.2,0,-1.09,-0.2,0,-1.09,-0.19},{2,-0.09,-1.14,-0.2,0,-1.09,-0.19,-0.09,-1.14,-0.19},{2,0,-1.09,0.2,0.09,-1.14,0.2,0,-0.97,0.2},{2,0,-0.97,0.19,0.09,-1.14,0.19,0,-1.09,0.19},{2,0,-1.09,0.2,0,-0.97,0.2,-0.09,-1.14,0.2},{2,-0.09,-1.14,0.19,0,-0.97,0.19,0,-1.09,0.19},{2,0,-1.09,0.19,0.09,-1.14,0.19,0.09,-1.14,0.2},{2,0,-1.09,0.19,0.09,-1.14,0.2,0,-1.09,0.2},{2,0.09,-1.14,0.19,0,-0.97,0.19,0,-0.97,0.2},{2,0.09,-1.14,0.19,0,-0.97,0.2,0.09,-1.14,0.2},{2,0,-0.97,0.19,-0.09,-1.14,0.19,-0.09,-1.14,0.2},{2,0,-0.97,0.19,-0.09,-1.14,0.2,0,-0.97,0.2},{2,-0.09,-1.14,0.19,0,-1.09,0.19,0,-1.09,0.2},{2,-0.09,-1.14,0.19,0,-1.09,0.2,-0.09,-1.14,0.2}},colors={Color3.fromRGB(12,13,19),Color3.fromRGB(82,66,60),Color3.fromRGB(255,95,20),Color3.fromRGB(19,17,26),Color3.fromRGB(204,217,240)}},
        {name="KUNAI",triangles={{1,-0.115,0.015,0,-0.38,0.43,0,0,0.47,0.1},{1,-0.38,0.43,0,-0.115,0.015,0,0,0.47,-0.1},{1,-0.38,0.43,0,0,1.52,0,0,0.47,0.1},{1,0,1.52,0,-0.38,0.43,0,0,0.47,-0.1},{1,0,1.52,0,0.38,0.43,0,0,0.47,0.1},{1,0.38,0.43,0,0,1.52,0,0,0.47,-0.1},{1,0.38,0.43,0,0.115,0.015,0,0,0.47,0.1},{1,0.115,0.015,0,0.38,0.43,0,0,0.47,-0.1},{1,0.115,0.015,0,-0.115,0.015,0,0,0.47,0.1},{1,-0.115,0.015,0,0.115,0.015,0,0,0.47,-0.1},{5,0.021,1.29,-0.018168,0.055,0.55,-0.079356,0.073,0.58,-0.071581},{5,0.073,0.58,-0.071581,0.034,1.22,-0.021283,0.021,1.29,-0.018168},{4,0,0.315,-0.067934,0.048,0.29,-0.061822,0,0.39,-0.084418},{4,0,0.315,-0.067934,0,0.39,-0.084418,-0.048,0.29,-0.061822},{5,0.021,1.29,0.018168,0.055,0.55,0.079356,0.073,0.58,0.071581},{5,0.073,0.58,0.071581,0.034,1.22,0.021283,0.021,1.29,0.018168},{4,0,0.315,0.067934,0.048,0.29,0.061822,0,0.39,0.084418},{4,0,0.315,0.067934,0,0.39,0.084418,-0.048,0.29,0.061822},{1,-0.115,0.12,0.035,-0.11,-0.025,0.035,0.11,-0.025,0.035},{1,0.11,-0.025,-0.035,-0.11,-0.025,-0.035,-0.115,0.12,-0.035},{1,0.11,-0.025,0.035,0.115,0.12,0.035,-0.115,0.12,0.035},{1,-0.115,0.12,-0.035,0.115,0.12,-0.035,0.11,-0.025,-0.035},{1,-0.11,-0.025,-0.035,0.11,-0.025,-0.035,0.11,-0.025,0.035},{1,-0.11,-0.025,-0.035,0.11,-0.025,0.035,-0.11,-0.025,0.035},{1,0.11,-0.025,-0.035,0.115,0.12,-0.035,0.115,0.12,0.035},{1,0.11,-0.025,-0.035,0.115,0.12,0.035,0.11,-0.025,0.035},{1,0.115,0.12,-0.035,-0.115,0.12,-0.035,-0.115,0.12,0.035},{1,0.115,0.12,-0.035,-0.115,0.12,0.035,0.115,0.12,0.035},{1,-0.115,0.12,-0.035,-0.11,-0.025,-0.035,-0.11,-0.025,0.035},{1,-0.115,0.12,-0.035,-0.11,-0.025,0.035,-0.115,0.12,0.035},{0,0.225,-1.12,0.0,0.194856,-1.0075,0.0,0.160215,-1.0275,0.04},{0,0.225,-1.12,0.0,0.160215,-1.0275,0.04,0.185,-1.12,0.04},{0,0.185,-1.12,0.04,0.160215,-1.0275,0.04,0.125574,-1.0475,0.0},{0,0.185,-1.12,0.04,0.125574,-1.0475,0.0,0.145,-1.12,0.0},{0,0.145,-1.12,0.0,0.125574,-1.0475,0.0,0.160215,-1.0275,-0.04},{0,0.145,-1.12,0.0,0.160215,-1.0275,-0.04,0.185,-1.12,-0.04},{0,0.185,-1.12,-0.04,0.160215,-1.0275,-0.04,0.194856,-1.0075,-0.0},{0,0.185,-1.12,-0.04,0.194856,-1.0075,-0.0,0.225,-1.12,-0.0},{0,0.194856,-1.0075,0.0,0.1125,-0.925144,0.0,0.0925,-0.959785,0.04},{0,0.194856,-1.0075,0.0,0.0925,-0.959785,0.04,0.160215,-1.0275,0.04},{0,0.160215,-1.0275,0.04,0.0925,-0.959785,0.04,0.0725,-0.994426,0.0},{0,0.160215,-1.0275,0.04,0.0725,-0.994426,0.0,0.125574,-1.0475,0.0},{0,0.125574,-1.0475,0.0,0.0725,-0.994426,0.0,0.0925,-0.959785,-0.04},{0,0.125574,-1.0475,0.0,0.0925,-0.959785,-0.04,0.160215,-1.0275,-0.04},{0,0.160215,-1.0275,-0.04,0.0925,-0.959785,-0.04,0.1125,-0.925144,-0.0},{0,0.160215,-1.0275,-0.04,0.1125,-0.925144,-0.0,0.194856,-1.0075,-0.0},{0,0.1125,-0.925144,0.0,0.0,-0.895,0.0,0.0,-0.935,0.04},{0,0.1125,-0.925144,0.0,0.0,-0.935,0.04,0.0925,-0.959785,0.04},{0,0.0925,-0.959785,0.04,0.0,-0.935,0.04,0.0,-0.975,0.0},{0,0.0925,-0.959785,0.04,0.0,-0.975,0.0,0.0725,-0.994426,0.0},{0,0.0725,-0.994426,0.0,0.0,-0.975,0.0,0.0,-0.935,-0.04},{0,0.0725,-0.994426,0.0,0.0,-0.935,-0.04,0.0925,-0.959785,-0.04},{0,0.0925,-0.959785,-0.04,0.0,-0.935,-0.04,0.0,-0.895,-0.0},{0,0.0925,-0.959785,-0.04,0.0,-0.895,-0.0,0.1125,-0.925144,-0.0},{0,0.0,-0.895,0.0,-0.1125,-0.925144,0.0,-0.0925,-0.959785,0.04},{0,0.0,-0.895,0.0,-0.0925,-0.959785,0.04,0.0,-0.935,0.04},{0,0.0,-0.935,0.04,-0.0925,-0.959785,0.04,-0.0725,-0.994426,0.0},{0,0.0,-0.935,0.04,-0.0725,-0.994426,0.0,0.0,-0.975,0.0},{0,0.0,-0.975,0.0,-0.0725,-0.994426,0.0,-0.0925,-0.959785,-0.04},{0,0.0,-0.975,0.0,-0.0925,-0.959785,-0.04,0.0,-0.935,-0.04},{0,0.0,-0.935,-0.04,-0.0925,-0.959785,-0.04,-0.1125,-0.925144,-0.0},{0,0.0,-0.935,-0.04,-0.1125,-0.925144,-0.0,0.0,-0.895,-0.0},{0,-0.1125,-0.925144,0.0,-0.194856,-1.0075,0.0,-0.160215,-1.0275,0.04},{0,-0.1125,-0.925144,0.0,-0.160215,-1.0275,0.04,-0.0925,-0.959785,0.04},{0,-0.0925,-0.959785,0.04,-0.160215,-1.0275,0.04,-0.125574,-1.0475,0.0},{0,-0.0925,-0.959785,0.04,-0.125574,-1.0475,0.0,-0.0725,-0.994426,0.0},{0,-0.0725,-0.994426,0.0,-0.125574,-1.0475,0.0,-0.160215,-1.0275,-0.04},{0,-0.0725,-0.994426,0.0,-0.160215,-1.0275,-0.04,-0.0925,-0.959785,-0.04},{0,-0.0925,-0.959785,-0.04,-0.160215,-1.0275,-0.04,-0.194856,-1.0075,-0.0},{0,-0.0925,-0.959785,-0.04,-0.194856,-1.0075,-0.0,-0.1125,-0.925144,-0.0},{0,-0.194856,-1.0075,0.0,-0.225,-1.12,0.0,-0.185,-1.12,0.04},{0,-0.194856,-1.0075,0.0,-0.185,-1.12,0.04,-0.160215,-1.0275,0.04},{0,-0.160215,-1.0275,0.04,-0.185,-1.12,0.04,-0.145,-1.12,0.0},{0,-0.160215,-1.0275,0.04,-0.145,-1.12,0.0,-0.125574,-1.0475,0.0},{0,-0.125574,-1.0475,0.0,-0.145,-1.12,0.0,-0.185,-1.12,-0.04},{0,-0.125574,-1.0475,0.0,-0.185,-1.12,-0.04,-0.160215,-1.0275,-0.04},{0,-0.160215,-1.0275,-0.04,-0.185,-1.12,-0.04,-0.225,-1.12,-0.0},{0,-0.160215,-1.0275,-0.04,-0.225,-1.12,-0.0,-0.194856,-1.0075,-0.0},{0,-0.225,-1.12,0.0,-0.194856,-1.2325,0.0,-0.160215,-1.2125,0.04},{0,-0.225,-1.12,0.0,-0.160215,-1.2125,0.04,-0.185,-1.12,0.04},{0,-0.185,-1.12,0.04,-0.160215,-1.2125,0.04,-0.125574,-1.1925,0.0},{0,-0.185,-1.12,0.04,-0.125574,-1.1925,0.0,-0.145,-1.12,0.0},{0,-0.145,-1.12,0.0,-0.125574,-1.1925,0.0,-0.160215,-1.2125,-0.04},{0,-0.145,-1.12,0.0,-0.160215,-1.2125,-0.04,-0.185,-1.12,-0.04},{0,-0.185,-1.12,-0.04,-0.160215,-1.2125,-0.04,-0.194856,-1.2325,-0.0},{0,-0.185,-1.12,-0.04,-0.194856,-1.2325,-0.0,-0.225,-1.12,-0.0},{0,-0.194856,-1.2325,0.0,-0.1125,-1.314856,0.0,-0.0925,-1.280215,0.04},{0,-0.194856,-1.2325,0.0,-0.0925,-1.280215,0.04,-0.160215,-1.2125,0.04},{0,-0.160215,-1.2125,0.04,-0.0925,-1.280215,0.04,-0.0725,-1.245574,0.0},{0,-0.160215,-1.2125,0.04,-0.0725,-1.245574,0.0,-0.125574,-1.1925,0.0},{0,-0.125574,-1.1925,0.0,-0.0725,-1.245574,0.0,-0.0925,-1.280215,-0.04},{0,-0.125574,-1.1925,0.0,-0.0925,-1.280215,-0.04,-0.160215,-1.2125,-0.04},{0,-0.160215,-1.2125,-0.04,-0.0925,-1.280215,-0.04,-0.1125,-1.314856,-0.0},{0,-0.160215,-1.2125,-0.04,-0.1125,-1.314856,-0.0,-0.194856,-1.2325,-0.0},{0,-0.1125,-1.314856,0.0,-0.0,-1.345,0.0,-0.0,-1.305,0.04},{0,-0.1125,-1.314856,0.0,-0.0,-1.305,0.04,-0.0925,-1.280215,0.04},{0,-0.0925,-1.280215,0.04,-0.0,-1.305,0.04,-0.0,-1.265,0.0},{0,-0.0925,-1.280215,0.04,-0.0,-1.265,0.0,-0.0725,-1.245574,0.0},{0,-0.0725,-1.245574,0.0,-0.0,-1.265,0.0,-0.0,-1.305,-0.04},{0,-0.0725,-1.245574,0.0,-0.0,-1.305,-0.04,-0.0925,-1.280215,-0.04},{0,-0.0925,-1.280215,-0.04,-0.0,-1.305,-0.04,-0.0,-1.345,-0.0},{0,-0.0925,-1.280215,-0.04,-0.0,-1.345,-0.0,-0.1125,-1.314856,-0.0},{0,-0.0,-1.345,0.0,0.1125,-1.314856,0.0,0.0925,-1.280215,0.04},{0,-0.0,-1.345,0.0,0.0925,-1.280215,0.04,-0.0,-1.305,0.04},{0,-0.0,-1.305,0.04,0.0925,-1.280215,0.04,0.0725,-1.245574,0.0},{0,-0.0,-1.305,0.04,0.0725,-1.245574,0.0,-0.0,-1.265,0.0},{0,-0.0,-1.265,0.0,0.0725,-1.245574,0.0,0.0925,-1.280215,-0.04},{0,-0.0,-1.265,0.0,0.0925,-1.280215,-0.04,-0.0,-1.305,-0.04},{0,-0.0,-1.305,-0.04,0.0925,-1.280215,-0.04,0.1125,-1.314856,-0.0},{0,-0.0,-1.305,-0.04,0.1125,-1.314856,-0.0,-0.0,-1.345,-0.0},{0,0.1125,-1.314856,0.0,0.194856,-1.2325,0.0,0.160215,-1.2125,0.04},{0,0.1125,-1.314856,0.0,0.160215,-1.2125,0.04,0.0925,-1.280215,0.04},{0,0.0925,-1.280215,0.04,0.160215,-1.2125,0.04,0.125574,-1.1925,0.0},{0,0.0925,-1.280215,0.04,0.125574,-1.1925,0.0,0.0725,-1.245574,0.0},{0,0.0725,-1.245574,0.0,0.125574,-1.1925,0.0,0.160215,-1.2125,-0.04},{0,0.0725,-1.245574,0.0,0.160215,-1.2125,-0.04,0.0925,-1.280215,-0.04},{0,0.0925,-1.280215,-0.04,0.160215,-1.2125,-0.04,0.194856,-1.2325,-0.0},{0,0.0925,-1.280215,-0.04,0.194856,-1.2325,-0.0,0.1125,-1.314856,-0.0},{0,0.194856,-1.2325,0.0,0.225,-1.12,0.0,0.185,-1.12,0.04},{0,0.194856,-1.2325,0.0,0.185,-1.12,0.04,0.160215,-1.2125,0.04},{0,0.160215,-1.2125,0.04,0.185,-1.12,0.04,0.145,-1.12,0.0},{0,0.160215,-1.2125,0.04,0.145,-1.12,0.0,0.125574,-1.1925,0.0},{0,0.125574,-1.1925,0.0,0.145,-1.12,0.0,0.185,-1.12,-0.04},{0,0.125574,-1.1925,0.0,0.185,-1.12,-0.04,0.160215,-1.2125,-0.04},{0,0.160215,-1.2125,-0.04,0.185,-1.12,-0.04,0.225,-1.12,-0.0},{0,0.160215,-1.2125,-0.04,0.225,-1.12,-0.0,0.194856,-1.2325,-0.0}},colors={Color3.fromRGB(23,33,48),Color3.fromRGB(184,204,222),Color3.fromRGB(128,128,128),Color3.fromRGB(11,14,19),Color3.fromRGB(230,171,64),Color3.fromRGB(247,251,255)},kunaiGrip=true},
        {name="BUTTERFLY KNIFE",triangles={{1,-0.08,0.05,0,-0.145,0.38,0,0,0.48,0.045,0},{1,-0.145,0.38,0,-0.08,0.05,0,0,0.48,-0.045,0},{1,-0.145,0.38,0,-0.12,1.1,0,0,0.48,0.045,0},{1,-0.12,1.1,0,-0.145,0.38,0,0,0.48,-0.045,0},{1,-0.12,1.1,0,0,1.55,0,0,0.48,0.045,0},{1,0,1.55,0,-0.12,1.1,0,0,0.48,-0.045,0},{1,0,1.55,0,0.145,0.4,0,0,0.48,0.045,0},{1,0.145,0.4,0,0,1.55,0,0,0.48,-0.045,0},{1,0.145,0.4,0,0.08,0.05,0,0,0.48,0.045,0},{1,0.08,0.05,0,0.145,0.4,0,0,0.48,-0.045,0},{1,0.08,0.05,0,-0.08,0.05,0,0,0.48,0.045,0},{1,-0.08,0.05,0,0.08,0.05,0,0,0.48,-0.045,0},{0,-0.165,0.06,0.065,-0.165,-0.96,0.065,-0.055,-0.985,0.065,-1},{0,-0.055,-0.985,-0.065,-0.165,-0.96,-0.065,-0.165,0.06,-0.065,-1},{0,-0.165,0.06,0.065,-0.055,-0.985,0.065,-0.025,-0.94,0.065,-1},{0,-0.025,-0.94,-0.065,-0.055,-0.985,-0.065,-0.165,0.06,-0.065,-1},{0,-0.165,0.06,0.065,-0.025,-0.94,0.065,-0.035,0.065,0.065,-1},{0,-0.035,0.065,-0.065,-0.025,-0.94,-0.065,-0.165,0.06,-0.065,-1},{0,-0.165,0.06,0.065,-0.035,0.065,0.065,-0.065,0.09,0.065,-1},{0,-0.065,0.09,-0.065,-0.035,0.065,-0.065,-0.165,0.06,-0.065,-1},{0,-0.065,0.09,0.065,-0.145,0.09,0.065,-0.165,0.06,0.065,-1},{0,-0.165,0.06,-0.065,-0.145,0.09,-0.065,-0.065,0.09,-0.065,-1},{0,-0.165,-0.96,-0.065,-0.055,-0.985,-0.065,-0.055,-0.985,0.065,-1},{0,-0.165,-0.96,-0.065,-0.055,-0.985,0.065,-0.165,-0.96,0.065,-1},{0,-0.055,-0.985,-0.065,-0.025,-0.94,-0.065,-0.025,-0.94,0.065,-1},{0,-0.055,-0.985,-0.065,-0.025,-0.94,0.065,-0.055,-0.985,0.065,-1},{0,-0.025,-0.94,-0.065,-0.035,0.065,-0.065,-0.035,0.065,0.065,-1},{0,-0.025,-0.94,-0.065,-0.035,0.065,0.065,-0.025,-0.94,0.065,-1},{0,-0.035,0.065,-0.065,-0.065,0.09,-0.065,-0.065,0.09,0.065,-1},{0,-0.035,0.065,-0.065,-0.065,0.09,0.065,-0.035,0.065,0.065,-1},{0,-0.065,0.09,-0.065,-0.145,0.09,-0.065,-0.145,0.09,0.065,-1},{0,-0.065,0.09,-0.065,-0.145,0.09,0.065,-0.065,0.09,0.065,-1},{0,-0.145,0.09,-0.065,-0.165,0.06,-0.065,-0.165,0.06,0.065,-1},{0,-0.145,0.09,-0.065,-0.165,0.06,0.065,-0.145,0.09,0.065,-1},{0,-0.165,0.06,-0.065,-0.165,-0.96,-0.065,-0.165,-0.96,0.065,-1},{0,-0.165,0.06,-0.065,-0.165,-0.96,0.065,-0.165,0.06,0.065,-1},{1,-0.155,0.05,0.07,-0.16,-0.92,0.07,-0.139,-0.93,0.07,-1},{1,-0.139,-0.93,0.066,-0.16,-0.92,0.066,-0.155,0.05,0.066,-1},{1,-0.139,-0.93,0.07,-0.135,0.045,0.07,-0.155,0.05,0.07,-1},{1,-0.155,0.05,0.066,-0.135,0.045,0.066,-0.139,-0.93,0.066,-1},{1,-0.16,-0.92,0.066,-0.139,-0.93,0.066,-0.139,-0.93,0.07,-1},{1,-0.16,-0.92,0.066,-0.139,-0.93,0.07,-0.16,-0.92,0.07,-1},{1,-0.139,-0.93,0.066,-0.135,0.045,0.066,-0.135,0.045,0.07,-1},{1,-0.139,-0.93,0.066,-0.135,0.045,0.07,-0.139,-0.93,0.07,-1},{1,-0.135,0.045,0.066,-0.155,0.05,0.066,-0.155,0.05,0.07,-1},{1,-0.135,0.045,0.066,-0.155,0.05,0.07,-0.135,0.045,0.07,-1},{1,-0.155,0.05,0.066,-0.16,-0.92,0.066,-0.16,-0.92,0.07,-1},{1,-0.155,0.05,0.066,-0.16,-0.92,0.07,-0.155,0.05,0.07,-1},{3,-0.123,-0.12,0.072,-0.125,-0.84,0.072,-0.057,-0.84,0.072,-1},{3,-0.057,-0.84,0.066,-0.125,-0.84,0.066,-0.123,-0.12,0.066,-1},{3,-0.057,-0.84,0.072,-0.066,-0.12,0.072,-0.123,-0.12,0.072,-1},{3,-0.123,-0.12,0.066,-0.066,-0.12,0.066,-0.057,-0.84,0.066,-1},{3,-0.125,-0.84,0.066,-0.057,-0.84,0.066,-0.057,-0.84,0.072,-1},{3,-0.125,-0.84,0.066,-0.057,-0.84,0.072,-0.125,-0.84,0.072,-1},{3,-0.057,-0.84,0.066,-0.066,-0.12,0.066,-0.066,-0.12,0.072,-1},{3,-0.057,-0.84,0.066,-0.066,-0.12,0.072,-0.057,-0.84,0.072,-1},{3,-0.066,-0.12,0.066,-0.123,-0.12,0.066,-0.123,-0.12,0.072,-1},{3,-0.066,-0.12,0.066,-0.123,-0.12,0.072,-0.066,-0.12,0.072,-1},{3,-0.123,-0.12,0.066,-0.125,-0.84,0.066,-0.125,-0.84,0.072,-1},{3,-0.123,-0.12,0.066,-0.125,-0.84,0.072,-0.123,-0.12,0.072,-1},{0,-0.115,-0.702,0.075,-0.115,-0.74,0.075,-0.067,-0.72,0.075,-1},{0,-0.067,-0.72,0.073,-0.115,-0.74,0.073,-0.115,-0.702,0.073,-1},{0,-0.067,-0.72,0.075,-0.067,-0.682,0.075,-0.115,-0.702,0.075,-1},{0,-0.115,-0.702,0.073,-0.067,-0.682,0.073,-0.067,-0.72,0.073,-1},{0,-0.115,-0.74,0.073,-0.067,-0.72,0.073,-0.067,-0.72,0.075,-1},{0,-0.115,-0.74,0.073,-0.067,-0.72,0.075,-0.115,-0.74,0.075,-1},{0,-0.067,-0.72,0.073,-0.067,-0.682,0.073,-0.067,-0.682,0.075,-1},{0,-0.067,-0.72,0.073,-0.067,-0.682,0.075,-0.067,-0.72,0.075,-1},{0,-0.067,-0.682,0.073,-0.115,-0.702,0.073,-0.115,-0.702,0.075,-1},{0,-0.067,-0.682,0.073,-0.115,-0.702,0.075,-0.067,-0.682,0.075,-1},{0,-0.115,-0.702,0.073,-0.115,-0.74,0.073,-0.115,-0.74,0.075,-1},{0,-0.115,-0.702,0.073,-0.115,-0.74,0.075,-0.115,-0.702,0.075,-1},{0,-0.115,-0.502,0.075,-0.115,-0.54,0.075,-0.067,-0.52,0.075,-1},{0,-0.067,-0.52,0.073,-0.115,-0.54,0.073,-0.115,-0.502,0.073,-1},{0,-0.067,-0.52,0.075,-0.067,-0.482,0.075,-0.115,-0.502,0.075,-1},{0,-0.115,-0.502,0.073,-0.067,-0.482,0.073,-0.067,-0.52,0.073,-1},{0,-0.115,-0.54,0.073,-0.067,-0.52,0.073,-0.067,-0.52,0.075,-1},{0,-0.115,-0.54,0.073,-0.067,-0.52,0.075,-0.115,-0.54,0.075,-1},{0,-0.067,-0.52,0.073,-0.067,-0.482,0.073,-0.067,-0.482,0.075,-1},{0,-0.067,-0.52,0.073,-0.067,-0.482,0.075,-0.067,-0.52,0.075,-1},{0,-0.067,-0.482,0.073,-0.115,-0.502,0.073,-0.115,-0.502,0.075,-1},{0,-0.067,-0.482,0.073,-0.115,-0.502,0.075,-0.067,-0.482,0.075,-1},{0,-0.115,-0.502,0.073,-0.115,-0.54,0.073,-0.115,-0.54,0.075,-1},{0,-0.115,-0.502,0.073,-0.115,-0.54,0.075,-0.115,-0.502,0.075,-1},{0,-0.115,-0.302,0.075,-0.115,-0.34,0.075,-0.067,-0.32,0.075,-1},{0,-0.067,-0.32,0.073,-0.115,-0.34,0.073,-0.115,-0.302,0.073,-1},{0,-0.067,-0.32,0.075,-0.067,-0.282,0.075,-0.115,-0.302,0.075,-1},{0,-0.115,-0.302,0.073,-0.067,-0.282,0.073,-0.067,-0.32,0.073,-1},{0,-0.115,-0.34,0.073,-0.067,-0.32,0.073,-0.067,-0.32,0.075,-1},{0,-0.115,-0.34,0.073,-0.067,-0.32,0.075,-0.115,-0.34,0.075,-1},{0,-0.067,-0.32,0.073,-0.067,-0.282,0.073,-0.067,-0.282,0.075,-1},{0,-0.067,-0.32,0.073,-0.067,-0.282,0.075,-0.067,-0.32,0.075,-1},{0,-0.067,-0.282,0.073,-0.115,-0.302,0.073,-0.115,-0.302,0.075,-1},{0,-0.067,-0.282,0.073,-0.115,-0.302,0.075,-0.067,-0.282,0.075,-1},{0,-0.115,-0.302,0.073,-0.115,-0.34,0.073,-0.115,-0.34,0.075,-1},{0,-0.115,-0.302,0.073,-0.115,-0.34,0.075,-0.115,-0.302,0.075,-1},{4,-0.067473,-0.012527,0.085,-0.054,0.02,0.085,-0.067473,0.052527,0.085,-1},{4,-0.067473,0.052527,0.071,-0.054,0.02,0.071,-0.067473,-0.012527,0.071,-1},{4,-0.067473,-0.012527,0.085,-0.067473,0.052527,0.085,-0.1,0.066,0.085,-1},{4,-0.1,0.066,0.071,-0.067473,0.052527,0.071,-0.067473,-0.012527,0.071,-1},{4,-0.067473,-0.012527,0.085,-0.1,0.066,0.085,-0.132527,0.052527,0.085,-1},{4,-0.132527,0.052527,0.071,-0.1,0.066,0.071,-0.067473,-0.012527,0.071,-1},{4,-0.067473,-0.012527,0.085,-0.132527,0.052527,0.085,-0.146,0.02,0.085,-1},{4,-0.146,0.02,0.071,-0.132527,0.052527,0.071,-0.067473,-0.012527,0.071,-1},{4,-0.067473,-0.012527,0.085,-0.146,0.02,0.085,-0.132527,-0.012527,0.085,-1},{4,-0.132527,-0.012527,0.071,-0.146,0.02,0.071,-0.067473,-0.012527,0.071,-1},{4,-0.132527,-0.012527,0.085,-0.1,-0.026,0.085,-0.067473,-0.012527,0.085,-1},{4,-0.067473,-0.012527,0.071,-0.1,-0.026,0.071,-0.132527,-0.012527,0.071,-1},{4,-0.054,0.02,0.071,-0.067473,0.052527,0.071,-0.067473,0.052527,0.085,-1},{4,-0.054,0.02,0.071,-0.067473,0.052527,0.085,-0.054,0.02,0.085,-1},{4,-0.067473,0.052527,0.071,-0.1,0.066,0.071,-0.1,0.066,0.085,-1},{4,-0.067473,0.052527,0.071,-0.1,0.066,0.085,-0.067473,0.052527,0.085,-1},{4,-0.1,0.066,0.071,-0.132527,0.052527,0.071,-0.132527,0.052527,0.085,-1},{4,-0.1,0.066,0.071,-0.132527,0.052527,0.085,-0.1,0.066,0.085,-1},{4,-0.132527,0.052527,0.071,-0.146,0.02,0.071,-0.146,0.02,0.085,-1},{4,-0.132527,0.052527,0.071,-0.146,0.02,0.085,-0.132527,0.052527,0.085,-1},{4,-0.146,0.02,0.071,-0.132527,-0.012527,0.071,-0.132527,-0.012527,0.085,-1},{4,-0.146,0.02,0.071,-0.132527,-0.012527,0.085,-0.146,0.02,0.085,-1},{4,-0.132527,-0.012527,0.071,-0.1,-0.026,0.071,-0.1,-0.026,0.085,-1},{4,-0.132527,-0.012527,0.071,-0.1,-0.026,0.085,-0.132527,-0.012527,0.085,-1},{4,-0.1,-0.026,0.071,-0.067473,-0.012527,0.071,-0.067473,-0.012527,0.085,-1},{4,-0.1,-0.026,0.071,-0.067473,-0.012527,0.085,-0.1,-0.026,0.085,-1},{4,-0.067473,-0.012527,0.071,-0.054,0.02,0.071,-0.054,0.02,0.085,-1},{4,-0.067473,-0.012527,0.071,-0.054,0.02,0.085,-0.067473,-0.012527,0.085,-1},{0,-0.123,0.025,0.088,-0.123,0.015,0.088,-0.077,0.015,0.088,-1},{0,-0.077,0.015,0.086,-0.123,0.015,0.086,-0.123,0.025,0.086,-1},{0,-0.077,0.015,0.088,-0.077,0.025,0.088,-0.123,0.025,0.088,-1},{0,-0.123,0.025,0.086,-0.077,0.025,0.086,-0.077,0.015,0.086,-1},{0,-0.123,0.015,0.086,-0.077,0.015,0.086,-0.077,0.015,0.088,-1},{0,-0.123,0.015,0.086,-0.077,0.015,0.088,-0.123,0.015,0.088,-1},{0,-0.077,0.015,0.086,-0.077,0.025,0.086,-0.077,0.025,0.088,-1},{0,-0.077,0.015,0.086,-0.077,0.025,0.088,-0.077,0.015,0.088,-1},{0,-0.077,0.025,0.086,-0.123,0.025,0.086,-0.123,0.025,0.088,-1},{0,-0.077,0.025,0.086,-0.123,0.025,0.088,-0.077,0.025,0.088,-1},{0,-0.123,0.025,0.086,-0.123,0.015,0.086,-0.123,0.015,0.088,-1},{0,-0.123,0.025,0.086,-0.123,0.015,0.088,-0.123,0.025,0.088,-1},{0,0.035,0.06,0.065,0.035,-0.96,0.065,0.145,-0.985,0.065,1},{0,0.145,-0.985,-0.065,0.035,-0.96,-0.065,0.035,0.06,-0.065,1},{0,0.035,0.06,0.065,0.145,-0.985,0.065,0.175,-0.94,0.065,1},{0,0.175,-0.94,-0.065,0.145,-0.985,-0.065,0.035,0.06,-0.065,1},{0,0.035,0.06,0.065,0.175,-0.94,0.065,0.165,0.065,0.065,1},{0,0.165,0.065,-0.065,0.175,-0.94,-0.065,0.035,0.06,-0.065,1},{0,0.035,0.06,0.065,0.165,0.065,0.065,0.135,0.09,0.065,1},{0,0.135,0.09,-0.065,0.165,0.065,-0.065,0.035,0.06,-0.065,1},{0,0.135,0.09,0.065,0.055,0.09,0.065,0.035,0.06,0.065,1},{0,0.035,0.06,-0.065,0.055,0.09,-0.065,0.135,0.09,-0.065,1},{0,0.035,-0.96,-0.065,0.145,-0.985,-0.065,0.145,-0.985,0.065,1},{0,0.035,-0.96,-0.065,0.145,-0.985,0.065,0.035,-0.96,0.065,1},{0,0.145,-0.985,-0.065,0.175,-0.94,-0.065,0.175,-0.94,0.065,1},{0,0.145,-0.985,-0.065,0.175,-0.94,0.065,0.145,-0.985,0.065,1},{0,0.175,-0.94,-0.065,0.165,0.065,-0.065,0.165,0.065,0.065,1},{0,0.175,-0.94,-0.065,0.165,0.065,0.065,0.175,-0.94,0.065,1},{0,0.165,0.065,-0.065,0.135,0.09,-0.065,0.135,0.09,0.065,1},{0,0.165,0.065,-0.065,0.135,0.09,0.065,0.165,0.065,0.065,1},{0,0.135,0.09,-0.065,0.055,0.09,-0.065,0.055,0.09,0.065,1},{0,0.135,0.09,-0.065,0.055,0.09,0.065,0.135,0.09,0.065,1},{0,0.055,0.09,-0.065,0.035,0.06,-0.065,0.035,0.06,0.065,1},{0,0.055,0.09,-0.065,0.035,0.06,0.065,0.055,0.09,0.065,1},{0,0.035,0.06,-0.065,0.035,-0.96,-0.065,0.035,-0.96,0.065,1},{0,0.035,0.06,-0.065,0.035,-0.96,0.065,0.035,0.06,0.065,1},{1,0.045,0.05,0.07,0.04,-0.92,0.07,0.061,-0.93,0.07,1},{1,0.061,-0.93,0.066,0.04,-0.92,0.066,0.045,0.05,0.066,1},{1,0.061,-0.93,0.07,0.065,0.045,0.07,0.045,0.05,0.07,1},{1,0.045,0.05,0.066,0.065,0.045,0.066,0.061,-0.93,0.066,1},{1,0.04,-0.92,0.066,0.061,-0.93,0.066,0.061,-0.93,0.07,1},{1,0.04,-0.92,0.066,0.061,-0.93,0.07,0.04,-0.92,0.07,1},{1,0.061,-0.93,0.066,0.065,0.045,0.066,0.065,0.045,0.07,1},{1,0.061,-0.93,0.066,0.065,0.045,0.07,0.061,-0.93,0.07,1},{1,0.065,0.045,0.066,0.045,0.05,0.066,0.045,0.05,0.07,1},{1,0.065,0.045,0.066,0.045,0.05,0.07,0.065,0.045,0.07,1},{1,0.045,0.05,0.066,0.04,-0.92,0.066,0.04,-0.92,0.07,1},{1,0.045,0.05,0.066,0.04,-0.92,0.07,0.045,0.05,0.07,1},{3,0.077,-0.12,0.072,0.075,-0.84,0.072,0.143,-0.84,0.072,1},{3,0.143,-0.84,0.066,0.075,-0.84,0.066,0.077,-0.12,0.066,1},{3,0.143,-0.84,0.072,0.134,-0.12,0.072,0.077,-0.12,0.072,1},{3,0.077,-0.12,0.066,0.134,-0.12,0.066,0.143,-0.84,0.066,1},{3,0.075,-0.84,0.066,0.143,-0.84,0.066,0.143,-0.84,0.072,1},{3,0.075,-0.84,0.066,0.143,-0.84,0.072,0.075,-0.84,0.072,1},{3,0.143,-0.84,0.066,0.134,-0.12,0.066,0.134,-0.12,0.072,1},{3,0.143,-0.84,0.066,0.134,-0.12,0.072,0.143,-0.84,0.072,1},{3,0.134,-0.12,0.066,0.077,-0.12,0.066,0.077,-0.12,0.072,1},{3,0.134,-0.12,0.066,0.077,-0.12,0.072,0.134,-0.12,0.072,1},{3,0.077,-0.12,0.066,0.075,-0.84,0.066,0.075,-0.84,0.072,1},{3,0.077,-0.12,0.066,0.075,-0.84,0.072,0.077,-0.12,0.072,1},{0,0.085,-0.702,0.075,0.085,-0.74,0.075,0.133,-0.72,0.075,1},{0,0.133,-0.72,0.073,0.085,-0.74,0.073,0.085,-0.702,0.073,1},{0,0.133,-0.72,0.075,0.133,-0.682,0.075,0.085,-0.702,0.075,1},{0,0.085,-0.702,0.073,0.133,-0.682,0.073,0.133,-0.72,0.073,1},{0,0.085,-0.74,0.073,0.133,-0.72,0.073,0.133,-0.72,0.075,1},{0,0.085,-0.74,0.073,0.133,-0.72,0.075,0.085,-0.74,0.075,1},{0,0.133,-0.72,0.073,0.133,-0.682,0.073,0.133,-0.682,0.075,1},{0,0.133,-0.72,0.073,0.133,-0.682,0.075,0.133,-0.72,0.075,1},{0,0.133,-0.682,0.073,0.085,-0.702,0.073,0.085,-0.702,0.075,1},{0,0.133,-0.682,0.073,0.085,-0.702,0.075,0.133,-0.682,0.075,1},{0,0.085,-0.702,0.073,0.085,-0.74,0.073,0.085,-0.74,0.075,1},{0,0.085,-0.702,0.073,0.085,-0.74,0.075,0.085,-0.702,0.075,1},{0,0.085,-0.502,0.075,0.085,-0.54,0.075,0.133,-0.52,0.075,1},{0,0.133,-0.52,0.073,0.085,-0.54,0.073,0.085,-0.502,0.073,1},{0,0.133,-0.52,0.075,0.133,-0.482,0.075,0.085,-0.502,0.075,1},{0,0.085,-0.502,0.073,0.133,-0.482,0.073,0.133,-0.52,0.073,1},{0,0.085,-0.54,0.073,0.133,-0.52,0.073,0.133,-0.52,0.075,1},{0,0.085,-0.54,0.073,0.133,-0.52,0.075,0.085,-0.54,0.075,1},{0,0.133,-0.52,0.073,0.133,-0.482,0.073,0.133,-0.482,0.075,1},{0,0.133,-0.52,0.073,0.133,-0.482,0.075,0.133,-0.52,0.075,1},{0,0.133,-0.482,0.073,0.085,-0.502,0.073,0.085,-0.502,0.075,1},{0,0.133,-0.482,0.073,0.085,-0.502,0.075,0.133,-0.482,0.075,1},{0,0.085,-0.502,0.073,0.085,-0.54,0.073,0.085,-0.54,0.075,1},{0,0.085,-0.502,0.073,0.085,-0.54,0.075,0.085,-0.502,0.075,1},{0,0.085,-0.302,0.075,0.085,-0.34,0.075,0.133,-0.32,0.075,1},{0,0.133,-0.32,0.073,0.085,-0.34,0.073,0.085,-0.302,0.073,1},{0,0.133,-0.32,0.075,0.133,-0.282,0.075,0.085,-0.302,0.075,1},{0,0.085,-0.302,0.073,0.133,-0.282,0.073,0.133,-0.32,0.073,1},{0,0.085,-0.34,0.073,0.133,-0.32,0.073,0.133,-0.32,0.075,1},{0,0.085,-0.34,0.073,0.133,-0.32,0.075,0.085,-0.34,0.075,1},{0,0.133,-0.32,0.073,0.133,-0.282,0.073,0.133,-0.282,0.075,1},{0,0.133,-0.32,0.073,0.133,-0.282,0.075,0.133,-0.32,0.075,1},{0,0.133,-0.282,0.073,0.085,-0.302,0.073,0.085,-0.302,0.075,1},{0,0.133,-0.282,0.073,0.085,-0.302,0.075,0.133,-0.282,0.075,1},{0,0.085,-0.302,0.073,0.085,-0.34,0.073,0.085,-0.34,0.075,1},{0,0.085,-0.302,0.073,0.085,-0.34,0.075,0.085,-0.302,0.075,1},{4,0.132527,-0.012527,0.085,0.146,0.02,0.085,0.132527,0.052527,0.085,1},{4,0.132527,0.052527,0.071,0.146,0.02,0.071,0.132527,-0.012527,0.071,1},{4,0.132527,-0.012527,0.085,0.132527,0.052527,0.085,0.1,0.066,0.085,1},{4,0.1,0.066,0.071,0.132527,0.052527,0.071,0.132527,-0.012527,0.071,1},{4,0.132527,-0.012527,0.085,0.1,0.066,0.085,0.067473,0.052527,0.085,1},{4,0.067473,0.052527,0.071,0.1,0.066,0.071,0.132527,-0.012527,0.071,1},{4,0.132527,-0.012527,0.085,0.067473,0.052527,0.085,0.054,0.02,0.085,1},{4,0.054,0.02,0.071,0.067473,0.052527,0.071,0.132527,-0.012527,0.071,1},{4,0.132527,-0.012527,0.085,0.054,0.02,0.085,0.067473,-0.012527,0.085,1},{4,0.067473,-0.012527,0.071,0.054,0.02,0.071,0.132527,-0.012527,0.071,1},{4,0.067473,-0.012527,0.085,0.1,-0.026,0.085,0.132527,-0.012527,0.085,1},{4,0.132527,-0.012527,0.071,0.1,-0.026,0.071,0.067473,-0.012527,0.071,1},{4,0.146,0.02,0.071,0.132527,0.052527,0.071,0.132527,0.052527,0.085,1},{4,0.146,0.02,0.071,0.132527,0.052527,0.085,0.146,0.02,0.085,1},{4,0.132527,0.052527,0.071,0.1,0.066,0.071,0.1,0.066,0.085,1},{4,0.132527,0.052527,0.071,0.1,0.066,0.085,0.132527,0.052527,0.085,1},{4,0.1,0.066,0.071,0.067473,0.052527,0.071,0.067473,0.052527,0.085,1},{4,0.1,0.066,0.071,0.067473,0.052527,0.085,0.1,0.066,0.085,1},{4,0.067473,0.052527,0.071,0.054,0.02,0.071,0.054,0.02,0.085,1},{4,0.067473,0.052527,0.071,0.054,0.02,0.085,0.067473,0.052527,0.085,1},{4,0.054,0.02,0.071,0.067473,-0.012527,0.071,0.067473,-0.012527,0.085,1},{4,0.054,0.02,0.071,0.067473,-0.012527,0.085,0.054,0.02,0.085,1},{4,0.067473,-0.012527,0.071,0.1,-0.026,0.071,0.1,-0.026,0.085,1},{4,0.067473,-0.012527,0.071,0.1,-0.026,0.085,0.067473,-0.012527,0.085,1},{4,0.1,-0.026,0.071,0.132527,-0.012527,0.071,0.132527,-0.012527,0.085,1},{4,0.1,-0.026,0.071,0.132527,-0.012527,0.085,0.1,-0.026,0.085,1},{4,0.132527,-0.012527,0.071,0.146,0.02,0.071,0.146,0.02,0.085,1},{4,0.132527,-0.012527,0.071,0.146,0.02,0.085,0.132527,-0.012527,0.085,1},{0,0.077,0.025,0.088,0.077,0.015,0.088,0.123,0.015,0.088,1},{0,0.123,0.015,0.086,0.077,0.015,0.086,0.077,0.025,0.086,1},{0,0.123,0.015,0.088,0.123,0.025,0.088,0.077,0.025,0.088,1},{0,0.077,0.025,0.086,0.123,0.025,0.086,0.123,0.015,0.086,1},{0,0.077,0.015,0.086,0.123,0.015,0.086,0.123,0.015,0.088,1},{0,0.077,0.015,0.086,0.123,0.015,0.088,0.077,0.015,0.088,1},{0,0.123,0.015,0.086,0.123,0.025,0.086,0.123,0.025,0.088,1},{0,0.123,0.015,0.086,0.123,0.025,0.088,0.123,0.015,0.088,1},{0,0.123,0.025,0.086,0.077,0.025,0.086,0.077,0.025,0.088,1},{0,0.123,0.025,0.086,0.077,0.025,0.088,0.123,0.025,0.088,1},{0,0.077,0.025,0.086,0.077,0.015,0.086,0.077,0.015,0.088,1},{0,0.077,0.025,0.086,0.077,0.015,0.088,0.077,0.025,0.088,1}},colors={Color3.fromRGB(25,31,42),Color3.fromRGB(182,197,212),Color3.fromRGB(0,0,0),Color3.fromRGB(61,11,17),Color3.fromRGB(205,172,100)}},
        {name="BUTTERFLY TALON",triangles={{1,-0.15,0.03,0.035,-0.08,0.02,0.035,-0.23,0.35,0.035,0},{1,-0.23,0.35,-0.035,-0.08,0.02,-0.035,-0.15,0.03,-0.035,0},{1,0.02,1.05,0.035,0.29,1.44,0.035,0.3,1.5,0.035,0},{1,0.3,1.5,-0.035,0.29,1.44,-0.035,0.02,1.05,-0.035,0},{1,0.02,1.05,0.035,0.3,1.5,0.035,0.09,1.48,0.035,0},{1,0.09,1.48,-0.035,0.3,1.5,-0.035,0.02,1.05,-0.035,0},{1,-0.17,0.67,0.035,0.02,1.05,0.035,0.09,1.48,0.035,0},{1,0.09,1.48,-0.035,0.02,1.05,-0.035,-0.17,0.67,-0.035,0},{1,-0.17,0.67,0.035,0.09,1.48,0.035,-0.15,1.35,0.035,0},{1,-0.15,1.35,-0.035,0.09,1.48,-0.035,-0.17,0.67,-0.035,0},{1,-0.23,0.35,0.035,-0.17,0.67,0.035,-0.15,1.35,0.035,0},{1,-0.15,1.35,-0.035,-0.17,0.67,-0.035,-0.23,0.35,-0.035,0},{1,-0.23,0.35,0.035,-0.15,1.35,0.035,-0.31,1.12,0.035,0},{1,-0.31,1.12,-0.035,-0.15,1.35,-0.035,-0.23,0.35,-0.035,0},{1,-0.23,0.35,0.035,-0.31,1.12,0.035,-0.34,0.83,0.035,0},{1,-0.34,0.83,-0.035,-0.31,1.12,-0.035,-0.23,0.35,-0.035,0},{1,-0.23,0.35,0.035,-0.34,0.83,0.035,-0.29,0.48,0.035,0},{1,-0.29,0.48,-0.035,-0.34,0.83,-0.035,-0.23,0.35,-0.035,0},{1,-0.23,0.35,0.035,-0.29,0.48,0.035,-0.15,0.03,0.035,0},{1,-0.15,0.03,-0.035,-0.29,0.48,-0.035,-0.23,0.35,-0.035,0},{1,-0.08,0.02,-0.035,-0.23,0.35,-0.035,-0.23,0.35,0.035,0},{1,-0.08,0.02,-0.035,-0.23,0.35,0.035,-0.08,0.02,0.035,0},{1,-0.23,0.35,-0.035,-0.17,0.67,-0.035,-0.17,0.67,0.035,0},{1,-0.23,0.35,-0.035,-0.17,0.67,0.035,-0.23,0.35,0.035,0},{1,-0.17,0.67,-0.035,0.02,1.05,-0.035,0.02,1.05,0.035,0},{1,-0.17,0.67,-0.035,0.02,1.05,0.035,-0.17,0.67,0.035,0},{1,0.02,1.05,-0.035,0.29,1.44,-0.035,0.29,1.44,0.035,0},{1,0.02,1.05,-0.035,0.29,1.44,0.035,0.02,1.05,0.035,0},{1,0.29,1.44,-0.035,0.3,1.5,-0.035,0.3,1.5,0.035,0},{1,0.29,1.44,-0.035,0.3,1.5,0.035,0.29,1.44,0.035,0},{1,0.3,1.5,-0.035,0.09,1.48,-0.035,0.09,1.48,0.035,0},{1,0.3,1.5,-0.035,0.09,1.48,0.035,0.3,1.5,0.035,0},{1,0.09,1.48,-0.035,-0.15,1.35,-0.035,-0.15,1.35,0.035,0},{1,0.09,1.48,-0.035,-0.15,1.35,0.035,0.09,1.48,0.035,0},{1,-0.15,1.35,-0.035,-0.31,1.12,-0.035,-0.31,1.12,0.035,0},{1,-0.15,1.35,-0.035,-0.31,1.12,0.035,-0.15,1.35,0.035,0},{1,-0.31,1.12,-0.035,-0.34,0.83,-0.035,-0.34,0.83,0.035,0},{1,-0.31,1.12,-0.035,-0.34,0.83,0.035,-0.31,1.12,0.035,0},{1,-0.34,0.83,-0.035,-0.29,0.48,-0.035,-0.29,0.48,0.035,0},{1,-0.34,0.83,-0.035,-0.29,0.48,0.035,-0.34,0.83,0.035,0},{1,-0.29,0.48,-0.035,-0.15,0.03,-0.035,-0.15,0.03,0.035,0},{1,-0.29,0.48,-0.035,-0.15,0.03,0.035,-0.29,0.48,0.035,0},{1,-0.15,0.03,-0.035,-0.08,0.02,-0.035,-0.08,0.02,0.035,0},{1,-0.15,0.03,-0.035,-0.08,0.02,0.035,-0.15,0.03,0.035,0},{0,-0.16,0.075,0.06,-0.18,-1.0,0.06,-0.033,-0.98,0.06,-1},{0,-0.033,-0.98,-0.06,-0.18,-1.0,-0.06,-0.16,0.075,-0.06,-1},{0,-0.033,-0.98,0.06,-0.045,0.06,0.06,-0.16,0.075,0.06,-1},{0,-0.16,0.075,-0.06,-0.045,0.06,-0.06,-0.033,-0.98,-0.06,-1},{0,-0.18,-1.0,-0.06,-0.033,-0.98,-0.06,-0.033,-0.98,0.06,-1},{0,-0.18,-1.0,-0.06,-0.033,-0.98,0.06,-0.18,-1.0,0.06,-1},{0,-0.033,-0.98,-0.06,-0.045,0.06,-0.06,-0.045,0.06,0.06,-1},{0,-0.033,-0.98,-0.06,-0.045,0.06,0.06,-0.033,-0.98,0.06,-1},{0,-0.045,0.06,-0.06,-0.16,0.075,-0.06,-0.16,0.075,0.06,-1},{0,-0.045,0.06,-0.06,-0.16,0.075,0.06,-0.045,0.06,0.06,-1},{0,-0.16,0.075,-0.06,-0.18,-1.0,-0.06,-0.18,-1.0,0.06,-1},{0,-0.16,0.075,-0.06,-0.18,-1.0,0.06,-0.16,0.075,0.06,-1},{3,-0.131,-0.12,0.065,-0.143,-0.89,0.065,-0.07,-0.88,0.065,-1},{3,-0.07,-0.88,0.061,-0.143,-0.89,0.061,-0.131,-0.12,0.061,-1},{3,-0.07,-0.88,0.065,-0.078,-0.12,0.065,-0.131,-0.12,0.065,-1},{3,-0.131,-0.12,0.061,-0.078,-0.12,0.061,-0.07,-0.88,0.061,-1},{3,-0.143,-0.89,0.061,-0.07,-0.88,0.061,-0.07,-0.88,0.065,-1},{3,-0.143,-0.89,0.061,-0.07,-0.88,0.065,-0.143,-0.89,0.065,-1},{3,-0.07,-0.88,0.061,-0.078,-0.12,0.061,-0.078,-0.12,0.065,-1},{3,-0.07,-0.88,0.061,-0.078,-0.12,0.065,-0.07,-0.88,0.065,-1},{3,-0.078,-0.12,0.061,-0.131,-0.12,0.061,-0.131,-0.12,0.065,-1},{3,-0.078,-0.12,0.061,-0.131,-0.12,0.065,-0.078,-0.12,0.065,-1},{3,-0.131,-0.12,0.061,-0.143,-0.89,0.061,-0.143,-0.89,0.065,-1},{3,-0.131,-0.12,0.061,-0.143,-0.89,0.065,-0.131,-0.12,0.065,-1},{3,-0.086615,-0.778385,0.068,-0.079,-0.76,0.068,-0.086615,-0.741615,0.068,-1},{3,-0.086615,-0.741615,0.066,-0.079,-0.76,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.086615,-0.741615,0.068,-0.105,-0.734,0.068,-1},{3,-0.105,-0.734,0.066,-0.086615,-0.741615,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.105,-0.734,0.068,-0.123385,-0.741615,0.068,-1},{3,-0.123385,-0.741615,0.066,-0.105,-0.734,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.123385,-0.741615,0.068,-0.131,-0.76,0.068,-1},{3,-0.131,-0.76,0.066,-0.123385,-0.741615,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.131,-0.76,0.068,-0.123385,-0.778385,0.068,-1},{3,-0.123385,-0.778385,0.066,-0.131,-0.76,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.123385,-0.778385,0.068,-0.105,-0.786,0.068,-0.086615,-0.778385,0.068,-1},{3,-0.086615,-0.778385,0.066,-0.105,-0.786,0.066,-0.123385,-0.778385,0.066,-1},{3,-0.079,-0.76,0.066,-0.086615,-0.741615,0.066,-0.086615,-0.741615,0.068,-1},{3,-0.079,-0.76,0.066,-0.086615,-0.741615,0.068,-0.079,-0.76,0.068,-1},{3,-0.086615,-0.741615,0.066,-0.105,-0.734,0.066,-0.105,-0.734,0.068,-1},{3,-0.086615,-0.741615,0.066,-0.105,-0.734,0.068,-0.086615,-0.741615,0.068,-1},{3,-0.105,-0.734,0.066,-0.123385,-0.741615,0.066,-0.123385,-0.741615,0.068,-1},{3,-0.105,-0.734,0.066,-0.123385,-0.741615,0.068,-0.105,-0.734,0.068,-1},{3,-0.123385,-0.741615,0.066,-0.131,-0.76,0.066,-0.131,-0.76,0.068,-1},{3,-0.123385,-0.741615,0.066,-0.131,-0.76,0.068,-0.123385,-0.741615,0.068,-1},{3,-0.131,-0.76,0.066,-0.123385,-0.778385,0.066,-0.123385,-0.778385,0.068,-1},{3,-0.131,-0.76,0.066,-0.123385,-0.778385,0.068,-0.131,-0.76,0.068,-1},{3,-0.123385,-0.778385,0.066,-0.105,-0.786,0.066,-0.105,-0.786,0.068,-1},{3,-0.123385,-0.778385,0.066,-0.105,-0.786,0.068,-0.123385,-0.778385,0.068,-1},{3,-0.105,-0.786,0.066,-0.086615,-0.778385,0.066,-0.086615,-0.778385,0.068,-1},{3,-0.105,-0.786,0.066,-0.086615,-0.778385,0.068,-0.105,-0.786,0.068,-1},{3,-0.086615,-0.778385,0.066,-0.079,-0.76,0.066,-0.079,-0.76,0.068,-1},{3,-0.086615,-0.778385,0.066,-0.079,-0.76,0.068,-0.086615,-0.778385,0.068,-1},{3,-0.086615,-0.548385,0.068,-0.079,-0.53,0.068,-0.086615,-0.511615,0.068,-1},{3,-0.086615,-0.511615,0.066,-0.079,-0.53,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.086615,-0.511615,0.068,-0.105,-0.504,0.068,-1},{3,-0.105,-0.504,0.066,-0.086615,-0.511615,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.105,-0.504,0.068,-0.123385,-0.511615,0.068,-1},{3,-0.123385,-0.511615,0.066,-0.105,-0.504,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.123385,-0.511615,0.068,-0.131,-0.53,0.068,-1},{3,-0.131,-0.53,0.066,-0.123385,-0.511615,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.131,-0.53,0.068,-0.123385,-0.548385,0.068,-1},{3,-0.123385,-0.548385,0.066,-0.131,-0.53,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.123385,-0.548385,0.068,-0.105,-0.556,0.068,-0.086615,-0.548385,0.068,-1},{3,-0.086615,-0.548385,0.066,-0.105,-0.556,0.066,-0.123385,-0.548385,0.066,-1},{3,-0.079,-0.53,0.066,-0.086615,-0.511615,0.066,-0.086615,-0.511615,0.068,-1},{3,-0.079,-0.53,0.066,-0.086615,-0.511615,0.068,-0.079,-0.53,0.068,-1},{3,-0.086615,-0.511615,0.066,-0.105,-0.504,0.066,-0.105,-0.504,0.068,-1},{3,-0.086615,-0.511615,0.066,-0.105,-0.504,0.068,-0.086615,-0.511615,0.068,-1},{3,-0.105,-0.504,0.066,-0.123385,-0.511615,0.066,-0.123385,-0.511615,0.068,-1},{3,-0.105,-0.504,0.066,-0.123385,-0.511615,0.068,-0.105,-0.504,0.068,-1},{3,-0.123385,-0.511615,0.066,-0.131,-0.53,0.066,-0.131,-0.53,0.068,-1},{3,-0.123385,-0.511615,0.066,-0.131,-0.53,0.068,-0.123385,-0.511615,0.068,-1},{3,-0.131,-0.53,0.066,-0.123385,-0.548385,0.066,-0.123385,-0.548385,0.068,-1},{3,-0.131,-0.53,0.066,-0.123385,-0.548385,0.068,-0.131,-0.53,0.068,-1},{3,-0.123385,-0.548385,0.066,-0.105,-0.556,0.066,-0.105,-0.556,0.068,-1},{3,-0.123385,-0.548385,0.066,-0.105,-0.556,0.068,-0.123385,-0.548385,0.068,-1},{3,-0.105,-0.556,0.066,-0.086615,-0.548385,0.066,-0.086615,-0.548385,0.068,-1},{3,-0.105,-0.556,0.066,-0.086615,-0.548385,0.068,-0.105,-0.556,0.068,-1},{3,-0.086615,-0.548385,0.066,-0.079,-0.53,0.066,-0.079,-0.53,0.068,-1},{3,-0.086615,-0.548385,0.066,-0.079,-0.53,0.068,-0.086615,-0.548385,0.068,-1},{3,-0.086615,-0.318385,0.068,-0.079,-0.3,0.068,-0.086615,-0.281615,0.068,-1},{3,-0.086615,-0.281615,0.066,-0.079,-0.3,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.086615,-0.281615,0.068,-0.105,-0.274,0.068,-1},{3,-0.105,-0.274,0.066,-0.086615,-0.281615,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.105,-0.274,0.068,-0.123385,-0.281615,0.068,-1},{3,-0.123385,-0.281615,0.066,-0.105,-0.274,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.123385,-0.281615,0.068,-0.131,-0.3,0.068,-1},{3,-0.131,-0.3,0.066,-0.123385,-0.281615,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.131,-0.3,0.068,-0.123385,-0.318385,0.068,-1},{3,-0.123385,-0.318385,0.066,-0.131,-0.3,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.123385,-0.318385,0.068,-0.105,-0.326,0.068,-0.086615,-0.318385,0.068,-1},{3,-0.086615,-0.318385,0.066,-0.105,-0.326,0.066,-0.123385,-0.318385,0.066,-1},{3,-0.079,-0.3,0.066,-0.086615,-0.281615,0.066,-0.086615,-0.281615,0.068,-1},{3,-0.079,-0.3,0.066,-0.086615,-0.281615,0.068,-0.079,-0.3,0.068,-1},{3,-0.086615,-0.281615,0.066,-0.105,-0.274,0.066,-0.105,-0.274,0.068,-1},{3,-0.086615,-0.281615,0.066,-0.105,-0.274,0.068,-0.086615,-0.281615,0.068,-1},{3,-0.105,-0.274,0.066,-0.123385,-0.281615,0.066,-0.123385,-0.281615,0.068,-1},{3,-0.105,-0.274,0.066,-0.123385,-0.281615,0.068,-0.105,-0.274,0.068,-1},{3,-0.123385,-0.281615,0.066,-0.131,-0.3,0.066,-0.131,-0.3,0.068,-1},{3,-0.123385,-0.281615,0.066,-0.131,-0.3,0.068,-0.123385,-0.281615,0.068,-1},{3,-0.131,-0.3,0.066,-0.123385,-0.318385,0.066,-0.123385,-0.318385,0.068,-1},{3,-0.131,-0.3,0.066,-0.123385,-0.318385,0.068,-0.131,-0.3,0.068,-1},{3,-0.123385,-0.318385,0.066,-0.105,-0.326,0.066,-0.105,-0.326,0.068,-1},{3,-0.123385,-0.318385,0.066,-0.105,-0.326,0.068,-0.123385,-0.318385,0.068,-1},{3,-0.105,-0.326,0.066,-0.086615,-0.318385,0.066,-0.086615,-0.318385,0.068,-1},{3,-0.105,-0.326,0.066,-0.086615,-0.318385,0.068,-0.105,-0.326,0.068,-1},{3,-0.086615,-0.318385,0.066,-0.079,-0.3,0.066,-0.079,-0.3,0.068,-1},{3,-0.086615,-0.318385,0.066,-0.079,-0.3,0.068,-0.086615,-0.318385,0.068,-1},{1,-0.07318,-0.01182,0.078,-0.06,0.02,0.078,-0.07318,0.05182,0.078,-1},{1,-0.07318,0.05182,0.066,-0.06,0.02,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.07318,0.05182,0.078,-0.105,0.065,0.078,-1},{1,-0.105,0.065,0.066,-0.07318,0.05182,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.105,0.065,0.078,-0.13682,0.05182,0.078,-1},{1,-0.13682,0.05182,0.066,-0.105,0.065,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.13682,0.05182,0.078,-0.15,0.02,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,0.05182,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.15,0.02,0.078,-0.13682,-0.01182,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.15,0.02,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.13682,-0.01182,0.078,-0.105,-0.025,0.078,-0.07318,-0.01182,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.105,-0.025,0.066,-0.13682,-0.01182,0.066,-1},{1,-0.06,0.02,0.066,-0.07318,0.05182,0.066,-0.07318,0.05182,0.078,-1},{1,-0.06,0.02,0.066,-0.07318,0.05182,0.078,-0.06,0.02,0.078,-1},{1,-0.07318,0.05182,0.066,-0.105,0.065,0.066,-0.105,0.065,0.078,-1},{1,-0.07318,0.05182,0.066,-0.105,0.065,0.078,-0.07318,0.05182,0.078,-1},{1,-0.105,0.065,0.066,-0.13682,0.05182,0.066,-0.13682,0.05182,0.078,-1},{1,-0.105,0.065,0.066,-0.13682,0.05182,0.078,-0.105,0.065,0.078,-1},{1,-0.13682,0.05182,0.066,-0.15,0.02,0.066,-0.15,0.02,0.078,-1},{1,-0.13682,0.05182,0.066,-0.15,0.02,0.078,-0.13682,0.05182,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,-0.01182,0.066,-0.13682,-0.01182,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,-0.01182,0.078,-0.15,0.02,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.105,-0.025,0.066,-0.105,-0.025,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.105,-0.025,0.078,-0.13682,-0.01182,0.078,-1},{1,-0.105,-0.025,0.066,-0.07318,-0.01182,0.066,-0.07318,-0.01182,0.078,-1},{1,-0.105,-0.025,0.066,-0.07318,-0.01182,0.078,-0.105,-0.025,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.06,0.02,0.066,-0.06,0.02,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.06,0.02,0.078,-0.07318,-0.01182,0.078,-1},{0,0.05,0.075,0.06,0.03,-1.0,0.06,0.177,-0.98,0.06,1},{0,0.177,-0.98,-0.06,0.03,-1.0,-0.06,0.05,0.075,-0.06,1},{0,0.177,-0.98,0.06,0.165,0.06,0.06,0.05,0.075,0.06,1},{0,0.05,0.075,-0.06,0.165,0.06,-0.06,0.177,-0.98,-0.06,1},{0,0.03,-1.0,-0.06,0.177,-0.98,-0.06,0.177,-0.98,0.06,1},{0,0.03,-1.0,-0.06,0.177,-0.98,0.06,0.03,-1.0,0.06,1},{0,0.177,-0.98,-0.06,0.165,0.06,-0.06,0.165,0.06,0.06,1},{0,0.177,-0.98,-0.06,0.165,0.06,0.06,0.177,-0.98,0.06,1},{0,0.165,0.06,-0.06,0.05,0.075,-0.06,0.05,0.075,0.06,1},{0,0.165,0.06,-0.06,0.05,0.075,0.06,0.165,0.06,0.06,1},{0,0.05,0.075,-0.06,0.03,-1.0,-0.06,0.03,-1.0,0.06,1},{0,0.05,0.075,-0.06,0.03,-1.0,0.06,0.05,0.075,0.06,1},{3,0.079,-0.12,0.065,0.067,-0.89,0.065,0.14,-0.88,0.065,1},{3,0.14,-0.88,0.061,0.067,-0.89,0.061,0.079,-0.12,0.061,1},{3,0.14,-0.88,0.065,0.132,-0.12,0.065,0.079,-0.12,0.065,1},{3,0.079,-0.12,0.061,0.132,-0.12,0.061,0.14,-0.88,0.061,1},{3,0.067,-0.89,0.061,0.14,-0.88,0.061,0.14,-0.88,0.065,1},{3,0.067,-0.89,0.061,0.14,-0.88,0.065,0.067,-0.89,0.065,1},{3,0.14,-0.88,0.061,0.132,-0.12,0.061,0.132,-0.12,0.065,1},{3,0.14,-0.88,0.061,0.132,-0.12,0.065,0.14,-0.88,0.065,1},{3,0.132,-0.12,0.061,0.079,-0.12,0.061,0.079,-0.12,0.065,1},{3,0.132,-0.12,0.061,0.079,-0.12,0.065,0.132,-0.12,0.065,1},{3,0.079,-0.12,0.061,0.067,-0.89,0.061,0.067,-0.89,0.065,1},{3,0.079,-0.12,0.061,0.067,-0.89,0.065,0.079,-0.12,0.065,1},{3,0.123385,-0.778385,0.068,0.131,-0.76,0.068,0.123385,-0.741615,0.068,1},{3,0.123385,-0.741615,0.066,0.131,-0.76,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.123385,-0.741615,0.068,0.105,-0.734,0.068,1},{3,0.105,-0.734,0.066,0.123385,-0.741615,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.105,-0.734,0.068,0.086615,-0.741615,0.068,1},{3,0.086615,-0.741615,0.066,0.105,-0.734,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.086615,-0.741615,0.068,0.079,-0.76,0.068,1},{3,0.079,-0.76,0.066,0.086615,-0.741615,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.079,-0.76,0.068,0.086615,-0.778385,0.068,1},{3,0.086615,-0.778385,0.066,0.079,-0.76,0.066,0.123385,-0.778385,0.066,1},{3,0.086615,-0.778385,0.068,0.105,-0.786,0.068,0.123385,-0.778385,0.068,1},{3,0.123385,-0.778385,0.066,0.105,-0.786,0.066,0.086615,-0.778385,0.066,1},{3,0.131,-0.76,0.066,0.123385,-0.741615,0.066,0.123385,-0.741615,0.068,1},{3,0.131,-0.76,0.066,0.123385,-0.741615,0.068,0.131,-0.76,0.068,1},{3,0.123385,-0.741615,0.066,0.105,-0.734,0.066,0.105,-0.734,0.068,1},{3,0.123385,-0.741615,0.066,0.105,-0.734,0.068,0.123385,-0.741615,0.068,1},{3,0.105,-0.734,0.066,0.086615,-0.741615,0.066,0.086615,-0.741615,0.068,1},{3,0.105,-0.734,0.066,0.086615,-0.741615,0.068,0.105,-0.734,0.068,1},{3,0.086615,-0.741615,0.066,0.079,-0.76,0.066,0.079,-0.76,0.068,1},{3,0.086615,-0.741615,0.066,0.079,-0.76,0.068,0.086615,-0.741615,0.068,1},{3,0.079,-0.76,0.066,0.086615,-0.778385,0.066,0.086615,-0.778385,0.068,1},{3,0.079,-0.76,0.066,0.086615,-0.778385,0.068,0.079,-0.76,0.068,1},{3,0.086615,-0.778385,0.066,0.105,-0.786,0.066,0.105,-0.786,0.068,1},{3,0.086615,-0.778385,0.066,0.105,-0.786,0.068,0.086615,-0.778385,0.068,1},{3,0.105,-0.786,0.066,0.123385,-0.778385,0.066,0.123385,-0.778385,0.068,1},{3,0.105,-0.786,0.066,0.123385,-0.778385,0.068,0.105,-0.786,0.068,1},{3,0.123385,-0.778385,0.066,0.131,-0.76,0.066,0.131,-0.76,0.068,1},{3,0.123385,-0.778385,0.066,0.131,-0.76,0.068,0.123385,-0.778385,0.068,1},{3,0.123385,-0.548385,0.068,0.131,-0.53,0.068,0.123385,-0.511615,0.068,1},{3,0.123385,-0.511615,0.066,0.131,-0.53,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.123385,-0.511615,0.068,0.105,-0.504,0.068,1},{3,0.105,-0.504,0.066,0.123385,-0.511615,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.105,-0.504,0.068,0.086615,-0.511615,0.068,1},{3,0.086615,-0.511615,0.066,0.105,-0.504,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.086615,-0.511615,0.068,0.079,-0.53,0.068,1},{3,0.079,-0.53,0.066,0.086615,-0.511615,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.079,-0.53,0.068,0.086615,-0.548385,0.068,1},{3,0.086615,-0.548385,0.066,0.079,-0.53,0.066,0.123385,-0.548385,0.066,1},{3,0.086615,-0.548385,0.068,0.105,-0.556,0.068,0.123385,-0.548385,0.068,1},{3,0.123385,-0.548385,0.066,0.105,-0.556,0.066,0.086615,-0.548385,0.066,1},{3,0.131,-0.53,0.066,0.123385,-0.511615,0.066,0.123385,-0.511615,0.068,1},{3,0.131,-0.53,0.066,0.123385,-0.511615,0.068,0.131,-0.53,0.068,1},{3,0.123385,-0.511615,0.066,0.105,-0.504,0.066,0.105,-0.504,0.068,1},{3,0.123385,-0.511615,0.066,0.105,-0.504,0.068,0.123385,-0.511615,0.068,1},{3,0.105,-0.504,0.066,0.086615,-0.511615,0.066,0.086615,-0.511615,0.068,1},{3,0.105,-0.504,0.066,0.086615,-0.511615,0.068,0.105,-0.504,0.068,1},{3,0.086615,-0.511615,0.066,0.079,-0.53,0.066,0.079,-0.53,0.068,1},{3,0.086615,-0.511615,0.066,0.079,-0.53,0.068,0.086615,-0.511615,0.068,1},{3,0.079,-0.53,0.066,0.086615,-0.548385,0.066,0.086615,-0.548385,0.068,1},{3,0.079,-0.53,0.066,0.086615,-0.548385,0.068,0.079,-0.53,0.068,1},{3,0.086615,-0.548385,0.066,0.105,-0.556,0.066,0.105,-0.556,0.068,1},{3,0.086615,-0.548385,0.066,0.105,-0.556,0.068,0.086615,-0.548385,0.068,1},{3,0.105,-0.556,0.066,0.123385,-0.548385,0.066,0.123385,-0.548385,0.068,1},{3,0.105,-0.556,0.066,0.123385,-0.548385,0.068,0.105,-0.556,0.068,1},{3,0.123385,-0.548385,0.066,0.131,-0.53,0.066,0.131,-0.53,0.068,1},{3,0.123385,-0.548385,0.066,0.131,-0.53,0.068,0.123385,-0.548385,0.068,1},{3,0.123385,-0.318385,0.068,0.131,-0.3,0.068,0.123385,-0.281615,0.068,1},{3,0.123385,-0.281615,0.066,0.131,-0.3,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.123385,-0.281615,0.068,0.105,-0.274,0.068,1},{3,0.105,-0.274,0.066,0.123385,-0.281615,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.105,-0.274,0.068,0.086615,-0.281615,0.068,1},{3,0.086615,-0.281615,0.066,0.105,-0.274,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.086615,-0.281615,0.068,0.079,-0.3,0.068,1},{3,0.079,-0.3,0.066,0.086615,-0.281615,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.079,-0.3,0.068,0.086615,-0.318385,0.068,1},{3,0.086615,-0.318385,0.066,0.079,-0.3,0.066,0.123385,-0.318385,0.066,1},{3,0.086615,-0.318385,0.068,0.105,-0.326,0.068,0.123385,-0.318385,0.068,1},{3,0.123385,-0.318385,0.066,0.105,-0.326,0.066,0.086615,-0.318385,0.066,1},{3,0.131,-0.3,0.066,0.123385,-0.281615,0.066,0.123385,-0.281615,0.068,1},{3,0.131,-0.3,0.066,0.123385,-0.281615,0.068,0.131,-0.3,0.068,1},{3,0.123385,-0.281615,0.066,0.105,-0.274,0.066,0.105,-0.274,0.068,1},{3,0.123385,-0.281615,0.066,0.105,-0.274,0.068,0.123385,-0.281615,0.068,1},{3,0.105,-0.274,0.066,0.086615,-0.281615,0.066,0.086615,-0.281615,0.068,1},{3,0.105,-0.274,0.066,0.086615,-0.281615,0.068,0.105,-0.274,0.068,1},{3,0.086615,-0.281615,0.066,0.079,-0.3,0.066,0.079,-0.3,0.068,1},{3,0.086615,-0.281615,0.066,0.079,-0.3,0.068,0.086615,-0.281615,0.068,1},{3,0.079,-0.3,0.066,0.086615,-0.318385,0.066,0.086615,-0.318385,0.068,1},{3,0.079,-0.3,0.066,0.086615,-0.318385,0.068,0.079,-0.3,0.068,1},{3,0.086615,-0.318385,0.066,0.105,-0.326,0.066,0.105,-0.326,0.068,1},{3,0.086615,-0.318385,0.066,0.105,-0.326,0.068,0.086615,-0.318385,0.068,1},{3,0.105,-0.326,0.066,0.123385,-0.318385,0.066,0.123385,-0.318385,0.068,1},{3,0.105,-0.326,0.066,0.123385,-0.318385,0.068,0.105,-0.326,0.068,1},{3,0.123385,-0.318385,0.066,0.131,-0.3,0.066,0.131,-0.3,0.068,1},{3,0.123385,-0.318385,0.066,0.131,-0.3,0.068,0.123385,-0.318385,0.068,1},{1,0.13682,-0.01182,0.078,0.15,0.02,0.078,0.13682,0.05182,0.078,1},{1,0.13682,0.05182,0.066,0.15,0.02,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.13682,0.05182,0.078,0.105,0.065,0.078,1},{1,0.105,0.065,0.066,0.13682,0.05182,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.105,0.065,0.078,0.07318,0.05182,0.078,1},{1,0.07318,0.05182,0.066,0.105,0.065,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.07318,0.05182,0.078,0.06,0.02,0.078,1},{1,0.06,0.02,0.066,0.07318,0.05182,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.06,0.02,0.078,0.07318,-0.01182,0.078,1},{1,0.07318,-0.01182,0.066,0.06,0.02,0.066,0.13682,-0.01182,0.066,1},{1,0.07318,-0.01182,0.078,0.105,-0.025,0.078,0.13682,-0.01182,0.078,1},{1,0.13682,-0.01182,0.066,0.105,-0.025,0.066,0.07318,-0.01182,0.066,1},{1,0.15,0.02,0.066,0.13682,0.05182,0.066,0.13682,0.05182,0.078,1},{1,0.15,0.02,0.066,0.13682,0.05182,0.078,0.15,0.02,0.078,1},{1,0.13682,0.05182,0.066,0.105,0.065,0.066,0.105,0.065,0.078,1},{1,0.13682,0.05182,0.066,0.105,0.065,0.078,0.13682,0.05182,0.078,1},{1,0.105,0.065,0.066,0.07318,0.05182,0.066,0.07318,0.05182,0.078,1},{1,0.105,0.065,0.066,0.07318,0.05182,0.078,0.105,0.065,0.078,1},{1,0.07318,0.05182,0.066,0.06,0.02,0.066,0.06,0.02,0.078,1},{1,0.07318,0.05182,0.066,0.06,0.02,0.078,0.07318,0.05182,0.078,1},{1,0.06,0.02,0.066,0.07318,-0.01182,0.066,0.07318,-0.01182,0.078,1},{1,0.06,0.02,0.066,0.07318,-0.01182,0.078,0.06,0.02,0.078,1},{1,0.07318,-0.01182,0.066,0.105,-0.025,0.066,0.105,-0.025,0.078,1},{1,0.07318,-0.01182,0.066,0.105,-0.025,0.078,0.07318,-0.01182,0.078,1},{1,0.105,-0.025,0.066,0.13682,-0.01182,0.066,0.13682,-0.01182,0.078,1},{1,0.105,-0.025,0.066,0.13682,-0.01182,0.078,0.105,-0.025,0.078,1},{1,0.13682,-0.01182,0.066,0.15,0.02,0.066,0.15,0.02,0.078,1},{1,0.13682,-0.01182,0.066,0.15,0.02,0.078,0.13682,-0.01182,0.078,1}},colors={Color3.fromRGB(24,29,33),Color3.fromRGB(168,177,185),Color3.fromRGB(0,0,0),Color3.fromRGB(8,10,13),Color3.fromRGB(215,220,225)}},
        {name="BUTTERFLY COBALT",triangles={{1,-0.08,0.02,0.035,0.08,0.02,0.035,0.18,0.22,0.035,0},{1,0.18,0.22,-0.035,0.08,0.02,-0.035,-0.08,0.02,-0.035,0},{1,-0.08,0.02,0.035,0.18,0.22,0.035,0.18,0.74,0.035,0},{1,0.18,0.74,-0.035,0.18,0.22,-0.035,-0.08,0.02,-0.035,0},{1,-0.08,0.02,0.035,0.18,0.74,0.035,0.1,1.24,0.035,0},{1,0.1,1.24,-0.035,0.18,0.74,-0.035,-0.08,0.02,-0.035,0},{1,-0.08,0.02,0.035,0.1,1.24,0.035,-0.02,1.48,0.035,0},{1,-0.02,1.48,-0.035,0.1,1.24,-0.035,-0.08,0.02,-0.035,0},{1,-0.08,0.02,0.035,-0.02,1.48,0.035,-0.15,1.08,0.035,0},{1,-0.15,1.08,-0.035,-0.02,1.48,-0.035,-0.08,0.02,-0.035,0},{1,-0.15,1.08,0.035,-0.16,0.38,0.035,-0.08,0.02,0.035,0},{1,-0.08,0.02,-0.035,-0.16,0.38,-0.035,-0.15,1.08,-0.035,0},{1,0.08,0.02,-0.035,0.18,0.22,-0.035,0.18,0.22,0.035,0},{1,0.08,0.02,-0.035,0.18,0.22,0.035,0.08,0.02,0.035,0},{1,0.18,0.22,-0.035,0.18,0.74,-0.035,0.18,0.74,0.035,0},{1,0.18,0.22,-0.035,0.18,0.74,0.035,0.18,0.22,0.035,0},{1,0.18,0.74,-0.035,0.1,1.24,-0.035,0.1,1.24,0.035,0},{1,0.18,0.74,-0.035,0.1,1.24,0.035,0.18,0.74,0.035,0},{1,0.1,1.24,-0.035,-0.02,1.48,-0.035,-0.02,1.48,0.035,0},{1,0.1,1.24,-0.035,-0.02,1.48,0.035,0.1,1.24,0.035,0},{1,-0.02,1.48,-0.035,-0.15,1.08,-0.035,-0.15,1.08,0.035,0},{1,-0.02,1.48,-0.035,-0.15,1.08,0.035,-0.02,1.48,0.035,0},{1,-0.15,1.08,-0.035,-0.16,0.38,-0.035,-0.16,0.38,0.035,0},{1,-0.15,1.08,-0.035,-0.16,0.38,0.035,-0.15,1.08,0.035,0},{1,-0.16,0.38,-0.035,-0.08,0.02,-0.035,-0.08,0.02,0.035,0},{1,-0.16,0.38,-0.035,-0.08,0.02,0.035,-0.16,0.38,0.035,0},{1,-0.08,0.02,-0.035,0.08,0.02,-0.035,0.08,0.02,0.035,0},{1,-0.08,0.02,-0.035,0.08,0.02,0.035,-0.08,0.02,0.035,0},{0,-0.16,0.075,0.06,-0.18,-1.0,0.06,-0.033,-0.98,0.06,-1},{0,-0.033,-0.98,-0.06,-0.18,-1.0,-0.06,-0.16,0.075,-0.06,-1},{0,-0.033,-0.98,0.06,-0.045,0.06,0.06,-0.16,0.075,0.06,-1},{0,-0.16,0.075,-0.06,-0.045,0.06,-0.06,-0.033,-0.98,-0.06,-1},{0,-0.18,-1.0,-0.06,-0.033,-0.98,-0.06,-0.033,-0.98,0.06,-1},{0,-0.18,-1.0,-0.06,-0.033,-0.98,0.06,-0.18,-1.0,0.06,-1},{0,-0.033,-0.98,-0.06,-0.045,0.06,-0.06,-0.045,0.06,0.06,-1},{0,-0.033,-0.98,-0.06,-0.045,0.06,0.06,-0.033,-0.98,0.06,-1},{0,-0.045,0.06,-0.06,-0.16,0.075,-0.06,-0.16,0.075,0.06,-1},{0,-0.045,0.06,-0.06,-0.16,0.075,0.06,-0.045,0.06,0.06,-1},{0,-0.16,0.075,-0.06,-0.18,-1.0,-0.06,-0.18,-1.0,0.06,-1},{0,-0.16,0.075,-0.06,-0.18,-1.0,0.06,-0.16,0.075,0.06,-1},{3,-0.131,-0.12,0.065,-0.143,-0.89,0.065,-0.07,-0.88,0.065,-1},{3,-0.07,-0.88,0.061,-0.143,-0.89,0.061,-0.131,-0.12,0.061,-1},{3,-0.07,-0.88,0.065,-0.078,-0.12,0.065,-0.131,-0.12,0.065,-1},{3,-0.131,-0.12,0.061,-0.078,-0.12,0.061,-0.07,-0.88,0.061,-1},{3,-0.143,-0.89,0.061,-0.07,-0.88,0.061,-0.07,-0.88,0.065,-1},{3,-0.143,-0.89,0.061,-0.07,-0.88,0.065,-0.143,-0.89,0.065,-1},{3,-0.07,-0.88,0.061,-0.078,-0.12,0.061,-0.078,-0.12,0.065,-1},{3,-0.07,-0.88,0.061,-0.078,-0.12,0.065,-0.07,-0.88,0.065,-1},{3,-0.078,-0.12,0.061,-0.131,-0.12,0.061,-0.131,-0.12,0.065,-1},{3,-0.078,-0.12,0.061,-0.131,-0.12,0.065,-0.078,-0.12,0.065,-1},{3,-0.131,-0.12,0.061,-0.143,-0.89,0.061,-0.143,-0.89,0.065,-1},{3,-0.131,-0.12,0.061,-0.143,-0.89,0.065,-0.131,-0.12,0.065,-1},{3,-0.086615,-0.778385,0.068,-0.079,-0.76,0.068,-0.086615,-0.741615,0.068,-1},{3,-0.086615,-0.741615,0.066,-0.079,-0.76,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.086615,-0.741615,0.068,-0.105,-0.734,0.068,-1},{3,-0.105,-0.734,0.066,-0.086615,-0.741615,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.105,-0.734,0.068,-0.123385,-0.741615,0.068,-1},{3,-0.123385,-0.741615,0.066,-0.105,-0.734,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.123385,-0.741615,0.068,-0.131,-0.76,0.068,-1},{3,-0.131,-0.76,0.066,-0.123385,-0.741615,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.086615,-0.778385,0.068,-0.131,-0.76,0.068,-0.123385,-0.778385,0.068,-1},{3,-0.123385,-0.778385,0.066,-0.131,-0.76,0.066,-0.086615,-0.778385,0.066,-1},{3,-0.123385,-0.778385,0.068,-0.105,-0.786,0.068,-0.086615,-0.778385,0.068,-1},{3,-0.086615,-0.778385,0.066,-0.105,-0.786,0.066,-0.123385,-0.778385,0.066,-1},{3,-0.079,-0.76,0.066,-0.086615,-0.741615,0.066,-0.086615,-0.741615,0.068,-1},{3,-0.079,-0.76,0.066,-0.086615,-0.741615,0.068,-0.079,-0.76,0.068,-1},{3,-0.086615,-0.741615,0.066,-0.105,-0.734,0.066,-0.105,-0.734,0.068,-1},{3,-0.086615,-0.741615,0.066,-0.105,-0.734,0.068,-0.086615,-0.741615,0.068,-1},{3,-0.105,-0.734,0.066,-0.123385,-0.741615,0.066,-0.123385,-0.741615,0.068,-1},{3,-0.105,-0.734,0.066,-0.123385,-0.741615,0.068,-0.105,-0.734,0.068,-1},{3,-0.123385,-0.741615,0.066,-0.131,-0.76,0.066,-0.131,-0.76,0.068,-1},{3,-0.123385,-0.741615,0.066,-0.131,-0.76,0.068,-0.123385,-0.741615,0.068,-1},{3,-0.131,-0.76,0.066,-0.123385,-0.778385,0.066,-0.123385,-0.778385,0.068,-1},{3,-0.131,-0.76,0.066,-0.123385,-0.778385,0.068,-0.131,-0.76,0.068,-1},{3,-0.123385,-0.778385,0.066,-0.105,-0.786,0.066,-0.105,-0.786,0.068,-1},{3,-0.123385,-0.778385,0.066,-0.105,-0.786,0.068,-0.123385,-0.778385,0.068,-1},{3,-0.105,-0.786,0.066,-0.086615,-0.778385,0.066,-0.086615,-0.778385,0.068,-1},{3,-0.105,-0.786,0.066,-0.086615,-0.778385,0.068,-0.105,-0.786,0.068,-1},{3,-0.086615,-0.778385,0.066,-0.079,-0.76,0.066,-0.079,-0.76,0.068,-1},{3,-0.086615,-0.778385,0.066,-0.079,-0.76,0.068,-0.086615,-0.778385,0.068,-1},{3,-0.086615,-0.548385,0.068,-0.079,-0.53,0.068,-0.086615,-0.511615,0.068,-1},{3,-0.086615,-0.511615,0.066,-0.079,-0.53,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.086615,-0.511615,0.068,-0.105,-0.504,0.068,-1},{3,-0.105,-0.504,0.066,-0.086615,-0.511615,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.105,-0.504,0.068,-0.123385,-0.511615,0.068,-1},{3,-0.123385,-0.511615,0.066,-0.105,-0.504,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.123385,-0.511615,0.068,-0.131,-0.53,0.068,-1},{3,-0.131,-0.53,0.066,-0.123385,-0.511615,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.086615,-0.548385,0.068,-0.131,-0.53,0.068,-0.123385,-0.548385,0.068,-1},{3,-0.123385,-0.548385,0.066,-0.131,-0.53,0.066,-0.086615,-0.548385,0.066,-1},{3,-0.123385,-0.548385,0.068,-0.105,-0.556,0.068,-0.086615,-0.548385,0.068,-1},{3,-0.086615,-0.548385,0.066,-0.105,-0.556,0.066,-0.123385,-0.548385,0.066,-1},{3,-0.079,-0.53,0.066,-0.086615,-0.511615,0.066,-0.086615,-0.511615,0.068,-1},{3,-0.079,-0.53,0.066,-0.086615,-0.511615,0.068,-0.079,-0.53,0.068,-1},{3,-0.086615,-0.511615,0.066,-0.105,-0.504,0.066,-0.105,-0.504,0.068,-1},{3,-0.086615,-0.511615,0.066,-0.105,-0.504,0.068,-0.086615,-0.511615,0.068,-1},{3,-0.105,-0.504,0.066,-0.123385,-0.511615,0.066,-0.123385,-0.511615,0.068,-1},{3,-0.105,-0.504,0.066,-0.123385,-0.511615,0.068,-0.105,-0.504,0.068,-1},{3,-0.123385,-0.511615,0.066,-0.131,-0.53,0.066,-0.131,-0.53,0.068,-1},{3,-0.123385,-0.511615,0.066,-0.131,-0.53,0.068,-0.123385,-0.511615,0.068,-1},{3,-0.131,-0.53,0.066,-0.123385,-0.548385,0.066,-0.123385,-0.548385,0.068,-1},{3,-0.131,-0.53,0.066,-0.123385,-0.548385,0.068,-0.131,-0.53,0.068,-1},{3,-0.123385,-0.548385,0.066,-0.105,-0.556,0.066,-0.105,-0.556,0.068,-1},{3,-0.123385,-0.548385,0.066,-0.105,-0.556,0.068,-0.123385,-0.548385,0.068,-1},{3,-0.105,-0.556,0.066,-0.086615,-0.548385,0.066,-0.086615,-0.548385,0.068,-1},{3,-0.105,-0.556,0.066,-0.086615,-0.548385,0.068,-0.105,-0.556,0.068,-1},{3,-0.086615,-0.548385,0.066,-0.079,-0.53,0.066,-0.079,-0.53,0.068,-1},{3,-0.086615,-0.548385,0.066,-0.079,-0.53,0.068,-0.086615,-0.548385,0.068,-1},{3,-0.086615,-0.318385,0.068,-0.079,-0.3,0.068,-0.086615,-0.281615,0.068,-1},{3,-0.086615,-0.281615,0.066,-0.079,-0.3,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.086615,-0.281615,0.068,-0.105,-0.274,0.068,-1},{3,-0.105,-0.274,0.066,-0.086615,-0.281615,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.105,-0.274,0.068,-0.123385,-0.281615,0.068,-1},{3,-0.123385,-0.281615,0.066,-0.105,-0.274,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.123385,-0.281615,0.068,-0.131,-0.3,0.068,-1},{3,-0.131,-0.3,0.066,-0.123385,-0.281615,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.086615,-0.318385,0.068,-0.131,-0.3,0.068,-0.123385,-0.318385,0.068,-1},{3,-0.123385,-0.318385,0.066,-0.131,-0.3,0.066,-0.086615,-0.318385,0.066,-1},{3,-0.123385,-0.318385,0.068,-0.105,-0.326,0.068,-0.086615,-0.318385,0.068,-1},{3,-0.086615,-0.318385,0.066,-0.105,-0.326,0.066,-0.123385,-0.318385,0.066,-1},{3,-0.079,-0.3,0.066,-0.086615,-0.281615,0.066,-0.086615,-0.281615,0.068,-1},{3,-0.079,-0.3,0.066,-0.086615,-0.281615,0.068,-0.079,-0.3,0.068,-1},{3,-0.086615,-0.281615,0.066,-0.105,-0.274,0.066,-0.105,-0.274,0.068,-1},{3,-0.086615,-0.281615,0.066,-0.105,-0.274,0.068,-0.086615,-0.281615,0.068,-1},{3,-0.105,-0.274,0.066,-0.123385,-0.281615,0.066,-0.123385,-0.281615,0.068,-1},{3,-0.105,-0.274,0.066,-0.123385,-0.281615,0.068,-0.105,-0.274,0.068,-1},{3,-0.123385,-0.281615,0.066,-0.131,-0.3,0.066,-0.131,-0.3,0.068,-1},{3,-0.123385,-0.281615,0.066,-0.131,-0.3,0.068,-0.123385,-0.281615,0.068,-1},{3,-0.131,-0.3,0.066,-0.123385,-0.318385,0.066,-0.123385,-0.318385,0.068,-1},{3,-0.131,-0.3,0.066,-0.123385,-0.318385,0.068,-0.131,-0.3,0.068,-1},{3,-0.123385,-0.318385,0.066,-0.105,-0.326,0.066,-0.105,-0.326,0.068,-1},{3,-0.123385,-0.318385,0.066,-0.105,-0.326,0.068,-0.123385,-0.318385,0.068,-1},{3,-0.105,-0.326,0.066,-0.086615,-0.318385,0.066,-0.086615,-0.318385,0.068,-1},{3,-0.105,-0.326,0.066,-0.086615,-0.318385,0.068,-0.105,-0.326,0.068,-1},{3,-0.086615,-0.318385,0.066,-0.079,-0.3,0.066,-0.079,-0.3,0.068,-1},{3,-0.086615,-0.318385,0.066,-0.079,-0.3,0.068,-0.086615,-0.318385,0.068,-1},{1,-0.07318,-0.01182,0.078,-0.06,0.02,0.078,-0.07318,0.05182,0.078,-1},{1,-0.07318,0.05182,0.066,-0.06,0.02,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.07318,0.05182,0.078,-0.105,0.065,0.078,-1},{1,-0.105,0.065,0.066,-0.07318,0.05182,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.105,0.065,0.078,-0.13682,0.05182,0.078,-1},{1,-0.13682,0.05182,0.066,-0.105,0.065,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.13682,0.05182,0.078,-0.15,0.02,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,0.05182,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.15,0.02,0.078,-0.13682,-0.01182,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.15,0.02,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.13682,-0.01182,0.078,-0.105,-0.025,0.078,-0.07318,-0.01182,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.105,-0.025,0.066,-0.13682,-0.01182,0.066,-1},{1,-0.06,0.02,0.066,-0.07318,0.05182,0.066,-0.07318,0.05182,0.078,-1},{1,-0.06,0.02,0.066,-0.07318,0.05182,0.078,-0.06,0.02,0.078,-1},{1,-0.07318,0.05182,0.066,-0.105,0.065,0.066,-0.105,0.065,0.078,-1},{1,-0.07318,0.05182,0.066,-0.105,0.065,0.078,-0.07318,0.05182,0.078,-1},{1,-0.105,0.065,0.066,-0.13682,0.05182,0.066,-0.13682,0.05182,0.078,-1},{1,-0.105,0.065,0.066,-0.13682,0.05182,0.078,-0.105,0.065,0.078,-1},{1,-0.13682,0.05182,0.066,-0.15,0.02,0.066,-0.15,0.02,0.078,-1},{1,-0.13682,0.05182,0.066,-0.15,0.02,0.078,-0.13682,0.05182,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,-0.01182,0.066,-0.13682,-0.01182,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,-0.01182,0.078,-0.15,0.02,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.105,-0.025,0.066,-0.105,-0.025,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.105,-0.025,0.078,-0.13682,-0.01182,0.078,-1},{1,-0.105,-0.025,0.066,-0.07318,-0.01182,0.066,-0.07318,-0.01182,0.078,-1},{1,-0.105,-0.025,0.066,-0.07318,-0.01182,0.078,-0.105,-0.025,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.06,0.02,0.066,-0.06,0.02,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.06,0.02,0.078,-0.07318,-0.01182,0.078,-1},{0,0.05,0.075,0.06,0.03,-1.0,0.06,0.177,-0.98,0.06,1},{0,0.177,-0.98,-0.06,0.03,-1.0,-0.06,0.05,0.075,-0.06,1},{0,0.177,-0.98,0.06,0.165,0.06,0.06,0.05,0.075,0.06,1},{0,0.05,0.075,-0.06,0.165,0.06,-0.06,0.177,-0.98,-0.06,1},{0,0.03,-1.0,-0.06,0.177,-0.98,-0.06,0.177,-0.98,0.06,1},{0,0.03,-1.0,-0.06,0.177,-0.98,0.06,0.03,-1.0,0.06,1},{0,0.177,-0.98,-0.06,0.165,0.06,-0.06,0.165,0.06,0.06,1},{0,0.177,-0.98,-0.06,0.165,0.06,0.06,0.177,-0.98,0.06,1},{0,0.165,0.06,-0.06,0.05,0.075,-0.06,0.05,0.075,0.06,1},{0,0.165,0.06,-0.06,0.05,0.075,0.06,0.165,0.06,0.06,1},{0,0.05,0.075,-0.06,0.03,-1.0,-0.06,0.03,-1.0,0.06,1},{0,0.05,0.075,-0.06,0.03,-1.0,0.06,0.05,0.075,0.06,1},{3,0.079,-0.12,0.065,0.067,-0.89,0.065,0.14,-0.88,0.065,1},{3,0.14,-0.88,0.061,0.067,-0.89,0.061,0.079,-0.12,0.061,1},{3,0.14,-0.88,0.065,0.132,-0.12,0.065,0.079,-0.12,0.065,1},{3,0.079,-0.12,0.061,0.132,-0.12,0.061,0.14,-0.88,0.061,1},{3,0.067,-0.89,0.061,0.14,-0.88,0.061,0.14,-0.88,0.065,1},{3,0.067,-0.89,0.061,0.14,-0.88,0.065,0.067,-0.89,0.065,1},{3,0.14,-0.88,0.061,0.132,-0.12,0.061,0.132,-0.12,0.065,1},{3,0.14,-0.88,0.061,0.132,-0.12,0.065,0.14,-0.88,0.065,1},{3,0.132,-0.12,0.061,0.079,-0.12,0.061,0.079,-0.12,0.065,1},{3,0.132,-0.12,0.061,0.079,-0.12,0.065,0.132,-0.12,0.065,1},{3,0.079,-0.12,0.061,0.067,-0.89,0.061,0.067,-0.89,0.065,1},{3,0.079,-0.12,0.061,0.067,-0.89,0.065,0.079,-0.12,0.065,1},{3,0.123385,-0.778385,0.068,0.131,-0.76,0.068,0.123385,-0.741615,0.068,1},{3,0.123385,-0.741615,0.066,0.131,-0.76,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.123385,-0.741615,0.068,0.105,-0.734,0.068,1},{3,0.105,-0.734,0.066,0.123385,-0.741615,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.105,-0.734,0.068,0.086615,-0.741615,0.068,1},{3,0.086615,-0.741615,0.066,0.105,-0.734,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.086615,-0.741615,0.068,0.079,-0.76,0.068,1},{3,0.079,-0.76,0.066,0.086615,-0.741615,0.066,0.123385,-0.778385,0.066,1},{3,0.123385,-0.778385,0.068,0.079,-0.76,0.068,0.086615,-0.778385,0.068,1},{3,0.086615,-0.778385,0.066,0.079,-0.76,0.066,0.123385,-0.778385,0.066,1},{3,0.086615,-0.778385,0.068,0.105,-0.786,0.068,0.123385,-0.778385,0.068,1},{3,0.123385,-0.778385,0.066,0.105,-0.786,0.066,0.086615,-0.778385,0.066,1},{3,0.131,-0.76,0.066,0.123385,-0.741615,0.066,0.123385,-0.741615,0.068,1},{3,0.131,-0.76,0.066,0.123385,-0.741615,0.068,0.131,-0.76,0.068,1},{3,0.123385,-0.741615,0.066,0.105,-0.734,0.066,0.105,-0.734,0.068,1},{3,0.123385,-0.741615,0.066,0.105,-0.734,0.068,0.123385,-0.741615,0.068,1},{3,0.105,-0.734,0.066,0.086615,-0.741615,0.066,0.086615,-0.741615,0.068,1},{3,0.105,-0.734,0.066,0.086615,-0.741615,0.068,0.105,-0.734,0.068,1},{3,0.086615,-0.741615,0.066,0.079,-0.76,0.066,0.079,-0.76,0.068,1},{3,0.086615,-0.741615,0.066,0.079,-0.76,0.068,0.086615,-0.741615,0.068,1},{3,0.079,-0.76,0.066,0.086615,-0.778385,0.066,0.086615,-0.778385,0.068,1},{3,0.079,-0.76,0.066,0.086615,-0.778385,0.068,0.079,-0.76,0.068,1},{3,0.086615,-0.778385,0.066,0.105,-0.786,0.066,0.105,-0.786,0.068,1},{3,0.086615,-0.778385,0.066,0.105,-0.786,0.068,0.086615,-0.778385,0.068,1},{3,0.105,-0.786,0.066,0.123385,-0.778385,0.066,0.123385,-0.778385,0.068,1},{3,0.105,-0.786,0.066,0.123385,-0.778385,0.068,0.105,-0.786,0.068,1},{3,0.123385,-0.778385,0.066,0.131,-0.76,0.066,0.131,-0.76,0.068,1},{3,0.123385,-0.778385,0.066,0.131,-0.76,0.068,0.123385,-0.778385,0.068,1},{3,0.123385,-0.548385,0.068,0.131,-0.53,0.068,0.123385,-0.511615,0.068,1},{3,0.123385,-0.511615,0.066,0.131,-0.53,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.123385,-0.511615,0.068,0.105,-0.504,0.068,1},{3,0.105,-0.504,0.066,0.123385,-0.511615,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.105,-0.504,0.068,0.086615,-0.511615,0.068,1},{3,0.086615,-0.511615,0.066,0.105,-0.504,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.086615,-0.511615,0.068,0.079,-0.53,0.068,1},{3,0.079,-0.53,0.066,0.086615,-0.511615,0.066,0.123385,-0.548385,0.066,1},{3,0.123385,-0.548385,0.068,0.079,-0.53,0.068,0.086615,-0.548385,0.068,1},{3,0.086615,-0.548385,0.066,0.079,-0.53,0.066,0.123385,-0.548385,0.066,1},{3,0.086615,-0.548385,0.068,0.105,-0.556,0.068,0.123385,-0.548385,0.068,1},{3,0.123385,-0.548385,0.066,0.105,-0.556,0.066,0.086615,-0.548385,0.066,1},{3,0.131,-0.53,0.066,0.123385,-0.511615,0.066,0.123385,-0.511615,0.068,1},{3,0.131,-0.53,0.066,0.123385,-0.511615,0.068,0.131,-0.53,0.068,1},{3,0.123385,-0.511615,0.066,0.105,-0.504,0.066,0.105,-0.504,0.068,1},{3,0.123385,-0.511615,0.066,0.105,-0.504,0.068,0.123385,-0.511615,0.068,1},{3,0.105,-0.504,0.066,0.086615,-0.511615,0.066,0.086615,-0.511615,0.068,1},{3,0.105,-0.504,0.066,0.086615,-0.511615,0.068,0.105,-0.504,0.068,1},{3,0.086615,-0.511615,0.066,0.079,-0.53,0.066,0.079,-0.53,0.068,1},{3,0.086615,-0.511615,0.066,0.079,-0.53,0.068,0.086615,-0.511615,0.068,1},{3,0.079,-0.53,0.066,0.086615,-0.548385,0.066,0.086615,-0.548385,0.068,1},{3,0.079,-0.53,0.066,0.086615,-0.548385,0.068,0.079,-0.53,0.068,1},{3,0.086615,-0.548385,0.066,0.105,-0.556,0.066,0.105,-0.556,0.068,1},{3,0.086615,-0.548385,0.066,0.105,-0.556,0.068,0.086615,-0.548385,0.068,1},{3,0.105,-0.556,0.066,0.123385,-0.548385,0.066,0.123385,-0.548385,0.068,1},{3,0.105,-0.556,0.066,0.123385,-0.548385,0.068,0.105,-0.556,0.068,1},{3,0.123385,-0.548385,0.066,0.131,-0.53,0.066,0.131,-0.53,0.068,1},{3,0.123385,-0.548385,0.066,0.131,-0.53,0.068,0.123385,-0.548385,0.068,1},{3,0.123385,-0.318385,0.068,0.131,-0.3,0.068,0.123385,-0.281615,0.068,1},{3,0.123385,-0.281615,0.066,0.131,-0.3,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.123385,-0.281615,0.068,0.105,-0.274,0.068,1},{3,0.105,-0.274,0.066,0.123385,-0.281615,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.105,-0.274,0.068,0.086615,-0.281615,0.068,1},{3,0.086615,-0.281615,0.066,0.105,-0.274,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.086615,-0.281615,0.068,0.079,-0.3,0.068,1},{3,0.079,-0.3,0.066,0.086615,-0.281615,0.066,0.123385,-0.318385,0.066,1},{3,0.123385,-0.318385,0.068,0.079,-0.3,0.068,0.086615,-0.318385,0.068,1},{3,0.086615,-0.318385,0.066,0.079,-0.3,0.066,0.123385,-0.318385,0.066,1},{3,0.086615,-0.318385,0.068,0.105,-0.326,0.068,0.123385,-0.318385,0.068,1},{3,0.123385,-0.318385,0.066,0.105,-0.326,0.066,0.086615,-0.318385,0.066,1},{3,0.131,-0.3,0.066,0.123385,-0.281615,0.066,0.123385,-0.281615,0.068,1},{3,0.131,-0.3,0.066,0.123385,-0.281615,0.068,0.131,-0.3,0.068,1},{3,0.123385,-0.281615,0.066,0.105,-0.274,0.066,0.105,-0.274,0.068,1},{3,0.123385,-0.281615,0.066,0.105,-0.274,0.068,0.123385,-0.281615,0.068,1},{3,0.105,-0.274,0.066,0.086615,-0.281615,0.066,0.086615,-0.281615,0.068,1},{3,0.105,-0.274,0.066,0.086615,-0.281615,0.068,0.105,-0.274,0.068,1},{3,0.086615,-0.281615,0.066,0.079,-0.3,0.066,0.079,-0.3,0.068,1},{3,0.086615,-0.281615,0.066,0.079,-0.3,0.068,0.086615,-0.281615,0.068,1},{3,0.079,-0.3,0.066,0.086615,-0.318385,0.066,0.086615,-0.318385,0.068,1},{3,0.079,-0.3,0.066,0.086615,-0.318385,0.068,0.079,-0.3,0.068,1},{3,0.086615,-0.318385,0.066,0.105,-0.326,0.066,0.105,-0.326,0.068,1},{3,0.086615,-0.318385,0.066,0.105,-0.326,0.068,0.086615,-0.318385,0.068,1},{3,0.105,-0.326,0.066,0.123385,-0.318385,0.066,0.123385,-0.318385,0.068,1},{3,0.105,-0.326,0.066,0.123385,-0.318385,0.068,0.105,-0.326,0.068,1},{3,0.123385,-0.318385,0.066,0.131,-0.3,0.066,0.131,-0.3,0.068,1},{3,0.123385,-0.318385,0.066,0.131,-0.3,0.068,0.123385,-0.318385,0.068,1},{1,0.13682,-0.01182,0.078,0.15,0.02,0.078,0.13682,0.05182,0.078,1},{1,0.13682,0.05182,0.066,0.15,0.02,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.13682,0.05182,0.078,0.105,0.065,0.078,1},{1,0.105,0.065,0.066,0.13682,0.05182,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.105,0.065,0.078,0.07318,0.05182,0.078,1},{1,0.07318,0.05182,0.066,0.105,0.065,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.07318,0.05182,0.078,0.06,0.02,0.078,1},{1,0.06,0.02,0.066,0.07318,0.05182,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.06,0.02,0.078,0.07318,-0.01182,0.078,1},{1,0.07318,-0.01182,0.066,0.06,0.02,0.066,0.13682,-0.01182,0.066,1},{1,0.07318,-0.01182,0.078,0.105,-0.025,0.078,0.13682,-0.01182,0.078,1},{1,0.13682,-0.01182,0.066,0.105,-0.025,0.066,0.07318,-0.01182,0.066,1},{1,0.15,0.02,0.066,0.13682,0.05182,0.066,0.13682,0.05182,0.078,1},{1,0.15,0.02,0.066,0.13682,0.05182,0.078,0.15,0.02,0.078,1},{1,0.13682,0.05182,0.066,0.105,0.065,0.066,0.105,0.065,0.078,1},{1,0.13682,0.05182,0.066,0.105,0.065,0.078,0.13682,0.05182,0.078,1},{1,0.105,0.065,0.066,0.07318,0.05182,0.066,0.07318,0.05182,0.078,1},{1,0.105,0.065,0.066,0.07318,0.05182,0.078,0.105,0.065,0.078,1},{1,0.07318,0.05182,0.066,0.06,0.02,0.066,0.06,0.02,0.078,1},{1,0.07318,0.05182,0.066,0.06,0.02,0.078,0.07318,0.05182,0.078,1},{1,0.06,0.02,0.066,0.07318,-0.01182,0.066,0.07318,-0.01182,0.078,1},{1,0.06,0.02,0.066,0.07318,-0.01182,0.078,0.06,0.02,0.078,1},{1,0.07318,-0.01182,0.066,0.105,-0.025,0.066,0.105,-0.025,0.078,1},{1,0.07318,-0.01182,0.066,0.105,-0.025,0.078,0.07318,-0.01182,0.078,1},{1,0.105,-0.025,0.066,0.13682,-0.01182,0.066,0.13682,-0.01182,0.078,1},{1,0.105,-0.025,0.066,0.13682,-0.01182,0.078,0.105,-0.025,0.078,1},{1,0.13682,-0.01182,0.066,0.15,0.02,0.066,0.15,0.02,0.078,1},{1,0.13682,-0.01182,0.066,0.15,0.02,0.078,0.13682,-0.01182,0.078,1}},colors={Color3.fromRGB(7,59,184),Color3.fromRGB(168,177,185),Color3.fromRGB(0,0,0),Color3.fromRGB(8,10,13),Color3.fromRGB(215,220,225)}},
        {name="BUTTERFLY BLACK",triangles={{1,-0.065,0.02,0.022,0.065,0.02,0.022,0.135,0.25,0.022,0},{1,0.135,0.25,-0.022,0.065,0.02,-0.022,-0.065,0.02,-0.022,0},{1,-0.065,0.02,0.022,0.135,0.25,0.022,0.14,0.85,0.022,0},{1,0.14,0.85,-0.022,0.135,0.25,-0.022,-0.065,0.02,-0.022,0},{1,-0.065,0.02,0.022,0.14,0.85,0.022,0.09,1.28,0.022,0},{1,0.09,1.28,-0.022,0.14,0.85,-0.022,-0.065,0.02,-0.022,0},{1,-0.065,0.02,0.022,0.09,1.28,0.022,0.005,1.55,0.022,0},{1,0.005,1.55,-0.022,0.09,1.28,-0.022,-0.065,0.02,-0.022,0},{1,-0.065,0.02,0.022,0.005,1.55,0.022,-0.105,1.1,0.022,0},{1,-0.105,1.1,-0.022,0.005,1.55,-0.022,-0.065,0.02,-0.022,0},{1,-0.065,0.02,0.022,-0.105,1.1,0.022,-0.135,0.72,0.022,0},{1,-0.135,0.72,-0.022,-0.105,1.1,-0.022,-0.065,0.02,-0.022,0},{1,-0.135,0.72,0.022,-0.125,0.25,0.022,-0.065,0.02,0.022,0},{1,-0.065,0.02,-0.022,-0.125,0.25,-0.022,-0.135,0.72,-0.022,0},{1,0.065,0.02,-0.022,0.135,0.25,-0.022,0.135,0.25,0.022,0},{1,0.065,0.02,-0.022,0.135,0.25,0.022,0.065,0.02,0.022,0},{1,0.135,0.25,-0.022,0.14,0.85,-0.022,0.14,0.85,0.022,0},{1,0.135,0.25,-0.022,0.14,0.85,0.022,0.135,0.25,0.022,0},{1,0.14,0.85,-0.022,0.09,1.28,-0.022,0.09,1.28,0.022,0},{1,0.14,0.85,-0.022,0.09,1.28,0.022,0.14,0.85,0.022,0},{1,0.09,1.28,-0.022,0.005,1.55,-0.022,0.005,1.55,0.022,0},{1,0.09,1.28,-0.022,0.005,1.55,0.022,0.09,1.28,0.022,0},{1,0.005,1.55,-0.022,-0.105,1.1,-0.022,-0.105,1.1,0.022,0},{1,0.005,1.55,-0.022,-0.105,1.1,0.022,0.005,1.55,0.022,0},{1,-0.105,1.1,-0.022,-0.135,0.72,-0.022,-0.135,0.72,0.022,0},{1,-0.105,1.1,-0.022,-0.135,0.72,0.022,-0.105,1.1,0.022,0},{1,-0.135,0.72,-0.022,-0.125,0.25,-0.022,-0.125,0.25,0.022,0},{1,-0.135,0.72,-0.022,-0.125,0.25,0.022,-0.135,0.72,0.022,0},{1,-0.125,0.25,-0.022,-0.065,0.02,-0.022,-0.065,0.02,0.022,0},{1,-0.125,0.25,-0.022,-0.065,0.02,0.022,-0.125,0.25,0.022,0},{1,-0.065,0.02,-0.022,0.065,0.02,-0.022,0.065,0.02,0.022,0},{1,-0.065,0.02,-0.022,0.065,0.02,0.022,-0.065,0.02,0.022,0},{0,-0.16,0.075,0.06,-0.18,-1.0,0.06,-0.033,-0.98,0.06,-1},{0,-0.033,-0.98,-0.06,-0.18,-1.0,-0.06,-0.16,0.075,-0.06,-1},{0,-0.033,-0.98,0.06,-0.045,0.06,0.06,-0.16,0.075,0.06,-1},{0,-0.16,0.075,-0.06,-0.045,0.06,-0.06,-0.033,-0.98,-0.06,-1},{0,-0.18,-1.0,-0.06,-0.033,-0.98,-0.06,-0.033,-0.98,0.06,-1},{0,-0.18,-1.0,-0.06,-0.033,-0.98,0.06,-0.18,-1.0,0.06,-1},{0,-0.033,-0.98,-0.06,-0.045,0.06,-0.06,-0.045,0.06,0.06,-1},{0,-0.033,-0.98,-0.06,-0.045,0.06,0.06,-0.033,-0.98,0.06,-1},{0,-0.045,0.06,-0.06,-0.16,0.075,-0.06,-0.16,0.075,0.06,-1},{0,-0.045,0.06,-0.06,-0.16,0.075,0.06,-0.045,0.06,0.06,-1},{0,-0.16,0.075,-0.06,-0.18,-1.0,-0.06,-0.18,-1.0,0.06,-1},{0,-0.16,0.075,-0.06,-0.18,-1.0,0.06,-0.16,0.075,0.06,-1},{3,-0.131,-0.12,0.065,-0.143,-0.89,0.065,-0.07,-0.88,0.065,-1},{3,-0.07,-0.88,0.061,-0.143,-0.89,0.061,-0.131,-0.12,0.061,-1},{3,-0.07,-0.88,0.065,-0.078,-0.12,0.065,-0.131,-0.12,0.065,-1},{3,-0.131,-0.12,0.061,-0.078,-0.12,0.061,-0.07,-0.88,0.061,-1},{3,-0.143,-0.89,0.061,-0.07,-0.88,0.061,-0.07,-0.88,0.065,-1},{3,-0.143,-0.89,0.061,-0.07,-0.88,0.065,-0.143,-0.89,0.065,-1},{3,-0.07,-0.88,0.061,-0.078,-0.12,0.061,-0.078,-0.12,0.065,-1},{3,-0.07,-0.88,0.061,-0.078,-0.12,0.065,-0.07,-0.88,0.065,-1},{3,-0.078,-0.12,0.061,-0.131,-0.12,0.061,-0.131,-0.12,0.065,-1},{3,-0.078,-0.12,0.061,-0.131,-0.12,0.065,-0.078,-0.12,0.065,-1},{3,-0.131,-0.12,0.061,-0.143,-0.89,0.061,-0.143,-0.89,0.065,-1},{3,-0.131,-0.12,0.061,-0.143,-0.89,0.065,-0.131,-0.12,0.065,-1},{0,-0.086615,-0.778385,0.068,-0.079,-0.76,0.068,-0.086615,-0.741615,0.068,-1},{0,-0.086615,-0.741615,0.066,-0.079,-0.76,0.066,-0.086615,-0.778385,0.066,-1},{0,-0.086615,-0.778385,0.068,-0.086615,-0.741615,0.068,-0.105,-0.734,0.068,-1},{0,-0.105,-0.734,0.066,-0.086615,-0.741615,0.066,-0.086615,-0.778385,0.066,-1},{0,-0.086615,-0.778385,0.068,-0.105,-0.734,0.068,-0.123385,-0.741615,0.068,-1},{0,-0.123385,-0.741615,0.066,-0.105,-0.734,0.066,-0.086615,-0.778385,0.066,-1},{0,-0.086615,-0.778385,0.068,-0.123385,-0.741615,0.068,-0.131,-0.76,0.068,-1},{0,-0.131,-0.76,0.066,-0.123385,-0.741615,0.066,-0.086615,-0.778385,0.066,-1},{0,-0.086615,-0.778385,0.068,-0.131,-0.76,0.068,-0.123385,-0.778385,0.068,-1},{0,-0.123385,-0.778385,0.066,-0.131,-0.76,0.066,-0.086615,-0.778385,0.066,-1},{0,-0.123385,-0.778385,0.068,-0.105,-0.786,0.068,-0.086615,-0.778385,0.068,-1},{0,-0.086615,-0.778385,0.066,-0.105,-0.786,0.066,-0.123385,-0.778385,0.066,-1},{0,-0.079,-0.76,0.066,-0.086615,-0.741615,0.066,-0.086615,-0.741615,0.068,-1},{0,-0.079,-0.76,0.066,-0.086615,-0.741615,0.068,-0.079,-0.76,0.068,-1},{0,-0.086615,-0.741615,0.066,-0.105,-0.734,0.066,-0.105,-0.734,0.068,-1},{0,-0.086615,-0.741615,0.066,-0.105,-0.734,0.068,-0.086615,-0.741615,0.068,-1},{0,-0.105,-0.734,0.066,-0.123385,-0.741615,0.066,-0.123385,-0.741615,0.068,-1},{0,-0.105,-0.734,0.066,-0.123385,-0.741615,0.068,-0.105,-0.734,0.068,-1},{0,-0.123385,-0.741615,0.066,-0.131,-0.76,0.066,-0.131,-0.76,0.068,-1},{0,-0.123385,-0.741615,0.066,-0.131,-0.76,0.068,-0.123385,-0.741615,0.068,-1},{0,-0.131,-0.76,0.066,-0.123385,-0.778385,0.066,-0.123385,-0.778385,0.068,-1},{0,-0.131,-0.76,0.066,-0.123385,-0.778385,0.068,-0.131,-0.76,0.068,-1},{0,-0.123385,-0.778385,0.066,-0.105,-0.786,0.066,-0.105,-0.786,0.068,-1},{0,-0.123385,-0.778385,0.066,-0.105,-0.786,0.068,-0.123385,-0.778385,0.068,-1},{0,-0.105,-0.786,0.066,-0.086615,-0.778385,0.066,-0.086615,-0.778385,0.068,-1},{0,-0.105,-0.786,0.066,-0.086615,-0.778385,0.068,-0.105,-0.786,0.068,-1},{0,-0.086615,-0.778385,0.066,-0.079,-0.76,0.066,-0.079,-0.76,0.068,-1},{0,-0.086615,-0.778385,0.066,-0.079,-0.76,0.068,-0.086615,-0.778385,0.068,-1},{0,-0.086615,-0.548385,0.068,-0.079,-0.53,0.068,-0.086615,-0.511615,0.068,-1},{0,-0.086615,-0.511615,0.066,-0.079,-0.53,0.066,-0.086615,-0.548385,0.066,-1},{0,-0.086615,-0.548385,0.068,-0.086615,-0.511615,0.068,-0.105,-0.504,0.068,-1},{0,-0.105,-0.504,0.066,-0.086615,-0.511615,0.066,-0.086615,-0.548385,0.066,-1},{0,-0.086615,-0.548385,0.068,-0.105,-0.504,0.068,-0.123385,-0.511615,0.068,-1},{0,-0.123385,-0.511615,0.066,-0.105,-0.504,0.066,-0.086615,-0.548385,0.066,-1},{0,-0.086615,-0.548385,0.068,-0.123385,-0.511615,0.068,-0.131,-0.53,0.068,-1},{0,-0.131,-0.53,0.066,-0.123385,-0.511615,0.066,-0.086615,-0.548385,0.066,-1},{0,-0.086615,-0.548385,0.068,-0.131,-0.53,0.068,-0.123385,-0.548385,0.068,-1},{0,-0.123385,-0.548385,0.066,-0.131,-0.53,0.066,-0.086615,-0.548385,0.066,-1},{0,-0.123385,-0.548385,0.068,-0.105,-0.556,0.068,-0.086615,-0.548385,0.068,-1},{0,-0.086615,-0.548385,0.066,-0.105,-0.556,0.066,-0.123385,-0.548385,0.066,-1},{0,-0.079,-0.53,0.066,-0.086615,-0.511615,0.066,-0.086615,-0.511615,0.068,-1},{0,-0.079,-0.53,0.066,-0.086615,-0.511615,0.068,-0.079,-0.53,0.068,-1},{0,-0.086615,-0.511615,0.066,-0.105,-0.504,0.066,-0.105,-0.504,0.068,-1},{0,-0.086615,-0.511615,0.066,-0.105,-0.504,0.068,-0.086615,-0.511615,0.068,-1},{0,-0.105,-0.504,0.066,-0.123385,-0.511615,0.066,-0.123385,-0.511615,0.068,-1},{0,-0.105,-0.504,0.066,-0.123385,-0.511615,0.068,-0.105,-0.504,0.068,-1},{0,-0.123385,-0.511615,0.066,-0.131,-0.53,0.066,-0.131,-0.53,0.068,-1},{0,-0.123385,-0.511615,0.066,-0.131,-0.53,0.068,-0.123385,-0.511615,0.068,-1},{0,-0.131,-0.53,0.066,-0.123385,-0.548385,0.066,-0.123385,-0.548385,0.068,-1},{0,-0.131,-0.53,0.066,-0.123385,-0.548385,0.068,-0.131,-0.53,0.068,-1},{0,-0.123385,-0.548385,0.066,-0.105,-0.556,0.066,-0.105,-0.556,0.068,-1},{0,-0.123385,-0.548385,0.066,-0.105,-0.556,0.068,-0.123385,-0.548385,0.068,-1},{0,-0.105,-0.556,0.066,-0.086615,-0.548385,0.066,-0.086615,-0.548385,0.068,-1},{0,-0.105,-0.556,0.066,-0.086615,-0.548385,0.068,-0.105,-0.556,0.068,-1},{0,-0.086615,-0.548385,0.066,-0.079,-0.53,0.066,-0.079,-0.53,0.068,-1},{0,-0.086615,-0.548385,0.066,-0.079,-0.53,0.068,-0.086615,-0.548385,0.068,-1},{0,-0.086615,-0.318385,0.068,-0.079,-0.3,0.068,-0.086615,-0.281615,0.068,-1},{0,-0.086615,-0.281615,0.066,-0.079,-0.3,0.066,-0.086615,-0.318385,0.066,-1},{0,-0.086615,-0.318385,0.068,-0.086615,-0.281615,0.068,-0.105,-0.274,0.068,-1},{0,-0.105,-0.274,0.066,-0.086615,-0.281615,0.066,-0.086615,-0.318385,0.066,-1},{0,-0.086615,-0.318385,0.068,-0.105,-0.274,0.068,-0.123385,-0.281615,0.068,-1},{0,-0.123385,-0.281615,0.066,-0.105,-0.274,0.066,-0.086615,-0.318385,0.066,-1},{0,-0.086615,-0.318385,0.068,-0.123385,-0.281615,0.068,-0.131,-0.3,0.068,-1},{0,-0.131,-0.3,0.066,-0.123385,-0.281615,0.066,-0.086615,-0.318385,0.066,-1},{0,-0.086615,-0.318385,0.068,-0.131,-0.3,0.068,-0.123385,-0.318385,0.068,-1},{0,-0.123385,-0.318385,0.066,-0.131,-0.3,0.066,-0.086615,-0.318385,0.066,-1},{0,-0.123385,-0.318385,0.068,-0.105,-0.326,0.068,-0.086615,-0.318385,0.068,-1},{0,-0.086615,-0.318385,0.066,-0.105,-0.326,0.066,-0.123385,-0.318385,0.066,-1},{0,-0.079,-0.3,0.066,-0.086615,-0.281615,0.066,-0.086615,-0.281615,0.068,-1},{0,-0.079,-0.3,0.066,-0.086615,-0.281615,0.068,-0.079,-0.3,0.068,-1},{0,-0.086615,-0.281615,0.066,-0.105,-0.274,0.066,-0.105,-0.274,0.068,-1},{0,-0.086615,-0.281615,0.066,-0.105,-0.274,0.068,-0.086615,-0.281615,0.068,-1},{0,-0.105,-0.274,0.066,-0.123385,-0.281615,0.066,-0.123385,-0.281615,0.068,-1},{0,-0.105,-0.274,0.066,-0.123385,-0.281615,0.068,-0.105,-0.274,0.068,-1},{0,-0.123385,-0.281615,0.066,-0.131,-0.3,0.066,-0.131,-0.3,0.068,-1},{0,-0.123385,-0.281615,0.066,-0.131,-0.3,0.068,-0.123385,-0.281615,0.068,-1},{0,-0.131,-0.3,0.066,-0.123385,-0.318385,0.066,-0.123385,-0.318385,0.068,-1},{0,-0.131,-0.3,0.066,-0.123385,-0.318385,0.068,-0.131,-0.3,0.068,-1},{0,-0.123385,-0.318385,0.066,-0.105,-0.326,0.066,-0.105,-0.326,0.068,-1},{0,-0.123385,-0.318385,0.066,-0.105,-0.326,0.068,-0.123385,-0.318385,0.068,-1},{0,-0.105,-0.326,0.066,-0.086615,-0.318385,0.066,-0.086615,-0.318385,0.068,-1},{0,-0.105,-0.326,0.066,-0.086615,-0.318385,0.068,-0.105,-0.326,0.068,-1},{0,-0.086615,-0.318385,0.066,-0.079,-0.3,0.066,-0.079,-0.3,0.068,-1},{0,-0.086615,-0.318385,0.066,-0.079,-0.3,0.068,-0.086615,-0.318385,0.068,-1},{1,-0.07318,-0.01182,0.078,-0.06,0.02,0.078,-0.07318,0.05182,0.078,-1},{1,-0.07318,0.05182,0.066,-0.06,0.02,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.07318,0.05182,0.078,-0.105,0.065,0.078,-1},{1,-0.105,0.065,0.066,-0.07318,0.05182,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.105,0.065,0.078,-0.13682,0.05182,0.078,-1},{1,-0.13682,0.05182,0.066,-0.105,0.065,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.13682,0.05182,0.078,-0.15,0.02,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,0.05182,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.07318,-0.01182,0.078,-0.15,0.02,0.078,-0.13682,-0.01182,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.15,0.02,0.066,-0.07318,-0.01182,0.066,-1},{1,-0.13682,-0.01182,0.078,-0.105,-0.025,0.078,-0.07318,-0.01182,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.105,-0.025,0.066,-0.13682,-0.01182,0.066,-1},{1,-0.06,0.02,0.066,-0.07318,0.05182,0.066,-0.07318,0.05182,0.078,-1},{1,-0.06,0.02,0.066,-0.07318,0.05182,0.078,-0.06,0.02,0.078,-1},{1,-0.07318,0.05182,0.066,-0.105,0.065,0.066,-0.105,0.065,0.078,-1},{1,-0.07318,0.05182,0.066,-0.105,0.065,0.078,-0.07318,0.05182,0.078,-1},{1,-0.105,0.065,0.066,-0.13682,0.05182,0.066,-0.13682,0.05182,0.078,-1},{1,-0.105,0.065,0.066,-0.13682,0.05182,0.078,-0.105,0.065,0.078,-1},{1,-0.13682,0.05182,0.066,-0.15,0.02,0.066,-0.15,0.02,0.078,-1},{1,-0.13682,0.05182,0.066,-0.15,0.02,0.078,-0.13682,0.05182,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,-0.01182,0.066,-0.13682,-0.01182,0.078,-1},{1,-0.15,0.02,0.066,-0.13682,-0.01182,0.078,-0.15,0.02,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.105,-0.025,0.066,-0.105,-0.025,0.078,-1},{1,-0.13682,-0.01182,0.066,-0.105,-0.025,0.078,-0.13682,-0.01182,0.078,-1},{1,-0.105,-0.025,0.066,-0.07318,-0.01182,0.066,-0.07318,-0.01182,0.078,-1},{1,-0.105,-0.025,0.066,-0.07318,-0.01182,0.078,-0.105,-0.025,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.06,0.02,0.066,-0.06,0.02,0.078,-1},{1,-0.07318,-0.01182,0.066,-0.06,0.02,0.078,-0.07318,-0.01182,0.078,-1},{0,0.05,0.075,0.06,0.03,-1.0,0.06,0.177,-0.98,0.06,1},{0,0.177,-0.98,-0.06,0.03,-1.0,-0.06,0.05,0.075,-0.06,1},{0,0.177,-0.98,0.06,0.165,0.06,0.06,0.05,0.075,0.06,1},{0,0.05,0.075,-0.06,0.165,0.06,-0.06,0.177,-0.98,-0.06,1},{0,0.03,-1.0,-0.06,0.177,-0.98,-0.06,0.177,-0.98,0.06,1},{0,0.03,-1.0,-0.06,0.177,-0.98,0.06,0.03,-1.0,0.06,1},{0,0.177,-0.98,-0.06,0.165,0.06,-0.06,0.165,0.06,0.06,1},{0,0.177,-0.98,-0.06,0.165,0.06,0.06,0.177,-0.98,0.06,1},{0,0.165,0.06,-0.06,0.05,0.075,-0.06,0.05,0.075,0.06,1},{0,0.165,0.06,-0.06,0.05,0.075,0.06,0.165,0.06,0.06,1},{0,0.05,0.075,-0.06,0.03,-1.0,-0.06,0.03,-1.0,0.06,1},{0,0.05,0.075,-0.06,0.03,-1.0,0.06,0.05,0.075,0.06,1},{3,0.079,-0.12,0.065,0.067,-0.89,0.065,0.14,-0.88,0.065,1},{3,0.14,-0.88,0.061,0.067,-0.89,0.061,0.079,-0.12,0.061,1},{3,0.14,-0.88,0.065,0.132,-0.12,0.065,0.079,-0.12,0.065,1},{3,0.079,-0.12,0.061,0.132,-0.12,0.061,0.14,-0.88,0.061,1},{3,0.067,-0.89,0.061,0.14,-0.88,0.061,0.14,-0.88,0.065,1},{3,0.067,-0.89,0.061,0.14,-0.88,0.065,0.067,-0.89,0.065,1},{3,0.14,-0.88,0.061,0.132,-0.12,0.061,0.132,-0.12,0.065,1},{3,0.14,-0.88,0.061,0.132,-0.12,0.065,0.14,-0.88,0.065,1},{3,0.132,-0.12,0.061,0.079,-0.12,0.061,0.079,-0.12,0.065,1},{3,0.132,-0.12,0.061,0.079,-0.12,0.065,0.132,-0.12,0.065,1},{3,0.079,-0.12,0.061,0.067,-0.89,0.061,0.067,-0.89,0.065,1},{3,0.079,-0.12,0.061,0.067,-0.89,0.065,0.079,-0.12,0.065,1},{0,0.123385,-0.778385,0.068,0.131,-0.76,0.068,0.123385,-0.741615,0.068,1},{0,0.123385,-0.741615,0.066,0.131,-0.76,0.066,0.123385,-0.778385,0.066,1},{0,0.123385,-0.778385,0.068,0.123385,-0.741615,0.068,0.105,-0.734,0.068,1},{0,0.105,-0.734,0.066,0.123385,-0.741615,0.066,0.123385,-0.778385,0.066,1},{0,0.123385,-0.778385,0.068,0.105,-0.734,0.068,0.086615,-0.741615,0.068,1},{0,0.086615,-0.741615,0.066,0.105,-0.734,0.066,0.123385,-0.778385,0.066,1},{0,0.123385,-0.778385,0.068,0.086615,-0.741615,0.068,0.079,-0.76,0.068,1},{0,0.079,-0.76,0.066,0.086615,-0.741615,0.066,0.123385,-0.778385,0.066,1},{0,0.123385,-0.778385,0.068,0.079,-0.76,0.068,0.086615,-0.778385,0.068,1},{0,0.086615,-0.778385,0.066,0.079,-0.76,0.066,0.123385,-0.778385,0.066,1},{0,0.086615,-0.778385,0.068,0.105,-0.786,0.068,0.123385,-0.778385,0.068,1},{0,0.123385,-0.778385,0.066,0.105,-0.786,0.066,0.086615,-0.778385,0.066,1},{0,0.131,-0.76,0.066,0.123385,-0.741615,0.066,0.123385,-0.741615,0.068,1},{0,0.131,-0.76,0.066,0.123385,-0.741615,0.068,0.131,-0.76,0.068,1},{0,0.123385,-0.741615,0.066,0.105,-0.734,0.066,0.105,-0.734,0.068,1},{0,0.123385,-0.741615,0.066,0.105,-0.734,0.068,0.123385,-0.741615,0.068,1},{0,0.105,-0.734,0.066,0.086615,-0.741615,0.066,0.086615,-0.741615,0.068,1},{0,0.105,-0.734,0.066,0.086615,-0.741615,0.068,0.105,-0.734,0.068,1},{0,0.086615,-0.741615,0.066,0.079,-0.76,0.066,0.079,-0.76,0.068,1},{0,0.086615,-0.741615,0.066,0.079,-0.76,0.068,0.086615,-0.741615,0.068,1},{0,0.079,-0.76,0.066,0.086615,-0.778385,0.066,0.086615,-0.778385,0.068,1},{0,0.079,-0.76,0.066,0.086615,-0.778385,0.068,0.079,-0.76,0.068,1},{0,0.086615,-0.778385,0.066,0.105,-0.786,0.066,0.105,-0.786,0.068,1},{0,0.086615,-0.778385,0.066,0.105,-0.786,0.068,0.086615,-0.778385,0.068,1},{0,0.105,-0.786,0.066,0.123385,-0.778385,0.066,0.123385,-0.778385,0.068,1},{0,0.105,-0.786,0.066,0.123385,-0.778385,0.068,0.105,-0.786,0.068,1},{0,0.123385,-0.778385,0.066,0.131,-0.76,0.066,0.131,-0.76,0.068,1},{0,0.123385,-0.778385,0.066,0.131,-0.76,0.068,0.123385,-0.778385,0.068,1},{0,0.123385,-0.548385,0.068,0.131,-0.53,0.068,0.123385,-0.511615,0.068,1},{0,0.123385,-0.511615,0.066,0.131,-0.53,0.066,0.123385,-0.548385,0.066,1},{0,0.123385,-0.548385,0.068,0.123385,-0.511615,0.068,0.105,-0.504,0.068,1},{0,0.105,-0.504,0.066,0.123385,-0.511615,0.066,0.123385,-0.548385,0.066,1},{0,0.123385,-0.548385,0.068,0.105,-0.504,0.068,0.086615,-0.511615,0.068,1},{0,0.086615,-0.511615,0.066,0.105,-0.504,0.066,0.123385,-0.548385,0.066,1},{0,0.123385,-0.548385,0.068,0.086615,-0.511615,0.068,0.079,-0.53,0.068,1},{0,0.079,-0.53,0.066,0.086615,-0.511615,0.066,0.123385,-0.548385,0.066,1},{0,0.123385,-0.548385,0.068,0.079,-0.53,0.068,0.086615,-0.548385,0.068,1},{0,0.086615,-0.548385,0.066,0.079,-0.53,0.066,0.123385,-0.548385,0.066,1},{0,0.086615,-0.548385,0.068,0.105,-0.556,0.068,0.123385,-0.548385,0.068,1},{0,0.123385,-0.548385,0.066,0.105,-0.556,0.066,0.086615,-0.548385,0.066,1},{0,0.131,-0.53,0.066,0.123385,-0.511615,0.066,0.123385,-0.511615,0.068,1},{0,0.131,-0.53,0.066,0.123385,-0.511615,0.068,0.131,-0.53,0.068,1},{0,0.123385,-0.511615,0.066,0.105,-0.504,0.066,0.105,-0.504,0.068,1},{0,0.123385,-0.511615,0.066,0.105,-0.504,0.068,0.123385,-0.511615,0.068,1},{0,0.105,-0.504,0.066,0.086615,-0.511615,0.066,0.086615,-0.511615,0.068,1},{0,0.105,-0.504,0.066,0.086615,-0.511615,0.068,0.105,-0.504,0.068,1},{0,0.086615,-0.511615,0.066,0.079,-0.53,0.066,0.079,-0.53,0.068,1},{0,0.086615,-0.511615,0.066,0.079,-0.53,0.068,0.086615,-0.511615,0.068,1},{0,0.079,-0.53,0.066,0.086615,-0.548385,0.066,0.086615,-0.548385,0.068,1},{0,0.079,-0.53,0.066,0.086615,-0.548385,0.068,0.079,-0.53,0.068,1},{0,0.086615,-0.548385,0.066,0.105,-0.556,0.066,0.105,-0.556,0.068,1},{0,0.086615,-0.548385,0.066,0.105,-0.556,0.068,0.086615,-0.548385,0.068,1},{0,0.105,-0.556,0.066,0.123385,-0.548385,0.066,0.123385,-0.548385,0.068,1},{0,0.105,-0.556,0.066,0.123385,-0.548385,0.068,0.105,-0.556,0.068,1},{0,0.123385,-0.548385,0.066,0.131,-0.53,0.066,0.131,-0.53,0.068,1},{0,0.123385,-0.548385,0.066,0.131,-0.53,0.068,0.123385,-0.548385,0.068,1},{0,0.123385,-0.318385,0.068,0.131,-0.3,0.068,0.123385,-0.281615,0.068,1},{0,0.123385,-0.281615,0.066,0.131,-0.3,0.066,0.123385,-0.318385,0.066,1},{0,0.123385,-0.318385,0.068,0.123385,-0.281615,0.068,0.105,-0.274,0.068,1},{0,0.105,-0.274,0.066,0.123385,-0.281615,0.066,0.123385,-0.318385,0.066,1},{0,0.123385,-0.318385,0.068,0.105,-0.274,0.068,0.086615,-0.281615,0.068,1},{0,0.086615,-0.281615,0.066,0.105,-0.274,0.066,0.123385,-0.318385,0.066,1},{0,0.123385,-0.318385,0.068,0.086615,-0.281615,0.068,0.079,-0.3,0.068,1},{0,0.079,-0.3,0.066,0.086615,-0.281615,0.066,0.123385,-0.318385,0.066,1},{0,0.123385,-0.318385,0.068,0.079,-0.3,0.068,0.086615,-0.318385,0.068,1},{0,0.086615,-0.318385,0.066,0.079,-0.3,0.066,0.123385,-0.318385,0.066,1},{0,0.086615,-0.318385,0.068,0.105,-0.326,0.068,0.123385,-0.318385,0.068,1},{0,0.123385,-0.318385,0.066,0.105,-0.326,0.066,0.086615,-0.318385,0.066,1},{0,0.131,-0.3,0.066,0.123385,-0.281615,0.066,0.123385,-0.281615,0.068,1},{0,0.131,-0.3,0.066,0.123385,-0.281615,0.068,0.131,-0.3,0.068,1},{0,0.123385,-0.281615,0.066,0.105,-0.274,0.066,0.105,-0.274,0.068,1},{0,0.123385,-0.281615,0.066,0.105,-0.274,0.068,0.123385,-0.281615,0.068,1},{0,0.105,-0.274,0.066,0.086615,-0.281615,0.066,0.086615,-0.281615,0.068,1},{0,0.105,-0.274,0.066,0.086615,-0.281615,0.068,0.105,-0.274,0.068,1},{0,0.086615,-0.281615,0.066,0.079,-0.3,0.066,0.079,-0.3,0.068,1},{0,0.086615,-0.281615,0.066,0.079,-0.3,0.068,0.086615,-0.281615,0.068,1},{0,0.079,-0.3,0.066,0.086615,-0.318385,0.066,0.086615,-0.318385,0.068,1},{0,0.079,-0.3,0.066,0.086615,-0.318385,0.068,0.079,-0.3,0.068,1},{0,0.086615,-0.318385,0.066,0.105,-0.326,0.066,0.105,-0.326,0.068,1},{0,0.086615,-0.318385,0.066,0.105,-0.326,0.068,0.086615,-0.318385,0.068,1},{0,0.105,-0.326,0.066,0.123385,-0.318385,0.066,0.123385,-0.318385,0.068,1},{0,0.105,-0.326,0.066,0.123385,-0.318385,0.068,0.105,-0.326,0.068,1},{0,0.123385,-0.318385,0.066,0.131,-0.3,0.066,0.131,-0.3,0.068,1},{0,0.123385,-0.318385,0.066,0.131,-0.3,0.068,0.123385,-0.318385,0.068,1},{1,0.13682,-0.01182,0.078,0.15,0.02,0.078,0.13682,0.05182,0.078,1},{1,0.13682,0.05182,0.066,0.15,0.02,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.13682,0.05182,0.078,0.105,0.065,0.078,1},{1,0.105,0.065,0.066,0.13682,0.05182,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.105,0.065,0.078,0.07318,0.05182,0.078,1},{1,0.07318,0.05182,0.066,0.105,0.065,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.07318,0.05182,0.078,0.06,0.02,0.078,1},{1,0.06,0.02,0.066,0.07318,0.05182,0.066,0.13682,-0.01182,0.066,1},{1,0.13682,-0.01182,0.078,0.06,0.02,0.078,0.07318,-0.01182,0.078,1},{1,0.07318,-0.01182,0.066,0.06,0.02,0.066,0.13682,-0.01182,0.066,1},{1,0.07318,-0.01182,0.078,0.105,-0.025,0.078,0.13682,-0.01182,0.078,1},{1,0.13682,-0.01182,0.066,0.105,-0.025,0.066,0.07318,-0.01182,0.066,1},{1,0.15,0.02,0.066,0.13682,0.05182,0.066,0.13682,0.05182,0.078,1},{1,0.15,0.02,0.066,0.13682,0.05182,0.078,0.15,0.02,0.078,1},{1,0.13682,0.05182,0.066,0.105,0.065,0.066,0.105,0.065,0.078,1},{1,0.13682,0.05182,0.066,0.105,0.065,0.078,0.13682,0.05182,0.078,1},{1,0.105,0.065,0.066,0.07318,0.05182,0.066,0.07318,0.05182,0.078,1},{1,0.105,0.065,0.066,0.07318,0.05182,0.078,0.105,0.065,0.078,1},{1,0.07318,0.05182,0.066,0.06,0.02,0.066,0.06,0.02,0.078,1},{1,0.07318,0.05182,0.066,0.06,0.02,0.078,0.07318,0.05182,0.078,1},{1,0.06,0.02,0.066,0.07318,-0.01182,0.066,0.07318,-0.01182,0.078,1},{1,0.06,0.02,0.066,0.07318,-0.01182,0.078,0.06,0.02,0.078,1},{1,0.07318,-0.01182,0.066,0.105,-0.025,0.066,0.105,-0.025,0.078,1},{1,0.07318,-0.01182,0.066,0.105,-0.025,0.078,0.07318,-0.01182,0.078,1},{1,0.105,-0.025,0.066,0.13682,-0.01182,0.066,0.13682,-0.01182,0.078,1},{1,0.105,-0.025,0.066,0.13682,-0.01182,0.078,0.105,-0.025,0.078,1},{1,0.13682,-0.01182,0.066,0.15,0.02,0.066,0.15,0.02,0.078,1},{1,0.13682,-0.01182,0.066,0.15,0.02,0.078,0.13682,-0.01182,0.078,1}},colors={Color3.fromRGB(5,5,6),Color3.fromRGB(9,10,12),Color3.fromRGB(0,0,0),Color3.fromRGB(2,2,3),Color3.fromRGB(6,7,9)}},
    }
    function api.SkinCount() return #knifeSkins end
    function api.SkinName(index) return knifeSkins[math.clamp(math.floor(index+.5),1,#knifeSkins)].name end
    function api.DefaultGrip()
        if math.floor(settings.knifeSkin+.5)>=4 then
            return {knifeSize=.97,knifeOffsetX=-.08,knifeOffsetY=.01,knifeOffsetZ=0,
                voidglassPitch=-86,voidglassYaw=-7,voidglassRoll=83}
        end
        local realistic=math.floor(settings.knifeSkin+.5)==1
        return {knifeOffsetX=realistic and -.08 or 0,knifeOffsetY=realistic and -.03 or 0,knifeOffsetZ=0,
            voidglassPitch=90,voidglassYaw=0,voidglassRoll=realistic and 70 or -20}
    end
    function api.RestoreGrip()
        for key,value in pairs(api.DefaultGrip()) do
            settings[key]=value
            if stateRefreshers[key] then stateRefreshers[key]() end
        end
    end
    function api.Reset()
        clearFirstPerson();table.clear(authored);table.clear(authoredComponents)
        if activation then activation:Disconnect();activation=nil end
        if previewConnection then previewConnection:Disconnect();previewConnection=nil end
        if tool then tool:Destroy();tool=nil end
        started=nil;stabStarted=nil;baseGrip=nil
    end
    local function build()
        local backpack=player:FindFirstChildOfClass("Backpack")
        if not backpack then return end
        local skin=knifeSkins[math.clamp(math.floor(settings.knifeSkin+.5),1,#knifeSkins)]
        local triangles,colors=skin.triangles,skin.colors
        tool=make("Tool",{Name=skin.name,ToolTip=skin.name.." · cosmetic knife · V to inspect",CanBeDropped=false,RequiresHandle=true})
        local handle=make("Part",{Name="Handle",Size=Vector3.new(0.18,0.62,0.18),Transparency=1,
            Anchored=false,CanCollide=false,CanTouch=false,CanQuery=false,Massless=true},tool)
        local scale=0.65*settings.knifeSize
        local function point(x,y,z) return Vector3.new(x,y+0.57,z)*scale end
        local function wedge(size,frame,mat,component)
            if size.Y<0.0001 or size.Z<0.0001 then return end
            local part=make("WedgePart",{Name="VoidglassSurface",Size=size,CFrame=frame,
                Color=colors[mat+1],Material=mat==2 and Enum.Material.Neon or mat==3 and Enum.Material.SmoothPlastic or Enum.Material.Metal,
                Anchored=false,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Massless=true},tool)
            authored[part]=frame;authoredComponents[part]=component
            make("WeldConstraint",{Part0=handle,Part1=part},part)
        end
        if skin.kunaiGrip then
            local function cylinder(name,y,length,radius,mat)
                local frame=CFrame.new(point(0,y,0))*CFrame.Angles(0,0,math.pi/2)
                local part=make("Part",{Name=name,Shape=Enum.PartType.Cylinder,Size=Vector3.new(length,radius*2,radius*2)*scale,
                    CFrame=frame,Color=colors[mat+1],Material=mat==3 and Enum.Material.SmoothPlastic or Enum.Material.Metal,
                    Anchored=false,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Massless=true},tool)
                authored[part]=frame;make("WeldConstraint",{Part0=handle,Part1=part},part)
            end
            cylinder("Kunai collar",-.01,.12,.145,4)
            cylinder("Wrapped grip",-.45,.76,.11,3)
            for i=0,5 do cylinder("Grip wrap",-.7675+i*.115,.025,.115,0) end
            cylinder("Ring neck",-.88,.12,.09,4)
        end
        if skin.solidGrip then
            local function solid(name,size,offset,mat,shape,rotation)
                local frame=CFrame.new(point(offset[1],offset[2],offset[3]))*(rotation or CFrame.new())
                local part=make("Part",{Name=name,Size=size*scale,CFrame=frame,Color=colors[mat+1],
                    Material=mat==3 and Enum.Material.SmoothPlastic or Enum.Material.Metal,
                    Anchored=false,CanCollide=false,CanTouch=false,CanQuery=false,CastShadow=false,Massless=true},tool)
                if shape=="ellipsoid" then make("SpecialMesh",{MeshType=Enum.MeshType.Sphere},part)
                else part.Shape=Enum.PartType.Cylinder end
                authored[part]=frame
                make("WeldConstraint",{Part0=handle,Part1=part},part)
            end
            local cylinder=CFrame.Angles(0,0,math.pi/2)
            solid("Rounded guard",Vector3.new(.94,.13,.19),{0,-.035,0},0,"ellipsoid")
            solid("Leather grip",Vector3.new(.91,.265,.265),{0,-.565,0},3,"cylinder",cylinder)
            for i=0,5 do solid("Leather wrap",Vector3.new(.018,.275,.275),{0,-.94+i*.14,0},3,"cylinder",cylinder) end
            solid("Grip collar",Vector3.new(.075,.30,.30),{0,-.1325,0},0,"cylinder",cylinder)
            solid("Rounded pommel",Vector3.new(.31,.15,.31),{0,-1.075,0},0,"ellipsoid")
        end
        for _,row in ipairs(triangles) do
            local a,b,c=point(row[2],row[3],row[4]),point(row[5],row[6],row[7]),point(row[8],row[9],row[10])
            local ab,ac,bc=b-a,c-a,c-b
            if ab:Dot(ab)>ac:Dot(ac) and ab:Dot(ab)>bc:Dot(bc) then a,c=c,a
            elseif ac:Dot(ac)>bc:Dot(bc) then a,b=b,a end
            ab,ac,bc=b-a,c-a,c-b
            local normal=ac:Cross(ab)
            if normal.Magnitude>0.00001 and bc.Magnitude>0.00001 then
                local right=normal.Unit;local up=bc:Cross(right).Unit;local back=bc.Unit
                local height=math.abs(ab:Dot(up))
                wedge(Vector3.new(0.006,height,math.abs(ab:Dot(back))),CFrame.fromMatrix((a+b)/2,right,up,back),row[1],row[11])
                wedge(Vector3.new(0.006,height,math.abs(ac:Dot(back))),CFrame.fromMatrix((a+c)/2,-right,up,-back),row[1],row[11])
            end
        end
        baseGrip=CFrame.Angles(math.rad(settings.voidglassPitch),math.rad(settings.voidglassYaw),math.rad(settings.voidglassRoll))
        tool.Grip=baseGrip
        activation=tool.Activated:Connect(function() api.Inspect() end)
        tool.Parent=backpack
    end
    -- Hand-authored poses from the visual reference, not extracted animation data.
    local inspectKeys={
        {0,0,0,0,0,0,0}, {.16,-.025,.065,-.025,-8,-10,12},
        {.38,-.045,.09,-.035,-12,18,-18}, {.65,-.015,.045,-.015,-5,-8,10},
        {1,0,0,0,0,0,0},
    }
    local kunaiKeys={
        {0,0,0,0,0,0,0},{.23,-.025,.025,-.015,-5,6,12},
        {.42,-.035,.035,-.02,-7,12,20},{.68,-.035,.035,-.02,-7,12,20},
        {1,0,0,0,0,0,0},
    }
    local function kunaiActive() return tool and tool.Name=="KUNAI" end
    local function butterflyActive() return tool and tool.Name:find("BUTTERFLY",1,true)~=nil end
    local function inspectDuration() return butterflyActive() and 1.35 or kunaiActive() and 1.25 or .85 end
    local butterflyKeys={
        {0,0,0,0,0,0,0},{.12,.003,.004,0,2,-1.5,-3},
        {.25,-.003,.007,-.003,-2,2,4},{.40,-.006,.010,-.004,-3.5,-2,5},
        {.58,.012,.025,0,8,9,-18},{.69,-.004,.080,-.012,-27,-2,12},
        {.79,-.008,.040,-.008,-12,-5,15},{.90,.004,.018,.004,9,2,-7},
        {1,0,0,0,0,0,0},
    }
    function api.StabPhase()
        return stabStarted and math.clamp((os.clock()-stabStarted)/(stabKind=="jab" and .82 or 1.30),0,1) or nil
    end
    local stabKeys={
        {0,0,0,0,0,0,0},{.1015,.065,-.025,.14,12,-12,-14},
        {.1946,-.035,.035,-.22,-15,-4,8},{.2538,-.035,.035,-.22,-15,-4,8},
        {.61,.025,-.025,.055,7,-5,-6},{.82,.008,-.008,.015,2,-1,-2},
        {1,0,0,0,0,0,0},
    }
    local jabKeys={
        {0,0,0,0,0,0,0},{.20,.045,.13,.025,-18,6,-12},
        {.40,-.045,-.12,-.06,18,-6,14},{.50,-.035,-.075,-.035,10,-3,8},
        {.78,.012,-.012,.025,2,2,-3},{1,0,0,0,0,0,0},
    }
    function api.LeftShake()
        if not shakeStarted then return nil end
        local p=(os.clock()-shakeStarted)/.80
        if p>=1 then shakeStarted=nil;return nil end
        return p
    end
    function api.Jabbing() return stabStarted~=nil and stabKind=="jab" end
    function api.StabExtension()
        local p=api.StabPhase()
        if not p then return 0 end
        local function smooth(x) x=math.clamp(x,0,1);return x*x*(3-2*x) end
        if stabKind=="jab" then return smooth(p/.12)*(1-smooth((p-.66)/.34)) end
        return smooth((p-.1015)/.0931)*(1-smooth((p-.2538)/.2287))
    end
    function api.StabMotion()
        local t=api.StabPhase()
        if not t then return CFrame.new() end
        local keys=stabKind=="jab" and jabKeys or stabKeys
        for i=2,#keys do
            local a,b=keys[i-1],keys[i]
            if t<=b[1] then
                local u=(t-a[1])/(b[1]-a[1]);u=u*u*(3-2*u)
                local function pose(k) return CFrame.new(k[2],k[3],k[4])*CFrame.Angles(math.rad(k[5]),math.rad(k[6]),math.rad(k[7])) end
                return pose(a):Lerp(pose(b),u)
            end
        end
        return CFrame.new()
    end
    function api.Stab(kind)
        local camera=Workspace.CurrentCamera
        if not butterflyActive() or not api.Equipped() or not camera or not living(player.Character)
            or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 then return end
        if stabStarted then return end
        shakeStarted=nil;started=nil;stabKind=kind=="jab" and "jab" or "stab";stabStarted=os.clock()
    end
    function api.HandMotion()
        if stabStarted then return api.StabMotion() end
        if not started then return CFrame.new() end
        local t=math.clamp((os.clock()-started)/inspectDuration(),0,1)
        local keys=butterflyActive() and butterflyKeys or kunaiActive() and kunaiKeys or inspectKeys
        for i=2,#keys do
            local a,b=keys[i-1],keys[i]
            if t<=b[1] then
                local u=(t-a[1])/(b[1]-a[1]);u=u*u*(3-2*u)
                local function pose(k) return CFrame.new(k[2],k[3],k[4])*CFrame.Angles(math.rad(k[5]),math.rad(k[6]),math.rad(k[7])) end
                return pose(a):Lerp(pose(b),u)
            end
        end
        return CFrame.new()
    end
    function api.InspectPhase() return started and math.clamp((os.clock()-started)/inspectDuration(),0,1) or nil end
    function api.Equipped() return tool~=nil and tool.Parent==player.Character end
    function api.Inspect()
        local camera=Workspace.CurrentCamera
        if not api.Equipped() or not camera or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 then return end
        stabStarted=nil;started=os.clock()
    end
    local function firstPersonPose(camera)
        local character=player.Character
        local hand=character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
        local handle=tool and tool:FindFirstChild("Handle")
        if not hand or not handle then return end
        local palm=hand.Position
        if hand.Name=="Right Arm" then palm=(hand.CFrame*CFrame.new(0,-hand.Size.Y*.42,0)).Position end
        if settings.customArms and GripArms then palm=GripArms.RightPose(camera).Position end
        local position=palm+camera.CFrame.RightVector*.03-camera.CFrame.UpVector*.08+camera.CFrame.LookVector*.04
        local right=Vector3.new(.916515,-.4,0)
        local blade=Vector3.new(-.4,-.916515,0)
        local basis=CFrame.fromMatrix(Vector3.zero,right,blade,right:Cross(blade))
        local adjustment=CFrame.Angles(math.rad(settings.voidglassPitch-90),math.rad(settings.voidglassYaw),math.rad(settings.voidglassRoll+20))
        position=position+camera.CFrame:VectorToWorldSpace(Vector3.new(settings.knifeOffsetX,settings.knifeOffsetY,settings.knifeOffsetZ))
        local target=CFrame.new(position)*camera.CFrame.Rotation*(settings.customArms and JumpMotion and JumpMotion.Frame().Rotation or CFrame.new())*api.HandMotion().Rotation*basis*adjustment*inspectPose
        if stabStarted then
            local blade=Vector3.new(-.20,.32,-.93).Unit
            if stabKind=="jab" then
                -- Forward grip: blade exits above thumb/index, never below the fist.
                local sweep=math.clamp((api.StabPhase()-.16)/.48,0,1)
                local start=Vector3.new(.35,.80,-.48)
                local finish=Vector3.new(-.83,.20,-.51)
                blade=start:Lerp(finish,sweep).Unit
            end
            local across=Vector3.new(blade.Y,-blade.X,0).Unit
            local stabBasis=CFrame.fromMatrix(Vector3.zero,across,blade,across:Cross(blade))
            local stabFrame=CFrame.new(position)*camera.CFrame.Rotation*stabBasis
            if stabKind=="jab" then
                local sweep=math.clamp((api.StabPhase()-.16)/.48,0,1)
                stabFrame=stabFrame*CFrame.Angles(0,math.rad(-18+12*sweep),0)
            end
            target=target:Lerp(stabFrame,api.StabExtension())
            -- Palm roll: rotate about the handle's longitudinal axis. Its centreline
            -- stays fixed in the grip instead of orbiting around an end-over-end pivot.
            local recovery=stabKind=="jab" and 0 or math.clamp((api.StabPhase()-.3235)/.6565,0,1)
            -- Monotone fast/slow/fast roll, with gentle endpoints.
            local paced=recovery+.72*math.sin(2*math.pi*recovery)/(2*math.pi)
            local turn=paced*paced*(3-2*paced)
            local away=math.sin(math.pi*math.clamp(recovery/.65,0,1))^2
            target=target*CFrame.Angles(math.rad(-14)*away,0,0)*CFrame.Angles(0,math.pi*turn,0)
        end
        -- Retain the resulting face after a completed half-turn.
        target=target*CFrame.Angles(0,palmRoll,0)
        if not viewModel then
            viewModel=make("Model",{Name="StarfireKnifeFirstPersonVisual"},effects)
            for source,relative in pairs(authored) do
                if source.Parent then
                    local copy=source:Clone()
                    -- The viewmodel has no joints to the Tool or character.
                    for _,child in ipairs(copy:GetChildren()) do if not child:IsA("DataModelMesh") then child:Destroy() end end
                    copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false
                    copy.Massless=true;copy.LocalTransparencyModifier=0;copy.Parent=viewModel
                    copy.Size=source.Size*.48
                    if WireStyle then
                        local component=authoredComponents[source] or 0
                        if not viewWireGroups[component] then viewWireGroups[component]={} end
                        WireStyle.Register(copy,"knife",viewWireGroups[component])
                    end
                    viewCopies[copy]=CFrame.new(relative.Position*.48)*relative.Rotation
                    viewComponents[copy]=authoredComponents[source]
                    viewHidden[source]=source.LocalTransparencyModifier
                end
            end
        end
        for source in pairs(viewHidden) do if source.Parent then source.LocalTransparencyModifier=1 end end
        for copy,relative in pairs(viewCopies) do
            copy.LocalTransparencyModifier=BunnyHop and BunnyHop.GesturePhase() and 1 or 0
            local component=viewComponents[copy]
            if butterflyActive() and component and component~=0 and started then
                local phase=math.clamp((os.clock()-started)/inspectDuration(),0,1)
                local keys={{0,0},{.16,95},{.34,185},{.52,350},{.73,350},{.83,185},{.94,0},{1,0}}
                local angle=0
                for i=2,#keys do
                    local a,b=keys[i-1],keys[i]
                    if phase<=b[1] then local u=(phase-a[1])/(b[1]-a[1]);u=u*u*(3-2*u);angle=a[2]+(b[2]-a[2])*u;break end
                end
                if component==-1 then angle=-angle*.12 end
                local hinge=CFrame.new(component*.10*.65*settings.knifeSize*.48,.59*.65*settings.knifeSize*.48,0)
                relative=hinge*CFrame.Angles(0,0,math.rad(angle))*hinge:Inverse()*relative
            end
            copy.CFrame=target*relative
        end
    end
    function api.Step()
        if not settings.voidglassInventory then if tool then api.Reset() end;return end
        local backpack=player:FindFirstChildOfClass("Backpack")
        if tool and tool.Parent~=backpack and tool.Parent~=player.Character then api.Reset() end
        if not tool then build() end
        if not tool then return end
        baseGrip=CFrame.Angles(math.rad(settings.voidglassPitch),math.rad(settings.voidglassYaw),math.rad(settings.voidglassRoll))
        local camera=Workspace.CurrentCamera
        if not api.Equipped() or not camera or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 then
            started=nil;stabStarted=nil;tool.Grip=baseGrip;clearFirstPerson();return
        end
        tool.Grip=baseGrip
        if stabStarted then
            local phase=api.StabPhase()
            if phase>=1 then
                if stabKind=="jab" then shakeStarted=os.clock()
                else palmRoll=(palmRoll+math.pi)%(2*math.pi) end
                stabStarted=nil;inspectPose=CFrame.new()
            else
                local wind=math.clamp(phase/.22,0,1)*(1-math.clamp((phase-.48)/.40,0,1))
                inspectPose=CFrame.Angles(math.rad(65)*wind,math.rad(-12)*wind,0)
            end
            firstPersonPose(camera);return
        end
        if not started then inspectPose=CFrame.new();firstPersonPose(camera);return end
        local t=(os.clock()-started)/inspectDuration()
        if t>=1 then started=nil;inspectPose=CFrame.new();firstPersonPose(camera);return end
        -- A single quick finger-pivot twirl; pressing V resets started immediately.
        local realistic=tool and tool.Name=="REALISTIC DAGGER"
        local spin=realistic and math.clamp(t/.8,0,1) or math.clamp((t-.08)/.72,0,1)
        if not realistic then spin=spin*spin*(3-2*spin) end
        if butterflyActive() then
            local earlyBlend=math.clamp((t-.40)/.14,0,1)
            local earlyWeight=.2+.8*earlyBlend*earlyBlend*(3-2*earlyBlend)
            local lift=math.sin(math.pi*t)*earlyWeight
            local finalFlick=math.sin(math.pi*math.clamp((t-.59)/.22,0,1))^2
            inspectPose=CFrame.Angles(math.rad(-10)*lift-math.rad(16)*finalFlick,math.rad(18)*math.sin(t*math.pi*2)*earlyWeight,math.rad(24)*math.sin(t*math.pi*2)*earlyWeight)
        elseif kunaiActive() then
            -- Controlled blade presentation; no toss or finger transfer.
            local keys={
                {0,0,0,0,0,0,0},{.25,0,.008,0,-4,25,12},
                {.42,0,.012,0,-7,48,22},{.68,0,.012,0,-7,48,22},
                {1,0,0,0,0,0,0},
            }
            inspectPose=CFrame.new()
            for i=2,#keys do
                local a,b=keys[i-1],keys[i]
                if t<=b[1] then
                    local u=math.clamp((t-a[1])/(b[1]-a[1]),0,1);u=u*u*(3-2*u)
                    local function pose(k) return CFrame.new(k[2],k[3],k[4])*CFrame.Angles(math.rad(k[5]),math.rad(k[6]),math.rad(k[7])) end
                    inspectPose=pose(a):Lerp(pose(b),u);break
                end
            end
        else
            inspectPose=CFrame.Angles(0,math.rad(12)*math.sin(t*math.pi),-2*math.pi*spin)
        end
        firstPersonPose(camera)
    end
    return api
end)()
slider(UIRefs.skinsPage,"Knife skin","knifeSkin",1,Voidglass.SkinCount(),function(v) return Voidglass.SkinName(v) end,function(v)
    local selected=math.floor(v+.5)
    if Voidglass._selectedSkin~=selected then Voidglass._selectedSkin=selected;Voidglass.RestoreGrip();Voidglass.Reset() end
end)
stateAppliers.knifeSkin=function(v)
    settings.knifeSkin=math.clamp(math.floor(v+.5),1,Voidglass.SkinCount())
    Voidglass._selectedSkin=settings.knifeSkin;Voidglass.Reset()
    if stateRefreshers.knifeSkin then stateRefreshers.knifeSkin() end
end
toggle(UIRefs.skinsPage,"Cosmetic inventory knife","voidglassInventory",function(enabled)
    if not enabled then Voidglass.Reset() else Voidglass.Step() end
end)
button(UIRefs.skinsPage,"Inspect knife · equip then V",function() Voidglass.Inspect() end)
slider(UIRefs.skinsPage,"Knife size","knifeSize",.5,1.75,function(v) return string.format("%.2fx",v) end,function() Voidglass.Reset() end)
stateAppliers.knifeSize=function(v)
    settings.knifeSize=math.clamp(v,.5,1.75);Voidglass.Reset()
    if stateRefreshers.knifeSize then stateRefreshers.knifeSize() end
end
for _,entry in ipairs({{"Left / right","knifeOffsetX"},{"Up / down","knifeOffsetY"},{"Forward / back","knifeOffsetZ"}}) do
    slider(UIRefs.skinsPage,"Knife position · "..entry[1],entry[2],-.6,.6,function(v) return string.format("%.2f",v) end)
end
button(UIRefs.skinsPage,"Reset knife position",function()
    local defaults=Voidglass.DefaultGrip()
    for key,value in pairs(defaults) do
        settings[key]=value
        if stateRefreshers[key] then stateRefreshers[key]() end
    end
    Voidglass.Reset()
end)
for _,axis in ipairs({"Pitch","Yaw","Roll"}) do
    slider(UIRefs.skinsPage,"Knife grip "..axis,"voidglass"..axis,-180,180,function(v) return string.format("%.0f°",v) end)
end


Inspect = (function()
    local api, state = {}, nil
    function api.Reset()
        local old=state;state=nil
        if not old then return end
        if old.connection then old.connection:Disconnect() end
        for part,value in pairs(old.hidden) do if part.Parent then part.LocalTransparencyModifier=value end end
        if old.model then old.model:Destroy() end
    end
    local function pose(base,arms)
        if not state then return base end
        local t=math.clamp((os.clock()-state.start)/1.15,0,1)
        local function smooth(x) x=math.clamp(x,0,1);return x*x*(3-2*x) end
        local lift=smooth(t/0.18)*(1-smooth((t-0.76)/0.24))
        local spin=smooth((t-0.18)/0.54)*math.pi*2
        local camera=Workspace.CurrentCamera
        local held=CFrame.new(camera.CFrame:VectorToWorldSpace(Vector3.new(-0.04,0.10,0.04))*lift)
            *base*CFrame.Angles(math.rad(-8)*lift,0,math.rad(-5)*lift)
        if arms then
            return held*CFrame.Angles(math.rad(-5)*math.sin(spin),0,0)
        end
        -- Single forward revolver twirl about the trigger/finger area, in the camera's side plane.
        local pivot=(held*CFrame.new(0,0.12,-0.12)).Position
        return CFrame.new(pivot)*CFrame.fromAxisAngle(camera.CFrame.RightVector,-spin)*CFrame.new(-pivot)*held
    end
    function api.Phase() return state and math.clamp((os.clock()-state.start)/1.15,0,1) or nil end
    function api.Transform(base) return pose(base,false) end
    function api.GripFrame(base) return pose(base,true) end
    function api.TransformArm(base)
        if not state then return base end
        local anchor=state.handle.CFrame
        return pose(anchor,true)*anchor:ToObjectSpace(base)
    end
    function api.Start()
        if Voidglass and Voidglass.Equipped() then Voidglass.Inspect();return end
        if state then state.start=os.clock();return end
        local camera,character=Workspace.CurrentCamera,player.Character
        local tool=character and character:FindFirstChild("Gun")
        local handle=tool and tool:FindFirstChild("Handle")
        if not camera or not living(character) or not handle or not handle:IsA("BasePart")
            or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 then return end
        local custom=(settings.customArms and GunViewmodel~=nil) or (Skins and Skins.HasModel and Skins.HasModel() and settings.skinKind=="Gun" and settings.skinChanger)
        local current={start=os.clock(),tool=tool,handle=handle,hidden={},copies={},custom=custom}
        if not custom then
            current.model=make("Model",{Name="StarfireGunInspect"})
            for _,source in ipairs(tool:GetDescendants()) do
                if source:IsA("BasePart") then
                    local copy=source:Clone()
                    if copy then
                        for _,child in ipairs(copy:GetChildren()) do
                            if not (child:IsA("SpecialMesh") or child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy() end
                        end
                        copy.Anchored=true;copy.CanCollide=false;copy.CanTouch=false;copy.CanQuery=false;copy.LocalTransparencyModifier=0
                        copy.Parent=current.model
                        current.copies[copy]=handle.CFrame:ToObjectSpace(source.CFrame)
                        current.hidden[source]=source.LocalTransparencyModifier
                    end
                end
            end
            current.model.Parent=effects
        end
        state=current
        current.connection=tool.Activated:Connect(function() api.Reset() end)
    end
    function api.Step()
        if not state then return end
        local camera=Workspace.CurrentCamera
        if not living(player.Character) or state.tool.Parent~=player.Character or not camera
            or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 or os.clock()-state.start>=1.15
            or (UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then api.Reset();return end
        for source in pairs(state.hidden) do if source.Parent then source.LocalTransparencyModifier=1 end end
        local target=api.Transform(state.handle.CFrame)
        for copy,relative in pairs(state.copies) do copy.CFrame=target*relative end
    end
    return api
end)()
connect(UIS.InputBegan,function(input,processed)
    if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.V then Inspect.Start() end
end)
connect(UIS.InputBegan,function(input,processed)
    if not processed and not UIS:GetFocusedTextBox() and not menuOpen then
        if input.UserInputType==Enum.UserInputType.MouseButton2 then Voidglass.Stab()
        elseif input.UserInputType==Enum.UserInputType.MouseButton1 then Voidglass.Stab("jab") end
    end
end)
button(UIRefs.skinsPage,"Single revolver spin · V",function() Inspect.Start() end)

BunnyHop = (function()
    local api, character, humanoid, root, connection = {}, nil, nil, nil, nil
    local originalSpeed, momentum, landedAt, wasAirborne, trail, attachment0, attachment1 = nil, 0, nil, false, nil, nil, nil
    local segments, guide = {}, nil
    local trailAnchor,trailForward=nil,Vector3.new(0,0,-1)
    local gestureStarted
    function api.StartGesture() gestureStarted=os.clock() end
    function api.GesturePhase()
        if not settings.bunnyHop or not gestureStarted then return nil end
        local t=(os.clock()-gestureStarted)/1.05
        return t<1 and t or nil
    end
    local function clearVisuals()
        if guide then guide:Destroy();guide=nil end
        if trail then trail:Destroy();trail=nil end
        if attachment0 then attachment0:Destroy();attachment0=nil end
        if attachment1 then attachment1:Destroy();attachment1=nil end
        trailAnchor=nil;trailForward=Vector3.new(0,0,-1)
        table.clear(segments)
    end
    function api.Reset()
        if connection then connection:Disconnect();connection=nil end
        if humanoid and humanoid.Parent and originalSpeed then humanoid.WalkSpeed=originalSpeed end
        character,humanoid,root,originalSpeed,momentum,landedAt,wasAirborne=nil,nil,nil,nil,0,nil,false
        clearVisuals()
    end
    local function paused()
        return settings.fly or sweepState~=nil or (Evade and Evade.Busy()) or (Fling and Fling.Busy())
            or (Scare and Scare.Busy()) or (Automation and Automation.Busy()) or settings.coinCollect
    end
    local function bind(current)
        api.Reset();character=current;humanoid=current:FindFirstChildOfClass("Humanoid");root=current:FindFirstChild("HumanoidRootPart")
        originalSpeed=humanoid.WalkSpeed
        connection=humanoid.StateChanged:Connect(function(_,state)
            if state==Enum.HumanoidStateType.Landed then landedAt=os.clock();wasAirborne=false end
            if state~=Enum.HumanoidStateType.Jumping or not settings.bunnyHop or paused() then return end
            if humanoid.MoveDirection.Magnitude<0.1 then momentum=0;return end
            local base=settings.speedEnabled and settings.walkSpeed or originalSpeed
            if landedAt and os.clock()-landedAt<=0.3 then momentum=math.min(math.max(momentum,base)+settings.bunnyGain,math.max(settings.bunnyMax,base))
            else momentum=math.min(base,math.max(settings.bunnyMax,base)) end
            local velocity=root.AssemblyLinearVelocity
            local direction=humanoid.MoveDirection.Unit
            root.AssemblyLinearVelocity=Vector3.new(direction.X*momentum,velocity.Y,direction.Z*momentum)
            landedAt=nil;wasAirborne=true
        end)
    end
    function api.Step()
        if not (settings.bunnyHop or settings.jumpTrajectory) or not living(player.Character) or paused() then
            if character then api.Reset() end;return
        end
        if player.Character~=character then bind(player.Character) end
        local grounded=humanoid.FloorMaterial~=Enum.Material.Air
        if settings.bunnyHop then
            local base=settings.speedEnabled and settings.walkSpeed or originalSpeed
            if grounded and landedAt and os.clock()-landedAt>0.3 then momentum=0 end
            if humanoid.MoveDirection.Magnitude<0.1 and grounded then momentum=0 end
            humanoid.WalkSpeed=math.max(base,momentum)
            if grounded and UIS:IsKeyDown(Enum.KeyCode.Space) and not UIS:GetFocusedTextBox() then humanoid.Jump=true end
        end
        if not settings.jumpTrajectory then if guide or trail then clearVisuals() end;return end
        local color=Color3.fromRGB(settings.tracerRed,settings.tracerGreen,settings.tracerBlue)
        if not guide then
            guide=make("Folder",{Name="StarfireJumpTrajectory"},effects)
            trailAnchor=make("Part",{Name="JumpTrailMotionAnchor",Anchored=true,CanCollide=false,CanTouch=false,
                CanQuery=false,CastShadow=false,Transparency=1,Size=Vector3.new(.1,.1,.1)},guide)
            attachment0=make("Attachment",{Position=Vector3.new(-.07,0,0)},trailAnchor)
            attachment1=make("Attachment",{Position=Vector3.new(.07,0,0)},trailAnchor)
            trail=make("Trail",{Name="StarfireActualJumpTrail",Attachment0=attachment0,Attachment1=attachment1,
                FaceCamera=true,MinLength=0.05,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0.15),NumberSequenceKeypoint.new(1,1)})},guide)
        end
        -- Translation follows the character; heading follows travel, never avatar spin.
        local velocity=root.AssemblyLinearVelocity
        local horizontal=Vector3.new(velocity.X,0,velocity.Z)
        if horizontal.Magnitude>1 then trailForward=horizontal.Unit end
        local position=root.Position-Vector3.new(0,2,0)-trailForward*.55
        trailAnchor.CFrame=CFrame.lookAt(position,position+trailForward)
        trail.Color=ColorSequence.new(color);trail.Lifetime=settings.jumpTrailLife;trail.Enabled=not grounded

    end
    return api
end)()
toggle(UIRefs.movementPage,"Bunny hop · E toggle / hold Space","bunnyHop",function() BunnyHop.Reset() end)
connect(UIS.InputBegan,function(input,processed)
    if processed or UIS:GetFocusedTextBox() or input.KeyCode~=Enum.KeyCode.E then return end
    stateAppliers.bunnyHop(not settings.bunnyHop)
    if settings.bunnyHop then
        if stateAppliers.customArms then stateAppliers.customArms(true) end
        BunnyHop.StartGesture()
    end
end)
slider(UIRefs.movementPage,"Momentum gain per hop","bunnyGain",1,15,function(v) return string.format("%.0f studs/s",v) end)
slider(UIRefs.movementPage,"Bunny hop speed cap","bunnyMax",20,150,function(v) return string.format("%.0f studs/s",v) end)
toggle(UIRefs.movementPage,"Actual jump trail · no prediction","jumpTrajectory",function() BunnyHop.Reset() end)
slider(UIRefs.movementPage,"Jump trail lifetime","jumpTrailLife",0.5,6,function(v) return string.format("%.1f s",v) end)

Glossy = (function()
    local api, originals, queue, queued = {}, {}, {}, {}
    local snapshot, bloom, cursor, signature = nil, nil, 1, nil
    local Lighting=game:GetService("Lighting")
    local function enqueue(part)
        if not part:IsA("BasePart") or queued[part] or part:IsDescendantOf(effects) then return end
        if not part.Anchored or part.Transparency>0.1 then return end
        local ancestor=part.Parent
        while ancestor and ancestor~=Workspace do
            if ancestor:IsA("Tool") or (ancestor:IsA("Model") and ancestor:FindFirstChildOfClass("Humanoid")) then return end
            ancestor=ancestor.Parent
        end
        queued[part]=true;table.insert(queue,part)
    end
    function api.Reset()
        for part,original in pairs(originals) do
            if part.Parent then part.Material=original.material;part.Reflectance=original.reflectance end
        end
        table.clear(originals);table.clear(queue);table.clear(queued);cursor=1;signature=nil
        if bloom then bloom:Destroy();bloom=nil end
        if snapshot then
            Lighting.EnvironmentSpecularScale=snapshot.specular
            Lighting.EnvironmentDiffuseScale=snapshot.diffuse
            snapshot=nil
        end
    end
    function api.Start()
        if PShade and settings.pshade then settings.pshade=false;PShade.Reset();if stateRefreshers.pshade then stateRefreshers.pshade() end end
        api.Reset()
        if not settings.glossyShaders then return end
        snapshot={specular=Lighting.EnvironmentSpecularScale,diffuse=Lighting.EnvironmentDiffuseScale}
        bloom=make("BloomEffect",{Name="StarfireGlossyBloom",Threshold=1.1,Size=32},Lighting)
        for _,object in ipairs(Workspace:GetDescendants()) do enqueue(object) end
    end
    connect(Workspace.DescendantAdded,function(object)
        if settings.glossyShaders and snapshot then enqueue(object) end
    end)
    function api.Step()
        if not settings.glossyShaders then if snapshot then api.Reset() end;return end
        if not snapshot then api.Start() end
        Lighting.EnvironmentSpecularScale=settings.glossySpecular
        Lighting.EnvironmentDiffuseScale=math.max(snapshot.diffuse,0.45)
        bloom.Intensity=settings.glossyBloom
        local nextSignature=tostring(settings.glossyPlastic)..":"..tostring(settings.glossyReflectance)
        if signature~=nextSignature then
            signature=nextSignature
            for part in pairs(originals) do enqueue(part) end
        end
        local stop=math.min(#queue,cursor+149)
        for i=cursor,stop do
            local part=queue[i];queued[part]=nil
            if part:IsDescendantOf(Workspace) then
                if not originals[part] then originals[part]={material=part.Material,reflectance=part.Reflectance} end
                part.Material=originals[part].material
                part.Reflectance=settings.glossyReflectance
            end
        end
        cursor=stop+1
        if cursor>#queue then table.clear(queue);cursor=1 end
    end
    return api
end)()
toggle(UIRefs.ambiencePage,"Glossy shaders · local preset","glossyShaders",function() Glossy.Start() end)
slider(UIRefs.ambiencePage,"Surface shine","glossyReflectance",0,0.95,function(v) return string.format("%.0f%%",v*100) end)
slider(UIRefs.ambiencePage,"Environment highlights","glossySpecular",0,1,function(v) return string.format("%.0f%%",v*100) end)
slider(UIRefs.ambiencePage,"Glossy bloom","glossyBloom",0,1.5,function(v) return string.format("%.2f",v) end)
button(UIRefs.ambiencePage,"Extra glossy · keep textures",function()
    settings.glossyShaders=true;settings.glossyPlastic=false;settings.glossyReflectance=0.8
    settings.glossySpecular=1;settings.glossyBloom=0.65
    for _,key in ipairs({"glossyShaders","glossyPlastic","glossyReflectance","glossySpecular","glossyBloom"}) do
        if stateRefreshers[key] then stateRefreshers[key]() end
    end
    Glossy.Start()
end)

-- Native Roblox lighting presets; these do not install external shaders.
for _,preset in ipairs({
    {name="Shader preset · clear daylight",time=14,brightness=2.2,exposure=0.1,density=0.12,haze=0.4,contrast=0.12,saturation=0.08,bloom=0.18,shine=0.3},
    {name="Shader preset · violet night",time=0,brightness=1.5,exposure=0.15,density=0.22,haze=1,contrast=0.15,saturation=0.12,bloom=0.3,shine=0.45},
    {name="Shader preset · cinematic sunset",time=17.6,brightness=2,exposure=0,density=0.18,haze=1.3,contrast=0.2,saturation=-0.05,bloom=0.22,shine=0.25}
}) do
    button(UIRefs.ambiencePage,preset.name,function()
        local values={ambience=true,glossyShaders=true,glossyPlastic=false,
            ambienceTime=preset.time,ambienceBrightness=preset.brightness,ambienceExposure=preset.exposure,
            ambienceFog=false,ambienceAtmosphere=true,ambienceDensity=preset.density,ambienceHaze=preset.haze,
            ambienceGrade=true,ambienceContrast=preset.contrast,ambienceSaturation=preset.saturation,
            ambienceBloom=false,glossyBloom=preset.bloom,glossyReflectance=preset.shine,glossySpecular=1,
            ambienceSunRays=true,ambienceRayIntensity=0.06,ambienceDepth=false}
        for key,value in pairs(values) do
            settings[key]=value
            if stateRefreshers[key] then stateRefreshers[key]() end
        end
        Ambience.Step();Glossy.Start()
        notify(preset.name .. " applied locally")
    end)
end

Ambience = (function()
    local api, snapshot, originalSky, originalSkyParent, originalAtmosphere, originalAtmosphereParent = {}, nil, nil, nil, nil, nil
    local owned = {}
    local Lighting = game:GetService("Lighting")
    local properties={"ClockTime","Brightness","ExposureCompensation","FogStart","FogEnd","FogColor","Ambient","OutdoorAmbient"}
    function api.Reset()
        for _,object in pairs(owned) do object:Destroy() end
        table.clear(owned)
        if snapshot then for key,value in pairs(snapshot) do Lighting[key]=value end end
        if originalSky then originalSky.Parent=originalSkyParent end
        if originalAtmosphere then originalAtmosphere.Parent=originalAtmosphereParent end
        snapshot,originalSky,originalSkyParent,originalAtmosphere,originalAtmosphereParent=nil,nil,nil,nil,nil
    end
    local function start()
        snapshot={}
        for _,key in ipairs(properties) do snapshot[key]=Lighting[key] end
        originalSky=Lighting:FindFirstChildOfClass("Sky")
        if originalSky then originalSkyParent=originalSky.Parent end
        originalAtmosphere=Lighting:FindFirstChildOfClass("Atmosphere")
        if originalAtmosphere then originalAtmosphereParent=originalAtmosphere.Parent;originalAtmosphere.Parent=nil end
        owned.sky=originalSky and originalSky:Clone() or Instance.new("Sky")
        owned.sky.Name="StarfireSky";owned.sky.Parent=Lighting
        if originalSky then originalSky.Parent=nil end
        owned.atmosphere=make("Atmosphere",{Name="StarfireAtmosphere"})
        owned.bloom=make("BloomEffect",{Name="StarfireBloom",Threshold=1,Size=24},Lighting)
        owned.grade=make("ColorCorrectionEffect",{Name="StarfireColourGrade"},Lighting)
        owned.rays=make("SunRaysEffect",{Name="StarfireSunRays",Spread=0.8},Lighting)
        owned.depth=make("DepthOfFieldEffect",{Name="StarfireDepthOfField",NearIntensity=0,InFocusRadius=25},Lighting)
    end
    function api.Step()
        if not settings.ambience then if snapshot then api.Reset() end;return end
        if not snapshot then start() end
        local tint=Color3.fromRGB(settings.ambienceRed,settings.ambienceGreen,settings.ambienceBlue)
        Lighting.ClockTime=settings.ambienceTime
        Lighting.Brightness=settings.ambienceBrightness
        Lighting.ExposureCompensation=settings.ambienceExposure
        Lighting.FogStart=settings.ambienceFog and settings.ambienceFogStart or snapshot.FogStart
        Lighting.FogEnd=settings.ambienceFog and math.max(settings.ambienceFogEnd,settings.ambienceFogStart+1) or snapshot.FogEnd
        Lighting.FogColor=settings.ambienceFog and tint or snapshot.FogColor
        Lighting.Ambient=Color3.fromRGB(65,65,75):Lerp(tint,0.15)
        Lighting.OutdoorAmbient=Color3.fromRGB(100,100,110):Lerp(tint,0.15)
        -- Classic fog and Atmosphere are separate modes; Atmosphere otherwise suppresses classic fog.
        owned.atmosphere.Parent=settings.ambienceAtmosphere and not settings.ambienceFog and Lighting or nil
        owned.atmosphere.Color=tint
        owned.atmosphere.Decay=tint:Lerp(Color3.new(0,0,0),0.65)
        owned.atmosphere.Density=settings.ambienceDensity
        owned.atmosphere.Haze=settings.ambienceHaze
        owned.sky.StarCount=math.floor(settings.ambienceStars)
        owned.sky.CelestialBodiesShown=settings.ambienceCelestial
        owned.bloom.Enabled=settings.ambienceBloom;owned.bloom.Intensity=settings.ambienceBloomIntensity
        owned.grade.Enabled=settings.ambienceGrade
        owned.grade.TintColor=Color3.new(1,1,1):Lerp(tint,0.12)
        owned.grade.Saturation=settings.ambienceSaturation;owned.grade.Contrast=settings.ambienceContrast
        owned.rays.Enabled=settings.ambienceSunRays;owned.rays.Intensity=settings.ambienceRayIntensity
        owned.depth.Enabled=settings.ambienceDepth
        owned.depth.FocusDistance=settings.ambienceFocus;owned.depth.FarIntensity=settings.ambienceFarBlur
    end
    return api
end)()
toggle(UIRefs.ambiencePage,"Enable local ambience","ambience",function(enabled)
    if enabled then
        if PShade then settings.pshade=false;PShade.Reset();if stateRefreshers.pshade then stateRefreshers.pshade() end end
        Ambience.Step()
    else Ambience.Reset() end
end)
button(UIRefs.ambiencePage,"Restore game lighting",function()
    settings.ambience=false;settings.glossyShaders=false;settings.pshade=false;if PShade then PShade.Reset() end;if stateRefreshers.pshade then stateRefreshers.pshade() end;Glossy.Reset();Ambience.Reset();stateRefreshers.ambience();stateRefreshers.glossyShaders()
end)
for _,preset in ipairs({{"Violet dusk",18,0.25,450,2},{"Clear daylight",13,0.1,1600,2.5},{"Midnight",0,0.3,350,1},{"Heavy mist",7,0.5,130,1.5}}) do
    button(UIRefs.ambiencePage,preset[1],function()
        settings.ambienceTime=preset[2];settings.ambienceDensity=preset[3]
        settings.ambienceFogEnd=preset[4];settings.ambienceBrightness=preset[5]
        settings.ambience=true
        for _,key in ipairs({"ambience","ambienceTime","ambienceDensity","ambienceFogEnd","ambienceBrightness"}) do
            if stateRefreshers[key] then stateRefreshers[key]() end
        end
        Ambience.Step()
    end)
end
for _,control in ipairs({
    {"Time of day","ambienceTime",0,24},{"Brightness","ambienceBrightness",0,5},{"Exposure","ambienceExposure",-2,2},
    {"Fog starts","ambienceFogStart",0,500},{"Fog ends","ambienceFogEnd",50,3000},
    {"Atmosphere density","ambienceDensity",0,0.8},{"Atmosphere haze","ambienceHaze",0,5},
    {"Bloom strength","ambienceBloomIntensity",0,2},{"Saturation","ambienceSaturation",-1,1},
    {"Contrast","ambienceContrast",-0.5,0.5},{"Sun ray strength","ambienceRayIntensity",0,0.3},
    {"Focus distance","ambienceFocus",5,150},{"Distant blur","ambienceFarBlur",0,0.5},{"Sky stars","ambienceStars",0,5000}
}) do
    slider(UIRefs.ambiencePage,control[1],control[2],control[3],control[4],function(v) return string.format("%.2f",v) end)
end
for _,control in ipairs({{"Classic fog · takes priority","ambienceFog"},{"Atmosphere · disable classic fog first","ambienceAtmosphere"},
    {"Bloom","ambienceBloom"},{"Colour grading","ambienceGrade"},{"Sun rays","ambienceSunRays"},
    {"Depth of field","ambienceDepth"},{"Sun and moon","ambienceCelestial"}}) do
    toggle(UIRefs.ambiencePage,control[1],control[2])
end
UIRefs.ColourPicker(UIRefs.ambiencePage,"Ambience colour",{"ambienceRed","ambienceGreen","ambienceBlue"})

-- Visual settings adapted from PShade Ultimate 1.4.9, @Im_patrick / randomstring0.
-- Presets are bundled data; no remote script execution, feedback, blacklist, or hidden-property calls.
PShade = (function()
local presets={["morning"]={["fhnchvhfjsd"]=-0.02,["ugtbbjhygt"]=0.8,["tfbghuugbnjhg"]=-0.5,["fvrtccvghghj"]=Color3.fromRGB(100,150,200),["jnfdhbnfcvh"]=0.2,["fvtyghj"]=5,["ygbhnj"]=0.8,["njnfg"]=2,["yfbghj"]=Color3.fromRGB(10,10,10),["tgvbyd"]=7.5,["ghuybhuyhj"]=44,["khnbfth"]=1.5,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(200,200,200),["ygyyfgvhbjytrt"]=0.1,["sdfcddc"]=0.1,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(10,10,10),["hdfr7thgr"]=0.3,["gyhgtg"]=0.6,["ygbhggv"]=0.36,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.2,["skdjfkdm"]=0.5,["sjdjncdjf"]=Color3.fromRGB(70,120,170),["efjdjfk"]=Color3.fromRGB(10,50,100),["sejfd"]=0.3,["jddfjsd"]=1,["jdfkd"]=0.5,["fvgsdfg"]=15,["sdkvkflv"]=5,["hbjhd"]=0.5},["midday"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=8,["ghuybhuyhj"]=-15.12,["khnbfth"]=3.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.85,["gyhgtg"]=0.75,["ygbhggv"]=0.26,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.277,["fvgsdfg"]=21.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["afternoon"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.312,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.31234,["fvtyghj"]=10,["ygbhnj"]=0.843,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=14,["ghuybhuyhj"]=-15.12,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.85,["gyhgtg"]=0.45,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=21.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["evening"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(255, 205, 185),["jnfdhbnfcvh"]=0.3234,["fvtyghj"]=10,["ygbhnj"]=0.813,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=16,["ghuybhuyhj"]=45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.215,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.65,["gyhgtg"]=0.55,["ygbhggv"]=0.43,["jghbjhgyfd"]=Color3.fromRGB(199,175,166),["shdbsnjfc"]=0.364,["skdjfkdm"]=5.556,["sjdjncdjf"]=Color3.fromRGB(199,175,166),["efjdjfk"]=Color3.fromRGB(44,39,33),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=21.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["night"]={["fhnchvhfjsd"]=-0.06,["ugtbbjhygt"]=-0.02,["tfbghuugbnjhg"]=-0.2,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.34,["fvtyghj"]=10,["ygbhnj"]=0.813,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=20,["ghuybhuyhj"]=-15,["khnbfth"]=3.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.85,["gyhgtg"]=0.65,["ygbhggv"]=0.33,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.264,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["midnight"]={["fhnchvhfjsd"]=-0.1,["ugtbbjhygt"]=-0.05,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.1,["fvtyghj"]=10,["ygbhnj"]=0.81,["njnfg"]=6,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=0,["ghuybhuyhj"]=-0,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.15,["gyhgtg"]=0.75,["ygbhggv"]=0.33,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.264,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.16,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["morninglite"]={["fhnchvhfjsd"]=-0.02,["ugtbbjhygt"]=0.4,["tfbghuugbnjhg"]=-0.5,["fvrtccvghghj"]=Color3.fromRGB(100,150,200),["jnfdhbnfcvh"]=0.135,["fvtyghj"]=3,["ygbhnj"]=0.452,["njnfg"]=1.45654,["yfbghj"]=Color3.fromRGB(10,10,10),["tgvbyd"]=7.5,["ghuybhuyhj"]=34,["khnbfth"]=1.5,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(200,200,200),["ygyyfgvhbjytrt"]=0.1,["sdfcddc"]=0.1,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(10,10,10),["hdfr7thgr"]=0.3,["gyhgtg"]=0.134,["ygbhggv"]=0.36,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.2,["skdjfkdm"]=0.5,["sjdjncdjf"]=Color3.fromRGB(70,120,170),["efjdjfk"]=Color3.fromRGB(10,50,100),["sejfd"]=0.154,["jddfjsd"]=0.3456,["jdfkd"]=0.5,["fvgsdfg"]=15,["sdkvkflv"]=5,["hbjhd"]=0.5},["middaylite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.15,["tfbghuugbnjhg"]=-0.1543,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.276,["fvtyghj"]=7,["ygbhnj"]=0.456,["njnfg"]=2,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=8,["ghuybhuyhj"]=-15.12,["khnbfth"]=3.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.85,["gyhgtg"]=0.75,["ygbhggv"]=0.26,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.264,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.26,["jddfjsd"]=0.72,["jdfkd"]=0.277,["fvgsdfg"]=2.54,["sdkvkflv"]=3.77,["hbjhd"]=0.277},["afternoonlite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.25,["tfbghuugbnjhg"]=-0.112,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.1234,["fvtyghj"]=5,["ygbhnj"]=0.43,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=14,["ghuybhuyhj"]=-15.12,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.103,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.85,["gyhgtg"]=0.0145,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.164,["skdjfkdm"]=0.256,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=21.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["eveninglite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.25,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(255,235,203),["jnfdhbnfcvh"]=0.234,["fvtyghj"]=3,["ygbhnj"]=0.413,["njnfg"]=4.34,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=16,["ghuybhuyhj"]=45,["khnbfth"]=1.15,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.1203,["sdfcddc"]=0.1215,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.365,["gyhgtg"]=0.255,["ygbhggv"]=0.143,["jghbjhgyfd"]=Color3.fromRGB(199,175,166),["shdbsnjfc"]=0.164,["skdjfkdm"]=5.356,["sjdjncdjf"]=Color3.fromRGB(199,175,166),["efjdjfk"]=Color3.fromRGB(44,39,33),["sejfd"]=0.16,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=21.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["nightlite"]={["fhnchvhfjsd"]=-0.06,["ugtbbjhygt"]=-0.02,["tfbghuugbnjhg"]=-0.2,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.34,["fvtyghj"]=4,["ygbhnj"]=0.4513,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=20,["ghuybhuyhj"]=-15,["khnbfth"]=3.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.103,["sdfcddc"]=0.155,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.85,["gyhgtg"]=0.15,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.264,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["midnightlite"]={["fhnchvhfjsd"]=-0.1,["ugtbbjhygt"]=-0.05,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.1,["fvtyghj"]=4,["ygbhnj"]=0.181,["njnfg"]=3,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=0,["ghuybhuyhj"]=-0,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,247,237),["ygyyfgvhbjytrt"]=0.1203,["sdfcddc"]=0.1255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.05,["gyhgtg"]=0.15,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.264,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(175,221,255),["efjdjfk"]=Color3.fromRGB(13,105,172),["sejfd"]=0.16,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["black"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(30,30,30),["jnfdhbnfcvh"]=0.1,["fvtyghj"]=10,["ygbhnj"]=0.9,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(3,3,3),["tgvbyd"]=5,["ghuybhuyhj"]=-45,["khnbfth"]=0.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.45,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(0,0,0),["shdbsnjfc"]=0.264,["skdjfkdm"]=1.256,["sjdjncdjf"]=Color3.fromRGB(2,2,2),["efjdjfk"]=Color3.fromRGB(0,0,0),["sejfd"]=0.16,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["green"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(132,182,141),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=8,["ghuybhuyhj"]=-16,["khnbfth"]=4.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(75,151,75),["hdfr7thgr"]=0.5,["gyhgtg"]=0.95,["ygbhggv"]=0.63,["jghbjhgyfd"]=Color3.fromRGB(75,151,75),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(75,151,75),["efjdjfk"]=Color3.fromRGB(40,127,71),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["red"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(238,196,182),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(238,196,182),["tgvbyd"]=7,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(205,84,75),["hdfr7thgr"]=0.5,["gyhgtg"]=0.95,["ygbhggv"]=0.43,["jghbjhgyfd"]=Color3.fromRGB(217,133,108),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(205,84,75),["efjdjfk"]=Color3.fromRGB(217,133,108),["sejfd"]=0.36,["jddfjsd"]=6.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["yellow"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(247,241,141),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(247,241,141),["tgvbyd"]=7,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(245,205,153),["hdfr7thgr"]=0.5,["gyhgtg"]=0.95,["ygbhggv"]=0.43,["jghbjhgyfd"]=Color3.fromRGB(249,233,153),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(245,205,153),["efjdjfk"]=Color3.fromRGB(249,233,153),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["pink"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(229,173,200),["jnfdhbnfcvh"]=1,["fvtyghj"]=58,["ygbhnj"]=4,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(238,196,182),["tgvbyd"]=7,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.95,["ygbhggv"]=0.63,["jghbjhgyfd"]=Color3.fromRGB(238,196,182),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(232,186,182),["efjdjfk"]=Color3.fromRGB(238,196,182),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["gray"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(199,193,183),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=7,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.95,["ygbhggv"]=0.63,["jghbjhgyfd"]=Color3.fromRGB(109,110,108),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(109,110,108),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["white"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=10,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(255,255,255),["hdfr7thgr"]=0.5,["gyhgtg"]=0.95,["ygbhggv"]=0.63,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(249,233,153),["efjdjfk"]=Color3.fromRGB(245,205,48),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["purple"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(165,165,203),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=46,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=10,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.65,["ygbhggv"]=0.63,["jghbjhgyfd"]=Color3.fromRGB(104,116,172),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(107,50,124),["efjdjfk"]=Color3.fromRGB(104,116,172),["sejfd"]=0.36,["jddfjsd"]=7.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["blacklite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(30,30,30),["jnfdhbnfcvh"]=0.1,["fvtyghj"]=10,["ygbhnj"]=0.9,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(35,35,35),["tgvbyd"]=20,["ghuybhuyhj"]=-45,["khnbfth"]=0.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.255,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.45,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(0,0,0),["shdbsnjfc"]=0.264,["skdjfkdm"]=1.256,["sjdjncdjf"]=Color3.fromRGB(2,2,2),["efjdjfk"]=Color3.fromRGB(0,0,0),["sejfd"]=0.16,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["greenlite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(132,182,141),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.3,["njnfg"]=2,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=8,["ghuybhuyhj"]=-16,["khnbfth"]=4.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(75,151,75),["hdfr7thgr"]=0.5,["gyhgtg"]=0.35,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(75,151,75),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.1556,["sjdjncdjf"]=Color3.fromRGB(75,151,75),["efjdjfk"]=Color3.fromRGB(40,127,71),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["redlite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(238,196,182),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=4,["ygbhnj"]=0.8,["njnfg"]=2,["yfbghj"]=Color3.fromRGB(238,196,182),["tgvbyd"]=7,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(205,84,75),["hdfr7thgr"]=0.2,["gyhgtg"]=0.25,["ygbhggv"]=0.13,["jghbjhgyfd"]=Color3.fromRGB(217,133,108),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(205,84,75),["efjdjfk"]=Color3.fromRGB(217,133,108),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["yellowlite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(247,241,141),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=5,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(247,241,141),["tgvbyd"]=8,["ghuybhuyhj"]=-35,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(255,255,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(245,205,153),["hdfr7thgr"]=0.5,["gyhgtg"]=0.25,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(249,233,153),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(245,205,153),["efjdjfk"]=Color3.fromRGB(249,233,153),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["pinklite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(229,173,200),["jnfdhbnfcvh"]=1,["fvtyghj"]=8,["ygbhnj"]=4,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(238,196,182),["tgvbyd"]=7,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.25,["ygbhggv"]=0.13,["jghbjhgyfd"]=Color3.fromRGB(238,196,182),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(232,186,182),["efjdjfk"]=Color3.fromRGB(238,196,182),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["graylite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(199,193,183),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=6,["ygbhnj"]=0.5,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=7,["ghuybhuyhj"]=-35,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.25,["ygbhggv"]=0.13,["jghbjhgyfd"]=Color3.fromRGB(109,110,108),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(109,110,108),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.117,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["whitelite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(242,243,243),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=1,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=10,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(255,255,255),["hdfr7thgr"]=0.5,["gyhgtg"]=0.15,["ygbhggv"]=0.63,["jghbjhgyfd"]=Color3.fromRGB(255,255,255),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(249,233,153),["efjdjfk"]=Color3.fromRGB(245,205,48),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["purplelite"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(165,165,203),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=6,["ygbhnj"]=0.8,["njnfg"]=2,["yfbghj"]=Color3.fromRGB(2,2,2),["tgvbyd"]=8,["ghuybhuyhj"]=-45,["khnbfth"]=2.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.35,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(104,116,172),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(107,50,124),["efjdjfk"]=Color3.fromRGB(104,116,172),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["rain"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(200,200,200),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(109,110,108),["tgvbyd"]=15,["ghuybhuyhj"]=-45,["khnbfth"]=0.25,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=0.75,["ygbhggv"]=0.93,["jghbjhgyfd"]=Color3.fromRGB(161,165,162),["shdbsnjfc"]=0.564,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(161,165,162),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["snow"]={["fhnchvhfjsd"]=-0.1,["ugtbbjhygt"]=0.2,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(200,200,255),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=3,["yfbghj"]=Color3.fromRGB(242,243,243),["tgvbyd"]=10,["ghuybhuyhj"]=-45,["khnbfth"]=-0.1,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.403,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.2,["gyhgtg"]=0.55,["ygbhggv"]=0.93,["jghbjhgyfd"]=Color3.fromRGB(242,243,243),["shdbsnjfc"]=0.564,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(242,243,243),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["fog"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.2,["tfbghuugbnjhg"]=0.3,["fvrtccvghghj"]=Color3.fromRGB(255,247,239),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=3,["yfbghj"]=Color3.fromRGB(33,33,33),["tgvbyd"]=9,["ghuybhuyhj"]=-45,["khnbfth"]=-1.61,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.403,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.72,["gyhgtg"]=0.75,["ygbhggv"]=0.83,["jghbjhgyfd"]=Color3.fromRGB(242,243,243),["shdbsnjfc"]=1.564,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(242,243,243),["sejfd"]=0.36,["jddfjsd"]=1.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["sunny"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.4,["tfbghuugbnjhg"]=-0.1,["fvrtccvghghj"]=Color3.fromRGB(255,247,239),["jnfdhbnfcvh"]=0.5,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(255,255,255),["tgvbyd"]=12,["ghuybhuyhj"]=-1,["khnbfth"]=-5.61,["hgyghkg"]=Color3.fromRGB(255,255,255),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.403,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.72,["gyhgtg"]=0.55,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(242,243,243),["shdbsnjfc"]=0.164,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(242,243,243),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["cloudy"]={["fhnchvhfjsd"]=0,["ugtbbjhygt"]=-0.07,["tfbghuugbnjhg"]=-0.1,["fvrtccvghghj"]=Color3.fromRGB(255,247,239),["jnfdhbnfcvh"]=0.3,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(109,110,108),["tgvbyd"]=15,["ghuybhuyhj"]=34,["khnbfth"]=-0.61,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(0,0,0),["hdfr7thgr"]=0.5,["gyhgtg"]=9.55,["ygbhggv"]=0.93,["jghbjhgyfd"]=Color3.fromRGB(161, 165,162),["shdbsnjfc"]=0.164,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(242,243,243),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["storm"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(255,235,203),["jnfdhbnfcvh"]=0.5,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=7,["yfbghj"]=Color3.fromRGB(109,110,108),["tgvbyd"]=16,["ghuybhuyhj"]=45,["khnbfth"]=-0.11,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.403,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(51,54,67),["hdfr7thgr"]=0.52,["gyhgtg"]=1.5,["ygbhggv"]=0.93,["jghbjhgyfd"]=Color3.fromRGB(200,200,200),["shdbsnjfc"]=0.564,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(161,165,162),["efjdjfk"]=Color3.fromRGB(161, 165,162),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["autumn"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=-0.3,["fvrtccvghghj"]=Color3.fromRGB(255,165,0),["jnfdhbnfcvh"]=0.5,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(255,140,0),["tgvbyd"]=8,["ghuybhuyhj"]=-15.12,["khnbfth"]=-2.61,["hgyghkg"]=Color3.fromRGB(255,140,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.403,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(255,165,0),["hdfr7thgr"]=0.72,["gyhgtg"]=0.55,["ygbhggv"]=0.23,["jghbjhgyfd"]=Color3.fromRGB(242,243,243),["shdbsnjfc"]=0.164,["skdjfkdm"]=0.356,["sjdjncdjf"]=Color3.fromRGB(255,165,0),["efjdjfk"]=Color3.fromRGB(255,165,0),["sejfd"]=0.36,["jddfjsd"]=0.52,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["spring"]={["fhnchvhfjsd"]=0.1,["ugtbbjhygt"]=0.5,["tfbghuugbnjhg"]=0.1,["fvrtccvghghj"]=Color3.fromRGB(255,247,239),["jnfdhbnfcvh"]=0.5,["fvtyghj"]=10,["ygbhnj"]=0.8,["njnfg"]=5,["yfbghj"]=Color3.fromRGB(173,216,230),["tgvbyd"]=9,["ghuybhuyhj"]=0,["khnbfth"]=-1.61,["hgyghkg"]=Color3.fromRGB(0,0,0),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(144,238,144),["hdfr7thgr"]=0.72,["gyhgtg"]=0.65,["ygbhggv"]=0.53,["jghbjhgyfd"]=Color3.fromRGB(144,144,144),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.156,["sjdjncdjf"]=Color3.fromRGB(173,216,230),["efjdjfk"]=Color3.fromRGB(144,238,144),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["summer"]={["fhnchvhfjsd"]=0.15,["ugtbbjhygt"]=0.6,["tfbghuugbnjhg"]=0.1,["fvrtccvghghj"]=Color3.fromRGB(255,250,205),["jnfdhbnfcvh"]=0.4,["fvtyghj"]=12,["ygbhnj"]=0.7,["njnfg"]=4.5,["yfbghj"]=Color3.fromRGB(255,223,186),["tgvbyd"]=12,["ghuybhuyhj"]=1,["khnbfth"]=2.61,["hgyghkg"]=Color3.fromRGB(255,223,186),["yfbhjku"]=Color3.fromRGB(0,0,0),["ygyyfgvhbjytrt"]=0.403,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(255,223,186),["hdfr7thgr"]=0.72,["gyhgtg"]=0.35,["ygbhggv"]=0.83,["jghbjhgyfd"]=Color3.fromRGB(242,243,243),["shdbsnjfc"]=0.464,["skdjfkdm"]=0.656,["sjdjncdjf"]=Color3.fromRGB(255,223,186),["efjdjfk"]=Color3.fromRGB(255,200,160),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277},["winter"]={["fhnchvhfjsd"]=-0.1,["ugtbbjhygt"]=0.4,["tfbghuugbnjhg"]=-0.2,["fvrtccvghghj"]=Color3.fromRGB(240,248,255),["jnfdhbnfcvh"]=0.2,["fvtyghj"]=8,["ygbhnj"]=0.81,["njnfg"]=6,["yfbghj"]=Color3.fromRGB(192,224,255),["tgvbyd"]=16,["ghuybhuyhj"]=45,["khnbfth"]=2.61,["hgyghkg"]=Color3.fromRGB(245,245,245),["yfbhjku"]=Color3.fromRGB(240,248,255),["ygyyfgvhbjytrt"]=0.203,["sdfcddc"]=0.25,["hgnujuu7thgr"]=true,["hyhnngtf"]=Color3.fromRGB(192,224,255),["hdfr7thgr"]=0.72,["gyhgtg"]=0.65,["ygbhggv"]=0.93,["jghbjhgyfd"]=Color3.fromRGB(192,224,255),["shdbsnjfc"]=0.364,["skdjfkdm"]=0.556,["sjdjncdjf"]=Color3.fromRGB(192,224,255),["efjdjfk"]=Color3.fromRGB(200,200,200),["sejfd"]=0.36,["jddfjsd"]=0.72,["jdfkd"]=0.217,["fvgsdfg"]=11.54,["sdkvkflv"]=16.77,["hbjhd"]=0.277}}
local skies={["morning"]={["bk"]='rbxassetid://7879352266',["dn"]='rbxassetid://7879347786',["ft"]='rbxassetid://7879358161',["lt"]='rbxassetid://7879393853',["rt"]='rbxassetid://7879350066',["up"]='rbxassetid://7879345023'},["midday"]={["bk"]='rbxassetid://11832250366',["dn"]='rbxassetid://11832250656',["ft"]='rbxassetid://11832250915',["lt"]='rbxassetid://11832250090',["rt"]='rbxassetid://11832249798',["up"]='rbxassetid://11832257515'},["afternoon"]={["bk"]='rbxassetid://225469345',["dn"]='rbxassetid://225469349',["ft"]='rbxassetid://225469359',["lt"]='rbxassetid://225469364',["rt"]='rbxassetid://225469372',["up"]='rbxassetid://225469380'},["evening"]={["bk"]='rbxassetid://271042516',["dn"]='rbxassetid://271077243',["ft"]='rbxassetid://271042556',["lt"]='rbxassetid://271042310',["rt"]='rbxassetid://271042467',["up"]='rbxassetid://271077958'},["rain"]={["bk"]='rbxassetid://4498828382',["dn"]='rbxassetid://4498828812',["ft"]='rbxassetid://4498829917',["lt"]='rbxassetid://4498830911',["rt"]='rbxassetid://4498830417',["up"]='rbxassetid://4498831746'},["cloudy"]={["bk"]='rbxassetid://4495864450',["dn"]='rbxassetid://4495864887',["ft"]='rbxassetid://4495865458',["lt"]='rbxassetid://4495866035',["rt"]='rbxassetid://4495866584',["up"]='rbxassetid://4495867486'}}
    local api, snapshot, owned, displaced, enabled, surface = {}, nil, {}, {}, {}, {}
    local Lighting=game:GetService("Lighting")
    local terrain=Workspace.Terrain
    local lastLook, appliedReflectance = nil, nil
    local mapping={ClockTime="tgvbyd",Ambient="yfbghj",Brightness="khnbfth",ColorShift_Bottom="hgyghkg",
        ColorShift_Top="yfbhjku",EnvironmentDiffuseScale="ygyyfgvhbjytrt",EnvironmentSpecularScale="sdfcddc",
        GlobalShadows="hgnujuu7thgr",OutdoorAmbient="hyhnngtf",GeographicLatitude="ghuybhuyhj",ExposureCompensation="hdfr7thgr"}
    function api.Reset()
        for _,object in pairs(owned) do object:Destroy() end;table.clear(owned)
        for object,parent in pairs(displaced) do object.Parent=parent end;table.clear(displaced)
        for object,value in pairs(enabled) do if object.Parent then object.Enabled=value end end;table.clear(enabled)
        for object,value in pairs(surface) do if object.Parent then object.Reflectance=value end end;table.clear(surface)
        if snapshot then for key,value in pairs(snapshot) do Lighting[key]=value end end
        snapshot=nil;lastLook=nil;appliedReflectance=nil
    end
    function api.Start()
        api.Reset()
        if not settings.pshade then return end
        settings.ambience=false;settings.glossyShaders=false
        Ambience.Reset();Glossy.Reset()
        for _,key in ipairs({"ambience","glossyShaders"}) do if stateRefreshers[key] then stateRefreshers[key]() end end
        snapshot={FogStart=Lighting.FogStart,FogEnd=Lighting.FogEnd,FogColor=Lighting.FogColor}
        for key in pairs(mapping) do snapshot[key]=Lighting[key] end
        local sky=Lighting:FindFirstChildOfClass("Sky")
        owned.sky=sky and sky:Clone() or Instance.new("Sky")
        for _,object in ipairs(Lighting:GetChildren()) do
            if object:IsA("Sky") or object:IsA("Atmosphere") then displaced[object]=Lighting;object.Parent=nil
            elseif object:IsA("PostEffect") then enabled[object]=object.Enabled;object.Enabled=false end
        end
        for _,object in ipairs(terrain:GetChildren()) do
            if object:IsA("Clouds") then displaced[object]=terrain;object.Parent=nil end
        end
        owned.sky.Name="StarfirePShadeSky";owned.sky.Parent=Lighting
        for key,class in pairs({grade="ColorCorrectionEffect",bloom="BloomEffect",blur="BlurEffect",
            depth="DepthOfFieldEffect",rays="SunRaysEffect",atmosphere="Atmosphere"}) do
            owned[key]=make(class,{Name="StarfirePShade_"..key},Lighting)
        end
        owned.clouds=make("Clouds",{Name="StarfirePShadeClouds"},terrain)
    end
    local function reflective(object)
        if object:IsA("BasePart") and object.Anchored and not object:IsDescendantOf(effects) then
            if surface[object]==nil then surface[object]=object.Reflectance end
            object.Reflectance=settings.pshadeReflectance
        end
    end
    connect(Workspace.DescendantAdded,function(object) if snapshot then reflective(object) end end)
    function api.Step(dt)
        if not settings.pshade then if snapshot then api.Reset() end;return end
        if not snapshot then api.Start() end
        local light=presets[settings.pshadePreset] or presets.midday
        for property,key in pairs(mapping) do Lighting[property]=light[key] end
        Lighting.FogStart=100000;Lighting.FogEnd=100001;Lighting.FogColor=Color3.new(1,1,1)
        local box=skies[settings.pshadeSky] or skies.midday
        for property,key in pairs({SkyboxBk="bk",SkyboxDn="dn",SkyboxFt="ft",SkyboxLf="lt",SkyboxRt="rt",SkyboxUp="up"}) do owned.sky[property]=box[key] end
        owned.grade.Brightness=light.fhnchvhfjsd;owned.grade.Contrast=light.ugtbbjhygt
        owned.grade.Saturation=light.tfbghuugbnjhg;owned.grade.TintColor=light.fvrtccvghghj
        owned.bloom.Intensity=light.jnfdhbnfcvh;owned.bloom.Size=light.fvtyghj;owned.bloom.Threshold=light.ygbhnj
        owned.atmosphere.Density=light.shdbsnjfc;owned.atmosphere.Offset=light.skdjfkdm
        owned.atmosphere.Color=light.sjdjncdjf;owned.atmosphere.Decay=light.efjdjfk
        owned.atmosphere.Glare=light.sejfd;owned.atmosphere.Haze=light.jddfjsd
        owned.clouds.Cover=light.gyhgtg;owned.clouds.Density=light.ygbhggv;owned.clouds.Color=light.jghbjhgyfd
        owned.depth.Enabled=settings.pshadeDepth;owned.depth.FarIntensity=light.jdfkd
        owned.depth.FocusDistance=light.fvgsdfg;owned.depth.InFocusRadius=light.sdkvkflv;owned.depth.NearIntensity=light.hbjhd
        owned.rays.Intensity=0.08;owned.rays.Spread=0.8
        local camera=Workspace.CurrentCamera;local motion=0
        if camera then
            local look=camera.CFrame.LookVector
            if lastLook and settings.pshadeMotion then motion=math.min((look-lastLook).Magnitude/math.max(dt or 1/60,0.001)*0.45,12) end
            lastLook=look
        end
        owned.blur.Size=math.max(settings.pshadeBlur and light.njnfg or 0,motion)
        if appliedReflectance~=settings.pshadeReflectance then
            appliedReflectance=settings.pshadeReflectance
            for _,object in ipairs(Workspace:GetDescendants()) do reflective(object) end
        end
    end
    return api
end)()
toggle(UIRefs.ambiencePage,"PShade Ultimate · supplied presets","pshade",function() PShade.Start() end)
local pshadeNames={"morning","midday","afternoon","evening","night","midnight","morninglite","middaylite","afternoonlite","eveninglite","nightlite","midnightlite","black","green","red","yellow","pink","gray","white","purple","blacklite","greenlite","redlite","yellowlite","pinklite","graylite","whitelite","purplelite","rain","snow","fog","sunny","cloudy","storm","autumn","spring","summer","winter"}
UIRefs.pshadeSelector=nil
UIRefs.pshadeSelector=button(UIRefs.ambiencePage,"PShade preset: "..settings.pshadePreset,function()
    local index=table.find(pshadeNames,settings.pshadePreset) or 0
    settings.pshadePreset=pshadeNames[index % #pshadeNames+1]
    UIRefs.pshadeSelector.Text="PShade preset: "..settings.pshadePreset
end)
stateRefreshers.pshadePreset=function() UIRefs.pshadeSelector.Text="PShade preset: "..settings.pshadePreset end
UIRefs.pshadeSkySelector=nil
UIRefs.pshadeSkySelector=button(UIRefs.ambiencePage,"PShade sky: "..settings.pshadeSky,function()
    local names={"morning","midday","afternoon","evening","rain","cloudy"}
    local index=table.find(names,settings.pshadeSky) or 0
    settings.pshadeSky=names[index % #names+1]
    UIRefs.pshadeSkySelector.Text="PShade sky: "..settings.pshadeSky
end)
stateRefreshers.pshadeSky=function() UIRefs.pshadeSkySelector.Text="PShade sky: "..settings.pshadeSky end
toggle(UIRefs.ambiencePage,"PShade soft blur","pshadeBlur")
toggle(UIRefs.ambiencePage,"PShade motion blur","pshadeMotion")
toggle(UIRefs.ambiencePage,"PShade depth of field","pshadeDepth")
slider(UIRefs.ambiencePage,"PShade reflectance","pshadeReflectance",0,0.9,function(v) return string.format("%.0f%%",v*100) end)

Tracers = (function()
    local api, watched, lines, native = {}, {}, {}, {}
    local function shotName(name)
        name = string.lower(name):gsub("[%s_%-]", "")
        return name == "gunshot" or name == "shoot" or name == "shot" or name == "fire"
            or name == "firesound" or name == "shootsound" or name == "gunfire"
    end
    local recentShots,pending={},{}
    local function shotShape(object)
        if not object:IsA("BasePart") or object:IsDescendantOf(effects) or object.CanCollide
            or object:FindFirstAncestorOfClass("Tool") then return nil end
        local size=object.Size
        local long=math.max(size.X,size.Y,size.Z)
        local thin=math.min(size.X,size.Y,size.Z)
        local middle=size.X+size.Y+size.Z-long-thin
        if long<2 or middle>.4 or long/math.max(middle,.001)<15 then return nil end
        local axis=size.X==long and object.CFrame.RightVector or size.Y==long and object.CFrame.UpVector or object.CFrame.LookVector
        return object.Position,axis
    end
    local function matchesShot(object)
        local position,axis=shotShape(object)
        if not position then return false end
        local now=os.clock()
        for _,shot in ipairs(recentShots) do
            if now-shot.time<=.35 then
                local offset=position-shot.origin
                local along=offset:Dot(shot.direction)
                local perpendicular=(offset-shot.direction*along).Magnitude
                if along>=-2 and along<=550 and perpendicular<=2.5 and math.abs(axis:Dot(shot.direction))>=.97 then return true end
            end
        end
        return false
    end
    local function emit(sound, tool)
        if not settings.bulletTracers or not tool:IsDescendantOf(Workspace) then return end
        local handle = tool:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then return end
        local origin = handle.Position
        local direction = handle.CFrame.LookVector * 500
        local character, camera = tool.Parent, Workspace.CurrentCamera
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = {character, effects}
        if character == player.Character and camera then
            local mouse = player:GetMouse()
            local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
            local hit = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)
            local destination = hit and hit.Position or (ray.Origin + ray.Direction * 500)
            local offset = destination - origin
            if offset.Magnitude < 0.01 then return end
            direction = offset.Unit * math.min(offset.Magnitude,500)
        end
        local hit = Workspace:Raycast(origin,direction,params)
        local destination = hit and hit.Position or origin + direction
        local length = (destination-origin).Magnitude
        if length < 0.01 then return end
        table.insert(recentShots,{origin=origin,direction=(destination-origin).Unit,time=os.clock()})
        if #recentShots>24 then table.remove(recentShots,1) end
        local part = make("Part", {Name = "StarfireBulletTracer", Anchored = true, CanCollide = false,
            CanTouch = false, CanQuery = false, CastShadow = false, Material = Enum.Material.Neon,
            Color = Color3.fromRGB(settings.tracerRed,settings.tracerGreen,settings.tracerBlue), Transparency = 0.1,
            Size = Vector3.new(settings.tracerWidth,settings.tracerWidth,length),
            CFrame = CFrame.lookAt((origin+destination)/2,destination)},effects)
        table.insert(lines,{part = part,time = os.clock(),life = settings.tracerLife})
        if #lines > 150 then lines[1].part:Destroy();table.remove(lines,1) end
    end
    local function hideNative(object)
        if object:IsDescendantOf(effects) or native[object] then return end
        local beam = object:IsA("Beam") or object:IsA("Trail")
        local physical = object:IsA("BasePart")
        if not beam and not physical then return end
        local ancestor, identified = object, false
        while ancestor and ancestor ~= Workspace do
            local name=string.lower(ancestor.Name):gsub("[%s_%-]","")
            if name == "bullet" or name == "bullettracer" or name == "guntracer" or name == "bullettrail"
                or name == "tracer" or name == "bulletvisual" or name == "gunbeam" or name == "bulletbeam"
                or name == "shotbeam" or name == "shottracer" or name == "bullettrace" or name == "bulletray"
                or name == "bullettracerpart" or name == "guntracerpart" or name == "bulletline" or name == "bulletpath" or name == "bulletpart" or name == "gunbullet" or name == "shotline" then identified=true;break end
            ancestor=ancestor.Parent
        end
        if not identified and not matchesShot(object) then return end
        local property=beam and "Transparency" or "LocalTransparencyModifier"
        native[object]={property=property,value=object[property]}
        object[property]=beam and NumberSequence.new(1) or 1
    end
    local function watch(object)
        if not object:IsA("Sound") or watched[object] or not shotName(object.Name) then return end
        local tool = object:FindFirstAncestorOfClass("Tool")
        if not tool or string.lower(tool.Name) ~= "gun" then return end
        watched[object] = object.Played:Connect(function() emit(object,tool) end)
    end
    function api.Reset()
        table.clear(recentShots);table.clear(pending)
        for object, original in pairs(native) do
            if object.Parent then object[original.property]=original.value end
        end
        table.clear(native)
        for sound, connection in pairs(watched) do connection:Disconnect() end
        table.clear(watched)
        for _, line in ipairs(lines) do line.part:Destroy() end
        table.clear(lines)
    end
    function api.Start()
        api.Reset()
        if not settings.bulletTracers then return end
        for _, object in ipairs(Workspace:GetDescendants()) do hideNative(object);watch(object) end
    end
    connect(Workspace.DescendantAdded,function(object)
        if not settings.bulletTracers then return end
        hideNative(object);watch(object)
        if shotShape(object) then pending[object]=os.clock() end
        -- Some game effects receive their final name/parent after being created.
        if object:IsA("BasePart") or object:IsA("Beam") or object:IsA("Trail") or object:IsA("Sound") then
            task.defer(function()
                if running and settings.bulletTracers and object:IsDescendantOf(Workspace) then
                    hideNative(object);watch(object)
                end
            end)
        end
    end)
    function api.Step()
        if not settings.bulletTracers then if next(watched) or next(native) or #lines>0 then api.Reset() end;return end
        for sound, connection in pairs(watched) do
            if not sound:IsDescendantOf(Workspace) then connection:Disconnect();watched[sound]=nil end
        end
        for object, original in pairs(native) do
            if not object:IsDescendantOf(Workspace) then
                if object.Parent then object[original.property]=original.value end
                native[object]=nil
            else object[original.property]=original.property=="Transparency" and NumberSequence.new(1) or 1 end
        end
        for object,born in pairs(pending) do
            if not object.Parent or os.clock()-born>.30 then pending[object]=nil
            else hideNative(object);if native[object] then pending[object]=nil end end
        end
        local now = os.clock()
        for i=#lines,1,-1 do
            local line=lines[i];local age=(now-line.time)/line.life
            if age>=1 then line.part:Destroy();table.remove(lines,i)
            else
                line.part.Transparency = 0.1 + 0.9*math.clamp((age-0.5)*2,0,1)
                line.part.Color = Color3.fromRGB(settings.tracerRed,settings.tracerGreen,settings.tracerBlue)
            end
        end
    end
    return api
end)()
toggle(UIRefs.gunsPage,"Replace game bullet tracers · local","bulletTracers",function() Tracers.Start() end)
slider(UIRefs.gunsPage,"Tracer lifetime","tracerLife",0.5,10,function(v) return string.format("%.1f s",v) end)
slider(UIRefs.gunsPage,"Tracer width","tracerWidth",0.02,0.3,function(v) return string.format("%.2f",v) end)
UIRefs.ColourPicker(UIRefs.gunsPage,"Tracer colour",{"tracerRed","tracerGreen","tracerBlue"})

-- Asset-free, local-only articulated first-person hands.
GripArms = (function()
    local api,model,rigs,hidden,character={},nil,{},{},nil
    local function restore()
        for part,value in pairs(hidden) do if part.Parent then part.LocalTransparencyModifier=value end end
        table.clear(hidden)
    end
    function api.Reset()
        restore()
        if model then model:Destroy();model=nil end
        table.clear(rigs);character=nil
    end
    function api.Destroy() api.Reset() end
    local function visual(class,name,size,parent,color)
        local part=make("Part",{Name=name,Size=size,Color=color,Material=Enum.Material.SmoothPlastic,
            Anchored=true,CanCollide=false,CanTouch=false,CanQuery=false,Massless=true,CastShadow=false},parent)
        make("SpecialMesh",{MeshType=Enum.MeshType.Sphere,Scale=Vector3.new(1,1,1)},part)
        if WireStyle then WireStyle.Register(part,"arms") end
        return part
    end
    local function createHand(side,color)
        local group=make("Model",{Name=side.."ProceduralHand"},model)
        local palm=visual("Part","Palm",Vector3.new(.305,.30,side=="Left" and .125 or .15),group,color)
        local rig={group=group,palm=palm,joints={},fixed={}}
        local function fixed(class,name,size,offset,tint)
            local p=visual(class,name,size,group,color)
            table.insert(rig.fixed,{part=p,offset=offset,tint=tint});return p
        end
        -- Overlapping rounded surfaces hide abrupt wrist and forearm transitions.
        fixed("Part","Rounded forearm",Vector3.new(.255,.78,.195),CFrame.new(0,.54,0))
        fixed("Part","Forearm rounded cap",Vector3.new(.245,.25,.19),CFrame.new(0,.84,0))
        fixed("Part","Lower forearm blend",Vector3.new(.215,side=="Right" and .77 or .46,side=="Right" and .18 or .17),CFrame.new(0,side=="Right" and .34 or .39,0))
        fixed("Part","Wrist blend",Vector3.new(side=="Right" and .215 or .20,side=="Right" and .57 or .16,side=="Right" and .15 or .14),CFrame.new(0,side=="Right" and .10 or .20,0))
        fixed("Part","Thumb pad",Vector3.new(side=="Left" and .125 or .15,.255,side=="Left" and .115 or .14),CFrame.new((side=="Left" and 1 or -1)*.082,-.015,0))
        local sign=side=="Left" and -1 or 1
        local thumbSign=side=="Left" and 1 or -1
        for finger=1,5 do
            local parent=palm
            local lengths=finger==5 and {.095,.075,.06} or finger==4 and {.085,.065,.055} or {.11,.085,.065}
            for bone,length in ipairs(lengths) do
                local width=(finger==5 and .067 or .055)*(1-(bone-1)*.07)
                local p=visual("Part",(finger==5 and "Thumb" or "Finger"..finger).."_"..bone,Vector3.new(width,length+.105,.072-(bone-1)*.004),group,color)
                local origin
                if bone==1 then
                    origin=finger==5 and CFrame.new(thumbSign*.135,.015,.015)*CFrame.Angles(0,0,thumbSign*math.rad(48))
                        or CFrame.new(sign*(finger-2.5)*.067,-.12,0)
                else origin=CFrame.new(0,-lengths[bone-1]/2+.006,0) end
                local joint=make("Motor6D",{Name="VisualFingerJoint",Part0=parent,Part1=p,C0=origin,C1=CFrame.new(0,length/2,0)},parent)
                local blend=visual("Part","RoundedKnuckle",Vector3.new(width*1.08,width*1.8,.076-(bone-1)*.004),group,color)
                table.insert(rig.joints,{motor=joint,parent=parent,part=p,blend=blend,finger=finger,bone=bone})
                parent=p
            end
        end
        return rig
    end
    function api.GesturePose(camera,side,base)
        local phase=BunnyHop and BunnyHop.GesturePhase()
        if not phase then return base end
        local function smooth(t) t=math.clamp(t,0,1);return t*t*(3-2*t) end
        local enter=smooth(phase/.24)
        local drop=smooth((phase-.37)/.31)
        local restore=smooth((phase-.79)/.21)
        local sweep=side=="Right" and CFrame.new(-.08,-.30,-1.25)
            *CFrame.Angles(math.rad(125),math.rad(-12),math.rad(-50))
            or CFrame.new(-.70,-1.25,-.90)*CFrame.Angles(math.rad(145),0,math.rad(35))
        local lowered=side=="Right" and CFrame.new(.40,-1.45,-.82)
            *CFrame.Angles(math.rad(150),math.rad(-8),math.rad(-25))
            or CFrame.new(-.70,-1.4,-.80)*CFrame.Angles(math.rad(150),0,math.rad(35))
        local motion=base:Lerp(camera.CFrame*sweep,enter)
        motion=motion:Lerp(camera.CFrame*lowered,drop)
        return motion:Lerp(base,restore)
    end
    function api.RightBase(camera)
        return camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())
            *CFrame.new(.52,-.25,-1.05)*CFrame.Angles(math.rad(125),0,math.rad(-25))
            *CFrame.new(settings.customArmX,settings.customArmY,settings.customArmZ)
    end
    function api.RightPose(camera)
        local motion=Voidglass and Voidglass.Equipped() and Voidglass.HandMotion and Voidglass.HandMotion() or CFrame.new()
        local pose=camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())*motion*CFrame.new(.52,-.25,-1.05)
            *CFrame.Angles(math.rad(125),0,math.rad(-25))
            *CFrame.new(settings.customArmX,settings.customArmY,settings.customArmZ)
        local extension=Voidglass and Voidglass.StabExtension and Voidglass.StabExtension() or 0
        if extension>0 then
            local extended=camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())
                *CFrame.new(.08,-.15,-1.62)*CFrame.Angles(math.rad(115),math.rad(-4),math.rad(-28))
            if Voidglass.Jabbing and Voidglass.Jabbing() then
                local phase=Voidglass.StabPhase()
                local strike=math.clamp((phase-.16)/.48,0,1)
                strike=strike*strike*(3-2*strike)
                local u=1-strike
                -- Upper-right to lower-left arc from the supplied screen-space sketch.
                local p0=Vector3.new(.62,-.03,-1.03)
                local p1=Vector3.new(.55,.06,-1.10)
                local p2=Vector3.new(.14,-.25,-1.20)
                local p3=Vector3.new(.08,-.62,-1.10)
                local position=p0*(u*u*u)+p1*(3*u*u*strike)+p2*(3*u*strike*strike)+p3*(strike*strike*strike)
                extended=camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())
                    *CFrame.new(position)*CFrame.Angles(math.rad(119+9*strike),math.rad(10-22*strike),math.rad(-34+46*strike))
            end
            pose=pose:Lerp(extended,extension)
        end
        if Voidglass and Voidglass.Jabbing and Voidglass.Jabbing() then
            local base=api.RightBase(camera)
            local relative=base:ToObjectSpace(pose)
            local rotation=CFrame.new():Lerp(relative.Rotation,1.35)
            local hinge=CFrame.new(0,.12,0)
            local travel=Vector3.new(relative.Position.X*.35,relative.Position.Y*.55,relative.Position.Z*.35)
            pose=base*CFrame.new(travel)*hinge*rotation*hinge:Inverse()
        end
        return api.GesturePose(camera,"Right",Inspect and Inspect.TransformArm(pose) or pose)
    end
    local function fingerInk(rig,camera)
        rig.ink=rig.ink or {}
        if not settings.wireArms or not settings.wireContours then
            for _,part in ipairs(rig.ink) do part.Transparency=1 end
            return
        end
        local face=rig.palm.CFrame:PointToObjectSpace(camera.CFrame.Position).Z>=0 and 1 or -1
        local fingers={}
        for _,entry in ipairs(rig.joints) do
            fingers[entry.finger]=fingers[entry.finger] or {}
            fingers[entry.finger][entry.bone]=entry.part
        end
        local used=0
        local wrist=rig.palm.CFrame:PointToWorldSpace(Vector3.new(0,.085,face*rig.palm.Size.Z*.48))
        -- The finger fan shares one central stroke from the wrist down the arm.
        for finger=0,5 do
            local bones=fingers[finger]
            local points={wrist}
            if finger==0 then
                for sample=1,18 do
                    local y=.085+sample/18*1.08
                    local depth=0
                    for _,entry in ipairs(rig.fixed) do
                        if entry.part.Name=="Rounded forearm" or entry.part.Name=="Forearm rounded cap" or entry.part.Name=="Lower forearm blend" or entry.part.Name=="Wrist blend" then
                            local h=entry.part.Size*.5
                            local dy=(y-entry.offset.Position.Y)/h.Y
                            if math.abs(dy)<1 then depth=math.max(depth,h.Z*math.sqrt(1-dy*dy)) end
                        end
                    end
                    table.insert(points,rig.palm.CFrame:PointToWorldSpace(Vector3.new(0,y,face*(depth+.002))))
                end
            else
            for bone=1,3 do
                local part=bones[bone]
                table.insert(points,part.CFrame:PointToWorldSpace(Vector3.new(0,0,face*part.Size.Z*.53)))
            end
            local tip=bones[3]
            table.insert(points,tip.CFrame:PointToWorldSpace(Vector3.new(0,-tip.Size.Y*.34,face*tip.Size.Z*.36)))
            end
            local previous=points[1]
            for i=1,#points-1 do
                local p0,p1,p2,p3=points[math.max(1,i-1)],points[i],points[i+1],points[math.min(#points,i+2)]
                for sample=1,3 do
                    local t=sample/3;local t2,t3=t*t,t*t*t
                    local nextPoint=(p1*2+(p2-p0)*t+(p0*2-p1*5+p2*4-p3)*t2+(-p0+p1*3-p2*3+p3)*t3)*.5
                    local length=(nextPoint-previous).Magnitude
                    if length>.0001 then
                        used=used+1
                        local line=rig.ink[used]
                        if not line then
                            line=make("Part",{Name="ContinuousFingerContour",Anchored=true,CanCollide=false,CanTouch=false,
                                CanQuery=false,Massless=true,CastShadow=false,Material=Enum.Material.SmoothPlastic,
                                Color=Color3.fromRGB(8,9,12)},rig.group)
                            rig.ink[used]=line
                        end
                        line.Color=Color3.fromRGB(settings.contourRed,settings.contourGreen,settings.contourBlue)
                        line.Transparency=1-settings.contourOpacity;line.Size=Vector3.new(.0035,.0035,length+.001)
                        line.CFrame=CFrame.lookAt((previous+nextPoint)*.5,nextPoint)
                    end
                    previous=nextPoint
                end
            end
        end
        for i=used+1,#rig.ink do rig.ink[i].Transparency=1 end
    end
    function api.Step(dt)
        local current,camera=player.Character,Workspace.CurrentCamera
        if not settings.customArms or not camera or not living(current)
            or (camera.CFrame.Position-camera.Focus.Position).Magnitude>=1.2 then
            if model then api.Reset() end;return
        end
        if character and character~=current then api.Reset() end
        restore()
        local held=current:FindFirstChildOfClass("Tool")
        local gun=held and held.Name:lower()=="gun" and held:FindFirstChild("Handle")
        if gun and not gun:IsA("BasePart") then gun=nil end
        local phase=(Voidglass and Voidglass.InspectPhase()) or (Inspect and Inspect.Phase())
        local release=phase and math.sin(math.pi*math.clamp((phase-.12)/.48,0,1))^2 or 0
        if not model then model=make("Model",{Name="StarfireAssetFreeHands"},effects);character=current end
        for _,side in ipairs({"Left","Right"}) do
            local hand=current:FindFirstChild(side.."Hand")
            local classic=current:FindFirstChild(side.." Arm")
            local source=hand or classic
            local color=source and source.Color or Color3.fromRGB(205,175,154)
            if not rigs[side] then rigs[side]=createHand(side,color) end
            local rig=rigs[side]
            local pose=camera.CFrame*CFrame.new(.52,-.25,-1.05)
                *CFrame.Angles(math.rad(125),0,math.rad(-25))
            -- Camera-relative open support hand: forearm enters from lower left,
            -- fingers point forward and slightly toward the centre.
            rig.shakeForearm=nil
            if side=="Left" then
                local knifePhase=Voidglass and (Voidglass.StabPhase() or Voidglass.InspectPhase())
                local wanted=knifePhase and 1 or 0
                -- Preserve the retreat across repeated inspect presses; no arm snapping.
                rig.retreat=(rig.retreat or 0)+(wanted-(rig.retreat or 0))*(1-math.exp(-(wanted==1 and 15 or 5.5)*math.min(dt or 1/60,.1)))
                local withdraw=rig.retreat*rig.retreat*(3-2*rig.retreat)
                local resting=CFrame.new(-.62,-.38,-1.12)*CFrame.Angles(math.rad(125),0,math.rad(35))
                local lowered=CFrame.new(-.83,-1.20,-.68)*CFrame.Angles(math.rad(145),math.rad(-12),math.rad(52))
                pose=camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())*resting:Lerp(lowered,withdraw)
                local shake=Voidglass and Voidglass.LeftShake()
                if shake then
                    local function ease(x) x=math.clamp(x,0,1);return x*x*(3-2*x) end
                    local envelope=ease(shake/.16)*(1-ease((shake-.62)/.38))
                    local keys={{0,0},{.16,.25},{.28,-1},{.42,.60},{.57,-.22},{.72,0},{1,0}}
                    local wave=0
                    for i=2,#keys do
                        local a,b=keys[i-1],keys[i]
                        if shake<=b[1] then wave=a[2]+(b[2]-a[2])*ease((shake-a[1])/(b[1]-a[1]));break end
                    end
                    local reaction=CFrame.new(-.44,-.19,-1.08)*CFrame.Angles(math.rad(108),math.rad(52),math.rad(48))
                    local forearm=camera.CFrame*(JumpMotion and JumpMotion.Frame() or CFrame.new())*resting:Lerp(reaction,envelope)
                    rig.shakeForearm=forearm
                    local hinge=CFrame.new(0,.12,0)
                    pose=forearm*hinge*CFrame.Angles(math.rad(-28)*envelope+math.rad(28)*wave,
                        math.rad(15)*wave,math.rad(48)*wave)*hinge:Inverse()
                end
            end
            pose=pose*CFrame.new(settings.customArmX,settings.customArmY,settings.customArmZ)
            if Inspect then pose=Inspect.TransformArm(pose) end
            if side=="Right" then pose=api.RightPose(camera) else pose=api.GesturePose(camera,side,pose) end
            rig.gunWeight=(rig.gunWeight or 0)+((gun and 1 or 0)-(rig.gunWeight or 0))*(1-math.exp(-22*math.min(dt or 1/60,.1)))
            if gun then
                local stable=GunViewmodel and GunViewmodel.Frame(camera) or gun.CFrame
                local anchor=Inspect and Inspect.GripFrame(stable) or stable
                local grip=anchor.Position-camera.CFrame.UpVector*.045+camera.CFrame.LookVector*.025
                local support=side=="Left" and (-camera.CFrame.RightVector*.145-camera.CFrame.UpVector*.025+camera.CFrame.LookVector*.025) or Vector3.zero
                local gunPose=CFrame.new(grip+support)*camera.CFrame.Rotation
                    *CFrame.Angles(math.rad(125),math.rad(side=="Left" and 12 or 0),math.rad(side=="Left" and 32 or -25))
                local gunInspect=Inspect and Inspect.Phase()
                if gunInspect and side=="Left" then
                    local enter=math.clamp(gunInspect/.13,0,1)
                    local leave=math.clamp((gunInspect-.80)/.20,0,1)
                    local away=enter*(1-leave)
                    gunPose=gunPose:Lerp(camera.CFrame*CFrame.new(-.60,-1.20,-.80)
                        *CFrame.Angles(math.rad(145),0,math.rad(35)),away)
                end
                pose=pose:Lerp(api.GesturePose(camera,side,gunPose),rig.gunWeight)
            end
            local gloveColor=color
            rig.palm.CFrame=pose;rig.palm.Color=gloveColor
            for _,entry in ipairs(rig.fixed) do
                local frame=pose
                if side=="Right" and Voidglass and Voidglass.Jabbing() and
                    (entry.part.Name=="Rounded forearm" or entry.part.Name=="Forearm rounded cap" or entry.part.Name=="Lower forearm blend" or entry.part.Name=="Wrist blend") then
                    frame=api.RightBase(camera):Lerp(pose,.25)
                end
                if side=="Left" and rig.shakeForearm and
                    (entry.part.Name=="Rounded forearm" or entry.part.Name=="Forearm rounded cap" or entry.part.Name=="Lower forearm blend" or entry.part.Name=="Wrist blend") then
                    frame=rig.shakeForearm
                end
                entry.part.CFrame=frame*entry.offset
                entry.part.Color=entry.tint or ((entry.part.Name=="Thumb pad" or entry.part.Name=="Wrist blend") and gloveColor or color)
            end
            for _,entry in ipairs(rig.joints) do
                local curl=held and (side=="Right" and .88 or .5) or .08
                if held and held.Name=="Gun" and side=="Right" and entry.finger==1 then curl=.2 end
                -- Open support pose: index extended, progressively softer curled outer fingers.
                if side=="Left" then curl=({.08,.14,.24,.34,.12})[entry.finger] end
                local gesture=BunnyHop and BunnyHop.GesturePhase()
                if gesture then curl=curl*(1-.92*math.sin(math.pi*gesture)) end
                curl=curl*(1-release*.85)
                local flex=math.rad(entry.finger==5 and 48 or ({64,82,58})[entry.bone])*curl
                local alpha=1-math.exp(-24*math.min(dt or 1/60,.1))
                local spread=side=="Left" and entry.bone==1 and math.rad(({ -10,-3,5,13,22 })[entry.finger]) or 0
                local thumbOpen=side=="Left" and entry.finger==5 and math.rad(({18,12,8})[entry.bone]) or 0
                if side=="Left" and entry.finger==5 then
                    -- Curve in the palm plane as well as at the knuckles.
                    spread=math.rad(({12,-28,-32})[entry.bone])
                end
                if side=="Left" then
                    -- Each phalanx has its own bend; avoid the uniform mitten silhouette.
                    local bends={{4,9,6},{7,15,10},{12,24,17},{18,32,23},{12,30,38}}
                    flex=math.rad(bends[entry.finger][entry.bone])*(1-release*.35)
                end
                if gesture and side=="Right" then
                    local open=math.sin(math.pi*gesture)
                    flex=flex*(1-.9*open)
                    if entry.bone==1 then
                        spread=math.rad(({-7,-2,4,10,-16})[entry.finger])*open
                        if entry.finger==5 then thumbOpen=math.rad(-22)*open end
                    end
                end
                if gun and not gesture then
                    local bends
                    if side=="Left" then bends=entry.finger==5 and {32,42,30} or {62,78,54}
                    elseif entry.finger==1 then bends={16,32,24}
                    elseif entry.finger==5 then bends={38,48,32}
                    else bends={66,82,56} end
                    flex=math.rad(bends[entry.bone]);spread=0;thumbOpen=0
                    if entry.finger==5 and entry.bone==1 then thumbOpen=math.rad(side=="Left" and 16 or -12) end
                end
                local gunInspect=gun and Inspect and Inspect.Phase()
                if gunInspect and side=="Right" then
                    local spinWindow=math.clamp((gunInspect-.12)/.10,0,1)*(1-math.clamp((gunInspect-.75)/.15,0,1))
                    if entry.finger==1 then flex=math.rad(({14,38,28})[entry.bone])
                    elseif entry.finger==5 then flex=math.rad(24)*(1-spinWindow*.65);thumbOpen=-math.rad(20)*spinWindow
                    else flex=flex*(1-spinWindow*.88);spread=math.rad((entry.finger-2)*6)*spinWindow end
                end
                local butterflyPhase=side=="Right" and held and held.Name:find("BUTTERFLY",1,true)
                    and Voidglass and Voidglass.InspectPhase()
                if butterflyPhase then
                    local p=butterflyPhase
                    local function pulse(center,width) return math.max(0,1-math.abs(p-center)/width) end
                    -- Thumb/index retain the safe handle; the other fingers open for each pass.
                    local release=math.max(pulse(.30,.18),pulse(.56,.13),pulse(.73,.12))
                    if entry.finger==1 then
                        flex=math.rad(({48,68,46})[entry.bone])*(1-release*.2)
                    elseif entry.finger==5 then
                        flex=math.rad(({35,48,30})[entry.bone]);thumbOpen=math.rad(-12)*release
                    else
                        flex=math.rad(({65,82,56})[entry.bone])*(1-release*.85)
                        if entry.bone==1 then spread=math.rad((entry.finger-2)*5)*release end
                    end
                end
                if side=="Right" and held and held.Name:find("BUTTERFLY",1,true) and entry.finger==5 and not butterflyPhase then
                    flex=math.rad(({58,72,48})[entry.bone]);thumbOpen=math.rad(18)
                end
                local stabPhase=side=="Right" and held and held.Name:find("BUTTERFLY",1,true)
                    and Voidglass and Voidglass.StabPhase()
                if stabPhase then
                    -- Brief grip adjustment during the pullback, then a firm catch on the thrust.
                    local open=math.sin(math.pi*math.clamp(stabPhase/.24,0,1))^2
                    local thrust=Voidglass.StabExtension()
                    if entry.finger==5 then
                        flex=math.rad(({58,72,48})[entry.bone])*(1-open*.18)
                        thumbOpen=math.rad(18)*(1-open*.5)
                    else
                        local closed=math.rad(({62,86,64})[entry.bone])
                        flex=closed*(1-open*.55)+math.rad(5)*thrust
                        if entry.bone==1 then spread=math.rad((entry.finger-2)*4)*open end
                    end
                    local recovery=Voidglass.Jabbing() and 0 or math.clamp((stabPhase-.3235)/.6565,0,1)
                    local release=math.sin(math.pi*recovery)^2
                    local guide=math.sin(2*math.pi*recovery)
                    if entry.finger==1 then
                        -- Index retains contact and guides the handle around the pivot.
                        flex=math.rad(({48,68,42})[entry.bone])+math.rad(12)*guide
                        if entry.bone==1 then spread=math.rad(10)*guide end
                    elseif entry.finger==5 then
                        flex=flex*(1-release*.45)
                        thumbOpen=thumbOpen-math.rad(24)*release
                    else
                        flex=flex*(1-release*.48)
                        if entry.bone==1 then spread=spread+math.rad((entry.finger-1)*2.5)*release end
                    end
                end
                local leftShake=side=="Left" and Voidglass and Voidglass.LeftShake()
                if leftShake then
                    local flutter=math.sin(leftShake*math.pi*4+entry.finger*.25)*math.sin(math.pi*leftShake)^2
                    local open=math.sin(math.pi*leftShake)^2
                    local relaxed=math.rad(entry.finger==5 and 22 or entry.finger<=2 and 5 or 18)
                    flex=flex*(1-open)+relaxed*open+math.rad(6)*flutter
                    if entry.bone==1 then spread=spread+math.rad((entry.finger-3)*2)*math.sin(math.pi*leftShake)^2 end
                end
                entry.motor.Transform=entry.motor.Transform:Lerp(CFrame.Angles(-flex,thumbOpen,spread),alpha)
                entry.part.CFrame=entry.parent.CFrame*entry.motor.C0*entry.motor.Transform*entry.motor.C1:Inverse()
                entry.part.Color=color
                entry.blend.CFrame=entry.parent.CFrame*entry.motor.C0*entry.motor.Transform
                entry.blend.Color=color
            end
            fingerInk(rig,camera)
        end
        for _,name in ipairs({"Left Arm","Right Arm","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand"}) do
            local part=current:FindFirstChild(name)
            if part and part:IsA("BasePart") then if hidden[part]==nil then hidden[part]=part.LocalTransparencyModifier end;part.LocalTransparencyModifier=1 end
        end
    end
    return api
end)()
button(UIRefs.skinsPage,"White wireframe",function()
    settings.wireRed=255;settings.wireGreen=255;settings.wireBlue=255;settings.wireWidth=1
    for _,key in ipairs({"wireRed","wireGreen","wireBlue","wireWidth"}) do if stateRefreshers[key] then stateRefreshers[key]() end end
end)
toggle(UIRefs.skinsPage,"Arms wireframe","wireArms")
toggle(UIRefs.skinsPage,"All knives · wireframe","wireKnife")
UIRefs.ColourPicker(UIRefs.skinsPage,"Wire colour",{"wireRed","wireGreen","wireBlue"})
toggle(UIRefs.skinsPage,"Arm contour lines","wireContours")
slider(UIRefs.skinsPage,"Hands contour opacity","contourOpacity",0,1,function(v) return string.format("%.0f%%",v*100) end)
UIRefs.ColourPicker(UIRefs.skinsPage,"Hands contour colour",{"contourRed","contourGreen","contourBlue"})
slider(UIRefs.skinsPage,"Wire thickness","wireWidth",.5,3,function(v) return string.format("%.1f px",v) end)
UIRefs.handsButton=nil
UIRefs.handsButton=button(UIRefs.skinsPage,"Procedural hands: OFF · click to enable",function() stateAppliers.customArms(not settings.customArms) end)
stateRefreshers.customArms=function()
    UIRefs.handsButton.Text=settings.customArms and "Procedural hands: ON · click to disable" or "Procedural hands: OFF · click to enable"
end
stateAppliers.customArms=function(enabled)
    settings.customArms=enabled;GripArms.Reset();stateRefreshers.customArms()
end
for _,axis in ipairs({"X","Y","Z"}) do
    slider(UIRefs.skinsPage,"Hand offset "..axis,"customArm"..axis,-1,1,function(v) return string.format("%.2f",v) end)
end

GunAudio = (function()
    local api, changed, preview = {}, {}, nil
    local asset = "rbxassetid://132948338000932"
    local reloadAsset = "rbxassetid://9125410132"
    function api.Warm()
        task.spawn(function()
            local sound = make("Sound", {SoundId = reloadAsset})
            pcall(function() game:GetService("ContentProvider"):PreloadAsync({sound}) end)
            sound:Destroy()
        end)
    end
    function api.Reset()
        for sound, original in pairs(changed) do
            if original.connection then original.connection:Disconnect() end
            if sound.Parent then sound.SoundId, sound.Volume = original.id, original.volume end
        end
        table.clear(changed)
        if preview then preview:Destroy(); preview = nil end
    end
    function api.Step()
        if not settings.bubbleShot then if next(changed) then api.Reset() end; return end
        local character, tool = player.Character, nil
        if character then
            for _, object in ipairs(character:GetChildren()) do
                if object:IsA("Tool") and string.lower(object.Name) == "gun" then tool = object; break end
            end
        end
        for sound, original in pairs(changed) do
            if original.deadline and os.clock() >= original.deadline then
                if sound.Parent and sound.IsPlaying then sound:Stop() end
                original.deadline = nil
            end
            if not sound.Parent then
                if original.connection then original.connection:Disconnect() end
                changed[sound] = nil
            elseif not tool or not sound:IsDescendantOf(tool) then
                -- Keep an in-flight shot/reload replaced after its tool leaves the hand.
                if original.reload and sound.IsPlaying then sound:Stop() end
                if not sound.IsPlaying then
                    if original.connection then original.connection:Disconnect() end
                    sound.SoundId, sound.Volume = original.id, original.volume
                    changed[sound] = nil
                end
            end
        end
        if not tool then return end
        for _, object in ipairs(tool:GetDescendants()) do
            if object:IsA("Sound") then
                local name = string.lower(object.Name):gsub("[%s_%-]", "")
                local shot = name == "gunshot" or name == "shoot" or name == "shot" or name == "fire"
                    or name == "firesound" or name == "shootsound" or name == "gunfire"
                local reload = name:find("reload",1,true) ~= nil
                if shot or reload then
                    if not changed[object] then
                        local original = {id = object.SoundId, volume = object.Volume, reload = reload,
                            duration = object.TimeLength / math.max(object.PlaybackSpeed,0.01)}
                        changed[object] = original
                        if reload then
                            if original.duration <= 0 then
                                task.spawn(function()
                                    local probe = make("Sound", {SoundId = original.id})
                                    pcall(function() game:GetService("ContentProvider"):PreloadAsync({probe}) end)
                                    if probe.TimeLength > 0 then original.duration = probe.TimeLength / math.max(object.PlaybackSpeed,0.01) end
                                    probe:Destroy()
                                end)
                            end
                            original.connection = object.Played:Connect(function()
                                object.TimePosition = 0.35
                                original.deadline = original.duration > 0 and (os.clock()+original.duration) or nil
                            end)
                        end
                    end
                    object.SoundId = reload and reloadAsset or asset
                    local gain = 1
                    local original = changed[object]
                    if reload and original.deadline then
                        local fadeDuration = math.min(0.3, original.duration * 0.4)
                        gain = math.clamp((original.deadline - os.clock()) / math.max(fadeDuration,0.01),0,1)
                    end
                    object.Volume = (reload and settings.bubbleReloadVolume or settings.bubbleShotVolume) * gain
                end
            end
        end
    end
    function api.Preview(reload)
        if preview then preview:Destroy() end
        preview = make("Sound", {Name = "StarfireBubblePreview", SoundId = reload and reloadAsset or asset,
            Volume = reload and settings.bubbleReloadVolume or settings.bubbleShotVolume}, game:GetService("SoundService"))
        game:GetService("SoundService"):PlayLocalSound(preview)
    end
    return api
end)()
toggle(UIRefs.gunsPage, "Bubble shot + reload · local", "bubbleShot", function(enabled)
    if enabled then GunAudio.Warm() else GunAudio.Reset() end
end)
slider(UIRefs.gunsPage, "Bubble shot volume", "bubbleShotVolume", 0, 5, function(v) return string.format("%.0f%%",v*100) end)
button(UIRefs.gunsPage, "Preview bubble pop", function() GunAudio.Preview() end)
slider(UIRefs.gunsPage, "Bubble reload volume", "bubbleReloadVolume", 0, 5, function(v) return string.format("%.0f%%",v*100) end)
button(UIRefs.gunsPage, "Preview bubbly reload", function() GunAudio.Preview(true) end)

Skins = (function()
    local api, state, generation = {}, nil, 0
    local function karambit(crimson)
        local model = make("Model", {Name = "StarfireKarambit"})
        local blade = crimson and Color3.fromRGB(210, 45, 65) or Color3.fromRGB(190, 210, 230)
        local grip = Color3.fromRGB(29, 30, 39)
        local function segment(name, a, b, width, depth, color, material)
            local middle = (a + b) / 2
            return make("Part", {Name = name, Size = Vector3.new(width, depth, (b-a).Magnitude + 0.025),
                CFrame = CFrame.lookAt(middle, b), Color = color, Material = material,
                Anchored = true, CanCollide = false, CanTouch = false, CanQuery = false,
                CastShadow = false}, model)
        end
        segment("Handle", Vector3.new(0,0,-0.45), Vector3.new(0,0,0.45), 0.22, 0.18, grip, Enum.Material.SmoothPlastic)
        for i=0,5 do
            local z = -0.32+i*0.13
            segment("Grip wrap", Vector3.new(-0.125,0,z), Vector3.new(0.125,0,z), 0.045, 0.20,
                Color3.fromRGB(67,65,81), Enum.Material.SmoothPlastic)
        end
        local center = Vector3.new(0,0,0.69)
        for i=0,17 do
            local a, b = i*math.pi*2/18, (i+1)*math.pi*2/18
            segment("Finger ring", center+Vector3.new(math.cos(a)*0.23,0,math.sin(a)*0.23),
                center+Vector3.new(math.cos(b)*0.23,0,math.sin(b)*0.23), 0.075,0.12,blade,Enum.Material.Metal)
        end
        -- A tapering hook curves forward from the grip, then back toward its tip.
        local points = {Vector3.new(0,0,-0.43), Vector3.new(0.23,0,-0.65), Vector3.new(0.51,0,-0.82),
            Vector3.new(0.78,0,-0.84), Vector3.new(1.01,0,-0.72), Vector3.new(1.16,0,-0.48), Vector3.new(1.17,0,-0.23)}
        for i=1,#points-1 do
            segment("Hook blade",points[i],points[i+1],0.25*(1-i/#points)+0.025,0.075,blade,Enum.Material.Metal)
        end
        return model
    end
    local function restore(current)
        for part, original in pairs(current.hidden) do
            if part.Parent then part.LocalTransparencyModifier = WeaponVisuals.Managed(part) and 1 or original end
        end
        table.clear(current.hidden)
    end
    function api.Reset()
        generation = generation + 1
        if state then restore(state); state.model:Destroy(); state = nil end
    end
    function api.Load()
        api.Reset()
        local builtin = settings.skinAssetId == "builtin:karambit" or settings.skinAssetId == "builtin:crimson"
        local id = builtin and settings.skinAssetId or tostring(settings.skinAssetId):match("^%d+$")
        if not id or (not builtin and #id > 18) then notify("Enter a numeric Roblox model asset ID", true); return end
        local token = generation
        notify("Loading local weapon model " .. id .. "…")
        task.spawn(function()
            local roots, model = {}, nil
            local ok, err = pcall(function()
                roots = builtin and {karambit(id == "builtin:crimson")} or game:GetObjects("rbxassetid://" .. id)
                if token ~= generation or not running then return end
                local sourceParts, handle = {}, nil
                for _, root in ipairs(roots) do
                    local objects = root:GetDescendants(); table.insert(objects, root)
                    for _, object in ipairs(objects) do
                        if object:IsA("BasePart") then
                            table.insert(sourceParts, object)
                            if string.lower(object.Name) == "handle" then handle = object end
                        end
                    end
                end
                assert(#sourceParts > 0 and #sourceParts <= 250, "Asset must contain 1–250 visual parts")
                handle = handle or sourceParts[1]
                local pivot = handle.CFrame
                model = make("Model", {Name = "StarfireLocalWeaponSkin"})
                for _, sourcePart in ipairs(sourceParts) do
                    local copy = sourcePart:Clone()
                    assert(copy, "Weapon part could not be copied")
                    for _, child in ipairs(copy:GetChildren()) do
                        if not (child:IsA("SpecialMesh") or child:IsA("BlockMesh") or child:IsA("CylinderMesh")
                            or child:IsA("SurfaceAppearance") or child:IsA("Decal") or child:IsA("Texture")) then child:Destroy() end
                    end
                    for _, child in ipairs(copy:GetDescendants()) do if child:IsA("LuaSourceContainer") then child:Destroy() end end
                    copy.Anchored, copy.CanCollide, copy.CanTouch, copy.CanQuery, copy.Massless = true, false, false, false, true
                    copy.AssemblyLinearVelocity, copy.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
                    copy.CFrame = pivot:ToObjectSpace(sourcePart.CFrame)
                    copy.Parent = model
                end
                model.WorldPivot = CFrame.new()
                local _, size = model:GetBoundingBox()
                assert(size.Magnitude < 1000, "Asset is too large for a weapon skin")
                local normalise = (settings.skinKind == "Knife" and 2.8 or 3.6) / math.max(size.X, size.Y, size.Z, 0.01)
                model:ScaleTo(normalise)
                if token ~= generation or not running then return end
                state = {model = model, hidden = {}, scale = settings.skinScale, baseScale = model:GetScale()}
                model:ScaleTo(state.baseScale * settings.skinScale)
                model = nil
                notify("Weapon skin loaded locally · adjust scale/rotation to fit")
            end)
            for _, root in ipairs(roots) do root:Destroy() end
            if model then model:Destroy() end
            if not ok and token == generation and running then
                settings.skinChanger = false
                if stateRefreshers.skinChanger then stateRefreshers.skinChanger() end
                notify("Skin model unavailable: " .. tostring(err), true)
            end
        end)
    end
    local function normalGunLength(tool,handle)
        local lo,hi=Vector3.new(math.huge,math.huge,math.huge),Vector3.new(-math.huge,-math.huge,-math.huge)
        local count=0
        for _,part in ipairs(tool:GetDescendants()) do
            if part:IsA("BasePart") and part.Transparency<1 then
                for _,x in ipairs({-1,1}) do for _,y in ipairs({-1,1}) do for _,z in ipairs({-1,1}) do
                    local p=handle.CFrame:PointToObjectSpace(part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)*.5))
                    lo=Vector3.new(math.min(lo.X,p.X),math.min(lo.Y,p.Y),math.min(lo.Z,p.Z))
                    hi=Vector3.new(math.max(hi.X,p.X),math.max(hi.Y,p.Y),math.max(hi.Z,p.Z))
                end end end
                count=count+1
            end
        end
        if count==0 then return math.max(handle.Size.X,handle.Size.Y,handle.Size.Z) end
        local size=hi-lo;return math.max(size.X,size.Y,size.Z,.1)
    end
    function api.HasModel() return state ~= nil end
    function api.Step()
        local current = state
        if not current then return end
        if not settings.skinChanger then api.Reset(); return end
        local character, tool = player.Character, nil
        if living(character) then
            for _, object in ipairs(character:GetChildren()) do
                if object:IsA("Tool") and string.lower(object.Name) == string.lower(settings.skinKind) then tool = object; break end
            end
        end
        local handle = tool and tool:FindFirstChild("Handle")
        if not handle or not handle:IsA("BasePart") then restore(current); current.model.Parent = nil; return end
        for part, original in pairs(current.hidden) do
            if not part:IsDescendantOf(tool) then
                if part.Parent then part.LocalTransparencyModifier = original end
                current.hidden[part] = nil
            end
        end
        for _, part in ipairs(tool:GetDescendants()) do
            if part:IsA("BasePart") then
                if current.hidden[part] == nil then current.hidden[part] = WeaponVisuals.Original(part, "LocalTransparencyModifier") end
                part.LocalTransparencyModifier = 1
            end
        end
        local desiredScale=settings.skinScale
        if settings.skinKind=="Gun" and settings.gunMatchSize then
            if current.nativeTool~=tool then current.nativeTool=tool;current.nativeLength=normalGunLength(tool,handle) end
            desiredScale=math.clamp(current.nativeLength,.65,1.25)/3.6
        end
        local camera=Workspace.CurrentCamera
        if settings.skinKind=="Gun" and camera and (camera.CFrame.Position-camera.Focus.Position).Magnitude<1.2 then
            desiredScale=desiredScale*settings.gunViewSize
        end
        if current.scale~=desiredScale then
            current.model:ScaleTo(current.baseScale*desiredScale);current.scale=desiredScale
        end
        current.model:PivotTo((Inspect and Inspect.Transform((GunViewmodel and GunViewmodel.Frame(Workspace.CurrentCamera)) or handle.CFrame) or handle.CFrame) * CFrame.new(settings.skinOffsetX, settings.skinOffsetY, settings.skinOffsetZ)
            * CFrame.Angles(math.rad(settings.skinPitch), math.rad(settings.skinYaw), math.rad(settings.skinRoll)))
        current.model.Parent = effects
        for _, part in ipairs(current.model:GetChildren()) do
            if part:IsA("BasePart") then
                part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery = true, false, false, false
                if settings.skinKind=="Knife" and WireStyle then WireStyle.Register(part,"knife",current.model) end
            end
        end
    end
    return api
end)()
UIRefs.skinAssetField = make("TextBox", {Text = settings.skinAssetId, PlaceholderText = "Roblox weapon model asset ID",
    ClearTextOnFocus = false, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = colors.text,
    PlaceholderColor3 = colors.muted, BackgroundColor3 = colors.raised, BorderSizePixel = 0,
    Size = UDim2.new(1, -2, 0, 40)}, UIRefs.skinsPage)
round(UIRefs.skinAssetField, 3)
UIRefs.skinPresets = {{"Karambit · steel", "builtin:karambit", "Knife"}, {"Karambit · crimson", "builtin:crimson", "Knife"},
    {"Valorant Revolver", "13913933689", "Gun"}, {"Vandal Valorant", "9814289916", "Gun"}}
UIRefs.presetIndex = 0
UIRefs.presetButton=nil
UIRefs.presetButton = button(UIRefs.skinsPage, "Choose weapon visual preset", function()
    UIRefs.presetIndex = UIRefs.presetIndex % #UIRefs.skinPresets + 1
    local preset = UIRefs.skinPresets[UIRefs.presetIndex]
    settings.skinAssetId, settings.skinKind, UIRefs.skinAssetField.Text = preset[2], preset[3], preset[2]
    UIRefs.presetButton.Text = preset[1]
    if stateRefreshers.skinKind then stateRefreshers.skinKind() end
end)
UIRefs.skinKindButton=nil
UIRefs.skinKindButton = button(UIRefs.skinsPage, "Weapon: Gun · click to switch", function()
    settings.skinKind = settings.skinKind == "Gun" and "Knife" or "Gun"
    UIRefs.skinKindButton.Text = "Weapon: " .. settings.skinKind .. " · click to switch"
end)
stateRefreshers.skinKind = function() UIRefs.skinKindButton.Text = "Weapon: " .. settings.skinKind .. " · click to switch" end
stateRefreshers.skinAssetId = function() UIRefs.skinAssetField.Text = settings.skinAssetId end
toggle(UIRefs.skinsPage, "Local weapon skin", "skinChanger", function(enabled)
    if enabled then Skins.Load() else Skins.Reset() end
end)
button(UIRefs.skinsPage, "Apply model asset", function()
    local text = UIRefs.skinAssetField.Text
    local id = (text == "builtin:karambit" or text == "builtin:crimson") and text or text:match("^%s*(%d+)%s*$")
    if not id then notify("Enter a numeric Roblox model ID", true); return end
    settings.skinAssetId, settings.skinChanger = id, true
    stateRefreshers.skinChanger(); Skins.Load()
end)
slider(UIRefs.skinsPage,"First-person gun size","gunViewSize",.2,1.2,function(v) return string.format("%.2fx",v) end,function() GunViewmodel.Reset() end)
stateAppliers.gunViewSize=function(v)
    settings.gunViewSize=math.clamp(v,.2,1.2);GunViewmodel.Reset()
    if stateRefreshers.gunViewSize then stateRefreshers.gunViewSize() end
end
toggle(UIRefs.skinsPage,"Match normal gun size","gunMatchSize")
slider(UIRefs.skinsPage, "Model scale", "skinScale", 0.25, 3, function(v) return string.format("%.2fx", v) end)
for _, axis in ipairs({"Pitch", "Yaw", "Roll"}) do
    slider(UIRefs.skinsPage, "Model " .. axis, "skin" .. axis, -180, 180, function(v) return string.format("%.0f°", v) end)
end
for _, axis in ipairs({"X", "Y", "Z"}) do
    slider(UIRefs.skinsPage, "Offset " .. axis, "skinOffset" .. axis, -3, 3, function(v) return string.format("%.2f", v) end)
end

local ConfigCodec = (function()
    local api = {}
    function api.Name(name)
        assert(type(name) == "string", "Config name must be text")
        name = name:match("^%s*(.-)%s*$")
        assert(#name > 0 and #name <= 32 and name:match("^[%w_ %-]+$"), "Use 1–32 letters, numbers, spaces, _ or -")
        return name
    end
    local function binding(kind, name)
        assert(type(name) == "string" and #name < 40, "Invalid keybind")
        local group = kind == "UserInputType" and Enum.UserInputType or Enum.KeyCode
        local ok, value = pcall(function() return group[name] end)
        assert(ok and value and value ~= Enum.KeyCode.Unknown, "Unknown keybind")
        if kind == "UserInputType" then
            assert(value == Enum.UserInputType.MouseButton1 or value == Enum.UserInputType.MouseButton2
                or value == Enum.UserInputType.MouseButton3, "Unsupported mouse binding")
        else assert(kind == "KeyCode", "Invalid keybind type") end
        assert(value ~= Enum.KeyCode.B and value ~= Enum.KeyCode.RightShift and value ~= Enum.KeyCode.Escape, "Key is reserved")
        return value
    end
    function api.Validate(profile)
        assert(type(profile) == "table" and type(profile.settings) == "table", "Invalid config data")
        local result = {settings = {}, inputs = {}, bindings = {}}
        for key, fallback in pairs(defaultSettings) do
            local value = profile.settings[key]
            if value == nil then value = fallback end
            assert(type(value) == type(fallback), "Wrong value type for " .. key)
            if type(value) == "number" then
                assert(value == value and math.abs(value) < 1000000, "Invalid number for " .. key)
                local limits = settingLimits[key]
                if limits then value = math.clamp(value, limits[1], limits[2]) end
            elseif type(value) == "string" then assert(#value <= 128, "Setting text too long") end
            result.settings[key] = value
        end
        local keys = profile.bindings or {}
        assert(type(keys) == "table", "Invalid keybind data")
        local aim = keys.aim or {kind = "UserInputType", name = "MouseButton2"}
        assert(type(aim) == "table", "Invalid aim binding")
        result.aim = binding(aim.kind, aim.name)
        result.pickup = binding("KeyCode", keys.pickup or "O")
        result.response = binding("KeyCode", keys.response or "G")
        assert(result.aim ~= result.pickup and result.aim ~= result.response and result.pickup ~= result.response, "Keybinds conflict")
        result.bindings = {aim = {kind = aim.kind, name = aim.name}, pickup = result.pickup.Name, response = result.response.Name}
        local inputs = profile.inputs or {}
        assert(type(inputs) == "table", "Invalid saved input fields")
        for _, key in ipairs({"avatar", "swingIds", "emote"}) do
            local value = inputs[key] or ""
            assert(type(value) == "string" and #value <= 2048, "Invalid input field")
            result.inputs[key] = value
        end
        return result
    end
    return api
end)()
local Configs = (function()
    local api, profiles, selected, defaultName = {}, {}, "Default", "Default"
    local selector, nameField, jsonField, savedList, autoLoadLabel
    local savedRows={}
    local restored = false
    local folder = playerGui:FindFirstChild("StarfireMM2Profiles")
    if not folder then folder = make("ScreenGui", {Name = "StarfireMM2Profiles", ResetOnSpawn = false, Enabled = false}, playerGui) end
    local session = folder:FindFirstChild("Profiles") or make("StringValue", {Name = "Profiles", Value = ""}, folder)
    local diskPath = "StarfireMM2/configs.json"
    local function snapshot()
        return {settings = table.clone(settings), bindings = {aim = {
            kind = aimKey.EnumType == Enum.KeyCode and "KeyCode" or "UserInputType", name = aimKey.Name},
            pickup = gunKey.Name, response = responseKey.Name},
            inputs = {avatar = UIRefs.avatarUsername.Text, swingIds = UIRefs.swingIds.Text, emote = UIRefs.emoteId.Text}}
    end
    local function names()
        local result = {}; for name in pairs(profiles) do table.insert(result, name) end
        table.sort(result); return result
    end
    local function refresh()
        if selector then selector.Text = "Config: " .. selected .. (selected == defaultName and " · default" or "") end
        if nameField then nameField.Text = selected end
        if autoLoadLabel then autoLoadLabel.Text="Auto-load: "..defaultName end
        if savedList then
            for name,row in pairs(savedRows) do if not profiles[name] then row:Destroy();savedRows[name]=nil end end
            for index,name in ipairs(names()) do
                local row=savedRows[name]
                if not row then
                    row=make("TextButton",{Font=Enum.Font.GothamBold,TextSize=13,TextXAlignment=Enum.TextXAlignment.Left,
                        TextTruncate=Enum.TextTruncate.AtEnd,Size=UDim2.new(1,-8,0,34),BorderSizePixel=0,AutoButtonColor=false},savedList)
                    round(row,5);savedRows[name]=row
                    connect(row.Activated,function() selected=name;refresh() end)
                end
                row.LayoutOrder=index;row.Text="  "..name..(name==defaultName and "  · AUTO" or "")
                row.TextColor3=name==selected and colors.text or colors.muted
                row.BackgroundColor3=name==selected and colors.accentPanel or colors.raised
            end
        end
    end
    local function persist()
        local json = HttpService:JSONEncode({format = "StarfireMM2Configs", version = 1, default = defaultName, profiles = profiles})
        session.Value = json
        if type(writefile) == "function" then
            local ok = pcall(function()
                if type(makefolder) == "function" and (type(isfolder) ~= "function" or not isfolder("StarfireMM2")) then makefolder("StarfireMM2") end
                writefile(diskPath, json)
            end)
            return ok and "disk + session" or "session only · disk write failed"
        end
        return "session only · export JSON for later"
    end
    local function decodeStore(json)
        assert(type(json) == "string" and #json <= 524288, "Invalid config store size")
        local doc = HttpService:JSONDecode(json)
        assert(type(doc) == "table" and doc.format == "StarfireMM2Configs" and doc.version == 1 and type(doc.profiles) == "table", "Unknown config store")
        local result, count = {}, 0
        for name, profile in pairs(doc.profiles) do
            name = ConfigCodec.Name(name)
            ConfigCodec.Validate(profile)
            result[name], count = profile, count + 1
            assert(count <= 40, "Too many configs")
        end
        assert(count > 0, "Empty config store")
        return result, doc.default
    end
    local raw = session.Value
    if raw == "" and type(readfile) == "function" then
        local ok, data = pcall(readfile, diskPath)
        if ok and type(data) == "string" then raw = data end
    end
    if raw ~= "" then
        local ok, loaded, preferred = pcall(decodeStore, raw)
        if ok then
            profiles, restored = loaded, true
            local sorted = names(); defaultName = profiles[preferred] and preferred or sorted[1]; selected = defaultName
            session.Value = raw
        else notify("Saved configs could not be read; defaults are available", true) end
    end
    if not next(profiles) then profiles.Default = snapshot() end
    local function protected(action)
        local ok, err = pcall(action)
        if not ok then notify("Config: " .. tostring(err), true) end
    end
    function api.Load(name)
        local profile = assert(profiles[name], "Config not found")
        local validated = ConfigCodec.Validate(profile)
        Fling.Stop(true); Scare.Stop(true); Evade.Stop(true)
        stopSweep(true); Automation.StopBag(true); stopCollecting(true, false)
        AvatarClone.Stop(); Ghost.Reset(); Mobility.Reset(); VisualSpin.Reset(); Skins.Reset()
        captureAim, captureGun, captureResponse, aiming = false, false, false, false
        for key, value in pairs(validated.settings) do settings[key] = value end
        aimKey, gunKey, responseKey = validated.aim, validated.pickup, validated.response
        UIRefs.avatarUsername.Text, UIRefs.swingIds.Text, UIRefs.emoteId.Text = validated.inputs.avatar, validated.inputs.swingIds, validated.inputs.emote
        Evade.SetIds(UIRefs.swingIds.Text)
        local ordered = {ghost = true, avatarClone = true, visualSpin = true, fly = true, noclip = true, coinCollect = true, skinChanger = true}
        for key, apply in pairs(stateAppliers) do if not ordered[key] then apply(validated.settings[key]) end end
        for _, key in ipairs({"ghost", "avatarClone", "visualSpin", "fly", "noclip", "skinChanger", "coinCollect"}) do
            local value = validated.settings[key]
            if key == "ghost" and validated.settings.avatarClone then value = false end
            stateAppliers[key](value)
        end
        if track then pcall(function() track:AdjustSpeed(settings.emoteSpeed) end) end
        for _, refreshControl in pairs(stateRefreshers) do refreshControl() end
        refreshAimBind(); refreshGunBind(); refreshResponseBind()
        selected = name; refresh(); notify("Loaded config: " .. name)
    end
    function api.AutoLoad()
        if restored then protected(function() api.Load(defaultName) end) end
    end
    nameField = make("TextBox", {Text = selected, PlaceholderText = "Config name", ClearTextOnFocus = false,
        Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
        BackgroundColor3 = colors.raised, BorderSizePixel = 0, Size = UDim2.new(1, -2, 0, 40)}, UIRefs.configsPage)
    round(nameField, 3)
    selector = button(UIRefs.configsPage, "Config: Default", function()
        local sorted = names(); local index = table.find(sorted, selected) or 0
        selected = sorted[index % #sorted + 1]; refresh()
    end)
    button(UIRefs.configsPage, "Save current settings", function() protected(function()
        local name = ConfigCodec.Name(nameField.Text)
        assert(profiles[name] or #names() < 40, "Maximum 40 configs")
        local profile = snapshot(); ConfigCodec.Validate(profile)
        profiles[name], selected = profile, name; refresh()
        notify("Saved " .. name .. " · " .. persist())
    end) end)
    button(UIRefs.configsPage, "Save current as default", function() protected(function()
        local name=ConfigCodec.Name(nameField.Text)
        assert(profiles[name] or #names()<40,"Maximum 40 configs")
        local profile=snapshot();ConfigCodec.Validate(profile)
        profiles[name]=profile;selected=name;defaultName=name;refresh()
        notify("Current settings saved as default: "..name.." · "..persist())
    end) end)
    button(UIRefs.configsPage, "Load selected config", function() protected(function() api.Load(selected) end) end)
    button(UIRefs.configsPage, "Make selected the default", function() protected(function()
        defaultName = selected; refresh(); notify("Default: " .. selected .. " · " .. persist())
    end) end)
    button(UIRefs.configsPage, "Delete selected config", function() protected(function()
        assert(#names() > 1, "Keep at least one config")
        profiles[selected] = nil; selected = names()[1]
        if not profiles[defaultName] then defaultName = selected end
        refresh(); notify("Config deleted · " .. persist())
    end) end)
    autoLoadLabel=label(UIRefs.configsPage,"Auto-load: "..defaultName,13,colors.purple)
    autoLoadLabel.Size=UDim2.new(1,-2,0,25);autoLoadLabel:SetAttribute("PreferredColumn",2)
    savedList=make("ScrollingFrame",{Name="SavedConfigList",Size=UDim2.new(1,-2,0,180),BackgroundColor3=colors.background,
        BackgroundTransparency=.25,BorderSizePixel=0,ScrollBarThickness=3,ScrollBarImageColor3=colors.purple,
        AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),ScrollingDirection=Enum.ScrollingDirection.Y},UIRefs.configsPage)
    savedList:SetAttribute("SearchText","Saved configs list auto load");savedList:SetAttribute("PreferredColumn",2)
    round(savedList,6)
    make("UIPadding",{PaddingLeft=UDim.new(0,6),PaddingTop=UDim.new(0,6),PaddingBottom=UDim.new(0,6)},savedList)
    make("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder},savedList)
    button(UIRefs.configsPage,"Auto-load selected config",function() protected(function()
        assert(profiles[selected],"Choose a saved config first")
        defaultName=selected;refresh();notify("Auto-load: "..selected.." · "..persist())
    end) end):SetAttribute("PreferredColumn",2)
    button(UIRefs.configsPage,"Load selected now",function() protected(function() api.Load(selected) end) end):SetAttribute("PreferredColumn",2)
    section(UIRefs.configsPage, "Import / export")
    jsonField = make("TextBox", {Text = "", PlaceholderText = "Exported config JSON / paste JSON here to import",
        ClearTextOnFocus = false, MultiLine = true, TextWrapped = true,
        Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = colors.text, PlaceholderColor3 = colors.muted,
        BackgroundColor3 = colors.raised, BorderSizePixel = 0, TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top, Size = UDim2.new(1, -2, 0, 110)}, UIRefs.configsPage)
    round(jsonField, 3)
    button(UIRefs.configsPage, "Export selected to JSON", function() protected(function()
        jsonField.Text = HttpService:JSONEncode({format = "StarfireMM2Profile", version = 1, name = selected, profile = profiles[selected]})
        notify("Export ready · select and copy the JSON field")
    end) end)
    button(UIRefs.configsPage, "Import JSON as a config", function() protected(function()
        assert(#jsonField.Text <= 65536, "Import is too large")
        local doc = HttpService:JSONDecode(jsonField.Text)
        assert(type(doc) == "table" and doc.format == "StarfireMM2Profile" and doc.version == 1, "Unknown config format")
        local name = ConfigCodec.Name(doc.name or nameField.Text)
        assert(profiles[name] or #names() < 40, "Maximum 40 configs")
        ConfigCodec.Validate(doc.profile)
        profiles[name], selected = doc.profile, name; refresh()
        notify("Imported " .. name .. " · " .. persist())
    end) end)
    refresh()
    return api
end)()

for _, columns in pairs(pageColumns) do
    local rows, total = {}, 0
    for _, row in ipairs(columns[1]:GetChildren()) do
        if row:IsA("GuiObject") then
            table.insert(rows, row)
            total = total + row.Size.Y.Offset + 16
        end
    end
    local height, rightSide = 0, false
    for index, row in ipairs(rows) do
        local extent = row.Size.Y.Offset + 16
        row.LayoutOrder = index
        rightSide = rightSide or height >= total * 0.5
            or (height > 0 and math.abs(height - total * 0.5) < math.abs(height + extent - total * 0.5))
        if row:GetAttribute("PreferredColumn")==2 or rightSide then
            row.Parent = columns[2]
        else
            height = height + extent
        end
    end
end
-- Focused skin categories keep unrelated controls out of the current view.
do
    local columns=pageColumns.Skins
    local host=pages.Skins
    local rows={}
    for _,column in ipairs(columns) do
        column.Position=UDim2.new(column.Position.X.Scale,column.Position.X.Offset,0,82)
        column.Size=UDim2.new(column.Size.X.Scale,column.Size.X.Offset,1,-94)
        for _,row in ipairs(column:GetChildren()) do
            if row:IsA("GuiObject") then
                local text=row:GetAttribute("SearchText") or ""
                local category="Knife"
                if text:find("Hand") or text:find("hands") or text:find("gloves") or text:find("Glove") or text:find("Arms wire") or text:find("Wire colour") or text:find("Wire thickness") or text:find("White wireframe") or text:find("Black arm contour") then category="Hands"
                elseif row==UIRefs.skinAssetField or text:find("weapon") or text:find("Weapon:") or text:find("Model") or text:find("model") or text:find("Offset ") or text:find("revolver") or text:find("normal gun") or text:find("gun size") then category="Weapon" end
                row:SetAttribute("SkinCategory",category);table.insert(rows,row)
            end
        end
    end
    for _,card in ipairs(host:GetChildren()) do
        if card:IsA("Frame") then
            card.Position=UDim2.new(card.Position.X.Scale,card.Position.X.Offset,0,44)
            card.Size=UDim2.new(card.Size.X.Scale,card.Size.X.Offset,1,-44)
        end
    end
    local tabs={}
    local function show(category)
        local visible={}
        for _,row in ipairs(rows) do
            row.Visible=row:GetAttribute("SkinCategory")==category
            if row.Visible then table.insert(visible,row) end
        end
        table.sort(visible,function(a,b) return a.LayoutOrder<b.LayoutOrder end)
        for i,row in ipairs(visible) do row.Parent=columns[i<=math.ceil(#visible/2) and 1 or 2] end
        for name,tab in pairs(tabs) do tab.BackgroundColor3=name==category and colors.purple or colors.raised end
    end
    for i,name in ipairs({"Knife","Hands","Weapon"}) do
        local tab=make("TextButton",{Text=name,Font=Enum.Font.GothamBold,TextSize=14,TextColor3=colors.text,
            BackgroundColor3=colors.raised,BorderSizePixel=0,AutoButtonColor=false,
            Position=UDim2.new((i-1)/3,4,0,0),Size=UDim2.new(1/3,-12,0,32)},host)
        round(tab,6);tabs[name]=tab;connect(tab.Activated,function() show(name) end)
    end
    show("Knife")
end
selectPage("Aim")
animate(window, {GroupTransparency = 0}, 0.3)
notify("Right Shift: menu · O: gun · B: cursor teleport · aim is off")
Configs.AutoLoad()

-- Saved profiles own startup settings; do not overwrite their colours, hands or knife grip.
