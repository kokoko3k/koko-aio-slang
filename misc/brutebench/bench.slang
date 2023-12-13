#version 450

// Released under: See LICENSE.txt

layout(push_constant) uniform Push {
	mat4 MVP;
	vec4 SourceSize;
} params;

layout(std140, set = 0, binding = 0) uniform UBO {
	mat4 MVP;
} global;

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;

void main() {
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#define RECT vec4(0.05,0.05,0.95,0.95)

vec4 sub_bench1(vec2 point) {
	if (point.x > RECT.x &&
		point.x < RECT.z &&
		point.y < RECT.w &&
		point.y > RECT.y)
	return vec4(0.1);
	
	return vec4(0.0);
}

vec4 sub_bench11(vec2 point) {
	bool c1 = point.x > RECT.x;
	bool c2 = point.x < RECT.z;
	bool c3 = point.y < RECT.w ;
	bool c4 = point.y > RECT.y;
	
	if ( (c1 && c2) && (c3 && c4))
	return vec4(0.1);
	
	return vec4(0.0);
}

vec4 sub_bench2(vec2 point) {
	if (any(lessThan(point, RECT.xy )) ||
	    any(greaterThan(point, RECT.zw)))
	return vec4(0.1);
	
	return vec4(0.0);
}

vec4 sub_bench3(vec2 point) {
    vec2 s = step(RECT.xy, point) - step(RECT.zw, point);
    return vec4(s.x * s.y);   
}

vec4 sub_bench4(vec2 point) {
	bvec4 b = bvec4(greaterThan(point, RECT.xy), lessThan(point, RECT.zw));
	bool inside = all(b);
	if (all(b))
		return vec4(0.1);
	return vec4(0.0);
	//return vec4(float(inside));
}

vec4 sub_bench5(vec2 point) {
	vec2 bounded = clamp(point, RECT.xy, RECT.zw); 
	if (point == bounded)
		return vec4(0.1);
	return vec4(0.0);
}
	
vec4 sub_bench6(vec2 point) {
	vec4 rect2 = vec4(0.0,0.0,RECT.z-RECT.x, RECT.w-RECT.y);
	if ((point.x-RECT.x < rect2.z) && (point.y < rect2.w))
		return vec4(0.1);
	return vec4(0.0);
}

vec4 sub_bench7(vec2 point){
	//point.x = point.x*3.14*10;
	return vec4(pow(cos(point.x), 2.0)); //33.3
	//return vec4( cos(point.x) * cos(point.x) );
	//return vec4(     (cos(point.x*2)+1.0)/2.0                          );  //36.8
	//float c = cos(point.x); return vec4(c*c); //33.3
	
}
	
void main() {
/*	int iterations = 1;
	vec4 pixel_out = vec4(0.0);
	for (int i=0 ; i <= iterations ; i++) {
		//pixel_out += pixel_out; //115.1 //45.15
		//pixel_out += sub_bench1(vTexCoord); //112.3 //112.6   44.75
		//pixel_out += sub_bench11(vTexCoord); //xxx //112.5	44.8
		//pixel_out += sub_bench2(vTexCoord); //112.8 //112.8		44.75
		//pixel_out += sub_bench3(vTexCoord); //87 //86.8			33.06
		//pixel_out += sub_bench4(vTexCoord); //112.6 //112.7		44.7
		//pixel_out += sub_bench5(vTexCoord); //113.3 //112.8			44.82
		//pixel_out += sub_bench6(vTexCoord); //113.3 //112.8			44.82
		
		//pixel_out += sub_bench7(vTexCoord);
		
		
		pixel_out = vec4(vTexCoord.x*0.12345678);
	}*/
	FragColor.x = pow(vTexCoord.x, vTexCoord.y);
	FragColor.y = pow(vTexCoord.y, vTexCoord.x);

}
 
  
