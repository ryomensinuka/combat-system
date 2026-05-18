--!strict
-- ─────────────────────────────────────────────────────────────
--  CombatService (ServerScript)
--  Responsável por validar, processar e aplicar combate.
--  Comunicação via RemoteEvents em ReplicatedStorage.
-- ─────────────────────────────────────────────────────────────

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local DamageCalculator = require(script.Parent.DamageCalculator)
local StatusEffects    = require(script.Parent.StatusEffects)

-- ── RemoteEvents ─────────────────────────────────────────────
local Remotes   = ReplicatedStorage:WaitForChild("CombatRemotes")
local RE_Attack = Remotes:WaitForChild("RequestAttack")   -- Client → Server
local RE_Hit    = Remotes:WaitForChild("OnHit")           -- Server → Client (feedback)

-- ── Configurações gerais ──────────────────────────────────────
local CONFIG = {
	AttackCooldown   = 0.6,   -- segundos entre ataques
	MaxAttackRange   = 8,     -- distância máxima (studs) para acertar
	ComboWindow      = 1.2,   -- janela de tempo para encadear combo
	MaxCombo         = 3,     -- máximo de hits no combo
}

-- ── Estado dos jogadores ──────────────────────────────────────
-- Guarda cooldown e combo por jogador (limpo ao sair)
local playerState: { [Player]: { lastAttack: number, combo: number, lastHit: number } } = {}

local function getState(player: Player)
	if not playerState[player] then
		playerState[player] = { lastAttack = 0, combo = 0, lastHit = 0 }
	end
	return playerState[player]
end

Players.PlayerRemoving:Connect(function(player)
	playerState[player] = nil
end)

-- ── Validações ────────────────────────────────────────────────

-- Checa se o ataque está fora do cooldown
local function isCooldownReady(state): boolean
	return (tick() - state.lastAttack) >= CONFIG.AttackCooldown
end

-- Checa se o alvo está dentro do range
local function isInRange(attacker: Player, targetCharacter: Model): boolean
	local atkRoot = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
	local tgtRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
	if not atkRoot or not tgtRoot then return false end
	return (atkRoot.Position - tgtRoot.Position).Magnitude <= CONFIG.MaxAttackRange
end

-- Checa se o alvo é um personagem válido e vivo
local function isValidTarget(targetCharacter: Model): boolean
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- ── Lógica de combo ───────────────────────────────────────────
local function updateCombo(state): number
	local now = tick()
	-- Se passou a janela de combo, reseta
	if (now - state.lastHit) > CONFIG.ComboWindow then
		state.combo = 0
	end
	state.combo = math.min(state.combo + 1, CONFIG.MaxCombo)
	state.lastHit = now
	return state.combo
end

-- ── Aplicar dano ao alvo ──────────────────────────────────────
local function applyDamage(
	attacker: Player,
	targetCharacter: Model,
	comboCount: number
)
	local humanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	-- Pega os atributos do atacante (definidos no Character pelo jogo)
	local attackerChar = attacker.Character
	local baseDamage   = if attackerChar then attackerChar:GetAttribute("BaseDamage") or 10 else 10
	local critChance   = if attackerChar then attackerChar:GetAttribute("CritChance") or 0.1 else 0.1

	-- Calcula dano final via módulo separado
	local result = DamageCalculator.Calculate({
		baseDamage  = baseDamage,
		comboCount  = comboCount,
		critChance  = critChance,
		targetArmor = targetCharacter:GetAttribute("Armor") or 0,
	})

	humanoid:TakeDamage(result.finalDamage)

	-- Aplica efeito de status se o combo chegou ao máximo
	if comboCount >= CONFIG.MaxCombo then
		StatusEffects.Apply(targetCharacter, "Stun", 1.5)
	end

	-- Notifica clientes sobre o hit (para feedback visual/sonoro)
	RE_Hit:FireAllClients({
		attacker    = attacker,
		target      = targetCharacter,
		damage      = result.finalDamage,
		isCrit      = result.isCrit,
		comboCount  = comboCount,
	})
end

-- ── Handler principal: recebe pedido de ataque do cliente ─────
RE_Attack.OnServerEvent:Connect(function(attacker: Player, targetCharacter: Model)
	-- Validações de segurança (NUNCA confie no cliente)
	if not attacker.Character then return end
	if not targetCharacter or not targetCharacter:IsA("Model") then return end
	if not isValidTarget(targetCharacter) then return end
	if not isInRange(attacker, targetCharacter) then return end

	-- Impede atacar a si mesmo
	if attacker.Character == targetCharacter then return end

	local state = getState(attacker)
	if not isCooldownReady(state) then return end

	-- Atualiza estado
	state.lastAttack = tick()
	local comboCount = updateCombo(state)

	-- Aplica o dano
	applyDamage(attacker, targetCharacter, comboCount)
end)

print("[CombatService] Carregado com sucesso.")
