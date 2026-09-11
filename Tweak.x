#import <Foundation/Foundation.h>

@interface TUDialRequest
@end

%hook TUDialRequest
- (void)performViaRelay {
    %log;
    %orig;
}
%end
