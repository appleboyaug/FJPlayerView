1. 需要导入的框架：MediaPlayer.framework
2. 使用方法： 
（1）导入     #import “FJPlayerViewController.h"
（2）使用
    FJPlayerViewController *vc = [[FJPlayerViewController alloc] init];
    vc.videoTitle = @"display the video title";
    vc.videoUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"1" ofType:@"mp4"]];
//    vc.file = file;
//    vc.delegate = self;
    [self presentViewController:vc animated:YES completion:^{}];
    [vc release];

为了能够和系统声音同步还需要在AppDelegate.m中定义两个方法（如下） 并且在didFinishLaunchingWithOptions方法中调用[self addHardKeyVolumeListener];

//监听音量键：
- (void)addHardKeyVolumeListener
{
    AudioSessionInitialize(NULL, NULL, NULL, NULL);    
    AudioSessionSetActive(true);    
    AudioSessionAddPropertyListener(kAudioSessionProperty_CurrentHardwareOutputVolume ,
                                    
                                    volumeListenerCallback,
                                    
                                    (void *)(self)
                                    
                                    );    
}
//音量键回调函数：

void volumeListenerCallback (void *inUserData,
                             AudioSessionPropertyID inPropertyID,
                             UInt32 inPropertyValueSize,
                             const void *inPropertyValue)
{
    if (inPropertyID != kAudioSessionProperty_CurrentHardwareOutputVolume) return;
    Float32 value = *(Float32 *)inPropertyValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateVolume" object:nil];
}

注意： 
1. file为FJPlayerViewController中的一个成员变量，可根据实际情况传入一个对象，也可不传
2. 类中有一个代理 FJPlayVideoDelegate, 其中有一个代理方法- (void)didFinishPlay:(id)file videoPath:(NSString *)path;可根据实际情况调用