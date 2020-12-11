//
//  ResponseModel.swift
//  fk-firebase-kit-ios
//
//  Created by Furkan Kaplan on 5.12.2020.
//

import Foundation

public struct ResponseModel<T: Codable>: Codable {
    public var key: String?
    public var result: T?
}
