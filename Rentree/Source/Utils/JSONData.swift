//
//  JSONData.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//


import Foundation
enum JSONData: Codable {
   case object([String: JSONData])
   case array([JSONData])
   case string(String)
   case number(Double)
   case bool(Bool)
   case null
   
   init(from decoder: Decoder) throws {
      let container = try decoder.singleValueContainer()
      
      if let object = try? container.decode([String: JSONData].self) {
         self = .object(object)
      } else if let array = try? container.decode([JSONData].self) {
         self = .array(array)
      } else if let string = try? container.decode(String.self) {
         self = .string(string)
      } else if let number = try? container.decode(Double.self) {
         self = .number(number)
      } else if let bool = try? container.decode(Bool.self) {
         self = .bool(bool)
      } else {
         self = .null
      }
   }
   
   func encode(to encoder: Encoder) throws {
      var container = encoder.singleValueContainer()
      
      switch self {
      case .object(let object):
         try container.encode(object)
      case .array(let array):
         try container.encode(array)
      case .string(let string):
         try container.encode(string)
      case .number(let number):
         try container.encode(number)
      case .bool(let bool):
         try container.encode(bool)
      case .null:
         try container.encodeNil()
      }
   }
}

