// Create spawn script
/// @function spawn_celebration(x, y, count)
/// @param {real} x X position to spawn stars
/// @param {real} y Y position to spawn stars
/// @param {real} count Number of stars to create
function spawn_celebration(x_pos1, y_pos1, count) {
    for (var i = 0; i < count; i++) {
        var star = instance_create_depth(
            x_pos1 + random_range(-2000, 2000),
            y_pos1 + random_range(-2000, 2000),
            -999,
            obj_star_effect
        );
    }
}