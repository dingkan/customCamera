//
//  MIT License
//
//  Copyright (c) 2014 Bob McCune http://bobmccune.com/
//  Copyright (c) 2014 TapHarmonic, LLC http://tapharmonic.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "THMainViewController.h"
#import "THControlKnob.h"
#import <UIKit/UIKit.h>
#import "DKAudioPlayerManager.h"

@interface THMainViewController ()<DKAudioPlayerManagerDelegate>
@property (nonatomic, strong) DKAudioPlayerManager *drumsManager;
@property (nonatomic, strong) DKAudioPlayerManager *guitarManager;
@property (nonatomic, strong) DKAudioPlayerManager *bassManager;

@property (weak, nonatomic) IBOutlet UILabel *playLabel;
@property (weak, nonatomic) IBOutlet THControlKnob *rateKnob;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (strong, nonatomic) IBOutletCollection(THControlKnob) NSArray *panKnobs;
@property (strong, nonatomic) IBOutletCollection(THControlKnob) NSArray *volumeKnobs;

@end

@implementation THMainViewController

- (void)viewDidLoad {

    self.drumsManager = [[DKAudioPlayerManager alloc]initWithFileName:@"drums" delegate:self];
    self.guitarManager = [[DKAudioPlayerManager alloc]initWithFileName:@"guitar" delegate:self];
    self.bassManager = [[DKAudioPlayerManager alloc]initWithFileName:@"bass" delegate:self];
    
    
    self.rateKnob.minimumValue = 0.5f;
    self.rateKnob.maximumValue = 1.5f;
    self.rateKnob.value = 1.0f;
    self.rateKnob.defaultValue = 1.0f;

    // Panning L = -1, C = 0, R = 1
    for (THControlKnob *knob in self.panKnobs) {
        knob.minimumValue = -1.0f;
        knob.maximumValue = 1.0f;
        knob.value = 0.0f;
        knob.defaultValue = 0.0f;
    }

    // Volume Ranges from 0..1
    for (THControlKnob *knob in self.volumeKnobs) {
        knob.minimumValue = 0.0f;
        knob.maximumValue = 1.0f;
        knob.value = 1.0f;
        knob.defaultValue = 1.0f;
    }
}

#pragma DKAudioPlayerManagerDelegate

-(void)DKAudioPlayerManagerDidFailedWithError:(NSError *)error target:(DKAudioPlayerManager *)target{
    NSLog(@"DidFailedWithError");
}
-(void)DKAudioPlayerManagerPlayBackStoppedWithTarget:(DKAudioPlayerManager *)target{
    NSLog(@"PlayBackStopped");
}
-(void)DKAudioPlayerManagerPlayBackBeginWithTarget:(DKAudioPlayerManager *)target{
    NSLog(@"PlayBackBegin");
}

- (IBAction)play:(UIButton *)sender {
    if (!self.drumsManager.isPlaying) {
        [self.drumsManager play];
        [self.guitarManager play];
        [self.bassManager play];
        self.playLabel.text = NSLocalizedString(@"Stop", nil);
    } else {
        [self.drumsManager stop];
        [self.guitarManager stop];
        [self.bassManager stop];
        self.playLabel.text = NSLocalizedString(@"Play", nil);
    }
    self.playButton.selected = !self.playButton.selected;
}

- (IBAction)adjustRate:(THControlKnob *)sender {
    [self.drumsManager adjustRate:sender.value];
    [self.guitarManager adjustRate:sender.value];
    [self.bassManager adjustRate:sender.value];
}

- (IBAction)adjustPan:(THControlKnob *)sender {
    NSInteger index= sender.tag;
    switch (index) {
        case 0:
        {
            [self.drumsManager adjustPan:sender.value];
        }
            break;
        case 1:
        {
            [self.guitarManager adjustPan:sender.value];
        }
            break;
        case 2:
        {
            [self.bassManager adjustPan:sender.value];
        }
            break;
            
        default:
            break;
    }
}

- (IBAction)adjustVolume:(THControlKnob *)sender {
    NSInteger index= sender.tag;
    switch (index) {
        case 0:
        {
            [self.drumsManager adjustVolume:sender.value];
        }
            break;
        case 1:
        {
            [self.guitarManager adjustVolume:sender.value];
        }
            break;
        case 2:
        {
            [self.bassManager adjustVolume:sender.value];
        }
            break;
            
        default:
            break;
    }
}


@end
