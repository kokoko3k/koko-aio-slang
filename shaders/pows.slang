vec3 pow_3(vec3 v) {
    return v*v*v;
}

vec3 pow_4(vec3 v) {
    vec3 v2 = v*v;
    return v2*v2;
}

vec3 pow_5(vec3 v) {
    vec3 v2 = v*v;
    return v2*v2*v;
}

vec3 pow_6(vec3 v) {
    vec3 v2 = v*v;
    return v2*v2*v2;
}

vec3 pow_7(vec3 v) {
    vec3 v2 = v*v;
    return v2*v2*v2*v;
}

vec3 pow_8(vec3 v) {
    vec3 v2 = v*v;
    vec3 v4 = v2*v2;
    return v4*v4;
}

vec3 pow_9(vec3 v) {
    vec3 v2 = v*v;
    vec3 v4 = v2*v2;
    return v4*v4*v;    
}

vec3 pow_10(vec3 v) {
    vec3 v2 = v*v;
    vec3 v4 = v2*v2;
    return v4*v4*v2; 
}
