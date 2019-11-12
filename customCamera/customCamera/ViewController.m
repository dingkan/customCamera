//
//  ViewController.m
//  customCamera
//
//  Created by dingkan on 2019/11/1.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "ViewController.h"
#import "DKCaptureService.h"
#import "DKSpeechManager.h"
#import "DKAudioRecorderManager.h"
#import "DKAudioPlayerManager.h"

@interface ViewController ()<DKSpeechManagerDelegate,DKAudioPlayerManagerDelegate>
@property (nonatomic, assign) NSInteger index;
@property (nonatomic, strong) DKAudioPlayerManager *manager;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self audioRecorderTest];
}

-(void)audioRecorderTest{
    NSInteger count = 4;
    for (NSInteger i = 0; i < count; i ++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setTitle:[NSString stringWithFormat:@"%ld",i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(btnDidClick:) forControlEvents:UIControlEventTouchUpInside];
        btn.frame = CGRectMake(i * 100, 200, 50, 50);
        btn.tag = i;
        [self.view addSubview:btn];
    }
}

-(void)btnDidClick:(UIButton *)btn{
    NSInteger index = btn.tag;
    switch (index) {
        case 0:
        {
            BOOL temp = [[DKAudioRecorderManager sharedInstance] record];
            NSLog(@"---%d",temp);
        }
            break;
        case 1:
        {
            [[DKAudioRecorderManager sharedInstance] pause];
        }
            break;
        case 2:
        {
            [[DKAudioRecorderManager sharedInstance] stop];
        }
            break;
        case 3:
        {
            [[DKAudioRecorderManager sharedInstance] saveRecorderingWithName:@"temp" complete:^(NSString * _Nonnull filePath) {
                NSLog(@"--------%@",filePath);
                self.manager = [[DKAudioPlayerManager alloc]initWithFileName:filePath delegate:self];
                [self.manager play];
            }];
        }
            break;
            
        default:
            break;
    }
}

-(void)speechTest{
    //   [[DKSpeechManager sharedInstance] speechManagerWithConfig:[[DKSpeechConfig alloc]init] speakString:@"噫吁嚱，危乎高哉！蜀道之难，难于上青天！蚕丛及鱼凫，开国何茫然！尔来四万八千岁，不与秦塞通人烟。西当太白有鸟道，可以横绝峨眉巅。地崩山摧壮士死，然后天梯石栈相钩连。上有六龙回日之高标，下有冲波逆折之回川。黄鹤之飞尚不得过，猿猱欲度愁攀援。青泥何盘盘，百步九折萦岩峦。扪参历井仰胁息，以手抚膺坐长叹。问君西游何时还？畏途巉岩不可攀。但见悲鸟号古木，雄飞雌从绕林间。又闻子规啼夜月，愁空山。蜀道之难，难于上青天，使人听此凋朱颜！连峰去天不盈尺，枯松倒挂倚绝壁。飞湍瀑流争喧豗，砯崖转石万壑雷。其险也如此，嗟尔远道之人胡为乎来哉！剑阁峥嵘而崔嵬，一夫当关，万夫莫开。所守或匪亲，化为狼与豺。朝避猛虎，夕避长蛇；磨牙吮血，杀人如麻。锦城虽云乐，不如早还家。蜀道之难，难于上青天，侧身西望长咨嗟！" delegate:self];
    
    [[DKSpeechManager sharedInstance] speechManagerWithConfig:[DKSpeechConfig defaultConfig] speakStrings:@[
                                                                                                            @"噫吁嚱，危乎高哉！蜀道之难，难于上青天！蚕丛及鱼凫，开国何茫然！尔来四万八千岁，不与秦塞通人烟。西当太白有鸟道，可以横绝峨眉巅。地崩山摧壮士死，然后天梯石栈相钩连。上有六龙回日之高标，下有冲波逆折之回川。",
                                                                                                            @"黄鹤之飞尚不得过，猿猱欲度愁攀援。青泥何盘盘，百步九折萦岩峦。扪参历井仰胁息，以手抚膺坐长叹。问君西游何时还？畏途巉岩不可攀。但见悲鸟号古木，雄飞雌从绕林间。又闻子规啼夜月，愁空山。",
                                                                                                            @"蜀道之难，难于上青天，使人听此凋朱颜！连峰去天不盈尺，枯松倒挂倚绝壁。飞湍瀑流争喧豗，砯崖转石万壑雷。其险也如此，嗟尔远道之人胡为乎来哉！剑阁峥嵘而崔嵬，一夫当关，万夫莫开。所守或匪亲，化为狼与豺。朝避猛虎，夕避长蛇；磨牙吮血，杀人如麻。锦城虽云乐，不如早还家。蜀道之难，难于上青天，侧身西望长咨嗟！"
                                                                                                            ] delegate:self];
}

-(void)speechhandle{
        if (self.index == 0) {
            [[DKSpeechManager sharedInstance] speak];
        }else if (self.index == 1){
            [[DKSpeechManager sharedInstance] pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        }else if (self.index == 2){
            [[DKSpeechManager sharedInstance] continueSpeaking];
        }else if (self.index == 3){
            [[DKSpeechManager sharedInstance] stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
        }else if (self.index == 4){
            [[DKSpeechManager sharedInstance] continueSpeaking];
        }else if (self.index == 5){
            self.index = -1;
        }
        self.index ++;
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    
//    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
//    UIViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"THMainViewController"];
//    [self presentViewController:vc animated:YES completion:nil];

}

#pragma DKSpeechManagerDelegate
-(void)DKSpeechManagerDidFailedError:(NSError *)error{
    NSLog(@"DKSpeechManagerDidFailedError");
}
- (void)DKSpeechManagerDidStartSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    NSLog(@"Start");
}
- (void)DKSpeechManagerDidFinishSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    NSLog(@"Finish");
    
}
- (void)DKSpeechManagerDidPauseSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    NSLog(@"Pause");
    
}
- (void)DKSpeechManageridContinueSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    NSLog(@"Continue");
    
}
- (void)DKSpeechManagerDidCancelSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    NSLog(@"Cancel");
    
}
- (void)DKSpeechManagerWillSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    NSLog(@"SpeakRange");
}


#pragma DKAudioPlayerManagerDelegate
-(void)DKAudioPlayerManagerDidFailedWithError:(NSError *)error target:(DKAudioPlayerManager *)target{
    NSLog(@"DKAudioPlayerManagerDidFailedWithError");
}
-(void)DKAudioPlayerManagerPlayBackStoppedWithTarget:(DKAudioPlayerManager *)target{
    NSLog(@"DKAudioPlayerManagerPlayBackStoppedWithTarget");
}
-(void)DKAudioPlayerManagerPlayBackBeginWithTarget:(DKAudioPlayerManager *)target{
    NSLog(@"DKAudioPlayerManagerPlayBackBeginWithTarget");
}
@end

