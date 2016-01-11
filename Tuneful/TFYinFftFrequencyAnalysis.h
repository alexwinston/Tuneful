//
//  TFYinFftFrequencyAnalysis.h
//  Tuneful
//
//  Created by Alex Winston on 3/19/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Accelerate/Accelerate.h>
#import <Foundation/Foundation.h>

@interface TFYinFftFrequencyAnalysis : NSObject
{
    @private
    /**
	 * The actual YIN threshold.
	 */
	double _threshold;
    
	/**
	 * The audio sample rate. Most audio has a sample rate of 44.1kHz.
	 */
	float _sampleRate;
    float _sampleRateMultiplier;
    
    int _audioBufferSize;
    
	/**
	 * The buffer that stores the calculated values. It is exactly half the size
	 * of the input buffer.
	 */
	float *_yinBuffer;
    int _yinBufferSize;
    
    int _fftBufferSize;
	/**
	 * Holds the FFT data, twice the length of the audio buffer.
	 */
	float *_audioBufferFFT;
    
	/**
	 * Half of the data, disguised as a convolution kernel.
	 */
	float *_kernel;
    
	/**
	 * Buffer to allow convolution via complex multiplication. It calculates the auto correlation function (ACF).
	 */
	float *_yinStyleACF;
}
- (TFYinFftFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize;
- (float)frequencyWithAudioBuffer:(float *)audioBuffer;
@end
