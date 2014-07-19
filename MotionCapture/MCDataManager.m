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

#import "MCDataManager.h"

@interface MCDataManager ()

@property (nonatomic, strong) NSString* bundleName;
@property (nonatomic, strong) NSString* modelName;
@property (nonatomic, strong) NSString* databaseName;
@property (nonatomic, strong) NSURL* databaseUrl;
@property (nonatomic, strong) NSManagedObjectModel* objectModel;
@property (nonatomic, strong) NSManagedObjectContext* objectContext;
@property (nonatomic, strong) NSPersistentStoreCoordinator* persistentStoreCoordinator;

@end

@implementation MCDataManager

- (id)initWithBundle:(NSString*)bundle model:(NSString*)model database:(NSString*)database
{
  self = [super init];
  if (!self) {
    return nil;
  }
  _bundleName = bundle;
  _modelName = model;
  _databaseName = database;
  
  NSURL* applicationDocumentsDirectory = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
  
  _databaseUrl = [applicationDocumentsDirectory URLByAppendingPathComponent:_databaseName];

  return self;
}

- (NSManagedObjectModel*)objectModel
{
	if (_objectModel)
		return _objectModel;
  
	NSBundle* bundle = [NSBundle mainBundle];
	if (_bundleName) {
		NSString* bundlePath = [[NSBundle mainBundle] pathForResource:_bundleName ofType:@"bundle"];
		bundle = [NSBundle bundleWithPath:bundlePath];
	}
  NSURL* modelUrl = [NSURL fileURLWithPath:[bundle pathForResource:_modelName ofType:@"momd"]];
  
  // TODO load specific version, e.g.
  // [bundle URLForResource:@"Blah2" withExtension:@"mom" subdirectory:@"Blah.momd"];

  _objectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
  
	return _objectModel;
}

- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
	if (_persistentStoreCoordinator) {
		return _persistentStoreCoordinator;
  }
  NSError* error;
  
  _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.objectModel];
	
  if (![self createDatabase:&error]) {
		NSLog(@"Fatal error while creating persistent store: %@", error);
		abort();
	}
  
	return _persistentStoreCoordinator;
}

- (NSPersistentStore*)createDatabase:(NSError**)error
{
  NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                            NSInferMappingModelAutomaticallyOption: @YES};
  
  return [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:_databaseUrl
                                                         options:options
                                                           error:error];
}

- (void)truncateDatabase
{
  NSPersistentStore* store = [self.persistentStoreCoordinator persistentStoreForURL:_databaseUrl];
  [self.objectContext performBlockAndWait:^{
    [self.objectContext rollback];
  }];
  
  [self.objectContext lock];
  NSError* error = nil;
  if (NO == [self.persistentStoreCoordinator removePersistentStore:store error:&error]) {
    NSLog(@"Error trying to truncate database %@", error);
  }
  else if (NO == [[NSFileManager defaultManager] removeItemAtPath:_databaseUrl.path error:&error]){
    NSLog(@"Error trying to delete file %@", error);
  }
  [self.objectContext unlock];
  _objectModel = nil;
  _objectContext = nil;
  _persistentStoreCoordinator = nil;
}

- (long long)databaseBytes
{
  NSNumber* size = nil;
  NSError* error = nil;
  [_databaseUrl getResourceValue:&size forKey:NSURLFileSizeKey error:&error];
  return size ? size.longLongValue : 0;
}

- (NSManagedObjectContext*)objectContext
{
	if (_objectContext)
		return _objectContext;
  
	// Create the main context only on the main thread
	if (![NSThread isMainThread]) {
		[self performSelectorOnMainThread:@selector(objectContext)
                           withObject:nil
                        waitUntilDone:YES];
		return _objectContext;
	}

	_objectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
	[_objectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];

	return _objectContext;
}

@end
