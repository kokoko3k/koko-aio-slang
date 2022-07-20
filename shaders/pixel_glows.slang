#include "pows.slang"

vec4 pixel_glow_gamma_1(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;


    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;


    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;


    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;


    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
    

vec4 pixel_glow_gamma_2(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3*=l3; l2*=l2; l1*=l1;
    r1*=r1; r2*=r2; r3*=r3;

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3*=l3; l2*=l2; l1*=l1;
    r1*=r1; r2*=r2; r3*=r3;

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3*=l3; l2*=l2; l1*=l1;
    r1*=r1; r2*=r2; r3*=r3;

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3*=l3; l2*=l2; l1*=l1;
    r1*=r1; r2*=r2; r3*=r3;

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_3(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_3(l3); l2=pow_3(l2); l1=pow_3(l1);
    r1=pow_3(r1); r2=pow_3(r2); r3=pow_3(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_3(l3); l2=pow_3(l2); l1=pow_3(l1);
    r1=pow_3(r1); r2=pow_3(r2); r3=pow_3(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_3(l3); l2=pow_3(l2); l1=pow_3(l1);
    r1=pow_3(r1); r2=pow_3(r2); r3=pow_3(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_3(l3); l2=pow_3(l2); l1=pow_3(l1);
    r1=pow_3(r1); r2=pow_3(r2); r3=pow_3(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_4(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_4(l3); l2=pow_4(l2); l1=pow_4(l1);
    r1=pow_4(r1); r2=pow_4(r2); r3=pow_4(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_4(l3); l2=pow_4(l2); l1=pow_4(l1);
    r1=pow_4(r1); r2=pow_4(r2); r3=pow_4(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_4(l3); l2=pow_4(l2); l1=pow_4(l1);
    r1=pow_4(r1); r2=pow_4(r2); r3=pow_4(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_4(l3); l2=pow_4(l2); l1=pow_4(l1);
    r1=pow_4(r1); r2=pow_4(r2); r3=pow_4(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_5(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_5(l3); l2=pow_5(l2); l1=pow_5(l1);
    r1=pow_5(r1); r2=pow_5(r2); r3=pow_5(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_5(l3); l2=pow_5(l2); l1=pow_5(l1);
    r1=pow_5(r1); r2=pow_5(r2); r3=pow_5(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_5(l3); l2=pow_5(l2); l1=pow_5(l1);
    r1=pow_5(r1); r2=pow_5(r2); r3=pow_5(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_5(l3); l2=pow_5(l2); l1=pow_5(l1);
    r1=pow_5(r1); r2=pow_5(r2); r3=pow_5(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_6(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_6(l3); l2=pow_6(l2); l1=pow_6(l1);
    r1=pow_6(r1); r2=pow_6(r2); r3=pow_6(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_6(l3); l2=pow_6(l2); l1=pow_6(l1);
    r1=pow_6(r1); r2=pow_6(r2); r3=pow_6(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_6(l3); l2=pow_6(l2); l1=pow_6(l1);
    r1=pow_6(r1); r2=pow_6(r2); r3=pow_6(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_6(l3); l2=pow_6(l2); l1=pow_6(l1);
    r1=pow_6(r1); r2=pow_6(r2); r3=pow_6(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_7(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_7(l3); l2=pow_7(l2); l1=pow_7(l1);
    r1=pow_7(r1); r2=pow_7(r2); r3=pow_7(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_7(l3); l2=pow_7(l2); l1=pow_7(l1);
    r1=pow_7(r1); r2=pow_7(r2); r3=pow_7(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_7(l3); l2=pow_7(l2); l1=pow_7(l1);
    r1=pow_7(r1); r2=pow_7(r2); r3=pow_7(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_7(l3); l2=pow_7(l2); l1=pow_7(l1);
    r1=pow_7(r1); r2=pow_7(r2); r3=pow_7(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_8(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_8(l3); l2=pow_8(l2); l1=pow_8(l1);
    r1=pow_8(r1); r2=pow_8(r2); r3=pow_8(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_8(l3); l2=pow_8(l2); l1=pow_8(l1);
    r1=pow_8(r1); r2=pow_8(r2); r3=pow_8(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_8(l3); l2=pow_8(l2); l1=pow_8(l1);
    r1=pow_8(r1); r2=pow_8(r2); r3=pow_8(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_8(l3); l2=pow_8(l2); l1=pow_8(l1);
    r1=pow_8(r1); r2=pow_8(r2); r3=pow_8(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_9(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_9(l3); l2=pow_9(l2); l1=pow_9(l1);
    r1=pow_9(r1); r2=pow_9(r2); r3=pow_9(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_9(l3); l2=pow_9(l2); l1=pow_9(l1);
    r1=pow_9(r1); r2=pow_9(r2); r3=pow_9(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_9(l3); l2=pow_9(l2); l1=pow_9(l1);
    r1=pow_9(r1); r2=pow_9(r2); r3=pow_9(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_9(l3); l2=pow_9(l2); l1=pow_9(l1);
    r1=pow_9(r1); r2=pow_9(r2); r3=pow_9(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}
vec4 pixel_glow_gamma_10(float my_glowpix, float my_glowpixy, float my_glow) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize;
    vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow_10(l3); l2=pow_10(l2); l1=pow_10(l1);
    r1=pow_10(r1); r2=pow_10(r2); r3=pow_10(r3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow_10(l3); l2=pow_10(l2); l1=pow_10(l1);
    r1=pow_10(r1); r2=pow_10(r2); r3=pow_10(r3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow_10(l3); l2=pow_10(l2); l1=pow_10(l1);
    r1=pow_10(r1); r2=pow_10(r2); r3=pow_10(r3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow_10(l3); l2=pow_10(l2); l1=pow_10(l1);
    r1=pow_10(r1); r2=pow_10(r2); r3=pow_10(r3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}

vec4 pixel_glow_std_pow(float my_glowpix, float my_glowpixy, float my_glow, float glow_gamma) {

    // Calculating texel coordinates
    vec2 tex = vTexCoord.xy * 1.00001;
    vec4 SourceSize1 = params.SourceSize; // vec4 SourceSize1 = rubyTextureSize;
    //vec4 size     = rubyTextureSize;
    vec2 OGL2Pos = tex * SourceSize1.xy - vec2(0.5,0.5); // vec2 OGL2Pos = tex * params.SourceSize.xy - vec2(0.5,0.5);
    vec2 fp = fract(OGL2Pos);
    vec2 dx = vec2(SourceSize1.z,0.0);
    vec2 dy = vec2(0.0,SourceSize1.w);
    vec2 pC4 = (floor(OGL2Pos) + vec2(0.5)) * params.SourceSize.zw;

    vec2 x2 = 2.0*dx; vec2 x3 = 3.0*dx;
    vec2 y2 = 2.0*dy;

    vec3 glow_gamma_vec3 = vec3(glow_gamma);
    
    my_glowpix = my_glowpix / scalemod_x * 2 ; // <-- Make it not dependant on the input resolution.
    my_glowpixy = my_glowpixy / scalemod_y *2 ;

    float wl3 = 2.0 + fp.x; wl3*=wl3; wl3 = exp2(-my_glowpix*wl3);
    float wl2 = 1.0 + fp.x; wl2*=wl2; wl2 = exp2(-my_glowpix*wl2);
    float wl1 =       fp.x; wl1*=wl1; wl1 = exp2(-my_glowpix*wl1);
    float wr1 = 1.0 - fp.x; wr1*=wr1; wr1 = exp2(-my_glowpix*wr1);
    float wr2 = 2.0 - fp.x; wr2*=wr2; wr2 = exp2(-my_glowpix*wr2);
    float wr3 = 3.0 - fp.x; wr3*=wr3; wr3 = exp2(-my_glowpix*wr3);

    float wt = 1.0/(wl3+wl2+wl1+wr1+wr2+wr3);

    vec3 l3 = texture2D(rubyTexture, pC4 -x2 ).rgb;
    vec3 l2 = texture2D(rubyTexture, pC4 -dx ).rgb;
    vec3 l1 = texture2D(rubyTexture, pC4     ).rgb;
    vec3 r1 = texture2D(rubyTexture, pC4 +dx ).rgb;
    vec3 r2 = texture2D(rubyTexture, pC4 +x2 ).rgb;
    vec3 r3 = texture2D(rubyTexture, pC4 +x3 ).rgb;
    l3=pow(l3,glow_gamma_vec3); l2=pow(l2,glow_gamma_vec3); l1=pow(l1,glow_gamma_vec3);
    r1=pow(r1,glow_gamma_vec3); r2=pow(r2,glow_gamma_vec3); r3=pow(r3,glow_gamma_vec3);

    vec3 t1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 -dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx -dy).rgb;
    l1 = texture2D(rubyTexture, pC4     -dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx -dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 -dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 -dy).rgb;
    l3=pow(l3,glow_gamma_vec3); l2=pow(l2,glow_gamma_vec3); l1=pow(l1,glow_gamma_vec3);
    r1=pow(r1,glow_gamma_vec3); r2=pow(r2,glow_gamma_vec3); r3=pow(r3,glow_gamma_vec3);

    vec3 t2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +dy).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +dy).rgb;
    l1 = texture2D(rubyTexture, pC4     +dy).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +dy).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +dy).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +dy).rgb;
    l3=pow(l3,glow_gamma_vec3); l2=pow(l2,glow_gamma_vec3); l1=pow(l1,glow_gamma_vec3);
    r1=pow(r1,glow_gamma_vec3); r2=pow(r2,glow_gamma_vec3); r3=pow(r3,glow_gamma_vec3);

    vec3 b1 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    l3 = texture2D(rubyTexture, pC4 -x2 +y2).rgb;
    l2 = texture2D(rubyTexture, pC4 -dx +y2).rgb;
    l1 = texture2D(rubyTexture, pC4     +y2).rgb;
    r1 = texture2D(rubyTexture, pC4 +dx +y2).rgb;
    r2 = texture2D(rubyTexture, pC4 +x2 +y2).rgb;
    r3 = texture2D(rubyTexture, pC4 +x3 +y2).rgb;
    l3=pow(l3,glow_gamma_vec3); l2=pow(l2,glow_gamma_vec3); l1=pow(l1,glow_gamma_vec3);
    r1=pow(r1,glow_gamma_vec3); r2=pow(r2,glow_gamma_vec3); r3=pow(r3,glow_gamma_vec3);

    vec3 b2 = (l3*wl3 + l2*wl2 + l1*wl1 + r1*wr1 + r2*wr2 + r3*wr3)*wt;

    wl2 = 1.0 + fp.y; wl2*=wl2; wl2 = exp2(-my_glowpixy*wl2);
    wl1 =       fp.y; wl1*=wl1; wl1 = exp2(-my_glowpixy*wl1);
    wr1 = 1.0 - fp.y; wr1*=wr1; wr1 = exp2(-my_glowpixy*wr1);
    wr2 = 2.0 - fp.y; wr2*=wr2; wr2 = exp2(-my_glowpixy*wr2);

    wt = 1.0/(wl2+wl1+wr1+wr2);

    vec3 Bloom = (t2*wl2 + t1*wl1 + b1*wr1 + b2*wr2)*wt;

    return vec4(Bloom*my_glow,0.0);
}

vec4 dumb_glow(float my_glow, float glow_gamma) {
    vec3 pixel_in = texture2D(rubyTexture, vTexCoord ).rgb;
    pixel_in = pow(pixel_in,vec3(glow_gamma))*my_glow;
    return vec4(pixel_in,0.0);
}

vec4 pixel_glow(float my_glowpix, float my_glowpixy, float my_glow, float glow_gamma) {

    if ( (my_glowpix >= GLOW_SHARP_MAX) && (my_glowpixy >= GLOW_SHARP_MAX) ) {
        return dumb_glow(my_glow,glow_gamma);
    }

    if (prefer_std_pow != 1.0)
    {
        if (glow_gamma == 1) { return pixel_glow_gamma_1(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 2) { return pixel_glow_gamma_2(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 3) { return pixel_glow_gamma_3(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 4) { return pixel_glow_gamma_4(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 5) { return pixel_glow_gamma_5(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 6) { return pixel_glow_gamma_6(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 7) { return pixel_glow_gamma_7(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 8) { return pixel_glow_gamma_8(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 9) { return pixel_glow_gamma_9(my_glowpix,my_glowpixy,my_glow);   }
        if (glow_gamma == 10) { return pixel_glow_gamma_10(my_glowpix,my_glowpixy,my_glow); }
    } else {
        return pixel_glow_std_pow(my_glowpix,my_glowpixy,my_glow,glow_gamma);
    }
}
 
