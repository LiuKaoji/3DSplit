//
//  ViewController.m
//  3DSplit
//
//  Created by kaoji on 2021/8/24.
//

#import "ViewController.h"
#import "RenderView.h"
#import "MBProgressHUD.h"
#import "SplitAlgorithm.h"
#import "SplitDisplayController.h"


#define weakify(var) __weak typeof(var) XYWeak_##var = var;
#define strongify(var) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__strong typeof(var) var = XYWeak_##var; \
_Pragma("clang diagnostic pop")

@interface ViewController ()
@property (copy, nonatomic)  NSString *demoModelPath;
@property (assign, nonatomic) BOOL isShowWireFrame;
@property (strong, nonatomic) IBOutlet RenderView *render;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _demoModelPath =  [[NSBundle mainBundle] pathForResource:@"ship" ofType:@"obj"];
    [self.render render: _demoModelPath];
}

/// 显示网格
- (IBAction)onClickWireframe:(id)sender {
    
    SCNDebugOptions option = self.isShowWireFrame ?SCNDebugOptionNone:SCNDebugOptionShowWireframe;
    self.render.debugOptions = option;
    
}

/// 切割测试
- (IBAction)onClickSplit:(id)sender {
    
    weakify(self);
    SplitAlgorithm *algorithm = [[SplitAlgorithm alloc] init];
    [algorithm splitWithPath:_demoModelPath
                      Center:SCNVector3Make(0, 0, 0)
                      Normal:SCNVector3Make(1, 0, 0)
                   Completed:^(NSString *partA, NSString *partB) {
        strongify(self);
        UIStoryboard *story = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        SplitDisplayController *displayVC = [story instantiateViewControllerWithIdentifier:@"SplitDisplay"];
        [self presentViewController:displayVC animated:true completion:^{
            [displayVC renderPartA:partA PartB:partB];
        }];
    }];
}


@end
