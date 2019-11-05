//
//  DKVideoAssetHandle.m
//  customCamera
//
//  Created by dingkan on 2019/11/2.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKVideoAssetHandle.h"

@implementation DKVideoAssetHandle

+(UIImage *)getImgWithAsset:(AVURLAsset *)asset{
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc]initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    CMTime actualTime;
    CGImageRef imgRef = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:nil];
    UIImage *temp = [[UIImage alloc]initWithCGImage:imgRef];
    CGImageRelease(imgRef);
    return temp;
}

@end
