//
//  TFViewController.m
//  Tuneful
//
//  Created by Alex Winston on 3/27/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFViewController.h"
#import "TFMpmFrequencyAnalysis.h"
#import "TPPreciseTimer.h"
#import "OALSimpleAudio.h"
#import "BBVoice.h"
#import "BBGroove.h"

@interface TFViewController ()

@end

@implementation TFViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSLog(@"initWithNibName:");
    }
    
    return self;
}

- (void)awakeFromNib
{
    NSLog(@"awakeFromNib");
    sampleRate = 44100;
    
    actionsQueue = [NSMutableArray array];
    
    novocaineBufferSize = sampleRate * 2;
    novocaineBuffer = (float *)malloc(novocaineBufferSize * sizeof(float));
    novocaineBufferIndex = 0;
    novocaine = [Novocaine audioManager];
    [novocaine pause];
    
    [novocaine setInputBlock:^(float *newAudio, UInt32 numSamples, UInt32 numChannels) {
//        NSLog(@"%d", numChannels);
        // Now you're getting audio from the microphone every 20 milliseconds or so. How's that for easy?
        // Audio comes in interleaved, so,
        // if numChannels = 2, newAudio[0] is channel 1, newAudio[1] is channel 2, newAudio[2] is channel 1, etc.
//        @synchronized(self) {
            for (int i = 0; i < numSamples * numChannels; i++) {
                // TODO memmove
                if (novocaineBufferIndex + i > novocaineBufferSize)
                    novocaineBufferIndex = 0;
                novocaineBuffer[novocaineBufferIndex + i] = newAudio[i * numChannels];
            }
            novocaineBufferIndex += numSamples;
//        }
    }];
    
    [[OALSimpleAudio sharedInstance] preloadEffect:@"tick1.wav"];
    
    BBVoice *c1 = [[BBVoice alloc] initWithValues:@[ @YES,  @NO,  @NO, @NO ]];
    c1.name = @"C1";
    BBVoice *d1 = [[BBVoice alloc] initWithValues:@[ @NO,  @YES,  @NO, @NO ]];
    d1.name = @"D1";
    BBVoice *e1 = [[BBVoice alloc] initWithValues:@[ @NO,  @NO,  @YES, @NO ]];
    e1.name = @"E1";
    BBVoice *f1 = [[BBVoice alloc] initWithValues:@[ @NO,  @NO,  @NO, @YES ]];
    f1.name = @"F1";
    
    BBGroove *groove = [[BBGroove alloc] init];
    
    groove.voices = @[ c1, d1, e1, f1 ];
    groove.tempo = 240;
    
    // 4/4 time
    groove.beats = 4;
    groove.beatUnit = BBGrooverBeatQuarter;
    
    _groover = [BBGroover grooverWithGroove:groove];
    _groover.delegate = self;
    
    _metronome = [TFMetronome metronomeWithTempo:60];
    _metronome.delegate = self;
}

- (IBAction)startTimer:(id)sender
{
    NSLog(@"startTimer:");
//    [novocaine play];

//    [TPPreciseTimer scheduleAction:@selector(startGrooving) target:self inTimeInterval:1.0];
    [_metronome start];
}

- (void)startGrooving
{
//    float bpm = 240.0 / 60.0;
//    float bpmInterval = 1.0 / bpm;
//    [TPPreciseTimer scheduleAction:@selector(dequeueAction) target:self inTimeInterval:bpmInterval];
    NSLog(@"startGrooving");
    [_groover startGrooving];
    novocaineBufferIndex = 0;
}

- (void)dequeueAction
{
    NSLog(@"dequeueAction:%d", novocaineBufferIndex);
    [[OALSimpleAudio sharedInstance] playEffect:@"tick1.wav"];
    
    float bpm = 240.0 / 60.0;
    float bpmInterval = 1.0 / bpm;
    if ([actionsQueue count] > 1)
    [TPPreciseTimer scheduleAction:@selector(dequeueAction) target:self inTimeInterval:bpmInterval];
    
    NSLog(@"%@", [actionsQueue objectAtIndex:0]);
    [actionsQueue removeObjectAtIndex:0];
    
    [self analyseAudioBuffer];
    
    if ([actionsQueue count])
        return;

    [novocaine pause];
}

- (void)analyseAudioBuffer
{
    NSLog(@"analyseAudioBuffer:%d", novocaineBufferIndex);
    int audioBufferSize = novocaineBufferIndex;
    float *audioBuffer = (float *)malloc(audioBufferSize * sizeof(float));
    //    @synchronized(self) {
    memcpy(audioBuffer, novocaineBuffer, audioBufferSize * sizeof(float));
    novocaineBufferIndex = 0;
    //    }
    
    //    ((44032 - 4028) / 2) * 2
    int analysisCount = 2;
    int analysisBufferSize = 4096;
    for (int i = 0; i <= analysisCount; i++) {
        int analysisBufferOffset = ((audioBufferSize - analysisBufferSize) / analysisCount) * i;
        float *analysisBuffer = (float *)malloc(analysisBufferSize * sizeof(float));
        memcpy(analysisBuffer, audioBuffer + analysisBufferOffset, analysisBufferSize * sizeof(float));
        
        TFMpmFrequencyAnalysis *mpmAnalysis = [[TFMpmFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:analysisBufferSize];
        float mpmFrequency = [mpmAnalysis frequencyWithAudioBuffer:analysisBuffer];
        NSLog(@"MPM %d:%f", analysisBufferOffset, mpmFrequency);
        
        free(analysisBuffer);
    }
    
    free(audioBuffer);
}

#pragma mark TFMetronomeDelegate Methods

- (void)metronome:(TFMetronome *)metronome didTick:(NSUInteger)tick {
    NSLog(@"metronome:didTick:%ld", tick);
    [[OALSimpleAudio sharedInstance] playEffect:@"tick1.wav"];
}

#pragma mark BBGrooverDelegate Methods

- (void) groover:(BBGroover *)sequencer didTick:(NSUInteger)tick {
    NSLog(@"groover:didTick:%ld", tick);
    [[OALSimpleAudio sharedInstance] playEffect:@"tick1.wav"];
    [self analyseAudioBuffer];
}

- (void) groover:(BBGroover *)sequencer voicesDidTick:(NSArray *)voices {
    for (BBVoice *voice in voices) {
        NSLog(@"%@", voice.name);
    }
}


@end
