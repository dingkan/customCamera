//
//  DKViewController.m
//  customCamera
//
//  Created by dingkan on 2019/11/2.
//  Copyright © 2019年 dingkan. All rights reserved.
//

#import "DKViewController.h"
#import "DKCaptureService.h"
#import <AVKit/AVKit.h>
#import "DKVideoAssetHandle.h"

@interface DKViewController ()<DKCaptureServiceDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *recordstate;

@property (nonatomic, strong) DKCaptureService *service;
@end

@implementation DKViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    
    _service = [[DKCaptureService alloc]init];
    _service.delegate = self;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(_showDetial)];
    _imageView.userInteractionEnabled = YES;
    [_imageView addGestureRecognizer:tap];
}

#pragma DKCaptureServiceDelegate
// CaptureService 生命周期
-(void)captureServiceDidStartService:(DKCaptureService *)service{
    NSLog(@"captureServiceDidStartService");
}

-(void)captureServiceDidStopService:(DKCaptureService *)service{
    NSLog(@"captureServiceDidStopService");
}

-(void)captureService:(DKCaptureService *)service serviceDidFailedWithError:(NSError *)error{
    NSLog(@"serviceDidFailedWithError %@",error.userInfo);
}

-(void)captureService:(DKCaptureService *)service getPreViewLayer:(AVCaptureVideoPreviewLayer *)preViewLayer{
    if (preViewLayer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.contentView.layer addSublayer:preViewLayer];
            preViewLayer.frame = self.contentView.bounds;
        });
    }
}

-(void)captureService:(DKCaptureService *)service outputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
//    NSLog(@"outputSampleBuffer");
}

//人脸检测
-(void)captureService:(DKCaptureService *)service outputFaceDetectData:(NSArray <AVMetadataFaceObject *>*)faces{
    NSLog(@"outputFaceDetectData");
}

//录像相关
-(void)caputreServiceRecorderDidStart:(DKCaptureService *)service{
    NSLog(@"caputreServiceRecorderDidStart");
}

-(void)caputreServiceRecorderDidCancel:(DKCaptureService *)servie{
    NSLog(@"caputreServiceRecorderDidCancel");
}

-(void)captureServiceRecorderDidStop:(DKCaptureService *)service{
    NSLog(@"captureServiceRecorderDidStop");
}

-(void)captureServiceRecorderDidStop:(DKCaptureService *)service asset:(AVURLAsset *)asset{
    NSLog(@"captureServiceRecorderDidStop  asset = %@",asset);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *img = [DKVideoAssetHandle getImgWithAsset:asset];
        self.imageView.image = img;
        self.label.text = @"Video";
    });
    
}

-(void)captureService:(DKCaptureService *)service recorderDidFailWithError:(NSError *)error{
    NSLog(@"recorderDidFailWithError = %@",error.userInfo);
}

//照片捕获
-(void)captureServie:(DKCaptureService *)servie capturePhoto:(UIImage *)photo{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.imageView.image = photo;
        self.label.text = @"Photo";
    });
}

-(void)_showDetial{
    if ([_label.text isEqualToString:@"Photo"]) {
        
    }else if ([_label.text isEqualToString:@"Video"]){
        AVPlayerViewController *avVc = [[AVPlayerViewController alloc]init];
        avVc.player = [AVPlayer playerWithURL:_service.recordURL];
        avVc.videoGravity = AVLayerVideoGravityResizeAspect;
        [avVc.player play];
        avVc.title = @"captueService Demo";
        [self.navigationController pushViewController:avVc animated:YES];
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [_service startRunning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_service stopRunning];
}

- (IBAction)switchCamera:(id)sender {
    [_service switchCamera];
}

- (IBAction)startRecord:(id)sender {
    [_service startRecording];
    _recordstate.hidden = NO;
}

- (IBAction)stopRecord:(id)sender {
    _recordstate.hidden = YES;
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"停止录像" message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
    [alert show];
    [_service stopRecording];
}

- (IBAction)takePhoto:(id)sender {
    [_service capturePhoto];
}


@end
