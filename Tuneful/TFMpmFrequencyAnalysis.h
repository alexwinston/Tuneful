//
//  TFMpmFrequencyAnalysis.h
//  Tuneful
//
//  Created by Alex Winston on 3/19/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TFMpmFrequencyAnalysis : NSObject
{
    @private
    /**
	 * Defines the relative size the chosen peak (pitch) has.
	 */
    double _cutoff;
    double _smallCutoff;
    double _lowerPitchCutoff;
    
	/**
	 * The audio sample rate. Most audio has a sample rate of 44.1kHz.
	 */
	float _sampleRate;
    float _sampleRateMultiplier;
    int _audioBufferSize;
    
	/**
	 * Contains a normalized square difference function value for each delay
	 * (tau).
	 */
	float *_nsdf;
    
	/**
	 * The x and y coordinate of the top of the curve (nsdf).
	 */
	float _turningPointX, _turningPointY;
    
	/**
	 * A list with minimum and maximum values of the nsdf curve.
	 */
	NSMutableArray *_maxPositions;
    
	/**
	 * A list of estimates of the period of the signal (in samples).
	 */
	NSMutableArray *_periodEstimates;
    
	/**
	 * A list of estimates of the amplitudes corresponding with the period
	 * estimates.
	 */
	NSMutableArray *_ampEstimates;
}
- (TFMpmFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize;
- (float)frequencyWithAudioBuffer:(float *)audioBuffer;
@end
