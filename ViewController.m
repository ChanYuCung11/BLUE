//
//  ViewController.m
//  BLUE
//
//  Created by student on 16/9/14.
//  Copyright © 2016年 lyb. All rights reserved.
//

#import "ViewController.h"
#import "CoreBlue.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)openAction:(id)sender {
    
    CoreBlue *blue = [[CoreBlue alloc]init];
    
    [self.navigationController pushViewController:blue animated:YES];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
