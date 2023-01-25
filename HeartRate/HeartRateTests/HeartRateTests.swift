//
//  HeartRateTests.swift
//  HeartRateTests
//
//  Created by Mobile Programming on 25/01/23.
//

import XCTest
@testable import HeartRate
@testable import CoreBluetooth

final class HeartRateTests: XCTestCase {

    let vc = ViewController()

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        testDeviceBluetoothStatus()
        testConnectionandServices()
        
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDeviceBluetoothStatus() {
        let status = vc.centralManager.state
        print("Test: Device Bluetooth status is \(XCTAssertEqual(status, .poweredOn))")
    }

    func testConnectionandServices() {
        let devices = vc.heartRatePeripheral.services
        if devices != nil {
            print("Test Services Success: \(XCTAssertNil(devices))")
            print("Test Device Connection Successful")
        }
    }
    
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
