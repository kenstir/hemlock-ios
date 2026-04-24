//
//  Copyright (c) 2026 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, see <https://www.gnu.org/licenses/>.

struct TokenEntry: Codable {
    let token: String
    let addedAt: Int64

    enum CodingKeys: String, CodingKey {
        case token
        case addedAt = "added_at"
    }
}

class TokenStore: Codable {
    static let maxEntries = 4
    static let tokenExpirationSeconds: Int64 = 86400 * 365 // 1 year
    static let tokenRefreshIntervalSeconds: Int64 = 86400 * 365 / 2
    // prefix for all v2 encoded tokens, which is base64url-encoded string '{"entries":['
    static let v2EncodedTokenPrefix = "eyJlbnRyaWVzIjpb"

    // only entries gets encoded
    var entries: [TokenEntry] = []
    enum CodingKeys: String, CodingKey {
        case entries
    }

    var isModified = false

    /// Initializes the TokenStore from a string, either a plain PN token (v1) or a base64url-encoded JSON TS object (v2)
    func initialize(fromString storedString: String?) {
        entries = []
        isModified = false

        guard let str = storedString, !str.isEmpty else { return }

        // if it looks like a v2 encoded object, try to decode it
        if str.hasPrefix(TokenStore.v2EncodedTokenPrefix),
           let data = Data(base64urlEncoded: str),
           initialize(fromData: data) {
            return
        }

        addCurrentToken(str)
    }

    private func initialize(fromData data: Data) -> Bool {
        guard let ts = try? JSONDecoder().decode(TokenStore.self, from: data) else {
            return false
        }

        // keep only non-expired entries
        let now = Int64(Date().timeIntervalSince1970)
        self.entries = ts.entries.filter { now - $0.addedAt < TokenStore.tokenExpirationSeconds }
        self.isModified = (self.entries.count != ts.entries.count)

        return true
    }

    func addCurrentToken(_ token: String) {
        let now = Int64(Date().timeIntervalSince1970)

        // check if token exists and if it needs to be refreshed
        if let currentEntry = entries.first(where: { $0.token == token }) {
            if now - currentEntry.addedAt > TokenStore.tokenRefreshIntervalSeconds {
                // exists but needs to be refreshed; remove and re-add
                entries.removeAll(where: { $0.token == token })
                pushToken(token, addedAt: now)
            }
            return
        }

        pushToken(token, addedAt: now)
    }

    private func pushToken(_ token: String, addedAt: Int64) {
        entries.append(TokenEntry(token: token, addedAt: addedAt))
        while entries.count > TokenStore.maxEntries {
            entries.removeFirst()
        }
        isModified = true
    }

    func encodeToString() -> String {
        // use sortedKeys to simplify testing
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        let data = try? encoder.encode(self)
        return data?.base64urlEncodedString() ?? ""
    }

    func dump() {
        for entry in entries {
            print("[fcm]   added_at:\(entry.addedAt) token:\(entry.token)")
        }
    }
}
