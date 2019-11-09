//
//  DKAudioPlayerManager.m
//  customCamera
//
//  Created by dingkan on 2019/11/9.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKAudioPlayerManager.h"
#import <AVFoundation/AVFoundation.h>

@interface DKAudioPlayerManager()<AVAudioPlayerDelegate>
@property (nonatomic, strong)AVAudioPlayer *player;
@property (nonatomic, weak) id<DKAudioPlayerManagerDelegate> delegate;

@end

@implementation DKAudioPlayerManager

-(instancetype)initWithFileName:(NSString *)fileName delegate:(id<DKAudioPlayerManagerDelegate>)delegate{
    if (self = [super init]) {
        self.delegate = delegate;
        self.player = [self playerWithFile:fileName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeRate:) name:AVAudioSessionRouteChangeNotification object:[AVAudioSession sharedInstance]];
    }
    return self;
}

#pragma AVAudioPlayerDelegate
/* audioPlayerBeginInterruption: is called when the audio session has been interrupted while the player was playing. The player will have been paused. */
- (void)audioPlayerBeginInterruption:(AVAudioPlayer *)player{
    [self stop];
    if ([self.delegate respondsToSelector:@selector(DKAudioPlayerManagerPlayBackStoppedWithTarget:)]) {
        [self.delegate DKAudioPlayerManagerPlayBackStoppedWithTarget:self];
    }
}


/* audioPlayerEndInterruption: is called when the preferred method, audioPlayerEndInterruption:withFlags:, is not implemented. */
- (void)audioPlayerEndInterruption:(AVAudioPlayer *)player withOptions:(NSUInteger)flags{
    if (flags == AVAudioSessionInterruptionOptionShouldResume) {
        [self play];
        if ([self.delegate respondsToSelector:@selector(DKAudioPlayerManagerPlayBackBeginWithTarget:)]) {
            [self.delegate DKAudioPlayerManagerPlayBackBeginWithTarget:self];
        }
    }
}


-(void)play{
    if (!self.isPlaying) {
        NSTimeInterval time = self.player.deviceCurrentTime + 0.01;
        [self.player playAtTime:time];
        self.isPlaying = YES;
    }
}

-(void)pause{
    if (self.isPlaying) {
        [self.player pause];
    }
}

-(void)stop{
    if (self.isPlaying) {
        [self.player stop];
        self.player.currentTime = 0.0f;
        self.isPlaying = NO;
    }
}

-(void)adjustPan:(float)pan{
    self.player.pan = pan;
}

-(void)adjustVolume:(float)volume{
    self.player.volume = volume;
}

- (void)adjustRate:(float)rate{
    self.player.rate = rate;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(AVAudioPlayer *)playerWithFile:(NSString *)file{
    NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:file withExtension:@"caf"];
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc]initWithContentsOfURL:fileUrl error:&error];
    if (player) {
        //无限循环
        player.numberOfLoops = -1;
        player.delegate = self;
        //循序修改倍速
        player.enableRate = YES;
        [player prepareToPlay];
    }else{
        if ([self.delegate respondsToSelector:@selector(DKAudioPlayerManagerDidFailedWithError:target:)]) {
            [self.delegate DKAudioPlayerManagerDidFailedWithError:error target:self];
        }
    }
    return player;
}

-(void)didChangeRate:(NSNotification *)noti{
    NSDictionary *userInfo = noti.userInfo;
    //AVAudioSessionInterruptionTypeKey 确认系统中断类型
    //来电、QQ微信语音、其他音乐软件暂停
    AVAudioSessionInterruptionType reason = [userInfo[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    
    //中断开始
    if (reason == AVAudioSessionInterruptionTypeBegan) {
        if (self.isPlaying) {
            [self stop];
            if ([self.delegate respondsToSelector:@selector(DKAudioPlayerManagerPlayBackStoppedWithTarget:)]) {
                [self.delegate DKAudioPlayerManagerPlayBackStoppedWithTarget:self];
            }
        }
    }else if (reason == AVAudioSessionInterruptionTypeEnded){
        //中断结束
        if (!self.isPlaying) {
            [self play];
            if ([self.delegate respondsToSelector:@selector(DKAudioPlayerManagerPlayBackBeginWithTarget:)]) {
                [self.delegate DKAudioPlayerManagerPlayBackBeginWithTarget:self];
            }
        }
    }
    
    //线路切换监听
    AVAudioSessionRouteChangeReason reason1 = [userInfo[AVAudioSessionRouteChangeReasonKey] unsignedIntegerValue];
    //旧音频设备中断原因
    if (reason1 == AVAudioSessionRouteChangeReasonOldDeviceUnavailable) {
        //线路描述信息
        AVAudioSessionRouteDescription *previousRoute = userInfo[AVAudioSessionRouteChangePreviousRouteKey];
        //第一个输出接口并判断是否是耳机接口
        AVAudioSessionPortDescription *previousOutput = previousRoute.outputs[0];
        NSString *portType = previousOutput.portType;
        if ([portType isEqualToString:AVAudioSessionPortHeadphones]) {
            [self stop];
            //输出到有线耳机
            if ([self.delegate respondsToSelector:@selector(DKAudioPlayerManagerPlayBackStoppedWithTarget:)]) {
                [self.delegate DKAudioPlayerManagerPlayBackStoppedWithTarget:self];
            }
        }
    }
}
@end

