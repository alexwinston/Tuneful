//
//  TFViewController.h
//  Tuneful
//
//  Created by Alex Winston on 3/27/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Novocaine.h"
#import "BBGroover.h"
#import "TFMetronome.h"

@interface TFViewController : NSViewController<BBGrooverDelegate, TFMetronomeDelegate>
{
    @private
    int sampleRate;
    
    NSTimer *actionTimer;
    NSMutableArray *actionsQueue;
    
    int novocaineBufferSize;
    float *novocaineBuffer;
    int novocaineBufferIndex;
    Novocaine *novocaine;
    
    BBGroover *_groover;
    
    TFMetronome *_metronome;
}
- (IBAction)startTimer:(id)sender;
@end
