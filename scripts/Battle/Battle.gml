// configurações da batalha, como fundo e inimigos
function NewEncounter(_enemies, _bg) {
	
	instance_create_depth(
	camera_get_view_x(view_camera[0]),// como será nossa visão da batalha eixos (x e y)
	camera_get_view_y(view_camera[0]),
	-9999, // profundidade
	oBattle,
	{enemies: _enemies, creator: id, battleBackground: _bg}
	
	);
}