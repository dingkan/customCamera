//
//  DKSpeechConfig.h
//  customCamera
//
//  Created by dingkan on 2019/11/9.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DKSpeechConfig : NSObject
//支持语言
@property (nonatomic, strong) NSString *Language;

//语速 Values are pinned between AVSpeechUtteranceMinimumSpeechRate and AVSpeechUtteranceMaximumSpeechRate.
@property (nonatomic, assign) float rate;

//音调  [0.5 - 2] Default = 1
@property (nonatomic, assign) float pitchMultiplier;

//音量 [0-1] Default = 1
@property (nonatomic, assign) float volume;

//播放下一句话延迟时间
@property (nonatomic, assign) NSTimeInterval preUtteranceDelay;

//开始播放之前等待时间
@property (nonatomic, assign) NSTimeInterval postUtteranceDelay;


+(instancetype)defaultConfig;

@end

NS_ASSUME_NONNULL_END
