//
//  EncodableExtension.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 29.09.2020.
//

import Foundation

public extension Encodable {
    
    /// Converts the encodable object to dictionary type.
    public func toDictionary() -> NSDictionary {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        jsonEncoder.dateEncodingStrategy = .iso8601
        let data = try! jsonEncoder.encode(self)
        
        return try! JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
    }
    
}
