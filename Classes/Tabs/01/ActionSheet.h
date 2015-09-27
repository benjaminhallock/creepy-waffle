
#import "AppConstant.h"

@interface ActionSheet : UITableViewController <UIAlertViewDelegate>

- (id)initWithRoom:(PFObject *)room AndMessage:(PFObject *)message;
- (void)showActionSheetWithDelegate:(UIViewController *)view;
@property UIViewController *viewDelegate;

@end
