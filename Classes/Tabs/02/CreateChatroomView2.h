

#import <UIKit/UIKit.h>

@protocol CreateChatroom2Delegate <NSObject>

-(void)sendBackArrayOfPhoneNumbers:(NSMutableArray *)array  andDidPressSend:(BOOL)send andText:(NSString *)text;

@end

@interface CreateChatroomView2 : UIViewController <UISearchBarDelegate, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (nonatomic,assign) id delegate;
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property BOOL isTherePicturesToSend;
@property (strong, nonatomic)  NSMutableDictionary *arrayOfNamesAndNumbers;
@property (strong, nonatomic) NSMutableArray *arrayofSelectedPhoneNumbers;
@property (strong, nonatomic) NSString *textForComment;
@end
