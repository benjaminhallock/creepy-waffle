
#import "ProgressHUD.h"
#import "RegisterView.h"
#import "VerifyTextView.h"
#import "utilities.h"

@interface RegisterView()

@property (strong, nonatomic) IBOutlet UITableViewCell *cellFirstName;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellLastName;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPassword;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPhoneNumber;

@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldLasteName;
@property (weak, nonatomic) IBOutlet UITextField *fieldPassword;
@property (weak, nonatomic) IBOutlet UITextField *fieldPhoneNumber;

@property (weak, nonatomic) IBOutlet UIButton *registerButton;

@property (strong, nonatomic) NSDate *dateUntiLNextText;

@property NSString *phoneNumber;
@property NSString *password;

@property BOOL isTextFieldUp;
@end

@implementation RegisterView

@synthesize cellFirstName, cellPassword, cellButton, cellPhoneNumber, cellLastName, password;
@synthesize fieldFirstName, fieldPassword, fieldLasteName, fieldPhoneNumber, phoneNumber;

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _isTextFieldUp = YES;
    PostNotification(NOTIFICATION_DISABLE_SCROLL_WELCOME);
    return YES;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    _isTextFieldUp = NO;
    PostNotification(NOTIFICATION_ENABLE_SCROLL_WELCOME);
    return YES;
}

- (IBAction)buttonPolicy:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Open Safari?" message:@"To view the terms of service and privacy policy, the app will switch to safari." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open", nil];
    alert.tag = 66;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 66 && buttonIndex != alertView.cancelButtonIndex)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://benmessenger.com/terms-of-use/"]];
    }
}

-(IBAction)didSlideRight:(id)sender
{
    if (!_isTextFieldUp)
    {
    PostNotification(NOTIFICATION_SLIDE_MIDDLE_WELCOME);
    }
    else
    {
        [self.view endEditing:1];
    }
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = @"Register";

    _registerButton.backgroundColor = [UIColor benFamousGreen];

    self.dateUntiLNextText = nil;

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@">"
                                                             style:UIBarButtonItemStylePlain target:self action:@selector(didSlideRight:)];
    item.image = [UIImage imageNamed:ASSETS_BACK_BUTTON_RIGHT];
    self.navigationItem.rightBarButtonItem = item;

	[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
	self.tableView.separatorInset = UIEdgeInsetsZero;
}


- (void)dismissKeyboard
{
	[self.view endEditing:YES];
}

#pragma mark - User actions

- (IBAction)actionRegister:(id)sender
{
    [self resignKeyboards];

	NSString *nameFirst		= [fieldFirstName.text capitalizedString];
    NSString *nameLast     = [fieldLasteName.text capitalizedString];
    password	= fieldPassword.text;
    phoneNumber = fieldPhoneNumber.text;

    phoneNumber = [phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    nameFirst	= [nameFirst stringByReplacingOccurrencesOfString:@" " withString:@""];
    nameLast    = [nameLast stringByReplacingOccurrencesOfString:@" " withString:@""];
//  password	= [password stringByReplacingOccurrencesOfString:@" " withString:@""];

    if (phoneNumber.length < 10 || [phoneNumber isEqualToString:@"Phone Number"])
    {
        [ProgressHUD showError:@"Enter Phone Number"];
        return;
    }

    if ([nameFirst isEqualToString:@"First"] || [nameLast isEqualToString:@"Last"])
    {
        [ProgressHUD showError:@"Enter Full Name"];
        return;
    }

	if ((nameFirst.length != 0) && (phoneNumber.length != 0) && (nameLast.length != 0))
    {
        phoneNumber  = [AppConstant formatPhoneNumberForCountry:phoneNumber];

		[ProgressHUD show:@"Searching for users..." Interaction:1];

        PFQuery *query = [PFUser query];
        [query whereKey:PF_USER_USERNAME equalTo:phoneNumber];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
            if (!error) {
                if (objects.count == 1)
                {
                    PFUser *user = objects.firstObject;

                    NSString *fullName = [user valueForKey:PF_USER_FULLNAME];

                    if  (fullName.length)
                    {
                         [ProgressHUD showError:@"Phone Number Registered"];
                    }
                    else
                    {
                        //USER FOUND BUT NO NAME YET. INVITING THEM NOW
                        [PFUser logInWithUsernameInBackground:phoneNumber password:phoneNumber block:^(PFUser *user, NSError *error)
                        {
                            if (!error)
                            {
                            [ProgressHUD show:@"Sending Text..." Interaction:0];
                            //Save name if user logs in.

                            NSString *fullName = [NSString stringWithFormat:@"%@ %@", nameFirst, nameLast];

                                [user setValue:fullName forKey:PF_USER_FULLNAME];
                                [user setValue:[fullName lowercaseString] forKey:PF_USER_FULLNAME_LOWER];

                            [self sendText:user];

                            }
                            else
                            {
                                [ProgressHUD showError:@"Couldn't sign in existing user \n (Email for assistance)"];
                            }
                            }];
                    }
                }
                else if (objects.count == 0)
                {
#warning AVOID STRANGE CIRCUMSTANCE WHERE USER LOGS IN AS UNREGISTERED USER, FAILS VERIFICATION, THEN SIGNS UP AGAIN AND REPLACES THAT USER, STEALING THEIR INBOX.
                    [ProgressHUD show:@"Registering..."];
                    [PFUser logOut];
                    //Make the anonymouse user the current user
                    PFUser *newUser = [PFUser currentUser];

                    if ([phoneNumber isEqualToString:@"+10000000000"])
                    {
                        newUser[PF_USER_PHONEVERIFICATIONCODE] = [NSNumber numberWithLongLong:8675309665];
                    }

                    NSString *fullName = [NSString stringWithFormat:@"%@ %@", nameFirst, nameLast];
                    newUser[PF_USER_FULLNAME] = [fullName capitalizedString];
                    newUser[PF_USER_FULLNAME_LOWER] = [fullName lowercaseString];
                    [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded)
                        {
                            [ProgressHUD show:@"Sending Text..." Interaction:0];
                                 [self sendText:newUser];
                        } else [ProgressHUD showError:error.userInfo[@"error"] Interaction:1];
                    }];
                }
            } else {
                [ProgressHUD showError:NETWORK_ERROR];
            }
        }];
    }
    else
    {
        [ProgressHUD showError:@"Enter all information"];
        NSLog(@"%@ %@ %@ %@", fieldFirstName.text, fieldPhoneNumber.text, fieldLasteName.text, fieldPassword.text);
    }
}

- (void) sendText:(PFUser *)userFound
{
    if ([phoneNumber  isEqual: @"+10000000000"])
    {
        phoneNumber = @"0000000000";
        return;
    }

    if (self.dateUntiLNextText.timeIntervalSinceNow > 0)
    {
        NSString *string = [NSString stringWithFormat:@"Please wait %i seconds", (int)self.dateUntiLNextText.timeIntervalSinceNow];

        [ProgressHUD showError:string];
        return;
    }

    NSDictionary *params = [NSDictionary dictionaryWithObject:phoneNumber forKey:@"phoneNumber"];

    [PFCloud callFunctionInBackground:@"sendVerificationCode" withParameters:params block:^(id object, NSError *error)
    {
        if (!error)
        {
            NSLog(@"%@ Twilio Return", object);

            self.dateUntiLNextText = [NSDate dateWithTimeIntervalSinceNow:30];

            [ProgressHUD showSuccess:@"Text Sent"];

//            [self sendFirstConversation];

            VerifyTextView *tableview = [[VerifyTextView alloc] initWithStyle:UITableViewStyleGrouped];
            tableview.title = @"Enter Verification Code";
            tableview.lastTextDate = self.dateUntiLNextText;
            tableview.user = userFound;
            tableview.password = password;
            tableview.phoneNumber = phoneNumber;
            [self.navigationController pushViewController:tableview animated:1];
        }
        else
        {
#warning Delete user since phone number was invalid? Replaced by anonymouse
        [[PFUser currentUser] deleteInBackground];
            NSLog(@"%@", error.userInfo);
        [ProgressHUD showError:[NSString stringWithFormat:@"Texting Number Invalid"] Interaction:1];
        }
    }];
}

-(void)sendFirstConversation
{
// CREATE A CHATROOM FOR THIS NEW USER.

    PFQuery *query = [PFUser query];
    //Hardcoded Value not good.
    [query whereKey:PF_USER_FULLNAME equalTo:@"ben Team"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
    {
        if (!error)
        {
            if (objects.count == 1)
            {
                PFUser *user = objects.firstObject;

                PFObject *chatroom = [PFObject objectWithClassName:PF_CHATROOMS_CLASS_NAME];
                PFRelation *arrayOfUsers = [chatroom relationForKey:PF_CHATROOMS_USERS];
                NSArray *arrayOfUsersIds = [NSArray arrayWithObjects:user.objectId, [PFUser currentUser].objectId, nil];
                [arrayOfUsers addObject:[PFUser currentUser]];
                [arrayOfUsers addObject:user];
                [chatroom setValue:@"First user" forKey:PF_CHATROOMS_NAME];
                [chatroom setValue:@(3) forKey:PF_CHATROOMS_ROOMNUMBER];
                [chatroom setValue:arrayOfUsersIds forKey:PF_CHATROOMS_USEROBJECTS];
                [chatroom saveInBackground];

                PFObject *set = [PFObject objectWithClassName:PF_SET_CLASS_NAME];
                [set setValue:chatroom forKey:PF_SET_ROOM];
                [set setValue:@(0) forKey:PF_SET_ROOMNUMBER];
                [set setValue:user forKey:PF_SET_USER];
                [set saveInBackground];

                PFObject *set2 = [PFObject objectWithClassName:PF_SET_CLASS_NAME];
                [set2 setValue:chatroom forKey:PF_SET_ROOM];
                [set2 setValue:@(1) forKey:PF_SET_ROOMNUMBER];
                [set2 setValue:user forKey:PF_SET_USER];
                [set2 saveInBackground];

                PFObject *message = [PFObject objectWithClassName:PF_MESSAGES_CLASS_NAME];
                message[PF_MESSAGES_USER] = [PFUser currentUser];
                message[PF_MESSAGES_ROOM] = chatroom;
                message[PF_MESSAGES_DESCRIPTION] = @"ben Team";
                message[PF_MESSAGES_HIDE_UNTIL_NEXT] = @NO;
                message[PF_MESSAGES_LASTUSER] = user;
                message[PF_MESSAGES_COUNTER] = @(3);
                message[PF_MESSAGES_LASTPICTUREUSER] = user;
                message[PF_MESSAGES_USER_DONOTDISTURB] = [PFUser currentUser];
                message[PF_MESSAGES_LASTMESSAGE] = @"Hey look here!";

                message[PF_MESSAGES_UPDATEDACTION] = [NSDate date];
                [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
                 {}];

                NSArray *arrayOfSetences1 = @[@"Welcome to ben!", @"Have fun converstions without all of your photos getting in the way!"];

                NSArray *arrayOfPictures = [NSArray arrayWithObjects:[UIImage imageNamed:@"Chicago1"],[UIImage imageNamed:@"Chicago2"], nil];

                __block int x = (int)arrayOfPictures.count;
                
                for (UIImage *image in arrayOfPictures)
                {
                    PFObject *picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
                    UIImage *thumbnail = ResizeImage(image, image.size.width, image.size.height);
                    PFFile *file = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .2)];
                    PFFile *imageFile = [PFFile fileWithName:@"image.png" data:UIImageJPEGRepresentation(image, .5)];
                    [picture setValue:imageFile forKey:PF_PICTURES_PICTURE];
                    [picture setValue:file forKey:PF_PICTURES_THUMBNAIL];
                    [picture setValue:user forKey:PF_PICTURES_USER];
                    [picture setValue:chatroom forKey:PF_PICTURES_CHATROOM];
                    [picture setValue:set forKey:PF_PICTURES_SETID];
                    [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];
                    [picture setValue:[NSDate dateWithTimeIntervalSinceNow:[arrayOfPictures indexOfObject:image]] forKey:PF_PICTURES_UPDATEDACTION];
                    [picture setValue:set forKey:PF_PICTURES_SETID];
                    [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded) {
                            x--;
                            if (x == 0) {
                                message[PF_MESSAGES_LASTPICTURE] = picture;
                                [message saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                                    if (succeeded)
                                    {
                                        PostNotification(NOTIFICATION_REFRESH_INBOX);
                                    }
                                }];
                            }
                        }
                    }];
                }

                for (NSString *string in arrayOfSetences1)
                {
                    PFObject *comment = [PFObject objectWithClassName:PF_CHAT_CLASS_NAME];
                    [comment setValue:user forKey:PF_CHAT_USER];
                    [comment setValue:string forKey:PF_CHAT_TEXT];
                    [comment setValue:chatroom forKey:PF_CHAT_ROOM];
                    [comment setValue:set forKey:PF_CHAT_SETID];
                    [comment setValue:[NSDate dateWithTimeIntervalSinceNow:[arrayOfSetences1 indexOfObject:string]] forKey:PF_PICTURES_UPDATEDACTION];
                    [comment saveInBackground];
                }

                [self secondSend:user andChatroom:chatroom andSet:set2];

                [self sendLastWithChatroom:chatroom User:user];
            }
        }
    }];
}

-(void) secondSend:(PFUser *)user andChatroom:(PFObject *)chatroom andSet:(PFObject *)set2
{
    NSArray *arrayOfSetences2 = @[@"Click here to see a conversation about a specific set of photos.", @"All the comments here will be the same color for this set."];

    NSArray *arrayOfPictures2 = [NSArray arrayWithObjects:[UIImage imageNamed:@"Chicago3"],[UIImage imageNamed:@"Chicago4"], nil];

    for (NSString *string in arrayOfSetences2)
    {
        PFObject *comment = [PFObject objectWithClassName:PF_CHAT_CLASS_NAME];
        [comment setValue:user forKey:PF_CHAT_USER];
        [comment setValue:string forKey:PF_CHAT_TEXT];
        [comment setValue:chatroom forKey:PF_CHAT_ROOM];
        [comment setValue:set2 forKey:PF_CHAT_SETID];
        [comment setValue:[NSDate dateWithTimeIntervalSinceNow:2 + [arrayOfSetences2 indexOfObject:string]] forKey:PF_PICTURES_UPDATEDACTION];
        [comment saveInBackground];
    }



    __block int x = (int)arrayOfPictures2.count;

    for (UIImage *image in arrayOfPictures2)
    {
        PFObject *picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
        UIImage *thumbnail = ResizeImage(image, image.size.width, image.size.height);
        PFFile *file = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .2)];
        PFFile *imageFile = [PFFile fileWithName:@"image.png" data:UIImageJPEGRepresentation(image, .5)];
        [picture setValue:imageFile forKey:PF_PICTURES_PICTURE];
        [picture setValue:file forKey:PF_PICTURES_THUMBNAIL];
        [picture setValue:user forKey:PF_PICTURES_USER];
        [picture setValue:chatroom forKey:PF_PICTURES_CHATROOM];
        [picture setValue:set2 forKey:PF_PICTURES_SETID];
        [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];
        [picture setValue:[NSDate dateWithTimeIntervalSinceNow:2 + [arrayOfPictures2 indexOfObject:image]] forKey:PF_PICTURES_UPDATEDACTION];
        [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) {
                x--;
                if (x == 0) {
//                    [self sendLastWithChatroom:chatroom User:user];
                }
            }
        }];
    }
}

- (void) sendLastWithChatroom:(PFObject *)chatroom User:(PFObject *)user
{

    NSString *blankComment = @"Or create a new set of photos.  They will appear in a different color!  This is gray because it is not tagged to a photo.";
        PFObject *comment = [PFObject objectWithClassName:PF_CHAT_CLASS_NAME];
        [comment setValue:user forKey:PF_CHAT_USER];
        [comment setValue:blankComment forKey:PF_CHAT_TEXT];
        [comment setValue:chatroom forKey:PF_CHAT_ROOM];
        [comment setValue:[NSDate dateWithTimeIntervalSinceNow:3] forKey:PF_PICTURES_UPDATEDACTION];
        [comment saveInBackground];
    

    PFObject *set3 = [PFObject objectWithClassName:PF_SET_CLASS_NAME];
    [set3 setValue:chatroom forKey:PF_SET_ROOM];
    [set3 setValue:@(2) forKey:PF_SET_ROOMNUMBER];
    [set3 setValue:user forKey:PF_SET_USER];
    [set3 saveInBackground];

    UIImage *imagee = [UIImage imageNamed:@"Chicago5"];

    for (UIImage *image in @[imagee])
    {
        PFObject *picture = [PFObject objectWithClassName:PF_PICTURES_CLASS_NAME];
        UIImage *thumbnail = ResizeImage(image, image.size.width, image.size.height);
        PFFile *file = [PFFile fileWithName:@"thumbnail.png" data:UIImageJPEGRepresentation(thumbnail, .2)];
        PFFile *imageFile = [PFFile fileWithName:@"image.png" data:UIImageJPEGRepresentation(image, .5)];
        [picture setValue:imageFile forKey:PF_PICTURES_PICTURE];
        [picture setValue:file forKey:PF_PICTURES_THUMBNAIL];
        [picture setValue:user forKey:PF_PICTURES_USER];
        [picture setValue:chatroom forKey:PF_PICTURES_CHATROOM];
        [picture setValue:set3 forKey:PF_PICTURES_SETID];
        [picture setValue:@YES forKey:PF_CHAT_ISUPLOADED];
        [picture setValue:[NSDate dateWithTimeIntervalSinceNow:3 ] forKey:PF_PICTURES_UPDATEDACTION];
        [picture saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded) PostNotification(NOTIFICATION_REFRESH_INBOX);
        }];
    }

    NSString *string3 = @"You can also save your new photos to an album by clicking the star button!";

    for (NSString *string in @[string3])
    {
        PFObject *comment = [PFObject objectWithClassName:PF_CHAT_CLASS_NAME];
        [comment setValue:user forKey:PF_CHAT_USER];
        [comment setValue:string forKey:PF_CHAT_TEXT];
        [comment setValue:chatroom forKey:PF_CHAT_ROOM];
        [comment setValue:set3 forKey:PF_CHAT_SETID];
        [comment setValue:[NSDate dateWithTimeIntervalSinceNow:3] forKey:PF_PICTURES_UPDATEDACTION];
        [comment saveInBackground];
    }
}


#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 2;
    }
    else
    {
        return 1;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section != 2)
    {
        return 60;
    }
    else
    {
        return 90;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
    if (indexPath.row == 0) return cellFirstName;
    if (indexPath.row == 1) return cellLastName;
    }
    else if (indexPath.section == 1)
    {
    if(indexPath.row == 0) return cellPhoneNumber;
    }
    else if (indexPath.section == 2)
    {
        return cellButton;
    }
    return nil;
}

#pragma mark - UITextField delegate
- (void) resignKeyboards
{
    [self.view endEditing:1];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == fieldFirstName)
	{
		[fieldLasteName becomeFirstResponder];
	}
   else if (textField == fieldLasteName)
    {
        [fieldPhoneNumber becomeFirstResponder];
    }
   else if (textField == fieldPhoneNumber)
    {
        [fieldPassword becomeFirstResponder];
        [self actionRegister:0];
        [textField resignFirstResponder];
    }
	return YES;
}

@end
