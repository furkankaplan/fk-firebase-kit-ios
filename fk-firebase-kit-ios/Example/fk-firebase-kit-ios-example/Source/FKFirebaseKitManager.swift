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
        let innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
        
        innerDatabase.setValue(data.toDictionary()) { (error: Error?, reference: DatabaseReference?) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            
            onSuccess()
        }
    }
    
    func request<T: Codable>(get object: T.Type, type: RequestEventEnum = .once, endpoint: String..., onSuccess: @escaping((T) -> Void), onError: @escaping((String) -> Void)) where T: Initializable {
        let innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
                
        if type == RequestEventEnum.once {
            innerDatabase.observeSingleEvent(of: .value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
            }
        } else if type == RequestEventEnum.listen {
            innerDatabase.observe(.value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
            }
        }
    }
    
    
    // MARK: - Helper
    
    private func handleResponse<T: Codable>(with data: DataSnapshot, onSuccess: @escaping((T) -> Void)) where T: Initializable {
        for item in data.children.allObjects as! [DataSnapshot] {
            let response = item.value as! [String:Any]
            
            let result: T = response.convertTo(object: T.self)

            onSuccess(result)
        }
    }
    
    private func configureEndpoint(endpoint: [String]) -> DatabaseReference {
        var innerDatabase: DatabaseReference = self.database
        
        for path in endpoint {
            if !path.isEmpty { // path cannot be empty! If it is, app crashes.
                innerDatabase = innerDatabase.child(path)
            } else {
                debugPrint("Error @ FKFirebaseKitManager because of endpoint creation.")
                debugPrint("Paths of the endpoint cannot be nil or empty!")
            }
        }
        
        return innerDatabase
    }
    
}
