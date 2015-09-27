

#import "AppConstant.h"
#import "NavigationController.h"
#import <MessageUI/MessageUI.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MFMessageComposeViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

//@property (strong, nonatomic) MasterScrollView *scrollView;
//@property (strong, nonatomic) UIViewController *vc;

@property (strong, nonatomic) NavigationController *navInbox;
@property (strong, nonatomic) NavigationController *navCamera;
@property UITabBarController *tabBar;
@end
