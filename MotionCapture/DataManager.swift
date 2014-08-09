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

import Foundation
import CoreData

class DataManager : NSObject
{
  let bundleName: String?
  let modelName: String
  let databaseName: String
  
  init(bundleName: String?, modelName: String, databaseName: String) {
    self.bundleName = bundleName
    self.modelName = modelName
    self.databaseName = databaseName
  }
  
  var objectContext: NSManagedObjectContext {
    get {
      return clearableObjectContext.getOrCreateOnMainThread()
    }
  }
  
  var objectModel: NSManagedObjectModel {
    get {
      return clearableObjectModel.getOrCreate()
    }
  }
  
  func truncateDatabase() {
    let store = persistentStoreCoordinator.persistentStoreForURL(databaseUrl)
    objectContext.performBlockAndWait() {
      self.objectContext.rollback()
      var error: NSError? = nil;
      if !self.persistentStoreCoordinator.removePersistentStore(store, error:&error) {
        NSLog("Error trying to truncate database %@", error!)
      }
      else if !NSFileManager.defaultManager().removeItemAtPath(self.databaseUrl.path, error:&error) {
        NSLog("Error trying to delete file %@", error!);
      }
    }
    clearableObjectModel.clear()
    clearableObjectContext.clear()
    clearablePersistentStoreCoordinator.clear()
  }
  
  var databaseBytes: CLongLong {
    get {
      var size: AnyObject?
      var error:  NSError?
      self.databaseUrl.getResourceValue(&size, forKey:NSURLFileSizeKey, error:&error)
      return size == nil ? 0 : (size as NSNumber).longLongValue;
    }
  }
  
  private lazy
  var databaseUrl: NSURL = {
    let directories = NSFileManager.defaultManager()!.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    let directory = directories[directories.endIndex-1] as NSURL
    return directory.URLByAppendingPathComponent(self.databaseName)
  }()

  private
  var persistentStoreCoordinator: NSPersistentStoreCoordinator {
    get {
      return clearablePersistentStoreCoordinator.getOrCreate()
    }
  }
  
  // Note, we need lazy on the clearables so we can access self in the initializer closures
  private lazy
  var clearableObjectContext: ClearableLazy<NSManagedObjectContext> = {
    return ClearableLazy<NSManagedObjectContext>() {
      let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
      context.persistentStoreCoordinator = self.persistentStoreCoordinator
      return context
    }
  }()
  
  private lazy
  var clearableObjectModel: ClearableLazy<NSManagedObjectModel> = {
    return ClearableLazy<NSManagedObjectModel>() {
      var bundle = NSBundle.mainBundle()
      if let name = self.bundleName? {
        let bundlePath = bundle.pathForResource(name, ofType:"bundle")
        bundle = NSBundle(path: bundlePath)
      }
      let modelUrl = NSURL.fileURLWithPath(bundle.pathForResource(self.modelName, ofType:"momd"))
        
      // TODO load specific version, e.g.
      // [bundle URLForResource:@"Blah2" withExtension:@"mom" subdirectory:@"Blah.momd"];
        
      var objectModel = NSManagedObjectModel(contentsOfURL: modelUrl)
        
      return objectModel;
    }
  }()
  
  private lazy
  var clearablePersistentStoreCoordinator: ClearableLazy<NSPersistentStoreCoordinator> = {
    return ClearableLazy<NSPersistentStoreCoordinator>() {
      var error: NSError?;
    
      let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel:self.objectModel)
    
      if nil == self.createDatabase(persistentStoreCoordinator, error: &error) {
        NSLog("Fatal error while creating persistent store: %@", error!);
        abort();
      }
      return persistentStoreCoordinator;
    }
  }()
  
  private
  func createDatabase(coordinator: NSPersistentStoreCoordinator, error: NSErrorPointer) -> NSPersistentStore! {
    let options = [NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: true]
    
    return coordinator.addPersistentStoreWithType(NSSQLiteStoreType,
      configuration: nil,
      URL: self.databaseUrl,
      options: options,
      error: error)
  }
}
