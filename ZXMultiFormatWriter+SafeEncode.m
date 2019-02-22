//
//  ZXMultiFormatWriter+SafeEncode.m
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

#import <Foundation/Foundation.h>
#import "ZXMultiFormatWriter+SafeEncode.h"

@implementation ZXMultiFormatWriter (SafeEncode)

// Extend ZXMultiFormatWriter with an encode method that doesn't throw
// NSInvalidArgumentException.  You can't catch that in Swift.
- (ZXBitMatrix *)safeEncode:(NSString *)contents format:(ZXBarcodeFormat)format width:(int)width height:(int)height {
    ZXBitMatrix *matrix = nil;
    @try {
        matrix = [self encode:contents format:format width:width height:height hints:nil error:nil];
    } @catch (NSException *exception) {
        // ignore
    } @finally {
        // nada
    }
    return matrix;
}

@end
