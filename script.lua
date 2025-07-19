--[[
    TurkSwarm Engine v8.0
    Açıklama: Bu script, TurkSwarm'ın ana motorudur.
    "TurkSwarm_UI.lua" tarafından ayarlanan global ayarları okuyarak çalışır.
]]

-- Adım 1: Gerekli Servisleri ve Değişkenleri Tanımla
local LocalPlayer = game:GetService("Players").LocalPlayer
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Adım 2: Oyuncu Verilerini Kesin Olarak Bul
local PlayerData = _G.PlayerData
if not PlayerData then
    for i,v in pairs(getnilinstances()) do
        if v.Name == "PlayerData" and v:FindFirstChild("Profile") and v:FindFirstChild("Bag") then
            PlayerData = v; break;
        end
    end
end

if not PlayerData then
    warn("TurkSwarm Motor Hatası: PlayerData bulunamadı! Motor çalışamaz.")
    return
end

-- Verileri global köprüye kaydet
if not _G.TurkSwarm then _G.TurkSwarm = {} end -- UI'dan önce yüklenirse diye güvenlik kontrolü
_G.TurkSwarm.Data = {
    Profile = PlayerData.Profile,
    Bag = PlayerData.Bag
}

-- Adım 3: Gerekli Yardımcı Değişkenleri ve Fonksiyonları Hazırla
local Fields = {}
for _, field in ipairs(Workspace.Fields:GetChildren()) do
    Fields[field.Name] = field
end

local isConverting = false
local lastSprinklerUse = 0
local sprinklerCooldown = 120 -- 2 Dakika

-- Adım 4: Yüksek Hızlı Ana Döngüyü Başlat
RunService.RenderStepped:Connect(function()
    pcall(function()
        -- Köprüden ayarları ve verileri her karede oku
        local Settings = _G.TurkSwarm.Settings
        local Data = _G.TurkSwarm.Data
        
        -- Eğer köprüler henüz hazır değilse devam etme
        if not Settings or not Data or not Data.Profile or not Data.Bag then return end

        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")

        -- Ana kontrol
        if not Settings.EnableAutoFarm or not hum or hum.Health <= 0 then 
            if hum then hum.WalkSpeed = 16 end
            isConverting = false
            return 
        end

        hum.WalkSpeed = Settings.WalkSpeed

        -- Dönüştürme durumu kontrolü
        if isConverting then
            if Data.Profile.Pollen.Value < Data.Bag.Capacity.Value then
                isConverting = false
            end
            return -- Dönüştürme bitene kadar başka bir şey yapma
        end
        
        -- ÖNCELİK 1: Çanta dolu mu?
        if Settings.AutoConvert and Data.Profile.Pollen.Value >= Data.Bag.Capacity.Value then
            isConverting = true
            root.CFrame = CFrame.new(10, 20, -130)
            ReplicatedStorage.Events.BeeConversionLink:FireServer()
            return -- Durumu ayarla ve bu karelik işlemi bitir
        end

        -- ÖNCELİK 2: Fıskiye hazır mı?
        if Settings.AutoSprinkler and (tick() - lastSprinklerUse > sprinklerCooldown) then
            ReplicatedStorage.Events.PlayerAbilityEvent:FireServer("Sprinkler")
            lastSprinklerUse = tick()
        end
        
        -- ÖNCELİK 3 (Varsayılan Eylem): Farm yap
        local targetField = Fields[Settings.SelectedField]
        if targetField then
            local fieldSize = targetField.Size
            local randomCFrame = targetField.CFrame * CFrame.new(
                math.random(-fieldSize.X / 2.1, fieldSize.X / 2.1),
                5,
                math.random(-fieldSize.Z / 2.1, fieldSize.Z / 2.1)
            )
            root.CFrame = randomCFrame
        end
    end)
end)

print("TurkSwarm Engine v8.0 başarıyla yüklendi.")
