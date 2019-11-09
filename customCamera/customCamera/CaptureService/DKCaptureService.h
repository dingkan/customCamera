//
//  DKCaptureService.h
//  customCamera
//
//  Created by dingkan on 2019/11/1.
//  Copyright © 2019年 dingkan. All rights reserved.
// 

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@class DKCaptureService;


NS_ASSUME_NONNULL_BEGIN

@protocol DKCaptureServicePreViewSource <NSObject>
-(AVCaptureVideoPreviewLayer *)preViewLayerSource;
@end

@protocol DKCaptureServiceDelegate <NSObject>
// CaptureService 生命周期
-(void)captureServiceDidStartService:(DKCaptureService *)service;

-(void)captureServiceDidStopService:(DKCaptureService *)service;

-(void)captureService:(DKCaptureService *)service serviceDidFailedWithError:(NSError *)error;

-(void)captureService:(DKCaptureService *)service getPreViewLayer:(AVCaptureVideoPreviewLayer *)preViewLayer;

-(void)captureService:(DKCaptureService *)service outputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

//人脸检测
-(void)captureService:(DKCaptureService *)service outputFaceDetectData:(NSArray <AVMetadataFaceObject *>*)faces;

//录像相关
-(void)caputreServiceRecorderDidStart:(DKCaptureService *)service;

-(void)caputreServiceRecorderDidCancel:(DKCaptureService *)servie;

-(void)captureServiceRecorderDidStop:(DKCaptureService *)service;

-(void)captureServiceRecorderDidStop:(DKCaptureService *)service asset:(AVURLAsset *)asset;

-(void)captureService:(DKCaptureService *)service recorderDidFailWithError:(NSError *)error;

//照片捕获
-(void)captureServie:(DKCaptureService *)servie capturePhoto:(UIImage *)photo;

//景深数据
-(void)captureService:(DKCaptureService *)servie captureTrueDepth:(AVDepthData *)depthData API_AVAILABLE(ios(11.0));

@end

@interface DKCaptureService : NSObject

@property (nonatomic, weak) id<DKCaptureServiceDelegate> delegate;

@property (nonatomic, weak) id<DKCaptureServicePreViewSource> preViewSource;

@property (nonatomic, assign, readonly) BOOL isRunning;

//录像的临时存放地址，建议每次录完视频做下重定向
@property (nonatomic, strong, readonly) NSURL *recordURL;

//分辨率
//只有一下指定的sessionPreset才有depth数据：AVCaptureSessionPresetPhoto、AVCaptureSessionPreset1280x720、AVCaptureSessionPreset640x480
@property (nonatomic, strong) AVCaptureSessionPreset sessionPreset;

@property (nonatomic, strong) NSDictionary *videoSetting;

//摄像头反向，默认front
@property (nonatomic, assign) AVCaptureDevicePosition devicePostion;

//帧率
@property (nonatomic, assign) int frameRate;

//是否录制音频。默认为NO
@property (nonatomic, assign) BOOL shouldRecordAudio;

//是否开启深景模式。默认为NO
@property (nonatomic, assign) BOOL openDepth;

//iOS原生人脸检测，默认为NO
@property (nonatomic, assign) BOOL openNativeFaceDetect;

//判断是否支持景深模式，当前只支持7p、8p、X的后知摄像头以及X的前后摄像头，系统要求iOS11以上
@property (nonatomic, assign, readonly) BOOL depthSupported;

@property (nonatomic, assign, readonly) BOOL isRecording;

//光感度(iOS8 以上)
@property (nonatomic, assign, readonly) CGFloat deviceISO;
@property (nonatomic, assign, readonly) CGFloat deviceMinISO;
@property (nonatomic, assign, readonly) CGFloat deviceMaxISO;

//镜头光圈大小
@property (nonatomic, assign, readonly) CGFloat devieAperture;

//曝光
@property (nonatomic, assign, readonly) BOOL supportsTapToExpose;
//曝光亮度调节
@property (nonatomic, assign) AVCaptureExposureMode exposureMode;
//曝光点
@property (nonatomic, assign) CGPoint exposurePoint;
//曝光时间
@property (nonatomic, assign, readonly) CMTime deviceExposureDuration;

//聚焦
@property (nonatomic, assign, readonly) BOOL supportsTapToFocus;
@property (nonatomic, assign) AVCaptureFocusMode focusMode;
@property (nonatomic, assign) CGPoint focusPoint;

//白平衡
@property (nonatomic, assign) AVCaptureWhiteBalanceMode whiteBalanceMode;

//手电筒
@property (nonatomic, assign, readonly) BOOL hasTorch;
@property (nonatomic, assign) AVCaptureTorchMode torchMode;

//闪光灯
@property (nonatomic, assign, readonly) BOOL hasFlash;
@property (nonatomic, assign) AVCaptureFlashMode flashMode;

//缩放因子
@property (nonatomic, assign) CGFloat factor;

//切换摄像机
-(void)switchCamera;

//启动
-(void)startRunning;

//关闭
-(void)stopRunning;

//开始录像
-(void)startRecording;

//取消录像
-(void)cancleRecording;

//停止录像
-(void)stopRecording;

//拍照
-(void)capturePhoto;

@end

NS_ASSUME_NONNULL_END
