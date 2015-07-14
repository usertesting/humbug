#import <Foundation/Foundation.h>

typedef void (^CompletionBlock)(BOOL success, NSError *error);
typedef void (^SessionCompletionHandler)(NSData *data, NSURLResponse *response, NSError *error);
typedef void (^RequestSetupBlock)(NSMutableURLRequest *request);

@protocol BUGInterface <NSObject>

- (void)createStoryWithStoryTitle:(NSString *)title
                 storyDescription:(NSString *)description
                            image:(NSData *)jpegImageData
                             text:(NSData *)textData
                       completion:(CompletionBlock)completion;

- (void)cancel;

@end
