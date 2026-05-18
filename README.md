# ⚔️ combat-system (Roblox / Luau)

Sistema de combate modular para Roblox Studio, escrito em Luau com `--!strict`.  
Projetado para ser limpo, seguro e fácil de expandir em projetos maiores.

---

## ✨ Funcionalidades

- **Validação server-side** — todas as ações são verificadas no servidor (range, cooldown, alvo válido)
- **Sistema de combo** — até 3 hits encadeados com multiplicadores de dano crescentes
- **Cálculo de dano isolado** — módulo separado com suporte a crítico e redução por armadura
- **Efeitos de status** — Stun, Poison e Burn, sem stack do mesmo efeito
- **Feedback visual** — floating damage numbers com animação (diferente para crítico)
- **Detecção de alvo por raycast** — mira pelo centro da tela

---

## 📁 Estrutura

```
combat-system/
└── src/
    ├── CombatService.luau      # ServerScript — lógica central e validações
    ├── DamageCalculator.luau   # ModuleScript — matemática de dano e crítico
    ├── StatusEffects.luau      # ModuleScript — efeitos de status (Stun, Poison, Burn)
    └── CombatClient.luau       # LocalScript — input do jogador e feedback visual
```

---

## 🚀 Como usar no Roblox Studio

### 1. Criar os RemoteEvents

Em `ReplicatedStorage`, crie uma pasta chamada `CombatRemotes` com dois `RemoteEvent`:
- `RequestAttack` — cliente → servidor (pedido de ataque)
- `OnHit` — servidor → clientes (feedback de hit)

### 2. Colocar os scripts

| Script               | Onde colocar                          |
|----------------------|---------------------------------------|
| `CombatService`      | `ServerScriptService`                 |
| `DamageCalculator`   | Dentro de `CombatService` (ModuleScript) |
| `StatusEffects`      | Dentro de `CombatService` (ModuleScript) |
| `CombatClient`       | `StarterPlayerScripts`                |

### 3. Atributos do personagem (opcional)

Você pode definir esses atributos no `Character` para personalizar por classe:

| Atributo     | Tipo   | Padrão | Descrição                      |
|--------------|--------|--------|-------------------------------|
| `BaseDamage` | number | 10     | Dano base do atacante          |
| `CritChance` | number | 0.10   | Chance de crítico (0.0 – 1.0)  |
| `Armor`      | number | 0      | Redução de dano do alvo        |

---

## ⚙️ Balanceamento

Todos os valores de gameplay estão centralizados em tabelas no topo de cada módulo — fácil de ajustar sem mexer na lógica:

```lua
-- CombatService.luau
local CONFIG = {
    AttackCooldown = 0.6,
    MaxAttackRange = 8,
    ComboWindow    = 1.2,
    MaxCombo       = 3,
}

-- DamageCalculator.luau
local COMBO_MULTIPLIERS = { [1]=1.0, [2]=1.15, [3]=1.4 }
local CRIT_MULTIPLIER   = 1.75
```

---

## 🛡️ Segurança

- Toda validação roda **exclusivamente no servidor**
- O cliente nunca define o valor do dano — apenas solicita o ataque
- Impossível atacar a si mesmo ou alvos fora do range

---

Feito com ☕ por [Arthur Calebe](https://github.com/ryomensinuka)
