#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// TelephonyUtilities Arayüz Tanımlamaları
@interface TUHandle : NSObject
+ (id)handleWithDestinationID:(NSString *)destinationID;
@end

@interface TUDialRequest : NSObject
@property (nonatomic, copy) NSString *bundleIdentifier;
@property (nonatomic, retain) TUHandle *handle;
- (id)initWithService:(long long)service handle:(TUHandle *)handle;
- (void)setDialType:(NSInteger)arg1;
@end

@interface TUCallCenter
+ (id)sharedInstance;
- (id)dialWithRequest:(TUDialRequest *)request;
@end

static NSString *const kSecretToken = @"MertSecretToken123"; // Güvenlik Şifreniz

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[GSMRouter] SpringBoard ici HTTP dinleyicisi baslatiliyor...");
        
        CFSocketContext context = {0, (__bridge void *)[NSThread currentThread], NULL, NULL, NULL};
        CFSocketRef s = CFSocketCreate(
            kCFAllocatorDefault,
            PF_INET,
            SOCK_STREAM,
            IPPROTO_TCP,
            kCFSocketAcceptCallBack,
            (CFSocketCallBack)ServerAcceptCallback,
            &context
        );
        
        if (s) {
            struct sockaddr_in addr;
            memset(&addr, 0, sizeof(addr));
            addr.sin_len = sizeof(addr);
            addr.sin_family = AF_INET;
            addr.sin_port = htons(8088);
            addr.sin_addr.s_addr = htonl(INADDR_LOOPBACK); // Sadece yerel baglanti (127.0.0.1)
            
            NSData *addressData = [NSData dataWithBytes:&addr length:sizeof(addr)];
            CFSocketSetAddress(s, (__bridge CFDataRef)addressData);
            
            CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(NULL, s, 0);
            CFRunLoopAddSource(CFRunLoopGetMain(), source, kCFRunLoopDefaultMode);
            CFRelease(source);
            NSLog(@"[GSMRouter] 127.0.0.1:8088 portunda dinlemede.");
        }
    });
}

static void ServerAcceptCallback(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
    if (type == kCFSocketAcceptCallBack) {
        int nativeSocket = *(int *)data;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            char buffer[1024] = {0};
            recv(nativeSocket, buffer, sizeof(buffer) - 1, 0);
            NSString *requestString = [NSString stringWithUTF8String:buffer];
            
            int statusCode = 404;
            NSString *responseBody = @"{\"status\":\"not_found\"}";
            
            if ([requestString containsString:@"POST /dial"] || [requestString containsString:@"GET /dial"]) {
                BOOL authorized = [requestString containsString:[NSString stringWithFormat:@"Authorization: Bearer %@", kSecretToken]];
                
                if (!authorized) {
                    statusCode = 401;
                    responseBody = @"{\"error\":\"unauthorized\"}";
                } else {
                    // İLK TEST İÇİN 'YES' KALSIN (Sadece loglar, arama yapmaz). 
                    // Test başarılı olduktan sonra 'NO' yapıp gerçek arama yaptırabilirsiniz.
                    BOOL testMode = YES; 
                    
                    NSString *number = nil;
                    NSRange range = [requestString rangeOfString:@"number="];
                    if (range.location != NSNotFound) {
                        NSUInteger start = range.location + range.length;
                        NSUInteger end = start;
                        while (end < [requestString length] && [requestString characterAtIndex:end] != ' ' && [requestString characterAtIndex:end] != '&' && [requestString characterAtIndex:end] != '\r') {
                            end++;
                        }
                        number = [requestString substringWithRange:NSMakeRange(start, end - start)];
                        number = [number stringByRemovingPercentEncoding];
                    }
                    
                    if (number && [number length] > 0) {
                        NSLog(@"[GSMRouter] Hedef Numara Alindi: %@", number);
                        
                        if (testMode) {
                            statusCode = 200;
                            responseBody = [NSString stringWithFormat:@"{\"status\":\"test_success\",\"number\":\"%@\"}", number];
                        } else {
                            // Gerçek GSM Arama Başlatma Komutu
                            dispatch_async(dispatch_get_main_queue(), ^{
                                Class TUHandleClass = objc_getClass("TUHandle");
                                Class TUDialRequestClass = objc_getClass("TUDialRequest");
                                Class TUCallCenterClass = objc_getClass("TUCallCenter");
                                
                                if (TUHandleClass && TUDialRequestClass && TUCallCenterClass) {
                                    id handle = [TUHandleClass handleWithDestinationID:number];
                                    id dialRequest = [[TUDialRequestClass alloc] initWithService:1 handle:handle]; // 1 = GSM Hücresel
                                    [dialRequest setDialType:0];
                                    
                                    id callCenter = [TUCallCenterClass sharedInstance];
                                    [callCenter dialWithRequest:dialRequest];
                                    NSLog(@"[GSMRouter] GSM Arama Basariyla Tetiklendi: %@", number);
                                }
                            });
                            
                            statusCode = 200;
                            responseBody = [NSString stringWithFormat:@"{\"status\":\"dialing\",\"number\":\"%@\"}", number];
                        }
                    } else {
                        statusCode = 400;
                        responseBody = @"{\"error\":\"missing_number\"}";
                    }
                }
            }
            
            NSString *httpResponse = [NSString stringWithFormat:
                @"HTTP/1.1 %d OK\r\nContent-Type: application/json\r\nContent-Length: %lu\r\nConnection: close\r\n\r\n%@",
                statusCode, (unsigned long)[responseBody lengthOfBytesUsingEncoding:NSUTF8StringEncoding], responseBody];
            
            write(nativeSocket, [httpResponse UTF8String], [httpResponse lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
            close(nativeSocket);
        });
    }
}
