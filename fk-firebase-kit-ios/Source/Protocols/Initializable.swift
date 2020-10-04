//
//  Initializable.swift
//  fk-firebase-kit-ios-example
//
//  Created by Furkan Kaplan on 30.09.2020.
//

import Foundation

/// DictionaryExtension has a method called convertTo(object:) converting dictionary to custom object inherited from Codable.
/// The method creates an instance which is kind of T2 generic type. Swift Lang doesn't know that if generic T2 paramater has
/// init method or not. Therefore I cannot use T2.init() in the return of convertTo method. Initializable method is required to prevent Swift compiler error.
public protocol Initializable {
    init()
}
