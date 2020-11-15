//
//  FKChatKitManager.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 29.09.2020.
//

import Foundation
import FirebaseDatabase

public class FKFirebaseKitManager {
    
    /// FKChatKitManager singleton object to access instance variable and methods.
    public static let shared: FKFirebaseKitManager = FKFirebaseKitManager()
    
    /// Firebase database shared instance to use it interaction layers of all modules.
    private let database: DatabaseReference = Database.database().reference()
    
    private init() {/* Instance of class must not be created more than one. */}
    
    // MARK: - CRUD Requests
    
    public func request(set data: Codable, endpoint: String..., childByAutoId: Bool = false, onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        var innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
        
        if childByAutoId {
            innerDatabase = innerDatabase.childByAutoId()
        }
        
        innerDatabase.setValue(data.toDictionary()) { (error: Error?, reference: DatabaseReference?) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            
            onSuccess()
        }
    }
    
    public func request<T: Codable>(get type: RequestEventEnum = .once, endpoint: String..., onSuccess: @escaping(([T]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
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
    
    public func request<T: Codable>(update object: T, paths: [String], onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
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
    
    public func request(delete endpoint: String..., onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        
        innerDatabase.removeValue { (error: Error?, reference: DatabaseReference) in
            if let error = error {
                onError(error.localizedDescription)
                return
            }
            
            onSuccess()
        }
    }
    
    // MARK: - Listen
    
    public func listenChild<T: Codable>(forEvent type: ListenEventEnum, endpoint: String..., onSuccess: @escaping(([T]) -> Void), onError: @escaping((String) -> Void)) where T: Initializable {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        var eventType: DataEventType!
        
        switch type {
        case .added:
            eventType = .childAdded
        case .changed:
            eventType = .childChanged
        case .removed:
            eventType = .childRemoved
        case .moved:
            eventType = .childMoved
        }
        
        innerDatabase.observe(eventType) { (data) in
            self.handleResponse(with: data, onSuccess: onSuccess)
        }
    }
    
    // MARK: - Sort Requests
    
    public func order<T: Codable>(by type: OrderByTypeEnum,with key: String, endpoint: String..., onSuccess: @escaping(([T]) -> Void), onError: @escaping((String) -> Void)) where T: Initializable {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        
        innerDatabase.queryOrdered(byChild: key).observe(.value) { (data) in
            self.handleResponse(with: data, onSuccess: onSuccess)
        }
    }
    
    // MARK: - Observers
    
    public func remove(observer key: UInt) {
        self.database.removeObserver(withHandle: key)
    }
    
    public func logout() {
        self.database.removeAllObservers()
    }
    
    // MARK: - Helpers
    
    private func handleResponse<T: Codable>(with data: DataSnapshot, onSuccess: @escaping(([T]) -> Void)) where T: Initializable {
        var responseHandler: [T] = []
        
        for item in data.children.allObjects as! [DataSnapshot] {
            let response = item.value as! [String:Any]
            
            let result: T = response.convertTo(object: T.self)
            
            responseHandler.append(result)
        }
        
        debugPrint(responseHandler)
        
        onSuccess(responseHandler)
    }
    
    private func configureEndpoint(endpoint: [String]) -> DatabaseReference {
        var innerDatabase: DatabaseReference = self.database
        
        for path in endpoint {
            if !path.isEmpty { // path cannot be empty! If it is, app crashes.
                innerDatabase = innerDatabase.child(path)
            } else {
                debugPrint("Error @ \(#file) because of endpoint creation. Paths of the endpoint cannot be nil or empty!")
            }
        }
        
        return innerDatabase
    }
    
}
