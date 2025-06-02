// 定时发送位置更新
var currentTime = current_time;
if (currentTime - lastUpdateTime >= UPDATE_INTERVAL) {
    lastUpdateTime = currentTime;
    sendPositionUpdateBinary();
}

