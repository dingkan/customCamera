//
//  DKAudioPlayerManager.h
//  customCamera
//
//  Created by dingkan on 2019/11/9.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <Foundation/Foundation.h>
@class DKAudioPlayerManager;
NS_ASSUME_NONNULL_BEGIN

@protocol DKAudioPlayerManagerDelegate <NSObject>
-(void)DKAudioPlayerManagerDidFailedWithError:(NSError *)error target:(DKAudioPlayerManager *)target;
-(void)DKAudioPlayerManagerPlayBackStoppedWithTarget:(DKAudioPlayerManager *)target;
-(void)DKAudioPlayerManagerPlayBackBeginWithTarget:(DKAudioPlayerManager *)target;
@end

@interface DKAudioPlayerManager : NSObject
@property (nonatomic, getter=isPlaying) BOOL isPlaying;
-(void)play;
-(void)pause;
-(void)stop;
-(void)adjustPan:(float)pan;
-(void)adjustVolume:(float)volume;
- (void)adjustRate:(float)rate;

-(instancetype)initWithFileName:(NSString *)fileName delegate:(id<DKAudioPlayerManagerDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
