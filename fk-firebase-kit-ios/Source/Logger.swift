//
//  File.swift
//  fk-firebase-kit-ios
//
//  Created by Furkan Kaplan on 6.12.2020.
//

import Foundation

struct Logger {
    
    static func requestLog(requestDictionary: NSDictionary) {
        #if DEBUG
        print("")
        print("Request ~> \(requestDictionary)")
        #endif
    }
    
    static func errorLog(message: String) {
        #if DEBUG
        print("")
        print("Error ~> \(message)")
        endLogMessage()
        #endif
    }
    
    static func succeed() {
        #if DEBUG
        print("")
        print("Succeed.")
        self.endLogMessage()
        #endif
    }
    
    static func infoLog(message: String) {
        #if DEBUG
        print("")
        print("Info ~> \(message)")
        #endif
    }
    
    static func responseLog(message: Any) {
        #if DEBUG
        print("")
        print("Response ~> \(message)")
        endLogMessage()
        #endif
    }
    
    static func endpointLog(endpoint: String) {
        #if DEBUG
        startLogMessage()
        print("Endpoint ~> \(endpoint)")
        #endif
    }
    
    private static func startLogMessage() {
        print("")
        print("################ FKFirebaseKit Request ################")
        print("")
    }
    
    private static func endLogMessage() {
        print("")
        print("################ FKFirebaseKit Request ################")
        print("")
    }
    
}
