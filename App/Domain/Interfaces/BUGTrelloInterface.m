#import "BUGTrelloInterface.h"
#import "NSData+BUGCompression.h"

@interface BUGTrelloInterface ()
@property (strong, nonatomic, readwrite) NSString *appKey;
@property (strong, nonatomic, readwrite) NSString *authToken;
@property (strong, nonatomic, readwrite) NSString *listID;
@property (strong, nonatomic, readwrite) CompletionBlock createStoryCompletion;
@property (assign, nonatomic, readwrite) NSInteger pendingUploads;
@end

static NSString const *basePath = @"https://api.trello.com/1";

@implementation BUGTrelloInterface

- (instancetype)initWithAppKey:(NSString *)appKey authToken:(NSString *)authToken listID:(NSString *)listID {
    if (self = [super init]) {
        self.appKey = appKey;
        self.authToken = authToken;
        self.listID = listID;
    }
    return self;
}

- (void)createStoryWithStoryTitle:(NSString *)title storyDescription:(NSString *)description image:(NSData *)jpegImageData text:(NSData *)textData completion:(CompletionBlock)completion {
    [self prepareForNewStory];
    
    self.createStoryCompletion = completion;
    __weak __typeof(self)weakSelf = self;
    [self createCardWithTitle:title description:description completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if ([(NSHTTPURLResponse *)response statusCode] / 100 != 2) {
            [weakSelf completeWithSuccess:NO error:error];
            return;
        }
        
        NSError *jsonError;
        NSDictionary *cardDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        if (!jsonError) {
            NSString *cardID = cardDictionary[@"id"];
            [weakSelf attachImageData:jpegImageData toCardWithID:cardID];
            [weakSelf attachTextData:textData toCardWithID:cardID];
        }
    }];
}

- (void)cancel {
    [[NSURLSession sharedSession] getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        [dataTasks makeObjectsPerformSelector:@selector(cancel)];
        [uploadTasks makeObjectsPerformSelector:@selector(cancel)];
    }];
}

#pragma mark - Private

- (void)prepareForNewStory {
    self.pendingUploads = 0;
    self.createStoryCompletion = nil;
}

- (void)createCardWithTitle:(NSString *)title description:(NSString *)description completionHandler:(SessionCompletionHandler)completion {
    NSDictionary *jsonDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                    @"top", @"pos",
                                    [NSNull null], @"due",
                                    [NSNull null], @"urlSource",
                                    self.listID, @"idList",
                                    title, @"name",
                                    description, @"desc",
                                    nil];
    
    NSURLSessionTask *task = [self dataTaskForPath:@"cards" withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *body = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:nil] encoding:NSUTF8StringEncoding];
        [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    } completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (completion) { completion(data, response, error); }
    }];
    
    [task resume];
}

- (void)attachImageData:(NSData *)image toCardWithID:(NSString *)cardID {
    if (!image) {
        [self dataUploadDidComplete];
        return;
    }
    
    self.pendingUploads ++;
    
    NSURLSessionTask *task = [self dataTaskForPath:[NSString stringWithFormat:@"cards/%@/attachments", cardID] withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *boundary = @"ThisIsTheBoundary";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        NSString *fileName = @"screenshot.png";
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding: NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:image];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:body];
    } completionHandler:[self uploadCompletionHandler]];
    
    [task resume];
}

- (void)attachTextData:(NSData *)textData toCardWithID:(NSString *)cardID {
    if (!textData) {
        [self dataUploadDidComplete];
        return;
    }
    
    self.pendingUploads ++;
    textData = [textData gzipDeflate];
    
    NSURLSessionTask *uploadTask = [self dataTaskForPath:[NSString stringWithFormat:@"cards/%@/attachments", cardID] withRequestSetup:^(NSMutableURLRequest *request) {
        NSString *boundary = @"ThisIsTheBoundary";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        NSMutableData *body = [NSMutableData data];
        NSString *dateString = [[NSDate date] description];
        dateString = [dateString substringToIndex:dateString.length - 6];
        NSString *fileName = [NSString stringWithFormat:@"log - %@.txt", dateString];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n",boundary] dataUsingEncoding: NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n",fileName] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: text/plain\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:textData];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPBody:body];
    } completionHandler:[self uploadCompletionHandler]];
    
    [uploadTask resume];
}

- (SessionCompletionHandler)uploadCompletionHandler {
    return [^(NSData *data, NSURLResponse *response, NSError *error) {
        self.pendingUploads --;
        [self dataUploadDidComplete];
    } copy];
}

- (void)dataUploadDidComplete {
    if (self.pendingUploads) {
        return;
    }
    
    if (self.createStoryCompletion) {
        [self completeWithSuccess:YES error:nil];
    }
}

- (void)completeWithSuccess:(BOOL)success error:(NSError *)error {
    if (self.createStoryCompletion) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.createStoryCompletion(success, error);
        });
    }
}

- (NSURLSessionTask *)dataTaskForPath:(NSString *)path withRequestSetup:(RequestSetupBlock)requestSetup completionHandler:(SessionCompletionHandler)completionHandler {
    NSMutableURLRequest *request = [self requestForPath:path];
    [request setHTTPMethod:@"POST"];
    
    if (requestSetup) {
        requestSetup(request);
    }
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completionHandler];
    return task;
}

- (NSMutableURLRequest *)requestForPath:(NSString *)path {
    return [[NSMutableURLRequest alloc] initWithURL:[self urlForPath:path]];
}

- (NSURL *)urlForPath:(NSString *)path {
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@?key=%@&token=%@", basePath, path, self.appKey, self.authToken]];
}

@end
