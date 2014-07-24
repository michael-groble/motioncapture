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

class MyThread: NSThread {
  let initializer: () -> Void
  init(initializer: () -> Void) {
    self.initializer = initializer
  }
  override func main() {
    initializer()
    NSThread.exit()
  }
}

class utilsTest: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testLazyGetOrCreate() {
    var counter = 0
    var expected: Int32 = 1
    let initializer: () -> Int32 = {
      counter += 1
      return expected
    }
    let lazy = ClearableLazy<Int32>(initializer)
    XCTAssertEqual(expected, lazy.getOrCreate())
    XCTAssertEqual(1, counter) // increments on first create
    lazy.getOrCreate()
    XCTAssertEqual(1, counter) // does not increment on subesequent get
    lazy.clear()
    XCTAssertEqual(1, counter) // ... or clear
    XCTAssertEqual(expected, lazy.getOrCreate())
    XCTAssertEqual(2, counter) // but does increment after cleared
  }

  func testCreateOnMainThread() {
    let expectation = expectationWithDescription("Created on main thread")
    let initializer: () -> Bool = {
      let onMainThread = NSThread.isMainThread()
      if onMainThread {
        expectation.fulfill()
      }
      return onMainThread
    }
    let lazy = ClearableLazy<Bool>(initializer)

    let thread = MyThread() {
      XCTAssertFalse(NSThread.isMainThread())
      lazy.getOrCreateOnMainThread()
    }
    thread.start()
    waitForExpectationsWithTimeout(1, handler: nil)
  }
}
