#import "BUGTrelloInterface.h"

@interface BUGTrelloInterface (Spec)

+ (void)beginOpaqueTestMode;
+ (void)endOpaqueTestMode;

+ (void)completeCreateStoryWithSuccess;
+ (void)completeCreateStoryWithError:(NSError *)error;

@end
