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

#import "MCAccelerometerData.h"

@interface MCAccelerometerData ()
@property (strong, nonatomic,readonly) CMAccelerometerData* core;
@end

@implementation MCAccelerometerData

@synthesize acceleration = _acceleration;
@synthesize timestamp = _timestamp;

-(id) initWithCoreMotion:(CMAccelerometerData *)accelerationData
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _core = accelerationData;
  return self;
}

-(id) initWithAcceleration:(CMAcceleration)acceleration time:(NSTimeInterval)time
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _acceleration = acceleration;
  _timestamp = time;
  return self;
}

-(CMAcceleration) acceleration
{
  if (_core) {
    return _core.acceleration;
  }
  return _acceleration;
}

-(NSTimeInterval) timestamp
{
  if (_core) {
    return _core.timestamp;
  }
  return _timestamp;
}
@end
