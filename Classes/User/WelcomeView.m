
#import <Parse/Parse.h>
#import "ProgressHUD.h"
#import "WelcomeView.h"

#import "AppConstant.h"
#import "pushnotification.h"
#import "utilities.h"

@implementation WelcomeView

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = @"Welcome";
    self.imageView.frame = CGRectMake(0, -344, 110, 351);
    self.label.frame = CGRectMake(0, -344, 100, 40);

    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
	[self.navigationItem setBackBarButtonItem:backButton];
}

-(void)viewWillAppear:(BOOL)animated {
       self.navigationController.navigationBarHidden= 1;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:1];

    [UIView animateWithDuration:0.3f delay:1.0 usingSpringWithDamping:5.0f initialSpringVelocity:1.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.imageView.frame = CGRectMake(0, 144, 330, 330);
        self.view.backgroundColor = [UIColor whiteColor];
        self.view.backgroundColor = [UIColor benFamousGreen];
    } completion:0];

    [UIView animateWithDuration:0.3f delay:1.5 usingSpringWithDamping:5.0f initialSpringVelocity:10.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.label.frame = CGRectMake(0, 110, 100, 40);
    } completion:0];
}

#pragma mark - User actions

- (IBAction)actionRegister:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:1];
}

- (IBAction)actionLogin:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width * 2, 0) animated:1];
}
- (void)userLoggedIn:(PFUser *)user
{
	[ProgressHUD showSuccess:[NSString stringWithFormat:@"Welcome back %@!", user[PF_USER_FULLNAME]]];
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
