#import <Foundation/Foundation.h>

%hook TUDialRequest
- (void)performViaRelay {
    %log;
    %orig;
}
%end
