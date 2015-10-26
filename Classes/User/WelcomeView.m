#import "ProgressHUD.h"
#import "WelcomeView.h"

@implementation WelcomeView

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.title = @"Welcome";
    self.imageView.frame = CGRectMake(0, -344, 330, 330);
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

//    [UIView animateWithDuration:0.6f delay:1.0 usingSpringWithDamping:1.0f initialSpringVelocity:-5.0f options:0 animations:^{

    [UIView animateWithDuration:1.0f delay:1.0
         usingSpringWithDamping:0.2f initialSpringVelocity:0
                        options:0 animations:^{
                            self.imageView.frame = CGRectMake(0, 144, 330, 330);
                            self.view.backgroundColor = [UIColor benFamousOrange];
                            self.view.backgroundColor = [UIColor benFamousGreen];
                        } completion:nil];

    [UIView animateWithDuration:0.4f delay:1.5
         usingSpringWithDamping:0.2f initialSpringVelocity:0
                        options:0 animations:^{
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
