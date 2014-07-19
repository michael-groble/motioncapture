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

#import "MCDeviceDetailViewController.h"
#import "MCMotionPeripheral.h"
#import "MCMotionBLEPeripheral.h"
#import "MCAppDelegate.h"
#import "MCMotionManager.h"

@interface MCDeviceDetailViewController () <UITextFieldDelegate>

@end

@implementation MCDeviceDetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (!self) {
      return nil;
    }
    return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  self.deviceUUID.text = _device.uuid;
  self.deviceName.text = _device.name;
  self.deviceName.delegate = self;
  self.accelerationSwitch.enabled = _device.accelerometerAvailable;
  self.accelerationSwitch.on = _device.accelerometerActive;
  self.rotationRateSwitch.enabled = _device.gyroAvailable;
  self.rotationRateSwitch.on = _device.gyroActive;
  self.magneticFieldSwitch.enabled = _device.magnetometerAvailable;
  self.magneticFieldSwitch.on = _device.magnetometerActive;
  self.deviceMotionSwitch.enabled = _device.deviceMotionAvailable;
  self.deviceMotionSwitch.on = _device.deviceMotionActive;

  if ([_device isKindOfClass:[MCMotionBLEPeripheral class]]) {
    [_device addObserver:self forKeyPath:@"corePeripheral.state" options:0 context:nil];
    self.connectButton.title = (YES == ((MCMotionBLEPeripheral*)_device).isConnected) ? @"Disconnect" : @"Connect";
    self.connectButton.enabled = YES;
  }
  else {
    self.connectButton.title = @"";
    self.connectButton.enabled = NO;
  }

  // TODO fix so it doesn't depend on storyboard order
  switch (_device.bodySide){
    case MCBodySideUnknown:
      self.bodySide.selectedSegmentIndex = UISegmentedControlNoSegment;
      break;
    case MCBodySideLeft:
      self.bodySide.selectedSegmentIndex = 0;
      break;
    case MCBodySideRight:
      self.bodySide.selectedSegmentIndex = 1;
      break;
  }
  
  // TODO fix so it doesn't depend on storyboard order
  switch (_device.bodyPart) {
    case MCBodyPartUnknown:
      self.bodyPart.selectedSegmentIndex = UISegmentedControlNoSegment;
      break;
    case MCBodyPartHead:
      self.bodyPart.selectedSegmentIndex = 0;
      break;
    case MCBodyPartArm:
      self.bodyPart.selectedSegmentIndex = 1;
      break;
    case MCBodyPartWrist:
      self.bodyPart.selectedSegmentIndex = 2;
      break;
    case MCBodyPartHip:
      self.bodyPart.selectedSegmentIndex = 3;
      break;
    case MCBodyPartAnkle:
      self.bodyPart.selectedSegmentIndex = 4;
      break;
  }
  
  for (int i = 0; i < self.intervalSelector.numberOfSegments; ++i) {
    NSString* title = [self.intervalSelector titleForSegmentAtIndex:i];
    if (title.doubleValue == _device.updateInterval) {
      self.intervalSelector.selectedSegmentIndex = i;
    }
  }
  // TODO none selected, leave default?
}

-(void)viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  if ([_device isKindOfClass:[MCMotionBLEPeripheral class]]) {
    [_device removeObserver:self forKeyPath:@"corePeripheral.state"];
  }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)updateDeviceName:(UITextField *)name {
  _device.name = name.text;
  [name resignFirstResponder];
}

- (IBAction)updateBodySide:(UISegmentedControl *)side {
  // TODO fix so it doesn't depend on storyboard order
  switch (side.selectedSegmentIndex){
    case 0:
      _device.bodySide = MCBodySideLeft;
      break;
    case 1:
      _device.bodySide = MCBodySideRight;
      break;
  }
}

- (IBAction)updateBodyPart:(UISegmentedControl *)part {
  // TODO fix so it doesn't depend on storyboard order
  switch (part.selectedSegmentIndex){
    case 0:
      _device.bodyPart = MCBodyPartHead;
      break;
    case 1:
      _device.bodyPart = MCBodyPartArm;
      break;
    case 2:
      _device.bodyPart = MCBodyPartWrist;
      break;
    case 3:
      _device.bodyPart = MCBodyPartHip;
      break;
    case 4:
      _device.bodyPart = MCBodyPartAnkle;
      break;
  }
}

- (IBAction)doConnect:(UIBarButtonItem *)sender {
  if([_device isKindOfClass:[MCMotionBLEPeripheral class]]) {
    MCMotionBLEPeripheral* ble = (MCMotionBLEPeripheral*)_device;
    if ([@"Disconnect" isEqualToString:sender.title]) {
      [[MCMotionManager sharedInstance] disconnectPeripheral:ble];
      [self dismissViewControllerAnimated:YES completion:nil];
    }
    else {
      [[MCMotionManager sharedInstance] connectPeripheral:ble];
    }
  }
}

- (IBAction)updateInterval:(UISegmentedControl *)sender {
  NSString* title = [sender titleForSegmentAtIndex:sender.selectedSegmentIndex];
  _device.updateInterval = title.floatValue;
}


- (IBAction)toggleAcceleration:(UISwitch *)sender
{
  _device.accelerometerEnabled = sender.isOn;
}

- (IBAction)toggleRotationRate:(UISwitch *)sender
{
  _device.gyroEnabled = sender.isOn;
}

- (IBAction)toggleMagneticField:(UISwitch *)sender
{
  _device.magnetometerEnabled = sender.isOn;

}

- (IBAction)toggleDeviceMotion:(UISwitch *)sender
{
  _device.deviceMotionEnabled = sender.isOn;

}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([@"corePeripheral.state" isEqualToString:keyPath]) {
    self.connectButton.title = (YES == ((MCMotionBLEPeripheral*)_device).isConnected) ? @"Disconnect" : @"Connect";
  }
}

-(BOOL) textFieldShouldEndEditing:(UITextField *)textField {
  return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

@end

