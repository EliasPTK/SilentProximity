shader_type canvas_item;
render_mode unshaded;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture;

uniform vec4 Black : source_color = vec4(0,0,0,1);
uniform vec4 level2 : source_color = vec4(0.5,0.5,0.5,1);
uniform vec4 level3 : source_color = vec4(1,1,1,1);
uniform vec4 White : source_color = vec4(1,1,1,1);


uniform vec4[23] colors: source_color;

uniform float threshold1 	: hint_range(0.0,1.0) = .1;
uniform float threshold2 	: hint_range(0.0,1.0) = .4;
uniform float threshold3	: hint_range(0.0,1.0) = .6;

uniform float pixelate: hint_range(2, 1048, 4) = 256;
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
	float rgb_avg = (COLOR.r + COLOR.g + COLOR.b)/3.0;
	//''' GrayScale World'''
	//if(rgb_avg < threshold1){
	//	ALBEDO = Black.rgb;
	//}else if(rgb_avg < threshold2){
		//ALBEDO = level2.rgb;
	//}else if(rgb_avg < threshold3){
	//	ALBEDO = level3.rgb;
	//}else{
	//	ALBEDO = White.rgb;
	//}
	
	//''' Hey This is a Different Section, This has Color '''
	float most_dist = -1.0;
	int chosen_color = 0;
	for(int i = 0; i < 23; i++){
		
		float testdist = 0.0;
		distcalc(COLOR, colors[i], testdist);
		
		if(most_dist == -1.0 || testdist < most_dist){
			chosen_color = i;
			most_dist = testdist;
			
		}
		
	}
	
	COLOR.rgb = colors[chosen_color].xyz;
	
	COLOR.a = 1.0;
	
}