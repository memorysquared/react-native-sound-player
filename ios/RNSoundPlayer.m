//
//  RNSoundPlayer
//
//  Created by Johnson Su on 2018-07-10.
//

#import "RNSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>

@implementation RNSoundPlayer
{
    bool hasListeners;
}

static NSString *const EVENT_SETUP_ERROR = @"OnSetupError";
static NSString *const EVENT_FINISHED_LOADING = @"FinishedLoading";
static NSString *const EVENT_FINISHED_LOADING_FILE = @"FinishedLoadingFile";
static NSString *const EVENT_FINISHED_LOADING_URL = @"FinishedLoadingURL";
static NSString *const EVENT_FINISHED_PLAYING = @"FinishedPlaying";

RCT_EXPORT_MODULE();

@synthesize bridge = _bridge;

+ (BOOL)requiresMainQueueSetup {
    return YES;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.players = [NSMutableDictionary new];

        // TODO
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(itemDidFinishPlaying:)
                                                     name:AVPlayerItemDidPlayToEndTimeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSArray<NSString *> *)supportedEvents {
    return @[EVENT_FINISHED_PLAYING, EVENT_FINISHED_LOADING, EVENT_FINISHED_LOADING_URL, EVENT_FINISHED_LOADING_FILE, EVENT_SETUP_ERROR];
}

-(void)startObserving {
    hasListeners = YES;
}

-(void)stopObserving {
    hasListeners = NO;
}

RCT_EXPORT_METHOD(playUrl:(NSString *)url key:(NSString *)key) {
    [self prepareUrl:url withKey:key];
    [self playSoundWithKey:key];
}

RCT_EXPORT_METHOD(loadUrl:(NSString *)url key:(NSString *)key) {
    [self prepareUrl:url withKey:key];
}

RCT_EXPORT_METHOD(playSoundFile:(NSString *)name ofType:(NSString *)type key:(NSString *)key) {
    [self mountSoundFile:name ofType:type withKey:key];
    [self playSoundWithKey:key];
}

RCT_EXPORT_METHOD(playSoundFileWithDelay:(NSString *)name ofType:(NSString *)type delay:(double)delay withKey:(NSString *)key) {
    [self mountSoundFile:name ofType:type withKey:key];

    AVAudioPlayer *player = self.players[key];
    if (player) {
        [player playAtTime:(player.deviceCurrentTime + delay)];
    }
}

RCT_EXPORT_METHOD(loadSoundFile:(NSString *)name ofType:(NSString *)type withKey:(NSString *)key) {
    [self mountSoundFile:name ofType:type withKey:key];
}

RCT_EXPORT_METHOD(pause:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        [player pause];
    }
}

RCT_EXPORT_METHOD(resume:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        [player play];
    }
}

RCT_EXPORT_METHOD(stop:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        [player stop];
    }
}

RCT_EXPORT_METHOD(seek:(float)seconds key:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        player.currentTime = seconds;
    }
}

#if !TARGET_OS_TV
RCT_EXPORT_METHOD(setSpeaker:(BOOL)on withKey:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        if (on) {
            [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        } else {
            [session setCategory:AVAudioSessionCategoryPlayback error:&error];
            [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        }
        [session setActive:YES error:&error];

        if (error) {
            [self sendErrorEvent:error];
        }
    }
}
#endif

RCT_EXPORT_METHOD(setMixAudio:(BOOL)on withKey:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        AVAudioSession *session = [AVAudioSession sharedInstance];
        NSError *error = nil;
        if (on) {
            [session setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
        } else {
            [session setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&error];
        }
        [session setActive:YES error:&error];

        if (error) {
            [self sendErrorEvent:error];
        }
    }
}

RCT_EXPORT_METHOD(setVolume:(float)volume withKey:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        [player setVolume:volume];
    }
}

RCT_EXPORT_METHOD(setNumberOfLoops:(NSInteger)loopCount forKey:(NSString *)key) {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        NSLog(@"Setting number of loop");
        [player setNumberOfLoops:loopCount];
    } else {
        NSLog(@"No player found for key: %@", key);
    }
}

RCT_REMAP_METHOD(getInfo,
                 getInfoWithResolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject
                 withKey:(NSString *)key) {

    AVAudioPlayer *player = self.players[key];
    if (player != nil) {
        NSDictionary *data = @{
            @"currentTime": [NSNumber numberWithDouble:[player currentTime]],
            @"duration": [NSNumber numberWithDouble:[player duration]]
        };
        resolve(data);
    } else if (self.avPlayer != nil) {
        CMTime currentTime = [[self.avPlayer currentItem] currentTime];
        CMTime duration = [[[self.avPlayer currentItem] asset] duration];
        NSDictionary *data = @{
            @"currentTime": [NSNumber numberWithFloat:CMTimeGetSeconds(currentTime)],
            @"duration": [NSNumber numberWithFloat:CMTimeGetSeconds(duration)]
        };
        resolve(data);
    } else {
        resolve(nil);
    }
}


- (void)playSoundWithKey:(NSString *)key {
    AVAudioPlayer *player = self.players[key];
    if (player) {
        [player play];
    }
}

// TODO
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    if (hasListeners) {
        [self sendEventWithName:EVENT_FINISHED_PLAYING body:@{@"success": [NSNumber numberWithBool:flag]}];
    }
}

// TODO
- (void)itemDidFinishPlaying:(NSNotification *)notification {
    if (hasListeners) {
        [self sendEventWithName:EVENT_FINISHED_PLAYING body:@{@"success": [NSNumber numberWithBool:YES]}];
    }
}

- (void)mountSoundFile:(NSString *)name ofType:(NSString *)type withKey:(NSString *)key {
    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:name ofType:type];
    if (soundFilePath == nil) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        soundFilePath = [NSString stringWithFormat:@"%@.%@", [documentsDirectory stringByAppendingPathComponent:name], type];
    }

    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
    if (error) {
        [self sendErrorEvent:error];
        return;
    }
    [player setDelegate:self];
    [player setNumberOfLoops:self.loopCount];
    [player prepareToPlay];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    if (error) {
        [self sendErrorEvent:error];
        return;
    }

    self.players[key] = player;

    if (hasListeners) {
        [self sendEventWithName:EVENT_FINISHED_LOADING body:@{@"success": [NSNumber numberWithBool:YES]}];
        [self sendEventWithName:EVENT_FINISHED_LOADING_FILE body:@{@"success": [NSNumber numberWithBool:YES], @"name": name, @"type": type}];
    }
}

- (void)prepareUrl:(NSString *)url withKey:(NSString *)key {
    AVAudioPlayer *existingPlayer = self.players[key];
    if (existingPlayer) {
        [existingPlayer stop];
        [self.players removeObjectForKey:key];
    }

    NSError *error = nil;
    NSURL *soundURL = [NSURL URLWithString:url];
    NSData *audioData = [NSData dataWithContentsOfURL:soundURL];

    if (!audioData) {
        NSLog(@"Failed to load audio data from URL: %@", url);
        return;
    }

    AVAudioPlayer *newPlayer = [[AVAudioPlayer alloc] initWithData:audioData error:&error];
    if (error) {
        NSLog(@"Error initializing AVAudioPlayer: %@", error.localizedDescription);
        return;
    }

    [newPlayer prepareToPlay];

    if (!self.players) {
        self.players = [NSMutableDictionary new];
    }
    self.players[key] = newPlayer;

    if (hasListeners) {
        [self sendEventWithName:EVENT_FINISHED_LOADING body:@{@"success": @YES, @"key": key}];
    }
}


// TODO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.avPlayer.currentItem && [keyPath isEqualToString:@"status"] && hasListeners) {
        if (self.avPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            [self sendEventWithName:EVENT_FINISHED_LOADING body:@{@"success": [NSNumber numberWithBool:YES]}];
            NSURL *url = [(AVURLAsset *)self.avPlayer.currentItem.asset URL];
            [self sendEventWithName:EVENT_FINISHED_LOADING_URL body:@{@"success": [NSNumber numberWithBool:YES], @"url": [url absoluteString]}];
        } else if (self.avPlayer.currentItem.status == AVPlayerItemStatusFailed) {
            [self sendErrorEvent:self.avPlayer.currentItem.error];
        }
    }
}

// TODO
- (void)sendErrorEvent:(NSError *)error {
	if (hasListeners) {
	    [self sendEventWithName:EVENT_SETUP_ERROR body:@{@"error": [error localizedDescription]}];
	}
}

@end
