// Aqui "desativamos" o jogo para a batalha e gerencia e depois volta para o jogo de onde parou 
instance_deactivate_all(true); // => aqui fala que o oBattle será a única instância em execução

units = [];

//configuração dos inimigos na batalha
for (var i= 0; i < array_length(enemies); i++)
{
	enemyUnits[i] = instance_create_depth(x+250+(i*10), y+68+(i*20), depth - 10, oBattleUnitEnem, enemies[i]);
	array_push(units, enemyUnits[i]); // coloca o ID de cada unidade na lista geral que contèm todas as unidades na batalha (ordem de turno)
	
}
//configuração dos personagens na batalha
for (var i = 0; i < array_length(global.party); i++)
{
	partyUnits[i] = instance_create_depth(x+70+(i*10), y+68+(i*15), depth-10, oBattleUnitPC, global.party[i]);
	array_push(units, partyUnits[i]);
}