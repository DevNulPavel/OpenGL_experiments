#import <Foundation/Foundation.h>
#import "glUtil.h"
#import "Camera.h"
#import "Model3D.h"
#import "LightObject.h"
#import "CubeModel.h"
#import "ParticlesModel.h"
#import "BillboardModel.h"
#import "PhysicsLogic.h"
#import "Skybox.h"
#import "SkyModel3D.h"
#import "LabelModel.h"


#define FPS_UPDATE_PERION 0.1f

@interface OpenGLRenderer : NSObject {

}

@property (nonatomic, assign) double lastFPSUpdateTime;
@property (nonatomic, assign) double lastRenderTime;

@property (atomic, assign) BOOL isPhysicsCalc;
@property (atomic, assign) BOOL needCalcLookTarget;
@property (atomic, assign) double lastHitTime;
@property (nonatomic, retain) Camera* camera;
@property (atomic, retain) NSMutableArray* lights;
@property (atomic, retain) NSMutableArray* animatedModels;
@property (atomic, retain) NSMutableArray* gBufferModels;
@property (atomic, retain) NSMutableArray* bullets;
@property (atomic, retain) NSMutableArray* normalModels;
@property (nonatomic, retain) SkyModel3D* skymodel;
@property (nonatomic, retain) LabelModel* fpsLabel;

- (id) initWithWidth:(int)width height:(int)height;
- (void) resizeWithWidth:(GLuint)width AndHeight:(GLuint)height;
- (void)keyButtonUp:(NSString*)chars;
- (void)keyButtonDown:(NSString*)chars;
- (void)mouseMoved:(float)deltaX deltaY:(float)deltaY;
- (void)updatePhysics;
- (void) render;
- (void) dealloc;

@end
