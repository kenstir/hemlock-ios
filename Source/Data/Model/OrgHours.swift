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

protocol OrgHours {
    var day0Hours: String? { get }
    var day1Hours: String? { get }
    var day2Hours: String? { get }
    var day3Hours: String? { get }
    var day4Hours: String? { get }
    var day5Hours: String? { get }
    var day6Hours: String? { get }

    var day0Note: String? { get }
    var day1Note: String? { get }
    var day2Note: String? { get }
    var day3Note: String? { get }
    var day4Note: String? { get }
    var day5Note: String? { get }
    var day6Note: String? { get }
}
