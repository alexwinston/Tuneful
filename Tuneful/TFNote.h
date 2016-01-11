//
//  TFNote.h
//  Tuneful
//
//  Created by Alex Winston on 4/5/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>

// http://en.wikipedia.org/wiki/Accidental_(music)
typedef enum TFNoteAccidental : NSUInteger {
    TFNoteAccidentalNone       = 0,
    TFNoteAccidentalSharp      = 1,
    TFNoteAccidentalFlat       = 2,
    TFNoteAccidentalNatural    = 3
} TFNoteAccidental;

// http://en.wikipedia.org/wiki/Note
// http://en.wikipedia.org/wiki/Note_value
// http://en.wikipedia.org/wiki/Scientific_pitch_notation
@interface TFNote : NSObject

#pragma mark Initializers

- (id)initWithName:(NSString *)name accidental:(TFNoteAccidental)accidental octave:(int)octave; // ??? Value
+ (id)noteWithName:(NSString *)name accidental:(TFNoteAccidental)accidental octave:(int)octave;

@end
