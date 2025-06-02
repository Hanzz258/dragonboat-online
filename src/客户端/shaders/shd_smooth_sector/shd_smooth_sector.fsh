// 片段着色器
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
varying vec2 v_vPosition;

uniform vec2 u_center;     // 扇形中心点
uniform float u_radius;    // 扇形半径
uniform float u_startAngle; // 起始角度（弧度）
uniform float u_endAngle;   // 结束角度（弧度）
uniform float u_smoothness; // 边缘平滑度（像素单位）
uniform float u_angleSmoothness; // 角度平滑度（弧度）

void main()
{
    // 计算当前片段到中心点的距离
    vec2 toCenter = v_vPosition - u_center;
    float dist = length(toCenter);
    
    // 计算当前片段的角度 - 从正y轴开始计算（而不是从正x轴）
    // 使用atan2等价函数，从正y轴开始，顺时针方向
    float angle = atan(toCenter.x, -toCenter.y);  // 注意这里x和y的顺序以及负号
    
    // 将角度转换为[0, 2π]范围
    if (angle < 0.0) angle += 6.28318530718; // 2π
    
    // 检查角度是否在扇形范围内
    float startAngle = u_startAngle;
    float endAngle = u_endAngle;
    if (endAngle < startAngle) endAngle += 6.28318530718; // 确保结束角度大于起始角度
    
    bool inAngleRange = false;
    if (angle >= startAngle && angle <= endAngle) {
        inAngleRange = true;
    } else if (angle + 6.28318530718 >= startAngle && angle + 6.28318530718 <= endAngle) {
        inAngleRange = true;
    }
    
    // 计算距离的平滑过渡
    float distAlpha = 1.0 - smoothstep(u_radius - u_smoothness, u_radius, dist);
    
    // 计算角度的平滑过渡
    float angleAlpha = 1.0;
    if (!inAngleRange) {
        angleAlpha = 0.0;
    } else {
        // 在边缘附近平滑过渡
        float angleDiffStart = abs(angle - startAngle);
        if (angleDiffStart > 3.14159265359) angleDiffStart = 6.28318530718 - angleDiffStart;
        
        float angleDiffEnd = abs(angle - endAngle);
        if (angleDiffEnd > 3.14159265359) angleDiffEnd = 6.28318530718 - angleDiffEnd;
        
        if (angleDiffStart < u_angleSmoothness) {
            angleAlpha = min(angleAlpha, angleDiffStart / u_angleSmoothness);
        }
        if (angleDiffEnd < u_angleSmoothness) {
            angleAlpha = min(angleAlpha, angleDiffEnd / u_angleSmoothness);
        }
    }
    
    // 合并距离和角度的alpha值
    float alpha = distAlpha * angleAlpha;
    
    // 输出最终颜色
    gl_FragColor = v_vColour;
    gl_FragColor.a *= alpha;
}
