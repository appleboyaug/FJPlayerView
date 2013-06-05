//
//  FJPlayerViewController.m
//  TestGuidePage
//
//  Created by fengjia on 5/21/13.
//  Copyright (c) 2013 feng jia. All rights reserved.
//

#import "FJPlayerViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AudioToolbox/AudioToolbox.h>
#import "FJPlayerProgressSlider.h"
@interface FJPlayerViewController () {
@private
    CGRect frame;
    MPMoviePlayerController *moviePlayer;
    BOOL theFirstRotate;
    //加载时显示的页面
    UIImageView *loadingBgImageViw;
    UIActivityIndicatorView *loadingActiviy;  //加载动画
    UILabel *lbLoading;
    //上部导航控件
    UIImageView *navView;
    //定义下部控件
    UIImageView *bottomView;
    FJPlayerProgressSlider *sliderProgress;
    FJPlayerProgressSlider *cacheProgress;
    UILabel *lbCurrentPlayTime;
    UILabel *lbTotalPlayTime;
    UIButton *playBtn;
    
    BOOL isPlaying;
    BOOL isAnimationing;
    BOOL isShowingCtrls;
    
    float curVolume;
    float curPlaytime;
    
}
//配置整个页面
- (void)configPage;
- (void)initMoviePlayer;
- (void)configPreloadPage;
- (void)configNavControls;
- (void)configBottomControls;

//actions
- (void)monitorPlaybackTime;
- (void)back:(id)sender;
- (void)play:(id)sender;
- (void)changePlayerProgress:(id)sender;
- (void)changePlayerVolume:(id)sender;
- (void)clickVolumeBtn:(id)sender;
- (void)showControls;
- (void)hiddenControls;

@end

@implementation FJPlayerViewController
@synthesize videoUrl, volumeSlider, videoTitle;
@synthesize delegate;
- (void)dealloc {
    [videoUrl release];
    [volumeSlider release];
    [moviePlayer release];
    [videoTitle release];
    [navView release];
    [bottomView release];
    [sliderProgress release];
    [cacheProgress release];
    [lbCurrentPlayTime release];
    [lbTotalPlayTime release];
    [playBtn release];
    
    [super dealloc];
}
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
	// Do any additional setup after loading the view.
    theFirstRotate = YES;
}
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self configPage];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self showControls];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(monitorPlaybackTime) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControls) object:nil];
    [navView removeFromSuperview];
    [sliderProgress removeFromSuperview];
    [lbCurrentPlayTime removeFromSuperview];
    [lbTotalPlayTime removeFromSuperview];
    [bottomView removeFromSuperview];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 控制旋转
// after ios6
-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscape;
}
- (BOOL)shouldAutorotate
{
    return  YES;
}
// before ios6 
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);    
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControls) object:nil];

    [self hiddenControls];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"rotate");

}
#pragma mark - 配置整个页面信息
- (void)configPage {
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    [self initMoviePlayer];    //初始化MoviePlayer
    [self configPreloadPage];  //初始化播放钱预载页面
    [self configNavControls];  //初始化上部控件
    [self configBottomControls]; //初始化底部控件
    
    [self performSelector:@selector(hiddenControls) withObject:nil afterDelay:6];
}
- (void)initMoviePlayer {
        
    frame = self.view.bounds;
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.videoUrl];
    [moviePlayer.view setFrame:self.view.bounds];  // player的尺寸
    [moviePlayer setFullscreen:YES];    
    [moviePlayer setScalingMode:MPMovieScalingModeAspectFit];
    [moviePlayer setControlStyle:MPMovieControlStyleNone];
//    [moviePlayer setMovieSourceType:MPMovieSourceTypeFile];
    [moviePlayer prepareToPlay];  //有助于减少延迟
//    moviePlayer.shouldAutoplay=YES;
    [self.view addSubview: moviePlayer.view];
    
    // Register that the load state changed (movie is         ready)
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayerLoadStateChanged:)
                                                 name:MPMoviePlayerLoadStateDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(moviePlayBackDidFinish:)
     
                                                 name:MPMoviePlayerPlaybackDidFinishNotification
     
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDurationAvailableNotification)
                                                 name:MPMovieDurationAvailableNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(becomeActiviy:)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(enterBackground:)
                                                 name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateVolume:)
                                                 name:@"UpdateVolume"
                                               object:nil];

}


- (void)configPreloadPage {    
    loadingBgImageViw = [[UIImageView alloc] initWithFrame:frame];
    loadingBgImageViw.image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"play_back" ofType:@"png"]];
//    [moviePlayer.view addSubview:loadingBgImageViw];
    
    loadingActiviy = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(frame.size.width/2 - 15, frame.size.height/2 - 15, 30, 30)];
    loadingActiviy.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    [moviePlayer.view addSubview:loadingActiviy];
    
    lbLoading = [[UILabel alloc] initWithFrame:CGRectMake(frame.size.width/2 - 40, frame.size.height/2 + 15, 80, 30)];
    lbLoading.text = @"加载中...";
    lbLoading.font = [UIFont systemFontOfSize:12];
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 6.0) {
        lbLoading.textAlignment = NSTextAlignmentCenter;
    } else {
        lbLoading.textAlignment = UITextAlignmentCenter;
    }
    lbLoading.textColor = [UIColor whiteColor];
    lbLoading.backgroundColor = [UIColor clearColor];
    [moviePlayer.view addSubview:lbLoading];
    
    [loadingActiviy startAnimating];
    
    UIControl *control = [[UIControl alloc] initWithFrame:frame];
    control.backgroundColor = [UIColor clearColor];
    [control addTarget:self action:@selector(handleTap:) forControlEvents:UIControlEventTouchDown];
    [moviePlayer.view addSubview:control];
}
- (void)configNavControls {
    //定义nav tool bar
    navView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, frame.size.width, 44)];
    navView.userInteractionEnabled = YES;
    navView.image = [UIImage imageNamed:@"fj_play_navbg"];
    [moviePlayer.view addSubview:navView];
    
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    backBtn.frame = CGRectMake(10, 5, 55, 34);
    [backBtn setBackgroundImage:[UIImage imageNamed:@"fj_play_back"] forState:UIControlStateNormal];
    [backBtn setTitle:@"  返 回" forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [backBtn addTarget:self action:@selector(back:) forControlEvents:UIControlEventTouchUpInside];
    [navView addSubview:backBtn];
    
    UILabel *lbTitle = [[UILabel alloc] initWithFrame:CGRectMake(70, 0, frame.size.width - 140, 44)];
    lbTitle.backgroundColor = [UIColor clearColor];
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 6.0) {
        lbTitle.textAlignment = NSTextAlignmentCenter;
    } else {
        lbTitle.textAlignment = UITextAlignmentCenter;
    }
    lbTitle.textColor = [UIColor whiteColor];
    lbTitle.text = self.videoTitle;
    [navView addSubview:lbTitle];
    [lbTitle release];

}
- (void)configBottomControls {
    //定义底部控件
    bottomView = [[UIImageView alloc] initWithFrame:CGRectMake(0, frame.size.height - 80, frame.size.width, 80)];
    bottomView.image = [UIImage imageNamed:@"fj_play_bottombg"];
    bottomView.userInteractionEnabled = YES;
    [moviePlayer.view addSubview:bottomView];
    
    CGAffineTransform transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    
    cacheProgress = [[FJPlayerProgressSlider alloc] initWithFrame:CGRectMake(10, 13, frame.size.width - 20, 0)];
    [cacheProgress setMinimumTrackImage:[UIImage imageNamed:@"fj_play_progress_cache"] forState:UIControlStateNormal];
    [cacheProgress setMaximumTrackImage:[UIImage imageNamed:@"fj_play_progress_max"] forState:UIControlStateNormal];
    [cacheProgress setThumbImage:[UIImage imageNamed:@"fj_play_null"] forState:UIControlStateNormal];
    [bottomView addSubview:cacheProgress];
    sliderProgress = [[FJPlayerProgressSlider alloc] initWithFrame:CGRectMake(10, 13., frame.size.width - 20, 10)];
    sliderProgress.backgroundColor = [UIColor clearColor];
    [sliderProgress setMinimumTrackImage:[UIImage imageNamed:@"fj_play_progress_min"] forState:UIControlStateNormal];
    [sliderProgress setMaximumTrackImage:[UIImage imageNamed:@"fj_play_null"] forState:UIControlStateNormal];
    [sliderProgress setThumbImage:[UIImage imageNamed:@"fj_play_progress_thumb"] forState:UIControlStateNormal];
//    sliderProgress.transform = transform;
    [sliderProgress addTarget:self action:@selector(changePlayerProgress:) forControlEvents:UIControlEventValueChanged];
    [bottomView addSubview:sliderProgress];
//    [sliderProgress minimumValueImageRectForBounds:CGRectMake(0, 0, 100, 2)];
    
    
    playBtn = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
    playBtn.frame = CGRectMake(30, 30, 50, 50);
    [playBtn setBackgroundImage:[UIImage imageNamed:@"fj_play_playbtn"] forState:UIControlStateNormal];
    [playBtn addTarget:self action:@selector(play:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:playBtn];
    
    lbCurrentPlayTime = [[UILabel alloc] initWithFrame:CGRectMake(100, 34, 53, 40)];
    lbCurrentPlayTime.font = [UIFont systemFontOfSize:13];
    lbCurrentPlayTime.textColor = [UIColor whiteColor];
    lbCurrentPlayTime.backgroundColor = [UIColor clearColor];
    lbCurrentPlayTime.text = @"--:--:--";
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 6.0) {
        lbCurrentPlayTime.textAlignment = NSTextAlignmentCenter;
    } else {
        lbCurrentPlayTime.textAlignment = UITextAlignmentCenter;
    }
    
    [bottomView addSubview:lbCurrentPlayTime];
    
    UILabel *tmpLine = [[UILabel alloc] initWithFrame:CGRectMake(156, 47, 1, 13)];
    tmpLine.backgroundColor = [UIColor grayColor];
    [bottomView addSubview:tmpLine];
    
    lbTotalPlayTime = [[UILabel alloc] initWithFrame:CGRectMake(160, 34, 53, 40)];
    lbTotalPlayTime.font = [UIFont systemFontOfSize:13];
    lbTotalPlayTime.textColor = [UIColor lightGrayColor];
    lbTotalPlayTime.backgroundColor = [UIColor clearColor];
    lbTotalPlayTime.text = @"--:--:--";
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 6.0) {
        lbTotalPlayTime.textAlignment = NSTextAlignmentCenter;
    } else {
        lbTotalPlayTime.textAlignment = UITextAlignmentCenter;
    }
    [bottomView addSubview:lbTotalPlayTime];
    
    UIButton *volumeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    volumeBtn.frame = CGRectMake(frame.size.width - 200, 38, 30, 30);
    [volumeBtn setImage:[UIImage imageNamed:@"fj_play_volume"] forState:UIControlStateNormal];
    [volumeBtn addTarget:self action:@selector(clickVolumeBtn:) forControlEvents:UIControlEventTouchUpInside];
    [bottomView addSubview:volumeBtn];
    
    volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(frame.size.width - 180, 41, 160, 20)];
    [volumeSlider setMinimumTrackTintColor:[UIColor orangeColor]];
    [volumeSlider setMaximumTrackTintColor:[UIColor colorWithRed:20/255.0 green:20/255.0 blue:20/255.0 alpha:0.7]];
    [volumeSlider setValue:[MPMusicPlayerController applicationMusicPlayer].volume];
    [volumeSlider setMinimumTrackImage:[[UIImage imageNamed:@"fj_play_volume_min"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
    [volumeSlider setMaximumTrackImage:[[UIImage imageNamed:@"fj_play_volume_max"] stretchableImageWithLeftCapWidth:5 topCapHeight:5] forState:UIControlStateNormal];
//    [volumeSlider setThumbImage:[UIImage imageNamed:@"fj_play_volume_thumb"] forState:UIControlStateNormal];
//    CGAffineTransform transform = CGAffineTransformMakeScale(0.8f, 0.8f);
    volumeSlider.transform = transform;
    [volumeSlider addTarget:self action:@selector(changePlayerVolume:) forControlEvents:UIControlEventValueChanged];
    [bottomView addSubview:volumeSlider];

}

- (void)moviePlayerLoadStateChanged:(NSNotification*)notification {
    [loadingActiviy stopAnimating];
    [loadingActiviy removeFromSuperview];
    [loadingActiviy release];
    [lbLoading  removeFromSuperview];
    [lbLoading release];
    [loadingBgImageViw removeFromSuperview];
    [loadingBgImageViw release];
    // Unless    state is unknown, start playback
    NSLog(@"---------%d", [moviePlayer loadState]);
    
    if ([moviePlayer loadState] != MPMovieLoadStateUnknown) {
        // Remove observer
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerLoadStateDidChangeNotification
                                                      object:nil];
        
        [moviePlayer play];
        isPlaying = YES;
        [playBtn setBackgroundImage:[UIImage imageNamed:@"fj_play_pausebtn"] forState:UIControlStateNormal];
        [self monitorPlaybackTime];
    } else {
        [moviePlayer stop];
        isPlaying = NO;
    }
}

- (void)moviePlayBackDidFinish:(NSNotification*)notification {
   
    //还原状态栏为默认状态
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
    // Remove    observer
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:nil];
    
    if ([delegate  respondsToSelector:@selector(didFinishPlay:videoPath:)]) {
        [delegate didFinishPlay:self.file videoPath:moviePlayer.contentURL.path];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        
    }];
}

- (void)moviePlayLoadStateDidFinish:(NSNotification*)notification {    
    NSLog(@"loadstate");
}

- (void) handleDurationAvailableNotification
{
//    moviePlayer.currentPlaybackTime = self.file.curPlaytime;
    cacheProgress.maximumValue = moviePlayer.duration;
    lbCurrentPlayTime.text = [self convertStringFromInterval:moviePlayer.currentPlaybackTime];
    lbTotalPlayTime.text = [self convertStringFromInterval:moviePlayer.duration];
//    [self monitorPlaybackTime];
}



- (void)becomeActiviy:(NSNotification *)notify {
    NSLog(@"become: %f", moviePlayer.currentPlaybackTime);
    [playBtn setBackgroundImage:[UIImage imageNamed:@"fj_play_pausebtn"] forState:UIControlStateNormal];
    [moviePlayer play];
    isPlaying = YES;
    [self monitorPlaybackTime];
    
}
- (void)enterBackground:(NSNotification *)notity {
    NSLog(@"enterbackground");
    [moviePlayer pause];
    [playBtn setBackgroundImage:[UIImage imageNamed:@"fj_play_playbtn"] forState:UIControlStateNormal];
    isPlaying = NO;
}

- (void)updateVolume:(NSNotification *)notity {
    self.volumeSlider.value = [MPMusicPlayerController applicationMusicPlayer].volume;
}

#pragma mark - Actions
- (void) monitorPlaybackTime {
    cacheProgress.value = moviePlayer.playableDuration;
    sliderProgress.value = moviePlayer.currentPlaybackTime * 1.0 / moviePlayer.duration;
    lbCurrentPlayTime.text =[self convertStringFromInterval:moviePlayer.currentPlaybackTime];
    if (moviePlayer.duration != 0 && moviePlayer.currentPlaybackTime >= moviePlayer.duration - 1)
    {
        //-------- rewind code:
        moviePlayer.currentPlaybackTime = 0;
        sliderProgress.value = 0;
        lbCurrentPlayTime.text =[self convertStringFromInterval:moviePlayer.currentPlaybackTime];
        [moviePlayer pause];
        [playBtn setBackgroundImage:[UIImage imageNamed:@"fj_play_playbtn"] forState:UIControlStateNormal];
        isPlaying = NO;
    } else {
        if (isPlaying) {
            [self performSelector:@selector(monitorPlaybackTime) withObject:nil afterDelay:1];
        }
        
    }  
}
- (void)back:(id)sender {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidBecomeActiveNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationDidEnterBackgroundNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UpdateVolume"
                                                  object:nil];
    if (isPlaying) {
        curPlaytime =  moviePlayer.currentPlaybackTime;
        [moviePlayer stop];
        moviePlayer = nil;
        isPlaying = NO;
    } else {
        //还原状态栏为默认状态
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:NO];
        // Remove    observer
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:MPMoviePlayerPlaybackDidFinishNotification
                                                      object:nil];
        
        if ([delegate  respondsToSelector:@selector(didFinishPlay:videoPath:)]) {
//            self.file.curPlaytime = curPlaytime;
            [delegate didFinishPlay:self.file videoPath:moviePlayer.contentURL.path];
        }
        [self dismissViewControllerAnimated:YES completion:^{}];
    }    
}
- (void)play:(id)sender {
    UIButton *btn = (UIButton *)sender;
    if (isPlaying) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(monitorPlaybackTime) object:nil];
        [btn setBackgroundImage:[UIImage imageNamed:@"fj_play_playbtn"] forState:UIControlStateNormal];
        [moviePlayer pause];
        isPlaying = NO;
    } else {
        [btn setBackgroundImage:[UIImage imageNamed:@"fj_play_pausebtn"] forState:UIControlStateNormal];
        [moviePlayer play];
        isPlaying = YES;
        [self monitorPlaybackTime];
    }
}
- (void)handleTap:(id)sender {
    if (isShowingCtrls) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hiddenControls) object:nil];
        [self hiddenControls];
    } else {
        [self showControls];
        [self performSelector:@selector(hiddenControls) withObject:nil afterDelay:6];
    }
    
}
- (void)changePlayerProgress:(id)sender {
    moviePlayer.currentPlaybackTime = sliderProgress.value * moviePlayer.duration;
}
- (void)changePlayerVolume:(id)sender {
    [MPMusicPlayerController applicationMusicPlayer].volume = volumeSlider.value;
}
- (void)clickVolumeBtn:(id)sender {
    UIButton *btn = (UIButton *)sender;
    MPMusicPlayerController * mpc = [MPMusicPlayerController applicationMusicPlayer];
    if (mpc.volume == 0) {
        mpc.volume = curVolume;
        volumeSlider.value = curVolume;
        [btn setImage:[UIImage imageNamed:@"fj_play_volume"] forState:UIControlStateNormal];
    } else {
        curVolume = mpc.volume;
        mpc.volume = 0;
        volumeSlider.value = 0;
        [btn setImage:[UIImage imageNamed:@"fj_play_volume_none"] forState:UIControlStateNormal];
    }
}
- (void)showControls {
    if (isAnimationing) {
        return;
    }
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
    isAnimationing = YES;
    [UIView animateWithDuration:0.5 animations:^{
        navView.alpha = 1;
        bottomView.alpha = 1;
    } completion:^(BOOL finished) {
        isAnimationing = NO;
        isShowingCtrls = YES;
    }];
}
- (void)hiddenControls {
    if (isAnimationing) {
        return;
    }
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    isAnimationing = YES;
    [UIView animateWithDuration:0.5 animations:^{
        navView.alpha = 0;
        bottomView.alpha = 0;
    } completion:^(BOOL finished) {
        isAnimationing = NO;
        isShowingCtrls = NO;
    }];
}
- (NSString *)convertStringFromInterval:(NSTimeInterval)timeInterval {
    int hour = timeInterval/3600;
    int min = (int)timeInterval%3600/60;
    int second = (int)timeInterval%3600%60;
    if (hour == 0) {

    }
    return [NSString stringWithFormat:@"%02d:%02d:%02d", hour, min, second];
}
@end
