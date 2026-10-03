--[[
    Velaris UI Library v1.0.0
    A modern, Rayfield-inspired script hub library for Roblox.

    Created for you. Usage:
        local Velaris = loadstring(game:HttpGet("https://raw.githubusercontent.com/YOURUSERNAME/velaris/main/Velaris.lua"))()
        local Window = Velaris:CreateWindow({ Name = "My Hub" })
        local Tab = Window:CreateTab("Main")
        Tab:CreateButton({ Name = "Print", Callback = function() print("Hi") end })
]]

local Velaris = {
    Version = "1.0.0",
    Flags = {},
    _UIs = {}
}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Helpers
local function Tween(obj, props, time, style, dir)
    time = time or 0.2
    style = style or Enum.EasingStyle.Quad
    dir = dir or Enum.EasingDirection.Out
    local info = TweenInfo.new(time, style, dir)
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function Corner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local function Stroke(obj, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(60,60,80)
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function Padding(obj, l, t, r, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 10)
    p.PaddingTop = UDim.new(0, t or 8)
    p.PaddingRight = UDim.new(0, r or 10)
    p.PaddingBottom = UDim.new(0, b or 8)
    p.Parent = obj
    return p
end

local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging = false
    local dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function GetParent()
    local parent
    pcall(function()
        if gethui then
            parent = gethui()
        elseif get_hidden_gui then
            parent = get_hidden_gui()
        end
    end)
    if not parent then
        if RunService:IsStudio() then
            parent = LocalPlayer and LocalPlayer:WaitForChild("PlayerGui")
        else
            parent = game:GetService("CoreGui")
        end
    end
    return parent
end

local Themes = {
    Dark = {
        Background = Color3.fromRGB(15, 15, 22),
        Topbar = Color3.fromRGB(20, 20, 30),
        Sidebar = Color3.fromRGB(17, 17, 26),
        Page = Color3.fromRGB(15, 15, 22),
        Element = Color3.fromRGB(24, 24, 36),
        ElementHover = Color3.fromRGB(30, 30, 46),
        Accent = Color3.fromRGB(139, 92, 246),
        Accent2 = Color3.fromRGB(99, 102, 241),
        Text = Color3.fromRGB(235, 235, 245),
        SubText = Color3.fromRGB(150, 150, 170),
        Stroke = Color3.fromRGB(55, 55, 75),
        Success = Color3.fromRGB(34, 197, 94),
        Warn = Color3.fromRGB(234, 179, 8),
    },
    Midnight = {
        Background = Color3.fromRGB(8, 12, 24),
        Topbar = Color3.fromRGB(10, 16, 32),
        Sidebar = Color3.fromRGB(9, 14, 28),
        Page = Color3.fromRGB(8, 12, 24),
        Element = Color3.fromRGB(16, 24, 44),
        ElementHover = Color3.fromRGB(22, 32, 58),
        Accent = Color3.fromRGB(56, 189, 248),
        Accent2 = Color3.fromRGB(59, 130, 246),
        Text = Color3.fromRGB(230, 240, 255),
        SubText = Color3.fromRGB(130, 150, 180),
        Stroke = Color3.fromRGB(35, 50, 80),
        Success = Color3.fromRGB(34, 197, 94),
        Warn = Color3.fromRGB(234, 179, 8),
    },
    Light = {
        Background = Color3.fromRGB(245, 245, 250),
        Topbar = Color3.fromRGB(255, 255, 255),
        Sidebar = Color3.fromRGB(238, 238, 245),
        Page = Color3.fromRGB(245, 245, 250),
        Element = Color3.fromRGB(255, 255, 255),
        ElementHover = Color3.fromRGB(230, 230, 240),
        Accent = Color3.fromRGB(139, 92, 246),
        Accent2 = Color3.fromRGB(99, 102, 241),
        Text = Color3.fromRGB(25, 25, 35),
        SubText = Color3.fromRGB(110, 110, 130),
        Stroke = Color3.fromRGB(210, 210, 225),
        Success = Color3.fromRGB(22, 163, 74),
        Warn = Color3.fromRGB(202, 138, 4),
    }
}

local function SaveConfig(folder, file)
    if not writefile then return end
    pcall(function()
        if not isfolder(folder) then makefolder(folder) end
        writefile(folder .. "/" .. file .. ".json", HttpService:JSONEncode(Velaris.Flags))
    end)
end

local function LoadConfig(folder, file)
    if not readfile or not isfile then return end
    pcall(function()
        local path = folder .. "/" .. file .. ".json"
        if isfile(path) then
            local data = HttpService:JSONDecode(readfile(path))
            for k, v in pairs(data) do
                Velaris.Flags[k] = v
            end
        end
    end)
end

function Velaris:CreateWindow(Settings)
    Settings = Settings or {}
    local WindowName = Settings.Name or "Velaris Hub"
    local LoadingTitle = Settings.LoadingTitle or WindowName
    local LoadingSubtitle = Settings.LoadingSubtitle or ("Velaris " .. self.Version)
    local ThemeName = Settings.Theme or "Dark"
    local Theme = Themes[ThemeName] or Themes.Dark
    local ToggleKey = Settings.ToggleUIKeybind or Enum.KeyCode.K
    local KeySystem = Settings.KeySystem or false
    local KeySettings = Settings.KeySettings or { Title = "Key System", Subtitle = "Enter your key", Keys = { "velaris-demo-key" } }
    local ConfigSettings = Settings.ConfigurationSaving or { Enabled = false, FolderName = "Velaris", FileName = "config" }

    if ConfigSettings.Enabled then
        LoadConfig(ConfigSettings.FolderName, ConfigSettings.FileName)
    end

    local Parent = GetParent()

    -- Root GUI
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "Velaris_" .. tostring(math.random(100000, 999999))
    Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    pcall(function()
        if syn and syn.protect_gui then syn.protect_gui(Gui) end
        Gui.Parent = Parent
    end)
    if not Gui.Parent then
        Gui.Parent = Parent
    end

    -- ===== Loading Screen =====
    local Loading = Instance.new("Frame")
    Loading.Name = "Loading"
    Loading.Size = UDim2.new(0, 380, 0, 180)
    Loading.Position = UDim2.new(0.5, -190, 0.5, -90)
    Loading.BackgroundColor3 = Theme.Background
    Loading.Parent = Gui
    Corner(Loading, 12)
    Stroke(Loading, Theme.Stroke, 1, 0.3)

    local LoadTitle = Instance.new("TextLabel")
    LoadTitle.Size = UDim2.new(1, -40, 0, 34)
    LoadTitle.Position = UDim2.new(0, 20, 0, 22)
    LoadTitle.BackgroundTransparency = 1
    LoadTitle.Text = LoadingTitle
    LoadTitle.Font = Enum.Font.GothamBold
    LoadTitle.TextSize = 22
    LoadTitle.TextColor3 = Theme.Text
    LoadTitle.TextXAlignment = Enum.TextXAlignment.Left
    LoadTitle.Parent = Loading

    local LoadSub = Instance.new("TextLabel")
    LoadSub.Size = UDim2.new(1, -40, 0, 20)
    LoadSub.Position = UDim2.new(0, 20, 0, 56)
    LoadSub.BackgroundTransparency = 1
    LoadSub.Text = LoadingSubtitle
    LoadSub.Font = Enum.Font.Gotham
    LoadSub.TextSize = 14
    LoadSub.TextColor3 = Theme.SubText
    LoadSub.TextXAlignment = Enum.TextXAlignment.Left
    LoadSub.Parent = Loading

    local BarBG = Instance.new("Frame")
    BarBG.Size = UDim2.new(1, -40, 0, 6)
    BarBG.Position = UDim2.new(0, 20, 1, -42)
    BarBG.BackgroundColor3 = Theme.Element
    BarBG.BorderSizePixel = 0
    BarBG.Parent = Loading
    Corner(BarBG, 99)

    local BarFill = Instance.new("Frame")
    BarFill.Size = UDim2.new(0, 0, 1, 0)
    BarFill.BackgroundColor3 = Theme.Accent
    BarFill.BorderSizePixel = 0
    BarFill.Parent = BarBG
    Corner(BarFill, 99)

    local LoadPct = Instance.new("TextLabel")
    LoadPct.Size = UDim2.new(1, -40, 0, 18)
    LoadPct.Position = UDim2.new(0, 20, 1, -68)
    LoadPct.BackgroundTransparency = 1
    LoadPct.Text = "Loading... 0%"
    LoadPct.Font = Enum.Font.GothamMedium
    LoadPct.TextSize = 12
    LoadPct.TextColor3 = Theme.SubText
    LoadPct.TextXAlignment = Enum.TextXAlignment.Left
    LoadPct.Parent = Loading

    -- ===== Key System =====
    local KeyPassed = not KeySystem
    local KeyFrame
    if KeySystem then
        Loading.Visible = false
        KeyFrame = Instance.new("Frame")
        KeyFrame.Name = "KeySystem"
        KeyFrame.Size = UDim2.new(0, 380, 0, 250)
        KeyFrame.Position = UDim2.new(0.5, -190, 0.5, -125)
        KeyFrame.BackgroundColor3 = Theme.Background
        KeyFrame.Parent = Gui
        Corner(KeyFrame, 12)
        Stroke(KeyFrame, Theme.Stroke, 1, 0.3)

        local KT = Instance.new("TextLabel")
        KT.Size = UDim2.new(1, -40, 0, 30)
        KT.Position = UDim2.new(0, 20, 0, 18)
        KT.BackgroundTransparency = 1
        KT.Text = KeySettings.Title or "Key System"
        KT.Font = Enum.Font.GothamBold
        KT.TextSize = 20
        KT.TextColor3 = Theme.Text
        KT.TextXAlignment = Enum.TextXAlignment.Left
        KT.Parent = KeyFrame

        local KS = Instance.new("TextLabel")
        KS.Size = UDim2.new(1, -40, 0, 20)
        KS.Position = UDim2.new(0, 20, 0, 48)
        KS.BackgroundTransparency = 1
        KS.Text = KeySettings.Subtitle or "Enter your key below"
        KS.Font = Enum.Font.Gotham
        KS.TextSize = 13
        KS.TextColor3 = Theme.SubText
        KS.TextXAlignment = Enum.TextXAlignment.Left
        KS.Parent = KeyFrame

        local KeyBox = Instance.new("TextBox")
        KeyBox.Size = UDim2.new(1, -40, 0, 42)
        KeyBox.Position = UDim2.new(0, 20, 0, 82)
        KeyBox.BackgroundColor3 = Theme.Element
        KeyBox.Text = ""
        KeyBox.PlaceholderText = "Paste key here..."
        KeyBox.Font = Enum.Font.Gotham
        KeyBox.TextSize = 14
        KeyBox.TextColor3 = Theme.Text
        KeyBox.PlaceholderColor3 = Theme.SubText
        KeyBox.Parent = KeyFrame
        Corner(KeyBox, 8)
        Stroke(KeyBox, Theme.Stroke, 1, 0.4)
        Padding(KeyBox, 12, 0, 12, 0)

        local KeyBtn = Instance.new("TextButton")
        KeyBtn.Size = UDim2.new(1, -40, 0, 42)
        KeyBtn.Position = UDim2.new(0, 20, 0, 136)
        KeyBtn.BackgroundColor3 = Theme.Accent
        KeyBtn.Text = "Check Key"
        KeyBtn.Font = Enum.Font.GothamBold
        KeyBtn.TextSize = 14
        KeyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        KeyBtn.AutoButtonColor = true
        KeyBtn.Parent = KeyFrame
        Corner(KeyBtn, 8)

        local KeyMsg = Instance.new("TextLabel")
        KeyMsg.Size = UDim2.new(1, -40, 0, 20)
        KeyMsg.Position = UDim2.new(0, 20, 0, 186)
        KeyMsg.BackgroundTransparency = 1
        KeyMsg.Text = ""
        KeyMsg.Font = Enum.Font.Gotham
        KeyMsg.TextSize = 12
        KeyMsg.TextColor3 = Theme.SubText
        KeyMsg.TextXAlignment = Enum.TextXAlignment.Left
        KeyMsg.Parent = KeyFrame

        local GetKeyBtn
        if KeySettings.Note then
            GetKeyBtn = Instance.new("TextButton")
            GetKeyBtn.Size = UDim2.new(1, -40, 0, 28)
            GetKeyBtn.Position = UDim2.new(0, 20, 0, 208)
            GetKeyBtn.BackgroundTransparency = 1
            GetKeyBtn.Text = KeySettings.Note
            GetKeyBtn.Font = Enum.Font.Gotham
            GetKeyBtn.TextSize = 12
            GetKeyBtn.TextColor3 = Theme.Accent
            GetKeyBtn.Parent = KeyFrame
        end

        KeyBtn.MouseButton1Click:Connect(function()
            local entered = KeyBox.Text
            local valid = false
            for _, k in ipairs(KeySettings.Keys or {}) do
                if entered == k then valid = true break end
            end
            if valid then
                KeyMsg.Text = "Correct key! Loading..."
                KeyMsg.TextColor3 = Theme.Success
                task.wait(0.5)
                KeyPassed = true
                Tween(KeyFrame, { Size = UDim2.new(0, 0, 0, 0) }, 0.25)
                task.wait(0.25)
                KeyFrame:Destroy()
                Loading.Visible = true
            else
                KeyMsg.Text = "Invalid key, try again."
                KeyMsg.TextColor3 = Color3.fromRGB(239, 68, 68)
                Tween(KeyBox, { Position = KeyBox.Position + UDim2.new(0, 6, 0, 0) }, 0.05)
                task.wait(0.05)
                Tween(KeyBox, { Position = KeyBox.Position - UDim2.new(0, 12, 0, 0) }, 0.05)
                task.wait(0.05)
                Tween(KeyBox, { Position = KeyBox.Position + UDim2.new(0, 6, 0, 0) }, 0.05)
            end
        end)
        repeat task.wait() until KeyPassed
    end

    -- ===== Main Window =====
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 620, 0, 420)
    Main.Position = UDim2.new(0.5, -310, 0.5, -210)
    Main.BackgroundColor3 = Theme.Background
    Main.Visible = false
    Main.Parent = Gui
    Corner(Main, 12)
    Stroke(Main, Theme.Stroke, 1, 0.25)
    Main.ClipsDescendants = true

    local Topbar = Instance.new("Frame")
    Topbar.Name = "Topbar"
    Topbar.Size = UDim2.new(1, 0, 0, 48)
    Topbar.BackgroundColor3 = Theme.Topbar
    Topbar.BorderSizePixel = 0
    Topbar.Parent = Main

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -130, 1, 0)
    TitleLabel.Position = UDim2.new(0, 16, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = "  " .. WindowName .. '  <font color="rgb(139,92,246)">• Velaris</font>'
    TitleLabel.RichText = true
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextSize = 15
    TitleLabel.TextColor3 = Theme.Text
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = Topbar

    local function TopButton(text, xOff)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 32, 0, 32)
        b.Position = UDim2.new(1, xOff, 0.5, -16)
        b.BackgroundColor3 = Theme.Element
        b.Text = text
        b.Font = Enum.Font.GothamBold
        b.TextSize = 14
        b.TextColor3 = Theme.Text
        b.Parent = Topbar
        Corner(b, 8)
        return b
    end

    local CloseBtn = TopButton("×", -42)
    local MinBtn = TopButton("–", -80)

    MakeDraggable(Main, Topbar)

    -- Sidebar
    local Sidebar = Instance.new("ScrollingFrame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 160, 1, -48)
    Sidebar.Position = UDim2.new(0, 0, 0, 48)
    Sidebar.BackgroundColor3 = Theme.Sidebar
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 0
    Sidebar.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Sidebar.CanvasSize = UDim2.new(0, 0, 0, 0)
    Sidebar.Parent = Main

    local SideList = Instance.new("UIListLayout")
    SideList.Padding = UDim.new(0, 6)
    SideList.SortOrder = Enum.SortOrder.LayoutOrder
    SideList.Parent = Sidebar
    Padding(Sidebar, 10, 10, 10, 10)

    -- Page container
    local PageHolder = Instance.new("Frame")
    PageHolder.Name = "Pages"
    PageHolder.Size = UDim2.new(1, -160, 1, -48)
    PageHolder.Position = UDim2.new(0, 160, 0, 48)
    PageHolder.BackgroundColor3 = Theme.Page
    PageHolder.BorderSizePixel = 0
    PageHolder.ClipsDescendants = true
    PageHolder.Parent = Main

    -- Notifications holder
    local NotifHolder = Instance.new("Frame")
    NotifHolder.Name = "Notifications"
    NotifHolder.Size = UDim2.new(0, 300, 1, 0)
    NotifHolder.Position = UDim2.new(1, -312, 0, 12)
    NotifHolder.BackgroundTransparency = 1
    NotifHolder.Parent = Gui
    local NotifList = Instance.new("UIListLayout")
    NotifList.Padding = UDim.new(0, 8)
    NotifList.VerticalAlignment = Enum.VerticalAlignment.Bottom
    NotifList.SortOrder = Enum.SortOrder.LayoutOrder
    NotifList.Parent = NotifHolder

    local WindowObj = {}
    WindowObj._Gui = Gui
    WindowObj._Main = Main
    WindowObj._Theme = Theme
    WindowObj._Tabs = {}
    WindowObj._CurrentTab = nil

    function WindowObj:Notify(NotifSettings)
        NotifSettings = NotifSettings or {}
        local title = NotifSettings.Title or "Velaris"
        local content = NotifSettings.Content or "Hello!"
        local duration = NotifSettings.Duration or 4

        local n = Instance.new("Frame")
        n.Size = UDim2.new(1, 0, 0, 76)
        n.BackgroundColor3 = Theme.Background
        n.Parent = NotifHolder
        Corner(n, 10)
        Stroke(n, Theme.Stroke, 1, 0.3)

        local nt = Instance.new("TextLabel")
        nt.Size = UDim2.new(1, -24, 0, 22)
        nt.Position = UDim2.new(0, 12, 0, 8)
        nt.BackgroundTransparency = 1
        nt.Text = title
        nt.Font = Enum.Font.GothamBold
        nt.TextSize = 14
        nt.TextColor3 = Theme.Text
        nt.TextXAlignment = Enum.TextXAlignment.Left
        nt.TextTruncate = Enum.TextTruncate.AtEnd
        nt.Parent = n

        local nc = Instance.new("TextLabel")
        nc.Size = UDim2.new(1, -24, 0, 36)
        nc.Position = UDim2.new(0, 12, 0, 30)
        nc.BackgroundTransparency = 1
        nc.Text = content
        nc.Font = Enum.Font.Gotham
        nc.TextSize = 12
        nc.TextColor3 = Theme.SubText
        nc.TextXAlignment = Enum.TextXAlignment.Left
        nc.TextYAlignment = Enum.TextYAlignment.Top
        nc.TextWrapped = true
        nc.Parent = n

        n.Size = UDim2.new(1, 0, 0, 0)
        Tween(n, { Size = UDim2.new(1, 0, 0, 76) }, 0.25, Enum.EasingStyle.Back)
        task.delay(duration, function()
            local tw = Tween(n, { Size = UDim2.new(1, 0, 0, 0) }, 0.25)
            tw.Completed:Wait()
            n:Destroy()
        end)
    end

    function WindowObj:Destroy()
        Gui:Destroy()
    end

    function WindowObj:Toggle(state)
        if state == nil then state = not Main.Visible end
        Main.Visible = state
    end

    MinBtn.MouseButton1Click:Connect(function()
        WindowObj:Toggle(not Main.Visible)
        -- keep a small restore pill? simplest: toggle back with keybind
    end)
    CloseBtn.MouseButton1Click:Connect(function()
        WindowObj:Destroy()
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == ToggleKey then
            if Main.Visible then
                Tween(Main, { Size = UDim2.new(0, 0, 0, 0) }, 0.2)
                task.wait(0.2)
                Main.Visible = false
                Main.Size = UDim2.new(0, 620, 0, 420)
            else
                Main.Visible = true
            end
        end
    end)

    -- Tab creation
    function WindowObj:CreateTab(TabName, TabIcon)
        TabName = TabName or "Tab"
        local tabIndex = #self._Tabs + 1

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Theme.Element
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "  " .. TabName
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.TextSize = 13
        TabBtn.TextColor3 = Theme.SubText
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.LayoutOrder = tabIndex
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = Sidebar
        Corner(TabBtn, 8)
        Padding(TabBtn, 10, 0, 0, 0)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = TabName
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.BorderSizePixel = 0
        Page.Visible = false
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Theme.Accent
        Page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Parent = PageHolder

        local PageList = Instance.new("UIListLayout")
        PageList.Padding = UDim.new(0, 8)
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Parent = Page
        Padding(Page, 14, 14, 14, 14)

        local function Select()
            for _, t in ipairs(WindowObj._Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundTransparency = 1
                t.Button.TextColor3 = Theme.SubText
            end
            Page.Visible = true
            TabBtn.BackgroundTransparency = 0
            TabBtn.BackgroundColor3 = Theme.Element
            TabBtn.TextColor3 = Theme.Text
            WindowObj._CurrentTab = Page
        end
        TabBtn.MouseButton1Click:Connect(Select)
        TabBtn.MouseEnter:Connect(function()
            if WindowObj._CurrentTab ~= Page then
                Tween(TabBtn, { BackgroundTransparency = 0.5 }, 0.15)
                TabBtn.BackgroundColor3 = Theme.ElementHover
            end
        end)
        TabBtn.MouseLeave:Connect(function()
            if WindowObj._CurrentTab ~= Page then
                TabBtn.BackgroundTransparency = 1
            end
        end)

        local TabObj = { Button = TabBtn, Page = Page }

        local function NewElementBase(height)
            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -4, 0, height)
            f.BackgroundColor3 = Theme.Element
            f.BorderSizePixel = 0
            f.Parent = Page
            Corner(f, 10)
            Stroke(f, Theme.Stroke, 1, 0.5)
            Padding(f, 12, 10, 12, 10)
            return f
        end

        local function ElementTitle(parent, name, sub)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, -60, 0, sub and 20 or 24)
            t.Position = UDim2.new(0, 0, 0, 0)
            t.BackgroundTransparency = 1
            t.Text = name
            t.Font = Enum.Font.GothamMedium
            t.TextSize = 13
            t.TextColor3 = Theme.Text
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.TextTruncate = Enum.TextTruncate.AtEnd
            t.Parent = parent
            if sub then
                local s = Instance.new("TextLabel")
                s.Size = UDim2.new(1, -60, 0, 16)
                s.Position = UDim2.new(0, 0, 0, 20)
                s.BackgroundTransparency = 1
                s.Text = sub
                s.Font = Enum.Font.Gotham
                s.TextSize = 11
                s.TextColor3 = Theme.SubText
                s.TextXAlignment = Enum.TextXAlignment.Left
                s.TextTruncate = Enum.TextTruncate.AtEnd
                s.Parent = parent
            end
        end

        function TabObj:CreateLabel(Text)
            local f = NewElementBase(36)
            f.BackgroundTransparency = 1
            f:SetAttribute("IsLabel", true)
            Stroke(f, Theme.Stroke, 0, 1)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 1, 0)
            l.BackgroundTransparency = 1
            l.Text = Text or "Label"
            l.Font = Enum.Font.GothamMedium
            l.TextSize = 13
            l.TextColor3 = Theme.Text
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.TextWrapped = true
            l.Parent = f
            return { Set = function(_, v) l.Text = v end }
        end

        function TabObj:CreateParagraph(ParSettings)
            local title = ParSettings.Title or "Paragraph"
            local content = ParSettings.Content or "..."
            local f = NewElementBase(70)
            local t = Instance.new("TextLabel")
            t.Size = UDim2.new(1, 0, 0, 20)
            t.BackgroundTransparency = 1
            t.Text = title
            t.Font = Enum.Font.GothamBold
            t.TextSize = 14
            t.TextColor3 = Theme.Text
            t.TextXAlignment = Enum.TextXAlignment.Left
            t.Parent = f
            local c = Instance.new("TextLabel")
            c.Size = UDim2.new(1, 0, 0, 30)
            c.Position = UDim2.new(0, 0, 0, 22)
            c.BackgroundTransparency = 1
            c.Text = content
            c.Font = Enum.Font.Gotham
            c.TextSize = 12
            c.TextColor3 = Theme.SubText
            c.TextXAlignment = Enum.TextXAlignment.Left
            c.TextYAlignment = Enum.TextYAlignment.Top
            c.TextWrapped = true
            c.Parent = f
            return { Set = function(_, nt, nc2) t.Text = nt or t.Text c.Text = nc2 or c.Text end }
        end

        function TabObj:CreateButton(BtnSettings)
            local name = BtnSettings.Name or "Button"
            local cb = BtnSettings.Callback or function() end
            local f = NewElementBase(48)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 1, 0)
            b.BackgroundColor3 = Theme.Accent
            b.Text = name
            b.Font = Enum.Font.GothamBold
            b.TextSize = 13
            b.TextColor3 = Color3.fromRGB(255,255,255)
            b.Parent = f
            Corner(b, 8)
            b.MouseButton1Click:Connect(function()
                Tween(b, { Size = UDim2.new(1, -4, 1, -4) }, 0.08)
                task.wait(0.08)
                Tween(b, { Size = UDim2.new(1, 0, 1, 0) }, 0.08)
                pcall(cb)
            end)
            return { Set = function(_, v) b.Text = v end, Fire = function() pcall(cb) end }
        end

        function TabObj:CreateToggle(TogSettings)
            local name = TogSettings.Name or "Toggle"
            local current = TogSettings.CurrentValue or false
            local flag = TogSettings.Flag
            local cb = TogSettings.Callback or function() end
            if flag and Velaris.Flags[flag] ~= nil then current = Velaris.Flags[flag] end

            local f = NewElementBase(48)
            ElementTitle(f, name)

            local outer = Instance.new("Frame")
            outer.Size = UDim2.new(0, 46, 0, 24)
            outer.Position = UDim2.new(1, -46, 0.5, -12)
            outer.BackgroundColor3 = current and Theme.Accent or Theme.ElementHover
            outer.BorderSizePixel = 0
            outer.Parent = f
            Corner(outer, 99)
            Stroke(outer, Theme.Stroke, 1, 0.4)

            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.Position = current and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
            knob.BorderSizePixel = 0
            knob.Parent = outer
            Corner(knob, 99)

            local state = current
            local function Set(v)
                state = v
                if flag then
                    Velaris.Flags[flag] = v
                    if ConfigSettings.Enabled then SaveConfig(ConfigSettings.FolderName, ConfigSettings.FileName) end
                end
                Tween(outer, { BackgroundColor3 = v and Theme.Accent or Theme.ElementHover }, 0.2)
                Tween(knob, { Position = v and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9) }, 0.2)
                pcall(cb, v)
            end
            outer.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    Set(not state)
                end
            end)
            if flag then Velaris.Flags[flag] = state end
            return { Set = Set, Get = function() return state end }
        end

        function TabObj:CreateSlider(SliSettings)
            local name = SliSettings.Name or "Slider"
            local range = SliSettings.Range or {0, 100}
            local inc = SliSettings.Increment or 1
            local current = SliSettings.CurrentValue or range[1]
            local flag = SliSettings.Flag
            local cb = SliSettings.Callback or function() end
            if flag and Velaris.Flags[flag] ~= nil then current = Velaris.Flags[flag] end

            local min, max = range[1], range[2]
            local f = NewElementBase(64)
            ElementTitle(f, name .. "  •  " .. tostring(current))
            local titleLbl = f:FindFirstChildOfClass("TextLabel")

            local bg = Instance.new("Frame")
            bg.Size = UDim2.new(1, 0, 0, 8)
            bg.Position = UDim2.new(0, 0, 1, -14)
            bg.BackgroundColor3 = Theme.ElementHover
            bg.BorderSizePixel = 0
            bg.Parent = f
            Corner(bg, 99)

            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((current - min) / math.max(1, (max - min)), 0, 1, 0)
            fill.BackgroundColor3 = Theme.Accent
            fill.BorderSizePixel = 0
            fill.Parent = bg
            Corner(fill, 99)

            local dragging = false
            local function UpdateFromX(x)
                local rel = math.clamp((x - bg.AbsolutePosition.X) / bg.AbsoluteSize.X, 0, 1)
                local val = min + rel * (max - min)
                val = math.floor(val / inc + 0.5) * inc
                val = math.clamp(val, min, max)
                fill.Size = UDim2.new((val - min) / math.max(1, (max - min)), 0, 1, 0)
                if titleLbl then titleLbl.Text = name .. "  •  " .. tostring(val) end
                if flag then
                    Velaris.Flags[flag] = val
                    if ConfigSettings.Enabled then SaveConfig(ConfigSettings.FolderName, ConfigSettings.FileName) end
                end
                pcall(cb, val)
            end
            bg.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    UpdateFromX(inp.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(inp)
                if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateFromX(inp.Position.X)
                end
            end)
            if flag then Velaris.Flags[flag] = current end
            return {}
        end

        function TabObj:CreateDropdown(DropSettings)
            local name = DropSettings.Name or "Dropdown"
            local options = DropSettings.Options or {"Option 1", "Option 2"}
            local current = DropSettings.CurrentOption or options[1]
            local multi = DropSettings.MultipleOptions or false
            local flag = DropSettings.Flag
            local cb = DropSettings.Callback or function() end
            if flag and Velaris.Flags[flag] ~= nil then current = Velaris.Flags[flag] end
            if type(current) == "string" then current = {current} end
            if type(current) ~= "table" then current = {options[1]} end

            local f = Instance.new("Frame")
            f.Size = UDim2.new(1, -4, 0, 48)
            f.BackgroundColor3 = Theme.Element
            f.Parent = Page
            Corner(f, 10)
            Stroke(f, Theme.Stroke, 1, 0.5)
            Padding(f, 12, 10, 12, 10)
            f.ClipsDescendants = true

            ElementTitle(f, name)
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, 20, 0, 20)
            arrow.Position = UDim2.new(1, -20, 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "▾"
            arrow.Font = Enum.Font.GothamBold
            arrow.TextSize = 16
            arrow.TextColor3 = Theme.SubText
            arrow.Parent = f

            local open = false
            local listH = #options * 32
            local function RefreshLabel()
                -- update title with selection
                local lbl = f:FindFirstChildOfClass("TextLabel")
                if lbl then
                    lbl.Text = name .. "  •  " .. table.concat(current, ", ")
                end
            end
            RefreshLabel()

            local optHolder = Instance.new("Frame")
            optHolder.Size = UDim2.new(1, 0, 0, listH)
            optHolder.Position = UDim2.new(0, 0, 0, 44)
            optHolder.BackgroundTransparency = 1
            optHolder.Parent = f

            local ol = Instance.new("UIListLayout")
            ol.Padding = UDim.new(0, 4)
            ol.Parent = optHolder

            for _, opt in ipairs(options) do
                local ob = Instance.new("TextButton")
                ob.Size = UDim2.new(1, 0, 0, 28)
                ob.BackgroundColor3 = Theme.ElementHover
                ob.Text = opt
                ob.Font = Enum.Font.Gotham
                ob.TextSize = 12
                ob.TextColor3 = Theme.Text
                ob.Parent = optHolder
                Corner(ob, 6)
                ob.MouseButton1Click:Connect(function()
                    if multi then
                        local found = table.find(current, opt)
                        if found then table.remove(current, found)
                        else table.insert(current, opt) end
                        pcall(cb, current)
                    else
                        current = {opt}
                        pcall(cb, opt)
                        -- auto close single
                        open = false
                        Tween(f, { Size = UDim2.new(1, -4, 0, 48) }, 0.2)
                        arrow.Text = "▾"
                    end
                    RefreshLabel()
                    if flag then
                        Velaris.Flags[flag] = multi and current or current[1]
                        if ConfigSettings.Enabled then SaveConfig(ConfigSettings.FolderName, ConfigSettings.FileName) end
                    end
                end)
            end

            f.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                    -- only toggle if click on header area
                    if inp.Position.Y - f.AbsolutePosition.Y < 44 then
                        open = not open
                        arrow.Text = open and "▴" or "▾"
                        Tween(f, { Size = UDim2.new(1, -4, 0, open and (52 + listH) or 48) }, 0.2)
                    end
                end
            end)
            if flag then Velaris.Flags[flag] = multi and current or current[1] end
            return {}
        end

        function TabObj:CreateInput(InpSettings)
            local name = InpSettings.Name or "Input"
            local placeholder = InpSettings.PlaceholderText or "Enter text..."
            local removeAfter = InpSettings.RemoveTextAfterFocusLost ~= false
            local flag = InpSettings.Flag
            local cb = InpSettings.Callback or function() end

            local f = NewElementBase(64)
            ElementTitle(f, name)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, 0, 0, 30)
            box.Position = UDim2.new(0, 0, 1, -32)
            box.BackgroundColor3 = Theme.Background
            box.Text = ""
            box.PlaceholderText = placeholder
            box.Font = Enum.Font.Gotham
            box.TextSize = 13
            box.TextColor3 = Theme.Text
            box.PlaceholderColor3 = Theme.SubText
            box.ClearTextOnFocus = false
            box.Parent = f
            Corner(box, 8)
            Stroke(box, Theme.Stroke, 1, 0.4)
            Padding(box, 10, 0, 10, 0)
            box.FocusLost:Connect(function(enter)
                if flag then
                    Velaris.Flags[flag] = box.Text
                    if ConfigSettings.Enabled then SaveConfig(ConfigSettings.FolderName, ConfigSettings.FileName) end
                end
                pcall(cb, box.Text)
                if removeAfter then box.Text = "" end
            end)
            return {}
        end

        function TabObj:CreateKeybind(KeySettings2)
            local name = KeySettings2.Name or "Keybind"
            local current = KeySettings2.CurrentKeybind or "K"
            local hold = KeySettings2.HoldToInteract or false
            local flag = KeySettings2.Flag
            local cb = KeySettings2.Callback or function() end
            if flag and Velaris.Flags[flag] ~= nil then current = Velaris.Flags[flag] end

            local f = NewElementBase(48)
            ElementTitle(f, name)
            local kb = Instance.new("TextButton")
            kb.Size = UDim2.new(0, 90, 0, 28)
            kb.Position = UDim2.new(1, -90, 0.5, -14)
            kb.BackgroundColor3 = Theme.Background
            kb.Text = tostring(current)
            kb.Font = Enum.Font.GothamBold
            kb.TextSize = 12
            kb.TextColor3 = Theme.Text
            kb.Parent = f
            Corner(kb, 8)
            Stroke(kb, Theme.Stroke, 1, 0.4)

            local listening = false
            kb.MouseButton1Click:Connect(function()
                listening = true
                kb.Text = "..."
            end)
            UserInputService.InputBegan:Connect(function(inp, gpe)
                if listening and inp.UserInputType == Enum.UserInputType.Keyboard then
                    listening = false
                    current = inp.KeyCode.Name
                    kb.Text = current
                    if flag then
                        Velaris.Flags[flag] = current
                        if ConfigSettings.Enabled then SaveConfig(ConfigSettings.FolderName, ConfigSettings.FileName) end
                    end
                elseif not listening and not gpe and inp.UserInputType == Enum.UserInputType.Keyboard and inp.KeyCode.Name == tostring(current) then
                    if hold then
                        -- hold logic simplified to fire once
                        pcall(cb, inp.KeyCode)
                    else
                        pcall(cb, inp.KeyCode)
                    end
                end
            end)
            return {}
        end

        function TabObj:CreateColorPicker(CPSettings)
            local name = CPSettings.Name or "Color"
            local color = CPSettings.Color or Color3.fromRGB(139, 92, 246)
            local flag = CPSettings.Flag
            local cb = CPSettings.Callback or function() end
            if flag and Velaris.Flags[flag] ~= nil then
                pcall(function()
                    local c = Velaris.Flags[flag]
                    if typeof(c) == "Color3" then color = c end
                end)
            end

            local f = NewElementBase(48)
            ElementTitle(f, name)
            local preview = Instance.new("TextButton")
            preview.Size = UDim2.new(0, 60, 0, 28)
            preview.Position = UDim2.new(1, -60, 0.5, -14)
            preview.BackgroundColor3 = color
            preview.Text = ""
            preview.Parent = f
            Corner(preview, 8)
            Stroke(preview, Theme.Stroke, 1, 0.3)

            -- Simple rainbow cycle on click + RGB inputs via prompt? Keep simple: click cycles preset colors
            local presets = {
                Color3.fromRGB(139,92,246), Color3.fromRGB(59,130,246),
                Color3.fromRGB(34,197,94), Color3.fromRGB(234,179,8),
                Color3.fromRGB(239,68,68), Color3.fromRGB(236,72,153),
                Color3.fromRGB(56,189,248), Color3.fromRGB(255,255,255),
            }
            local idx = 1
            preview.MouseButton1Click:Connect(function()
                idx = idx % #presets + 1
                color = presets[idx]
                Tween(preview, { BackgroundColor3 = color }, 0.2)
                if flag then Velaris.Flags[flag] = color end
                pcall(cb, color)
            end)
            return {}
        end

        function TabObj:CreateSection(SectionName)
            local s = Instance.new("TextLabel")
            s.Size = UDim2.new(1, -4, 0, 24)
            s.BackgroundTransparency = 1
            s.Text = string.upper(SectionName or "SECTION")
            s.Font = Enum.Font.GothamBold
            s.TextSize = 11
            s.TextColor3 = Theme.Accent
            s.TextXAlignment = Enum.TextXAlignment.Left
            s.Parent = Page
            return {}
        end

        table.insert(WindowObj._Tabs, TabObj)
        if #WindowObj._Tabs == 1 then
            Select()
        end
        return TabObj
    end

    -- Animate loading -> main
    task.spawn(function()
        for i = 0, 100, 5 do
            if not Loading.Parent then break end
            BarFill.Size = UDim2.new(i/100, 0, 1, 0)
            LoadPct.Text = "Loading... " .. i .. "%"
            task.wait(0.04)
        end
        task.wait(0.2)
        Tween(Loading, { Size = UDim2.new(0, 0, 0, 0) }, 0.3)
        task.wait(0.3)
        Loading:Destroy()
        Main.Visible = true
        Main.Size = UDim2.new(0, 0, 0, 0)
        Tween(Main, { Size = UDim2.new(0, 620, 0, 420) }, 0.4, Enum.EasingStyle.Back)
        WindowObj:Notify({ Title = WindowName, Content = "Loaded with Velaris " .. Velaris.Version, Duration = 4 })
    end)

    table.insert(Velaris._UIs, WindowObj)
    return WindowObj
end

return Velaris
