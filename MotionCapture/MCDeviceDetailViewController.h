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

#import <UIKit/UIKit.h>

@class MCMotionPeripheral;

@interface MCDeviceDetailViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *deviceUUID;
@property (weak, nonatomic) IBOutlet UITextField *deviceName;
@property (weak, nonatomic) IBOutlet UIProgressView *motionProgress;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bodySide;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *connectButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *bodyPart;
@property (weak, nonatomic) IBOutlet UISegmentedControl *intervalSelector;
@property (weak, nonatomic) IBOutlet UISwitch *accelerationSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *rotationRateSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *magneticFieldSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *deviceMotionSwitch;

@property (weak, nonatomic) MCMotionPeripheral* device;


- (IBAction)updateDeviceName:(UITextField *)name;
- (IBAction)updateBodySide:(UISegmentedControl *)side;
- (IBAction)updateBodyPart:(UISegmentedControl *)part;
- (IBAction)doConnect:(UIBarButtonItem*)sender;
- (IBAction)updateInterval:(UISegmentedControl *)sender;

- (IBAction)toggleAcceleration:(UISwitch *)sender;
- (IBAction)toggleRotationRate:(UISwitch *)sender;
- (IBAction)toggleMagneticField:(UISwitch *)sender;
- (IBAction)toggleDeviceMotion:(UISwitch *)sender;

@end
