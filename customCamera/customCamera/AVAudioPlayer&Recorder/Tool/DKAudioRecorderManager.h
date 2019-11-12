//
//  DKAudioRecorderManager.h
//  customCamera
//
//  Created by dingkan on 2019/11/11.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <Foundation/Foundation.h>
@protocol DKAudioRecorderManagerDelegate <NSObject>
-(void)DKAudioRecorderManagerDidFailedWithError:(NSError *)error;
-(void)DKAudioRecorderManagerBeginInterruption;
-(void)DKAudioRecorderManagerEndInterruption;
@end

NS_ASSUME_NONNULL_BEGIN

@interface DKAudioRecorderManager : NSObject
+(instancetype)sharedInstance;

- (BOOL)record;
- (void)pause;
- (void)stop;
-(NSTimeInterval)formattedCurrentTime;

-(void)saveRecorderingWithName:(NSString *)name complete:(void(^)(NSString *filePath))complete;

@end

NS_ASSUME_NONNULL_END
