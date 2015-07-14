#import <Foundation/Foundation.h>
#import "BUGInterface.h"

@interface BUGTrelloInterface : NSObject <BUGInterface>

- (instancetype)initWithAppKey:(NSString *)appKey authToken:(NSString *)authToken listID:(NSString *)listID;

@end
