//
//  TFAnalysis.m
//  Tuneful
//
//  Created by Alex Winston on 3/11/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFAnalysis.h"

@implementation TFAnalysis

void writeToFile(float *array, int arraySize, NSString *fileName) {
    NSMutableString *arrayString = [NSMutableString string];
    for (int i = 0; i < arraySize; i++)
        [arrayString appendFormat:@"%f\n", array[i]];
    
    [arrayString writeToFile:fileName
                  atomically:YES
                    encoding:NSUTF8StringEncoding
                       error:nil];
}

float MagnitudeSquared(float x, float y) {
	return sqrtf((x * x) + (y * y));
}

-(id) initWithSampleRate:(float)sampleRate audioBufferCapacity:(int)audioBufferCapacity {
    self = [super init];
    if (self) {
        _sampleRate = sampleRate;
        
        _audioBufferCapacity = audioBufferCapacity;
        _magnitudeBufferCapacity = (_audioBufferCapacity / 2);
        
        _hannBuffer = (float *)malloc(_audioBufferCapacity * sizeof(float));
        _hannWindowBuffer = (float *)malloc(_audioBufferCapacity * sizeof(float));
        _magnitudeBuffer = (float *)malloc(_magnitudeBufferCapacity * sizeof(float));
        
        _log2n = log2f(_audioBufferCapacity);
        int n = 1 << _log2n;
        assert(n == _audioBufferCapacity);
        
        _nOver2 = _audioBufferCapacity / 2;

        _A.realp = (float *)malloc(_nOver2 * sizeof(float));
        _A.imagp = (float *)malloc(_nOver2 * sizeof(float));
        _fftSetup = vDSP_create_fftsetup(_log2n, FFT_RADIX2);
    }
    return self;
}

// Works starting at about E4, 329.6
- (float)frequencyWithAudioBufferNew:(float *)audioBuffer {
    // Hann window
    memset(_hannWindowBuffer, 0, _audioBufferCapacity * sizeof(float));
    vDSP_hann_window(_hannWindowBuffer, _audioBufferCapacity, vDSP_HANN_NORM);
    memset(_hannBuffer, 0, _audioBufferCapacity * sizeof(float));
    vDSP_vmul(audioBuffer, 1, _hannWindowBuffer, 1, _hannBuffer, 1, _audioBufferCapacity);
    
    /**
     Look at the real signal as an interleaved complex vector by casting it.
     Then call the transformation function vDSP_ctoz to get a split complex
     vector, which for a real signal, divides into an even-odd configuration.
     */
    vDSP_ctoz((COMPLEX *)_hannBuffer, 2, &_A, 1, _nOver2);
    
    // Carry out a Forward FFT transform.
    vDSP_fft_zrip(_fftSetup, &_A, 1, _log2n, FFT_FORWARD);
    
    // The output signal is now in a split real form. Use the vDSP_ztoc to get
    // a split real vector.
    vDSP_ztoc(&_A, 1, (COMPLEX *)_hannBuffer, 2, _nOver2);
    
    float dominantFrequency = 0;
    int bin = -1;
    for (int i = 0, j = 0; i< _audioBufferCapacity; i += 2, j++) {
        float currentFrequency = MagnitudeSquared(_hannBuffer[i], _hannBuffer[i + 1]);
        if (currentFrequency > dominantFrequency) {
            dominantFrequency = currentFrequency;
            bin = (i + 1) / 2;
        }
    }
    
    float currentFrequency = bin * (_sampleRate / _audioBufferCapacity);
    return currentFrequency;
}

- (float)frequencyWithAudioBuffer:(float *)audioBuffer {
    // Hann window
    memset(_hannWindowBuffer, 0, _audioBufferCapacity * sizeof(float));
    vDSP_hann_window(_hannWindowBuffer, _audioBufferCapacity, vDSP_HANN_NORM);
    memset(_hannBuffer, 0, _audioBufferCapacity * sizeof(float));
    vDSP_vmul(audioBuffer, 1, _hannWindowBuffer, 1, _hannBuffer, 1, _audioBufferCapacity);
    
    /**
     Look at the real signal as an interleaved complex vector by casting it.
     Then call the transformation function vDSP_ctoz to get a split complex
     vector, which for a real signal, divides into an even-odd configuration.
     */
    vDSP_ctoz((COMPLEX *)_hannBuffer, 2, &_A, 1, _nOver2);
    
    // Carry out a Forward FFT transform.
    vDSP_fft_zrip(_fftSetup, &_A, 1, _log2n, FFT_FORWARD);
    
    // The output signal is now in a split real form. Use the vDSP_ztoc to get
    // a split real vector.
    vDSP_ztoc(&_A, 1, (COMPLEX *)_hannBuffer, 2, _nOver2);
    
    // Determine the dominant frequency by taking the magnitude squared and
    // saving the bin which it resides in.
    memset(_magnitudeBuffer, 0, _magnitudeBufferCapacity * sizeof(float));
    
    float dominantFrequency = 0;
    int bin = -1;
    for (int i = 0, j = 0; i< _audioBufferCapacity; i += 2, j++) {
        float currentFrequency = MagnitudeSquared(_hannBuffer[i], _hannBuffer[i + 1]);
        if (currentFrequency > dominantFrequency) {
            dominantFrequency = currentFrequency;
            bin = (i + 1) / 2;
        }
        
        _magnitudeBuffer[j] = currentFrequency;
    }
    
    return [self frequencyWithMagnitudesSquared:_magnitudeBuffer length:_magnitudeBufferCapacity];
}

- (float)frequencyWithMagnitudesSquared:(float *)magnitudes length:(int)magnitudesLength
{
    writeToFile(_magnitudeBuffer, _magnitudeBufferCapacity, @"/Users/alexwinston/Desktop/Tuneful/tf_mag.txt");

    float dominantMagnitude = 0;
    
    int bin = -1;
    for (int i = 0; i < magnitudesLength; i++) {
        float currentMagnitude = magnitudes[i];        
        if (currentMagnitude > dominantMagnitude) {
            dominantMagnitude = currentMagnitude;
            bin = i;
        }
    }
    
    const int peakBinsSize = 3;
    int peakBins[peakBinsSize] = { 0 };
    for (int i = 0; i < magnitudesLength - 3; i++) {
        if (magnitudes[i - 2] < magnitudes[i - 1] &&
            magnitudes[i - 1] < magnitudes[i] &&
            magnitudes[i] > magnitudes[i + 1] &&
            magnitudes[i + 1] > magnitudes[i + 2]) {
            float currentMagnitude = magnitudes[i];
            
            if (currentMagnitude > dominantMagnitude / 10)
                for (int j = 0; j < peakBinsSize; j++) {
                    if (currentMagnitude > magnitudes[peakBins[j]]) {
                        // Push values less than current magnitude down
                        for (int k = peakBinsSize - 1; k > j; k--) {
                            peakBins[k] = peakBins[k - 1];
                        }
                        
                        peakBins[j] = i;
                        break;
                    }
                }
        }
    }
    
    for (int i = 0; i < peakBinsSize; i ++) {
        printf("FREQ:%f ", peakBins[i] * (_sampleRate / _audioBufferCapacity));
    }
    printf("\n");
    
    float currentFrequency = bin * (_sampleRate / _audioBufferCapacity);
    float minimumDifferenceFrequency = currentFrequency;
    for (int i = 1; i < peakBinsSize; i++) {
        float currentPeakFrequency = peakBins[i] * (_sampleRate / _audioBufferCapacity);
        if (fabs(currentFrequency - currentPeakFrequency) < minimumDifferenceFrequency) {
            // Try to restrict tha adjustment to a sensible harmonic subset
            if (fabs(currentFrequency - currentPeakFrequency) > currentFrequency / 5)
                minimumDifferenceFrequency = fabs(currentFrequency - currentPeakFrequency);
        }
    }
    
    float frequencyDivider = floor((currentFrequency / minimumDifferenceFrequency) + 0.5);
    
    printf("DOMINANT:%f ADJUSTED:%f BIN:%d\n", currentFrequency, currentFrequency / frequencyDivider, bin);
    
    return currentFrequency / frequencyDivider;
}
@end
