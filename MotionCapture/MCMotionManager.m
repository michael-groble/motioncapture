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

#import <CoreMotion/CoreMotion.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <AVFoundation/AVFoundation.h>
#import <objc/message.h>

#import "MCMotionManager.h"
#import "MCMotionStore.h"
#import "MCMotionLocalDevice.h"
#import "MCMotionBLEPeripheral.h"

@interface MCMotionManager ()<CBCentralManagerDelegate, CBPeripheralDelegate>
{
  NSMutableArray* _peripherals;
  NSMutableArray* _disconnectedPeripherals;
}

@property(nonatomic, strong) MCMotionLocalDevice* localDevice;
@property(nonatomic, strong) NSMutableDictionary* bleUnknownDevices;
@property(nonatomic, strong) CBCentralManager* central;
@property(nonatomic, strong) AVAudioEngine* engine;
@property(nonatomic, assign, getter = isScanning) BOOL scanning;

-(void)insertObject:(MCMotionPeripheral*)object inPeripheralsAtIndex:(NSUInteger)index;
-(void)removeObjectFromPeripheralsAtIndex:(NSUInteger)index;
-(NSUInteger) indexOfPeripheralWithCBPeripheral:(CBPeripheral*)peripheral;

-(void)insertObject:(MCMotionPeripheral*)object inDisconnectedPeripheralsAtIndex:(NSUInteger)index;
-(void)removeObjectFromDisconnectedPeripheralsAtIndex:(NSUInteger)index;
-(NSUInteger) indexOfDisconnectedPeripheralWithCBPeripheral:(CBPeripheral*)peripheral;

@end

@implementation MCMotionManager

- (id)init
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _localDevice = [[MCMotionLocalDevice alloc] init];
  _peripherals = [[NSMutableArray alloc] initWithCapacity:10];
  _disconnectedPeripherals = [[NSMutableArray alloc] initWithCapacity:10];
  _bleUnknownDevices = [[NSMutableDictionary alloc] initWithCapacity:10];
  _central = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
  _engine = [[AVAudioEngine alloc] init];
  
  AVAudioInputNode* input = [_engine inputNode];
  // We don't do anything with the data, we just set up the tap to get the red recording banner on the device so people know it is recording.
  // TODO fix so we still get banner without messing up audio.
  // TODO Also consider recording the motion as a metadata track in a real audio recording.
  [input installTapOnBus:0 bufferSize:8192 format:[input inputFormatForBus:0] block:^(AVAudioPCMBuffer *buffer, AVAudioTime *when){}];
  
  self.recording = [MCMotionStore sharedInstance].enabled;
  self.scanning = NO;
  
  return self;
}

+ (MCMotionManager*)sharedInstance
{
  static dispatch_once_t pred;
  static MCMotionManager *sharedInstance = nil;
  
  dispatch_once(&pred, ^{ sharedInstance = [[self alloc] init]; });
  return sharedInstance;
}

- (void)saveState:(NSCoder *)coder
{
  NSDictionary* state = @{ // TODO
                          };
  
  [coder encodeObject:state forKey:@"motion"];
}

- (void) setRecording:(BOOL)recording
{
  if (YES == recording) {
    NSError* error;
    if (NO == [_engine startAndReturnError:&error]) {
      NSLog(@"Error starting AVAudioEngine: %@", error.localizedDescription);
    }
  }
  else {
    [_engine stop];
  }
  _recording = recording;
  [MCMotionStore sharedInstance].enabled = recording;
}

- (void)restoreState:(NSCoder *)coder
{
  NSDictionary* state = (NSDictionary*)[coder decodeObjectForKey:@"motion"];
  if (state) {
    // TODO figure out new state
  }
}

-(OSStatus) io:(AudioBufferList*)ioData
         flags:(AudioUnitRenderActionFlags*)ioActionFlags
     timeStamp:(const AudioTimeStamp*)inTimeStamp
     busNumber:(UInt32)inBusNumber
     numFrames:(UInt32)inNumberFrames
{
  return noErr;
}

-(void) scanForPeripherals
{
  if (CBCentralManagerStatePoweredOn == _central.state) {
    // TODO understand why nothing is detected when we provide list of services [MCMotionBLEPeripheral supportedServiceUUIDs]
    [_central scanForPeripheralsWithServices:nil options:nil];
    self.scanning = YES;
    [self startScanningTimer];
  }
  else {
    // TODO
  }
}

-(void)connectPeripheral:(MCMotionBLEPeripheral *)peripheral
{
  peripheral.autoconnect = YES;
  NSUInteger existingIndex = [_peripherals indexOfObject:peripheral];
  if (NSNotFound != existingIndex) {
    if (peripheral.isConnected == YES) {
      return;
    }
    else {
      // fixup our bookeeping
      [self removeObjectFromPeripheralsAtIndex:existingIndex];
      [self insertObject:peripheral inDisconnectedPeripheralsAtIndex:_disconnectedPeripherals.count];
    }
  }
  existingIndex = [_disconnectedPeripherals indexOfObject:peripheral];
  if (NSNotFound != existingIndex) {
    [_central connectPeripheral:peripheral.corePeripheral options:nil];
  }
}

-(void)disconnectPeripheral:(MCMotionBLEPeripheral *)peripheral
{
  peripheral.autoconnect = NO;
  // TODO distinguish between peripheral that is requested to be disconnected
  // and one not so requested.  Automatically reconnect when not explicitly disconnected.
  NSUInteger existingIndex = [_disconnectedPeripherals indexOfObject:peripheral];
  if (NSNotFound != existingIndex) {
    if (peripheral.isConnected == NO) {
      return;
    }
    else {
      // fixup our bookeeping
      [self removeObjectFromDisconnectedPeripheralsAtIndex:existingIndex];
      [self insertObject:peripheral inPeripheralsAtIndex:_peripherals.count];
    }
  }
  existingIndex = [_peripherals indexOfObject:peripheral];
  if (NSNotFound != existingIndex) {
    [_central cancelPeripheralConnection:peripheral.corePeripheral];
  }
}

-(void)centralManagerDidUpdateState:(CBCentralManager*)central {
  if (central.state != CBCentralManagerStatePoweredOn) {
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"BLE not supported!" message:[NSString stringWithFormat:@"CoreBluetooth return state: %d",(int)central.state] delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
    // TODO disable scan button
  }
}

-(void)centralManager:(CBCentralManager*)central didDiscoverPeripheral:(CBPeripheral*)peripheral advertisementData:(NSDictionary*)advertisementData RSSI:(NSNumber*)RSSI {
  NSLog(@"Found a BLE Device : %@",peripheral);
  if (!_bleUnknownDevices[peripheral.identifier]) {
    _bleUnknownDevices[peripheral.identifier] = peripheral;
    [central connectPeripheral:peripheral options:nil];
  }
}

-(void)centralManager:(CBCentralManager*)central didConnectPeripheral:(CBPeripheral*)peripheral
{
  NSLog(@"Peripheral connected: %@",peripheral.identifier.UUIDString);
  peripheral.delegate = self;
  [peripheral discoverServices:[MCMotionBLEPeripheral supportedServiceUUIDs]];
}

-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
  NSLog(@"Services scanned !");
  if (peripheral.services.count == 0) {
    // this peripheral does not suport our services
    [_central cancelPeripheralConnection:peripheral];
  }
  else {
    peripheral.delegate = nil;
    NSUInteger existingIndex = [self indexOfDisconnectedPeripheralWithCBPeripheral:peripheral];
    if (NSNotFound != existingIndex) {
      // We don't want the peripheral to be garbage collected. Move it so we don't loose reference
      MCMotionBLEPeripheral* existing = _disconnectedPeripherals[existingIndex];
      [self removeObjectFromDisconnectedPeripheralsAtIndex:existingIndex];
      [existing corePeripheralDidReconnect];
      // update existing index to peripherals
      existingIndex = _peripherals.count;
      [self insertObject:existing inPeripheralsAtIndex:existingIndex];
    }
    else {
      existingIndex = [self indexOfPeripheralWithCBPeripheral:peripheral];
    }
    if (NSNotFound == existingIndex) {
      MCMotionBLEPeripheral* p = [[MCMotionBLEPeripheral alloc] initWithPeripheral:peripheral];
      // by default, we will autoconnect to peripherals that match the services we want
      // when user explicitly disconnects, we'll stop autoconnect
      p.autoconnect = YES;
      [self insertObject:p inPeripheralsAtIndex:_peripherals.count];
    }
    else {
    }
  }
}

-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
  NSLog(@"Peripheral connection failed for %@: %@", peripheral.identifier.UUIDString, error);
  NSUInteger existingIndex = [_disconnectedPeripherals indexOfObject:peripheral];
  if (NSNotFound != existingIndex) {
    MCMotionPeripheral* existing = _disconnectedPeripherals[existingIndex];
    if (YES == existing.autoconnect) {
      [_central connectPeripheral:peripheral options:nil];
    }
  }
}

-(void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
  NSLog(@"Peripheral disconnected: %@, error = %@",peripheral.identifier.UUIDString, error);
  [_bleUnknownDevices removeObjectForKey:peripheral.identifier];
  NSUInteger existingIndex = [self indexOfPeripheralWithCBPeripheral:peripheral];
  if (NSNotFound != existingIndex) {
    MCMotionPeripheral* existing = _peripherals[existingIndex];
    [self removeObjectFromPeripheralsAtIndex:existingIndex];
    [self insertObject:existing inDisconnectedPeripheralsAtIndex:_disconnectedPeripherals.count];
    if (YES == existing.autoconnect) {
      [_central connectPeripheral:peripheral options:nil];
    }
  }
  else {
    // check if we need to autoconnect if never fully connected
    NSUInteger existingIndex = [self indexOfDisconnectedPeripheralWithCBPeripheral:peripheral];
    if (NSNotFound != existingIndex) {
      MCMotionPeripheral* existing = _disconnectedPeripherals[existingIndex];
      if (YES == existing.autoconnect) {
        [_central connectPeripheral:peripheral options:nil];
      }
    }
  }
}

-(NSUInteger) indexOfPeripheralWithCBPeripheral:(CBPeripheral *)peripheral
{
  return[_peripherals indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
    MCMotionBLEPeripheral* p = obj;
    return ([p.uuid isEqual:peripheral.identifier.UUIDString]) ? YES : NO;
  }];
}

-(NSUInteger) indexOfDisconnectedPeripheralWithCBPeripheral:(CBPeripheral *)peripheral
{
  return[_disconnectedPeripherals indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop){
    MCMotionBLEPeripheral* p = obj;
    return ([p.uuid isEqual:peripheral.identifier.UUIDString]) ? YES : NO;
  }];
}


- (void)startScanningTimer {
  [self cancelScanningTimer];
  [self performSelector:@selector(stopScanning)
             withObject:nil
             afterDelay:5.0];
}

- (void)cancelScanningTimer {
  [NSObject cancelPreviousPerformRequestsWithTarget:self
                                           selector:@selector(stopScanning)
                                             object:nil];
}

- (void)stopScanning {
  [_central stopScan];
  self.scanning = NO;
}

-(NSUInteger)countOfPeripherals
{
  return _peripherals.count;
}

-(MCMotionPeripheral*)objectInPeripheralsAtIndex:(NSUInteger)index
{
  return _peripherals[index];
}

-(void)insertObject:(MCMotionPeripheral *)object inPeripheralsAtIndex:(NSUInteger)index
{
  [_peripherals insertObject:object atIndex:index];
}

-(void)removeObjectFromPeripheralsAtIndex:(NSUInteger)index
{
  [_peripherals removeObjectAtIndex:index];
}


-(NSUInteger)countOfDisconnectedPeripherals
{
  return _disconnectedPeripherals.count;
}

-(MCMotionPeripheral*)objectInDisconnectedPeripheralsAtIndex:(NSUInteger)index
{
  return _disconnectedPeripherals[index];
}

-(void)insertObject:(MCMotionPeripheral *)object inDisconnectedPeripheralsAtIndex:(NSUInteger)index
{
  [_disconnectedPeripherals insertObject:object atIndex:index];
}

-(void)removeObjectFromDisconnectedPeripheralsAtIndex:(NSUInteger)index
{
  [_disconnectedPeripherals removeObjectAtIndex:index];
}

@end


