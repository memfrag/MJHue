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

#import "MJHueBridgeBrowser.h"
#import "MJHueBridge.h"
#import "MJRESTClient.h"
#import "MJDOMParser.h"
#import "MJHTTPHeaderParser.h"

@implementation MJHueBridgeBrowser {
    MJRESTClient *_restClient;
    GCDAsyncUdpSocket *_ssdpSocket;
    NSOperationQueue *_queue;
    NSMutableDictionary *_searchCache;
}

- (id)init
{
    self = [super init];
    if (self) {
        _restClient = [[MJRESTClient alloc] init];
        _queue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (void)search
{
    [self searchREST];
}

- (void)searchUsingSSDPOnly
{
    [self searchSSDP];
}

- (void)stop
{
    if (_ssdpSocket) {
        [_ssdpSocket close];
        _ssdpSocket = nil;
    }
}

- (void)searchREST
{
    NSURL *url = [NSURL URLWithString:@"https://www.meethue.com/api/nupnp"];
    [_restClient getFromURL:url
          completionHandler:^(id jsonResponse, NSError *error) {
              NSArray *entries = (NSArray *)jsonResponse;
              if (entries && entries.count > 0) {
                  for (NSDictionary *entry in entries) {
                      NSString *hueId = entry[@"id"];
                      NSString *ip = entry[@"internalipaddress"];
                      NSString *urlString = [@"http://" stringByAppendingFormat:@"%@:80/", ip];
                      NSURL *baseUrl = [NSURL URLWithString:urlString];
                      NSString *name = [NSString stringWithFormat:@"Philips hue (%@)", ip];
                      
                      MJHueBridge *hueBridge = [[MJHueBridge alloc] initWithHueId:hueId name:name url:baseUrl];
                      
                      if (self.delegate
                          && [self.delegate respondsToSelector:@selector(hueBridgeBrowser:didFindHueBridge:)]) {
                          [self.delegate hueBridgeBrowser:self didFindHueBridge:hueBridge];
                      }
                  }
              } else {
                  [self searchSSDP];
              }
          }];
}

- (void)searchSSDP
{
    _searchCache = [NSMutableDictionary dictionaryWithCapacity:10];
    
    _ssdpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    
    if (![_ssdpSocket bindToPort:0 error:&error]) {
        NSLog(@"Error binding: %@", error.description);
        return;
    }
    
    if (![_ssdpSocket beginReceiving:&error]) {
        NSLog(@"Error receiving: %@", error.description);
        return;
    }
    
    [_ssdpSocket enableBroadcast:YES error:&error];
    if (error) {
        NSLog(@"Error enabling broadcast: %@", error.description);
        return;
    }

    NSString *msg = @"M-SEARCH * HTTP/1.1\r\n"
        @"Host: 239.255.255.250:1900\r\n"              // SSDP multicast address
        @"Man: ssdp:discover\r\n"                      // Packet type
        @"MX: 3\r\n"                                   // Seconds to wait for response
        @"ST: urn:schemas-upnp-org:device:Basic:1\r\n" // Service type
        @"\r\n";
    NSData *msgData = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [_ssdpSocket sendData:msgData toHost:@"239.255.255.250" port:1900 withTimeout:-1 tag:0];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (message) {
        
        MJHTTPHeaderParser *headerParser = [[MJHTTPHeaderParser alloc] init];
        NSDictionary *headers = [headerParser parseHTTPHeaders:message];
        
        if (![headers[@"ST"] isEqualToString:@"urn:schemas-upnp-org:device:basic:1"]) {
            return;
        }
        
        NSString *usn = headers[@"USN"];
        if (_searchCache[usn]) {
            // Duplicate
            return;
        } else {
            //NSLog(@"\n%@\n", message);

            _searchCache[usn] = headers;
        }
        
        NSURL *url = [NSURL URLWithString:headers[@"LOCATION"]];
        
        //NSLog(@"URL: %@", url);
        
        [self getFromURL:url completionHandler:^(NSData *xmlResponse, NSError *error) {
            if (xmlResponse) {
                //NSLog(@"\n%@\n", [[NSString alloc] initWithData:xmlResponse encoding:NSUTF8StringEncoding]);
                MJDOMParser *domParser = [[MJDOMParser alloc] init];
                id<MJDOMDocument> document = [domParser parseXML:xmlResponse];
                
                id<MJDOMNode> friendlyNameNode = [document nodeAtPath:@"root/device/friendlyName/#text"];
                NSString *name = friendlyNameNode.nodeValue;
                
                id<MJDOMNode> serialNumberNode = [document nodeAtPath:@"root/device/serialNumber/#text"];
                NSString *hueId = serialNumberNode.nodeValue;
                
                id<MJDOMNode> baseUrlNode = [document nodeAtPath:@"root/URLBase/#text"];
                NSString *baseUrlString = baseUrlNode.nodeValue;
                NSURL *baseUrl = [NSURL URLWithString:baseUrlString];
                
                MJHueBridge *hueBridge = [[MJHueBridge alloc] initWithHueId:hueId name:name url:baseUrl];

                if (self.delegate
                    && [self.delegate respondsToSelector:@selector(hueBridgeBrowser:didFindHueBridge:)]) {
                    [self.delegate hueBridgeBrowser:self didFindHueBridge:hueBridge];
                }
                
            } else {
                NSLog(@"Error: %@", [error localizedDescription]);
            }
        }];
    }
}

- (void)sendRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *xmlResponse, NSError *error))completionHandler {
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:_queue
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                               if (error == nil) {
                                   completionHandler(data, error);
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

- (void)getFromURL:(NSURL *)url completionHandler:(void (^)(NSData *xmlResponse, NSError *error))completionHandler
{
    NSURLRequest *request = [self createRequestWithURL:url method:@"GET" data:nil];
    [self sendRequest:request completionHandler:completionHandler];
}


@end
