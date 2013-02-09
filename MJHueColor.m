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

#import "MJHueColor.h"

@implementation MJHueColor {
    
}

- (id)initWithRed:(float)red green:(float)green blue:(float)blue
{
    self = [super init];
    if (self) {
        _red = red;
        _green = green;
        _blue = blue;
    }
    return self;
}

- (NSDictionary *)asHueColorDictionary
{
#if defined(TARGET_OS_MAC)
    NSColor *color = [NSColor colorWithCalibratedRed:self.red green:self.green blue:self.blue alpha:1.0];
#elif defined(TARGET_OS_IPHONE)
    UIColor *color = [UIColor colorWithRed:self.red green:self.green blue:self.blue alpha:1.0];
#else
#error MJHueColor does not support this platform.
#endif
    CGFloat hue;
    CGFloat saturation;
    CGFloat brightness;
    [color getHue:&hue saturation:&saturation brightness:&brightness alpha:NULL];
    NSNumber *hueHue = [NSNumber numberWithInteger:(NSInteger)(hue * 65535.0f)];
    NSNumber *hueBrightness = [NSNumber numberWithInteger:(NSInteger)(brightness * 254.0f)];
    NSNumber *hueSaturation = [NSNumber numberWithInteger:(NSInteger)(saturation * 254.0f)];
    return @{@"hue" : hueHue, @"bri" : hueBrightness, @"sat" : hueSaturation, @"on" : @YES};
}

@end
