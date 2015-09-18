

#import <UIKit/UIKit.h>
#import "JSQMessagesInputToolbar.h"
#import <Parse/Parse.h>

@protocol CreateChatroomDelegate <NSObject>

-(void)sendObjectsWithSelectedChatroom:(PFObject *)object andText:(NSString *)text andComment:(NSString *)comment;

@end

@interface CreateChatroomView : UIViewController <UISearchBarDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic,assign) id delegate;

@property (strong, nonatomic) IBOutlet UITableView *tableView;

@property BOOL isTherePicturesToSend;

@end
