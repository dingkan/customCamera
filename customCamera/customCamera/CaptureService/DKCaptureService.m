//
//  DKCaptureService.m
//  customCamera
//
//  Created by dingkan on 2019/11/1.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKCaptureService.h"
#import "DKViedoWritter.h"
#import <sys/sysctl.h>
#include <mach/mach_time.h>
#import <UIKit/UIKit.h>
#import "DKViedoWritter.h"
#import "DKVideoAssetHandle.h"
#import "DKCameraManager.h"
#import <CoreMotion/CoreMotion.h>

static NSString *const DKVIDEODIR = @"tmpVideo";

@interface DKCaptureService()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate,DKViedoWritterDelegate>{
    NSString *_videoDir;
    BOOL _startSessionOnEnteringForeground;
    BOOL _firstStartRunning;
}
//任务队列分流
//音视频任务启动
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
//数据输入
@property (nonatomic, strong) dispatch_queue_t writtingQueue;
//数据输出
@property (nonatomic, strong) dispatch_queue_t outputQueue;

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) AVCaptureDevice *currentDevice;

@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;

@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;

@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, strong) AVCaptureStillImageOutput *imageOutput;

@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;

@property (nonatomic, strong) NSDictionary *audioSetting;

@property (nonatomic, strong) AVCaptureConnection *videoConnection;

@property (nonatomic, strong) AVCaptureConnection *audioConnection;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *preViewLayer;

@property (nonatomic, strong) CMMotionManager *manager;

@property (nonatomic, assign) AVCaptureVideoOrientation orientation;

@property (nonatomic, strong) DKViedoWritter *videoWriter;

@end

@implementation DKCaptureService

-(instancetype)init{
    if (self = [super init]) {
        [self setupGCDDispatchQueue];
        _videoDir = [NSTemporaryDirectory() stringByAppendingPathComponent:DKVIDEODIR];
        _startSessionOnEnteringForeground = NO;
        _firstStartRunning = NO;
        _isRunning = NO;
        _openNativeFaceDetect = NO;
        [self setupDeviceSetting];
        [self sertupVideoSetting];
        [self startMotionManager];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopDeviceMotion];
}

#pragma DKViedoWritterDelegate
-(void)videoWriter:(DKViedoWritter *)writer didFailWithError:(NSError *)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:recorderDidFailWithError:)]) {
        [self.delegate captureService:self recorderDidFailWithError:error];
    }
}

-(void)videoWriter:(DKViedoWritter *)writer completeWriting:(NSError *)error{
    if (error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:recorderDidFailWithError:)]) {
            [self.delegate captureService:self recorderDidFailWithError:error];
        }
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureServiceRecorderDidStop:asset:)]) {
            AVURLAsset *asset = [AVURLAsset assetWithURL:self.recordURL];
            [self.delegate captureServiceRecorderDidStop:self asset:asset];
        }else if (self.delegate && [self.delegate respondsToSelector:@selector(captureServiceRecorderDidStop:)]) {
            [self.delegate captureServiceRecorderDidStop:self];
        }
    }
}

#pragma AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    NSMutableArray *transformedFaces = [NSMutableArray array];
    for (AVMetadataObject *face in metadataObjects) {
        @autoreleasepool {
            AVMetadataFaceObject *transformedFace = (AVMetadataFaceObject *)[self.preViewLayer transformedMetadataObjectForMetadataObject:face];
            if (transformedFace) {
                [transformedFaces addObject:transformedFace];
            }
        }
    }
    
    @autoreleasepool {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:outputFaceDetectData:)]) {
            [self.delegate captureService:self outputFaceDetectData:[transformedFaces copy]];
        }
    }
}

#pragma AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //捕获不同的线程
    if (connection == _videoConnection) {
        [self _processVideoData:sampleBuffer];
    }else if (connection == _audioConnection){
        [self _processAudioData:sampleBuffer];
    }
}

-(BOOL)_setupSession:(NSError **)error{
    
    if (_captureSession) {
        return YES;
    }

    if (![DKViedoWritter clearVideoFile:DKVIDEODIR error:error]) {
        return NO;
    }
    
    if (![[NSFileManager defaultManager] createDirectoryAtPath:_videoDir withIntermediateDirectories:YES attributes:nil error:error]) {
        return NO;
    }
    
    _captureSession = [[AVCaptureSession alloc]init];
    _captureSession.sessionPreset = _sessionPreset;
    
    if (![self _setupVideoInputOutput:error]) {
        return NO;
    }
    
    if (![self _setupImageOutput:error]) {
        return NO;
    }
    
    if (self.shouldRecordAudio) {
        if (![self _setupAudioOutput:error]) {
            return NO;
        }
    }
    
    if (self.openNativeFaceDetect) {
        if (![self _setupFaceDataOutput:error]) {
            return NO;
        }
    }
    
    //判断有无外界使用的预览图层
    if (self.preViewSource && [self.preViewSource respondsToSelector:@selector(preViewSource)]) {
        self.preViewLayer = [self.preViewSource preViewLayerSource];
        [_preViewLayer setSession:_captureSession];
        [_preViewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
//        _preViewLayer.connection.videoOrientation =
    }else{
        self.preViewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:_captureSession];
        //充满整个屏幕
        [_preViewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:getPreViewLayer:)]) {
            [self.delegate captureService:self getPreViewLayer:_preViewLayer];
        }
    }
    
    //captureService和videoWritter各自维护自己的生命周期，捕获视频流的状态与写入视频流的状态解耦分离，音视频状态变迁由captureService内部管理，外层业务无需手动处理视频流变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_captureSessionNotification:) name:nil object:self.captureSession];

    //为了适配低于iOS9的版本，在iOS9以前，当session start 还没有完成就退到后台，回到前台会捕获AVCaptureSessionRuntimeErrorNotification,这是需要手动重新启动session，iOS9以后系统对此作了优化，系统退到后台会将session start 缓存起来，回到前台自动调用缓存的session start.无需手动调用
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_enterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
    return YES;
}

#pragma CaptureSession Notificaiton
-(void)_captureSessionNotification:(NSNotification *)notification{
    NSString *name = notification.name;
    NSLog(@"_captureSessionNotification:%@",name);
    
    if ([name isEqualToString:AVCaptureSessionDidStartRunningNotification]) {
        if (!_firstStartRunning) {
            NSLog(@"session start runging");
            _firstStartRunning = YES;
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureServiceDidStartService:)]) {
                [self.delegate captureServiceDidStartService:self];
            }
        }else{
            NSLog(@"session resunme running");
        }
    }else if ([name isEqualToString:AVCaptureSessionDidStopRunningNotification]){
        if (!_isRunning) {
            NSLog(@"session stop running");
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureServiceDidStopService:)]) {
                [self.delegate captureServiceDidStopService:self];
            }
        }else{
            NSLog(@"interupt session stop running");
        }
    }else if ([name isEqualToString:AVCaptureSessionWasInterruptedNotification]){//电话打进来，收到打断通知
        NSLog(@"session was interupt, userInfo: %@",notification.userInfo);
    }else if ([name isEqualToString:AVCaptureSessionInterruptionEndedNotification]){
        NSLog(@"session interput end");
    }else if ([name isEqualToString:AVCaptureSessionRuntimeErrorNotification]){
        NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
        if (error.code == AVErrorDeviceIsNotAvailableInBackground) {
            NSLog(@"session runtime error: AVErrorDeviceIsNotAvailableInBackground");
            _startSessionOnEnteringForeground = YES;
        }else{
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }else{
        NSLog(@"handle other nofitication: %@",name);
    }
}

#pragma NSExtensionHostWillEnterForegroundNotification
-(void)_enterForegroundNotification:(NSNotification *)notification{
    if (_startSessionOnEnteringForeground) {
        NSLog(@"为了适配低于iOS 9的版本，在iOS 9以前，当session start 还没完成就退到后台，回到前台会捕获AVCaptureSessionRuntimeErrorNotification，这时需要手动重新启动session，iOS 9以后系统对此做了优化，系统退到后台后会将session start缓存起来，回到前台会自动调用缓存的session start，无需手动调用");
        _startSessionOnEnteringForeground = NO;
        [self startRunning];
    }else{
        
    }
}

-(void)startRecording{
    dispatch_async(_writtingQueue, ^{
        NSString *videoFilePath = [self->_videoDir stringByAppendingPathComponent:[NSString stringWithFormat:@"Record- %llu.mp4",mach_absolute_time()]];
        
        self->_recordURL = [[NSURL alloc]initFileURLWithPath:videoFilePath];
        
        if (self.recordURL) {
            self.videoWriter = [[DKViedoWritter alloc] initWithURL:self.recordURL videoSettings:self.videoSetting audioSetting:self.audioSetting];
            self.videoWriter.delegate = self;
            [self.videoWriter startWritting];
            if (self.delegate && [self.delegate respondsToSelector:@selector(caputreServiceRecorderDidStart:)]) {
                [self.delegate caputreServiceRecorderDidStart:self];
            }
        }else{
            NSLog(@" No record URL");
        }
        
    });
}

-(void)cancleRecording{
    dispatch_async(_writtingQueue, ^{
        if (self.videoWriter) {
            [self.videoWriter cancleWriting];
            if (self.delegate && [self.delegate respondsToSelector:@selector(caputreServiceRecorderDidCancel:)]) {
                [self.delegate caputreServiceRecorderDidCancel:self];
            }
        }
    });
}

-(void)stopRecording{
    dispatch_async(_writtingQueue, ^{
        if (self.videoWriter) {
            [self.videoWriter stopWtiringAsyn];
        }
    });
}

-(void)capturePhoto{
    AVCaptureConnection *connection = [_imageOutput connectionWithMediaType:AVMediaTypeVideo];

    if (connection.isVideoMirroringSupported) {
        connection.videoOrientation = _orientation;
    }
    
    __weak typeof(self) wself = self;
    [_imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        __strong typeof(wself) strongSelf = wself;
        if (imageDataSampleBuffer) {
            NSData *data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage *img = [UIImage imageWithData:data];
            if (strongSelf.delegate && [strongSelf.delegate respondsToSelector:@selector(captureServie:capturePhoto:)]) {
                [strongSelf.delegate captureServie:strongSelf capturePhoto:img];
            }
        }
    }];
}

-(void)startRunning{
    dispatch_async(_sessionQueue, ^{
        NSError *error = nil;
        BOOL result = [self _setupSession:&error];
        if (result) {
            self->_isRunning = YES;
            [self.captureSession startRunning];
        }else{
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    });
}

-(void)stopRunning{
    dispatch_async(_sessionQueue, ^{
        self->_isRunning = NO;
        NSError *error = nil;
        [DKViedoWritter clearVideoFile:DKVIDEODIR error:&error];
        if (error) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
        [self->_captureSession stopRunning];
    });
}

-(void)switchCamera{
    if (_openDepth) {return;}
    
    [DKCameraManager switchCameraWithPosition:_devicePostion session:_captureSession currentInput:_videoInput connection:_videoConnection output:_videoOutput complete:^(AVCaptureDeviceInput * _Nonnull input, AVCaptureDevicePosition currentPosition) {
        self.videoInput = input;
        self.devicePostion = currentPosition;
    }];
}

-(BOOL)depthSupported{
    NSString *deviceInfo = [self _getDeviceInfo];
    double sysVersion = [[self _grtSystemVersion] doubleValue];
    NSArray *supportDuaDevices = @[@"iPhone9,2",@"iPhone10,2",@"iPhone10,5",];
    NSArray *supportXDevices = @[@"iPhone10,3",@"iPhone10,6"];
    BOOL deviceSupported = NO;
    if ([supportDuaDevices containsObject:deviceInfo] && _devicePostion == AVCaptureDevicePositionBack) {
        deviceSupported = YES;
    }
    
    if ([supportXDevices containsObject:deviceInfo]) {
        deviceSupported = YES;
    }
    
    BOOL systemSupported = sysVersion >= 11.0 ? YES : NO;
    return deviceSupported && systemSupported;
}

#pragma private
- (NSString *)_getDeviceInfo {
    int mib[2];
    size_t len;
    char *machine;
    
    mib[0] = CTL_HW;
    mib[1] = HW_MACHINE;
    sysctl(mib, 2, NULL, &len, NULL, 0);
    machine = malloc(len);
    sysctl(mib, 2, machine, &len, NULL, 0);
    
    NSString *platform = [NSString stringWithCString:machine encoding:NSASCIIStringEncoding];
    free(machine);
    
    return platform;
}

-(NSString *)_grtSystemVersion{
    return [UIDevice currentDevice].systemVersion;
}

#pragma process Data
-(void)_processVideoData:(CMSampleBufferRef)sampleBuffer{
    if (_videoWriter && _videoWriter.isWriting) {
        //CFRetain 的目的是为了每条业务线（写视频、抛帧）的sampleBuffer都是独立的
        CFRetain(sampleBuffer);
        dispatch_async(_writtingQueue, ^{
            [self.videoWriter appendSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
        });
    }
    
    CFRetain(sampleBuffer);
    //及时清理临时变量。防止出现内存峰值
    dispatch_async(_outputQueue, ^{
        @autoreleasepool {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:outputSampleBuffer:)]) {
                [self.delegate captureService:self outputSampleBuffer:sampleBuffer];
            }
        }
        CFRelease(sampleBuffer);
    });
}

-(void)_processAudioData:(CMSampleBufferRef)sampleBuffer{
    if (_videoWriter && _videoWriter.isWriting) {
        CFRetain(sampleBuffer);
        dispatch_async(_writtingQueue, ^{
            [self.videoWriter appendSampleBuffer:sampleBuffer];
            CFRelease(sampleBuffer);
        });
    }
}

-(void)_precessDepthData:(AVDepthData *)depthData time:(CMTime)timestamp API_AVAILABLE(ios(11.0)){
    AVDepthData *cDepthData = [depthData depthDataByConvertingToDepthDataType:kCVPixelFormatType_DepthFloat32];
    dispatch_async(_outputQueue, ^{
        if(self.delegate && [self.delegate respondsToSelector:@selector(captureService:captureTrueDepth:)]){
            [self.delegate captureService:self captureTrueDepth:cDepthData];
        }
    });
}

#pragma setup
-(BOOL)_setupAudioOutput:(NSError **)error{
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    self.audioInput = [[AVCaptureDeviceInput alloc]initWithDevice:audioDevice error:error];
    if (_audioInput) {
        if ([_captureSession canAddInput:_audioInput]) {
            [_captureSession addInput:_audioInput];
        }else{
            *error = [NSError errorWithDomain:@"com.dingkan.captureservice.audio" code:-2220005 userInfo:@{NSLocalizedDescriptionKey:@"add audio input failed"}];
            return NO;
        }
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.audio" code:-2220005 userInfo:@{NSLocalizedDescriptionKey:@"device input is nil"}];
        return NO;
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc]init];
    dispatch_queue_t audioQueue = dispatch_queue_create("com.dingkan.captureservice.audio", DISPATCH_QUEUE_SERIAL);
    [_audioOutput setSampleBufferDelegate:self queue:audioQueue];
    
    if ([_captureSession canAddOutput:_audioOutput]) {
        [_captureSession addOutput:_audioOutput];
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.audio" code:-2220005 userInfo:@{NSLocalizedDescriptionKey:@"add audio output failed"}];
        return NO;
    }
    
    self.audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];

    self.audioSetting = [[self.audioOutput recommendedAudioSettingsForAssetWriterWithOutputFileType:AVFileTypeMPEG4] copy];
    
    return YES;
}

-(BOOL)_setupImageOutput:(NSError **)error{
    self.imageOutput = [[AVCaptureStillImageOutput alloc]init];
    NSDictionary *outputSetting = @{AVVideoCodecKey:AVVideoCodecJPEG};
    [_imageOutput setOutputSettings:outputSetting];
    if ([_captureSession canAddOutput:_imageOutput]) {
        [_captureSession addOutput:_imageOutput];
        return YES;
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.video" code:-2220005 userInfo:@{NSLocalizedDescriptionKey:@"device lock failed(output)"}];
        return NO;
    }
}

-(BOOL)_setupVideoInputOutput:(NSError **)error{

    //获取当前支持的设备
    self.currentDevice = [DKCameraManager _cameraWithPosition:_devicePostion];
    
    self.videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:_currentDevice error:error];
    if (_videoInput) {
        if ([_captureSession canAddInput:_videoInput]) {
            [_captureSession addInput:_videoInput];
        }else{
            *error = [NSError errorWithDomain:@"com.dingkan.captureservice.video" code:-2220000 userInfo:@{NSLocalizedDescriptionKey:@"add video input failed"}];
            return NO;
        }
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.video" code:-2220001 userInfo:@{NSLocalizedDescriptionKey:@"video input is NULL"}];
        return NO;
    }
    
    //稳定帧率
    CMTime frameDuration = CMTimeMake(1, _frameRate);
    if ([_currentDevice lockForConfiguration:error]) {
        _currentDevice.activeVideoMaxFrameDuration = frameDuration;
        _currentDevice.activeVideoMinFrameDuration = frameDuration;
        [_currentDevice unlockForConfiguration];
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.video" code:-2220003 userInfo:@{NSLocalizedDescriptionKey:@"device lock failed(input)"}];
        return NO;
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    _videoOutput.videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    //对迟到的帧做丢帧处理
    _videoOutput.alwaysDiscardsLateVideoFrames = NO;
    
    dispatch_queue_t videoQueue = dispatch_queue_create("com.dingkan.captureservice.video", DISPATCH_QUEUE_SERIAL);
    [_videoOutput setSampleBufferDelegate:self queue:videoQueue];
    
    if ([_captureSession canAddOutput:_videoOutput]) {
        [_captureSession addOutput:_videoOutput];
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.video" code:-2220003 userInfo:@{NSLocalizedDescriptionKey:@"device lock failed(outpur)"}];
        return NO;
    }
    
    self.videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //90°旋转问题
    if (_videoConnection.isVideoOrientationSupported) {
        _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    return YES;
}

-(BOOL)_setupFaceDataOutput:(NSError **)error{
    self.metadataOutput = [[AVCaptureMetadataOutput alloc]init];
    
    if ([_captureSession canAddOutput:_metadataOutput]) {
        [_captureSession addOutput:_metadataOutput];
        
        NSArray *metadataObjectTypes = @[AVMetadataObjectTypeFace];
        _metadataOutput.metadataObjectTypes = metadataObjectTypes;
        dispatch_queue_t metadataQueue = dispatch_queue_create("com.dingkan.captureservice.metadata", DISPATCH_QUEUE_SERIAL);
        [_metadataOutput setMetadataObjectsDelegate:self queue:metadataQueue];
        return YES;
    }else{
        *error = [NSError errorWithDomain:@"com.dingkan.captureservice.face" code:-2220009 userInfo:@{NSLocalizedDescriptionKey:@"add face output failed"}];
        return NO;
    }
}

-(void)setupGCDDispatchQueue{
    _sessionQueue = dispatch_queue_create("com.dingkan.captureservice.session", DISPATCH_QUEUE_SERIAL);
    _writtingQueue = dispatch_queue_create("com.caixindong.captureservice.write", DISPATCH_QUEUE_SERIAL);
    _outputQueue = dispatch_queue_create("com.caixindong.captureservice.output", DISPATCH_QUEUE_SERIAL);
}

-(void)setupDeviceSetting{
    _devicePostion = AVCaptureDevicePositionFront;
}

-(void)sertupVideoSetting{
    _frameRate = 30;
    _sessionPreset = AVCaptureSessionPresetMedium;
    _shouldRecordAudio = NO;
    NSDictionary *compressionproperties = @{
                                            AVVideoAverageBitRateKey:@(640 * 480 * 2.1),//视频尺寸比例
                                            AVVideoExpectedSourceFrameRateKey:@(30),//帧速率
                                            AVVideoMaxKeyFrameIntervalKey:@(30),//关键帧最大间隔
                                            AVVideoProfileLevelKey:AVVideoProfileLevelH264Main41,//基本画质
                                            };
    //宽高的设置影录制出来的视屏尺寸
    _videoSetting = @{
                      AVVideoCodecKey:AVVideoCodecH264,//264编码
                      AVVideoWidthKey:@(480),
                      AVVideoHeightKey:@(640),
                      AVVideoScalingModeKey:AVVideoScalingModeResizeAspect,//填充模式
                      AVVideoCompressionPropertiesKey:compressionproperties
                      };
}

// 2, 调用这个方法, 开启屏幕旋转监测
- (void)startMotionManager{
    if (self.manager == nil) {
        self.manager = [[CMMotionManager alloc] init];
    }
    // 刷新数据频率
    _manager.deviceMotionUpdateInterval = 1/30.0;
    
    // 判断设备的传感器是否可用
    if (_manager.deviceMotionAvailable) {
        NSLog(@"Device Motion Available");
        [_manager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
                                     withHandler: ^(CMDeviceMotion *motion, NSError*error){
                                         [self performSelectorOnMainThread:@selector(handleDeviceMotion:) withObject:motion waitUntilDone:YES];
                                     }];
    } else {
        NSLog(@"No device motion on device.");
        //通过通知获取方向
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
        _manager = nil;
    }
}

-(void)stopDeviceMotion{
    if (_manager.deviceMotionAvailable) {
        _manager = nil;
        [_manager stopAccelerometerUpdates];
    }
}

-(void)deviceOrientationDidChange{
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    if (deviceOrientation == UIDeviceOrientationPortrait){
        _orientation = AVCaptureVideoOrientationPortrait;
    }else if (deviceOrientation == UIDeviceOrientationPortraitUpsideDown){
        _orientation = AVCaptureVideoOrientationPortraitUpsideDown;
    }else if (deviceOrientation == UIDeviceOrientationLandscapeLeft){
        _orientation = AVCaptureVideoOrientationLandscapeRight;
    }else if (deviceOrientation == UIDeviceOrientationLandscapeRight){
        _orientation = AVCaptureVideoOrientationLandscapeLeft;
    }
}

- (void)handleDeviceMotion:(CMDeviceMotion *)deviceMotion{
    double x = deviceMotion.gravity.x;
    double y = deviceMotion.gravity.y;
    
    static BOOL portraitFlag_ = false;
    static BOOL landscapeLeftFlag_ = false;
    static BOOL landscapeRightFlag_ = false;
    static BOOL upsideDownFlag_ = false;
    
    if (fabs(y) >= fabs(x)) {
        if (y < 0) {
            if (portraitFlag_) {
                return;
            }
            portraitFlag_ = true;
            landscapeLeftFlag_ = false;
            landscapeRightFlag_ = false;
            upsideDownFlag_ = false;
            _orientation = AVCaptureVideoOrientationPortrait;
        }
        else {
            if (upsideDownFlag_) {
                return;
            }
            portraitFlag_ = false;
            landscapeLeftFlag_ = false;
            landscapeRightFlag_ = false;
            upsideDownFlag_ = true;
            _orientation = AVCaptureVideoOrientationPortraitUpsideDown;
        }
    }
    else {
        if (x < 0) {
            if (landscapeLeftFlag_) {
                return;
            }
            portraitFlag_ = false;
            landscapeLeftFlag_ = true;
            landscapeRightFlag_ = false;
            upsideDownFlag_ = false;
            _orientation = AVCaptureVideoOrientationLandscapeRight;
        }
        else {
            if (landscapeRightFlag_) {
                return;
            }
            portraitFlag_ = false;
            landscapeLeftFlag_ = false;
            landscapeRightFlag_ = true;
            upsideDownFlag_ = false;
            _orientation = AVCaptureVideoOrientationLandscapeLeft;
        }
    }
}


-(BOOL)isRecording{
    if (_videoWriter) {
        return _videoWriter.isWriting;
    }else{
        return NO;
    }
}

#pragma camera setting
-(CGFloat)deviceISO{
    return _currentDevice.ISO;
}

-(CGFloat)deviceMaxISO{
    return _currentDevice.activeFormat.maxISO;
}

-(CGFloat)deviceMinISO{
    return _currentDevice.activeFormat.minISO;
}

-(CGFloat)devieAperture{
    return _currentDevice.lensAperture;
}

-(AVCaptureExposureMode)exposureMode{
    return _currentDevice.exposureMode;
}

-(void)setExposureMode:(AVCaptureExposureMode)exposureMode{

    [DKCameraManager setCameraExposureMode:exposureMode device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

-(void)setExposurePoint:(CGPoint)exposurePoint{
    [DKCameraManager setCameraExposurePoint:exposurePoint device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

-(CMTime)deviceExposureDuration{
    return _currentDevice.exposureDuration;
}

-(AVCaptureFocusMode)focusMode{
    return _currentDevice.focusMode;
}

-(AVCaptureWhiteBalanceMode)whiteBalanceMode{
    return _currentDevice.whiteBalanceMode;
}

-(void)setWhiteBalanceMode:(AVCaptureWhiteBalanceMode)whiteBalanceMode{
    [DKCameraManager setCameraWhiteBalanceMode:whiteBalanceMode device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

-(void)setFocusMode:(AVCaptureFocusMode)focusMode{
    [DKCameraManager setCameraFocusMode:focusMode device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

-(void)setFocusPoint:(CGPoint)focusPoint{
    [DKCameraManager setCameraFocusPoint:focusPoint device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

-(BOOL)supportsTapToFocus{
    return [_currentDevice isFocusPointOfInterestSupported];
}

-(BOOL)supportsTapToExpose{
    return [_currentDevice isExposurePointOfInterestSupported];
}

-(BOOL)hasTorch{
    return _currentDevice.hasTorch;
}

-(BOOL)hasFlash{
    return _currentDevice.hasFlash;
}

-(AVCaptureTorchMode)torchMode{
    return _currentDevice.torchMode;
}

-(void)setTorchMode:(AVCaptureTorchMode)torchMode{
    [DKCameraManager setCameraTorchMode:torchMode device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

-(AVCaptureFlashMode)flashMode{
    return _currentDevice.flashMode;
}

-(void)setFlashMode:(AVCaptureFlashMode)flashMode{
    [DKCameraManager setCameraFlashMode:flashMode device:_currentDevice complete:^(BOOL isSuccess, NSError * _Nonnull error) {
        if (!isSuccess) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(captureService:serviceDidFailedWithError:)]) {
                [self.delegate captureService:self serviceDidFailedWithError:error];
            }
        }
    }];
}

@end

