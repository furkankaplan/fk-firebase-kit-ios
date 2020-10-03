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
    
    // MARK: - Requests
    
    // TODO Add auto-generation key support by childByAutoId with optional parameter
    // https://firebase.google.com/docs/database/ios/lists-of-data#reading_and_writing_lists
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
    
    func request<T: Codable>(get object: T.Type, type: RequestEventEnum = .once, endpoint: String..., onSuccess: @escaping((T) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
        let innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
                
        if type == RequestEventEnum.once {
            innerDatabase.observeSingleEvent(of: .value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
            }
        } else if type == RequestEventEnum.listen {
            let observer = innerDatabase.observe(.value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
            }
            
            return observer
        }
        
        return UInt()
    }
    
    func request<T: Codable>(update object: T, paths: [String], onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        var requestDictionary: [String : Any] = [:]
        
        for item in paths {
            requestDictionary[item] = object.toDictionary()
        }
        
        if !requestDictionary.isEmpty {
            self.database.updateChildValues(requestDictionary) { (error: Error?, reference: DatabaseReference) in
                if let error = error {
                    onError(error.localizedDescription)
                    return
                }
                
                onSuccess()
            }
        }
    }
    
    func request(delete endpoint: String..., onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        innerDatabase.removeValue { (error: Error?, reference: DatabaseReference) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            
            onSuccess()
        }
    }
    
    // MARK: - Observers
    
    func remove(observer key: UInt) {
        self.database.removeObserver(withHandle: key)
    }
    
    func logout() {
        self.database.removeAllObservers()
    }
    
    // MARK: - Helpers
    
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
