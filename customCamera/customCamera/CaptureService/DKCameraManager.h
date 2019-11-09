//
//  DKCameraManager.h
//  customCamera
//
//  Created by dingkan on 2019/11/2.
//  Copyright © 2019年 dingkan. All rights reserved.
//  相机设置

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKCameraManager : NSObject

//根据方向获取设备
+(AVCaptureDevice *)_cameraWithPosition:(AVCaptureDevicePosition)position;

//获取可用设备
+(AVCaptureDevice *)_incativeCameraWithPosition:(AVCaptureDevicePosition)position;

//转换摄像头
+(void)switchCameraWithPosition:(AVCaptureDevicePosition)position session:(AVCaptureSession *)session currentInput:(AVCaptureDeviceInput *)input connection:(AVCaptureConnection *)connection output:(AVCaptureOutput *)output complete:(void(^)(AVCaptureDeviceInput *input, AVCaptureDevicePosition currentPosition))complete;


/**
 相机设置曝光模式
 */
+(void)setCameraExposureMode:(AVCaptureExposureMode)exposureMode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 相机设置曝光点
 */
+(void)setCameraExposurePoint:(CGPoint)point device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 设置聚焦模式
 */
+(void)setCameraFocusMode:(AVCaptureFocusMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 设置聚焦点
 */
+(void)setCameraFocusPoint:(CGPoint)point device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 设置白平衡
 */
+(void)setCameraWhiteBalanceMode:(AVCaptureWhiteBalanceMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 设置手电筒
 */
+(void)setCameraTorchMode:(AVCaptureTorchMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 设置闪光灯
 */
+(void)setCameraFlashMode:(AVCaptureFlashMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;

/**
 设置缩放因子
 */
+(void)setCameraVideoZoomFactor:(CGFloat)factor device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete;



@end

NS_ASSUME_NONNULL_END
