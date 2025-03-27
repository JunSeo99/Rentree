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
    
    class func dateToString(date:Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}

class ChatDateConverter {
    let formatter = DateFormatter()
    func getDatePretty(formattedString: String,formatType: FormatType) -> String{
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        if formatType == .dynamic{
            guard let date = formatter.date(from: formattedString) else {return ""}
            if Calendar.current.isDateInToday(date) {
                guard let date = formatter.date(from: formattedString) else {return formattedString}
                formatter.dateFormat = FormatType.shorts.rawValue
                return formatter.string(from: date)
            }
            if Calendar.current.isDateInYesterday(date) {
                return "어제"
            }
            else{
                guard let date = formatter.date(from: formattedString) else {return formattedString}
                formatter.dateFormat = FormatType.shortDay.rawValue
                return formatter.string(from: date)
            }
        }
        
        guard let date = formatter.date(from: formattedString) else {return formattedString}
        formatter.dateFormat = formatType.rawValue
        return formatter.string(from: date)
    }
    /// Long: 2023 02/23 23:32
    /// Shorts: 오후 4:30
    /// Day: 2023년 2월 22일 (수)
    enum FormatType: String{
        case long = "yyyy-MM-dd HH:mm:ss"
        case dynamic = ""
        case shorts = "a hh:mm"
        case day = "yyyy년 M월 d일 (E)"
        case shortDay = "M월 d일"
    }
}
