
#import "AppConstant.h"


@interface VerifyTextView : UITableViewController <UITextFieldDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) NSDate *lastTextDate;

@property NSString *phoneNumber;

@property NSString *password;

@property PFUser *user;

@property BOOL isLoggingIn;

@end
