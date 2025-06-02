const net = require('net');

// 游戏配置
const GAME_CONFIG = {
  MIN_PLAYERS: 2,
  MAX_PLAYERS: 64,
  COUNTDOWN_TIME: 30, // 秒
  UPDATE_INTERVAL: 50, // 毫秒
};

// 游戏状态
const GAME_STATE = {
  WAITING: 'waiting',    // 等待玩家加入
  COUNTDOWN: 'countdown', // 倒计时中
  RUNNING: 'running',    // 比赛进行中
  FINISHED: 'finished'   // 比赛结束
};

const DATA_TYPES = {
  POSITION_UPDATE: 1, // 位置更新
  POSITION_BROADCAST: 2 // 位置广播
};

// 存储所有游戏房间
const gameRooms = new Map();
// 存储所有连接的客户端
const clients = new Map();
// 用于生成唯一ID
let nextClientId = 1;
let nextRoomId = 1;

// 创建一个新的游戏房间
function createGameRoom() {
  const roomId = `room_${nextRoomId++}`;
  const room = {
    id: roomId,
    players: new Map(),
    map: Math.floor(Math.random() * 5) + 1,
    state: GAME_STATE.WAITING,
    countdown: GAME_CONFIG.COUNTDOWN_TIME,
    countdownInterval: null,
    finishedPlayers: []
  };
  gameRooms.set(roomId, room);
  console.log(`创建新房间: ${roomId}`);
  return room;
}

// 查找可加入的房间或创建新房间
function findOrCreateRoom() {
  for (const [roomId, room] of gameRooms.entries()) {
    // 修改这里，允许在倒计时状态也可以加入房间
    if ((room.state === GAME_STATE.WAITING || room.state === GAME_STATE.COUNTDOWN) && 
        room.players.size < GAME_CONFIG.MAX_PLAYERS) {
      return room;
    }
  }
  return createGameRoom();
}

// 开始房间倒计时
function startRoomCountdown(room) {
  if (room.state !== GAME_STATE.WAITING) {
    console.log(`尝试为非等待状态的房间 ${room.id} 开始倒计时，当前状态: ${room.state}`);
    return;
  }
  
  console.log(`房间 ${room.id} 开始倒计时，初始时间: ${GAME_CONFIG.COUNTDOWN_TIME}秒`);
  
  room.state = GAME_STATE.COUNTDOWN;
  room.countdown = GAME_CONFIG.COUNTDOWN_TIME;
  
  broadcastToRoom(room, {
    type: 'countdown_start',
    countdown: room.countdown
  });
  
  room.countdownInterval = setInterval(() => {
    room.countdown--;
    
    console.log(`房间 ${room.id} 倒计时: ${room.countdown}秒`);
    
    broadcastToRoom(room, {
      type: 'countdown_update',
      countdown: room.countdown
    });
    
    if (room.countdown <= 0) {
      clearInterval(room.countdownInterval);
      startGame(room);
    }
  }, 1000);
}

// 开始游戏
function startGame(room) {
  room.state = GAME_STATE.RUNNING;
  
  broadcastToRoom(room, {
    type: 'game_start',
    players: Array.from(room.players.values()).map(player => ({
      id: player.id,
      name: player.name
    }))
  });
  
  console.log(`房间 ${room.id} 开始游戏，玩家数: ${room.players.size}`);
}

// 结束游戏
function endGame(room) {
  room.state = GAME_STATE.FINISHED;
  
  broadcastToRoom(room, {
    type: 'game_end',
    rankings: room.finishedPlayers.map((playerId, index) => {
      const player = room.players.get(playerId);
      return {
        id: playerId,
        name: player.name,
        rank: index + 1
      };
    })
  });
  
  console.log(`房间 ${room.id} 游戏结束`);
  
  // 清理房间
  setTimeout(() => {
    // 将玩家移出房间
    for (const [playerId, player] of room.players.entries()) {
      if (clients.has(playerId)) {
        const client = clients.get(playerId);
        client.roomId = null;
        // 通知客户端返回大厅
        sendToClient(client, {
          type: 'return_to_lobby'
        });
      }
    }
    
    // 删除房间
    gameRooms.delete(room.id);
    console.log(`房间 ${room.id} 已清理`);
  }, 5000);
}

// 向房间内所有玩家广播消息
function broadcastToRoom(room, message) {
  const messageStr = JSON.stringify(message);
  for (const [playerId, player] of room.players.entries()) {
    if (clients.has(playerId)) {
      const client = clients.get(playerId);
      client.socket.write(messageStr);
    }
  }
}

// 向指定客户端发送消息
function sendToClient(client, message) {
  client.socket.write(JSON.stringify(message));
}

// 处理玩家到达终点
function playerReachedFinish(room, playerId) {
  if (!room.finishedPlayers.includes(playerId)) {
    room.finishedPlayers.push(playerId);
    
    broadcastToRoom(room, {
      type: 'player_finished',
      playerId: playerId,
      rank: room.finishedPlayers.length
    });
    
    // 如果所有玩家都完成了，或者第一名已经产生
    if (room.finishedPlayers.length === room.players.size || room.finishedPlayers.length === 1) {
      endGame(room);
    }
  }
}

// 创建 TCP 服务器
const server = net.createServer((socket) => {
  const clientId = `client_${nextClientId++}`;
  console.log(`客户端已连接: ${socket.remoteAddress}:${socket.remotePort}, ID: ${clientId}`);
  
  // 创建客户端对象
  const client = {
    id: clientId,
    socket: socket,
    name: `Player${clientId}`,
    roomId: null,
    x: 0,
    y: 0,
    angle: 0,
    buffer: Buffer.alloc(0) // 用于存储不完整的二进制数据
  };
  
  // 添加到客户端列表
  clients.set(clientId, client);
  
  // 处理数据
  socket.on('data', (data) => {
    // 将新数据附加到客户端的缓冲区
    client.buffer = Buffer.concat([client.buffer, data]);
    
    // 处理缓冲区中的所有数据
    processBuffer(client);
  });
  
  // 客户端断开连接时
  socket.on('end', () => {
    handleClientDisconnect(client);
    console.log(`客户端断开连接: ${clientId}`);
  });
  
  // 发生错误时
  socket.on('error', (err) => {
    console.log(`连接错误 (${clientId}): ${err.message}`);
    handleClientDisconnect(client);
  });
  
  // 发送初始连接成功消息
  sendToClient(client, {
    type: 'connection_established',
    clientId: clientId
  });
});

// 处理客户端缓冲区数据
function processBuffer(client) {
  let bufferProcessed = false;
  
  // 如果有足够的数据来确定数据类型
  while (client.buffer.length > 0) {
    // 查看第一个字节来确定数据类型
    const dataType = client.buffer[0];
    
    // 处理二进制位置更新包
    if (dataType === DATA_TYPES.POSITION_UPDATE && client.buffer.length >= 17) {
      // 提取一个完整的位置更新包
      const packetBuffer = Buffer.alloc(17);
      client.buffer.copy(packetBuffer, 0, 0, 17);
      
      // 打印调试信息
      // console.log(`收到位置更新包: ${packetBuffer.toString('hex')}`);
      
      // 处理位置更新
      handleBinaryPositionUpdate(client, packetBuffer);
      
      // 从缓冲区中移除已处理的数据
      client.buffer = client.buffer.slice(17);
      bufferProcessed = true;
      continue;
    }
    
    // 尝试处理JSON数据
    if (client.buffer.length > 0) {
      // 检查是否有JSON开始标记
      const bufferStr = client.buffer.toString('utf8');
      const jsonStart = bufferStr.indexOf('{');
      
      if (jsonStart !== -1) {
        // 如果找到了JSON开始标记，但它不在开头，则移除开头的无效数据
        if (jsonStart > 0) {
          client.buffer = client.buffer.slice(jsonStart);
          bufferProcessed = true;
          continue;
        }
        
        // 尝试找到匹配的结束括号
        let bracketCount = 0;
        let jsonEnd = -1;
        
        for (let i = jsonStart; i < bufferStr.length; i++) {
          if (bufferStr[i] === '{') {
            bracketCount++;
          } else if (bufferStr[i] === '}') {
            bracketCount--;
            if (bracketCount === 0) {
              jsonEnd = i;
              break;
            }
          }
        }
        
        // 如果找到完整的JSON
        if (jsonEnd !== -1) {
          const jsonData = bufferStr.substring(jsonStart, jsonEnd + 1);
          try {
            const message = JSON.parse(jsonData);
            handleClientMessage(client, message);
          } catch (e) {
            console.log(`JSON解析错误: ${e.message}, JSON数据: ${jsonData}`);
          }
          
          // 移除已处理的JSON数据，保留剩余数据
          client.buffer = client.buffer.slice(jsonEnd + 1);
          bufferProcessed = true;
          continue;
        } else {
          // 没有找到完整的JSON，等待更多数据
          break;
        }
      } else {
        // 没有找到JSON开始标记，可能是无效数据
        // 尝试查找下一个可能的有效数据
        const nextValidDataIdx = bufferStr.indexOf('{');
        if (nextValidDataIdx === -1) {
          // 如果没有找到任何可能的JSON开始标记，检查是否可能是二进制数据包的开头
          if (client.buffer[0] !== DATA_TYPES.POSITION_UPDATE) {
            // 如果不是二进制位置更新包的开头，丢弃第一个字节
            client.buffer = client.buffer.slice(1);
            bufferProcessed = true;
            continue;
          } else {
            // 可能是不完整的二进制位置更新包，等待更多数据
            break;
          }
        } else {
          // 移动到下一个可能的JSON开始位置
          client.buffer = client.buffer.slice(nextValidDataIdx);
          bufferProcessed = true;
          continue;
        }
      }
    }
    
    // 如果缓冲区中没有足够的数据来处理任何消息类型，退出循环
    break;
  }
  
  return bufferProcessed;
}

// 向客户端发送消息，确保二进制消息和JSON消息不会混在一起
function sendToClient(client, message) {
  if (Buffer.isBuffer(message)) {
    // 直接发送二进制数据
    client.socket.write(message);
  } else {
    // 将JSON对象转换为字符串并发送
    // 添加分隔符以确保客户端能够识别完整的JSON
    const jsonStr = JSON.stringify(message) + "\n";
    client.socket.write(jsonStr);
  }
}

// 处理二进制位置更新
function handleBinaryPositionUpdate(client, buffer) {
  if (!client.roomId || !gameRooms.has(client.roomId)) return;
  
  const room = gameRooms.get(client.roomId);
  if (room.state !== GAME_STATE.RUNNING) return;
  
  try {
    // 解析二进制数据 - 格式: [类型(1字节), 玩家ID(4字节), x(4字节), y(4字节), angle(4字节)]
    const type = buffer.readUInt8(0);
    // 注意：我们不再使用客户端发送的playerId，而是使用当前连接的client.id
    // const playerId = buffer.readUInt32LE(1); // 这行被注释掉
    const x = buffer.readFloatLE(5);
    const y = buffer.readFloatLE(9);
    const angle = buffer.readFloatLE(13);
    
    // 验证数据类型
    if (type !== DATA_TYPES.POSITION_UPDATE) {
      console.log(`非位置更新数据类型: ${type}`);
      return;
    }
    
    // 更新玩家位置 - 使用当前客户端的ID
    const player = room.players.get(client.id);
    if (player) {
      player.x = x;
      player.y = y;
      player.angle = angle;
      
      // 使用二进制格式广播位置更新给房间内其他玩家
      broadcastBinaryPosition(room, client.id, x, y, angle);
    }
  } catch (e) {
    console.log(`解析二进制位置数据出错: ${e.message}, 缓冲区长度: ${buffer.length}`);
    // 打印缓冲区内容以便调试
    console.log(`缓冲区内容: ${buffer.toString('hex')}`);
  }
}

// 广播二进制位置更新到房间内其他玩家
function broadcastBinaryPosition(room, senderId, x, y, angle) {
  // 获取发送者ID的数字部分
  const senderIdParts = senderId.split('_');
  const numericId = parseInt(senderIdParts[1], 10) || 0;
  
  // 创建位置广播缓冲区 [类型(1字节), 玩家ID(4字节), x(4字节), y(4字节), angle(4字节)]
  const buffer = Buffer.alloc(17);
  
  // 写入数据
  buffer.writeUInt8(DATA_TYPES.POSITION_BROADCAST, 0);
  buffer.writeUInt32LE(numericId, 1);
  buffer.writeFloatLE(x, 5);
  buffer.writeFloatLE(y, 9);
  buffer.writeFloatLE(angle, 13);
  
  // 向房间内的每个其他玩家发送位置更新
  for (const [playerId, player] of room.players.entries()) {
    if (playerId !== senderId && clients.has(playerId)) {
      const client = clients.get(playerId);
      client.socket.write(buffer);
    }
  }
}


// 处理客户端消息
function handleClientMessage(client, message) {
  switch (message.type) {
    case 'join_game':
      handleJoinGame(client, message);
      break;
    
    case 'position_update':
      handlePositionUpdate(client, message);
      break;
      
    case 'finish_reached':
      handleFinishReached(client);
      break;
      
    default:
      console.log(`未知消息类型: ${message.type}`);
  }
}

// 向房间内所有玩家广播消息
function broadcastToRoom(room, message) {
  for (const [playerId, player] of room.players.entries()) {
    if (clients.has(playerId)) {
      const client = clients.get(playerId);
      sendToClient(client, message);
    }
  }
}

// 处理加入游戏请求
function handleJoinGame(client, message) {
  // 如果客户端已在房间中，先离开
  if (client.roomId && gameRooms.has(client.roomId)) {
    const oldRoom = gameRooms.get(client.roomId);
    oldRoom.players.delete(client.id);
  }
  
  // 设置玩家名称
  if (message.name) {
    client.name = message.name;
  }
  
  // 查找或创建房间
  const room = findOrCreateRoom();
  
  // 将玩家加入房间
  room.players.set(client.id, {
    id: client.id,
    name: client.name,
    x: 0,
    y: 0,
    angle: 0
  });
  
  client.roomId = room.id;
  
  // 通知客户端已加入房间
  sendToClient(client, {
    type: 'joined_room',
    roomId: room.id,
    map:room.map,
    playerCount: room.players.size,
    // 添加房间状态和倒计时信息
    roomState: room.state,
    countdown: room.state === GAME_STATE.COUNTDOWN ? room.countdown : null
  });
  
  console.log(`玩家 ${client.id} (${client.name}) 加入房间 ${room.id}, 当前人数: ${room.players.size}`);
  
  // 如果房间处于倒计时状态，通知新玩家当前倒计时状态
  if (room.state === GAME_STATE.COUNTDOWN) {
    sendToClient(client, {
      type: 'countdown_update',
      countdown: room.countdown
    });
    
    // 通知其他玩家有新玩家加入
    for (const [otherId, otherPlayer] of room.players.entries()) {
      if (otherId !== client.id && clients.has(otherId)) {
        const otherClient = clients.get(otherId);
        sendToClient(otherClient, {
          type: 'player_joined',
          id: client.id,
          name: client.name
        });
      }
    }
  }
  // 如果达到最小人数要求且房间处于等待状态，开始倒计时
  else if (room.players.size >= GAME_CONFIG.MIN_PLAYERS && room.state === GAME_STATE.WAITING) {
    startRoomCountdown(room);
  }
}

// 处理位置更新 (JSON格式 - 兼容旧版本)
function handlePositionUpdate(client, message) {
  if (!client.roomId || !gameRooms.has(client.roomId)) return;
  
  const room = gameRooms.get(client.roomId);
  if (room.state !== GAME_STATE.RUNNING) return;
  
  // 更新玩家位置
  const player = room.players.get(client.id);
  if (player) {
    player.x = message.x;
    player.y = message.y;
    player.angle = message.angle;
    
    // 广播位置更新给房间内其他玩家
    for (const [otherId, otherPlayer] of room.players.entries()) {
      if (otherId !== client.id && clients.has(otherId)) {
        const otherClient = clients.get(otherId);
        // 尝试使用二进制方式发送
        try {
          // 创建位置广播缓冲区
          const buffer = Buffer.alloc(17);
          
          // 获取发送者ID的数字部分
          const numericId = parseInt(client.id.split('_')[1], 10) || 0;
          
          // 写入数据
          buffer.writeUInt8(DATA_TYPES.POSITION_BROADCAST, 0);
          buffer.writeUInt32LE(numericId, 1);
          buffer.writeFloatLE(player.x, 5);
          buffer.writeFloatLE(player.y, 9);
          buffer.writeFloatLE(player.angle, 13);
          
          // 发送二进制数据
          otherClient.socket.write(buffer);
        } catch (e) {
          // 如果二进制发送失败，回退到JSON格式
          console.log(`二进制发送失败，使用JSON格式: ${e.message}`);
          sendToClient(otherClient, {
            type: 'player_position',
            id: client.id,
            x: player.x,
            y: player.y,
            angle: player.angle
          });
        }
      }
    }
  }
}

// 处理玩家到达终点
function handleFinishReached(client) {
  if (!client.roomId || !gameRooms.has(client.roomId)) return;
  
  const room = gameRooms.get(client.roomId);
  if (room.state !== GAME_STATE.RUNNING) return;
  
  playerReachedFinish(room, client.id);
}

// 处理客户端断开连接
function handleClientDisconnect(client) {
  // 如果客户端在房间中，将其移除
  if (client.roomId && gameRooms.has(client.roomId)) {
    const room = gameRooms.get(client.roomId);
    room.players.delete(client.id);
    
    // 通知房间内其他玩家
    broadcastToRoom(room, {
      type: 'player_disconnected',
      playerId: client.id
    });
    
    console.log(`玩家 ${client.id} 离开房间 ${room.id}, 剩余人数: ${room.players.size}`);
    
    // 如果房间内玩家数量不足最小要求，且正在倒计时，取消倒计时
    if (room.players.size < GAME_CONFIG.MIN_PLAYERS && room.state === GAME_STATE.COUNTDOWN) {
      clearInterval(room.countdownInterval);
      room.state = GAME_STATE.WAITING;
      
      broadcastToRoom(room, {
        type: 'countdown_cancelled'
      });
      
      console.log(`房间 ${room.id} 倒计时取消，玩家数不足`);
    }
    
    // 如果房间没有玩家了，删除房间
    if (room.players.size === 0) {
      gameRooms.delete(room.id);
      console.log(`房间 ${room.id} 已删除（无玩家）`);
    }
  }
  
  // 从客户端列表中移除
  clients.delete(client.id);
}

// 监听指定端口
const PORT = 8080; // 与客户端匹配
const HOST = '0.0.0.0';

server.listen(PORT, HOST, () => {
  console.log(`服务器正在监听 ${HOST}:${PORT}`);
});
