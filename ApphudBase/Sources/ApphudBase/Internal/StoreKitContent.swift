import Foundation

struct StoreKitContent: Decodable {
    let nonRenewingSubscriptions: [Product]?
    let nonConsumableProducts: [Product]?
    let subscriptionGroups: [SubscriptionGroup]?
    
    var products: [Product] {
        (nonRenewingSubscriptions ?? []) +
        (nonConsumableProducts ?? []) +
        (subscriptionGroups ?? []).flatMap(\.subscriptions)
    }

    enum CodingKeys: String, CodingKey {
        case nonRenewingSubscriptions = "nonRenewingSubscriptions"
        case nonConsumableProducts = "products"
        case subscriptionGroups = "subscriptionGroups"
    }

    struct SubscriptionGroup: Decodable {
        let subscriptions: [Product]

        enum CodingKeys: String, CodingKey {
            case subscriptions = "subscriptions"
        }
    }

    struct Product: Decodable {
        let productID: String
        let displayPrice: String
        let recurringSubscriptionPeriod: Period?
        let introductoryOffer: IntroductoryOffer?

        enum CodingKeys: String, CodingKey {
            case productID = "productID"
            case displayPrice = "displayPrice"
            case recurringSubscriptionPeriod = "recurringSubscriptionPeriod"
            case introductoryOffer = "introductoryOffer"
        }
    }

    struct IntroductoryOffer: Decodable {
        enum PaymentMode: String, Decodable {
            case free
            case payAsYouGo
            case payUpFront
        }
        let paymentMode: PaymentMode
        let subscriptionPeriod: Period
        let numberOfPeriods: Int?
        let displayPrice: String?

        enum CodingKeys: String, CodingKey {
            case paymentMode = "paymentMode"
            case subscriptionPeriod = "subscriptionPeriod"
            case numberOfPeriods = "numberOfPeriods"
            case displayPrice = "displayPrice"
        }
    }
    
    struct Period: Decodable {
        let unit: NSCalendar.Unit
        let numberOfUnits: Int
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            let periodString = try container.decode(String.self)

            guard periodString.first == "P" else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid period format. Must start with 'P'.")
            }
            
            let duration = periodString.dropFirst()
            
            let pattern = #"^(\d+)([YMWD])$"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let durationString = String(duration)

            guard
                let match = regex.firstMatch(in: durationString, options: [], range: NSRange(location: 0, length: durationString.utf16.count)),
                let numberRange = Range(match.range(at: 1), in: durationString),
                let unitRange = Range(match.range(at: 2), in: durationString),
                let number = Int(durationString[numberRange])
            else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid period format.")
            }

            let unitChar = durationString[unitRange]
            let calendarUnit: NSCalendar.Unit

            switch unitChar {
            case "Y": calendarUnit = .year
            case "M": calendarUnit = .month
            case "W": calendarUnit = .weekOfMonth
            case "D": calendarUnit = .day
            default:
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported time unit: \(unitChar)")
            }

            self.unit = calendarUnit
            self.numberOfUnits = number
        }
    }
}
