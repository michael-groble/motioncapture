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

#import "MCMotionBLEPeripheral.h"
#import "MCMotionStore.h"
#import "MCGyroData.h"
#import "MCAccelerometerData.h"
#import "MCMagnetometerData.h"

#import <CoreBluetooth/CoreBluetooth.h>
#import <Foundation/Foundation.h>

@interface MCMotionBLEPeripheral () <CBPeripheralDelegate>

+(NSDictionary*) serviceRegistry;
+(NSDictionary*) characteristicRegistry;

+(NSArray*) characteristicUUIDsWithPropertyNamePrefix:(NSString*)prefix;

// we would like to just use keyPathsForValuesAffectingValueForKey to redirect
// xxxActive to xxxDataCharacteristic.notifying, but when the peripheral disconnects,
// the underlying characteristic objects are deleted so observers loose the connection.
// so instead we shadow them with the following properties and update them in
// peripheral:didUpdateNotificationStateForCharacteristic:...
@property (nonatomic, assign, readwrite) BOOL accelerometerActive;
@property (nonatomic, assign, readwrite) BOOL gyroActive;
@property (nonatomic, assign, readwrite) BOOL magnetometerActive;


@property (weak, nonatomic) CBService* accelerometerService;
@property (weak, nonatomic) CBService* gyroscopeService;
@property (weak, nonatomic) CBService* magnetometerService;
@property (weak, nonatomic) CBCharacteristic* accelerometerDataCharacteristic;
@property (weak, nonatomic) CBCharacteristic* gyroscopeDataCharacteristic;
@property (weak, nonatomic) CBCharacteristic* magnetometerDataCharacteristic;
@property (weak, nonatomic) CBCharacteristic* accelerometerConfigCharacteristic;
@property (weak, nonatomic) CBCharacteristic* gyroscopeConfigCharacteristic;
@property (weak, nonatomic) CBCharacteristic* magnetometerConfigCharacteristic;
@property (weak, nonatomic) CBCharacteristic* accelerometerPeriodCharacteristic;
@property (weak, nonatomic) CBCharacteristic* gyroscopePeriodCharacteristic;
@property (weak, nonatomic) CBCharacteristic* magnetometerPeriodCharacteristic;

@property (nonatomic, assign) NSTimeInterval timeReferenceOffset;

@end

@implementation MCMotionBLEPeripheral
@synthesize accelerometerActive;
@synthesize gyroActive;
@synthesize magnetometerActive;

+(NSDictionary*) serviceRegistry
{
  static dispatch_once_t pred;
  static NSDictionary *shared = nil;
  dispatch_once(&pred, ^{
    shared = @{[CBUUID UUIDWithString:@"F000AA10-0451-4000-B000-000000000000"]: @"accelerometerService",
               [CBUUID UUIDWithString:@"F000AA30-0451-4000-B000-000000000000"]: @"magnetometerService",
               [CBUUID UUIDWithString:@"F000AA50-0451-4000-B000-000000000000"]: @"gyroscopeService"};
  });
  return shared;
}

+(NSDictionary*) characteristicRegistry
{
  static dispatch_once_t pred;
  static NSDictionary *shared = nil;
  dispatch_once(&pred, ^{
    shared = @{[CBUUID UUIDWithString:@"F000AA11-0451-4000-B000-000000000000"]: @"accelerometerDataCharacteristic",
               [CBUUID UUIDWithString:@"F000AA12-0451-4000-B000-000000000000"]: @"accelerometerConfigCharacteristic",
               [CBUUID UUIDWithString:@"F000AA13-0451-4000-B000-000000000000"]: @"accelerometerPeriodCharacteristic",
               [CBUUID UUIDWithString:@"F000AA31-0451-4000-B000-000000000000"]: @"magnetometerDataCharacteristic",
               [CBUUID UUIDWithString:@"F000AA32-0451-4000-B000-000000000000"]: @"magnetometerConfigCharacteristic",
               [CBUUID UUIDWithString:@"F000AA33-0451-4000-B000-000000000000"]: @"magnetometerPeriodCharacteristic",
               [CBUUID UUIDWithString:@"F000AA51-0451-4000-B000-000000000000"]: @"gyroscopeDataCharacteristic",
               [CBUUID UUIDWithString:@"F000AA52-0451-4000-B000-000000000000"]: @"gyroscopeConfigCharacteristic",
               [CBUUID UUIDWithString:@"F000AA53-0451-4000-B000-000000000000"]: @"gyroscopePeriodCharacteristic"};
  });
  return shared;
}

+(NSArray*) characteristicUUIDsWithPropertyNamePrefix:(NSString*)prefix
{
  NSMutableArray* characteristics = [[NSMutableArray alloc] initWithCapacity:3];
  [[self characteristicRegistry] enumerateKeysAndObjectsUsingBlock:^(CBUUID* uuid, NSString* propertyName, BOOL *stop) {
    if ([propertyName hasPrefix:prefix]) {
      [characteristics addObject:uuid];
    }
  }];
  return characteristics;
}

+(NSArray*)supportedServiceUUIDs
{
  return [self serviceRegistry].allKeys;
}

-(id) initWithPeripheral:(CBPeripheral*)peripheral
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _corePeripheral = peripheral;
  _uuid = _corePeripheral.identifier.UUIDString;
  _type = @"ble";
  _updateInterval = 0.1;
  accelerometerActive = NO;
  gyroActive = NO;
  magnetometerActive = NO;
  
  NSTimeInterval secondsFromBoot = [[NSProcessInfo processInfo] systemUptime];
  NSTimeInterval secondsFromReference = [NSDate timeIntervalSinceReferenceDate];
  _timeReferenceOffset = (secondsFromReference - secondsFromBoot) + NSTimeIntervalSince1970;

  [self corePeripheralDidReconnect];
  return self;
}

- (NSTimeInterval)secondsFromUnixEpochForDeviceTime:(NSTimeInterval)deviceTime
{
  return deviceTime + _timeReferenceOffset;
}

-(void) corePeripheralDidReconnect
{
  _corePeripheral.delegate = self;
  [self findServices];
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  NSLog(@"notification state %@ is %i, error = %@", characteristic.UUID.UUIDString, characteristic.isNotifying, error);
  if ([_accelerometerDataCharacteristic.UUID isEqual:characteristic.UUID]) {
    self.accelerometerActive = characteristic.isNotifying;
  }
  else if ([_gyroscopeDataCharacteristic.UUID isEqual:characteristic.UUID]) {
    self.gyroActive = characteristic.isNotifying;
  }
  else if ([_magnetometerDataCharacteristic.UUID isEqual:characteristic.UUID]) {
    self.magnetometerActive = characteristic.isNotifying;
  }
}

-(void) peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
  NSLog(@"wrote value %@, error = %@", characteristic.UUID.UUIDString, error);
}

+(NSData*) swapToHostFrom3Int16LittleEndian:(NSData*)data
{
  if (CFByteOrderBigEndian == CFByteOrderGetCurrent()) {
    uint8_t const* bytes = data.bytes;
    uint8_t swapped[6] = {bytes[1],bytes[0],bytes[3],bytes[2],bytes[5],bytes[4]};
    data = [NSData dataWithBytes:swapped length:6];
  }
  return data;
}

-(CMAcceleration) acceleration
{
  static const double scale = 2.0 / 128.0; // full range is +/- 2 G
  NSData* data = _accelerometerDataCharacteristic.value;
  int8_t x, y, z;
  [data getBytes:&x range:(NSRange){.location=0, .length=1}];
  [data getBytes:&y range:(NSRange){.location=1, .length=1}];
  [data getBytes:&z range:(NSRange){.location=2, .length=1}];
  return (CMAcceleration){
    // account for sensor mounting and scaling
    
    .x = + scale * x ,
    .y = - scale * y,
    .z = + scale * z};
}

-(CMMagneticField) magneticField
{
  static const double scale = 1000.0 / 32768.0; // full range is +/- 1000 uT

  NSData* data = [self.class swapToHostFrom3Int16LittleEndian:_magnetometerDataCharacteristic.value];
  
  int16_t x, y, z;
  [data getBytes:&x range:(NSRange){.location=0, .length=2}];
  [data getBytes:&y range:(NSRange){.location=2, .length=2}];
  [data getBytes:&z range:(NSRange){.location=4, .length=2}];

  return (CMMagneticField){
    // account for sensor mounting and scaling
    .x = - scale * x,
    .y = - scale * y,
    .z = + scale * z};
}

-(CMRotationRate) rotationRate
{
  static const double scale = 250.0 / 32768.0 * M_PI / 180.0; // full range is +/- 250 deg/sec, convert to radians per second to match local device
  
  NSData* data = [self.class swapToHostFrom3Int16LittleEndian:_magnetometerDataCharacteristic.value];
  
  int16_t x, y, z;
  [data getBytes:&x range:(NSRange){.location=0, .length=2}];
  [data getBytes:&y range:(NSRange){.location=2, .length=2}];
  [data getBytes:&z range:(NSRange){.location=4, .length=2}];
  
  return (CMRotationRate){
    // account for sensor mounting and scaling
    .x = - scale * x,
    .y = - scale * y,
    .z = + scale * z};
}

-(void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
  NSTimeInterval time = [NSProcessInfo processInfo].systemUptime;
  
  if ([characteristic.UUID isEqual:_accelerometerDataCharacteristic.UUID]) {
    MCAccelerometerData* data = [[MCAccelerometerData alloc] initWithAcceleration:[self acceleration] time:time];
    [MCMotionStore.sharedInstance storeAccelerometer:data device:self];
  }
  else if ([characteristic.UUID isEqual:_gyroscopeDataCharacteristic.UUID]) {
    MCGyroData* data = [[MCGyroData alloc] initWithRotationRate:[self rotationRate] time:time];
    [MCMotionStore.sharedInstance storeGyroscope:data device:self];
  }
  else if ([characteristic.UUID isEqual:_magnetometerDataCharacteristic.UUID]) {
    MCMagnetometerData* data = [[MCMagnetometerData alloc] initWithMagneticField:[self magneticField] time:time];
    [MCMotionStore.sharedInstance storeMagnetometer:data device:self];
  }
}

-(BOOL) isConnected
{
  return _corePeripheral.state == CBPeripheralStateConnected;
}

-(BOOL) isAccelerometerAvailable
{
  return _accelerometerService ? YES : NO;
}

-(BOOL) isGyroAvailable
{
  return _gyroscopeService ? YES : NO;
}

-(BOOL) isMagnetometerAvailable
{
  return _magnetometerService ? YES : NO;
}

-(BOOL) isDeviceMotionAvailable
{
  return NO;
}

-(BOOL) isAccelerometerActive
{
  return _accelerometerDataCharacteristic.isNotifying;
}

-(BOOL) isGyroActive
{
  return _gyroscopeDataCharacteristic.isNotifying;
}

-(BOOL) isMagnetometerActive
{
  return _magnetometerDataCharacteristic.isNotifying;
}

-(BOOL) isDeviceMotionActive
{
  return NO;
}

-(NSData*) getUpdateIntervalData
{
  uint8_t interval_10ms = 100 * _updateInterval;
  if (interval_10ms == 0) {
    interval_10ms = 1;
  }
  NSData* data = [NSData dataWithBytes:&interval_10ms length:1];
  return data;
}

- (void)setAccelerometerEnabled:(BOOL)accelerometerEnabled
{
  _accelerometerEnabled = accelerometerEnabled;
  [self syncAccelerometer];
}

- (void)setGyroEnabled:(BOOL)gyroEnabled
{
  _gyroEnabled = gyroEnabled;
  [self syncGyro];
}

- (void)setMagnetometerEnabled:(BOOL)magnetometerEnabled
{
  _magnetometerEnabled = magnetometerEnabled;
  [self syncMagnetometer];
}

- (void)setDeviceMotionEnabled:(BOOL)deviceMotionEnabled
{
  _deviceMotionEnabled = deviceMotionEnabled;
  // no device motion
}

// TODO crash logs show problems calling write value for characteristic.  Hypothesis is that the
// device is disconnecting/reconnecting and we have a race where isXxxActive is true but we haven't
// finished didDiscoverCharateristics so the characteristics are old/null.  We should either get
// rid of the cached characteristics or check they are valid before using (or catch exception so we
// don't crash).  For now, try testing the config characteristic.

- (void)syncAccelerometer
{
  if (!self.isConnected || !_accelerometerConfigCharacteristic) {
    return;
  }
  if (YES == _accelerometerEnabled && NO == self.isAccelerometerActive) {
    [_corePeripheral writeValue:[NSData dataWithBytes:&(uint8_t){0x01} length:1] forCharacteristic:_accelerometerConfigCharacteristic type:CBCharacteristicWriteWithResponse];
    [_corePeripheral writeValue:[self getUpdateIntervalData] forCharacteristic:_accelerometerPeriodCharacteristic type:CBCharacteristicWriteWithResponse];
    [_corePeripheral setNotifyValue:YES forCharacteristic:_accelerometerDataCharacteristic];
  }
  else if (NO == _accelerometerEnabled && YES == self.isAccelerometerActive) {
    [_corePeripheral setNotifyValue:NO forCharacteristic:_accelerometerDataCharacteristic];
    [_corePeripheral writeValue:[NSData dataWithBytes:&(uint8_t){0x00} length:1] forCharacteristic:_accelerometerConfigCharacteristic type:CBCharacteristicWriteWithResponse];
  }
}

- (void)syncGyro
{
  if (!self.isConnected || !_gyroscopeConfigCharacteristic) {
    return;
  }
  if (YES == _gyroEnabled && NO == self.isGyroActive) {
    [_corePeripheral writeValue:[NSData dataWithBytes:&(uint8_t){0x07} length:1] forCharacteristic:_gyroscopeConfigCharacteristic type:CBCharacteristicWriteWithResponse];
    if (_gyroscopePeriodCharacteristic) {
      [_corePeripheral writeValue:[self getUpdateIntervalData] forCharacteristic:_gyroscopePeriodCharacteristic type:CBCharacteristicWriteWithResponse];
    }
    [_corePeripheral setNotifyValue:YES forCharacteristic:_gyroscopeDataCharacteristic];
  }
  else if (NO == _gyroEnabled && YES == self.isGyroActive) {
    [_corePeripheral setNotifyValue:NO forCharacteristic:_gyroscopeDataCharacteristic];
    [_corePeripheral writeValue:[NSData dataWithBytes:&(uint8_t){0x00} length:1] forCharacteristic:_gyroscopeConfigCharacteristic type:CBCharacteristicWriteWithResponse];
  }
}

- (void)syncMagnetometer
{
  if (!self.isConnected || !_magnetometerConfigCharacteristic) {
    return;
  }
  if (YES == _magnetometerEnabled && NO == self.isMagnetometerActive) {
    [_corePeripheral writeValue:[NSData dataWithBytes:&(uint8_t){0x01} length:1] forCharacteristic:_magnetometerConfigCharacteristic type:CBCharacteristicWriteWithResponse];
    [_corePeripheral writeValue:[self getUpdateIntervalData] forCharacteristic:_magnetometerPeriodCharacteristic type:CBCharacteristicWriteWithResponse];
    [_corePeripheral setNotifyValue:YES forCharacteristic:_magnetometerDataCharacteristic];
  }
  else if (NO == _magnetometerEnabled && YES == self.isMagnetometerActive) {
    [_corePeripheral setNotifyValue:NO forCharacteristic:_magnetometerDataCharacteristic];
    [_corePeripheral writeValue:[NSData dataWithBytes:&(uint8_t){0x00} length:1] forCharacteristic:_magnetometerConfigCharacteristic type:CBCharacteristicWriteWithResponse];
  }
}

-(void) findServices
{
  for (CBService* s in _corePeripheral.services) {
    NSString* propertyName = [self.class serviceRegistry][s.UUID];
    if (propertyName) {
      [self setValue:s forKey:propertyName];
      NSString* prefix = [propertyName stringByReplacingOccurrencesOfString:@"Service" withString:@""];
      [_corePeripheral discoverCharacteristics:[self.class characteristicUUIDsWithPropertyNamePrefix:prefix] forService:s];
    }
  }
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
  for (CBCharacteristic* c in service.characteristics) {
    NSString* propertyName = [self.class characteristicRegistry][c.UUID];
    if (propertyName) {
      [self setValue:c forKey:propertyName];
    }
  }
  if ([service.UUID isEqual:_accelerometerService.UUID]) {
    [self syncAccelerometer];
  }
  else if ([service.UUID isEqual:_gyroscopeService.UUID]) {
    [self syncGyro];
  }
  else if ([service.UUID isEqual:_magnetometerService.UUID]) {
    [self syncMagnetometer];
  }
}

@end
