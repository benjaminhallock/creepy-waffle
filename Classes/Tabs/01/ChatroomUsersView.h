
#import <UIKit/UIKit.h>

@interface ChatroomUsersView : UITableViewController <UIAlertViewDelegate>

- (id)initWithRoom:(PFObject *)room AndMessage:(PFObject *)message;

- (void)showActionSheet;

@end
