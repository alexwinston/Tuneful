//
//  TunefulTests.m
//  TunefulTests
//
//  Created by Alex Winston on 3/11/13.
//  Copyright (c) 2013 Alex Winston. All rights reserved.
//

#import "TunefulTests.h"
#import "TFAnalysis.h"
#import "TFAmdfFrequencyAnalysis.h"
#import "TFYinFrequencyAnalysis.h"
#import "TFYinFftFrequencyAnalysis.h"
#import "TFMpmFrequencyAnalysis.h"
#include "fann.h"

@implementation TunefulTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (NSArray *)sampleAudioWithFrequency:(float)frequency length:(int)length {
    const double amplitude = 0.5;
    
    NSMutableArray *sampleAudio = [NSMutableArray arrayWithCapacity:length];
    for (int i = 0; i < length; i++)
        [sampleAudio addObject:[NSNumber numberWithFloat:amplitude * sinf(2 * M_PI * (i + 50) * frequency / 44100.0)]];
    
    return sampleAudio;
}

- (NSArray *)noteFrequencies {
    // http://members.efn.org/~qehn/global/building/cents.htm
    NSMutableArray *noteFrequencies = [NSMutableArray arrayWithCapacity:96];
    for (int i = -36; i < 52; i++)
        [noteFrequencies addObject:[NSNumber numberWithFloat:powf(powf(2.0, 1.0/12.0), i) * 220.0]]; //{[(2)^1/12]^n} * 220 Hz
    return noteFrequencies;
}

- (NSString *)noteWithFrequency:(float)frequency {
    float logFrequency = (logf(frequency) - logf(261.626)) / logf(2) + 4.0;
    int floorLogFrequency = floor(logFrequency);
    float cents = 1200 * (logFrequency - floorLogFrequency);
    
//    NSString *notes[] = { @"A", @"Bb", @"B", @"C", @"C#", @"D", @"Eb", @"E", @"F", @"F#", @"G", @"G#" };
    NSString *notes = @"C C#D EbE F F#G G#A BbB ";
    NSMutableString *note = [NSMutableString string];
    
    float offset = 50.0;
    int x = 2;
    if (cents < 50)
    {
        [note appendString:[NSString stringWithFormat:@"%c",[notes characterAtIndex:0]]];
    }
    else if (cents >= 1150)
    {
        [note appendString:[NSString stringWithFormat:@"%c",[notes characterAtIndex:0]]];
        cents -= 1200;
        floorLogFrequency++;
    }
    else
    {
        for (int j = 1 ; j <= 11 ; j++)
        {
            if (cents >= offset && cents < (offset + 100))
            {
                [note appendString:[NSString stringWithFormat:@"%c",[notes characterAtIndex:x]]];
                [note appendString:[NSString stringWithFormat:@"%c",[notes characterAtIndex:x + 1]]];
                cents -= (j * 100);
                break;
            }
            offset += 100;
            x += 2;
        }
    }
    
	return [NSString stringWithFormat:@"%@%d", note, floorLogFrequency];
}

- (void)testNoteWithFrequency
{
    STAssertEqualObjects(@"C0", [self noteWithFrequency:16.35], @"");
    STAssertEqualObjects(@"C#0", [self noteWithFrequency:17.32], @"");
    STAssertEqualObjects(@"D 0", [self noteWithFrequency:18.35], @"");
    STAssertEqualObjects(@"Eb0", [self noteWithFrequency:19.45], @"");
    STAssertEqualObjects(@"E 0", [self noteWithFrequency:20.60], @"");
    STAssertEqualObjects(@"F 0", [self noteWithFrequency:21.83], @"");
    STAssertEqualObjects(@"F#0", [self noteWithFrequency:23.12], @"");
    STAssertEqualObjects(@"G 0", [self noteWithFrequency:24.50], @"");
    STAssertEqualObjects(@"G#0", [self noteWithFrequency:25.96], @"");
    STAssertEqualObjects(@"A 0", [self noteWithFrequency:27.50], @"");
    STAssertEqualObjects(@"Bb0", [self noteWithFrequency:29.14], @"");
    STAssertEqualObjects(@"B 0", [self noteWithFrequency:30.87], @"");
    STAssertEqualObjects(@"C1", [self noteWithFrequency:32.70], @"");
    STAssertEqualObjects(@"C#1", [self noteWithFrequency:34.65], @"");
    STAssertEqualObjects(@"D 1", [self noteWithFrequency:36.71], @"");
    STAssertEqualObjects(@"Eb1", [self noteWithFrequency:38.89], @"");
    STAssertEqualObjects(@"E 1", [self noteWithFrequency:41.20], @"");
    STAssertEqualObjects(@"F 1", [self noteWithFrequency:43.65], @"");
    STAssertEqualObjects(@"F#1", [self noteWithFrequency:46.25], @"");
    STAssertEqualObjects(@"G 1", [self noteWithFrequency:49.00], @"");
    STAssertEqualObjects(@"G#1", [self noteWithFrequency:51.91], @"");
    STAssertEqualObjects(@"A 1", [self noteWithFrequency:55.00], @"");
    STAssertEqualObjects(@"Bb1", [self noteWithFrequency:58.27], @"");
    STAssertEqualObjects(@"B 1", [self noteWithFrequency:61.74], @"");
    STAssertEqualObjects(@"C2", [self noteWithFrequency:65.41], @"");
    STAssertEqualObjects(@"C#2", [self noteWithFrequency:69.30], @"");
    STAssertEqualObjects(@"D 2", [self noteWithFrequency:73.42], @"");
    STAssertEqualObjects(@"Eb2", [self noteWithFrequency:77.78], @"");
    STAssertEqualObjects(@"E 2", [self noteWithFrequency:82.41], @"");
    STAssertEqualObjects(@"C7", [self noteWithFrequency:2093], @"");
    STAssertEqualObjects(@"C8", [self noteWithFrequency:4186], @"");
    STAssertEqualObjects(@"B 8", [self noteWithFrequency:7902], @"");
    
    // Test notes with approximate frequency
    STAssertEqualObjects(@"B 0", [self noteWithFrequency:30.87], @"");
    STAssertEqualObjects(@"B 0", [self noteWithFrequency:31.68], @"");
    STAssertEqualObjects(@"C1", [self noteWithFrequency:32.70], @"");
    STAssertEqualObjects(@"C1", [self noteWithFrequency:33.41], @"");
}

- (void)ignoreTestFFT
{
    float sampleRate = 11025;
    int audioBufferCapacity = 1024 * 4;
    float *audioBuffer = (float *)malloc(audioBufferCapacity * sizeof(float));
    
    float *magnitudesSquared = (float *)malloc(audioBufferCapacity * sizeof(float));
    
    TFAnalysis *tunefulAnalysis = [[TFAnalysis alloc] initWithSampleRate:sampleRate audioBufferCapacity:audioBufferCapacity];
    
    int lineIndex = 0;
    NSString *fileName = [NSString stringWithContentsOfFile:@"/Users/alexwinston/Desktop/Tuneful/e1_fft.txt" encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [fileName componentsSeparatedByString:@"\n"]) {
        magnitudesSquared[lineIndex++] = [line floatValue];
    }
    
    STAssertEqualObjects(@"E 1", [self noteWithFrequency:[tunefulAnalysis frequencyWithMagnitudesSquared:magnitudesSquared length:audioBufferCapacity / 2]], @"");
    free(magnitudesSquared);

    const double amplitude = 0.5;
    // Generate the samples
    for (int frame = 0; frame < audioBufferCapacity; frame++) {
        audioBuffer[frame] = amplitude * sin(2 * M_PI * frame * 41.20 / 11025);
    }
    
    // TODO Double audio buffer capacity to narrow frequency bin deltas, ie 20.60
    STAssertEqualObjects(@"E 1", [self noteWithFrequency:[tunefulAnalysis frequencyWithAudioBuffer:audioBuffer]], @"");
}

- (void)ignoreTestSimpleFFT
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 4;
    NSArray *noteFrequencies = [self noteFrequencies];
    for (NSNumber *noteFrequency in noteFrequencies) {
        float *sampleAudioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
        NSArray *sampleAudio = [self sampleAudioWithFrequency:[noteFrequency floatValue] length:sampleBufferSize];
        for (int i = 0; i < [sampleAudio count]; i++)
            sampleAudioBuffer[i] = [[sampleAudio objectAtIndex:i] floatValue];
        
        NSLog(@"%f", [noteFrequency floatValue]);
        TFAnalysis *frequencyAnalysis = [[TFAnalysis alloc] initWithSampleRate:sampleRate audioBufferCapacity:sampleBufferSize];
        float fftFrequency = [frequencyAnalysis frequencyWithAudioBuffer:sampleAudioBuffer];
        NSLog(@"%f", fftFrequency);
        
        NSLog(@"%@ == %@", [self noteWithFrequency:[noteFrequency floatValue]], [self noteWithFrequency:fftFrequency]);
        free(sampleAudioBuffer);
    }
}


- (void)testSimpleFFTSample
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 4;
    
    float *audioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
    
    int lineIndex = 0;
    NSString *fileName = [NSString stringWithContentsOfFile:@"/Users/alexwinston/Desktop/Tuneful/e1_4096.txt" encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [fileName componentsSeparatedByString:@"\n"]) {
        audioBuffer[lineIndex++] = [line floatValue];
    }
    
    TFAnalysis *frequencyAnalysis = [[TFAnalysis alloc] initWithSampleRate:sampleRate audioBufferCapacity:sampleBufferSize];
    float fftFrequency = [frequencyAnalysis frequencyWithAudioBuffer:audioBuffer];
    NSLog(@"FFT: %f %@", fftFrequency, [self noteWithFrequency:fftFrequency]);
    
    free(audioBuffer);
}

- (void)testYinSample
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 4;
    
    float *audioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
    
    int lineIndex = 0;
    NSString *fileName = [NSString stringWithContentsOfFile:@"/Users/alexwinston/Desktop/Tuneful/e1_4096.txt" encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [fileName componentsSeparatedByString:@"\n"]) {
        audioBuffer[lineIndex++] = [line floatValue];
        if (lineIndex == sampleBufferSize)
            break;
    }
    
    TFYinFftFrequencyAnalysis *frequencyAnalysis = [[TFYinFftFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:sampleBufferSize];
    float yinFrequency = [frequencyAnalysis frequencyWithAudioBuffer:audioBuffer];
    NSLog(@"YIN: %f %@", yinFrequency, [self noteWithFrequency:yinFrequency]);
    
    free(audioBuffer);
}


- (void)ignoreTestYin
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 3;
    NSArray *noteFrequencies = [self noteFrequencies];
    for (NSNumber *noteFrequency in noteFrequencies) {
        float *sampleAudioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
        NSArray *sampleAudio = [self sampleAudioWithFrequency:[noteFrequency floatValue] length:sampleBufferSize];
        for (int i = 0; i < [sampleAudio count]; i++)
            sampleAudioBuffer[i] = [[sampleAudio objectAtIndex:i] floatValue];
        
        NSLog(@"%f", [noteFrequency floatValue]);
        TFYinFftFrequencyAnalysis *frequencyAnalysis = [[TFYinFftFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:sampleBufferSize];
        float yinFrequency = [frequencyAnalysis frequencyWithAudioBuffer:sampleAudioBuffer];
        NSLog(@"%f", yinFrequency);
        
        NSLog(@"%@ == %@", [self noteWithFrequency:[noteFrequency floatValue]], [self noteWithFrequency:yinFrequency]);
        free(sampleAudioBuffer);
    }
}

- (void)testMpmSample
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 2;

    float *audioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));

    int lineIndex = 0;
    NSString *fileName = [NSString stringWithContentsOfFile:@"/Users/alexwinston/Desktop/Tuneful/e1.txt" encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [fileName componentsSeparatedByString:@"\n"]) {
        audioBuffer[lineIndex++] = [line floatValue];
    }
    
    TFMpmFrequencyAnalysis *frequencyAnalysis = [[TFMpmFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:sampleBufferSize];
    float mpmFrequency = [frequencyAnalysis frequencyWithAudioBuffer:audioBuffer];
    NSLog(@"MPM: %f %@", mpmFrequency, [self noteWithFrequency:mpmFrequency]);

    free(audioBuffer);
}

- (void)ignoreTestMpm
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 4;
    NSArray *noteFrequencies = [self noteFrequencies];
//    NSArray *noteFrequencies = [NSArray arrayWithObject:[NSNumber numberWithFloat:41.2]];
    for (NSNumber *noteFrequency in noteFrequencies) {
        float *sampleAudioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
        NSArray *sampleAudio = [self sampleAudioWithFrequency:[noteFrequency floatValue] length:sampleBufferSize];
        for (int i = 0; i < [sampleAudio count]; i++)
            sampleAudioBuffer[i] = [[sampleAudio objectAtIndex:i] floatValue];
        
        NSLog(@"%f", [noteFrequency floatValue]);
        TFMpmFrequencyAnalysis *frequencyAnalysis = [[TFMpmFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:sampleBufferSize];
        float mpmFrequency = [frequencyAnalysis frequencyWithAudioBuffer:sampleAudioBuffer];
        NSLog(@"%f", mpmFrequency);
        
        NSLog(@"%@ == %@", [self noteWithFrequency:[noteFrequency floatValue]], [self noteWithFrequency:mpmFrequency]);
        free(sampleAudioBuffer);
    }
}

- (void)testAmdf
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 4;
    NSArray *noteFrequencies = [self noteFrequencies];
    //    NSArray *noteFrequencies = [NSArray arrayWithObject:[NSNumber numberWithFloat:51.91]];
    for (NSNumber *noteFrequency in noteFrequencies) {
        float *sampleAudioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
        NSArray *sampleAudio = [self sampleAudioWithFrequency:[noteFrequency floatValue] length:sampleBufferSize];
        for (int i = 0; i < [sampleAudio count]; i++)
            sampleAudioBuffer[i] = [[sampleAudio objectAtIndex:i] floatValue];
        
        // TODO https://github.com/Notnasiul/R2D2-Processing-Pitch/blob/FFT/PitchProject/PitchDetectorAutocorrelation.pde
        NSLog(@"%f", [noteFrequency floatValue]);
        TFAmdfFrequencyAnalysis *frequencyAnalysis = [[TFAmdfFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:sampleBufferSize];
        float mpmFrequency = [frequencyAnalysis frequencyWithAudioBuffer:sampleAudioBuffer];
        NSLog(@"%f", mpmFrequency);
        
        NSLog(@"%@ == %@", [self noteWithFrequency:[noteFrequency floatValue]], [self noteWithFrequency:mpmFrequency]);
        free(sampleAudioBuffer);
    }
}

- (void)testAmdfSample
{
    int sampleRate = 11025 * 4;
    int sampleBufferSize = 1024 * 4;
    
    float *audioBuffer = (float *)malloc(sampleBufferSize * sizeof(float));
    
    int lineIndex = 0;
    NSString *fileName = [NSString stringWithContentsOfFile:@"/Users/alexwinston/Desktop/Tuneful/e1_4096.txt" encoding:NSUTF8StringEncoding error:NULL];
    for (NSString *line in [fileName componentsSeparatedByString:@"\n"]) {
        audioBuffer[lineIndex++] = [line floatValue];
    }
    
    TFAmdfFrequencyAnalysis *frequencyAnalysis = [[TFAmdfFrequencyAnalysis alloc] initWithSampleRate:sampleRate audioBufferSize:sampleBufferSize];
    float mpmFrequency = [frequencyAnalysis frequencyWithAudioBuffer:audioBuffer];
    NSLog(@"AMDF: %f %@", mpmFrequency, [self noteWithFrequency:mpmFrequency]);
    
    free(audioBuffer);
}

- (void)ignoreTestFann
{
    const unsigned int num_input = 2;
    const unsigned int num_output = 1;
    const unsigned int num_layers = 3;
    const unsigned int num_neurons_hidden = 3;
    const float desired_error = (const float) 0.001;
    const unsigned int max_epochs = 500000;
    const unsigned int epochs_between_reports = 1000;
    struct fann *ann = fann_create_standard(num_layers, num_input,
                                            num_neurons_hidden, num_output);
    fann_set_activation_function_hidden(ann, FANN_SIGMOID_SYMMETRIC);
    fann_set_activation_function_output(ann, FANN_SIGMOID_SYMMETRIC);
    NSLog(@"%@", [[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/xor.data"]);
//    fann_train_on_file(ann, [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/xor.data"] UTF8String], max_epochs,
//                       epochs_between_reports, desired_error);
    fann_train_on_file(ann, "xor.data", max_epochs, epochs_between_reports, desired_error);
    fann_save(ann, "xor_float.net");
    fann_destroy(ann);
    
    fann_type *calc_out;
    fann_type input[2];
    struct fann *ann2 = fann_create_from_file("xor_float.net");
    input[0] = -1;
    input[1] = 1;
    calc_out = fann_run(ann2, input);
    printf("xor test (%f,%f) -> %f\n", input[0], input[1], calc_out[0]);
    fann_destroy(ann2);
}

@end
