//
//  FKChatKitManager.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 29.09.2020.
//

import Foundation
import Firebase

class FKFirebaseKitManager {
    
    /// FKChatKitManager singleton object to access instance variable and methods.
    public static let shared: FKFirebaseKitManager = FKFirebaseKitManager()
    
    /// Firebase database shared instance to use it interaction layers of all modules.
    private let database: DatabaseReference = Database.database().reference()
    
    func request(set data: Codable, endpoint: String..., onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        var innerDatabase: DatabaseReference = self.database
        
        for path in endpoint {
            innerDatabase = innerDatabase.child(path)
        }
        
        innerDatabase.setValue(data.toDictionary()) { (error: Error?, reference: DatabaseReference?) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            
            onSuccess()
        }
    }
    
}
