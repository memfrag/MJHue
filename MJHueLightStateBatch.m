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

#import "MJHueLightStateBatch.h"
#import "MJHueColor.h"

@implementation MJHueLightStateBatch {
    NSMutableDictionary *_batch;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self clear];
    }
    return self;
}

- (void)addState:(NSDictionary *)state
{
    [_batch addEntriesFromDictionary:state];
}

- (NSDictionary *)asDictionary
{
    return _batch;
}

- (void)clear
{
    _batch = [NSMutableDictionary dictionaryWithCapacity:10];
}

- (void)setOn
{
    [self addState:@{@"on" : @1}];
}

- (void)setOff
{
    [self addState:@{@"on" : @0}];
}

- (void)setTransitionTime:(float)time
{
    NSUInteger transitionTime = (NSUInteger)(10.0f * time);
    [self addState:@{@"transitiontime" : @(transitionTime)}];
}

- (void)setHue:(NSUInteger)hue
{
    NSUInteger clampedHue = MIN(hue, 65535);
    [self addState:@{@"hue" : @(clampedHue)}];
}

- (void)setBrightness:(NSUInteger)brightness
{
    NSUInteger clampedBrightness = MIN(brightness, 255);
    [self addState:@{@"bri" : @(clampedBrightness)}];
}

- (void)setSaturation:(NSUInteger)saturation
{
    NSUInteger clampedSaturation = MIN(saturation, 255);
    [self addState:@{@"sat" : @(clampedSaturation)}];
}

- (void)setColor:(MJHueColor *)color
{
    [self addState:[color asHueColorDictionary]];
}

- (void)setAlert:(MJHueAlert)alert
{
    switch (alert) {
        case MJHueAlertFlashOnce:
            [self addState:@{@"alert" : @"select"}];
            break;
        case MJHueAlertFlash:
            [self addState:@{@"alert" : @"lselect"}];
            break;
        case MJHueAlertNone:
        default:
            [self addState:@{@"alert" : @"none"}];
            break;
    }
}

- (void)setEffect:(MJHueEffect)effect
{
    switch (effect) {
        case MJHueEffectColorLoop:
            [self addState:@{@"effect" : @"colorloop"}];
            break;
        case MJHueEffectNone:
        default:
            [self addState:@{@"effect" : @"none"}];
            break;
    }
}

@end
