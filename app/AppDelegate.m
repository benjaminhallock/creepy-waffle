
#import <Parse/Parse.h>

#import <ParseUI/ParseUI.h>

//#import <ParseCrashReporting/ParseCrashReporting.h>

#import "ProgressHUD.h"
#import "AppConstant.h"
#import "utilities.h"
#import "UIColor.h"

#import "AppDelegate.h"

#import "ChatroomUsersView.h"
#import "CreateChatroomView.h"
#import "MessagesView.h"
#import "SettingsViewController.h"
#import "CustomCameraView.h"
#import "NavigationController.h"
#import "WelcomeView.h"
#import "RegisterView.h"
#import "LoginView.h"
#import "ChatView.h"

#import "MasterScrollView.h"

#import "MasterLoginRegisterView.h"

#import <QuartzCore/QuartzCore.h>

#import "JCNotificationCenter.h"
#import "JCNotificationBannerPresenterSmokeStyle.h"
#import "JCNotificationBannerPresenterIOS7Style.h"
#import "JCNotificationBannerPresenter.h"

@implementation AppDelegate 

@synthesize scrollView, vc;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

#warning ERROR WHEN LINKING CRASH REPORTING
    //Must come before appidkey, RUN SCRIPT IN BUILD PHASE
//    [ParseCrashReporting enable];

    [Parse setApplicationId:@"elq3rKjkGscvsbeeb21QP0GkuMfuEe3Zb8f3bvcq"
                  clientKey:@"9gXCJTaKXPhPHbG52kGHSzqCIkOSthyToynwl8zq"];
    
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

    [PFUser enableAutomaticUser];

    //Only for pinning data offline
//    [Parse enableLocalDatastore];

//    PFACL *defaultACL = [PFACL new];
    // If you would like all objects to be private by default, remove this line.
//    [defaultACL setPublicReadAccess:true];
//    [PFACL setDefaultACL:defaultACL withAccessForCurrentUser:true];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSendMail:) name:NOTIFICATION_APP_MAIL_SEND object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setCameraBack) name:NOTIFICATION_CAMERA_POPUP object:0];

	if ([application respondsToSelector:@selector(registerUserNotificationSettings:)])
	{
		UIUserNotificationType userNotificationTypes = (UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound);
		UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:userNotificationTypes categories:nil];
		[application registerUserNotificationSettings:settings];
		[application registerForRemoteNotifications];
	}

    [PFImageView class];

/*
#warning REMOVE THIS WHEN SHIPPING, TESTING CRASH
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [NSException raise:NSGenericException format:@"Everything is ok. This is just a test crash."];
    });
*/
    NSUserDefaults *userDefualts = [NSUserDefaults standardUserDefaults];
    
#warning DISABLE FOR APP PRODUCTION
    //Clear the cache of videos.
    /*
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory)
    {
        NSLog(@"%@", file);
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
    [PFQuery clearAllCachedResults];
    */

    if (![userDefualts boolForKey:@"firstRun"])
    {
        [userDefualts setBool:1 forKey:@"firstRun"];
        if (![userDefualts boolForKey:@"logout"])
        {
#warning LOGING OUT USER INCASE OLD VERSION.
            [userDefualts setBool:YES forKey:@"logout"];
            [PFUser logOut];
        }
        [userDefualts setBool:NO forKey:PF_KEY_SHOULDVIBRATE];
        [userDefualts synchronize];
    }

	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor benFamousGreen];

    vc = [[UIViewController alloc] init];
    vc.view.frame = self.window.bounds;
    scrollView = [[MasterScrollView alloc] init];

    scrollView.frame = self.window.bounds;
    [vc.view addSubview:scrollView];
    scrollView.bounces = NO;
    scrollView.pagingEnabled = 1;
    scrollView.scrollEnabled = 1;
    scrollView.directionalLockEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = 0;

//    CustomCameraView *camera = [[CustomCameraView alloc] initWithPopUp:NO];
//    camera.scrollView = scrollView;

    MessagesView *messages = [[MessagesView alloc] init];
    messages.scrollView = scrollView;

    SettingsViewController *settings = [SettingsViewController new];

    NavigationController *settingsNav = [[NavigationController alloc] initWithRootViewController:settings];

     scrollView.contentSize = CGSizeMake(1 * vc.view.frame.size.width, vc.view.frame.size.height);
//    [scrollView setContentOffset:CGPointMake(vc.view.frame.size.width, 0) animated:0];

    self.navInbox = [[NavigationController alloc] initWithRootViewController:messages];

//    self.navCamera = [[NavigationController alloc] initWithRootViewController:camera];

    _navCamera.view.frame = CGRectMake(vc.view.frame.size.width, 0, vc.view.frame.size.width, vc.view.frame.size.height);

    _navInbox.view.frame = CGRectMake(0, 0, vc.view.frame.size.width, vc.view.frame.size.height);

    [_navCamera didMoveToParentViewController:vc];
    [_navInbox didMoveToParentViewController:vc];

    [scrollView addSubview:_navCamera.view];
    [scrollView addSubview:_navInbox.view];

    UITabBarController *tabBar = [[UITabBarController alloc] init];
    tabBar.tabBar.translucent= NO;
    tabBar.tabBar.tintColor = [UIColor benFamousGreen];
    settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Settings" image:[UIImage imageNamed:ASSETS_NEW_SETTINGS] tag:0];
    self.navInbox.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Inbox" image:[UIImage imageNamed:@"Inbox"] tag:1];
    tabBar.viewControllers = [NSArray arrayWithObjects:self.navInbox, settingsNav, nil];

//    self.window.rootViewController = vc;
    self.window.rootViewController = tabBar;
    [self.window makeKeyAndVisible];

    // Parese push notification
    NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];

    if (notificationPayload)
    {
        // Create a pointer to the Photo object
        NSString *roomId = [notificationPayload objectForKey:@"r"];
        PFObject *room = [PFObject objectWithoutDataWithClassName:PF_CHATROOMS_CLASS_NAME
                                                         objectId:roomId];
        // Fetch photo object
        [room fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
            // Show photo view controller
            if (!error && [PFUser currentUser])
            {
                NSString *name = [object valueForKey:PF_CHATROOMS_NAME];
                ChatView *chat = [[ChatView alloc] initWith:object name:name];
#warning SEND TO MESSAGES VIEW (NOT ARCHIVE);
                [scrollView openView:chat];
            }
        }];
    }
	return YES;
}

- (void)setCameraBack
{
#warning TOO SLOW?
    [self performSelector:@selector(setCameraBack2) withObject:self afterDelay:0.5f];
}

- (void)setCameraBack2
{
    _navCamera.view.frame = CGRectMake(0, 0, vc.view.frame.size.width, vc.view.frame.size.height);
    scrollView.contentSize = CGSizeMake(3 * vc.view.frame.size.width, vc.view.frame.size.height);
    [scrollView addSubview:_navCamera.view];
}

- (void)didSendMail:(NSNotification *)notification
{
    NSDictionary *dict = notification.userInfo;
    NSString *string = [dict valueForKey:@"string"];
    NSArray *people = [dict valueForKey:@"people"];

    MFMessageComposeViewController *controller = [[MFMessageComposeViewController alloc] init];
    if([MFMessageComposeViewController canSendText])
    {
        controller.body = string;
        controller.recipients = [NSArray arrayWithArray:people];
        controller.messageComposeDelegate = self;
       [self.vc presentViewController:controller animated:1 completion:0];
    }
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    switch (result) {
        case MessageComposeResultCancelled:
            NSLog(@"Cancelled");
            break;
        case MessageComposeResultFailed:
            NSLog(@"Text Failed");
            break;
        case MessageComposeResultSent:
            NSLog(@"Text Sent");
            break;
        default:
            break;
    }
    [self.vc dismissViewControllerAnimated:1 completion:0];
}


- (void)applicationWillResignActive:(UIApplication *)application

{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    PFInstallation *currentInstallation = [PFInstallation currentInstallation];
    if (currentInstallation.badge != 0) {
        currentInstallation.badge = 0;
        [currentInstallation saveEventually];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0;
            [currentInstallation saveEventually];
        }
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
    if ([_navInbox.viewControllers.lastObject isKindOfClass:[ChatView class]])
    {
        PostNotification(NOTIFICATION_REFRESH_CHATROOM);
    }
}

#pragma mark - Push notification methods

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	PFInstallation *currentInstallation = [PFInstallation currentInstallation];
	[currentInstallation setDeviceTokenFromData:deviceToken];
        currentInstallation.channels = @[@"global"];
	[currentInstallation saveInBackground];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	NSLog(@"didFailToRegisterForRemoteNotificationsWithError %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{

    BOOL didJustOpenFromBackground = NO;

    //Tracking Push Notifications open and stuff
    if (application.applicationState == UIApplicationStateInactive) {
        didJustOpenFromBackground = YES;
        [PFAnalytics trackAppOpenedWithRemoteNotificationPayload:userInfo];
    }

//IF APPLICATION IS ACTIVE>
    NSLog(@"%@", userInfo); // ADD CHATROOM ID IN THIS TO CREATE NEW CHATROOM AND OPEN IT IN BACKGROUND.
//        [PFPush handlePush:userInfo]; // SEND AN ALERT IN APP

    NSString *alertText = [[userInfo objectForKey:@"aps"] objectForKey:@"alert"];

    if ([userInfo objectForKey:@"r"])
    {
    NSString *roomId = [userInfo objectForKey:@"r"];
    PFObject *room = [PFObject objectWithoutDataWithClassName:PF_CHATROOMS_CLASS_NAME
                                                            objectId:roomId];

    //Need to download new message if it exists.
    PostNotification(NOTIFICATION_REFRESH_INBOX);
        
    [room fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        // Show photo view controller
        if (error)
        {
            NSLog(@"%@ Push Error", error.userInfo);
            completionHandler(UIBackgroundFetchResultFailed);
        }
        //Irrelevant but acceptable
        else if ([PFUser currentUser])
        {
        if ([scrollView checkIfCurrentChatIsEqualToRoom:roomId didComeFromBackground:didJustOpenFromBackground])
            {
                //SAME CHATROOOM
                PostNotification(NOTIFICATION_REFRESH_CHATROOM);
            }
            else
            {
            ChatView *chat = [[ChatView alloc] initWith:room name:[room valueForKey:PF_CHATROOMS_NAME]];

            if (application.applicationState == UIApplicationStateActive && !didJustOpenFromBackground)
            {
                NSString* title = @"New Message!";

                NSUserDefaults *userDefualts = [NSUserDefaults standardUserDefaults];

                if ([userDefualts boolForKey:PF_KEY_SHOULDVIBRATE])
                {
                    [JSQSystemSoundPlayer jsq_playMessageReceivedAlert];
                }
                else
                {
                    [JSQSystemSoundPlayer jsq_playMessageReceivedSound];
                }

                [JCNotificationCenter sharedCenter].presenter = [JCNotificationBannerPresenterIOS7Style new];

                if (scrollView.contentOffset.x)
                {
                NSLog(@"IN APP NOTIFICATION");

                if (![UIApplication sharedApplication].isStatusBarHidden)
                {
                [JCNotificationCenter enqueueNotificationWithTitle:title
                                                           message:alertText
                                                        tapHandler:^{

                //Dismiss Modal Views
                PostNotification(NOTIFICATION_CLICKED_PUSH);

                [scrollView openView:chat];
                }];
                }
                }

            }
            else
            {
                [scrollView openView:chat];
            }
        }

            completionHandler(UIBackgroundFetchResultNewData);
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
    }
}

@end
