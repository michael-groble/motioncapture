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

#import "MCMotionPeripheral.h"
#import "MCMeasurement.h"

@implementation MCMotionPeripheral

@dynamic accelerometerAvailable;
@dynamic accelerometerActive;
@dynamic gyroAvailable;
@dynamic gyroActive;
@dynamic magnetometerAvailable;
@dynamic magnetometerActive;
@dynamic deviceMotionAvailable;
@dynamic deviceMotionActive;

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
  
  NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
  
  if ([key isEqualToString:@"locationString"]) {
    keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"bodySide", @"bodyPart"]];
  }

  return keyPaths;
}

-(NSString*)locationString
{
  NSString* sideString = @"";
  switch (_bodySide) {
    case MCBodySideLeft:
      sideString = @"L ";
      break;
    case MCBodySideRight:
      sideString = @"R ";
    case MCBodySideUnknown:
      break;
  }
  
  NSString* partString = @"?";
  switch (_bodyPart) {
    case MCBodyPartHead:
      partString = @"Head";
      break;
    case MCBodyPartArm:
      partString = @"Arm";
      break;
    case MCBodyPartWrist:
      partString = @"Wrist";
      break;
    case MCBodyPartHip:
      partString = @"Hip";
      break;
    case MCBodyPartAnkle:
      partString = @"Ankle";
      break;
    case MCBodyPartUnknown:
      break;
  }
  
  return [NSString stringWithFormat:@"%@%@", sideString, partString];
}

- (NSTimeInterval)secondsFromUnixEpochForDeviceTime:(NSTimeInterval)deviceTime
{
  return deviceTime;
}

- (BOOL)isEqual:(id)other
{
  if (other == self) {
    return YES;
  }
  else if (![super isEqual:other]) {
    return NO;
  }
  else {
    MCMotionPeripheral* otherPeripheral = other;
    return [_type isEqual:otherPeripheral.type] && [_uuid isEqual:otherPeripheral.uuid];
  }
}

- (NSUInteger)hash
{
    return [_uuid hash];
}

@end
