//
//  ShaderCreate.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glUtil.h"

GLuint makeShader(NSString* shaderName, NSDictionary* attributeIndexes, NSDictionary* outLayers);

GLuint buildSkyCharacter();
GLuint buildCubeProgram();
GLuint buildParticlesProgram();
GLuint buildToShadowProgramFunc();
GLuint buildSpriteProgram();
GLuint buildSkyboxProgram();
GLuint buildBillboardProgram();
GLuint buildHeightProgram();
GLuint buildHeightSpriteProgram();
GLuint buildTextProgram();
GLuint buildToGBufferProgram();
GLuint buildGBufferRenderProgram();
