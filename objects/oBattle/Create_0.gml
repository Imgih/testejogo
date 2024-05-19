instance_deactivate_all(true); // Desativa todas as instâncias, exceto oBattle

units = [];
turn = 0;
unitTurnOrder = [];
unitRenderOrder = []; 

turnCount = 0;
roundCount = 0;
battleWaitTimeFrames = 30;
battleWaitTimeRemaining = 0;
currentUser = noone;
currentAction = -1;
currentTargets = noone;

battleText = "";

cursor = 
{
    activeUser: noone,
    activeTarget: noone,
    activeAction : -1,
    targetSide : -1,
    targetIndex : 0,
    targetAll : false,
    confirmDelay : 0,
    active : false
};

// Configuração dos inimigos na batalha
for (var i = 0; i < array_length(enemies); i++) {    
    enemyUnits[i] = instance_create_depth(x + 250 + (i * 10), y + 68 + (i * 20), depth - 10, oBattleUnitEnem, enemies[i]);
    array_push(units, enemyUnits[i]); // Coloca o ID de cada unidade na lista geral que contém todas as unidades na batalha (ordem de turno)
}

// Configuração dos personagens na batalha
for (var i = 0; i < array_length(global.party); i++) {
    partyUnits[i] = instance_create_depth(x + 70 + (i * 10), y + 68 + (i * 15), depth - 10, oBattleUnitPC, global.party[i]);
    array_push(units, partyUnits[i]);
}

unitTurnOrder = array_shuffle(units);

RefreshRenderOrder = function() {
    unitRenderOrder = [];
    array_copy(unitRenderOrder, 0, units, 0, array_length(units));
    array_sort(unitRenderOrder, function(_1, _2) {
        return _1.y - _2.y;
    });
}

RefreshRenderOrder();

// CONFIGURAÇÕES DE BATALHA

function BattleStateSelectAction() {
    if (!instance_exists(oMenu)) {
        var _unit = unitTurnOrder[turn];

        // Saber se o personagem está morto ou apto a atacar
        if (!instance_exists(_unit) || (_unit.hp <= 0)) {
            battleState = BattleStateVictoryCheck;
            exit;
        }

        // Seleciona uma ação para ser executada
        //BeginAction(_unit.id, global.actionLibrary.attack, _unit.id);

        // Se a unit é um jogador mandando
        if (_unit.object_index == oBattleUnitPC) {
            var _menuOptions = [];
            var _subMenus = {};

            var _actionList = _unit.actions;

            for (var i = 0; i < array_length(_actionList); i++) {
                var _action = _actionList[i];
                var _available = true;
                var _nameAndCount = _action.name;
                if (_action.subMenu == -1) {
                    array_push(_menuOptions, [_nameAndCount, MenuSelectAction, [_unit, _action], _available]);
                } else {
                    if (is_undefined(_subMenus[$ _action.subMenu])) {
                        variable_struct_set(_subMenus, _action.subMenu, [[_nameAndCount, MenuSelectAction, [_unit, _action], _available]]);
                    } else {
                        array_push(_subMenus[$ _action.subMenu], [_nameAndCount, MenuSelectAction, [_units, _action], _available]);
                    }
                }
            }

            var _subMenusArray = variable_struct_get_names(_subMenus);
            for (var i = 0; i < array_length(_subMenusArray); i++) {
                // Sortear o submenu se preciso
                // Aqui
                
                // Adicionar a opção de voltar no final de cada submenu
                array_push(_subMenus[$ _subMenusArray[i]], ["Back", MenuGoBack, -1, true]);
                // Adicionar submenu no menu principal
                array_push(_menuOptions, [_subMenusArray[i], SubMenu, [_subMenus[$ _subMenusArray[i]]], true]);
            }
            Menu(x + 10, y + 110, _menuOptions, , 74, 60);
        } else {
            // Se for a IA controlando
            var _enemyAction = _unit.AIscript();
            if (_enemyAction != -1) BeginAction(_unit.id, _enemyAction[0], _enemyAction[1]);
        }
    }
}

// Função para iniciar uma ação

function BeginAction(_user, _action, _targets) {
    currentUser = _user;
    currentAction = _action;
    currentTargets = _targets;
    
    // Verificar se o usuário é um personagem controlado pelo jogador e se a ação é "Fraco"
    if (_user.object_index == oBattleUnitPC && _action.name == "Fraco") {
        // Recarregar MP em 3 unidades
        _user.mp += 3;
        if (_user.mp > _user.mpMax) _user.mp = _user.mpMax; // Garantir que o MP não ultrapasse o máximo
    } else if (_user.object_index == oBattleUnitPC && _action.name != "Defend") {
        // Verificar se o MP é suficiente para a ação
        if (_action.mpCost > _user.mp) {
            battleText = "MP insuficiente!";
            battleState = BattleStateSelectAction; // Voltar para a seleção de ação
            exit; // Sair da função
        }
        
        // Reduzir MP
        _user.mp -= _action.mpCost;
        if (_user.mp < 0) _user.mp = 0; // Garantir que o MP não seja negativo
    }
    
    // Se a ação não for "Defend", continuar com o processo de execução da ação
    if (_action.name != "Defend") {
        battleText = string_ext(_action.description, [_user.name]);
        if (!is_array(currentTargets)) currentTargets = [currentTargets];
        battleWaitTimeRemaining = battleWaitTimeFrames;
        with (_user) {
            acting = true;
            if (!is_undefined(_action[$ "userAnimation"]) && !is_undefined(_user.sprites[$ _action.userAnimation])) {
                sprite_index = sprites[$ _action.userAnimation];
                image_index = 0;
            }
        }
        battleState = BattleStatePerformAction;
    }
}

function BattleStatePerformAction() {
    // Se a animação ainda está acontecendo 
    if (currentUser.acting) {
        if (currentUser.image_index >= currentUser.image_number - 1) {
            with (currentUser) {
                sprite_index = sprites.idle;
                image_index = 0;
                acting = false;
            }
            
            if (variable_struct_exists(currentAction, "effectSprite")) {
                if (currentAction.effectOnTarget == MODE.ALWAYS || 
                    (currentAction.effectOnTarget == MODE.VARIES && array_length(currentTargets) <= 1)) {
                    for (var i = 0; i < array_length(currentTargets); i++) {
                        instance_create_depth(currentTargets[i].x, currentTargets[i].y, currentTargets[i].depth - 1, oBattleEffect, {sprite_index: currentAction.effectSprite});
                    }
                } else {
                    var _effectSprite = currentAction.effectSprite;
                    if (variable_struct_exists(currentAction, "effectSpriteNoTarget")) _effectSprite = currentAction.effectSpriteNoTarget;
                    instance_create_depth(x, y, depth - 100, oBattleEffect, {sprite_index: _effectSprite});
                }
            }
            currentAction.func(currentUser, currentTargets);
        }
    } else {
        if (!instance_exists(oBattleEffect)) {
            battleWaitTimeRemaining--;
            if (battleWaitTimeRemaining == 0) {
                battleState = BattleStateVictoryCheck;
            }
        }
    }
}

global.battleTrigger = noone;

// Função para iniciar a batalha (chame isso quando a batalha começar)
function StartBattle(_collisionObject) {
    global.battleTrigger = _collisionObject;
    // Outras lógicas de inicialização da batalha...
    instance_deactivate_all(true); // Desativa todas as instâncias
    instance_activate_object(oBattle); // Ativa a instância de batalha
    oBattle.active = true; // Garantir que a batalha esteja ativa
}

// Função para verificar vitória e derrota
function BattleStateVictoryCheck() {
    var allEnemiesDefeated = true;
    var allPartyDefeated = true;

    for (var i = 0; i < array_length(enemyUnits); i++) {
        if (enemyUnits[i].hp > 0) {
            allEnemiesDefeated = false;
            break;
        }
    }

    for (var i = 0; i < array_length(partyUnits); i++) {
        if (partyUnits[i].hp > 0) {
            allPartyDefeated = false;
            break;
        }
    }

    if (allEnemiesDefeated || allPartyDefeated) {
        EndBattle();
    } else {
        battleState = BattleStateTurnProgression;
    }
}

function EndBattle() {
    // Lógica de finalização da batalha, como recompensas e experiência
    // ...

    // Remover o objeto de colisão que iniciou a batalha
    if (instance_exists(global.battleTrigger)) {
        instance_destroy(global.battleTrigger);
    }

    // Restaurar o estado do jogo
  instance_deactivate_all(false);
   // Reativa todas as instâncias

    // Fechar a tela de combate e voltar ao mapa
    instance_destroy(oBattle); // Ou outra lógica específica para fechar a tela de combate
}

// Função para progressão do turno
function BattleStateTurnProgression() {
    battleText = "";
    turnCount++;
    turn++;
    
    // Loop dos turnos
    if (turn > array_length(unitTurnOrder) - 1) {
        turn = 0;
        roundCount++;
    }

    // Desativar a defesa do personagem que acabou de concluir o turno
    var _previousTurn = turn - 1;
    if (_previousTurn < 0) {
        _previousTurn = array_length(unitTurnOrder) - 1;
    }
    
    var _unit = unitTurnOrder[_previousTurn];

    // Verificar se a variável defendingTurn existe antes de acessá-la
    if (variable_instance_exists(_unit, "defendingTurn") && _unit.defendingTurn) {
        _unit.isDefending = false;
        _unit.defendingTurn = false;
        _unit.sprite_index = _unit.sprites.idle;
    }

    battleState = BattleStateSelectAction;
}

// Função de exemplo para aplicar dano com mitigação de defesa
function ApplyDamage(target, damage) {
    // Verifica se o alvo está defendendo
    if (target.defendingTurn) {
        // Mitiga todo o dano
        damage = 0;
        // Alternativamente, você pode reduzir o dano pela metade ou outro fator
        // damage = damage / 2;
    }
    target.hp -= damage;
    if (target.hp < 0) target.hp = 0;
}

battleState = BattleStateSelectAction;
