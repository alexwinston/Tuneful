//
//  TFAmdfFrequencyAnalysis.m
//  Tuneful
//
//  Created by Alex Winston on 3/14/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TFAmdfFrequencyAnalysis.h"

@implementation TFAmdfFrequencyAnalysis

- (TFAmdfFrequencyAnalysis *)initWithSampleRate:(float)sampleRate audioBufferSize:(int)audioBufferSize
{
    if (self = [super init]) {
        _sampleRate = sampleRate;
        _audioBufferSize = audioBufferSize;
        _ratio = 0.5;
        _sensitivity = 0.01;
        _maxPeriod = roundl(_sampleRate / 25.96);
        _minPeriod = roundl(_sampleRate / 1000);
        // TODO Ensure that minPeriod doesn't exceed amd length
        _amd = (double *)malloc(_audioBufferSize * sizeof(double));
        memset(_amd, 0, _audioBufferSize * sizeof(double));
    }
    return self;
}

- (void)dealloc
{
//    [super dealloc];
    free(_amd);
}

- (float)frequencyWithAudioBuffer:(float *)audioBuffer
{
    memset(_amd, 0, _audioBufferSize * sizeof(double));
    
    int t = 0;
    float f0 = -1;
    double minval = DBL_MAX;
    double maxval = -DBL_MAX;
    double *frames1 = (double *)malloc(_audioBufferSize * sizeof(double));
    double *frames2 = (double *)malloc(_audioBufferSize * sizeof(double));
    double *calcSub = (double *)malloc(_audioBufferSize * sizeof(double));
    
    int maxShift = _audioBufferSize;
    
    for (int i = 0; i < maxShift; i++) {
        //        frames1 = new double[maxShift - i + 1];
        memset(frames1, 0, maxShift * sizeof(double));
        
        //        frames2 = new double[maxShift - i + 1];
        memset(frames2, 0, maxShift * sizeof(double));
        
        t = 0;
        for (int aux1 = 0; aux1 < maxShift - i; aux1++) {
            //            t = t + 1;
            frames1[t++] = audioBuffer[aux1];
        }
        t = 0;
        for (int aux2 = i; aux2 < maxShift; aux2++) {
            //            t = t + 1;
            frames2[t++] = audioBuffer[aux2];
        }
        
        int frameLength = maxShift - i;
        //        calcSub = new double[frameLength];
        memset(calcSub, 0, maxShift * sizeof(double));
        for (int u = 0; u < frameLength; u++) {
            calcSub[u] = frames1[u] - frames2[u];
        }
        
        double summation = 0;
        for (int l = 0; l < frameLength; l++) {
            //            summation +=  Math.abs(calcSub[l]);
            summation += fabsl(calcSub[l]);
        }
        _amd[i] = summation;
    }
    
    for (int j = (int)_minPeriod; j < (int)_maxPeriod; j++){
        if(_amd[j] < minval){
            minval = _amd[j];
        }
        if(_amd[j] > maxval)	{
            maxval = _amd[j];
        }
    }
    //    int cutoff = (int) Math.round((sensitivity * (maxval - minval)) + minval);
    int cutoff = (int) roundl((_sensitivity * (maxval - minval)) + minval);
    
    int j = (int)_minPeriod;
    while(j <= (int)_maxPeriod && (_amd[j] > cutoff)){
        j = j + 1;
    }
    
    double search_length = _minPeriod / 2;
    minval = _amd[j];
    int minpos = j;
    int i=j;
    while((i < j + search_length) && (i <= _maxPeriod)){
        i=i+1;
        if(_amd[i] < minval){
            minval = _amd[i];
            minpos = i;
        }
    }
    
    //    if(Math.round(amd[minpos] * ratio) < maxval){
    if(roundl(_amd[minpos] * _ratio) < maxval){
        f0 = _sampleRate / minpos;
    }
    
    free(frames1);
    free(frames2);
    free(calcSub);
    
    return f0;
}

@end
