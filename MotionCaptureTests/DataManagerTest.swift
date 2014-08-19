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

import XCTest
import CoreData

class DataManagerTest: XCTestCase {

  var manager: DataManager!
  
  override func setUp() {
    super.setUp()
    let databaseName = "MotionTest.sqlite"
    let directories = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
    let directory = directories[directories.endIndex-1] as NSURL
    let url = directory.URLByAppendingPathComponent(databaseName)
    NSFileManager.defaultManager().removeItemAtPath(url.path, error:nil)
    manager = DataManager(bundleName: nil, modelName: "imu", databaseName: databaseName)
  }
  
  
  override func tearDown() {
    if let m = manager {
      m.objectContext.rollback()
    }
    super.tearDown()
  }
  
  var measurementEntity: NSEntityDescription {
    get {
      return self.manager.objectModel.entitiesByName["Measurement"] as NSEntityDescription
    }
  }
  
  func measurement(timestamp: Float64) -> NSManagedObject {
    let measurement = NSManagedObject(entity: self.measurementEntity, insertIntoManagedObjectContext:self.manager.objectContext)
    measurement.setValue(timestamp, forKey: "timestamp")
    measurement.setValue(0, forKey: "type")
    return measurement
  }
  
  var count: Int {
    get {
      let request = NSFetchRequest()
      request.entity = measurementEntity
      request.includesSubentities = false
      request.includesPendingChanges = false
      return manager.objectContext.countForFetchRequest(request, error: nil)
    }
  }

  func testTruncate() {
    measurement(1)
    XCTAssertEqual(0, count)
    XCTAssertTrue(manager.objectContext.save(nil))
    XCTAssertEqual(1, count)
    manager.truncateDatabase()
    XCTAssertEqual(0, count)
    measurement(1)
    XCTAssertTrue(manager.objectContext.save(nil))
    XCTAssertEqual(1, count)
  }
}
