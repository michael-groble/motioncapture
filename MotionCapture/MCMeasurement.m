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

#import "MCMeasurement.h"
#import "MCMotionPeripheral.h"
#import "MCGyroData.h"
#import "MCAccelerometerData.h"
#import "MCMagnetometerData.h"


@implementation MCMeasurement

@dynamic type;
@dynamic timestamp;
@dynamic x;
@dynamic y;
@dynamic z;
@dynamic w;
@dynamic accuracy;
@dynamic bodySide;
@dynamic bodyPart;
@dynamic isLocal;

- (MCMeasurement*)setAttitudeFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device
{
  CMQuaternion rotation = motion.attitude.quaternion;
  self.isLocal = @YES;
  self.type = @(MCMeasurementAttitueType);
  self.timestamp = @([device secondsFromUnixEpochForDeviceTime:motion.timestamp]);
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  self.w = @(rotation.w);
  self.x = @(rotation.x);
  self.y = @(rotation.y);
  self.z = @(rotation.z);
  return self;
}

- (MCMeasurement*)setRotationRateFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device
{
  CMRotationRate rate = motion.rotationRate;
  [self setRotationRate:&rate time:[device secondsFromUnixEpochForDeviceTime:motion.timestamp]];
  self.type = @(MCMeasurementRotationRateType);
  self.isLocal = @YES;
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setGravityFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device
{
  CMAcceleration gravity = motion.gravity;
  [self setAcceleration:&gravity time:[device secondsFromUnixEpochForDeviceTime:motion.timestamp]];
  self.type = @(MCMeasurementGravityType);
  self.isLocal = @YES;
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setUserAccelerationFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device
{
  CMAcceleration userAcceleration = motion.userAcceleration;
  [self setAcceleration:&userAcceleration time:[device secondsFromUnixEpochForDeviceTime:motion.timestamp]];
  self.type = @(MCMeasurementUserAccelerationType);
  self.isLocal = @YES;
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setMagneticFieldFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device
{
  CMCalibratedMagneticField mag = motion.magneticField;
  [self setMagneticField:&mag.field accuracy:mag.accuracy time:[device secondsFromUnixEpochForDeviceTime:motion.timestamp]];
  self.type = @(MCMeasurementMagneticFieldType);
  self.isLocal = @YES;
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setRotationRate:(MCGyroData*)data device:(MCMotionPeripheral*)device
{
  CMRotationRate rate = data.rotationRate;
  [self setRotationRate:&rate time:[device secondsFromUnixEpochForDeviceTime:data.timestamp]];
  self.isLocal = @([@"local" isEqualToString:device.type]);
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setAcceleration:(MCAccelerometerData*)data device:(MCMotionPeripheral*)device
{
  CMAcceleration acceleration = data.acceleration;
  [self setAcceleration:&acceleration time:[device secondsFromUnixEpochForDeviceTime:data.timestamp]];
  self.isLocal = @([@"local" isEqualToString:device.type]);
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setMagneticField:(MCMagnetometerData*)data device:(MCMotionPeripheral*)device
{
  CMMagneticField mag = data.magneticField;
  [self setMagneticField:&mag accuracy:CMMagneticFieldCalibrationAccuracyUncalibrated time:[device secondsFromUnixEpochForDeviceTime:data.timestamp]];
  self.isLocal = @([@"local" isEqualToString:device.type]);
  self.bodySide = @(device.bodySide);
  self.bodyPart = @(device.bodyPart);
  return self;
}

- (MCMeasurement*)setRotationRate:(CMRotationRate const*)rotationRate time:(double)time
{
  self.type = @(MCMeasurementGyroscopeType);
  self.timestamp = @(time);
  self.x = @(rotationRate->x);
  self.y = @(rotationRate->y);
  self.z = @(rotationRate->z);
  return self;
}

- (MCMeasurement*)setAcceleration:(CMAcceleration const*)acceleration time:(double)time
{
  self.type = @(MCMeasurementAccelerometerType);
  self.timestamp = @(time);
  self.x = @(acceleration->x);
  self.y = @(acceleration->y);
  self.z = @(acceleration->z);
  return self;
}

- (MCMeasurement*)setMagneticField:(CMMagneticField const*)field accuracy:(CMMagneticFieldCalibrationAccuracy)accuracy time:(double)time
{
  self.type = @(MCMeasurementMagnetometerType);
  self.timestamp = @(time);
  self.x = @(field->x);
  self.y = @(field->y);
  self.z = @(field->z);
  self.accuracy = @(accuracy);
  return self;
}

@end
