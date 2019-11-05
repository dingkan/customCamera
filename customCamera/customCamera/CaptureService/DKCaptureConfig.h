//
//  DKCaptureConfig.h
//  customCamera
//
//  Created by dingkan on 2019/11/4.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKCaptureConfig : NSObject
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

//曝光亮度调节
@property (nonatomic, assign) AVCaptureExposureMode exposureMode;
//曝光点
@property (nonatomic, assign) CGPoint exposurePoint;

@property (nonatomic, assign) AVCaptureFocusMode focusMode;

@property (nonatomic, assign) CGPoint focusPoint;

//白平衡
@property (nonatomic, assign) AVCaptureWhiteBalanceMode whiteBalanceMode;

@property (nonatomic, assign) AVCaptureTorchMode torchMode;

@property (nonatomic, assign) AVCaptureFlashMode flashMode;
//缩放因子
@property (nonatomic, assign) CGFloat factor;
@end

NS_ASSUME_NONNULL_END
