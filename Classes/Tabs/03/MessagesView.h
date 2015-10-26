
#import "AppConstant.h"

@interface MessagesView : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property  NSMutableArray *messages;
@property NSMutableArray *messagesObjectIds;
@property UIScrollView *scrollView;
@property bool isSelectingChatroomForPhotos;
- (void)loadInbox;
- (void)refreshMessages;
@end

