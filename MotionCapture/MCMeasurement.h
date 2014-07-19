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
#import <CoreData/CoreData.h>
#import <CoreMotion/CoreMotion.h>

typedef enum {
  MCMeasurementAttitueType,
  MCMeasurementRotationRateType,
  MCMeasurementGravityType,
  MCMeasurementUserAccelerationType,
  MCMeasurementMagneticFieldType,
  MCMeasurementAccelerometerType,
  MCMeasurementGyroscopeType,
  MCMeasurementMagnetometerType,
} MCMeasurementType;

typedef enum {
  MCBodySideUnknown,
  MCBodySideLeft,
  MCBodySideRight
} MCBodySide;

typedef enum {
  MCBodyPartUnknown,
  MCBodyPartHead,
  MCBodyPartArm,
  MCBodyPartWrist,
  MCBodyPartHip,
  MCBodyPartAnkle
} MCBodyPart;

@class MCMotionPeripheral;
@class MCGyroData;
@class MCAccelerometerData;
@class MCMagnetometerData;

@interface MCMeasurement : NSManagedObject

@property (nonatomic, strong) NSNumber * type;
@property (nonatomic, strong) NSNumber * timestamp;
@property (nonatomic, strong) NSNumber * x;
@property (nonatomic, strong) NSNumber * y;
@property (nonatomic, strong) NSNumber * z;
@property (nonatomic, strong) NSNumber * w;
@property (nonatomic, strong) NSNumber * accuracy;
@property (nonatomic, strong) NSNumber* bodySide;
@property (nonatomic, strong) NSNumber* bodyPart;
@property (nonatomic, strong) NSNumber* isLocal;

- (MCMeasurement*)setAttitudeFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device;
- (MCMeasurement*)setRotationRateFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device;
- (MCMeasurement*)setGravityFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device;
- (MCMeasurement*)setUserAccelerationFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device;
- (MCMeasurement*)setMagneticFieldFromMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device;

- (MCMeasurement*)setRotationRate:(MCGyroData*)data device:(MCMotionPeripheral*)device;
- (MCMeasurement*)setAcceleration:(MCAccelerometerData*)data device:(MCMotionPeripheral*)device;
- (MCMeasurement*)setMagneticField:(MCMagnetometerData*)data device:(MCMotionPeripheral*)device;

@end
