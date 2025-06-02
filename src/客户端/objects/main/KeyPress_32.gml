// 键盘按下事件 (空格键)
if (keyboard_check_pressed(vk_space)) {
    if (gameState == GameState.IN_LOBBY) {
        joinGame();
    } else if (gameState == GameState.FINISHED) {
        gameState = GameState.IN_LOBBY;
        joinGame();
    }
}
