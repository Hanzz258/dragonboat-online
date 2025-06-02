// 游戏常量
#macro FREC display_get_frequency()
#macro SERVER_IP "47.95.157.0"
#macro SERVER_PORT 8080
#macro UPDATE_INTERVAL 50 // 毫秒
#macro LERP_RATE 60/FREC/20
#macro RATE 60/FREC
#macro DATA_TYPE_POSITION_UPDATE 1
#macro DATA_TYPE_POSITION_BROADCAST 2

// 游戏状态
enum GameState {
    DISCONNECTED,
    CONNECTING,
    IN_LOBBY,
    WAITING_FOR_PLAYERS,
    COUNTDOWN,
    RACING,
    FINISHED
}

// 房间属性
global.RoomAttr = {
    startX:666,
    startY:7600,
    endX:7872,
    endY:4471,
    spawnRadius:100,
    endRadius:100
}

if persistent = false
{ 
    persistent = true;

    // 分辨率设置
    var windowrate=0.8;
    if os_type=os_macosx windowrate=0.75;
    var wdw=floor(display_get_width()*windowrate),wdh=floor(display_get_height()*windowrate);
    
    window_set_size(wdw,wdh);
    display_set_gui_size(window_get_width(),window_get_height());
    room_width=window_get_width();
    room_height=window_get_height();
    camera_set_view_size(view_camera[0],room_width,room_height);
    surface_resize(application_surface,room_width,room_height);
    window_center();
    var wgw=window_get_width(),wgh=window_get_height();
    macosxRetina=(wgw!=wdw);
    global.scal=wgw/3840
    
    //UI
    global.font_icon=font_add("icon.ttf", global.scal*256-macosxRetina*128, 0, 0, 0,256)
    
    global.selfSpr=-1
    // 创建对象
    // 初始化变量
    global.socket = network_create_socket(network_socket_tcp);
    connected = false;
    clientId = "";
    roomId = "";
    gameState = GameState.DISCONNECTED;
    randomize();
    playerName = "Player" + string(irandom_range(1000, 9999));
    countdownTime = 0;
    countdownTimeAnim = 30;
    otherPlayers = ds_map_create();
    finishRankings = ds_list_create();
    lastUpdateTime = current_time;
    raceFinished = false;
    playerRank = 0;
    clientIdNumeric = 0;
    MapID = -1;
    animTick=0
    btnPlayScal=1
    animAlpha1=1
    statusBgChange=1
    // 流缓冲
    global.buffer_remainder = buffer_create(1024, buffer_grow, 1);
    global.buffer_remainder_size = 0;
    if !audio_is_playing(snd_title) audio_play_sound(snd_title,0,1)
    
    // 连接到服务器
    function connectToServer() {
        gameState = GameState.CONNECTING;
        var connection = network_connect_raw_async(global.socket, SERVER_IP, SERVER_PORT);
        
        if (connection < 0) {
            show_debug_message("无法连接到服务器");
            gameState = GameState.DISCONNECTED;
        } else {
            show_debug_message("正在尝试连接到服务器...");
        }
    }
    
    // 发送消息到服务器
    function sendToServer(messageObj) {
        if (!connected) {
            show_debug_message("未连接到服务器，无法发送消息");
            return;
        }
        
        var jsonString = json_stringify(messageObj);
        
        // 确保JSON字符串不为空
        if (string_length(jsonString) == 0) {
            show_debug_message("警告: 尝试发送空JSON");
            return;
        }
        
        // 创建缓冲区并写入数据
        var buffer = buffer_create(string_byte_length(jsonString) + 1, buffer_fixed, 1);
        buffer_seek(buffer, buffer_seek_start, 0);
        buffer_write(buffer, buffer_text, jsonString); // 使用buffer_text而不是buffer_string
        
        // 检查缓冲区大小
        var bufferSize = buffer_get_size(buffer);
        
        // 发送数据
        var result = network_send_raw(global.socket, buffer, bufferSize);
        
        buffer_delete(buffer);
    }
    
    function sendPositionUpdateBinary() {
        if (!connected || gameState != GameState.RACING) return;
        
        // 创建二进制缓冲区 [类型(1字节), 玩家ID(4字节), x(4字节), y(4字节), angle(4字节)]
        var buffer = buffer_create(17, buffer_fixed, 1);
        buffer_seek(buffer, buffer_seek_start, 0);
        
        // 写入数据类型
        buffer_write(buffer, buffer_u8, DATA_TYPE_POSITION_UPDATE);
        
        // 写入玩家ID（数字部分）
        buffer_write(buffer, buffer_u32, clientIdNumeric);
        
        // 写入位置和角度数据（32位浮点数）
        buffer_write(buffer, buffer_f32, obj_player.x);
        buffer_write(buffer, buffer_f32, obj_player.y);
        buffer_write(buffer, buffer_f32, obj_player.image_angle);
        
        // 发送数据
        var result = network_send_raw(global.socket, buffer, buffer_get_size(buffer));
        
        buffer_delete(buffer);
    }
    
    // 加入游戏
    function joinGame() {
        sendToServer({
            type: "join_game",
            name: playerName
        });
    }
    
    // 发送位置更新
    function sendPositionUpdate() {
        if (gameState != GameState.RACING) return;
        
        sendToServer({
            type: "position_update",
            x: obj_player.x,
            y: obj_player.y,
            angle: obj_player.image_angle
        });
    }
    
    // 通知服务器玩家到达终点
    function notifyFinishReached() {
        if (gameState != GameState.RACING || raceFinished) return;
        
        sendToServer({
            type: "finish_reached"
        });
        
        raceFinished = true;
        show_debug_message("eee")
    }
    
    // 新增：解析二进制位置广播数据
    function parsePositionBroadcast(buffer) {
        // 确保缓冲区位置在开始位置
        //buffer_seek(buffer, buffer_seek_start, 0);
        
        // 读取数据类型
        var dataType = buffer_read(buffer, buffer_u8);
        if (dataType != DATA_TYPE_POSITION_BROADCAST) return;
        
        // 读取玩家ID
        var numericId = buffer_read(buffer, buffer_u32);
        var playerId = "client_" + string(numericId);
        
        // 读取位置和角度
        var _x = buffer_read(buffer, buffer_f32);
        var _y = buffer_read(buffer, buffer_f32);
        var angle = buffer_read(buffer, buffer_f32);
        
        // 更新其他玩家位置
        updateOtherPlayerPositionBinary(playerId, _x, _y, angle);
    }
    
    // 新增：使用二进制数据更新其他玩家位置
    function updateOtherPlayerPositionBinary(playerId, x, y, angle) {
        // 如果这个玩家还没有实例，创建一个
        if (!ds_map_exists(otherPlayers, playerId)) {
            var playerInst = instance_create_layer(x, y, "Instances", obj_other_player);
            playerInst.playerId = playerId;
            ds_map_add(otherPlayers, playerId, playerInst);
        }
        
        // 更新位置
        var playerInst = ds_map_find_value(otherPlayers, playerId);
        if (instance_exists(playerInst)) {
            playerInst.target_x = x;
            playerInst.target_y = y;
            playerInst.target_angle = angle;
            
            // 可以选择直接设置或者使用插值
            // playerInst.x = x;
            // playerInst.y = y;
            // playerInst.image_angle = angle;
        }
    }
    
    // 处理收到的消息
    function handleServerMessage(messageObj) {
        switch (messageObj.type) {
            case "connection_established":
                connected = true;
                clientId = messageObj.clientId;
                gameState = GameState.IN_LOBBY;
                show_debug_message("已连接到服务器，客户端ID: " + clientId);
                
                global.selfSpr=choose(spr_boat1,spr_boat2,spr_boat3,spr_boat4,spr_boat5)
                // 自动加入游戏
                //joinGame();
                break;
                
            case "joined_room":
                roomId = messageObj.roomId;
                gameState = GameState.WAITING_FOR_PLAYERS;
                if audio_is_playing(snd_title) audio_stop_sound(snd_title) 
                    
                audio_play_sound(snd_wait, 0 ,1)
                show_debug_message("已加入房间: " + roomId + "，当前玩家数: " + string(messageObj.playerCount));
                MapID=messageObj.map
                switch messageObj.map
                    {
                        case 1:
                            //room_goto(Map1)
                            break;
                        case 2:
                            //room_goto(Map2)
                    }
                break;
                
            case "countdown_start":
                gameState = GameState.COUNTDOWN;
                countdownTime = messageObj.countdown;
                show_debug_message("倒计时开始: " + string(countdownTime) + "秒");
                countdownTimeAnim = countdownTime;
                break;
                
            case "countdown_update":
                gameState = GameState.COUNTDOWN;
                countdownTime = messageObj.countdown;
                break;
                
            case "countdown_cancelled":
                gameState = GameState.WAITING_FOR_PLAYERS;
                show_debug_message("倒计时取消，等待更多玩家");
                break;
                
            case "game_start":
                gameState = GameState.RACING;
                show_debug_message("比赛开始！");
                // 初始化比赛
                initializeRace();
                break;
                
            case "player_position":
                updateOtherPlayerPosition(messageObj);
                break;
                
            case "player_finished":
                if (messageObj.playerId == clientId) {
                    playerRank = messageObj.rank;
                    show_debug_message("你完成了比赛！排名: " + string(playerRank));
                } else {
                    show_debug_message("玩家 " + messageObj.playerId + " 完成了比赛，排名: " + string(messageObj.rank));
                }
                break;
                
            case "player_disconnected":
                if (ds_map_exists(otherPlayers, messageObj.playerId)) {
                    var playerInst = ds_map_find_value(otherPlayers, messageObj.playerId);
                    if (instance_exists(playerInst)) {
                        instance_destroy(playerInst);
                    }
                    ds_map_delete(otherPlayers, messageObj.playerId);
                }
                break;
                
            case "game_end":
                gameState = GameState.FINISHED;
                ds_list_clear(finishRankings);
                
                for (var i = 0; i < array_length(messageObj.rankings); i++) {
                    ds_list_add(finishRankings, messageObj.rankings[i]);
                }
                
                show_debug_message("比赛结束！");
                break;
                
            case "return_to_lobby":
                gameState = GameState.IN_LOBBY;
                roomId = "";
                clearRace();
                show_debug_message("返回大厅");
                break;
        }
    }
    
    // 初始化比赛
    function initializeRace() {
        // 清理之前的比赛
        clearRace();
        switch MapID
        {
            case 1:
                audio_stop_sound(snd_wait)
                audio_play_sound(snd_1, 0, 1)
                room_goto(Map1)
                break;
            case 2:
                audio_stop_sound(snd_wait)
                audio_play_sound(snd_2, 0, 1)
                room_goto(Map2)
                break;
            case 3:
                audio_stop_sound(snd_wait)
                audio_play_sound(snd_3, 0, 1)
                room_goto(Map3)
                break;
            case 4:
                audio_stop_sound(snd_wait)
                audio_play_sound(snd_rainbow, 0, 1)
                room_goto(Map4)
                break;
            case 5:
                audio_stop_sound(snd_wait)
                audio_play_sound(snd_4, 0, 1)
                room_goto(Map5)
                break;
            
        }
        // 重置玩家位置
        obj_player.x = global.RoomAttr.startX;
        obj_player.y = global.RoomAttr.startY;
        obj_player.image_angle = 0;
        
        // 重置状态
        raceFinished = false;
        playerRank = 0;
    }
    
    // 清理比赛
    function clearRace() {
        // 删除其他玩家实例
        var key = ds_map_find_first(otherPlayers);
        while (!is_undefined(key)) {
            var playerInst = ds_map_find_value(otherPlayers, key);
            if (instance_exists(playerInst)) {
                instance_destroy(playerInst);
            }
            key = ds_map_find_next(otherPlayers, key);
        }
        ds_map_clear(otherPlayers);
    }
    
    // 更新其他玩家位置
    function updateOtherPlayerPosition(data) {
        var playerId = data.id;
        
        // 如果这个玩家还没有实例，创建一个
        if (!ds_map_exists(otherPlayers, playerId)) {
            var playerInst = instance_create_layer(data.x, data.y, "Instances", obj_other_player);
            playerInst.playerId = playerId;
            ds_map_add(otherPlayers, playerId, playerInst);
        }
        
        // 更新位置
        var playerInst = ds_map_find_value(otherPlayers, playerId);
        if (instance_exists(playerInst)) {
            playerInst.x = data.x;
            playerInst.y = data.y;
            playerInst.image_angle = data.angle;
        }
    }
    
    // 创建事件
    connectToServer();
    game_set_speed(FREC, gamespeed_fps)
}
    
    