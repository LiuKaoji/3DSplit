//
//  SplitDisplayController.m
//  3DSplit
//
//  Created by kaoji on 2022/2/6.
//

#import "SplitDisplayController.h"
#import "RenderView.h"

@interface SplitDisplayController ()

@property (weak, nonatomic) IBOutlet RenderView *partARender;
@property (weak, nonatomic) IBOutlet RenderView *partBRender;

@end

@implementation SplitDisplayController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)renderPartA:(NSString *)pathA PartB:(NSString *)pathB{
    
    [self.partARender render:pathA];
    [self.partBRender render:pathB];
 
}

@end
