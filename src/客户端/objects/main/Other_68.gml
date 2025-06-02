var network_event_type = ds_map_find_value(async_load, "type");

// 如果是网络事件
if (network_event_type == network_type_data) {
    // 确保这个事件是给我们的套接字的
    var event_socket = ds_map_find_value(async_load, "id");
    if (event_socket == global.socket) {
        // 获取接收到的数据
        var received_buffer = ds_map_find_value(async_load, "buffer");
        
        // 检查数据长度，判断是否为二进制位置数据
        var buffer_size = buffer_get_size(received_buffer);
        
        // 如果是二进制位置数据（17字节，且第一个字节是位置广播类型）
        if (buffer_size == 17) {
            buffer_seek(received_buffer, buffer_seek_start, 0);
            var data_type = buffer_peek(received_buffer, 0, buffer_u8);
            
            if (data_type == DATA_TYPE_POSITION_BROADCAST) {
                // 处理二进制位置广播
                parsePositionBroadcast(received_buffer);
                return; // 已处理完毕，不需要继续解析JSON
            }
        }
        if (buffer_size%17 == 0) {
            buffer_seek(received_buffer, buffer_seek_start, 0);
            var data_type = buffer_peek(received_buffer, 0, buffer_u8);
            
            if (data_type == DATA_TYPE_POSITION_BROADCAST) {
                // 处理二进制位置广播
                
                repeat(buffer_size/17)
                {
                    parsePositionBroadcast(received_buffer);
                }
                return; // 已处理完毕，不需要继续解析JSON
            }
        }
        
        // 如果不是二进制位置数据，按照原来的方式处理JSON
        buffer_seek(received_buffer, buffer_seek_start, 0);
        var message_str = buffer_read(received_buffer, buffer_string);
        
        show_debug_message("从服务器接收到数据: " + message_str);
        
        // 解析JSON
        try {
            var message_obj = json_parse(message_str);
            handleServerMessage(message_obj);
        } catch (e) {
            show_debug_message("解析消息失败: " + message_str);
        }
    }
}

// 如果发生连接事件
if (network_event_type == network_type_non_blocking_connect) {
    // 检查是否成功连接
    var connect_success = ds_map_find_value(async_load, "succeeded");
    if (connect_success) {
        connected = true;
        show_debug_message("已成功连接到服务器");
    } else {
        show_debug_message("连接失败");
        gameState = GameState.DISCONNECTED;
    }
}

// 如果是断开连接事件
if (network_event_type == network_type_disconnect) {
    connected = false;
    gameState = GameState.DISCONNECTED;
    show_debug_message("与服务器断开连接");
    
    // 尝试重新连接
    alarm[0] = game_get_speed(1) * 3; // 3秒后尝试重连
}

