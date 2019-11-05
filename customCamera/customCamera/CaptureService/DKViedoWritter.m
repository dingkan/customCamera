//
//  DKViedoWritter.m
//  customCamera
//
//  Created by dingkan on 2019/11/1.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKViedoWritter.h"

@interface DKViedoWritter()

@property (nonatomic, strong) AVAssetWriter *assetWriter;

@property (nonatomic, strong) NSURL *outputURL;

@property (nonatomic, strong) NSDictionary *videoSetting;

@property (nonatomic, strong) AVAssetWriterInput *videoInput;

@property (nonatomic, strong) AVAssetWriterInput *audioInput;

@property (nonatomic, strong) NSDictionary *audioSetting;

@property (nonatomic, assign) BOOL isWritting;

@property (nonatomic, assign) BOOL firstSample;

@end

@implementation DKViedoWritter

-(instancetype)initWithURL:(NSURL *)URL videoSettings:(NSDictionary *)videoSetting audioSetting:(NSDictionary *)audioSetting{
    if (self = [super init]) {
        _outputURL = URL;
        _videoSetting = videoSetting;
        _audioSetting = audioSetting;
        _isWriting = NO;
        _firstSample = YES;
    }
    return self;
}

-(void)dealloc{
    NSLog(@" -------  DKViedoWritter  dealloc  -------");
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
}

-(void)startWritting{
    if (_assetWriter) {
        _assetWriter = nil;
    }
    
    NSError *error = nil;
    NSString *fileType = AVFileTypeMPEG4;
    
    _assetWriter = [[AVAssetWriter alloc] initWithURL:_outputURL fileType:fileType error:&error];
    
    if (!_assetWriter || error) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
            [self.delegate videoWriter:self didFailWithError:error];
        }
    }
    
    if (_videoSetting) {
        _videoInput = [[AVAssetWriterInput alloc]initWithMediaType:AVMediaTypeVideo outputSettings:_videoSetting];
        _videoInput.expectsMediaDataInRealTime = YES;
        if ([_assetWriter canAddInput:_videoInput]) {
            [_assetWriter addInput:_videoInput];
        }else{
            NSError *error = [NSError errorWithDomain:@"com.dingkan.captureservice.writter" code:-2221000 userInfo:@{NSLocalizedDescriptionKey:@"VideoWritter unable to add video input"}];
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
                [self.delegate videoWriter:self didFailWithError:error];
            }
            return;
        }
    }else{
        NSLog(@"warning: no video setting");
    }
    
    if (_audioSetting) {
        _audioInput = [[AVAssetWriterInput alloc]initWithMediaType:AVMediaTypeAudio outputSettings:_audioSetting];
        _audioInput.expectsMediaDataInRealTime = YES;
        
        if ([_assetWriter canAddInput:_audioInput]) {
            [_assetWriter addInput:_audioInput];
        }else{
            NSError *error = [NSError errorWithDomain:@"com.dingkan.captureservice.writter" code:-2221001 userInfo:@{NSLocalizedDescriptionKey:@"VideoWritter unable to add audio input"}];
            if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
                [self.delegate videoWriter:self didFailWithError:error];
            }
            return;
        }
    }else{
        NSLog(@"waring: no audio setting");
    }
    
    
    if ([_assetWriter startWriting]) {
        _isWriting = YES;
    }else{
        NSError *error = [NSError errorWithDomain:@"com.dingkan.captureservice.writter" code:-2221002 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"VideoWritter startWriting fail error: %@",_assetWriter.error.localizedDescription]}];
        if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
            [self.delegate videoWriter:self didFailWithError:error];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_assetWrtterInteruptedNotification:) name:AVCaptureSessionWasInterruptedNotification object:nil];
}

-(void)_assetWrtterInteruptedNotification:(NSNotification *)notification{
    NSLog(@"AVCaptureSessionWasInterruptedNotification");
    [self cancleWriting];
}

-(void)cancleWriting{
    if (_assetWriter.status == AVAssetWriterStatusWriting && _isWriting == YES) {
        [_assetWriter cancelWriting];
        _isWriting = NO;
    }else{
        NSLog(@"warning : cancle writing with unsuitable state: %ld",(long)_assetWriter.status);
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
}

-(void)stopWtiringAsyn{
    if (_assetWriter.status == AVAssetWriterStatusWriting && _isWriting == YES) {
        _isWriting = NO;
        [_assetWriter finishWritingWithCompletionHandler:^{
            if (self.assetWriter.status == AVAssetWriterStatusCompleted) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:completeWriting:)]) {
                    [self.delegate videoWriter:self completeWriting:nil];
                }
            }else{
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
                    [self.delegate videoWriter:self didFailWithError:self.assetWriter.error];
                }
            }
        }];
    }else{
        NSLog(@"warning: stop writing with unsuitable state: %ld",(long)_assetWriter.error);
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:nil];
}

-(void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    if (!_isWriting) {
        NSLog(@"VideoWritter has been finish");
        return;
    }
    
    CMFormatDescriptionRef formatDes = CMSampleBufferGetFormatDescription(sampleBuffer);
    CMMediaType mediaType = CMFormatDescriptionGetMediaType(formatDes);
    
    if (mediaType == kCMMediaType_Video) {
        CMTime timesTamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        if (self.firstSample) {
            [_assetWriter startSessionAtSourceTime:timesTamp];
            self.firstSample = NO;
        }
        
        if (_videoInput.readyForMoreMediaData) {
            if (![_videoInput appendSampleBuffer:sampleBuffer]) {
                NSError *error = [NSError errorWithDomain:@"com.dingkan.captureservice.writter" code:-2221003 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"VieoWritter appending video sample buffer failed error : %@",_assetWriter.error.localizedDescription]}];
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
                    [self.delegate videoWriter:self didFailWithError:error];
                }
            }
        }
    
    }else if (!self.firstSample && mediaType == kCMMediaType_Audio){
        if (_audioInput.readyForMoreMediaData) {
            if (![_audioInput appendSampleBuffer:sampleBuffer]) {
                NSError *error = [NSError errorWithDomain:@"com.dingkan.captureservice.writter" code:-2221003 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"VieoWritter appending audio sample buffer failed error : %@",_assetWriter.error.localizedDescription]}];
                if (self.delegate && [self.delegate respondsToSelector:@selector(videoWriter:didFailWithError:)]) {
                    [self.delegate videoWriter:self didFailWithError:error];
                }
            }
        }
    }
    
}

+(BOOL)clearVideoFile:(NSString *)commponent error:(NSError **)error{
    NSString *videoPath = [NSTemporaryDirectory() stringByAppendingPathComponent:commponent];
    BOOL isDir = NO;
    BOOL existed = [[NSFileManager defaultManager] fileExistsAtPath:videoPath isDirectory:&isDir];
    if (isDir && existed) {
        if (![[NSFileManager defaultManager] removeItemAtPath:videoPath error:error]) {
            return NO;
        }
    }
    return YES;
}

@end
