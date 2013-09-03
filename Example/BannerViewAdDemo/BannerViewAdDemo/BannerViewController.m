/*
    File: BannerViewController.m
Abstract: A container view controller that manages an ADBannerView and a content view controller
 Version: 2.2

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the following
terms, and your use, installation, modification or redistribution of
this Apple software constitutes acceptance of these terms.  If you do
not agree with these terms, please do not use, install, modify or
redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software.
Neither the name, trademarks, service marks or logos of Apple Inc. may
be used to endorse or promote products derived from the Apple Software
without specific prior written permission from Apple.  Except as
expressly stated in this notice, no other rights or licenses, express or
implied, are granted by Apple herein, including but not limited to any
patent rights that may be infringed by your derivative works or by other
works in which the Apple Software may be incorporated.

The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.

IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

Copyright (C) 2013 Apple Inc. All Rights Reserved.

*/

// Modified by Paul Cezanne, Enki Labs,
// Changes Copyright (C) 2013 Paul Cezanne
// Changes released under the above Apple license

#import "BannerViewController.h"
#import "LARSAdController.h"


#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)

@implementation BannerViewController {
    UIView *_bannerView;
    UIViewController *_contentController;
    BOOL isLoaded;
    int adMobShadowHeight;
}

- (instancetype)initWithContentViewController:(UIViewController *)contentController
{
    // If contentController is nil, -loadView is going to throw an exception when it attempts to setup
    // containment of a nil view controller.  Instead, throw the exception here and make it obvious
    // what is wrong.
    NSAssert(contentController != nil, @"Attempting to initialize a BannerViewController with a nil contentController.");
    
    self = [super init];
    if (self != nil) {
        _contentController = contentController;
        
        // you can disable banner ads at startup if you are using in-app
        // purchases here
        //
        // IAPHelper *sharedInstance = [//IAPHelper sharedInstance];
        //if ([sharedInstance showBannerAds]) {
        if (YES) {
            _bannerView = [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            _bannerView = nil;      // not showing ads since the user has upgraded
        }
        _contentController = contentController;
    }
    
    isLoaded = NO;
    
    // This is gross. AdMob ads that are placed at the bottom of the view
    // have a 20 pixel shadow on top of them. So, if you slide your whole view
    // upwards then you'll have a gap between the visual top of the ad and the
    // bottom of your UI.
    adMobShadowHeight = 0;
    
    [[LARSAdController sharedManager] addObserver:self
                                       forKeyPath:kLARSAdObserverKeyPathIsAdVisible
                                          options:0
                                          context:KVO_AD_VISIBLE];
    return self;
}

- (void)loadView
{
    UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    [contentView addSubview:_bannerView];
    
    // Setup containment of the _contentController.
    [self addChildViewController:_contentController];
    [contentView addSubview:_contentController.view];
    [_contentController didMoveToParentViewController:self];
    
    self.view = contentView;
}
        

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context;
{
    //use the context to make sure this is a change in the address,
    //because we may also be observing other things
    if(context == KVO_AD_VISIBLE) {
        NSNumber *isVisible = [object valueForKey:kLARSAdObserverKeyPathIsAdVisible];
        
        if ([isVisible boolValue]) {
            _bannerView.frame = [[LARSAdController sharedManager] containerView].frame;

            isLoaded = YES;
            
            // right now we need to know if the Adapter was an AdMob ad
            // so we can do something about the shadow
        } else {
            isLoaded = YES;
        }
    }
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

// you would call this method if, for example, you implemented in-app purchases
// and wanted to turn off all banners
- (void) turnBannersOff;
{
    [_bannerView removeFromSuperview];
    _bannerView = nil;
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}


#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
#endif

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [_contentController preferredInterfaceOrientationForPresentation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [_contentController supportedInterfaceOrientations];
}

- (void)viewDidLayoutSubviews
{
    // This method will be called whenever we receive a delegate callback
    // from the banner view.
    // (See the comments in -bannerViewDidLoadAd: and -bannerView:didFailToReceiveAdWithError:)
    
    CGRect contentFrame = self.view.bounds, bannerFrame = CGRectZero;
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    bannerFrame = _bannerView.frame;
#else
    // If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
    // Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
    // At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.
    bannerFrame.size = [_bannerView sizeThatFits:contentFrame.size];
#endif
    
    // Check if the banner has an ad loaded and ready for display.  Move the banner off
    // screen if it does not have an ad.
    if (isLoaded) {
        contentFrame.size.height -= (bannerFrame.size.height - adMobShadowHeight);
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }
    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
}

-(void) dealloc;
{
    [[LARSAdController sharedManager]  removeObserver:self forKeyPath:kLARSAdObserverKeyPathIsAdVisible];
}

@end
