//
//  RenderView.m
//  3DSplit
//
//  Created by kaoji on 2021/8/24.
//

#import "RenderView.h"
#import <ModelIO/ModelIO.h>
#import <Scenekit/ModelIO.h>
#import "MDLMaterial+Properties.h"

@implementation RenderView
{
    NSString *_modelPath;
    UITapGestureRecognizer *_tapGesture;
}

- (void)awakeFromNib{
    [super awakeFromNib];
}

- (void)render:(NSString *)path{
    
    if (![[NSFileManager defaultManager] fileExistsAtPath: path]) {
        NSLog(@"ERROR - MODEL FILE NOT FOUND!");
        return;
    }
   
    _modelPath = path;
    
    //加载模型
    NSURL *modelURL = [NSURL fileURLWithPath:_modelPath];
    MDLAsset *asset = [[MDLAsset alloc] initWithURL: modelURL];
    
    if([asset count] == 0){
        NSLog(@"ERROR - MESH NOT FOUND!");
        return;
    }
    
    MDLMesh *mesh = (MDLMesh *) asset[0];
    
    MDLScatteringFunction *ScatterFunc = [[MDLScatteringFunction alloc] init];
    MDLMaterial *material = [[MDLMaterial alloc] initWithName:@"baseMaterial" scatteringFunction:ScatterFunc];
    
    NSString *baseColorKey = [NSString stringWithFormat:@"%lu",(unsigned long)MDLMaterialSemanticBaseColor];
    NSString *texturePath = [_modelPath stringByReplacingOccurrencesOfString:path.lastPathComponent withString:@"diffuseColor.jpg"];
    [material setTexturePropertiesFromPath:@{baseColorKey: texturePath}];
    
    for (MDLSubmesh *submesh in [mesh submeshes]){
        submesh.material = material;
    }
    [asset loadTextures];
    
    SCNNode *rootNode = [SCNNode nodeWithMDLObject:mesh];
    SCNScene *scene = [SCNScene scene];
    self.scene = scene;
    self.allowsCameraControl = YES;
    self.pointOfView.transform = SCNMatrix4Identity;
    [self setMultipleTouchEnabled: YES];
    [self.scene.rootNode addChildNode:rootNode];
    
    //添加手势
    _tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onClickNode:)];
    [self addGestureRecognizer:_tapGesture];
}

-(void)onClickNode: (UITapGestureRecognizer *)sender{
    
    CGPoint clickPoint = [sender locationInView:self];
    NSArray *hitResults = [self hitTest:clickPoint options:nil];
    if(!hitResults.count){
        NSLog(@"WARMING - MODEL NOT HITTED!");
        return;
    }
    SCNHitTestResult *firstResult = [hitResults objectAtIndex:0];
    SCNVector3 p = firstResult.localCoordinates;
    self.tapCallback ?self.tapCallback(p):nil;
    NSLog(@"GESTURE - ON CLICK NODE POSITION: X: (%.1f) Y: (%.1f) Z: (%.1f),", p.x, p.y, p.z);
}

-(void)removeAllNodesFromRootNode{
    
    [self.scene.rootNode.childNodes enumerateObjectsUsingBlock:^(SCNNode * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromParentNode];
    }];
}

@end
