//
//  TFMetronome.h
//  Tuneful
//
//  Created by Alex Winston on 4/4/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TFMetronomeDelegate;

@interface TFMetronome : NSObject
{
    @private
    int _bpm;
    BOOL _ticking;
    int _currentTick;
}

@property (nonatomic, assign) NSObject<TFMetronomeDelegate> *delegate;

#pragma mark Initializers

- (id)initWithTempo:(int)bpm;
+ (id)metronomeWithTempo:(int)bpm;

#pragma mark Methods

- (void) start;
- (void) stop;

@end

@protocol TFMetronomeDelegate <NSObject>

- (void)metronome:(TFMetronome *)metronome didTick:(NSUInteger)tick;

@end
