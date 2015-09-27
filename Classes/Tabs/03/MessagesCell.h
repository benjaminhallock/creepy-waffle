#import "AppConstant.h"

@interface MessagesCell : UITableViewCell

- (void)bindData:(PFObject *)message_;
- (void)format;
@property (strong, nonatomic) IBOutlet UILabel *labelDescription;
@property (strong, nonatomic) IBOutlet UILabel *labelLastMessage;
@property (strong, nonatomic) IBOutlet UILabel *labelElapsed;

@property (strong, nonatomic) IBOutlet UILabel *labelNumberOfPeople;

@property IBOutlet UIImageView *contactsPeople;

@property (strong, nonatomic) IBOutlet UILabel *labelCounter;
@property (strong, nonatomic) IBOutlet PFImageView *imageUser;
@property (weak, nonatomic) IBOutlet UILabel *labelInitials;
@property (strong, nonatomic) IBOutlet UIImageView *imageNew;
@property (strong, nonatomic) UIColor *tableBackgroundColor;
@end
