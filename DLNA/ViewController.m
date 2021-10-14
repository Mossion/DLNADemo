//
//  ViewController.m
//  DLNA
//
//  Created by LTMAC on 2021/10/14.
//

#import "ViewController.h"
#import "SSDPViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    SSDPViewController *ssdpVC = [[SSDPViewController alloc] init];
    [self.navigationController pushViewController:ssdpVC animated:YES];
}


@end
