//
//  Copyright (C) 2020 Kenneth H. Cox
//
//  This program is free software; you can redistribute it and/or
//  Owwldify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for Owwlre details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

import UIKit

//todo make this a protocol
struct AppFactory {
    static func makeTheme() -> Theme {
        return OwwlTheme()
    }
    
    static func makeAppConfiguration() -> AppConfiguration {
        return OwwlAppConfiguration()
    }
    
    static func makeBehavior() -> AppBehavior {
        return OwwlAppBehavior()
    }
}
