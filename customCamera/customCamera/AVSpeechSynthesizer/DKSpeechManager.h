//
//  DKSpeechManager.h
//  customCamera
//
//  Created by dingkan on 2019/11/9.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DKSpeechConfig.h"
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol DKSpeechManagerDelegate <NSObject>
-(void)DKSpeechManagerDidFailedError:(NSError *)error;
- (void)DKSpeechManagerDidStartSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14));
- (void)DKSpeechManagerDidFinishSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14));
- (void)DKSpeechManagerDidPauseSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14));
- (void)DKSpeechManageridContinueSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14));
- (void)DKSpeechManagerDidCancelSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14));
- (void)DKSpeechManagerWillSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14));
@end

@interface DKSpeechManager : NSObject

+(instancetype)sharedInstance;

-(void)speechManagerWithConfig:(DKSpeechConfig *)config speakString:(NSString *)speakString delegate:(id<DKSpeechManagerDelegate>)delegate;

-(void)speechManagerWithConfig:(DKSpeechConfig *)config speakStrings:(NSArray<NSString *> *)speakStrings delegate:(id<DKSpeechManagerDelegate>)delegate;

-(void)speak;

- (BOOL)stopSpeakingAtBoundary:(AVSpeechBoundary)boundary;

- (BOOL)pauseSpeakingAtBoundary:(AVSpeechBoundary)boundary;

- (BOOL)continueSpeaking;

@end

NS_ASSUME_NONNULL_END
