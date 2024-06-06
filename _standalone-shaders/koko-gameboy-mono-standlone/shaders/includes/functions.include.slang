// mix_step returns a or b, depending on the mix value.
// mix is supposed to have just 2 values, 1.0 or 0.0;
		vec2 mix_step(vec2 a, vec2 b, float mix){
			return (a * (1 - mix)) +
				(b * mix) ;
		}
		vec3 mix_step(vec3 a, vec3 b, float mix){
			return (a * (1 - mix)) +
				(b * mix) ;
		}
		vec3 mix_step3(vec3 a, vec3 b, float mix){
			return (a * (1 - mix)) +
				(b * mix) ;
		}
		vec4 mix_step(vec4 a, vec4 b, float mix){
			return (a * (1 - mix)) +
				(b * mix) ;
		}
		float mix_step(float a, float b, float mix){
			return (a * (1 - mix)) +
				(b * mix) ;
		}



vec3 pixel_push_luminance(vec3 c, float strength) {
	//if (strength == 0.0) return c; //lighter without the check.
	float whiteness = max(max(c.r, c.g), c.b);
	whiteness = clamp(whiteness, 0.0, 1.0);
	return c * (1+vec3((1-whiteness) * strength));
}



vec2 offsets_from_float(float in_param, int range){
    return vec2(
                  (int(in_param) % range) - range*0.5,
                  floor(in_param / range) - range*0.5
	        );
}


vec2 zoom(vec2 in_coords, float zoom_factor) {
   float off = 1.0/(zoom_factor*2.0) - 0.5;
   return (in_coords/zoom_factor)-off;
}

float zoom1D(float in_coord, float zoom_factor) {
   float off = 1.0/(zoom_factor*2.0) - 0.5;
   return (in_coord/zoom_factor)-off;
}

vec2 zoomxy(vec2 in_coords, vec2 zoom_factor) {
   vec2 off = 1.0/(zoom_factor*2.0) - 0.5;
   return (in_coords/zoom_factor)-off;
}

float scale_to_range(float x, float dmin, float dmax) {
    //Scales 0..1 range to a..b range
    return ( (dmax-dmin) * x ) + dmin;
}

vec3 scale_to_range_vec3(vec3 x, float dmin, float dmax) {
    //Scales 0..1 range to a..b range
    return ( (dmax-dmin) * x ) + dmin;
}

vec2 scale_to_range_vec2(vec2 x, float dmin, float dmax) {
    //Scales 0..1 range to a..b range
    return ( (dmax-dmin) * x ) + dmin;
}


vec3 apply_contrast_brightness(vec3 c, float contrast, float brightness) {
   return scale_to_range_vec3(c, -contrast, 1+contrast) + brightness;
}


#define VEC2_RND_A_B vec2(12.9898, 78.233)
#define RND_C 43758.5453
//The following produces weird results when with dynamic seed like framecount.
float random_fast(float power, vec2 seed) {
	float noise_out = fract(sin(dot(seed.xy, VEC2_RND_A_B)) * RND_C);
    noise_out = scale_to_range(noise_out, -power, power);
    return noise_out;
}




	bool border_needed() {
		return false;
	}



	float get_in_aspect() {
		if (ASPECT_X ==  0) return 1.3333333333333; //all mame games, not rotated
		return ASPECT_X / ASPECT_Y ;
	}

	vec2 get_scaled_coords_aspect(vec2 pTexCoord, vec4 destsize, float in_aspect , bool is_rotated){
		if (!border_needed()) return pTexCoord;
			//else
		float scale_x = 1.0;
		float scale_y = 1.0;
		float offset_x = 0.0 ;
		float offset_y = 0.0 ;
		if (is_rotated) {
			scale_y = destsize.x/(destsize.y / in_aspect );
			offset_y = (0.5 * scale_y ) - 0.5 ;
		} else {
			scale_x = destsize.x/(destsize.y * in_aspect);
			offset_x = (0.5 * scale_x ) - 0.5 ;
		}

		vec2 scale_coord=vec2(pTexCoord.x*scale_x - offset_x , pTexCoord.y*scale_y - offset_y);
		return scale_coord*2.0;
	}

	vec2 get_scaled_coords(vec2 pTexCoord, vec4 destsize, bool is_rotated){
		if (!border_needed()) return pTexCoord;
			//else
		float scale_x = 1.0;
		float scale_y = 1.0;
		float offset_x = 0.0 ;
		float offset_y = 0.0 ;
		float in_aspect = get_in_aspect();
		if (is_rotated) {
			scale_y = destsize.x/(destsize.y / in_aspect );
			offset_y = (0.5 * scale_y ) - 0.5 ;
		} else {
			scale_x = destsize.x/(destsize.y * in_aspect);
			offset_x = (0.5 * scale_x ) - 0.5 ;
		}

		vec2 scale_coord=vec2(pTexCoord.x*scale_x - offset_x , pTexCoord.y*scale_y - offset_y);
		return scale_coord;
	}

	vec2 integer_scale(vec2 in_coords, float target_aspect, bool is_rotated, float uncorrected_aspect) {

		float raw_in_aspect = params.OriginalSize.x/params.OriginalSize.y;
		float adapted_aspect = target_aspect / raw_in_aspect;

		//Keep aspect?
			adapted_aspect = mix_step(adapted_aspect, 1.0, uncorrected_aspect);
			in_coords.x = zoom1D(in_coords.x, adapted_aspect);

		vec2 izoom;
		if (!is_rotated) {
			//This is 1X integer zoom:
			izoom = params.OriginalSize.xy / global.FinalViewportSize.xy;
			//Find the maximum zoom allowed
			float int_zoom = floor(global.FinalViewportSize.y / params.OriginalSize.y );
			int_zoom = clamp(int_zoom, 1.0, GAME_GEOM_INT_SCALE_MAX);
			izoom *= int_zoom;
		} else {
			izoom = params.OriginalSize.xy / global.FinalViewportSize.yx;
			float int_zoom = floor(global.FinalViewportSize.y / (params.OriginalSize.x * adapted_aspect) );
			int_zoom = clamp(int_zoom, 1.0, GAME_GEOM_INT_SCALE_MAX);
			izoom *= int_zoom;
		}
		return zoomxy(in_coords, izoom);
	}

	bool need_NO_integer_scale() {
		return GAME_GEOM_INT_SCALE == 0.0;
	}

	bool need_integer_scale() {
		return GAME_GEOM_INT_SCALE != 0.0;
	}


vec3 hsv2rgb(vec3 c){
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

#define eps10 1.0e-10
vec3 rgb2hsv(vec3 c){
	vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
	vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
	vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

	float d = q.x - min(q.w, q.y);
	return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + eps10)), d / (q.x + eps10), q.x);
}

bool is_first_inside_rect(vec2 point, vec4 rect) {
	return (point.x >= rect.x && point.x < rect.z &&
			point.y >= rect.y && point.y < rect.w) ;
}

// COLOR TOOLS
	vec3 kelvin2rgb(float k) {
	//Convert kelvin temperature to rgb factors
	k = clamp(k,1000,40000);
	k=k/100.0;
	float tmpCalc;
		vec3 pixel_out;
	if (k<=66) {
		pixel_out.r = 255;
		pixel_out.g = 99.47080258612 * log(k) - 161.11956816610;
	} else {
		pixel_out.r = 329.6987274461 * pow(k - 60 ,-0.13320475922);
		pixel_out.g = 288.12216952833 * pow(k-60, -0.07551484921);
	}

	if (k >= 66)
		pixel_out.b = 255;
	else if (k<=19)
		pixel_out.b = 0;
	else
		pixel_out.b = 138.51773122311 * log(k - 10) - 305.04479273072;

	return pixel_out/255.0;
	}

	#define W vec3(0.2125, 0.7154, 0.0721)
	vec3 color_tools(vec3 pixel_out, vec3 Temperature_rgb) {
	//Apply color corrections to input signal.

	//Push luminance without clipping
		pixel_out = pixel_push_luminance(pixel_out,LUMINANCE);

	//Modify contrast and brightness
		if (CONTRAST != 0.0 || BRIGHTNESS != 0.0)
			pixel_out.rgb = apply_contrast_brightness(pixel_out.rgb, CONTRAST, BRIGHTNESS);

	//Modify color temperature
		if (TEMPERATURE != 6500.0) pixel_out.rgb = pixel_out.rgb * Temperature_rgb;

		//Colorization for monochrome display on hsv colorspace.
		//Select different hues for dark and bright pixels and mix them depending on the brightness
		if (COLOR_MONO_COLORIZE > 0.01) {
			vec3 pixel_grayscale = vec3(dot(pixel_out.rgb, W));
			vec3 pixel_in_hsv = rgb2hsv(pixel_grayscale); //FIXME needed? yes, checked.
			float lum = pixel_in_hsv.z * pixel_in_hsv.z; //<-- looks way better!
			vec2 bias = mix_step( vec2(0.0, COLOR_MONO_HUE_BIAS), vec2(COLOR_MONO_HUE_BIAS, 0.0), float(COLOR_MONO_HUE_BIAS > 0.0));
			bias = abs(bias);

			lum=scale_to_range(lum, 0.0-bias.x, 1.0+bias.y);
			pixel_in_hsv.y=1.0; //sat

							//Mix hues in rgb colorspace:
								vec3 pixel_rgb_hue1 = hsv2rgb( vec3(COLOR_MONO_HUE1, 1.0, pixel_in_hsv.z ) );
								vec3 pixel_rgb_hue2 = hsv2rgb( vec3(COLOR_MONO_HUE2, 1.0, pixel_in_hsv.z ) );
								vec3 pixel_rgb_hue12 = mix(pixel_rgb_hue2, pixel_rgb_hue1, vec3(lum));
							//Mix original and colorized with a specified strength
								pixel_out = mix(pixel_out, pixel_rgb_hue12, COLOR_MONO_COLORIZE);


			//pixel_in_hsv.x = mix(COLOR_MONO_HUE2, COLOR_MONO_HUE1, lum); //hue
			//pixel_out = mix(pixel_out, hsv2rgb(pixel_in_hsv), COLOR_MONO_COLORIZE);pk
		}

	//Modify saturation
		if (!(SATURATION == 1.0)) {
			vec3 intensity = vec3(dot(pixel_out.rgb, W));
			pixel_out.rgb = mix(intensity, pixel_out.rgb, SATURATION);
		}

	return pixel_out;
	}
