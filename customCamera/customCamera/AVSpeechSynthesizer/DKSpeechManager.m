//
//  DKSpeechManager.m
//  customCamera
//
//  Created by dingkan on 2019/11/9.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKSpeechManager.h"


@interface DKSpeechManager()<AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) AVSpeechSynthesizer *speech;
@property (nonatomic, strong) AVSpeechUtterance *utterance;
@property (nonatomic, strong) DKSpeechConfig *config;
@property (nonatomic, strong) NSString *speakString;
@property (nonatomic, strong) NSArray<NSString *> *speakStrings;
@property (nonatomic, strong) NSMutableArray *utterances;
@property (nonatomic, weak) id<DKSpeechManagerDelegate> delegate;
@end

@implementation DKSpeechManager

static DKSpeechManager * _shared;
+(instancetype)sharedInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shared = [[DKSpeechManager alloc] init];
    });
    return _shared;
}

-(void)speechManagerWithConfig:(DKSpeechConfig *)config speakString:(NSString *)speakString delegate:(id<DKSpeechManagerDelegate>)delegate{
    self.config = config;
    self.delegate = delegate;
    self.speakString = speakString;
}

-(void)speechManagerWithConfig:(DKSpeechConfig *)config speakStrings:(NSArray<NSString *> *)speakStrings delegate:(id<DKSpeechManagerDelegate>)delegate{
    self.config = config;
    self.delegate = delegate;
    self.speakStrings = speakStrings;
}

-(instancetype)init{
    if (self = [super init]) {
        self.speech = [[AVSpeechSynthesizer alloc]init];
        self.speech.delegate = self;
    }
    return self;
}

#pragma delegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    if(self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManagerDidStartSpeechUtterance:)]){
        [self.delegate DKSpeechManagerDidStartSpeechUtterance:utterance];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    if(self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManagerDidFinishSpeechUtterance:)]){
        [self.delegate DKSpeechManagerDidFinishSpeechUtterance:utterance];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    if(self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManagerDidPauseSpeechUtterance:)]){
        [self.delegate DKSpeechManagerDidPauseSpeechUtterance:utterance];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    if(self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManageridContinueSpeechUtterance:)]){
        [self.delegate DKSpeechManageridContinueSpeechUtterance:utterance];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    if(self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManagerDidCancelSpeechUtterance:)]){
        [self.delegate DKSpeechManagerDidCancelSpeechUtterance:utterance];
    }
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    if(self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManagerWillSpeakRangeOfSpeechString:utterance:)]){
        [self.delegate DKSpeechManagerWillSpeakRangeOfSpeechString:characterRange utterance:utterance];
    }
}

-(void)speak{
    if (self.speakString && self.speakString.length) {
        [self.speech speakUtterance:self.utterance];
        return;
    }
    
    if (self.utterances.count > 0) {
        for (AVSpeechUtterance *item in self.utterances) {
            [self.speech speakUtterance:item];
        }
    }
}

- (BOOL)stopSpeakingAtBoundary:(AVSpeechBoundary)boundary{
    return [self.speech stopSpeakingAtBoundary:boundary];
}

- (BOOL)pauseSpeakingAtBoundary:(AVSpeechBoundary)boundary{
    return [self.speech pauseSpeakingAtBoundary:boundary];
}

- (BOOL)continueSpeaking{
    return [self.speech continueSpeaking];
}

-(void)dealloc{
    self.utterance = nil;
    self.utterances = nil;
}

-(void)setSpeakStrings:(NSArray<NSString *> *)speakStrings{
    _speakStrings = speakStrings;
    
    for (NSString *subStr in speakStrings) {
        AVSpeechUtterance *utterance = [self createUtteranceWithString:subStr];
        [self.utterances addObject:utterance];
    }
}

-(void)setSpeakString:(NSString *)speakString{
    _speakString = speakString;
    self.utterance = nil;
    [self utterance];
}

-(AVSpeechUtterance *)utterance{
    if (!_utterance) {
        _utterance = [self createUtteranceWithString:self.speakString];
    }
    return _utterance;
}

-(AVSpeechUtterance *)createUtteranceWithString:(NSString *)string{
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:string];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:self.config.Language];
    utterance.rate = self.config.rate;
    utterance.pitchMultiplier = self.config.pitchMultiplier;
    utterance.volume = self.config.volume;
    utterance.postUtteranceDelay = self.config.postUtteranceDelay;
    utterance.preUtteranceDelay = self.config.preUtteranceDelay;
    return utterance;
}

-(void)setConfig:(DKSpeechConfig *)config{
    _config = config;
    
    BOOL hadLanguage = NO;
    NSArray<AVSpeechSynthesisVoice *> *datas = [AVSpeechSynthesisVoice speechVoices];
    for (AVSpeechSynthesisVoice *voice in datas) {
        if ([voice.language isEqualToString:config.Language]) {
            hadLanguage = YES;
            break;
        }
    }
    
    if (!hadLanguage) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(DKSpeechManagerDidFailedError:)]) {
            NSError *nError  = [NSError errorWithDomain:@"com.dingkan.DKSpeechManager.Language" code:-2230012 userInfo:@{NSLocalizedDescriptionKey:@"config with a error language"}];
            [self.delegate DKSpeechManagerDidFailedError:nError];
        }
    }
}

- (NSMutableArray *)utterances{
    if (!_utterances) {
        _utterances = [NSMutableArray array];
    }
    return _utterances;
}


@end

