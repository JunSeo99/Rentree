//
//  DateFormatter.swift
//  Rentree
//
//  Created by jun on 3/26/25.
//
import Foundation

class DateConverter{
    class func dateToString(string: String) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        guard let date = formatter.date(from: string) else{
            return string
        }
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
