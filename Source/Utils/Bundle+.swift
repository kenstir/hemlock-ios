//
//  Bundle+.swift
//
//  Copyright (C) 2019 Kenneth H. Cox
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
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import Foundation

extension Bundle {
    static var appIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "?"
    }

    static var appName: String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "?"
    }

    static var appVersion: String {
        return getAppVersion(urlSafe: false)
    }
    
    static var appVersionUrlSafe: String {
        return getAppVersion(urlSafe: true)
    }
    
    static func getAppVersion(urlSafe: Bool) -> String {
        guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else
        {
            return "?"
        }
        return (urlSafe ? "\(version).\(build)" : "\(version) (\(build))")
    }

    static var isTestFlightOrDebug: Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else { return false }
        return path.contains("sandboxReceipt") || path.contains("CoreSimulator")
    }

    static var isDebug: Bool {
        guard let path = Bundle.main.appStoreReceiptURL?.path else { return false }
        return path.contains("CoreSimulator")
    }
}
