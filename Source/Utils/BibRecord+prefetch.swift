//
//  Copyright (c) 2025 Kenneth H. Cox
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

import os.log

/// add prefetching semantics to BibRecord
extension BibRecord {

    func isLoaded() -> Bool {
        return hasMetadata && hasAttributes
    }

    /// `prefetch` does asynchronous prefetching of details and attributes.
    ///  It does not throw because we use it for preloading table rows.
    func prefetch() async -> Void {
        print("\(Utils.tt) id=\(String(format: "%7d", id)) prefetch hasMetadata=\(self.hasMetadata) hasAttrs=\(self.hasAttributes)")

        async let details: Void = App.serviceConfig.biblioService.loadRecordDetails(forRecord: self, needMARC: false)
        async let attrs: Void = App.serviceConfig.biblioService.loadRecordAttributes(forRecord: self)
        let _ = try? await (details, attrs)
    }
}
