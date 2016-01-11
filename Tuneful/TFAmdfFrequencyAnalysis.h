//
//  TFAmdfFrequencyAnalysis.h
//  Tuneful
//
//  Created by Alex Winston on 3/14/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TFAmdfFrequencyAnalysis : NSObject
{
    @private
    float _sampleRate;
    int _audioBufferSize;
    double _ratio;
    double _sensitivity;
    long _maxPeriod;
    long _minPeriod;
    double *_amd;
    int _amdSize;
}
- (TFAmdfFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize;
- (float)frequencyWithAudioBuffer:(float *)audioBuffer;
@end
