//  Copyright (c) 2014 Michael Groble
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import "SimpleIOUnit.h"
#import "ErrorHandler.h"

@interface SimpleIOUnit()

+ (void) defaultComponentDescription:(AudioComponentDescription*)description;
+ (OSStatus) defaultComponent:(AudioComponent*)component error:(NSError**)error;
+ (OSStatus) initializeDefaultUnit:(AudioComponentInstance*)unit error:(NSError**)error;
#if !TARGET_OS_IPHONE
+ (OSStatus) defaultInputDeviceId:(AudioDeviceID*)device error:(NSError**)error;
#endif


- (OSStatus) handleRenderWithFlags:(AudioUnitRenderActionFlags*) ioActionFlags 
                              time:(const AudioTimeStamp*) inTimeStamp 
                               bus:(UInt32) inBusNumber 
                            frames:(UInt32) inNumberFrames 
                            ioData:(AudioBufferList*) ioData;
- (OSStatus) handleInputWithFlags:(AudioUnitRenderActionFlags*) ioActionFlags 
                              time:(const AudioTimeStamp*) inTimeStamp 
                               bus:(UInt32) inBusNumber 
                            frames:(UInt32) inNumberFrames 
                            ioData:(AudioBufferList*) ioData;

- (OSStatus) initializeAudioUnit:(NSError**)error;
- (OSStatus) initializeOutputUnit:(NSError**)error;
- (OSStatus) initializeInputUnit:(NSError**)error;
- (OSStatus) enableInput:(NSError**)error;
- (OSStatus) disableOutput:(AudioComponentInstance)unit error:(NSError**)error;
- (OSStatus) setDefaultInputDevice:(NSError**)error;
- (OSStatus) getInputDeviceFormat:(AudioStreamBasicDescription*)format error:(NSError**)error;
- (OSStatus) getInputClientFormat:(AudioStreamBasicDescription*)format error:(NSError**)error;
- (OSStatus) configureInputFormat:(const AudioStreamBasicDescription*)inputFormat error:(NSError**)error;
- (OSStatus) setInputFormat:(const AudioStreamBasicDescription*)inputFormat error:(NSError**)error;
- (OSStatus) setOutputFormat:(const AudioStreamBasicDescription*)outputFormat error:(NSError**)error;
- (OSStatus) setInputCallback:(NSError**)error;
- (OSStatus) setRenderCallback:(NSError**)error;
- (OSStatus) setInputBufferAllocation:(UInt32)allocateBuffer error:(NSError**)error;
+ (void) freeBuffers:(AudioBufferList*)buffers;

#if !TARGET_OS_IPHONE
- (OSStatus) setInputDevice:(AudioDeviceID)inputDevice error:(NSError**)error;
#endif

@property(nonatomic) AudioComponentInstance inputUnit;
@property(nonatomic) AudioComponentInstance outputUnit;
@property(nonatomic) AudioBufferList* inputBufferList;

@end


NSString* const AudioToolsErrorDomain = @"me.groble.AudioTools";

enum 
{
  kAudioTools_noDefaultComponentError   = -2000,
  kAudioTools_interleavedNotSupported   = -2001
};

OSStatus simpleIOUnitOnInput(void* inRefCon, 
                             AudioUnitRenderActionFlags* ioActionFlags, 
                             const AudioTimeStamp* inTimeStamp, 
                             UInt32 inBusNumber, 
                             UInt32 inNumberFrames, 
                             AudioBufferList* nullIoData);

OSStatus simpleIOUnitOnRender(void* inRefCon, 
                              AudioUnitRenderActionFlags* ioActionFlags, 
                              const AudioTimeStamp* inTimeStamp, 
                              UInt32 inBusNumber, 
                              UInt32 inNumberFrames, 
                              AudioBufferList* nullIoData);


OSStatus simpleIOUnitOnInput(void* inRefCon, 
                             AudioUnitRenderActionFlags* ioActionFlags, 
                             const AudioTimeStamp* inTimeStamp, 
                             UInt32 inBusNumber, 
                             UInt32 inNumberFrames, 
                             AudioBufferList* nullIoData)
{
  __unsafe_unretained SimpleIOUnit* SELF = (__bridge __unsafe_unretained SimpleIOUnit*)inRefCon;
  
  return [SELF handleInputWithFlags:ioActionFlags time:inTimeStamp bus:inBusNumber frames:inNumberFrames ioData:nullIoData];
}


OSStatus simpleIOUnitOnRender(void* inRefCon, 
                              AudioUnitRenderActionFlags* ioActionFlags, 
                              const AudioTimeStamp* inTimeStamp, 
                              UInt32 inBusNumber, 
                              UInt32 inNumberFrames, 
                              AudioBufferList* ioData)
{
  __unsafe_unretained SimpleIOUnit* SELF = (__bridge __unsafe_unretained SimpleIOUnit*)inRefCon;
  
  return [SELF handleRenderWithFlags:ioActionFlags time:inTimeStamp bus:inBusNumber frames:inNumberFrames ioData:ioData];
}


@implementation SimpleIOUnit
@synthesize inputUnit;
@synthesize outputUnit;
@synthesize renderDelegate;
@synthesize inputDelegate;
@synthesize inputBufferList;
//@synthesize renderBlock;
//@synthesize inputBlock;
@dynamic running;

+ (void) defaultInputFormat:(AudioStreamBasicDescription*)format
{
  NSAssert(format,@"input format must not be nil");
  
  UInt32 bytesPerSample = sizeof (float);//(AudioUnitSampleType);
  memset(format,0,sizeof(*format));
  format->mSampleRate		    = 44100.00;
  format->mFormatID          = kAudioFormatLinearPCM;
  format->mFormatFlags       = kAudioFormatFlagIsFloat | kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsNonInterleaved;//kAudioFormatFlagsAudioUnitCanonical;
  format->mBytesPerPacket    = bytesPerSample;
  format->mFramesPerPacket   = 1;
  format->mBytesPerFrame     = bytesPerSample;
  format->mChannelsPerFrame  = 1;                  // 1 indicates mono
  format->mBitsPerChannel    = 8 * bytesPerSample;
}

+ (AudioBufferList*) newInputBufferListForFormat:(const AudioStreamBasicDescription*)format error:(NSError**)error
{
  NSAssert(format,@"Input format must not be null");
  
  if (format->mFramesPerPacket != 1) {
    // TODO handle other frame per packet values
    [ErrorHandler setError:error withDomain:AudioToolsErrorDomain code:kAudioTools_interleavedNotSupported description:@"Can't handle interleaved, frames per packet must be 1"];
    return 0;
  }
  
  AudioBufferList* inputBufferList = 0;
  
  inputBufferList = (AudioBufferList*) calloc(1, sizeof (AudioBufferList) + 
                                              sizeof (AudioBuffer) * (format->mChannelsPerFrame));
  if (!inputBufferList) {
    [ErrorHandler setError:error withDomain:@"MemoryErrorDomain" code:kAudio_MemFullError description:@"Can't allocate input buffer list"];
    return 0;
  }
  
  inputBufferList->mNumberBuffers = format->mChannelsPerFrame;
  
  UInt32 maxSamples = 2*4096; // TODO make configurable or determine appropriate value dynamically
  
  for (int i = 0; i < inputBufferList->mNumberBuffers; ++i) {
    inputBufferList->mBuffers[i].mNumberChannels  = 1;
    inputBufferList->mBuffers[i].mDataByteSize    = maxSamples * format->mBytesPerPacket;
    inputBufferList->mBuffers[i].mData            = malloc(inputBufferList->mBuffers[i].mDataByteSize);
    
    if (!inputBufferList->mBuffers[i].mData) {
      [ErrorHandler setError:error withDomain:@"MemoryErrorDomain" code:kAudio_MemFullError description:@"Can't allocate input buffer data"];
      [self freeBuffers: inputBufferList];
      return 0;
    }
  }
  
  return inputBufferList;
}

+ (void) defaultComponentDescription:(AudioComponentDescription*) description
{
  NSAssert(description,@"input description must not be nil");

  description->componentType = kAudioUnitType_Output;
#if !TARGET_OS_IPHONE
  description->componentSubType = kAudioUnitSubType_HALOutput;
#else
  description->componentSubType = kAudioUnitSubType_RemoteIO;
#endif
  description->componentManufacturer = kAudioUnitManufacturer_Apple;
  description->componentFlags = 0;
  description->componentFlagsMask = 0;
}

+ (OSStatus) defaultComponent:(AudioComponent*)component error:(NSError**)error 
{
  NSAssert(component,@"input component must not be nil");

  OSStatus result = noErr;
  AudioComponentDescription desc;
  [SimpleIOUnit defaultComponentDescription:&desc];
  
  AudioComponent defaultComponent = AudioComponentFindNext(NULL, &desc);
  
  if (defaultComponent) {
    *component = defaultComponent;
  }
  else {
    result = kAudioTools_noDefaultComponentError;
    [ErrorHandler setError:error withDomain:AudioToolsErrorDomain code:result description:@"Can't find default audio component"];
    return result;
  }
  
  return result;
}

+ (OSStatus) initializeDefaultUnit:(AudioComponentInstance*)unit error:(NSError**)error;
{
  NSAssert(unit, @"input unit must not be nil");
  NSAssert(*unit == 0, @"input unit is already initialized");
  
  OSStatus result = noErr;
  
  AudioComponent defaultComponent;
  result = [SimpleIOUnit defaultComponent:&defaultComponent error:error];
  if (result) return result;
  
  result = AudioComponentInstanceNew(defaultComponent, unit);
  
  if (result) {
    [ErrorHandler setError:error withDomain:@"IOErrorDomain" code:result description:@"Unable to initialize audio unit"];
    *unit = 0;
    return result;
  }

  return result;
}

- (OSStatus) enableInput:(NSError**)error
{
  OSStatus result = noErr;
  
  result = AudioUnitSetProperty(inputUnit, 
                                kAudioOutputUnitProperty_EnableIO,
                                kAudioUnitScope_Input,
                                1,
                                &(UInt32){1},
                                sizeof(UInt32));
  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't enable input"];
    return result;
  }
                           
  return result;
}

- (OSStatus) disableOutput:(AudioComponentInstance)unit error:(NSError**)error
{
  OSStatus result = noErr;
  UInt32 zero = 0;
  result = AudioUnitSetProperty(unit,
                                kAudioOutputUnitProperty_EnableIO,
                                kAudioUnitScope_Output,
                                0,
                                &zero,
                                sizeof(zero));
  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't disable output"];
    return result;
  }
  return result;
}

#if !TARGET_OS_IPHONE

+ (OSStatus) defaultInputDeviceId:(AudioDeviceID*)deviceId error:(NSError**)error
{
  NSAssert(deviceId,@"input device id must not be nil");
  
  OSStatus result = noErr;
  *deviceId = kAudioObjectUnknown;
  
  UInt32 size = sizeof(AudioDeviceID);
  
  AudioObjectPropertyAddress property_address = { 
    kAudioHardwarePropertyDefaultInputDevice,  // mSelector 
    kAudioObjectPropertyScopeGlobal,            // mScope 
    kAudioObjectPropertyElementMaster           // mElement 
  }; 
  
  result = AudioObjectGetPropertyData(kAudioObjectSystemObject, 
                                      &property_address, 
                                      0,     // inQualifierDataSize 
                                      NULL,  // inQualifierData 
                                      &size, 
                                      deviceId);

  if (noErr != result || *deviceId == kAudioObjectUnknown) {
    [ErrorHandler setError: error withDomain: @"PropertyErrorDomain" code:result description:@"Can't get the default input device"];
    *deviceId = kAudioObjectUnknown;
    return result;
  }
  
  return result;
}

- (OSStatus) setInputDevice:(AudioDeviceID)inputDevice error:(NSError**)error
{
  NSAssert(inputDevice,@"input device must not be nil");
 
  OSStatus result = noErr;
  
  result = AudioUnitSetProperty(inputUnit,
                                kAudioOutputUnitProperty_CurrentDevice, 
                                kAudioUnitScope_Global, 
                                0, 
                                &inputDevice, 
                                sizeof(inputDevice));
  if (result) {
    [ErrorHandler setError:error withDomain: @"PropertyErrorDomain" code:result description:@"Can't set input device"];
    return result;
  }

  return result;
}

#endif


- (OSStatus) setDefaultInputDevice:(NSError**)error
{
  OSStatus result = noErr;
  
#if !TARGET_OS_IPHONE
  AudioDeviceID deviceId; 
  result = [SimpleIOUnit defaultInputDeviceId:&deviceId error:error];
  if (result) return result;
  
  result = [self setInputDevice:deviceId error:error];
#endif
  
  return result;
}

- (OSStatus) getInputDeviceFormat:(AudioStreamBasicDescription*)format error:(NSError**)error
{
  NSAssert(format,@"Input format must not be null");
  OSStatus result = noErr;
  
  format->mSampleRate = 0;
  
  UInt32 size = sizeof(*format);
  
  //Get the input device format
  result = AudioUnitGetProperty (inputUnit,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Input,
                                 1,
                                 format,
                                 &size);
  if (result) {
    [ErrorHandler setError:error withDomain: @"PropertyErrorDomain" code:result description:@"Can't get input stream device format"];
    return result;
  }
  return result;
}

- (OSStatus) getInputClientFormat:(AudioStreamBasicDescription*)format error:(NSError**)error
{
  NSAssert(format,@"Input format must not be null");
  OSStatus result = noErr;

  format->mSampleRate = 0;
  
  UInt32 size = sizeof(*format);
  
  //Get the input device format
  result = AudioUnitGetProperty (inputUnit,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Output,
                                 1,
                                 format,
                                 &size);
   if (result) {
     [ErrorHandler setError:error withDomain: @"PropertyErrorDomain" code:result description:@"Can't get input stream client format"];
     return result;
   }
   
  return result;
}

- (OSStatus) configureInputFormat:(const AudioStreamBasicDescription*)inputFormat error:(NSError**)error
{
  OSStatus result = noErr;
  
  result = [self setInputFormat:inputFormat error:error];
  if (result) return result;
  
  result = [self setInputBufferAllocation:0 error:error];
  if (result) return result;
  
  inputBufferList = [SimpleIOUnit newInputBufferListForFormat:inputFormat error:error];
  if (!inputBufferList) {
    result = 1; // TODO get from error or figure out some other way to propogate real value
    return result;
  }
 
  return result;
}

- (OSStatus) setInputBufferAllocation:(UInt32)allocateBuffer error:(NSError**)error
{
  OSStatus result = noErr;
  
  result = AudioUnitSetProperty(inputUnit, 
                                kAudioUnitProperty_ShouldAllocateBuffer,
                                kAudioUnitScope_Output, 
                                1,
                                &allocateBuffer, 
                                sizeof(allocateBuffer));

  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't configure buffer allocation on input unit"];
    return result;
  }

  return result;
}


- (OSStatus) setInputFormat:(const AudioStreamBasicDescription*)inputFormat error:(NSError**)error;
{
  NSAssert(inputFormat,@"Input format must not be null");
  OSStatus result = noErr;

  result = AudioUnitSetProperty(inputUnit, 
                                kAudioUnitProperty_StreamFormat, 
                                kAudioUnitScope_Output, 
                                1, 
                                inputFormat, 
                                sizeof(*inputFormat));
  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't set input unit's client format"];
    return result;
  }
  
  return result;
}

- (OSStatus) setOutputFormat:(const AudioStreamBasicDescription*)outputFormat error:(NSError**)error;
{
  NSAssert(outputFormat,@"Input format must not be null");
  OSStatus result = noErr;

  result = AudioUnitSetProperty(outputUnit, 
                                kAudioUnitProperty_StreamFormat, 
                                kAudioUnitScope_Input, 
                                0, 
                                outputFormat, 
                                sizeof(*outputFormat));
  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't set output unit's client format"];
    return result;
  }
  
  return result;
}

- (OSStatus) setInputCallback:(NSError**) error
{
  OSStatus result = noErr;
  
  AURenderCallbackStruct inputCallbackStruct;
	inputCallbackStruct.inputProc = simpleIOUnitOnInput;
	inputCallbackStruct.inputProcRefCon = (__bridge void *)(self);
  result = AudioUnitSetProperty(inputUnit,
                                kAudioOutputUnitProperty_SetInputCallback,
                                kAudioUnitScope_Global,
                                1,
                                &inputCallbackStruct,
                                sizeof(inputCallbackStruct));
  
  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't set input callback"];
    return result;
  }
  
  return result;
}

- (OSStatus) setRenderCallback:(NSError**)error
{
  OSStatus result = noErr;
  
  AURenderCallbackStruct callbackStruct;
	callbackStruct.inputProc = simpleIOUnitOnRender;
	callbackStruct.inputProcRefCon = (__bridge void *)(self);
  result = AudioUnitSetProperty(outputUnit,
                                kAudioUnitProperty_SetRenderCallback,
                                kAudioUnitScope_Global,
                                0,
                                &callbackStruct,
                                sizeof(callbackStruct));
  if (result) {
    [ErrorHandler setError:error withDomain:@"PropertyErrorDomain" code:result description:@"Can't set render callback"];
    return result;
  }
  
  return result;
}

- (id)init
{
  return [self initWithInputFormat:nil outputFormat:nil error:nil];
}

-(id)initWithInputFormat:(const AudioStreamBasicDescription*)inputFormat error:(NSError**)error
{
   return [self initWithInputFormat:inputFormat outputFormat:nil error:error];
}

-(id)initWithOutputFormat:(const AudioStreamBasicDescription*)outputFormat error:(NSError**)error
{
  return [self initWithInputFormat:nil outputFormat:outputFormat error:error];
}

-(id)initWithInputFormat:(const AudioStreamBasicDescription*)inputFormat 
            outputFormat:(const AudioStreamBasicDescription*)outputFormat error:(NSError**)error
{
  self = [super init];
  if (self) {
    if ([self initializeAudioUnit:nil] != noErr) {
      return nil;
    }
  }
  
  return self;
}

- (OSStatus) initializeOutputUnit:(NSError**)error
{
  OSStatus result = noErr;
  NSAssert(outputUnit == 0, @"output unit already initialized");
  
  result = [SimpleIOUnit initializeDefaultUnit:&outputUnit error:error];
  if (result) return result;
  
  // TODO allow configurable output format
  AudioStreamBasicDescription desiredFormat;
  [SimpleIOUnit defaultInputFormat:&desiredFormat];
  
  result = [self setOutputFormat:&desiredFormat error: error];
  if (result) return result;
  
  result =  [self setRenderCallback: error];
  
  return result;
}


- (OSStatus) initializeInputUnit:(NSError**)error
{
  OSStatus result = noErr;
  NSAssert(inputUnit == 0,@"input unit already initialized");
  
#if TARGET_OS_IPHONE
  // we can use the output unit as the input unit at the same time
  inputUnit = outputUnit;
#endif

  if (!inputUnit) {
    result = [SimpleIOUnit initializeDefaultUnit:&inputUnit error: error];
    if (result) return result;
  }
  
  result = [self enableInput:error];
  if (result) return result;

  if (inputUnit != outputUnit) {
    result = [self disableOutput:inputUnit error:error];
    if (result) return result;
  }

  result = [self setDefaultInputDevice:error];
  if (result) return result;
  
  AudioStreamBasicDescription desiredFormat;
  [SimpleIOUnit defaultInputFormat:&desiredFormat];
  AudioStreamBasicDescription deviceFormat;
  result = [self getInputDeviceFormat:&deviceFormat error:error];
  if (result) return result;
  
  if (deviceFormat.mSampleRate > 0) {
    // we have to take the input at the device's sample rate
    desiredFormat.mSampleRate = deviceFormat.mSampleRate;
  }
  
  result = [self configureInputFormat:&desiredFormat error:error];
  if (result) return result;

  result = [self setInputCallback:error];
  if (result) return result;
  
  return result;
}


- (OSStatus)initializeAudioUnit:(NSError**)error
{
  OSStatus result = noErr;
  
  result = [self initializeOutputUnit: error];
  if (result) return result;
  
  result = [self initializeInputUnit:error];
  
  if (result) return result; // TODO dispose of outputUnit

  if (outputUnit) {
    result = AudioUnitInitialize(outputUnit);
    if (result) {
      [ErrorHandler setError:error withDomain: @"IOErrorDomain" code:result description:@"Can't initialize output unit"];
      return result;
    }
  }
  
  if (inputUnit && inputUnit != outputUnit) {
    result = AudioUnitInitialize(inputUnit);
    if (result) {
      [ErrorHandler setError:error withDomain: @"IOErrorDomain" code:result description:@"Can't initialize output unit"];
      return result;
    }
  }
  return result;
}

-(OSStatus) start:(NSError**)error
{
  OSStatus result = noErr;
  
  if (outputUnit) {
    result = AudioOutputUnitStart(outputUnit);
    if (result) {
      [ErrorHandler setError:error withDomain: @"IOErrorDomain" code:result description:@"Can't start output unit"];
      return result;
    }
  }
  
  if (inputUnit && inputUnit != outputUnit) {
    result = AudioOutputUnitStart(inputUnit);
    if (result) {
      [ErrorHandler setError:error withDomain: @"IOErrorDomain" code:result description:@"Can't start input unit"];
      return result;
    }
  }

  return result;
}

-(OSStatus) stop:(NSError**)error
{
  OSStatus result = noErr;
  
  if (outputUnit) {
    result = AudioOutputUnitStop(outputUnit);
    if (result) {
      [ErrorHandler setError:error withDomain: @"IOErrorDomain" code:result description:@"Can't stop output unit"];
      return result;
    }
  }

  if (inputUnit && inputUnit != outputUnit) {
    result = AudioOutputUnitStop(inputUnit);
    if (result) {
      [ErrorHandler setError:error withDomain: @"IOErrorDomain" code:result description:@"Can't stop input unit"];
      return result;
    }
  }

  return result;
}

- (BOOL) isRunning
{
  UInt32 isRunning = 0;
  UInt32 size = sizeof(isRunning);
  if (inputUnit) {
    // TODO check error: OSStatus result =
    AudioUnitGetProperty(inputUnit, kAudioOutputUnitProperty_IsRunning, kAudioUnitScope_Global, 0, &isRunning, &size);
  }
  if (isRunning) {
    return YES;
  }
  return NO;
}

- (OSStatus) handleInputWithFlags:(AudioUnitRenderActionFlags*) ioActionFlags 
                                           time:(const AudioTimeStamp*) inTimeStamp 
                                            bus:(UInt32) inBusNumber 
                                         frames:(UInt32) inNumberFrames 
                                         ioData:(AudioBufferList*) nullIoData;
{
  @autoreleasepool {
    OSStatus result = noErr;
    if (self.inputDelegate) {
      result = AudioUnitRender(inputUnit, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, inputBufferList);
      if (result) return result;
    }
    if (self.inputDelegate) {
      result = [self.inputDelegate io:inputBufferList flags:ioActionFlags timeStamp:inTimeStamp busNumber: inBusNumber numFrames:inNumberFrames];
    }
//    if (inputBlock) {
//      result = inputBlock(ioActionFlags,inTimeStamp,inBusNumber,inNumberFrames,inputBufferList);
//    }
    return result;
  }
}

- (OSStatus) handleRenderWithFlags:(AudioUnitRenderActionFlags*) ioActionFlags 
                             time:(const AudioTimeStamp*) inTimeStamp 
                              bus:(UInt32) inBusNumber 
                           frames:(UInt32) inNumberFrames 
                           ioData:(AudioBufferList*) ioData;
{
  @autoreleasepool {
    if (self.renderDelegate) {
      return [self.renderDelegate io:ioData flags:ioActionFlags timeStamp:inTimeStamp busNumber: inBusNumber numFrames:inNumberFrames];
    }
//    if (renderBlock) {
//      return renderBlock(ioActionFlags,inTimeStamp,inBusNumber,inNumberFrames,ioData);
//    }
    return noErr;
  }
}

+ (void) freeBuffers:(AudioBufferList*)buffers {
  if (buffers) {
    for (int i = 0; i < buffers->mNumberBuffers; ++i) {
      if (buffers->mBuffers[i].mData) {
        free(buffers->mBuffers[i].mData);
        buffers->mBuffers[i].mData = 0;
      }
    }
    free(buffers);
  }
}

- (void) dealloc
{
  [[self class ] freeBuffers:inputBufferList];
  inputBufferList = 0;
}

@end
