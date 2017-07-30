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


  /* 
 *  Child containers should not have access to each others registries
 */
  func testChildContainersAreIsolatedContainer() {

    let rootContainer = DependencyContainer()

    var countR = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      countR = countR + 1
      return ServiceA()
    }

    XCTAssertNotNil(try? rootContainer.resolve() as ServiceA)

    let userA = DependencyContainer(parent: rootContainer)
    var countA = 0
    userA.register(.singleton) { (serviceA: ServiceA) -> Password in
      countA = countA + 1
      return Password(text: "1234", service:serviceA)
    }


    let userB = DependencyContainer(parent: rootContainer)
    var countB = 0
    userB.register(.singleton) { (serviceA: ServiceA) -> Password in
      countB = countB + 1
      return Password(text: "ABCD", service:serviceA)
    }

    XCTAssert((try! userA.resolve() as Password).text == "1234")
    XCTAssert(countR == 1)
    XCTAssert(countA == 1)


    XCTAssert((try! userB.resolve() as Password).text == "ABCD")
    XCTAssert(countR == 1)
    XCTAssert(countB == 1)

    //Root doesn't have access to its children.
    XCTAssertNil(try? rootContainer.resolve() as Password)
  }


  /*
 * Child containers should not have access to each others registries
 *  nor should the parent have access to the childs registry
 */
  func testChildContainersDontFailOver() {

    let rootContainer = DependencyContainer()

    var count = 0
    rootContainer.register(.singleton) { () -> ServiceA in
      count = count + 1
      return ServiceA()
    }

    //Logged in user.
    let loggedIn = DependencyContainer(parent: rootContainer)
    loggedIn.register(.singleton) { Password(text: "1234", service:$0) }
    let passwordLoggedIn : Password? = try? loggedIn.resolve() as Password
    XCTAssert(passwordLoggedIn?.text == "1234")
    XCTAssert(count == 1)


    //UnLogged in user doesn't have access to Logged in users data.
    let unloggedIn = DependencyContainer(parent: rootContainer)
    let passwordUnloggedIn = try? unloggedIn.resolve() as Password
    XCTAssertNil(passwordUnloggedIn);
    XCTAssert(count == 1)

    //Root container doesn't have access to child containers data.
    XCTAssertNil(try? rootContainer.resolve() as Password)
  }


  class RootTransientDep { }
  class ChildTransientDep {}

  class ChildAggregate {
    let rootDep : RootTransientDep
    var anotherRootDep : RootTransientDep?

    let childDep : ChildTransientDep
    var anotherChildDep : ChildTransientDep?


    init(rootDep : RootTransientDep, childDep : ChildTransientDep){
      self.rootDep = rootDep
      self.childDep = childDep
    }
  }

 /*
 * Instances of that are resolved from parents are reused similar 
 * to how they're reused within containers and collaborators.
 */
  func testParentContainersReuseInstances() {
    let rootContainer = DependencyContainer()

    var countR = 0
    rootContainer.register { () -> RootTransientDep in
      countR = countR + 1
      return RootTransientDep()
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
