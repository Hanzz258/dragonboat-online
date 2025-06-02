if room!=room_lobby
{
    // 步事件
    if sprite_index=spr_player&&global.selfSpr>0 sprite_index=global.selfSpr
        
    
    // 获取输入
    var turn_input = keyboard_check(ord("A")) - keyboard_check(ord("D"));
    var forward_input = keyboard_check(ord("W"));
    var backward_input = keyboard_check(ord("S"));
    
    // 处理转向动量 - 使转向更真实
    turning_momentum = turning_momentum * turning_momentum_decay + turn_input * turn_rate;
    direction += turning_momentum;
    if instance_place(x, y, obj_obstacle)
    {
        direction -= turning_momentum*1.5;
        if instance_place(x, y, obj_obstacle)
        {
            direction -= 5;
            if instance_place(x, y, obj_obstacle)
            {
                direction += 10;
            }
        }
    }
    image_angle = direction - 90;  // 调整图像角度使船头朝向移动方向
    
    // 计算加速力
    var paddle_power = 0;
    if (forward_input) {
        paddle_power = paddle_force;
    } else if (backward_input) {
        paddle_power = -paddle_force * 0.6;  // 后退力量较小
    }
    
    // 计算水的阻力 (基于流体动力学)
    // 阻力 = 0.5 * 阻力系数 * 水密度 * 速度^2 * 船体面积
    var effective_area = 1 + abs(turning_momentum) * 0.5;  // 转向时增加有效面积
    var water_drag = 0.5 * drag_coefficient * water_density * (boat_speed * boat_speed) * effective_area;
    water_drag = water_drag / mass;  // 应用质量影响
    
    // 应用牛顿第二定律 (F = ma)
    var net_acceleration = paddle_power / mass - water_drag;
    boat_speed += net_acceleration;
    
    // 限制最大速度并防止负速度过大
    boat_speed = clamp(boat_speed, -max_speed * 0.4, max_speed);
    
    // 应用侧向漂移 (当转向时)
    var drift_x = 0;
    var drift_y = 0;
    if (abs(turning_momentum) > 0.1) {
        // 计算垂直于前进方向的漂移向量
        var drift_angle = direction + 90;
        drift_x = lengthdir_x(abs(turning_momentum) * drift_factor * boat_speed, drift_angle);
        drift_y = lengthdir_y(abs(turning_momentum) * drift_factor * boat_speed, drift_angle);
    }

    // 计算实际移动
    var move_x = lengthdir_x(boat_speed, direction) + drift_x;
    var move_y = lengthdir_y(boat_speed, direction) + drift_y;
    
    // 添加碰撞检测和响应
    var original_x = x;
    var original_y = y;
    
    // 保存原始移动向量
    var original_move_x = move_x;
    var original_move_y = move_y;
    
    // 临时移动来检测碰撞
    x += move_x;
    y += move_y;
    
// 检测是否与障碍物碰撞
var collision = instance_place(x, y, obj_obstacle);
var collision1 = instance_place(x, y, obj_zongzi);
if (collision1 != noone)
{
	instance_destroy(collision1)
	max_speed*=1.5
	boat_speed*=1.5
	alarm_set(1,FREC)
}
if (collision != noone)
{
    move_x=0
    move_y=0
    x=original_x
    y=original_y
}


    
    
    
    // 视角
    // 使用lerp平滑过渡到目标位置和缩放
    targetCamX=x
    targetCamY=y
    targetCamScal=global.scal*1.5-log10(1+abs(boat_speed)/3)
        
    currentCamX = lerp(currentCamX, targetCamX, camLerpSpeed);
    currentCamY = lerp(currentCamY, targetCamY, camLerpSpeed);
    currentCamScale = lerp(currentCamScale, targetCamScal, camScaleLerpSpeed);
    
    // 计算缩放后的视图大小
    var viewWidth = camWidth / currentCamScale;
    var viewHeight = camHeight / currentCamScale;
    
    // 更新摄像机视图
    camera_set_view_size(view_camera[0], viewWidth, viewHeight);
    
    // 计算摄像机位置，使目标保持在中心
    var camX = currentCamX - (viewWidth / 2);
    var camY = currentCamY - (viewHeight / 2);
    
    camX=clamp(camX,0,room_width-viewWidth)
    camY=clamp(camY,0,room_height-viewHeight)
    camera_set_view_pos(view_camera[0], camX, camY);
}

if texiao switch room
{
    case Map1:
    {
        if point_in_circle(x,y,9257,7506,300)
        {
            main.notifyFinishReached()
            spawn_celebration(x,y,30)
            alarm_set(0,3*FREC)
            audio_stop_all()
            audio_play_sound(snd_cheer,0,0)
			texiao=0
        }
        break;
    }
    case Map2:
    {
        if point_in_circle(x,y,1022,485,300)
        {
            main.notifyFinishReached()
            spawn_celebration(x,y,30)
            alarm_set(0,3*FREC)
            audio_stop_all()
            audio_play_sound(snd_cheer,0,0)
			texiao=0
        }
        break;
    }
    case Map3:
    {
        if point_in_circle(x,y,4202,728,300)
        {
            main.notifyFinishReached()
            spawn_celebration(x,y,30)
            alarm_set(0,3*FREC)
            audio_stop_all()
            audio_play_sound(snd_cheer,0,0)
			texiao=0
        }
        break;
    }
    case Map4:
    {
        if point_in_circle(x,y,6960,982,300)
        {
            main.notifyFinishReached()
            spawn_celebration(x,y,30)
            alarm_set(0,3*FREC)
            audio_stop_all()
            audio_play_sound(snd_cheer,0,0)
			texiao=0
        }
        break;
    }
    case Map5:
    {
        if point_in_circle(x,y,568,847,300)
        {
            main.notifyFinishReached()
            spawn_celebration(x,y,30)
            alarm_set(0,3*FREC)
            audio_stop_all()
            audio_play_sound(snd_cheer,0,0)
			texiao=0
        }
        break;
    }
	
}
