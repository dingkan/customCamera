//
//  DKCameraManager.m
//  customCamera
//
//  Created by dingkan on 2019/11/2.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKCameraManager.h"
#import <Foundation/Foundation.h>

@implementation DKCameraManager

//根据方向获取设备
+(AVCaptureDevice *)_cameraWithPosition:(AVCaptureDevicePosition)position{
    if (@available(iOS 10.0, *)) {
        //默认AVCaptureDeviceTypeBuiltInWideAngleCamera广角摄像头，AVCaptureDeviceTypeBuiltInTelephotoCamera 长焦摄像头
        NSMutableArray *mulArr = [NSMutableArray arrayWithObjects:AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, nil];
        if (@available(iOS 10.2, *)) {
            [mulArr addObject:AVCaptureDeviceTypeBuiltInDualCamera];//后置双摄像头
        }
        if (@available(iOS 11.1, *)) {
            [mulArr addObject:AVCaptureDeviceTypeBuiltInTrueDepthCamera];//红外前置摄像头
        }
        AVCaptureDeviceDiscoverySession *discoverySession = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:[mulArr copy] mediaType:AVMediaTypeVideo position:position];
        return discoverySession.devices.firstObject;
    }else{
        
        NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
        for (AVCaptureDevice *device in videoDevices) {
            if (device.position == position) {
                return device;
                break;
            }
        }
    }
    return nil;
}

//获取可用设备
+(AVCaptureDevice *)_incativeCameraWithPosition:(AVCaptureDevicePosition)position{
    AVCaptureDevice *device = nil;
    if (position == AVCaptureDevicePositionBack) {
        device = [self _cameraWithPosition:AVCaptureDevicePositionFront];
    }else{
        device = [self _cameraWithPosition:AVCaptureDevicePositionBack];
    }
    return device;
}

+(void)switchCameraWithPosition:(AVCaptureDevicePosition)position session:(AVCaptureSession *)session currentInput:(AVCaptureDeviceInput *)input connection:(AVCaptureConnection *)connection output:(AVCaptureOutput *)output complete:(void(^)(AVCaptureDeviceInput *input, AVCaptureDevicePosition currentPosition))complete{
    NSError *error = nil;
    AVCaptureDevice *videoDevice = [self _incativeCameraWithPosition:position];
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];

    if (videoInput) {
        [session beginConfiguration];
        [session removeInput:input];
        
        if ([session canAddInput:videoInput]) {
            [session addInput:videoInput];
            //切换镜头videoConnection会变化，所以需要重新获取
            connection = [output connectionWithMediaType:AVMediaTypeVideo];
            if (connection.isVideoOrientationSupported) {
                connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            }
        }else{
            [session addInput:videoInput];
        }
        [session commitConfiguration];
        AVCaptureDevicePosition newPosition = position == AVCaptureDevicePositionFront ? AVCaptureDevicePositionBack : AVCaptureDevicePositionFront;
        !complete?:complete(videoInput, newPosition);
    }else{
        !complete?:complete(input, position);
    }
}


/**
 相机设置曝光模式
 */
+(void)setCameraExposureMode:(AVCaptureExposureMode)exposureMode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
            device.exposureMode = exposureMode;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            [device unlockForConfiguration];
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220011 userInfo:@{NSLocalizedDescriptionKey:@"device no support exposureModel"}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError  = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220012 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
        !complete?:complete(NO, nError);
    }
}


/**
 相机设置曝光点
 */
+(void)setCameraExposurePoint:(CGPoint)point device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
            device.exposureMode = AVCaptureExposureModeAutoExpose;
            device.exposurePointOfInterest = point;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            [device unlockForConfiguration];
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220021 userInfo:@{NSLocalizedDescriptionKey:@"device no support exposurePointOfInterest"}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220022 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
        !complete?:complete(NO, nError);
    }
}

/**
 设置聚焦模式
 */
+(void)setCameraFocusMode:(AVCaptureFocusMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:mode]) {
            device.focusMode = mode;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            [device unlockForConfiguration];
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220031 userInfo:@{NSLocalizedDescriptionKey:@"device no support exposurePointOfInterest"}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220032 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
        !complete?:complete(NO, nError);
    }
}


/**
 设置聚焦点
 */
+(void)setCameraFocusPoint:(CGPoint)point device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            device.focusMode = AVCaptureFocusModeAutoFocus;
            device.focusPointOfInterest = point;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            [device unlockForConfiguration];
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220041 userInfo:@{NSLocalizedDescriptionKey:@"device no support focusPointOfInterest"}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220042 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
        !complete?:complete(NO, nError);
    }
}



/**
 设置白平衡
 */
+(void)setCameraWhiteBalanceMode:(AVCaptureWhiteBalanceMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if ([device isWhiteBalanceModeSupported:mode]) {
            device.whiteBalanceMode = mode;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            [device unlockForConfiguration];
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220041 userInfo:@{NSLocalizedDescriptionKey:@"device no support whiteBalanceMode"}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220042 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
        !complete?:complete(NO, nError);
    }
}


/**
 设置手电筒
 */
+(void)setCameraTorchMode:(AVCaptureTorchMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    if (device.torchMode != mode && [device isTorchModeSupported:mode]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.torchMode = mode;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220052 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220052 userInfo:@{NSLocalizedDescriptionKey:@"device no support touch"}];
        !complete?:complete(NO, nError);
    }
}

/**
 设置闪光灯
 */
+(void)setCameraFlashMode:(AVCaptureFlashMode)mode device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    if (device.flashMode != mode && [device isFlashModeSupported:mode]) {
        NSError *error = nil;
        if ([device lockForConfiguration:&error]) {
            device.flashMode = mode;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220062 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220062 userInfo:@{NSLocalizedDescriptionKey:@"device no support flash"}];
        !complete?:complete(NO, nError);
    }
}

/**
 设置缩放因子
 */
+(void)setCameraVideoZoomFactor:(CGFloat)factor device:(AVCaptureDevice *)device complete:(void(^)(BOOL isSuccess, NSError *error))complete{
    NSError *error = nil;
    if ([device lockForConfiguration:&error]) {
        if (device.isRampingVideoZoom) {
            factor = MAX(MIN(factor, device.activeFormat.videoMaxZoomFactor), 1.0);
            device.videoZoomFactor = factor;
            [device unlockForConfiguration];
            !complete?:complete(YES, nil);
        }else{
            [device unlockForConfiguration];
            NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220041 userInfo:@{NSLocalizedDescriptionKey:@"device no support isRampingVideoZoom"}];
            !complete?:complete(NO, nError);
        }
    }else{
        [device unlockForConfiguration];
        NSError *nError = [NSError errorWithDomain:@"com.dingkan.captureservice.CameraSet" code:-2220042 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"device lock configuration error: %@",error.localizedDescription]}];
        !complete?:complete(NO, nError);
    }
}

@end
