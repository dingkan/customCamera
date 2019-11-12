//
//  DKAudioRecorderManager.m
//  customCamera
//
//  Created by dingkan on 2019/11/11.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKAudioRecorderManager.h"
#import <AVFoundation/AVFoundation.h>

@interface DKAudioRecorderManager()<AVAudioRecorderDelegate>
@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, weak) id<DKAudioRecorderManagerDelegate> delegate;
@property (nonatomic, strong) void(^stopBlock)(void);
@property (nonatomic, strong) void(^finishBlock)(NSString *url);
@end

@implementation DKAudioRecorderManager

static DKAudioRecorderManager * _shared;
+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[DKAudioRecorderManager alloc] init];
    });
    return _shared;
}

-(instancetype)init{
    if (self = [super init]) {

        NSURL *url = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@"memo.caf"]];
        NSDictionary *settings = @{
                                   AVFormatIDKey: @(kAudioFormatAppleIMA4),
                                   AVSampleRateKey:@441000.0f,
                                   AVNumberOfChannelsKey:@1,
                                   AVEncoderBitDepthHintKey:@16,
                                   AVEncoderAudioQualityKey:@(AVAudioQualityMedium)
                                   };
        NSError *error = nil;
        self.recorder = [[AVAudioRecorder alloc]initWithURL:url settings:settings error:&error];
        if (self.recorder) {
            self.recorder.delegate = self;
            self.recorder.meteringEnabled = YES;
            [self.recorder prepareToRecord];
        }else{
            if (self.delegate && [self.delegate respondsToSelector:@selector(DKAudioRecorderManagerDidFailedWithError:)]) {
                [self.delegate DKAudioRecorderManagerDidFailedWithError:error];
            }
        }
    }
    return self;
}

- (BOOL)record{
    return [self.recorder record];
}

- (void)pause{
    [self.recorder pause];
}

- (void)stop{
    [self.recorder stop];
    !self.stopBlock?:self.stopBlock();
}

-(void)saveRecorderingWithName:(NSString *)name complete:(void(^)(NSString *filePath))complete{
    NSTimeInterval timestamp = [NSDate timeIntervalSinceReferenceDate];
    NSString *fileName = [NSString stringWithFormat:@"%@-%f.m4a",name, timestamp];
    NSString *destPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:fileName];
    
    NSURL *scrUrl = self.recorder.url;
    NSError *error = nil;
    
    NSData *scrData = [NSData dataWithContentsOfURL:scrUrl];
    BOOL isSuccess = [scrData writeToFile:destPath atomically:YES];
    if (isSuccess) {
        !complete?:complete(destPath);
        [self.recorder prepareToRecord];
    }else{
        if (self.delegate && [self.delegate respondsToSelector:@selector(DKAudioRecorderManagerDidFailedWithError:)]) {
            [self.delegate DKAudioRecorderManagerDidFailedWithError:error];
        }
    }
}

-(NSTimeInterval)formattedCurrentTime{
    return self.recorder.currentTime;
}

#pragma AVAudioRecorderDelegate
/* audioRecorderDidFinishRecording:successfully: is called when a recording has been finished or stopped. This method is NOT called if the recorder is stopped due to an interruption. */
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag{
    !self.finishBlock?:self.finishBlock(recorder.url.absoluteString);
}

/* if an error occurs while encoding it will be reported to the delegate. */
- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error{
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKAudioRecorderManagerDidFailedWithError:)]) {
        [self.delegate DKAudioRecorderManagerDidFailedWithError:error];
    }
}
/* audioRecorderBeginInterruption: is called when the audio session has been interrupted while the recorder was recording. The recorded file will be closed. */
- (void)audioRecorderBeginInterruption:(AVAudioRecorder *)recorder{
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKAudioRecorderManagerBeginInterruption)]) {
        [self.delegate DKAudioRecorderManagerBeginInterruption];
    }
}

- (void)audioRecorderEndInterruption:(AVAudioRecorder *)recorder withOptions:(NSUInteger)flags{
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(DKAudioRecorderManagerEndInterruption)]) {
        [self.delegate DKAudioRecorderManagerEndInterruption];
    }
}

@end

