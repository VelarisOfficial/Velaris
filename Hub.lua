-- Velaris Hub - READY TO USE, just upload this file to GitHub as Hub.lua
-- Your users will run: loadstring(game:HttpGet("https://raw.githubusercontent.com/VelarisOfficial/Velaris/refs/heads/main/Hub.lua"))()

local Velaris = loadstring(game:HttpGet("https://raw.githubusercontent.com/VelarisOfficial/Velaris/refs/heads/main/Velaris.lua"))()

local Window = Velaris:CreateWindow({
    Name = "Velaris Hub",
    LoadingTitle = "Velaris Hub",
    LoadingSubtitle = "by VelarisOfficial • v1.0.0",
    Theme = "Dark",
    ToggleUIKeybind = Enum.KeyCode.K,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "VelarisHub",
        FileName = "config"
    },
    KeySystem = false,
    KeySettings = {
        Title = "Velaris Key",
        Subtitle = "Enter your key",
        Note = "Get key at discord.gg/yourinvite",
        Keys = {"velaris-demo-key"}
    }
})

local MainTab = Window:CreateTab("Main")
MainTab:CreateSection("Player")

MainTab:CreateButton({
    Name = "Speed 100",
    Callback = function()
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = 100 end
        Window:Notify({Title = "Done", Content = "Speed set to 100", Duration = 3})
    end
})

MainTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(v) getgenv().InfiniteJump = v end
})

MainTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    CurrentValue = 16,
    Flag = "WalkSpeed",
    Callback = function(v)
        local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end
})

local MiscTab = Window:CreateTab("Misc")
MiscTab:CreateLabel("Velaris v1.0.0 • Press K to toggle")

Window:Notify({Title = "Velaris", Content = "Loaded! Press K to toggle UI", Duration = 5})
