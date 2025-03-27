//
//  Collection+Extension.swift
//  Rentree
//
//  Created by jun on 3/27/25.
//

extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
