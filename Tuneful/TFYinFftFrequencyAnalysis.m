//
//  TFYinFftFrequencyAnalysis.m
//  Tuneful
//
//  Created by Alex Winston on 3/19/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFYinFftFrequencyAnalysis.h"
#include "fftpack.h"

@implementation TFYinFftFrequencyAnalysis

- (TFYinFftFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize
{
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _sampleRateMultiplier = 44100 / sampleRate;
        _audioBufferSize = audioBufferSize;
        _threshold = 0.20;
        _yinBufferSize = audioBufferSize / 2;
        _yinBuffer = (float *)malloc(_yinBufferSize * sizeof(float));
        //        memset(_yinBuffer, 0, _yinBufferSize * sizeof(float));
        //Initializations for FFT difference step
        _fftBufferSize = audioBufferSize * 2;
		_audioBufferFFT = (float *)malloc(_fftBufferSize * sizeof(float));
        _kernel = (float *)malloc(_fftBufferSize * sizeof(float));
        _yinStyleACF = (float *)malloc(_fftBufferSize * sizeof(float));
    }
    return self;
}

- (void)dealloc
{
    free(_yinBuffer);
    free(_audioBufferFFT);
    free(_kernel);
    free(_yinStyleACF);
}

/**
 * Implements the difference function as described in step 2 of the YIN
 * paper with an FFT to reduce the number of operations.
 */
-(void)difference:(float *)audioBuffer
{
    memset(_audioBufferFFT, 0, _fftBufferSize * sizeof(float));
    memset(_kernel, 0, _fftBufferSize * sizeof(float));
    memset(_yinStyleACF, 0, _fftBufferSize * sizeof(float));
    
    // POWER TERM CALCULATION
    // ... for the power terms in equation (7) in the Yin paper
    float *powerTerms = (float *)malloc(_yinBufferSize * sizeof(float)); //new float[yinBuffer.length];
    memset(powerTerms, 0, _yinBufferSize * sizeof(float));
    
    for (int j = 0; j < _yinBufferSize; ++j) {
        powerTerms[0] += audioBuffer[j] * audioBuffer[j];
    }
    // now iteratively calculate all others (saves a few multiplications)
    for (int tau = 1; tau < _yinBufferSize; ++tau) {
        powerTerms[tau] = powerTerms[tau-1] - audioBuffer[tau-1] * audioBuffer[tau-1] + audioBuffer[tau+_yinBufferSize] * audioBuffer[tau+_yinBufferSize];
    }
    
    // YIN-STYLE AUTOCORRELATION via FFT
    // 1. data
    for (int j = 0; j < _audioBufferSize; ++j) {
        _audioBufferFFT[2*j] = audioBuffer[j];
        _audioBufferFFT[2*j+1] = 0;
    }
    
    int ndim = _fftBufferSize;
    
    float *wavetableFft = (float *)malloc((2 * ndim + 15) * sizeof(float));
    memset(wavetableFft, 0, (2 * ndim + 15) * sizeof(float));
    rffti(ndim, wavetableFft);
    rfftf(ndim, _audioBufferFFT, wavetableFft);
    for (int i = _fftBufferSize - 1; i > 1; i--)
        _audioBufferFFT[i] = _audioBufferFFT[i - 1];
    _audioBufferFFT[1] = 0;
//    writeToFile(_audioBufferFFT, 5000, @"/Users/alexwinston/Desktop/Tuneful/tf_fyin_fft.txt");
    
    // 2. half of the data, disguised as a convolution kernel
    for (int j = 0; j < _yinBufferSize; ++j) {
        _kernel[2*j] = audioBuffer[(_yinBufferSize-1)-j];
        _kernel[2*j+1] = 0;
        _kernel[2*j+_audioBufferSize] = 0;
        _kernel[2*j+_audioBufferSize+1] = 0;
    }
    
    float *wavetableKernel = (float *)malloc((2 * ndim + 15) * sizeof(float));
    memset(wavetableKernel, 0, (2 * ndim + 15) * sizeof(float));
    rffti(ndim, wavetableKernel);
    rfftf(ndim, _kernel, wavetableKernel);
    for (int i = _fftBufferSize - 1; i > 1; i--)
        _kernel[i] = _kernel[i - 1];
    _kernel[1] = 0;
//    writeToFile(_kernel, 5000, @"/Users/alexwinston/Desktop/Tuneful/tf_fyin_kern.txt");
    
    // 3. convolution via complex multiplication
    for (int j = 0; j < _audioBufferSize; ++j) {
        _yinStyleACF[2*j]   = _audioBufferFFT[2*j]*_kernel[2*j] - _audioBufferFFT[2*j+1]*_kernel[2*j+1]; // real
        _yinStyleACF[2*j+1] = _audioBufferFFT[2*j+1]*_kernel[2*j] + _audioBufferFFT[2*j]*_kernel[2*j+1]; // imaginary
    }
//    writeToFile(_yinStyleACF, 5000, @"/Users/alexwinston/Desktop/Tuneful/tf_fyin_conv.txt");
    float *wavetableAcf = (float *)malloc((2 * ndim + 15) * sizeof(float));
    memset(wavetableAcf, 0, (2 * ndim + 15) * sizeof(float));
    cffti(ndim / 2, wavetableAcf);
    cfftb(ndim / 2, _yinStyleACF, wavetableAcf);
//    writeToFile(_yinStyleACF, 5000, @"/Users/alexwinston/Desktop/Tuneful/tf_fyin_acf.txt");
    
    // Scale
    int n = _audioBufferSize;
    float norm = (float)(1.0 / _audioBufferSize);
    int n2 = 2 * n;
    for (int i = 0; i < n2; i++) {
        _yinStyleACF[i] *= norm;
    }
    
    // CALCULATION OF difference function
    // ... according to (7) in the Yin paper.
    for (int j = 0; j < _yinBufferSize; ++j) {
        // taking only the real part
        _yinBuffer[j] = powerTerms[0] + powerTerms[j] - 2 * _yinStyleACF[2 * (_yinBufferSize - 1 + j)];
    }
//    writeToFile(_yinBuffer, _yinBufferSize, @"/Users/alexwinston/Desktop/Tuneful/tf_fyin_diff.txt");
    
    //    free(ip);
    //    free(w);
    free(wavetableFft);
    free(wavetableKernel);
    free(wavetableAcf);
    free(powerTerms);
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
