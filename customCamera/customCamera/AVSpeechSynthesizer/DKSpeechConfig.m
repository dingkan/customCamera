//
//  DKSpeechConfig.m
//  customCamera
//
//  Created by dingkan on 2019/11/9.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKSpeechConfig.h"

@implementation DKSpeechConfig
-(instancetype)init{
    if (self = [super init]) {
        _Language = @"zh-CN";
        _rate = 0.5;
        _pitchMultiplier = 1.0;
        _volume = 0.5;
        _postUtteranceDelay = 0.5;
        _preUtteranceDelay = 0.5;
    }
    return self;
}


+(instancetype)defaultConfig{
    return [[DKSpeechConfig alloc]init];
}

@end
