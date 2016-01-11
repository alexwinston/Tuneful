//
//  TFComposition.h
//  Tuneful
//
//  Created by Alex Winston on 4/5/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFMetronome.h"
#import "TFTimeSignature.h"

@interface TFComposition : NSObject

#pragma mark Initializers

- (id)initWithMetronome:(TFMetronome *)metronome measures:(NSArray *)measures;
+ (id)compositionWithMetronome:(TFMetronome *)metronome measures:(NSArray *)measures;

@end
