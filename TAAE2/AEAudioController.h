//
//  AEAudioController.h
//  TAAE2
//
//  Created by Mark Jeschke on 7/17/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

@interface AEAudioController : NSObject

- (BOOL)start:(NSError * _Nullable * _Nullable)error;
- (void)stop;

-(void)playBeatOne;
-(void)playBeatTwo;
-(void)playBassline;
-(void)playMelody;

-(void)exportToAudioShare;

- (BOOL)beginRecordingAtTime:(AEHostTicks)time error:(NSError * _Nullable * _Nullable)error;
- (void)stopRecordingAtTime:(AEHostTicks)time completionBlock:(void(^ _Nullable)())block;

- (void)playRecordingWithCompletionBlock:(void(^ _Nullable)())block;
- (void)stopPlayingRecording;

// Effects modules
@property (nonatomic, strong, readonly) AEDelayModule * _Nonnull delay;
@property (nonatomic, strong, readonly) AEReverbModule * _Nonnull reverb;
@property (nonatomic, strong, readonly) AEDistortionModule * _Nonnull distortion;

// Audio File Player modules
@property (nonatomic, strong, readonly) AEAudioFilePlayerModule * _Nonnull technodrums;
@property (nonatomic, strong, readonly) AEAudioFilePlayerModule * _Nonnull bass;
@property (nonatomic, strong, readonly) AEAudioFilePlayerModule * _Nonnull drumbeat;
@property (nonatomic, strong, readonly) AEAudioFilePlayerModule * _Nonnull crystalline;

@property (nonatomic, strong, readonly) AEAudioFilePlayerModule * _Nonnull playback;
@property (nonatomic, strong, readonly) AEAudioFileRecorderModule * _Nonnull recordedFile;

// Recording components
@property (nonatomic, readonly) BOOL recording;
@property (nonatomic, readonly) NSURL * _Nonnull recordingPath;
@property (nonatomic, readwrite) NSString * _Nonnull recordingName;
@property (nonatomic, readwrite) NSString * _Nonnull recordingFormat;
@property (nonatomic, readonly) NSString * _Nonnull fullRecordingName;
@property (nonatomic, readonly) BOOL playingRecording;
@property (nonatomic) double recordingPlaybackPosition;

@end
