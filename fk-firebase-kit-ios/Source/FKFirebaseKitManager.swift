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
    
    private init() {/* Instance of the class must not be created more than one. */}
    
    // MARK: - CRUD Requests
    
    public func request(set data: Codable, endpoint: [String], childByAutoId: Bool = false, onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        var innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
                
        if childByAutoId {
            innerDatabase = innerDatabase.childByAutoId()
        }
        
        Logger.requestLog(requestDictionary: data.toDictionary())
        
        innerDatabase.setValue(data.toDictionary()) { (error: Error?, reference: DatabaseReference?) in
            if let error = error {
                Logger.errorLog(message: error.localizedDescription)
                onError(error.localizedDescription)
                
                return
            }
            
            Logger.succeed()
            
            onSuccess()
        }
    }
    
    @discardableResult
    public func request<T: Codable>(get type: RequestEventEnum = .once, endpoint: [String], onSuccess: @escaping(([ResponseModel<T>]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
        let innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
                
        if type == RequestEventEnum.once {
            innerDatabase.observeSingleEvent(of: .value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                Logger.errorLog(message: error.localizedDescription)
                onError(error.localizedDescription)
            }
        } else if type == RequestEventEnum.listen {
            let observer = innerDatabase.observe(.value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                Logger.errorLog(message: error.localizedDescription)
                onError(error.localizedDescription)
            }
            
            return observer
        }
        
        return UInt()
    }
    
    public func request<T: Codable>(update object: T, endpoint: [String], onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        let innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
        
        if let requestDictionary = object.toDictionary() as? [AnyHashable : Any] {
            innerDatabase.updateChildValues(requestDictionary) { (error: Error?, reference: DatabaseReference) in
                if let error = error {
                    Logger.errorLog(message: error.localizedDescription)
                    onError(error.localizedDescription)
                    return
                }
                
                Logger.succeed()
                
                onSuccess()
            }
        }

    }
    
    public func request(delete endpoint: [String], onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        
        innerDatabase.removeValue { (error: Error?, reference: DatabaseReference) in
            if let error = error {
                Logger.errorLog(message: error.localizedDescription)
                onError(error.localizedDescription)
                return
            }

            Logger.succeed()

            onSuccess()
        }
    }
    
    // MARK: - Listen
    
    public func listenChild<T: Codable>(forChild event: ListenEventEnum, endpoint: [String], onSuccess: @escaping(([ResponseModel<T>]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        var eventType: DataEventType!
        
        switch event {
        case .added:
            eventType = .childAdded
        case .changed:
            eventType = .childChanged
        case .removed:
            eventType = .childRemoved
        case .moved:
            eventType = .childMoved
        }
        
        let observer = innerDatabase.observe(eventType) { (data) in
            self.handleResponse(with: data, onSuccess: onSuccess)
        }
        
        return observer
    }
    
    // MARK: - Sort & Filter Requests
    
    public enum FilterTypeEnum {
        case prefix(String)
        case starting(Any)
        case ending(Any)
        case equal(Any)
        case startingAndEnding(Any, Any)
    }
    
    @discardableResult
    public func list<T: Codable>(key: String?, filterBy filteredType: FilterTypeEnum?, type: RequestEventEnum = .once, endpoint: [String], onSuccess: @escaping(([ResponseModel<T>]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        
        guard key != nil && !(key ?? "").isEmpty && filteredType != nil else {
            Logger.errorLog(message: "Query parameters both key and filter type must not be empty!")
            onError("Query parameters both key and filter type must not be empty!")
            return UInt()
        }
        
        var query: DatabaseQuery?
        
        if let key = key {
            Logger.infoLog(message: "Query ordered with \(key)")
            query = innerDatabase.queryOrdered(byChild: key)
        }
    
        if let filteredType = filteredType {
            switch filteredType {
            case .prefix(let value):
                if let _ = query {
                    query = query!.queryStarting(atValue: value).queryEnding(atValue: value + "\u{F8FF}")
                    
                    Logger.infoLog(message: "Query filtered with prefix \(value)")
                }
                
               
                break
            case .starting(let value):
                if let _ = query {
                    query = query!.queryStarting(atValue: value)
          
                    Logger.infoLog(message: "Query filtered with starting at value at \(value)")
                }
                
                break
            case .ending(let value):
                if let _ = query {
                    query = query!.queryEnding(atValue: value )
                    
                    Logger.infoLog(message: "Query filtered with ending at value at \(value)")
                }
                                
                break
            case .equal(let value):
                if let _ = query {
                    query = query!.queryEqual(toValue: value)
                    
                    Logger.infoLog(message: "Query filtered with match case of \(value)")
                }
                
                break
            case .startingAndEnding(let startingValue, let endingValue):
                if let _ = query {
                    query = query!.queryStarting(atValue: startingValue).queryEnding(atValue: endingValue)
                    
                    Logger.infoLog(message: "Query filtered with starting and ending at values for \(startingValue),\( endingValue), relatively")
                }
                
                break
            }
        }
        
        guard query != nil else { return UInt() }
        
        if type == RequestEventEnum.listen {
            let observer = query!.observe(.value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                Logger.errorLog(message: error.localizedDescription)
                onError(error.localizedDescription)
            }
            
            return observer
        } else if type == RequestEventEnum.once {
            query!.observeSingleEvent(of: .value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                Logger.errorLog(message: error.localizedDescription)
                onError(error.localizedDescription)
            }
        }
        
        return UInt()
    }
    
    // MARK: - Observers
    
    public func remove(observer key: UInt) {
        self.database.removeObserver(withHandle: key)
    }
    
    public func logout() {
        self.database.removeAllObservers()
    }
    
    // MARK: - Helpers
    
    private func handleResponse<T: Codable>(with data: DataSnapshot, onSuccess: @escaping(([ResponseModel<T>]) -> Void)) where T: Initializable {
        var responseHandler: [ResponseModel<T>] = []
        
        for item in data.children.allObjects as! [DataSnapshot] {
            let response = item.value as! [String:Any]
            let result: T = response.convertTo(object: T.self)
            
            responseHandler.append(ResponseModel(key: item.key, result: result))
        }
        
        Logger.responseLog(message: responseHandler)
        
        onSuccess(responseHandler)
    }
    
    private func configureEndpoint(endpoint: [String]) -> DatabaseReference {
        var innerDatabase: DatabaseReference = self.database
        
        Logger.endpointLog(endpoint: endpoint.joined(separator: "/"))
        
        for path in endpoint {
            if !path.isEmpty { // path cannot be empty! If it is, app crashes.
                innerDatabase = innerDatabase.child(path)
            } else {
                Logger.infoLog(message: "Error @ \(#file) because of nil endpoint parameter. Skipped to prevent crashing.")
            }
        }
        
        return innerDatabase
    }
    
}
