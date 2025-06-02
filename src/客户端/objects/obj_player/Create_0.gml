image_xscale=.5
image_yscale=.5
direction = 90;  // 初始方向（向右）
boat_speed = 0;  // 当前速度
max_speed = 8*RATE;   // 最大速度
turn_rate = .3*RATE;   // 转向速率
acceleration = .1*RATE;  // 加速率
water_resistance = 0.01*RATE;  // 水的阻力系数
turning_speed_penalty = 0.98;  // 转向时的速度惩罚系数
texiao=1

// 物理属性
mass = 100;  // 龙舟质量
momentum = 0;  // 动量
water_density = 1.0;  // 水密度
drag_coefficient = 0.7;  // 阻力系数
paddle_force = 4.5*RATE;  // 划桨力量
turning_momentum = 0;  // 转向动量
turning_momentum_decay = 0.92;  // 转向动量衰减
drift_factor = 0.2;  // 侧向漂移系数
wake_timer = 0;  // 水波生成计时器
mass = 100;  // 龙舟质量
momentum = 0;  // 动量
water_density = 1.0;  // 水密度
drag_coefficient = 0.7;  // 阻力系数
width=128
length=384

// 视角，默认视角的中心为XY
targetCamX=x
targetCamY=y
targetCamScal=1

// 当前摄像机实际位置和缩放
currentCamX = x;
currentCamY = y;
currentCamScale = 1;

// 摄像机平滑移动和缩放的速度（0-1之间，越小越平滑）
camLerpSpeed = 5/FREC;
camScaleLerpSpeed = 4/FREC;

// 摄像机视图大小
camWidth = window_get_width();
camHeight = window_get_height();
