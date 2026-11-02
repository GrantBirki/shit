import Foundation

enum MeetingLink {
    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    static func resolve(url: URL?, location: String?, notes: String?) -> URL? {
        let eventURL = url.flatMap(webURL)
        let locationURL = location.flatMap {
            URL(string: $0.trimmingCharacters(in: .whitespacesAndNewlines), encodingInvalidCharacters: false)
        }.flatMap(webURL)

        for candidate in [eventURL, locationURL].compactMap(\.self) where isConferenceLink(candidate) {
            return candidate
        }
        for text in [location, notes].compactMap(\.self) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = detector?.matches(in: text, range: range) ?? []
            if let link = matches.compactMap(\.url).first(where: isConferenceLink) {
                return link
            }
        }
        return eventURL ?? locationURL
    }

    private static func webURL(_ url: URL) -> URL? {
        guard let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil
        else { return nil }
        return url
    }

    private static func isConferenceLink(_ url: URL) -> Bool {
        guard webURL(url) != nil, let host = url.host?.lowercased(), url.path.count > 1 else { return false }
        let path = url.path.lowercased()
        switch host {
        case "meet.google.com":
            return true
        case "teams.microsoft.com", "teams.live.com", "teams.cloud.microsoft":
            return path.hasPrefix("/l/meetup-join/") || path.hasPrefix("/meet/")
        case "facetime.apple.com":
            return path.hasPrefix("/join")
        default:
            if host == "zoom.us" || host.hasSuffix(".zoom.us") ||
                host == "zoomgov.com" || host.hasSuffix(".zoomgov.com")
            {
                return ["/j/", "/my/", "/w/", "/s/", "/wc/"].contains(where: path.hasPrefix)
            }
            return (host == "webex.com" || host.hasSuffix(".webex.com")) &&
                (path.contains("/j.php") || path.hasPrefix("/meet/") || path.hasPrefix("/join/"))
        }
    }
}
