//
//  TFMpmFrequencyAnalysis.m
//  Tuneful
//
//  Created by Alex Winston on 3/19/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFMpmFrequencyAnalysis.h"
#import "TFAnalysis.h"
#include "fftpack.h"

@implementation TFMpmFrequencyAnalysis

- (TFMpmFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize
{
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _sampleRateMultiplier = 44100 / _sampleRate;
        _audioBufferSize = audioBufferSize;
        _cutoff = 0.97;
        _smallCutoff = 0.5;
        _lowerPitchCutoff = 30.87; //27.5; //80.0;
        _nsdf = (float *)malloc(_audioBufferSize * sizeof(float));
//        memset(_nsdf, 0, _audioBufferSize * sizeof(float));
        
        _maxPositions = [NSMutableArray array];
        _periodEstimates = [NSMutableArray array];
        _ampEstimates = [NSMutableArray array];
    }
    return self;
}

/**
 * Implements the normalized square difference function. See section 4 (and
 * the explanation before) in the MPM article. This calculation can be
 * optimized by using an FFT. The results should remain the same.
 *
 * @param audioBuffer
 *            The buffer with audio information.
 */
- (void)normalizedSquareDifference:(float *)audioBuffer
{
    NSLog(@"normalizedSquareDifference");
    for (int tau = 0; tau < _audioBufferSize; tau++) {
        float acf = 0;
        float divisorM = 0;
        for (int i = 0; i < _audioBufferSize - tau; i++) {
            acf += audioBuffer[i] * audioBuffer[i + tau];
            divisorM += audioBuffer[i] * audioBuffer[i] + audioBuffer[i + tau] * audioBuffer[i + tau];
        }
        _nsdf[tau] = 2 * acf / divisorM;
    }
    NSLog(@"normalizedSquareDifference");
}

// https://bitbucket.org/jpommier/pffft
- (void)normalizedSquareDifferenceFFT:(float *)audioBuffer
{
    NSLog(@"normalizedSquareDifferenceFFT");
//    writeToFile(audioBuffer, _audioBufferSize, @"/Users/alexwinston/Desktop/Tuneful/tf_buf.txt");
//    _fft->forward(0, audioBuffer, _nsdf, nil);
//    float *fft = new float[_audioBufferSize * 2];
    float *fft = (float *)malloc((_audioBufferSize * 2) * sizeof(float));
    memset(fft, 0, (_audioBufferSize * 2) * sizeof(float));
    for (int i = 0; i < _audioBufferSize; i++)
        fft[i] = audioBuffer[i];
//    pkmFFT *zeroPaddedFFT = new pkmFFT(_audioBufferSize * 2);
//    zeroPaddedFFT->nsdf(fft, fft);
    int ndim1 = _audioBufferSize * 2;
//    float *wavetable1 = new float[2*ndim1 + 15];
    float *wavetable1 = (float *)malloc((2 * ndim1 + 15) * sizeof(float));
    memset(wavetable1, 0, (2 * ndim1 + 15) * sizeof(float));
    rffti(ndim1, wavetable1);
    rfftf(ndim1, fft, wavetable1);
//    writeToFile(fft, _audioBufferSize, @"/Users/alexwinston/Desktop/Tuneful/tf_fft.txt");
    
//    float *acf = new float[_audioBufferSize];
    float *acf = (float *)malloc(_audioBufferSize * sizeof(float));
    memset(acf, 0, _audioBufferSize * sizeof(float));
//    acf[0] = fft[0] * fft[0] / (2 * _audioBufferSize);
    acf[0] = fft[0] * fft[0] / (2 * _audioBufferSize);
    for(int k = 1; k <= _audioBufferSize - 1; k++) {
//        acf[k] = (fft[2*k-1] * fft[2*k-1] + fft[2*k] * fft[2*k]) / (2*_audioBufferSize);
        acf[k] = (fft[2 * k-1] * fft[2 * k-1] + fft[2 * k] * fft[2 * k]) / (2 * _audioBufferSize);
    }
//    writeToFile(acf, _audioBufferSize, @"/Users/alexwinston/Desktop/Tuneful/tf_acf.txt");
    
    int ndim = _audioBufferSize;
//    float *wavetable = new float[3 * ndim + 15];
    float *wavetable = (float *)malloc((3 * ndim + 15) * sizeof(float));
    memset(wavetable, 0, (3 * ndim + 15) * sizeof(float));
    costi(ndim, wavetable);
    cost(ndim, acf, wavetable);
//    _fft->inverseD(acf);
//    [self normalizedSquareDifference:audioBuffer];
//    writeToFile(acf, _audioBufferSize, @"/Users/alexwinston/Desktop/Tuneful/tf_ifft.txt");

//    float *divisorM = new float[_audioBufferSize];
    float *divisorM = (float *)malloc(_audioBufferSize * sizeof(float));
    memset(divisorM, 0, _audioBufferSize * sizeof(float));
    for (int tau = 0; tau < _audioBufferSize; tau++) {
        // subtract the first and last squared values from the previous divisor to get the new one;
//        double m = tau == 0 ? 2*acf[0] : divisorM[tau-1] - data[n-tau]*data[n-tau] - data[tau-1]*data[tau-1];
        float m = tau == 0 ? 2 * acf[0] : divisorM[tau-1] - audioBuffer[_audioBufferSize-tau] * audioBuffer[_audioBufferSize-tau] - audioBuffer[tau-1] * audioBuffer[tau-1];
        divisorM[tau] = m;
        _nsdf[tau] = 2 * acf[tau] / m;
    }
//    writeToFile(_nsdf, _audioBufferSize, @"/Users/alexwinston/Desktop/Tuneful/tf_nsdf.txt");
    
    free(fft);
    free(wavetable1);
    free(acf);
    free(wavetable);
    free(divisorM);
    
    NSLog(@"normalizedSquareDifferenceFFT");
}

/**
 * <p>
 * Implementation based on the GPL'ED code of <a
 * href="http://tartini.net">Tartini</a> This code can be found in the file
 * <code>general/mytransforms.cpp</code>.
 * </p>
 * <p>
 * Finds the highest value between each pair of positive zero crossings.
 * Including the highest value between the last positive zero crossing and
 * the end (if any). Ignoring the first maximum (which is at zero). In this
 * diagram the desired values are marked with a +
 * </p>
 *
 * <pre>
 *  f(x)
 *   ^
 *   |
 *  1|               +
 *   | \      +     /\      +     /\
 *  0| _\____/\____/__\/\__/\____/_______> x
 *   |   \  /  \  /      \/  \  /
 * -1|    \/    \/            \/
 *   |
 * </pre>
 *
 * @param nsdf
 *            The array to look for maximum values in. It should contain
 *            values between -1 and 1
 * @author Phillip McLeod
 */
- (void)peakPicking
{
    int pos = 0;
    int curMaxPos = 0;
    
    // find the first negative zero crossing
    while (pos < (_audioBufferSize - 1) / 3 && _nsdf[pos] > 0) {
        pos++;
    }
    
    // loop over all the values below zero
    while (pos < _audioBufferSize - 1 && _nsdf[pos] <= 0.0) {
        pos++;
    }
    
    // can happen if output[0] is NAN
    if (pos == 0) {
        pos = 1;
    }
    
    while (pos < _audioBufferSize - 1) {
//        assert(_nsdf[pos] >= 0);
        if (_nsdf[pos] > _nsdf[pos - 1] && _nsdf[pos] >= _nsdf[pos + 1]) {
            if (curMaxPos == 0) {
                // the first max (between zero crossings)
                curMaxPos = pos;
            } else if (_nsdf[pos] > _nsdf[curMaxPos]) {
                // a higher max (between the zero crossings)
                curMaxPos = pos;
            }
        }
        pos++;
        // a negative zero crossing
        if (pos < _audioBufferSize - 1 && _nsdf[pos] <= 0) {
            // if there was a maximum add it to the list of maxima
            if (curMaxPos > 0) {
                [_maxPositions addObject:[NSNumber numberWithInt:curMaxPos]];
                curMaxPos = 0; // clear the maximum position, so we start
                // looking for a new ones
            }
            while (pos < _audioBufferSize - 1 && _nsdf[pos] <= 0.0f) {
                pos++; // loop over all the values below zero
            }
        }
    }
    if (curMaxPos > 0) { // if there was a maximum in the last part
        [_maxPositions addObject:[NSNumber numberWithInt:curMaxPos]]; // add it to the vector of maxima
    }
}

/**
 * <p>
 * Finds the x value corresponding with the peak of a parabola.
 * </p>
 * <p>
 * a,b,c are three samples that follow each other. E.g. a is at 511, b at
 * 512 and c at 513; f(a), f(b) and f(c) are the normalized square
 * difference values for those samples; x is the peak of the parabola and is
 * what we are looking for. Because the samples follow each other
 * <code>b - a = 1</code> the formula for <a
 * href="http://fizyka.umk.pl/nrbook/c10-2.pdf">parabolic interpolation</a>
 * can be simplified a lot.
 * </p>
 * <p>
 * The following ASCII ART shows it a bit more clear, imagine this to be a
 * bit more curvaceous.
 * </p>
 *
 * <pre>
 *     nsdf(x)
 *       ^
 *       |
 * f(x)  |------ ^
 * f(b)  |     / |\
 * f(a)  |    /  | \
 *       |   /   |  \
 *       |  /    |   \
 * f(c)  | /     |    \
 *       |_____________________> x
 *            a  x b  c
 * </pre>
 *
 * @param tau
 *            The delay tau, b value in the drawing is the tau value.
 */
- (void)prabolicInterpolation:(NSInteger)tau
{
    float nsdfa = _nsdf[tau - 1];
    float nsdfb = _nsdf[tau];
    float nsdfc = _nsdf[tau + 1];
    float bValue = tau;
    float bottom = nsdfc + nsdfa - 2 * nsdfb;
    if (bottom == 0.0) {
        _turningPointX = bValue;
        _turningPointY = nsdfb;
    } else {
        float delta = nsdfa - nsdfc;
        _turningPointX = bValue + delta / (2 * bottom);
        _turningPointY = nsdfb - delta * delta / (8 * bottom);
    }
}

- (float)frequencyWithAudioBuffer:(float *)audioBuffer
{
    memset(_nsdf, 0, _audioBufferSize * sizeof(float));
    
    float pitch;
    
    // 0. Clear previous results (Is this faster than initializing a list
    // again and again?)
//    [_maxPositions removeAllObjects];
//    [_periodEstimates removeAllObjects];
//    [_ampEstimates removeAllObjects];
    _maxPositions = [NSMutableArray array];
    _periodEstimates = [NSMutableArray array];
    _ampEstimates = [NSMutableArray array];
    
    // 1. Calculate the normalized square difference for each Tau value.
    [self normalizedSquareDifferenceFFT:audioBuffer];
    // 2. Peak picking time: time to pick some peaks.
    [self peakPicking];
    
    double highestAmplitude = -DBL_MAX; //Double.NEGATIVE_INFINITY;
    
    for (NSNumber *tau in _maxPositions) {
        NSInteger tauValue = [tau integerValue];
        // make sure every annotation has a probability attached
        highestAmplitude = fmax(highestAmplitude, _nsdf[tauValue]);
        
        if (_nsdf[tauValue] > _smallCutoff) {
            // calculates turningPointX and Y
            [self prabolicInterpolation:tauValue];
            // store the turning points
//            ampEstimates.add(turningPointY);
            [_ampEstimates addObject:[NSNumber numberWithFloat:_turningPointY]];
//            periodEstimates.add(turningPointX);
            [_periodEstimates addObject:[NSNumber numberWithFloat:_turningPointX]];
            // remember the highest amplitude
            highestAmplitude = fmax(highestAmplitude, _turningPointY);
        }
    }
    
    if ([_periodEstimates count] == 0) {// isEmpty()) {
        pitch = -1;
    } else {
        // use the overall maximum to calculate a cutoff.
        // The cutoff value is based on the highest value and a relative
        // threshold.
        double actualCutoff = _cutoff * highestAmplitude;
        
        // find first period above or equal to cutoff
        int periodIndex = 0;
        for (int i = 0; i < [_ampEstimates count]; i++) {
            if ([[_ampEstimates objectAtIndex:i] floatValue] >= actualCutoff) {
                periodIndex = i;
                break;
            }
        }
        
        double period = [[_periodEstimates objectAtIndex:periodIndex] floatValue];
        float pitchEstimate = (float) (_sampleRate / period);
        if (pitchEstimate > _lowerPitchCutoff) {
            pitch = pitchEstimate;
        } else {
            pitch = -1;
        }
        
    }
//    result.setProbability((float) highestAmplitude);
//    result.setPitch(pitch);
//    result.setPitched(pitch != -1);
    
    return pitch * _sampleRateMultiplier;
}

@end
