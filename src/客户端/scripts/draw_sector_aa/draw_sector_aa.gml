/// @function draw_sector_aa(x, y, radius, start_angle, end_angle, color, edge_smoothness, angle_smoothness)
/// @description 绘制抗锯齿扇形（从正y轴开始的角度系统）
/// @param {real} x 扇形中心点的X坐标
/// @param {real} y 扇形中心点的Y坐标
/// @param {real} radius 扇形半径
/// @param {real} start_angle 起始角度（度数，0=上，90=右，180=下，270=左）
/// @param {real} end_angle 结束角度（度数，同上）
/// @param {color} color 扇形颜色
/// @param {real} edge_smoothness 边缘平滑度（像素单位，默认为2.0）
/// @param {real} angle_smoothness 角度平滑度（度数，默认为1.0）
function draw_sector_aa(x, y, radius, start_angle, end_angle, color, edge_smoothness = 2.0, angle_smoothness = 1.0) {
    // 转换角度为弧度
    var start_rad = degtorad(start_angle);
    var end_rad = degtorad(end_angle);
    var angle_smoothness_rad = degtorad(angle_smoothness);
    
    // 确保结束角度大于起始角度
    if (end_rad < start_rad) {
        end_rad += 2 * pi;
    }
    
    // 创建一个足够大的矩形来包含整个扇形
    var size = radius * 2;
    var x1 = x - radius;
    var y1 = y - radius;
    var x2 = x + radius;
    var y2 = y + radius;
    
    // 启用着色器
    shader_set(shd_smooth_sector);
    
    // 设置着色器的uniform变量
    shader_set_uniform_f(shader_get_uniform(shd_smooth_sector, "u_center"), x, y);
    shader_set_uniform_f(shader_get_uniform(shd_smooth_sector, "u_radius"), radius);
    shader_set_uniform_f(shader_get_uniform(shd_smooth_sector, "u_startAngle"), start_rad);
    shader_set_uniform_f(shader_get_uniform(shd_smooth_sector, "u_endAngle"), end_rad);
    shader_set_uniform_f(shader_get_uniform(shd_smooth_sector, "u_smoothness"), edge_smoothness);
    shader_set_uniform_f(shader_get_uniform(shd_smooth_sector, "u_angleSmoothness"), angle_smoothness_rad);
    
    // 绘制矩形
    draw_rectangle_color(x1, y1, x2, y2, color, color, color, color, false);
    
    // 禁用着色器
    shader_reset();
}
