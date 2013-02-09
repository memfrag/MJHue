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

#import <Foundation/Foundation.h>

@protocol MJHueBridgeDelegate;
@class MJHueLightStateBatch;

@interface MJHueBridge : NSObject

@property (nonatomic, weak) id<MJHueBridgeDelegate> delegate;

@property (nonatomic, copy, readonly) NSString *hueId;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSURL *url;
@property (nonatomic, assign, readonly) NSUInteger lightCount;

- (id)initWithHueId:(NSString *)hueId name:(NSString *)name url:(NSURL *)url;

- (void)update;

- (void)changeBridgeName:(NSString *)newName;


- (void)changeNameOfLightAtIndex:(NSUInteger)index
                            name:(NSString *)newName;

- (void)changeStateForLightAtIndex:(NSUInteger)index
                             state:(MJHueLightStateBatch *)state;
- (void)changeStateForAllLights:(MJHueLightStateBatch *)state;

@end


@protocol MJHueBridgeDelegate <NSObject>

- (void)didGetUpdatedBridgeState:(MJHueBridge *)bridge;
- (void)didFailToGetUpdatedBridgeState:(MJHueBridge *)bridge error:(NSError *)error;

- (void)bridgeLinkButtonMustBePressed:(MJHueBridge *)bridge;

@optional

- (void)didChangeBridgeName:(MJHueBridge *)bridge;
- (void)didFailToChangeBridgeName:(MJHueBridge *)bridge error:(NSError *)error;

- (void)bridge:(MJHueBridge *)bridge didChangeNameOfLightAtIndex:(NSUInteger)index;
- (void)bridge:(MJHueBridge *)bridge didFailToChangeNameOfLightAtIndex:(NSUInteger)index error:(NSError *)error;


@end

