import Foundation
import OSLog
#if canImport(UIKit)
import UIKit
#else
import SwiftUI
#endif

struct OpenGraphFetcher {
    enum FetchError: Error {
        case invalidResponse
    }
    
    private static let logger = Logger(subsystem: "com.felixdulfer.gift-planner-ios", category: "OpenGraphFetcher")
    static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
    
    static func imageURL(for link: URL) async throws -> URL? {
        var request = URLRequest(url: link)
        request.timeoutInterval = 12
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<400).contains(httpResponse.statusCode) else {
            logger.warning("Invalid HTTP response for \(link.absoluteString, privacy: .public)")
            throw FetchError.invalidResponse
        }
        
        guard let html = htmlString(from: data, response: httpResponse) else {
            logger.debug("Unable to decode HTML for \(link.absoluteString, privacy: .public)")
            return nil
        }
        
        if let imageURL = extractImageURL(from: html, baseURL: link) {
            return imageURL
        }
        
        logger.debug("No Open Graph image found for \(link.absoluteString, privacy: .public)")
        return nil
    }
    
    private static func htmlString(from data: Data, response: HTTPURLResponse) -> String? {
        if let encodingName = response.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                let encoding = CFStringConvertEncodingToNSStringEncoding(cfEncoding)
                let stringEncoding = String.Encoding(rawValue: encoding)
                if let html = String(data: data, encoding: stringEncoding) {
                    return html
                }
            }
        }
        
        if let html = String(data: data, encoding: .utf8) {
            return html
        }
        
        if let html = String(data: data, encoding: .isoLatin1) {
            return html
        }
        
        return nil
    }
    
    private static func extractImageURL(from html: String, baseURL: URL) -> URL? {
        let patterns = [
            #"<meta\s[^>]*(?:property|name)\s*=\s*["']og:image["'][^>]*content\s*=\s*["']([^"']+)["'][^>]*>"#,
            #"<meta\s[^>]*content\s*=\s*["']([^"']+)["'][^>]*(?:property|name)\s*=\s*["']og:image["'][^>]*>"#
        ]
        
        for pattern in patterns {
            if let urlString = firstMatch(in: html, pattern: pattern, captureGroup: 1) {
                if let absoluteURL = makeAbsoluteURL(from: urlString, baseURL: baseURL) {
                    return absoluteURL
                }
            }
        }
        
        return nil
    }
    
    private static func firstMatch(in string: String, pattern: String, captureGroup: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return nil
        }
        
        let range = NSRange(string.startIndex..<string.endIndex, in: string)
        guard let match = regex.firstMatch(in: string, options: [], range: range),
              match.numberOfRanges > captureGroup,
              let matchRange = Range(match.range(at: captureGroup), in: string) else {
            return nil
        }
        
        return String(string[matchRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private static func makeAbsoluteURL(from urlString: String, baseURL: URL) -> URL? {
        if let url = URL(string: urlString), url.scheme != nil {
            return url
        }
        
        if let url = URL(string: urlString, relativeTo: baseURL) {
            return url.absoluteURL
        }
        
        return nil
    }
}

actor OpenGraphImageCache {
    static let shared = OpenGraphImageCache()
    
#if canImport(UIKit)
    private var storage: [URL: UIImage?] = [:]
    
    func cachedImage(for link: URL) -> UIImage?? {
        storage[link]
    }
    
    func store(image: UIImage?, for link: URL) {
        storage[link] = image
    }
#else
    private var storage: [URL: Image?] = [:]
    
    func cachedImage(for link: URL) -> Image?? {
        storage[link]
    }
    
    func store(image: Image?, for link: URL) {
        storage[link] = image
    }
#endif
}

