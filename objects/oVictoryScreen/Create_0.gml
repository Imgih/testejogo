// Objeto oVictoryScreen
function oVictoryScreen() {
    // Configurações iniciais
    event_perform_object(oVictoryScreen, ev_create, function() {

        draw_text(x, y, "Vitória! Todos os inimigos foram derrotados.");
    });
}
