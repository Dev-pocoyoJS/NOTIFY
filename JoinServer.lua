--[[
    MidNight Hub - Join Server
    HUB simples: cola o código, desofusca (Base64 + XOR) e dá TeleportToPlaceInstance.

    IMPORTANTE: a XOR_KEY aqui embaixo TEM que ser IDÊNTICA à XOR_KEY do
    .env do bot (bot/lib/serverCode.js), senão o decode não bate.
]]

local CONFIG = {
    XOR_KEY = "4e0eb2f03fb14b75553f68923d257f7fea67dacc16a164cb5bf356d227367405",
}

-- ================= Carrega a Midnight Library =================
if getgenv().Library then
    getgenv().Library:Unload()
end

local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/nightmereki-lab/TESTS/refs/heads/main/Library.lua"
))()

local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- ================= Base64 decode (Lua puro) =================
local B64_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64Decode(data)
    data = string.gsub(data, "[^" .. B64_CHARS .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (B64_CHARS:find(x) - 1)
        for i = 6, 1, -1 do
            r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0")
        end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d?", function(x)
        if #x ~= 8 then return "" end
        local c = 0
        for i = 1, 8 do
            c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0)
        end
        return string.char(c)
    end))
end

-- ================= XOR =================
local function xorCipher(str, key)
    local out = {}
    for i = 1, #str do
        local strByte = string.byte(str, i)
        local keyByte = string.byte(key, ((i - 1) % #key) + 1)
        out[i] = string.char(bit32.bxor(strByte, keyByte))
    end
    return table.concat(out)
end

-- ================= Decode do código de servidor =================
local function decodeServerCode(code)
    local b64 = code:gsub("^MHUB|", "")
    local ok, xored = pcall(base64Decode, b64)
    if not ok then return nil, nil end

    local raw = xorCipher(xored, CONFIG.XOR_KEY)
    local placeId, jobId = raw:match("^(%d+)|(.+)$")
    return placeId, jobId
end

-- ================= Teleport =================
local function JoinServerFromCode(code, statusLabel)
    local placeId, jobId = decodeServerCode(code)

    if not placeId or not jobId then
        if statusLabel then statusLabel:SetText("Código inválido!") end
        warn("[MidNight Hub] Código inválido ou corrompido.")
        return
    end

    if statusLabel then statusLabel:SetText("Entrando no servidor...") end

    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(tonumber(placeId), jobId, LocalPlayer)
    end)

    if not ok then
        if statusLabel then statusLabel:SetText("Falha ao entrar no servidor.") end
        warn("[MidNight Hub] Erro no teleport: " .. tostring(err))
    end
end

-- ================= Interface =================
local Window = Library:CreateWindow({
    Name = "MidNight Hub",
    SubName = "BF Notifier",
    Logo = "rbxassetid://0", -- troque pelo seu logo
    WatermarkEnabled = true,
    WatermarkText = "MidNight Hub",
    SettingsTabEnabled = true,
})

local Page = Window:Page({
    Name = "Join Server",
    Icon = "rocket",
})

local Section = Page:Section({
    Name = "Entrar no Servidor",
})

local codeInput -- referência pro Textbox, pra ler o valor no botão

local statusLabel = Section:AddLabel("Cole o código recebido no Discord")

codeInput = Section:AddTextbox({
    Name = "Server Code",
    Flag = "mhub_join_code",
    Placeholder = "MHUB|...",
    Default = "",
    Numeric = false,
    Finished = false,
})

Section:AddButton({
    Name = "Join Server",
    Callback = function()
        local code = codeInput:Get()
        if not code or code == "" then
            statusLabel:SetText("Cole um código antes!")
            return
        end
        JoinServerFromCode(code, statusLabel)
    end,
})

print("[MidNight Hub] HUB carregado.")
