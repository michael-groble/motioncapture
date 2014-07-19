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

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>

typedef OSStatus(^OnIOBlock)(AudioUnitRenderActionFlags *ioActionFlags, 
                             const AudioTimeStamp *inTimeStamp, 
                             UInt32 inBusNumber, 
                             UInt32 inNumberFrames, 
                             AudioBufferList *ioData);

@protocol SimpleIODelegate <NSObject>
@required
-(OSStatus) io:(AudioBufferList*)ioData
         flags:(AudioUnitRenderActionFlags*)ioActionFlags
     timeStamp:(const AudioTimeStamp*)inTimeStamp 
     busNumber:(UInt32)inBusNumber 
     numFrames:(UInt32)inNumberFrames;
@end


@protocol DelegatableIO <NSObject>

- (OSStatus) start:(NSError**)error;
- (OSStatus) stop:(NSError**)error;

@property(nonatomic,readonly, getter=isRunning) BOOL running;
@property(nonatomic,weak) id<SimpleIODelegate> inputDelegate;
@property(nonatomic,weak) id<SimpleIODelegate> renderDelegate;

@end
