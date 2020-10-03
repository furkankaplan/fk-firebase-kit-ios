//
//  FKAuthenticationManager.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 29.09.2020.
//

import Foundation
import Firebase

class FKAuthenticationManager {
    
    /// Singleton instance variable to access parameter and methods.
    public static let shared = FKAuthenticationManager()
    
    /// Permenant key for the data stored in UserDefaults.
    private let AUTH_VERIFICATION_ID = "authVerificationID"
    
    /// languageCode is default nil. Must be set before verifying phoneNumber.
    /// Example languageCode = "uk"
    var languageCode: String?
    
    /// phoneCode is the spesfic prefix for each country.
    /// phoneCode string must be started with plus(+) sign.
    /// Example phoneCode = "+44"
    var phoneCode: String?
    
    /// Default value of verificationID is nil. It's fetched and saved after successfull response of phone number verification.
    /// It's deleted just after successfull response of otp verification.
    var verificationID: String?
    
    func verify(phoneNumber: String?, onCompletion: @escaping(() -> Void), onError: @escaping((_ message: String) -> Void)) {
        guard let phone = phoneNumber else { return }
        guard let languageCode = languageCode else { return }
        guard let phoneCode = phoneCode else { return }
        
        Auth.auth().languageCode = languageCode
        
        PhoneAuthProvider.provider().verifyPhoneNumber("\(phoneCode)\(phone)", uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                
                onError(error.localizedDescription)
            }
            
            UserDefaults.standard.set(verificationID, forKey: self.AUTH_VERIFICATION_ID)
            
            self.verificationID = UserDefaults.standard.string(forKey: self.AUTH_VERIFICATION_ID)
            
            onCompletion()
        }
    }
    
    func verify(otp verificationID: String?, verificationCode: String?, onCompletion: @escaping(() -> Void), onError: @escaping((_ message: String) -> Void)) {
        guard let verificationID = verificationID else { return }
        guard let verificationCode = verificationCode else { return }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                debugPrint(error.localizedDescription)
                
                onError(error.localizedDescription)
                return
            }
            
            FKCurrentUser.user = authResult?.user
            
            self.removeVerificationID()
        
            onCompletion() // OTP verified.
        }
    }
    
    private func removeVerificationID() {
        self.verificationID = nil
    }
    
}
