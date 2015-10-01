
in vec4  inPosition;
in vec3  inNormal;
in vec2  inTexcoord;
in vec3  inTangent;

uniform mat4 u_mvpMatrix;
uniform mat4 u_modelMatrix;

out vec3 worldPos;
out vec3 normal;
out vec2 texCoord;
out mat3 tbn;


void calcTBN(){
    // нормаль
    vec3 normal = normalize(u_modelMatrix * vec4(inNormal, 0.0)).xyz;
    vec3 tangent = normalize(u_modelMatrix * vec4(inTangent, 0.0)).xyz;
    tangent = normalize(tangent - normal * dot(tangent, normal));
    vec3 binormal = normalize(cross(tangent, normal));
    if (dot(cross(normal, tangent), binormal) < 0.0f){
//        tangent = tangent * -1.0f;    // фиксы направлений x
        binormal = binormal * -1.0;     // фикс направления Z
    }
    tbn = mat3(tangent, binormal, normal);
}

void main (void) {
    gl_Position	= u_mvpMatrix * vec4(inPosition.xyz, 1.0);
    
    vec4 worldPos4Comp = u_modelMatrix * inPosition;
    worldPos = worldPos4Comp.xyz / worldPos4Comp.w;
    
    texCoord = inTexcoord;
    
    calcTBN();
    
    normal = normalize(mat3(u_modelMatrix) * inNormal);
}
