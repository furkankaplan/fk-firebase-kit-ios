//
//  DictionaryExtension.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 29.09.2020.
//

import Foundation

public extension Dictionary {
    
    public func convertTo<T2: Codable>(object class: T2.Type) -> T2 where T2: Initializable {
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            let decodedData = try decoder.decode(T2.self, from: jsonData)
            
            debugPrint(decodedData)
            
            return decodedData
        } catch let error {
            debugPrint(error)
        }
        
        return T2.init()
    }
    
}
