//
//  LightObject.h
//  OSXGLEssentials
//
//  Created by DevNul on 10.04.15.
//
//

#import <Foundation/Foundation.h>
#import "glm.hpp"
#import "ext.hpp"


using namespace glm;

@class Model3D;

@interface LightObject : NSObject

@property (nonatomic, assign) GLint shadowFBO;
@property (nonatomic, assign) GLint shadowCubeTexture;
@property (nonatomic, assign) vec3 lightPos;
@property (nonatomic, assign) vec3 lightColor;
@property (nonatomic, assign) float attConst;
@property (nonatomic, assign) float attLinear;
@property (nonatomic, assign) float attExp;
@property (nonatomic, retain) Model3D* visualizeModel;

-(void)begin;
-(void)enableLightFace:(int)faceIndex;
-(void)end;
-(float) calcLightSphereScale;

@end
