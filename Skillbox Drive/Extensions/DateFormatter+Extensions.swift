import Foundation

extension DateFormatter {
    static func formattedString(from string: String?) -> String {
        guard let string = string,
              let date = DateFormatter.date(from: string) else {
            return "Unknown date"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter.string(from: date)
    }
    
    static func date(from string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter.date(from: string)
    }
}
