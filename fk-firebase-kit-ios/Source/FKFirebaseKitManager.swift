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
        
        #if DEBUG
        print("")
        print("Request ~> \(data.toDictionary())")
        #endif

        innerDatabase.setValue(data.toDictionary()) { (error: Error?, reference: DatabaseReference?) in
            if let error = error {
                onError(error.localizedDescription)
                #if DEBUG
                print("")
                print("Response with Error ~> \(error.localizedDescription)")
                self.endLogMessage()
                #endif
                return
            }
            
            #if DEBUG
            print("")
            print("Succeed.")
            self.endLogMessage()
            #endif
            
            onSuccess()
        }
    }
    
    @discardableResult
    public func request<T: Codable>(get type: RequestEventEnum = .once, endpoint: [String], onSuccess: @escaping(([T]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
        let innerDatabase: DatabaseReference = self.configureEndpoint(endpoint: endpoint)
                
        if type == RequestEventEnum.once {
            innerDatabase.observeSingleEvent(of: .value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
                #if DEBUG
                print("")
                print("Response with Error ~> \(error.localizedDescription)")
                self.endLogMessage()
                #endif
            }
        } else if type == RequestEventEnum.listen {
            let observer = innerDatabase.observe(.value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
                #if DEBUG
                print("")
                print("Response with Error ~> \(error.localizedDescription)")
                self.endLogMessage()
                #endif
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
                    #if DEBUG
                    print("")
                    print("Response with Error ~> \(error.localizedDescription)")
                    self.endLogMessage()
                    #endif
                    return
                }
                
                #if DEBUG
                print("")
                print("Succeed.")
                self.endLogMessage()
                #endif
                onSuccess()
            }
            
        }
    }
    
    public func request(delete endpoint: [String], onSuccess: @escaping(() -> Void), onError: @escaping((String) -> Void)) {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        
        innerDatabase.removeValue { (error: Error?, reference: DatabaseReference) in
            if let error = error {
                onError(error.localizedDescription)
                #if DEBUG
                print("")
                print("Response with Error ~> \(error.localizedDescription)")
                self.endLogMessage()
                #endif
                return
            }
            
            #if DEBUG
            print("")
            print("Succeed.")
            self.endLogMessage()
            #endif
            onSuccess()
        }
    }
    
    // MARK: - Listen
    
    public func listenChild<T: Codable>(forChild event: ListenEventEnum, endpoint: [String], onSuccess: @escaping(([T]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
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
    public func list<T: Codable>(orderKey: String? = nil, filterBy filteredType: FilterTypeEnum? = nil, type: RequestEventEnum = .once, endpoint: [String], onSuccess: @escaping(([T]) -> Void), onError: @escaping((String) -> Void)) -> UInt where T: Initializable {
        let innerDatabase = configureEndpoint(endpoint: endpoint)
        
        var query: DatabaseQuery?
        
        if let orderKey = orderKey {
            #if DEBUG
            print("")
            print("Query ordered with \(orderKey)")
            #endif
            query = innerDatabase.queryOrdered(byChild: orderKey)
        }
    
        if let filteredType = filteredType {
            switch filteredType {
            case .prefix(let value):
                if let _ = query {
                    query = query!.queryStarting(atValue: value).queryEnding(atValue: value + "\u{F8FF}")
                    #if DEBUG
                    print("")
                    print("Query filtered with prefix \(value)")
                    #endif
                }
                break
            case .starting(let value):
                if let _ = query {
                    query = query!.queryStarting(atValue: value)
                    #if DEBUG
                    print("")
                    print("Query filtered with starting at value of \(value)")
                    #endif
                }
                break
            case .ending(let value):
                if let _ = query {
                    query = query!.queryEnding(atValue: value )
                    #if DEBUG
                    print("")
                    print("Query filtered with match case of \(value)")
                    #endif
                }
                break
            case .equal(let value):
                if let _ = query {
                    query = query!.queryEqual(toValue: value)
                  
                }
                break
            case .startingAndEnding(let startingValue, let endingValue):
                if let _ = query {
                    query = query!.queryStarting(atValue: startingValue).queryEnding(atValue: endingValue)
                    #if DEBUG
                    print("")
                    print("Query filtered with starting and ending at values for \(startingValue),\( endingValue), relatively")
                    #endif
                }
                break
            }
        }
        
        guard query != nil else { return UInt() }
        
        if type == RequestEventEnum.listen {
            let observer = query!.observe(.value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
                #if DEBUG
                print("")
                print("Response with Error ~> \(error.localizedDescription)")
                self.endLogMessage()
                #endif
            }
            
            return observer
        } else if type == RequestEventEnum.once {
            query!.observeSingleEvent(of: .value) { (data) in
                self.handleResponse(with: data, onSuccess: onSuccess)
            } withCancel: { (error: Error) in
                onError(error.localizedDescription)
                #if DEBUG
                print("")
                print("Response with Error ~> \(error.localizedDescription)")
                self.endLogMessage()
                #endif
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
    
    private func handleResponse<T: Codable>(with data: DataSnapshot, onSuccess: @escaping(([T]) -> Void)) where T: Initializable {
        var responseHandler: [T] = []
        
        for item in data.children.allObjects as! [DataSnapshot] {
            let response = item.value as! [String:Any]
            
            let result: T = response.convertTo(object: T.self)
            
            responseHandler.append(result)
        }
        
        #if DEBUG
        print("")
        print("Response ~> \(responseHandler)")
        endLogMessage()
        #endif
        
        onSuccess(responseHandler)
    }
    
    private func configureEndpoint(endpoint: [String]) -> DatabaseReference {
        var innerDatabase: DatabaseReference = self.database
        
        #if DEBUG
        startLogMessage()
        print("Endpoint ~> \(endpoint.joined(separator: "/"))")
        #endif
        
        for path in endpoint {
            if !path.isEmpty { // path cannot be empty! If it is, app crashes.
                innerDatabase = innerDatabase.child(path)
            } else {
                debugPrint("Error @ \(#file) because of endpoint creation. Paths of the endpoint cannot be nil or empty!")
                endLogMessage()
            }
        }
        
        return innerDatabase
    }
    
    private func startLogMessage() {
        print("")
        print("################ FKFirebaseKit Request ################")
        print("")
    }
    
    private func endLogMessage() {
        print("")
        print("################ FKFirebaseKit Request ################")
        print("")
    }
    
}
