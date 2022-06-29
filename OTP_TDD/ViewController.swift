//
//  ViewController.swift
//  OTP_TDD
//
//  Created by Chung EXI-Nguyen on 6/28/22.
//

// feature
//
// 1. generate otp
// 2. resend
// 3. input otp
//      6
// 4. verify otp
//      failed: red warning all input
//      success: move another screen

// modelling, relationship
struct OTP {
    static let none = OTP(digits: [])
    let digits: [Int]
}
// service
protocol OTPService {
    /// make sure digit <= 9 && >= 0
    func validOTP(_ otp: OTP) -> Bool
    
    /// generate + resend
    func generateOTP() -> OTP
    
    /// verify two OTP
    func verifyOTP(_ otp1: OTP, _ otp2: OTP) -> Bool
}

class OTPServiceImpl: OTPService {
    func validOTP(_ otp: OTP) -> Bool {
        if otp.digits.count != 6 {
            return false
        }
        
        if otp.digits.contains(where: { $0 > 9 || $0 < 0 }) {
            return false
        }
            
        return true
    }
    
    func generateOTP() -> OTP {
        var digits: [Int] = []
        for _ in 0..<6 {
            let randomDigit = Int.random(in: 0..<10)
            digits.append(randomDigit)
        }
        let otp = OTP(digits: digits)
        return otp
    }
    
    func verifyOTP(_ otp1: OTP, _ otp2: OTP) -> Bool {
        guard validOTP(otp1), validOTP(otp2) else {
            return false
        }
        
        let digits1 = otp1.digits
        let digits2 = otp2.digits
        
        for i in 0..<6 {
            if digits1[i] != digits2[i] {
                return false
            }
        }
        
        return true
    }
}
// testing
// implement service
// viewmodel, viewmodel

protocol ViewModelDelegate {
    func didGenerateNewOTP()
    func didInputValidOTP()
    func didInputInvalidOTP()
}

protocol ViewModel {
    var otp: OTP { get set }
    var otpService: OTPService { get set }
    var delegate: ViewModelDelegate? { get set }
    func generateOTP()
    func submitOTP(_ inputOTP: OTP)
}

class ViewModelImpl: ViewModel {
    var otp: OTP = OTP.none
    var otpService: OTPService = OTPServiceImpl()
    var delegate: ViewModelDelegate?
    
    func generateOTP() {
        let otp = otpService.generateOTP()
        guard otpService.validOTP(otp) else {
            return
        }
        self.otp = otp
        print ("OTP generated", otp.digits)
        delegate?.didGenerateNewOTP()
    }
    
    func submitOTP(_ inputOTP: OTP) {
        guard self.otp.digits != OTP.none.digits else {
            return
        }
        if otpService.verifyOTP(self.otp, inputOTP) {
            delegate?.didInputValidOTP()
        } else {
            delegate?.didInputInvalidOTP()
        }
    }
}

// testing
// implement view, viewmodel


import UIKit

class ViewController: UIViewController {

    let mainQueue = DispatchQueue.main
    var viewModel: ViewModel = ViewModelImpl()
    
    var stackView: UIStackView = {
        return UIStackView()
    }()
    
    lazy var inputs: [UITextField] = {
        var ans: [UITextField] = []
        for _ in 0..<6 {
            ans.append(UITextField())
        }
        return ans
    }()
    
    lazy var resendButton: UIButton = {
        return UIButton()
    }()
    
    lazy var submitButton: UIButton = {
        return UIButton()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupAutolayout()
        setupDelegates()
        viewModel.generateOTP()
    }

    func setupView() {
        stackView.distribution = .fillEqually
        stackView.axis = .horizontal
        view.addSubview(stackView)
        
        for textfield in self.inputs {
            stackView.addArrangedSubview(textfield)
        }
        resendButton.setTitle("Resend", for: .normal)
        resendButton.setTitleColor(.label, for: .normal)
        resendButton.addTarget(self,
                               action: #selector(didTapButton),
                               for: .touchUpInside)
        view.addSubview(resendButton)
        
        submitButton.setTitle("Submit", for: .normal)
        submitButton.setTitleColor(.label, for: .normal)
        submitButton.addTarget(self,
                               action: #selector(didTapButton),
                               for: .touchUpInside)
        view.addSubview(submitButton)
        
    }
    
    @objc func didTapButton(_ button: UIButton) {
        if button == resendButton {
            viewModel.generateOTP()
        } else {
            var inputDigits: [Int] = []
            for input in inputs {
                guard let text = input.text,
                        let digit = Int(text) else { return }
                inputDigits.append(digit)
            }
            viewModel.submitOTP(OTP(digits: inputDigits))
        }
    }
    
    func setupAutolayout() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        resendButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            resendButton.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 10),
            resendButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            submitButton.topAnchor.constraint(equalTo: resendButton.bottomAnchor, constant: 20),
            submitButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    func setupDelegates() {
        viewModel.delegate = self
    }
}

extension ViewController: ViewModelDelegate {
    func didInputValidOTP() {
        mainQueue.async {
            print ("next page")
        }
    }
    
    func didInputInvalidOTP() {
        mainQueue.async { [weak self] in
            guard let self = self else { return }
            for input in self.inputs {
                input.layer.borderColor = UIColor.red.cgColor
                input.layer.borderWidth = 1.0
            }
        }
    }
    
    func didGenerateNewOTP() {
        mainQueue.async { [weak self] in
            guard let self = self else { return }
            for input in self.inputs {
                input.layer.borderColor = UIColor.label.cgColor
                input.layer.borderWidth = 1.0
                input.text = nil
            }
        }
    }
}

