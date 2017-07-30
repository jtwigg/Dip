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


  class ServiceA {}

  class Password {
    let text: String
    let service : ServiceA

    init(text:String, service: ServiceA) {
      self.text = text
      self.service = service
    }
  }


  func testIsolationContainer() {

    let rootContainer = DependencyContainer()

    var count = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      count = count + 1
      return ServiceA()
    }

    XCTAssertNotNil(try? rootContainer.resolve() as ServiceA)

    let loggedIn = DependencyContainer(parent: rootContainer)
    var countL = 0
    loggedIn.register(.singleton) { (serviceA: ServiceA) -> Password in
      countL = countL + 1
      return Password(text: "1234", service:serviceA)
    }


    let unloggedIn = DependencyContainer(parent: rootContainer)
    var countU = 0
    unloggedIn.register(.singleton) { (serviceA: ServiceA) -> Password in
      countU = countU + 1
      return Password(text: "-none-", service:serviceA)
    }

    XCTAssert((try! loggedIn.resolve() as Password).text == "1234")  //<<<Works
    XCTAssert((try! loggedIn.resolve() as Password).text == "1234")  //<<<Works
    XCTAssert(count == 1)
    XCTAssert(countL == 1)


    XCTAssert((try! unloggedIn.resolve() as Password).text == "-none-") //<< FAILS
    XCTAssert((try! unloggedIn.resolve() as Password).text == "-none-") //<< FAILS
    XCTAssert(count == 1) ////<< Works
    XCTAssert(countU == 1) ////<< Works



  }


  func testIsolatedContainersDontFailOver() {

    let rootContainer = DependencyContainer()

    var count = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      count = count + 1
      return ServiceA()
    }


    XCTAssertNotNil(try? rootContainer.resolve() as ServiceA)


    let unloggedIn = DependencyContainer(parent: rootContainer)
    unloggedIn.register(.singleton) { Password(text: "-none-", service:$0) }

    XCTAssertNil(try? rootContainer.resolve() as Password)

    let passwordA = try? unloggedIn.resolve() as Password

    XCTAssert(passwordA?.text == "-none-")
    XCTAssert(count == 1) ////<< Works

    let loggedIn = DependencyContainer(parent: rootContainer)

    let passwordB : Password? = try? loggedIn.resolve() as Password

    //Should be nil
    XCTAssertNil(passwordB)
    XCTAssert(count == 1)
  }

  class RootTranientDep { }
  class ChildTransientDep {}


  class ChildAggregate {
    let rootDep : RootTranientDep
    var anotherRootDep : RootTranientDep?

    let childDep : ChildTransientDep
    var anotherChildDep : ChildTransientDep?


    init(rootDep : RootTranientDep, childDep : ChildTransientDep){
      self.rootDep = rootDep
      self.childDep = childDep
    }
  }

  func testParentContainersReuseInstances() {
    let rootContainer = DependencyContainer()

    var countR = 0
    rootContainer.register { () -> RootTranientDep in
      countR = countR + 1
      return RootTranientDep()
    }

    let childContainer = DependencyContainer(parent: rootContainer)
    childContainer.register {
      ChildAggregate(rootDep: $0, childDep: $1)
      }.resolvingProperties { (container, childAggregate) -> () in
        childAggregate.anotherRootDep = try? container.resolve()
        childAggregate.anotherChildDep = try? container.resolve()
    }

    var countC = 0
    childContainer.register { () -> ChildTransientDep in
      countC = countC + 1
      return ChildTransientDep()
    }

    XCTAssertNotNil(try? childContainer.resolve() as ChildAggregate)

    XCTAssert(countR == 1)
    XCTAssert(countC == 1)
  }
}
