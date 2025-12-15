import Foundation

public struct ProductDataPeriod {
    public let unit: NSCalendar.Unit
    public let numberOfUnits: Int
    
    public init(unit: NSCalendar.Unit, numberOfUnits: Int) {
        self.unit = unit
        self.numberOfUnits = numberOfUnits
    }
    
    public static let week = ProductDataPeriod(unit: .weekOfMonth, numberOfUnits: 1)
    public static let month = ProductDataPeriod(unit: .month, numberOfUnits: 1)
    public static let threeMonths = ProductDataPeriod(unit: .month, numberOfUnits: 3)
    public static let sixMonths = ProductDataPeriod(unit: .month, numberOfUnits: 6)
    public static let year = ProductDataPeriod(unit: .year, numberOfUnits: 1)
    
    private static var calendar: Calendar {
        var calendar = Calendar.current
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }
    
    public var days: Int {
        switch unit {
        case .day: numberOfUnits * 1
        case .weekOfMonth: numberOfUnits * 7
        case .month: numberOfUnits * 30
        case .year: numberOfUnits * 365
        default: 1
        }
    }
    
    public func format(omitOneUnit: Bool) -> String {
        var unit = unit
        var numberOfUnits = numberOfUnits
        if unit == .day, numberOfUnits == 7 {
            unit = .weekOfMonth
            numberOfUnits = 1
        }
        let componentFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.maximumUnitCount = 1
            formatter.unitsStyle = .full
            formatter.zeroFormattingBehavior = .dropAll
            formatter.calendar = Self.calendar
            formatter.allowedUnits = [unit]
            return formatter
        }()
        var dateComponents = DateComponents()
        dateComponents.calendar = Self.calendar
        switch unit {
        case .day:
            if omitOneUnit, numberOfUnits == 1 { return "day" }
            dateComponents.setValue(numberOfUnits, for: .day)
        case .weekOfMonth:
            if omitOneUnit, numberOfUnits == 1 { return "week" }
            dateComponents.setValue(numberOfUnits, for: .weekOfMonth)
        case .month:
            if omitOneUnit, numberOfUnits == 1 { return "month" }
            dateComponents.setValue(numberOfUnits, for: .month)
        case .year:
            if omitOneUnit, numberOfUnits == 1 { return "year" }
            dateComponents.setValue(numberOfUnits, for: .year)
        default:
            assertionFailure("invalid storekit")
        }
        
        return componentFormatter.string(from: dateComponents)!
    }
}
