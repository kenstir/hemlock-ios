//
//  HemlockAppConfiguration.swift
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

class HemlockAppConfiguration: AppConfiguration {
    let title = "Hemlock"
    let url = "https://catalog.cwmars.org"
    //let url = "https://kenstir.ddns.net"
    let logSubsystem = "net.kenstir.apps.hemlock"
    
    let enableHierarchicalOrgTree = false
    let enableHoldShowQueuePosition = true
    let enableHoldPhoneNotification = false
    let enableMainSceneBottomToolbar = false
    let enablePayFines = true
    let groupCopyInfoBySystem = false

    let barcodeFormat: BarcodeFormat = .Disabled
    let searchLimit = 100

    let searchFormatsJSON = """
[
  {"l":"All Formats", "f":""},
  {"l":"All Books", "f":"book", "L":"Book"},
  {"l":"All Music", "f":"music", "L":"Music"},
  {"l":"Audiocassette music recording", "f":"casmusic", "h":true},
  {"l":"Blu-ray", "f":"blu-ray"},
  {"l":"Braille", "f":"braille", "h":true},
  {"l":"Cassette audiobook", "f":"casaudiobook", "h":true},
  {"l":"CD Audiobook", "f":"cdaudiobook"},
  {"l":"CD Music recording", "f":"cdmusic"},
  {"l":"DVD", "f":"dvd"},
  {"l":"E-audio", "f":"eaudio"},
  {"l":"E-book", "f":"ebook"},
  {"l":"E-video", "f":"evideo"},
  {"l":"Equipment, games, toys", "f":"equip", "h":true},
  {"l":"Kit", "f":"kit", "h":true},
  {"l":"Large Print Book", "f":"lpbook"},
  {"l":"Map", "f":"map", "h":true},
  {"l":"Microform", "f":"microform", "h":true},
  {"l":"Music Score", "f":"score", "h":true},
  {"l":"Phonograph music recording", "f":"phonomusic", "h":true},
  {"l":"Phonograph spoken recording", "f":"phonospoken", "h":true},
  {"l":"Picture", "f":"picture"},
  {"l":"Serials and magazines", "f":"serial"},
  {"l":"Software and video games", "f":"software"},
  {"l":"VHS", "f":"vhs", "h":true}
]
"""
}
