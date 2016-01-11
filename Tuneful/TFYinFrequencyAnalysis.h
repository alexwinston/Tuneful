//
//  TFYinFrequencyAnalysis.h
//  Tuneful
//
//  Created by Alex Winston on 3/18/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TFYinFrequencyAnalysis : NSObject
{
    @private    
    double _threshold;
    float _sampleRate;
    float _sampleRateMultiplier;
    int _yinBufferSize;
    float *_yinBuffer;
}
- (TFYinFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize;
- (float)frequencyWithAudioBuffer:(float *)audioBuffer;
@end
