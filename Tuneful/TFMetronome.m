//
//  TFMetronome.m
//  Tuneful
//
//  Created by Alex Winston on 4/4/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFMetronome.h"
#include <mach/mach_time.h>

@implementation TFMetronome

#pragma mark Initializers

- (id)initWithTempo:(int)bpm
{
    self = [super init];
    
    if (self) {
        _bpm = bpm;
    }
    
    return self;
}

+ (id)metronomeWithTempo:(int)bpm
{
	return [[self alloc] initWithTempo:bpm];
}

#pragma mark Methods

- (void)start
{
    if (!_ticking) {
        _ticking = YES;
        [NSThread detachNewThreadSelector:@selector(tick:) toTarget:self withObject:@(0)];
    }
}

- (void)stop
{
    _ticking = NO;
}

#pragma mark Private Methods

- (uint64_t)interval
{
    // The default interval we're working with is 1 second (1 billion nanoseconds)
    uint64_t interval = 1000 * 1000 * 1000;
    
    // We find what fraction of a second the tempo really is. For example, a tempo of 60
    // would be 60/60 == 1 second, a tempo of 61 would be 60/61 == 0.984, etc.
    double intervalFraction = 60.0/_bpm;
    
    // Turn this back into nanoseconds
    interval = (uint64_t)(interval * intervalFraction);
    
    return interval;
}

- (void)tick:(NSNumber *)tick
{
    NSLog(@"tick:%d", [tick intValue]);
    _currentTick = [tick unsignedIntValue];
    
    uint64_t interval = [self interval];
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    uint64_t currentTime = mach_absolute_time();
    
    currentTime *= info.numer;
    currentTime /= info.denom;
    
    uint64_t nextTime = currentTime;
    
    // Save ourselves a function call within the loop
    dispatch_queue_t mainQueue = dispatch_get_main_queue();
    
    while (_ticking) {
        if (currentTime >= nextTime) {
            NSUInteger blockTick = _currentTick;
            
            dispatch_async(mainQueue, ^{
                [_delegate metronome:self didTick:blockTick];
            });
            
            _currentTick++;
            interval = [self interval];
            nextTime += interval;
        }
        
        usleep(1000);
        
        currentTime = mach_absolute_time();
        currentTime *= info.numer;
        currentTime /= info.denom;
    }
}

@end
