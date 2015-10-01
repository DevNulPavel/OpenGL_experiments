#import <glm.hpp>
#import <ext.hpp>
#import "Camera.h"
#import "GlobalValues.h"

using namespace glm;

@class LightObject;

@interface RenderObject: NSObject{
}

@property(nonatomic, assign) vec3 modelPos;
@property(nonatomic, assign) quat rotateQuat;
@property(nonatomic, assign) float scale;
@property(nonatomic, assign) BoudndingBox boundBox;
@property(nonatomic, assign) BOOL useVisibleTest;

-(void)renderModelFromCamera:(Camera*)cameraObj light:(LightObject*)light toShadow:(BOOL)toShadowMap customProj:(const mat4*)customProj;
-(void)renderModelToLight:(LightObject*)light faceIndex:(int)faceIndex;
-(void)renderToGBuffer:(Camera*)cameraObj;
-(mat4)modelTransformMatrix;
-(mat4)projectionMatrix;
-(BOOL)isVisible:(const mat4&)mvp;
-(BOOL)isVisibleFromCamera:(Camera*)cameraObj;

@end

