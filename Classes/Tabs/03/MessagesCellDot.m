
#import <Parse/Parse.h>

#import <ParseUI/ParseUI.h>

#import "AppConstant.h"

#import "utilities.h"

#import "UIColor.h"

#import "MessagesCellDot.h"

@interface MessagesCellDot ()

{
    PFObject *message;
}

@end

@implementation MessagesCellDot

@synthesize imageUser;

@synthesize labelDescription, labelLastMessage, labelInitials;

@synthesize labelElapsed, labelCounter;

-(void) format
{
    imageUser.layer.cornerRadius = 10;
    imageUser.layer.masksToBounds = YES;
    labelInitials.layer.borderWidth = 1;
    labelInitials.layer.borderColor = [UIColor whiteColor].CGColor;
    labelInitials.layer.cornerRadius = labelInitials.frame.size.height/2.9;
    imageUser.layer.borderWidth = 2;
    imageUser.layer.borderColor = [UIColor benFamousGreen].CGColor;
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
    imageUser.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)bindData:(PFObject *)message_
{
    message = message_;

    PFObject *room = message[PF_MESSAGES_ROOM];
    PFRelation *users = room[PF_CHATROOMS_USERS];
    PFQuery *query = users.query;
    PFUser *currentUser = [PFUser currentUser];
    [query whereKey:PF_USER_OBJECTID notEqualTo:currentUser.objectId];
#warning DOING CRAP WITH THE TITLES IN CELLFORROW

#warning BEST WAY TO CHECK FOR NSNULL OBJECT
    if (message[PF_MESSAGES_NICKNAME]) {
        labelDescription.text = message[PF_MESSAGES_NICKNAME];
    } else {
        NSString *description = message[PF_MESSAGES_DESCRIPTION];
        if (description.length) {
            labelDescription.text = description;
        } else {
            [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                if (!error && objects) {
                    NSMutableArray *userss = [NSMutableArray arrayWithArray:objects];
                    [userss removeObject:[PFUser currentUser]];
                    message_[PF_MESSAGES_DESCRIPTION] = [self setNameWithObjects:userss];
                    [message_ saveInBackground];
                }}];
        }
    }

    imageUser.layer.borderColor = self.tableBackgroundColor.CGColor;
    labelLastMessage.text = message[PF_MESSAGES_LASTMESSAGE];
    labelDescription.textColor = self.tableBackgroundColor;
    labelInitials.backgroundColor = self.tableBackgroundColor;
    NSTimeInterval seconds = [[NSDate date] timeIntervalSinceDate:message.updatedAt];
    labelElapsed.text = TimeElapsed(seconds);
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
