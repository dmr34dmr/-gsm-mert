#import <Foundation/Foundation.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>

// Apple'ın dahili arama yöneticisi için arayüz tanımı
@interface CTCallServer : NSObject
+ (id)sharedCallServer;
- (bool)connectToPhoneNumber:(NSString *)phoneNumber;
@end

// Gelen çağrı ve yönlendirme kancası (Hook)
%hook CTCallServer

- (bool)connectToPhoneNumber:(NSString *)phoneNumber {
    NSLog(@"[GSMBridge] iPhone 15'ten gelen arama isteği yakalandı: %@", phoneNumber);
    
    // İstek geldiğinde iPhone 6S hattı üzerinden aramayı tetikle
    bool result = %orig(phoneNumber);
    return result;
}

%end
