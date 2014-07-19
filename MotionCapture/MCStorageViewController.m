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

#import "MCStorageViewController.h"
#import "MCMotionStore.h"
#import "MCAppDelegate.h"
#import "MCMotionManager.h"

@interface MCStorageViewController () <UIAlertViewDelegate>
@property (nonatomic, strong) NSByteCountFormatter* sizeFormatter;
@end

@implementation MCStorageViewController

- (id)initWithStyle:(UITableViewStyle)style
{
  self = [super initWithStyle:style];
  if (!self) {
    return nil;
  }
  return self;
}

- (MCAppDelegate*) appDelegate
{
  return (MCAppDelegate*) [UIApplication sharedApplication].delegate;
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  _sizeFormatter = [[NSByteCountFormatter alloc] init];
  _sizeFormatter.countStyle = NSByteCountFormatterCountStyleFile;
  _storageSpaceLabel.text = [self.sizeFormatter stringFromByteCount:MCMotionStore.sharedInstance.byteCount];

  if ([MCMotionManager sharedInstance].recording) {
    _clearDataButton.enabled = NO;
  }
  
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

- (IBAction)clearData:(id)sender {
  UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Delete" message:@"Delete all measurements?" delegate:self cancelButtonTitle:@"CANCEL" otherButtonTitles:@"OK", nil];
  [alert show];
}

-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if(buttonIndex==1)
  {
    [MCMotionStore.sharedInstance clearStore];
    _storageSpaceLabel.text = [self.sizeFormatter stringFromByteCount:MCMotionStore.sharedInstance.byteCount];
  }
}
@end
