//
//  GlobalValues.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import "glUtil.h"
#import "glm.hpp"
#import "ext.hpp"
#import <map>
#import <vector>
#import "FrameBufferCreate.h"

using namespace glm;
using namespace std;

// random integer in [mn, mx)
int random_int(int mn, int mx);
float randomFloat(float mn, float mx);

struct BoudndingBox{
    vec3 leftBotomNear;
    vec3 rightBotomNear;
    vec3 leftTopNear;
    vec3 rightTopNear;
    vec3 leftBotomFar;
    vec3 rightBotomFar;
    vec3 leftTopFar;
    vec3 rightTopFar;
};

#define GlobI [GlobalValues instance]

@interface GlobalValues: NSObject{
    double _initTime;
    double _lastRenderTime;
    mat4 _cubemapProjections[6];
}

+ (GlobalValues *)instance;
-(float)timeFromStart;
-(float)angle;
-(float)deltaTime;
-(void)rendered;
-(const mat4&)cubemapProj:(int)index;

@property (nonatomic, assign) vec3 cameraInitPos;
@property (nonatomic, assign) vec3 worldSize;
@property (nonatomic, assign) mat4 projectionMatrix;
@property (nonatomic, assign) float zNear;
@property (nonatomic, assign) float zFar;

@property (nonatomic, assign) float viewWidth;
@property (nonatomic, assign) float viewHeight;

@property (nonatomic, assign) vec3 lookTargetPos;

@property(nonatomic, assign) float shadowMapScale;

// ображения
@property (nonatomic, assign) GLuint reflectionFBO;
@property (nonatomic, assign) GLuint reflectionTexture;
// Г буффер
@property (nonatomic, assign) GLint gBufferFBO;
@property (nonatomic, assign) map<GBufferTextures, uint> gbufferTextures;

@end
