//
//  HemlockError.swift
//
//  Copyright (C) 2018 Kenneth H. Cox
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

public enum HemlockError: Error {
    case unexpectedNetworkResponse(String)
    case shouldNotHappen(String)
    case sessionExpired
}

extension HemlockError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .unexpectedNetworkResponse(let reason):
            return "Unexpected network response: \(reason)"
        case .shouldNotHappen(let reason):
            return reason
        case .sessionExpired:
            return "Session expired"
        }
    }
}

func isSessionExpired(error: Error) -> Bool {
    if let gatewayError = error as? GatewayError {
        switch gatewayError {
        case .event(let ilsevent, _, _, _):
            return ilsevent == 1001 // && textcode == "NO_SESSION"
        default:
            return false
        }
    } else if let err = error as? HemlockError {
        switch err {
        case .sessionExpired:
            return true
        default:
            return false
        }
    }
    return false
}
