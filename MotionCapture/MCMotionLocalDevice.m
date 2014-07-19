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

#import "MCMotionLocalDevice.h"
#import "MCMotionStore.h"
#import "MCAccelerometerData.h"
#import "MCGyroData.h"
#import "MCMagnetometerData.h"

@interface MCMotionLocalDevice ()

@property(nonatomic, strong) CMMotionManager* coreMotionManager;
@property(nonatomic, strong) NSOperationQueue* queue;
@property(nonatomic, assign) NSTimeInterval timeReferenceOffset;

// we would like to just use keyPathsForValuesAffectingValueForKey to redirect
// xxxActive to coreMotionManager.xxxActive, but this does not appear to work.
// so instead we shadow them with the following properties and update them
// ourselves
@property (nonatomic, assign, readwrite) BOOL accelerometerActive;
@property (nonatomic, assign, readwrite) BOOL gyroActive;
@property (nonatomic, assign, readwrite) BOOL magnetometerActive;
@property (nonatomic, assign, readwrite) BOOL deviceMotionActive;

@end

@implementation MCMotionLocalDevice

@synthesize accelerometerActive;
@synthesize gyroActive;
@synthesize magnetometerActive;
@synthesize deviceMotionActive;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  
  NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];

//  for (NSString* property in @[@"accelerometerActive", @"gyroActive", @"magnetometerActive", @"deviceMotionActive"]) {
//    if ([key isEqualToString:property]) {
//      keyPaths = [keyPaths setByAddingObject:[@"coreMotionManager." stringByAppendingString:property]];
//    }
//  }
  
  return keyPaths;
}

- (id)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _coreMotionManager = [[CMMotionManager alloc] init];
  _queue = [[NSOperationQueue alloc] init];
  _updateInterval  = 0.1;
  
  NSUUID* local = [UIDevice currentDevice].identifierForVendor;
  if (local) {
    _uuid = [local UUIDString];
  }
  else {
    _uuid = @"00000000-0000-0000-0000-000000000000";
  }

  _type = @"local";
  self.name = @"this iPhone";
  
  NSTimeInterval secondsFromBoot = [[NSProcessInfo processInfo] systemUptime];
  NSTimeInterval secondsFromReference = [NSDate timeIntervalSinceReferenceDate];
  _timeReferenceOffset = (secondsFromReference - secondsFromBoot) + NSTimeIntervalSince1970;

  return self;
}

- (NSTimeInterval)secondsFromUnixEpochForDeviceTime:(NSTimeInterval)deviceTime
{
  return deviceTime + _timeReferenceOffset;
}

- (void)setUpdateInterval:(NSTimeInterval)interval
{
  _updateInterval = interval;
  if (_coreMotionManager.accelerometerAvailable == YES) {
    _coreMotionManager.accelerometerUpdateInterval = interval;
  }
  if (_coreMotionManager.gyroAvailable == YES) {
    _coreMotionManager.gyroUpdateInterval = interval;
  }
  if (_coreMotionManager.magnetometerAvailable == YES) {
    _coreMotionManager.magnetometerUpdateInterval = interval;
  }
  if (_coreMotionManager.deviceMotionAvailable == YES) {
    _coreMotionManager.deviceMotionUpdateInterval = interval;
  }
}

- (void)setAccelerometerEnabled:(BOOL)accelerometerEnabled
{
  _accelerometerEnabled = accelerometerEnabled;
  if (YES == accelerometerEnabled) {
    [_coreMotionManager startAccelerometerUpdatesToQueue:_queue withHandler:^(CMAccelerometerData* data, NSError* error){
      if (error) {
        // TODO
      }
      [MCMotionStore.sharedInstance storeAccelerometer:[[MCAccelerometerData alloc] initWithCoreMotion:data] device:self];
    }];
  }
  else {
    [_coreMotionManager stopAccelerometerUpdates];
  }
  self.accelerometerActive = [_coreMotionManager isAccelerometerActive];
}

- (void)setGyroEnabled:(BOOL)gyroEnabled
{
  _gyroEnabled = gyroEnabled;
  if (YES == gyroEnabled) {
    [_coreMotionManager startGyroUpdatesToQueue:_queue withHandler:^(CMGyroData* data, NSError* error){
      if (error) {
        // TODO
      }
      [MCMotionStore.sharedInstance storeGyroscope:[[MCGyroData alloc] initWithCoreMotion:data] device:self];
    }];
  }
  else {
    [_coreMotionManager stopGyroUpdates];
  }
  self.gyroActive = [_coreMotionManager isGyroActive];
}

- (void)setMagnetometerEnabled:(BOOL)magnetometerEnabled
{
  _magnetometerEnabled = magnetometerEnabled;
  if (YES == magnetometerEnabled) {
    [_coreMotionManager startMagnetometerUpdatesToQueue:_queue withHandler:^(CMMagnetometerData* data, NSError* error){
      if (error) {
        // TODO
      }
      [MCMotionStore.sharedInstance storeMagnetometer:[[MCMagnetometerData alloc] initWithCoreMotion:data] device:self];
    }];
  }
  else {
    [_coreMotionManager stopMagnetometerUpdates];
  }
  self.magnetometerActive = [_coreMotionManager isMagnetometerActive];
}

- (void)setDeviceMotionEnabled:(BOOL)deviceMotionEnabled
{
  _deviceMotionEnabled = deviceMotionEnabled;
  if (YES == deviceMotionEnabled) {
    [_coreMotionManager startDeviceMotionUpdatesToQueue:_queue withHandler:^(CMDeviceMotion* deviceMotion, NSError* error){
      if (error) {
        // TODO
      }
      [MCMotionStore.sharedInstance storeMotion:deviceMotion device:self];
    }];
  }
  else {
    [_coreMotionManager stopDeviceMotionUpdates];
  }
  self.deviceMotionActive = [_coreMotionManager isDeviceMotionActive];
}

#define PROPERTY_FORWARD(method, obj) method { return obj.method; }
#define VOID_FORWARD(method, obj) (void) method { [obj method]; }

- (BOOL) PROPERTY_FORWARD(isAccelerometerAvailable, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isGyroAvailable, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isMagnetometerAvailable, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isDeviceMotionAvailable, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isAccelerometerActive, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isGyroActive, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isMagnetometerActive, _coreMotionManager)
- (BOOL) PROPERTY_FORWARD(isDeviceMotionActive, _coreMotionManager)

@end
