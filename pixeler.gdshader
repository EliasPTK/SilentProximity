shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_disabled;

uniform float texture_scale : hint_range(0.01, 10.0, 0.01) = 1.0;
uniform float pixel_size : hint_range(0.001, 1.0, 0.001) = 0.05;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;
uniform float dither_scale : hint_range(1.0, 16.0, 1.0) = 1.0;
uniform vec4 dither_light : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 dither_dark : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float light_steps : hint_range(1.0, 16.0, 1.0) = 4.0;
uniform sampler2D albedo_texture : source_color, hint_default_white;
uniform vec4 albedo_tint : source_color = vec4(1.0);
uniform float light_pixel_size : hint_range(1.0, 32.0, 1.0) = 4.0;
varying vec3 world_pos;
varying vec3 world_normal;

float hash(vec3 p) {
    p = fract(p * vec3(443.897, 441.423, 437.195));
    p += dot(p, p.yzx + 19.19);
    return fract((p.x + p.y) * p.z);
}

float bayer4(vec2 pos) {
    int x = int(mod(pos.x, 4.0));
    int y = int(mod(pos.y, 4.0));
    int matrix[16] = int[16](
         0,  8,  2, 10,
        12,  4, 14,  6,
         3, 11,  1,  9,
        15,  7, 13,  5
    );
    return float(matrix[y * 4 + x]) / 16.0;
}

// Snap a value to N discrete steps
float posterize(float value, float steps) {
    return floor(value * steps + 0.5) / steps;
}

void vertex() {
    world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
    world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    vec3 snapped = floor(world_pos / pixel_size + 0.5) * pixel_size;

    vec4 x_tex = texture(albedo_texture, snapped.yz * texture_scale);
    vec4 y_tex = texture(albedo_texture, snapped.xz * texture_scale);
    vec4 z_tex = texture(albedo_texture, snapped.xy * texture_scale);

    vec3 blend = pow(abs(world_normal), vec3(4.0));
    blend /= (blend.x + blend.y + blend.z);

    vec4 tex_color = (x_tex * blend.x + y_tex * blend.y + z_tex * blend.z) * albedo_tint;

    vec2 dither_coord = floor(FRAGCOORD.xy / dither_scale);
    float threshold = bayer4(dither_coord);

    float lum = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
    float dithered_lum = step(threshold, lum + (1.0 - dither_strength) * 0.5);

    vec3 dither_color = mix(dither_dark.rgb, dither_light.rgb, dithered_lum);
    vec3 final_color = mix(tex_color.rgb, dither_color, dither_strength);

	float noise = hash(snapped);

// Add random offset to albedo — tune the multiplier for subtlety
	vec3 noisy_color = final_color + (noise - 0.25) * 0.15;

	ALBEDO = clamp(noisy_color, 0.0, 1.0);
    //ALBEDO = final_color;
}

void light() {
    // Calculate ndotl normally — no vector snapping
    float ndotl = max(dot(NORMAL, LIGHT), 0.0);

    // Snap world position to the same grid as the texture
    vec3 snapped = floor(world_pos / pixel_size + 0.5) * pixel_size;

    // Use the snapped position as a seed to get one stable ndotl per world cell
    // We do this by computing a per-cell average using the hash
    float cell_seed = hash(snapped);

    // Posterize ndotl then offset slightly per cell so each pixel cell
    // has a unique but stable light value locked to the world grid
    float stepped_light = floor(ndotl * light_steps) / light_steps;

    // Lock light value to cell — each cell in the world grid gets
    // exactly one light value that doesn't change with camera
    float cell_light = floor((ndotl + (cell_seed - 0.5) * (1.0 / light_steps)) * light_steps) / light_steps;
    cell_light = clamp(cell_light, 0.0, 1.0);

    // Dither edges between cells
    vec2 dither_coord = floor(FRAGCOORD.xy / dither_scale);
    float threshold = bayer4(dither_coord);

    float dithered_light = cell_light + (threshold - 0.5) * (1.0 / light_steps) * dither_strength;
    dithered_light = clamp(dithered_light, 0.0, 1.0);

    DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION * dithered_light;
}