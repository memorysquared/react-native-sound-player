//
//  RNSoundPlayer
//
//  Created by Johnson Su on 2018-07-10.
//

#import <React/RCTBridgeModule.h>
#import <AVFoundation/AVFoundation.h>
#import <React/RCTEventEmitter.h>

@interface RNSoundPlayer : RCTEventEmitter <RCTBridgeModule, AVAudioPlayerDelegate>
@property (nonatomic, strong) AVPlayer *avPlayer;
@property (nonatomic) int loopCount;
@property (nonatomic, strong) NSMutableDictionary<NSString *, AVAudioPlayer *> *players;
@end
