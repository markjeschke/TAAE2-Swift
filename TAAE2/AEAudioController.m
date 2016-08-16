//
//  AEAudioController.m
//  TAAE2
//
//  Created by Mark Jeschke on 7/17/16.
//  Copyright © 2016 Mark Jeschke. All rights reserved.
//

#import "AEAudioController.h"
#import "AudioShareSDK.h"

@interface AEAudioController ()

@property (nonatomic, strong, readwrite) AEAudioUnitOutput * output;

// Effects
@property (nonatomic, strong, readwrite) AEDelayModule * delay;
@property (nonatomic, strong, readwrite) AEReverbModule * reverb;

// Audio files
@property (nonatomic, strong, readwrite) AEAudioFilePlayerModule * technobeat;
@property (nonatomic, strong, readwrite) AEAudioFilePlayerModule * bass;
@property (nonatomic, strong, readwrite) AEAudioFilePlayerModule * housebeat;
@property (nonatomic, strong, readwrite) AEAudioFilePlayerModule * melody;

@property (nonatomic, strong, readwrite) AEAudioFilePlayerModule * playback;
@property (nonatomic, strong, readwrite) AEAudioFileRecorderModule * recordedFile;

// Recording
@property (nonatomic, readwrite) BOOL recording;
@property (nonatomic, readwrite) BOOL playingRecording;
@property (nonatomic, strong) AEManagedValue * recorderValue;
@property (nonatomic, strong) AEManagedValue * playerValue;

@end

@implementation AEAudioController
@dynamic recordingPlaybackPosition;

#pragma mark - Life-cycle

- (instancetype)init {
    if ( !(self = [super init]) ) return nil;
  
    _recordingName = @"Recorded TAAE2";
    _recordingFormat = @"m4a";
    _fullRecordingName = [NSString stringWithFormat:@"%@.%@",_recordingName, _recordingFormat];

    // Create a renderer
    AERenderer * renderer = [AERenderer new];
    
    // Create an output
    self.output = [[AEAudioUnitOutput alloc] initWithRenderer:renderer];
    
    // Setup audio loops
    
    NSURL * url = [[NSBundle mainBundle] URLForResource:@"technobeat" withExtension:@"m4a"];
    _technobeat = [[AEAudioFilePlayerModule alloc] initWithRenderer:renderer URL:url error:NULL];
    _technobeat.loop = YES;
    _technobeat.microfadeFrames = 32;
    
    url = [[NSBundle mainBundle] URLForResource:@"bass" withExtension:@"m4a"];
    _bass = [[AEAudioFilePlayerModule alloc] initWithRenderer:renderer URL:url error:NULL];
    _bass.loop = YES;
    _bass.microfadeFrames = 32;
    
    url = [[NSBundle mainBundle] URLForResource:@"housebeat" withExtension:@"m4a"];
    _housebeat = [[AEAudioFilePlayerModule alloc] initWithRenderer:renderer URL:url error:NULL];
    _housebeat.loop = YES;
    _housebeat.microfadeFrames = 32;
    
    url = [[NSBundle mainBundle] URLForResource:@"melody" withExtension:@"m4a"];
    _melody = [[AEAudioFilePlayerModule alloc] initWithRenderer:renderer URL:url error:NULL];
    _melody.loop = YES;
    _melody.microfadeFrames = 32;
    
    // Create the filters
  
    // Distortion
    _distortion = [[AEDistortionModule alloc] initWithRenderer:renderer];
    _distortion.squaredTerm = 80.0;
    _distortion.softClipGain = 5.0;
    _distortion.rounding = 20.0;
    _distortion.finalMix = 40.0;
  
    // Delay
    _delay = [[AEDelayModule alloc] initWithRenderer:renderer];
    _delay.delayTime = _technobeat.duration/4;
    _delay.feedback = 30.0;
    _delay.lopassCutoff = 15000.0;
    _delay.wetDryMix = 35.0;
  
    // Reverb
    _reverb = [[AEReverbModule alloc] initWithRenderer:renderer];
    _reverb.decayTimeAt0Hz = 2;
    _reverb.decayTimeAtNyquist = 3;
    _reverb.gain = 2;
    _reverb.dryWetMix = 20.0;
  
    // Setup recorder placeholder
    AEManagedValue * recorderValue = [AEManagedValue new];
    self.recorderValue = recorderValue;
    
    // Setup recording player placeholder
    AEManagedValue * playerValue = [AEManagedValue new];
    self.playerValue = playerValue;

    // Render block
    
    // Setup top-level renderer. This is all performed on the audio thread, so the usual
    // rules apply: No holding locks, no memory allocation, no Objective-C/Swift code.
    //__unsafe_unretained AEAudioController * THIS = self;
    renderer.block = ^(const AERenderContext * _Nonnull context) {
      
        // See if we have an active recorder
        __unsafe_unretained AEAudioFileRecorderModule * recorder
        = (__bridge AEAudioFileRecorderModule *)AEManagedValueGetValue(recorderValue);
        
        // See if we have an active player
        __unsafe_unretained AEAudioFilePlayerModule * player
        = (__bridge AEAudioFilePlayerModule *)AEManagedValueGetValue(playerValue);
      
        AEModuleProcess(_melody, context); // Run player (pushes 1)
      
        // Apply distortion and delay filters to the 'melody' audio file, only.
        AEModuleProcess(_distortion, context); // Run filter (edits top buffer)
        AEModuleProcess(_delay, context); // Run filter (edits top buffer)
      
        // Add the remaining audio files.
        AEModuleProcess(_bass, context); // Run player (pushes 1)
        AEModuleProcess(_housebeat, context); // Run player (pushes 1)
        AEModuleProcess(_technobeat, context); // Run player (pushes 1)
      
        // Mix all 4 audio file buffers
        AEBufferStackMix(context->stack, 4);
      
        // Apply reverb filter to entire audio output mix
        AEModuleProcess(_reverb, context);
      
        AERenderContextOutput(context, 1); // Put top buffer onto output
      
      // Run through recorder, if it's there
      if ( recorder && !player ) {
        // Run through recorder
        AEModuleProcess(recorder, context);
      }
      
      // Play recorded file, if playing
      if ( player ) {
        // Play
        AEModuleProcess(player, context);
        
        // Put on output
        AERenderContextOutput(context, 1);
      }
    };
  
    NSLog(@"Render block initialized and running.");
  
    return self;
}

- (BOOL)start:(NSError *__autoreleasing *)error {
    NSLog(@"Engine started");
  
    return [self.output start:error];
}

- (void)stop {
    [self.output stop];
}

#pragma mark - Audio loop triggers

-(void) playBeatOne {
  if (!_technobeat.playing) {
    [_technobeat playAtTime:AETimeStampNone];
  } else {
    [_technobeat stop];
  }
}

-(void) playBeatTwo {
  if (!_housebeat.playing) {
    [_housebeat playAtTime:AETimeStampNone];
  } else {
    [_housebeat stop];
  }
}

-(void) playBassline {
  if (!_bass.playing) {
    [_bass playAtTime:AETimeStampNone];
  } else {
    [_bass stop];
  }
}

-(void) playMelody {
  if (!_melody.playing) {
    [_melody playAtTime:AETimeStampNone];
  } else {
    [_melody stop];
  }
}

#pragma mark - Recording

- (BOOL)beginRecordingAtTime:(AEHostTicks)time error:(NSError**)error {
  if ( self.recording ) return NO;
  
  // Create recorder
  AEAudioFileRecorderModule * recorder = [[AEAudioFileRecorderModule alloc] initWithRenderer:self.output.renderer
                                                                                         URL:self.recordingPath type:AEAudioFileTypeM4A error:error];
  if ( !recorder ) {
    return NO;
  }
  
  // Make recorder available to audio renderer
  self.recorderValue.objectValue = recorder;
  
  self.recording = YES;
  [recorder beginRecordingAtTime:time];
  
  return YES;
}

- (void)stopRecordingAtTime:(AEHostTicks)time completionBlock:(void(^)())block {
  if ( !self.recording ) return;
  
  // End recording
  AEAudioFileRecorderModule * recorder = self.recorderValue.objectValue;
  __weak AEAudioController * weakSelf = self;
  [recorder stopRecordingAtTime:time completionBlock:^{
    weakSelf.recording = NO;
    weakSelf.recorderValue.objectValue = nil;
    if ( block ) block();
  }];
}

- (void)playRecordingWithCompletionBlock:(void (^)())block {
  NSURL * url = self.recordingPath;
  if ( [[NSFileManager defaultManager] fileExistsAtPath:url.path] ) {
    
    // Start player
    _playback =
    [[AEAudioFilePlayerModule alloc] initWithRenderer:self.output.renderer URL:url error:NULL];
    if ( !_playback) return;
    
    // Make player available to audio renderer
    self.playerValue.objectValue = _playback;
    __weak AEAudioController * weakSelf = self;
    _playback.completionBlock = ^{
      // Keep track of when playback ends
      [weakSelf stopPlayingRecording];
      if ( block ) block();
    };
    
    // Go
    self.playingRecording = YES;
    [_playback playAtTime:AETimeStampNone];
  }
}

- (void)stopPlayingRecording {
  self.playingRecording = NO;
  self.playerValue.objectValue = nil;
}

- (NSString *)recordingName:(NSString *)recordingName {
    self.recordingName = recordingName;
    return recordingName;
}

- (NSString *)recordingFormat:(NSString *)recordingFormat {
    self.recordingFormat = recordingFormat;
    return recordingFormat;
}

- (NSURL *)recordingPath {
  NSURL * docs = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
  return [docs URLByAppendingPathComponent:_fullRecordingName];
}

- (double)recordingPlaybackPosition {
  AEAudioFilePlayerModule * player = self.playerValue.objectValue;
  if ( !player ) return 0.0;
  
  return player.currentTime / player.duration;
}

- (void)setRecordingPlaybackPosition:(double)recordingPlaybackPosition {
  AEAudioFilePlayerModule * player = self.playerValue.objectValue;
  if ( !player ) return;
  player.currentTime = recordingPlaybackPosition * player.duration;
}

#pragma mark - Export to AudioShare

-(void)exportToAudioShare {
  NSArray *documentsFolders = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *path = [documentsFolders[0] stringByAppendingPathComponent:_fullRecordingName];
  [[AudioShare sharedInstance] addSoundFromPath:path withName:_recordingName];
}

@end
