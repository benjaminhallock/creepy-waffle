

#import <UIKit/UIKit.h>

#import "MessagesView.h"

#import "NavigationController.h"

#import "MasterScrollView.h"

#import <MessageUI/MessageUI.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, MFMessageComposeViewControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) MasterScrollView *scrollView;
@property (strong, nonatomic) UIViewController *vc;

@property (strong, nonatomic) NavigationController *navInbox;
@property (strong, nonatomic) NavigationController *navCamera;
@end
