//
//  Copyright (c) 2013 Martin Johannesson
//
//  Permission is hereby granted, free of charge, to any person obtaining a
//  copy of this software and associated documentation files (the "Software"),
//  to deal in the Software without restriction, including without limitation
//  the rights to use, copy, modify, merge, publish, distribute, sublicense,
//  and/or sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//
//  (MIT License)
//

#import "MJHTTPHeaderParser.h"

@implementation MJHTTPHeaderParser

- (NSDictionary *)parseHTTPHeaders:(NSString *)httpResponse
{
    NSScanner *scanner = [NSScanner scannerWithString:httpResponse];
    [scanner setCharactersToBeSkipped:nil];
    if (![scanner scanString:@"HTTP/1.1" intoString:NULL]) {
        return nil;
    }
    if (![scanner scanUpToString:@"\r\n" intoString:NULL]) {
        return nil;
    }
    
    NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithCapacity:10];
    
    while (1) {
        if ([scanner scanString:@"\r\n" intoString:NULL]) {
            if ([scanner scanString:@"\r\n" intoString:NULL]) {
                return headers;
            }
        } else {
            return nil;
        }
        NSString *headerName;
        if (![scanner scanUpToString:@":" intoString:&headerName]) {
            return nil;
        }
        [scanner scanString:@":" intoString:NULL];
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];
        NSString *headerValue;
        if (![scanner scanUpToString:@"\r\n" intoString:&headerValue]) {
            headerValue = [@"" copy];
        }
        [headers setObject:headerValue forKey:headerName];
    }
}

@end
