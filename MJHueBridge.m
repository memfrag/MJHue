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

#import "MJHueBridge.h"
#import "MJRESTClient.h"
#import "MJHueLightStateBatch.h"

const NSString *MJHueBridgeErrorDomain = @"MJHueBridgeErrorDomain";

@implementation MJHueBridge {
    MJRESTClient *_restClient;
    NSDictionary *_hueState;
    BOOL _linkButtonMustBePressed;
}

- (id)initWithHueId:(NSString *)hueId name:(NSString *)name url:(NSURL *)url
{
    self = [super init];
    if (self) {
        _hueId = [hueId copy];
        _name = [name copy];
        _url = [url copy];
        _restClient = [[MJRESTClient alloc] init];
    }
    return self;
}

#pragma mark - Info Methods

- (NSString *)description
{
    return [NSString stringWithFormat:@"<hue id=\"%@\" name=\"%@\" url=\"%@\"/>", _hueId, _name, _url];
}

- (NSString *)clientId
{
    NSString *key = [@"hueClientId_" stringByAppendingString:_hueId];
    NSString *clientId = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if (!clientId) {
        clientId = [[[NSUUID UUID] UUIDString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
        [[NSUserDefaults standardUserDefaults] setValue:clientId forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    return clientId;
}

- (NSUInteger)lightCount
{
    if (!_hueState) {
        return 0;
    } else {
        NSDictionary *lights = _hueState[@"lights"];
        if (!lights) {
            return 0;
        } else {
            return lights.count;
        }
    }
}

#pragma mark - Update Bridge State

- (void)update
{
    NSString *urlPath = [@"api/" stringByAppendingString:[self clientId]];
    NSURL *updateUrl = [_url URLByAppendingPathComponent:urlPath];
        
    [_restClient getFromURL:updateUrl completionHandler:^(id jsonResponse, NSError *error) {
        NSLog(@"Response: %@", jsonResponse);
        
        if (!error) {
            
            if ([jsonResponse isKindOfClass:[NSArray class]]) {
                // Could be an error
                NSDictionary *message = jsonResponse[0];
                NSDictionary *errorMessage = message[@"error"];
                if (errorMessage) {
                    NSNumber *errorCode = errorMessage[@"type"];
                    if (errorCode.intValue == 1) {
                        [self link];
                    } else {
                        NSError *updateError = [NSError errorWithDomain:[MJHueBridgeErrorDomain copy] code:errorCode.intValue userInfo:@{NSLocalizedDescriptionKey : errorMessage[@"description"]}];
                        if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToGetUpdatedBridgeState:error:)]) {
                            [self.delegate didFailToGetUpdatedBridgeState:self error:updateError];
                        }
                    }
                } else {
                    // FIXME: Not sure how to handle this case yet.
                }
            } else {
                _hueState = jsonResponse;
                if (self.delegate && [self.delegate respondsToSelector:@selector(didGetUpdatedBridgeState:)]) {
                    [self.delegate didGetUpdatedBridgeState:self];
                }
            }
        } else {
            NSLog(@"Error %ld (%@) - %@", error.code, error.domain, error.localizedDescription);
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToGetUpdatedBridgeState:error:)]) {
                [self.delegate didFailToGetUpdatedBridgeState:self error:error];
            }
        }
    }];
    
}

#pragma mark - Link with Bridge

- (void)link
{
    NSURL *linkUrl = [_url URLByAppendingPathComponent:@"api"];

    NSDictionary *request = @{@"username" : [self clientId],
                              @"devicetype" : @"se.memfrag.MJHue"};
    NSLog(@"Posted username: %@", [self clientId]);
    
    [_restClient postToURL:linkUrl jsonRequest:request completionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            NSLog(@"Response: %@", jsonResponse);
            
            if ([jsonResponse isKindOfClass:[NSArray class]]) {
                NSArray *responses = jsonResponse;
                
                for (NSDictionary *response in responses) {
                    if (response[@"success"]) {
                        NSString *key = response[@"success"][@"username"];
                        NSLog(@"Key: %@", key);
                        _linkButtonMustBePressed = NO;
                        [self update];
                    } else if (response[@"error"]) {
                        NSDictionary *errorMessage = response[@"error"];
                        NSNumber *errorTypeNumber = errorMessage[@"type"];
                        int type = [errorTypeNumber intValue];
                        NSString *description = errorMessage[@"description"];
                        switch (type) {
                            case 101: {
                                // Link button needs to be pressed!
                                NSLog(@"Link button needs to be pressed!");
                                if (!_linkButtonMustBePressed) {
                                    if (self.delegate && [self.delegate respondsToSelector:@selector(bridgeLinkButtonMustBePressed:)]) {
                                        [self.delegate bridgeLinkButtonMustBePressed:self];
                                    }
                                }
                                _linkButtonMustBePressed = YES;
                                double delayInSeconds = 2.0;
                                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                                    [self link];
                                });
                                break;
                            }
                            default:
                                NSLog(@"Error %d: %@", type, description);
                                break;
                        }
                    }
                }
            }
        }
    }];
}

#pragma mark - Configuration

- (void)changeBridgeName:(NSString *)newName
{
    NSString *urlPath = [@"api/" stringByAppendingString:[self clientId]];
    NSURL *url = [_url URLByAppendingPathComponent:urlPath];
    
    [_restClient getFromURL:url completionHandler:^(id jsonResponse, NSError *error) {
        NSLog(@"Response: %@", jsonResponse);
        
        if (!error) {
            
            NSDictionary *message = jsonResponse[0];
            if (message[@"success"]) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(didChangeBridgeName:)]) {
                    [self.delegate didChangeBridgeName:self];
                }
            } else {
                NSDictionary *errorMessage = message[@"error"];
                if (errorMessage) {
                    NSNumber *errorCode = errorMessage[@"type"];
                    NSError *updateError = [NSError errorWithDomain:[MJHueBridgeErrorDomain copy] code:errorCode.intValue userInfo:@{NSLocalizedDescriptionKey : errorMessage[@"description"]}];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToChangeBridgeName:error:)]) {
                        [self.delegate didFailToChangeBridgeName:self error:updateError];
                    }

                } else {
                    // FIXME: Not sure how to handle this case yet.
                }
            }
        } else {
            NSLog(@"Error %ld (%@) - %@", error.code, error.domain, error.localizedDescription);
            if (self.delegate && [self.delegate respondsToSelector:@selector(didFailToChangeBridgeName:error:)]) {
                [self.delegate didFailToChangeBridgeName:self error:error];
            }
        }
    }];
}

#pragma mark - Light State Configuration

- (void)changeNameOfLightAtIndex:(NSUInteger)index
                            name:(NSString *)newName
{
    NSString *urlPath = [NSString stringWithFormat:@"api/%@/lights/%lu", [self clientId], index];
    NSURL *url = [_url URLByAppendingPathComponent:urlPath];

    NSDictionary *namePayload = @{@"name" : newName};
    
    [_restClient putToURL:url jsonRequest:namePayload completionHandler:^(id jsonResponse, NSError *error) {
        NSLog(@"Response: %@", jsonResponse);
        
        if (!error) {
            
            NSDictionary *message = jsonResponse[0];
            if (message[@"success"]) {
                if (self.delegate && [self.delegate respondsToSelector:@selector(bridge:didChangeNameOfLightAtIndex:)]) {
                    [self.delegate bridge:self didChangeNameOfLightAtIndex:index];
                }
            } else {
                NSDictionary *errorMessage = message[@"error"];
                if (errorMessage) {
                    NSNumber *errorCode = errorMessage[@"type"];
                    NSError *updateError = [NSError errorWithDomain:[MJHueBridgeErrorDomain copy] code:errorCode.intValue userInfo:@{NSLocalizedDescriptionKey : errorMessage[@"description"]}];
                    if (self.delegate && [self.delegate respondsToSelector:@selector(bridge:didFailToChangeNameOfLightAtIndex:error:)]) {
                        [self.delegate bridge:self didFailToChangeNameOfLightAtIndex:index error:updateError];
                    }
                    
                } else {
                    // FIXME: Not sure how to handle this case yet.
                }
            }
        } else {
            NSLog(@"Error %ld (%@) - %@", error.code, error.domain, error.localizedDescription);
            if (self.delegate && [self.delegate respondsToSelector:@selector(bridge:didFailToChangeNameOfLightAtIndex:error:)]) {
                [self.delegate bridge:self didFailToChangeNameOfLightAtIndex:index error:error];
            }
        }
    }];
}


- (void)changeStateForLightAtIndex:(NSUInteger)index state:(MJHueLightStateBatch *)state
{
    NSString *urlPath = [NSString stringWithFormat:@"api/%@/lights/%lu/state", [self clientId], index];
    NSURL *url = [_url URLByAppendingPathComponent:urlPath];

    [_restClient putToURL:url jsonRequest:[state asDictionary] completionHandler:^(id jsonResponse, NSError *error) {
        if (error) {
            NSLog(@"Error: %@", [error localizedDescription]);
        } else {
            //NSLog(@"Response: %@", jsonResponse);
        }
    }];
}

- (void)changeStateForAllLights:(MJHueLightStateBatch *)state
{
    if (_hueState) {
        NSDictionary *lights = _hueState[@"lights"];
        for (int i = 1; i <= lights.count; i++) {
            [self changeStateForLightAtIndex:i state:state];
        }
    }
}

@end
