
in vec4  inPosition;
in ivec4 inBoneIds;
in vec4  inWeights;


uniform mat4 u_vpMatrix;
uniform mat4 u_modelMatrix;
uniform mat4 u_bonesTransforms[100];

out vec3 worldPos;

void main (void) {
    // вычисляем костевую анимацию
    mat4 boneTransform = u_bonesTransforms[inBoneIds.x] * inWeights.x;
    boneTransform     += u_bonesTransforms[inBoneIds.y] * inWeights.y;
    boneTransform     += u_bonesTransforms[inBoneIds.z] * inWeights.z;
    boneTransform     += u_bonesTransforms[inBoneIds.w] * inWeights.w;
    // домножаем на костевую анимацию
    vec4 posInWorld = u_modelMatrix * boneTransform * inPosition;
    
	gl_Position	= u_vpMatrix * posInWorld;
    worldPos = posInWorld.xyz / posInWorld.w;
}
