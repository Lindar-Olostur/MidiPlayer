import Foundation

public enum ProductDataIntroductory {
    case freeTrial(ProductDataPeriod)
    case payUpFront(Decimal, ProductDataPeriod)
    case payAsYouGo(Decimal, ProductDataPeriod, Int)
    
    public var firstPaymentPrice: Decimal? {
        switch self {
        case .freeTrial(_): nil
        case .payUpFront(let price, _): price
        case .payAsYouGo(let price, _, _): price
        }
    }
    
    public var period: ProductDataPeriod? {
        switch self {
        case .freeTrial(let period): period
        case .payUpFront(_, let period): period
        case .payAsYouGo(_, let period, _): period
        }
    }
}
