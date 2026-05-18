--!strict
-- ─────────────────────────────────────────────────────────────
--  CombatClient (LocalScript)
--  Detecta input do jogador e envia pedido de ataque ao server.
--  Também exibe feedback visual de dano (floating numbers).
-- ─────────────────────────────────────────────────────────────

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera

-- ── RemoteEvents ─────────────────────────────────────────────
local Remotes   = ReplicatedStorage:WaitForChild("CombatRemotes")
local RE_Attack = Remotes:WaitForChild("RequestAttack")
local RE_Hit    = Remotes:WaitForChild("OnHit")

-- ── Configurações do cliente ──────────────────────────────────
local ATTACK_KEY   = Enum.UserInputType.MouseButton1  -- clique esquerdo
local ATTACK_RANGE = 8  -- deve espelhar o valor do server

-- ── Detecção de alvo por raycast ──────────────────────────────
local function getTargetCharacter(): Model?
	local unitRay = Camera:ScreenPointToRay(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { LocalPlayer.Character }
	params.FilterType = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(unitRay.Origin, unitRay.Direction * ATTACK_RANGE, params)
	if not result then return nil end

	-- Sobe na hierarquia até encontrar um Model com Humanoid
	local hit = result.Instance
	local model = hit:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return model
	end

	return nil
end

-- ── Input: enviar ataque ao server ────────────────────────────
UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if input.UserInputType ~= ATTACK_KEY then return end

	local target = getTargetCharacter()
	if not target then return end

	RE_Attack:FireServer(target)
end)

-- ── Feedback: floating damage numbers ────────────────────────
local function showDamageNumber(targetCharacter: Model, damage: number, isCrit: boolean)
	local root = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- BillboardGui flutuante
	local billboard    = Instance.new("BillboardGui")
	billboard.Size     = UDim2.new(0, 80, 0, 40)
	billboard.StudsOffset = Vector3.new(
		math.random(-1, 1),  -- leve variação horizontal
		2.5,
		0
	)
	billboard.AlwaysOnTop  = true
	billboard.LightInfluence = 0
	billboard.Parent = root

	local label            = Instance.new("TextLabel", billboard)
	label.Size             = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled       = true
	label.Font             = Enum.Font.GothamBold

	-- Visual diferente para crítico
	if isCrit then
		label.Text      = "💥 " .. tostring(damage)
		label.TextColor3 = Color3.fromRGB(255, 80, 80)
	else
		label.Text      = tostring(damage)
		label.TextColor3 = Color3.fromRGB(255, 220, 50)
	end

	-- Anima: sobe e desaparece
	local startOffset = billboard.StudsOffset
	local duration    = 0.9
	local elapsed     = 0

	game:GetService("RunService").Heartbeat:Connect(function(dt)
		elapsed += dt
		local t = elapsed / duration

		billboard.StudsOffset = startOffset + Vector3.new(0, t * 2.5, 0)
		label.TextTransparency = t

		if elapsed >= duration then
			billboard:Destroy()
		end
	end)
end

-- ── Ouvir hits vindos do server ───────────────────────────────
RE_Hit.OnClientEvent:Connect(function(data: {
	attacker   : Player,
	target     : Model,
	damage     : number,
	isCrit     : boolean,
	comboCount : number,
})
	-- Mostra número de dano para todos os clientes
	showDamageNumber(data.target, data.damage, data.isCrit)

	-- Log local apenas para quem atacou
	if data.attacker == LocalPlayer then
		local msg = string.format(
			"[Combate] Hit %d | Dano: %d%s",
			data.comboCount,
			data.damage,
			if data.isCrit then " (CRÍTICO!)" else ""
		)
		print(msg)
	end
end)

print("[CombatClient] Carregado com sucesso.")
