import Foundation

public enum HttpEndpoint {
    case findAccountRegion
    case identifyCustomer(identifier: String)
    case registerDevice(identifier: String)
    case deleteDevice(identifier: String, deviceToken: String)
    case trackCustomerEvent(identifier: String)
    case pushMetrics

    var path: String {
        switch self {
        case .findAccountRegion: return "/api/v1/accounts/region"
        case .identifyCustomer(let identifier): return "/api/v1/customers/\(identifier)"
        case .registerDevice(let identifier): return "/api/v1/customers/\(identifier)/devices"
        case .deleteDevice(let identifier,
                           let deviceToken): return "/api/v1/customers/\(identifier)/devices/\(deviceToken)"
        case .trackCustomerEvent(let identifier): return "/api/v1/customers/\(identifier)/events"
        case .pushMetrics: return "/push/events"
        }
    }

    var method: String {
        switch self {
        case .findAccountRegion: return "GET"
        case .identifyCustomer: return "PUT"
        case .registerDevice: return "PUT"
        case .deleteDevice: return "DELETE"
        case .trackCustomerEvent: return "POST"
        case .pushMetrics: return "POST"
        }
    }
}

public extension HttpEndpoint {
    func getUrl(baseUrls: HttpBaseUrls) -> URL? {
        URL(string: getUrlString(baseUrls: baseUrls))
    }

    func getUrlString(baseUrls: HttpBaseUrls) -> String {
        // At this time, all endpoints use tracking endpoint so we only use only 1 base URL here.
        var baseUrl = baseUrls.trackingApi

        guard !baseUrl.isEmpty else {
            return ""
        }
        if baseUrl.last! == "/" {
            baseUrl = String(baseUrl.dropLast())
        }

        return baseUrl + path
    }
}

/**
 Collection of the different base URLs for all the APIs of Customer.io.
 Each endpoint in `HttpEndpoint` knows what base API that it needs. That is where
 the full URL including path is constructed.
 */
public struct HttpBaseUrls: Equatable {
    let trackingApi: String

    static func getProduction(region: Region) -> HttpBaseUrls {
        HttpBaseUrls(trackingApi: region.productionTrackingUrl)
    }
}
