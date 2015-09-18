

#import <Parse/Parse.h>

#import <ParseUI/ParseUI.h>

#import <UIKit/UIKit.h>

@interface MessagesCellDot : UITableViewCell

- (void)bindData:(PFObject *)message_;

- (void)format;

@property (strong, nonatomic) IBOutlet UILabel *labelDescription;

@property (strong, nonatomic) IBOutlet UILabel *labelLastMessage;

@property (strong, nonatomic) IBOutlet UILabel *labelElapsed;

@property (strong, nonatomic) IBOutlet UILabel *labelCounter;

@property (strong, nonatomic) IBOutlet PFImageView *imageUser;

@property (weak, nonatomic) IBOutlet UILabel *labelInitials;

@property (strong, nonatomic) UIColor *tableBackgroundColor;

@end
