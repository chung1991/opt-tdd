//
//  OTP_TDDTests.swift
//  OTP_TDDTests
//
//  Created by Chung Nguyen on 6/28/22.
//

import XCTest
@testable import OTP_TDD

class MockViewModelDelegate: ViewModelDelegate {
    var logs: [String] = []
    func didGenerateNewOTP() {
        logs.append("didGenerateNewOTP")
    }
    
    func didInputValidOTP() {
        logs.append("didInputValidOTP")
    }
    
    func didInputInvalidOTP() {
        logs.append("didInputInvalidOTP")
    }
}

class MockOTPService: OTPServiceImpl {
    var _validOTP = false
    var _otp = OTP.none
    var _verifyOTP = false
    var overrideFuncs: Set<String> = []
    
    override func validOTP(_ otp: OTP) -> Bool {
        if overrideFuncs.contains("validOTP") {
            return _validOTP
        } else {
            return super.validOTP(otp)
        }
    }
    
    override func generateOTP() -> OTP {
        if overrideFuncs.contains("generateOTP") {
            return _otp
        } else {
            return super.generateOTP()
        }
    }
    
    override func verifyOTP(_ otp1: OTP, _ otp2: OTP) -> Bool {
        if overrideFuncs.contains("verifyOTP") {
            return _verifyOTP
        } else {
            return super.verifyOTP(otp1, otp2)
        }
    }

}

class ViewModelImplTests: XCTestCase {
    var viewModel = ViewModelImpl()
    let mockService = MockOTPService()
    let mockDelegate = MockViewModelDelegate()
    override func setUpWithError() throws {
        viewModel.otpService = mockService
        viewModel.delegate = mockDelegate
    }
    
    func testGenerateOTP() {
        // TC1: valid otp
        let input11 = [1,2,3,4,5,6]
        // TC2: invalid otp, out of bound
        let input21 = [1,2,3,4,5,10]
        // TC3: invalid otp, length is not 6
        let input31 = [1,2,3,4,5]
        
        let goodInputs = [input11]
        let badInputs = [input21, input31]
        
        mockService.overrideFuncs.insert("generateOTP")
        
        for input in goodInputs {
            let otp = OTP(digits: input)
            mockService._otp = otp
            viewModel.generateOTP()
            XCTAssertEqual(viewModel.otp.digits, input)
            XCTAssertEqual(mockDelegate.logs.count, 1)
            XCTAssertEqual(mockDelegate.logs[0], "didGenerateNewOTP")
            
            viewModel.otp = OTP.none
            mockDelegate.logs = []
        }
        
        for input in badInputs {
            let otp = OTP(digits: input)
            mockService._otp = otp
            viewModel.generateOTP()
            XCTAssertTrue(viewModel.otp.digits == OTP.none.digits)
            XCTAssertEqual(mockDelegate.logs.count, 0)
            
            viewModel.otp = OTP.none
            mockDelegate.logs = []
        }
    }
    
    func testSubmitOTP() {
        // TC1: submit matched otp
        let input11 = [[1,2,3,4,5,6], [1,2,3,4,5,6]]
        // TC2: submit not mactched otp
        let input21 = [[1,2,3,4,5,6], [1,2,3,4,4,6]]
        // TC3: otp never generated
        let input31 = [OTP.none.digits, [1,2,3,4,4,6]]
        
        let normalInputs = [input11, input21]
        let normalExpects = ["didInputValidOTP", "didInputInvalidOTP"]
        for (i, input) in normalInputs.enumerated() {
            let current = OTP(digits: input[0])
            let sending = OTP(digits: input[1])
            viewModel.otp = current
            viewModel.submitOTP(sending)
            XCTAssertEqual(mockDelegate.logs.count, 1)
            XCTAssertEqual(mockDelegate.logs[0], normalExpects[i])
            mockDelegate.logs = []
        }
        
        let abnormalInput = [input31]
        for input in abnormalInput {
            let current = OTP(digits: input[0])
            let sending = OTP(digits: input[1])
            viewModel.otp = current
            viewModel.submitOTP(sending)
            XCTAssertEqual(mockDelegate.logs.count, 0)
            mockDelegate.logs = []
        }
        
    }
}

class OTPServiceImplTests: XCTestCase {

    let service = OTPServiceImpl()
    override func setUpWithError() throws {
    }

    override func tearDownWithError() throws {
    }

    func testIsValidOTP() {
        // TC 1: OTP is valid, 6 character
        let input11 = OTP(digits: [1,2,3,4,5,6])
        // TC 2: OTP is invalid, 6 character, but one out of bound 0-9
        let input21 = OTP(digits: [-1,1,2,3,4,5])
        let input22 = OTP(digits: [1,1,2,3,10,5])
        // TC 3: OTP is invalid, out of bound 6 character
        let input31 = OTP(digits: [])
        let input32 = OTP(digits: [1,2,3,4,5,6,7])
        let input33 = OTP(digits: [1,2,3,4,5])
        
        let inputs = [input11, input21, input22, input31, input32, input33]
        let expects = [true, false, false, false, false, false]
        
        for (i, input) in inputs.enumerated() {
            let actual = service.validOTP(input)
            let expect = expects[i]
            XCTAssertEqual(actual, expect)
        }
    }
    
    func testGenerateOTP() {
        for _ in 0..<10 {
            let actual = service.generateOTP()
            XCTAssertEqual(actual.digits.count, 6)
            
            for num in actual.digits {
                XCTAssertTrue(num >= 0 || num <= 9)
            }
        }
    }
    
    func testVerifyOTP() {
        // TC1: 2 otp matches
        let input11 = [OTP(digits: [1,2,3,4,5,6]),
                       OTP(digits: [1,2,3,4,5,6])]
        // TC2: 2 otp not natches, length diff
        let input21 = [OTP(digits: [1,2,3,4,5,6,7]),
                       OTP(digits: [1,2,3,4,5,6])]
        // TC3: 2 otp not natches, same length but diff number
        let input31 = [OTP(digits: [1,2,3,4,4,6]),
                       OTP(digits: [1,2,3,4,5,6])]
        // TC3: 2 otp not natches, same length but contains special number
        let input41 = [OTP(digits: [1,2,3,4,10,6]),
                       OTP(digits: [1,2,3,4,10,6])]
        
        
        let inputs = [input11, input21, input31, input41]
        let expects = [true, false, false, false]
        
        for (i, input) in inputs.enumerated() {
            let actual = service.verifyOTP(input[0], input[1])
            let expect = expects[i]
            XCTAssertEqual(actual, expect)
        }
    }

}
