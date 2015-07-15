#import "BUGViewController.h"
#import "UIAlertView+Spec.h"
#import "BUGPivotalTrackerInterface+Spec.h"
#import "BUGTrelloInterface+Spec.h"
#import "MBProgressHUD.h"
#import "FLEXManager.h"
#import "BUGInterface.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface BUGViewController (PrivateSpec) <UITextViewDelegate, UITextFieldDelegate>
@property (strong, nonatomic, readwrite) UIWindow *window;
@property (weak, nonatomic, readwrite) UIWindow *originalKeyWindow;
@property (strong, nonatomic, readwrite) id<BUGInterface> interface;
- (void)tapGestureDidRecognize:(UITapGestureRecognizer *)recognizer;
@end

SPEC_BEGIN(BUGViewControllerSpec)

describe(@"BUGViewController", ^{
    __block BUGViewController *controller;
    __block NSData * (^logFileDataBlock)();
    __block NSData *logFileData;
    __block BOOL blockCalled;
    __block UIWindow *originalKeyWindow;
    
    beforeEach(^{
        logFileData = [@"This is a log line" dataUsingEncoding:NSUTF8StringEncoding];
        logFileDataBlock = [^NSData *() {
            blockCalled = YES;
            return logFileData;
        } copy];
        controller = [BUGViewController createSharedInstanceWithLogFileData:logFileDataBlock trackerAPIToken:nil trackerProjectID:nil];
        originalKeyWindow = [UIApplication sharedApplication].keyWindow;
        [[NSUserDefaults standardUserDefaults] setObject:@"Default Name" forKey:@"humbug.requestorsName"];
        [BUGViewController showHideDebugWindow];
        controller.view should_not be_nil;
    });
    
    afterEach(^{
        [[FLEXManager sharedManager] hideExplorer];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"humbug.requestorsName"];
    });
    
    sharedExamplesFor(@"the default view configuration", ^(NSDictionary *sharedContext) {
        it(@"should not have a story title", ^{
            controller.storyTitleTextView.text should equal(@"");
        });
        
        it(@"should not have a story description", ^{
            controller.storyDescriptionTextView.text should equal(@"");
        });
        
        it(@"should have 'Bug Title' as title placeholder text", ^{
            controller.storyTitlePlaceholderLabel.text should equal(@"Bug Title");
        });
        
        it(@"should have 'Bug Description' as title placeholder text", ^{
            controller.storyDescriptionPlaceholderLabel.text should equal(@"Bug Description");
        });
        
        it(@"should set the logs switch to off", ^{
            controller.attachLogsSwitch.on should_not be_truthy;
        });

        it(@"should set the screen shot switch to off", ^{
            controller.attachScreenShotSwitch.on should_not be_truthy;
        });
        
        it(@"should show the requestor's name", ^{
            controller.requestorNameTextField.text should equal([[NSUserDefaults standardUserDefaults] stringForKey:@"humbug.requestorsName"]);
        });
    });
    
    describe(@"sharedInstance", ^{
        __block BUGViewController *controller;

        beforeEach(^{
            controller = [BUGViewController sharedInstance];
        });

        it(@"should return the DebugViewController singleton", ^{
            controller should_not be_nil;
        });
    });
    
    describe(@"showHideDebugWindow", ^{
        context(@"when called when the DegubViewController is already visible", ^{
            beforeEach(^{
                // verifying the initial setup
                originalKeyWindow should_not be_nil;
                originalKeyWindow should_not equal(controller.window);
                controller.window.isHidden should_not be_truthy;
                [UIApplication sharedApplication].keyWindow should equal(controller.window);
                [BUGViewController showHideDebugWindow];
            });
            
            it(@"should hide the DegubViewController", ^{
                controller.window.isHidden should be_truthy;
            });
            
            it(@"should show the original kewWindow", ^{
                controller.originalKeyWindow should equal(originalKeyWindow);
            });
            
            context(@"when called when the window is not visible", ^{
                beforeEach(^{
                    spy_on(originalKeyWindow);
                    [BUGViewController showHideDebugWindow];
                });
                
                it(@"should take a screen shot", ^{
                    originalKeyWindow should have_received(@selector(drawViewHierarchyInRect:afterScreenUpdates:));
                });
                
                it(@"should show the debugViewController", ^{
                    controller.window.isKeyWindow should be_truthy;
                    controller.window.isHidden should_not be_truthy;
                });
            });
        });
    });
    
    describe(@"moving inputs from under the keyboard", ^{
        NSUInteger keyboardHeight = 255;
        __block NSValue *keyboardRectValue;
        __block NSDictionary *userInfo;
        
        beforeEach(^{
            keyboardRectValue = [NSValue valueWithCGRect:CGRectMake(controller.view.frame.size.height - keyboardHeight, 0, 0, keyboardHeight)];
            userInfo = [NSDictionary dictionaryWithObject:keyboardRectValue forKey:UIKeyboardFrameEndUserInfoKey];
            spy_on(controller.scrollView);
        });
        
        describe(@"when selecting an input view", ^{
            beforeEach(^{
                [controller.requestorNameTextField becomeFirstResponder];
                [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:UIKeyboardWillChangeFrameNotification object:nil userInfo:userInfo]];
            });
            
            it(@"should scroll so the input remains visible", ^{
                controller.scrollView.contentInset should equal(UIEdgeInsetsMake(0, 0, keyboardHeight, 0));
                controller.scrollView.scrollIndicatorInsets should equal(UIEdgeInsetsMake(0, 0, keyboardHeight, 0));
                controller.scrollView should have_received(@selector(scrollRectToVisible:animated:));
            });
            
            context(@"when selecting a different input view", ^{
                beforeEach(^{
                    [controller.storyDescriptionTextView becomeFirstResponder];
                });
                
                it(@"should scroll so the new input is visible", ^{
                    controller.scrollView should have_received(@selector(scrollRectToVisible:animated:));
                });
            });
            
            context(@"when deselecting an input view", ^{
                beforeEach(^{
                    [controller.requestorNameTextField resignFirstResponder];
                    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:UIKeyboardWillHideNotification object:nil userInfo:userInfo]];
                });
                
                it(@"should scroll to the top", ^{
                    controller.scrollView.contentInset should equal(UIEdgeInsetsZero);
                    controller.scrollView.scrollIndicatorInsets should equal(UIEdgeInsetsZero);
                });
            });
        });
    });
    
    describe(@"view configuration", ^{
        it(@"should be in a navigationController in a window that sits above all else", ^{
            [(UINavigationController *)controller.window.rootViewController topViewController] should equal(controller);
            controller.window.windowLevel should equal(UIWindowLevelStatusBar);
        });
        
        it(@"should set its title to 'Debug'", ^{
            controller.title should equal(@"Debug");
        });

        it(@"should have a contentView inside a scrollView", ^{
            controller.contentView.superview should equal(controller.scrollView);
        });

        it(@"should have a 'Submit' Button", ^{
            controller.navigationItem.rightBarButtonItem.title should equal(@"Submit");
        });
        
        it(@"should have a 'Cancel' button", ^{
            controller.navigationItem.leftBarButtonItem.title should equal(@"Cancel");
        });
        
        it(@"should have a label indicating the Bugs destination", ^{
            controller.bugDestinationLabel.superview should equal(controller.contentView);
        });
        
        describe(@"story title input views", ^{
            it(@"should have a textView", ^{
                controller.storyTitleTextView.superview should equal(controller.contentView);
            });
            
            it(@"should be the textView's delegate", ^{
                controller.storyTitleTextView.delegate should equal(controller);
            });
            
            it(@"should have 'Bug Title' as placeholder text", ^{
                controller.storyTitlePlaceholderLabel.superview should equal(controller.contentView);
                controller.storyTitlePlaceholderLabel.text should equal(@"Bug Title");
            });
        });
        
        describe(@"story description input views", ^{
            it(@"should have a textView", ^{
                controller.storyDescriptionTextView.superview should equal(controller.contentView);
            });

            it(@"should be the textView's delegate", ^{
                controller.storyTitleTextView.delegate should equal(controller);
            });
            
            it(@"should have 'Bug Description' as placeholder text", ^{
                controller.storyDescriptionPlaceholderLabel.superview should equal(controller.contentView);
                controller.storyDescriptionPlaceholderLabel.text should equal(@"Bug Description");
            });
        });
        
        describe(@"attachments", ^{
            it(@"should have an 'Attachments' label", ^{
                controller.attachmentsLabel.superview should equal(controller.contentView);
            });
            
            describe(@"logs", ^{
                it(@"should have a switch", ^{
                    controller.attachLogsSwitch.superview should equal(controller.contentView);
                });
                
                it(@"should have a 'Logs:' label", ^{
                    controller.logsAttachmentLabel.superview should equal(controller.contentView);
                    controller.logsAttachmentLabel.text should equal(@"Logs:");
                });
            });
            
            describe(@"Screen Shot", ^{
                it(@"should have a switch", ^{
                    controller.attachScreenShotSwitch.superview should equal(controller.contentView);
                });
                
                it(@"should have a 'Screen Shot:' label", ^{
                    controller.screenShotAttachmentLabel.superview should equal(controller.contentView);
                    controller.screenShotAttachmentLabel.text should equal(@"Screen Shot:");
                });
            });
        });
        
        it(@"should have a 'FLEX' switch", ^{
            controller.flexButton.superview should equal(controller.contentView);
        });
        
        it(@"should have a requestor name label", ^{
            controller.requestorNameTextField.superview should equal(controller.contentView);
            controller.requestorNameTextField.placeholder should equal(@"Requestor's Name");
        });
    });
    
    describe(@"when 'Cancel' is tapped", ^{
        sharedExamplesFor(@"when the 'Cancel' button is tapped", ^(NSDictionary *sharedContext) {
            beforeEach(^{
                spy_on(controller.interface);
                controller.attachScreenShotSwitch.on = YES;
                controller.attachScreenShotSwitch.on = YES;
                controller.storyTitleTextView.text = @"A Bug's Life";
                controller.storyDescriptionTextView.text = @"Ants";
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [controller.navigationItem.leftBarButtonItem.target performSelector:controller.navigationItem.leftBarButtonItem.action withObject:nil];
                #pragma clang diagnostic pop
            });
            
            itShouldBehaveLike(@"the default view configuration");
            
            it(@"should hide the controller", ^{
                controller.window.isHidden should be_truthy;
            });
            
            it(@"should tell the interface to cancel", ^{
                controller.interface should have_received(@selector(cancel));
            });
        });
        
        context(@"when initialized for Pivotal Tracker", ^{
            itShouldBehaveLike(@"when the 'Cancel' button is tapped");
        });
        
        context(@"when initialized for Trello", ^{
            beforeEach(^{
                controller = [BUGViewController createSharedInstanceWithLogFileData:logFileDataBlock trackerAPIToken:nil trackerProjectID:nil];
                [BUGViewController showHideDebugWindow];
                controller.view should_not be_nil;
            });
            
            itShouldBehaveLike(@"when the 'Cancel' button is tapped");
        });
    });
    
    describe(@"when a requestor enters their name", ^{
        __block NSString *requestorName;
        
        beforeEach(^{
            requestorName = @"Flik";
            controller.requestorNameTextField.text = requestorName;
            [controller textFieldDidEndEditing:controller.requestorNameTextField];
        });
        
        it(@"should persist the name so they only have to enter it once", ^{
            [[NSUserDefaults standardUserDefaults] stringForKey:@"humbug.requestorsName"] should equal(requestorName);
        });
        
        context(@"when the BugVC is shown again", ^{
            beforeEach(^{
                controller = [BUGViewController createSharedInstanceWithLogFileData:logFileDataBlock trackerAPIToken:nil trackerProjectID:nil];
                originalKeyWindow = [UIApplication sharedApplication].keyWindow;
                [BUGViewController showHideDebugWindow];
                controller.view should_not be_nil;
            });
            
            it(@"should fill in the requestor's name", ^{
                controller.requestorNameTextField.text should equal(requestorName);
            });
        });
    });
    
    describe(@"when 'Submit' is tapped", ^{
        sharedExamplesFor(@"when the 'Submit' button is tapped", ^(NSDictionary *sharedContext) {
            beforeEach(^{
                [BUGPivotalTrackerInterface beginOpaqueTestMode];
                [BUGTrelloInterface beginOpaqueTestMode];
                [controller.storyTitleTextView becomeFirstResponder];
            });
            
            sharedExamplesFor(@"when a create story request completes successfully", ^(NSDictionary *sharedContext) {
                beforeEach(^{
                    [BUGPivotalTrackerInterface completeCreateStoryWithSuccess];
                    [BUGTrelloInterface completeCreateStoryWithSuccess];
                });
                
                it(@"should indicate success with the HUD", ^{
                    [MBProgressHUD HUDForView:controller.view].labelText should equal(@"Success");
                });
                
                itShouldBehaveLike(@"the default view configuration");
                
                it(@"should dismiss the controller", ^{
                    controller.window.isHidden should be_truthy;
                });
                
                it(@"should dismiss the keyboard if visible", ^{
                    controller.storyTitleTextView.isFirstResponder should_not be_truthy;
                });
            });
            
            sharedExamplesFor(@"when a create story request fails", ^(NSDictionary *sharedContext) {
                beforeEach(^{
                    [BUGPivotalTrackerInterface completeCreateStoryWithError:[NSError errorWithDomain:@"Ant Hill" code:0 userInfo:nil]];
                    [BUGTrelloInterface completeCreateStoryWithError:[NSError errorWithDomain:@"Ant Hill" code:0 userInfo:nil]];
                });
                
                it(@"should indicate faliure with the HUD", ^{
                    [MBProgressHUD HUDForView:controller.view].labelText should equal(@"Failed");
                });
                
                it(@"should not reset the view to the default configuration", ^{
                    controller.storyTitleTextView.text should_not equal(@"");
                });
                
                it(@"should not dismiss the controller", ^{
                    controller.window.isHidden should_not be_truthy;
                });
                it(@"should dismiss the keyboard if visible", ^{
                    controller.storyTitleTextView.isFirstResponder should_not be_truthy;
                });
            });
            
            context(@"when a 'Bug Title' has not been added", ^{
                beforeEach(^{
                    spy_on(controller.storyTitleTextView);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [controller.navigationItem.rightBarButtonItem.target performSelector:controller.navigationItem.rightBarButtonItem.action withObject:nil];
#pragma clang diagnostic pop
                });
                
                it(@"should present an alert", ^{
                    [UIAlertView currentAlertView] should_not be_nil;
                    [UIAlertView currentAlertView].title should equal(@"Bugs need names");
                    [UIAlertView currentAlertView].message should equal(@"Please add a descriptive title.");
                    [[UIAlertView currentAlertView] buttonTitleAtIndex:0] should equal(@"OK");
                });
                
                context(@"when the 'OK' button is tapped", ^{
                    beforeEach(^{
                        [[UIAlertView currentAlertView] dismissWithClickedButtonIndex:0 animated:NO];
                    });
                    
                    it(@"should dismiss the alert", ^{
                        [UIAlertView currentAlertView] should be_nil;
                    });
                    
                    it(@"should place the cursor in the 'Bug Title' textView", ^{
                        // does not become first responder until the alert finishes dismissing.
                        controller.storyTitleTextView should have_received("becomeFirstResponder");
                    });
                });
            });
            
            context(@"when a 'Requestor's Name' has not been added", ^{
                beforeEach(^{
                    spy_on(controller.requestorNameTextField);
                    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"humbug.requestorsName"];
                    controller.requestorNameTextField.text = nil;
                    controller.storyTitleTextView.text = @"a story title";
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [controller.navigationItem.rightBarButtonItem.target performSelector:controller.navigationItem.rightBarButtonItem.action withObject:nil];
#pragma clang diagnostic pop
                });
                
                it(@"should present an alert", ^{
                    [UIAlertView currentAlertView] should_not be_nil;
                    [UIAlertView currentAlertView].title should equal(@"Requestor");
                    [UIAlertView currentAlertView].message should equal(@"Please provide your name.");
                    [[UIAlertView currentAlertView] buttonTitleAtIndex:0] should equal(@"OK");
                });
                
                context(@"when the 'OK' button is tapped", ^{
                    beforeEach(^{
                        [[UIAlertView currentAlertView] dismissWithClickedButtonIndex:0 animated:NO];
                    });
                    
                    it(@"should dismiss the alert", ^{
                        [UIAlertView currentAlertView] should be_nil;
                    });
                    
                    it(@"should place the cursor in the 'Requestor's Name' textView", ^{
                        // does not become first responder until the alert finishes dismissing.
                        controller.requestorNameTextField should have_received(@selector(becomeFirstResponder));
                    });
                });
            });
            
            context(@"when a 'Bug Title' and 'Requestor's Name' have been added", ^{
                __block NSString *storyTitle;
                __block NSString *requestorName;
                
                beforeEach(^{
                    spy_on(controller.interface);
                    storyTitle = @"A Bug's Life";
                    controller.storyTitleTextView.text = storyTitle;
                    requestorName = @"Flik";
                    controller.requestorNameTextField.text = requestorName;
                    [controller textFieldDidEndEditing:controller.requestorNameTextField];
                });
                
                context(@"and nothing else", ^{
                    beforeEach(^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [controller.navigationItem.rightBarButtonItem.target performSelector:controller.navigationItem.rightBarButtonItem.action withObject:nil];
#pragma clang diagnostic pop
                    });
                    
                    it(@"should present a HUD", ^{
                        [MBProgressHUD HUDForView:controller.view] should_not be_nil;
                    });
                    
                    it(@"should file the bug with the entered title", ^{
                        controller.interface should have_received(@selector(createStoryWithStoryTitle:storyDescription:image:text:completion:)).with(storyTitle).with(Arguments::any([NSString class])).with(nil).with(nil).with(Arguments::anything);
                    });
                    
                    it(@"should include the requestor's name, the date, and the App version number in the description", ^{
                        NSInvocation *invocation = [(id<CedarDouble>)controller.interface sent_messages][0];
                        NSString *descriptionText;
                        [invocation getArgument:&descriptionText atIndex:3];
                        descriptionText should contain([NSString stringWithFormat:@"Date: %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]]);
                        descriptionText should contain([NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]);
                        descriptionText should contain([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
                        descriptionText should contain([NSString stringWithFormat:@"Requestor: %@", requestorName]);
                    });
                    
                    it(@"should dismiss the keyboard if visible", ^{
                        controller.storyTitleTextView.isFirstResponder should_not be_truthy;
                    });
                    
                    itShouldBehaveLike(@"when a create story request completes successfully");
                    
                    itShouldBehaveLike(@"when a create story request fails");
                    
                });
                
                context(@"and a description has been added", ^{
                    __block NSString *storyDescription;
                    
                    beforeEach(^{
                        storyDescription = @"A description";
                        controller.storyDescriptionTextView.text = storyDescription;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [controller.navigationItem.rightBarButtonItem.target performSelector:controller.navigationItem.rightBarButtonItem.action withObject:nil];
#pragma clang diagnostic pop
                    });
                    
                    it(@"should present a HUD", ^{
                        [MBProgressHUD HUDForView:controller.view] should_not be_nil;
                    });
                    
                    it(@"should file the bug with the entered title", ^{
                        controller.interface should have_received(@selector(createStoryWithStoryTitle:storyDescription:image:text:completion:)).with(storyTitle).with(Arguments::any([NSString class])).with(nil).with(nil).with(Arguments::anything);
                    });
                    
                    it(@"should include the requestor's name, the date, and the App version number in the description", ^{
                        NSInvocation *invocation = [(id<CedarDouble>)controller.interface sent_messages][0];
                        NSString *descriptionText;
                        [invocation getArgument:&descriptionText atIndex:3];
                        descriptionText should contain([NSString stringWithFormat:@"Date: %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]]);
                        descriptionText should contain([NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]);
                        descriptionText should contain([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
                        descriptionText should contain([NSString stringWithFormat:@"Requestor: %@", requestorName]);
                        descriptionText should contain(storyDescription);
                    });
                    
                    it(@"should dismiss the keyboard if visible", ^{
                        controller.storyTitleTextView.isFirstResponder should_not be_truthy;
                    });
                    
                    itShouldBehaveLike(@"when a create story request completes successfully");
                    
                    itShouldBehaveLike(@"when a create story request fails");
                    
                });
                
                context(@"and a the logs switch is on", ^{
                    beforeEach(^{
                        controller.attachLogsSwitch.on = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [controller.navigationItem.rightBarButtonItem.target performSelector:controller.navigationItem.rightBarButtonItem.action withObject:nil];
#pragma clang diagnostic pop
                    });
                    
                    it(@"should present a HUD", ^{
                        [MBProgressHUD HUDForView:controller.view] should_not be_nil;
                    });
                    
                    it(@"should file the bug with the entered title", ^{
                        controller.interface should have_received(@selector(createStoryWithStoryTitle:storyDescription:image:text:completion:)).with(storyTitle).with(Arguments::any([NSString class])).with(nil).with(logFileData).with(Arguments::anything);
                    });
                    
                    it(@"should include the requestor's name, the date, and the App version number in the description", ^{
                        NSInvocation *invocation = [(id<CedarDouble>)controller.interface sent_messages][0];
                        NSString *descriptionText;
                        [invocation getArgument:&descriptionText atIndex:3];
                        descriptionText should contain([NSString stringWithFormat:@"Date: %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]]);
                        descriptionText should contain([NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]);
                        descriptionText should contain([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
                        descriptionText should contain([NSString stringWithFormat:@"Requestor: %@", requestorName]);
                    });
                    
                    it(@"should dismiss the keyboard if visible", ^{
                        controller.storyTitleTextView.isFirstResponder should_not be_truthy;
                    });
                    
                    itShouldBehaveLike(@"when a create story request completes successfully");
                    
                    itShouldBehaveLike(@"when a create story request fails");
                    
                });
                
                context(@"and a the screen shot switch is on", ^{
                    beforeEach(^{
                        controller.attachScreenShotSwitch.on = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                        [controller.navigationItem.rightBarButtonItem.target performSelector:controller.navigationItem.rightBarButtonItem.action withObject:nil];
#pragma clang diagnostic pop
                    });
                    
                    it(@"should present a HUD", ^{
                        [MBProgressHUD HUDForView:controller.view] should_not be_nil;
                    });
                    
                    it(@"should file the bug", ^{
                        controller.interface should have_received(@selector(createStoryWithStoryTitle:storyDescription:image:text:completion:)).with(storyTitle).with(Arguments::any([NSString class])).with(Arguments::anything).with(nil).with(Arguments::anything);
                    });
                    
                    it(@"should include the requestor's name, the date, and the App version number in the description", ^{
                        NSInvocation *invocation = [(id<CedarDouble>)controller.interface sent_messages][0];
                        NSString *descriptionText;
                        [invocation getArgument:&descriptionText atIndex:3];
                        descriptionText should contain([NSString stringWithFormat:@"Date: %@", [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterShortStyle]]);
                        descriptionText should contain([NSString stringWithFormat:@"Version: %@", [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]);
                        descriptionText should contain([[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"]);
                        descriptionText should contain([NSString stringWithFormat:@"Requestor: %@", requestorName]);
                    });
                    
                    it(@"should dismiss the keyboard if visible", ^{
                        controller.storyTitleTextView.isFirstResponder should_not be_truthy;
                    });
                    
                    itShouldBehaveLike(@"when a create story request completes successfully");
                    
                    itShouldBehaveLike(@"when a create story request fails");
                    
                });
            });
        });
        
        context(@"when initialized for Pivotal Tracker", ^{
            itShouldBehaveLike(@"when the 'Submit' button is tapped");
        });
        
        context(@"when initialized for Trello", ^{
            beforeEach(^{
                controller = [BUGViewController createSharedInstanceWithLogFileData:logFileDataBlock trackerAPIToken:nil trackerProjectID:nil];
                [BUGViewController showHideDebugWindow];
                controller.view should_not be_nil;
            });
            
            itShouldBehaveLike(@"when the 'Submit' button is tapped");
        });
    });
    
    describe(@"when the 'FLEX' button is tapped", ^{
        beforeEach(^{
            [controller.flexButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        });
        
        it(@"should display the FLEX view", ^{
            [FLEXManager sharedManager].isHidden should_not be_truthy;
        });
        
        context(@"when the FLEX button is tapped again", ^{
            beforeEach(^{
                [controller.flexButton sendActionsForControlEvents:UIControlEventTouchUpInside];
            });
            
            it(@"should dismiss the FLEX view", ^{
                [FLEXManager sharedManager].isHidden should be_truthy;
            });
        });
    });
    
    describe(@"keyboard dismissal", ^{
        context(@"when a switch is toggled", ^{
            beforeEach(^{
                [controller.storyDescriptionTextView becomeFirstResponder];
                [controller.attachLogsSwitch sendActionsForControlEvents:UIControlEventValueChanged];
            });
            
            it(@"should dismiss the keyboard", ^{
                controller.storyDescriptionTextView.isFirstResponder should_not be_truthy;
            });
        });
        
        context(@"when the view is tapped outside of the textfield", ^{
            beforeEach(^{
                [controller.storyDescriptionTextView becomeFirstResponder];
                [controller tapGestureDidRecognize:nil];
            });
            
            it(@"should dismiss the keyboard", ^{
                controller.storyDescriptionTextView.isFirstResponder should_not be_truthy;
            });
        });
    });
    
    describe(@"placeholder text", ^{
        describe(@"the story title text view", ^{
            context(@"when there is no title", ^{
                beforeEach(^{
                    controller.storyTitleTextView.text should equal(@"");
                });
                
                it(@"should have placeholder text", ^{
                    controller.storyTitlePlaceholderLabel.text should equal(@"Bug Title");
                });
            });
            
            context(@"when a title is entered", ^{
                beforeEach(^{
                    controller.storyTitleTextView.text = @"The wizz does not bang!";
                    [controller textViewDidChange:controller.storyTitleTextView];
                });
                
                it(@"should remove the placeholder text", ^{
                    controller.storyTitlePlaceholderLabel.text should be_nil;
                });
            });
        });
        
        describe(@"the story description text view", ^{
            context(@"when there is no description", ^{
                beforeEach(^{
                    controller.storyDescriptionTextView.text should equal(@"");
                });
                
                it(@"should have placeholder text", ^{
                    controller.storyDescriptionPlaceholderLabel.text should equal(@"Bug Description");
                });
            });
            
            context(@"when a description is entered", ^{
                beforeEach(^{
                    controller.storyDescriptionTextView.text = @"The wizz does not bang!";
                    [controller textViewDidChange:controller.storyDescriptionTextView];
                });
                
                it(@"should remove the placeholder text", ^{
                    controller.storyDescriptionPlaceholderLabel.text should be_nil;
                });
            });
        });
    });
    
    describe(@"text validation", ^{
        __block NSString *longString;
        
        beforeEach(^{
            longString = @"This string is not very long but it is better then nothing.";
        });
        
        context(@"story title validation", ^{
            beforeEach(^{
                while ([longString length] < 5000) {
                    longString = [longString stringByAppendingString:longString];
                }
                controller.storyTitleTextView.text = longString;
                [controller.storyTitleTextView.text length] should be_greater_than(5000);
                [controller textViewDidChange:controller.storyTitleTextView];
            });

            it(@"should only allow titles with no more than 5,000 characters", ^{
                [controller.storyTitleTextView.text length] should equal(5000);
            });
        });
        
        context(@"story description validation", ^{
            beforeEach(^{
                while ([longString length] < 20000) {
                    longString = [longString stringByAppendingString:longString];
                }
                controller.storyDescriptionTextView.text = longString;
                [controller.storyDescriptionTextView.text length] should be_greater_than(20000);
                [controller textViewDidChange:controller.storyDescriptionTextView];
            });
            
            it(@"should only allow descriptions with no more than 20,000 characters", ^{
                [controller.storyDescriptionTextView.text length] should equal(20000);
            });
        });
    });
});

SPEC_END
