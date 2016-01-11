//
//  TFTimeSignature.h
//  Tuneful
//
//  Created by Alex Winston on 4/5/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TFTimeSignature : NSObject

#pragma mark Initializers

- (id)initWithBeat:(int)beat note:(int)note;
+ (id)timeSignatureWithBeat:(int)beat note:(int)note;

@end
