//
//  TFYinFrequencyAnalysis.m
//  Tuneful
//
//  Created by Alex Winston on 3/18/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFYinFrequencyAnalysis.h"

@implementation TFYinFrequencyAnalysis

- (TFYinFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize
{
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _sampleRateMultiplier = 44100 / sampleRate;
		_threshold = 0.20;
        _yinBufferSize = audioBufferSize / 2;
        _yinBuffer = (float *)malloc(_yinBufferSize * sizeof(float));
//        memset(_yinBuffer, 0, _yinBufferSize * sizeof(float));
    }
    return self;
}

- (void)dealloc
{
    free(_yinBuffer);
}

/**
 * Implements the difference function as described in step 2 of the YIN
 * paper.
 */
- (void)difference:(float *)audioBuffer
{
    int index, tau;
    float delta;
    for (tau = 0; tau < _yinBufferSize; tau++) {
        _yinBuffer[tau] = 0;
    }
    for (tau = 1; tau < _yinBufferSize; tau++) {
        for (index = 0; index < _yinBufferSize; index++) {
            delta = audioBuffer[index] - audioBuffer[index + tau];
            _yinBuffer[tau] += delta * delta;
        }
    }
}

/**
 * The cumulative mean normalized difference function as described in step 3
 * of the YIN paper. <br>
 * <code>
 * yinBuffer[0] == yinBuffer[1] = 1
 * </code>
 */
- (void)cumulativeMeanNormalizedDifference
{
    int tau;
    _yinBuffer[0] = 1;
    float runningSum = 0;
    for (tau = 1; tau < _yinBufferSize; tau++) {
        runningSum += _yinBuffer[tau];
        _yinBuffer[tau] *= tau / runningSum;
    }
}

/**
 * Implements step 4 of the AUBIO_YIN paper.
 */
- (int)absoluteThreshold
{
    // Uses another loop construct
    // than the AUBIO implementation
    int tau;
    // first two positions in yinBuffer are always 1
    // So start at the third (index 2)
    for (tau = 2; tau < _yinBufferSize; tau++) {
        if (_yinBuffer[tau] < _threshold) {
            while (tau + 1 < _yinBufferSize && _yinBuffer[tau + 1] < _yinBuffer[tau]) {
                tau++;
            }
            // found tau, exit loop and return
            // store the probability
            // From the YIN paper: The threshold determines the list of
            // candidates admitted to the set, and can be interpreted as the
            // proportion of aperiodic power tolerated
            // within a periodic signal.
            //
            // Since we want the periodicity and and not aperiodicity:
            // periodicity = 1 - aperiodicity
//            result.setProbability(1 - yinBuffer[tau]);
            break;
        }
    }
    
    
    // if no pitch found, tau => -1
    if (tau == _yinBufferSize || _yinBuffer[tau] >= _threshold) {
        NSLog(@"TAU: %d", tau);
        tau = -1;
//        result.setProbability(0);
//        result.setPitched(false);
    } else {
//        result.setPitched(true);
    }
    
    return tau;
}

/**
 * Implements step 5 of the AUBIO_YIN paper. It refines the estimated tau
 * value using parabolic interpolation. This is needed to detect higher
 * frequencies more precisely. See http://fizyka.umk.pl/nrbook/c10-2.pdf and
 * for more background
 * http://fedc.wiwi.hu-berlin.de/xplore/tutorials/xegbohtmlnode62.html
 *
 * @param tauEstimate
 *            The estimated tau value.
 * @return A better, more precise tau value.
 */
- (float)parabolicInterpolation:(int)tauEstimate {
    float betterTau;
    int x0;
    int x2;
    
    if (tauEstimate < 1) {
        x0 = tauEstimate;
    } else {
        x0 = tauEstimate - 1;
    }
    if (tauEstimate + 1 < _yinBufferSize) {
        x2 = tauEstimate + 1;
    } else {
        x2 = tauEstimate;
    }
    if (x0 == tauEstimate) {
        if (_yinBuffer[tauEstimate] <= _yinBuffer[x2]) {
            betterTau = tauEstimate;
        } else {
            betterTau = x2;
        }
    } else if (x2 == tauEstimate) {
        if (_yinBuffer[tauEstimate] <= _yinBuffer[x0]) {
            betterTau = tauEstimate;
        } else {
            betterTau = x0;
        }
    } else {
        float s0, s1, s2;
        s0 = _yinBuffer[x0];
        s1 = _yinBuffer[tauEstimate];
        s2 = _yinBuffer[x2];
        // fixed AUBIO implementation, thanks to Karl Helgason:
        // (2.0f * s1 - s2 - s0) was incorrectly multiplied with -1
//        betterTau = tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
        betterTau = tauEstimate + (s2 - s0) / (2 * (2 * s1 - s2 - s0));
    }
    return betterTau;
}

- (float)frequencyWithAudioBuffer:(float *)audioBuffer
{
    memset(_yinBuffer, 0, _yinBufferSize * sizeof(float));
    
    int tauEstimate;
    float pitchInHertz;
    
    // step 2
    [self difference:audioBuffer];
    
    // step 3
    [self cumulativeMeanNormalizedDifference];
    
    // step 4
    tauEstimate = [self absoluteThreshold];
    
    // step 5
    if (tauEstimate != -1) {
        float betterTau = [self parabolicInterpolation:tauEstimate];
        
        // step 6
        // TODO Implement optimization for the AUBIO_YIN algorithm.
        // 0.77% => 0.5% error rate,
        // using the data of the YIN paper
        // bestLocalEstimate()
        
        // conversion to Hz
        pitchInHertz = (_sampleRate * _sampleRateMultiplier) / betterTau;
    } else{
        // no pitch found
        pitchInHertz = -1;
    }
    
    return pitchInHertz;
}

@end
