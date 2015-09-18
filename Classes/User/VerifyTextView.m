
#import <Parse/Parse.h>
#import <ParseUI/ParseUI.h>
#import "ProgressHUD.h"
#import "AppConstant.h"
#import "pushnotification.h"
#import "AppDelegate.h"
#import "VerifyTextView.h"
#import "utilities.h"
#import "UIColor.h"

@interface VerifyTextView ()

@property (strong, nonatomic) IBOutlet UITableViewCell *cellFirstName;
@property (weak, nonatomic) IBOutlet UITextField *fieldFirstName;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButton;
@property (weak, nonatomic) IBOutlet UIButton *verifyButton;
@end

@implementation VerifyTextView

@synthesize cellFirstName, phoneNumber, password;
@synthesize fieldFirstName;

-(void)viewDidAppear:(BOOL)animated
{
    [fieldFirstName becomeFirstResponder];

    if (_isLoggingIn)
    {
        [self.verifyButton addTarget:self action:@selector(actionSignin) forControlEvents:UIControlEventTouchUpInside];
    }
    else
    {
        [self.verifyButton addTarget:self action:@selector(actionRegister:) forControlEvents:UIControlEventTouchUpInside];
    }


    PostNotification(NOTIFICATION_DISABLE_SCROLL_WELCOME);
}

-(void)viewDidDisappear:(BOOL)animated {
   PostNotification(NOTIFICATION_DISABLE_SCROLL_WELCOME);
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = @"Enter Verification Code";

    _verifyButton.backgroundColor = [UIColor benFamousGreen];

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
    [ProgressHUD show:@"Verifying..." Interaction:0];
    [self dismissKeyboard];
    NSDictionary *parms = [NSDictionary new];
    fieldFirstName.text = [fieldFirstName.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    parms = @{PF_USER_PHONEVERIFICATIONCODE: fieldFirstName.text, PF_USER_USERNAME: phoneNumber};

    [PFCloud callFunctionInBackground:@"verifyPhoneNumber" withParameters:parms block:^(id object, NSError *error)
    {
        if (!error)
        {
            [_user setValue:@(arc4random_uniform(2323223)) forKey:PF_USER_PHONEVERIFICATIONCODE];
            [_user setValue:@YES forKey:PF_USER_ISVERIFIED];
            
            _user.password = phoneNumber;
            _user.username = phoneNumber;

            [_user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
            {
                if (!error && succeeded)
                {
                    //LOGIN AGAIN IF ANOTHER USER, OTHERWISE SIGNUP.
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setBool:YES forKey:PF_USER_ISVERIFIED];
                        [userDefaults synchronize];

                        ParsePushUserAssign();
                        [ProgressHUD showSuccess:@"Welcome!" Interaction:1];
                        PostNotification(NOTIFICATION_USER_LOGGED_IN);
                }
                else
                {
                    NSLog(@"%@ saving user", error.userInfo);
                    NSString *errorString = error.userInfo[@"error"];
                    if (errorString.length < 50)
                    {
                        [ProgressHUD showError:errorString];
                    }
                    else
                    {
                    [ProgressHUD showError:NETWORK_ERROR];
                    }
                }
            }];

        } else {
            NSLog(@"%@", error.userInfo);
            NSString *errorString = error.userInfo[@"error"];
            if (errorString.length < 50) {
                [ProgressHUD showError:errorString];
            } else {
                [ProgressHUD showError:NETWORK_ERROR];
            }
        }
    }];
}



-(void)actionSignin
{
    [ProgressHUD show:@"Verifying..." Interaction:0];

    [self dismissKeyboard];
    NSDictionary *parms = [NSDictionary new];
    fieldFirstName.text = [fieldFirstName.text stringByReplacingOccurrencesOfString:@" " withString:@""];
    parms = @{PF_USER_PHONEVERIFICATIONCODE: fieldFirstName.text, PF_USER_USERNAME: phoneNumber};

    [PFCloud callFunctionInBackground:@"verifyPhoneNumber" withParameters:parms block:^(id object, NSError *error)
     {
         if (!error)
         {
             [[PFUser currentUser] setValue:@YES forKey:PF_USER_ISVERIFIED];
             [[PFUser currentUser] setValue:@(arc4random_uniform(2323223)) forKey:PF_USER_PHONEVERIFICATIONCODE];
             [[PFUser currentUser] setValue:@YES forKey:PF_USER_ISVERIFIED];
             [[PFUser currentUser] saveInBackground];

             [ProgressHUD showSuccess:[NSString stringWithFormat:@"Welcome back \n %@!", [PFUser currentUser][PF_USER_FULLNAME]]];

             ParsePushUserAssign();

             PostNotification(NOTIFICATION_USER_LOGGED_IN);

             [self.view endEditing:1];

             self.fieldFirstName.text =@"";

         }
         else
         {
             [ProgressHUD showError:NETWORK_ERROR];
             NSLog(@"%@", error.userInfo);
         }

     }];
}

#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) return cellFirstName;
    if (indexPath.section == 1) return _cellButton;
    return nil;
}

#pragma mark - UITextField delegate
- (void) resignKeyboards
{
    [self.view endEditing:1];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self dismissKeyboard];
    [self actionRegister:0];
    return YES;
}

@end
