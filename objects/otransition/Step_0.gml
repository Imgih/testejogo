if (transitioning) {
    alpha += transitionSpeed;
    if (alpha >= 1) {
        // Muda para a próxima sala e reinicia a transição
        room_goto(nextRoom);
        audio_play_sound(Novojogo, 1, false);
    }
} else if (alpha > 0) {
    alpha -= transitionSpeed;
    if (alpha < 0) alpha = 0;
}
