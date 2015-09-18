

#import <UIKit/UIKit.h>

#import "NavigationController.h"

@interface MasterScrollView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate>

-(id) init;

-(void)openView:(UIViewController *)view2;

- (BOOL) checkIfCurrentChatIsEqualToRoom:(NSString *)roomId didComeFromBackground:(BOOL)isBack;

@end
