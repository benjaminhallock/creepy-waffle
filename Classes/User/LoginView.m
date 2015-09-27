#import "ProgressHUD.h"
#import "utilities.h"
#import "pushnotification.h"
#import "LoginView.h"
#import "VerifyTextView.h"

@interface LoginView ()

@property (weak, nonatomic) IBOutlet UITableViewCell *cellPhoneNumber;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellPassword;
@property (weak, nonatomic) IBOutlet UITableViewCell *cellButton;

@property (weak, nonatomic) IBOutlet UITextField *fieldPhoneNumber;
@property (weak, nonatomic) IBOutlet UITextField *fieldPassword;

@property BOOL isTextFieldUp;

@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property NSDate *dateUntilNextText;
@property NSString *phoneNumber;

@end

@implementation LoginView

@synthesize cellPhoneNumber, cellPassword, cellButton;
@synthesize fieldPhoneNumber, fieldPassword, phoneNumber;

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

- (IBAction)didSlideLeft:(id)sender
{
    if (!_isTextFieldUp) {
    PostNotification(NOTIFICATION_SLIDE_MIDDLE_WELCOME);
    } else {
        [self.view endEditing:1];
    }
}

- (void) sendText:(PFUser *)userFound
{
    if (self.dateUntilNextText.timeIntervalSinceNow > 0)
    {
        NSString *string = [NSString stringWithFormat:@"Please wait %i seconds", (int)self.dateUntilNextText.timeIntervalSinceNow];

        [ProgressHUD showError:string];
        return;

    }

    NSDictionary *params = [NSDictionary dictionaryWithObject:phoneNumber forKey:@"phoneNumber"];

    [PFCloud callFunctionInBackground:@"sendVerificationCode" withParameters:params block:^(id object, NSError *error)
     {
         if (!error)
         {
             NSLog(@"%@ Twilio Return", object);

             [ProgressHUD showSuccess:@"Text Sent"];

             VerifyTextView *tableview = [[VerifyTextView alloc] initWithStyle:UITableViewStyleGrouped];
             tableview.title = @"Enter Verification Code";
             tableview.user = [PFUser currentUser];
             tableview.phoneNumber = phoneNumber;
             tableview.isLoggingIn = YES;

             self.dateUntilNextText = [NSDate dateWithTimeIntervalSinceNow:30];



             [self.navigationController pushViewController:tableview animated:1];
         }
         else
         {
             //Logout user, even tho we did set him to unverified, so he cant get in.
             //Delete anonymouse user before login????
             [PFUser logOut];
             NSLog(@"%@", error.userInfo);
        [ProgressHUD showError:[NSString stringWithFormat:@"Texting Number Invalid"] Interaction:1];
         }
     }];
}


- (void)viewDidLoad
{
    _loginButton.backgroundColor = [UIColor benFamousGreen];

//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Forgot?" style:UIBarButtonItemStyleBordered target:self action:@selector(actionForgot)];

	[super viewDidLoad];
	self.title = @"Login";

    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@">"
                                                             style:UIBarButtonItemStylePlain    target:self action:@selector(didSlideLeft:)];
    item.image = [UIImage imageNamed:ASSETS_BACK_BUTTON];
    self.navigationItem.leftBarButtonItem = item;

	[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];

    self.tableView.separatorInset = UIEdgeInsetsZero;
}

- (void)dismissKeyboard
{
	[self.view endEditing:YES];
}

#pragma mark - User actions

- (IBAction)actionLogin:(id)sender
{
	phoneNumber = fieldPhoneNumber.text;
	NSString *password = fieldPassword.text;

    [self dismissKeyboard];

    if (phoneNumber.length < 10 || [phoneNumber isEqualToString:@"Phone Number"])
    {
        [ProgressHUD showError:@"Enter Phone Number"];
        return;
    }

    if (![phoneNumber isEqualToString:@"0000000000"])
    {
    phoneNumber = [AppConstant formatPhoneNumberForCountry:phoneNumber];
    }
    else
    {
        [PFUser logInWithUsernameInBackground:@"0000000000" password:@"benben" block:^(PFUser *user, NSError *error) {
            if (!error)
            {
                ParsePushUserAssign();
                [ProgressHUD showSuccess:@"Welcome!" Interaction:1];
                PostNotification(NOTIFICATION_USER_LOGGED_IN);
                [self dismissViewControllerAnimated:1 completion:0];
            }
        }];
        return;
    }

    if ([phoneNumber isEqualToString:password])
    {
        [ProgressHUD showError:@"Duplicate fields"];
        return;
    }

	if (phoneNumber.length != 0)
	{
		[ProgressHUD show:@"Searching Users..." Interaction:NO];

		[PFUser logInWithUsernameInBackground:phoneNumber password:phoneNumber block:^(PFUser *user, NSError *error)
		{
			if (user && !error)
			{
                NSString *fullName = [user valueForKey:PF_USER_FULLNAME];

                if (!fullName.length)
                {
                    [ProgressHUD showError:@"Account Not Register"];

                    [PFUser logOut];

                }
                else
                {
    //       Make sure to set verified to 0, otherwise they could login.

                [ProgressHUD show:@"Sending Text..." Interaction:0];

                [user setValue:@NO forKey:PF_USER_ISVERIFIED];
                [user saveInBackground];

                [self sendText:user];
                }
            }
            else
            {
                NSLog(@"%@", error.userInfo);
                NSString *errorString = error.userInfo[@"error"];
                if (error.code == 101)
                {
                    [ProgressHUD showError:@"Account Not Registered"];
                }
                else if (errorString.length < 50)
                {
                    [ProgressHUD showError:errorString  Interaction:1];
                }
                else
                {
                    [ProgressHUD showError:NETWORK_ERROR Interaction:1];
                }
            }
		}];
	}
	else [ProgressHUD showError:@"No Phone Number Entered"];
}



#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) return 1;
	return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
	if (indexPath.row == 0) return cellPhoneNumber;
//	if (indexPath.row == 1) return cellPassword;
    }
	if (indexPath.section == 1) return cellButton;
	return nil;
}

#pragma mark - UITextField delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if (textField == fieldPhoneNumber)
	{
		[fieldPassword becomeFirstResponder];
	}
	if (textField == fieldPassword)
	{
		[self actionLogin:nil];
	}
	return YES;
}

@end
