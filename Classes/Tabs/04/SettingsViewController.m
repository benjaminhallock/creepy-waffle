#import "ProgressHUD.h"
#import "AppConstant.h"
#import "camera.h"
#import "pushnotification.h"
#import "utilities.h"
#import "SettingsViewController.h"
#import "MasterLoginRegisterView.h"

@interface SettingsViewController () <UIActionSheetDelegate, UITextFieldDelegate>
@property (strong, nonatomic) IBOutlet UIView *viewHeader;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellName;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPhoneNumber;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellTOS;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellPP;
@property (strong, nonatomic) IBOutlet UITextField *fieldPhoneNumber;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellButton;
@property (strong, nonatomic) IBOutlet UITableViewCell *cellVibrate;
@property (strong, nonatomic) IBOutlet UITextField *fieldName;
@property (strong, nonatomic) IBOutlet UISwitch *switchVibrate;
@property (strong, nonatomic) IBOutlet UIButton *buttonLogout;
@end

@implementation SettingsViewController

@synthesize cellName, cellButton, cellVibrate, viewHeader, fieldName;

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    PostNotification(NOTIFICATION_ENABLESCROLLVIEW);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = @"Settings";

    self.buttonLogout.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorInset = UIEdgeInsetsZero;
    cellButton.backgroundColor = [UIColor clearColor];
    self.tableView.separatorInset = UIEdgeInsetsZero;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(actionDismiss) name:NOTIFICATION_CLICKED_PUSH object:0];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(profileLoad) name:NOTIFICATION_USER_LOGGED_IN object:0];

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults boolForKey:PF_KEY_SHOULDVIBRATE]) {
        [_switchVibrate setOn:1 animated:1];
    } else {
        [_switchVibrate setOn:0 animated:1];
    }

	[self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];
    UIPanGestureRecognizer *pan = [UIPanGestureRecognizer new];
    [self.view addGestureRecognizer:pan];

    if ([PFUser currentUser] != nil)   [self profileLoad];
}

- (void)dismissKeyboard
{
	[self.view endEditing:YES];
}

- (void)profileLoad
{
	PFUser *user = [PFUser currentUser];
    [user fetchIfNeededInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        fieldName.text =  [NSString stringWithFormat:@"%@ - %@", object[PF_USER_FULLNAME], [object valueForKey:PF_USER_USERNAME]];
    }];

}

#pragma mark - User actions

- (IBAction)actionLogout:(id)sender
{
	UIActionSheet *action = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
											   otherButtonTitles:@"Logout", nil];
    [action showInView:self.view];
}


//Not used
- (IBAction) actionDelete
{
//PFCloud *cloud = [PFCloud callFunction:@"DeleteAll" withParameters:0];
#warning FETCHING OTHER CLASSES TOO????
    PFQuery *query = [PFQuery queryWithClassName:PF_CHAT_CLASS_NAME];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        if (!error) {
        [objects.firstObject deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                [ProgressHUD showError:@"Your not Neo"];
                return;
            } else {
                for (PFObject *object in objects) {
                    [object deleteInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (!error && object == objects.lastObject) {
                            [self dismissViewControllerAnimated:1 completion:0];
                            [ProgressHUD showSuccess:@"Deleted All Chats"];
                            [query clearCachedResult];
                        }
                    }];
                }
            }
            }];
        } else {
            [ProgressHUD showError:NETWORK_ERROR];
        }
    }];
}

- (void)actionDismiss
{
    [self dismissViewControllerAnimated:1 completion:0];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex != actionSheet.cancelButtonIndex)
	{
        [PFUser logOut];
        fieldName.text = @"";
        ParsePushUserResign();
        PostNotification(NOTIFICATION_USER_LOGGED_OUT);
    }
}

- (IBAction)switchVibrate:(UISwitch *)sender
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if (sender.isOn) {
         [userDefaults setBool:YES forKey:PF_KEY_SHOULDVIBRATE];
    } else {
        [userDefaults setBool:NO forKey:PF_KEY_SHOULDVIBRATE];
    }
    [userDefaults synchronize];
}

- (IBAction)TOS
{
    UIViewController *tos = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:tos.view.frame];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://benmessenger.com/terms-of-use/"]]];
    webView.backgroundColor = [UIColor whiteColor];
    [tos.view addSubview:webView];
    tos.title = @"Terms Of Service";
    self.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:tos animated:1];
    self.hidesBottomBarWhenPushed = NO;
}

- (IBAction)PP
{
    UIViewController *pp = [[UIViewController alloc] init];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:pp.view.frame];
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://benmessenger.com/privacy-policy/"]]];
    webView.backgroundColor = [UIColor whiteColor];
    [pp.view addSubview:webView];
    pp.title = @"Privacy Policy";
    self.hidesBottomBarWhenPushed = YES;
    [self.navigationController pushViewController:pp animated:1];
    self.hidesBottomBarWhenPushed = NO;
}

- (IBAction)actionSave:(id)sender
{
	[self dismissKeyboard];
    [self.navigationController popViewControllerAnimated:0];
    return;

	if ([fieldName.text isEqualToString:@""] == NO)
	{
		[ProgressHUD show:@"Please wait..."];

		PFUser *user = [PFUser currentUser];
		user[PF_USER_FULLNAME] = fieldName.text;
		user[PF_USER_FULLNAME_LOWER] = [fieldName.text lowercaseString];

		[user saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error)
		{
			if (error == nil)
			{
                [self.navigationController popViewControllerAnimated:0];
                [ProgressHUD showSuccess:@"Saved."];
			}
			else [ProgressHUD showError:NETWORK_ERROR];
		}];
	}
	else [ProgressHUD showError:@"Name field must be set."];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0 || section == 1) return 2;
    else return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (indexPath.row == 0) return cellName;
        else if (indexPath.row == 1) return cellVibrate;
//        if (indexPath.row == 1) return _cellPhoneNumber;
    }
    if (indexPath.section == 1)
    {
        if (indexPath.row == 0) return _cellTOS;
        if (indexPath.row == 1) return _cellPP;
    }
    if (indexPath.section == 2) return cellButton;
	return nil;
}

@end
