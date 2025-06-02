if room==room_lobby
{
    // 绘制背景
    var BackGroundSpr=bg_lobby
    if MapID>=0&&!statusBgChange
    {
        BackGroundSpr=bg_map1
        switch MapID
        {
            case 1:
                BackGroundSpr=bg_map1
                break;
            
			case 2:
				BackGroundSpr=bg_map2
				break;
				
			case 3:
				BackGroundSpr=bg_map3
				break;
			
            case 4:
                BackGroundSpr=bg_map4
                break;
				
			case 5:
				BackGroundSpr=bg_map5
                break;
        }
    }
    var bgWidth=sprite_get_width(BackGroundSpr)
    var bgHeight=sprite_get_height(BackGroundSpr)
    var bgScal=max(window_get_width()/bgWidth,window_get_height()/bgHeight)
    draw_sprite_ext(BackGroundSpr, 0, window_get_width()/2, window_get_height()/2, bgScal, bgScal, 0, c_white, 1)
	if BackGroundSpr=bg_lobby
	{
		draw_sprite_ext(bg_lobby_3, 0, window_get_width()/2+global.scal*200*(window_mouse_get_x()-window_get_width()/2)/window_get_width(), window_get_height()/2+global.scal*200*(window_mouse_get_y()-window_get_height()/2)/window_get_height(), bgScal*1.1, bgScal*1.1, 0, c_white, 1)
		draw_sprite_ext(bg_lobby_2, 0, window_get_width()/2+global.scal*100*(window_mouse_get_x()-window_get_width()/2)/window_get_width(), window_get_height()/2+global.scal*100*(window_mouse_get_y()-window_get_height()/2)/window_get_height(), bgScal*1.1, bgScal*1.1, 0, c_white, 1)
	}
    
    if gameState==GameState.CONNECTING
    {
        draw_set_font(global.font_icon)
        draw_set_halign(1)
        draw_set_valign(1)
        draw_text(window_get_width()/2,window_get_height()/2,"y")
    }
    else if connected
    {
        if gameState==GameState.IN_LOBBY animAlpha1=lerp(animAlpha1,0,5/FREC)
            if animAlpha1>0.98 statusBgChange=0
        if statusBgChange 
        {
            if gameState==GameState.WAITING_FOR_PLAYERS||gameState==GameState.COUNTDOWN animAlpha1=lerp(animAlpha1,1,5/FREC)    
        }
        else 
        {
        	animAlpha1=lerp(animAlpha1,0,5/FREC)  
        }
        draw_set_alpha(animAlpha1)
        draw_set_color(c_black)
        draw_rectangle(0,0,window_get_width(),window_get_height(),0)
        draw_set_alpha(1)
        draw_set_font(global.font_icon)
        draw_set_halign(1)
        draw_set_valign(1)
        draw_set_color(c_white)
        draw_text_transformed(global.scal*100,global.scal*80,"z", global.scal,global.scal,0)
        if point_in_circle(mouse_x,mouse_y,window_get_width()/2,window_get_height()/2,global.scal*btnPlayScal*140) 
        {
            btnPlayScal=lerp(btnPlayScal,1.5,3/FREC) 
            if mouse_check_button_pressed(mb_left)&&gameState==GameState.IN_LOBBY
            {
                joinGame()
            }
        }
        else btnPlayScal=lerp(btnPlayScal,1,3/FREC) 
            
        draw_set_alpha(1-animAlpha1)
        if statusBgChange draw_text_transformed(window_get_width()/2,window_get_height()/2,"p", global.scal*2*btnPlayScal,global.scal*2*btnPlayScal,0) 
        draw_set_alpha(1)
    }
}

draw_set_color(c_white);

switch (gameState) {
    case GameState.DISCONNECTED:

        break;
        
    case GameState.CONNECTING:

        break;
        
    case GameState.IN_LOBBY:

        break;
        
    case GameState.WAITING_FOR_PLAYERS:
        if !statusBgChange
        {
            draw_set_font(global.font_icon)
            draw_set_color(c_white)
            draw_set_halign(1)
            draw_set_valign(1)
            draw_text_transformed(window_get_width()/2-global.scal*100,window_get_height()/2,"r",global.scal,global.scal,0)
            draw_text_transformed(window_get_width()/2+global.scal*50,window_get_height()/2+global.scal*75,"w",global.scal*.35,global.scal*.35,-current_time/10)
            //draw_text_transformed(window_get_width()/2,window_get_height()/2,"r",global.scal,global.scal,0)
            //draw_text_transformed(window_get_width()/2,window_get_height()/2,"w",global.scal*2.75,global.scal*2.75,-current_time/10)
        }

        break;
        
    case GameState.COUNTDOWN:
        countdownTimeAnim=lerp(countdownTimeAnim,countdownTime,LERP_RATE)
        draw_sector_aa(room_width / 2, room_height / 2, 100, 0, 360*countdownTimeAnim/30, c_white);
        //draw_text(20, 20, "比赛即将开始: " + string(countdownTime) + "秒");
        break;
        
    case GameState.RACING:
        if (raceFinished) {
            //draw_text(20, 20, "你已完成比赛！排名: " + string(playerRank));
        } else {
            //draw_text(20, 20, "比赛进行中");
        }
        break;
        
    case GameState.FINISHED:
       // draw_text(20, 20, "比赛结束");
        
        // 显示排名
        for (var i = 0; i < ds_list_size(finishRankings); i++) {
            var ranking = finishRankings[| i];
            var rankText = string(ranking.rank) + ". " + ranking.name;
            
            // 如果是当前玩家，高亮显示
            if (ranking.id == clientId) {
                draw_set_color(c_yellow);
            } else {
                draw_set_color(c_white);
            }
            
            //draw_text(20, 60 + i * 30, rankText);
        }
        
        draw_set_color(c_white);
        //draw_text(20, 50, "按空格返回大厅");
        break;
}