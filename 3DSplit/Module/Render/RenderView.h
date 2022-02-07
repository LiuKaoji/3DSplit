//
//  RenderView.h
//  3DSplit
//
//  Created by kaoji on 2021/8/24.
//

#import <UIKit/UIKit.h>
#import <Scenekit/scenekit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SCNTapGesture)(SCNVector3 p);

@interface RenderView : SCNView

/// 点击模型回调三维坐标
@property(nonatomic, copy) SCNTapGesture tapCallback;

/// 传入模型路径进行渲染
-(void)render:(NSString *)path;

/// 移除RootNode根节点的所有子节点Node
-(void)removeAllNodesFromRootNode;

@end

NS_ASSUME_NONNULL_END
