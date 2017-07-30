//
//  CollaborateTests.swift
//  Dip
//
//  Created by John Twigg on 7/28/17.
//  Copyright © 2017 AliSoftware. All rights reserved.
//

import XCTest
@testable import Dip


class CollaborateTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    



  func testIsolationContainer() {

    let rootContainer = DependencyContainer()

    var count = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      count = count + 1
      return ServiceA()
    }

    let loggedIn = DependencyContainer()
    loggedIn.register(.singleton) { Password(text: "1234", service:$0) }

    let unloggedIn = DependencyContainer()
    unloggedIn.register(.singleton) { Password(text: "-none-", service:$0) }

    // NOTE: Isolated containers
    loggedIn.collaborate(with: rootContainer) //Isolated containers
    unloggedIn.collaborate(with: rootContainer)//Isolated Container

    let passwordA = try! unloggedIn.resolve() as Password

    XCTAssert(passwordA.text == "-none-") //<< FAILS
    XCTAssert(count == 1) ////<< Works

    let passwordB = try! loggedIn.resolve() as Password
    XCTAssert(passwordB.text == "1234")  //<<<Works
    XCTAssert(count == 1)
  }


  class ServiceA {}

  class Password {
    let text: String
    let service : ServiceA

    init(text:String, service: ServiceA) {
      self.text = text
      self.service = service
    }
  }


  func testIsolationContainer2() {

    let rootContainer = DependencyContainer()

    var count = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      count = count + 1
      return ServiceA()
    }

    let loggedIn = DependencyContainer()

    let unloggedIn = DependencyContainer()
    unloggedIn.register() { Password(text: "-none-", service:$0) }

    // NOTE: Isolated containers
    loggedIn.collaborate(with: rootContainer) //Isolated containers
    unloggedIn.collaborate(with: rootContainer)//Isolated Container

    let passwordA = try! unloggedIn.resolve() as Password

    XCTAssert(passwordA.text == "-none-")
    XCTAssert(count == 1) ////<< Works

    let passwordB : Password? = try? loggedIn.resolve() as Password

    XCTAssertNil(passwordB) //<<<< FAILS. Should be nil,  but its "-none-"
    XCTAssert(count == 1)
  }

}
