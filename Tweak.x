#import <Foundation/Foundation.h>

@interface TUDialRequest : NSObject
@property (nonatomic, copy) NSString *handle;
@property (nonatomic, assign, getter=isRelayCall) BOOL relayCall;
@property (nonatomic, assign) int service;
@end

%hook TUDialRequest

- (void)setRelayCall:(BOOL)arg1 {
    // Aramanın her zaman relay (aktarılan arama) olarak işaretlenmesini zorla
    %orig(YES);
}

- (void)setService:(int)arg1 {
    // Servis türünü hücresel yerine relay/uzak arama olarak zorla
    %orig(2); 
}

%end
