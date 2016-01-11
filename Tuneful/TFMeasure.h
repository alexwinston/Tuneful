//
//  TFMeasure.h
//  Tuneful
//
//  Created by Alex Winston on 4/5/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TFTimeSignature.h"

@interface TFMeasure : NSObject

#pragma mark Initializers

// TODO Clef, http://en.wikipedia.org/wiki/Note
- (id)initWithTimeSignature:(TFTimeSignature *)timeSignature notes:(NSArray *)notes;
+ (id)measureWithTimeSignature:(TFTimeSignature *)timeSignature notes:(NSArray *)notes;

@end
