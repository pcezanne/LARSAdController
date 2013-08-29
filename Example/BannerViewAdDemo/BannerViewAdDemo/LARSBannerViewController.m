//
//  LARSBannerViewController.m
//  BannerViewAdDemo
//
//  Created by Paul Cezanne on 8/29/13.
//  Copyright (c) 2013 theonlylars. All rights reserved.
//

#import "LARSBannerViewController.h"

@interface LARSBannerViewController ()

@end

@implementation LARSBannerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//Deprecated
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
    return (toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}
#endif

//New iOS 6 stuff
- (BOOL)shouldAutorotate{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


@end
