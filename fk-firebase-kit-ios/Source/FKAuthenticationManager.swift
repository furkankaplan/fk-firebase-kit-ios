//
//  FKAuthenticationManager.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 29.09.2020.
//

import Foundation
import FirebaseAuth

public class FKAuthenticationManager {
    
    /// Singleton instance variable to access parameter and methods.
    public static let shared = FKAuthenticationManager()
    
    /// Permenant key for the data stored in UserDefaults.
    private let AUTH_VERIFICATION_ID = "authVerificationID"
    
    /// languageCode is default nil. Must be set before verifying phoneNumber.
    /// Example languageCode = "uk"
    public var languageCode: String?
    
    /// phoneCode is the spesfic prefix for each country.
    /// phoneCode string must be started with plus(+) sign.
    /// Example phoneCode = "+44"
    public var phoneCode: String?
    
    /// Default value of verificationID is nil. It's fetched and saved after successfull response of phone number verification.
    /// It's deleted just after successfull response of otp verification.
    public var verificationID: String?
    
    private init() {/* Instance of the class must not be created more than one. */}
    
    public func verify(phoneNumber: String?, onCompletion: @escaping(() -> Void), onError: @escaping((_ message: String) -> Void)) {
        guard let phone = phoneNumber else { return }
        guard let languageCode = languageCode else { return }
        guard let phoneCode = phoneCode else { return }
        
        Auth.auth().languageCode = languageCode
        
        PhoneAuthProvider.provider().verifyPhoneNumber("\(phoneCode)\(phone)", uiDelegate: nil) { (verificationID, error) in
            if let error = error {
                Logger.errorLog(message: error.localizedDescription)
                
                onError(error.localizedDescription)
            }
            
            UserDefaults.standard.set(verificationID, forKey: self.AUTH_VERIFICATION_ID)
            
            self.verificationID = UserDefaults.standard.string(forKey: self.AUTH_VERIFICATION_ID)
            
            onCompletion()
        }
    }
    
    public func verify(otp verificationCode: String?, onCompletion: @escaping(() -> Void), onError: @escaping((_ message: String) -> Void)) {
        guard let verificationID = verificationID else {
            Logger.errorLog(message: "\(#function) in \(#file) handles verificationID as nil!")
            return
        }
        
        guard let verificationCode = verificationCode else { return }
        
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { (authResult, error) in
            if let error = error {
                Logger.errorLog(message: error.localizedDescription)
                
                onError(error.localizedDescription)
                return
            }
            
            FKCurrentUser.user = authResult?.user
            
            self.removeVerificationID()
        
            onCompletion() // OTP verified.
        }
    }
    
    public var isLoggedIn: Bool {
        get {
            guard let _ = Auth.auth().currentUser else { return false }
            
            return true
        }
    }
    
    public var currentUser: User? {
        get {
            guard let user = Auth.auth().currentUser else { return nil }
            
            return user
        }
    }
    
    public func logout() {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            Logger.errorLog(message: signOutError.localizedDescription)
        }
    }
    
    private func removeVerificationID() {
        self.verificationID = nil
    }
    
}
