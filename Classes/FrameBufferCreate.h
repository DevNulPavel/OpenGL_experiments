//
//  FrameBufferCreate.h
//  OSXGLEssentials
//
//  Created by Pavel Ershov on 05.04.15.
//
//

#import <Foundation/Foundation.h>
#include "glUtil.h"
#include <map>


using namespace std;

enum GBufferTextures{
    GBUFFER_DIFFUSE_ATTACH = GL_COLOR_ATTACHMENT0 + 0,
    GBUFFER_POSITION_ATTACH = GL_COLOR_ATTACHMENT0 + 1,
    GBUFFER_NORMALS_ATTACH = GL_COLOR_ATTACHMENT0 + 2,
    GBUFFER_DEPTH_ATTACH = GL_DEPTH_ATTACHMENT,
};


GLuint createGBufferFBO(uint width, uint height, map<GBufferTextures, uint>& textures);
GLuint createHeightFBO(uint width, uint height, uint& pixelBufferSize, uint& pixelBufferVertex, uint& pixelBufferNormal, uint& pixelBufferTexCoord);
GLuint buildShadowFBO(int viewWidth, int viewHeight, GLuint* depthCubemap);
GLuint buildCubeFBO(GLuint* colorTexture, uint width, uint height);
void destroyFBO(GLuint fboName);
