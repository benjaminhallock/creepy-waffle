
#import <Parse/Parse.h>

#import <ParseUI/ParseUI.h>

#import "AppConstant.h"

#import "utilities.h"

#import "UIColor.h"

#import "MessagesCell.h"


@interface MessagesCell ()
{
	PFObject *message;
}
@end

@implementation MessagesCell

@synthesize imageUser;
@synthesize labelDescription, labelLastMessage, labelInitials;
@synthesize labelElapsed, labelCounter;
@synthesize imageNew;

-(void) format
{
        self.labelNumberOfPeople.text = @"";
        imageUser.layer.cornerRadius = 10;
        imageUser.layer.masksToBounds = YES;
        labelInitials.layer.borderWidth = 1;

   //  self.selectionStyle = UITableViewCellSelectionStyleNone;
   //    self.imageUser.image = [UIImage imageNamed:@"Blank V"];

    self.contactsPeople.image = [[UIImage imageNamed:@"contacts icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];

    UIColor *lightGray = [UIColor colorWithRed:225/255.0f green:225/255.0f blue:225/255.0f alpha:0.8f];

    self.contactsPeople.tintColor = lightGray;
    self.labelNumberOfPeople.textColor = lightGray;

        labelInitials.layer.borderColor = [UIColor whiteColor].CGColor;
        labelInitials.layer.cornerRadius = labelInitials.frame.size.height/2.7;
        imageUser.layer.borderWidth = 2;
        imageUser.layer.borderColor = [UIColor benFamousGreen].CGColor;
        self.layer.rasterizationScale = [UIScreen mainScreen].scale;
        self.layer.shouldRasterize = YES;
        imageUser.contentMode = UIViewContentModeScaleAspectFill;
        imageNew.image = [UIImage imageNamed:ASSETS_READ];
}


- (void)bindData:(PFObject *)message_
{
	message = message_;

    PFObject *room = message[PF_MESSAGES_ROOM];


    if (message[PF_MESSAGES_NICKNAME]) {
        labelDescription.text = message[PF_MESSAGES_NICKNAME];
    } else {
        NSString *description = message[PF_MESSAGES_DESCRIPTION];
        if (description.length) {
            labelDescription.text = description;
        }
    }

    NSArray *array = [room valueForKey:PF_CHATROOMS_USEROBJECTS];
    self.labelNumberOfPeople.text = [NSString stringWithFormat:@"%lu", (array.count - 1)];

    imageUser.layer.borderColor = self.tableBackgroundColor.CGColor;
	labelLastMessage.text = message[PF_MESSAGES_LASTMESSAGE];
    labelDescription.textColor = self.tableBackgroundColor;
    labelInitials.backgroundColor = self.tableBackgroundColor;

    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:message.updatedAt];
	labelElapsed.text = TimeElapsed(seconds);
	int counter = [message[PF_MESSAGES_COUNTER] intValue];

    if (counter > 0)
    {
        imageNew.tintColor = [UIColor benFamousGreen];
        imageNew.image = [UIImage imageNamed:ASSETS_UNREAD];

        UIImage *newImage = [imageNew.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        UIGraphicsBeginImageContextWithOptions(imageNew.image.size, NO, newImage.scale);
        [[UIColor benFamousOrange] set];
        [newImage drawInRect:CGRectMake(0, 0, imageNew.image.size.width, newImage.size.height)];
        newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        imageNew.image = newImage;
    }
    else
    {
        imageNew.image = [UIImage imageNamed:ASSETS_READ];
    }
}

- (NSString *)setNameWithObjects:(NSArray *)objects
{
    if (objects.count > 0) {
    NSString *titleOfUsers = [NSString stringWithFormat:@""];

    for (PFUser *user in objects) {
    [user fetchIfNeededInBackground];
    NSString *name = user[PF_USER_FULLNAME];
    titleOfUsers = [titleOfUsers stringByAppendingString:[NSString stringWithFormat:@"%@, ", name]];
    }

    titleOfUsers = [titleOfUsers substringToIndex:[titleOfUsers length] - 2];
    [UIView animateWithDuration:1.0 animations:^{
        labelDescription.text = titleOfUsers;
        labelDescription.textColor = self.tableBackgroundColor;
    }];
    return titleOfUsers;
    } else {
        return @"";
    }
}

@end
