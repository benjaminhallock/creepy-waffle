
#import "AppConstant.h"
#import "MasterScrollView.h"

@interface MessagesView : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UITextFieldDelegate, UIAlertViewDelegate>

@property NSArray *savedPhotos;
@property  NSMutableArray *messages;
@property NSMutableArray *messagesObjectIds;
@property bool isSelectingChatroomForPhotos;
@property (strong, nonatomic) MasterScrollView *scrollView;

- (void)loadInbox;
- (void)refreshMessages;

@end

