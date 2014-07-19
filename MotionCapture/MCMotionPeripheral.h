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
#import "MCMeasurement.h"

@interface MCMotionPeripheral : NSObject {
@protected
  NSString* _uuid;
  NSString* _type;
  NSTimeInterval _updateInterval;
  BOOL _accelerometerEnabled;
  BOOL _gyroEnabled;
  BOOL _magnetometerEnabled;
  BOOL _deviceMotionEnabled;
}

@property (nonatomic, strong, readonly) NSString* uuid;
@property (nonatomic, strong, readonly) NSString* type;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, assign) MCBodySide bodySide;
@property (nonatomic, assign) MCBodyPart bodyPart;
@property (nonatomic, strong, readonly) NSString* locationString;

@property(assign, nonatomic) NSTimeInterval updateInterval;
@property(assign, nonatomic) BOOL autoconnect;

@property(readonly, nonatomic, getter=isAccelerometerAvailable) BOOL accelerometerAvailable;
@property(readonly, nonatomic, getter=isGyroAvailable) BOOL gyroAvailable;
@property(readonly, nonatomic, getter=isMagnetometerAvailable) BOOL magnetometerAvailable;
@property(readonly, nonatomic, getter=isAccelerometerActive) BOOL accelerometerActive;
@property(readonly, nonatomic, getter=isGyroActive) BOOL gyroActive;
@property(readonly, nonatomic, getter=isMagnetometerActive) BOOL magnetometerActive;
@property(readonly, nonatomic, getter=isDeviceMotionActive) BOOL deviceMotionActive;
@property(readonly, nonatomic, getter=isDeviceMotionAvailable) BOOL deviceMotionAvailable;
@property(assign, nonatomic, getter=isAccelerometerEnabled) BOOL accelerometerEnabled;
@property(assign, nonatomic, getter=isGyroEnabled) BOOL gyroEnabled;
@property(assign, nonatomic, getter=isMagnetometerActive) BOOL magnetometerEnabled;
@property(assign, nonatomic, getter=isDeviceMotionActive) BOOL deviceMotionEnabled;


- (NSTimeInterval)secondsFromUnixEpochForDeviceTime:(NSTimeInterval)deviceTime;
@end
