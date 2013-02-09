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

#import "MJRESTClient.h"

@implementation MJRESTClient {
    NSOperationQueue *_queue;
}

- (id)init
{
    self = [super init];
    if (self) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)sendRequest:(NSURLRequest *)request completionHandler:(void (^)(id jsonResponse, NSError *error))completionHandler {
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error == nil) {
                                   NSError *jsonError = nil;
                                   id jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                   completionHandler(jsonResponse, jsonError);
                               } else if (error != nil) {
                                   completionHandler(nil, error);
                               }
                           }];    
}

- (NSURLRequest *)createRequestWithURL:(NSURL *)url method:(NSString *)method data:(NSData *)data
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:60.0];
    [request setHTTPMethod:method];
    if (data) {
        [request setHTTPBody:data];
    }
    return request;
}

- (void)getFromURL:(NSURL *)url completionHandler:(void (^)(id jsonResponse, NSError *error))completionHandler
{
    NSURLRequest *request = [self createRequestWithURL:url method:@"GET" data:nil];
    [self sendRequest:request completionHandler:completionHandler];
}

- (void)postToURL:(NSURL *)url jsonRequest:(id)jsonRequest completionHandler:(void (^)(id jsonResponse, NSError *error))completionHandler
{
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonRequest options:0 error:&error];
    if (postData == nil) {
        completionHandler(nil, error);
        return;
    }
    NSURLRequest *request = [self createRequestWithURL:url method:@"POST" data:postData];
    [self sendRequest:request completionHandler:completionHandler];
}

- (void)putToURL:(NSURL *)url jsonRequest:(id)jsonRequest completionHandler:(void (^)(id jsonResponse, NSError *error))completionHandler;
{
    NSError *error = nil;
    NSData *postData = [NSJSONSerialization dataWithJSONObject:jsonRequest options:0 error:&error];
    if (postData == nil) {
        completionHandler(nil, error);
        return;
    }
    NSURLRequest *request = [self createRequestWithURL:url method:@"PUT" data:postData];
    [self sendRequest:request completionHandler:completionHandler];
}

@end
