

#import "AppConstant.h"

@interface MasterScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

-(id) init;

-(void)openView:(UIViewController *)view2;

- (BOOL) checkIfCurrentChatIsEqualToRoom:(NSString *)roomId didComeFromBackground:(BOOL)isBack;

@property NavigationController *navInbox;

@end
