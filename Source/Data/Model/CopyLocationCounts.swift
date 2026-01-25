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

/// summary of copies at a specific shelving location at a specific org, by status
protocol CopyLocationCounts {
    var orgID: Int { get }

    var shelvingLocation: String { get }

    var callNumber: String { get }

    /// newline-separated list of "count status" labels, e.g. "1 Available\n1 Checked out"
    var countsByStatusLabel: String { get }
}
