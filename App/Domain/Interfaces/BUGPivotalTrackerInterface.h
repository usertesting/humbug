#import <Foundation/Foundation.h>
#import "BUGInterface.h"

@interface BUGPivotalTrackerInterface : NSObject <BUGInterface>

- (instancetype)initWithAPIToken:(NSString *)token trackerProjectID:(NSString *)projectID;

@end
