--!strict
-- ─────────────────────────────────────────────────────────────
--  StatusEffects (ModuleScript)
--  Aplica e gerencia efeitos de status em personagens.
--  Cada efeito roda de forma independente via task.spawn.
-- ─────────────────────────────────────────────────────────────

local StatusEffects = {}

-- ── Tipos ─────────────────────────────────────────────────────
type EffectName = "Stun" | "Poison" | "Burn"

type EffectHandler = (character: Model, duration: number) -> ()

-- ── Registro de efeitos ativos (evita stack do mesmo efeito) ──
-- Chave: "CharacterName_EffectName"
local activeEffects: { [string]: boolean } = {}

local function effectKey(character: Model, effect: EffectName): string
	return character.Name .. "_" .. effect
end

-- ── Definição dos efeitos ─────────────────────────────────────

local EFFECTS: { [EffectName]: EffectHandler } = {

	-- Stun: impede movimento por X segundos
	Stun = function(character: Model, duration: number)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local originalSpeed = humanoid.WalkSpeed
		local originalJump  = humanoid.JumpPower

		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0

		-- Adiciona tag visual (BillboardGui simples)
		local root = character:FindFirstChild("HumanoidRootPart")
		local tag: BillboardGui? = nil
		if root then
			tag = Instance.new("BillboardGui")
			tag.Size = UDim2.new(0, 60, 0, 30)
			tag.StudsOffset = Vector3.new(0, 3, 0)
			tag.AlwaysOnTop = true
			local label = Instance.new("TextLabel", tag)
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = "⚡ STUN"
			label.TextColor3 = Color3.fromRGB(255, 220, 50)
			label.TextScaled = true
			tag.Parent = root
		end

		task.wait(duration)

		-- Restaura apenas se o personagem ainda existir
		if humanoid and humanoid.Parent then
			humanoid.WalkSpeed = originalSpeed
			humanoid.JumpPower = originalJump
		end
		if tag then tag:Destroy() end
	end,

	-- Poison: causa dano por tick durante X segundos
	Poison = function(character: Model, duration: number)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local tickDamage  = 3    -- dano por tick
		local tickInterval = 0.8 -- segundos entre ticks
		local elapsed     = 0

		while elapsed < duration do
			task.wait(tickInterval)
			elapsed += tickInterval
			if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then break end
			humanoid:TakeDamage(tickDamage)
		end
	end,

	-- Burn: dano por tick mais alto, duração menor
	Burn = function(character: Model, duration: number)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local tickDamage   = 6
		local tickInterval = 0.5
		local elapsed      = 0

		while elapsed < duration do
			task.wait(tickInterval)
			elapsed += tickInterval
			if not humanoid or not humanoid.Parent or humanoid.Health <= 0 then break end
			humanoid:TakeDamage(tickDamage)
		end
	end,
}

-- ── Função pública ────────────────────────────────────────────
function StatusEffects.Apply(character: Model, effect: EffectName, duration: number)
	local key     = effectKey(character, effect)
	local handler = EFFECTS[effect]

	if not handler then
		warn("[StatusEffects] Efeito desconhecido:", effect)
		return
	end

	-- Não empilha o mesmo efeito no mesmo personagem
	if activeEffects[key] then return end

	activeEffects[key] = true

	task.spawn(function()
		handler(character, duration)
		activeEffects[key] = nil
	end)
end

-- Checa se um efeito está ativo em um personagem
function StatusEffects.IsActive(character: Model, effect: EffectName): boolean
	return activeEffects[effectKey(character, effect)] == true
end

return StatusEffects
