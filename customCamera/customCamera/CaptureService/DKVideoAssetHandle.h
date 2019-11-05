//
//  DKVideoAssetHandle.h
//  customCamera
//
//  Created by dingkan on 2019/11/2.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKVideoAssetHandle : NSObject

+(UIImage *)getImgWithAsset:(AVURLAsset *)asset;

@end

NS_ASSUME_NONNULL_END
