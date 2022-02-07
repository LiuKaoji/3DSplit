//
//  SplitAlgorithm.h
//  3DSplit
//
//  Created by kaoji on 2022/1/24.
//

#import <Foundation/Foundation.h>
#import <Scenekit/Scenekit.h>

typedef void (^MeshCutBlock)(NSString *partA, NSString *partB);

NS_ASSUME_NONNULL_BEGIN

@interface SplitAlgorithm : NSObject

///@param path 3D模型路径
///@param center 平面中心
///@param normal 法线方向
///@param complete  回调错误或者切割后模型输出路径
-(void)splitWithPath:(NSString *)path
                Center:(SCNVector3)center
                Normal:(SCNVector3)normal
                Completed:(MeshCutBlock)complete;

@end

NS_ASSUME_NONNULL_END
