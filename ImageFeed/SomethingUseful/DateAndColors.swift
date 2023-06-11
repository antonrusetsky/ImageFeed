//
//  Date.swift
//  ImageFeed
//
//  Created by Anton Rusetsky on 06.06.2023.
//

import UIKit

private  let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMMM yyyy"
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
} ()

extension Date {
    var dateTimeString: String {
        var dateString = dateFormatter.string(from: self)
        dateString = dateString.replacingOccurrences(of: "г.", with: "")
        return dateString
    }
}

extension UIColor {
    static let black = UIColor(named: "black")
    static let darkGray = UIColor(named: "darkGray")
    static let gray = UIColor(named: "gray")
    static let red = UIColor(named: "red")
    static let white = UIColor(named: "white")
}
