//
//  TFAnalysis.h
//  Tuneful
//
//  Created by Alex Winston on 3/11/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <AudioToolbox/AudioToolbox.h>
#import <Foundation/Foundation.h>

@interface TFAnalysis : NSObject
{
@private
    float _sampleRate;
    
    int _audioBufferCapacity;
    int _magnitudeBufferCapacity;
    
    int _log2n;
    int _nOver2;
    COMPLEX_SPLIT _A;
    FFTSetup _fftSetup;
	
    float *_hannWindowBuffer;
    float *_hannBuffer;
    float *_magnitudeBuffer;
}
- (id)initWithSampleRate:(float)sampleRate audioBufferCapacity:(int)audioBufferCapacity;
- (float)frequencyWithAudioBuffer:(float *)audioBuffer;
- (float)frequencyWithMagnitudesSquared:(float *)magnitudes length:(int)length;
@end
