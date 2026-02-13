# Sistema de Inimigos e Fases - Documentação

## 📋 Resumo das Mudanças

### ✅ Problemas Corrigidos
1. **Pickups agora dropam corretamente** - Sistema global de pickups implementado
2. **Sistema de Resources** - Padronização de configurações
3. **Randomização de inimigos** - Múltiplos inimigos podem spawnar na mesma fase
4. **Randomização de fases** - Sistema de transição entre fases aleatórias

---

## 🎮 Como Funciona

### 1. Sistema de Resources

#### **EnemyData** (`scripts/enemy_data.gd`)
Resource que armazena as configurações padronizadas de cada inimigo:
- Velocidade, vida, dano
- Configurações de combate
- Chances de drop
- Multiplicadores de boss

**Arquivos criados:**
- `resources/enemies/goblin_data.tres` - Configurações do Goblin
- `resources/enemies/cow_data.tres` - Configurações da Cow

#### **LevelData** (`scripts/level_data.gd`)
Resource que armazena as configurações padronizadas de cada fase:
- Lista de inimigos que podem aparecer
- Configurações de spawn
- Próximas fases possíveis
- Configurações de boss

**Arquivos criados:**
- `resources/levels/forest_data.tres` - Configurações da Forest
- `resources/levels/beach_data.tres` - Configurações da Beach

---

### 2. Sistema de Pickups Globais

#### **GameGlobals** (`scripts/game_globals.gd`)
Autoload que gerencia:
- Referências globais das cenas de pickup
- Lista de fases disponíveis
- Transição entre fases
- Randomização

**Como funciona:**
1. GameGlobals carrega as cenas de pickup no `_ready()`
2. Os inimigos pegam essas referências automaticamente
3. Quando um inimigo morre, usa essas cenas para dropar items

---

### 3. Sistema de Fases

#### **LevelManager** (`scripts/level_manager.gd`)
Script base que gerencia qualquer fase:
- Spawn de inimigos aleatórios da lista
- Sistema de boss
- Transição para próxima fase aleatória
- Tela de upgrade

**Scripts de fases:**
- `scripts/forest.gd` - Herda de LevelManager
- `scripts/beach.gd` - Herda de LevelManager

---

## 🔧 Como Adicionar Novo Conteúdo

### Adicionar Novo Inimigo

1. **Criar o Resource:**
```gdscript
# resources/enemies/novo_inimigo_data.tres
[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/enemy_data.gd" id="1_1"]

[resource]
script = ExtResource("1_1")
enemy_name = "Novo Inimigo"
speed = 35.0
health = 100
damage = 15
# ... outras configurações
```

2. **Criar a cena:**
   - Duplicar `goblin.tscn` ou `cow.tscn`
   - Trocar o sprite
   - Adicionar o novo resource em `enemy_data`

3. **Adicionar às fases:**
   - Abrir o resource da fase desejada
   - Adicionar a cena do inimigo em `enemy_scenes`

### Adicionar Nova Fase

1. **Criar o Resource:**
```gdscript
# resources/levels/nova_fase_data.tres
[gd_resource type="Resource" script_class="LevelData" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/level_data.gd" id="1_1"]
[ext_resource type="PackedScene" path="res://characters/goblin.tscn" id="2_1"]
[ext_resource type="PackedScene" path="res://characters/cow.tscn" id="3_1"]

[resource]
script = ExtResource("1_1")
level_name = "Nova Fase"
enemy_scenes = Array[PackedScene]([ExtResource("2_1"), ExtResource("3_1")])
# ... outras configurações
```

2. **Criar a cena:**
   - Duplicar `forest.tscn` ou `beach.tscn`
   - Criar script que herda de `LevelManager`
   - Adicionar o resource em `level_data`

3. **Adicionar ao GameGlobals:**
```gdscript
# Em scripts/game_globals.gd, adicionar na lista:
available_levels = [
    load("res://rooms/forest.tscn"),
    load("res://rooms/beach.tscn"),
    load("res://rooms/nova_fase.tscn")  # Nova fase
]
```

---

## 📁 Estrutura de Arquivos

```
projeto/
├── scripts/
│   ├── enemy_data.gd          # Resource base para inimigos
│   ├── level_data.gd          # Resource base para fases
│   ├── enemy.gd               # Script do inimigo (atualizado)
│   ├── level_manager.gd       # Script base para fases
│   ├── game_globals.gd        # Autoload com configurações globais
│   ├── forest.gd              # Script da fase Forest
│   └── beach.gd               # Script da fase Beach
│
├── resources/
│   ├── enemies/
│   │   ├── goblin_data.tres   # Dados do Goblin
│   │   └── cow_data.tres      # Dados da Cow
│   │
│   └── levels/
│       ├── forest_data.tres   # Dados da Forest
│       └── beach_data.tres    # Dados da Beach
│
├── characters/
│   ├── goblin.tscn            # Cena do Goblin (atualizada)
│   └── cow.tscn               # Cena da Cow (atualizada)
│
└── rooms/
    ├── forest.tscn            # Cena da Forest
    └── beach.tscn             # Cena da Beach
```

---

## 🎯 Diferenças: Resource vs Cena

### **O que vai no Resource:**
✅ Configurações que são compartilhadas/padronizadas:
- Velocidade base do inimigo
- Vida base
- Dano base
- Chances de drop
- Multiplicadores de boss

### **O que vai na Cena:**
✅ Características únicas da instância:
- Sprite visual específico
- Tamanho do colisor
- Efeitos de luz
- Sons específicos
- Overrides de configurações (se necessário)

---

## 🔄 Fluxo de Execução

1. **Início do Jogo:**
   - GameGlobals carrega pickups e fases
   
2. **Fase Inicia:**
   - LevelManager carrega dados do LevelData
   - Timer de spawn começa
   
3. **Spawn de Inimigo:**
   - Escolhe inimigo aleatório da lista
   - Instancia com configurações do EnemyData
   - Conecta sinal de morte
   
4. **Inimigo Morre:**
   - Verifica chance de drop
   - Instancia pickup do GameGlobals
   - Emite sinal de morte
   
5. **Boss Derrotado:**
   - Mostra tela de upgrade
   - Após upgrade, vai para próxima fase aleatória
   - GameGlobals escolhe fase da lista

---

## 🐛 Debug

Se os pickups não estiverem funcionando:
1. Verificar se GameGlobals está configurado como autoload
2. Verificar se as cenas de pickup existem nos caminhos corretos
3. Olhar no console por mensagens de debug
4. Verificar se o inimigo tem `health_pickup_scene` e `reroll_pickup_scene`

---

## 💡 Próximas Melhorias Possíveis

- [ ] Sistema de progressão de dificuldade
- [ ] Diferentes tipos de bosses
- [ ] Eventos especiais em fases
- [ ] Sistema de achievements
- [ ] Spawn de inimigos por wave
- [ ] Biomas com características únicas
