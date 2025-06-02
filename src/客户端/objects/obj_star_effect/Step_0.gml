lifetime -= delta_time / 1000000;

if (scale < max_scale) {
    scale += 0.05;
}

image_angle += rotation_speed;

if (lifetime < fade_start) {
    alpha = lifetime / fade_start;
}

image_alpha = alpha;
image_xscale = scale;
image_yscale = scale;

if (lifetime <= 0) {
    instance_destroy();
}