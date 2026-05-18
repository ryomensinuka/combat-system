--!strict
-- ─────────────────────────────────────────────────────────────
--  DamageCalculator (ModuleScript)
--  Isola toda a matemática de dano em um lugar só.
--  Fácil de balancear sem tocar no resto do sistema.
-- ─────────────────────────────────────────────────────────────

local DamageCalculator = {}

-- ── Tipos ─────────────────────────────────────────────────────
export type DamageInput = {
	baseDamage  : number,  -- dano base do atacante
	comboCount  : number,  -- hit atual no combo (1, 2 ou 3)
	critChance  : number,  -- probabilidade de crítico (0.0 – 1.0)
	targetArmor : number,  -- armadura do alvo (redução flat)
}

export type DamageResult = {
	finalDamage : number,
	isCrit      : boolean,
	rawDamage   : number,  -- antes de aplicar armadura (útil para logs)
}

-- ── Tabela de multiplicadores por hit do combo ────────────────
local COMBO_MULTIPLIERS = {
	[1] = 1.0,   -- hit 1: dano normal
	[2] = 1.15,  -- hit 2: +15%
	[3] = 1.4,   -- hit 3 (finisher): +40%
}

local CRIT_MULTIPLIER = 1.75  -- crítico faz 175% do dano

-- ── Fórmula de redução de armadura ───────────────────────────
-- Usa a fórmula clássica: dano_final = dano * (100 / (100 + armadura))
-- Evita valores negativos e garante que armadura nunca zere o dano.
local function applyArmor(damage: number, armor: number): number
	armor = math.max(0, armor)
	return damage * (100 / (100 + armor))
end

-- ── Função principal ──────────────────────────────────────────
function DamageCalculator.Calculate(input: DamageInput): DamageResult
	-- 1. Multiplica pelo combo
	local comboMult = COMBO_MULTIPLIERS[input.comboCount] or 1.0
	local rawDamage = input.baseDamage * comboMult

	-- 2. Checa crítico
	local isCrit = math.random() <= input.critChance
	if isCrit then
		rawDamage = rawDamage * CRIT_MULTIPLIER
	end

	-- 3. Aplica armadura do alvo
	local reduced = applyArmor(rawDamage, input.targetArmor)

	-- 4. Arredonda e garante mínimo de 1 de dano
	local finalDamage = math.max(1, math.round(reduced))

	return {
		finalDamage = finalDamage,
		isCrit      = isCrit,
		rawDamage   = math.round(rawDamage),
	}
end

return DamageCalculator
