#import <UIKit/UIKit.h>

@interface BUGViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *bugDestinationLabel;
@property (weak, nonatomic) IBOutlet UITextView *storyTitleTextView;
@property (weak, nonatomic) IBOutlet UITextView *storyDescriptionTextView;
@property (weak, nonatomic) IBOutlet UILabel *attachmentsLabel;
@property (weak, nonatomic) IBOutlet UILabel *logsAttachmentLabel;
@property (weak, nonatomic) IBOutlet UILabel *screenShotAttachmentLabel;
@property (weak, nonatomic) IBOutlet UISwitch *attachLogsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *attachScreenShotSwitch;
@property (weak, nonatomic) IBOutlet UIButton *flexButton;
@property (weak, nonatomic) IBOutlet UILabel *storyTitlePlaceholderLabel;
@property (weak, nonatomic) IBOutlet UILabel *storyDescriptionPlaceholderLabel;
@property (weak, nonatomic) IBOutlet UITextField *requestorNameTextField;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

+ (instancetype)createSharedInstanceWithLogFileData:(NSData * (^)())logData trackerAPIToken:(NSString *)token trackerProjectID:(NSString *)projectID;
+ (instancetype)createSharedInstanceWithLogFileData:(NSData * (^)())logData trelloAppKey:(NSString *)appKey trelloAuthToken:(NSString *)authToken trelloListID:(NSString *)listID;
+ (instancetype)sharedInstance;

+ (void)showHideDebugWindow;

@end
