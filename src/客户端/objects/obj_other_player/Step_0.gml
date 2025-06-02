x = lerp(x, target_x, LERP_RATE);
y = lerp(y, target_y, LERP_RATE);
var diff = target_angle - buf_angle;

// 如果差值大于 180°，说明顺时针跨越零点更近，把目标角度减 360°
if (diff > 180) target_angle -= 360;

// 如果差值小于-180°，说明逆时针跨越零点更近，把目标角度加 360°
if (diff < -180) target_angle += 360;

// 现在两角度一定相差不超过 180°，再去 lerp 就不会绕圈
buf_angle = lerp(buf_angle, target_angle+90, LERP_RATE);
image_angle=buf_angle-90
if abs(target_angle-image_angle)>180 image_angle=target_angle
