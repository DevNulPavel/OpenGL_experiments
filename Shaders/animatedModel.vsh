
in vec4  inPosition;
in vec3  inNormal;
in vec2  inTexcoord;
in vec3  inTangent;
in vec3  inBitangent;
in ivec4 inBoneIds;
in vec4  inWeights;


uniform mat4 u_projectionMatrix;
uniform mat4 u_viewMatrix;
uniform mat4 u_modelMatrix;
uniform mat4 u_bonesTransforms[100];

out vec3 worldPos;
out vec3 normal;
out vec2 texCoord;
out mat3 tbn;

void calcTBN(){
    // нормаль
    vec3 normal = normalize(u_modelMatrix * vec4(inNormal, 0.0)).xyz;
    vec3 tangent = normalize(u_modelMatrix * vec4(inTangent, 0.0)).xyz;
    vec3 bitangent = normalize(u_modelMatrix * vec4(inBitangent, 0.0)).xyz;
    tbn = mat3(tangent, bitangent, normal);
}

void main (void) {
    // вычисляем костевую анимацию
    mat4 boneTransform = u_bonesTransforms[inBoneIds.x] * inWeights.x;
    boneTransform     += u_bonesTransforms[inBoneIds.y] * inWeights.y;
    boneTransform     += u_bonesTransforms[inBoneIds.z] * inWeights.z;
    boneTransform     += u_bonesTransforms[inBoneIds.w] * inWeights.w;
    // домножаем на костевую анимацию
    vec4 posInWorld = u_modelMatrix * boneTransform * inPosition;
    
	gl_Position	= u_projectionMatrix * u_viewMatrix * posInWorld;
    
    // матрица перехода в тангенциальное пространство
    calcTBN();
    
    // текст коорд
    texCoord = inTexcoord;
    worldPos = posInWorld.xyz / posInWorld.w;
}
