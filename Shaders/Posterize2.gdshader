shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform sampler2D grad;
uniform vec4 Black : source_color = vec4(0,0,0,1);
uniform vec4 level2 : source_color = vec4(0.5,0.5,0.5,1);
uniform vec4 level3 : source_color = vec4(1,1,1,1);
uniform vec4 White : source_color = vec4(1,1,1,1);


uniform vec4[23] colors: source_color;

uniform float threshold1 	: hint_range(-2.0,1.0) = .1;
uniform float threshold2 	: hint_range(0.0,1.0) = .4;
uniform float threshold3	: hint_range(0.0,1.0) = .6;


uniform float pixelate: hint_range(2, 2096, 4) = 256;
void distcalc(vec4 firstcolor, vec4 secondcolor, out float thisdist){
	
	float xdist = (firstcolor.x - secondcolor.x);
	xdist = xdist * xdist;
	
	float ydist = (firstcolor.y - secondcolor.y);
	ydist = ydist * ydist;
	
	float zdist = (firstcolor.z - secondcolor.z);
	zdist = zdist * zdist;
	
	float dist = sqrt(zdist + ydist + xdist);
	
	thisdist = dist;
}

void fragment(){
	vec2 uv = floor(UV * pixelate) / pixelate;
	COLOR.rgb = texture(SCREEN_TEXTURE, floor(SCREEN_UV * pixelate) / pixelate).rgb;
	
	//COLOR.r += COLOR.r * 2.0;
	//COLOR.r -= (COLOR.g * COLOR.b) * 3.0;
	//COLOR.gb = vec2(0,0);
	//COLOR.a  = 1.0- (COLOR.g + COLOR.b);
	
	//float impact = round((COLOR.r + threshold1) * 32.0)/32.0;
	//float impact = round((COLOR.r + threshold1) * 16.0)/16.0;
	//vec3 gradtext = texture(grad,vec2(impact,impact) ).rgb;
	//COLOR.rgb =round(COLOR.rgb * 16.0)/16.0;
	//COLOR.rgb = pow(COLOR.rgb, vec3(3,3,3)) * 4.5;
	//COLOR.rgb = vec3(COLOR.r,COLOR.r,COLOR.r);
	
	
	//Color Mode:
	//float impact = round((COLOR.r + threshold1) * 16.0)/16.0;
	//COLOR.rgb =round(COLOR.rgb * 16.0)/16.0;
	//COLOR.rgb = pow(COLOR.rgb, vec3(3,3,3)) * 4.5;
	
	//Grayscale Mode:
	
	COLOR.rgb =round(COLOR.rgb * 24.0)/24.0;
	COLOR.rgb = pow(COLOR.rgb, vec3(3,3,3)) * 4.0;
	COLOR.rgb = vec3(COLOR.r,COLOR.r,COLOR.r);
}