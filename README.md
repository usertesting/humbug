humbug
======

A self-contained widget you can add to any iOS project that provides Trello or Pivotal Tracker integration and [FLEX](https://github.com/Flipboard/FLEX) debugging tools. Include it in beta builds to see consistent bug reports with logs and screen shots from your testers.

![Screenshot](https://github.com/upstartmobile/humbug/blob/master/Readme/screenshot.png?raw=true)

### Installation
Requires iOS 7 and later

* clone the repository.
* cd into the humbug folder and run git submodule init and git submodule update to pull down the dependencies.
* Drag the 'App' folder into your project.
* Drag Externals/FLEX/Classes and Externals/MBProgressHUD/MBProgressHUD.h/.m into your project if necessary.
* Link against libz.dylib (used to compress log files).
* Initialize the BUGViewController by passing in
	* Your Trello appKey, authToken, listID, and optionally a block that returns your logs as a NSData.
	* Your pivotal tracker api token, project ID, and optionally a block that returns your logs as a NSData.

######Trello Info
Your __Trello Key__ can be found by logging into Trello and then visiting [https://trello.com/app-key](https://trello.com/app-key).

To obtain an read/write/never expire __Auth Token__ subsititue your Trello Key into this URL and then visit it in your web browser:

	https://trello.com/1/authorize?key=TRELLO_KEY&name=Humbug&expiration=never&response_type=token&scope=read,write

The location of filed bugs is specified by the listID you provide. Getting the __ListID__ is a two step process. First get the list of all the boards you belong to by visiting this URL:

	https://api.trello.com/1/members/me/boards?key=TRELLO_KEY&token=AUTH_TOKEN

That list will contain the IDs for all of the boards you belong to. Find the board ID for the board that contains the list that you want your bugs to be filed in. Enter that ID into this URL:

	https://api.trello.com/1/boards/BOARD_ID/lists?key=TRELLO_KEY&token=AUTH_TOKEN

######Pivotal Tracker Info
Your [Pivotal Tracker API Token](https://www.pivotaltracker.com/faq#wherecanifindmyapitoken) can be found at the bottom of your Pivotal Tracker 'Profile' page. Your Pivotal Tracker Project ID is the number in the URL for you Tracker project's page (https://www.pivotaltracker.com/n/projects/123456).

######Excluding Humbug From AppStore Builds
humbug should only be included in non-AppStore builds as FLEX will cause an AppStore rejection. To exclude the files from your AppStore builds:

* Go to your project's build settings and click 'Add User-Defined Setting'. Name the settings key ```EXCLUDED_SOURCE_FILE_NAMES``` then, for your release configuration, add ```FLEX* BUG* UIWindow+BUG*``` as its value. 
* Wrap all Humbug file imports and method calls in a #if DEBUG check:

```objc
#ifdef DEBUG
	#import "BUGViewController.h"
	#import "DDFileLogger.h"
#endif

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    #ifdef DEBUG
    [BUGViewController createSharedInstanceWithLogFileData:^NSData *{
        DDFileLogger *fileLogger;
        for (id logger in Flywheel.sharedInstance.loggers) {
            if ([logger isKindOfClass:[DDFileLogger class]]) {
                fileLogger = logger;
            }
        }
        NSData *fileData;
        if ([fileLogger.logFileManager sortedLogFilePaths].count) {
            fileData = [NSData dataWithContentsOfFile:[fileLogger.logFileManager sortedLogFilePaths][0]];
        }
        return fileData;
    } trackerAPIToken:@"your-pivotal-tracker-api-token" trackerProjectID:@"your-project-id"];
    #endif
}
```

### Usage
Once initialized, humbug can be activated out of the box by shaking your device or by calling ```[BUGViewController showHideDebugViewController]```.
If you would like to disable the 'shake to reveal humbug' feature, just remove "UIWindow+BUG.m" from your apps' compile sources.

### Contributing 
Pull requests welcome. Please add tests where appropriate.

### Maintainers
* [Matt Edmonds](mailto:matthewedmonds@me.com) ([github](https://github.com/medmonds)), UserTesting, San Francisco

### Dependencies

* [FLEX](https://github.com/Flipboard/FLEX) - in-app debugging tool from Flipboard
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - The HUD used by everyone
 
### Tests

To run the Cedar tests, select the Specs target and run under the iOS 7.1 simulator.

### Disclaimers
This software has and will continue to be modified from its original form.

Copyright (c) 2014 Flywheel Software. This software is licensed under the GPL v2.0 license. 

