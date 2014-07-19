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

#import <CoreAudio/CoreAudioTypes.h>
#import "MCMotionStore.h"
#import "MCMeasurement.h"
#import "MCDataManager.h"
#import "MCMotionLocalDevice.h"

@interface MCMotionStore ()
@property (nonatomic, assign) int count;
@property (nonatomic, assign) NSTimeInterval timeReferenceOffset;
@property (nonatomic, strong) MCDataManager* dataManager;
@property (nonatomic, strong) NSEntityDescription* measurementEntity;
@end

@implementation MCMotionStore

+ (MCMotionStore*)sharedInstance
{
	static dispatch_once_t pred;
	static MCMotionStore* sharedInstance = nil;
  
	dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
	return sharedInstance;
}

- (id)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _enabled = NO;
  _count = 0;
  _dataManager = [[MCDataManager alloc] initWithBundle:nil model:@"imu" database:@"Motion.sqlite"];
  _measurementEntity = _dataManager.objectModel.entitiesByName[@"Measurement"];

  return self;
}

- (MCMeasurement*) newMeasurement
{
  ++_count;
  return [[MCMeasurement alloc] initWithEntity:_measurementEntity insertIntoManagedObjectContext:_dataManager.objectContext];
}

- (void) setEnabled:(BOOL)enabled
{
  if (NO == enabled) {
    [self flush];
  }
  _enabled = enabled;
}

- (void)storeMeasurement:(MCMeasurement*)measurement
{
  if (_count > 100) {
    [self internalFlush];
    _count = 0;
  }
}

-(void)flush
{
  [_dataManager.objectContext performBlock:^{[self internalFlush];}];
}

- (void)internalFlush
{
  if ([_dataManager.objectContext hasChanges]) {
    [_dataManager.objectContext save:nil];
  }
}

- (void)storeMotion:(CMDeviceMotion*)motion device:(MCMotionPeripheral*)device
{
  if (NO == _enabled) return;
  
  [_dataManager.objectContext performBlock:^{
    [self storeMeasurement:[[self newMeasurement] setAttitudeFromMotion:motion device:device]];
    [self storeMeasurement:[[self newMeasurement] setRotationRateFromMotion:motion device:device]];
    [self storeMeasurement:[[self newMeasurement] setGravityFromMotion:motion device:device]];
    [self storeMeasurement:[[self newMeasurement] setUserAccelerationFromMotion:motion device:device]];
    [self storeMeasurement:[[self newMeasurement] setMagneticFieldFromMotion:motion device:device]];
  }];
}

- (void)storeAccelerometer:(MCAccelerometerData*)acceleration device:(MCMotionPeripheral*)device
{
  if (NO == _enabled) return;

  [_dataManager.objectContext performBlock:^{
    [self storeMeasurement:[[self newMeasurement] setAcceleration:acceleration device:device]];
  }];
}

- (void)storeGyroscope:(MCGyroData*)rotation device:(MCMotionPeripheral*)device
{
  if (NO == _enabled) return;

  [_dataManager.objectContext performBlock:^{
    [self storeMeasurement:[[self newMeasurement] setRotationRate:rotation device:device]];
  }];
}

- (void)storeMagnetometer:(MCMagnetometerData*)magneticField device:(MCMotionPeripheral*)device
{
  if (NO == _enabled) return;

  [_dataManager.objectContext performBlock:^{
    [self storeMeasurement:[[self newMeasurement] setMagneticField:magneticField device:device]];
  }];
}

- (void)clearStore
{
  [_dataManager truncateDatabase];
  _measurementEntity = _dataManager.objectModel.entitiesByName[@"Measurement"];
}

- (long long)byteCount
{
  return _dataManager.databaseBytes;
}

@end
