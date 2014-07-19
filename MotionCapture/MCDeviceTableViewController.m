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

#import "MCDeviceTableViewController.h"
#import "MCDeviceTableViewCell.h"
#import "MCMotionPeripheral.h"
#import "MCMotionLocalDevice.h"
#import "MCAppDelegate.h"
#import "MCMotionManager.h"
#import "MCDeviceDetailViewController.h"
#import "MCMotionStore.h"

@interface MCDeviceTableViewController ()
@property (nonatomic, strong) NSByteCountFormatter* sizeFormatter;
@property (nonatomic, strong) NSTimer* storageSpaceUpdateTimer;
-(void) updateStorageSpace:(NSTimer*)timer;
@end

#define STORAGE_SECTION                0
#define LOCAL_DEVICE_SECTION           1
#define CONNECTED_DEVICE_SECTION       2
#define DISCONNECTED_DEVICE_SECTION    3
#define NUM_SECTIONS                   4

@implementation MCDeviceTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (!self) {
    return nil;
  }
  return self;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _sizeFormatter = [[NSByteCountFormatter alloc] init];
  _sizeFormatter.countStyle = NSByteCountFormatterCountStyleFile;
  _storageSpaceUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateStorageSpace:) userInfo:nil repeats:YES];
  [[MCMotionManager sharedInstance] addObserver:self forKeyPath:@"peripherals" options:0 context:nil];
  [[MCMotionManager sharedInstance] addObserver:self forKeyPath:@"disconnectedPeripherals" options:0 context:nil];
  [[MCMotionManager sharedInstance] addObserver:self forKeyPath:@"scanning" options:0 context:nil];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];
  [self.tableView reloadData];
  [_storageSpaceUpdateTimer invalidate];
  _storageSpaceUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(updateStorageSpace:) userInfo:nil repeats:YES];
}

-(void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  [_storageSpaceUpdateTimer invalidate];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return NUM_SECTIONS;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case STORAGE_SECTION:
      return 2;
    case LOCAL_DEVICE_SECTION:
      return 1;
    case CONNECTED_DEVICE_SECTION:
      return [MCMotionManager sharedInstance].peripherals.count;
    case DISCONNECTED_DEVICE_SECTION:
      return [MCMotionManager sharedInstance].disconnectedPeripherals.count;
    default:
      return 0;
  }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  switch (indexPath.section)
  {
    case STORAGE_SECTION:
      return 45;
  }
  return 56;
}

-(void) updateCell:(MCDeviceTableViewCell*)cell withPeripheral:(MCMotionPeripheral*)peripheral
{
  cell.deviceName.text = peripheral.name ? peripheral.name : peripheral.uuid;
  cell.deviceLocation.text = peripheral.locationString;
  UIColor* inactiveColor = [UIColor lightGrayColor];
  UIColor* activeColor = [UIColor blueColor];
  cell.accelerationIndicator.textColor = peripheral.isAccelerometerActive ? activeColor : inactiveColor;
  cell.rotationIndicator.textColor = peripheral.isGyroActive ? activeColor : inactiveColor;
  cell.magneticIndicator.textColor = peripheral.isMagnetometerActive ? activeColor : inactiveColor;
  cell.fusedIndicator.textColor = peripheral.isDeviceMotionActive ? activeColor : inactiveColor;
}

-(void) updateStorageSpace:(NSTimer*)timer
{
  _storageSpaceLabel.text = [self.sizeFormatter stringFromByteCount:MCMotionStore.sharedInstance.byteCount];
}

- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* plainCell;
  MCDeviceTableViewCell* cell;
  switch (indexPath.section)
  {
    case STORAGE_SECTION:
      switch (indexPath.row)
      {
        case 0:
          plainCell = [tableView dequeueReusableCellWithIdentifier:@"RecordingCell" forIndexPath:indexPath];
          _recordSwitch = (UISwitch*)[plainCell viewWithTag:1];
          _recordSwitch.on = [MCMotionManager sharedInstance].isRecording;
          return plainCell;
        case 1:
          plainCell = [tableView dequeueReusableCellWithIdentifier:@"DataCell" forIndexPath:indexPath];
          _storageSpaceLabel = (UILabel*)[plainCell viewWithTag:1];
          [self updateStorageSpace:nil];
          return plainCell;
      }
      return nil;
    case LOCAL_DEVICE_SECTION:
      cell = (MCDeviceTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"DeviceStatusCell" forIndexPath:indexPath];
      [self updateCell:cell withPeripheral:[MCMotionManager sharedInstance].localDevice];
      return cell;
    case CONNECTED_DEVICE_SECTION:
      cell = (MCDeviceTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"DeviceStatusCell" forIndexPath:indexPath];
      [self updateCell:cell withPeripheral:[MCMotionManager sharedInstance].peripherals[indexPath.row]];
      return cell;
    case DISCONNECTED_DEVICE_SECTION:
      cell = (MCDeviceTableViewCell*)[tableView dequeueReusableCellWithIdentifier:@"DeviceStatusCell" forIndexPath:indexPath];
      [self updateCell:cell withPeripheral:[MCMotionManager sharedInstance].disconnectedPeripherals[indexPath.row]];
      return cell;
  }
  
  return cell;
}

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case STORAGE_SECTION:
      return @"Recording";
    case LOCAL_DEVICE_SECTION:
      return @"Local Device";
    case CONNECTED_DEVICE_SECTION:
      return @"Connected Peripherals";
    case DISCONNECTED_DEVICE_SECTION:
      return @"Disconnected Peripherals";
    default:
      return @"";
  }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
  if ([@"scanning" isEqualToString:keyPath]) {
    MCMotionManager* manager = object;
    _rescanButton.enabled  = manager.scanning == YES ? NO : YES;
  }
  else {
    [self.tableView reloadData];
  }
}

#pragma mark - Navigation

-(MCMotionPeripheral*) peripheralAtIndexPath:(NSIndexPath*)indexPath
{
  switch (indexPath.section)
  {
    case LOCAL_DEVICE_SECTION:
      return [MCMotionManager sharedInstance].localDevice;
    case CONNECTED_DEVICE_SECTION:
      return [MCMotionManager sharedInstance].peripherals[indexPath.row];
    case DISCONNECTED_DEVICE_SECTION:
      return [MCMotionManager sharedInstance].disconnectedPeripherals[indexPath.row];
    default:
      return nil;
  }
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
  if ([@"showDeviceDetail" isEqualToString:segue.identifier]) {
    MCDeviceDetailViewController* nextController = (MCDeviceDetailViewController*)[segue destinationViewController];
    nextController.device = [self peripheralAtIndexPath:[self.tableView indexPathForSelectedRow]];
  }
}

- (IBAction)toggleRecording:(UISwitch *)sender {
  [MCMotionManager sharedInstance].recording = sender.on;
}

- (IBAction)doScan:(id)sender {
  [[MCMotionManager sharedInstance] scanForPeripherals];
  _rescanButton.enabled = NO;
}
@end
