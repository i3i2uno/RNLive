//
//  RCTStream.m
//  RCTLFLiveKit
//
//  Created by 권오빈 on 2016. 8. 10..
//  Copyright © 2016년 권오빈. All rights reserved.
//

#import <React/RCTBridgeModule.h>
#import "LFLiveSession.h"
//#import <LFLiveKit/LFLiveSession.h>
#import "RCTStream.h"
#import "RCTStreamManager.h"
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTEventDispatcher.h>
#import <React/UIView+React.h>

@interface RCTStream () <LFLiveSessionDelegate>

@property (nonatomic, weak) RCTStreamManager *manager;
@property (nonatomic, strong) LFLiveSession *session;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIButton *startLiveButton;

@end

@implementation RCTStream{
    bool _started;
    bool _cameraFronted;
    NSString *_url;
    bool _landscape;
	RCTEventDispatcher *_eventDispatcher;
}

- (void)insertReactSubview:(UIView *)view atIndex:(NSInteger)atIndex
{
    [self insertSubview:view atIndex:atIndex + 1];
    return;
}

- (void)removeReactSubview:(UIView *)subview
{
    [subview removeFromSuperview];
    return;
}

- (void)removeFromSuperview
{
    __weak typeof(self) _self = self;
    if(!_started){
        [_self.session stopLive];
    }
    [super removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    
    //[UIApplication sharedApplication].idleTimerDisabled = _previousIdleTimerDisabled;
}

- (instancetype)initWithEventDispatcher:(RCTEventDispatcher *)eventDispatcher
{
	if ((self = [super init])) {
		_eventDispatcher = eventDispatcher;
		_started = NO;
		_cameraFronted = YES;
		self.backgroundColor = [UIColor clearColor];
		[self requestAccessForVideo];
		[self requestAccessForAudio];
		[self addSubview:self.containerView];
	}

    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];  // allow
		[[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
	});

	return self;
}

#pragma mark -- Public Method
- (void)requestAccessForVideo {
    __weak typeof(self) _self = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.session setRunning:YES];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            // 已经开启授权，可继续
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.session setRunning:YES];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
        default:
            break;
    }
}

- (void)requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}

#pragma mark -- LFStreamingSessionDelegate
/** live status changed will callback */
- (void)liveSession:(nullable LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
    NSLog(@"liveStateDidChange: %ld", state);
    switch (state) {
        case LFLiveReady:
			self.onLiveReady(@{@"target": self.reactTag});
            break;
        case LFLivePending:
			self.onLivePending(@{@"target": self.reactTag});
			break;
        case LFLiveStart:
			self.onLiveStart(@{@"target": self.reactTag});
			break;
        case LFLiveError:
			self.onLiveError(@{@"target": self.reactTag});
			break;
        case LFLiveStop:
			self.onLiveStop(@{@"target": self.reactTag});
			break;
        default:
            break;
    }
}

#pragma mark -- Getter Setter
- (LFLiveSession *)session {
    NSLog(@"Session 호출");
    if (!_session) {
        NSLog(@"Session 생성");
        /**      发现大家有不会用横屏的请注意啦，横屏需要在ViewController  supportedInterfaceOrientations修改方向  默认竖屏  ****/
        /**      发现大家有不会用横屏的请注意啦，横屏需要在ViewController  supportedInterfaceOrientations修改方向  默认竖屏  ****/
        /**      发现大家有不会用横屏的请注意啦，横屏需要在ViewController  supportedInterfaceOrientations修改方向  默认竖屏  ****/
        
        
        /***   默认分辨率368 ＊ 640  音频：44.1 iphone6以上48  双声道  方向竖屏 ***/
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:[LFLiveAudioConfiguration defaultConfiguration] videoConfiguration:[LFLiveVideoConfiguration defaultConfigurationForQuality:LFLiveVideoQuality_Low3 landscape:_landscape]];
        
        /**    自己定制单声道  */
        /*
         LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
         audioConfiguration.numberOfChannels = 1;
         audioConfiguration.audioBitrate = LFLiveAudioBitRate_64Kbps;
         audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
         _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:[LFLiveVideoConfiguration defaultConfiguration]];
         */
        
        /**    自己定制高质量音频96K */
        /*
         LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
         audioConfiguration.numberOfChannels = 2;
         audioConfiguration.audioBitrate = LFLiveAudioBitRate_96Kbps;
         audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
         _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:[LFLiveVideoConfiguration defaultConfiguration]];
         */
        
        /**    自己定制高质量音频96K 分辨率设置为540*960 方向竖屏 */
        
        /*
         LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
         audioConfiguration.numberOfChannels = 2;
         audioConfiguration.audioBitrate = LFLiveAudioBitRate_96Kbps;
         audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
         
         LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
         videoConfiguration.videoSize = CGSizeMake(540, 960);
         videoConfiguration.videoBitRate = 800*1024;
         videoConfiguration.videoMaxBitRate = 1000*1024;
         videoConfiguration.videoMinBitRate = 500*1024;
         videoConfiguration.videoFrameRate = 24;
         videoConfiguration.videoMaxKeyframeInterval = 48;
         videoConfiguration.orientation = UIInterfaceOrientationPortrait;
         videoConfiguration.sessionPreset = LFCaptureSessionPreset540x960;
         
         _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration];
         */
        
        
        /**    自己定制高质量音频128K 分辨率设置为720*1280 方向竖屏 */
        
        /*
         LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
         audioConfiguration.numberOfChannels = 2;
         audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
         audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
         
         LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
         videoConfiguration.videoSize = CGSizeMake(720, 1280);
         videoConfiguration.videoBitRate = 800*1024;
         videoConfiguration.videoMaxBitRate = 1000*1024;
         videoConfiguration.videoMinBitRate = 500*1024;
         videoConfiguration.videoFrameRate = 15;
         videoConfiguration.videoMaxKeyframeInterval = 30;
         videoConfiguration.landscape = NO;
         videoConfiguration.sessionPreset = LFCaptureSessionPreset360x640;
         
         _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration];
         */
        
        
        /**    自己定制高质量音频128K 分辨率设置为720*1280 方向横屏  */
        
        /*
         LFLiveAudioConfiguration *audioConfiguration = [LFLiveAudioConfiguration new];
         audioConfiguration.numberOfChannels = 2;
         audioConfiguration.audioBitrate = LFLiveAudioBitRate_128Kbps;
         audioConfiguration.audioSampleRate = LFLiveAudioSampleRate_44100Hz;
         
         LFLiveVideoConfiguration *videoConfiguration = [LFLiveVideoConfiguration new];
         videoConfiguration.videoSize = CGSizeMake(1280, 720);
         videoConfiguration.videoBitRate = 800*1024;
         videoConfiguration.videoMaxBitRate = 1000*1024;
         videoConfiguration.videoMinBitRate = 500*1024;
         videoConfiguration.videoFrameRate = 15;
         videoConfiguration.videoMaxKeyframeInterval = 30;
         videoConfiguration.landscape = YES;
         videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
         
         _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfiguration videoConfiguration:videoConfiguration];
         */
        
        _session.delegate = self;
        _session.showDebugInfo = YES;
        _session.preView = self;
        //_session.mirror = NO;

        //        UIImageView *imageView = [[UIImageView alloc] init];
        //        imageView.alpha = 0.8;
        //        imageView.frame = CGRectMake(100, 100, 29, 29);
        //        imageView.image = [UIImage imageNamed:@"ios-29x29"];
        //        _session.warterMarkView = imageView;
        //        
    }
    return _session;
}

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.frame = self.bounds;
        _containerView.backgroundColor = [UIColor clearColor];
        _containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return _containerView;
}


- (void) setStarted:(BOOL) started{
    __weak typeof(self) _self = self;
    if(started != _started){
        if(started){
            LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
            stream.url = _url;
            [_self.session startLive:stream];
        }else{
            [_self.session stopLive];
        }
        _started = started;
    }
}

- (void) setCameraFronted: (BOOL) cameraFronted{
    __weak typeof(self) _self = self;
    if(cameraFronted != _cameraFronted){
        //AVCaptureDevicePosition devicePositon = _self.session.captureDevicePosition;
        if (cameraFronted){
            _self.session.captureDevicePosition = AVCaptureDevicePositionFront;
        }else {
            _self.session.captureDevicePosition = AVCaptureDevicePositionBack;
        }
        _cameraFronted = cameraFronted;
    }
}

- (void) setUrl: (NSString *) url {
    _url = url;
}

- (void) setLandscape: (BOOL) landscape{
    _landscape = landscape;
}

@end
