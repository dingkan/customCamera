//
//  DKViedoWritter.h
//  customCamera
//
//  Created by dingkan on 2019/11/1.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

@class DKViedoWritter;

@protocol DKViedoWritterDelegate <NSObject>

-(void)videoWriter:(DKViedoWritter *_Nonnull)writer didFailWithError:(NSError *_Nonnull)error;

-(void)videoWriter:(DKViedoWritter *_Nonnull)writer completeWriting:(NSError *_Nonnull)error;
@end

NS_ASSUME_NONNULL_BEGIN

@interface DKViedoWritter : NSObject

@property (nonatomic, assign, readonly) BOOL isWriting;

@property (nonatomic, weak) id<DKViedoWritterDelegate> delegate;

-(instancetype)initWithURL:(NSURL *)URL videoSettings:(NSDictionary *)videoSetting audioSetting:(NSDictionary *)audioSetting;

-(void)startWritting;

-(void)cancleWriting;

-(void)stopWtiringAsyn;

-(void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer;

+(BOOL)clearVideoFile:(NSString *)commponent error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
