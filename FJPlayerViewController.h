//
//  FJPlayerViewController.h
//  TestGuidePage
//
//  Created by fengjia on 5/21/13.
//  Copyright (c) 2013 feng jia. All rights reserved.
//

#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const FJPlayerUpdateVolumeNotification;

@class FJPlayerProgressSlider;
@protocol FJPlayVideoDelegate <NSObject>

- (void)didFinishPlay:(id)file videoPath:(NSString *)path;

@end

@interface FJPlayerViewController : UIViewController

@property (nonatomic, copy) NSURL *videoUrl;
@property (nonatomic, copy) NSString *videoTitle;
@property (nonatomic, retain) id file;
@property (nonatomic, retain) UISlider *volumeSlider;
@property (nonatomic, assign) id<FJPlayVideoDelegate> delegate;

@end
