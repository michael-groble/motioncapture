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

#import "ErrorHandler.h"


@implementation ErrorHandler

+ (BOOL)errorFromErrnoWithDescription:(NSString*)description error:(NSError**) error
{
  if (error) {
    [self setError:error withDomain:NSPOSIXErrorDomain code:errno description:description];
  }
  return NO;
}

+ (BOOL) setError:(NSError**)error withDomain:(NSString*)domain code:(NSInteger)code description:(NSString*)description
{
  if (error) {
    NSMutableDictionary* userInfo = nil;
    if (description) {
      userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
      [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
    }
    *error = [NSError errorWithDomain:domain code:code userInfo:userInfo];
  }
  NSLog(@"Error %ld %@", (long)code, description);
  return NO;
}


+ (BOOL)hasError:(OSStatus)status domain:(NSString*)domain description:(NSString*)description error:(NSError**) error
{
  if (status != noErr) {
    if (error) {
      NSMutableDictionary* userInfo = nil;
      if (description) {
        userInfo = [NSMutableDictionary dictionaryWithCapacity:1];
        [userInfo setValue:description forKey:NSLocalizedDescriptionKey];
      }
      *error = [NSError errorWithDomain:domain code:status userInfo:userInfo];
    }
    NSLog(@"Error %d %@", (int)status, description);
#if !TARGET_OS_IPHONE
    NSLog(@"%s",GetMacOSStatusErrorString(status));
#endif
    return YES;
  }
  return NO;
}

@end
