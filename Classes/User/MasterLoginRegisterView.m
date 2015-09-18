

#import "MasterLoginRegisterView.h"
#import "MasterScrollView.h"
#import "RegisterView.h"
#import "LoginView.h"
#import "WelcomeView.h"
#import "AppConstant.h"

#import "IQKeyboardManager.h"

@interface MasterLoginRegisterView ()
@property NavigationController *navWelcome;
@property NavigationController *navRegister;
@property NavigationController *navLogin;
@property UIScrollView *scrollView;
@end

@implementation MasterLoginRegisterView
@synthesize navWelcome, navRegister, navLogin, scrollView;

- (void)viewDidLoad
{
    [IQKeyboardManager sharedManager].enableAutoToolbar = YES;

    [super viewDidLoad];
    scrollView = [[UIScrollView alloc] init];
    scrollView.frame = self.view.frame;
    [self.view addSubview:scrollView];
    
    scrollView.bounces = NO;
    scrollView.pagingEnabled = 1;
    scrollView.directionalLockEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = 0;
    scrollView.scrollEnabled = 1;

    WelcomeView *welcome = [WelcomeView new];
    welcome.scrollView = scrollView;
    LoginView *login = [[LoginView alloc] init];
    RegisterView *registerView = [[RegisterView alloc] init];

    navWelcome = [[NavigationController alloc] initWithRootViewController:welcome];
    navRegister = [[NavigationController alloc] initWithRootViewController:registerView];
    navLogin = [[NavigationController alloc] initWithRootViewController:login];

    navWelcome.view.frame = CGRectMake(self.view.frame.size.width,
                                                  0,
                                                  self.view.frame.size.width,
                                                  self.view.frame.size.height);

    navLogin.view.frame = CGRectMake(self.view.frame.size.width * 2,
                                                0,
                                                self.view.frame.size.width,
                                                self.view.frame.size.height);

    navRegister.view.frame =         CGRectMake(0,
                                                0,
                                                self.view.frame.size.width,
                                                self.view.frame.size.height);

    [scrollView addSubview:navRegister.view];
    [scrollView addSubview:navLogin.view];
    [scrollView addSubview:navWelcome.view];

    [navLogin didMoveToParentViewController:self];
    [navRegister didMoveToParentViewController:self];
    [navWelcome didMoveToParentViewController:self];

    scrollView.contentSize = CGSizeMake(3 * self.view.frame.size.width,
                                        self.view.frame.size.height);
    
    [scrollView setContentOffset:CGPointMake(self.view.frame.size.width, 0) animated:1];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss2) name:NOTIFICATION_USER_LOGGED_IN object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setToCenter) name:NOTIFICATION_SLIDE_MIDDLE_WELCOME object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(disableScroll) name:NOTIFICATION_DISABLE_SCROLL_WELCOME object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableScroll) name:NOTIFICATION_ENABLE_SCROLL_WELCOME object:0];
}

-(void) disableScroll
{
    scrollView.scrollEnabled = NO;
}

-(void) enableScroll
{
    scrollView.scrollEnabled = YES;
}

-(void) setToCenter
{
    [scrollView setContentOffset:CGPointMake(self.view.frame.size.width, 0) animated:1];
}

-(void)dismiss2
{
    [IQKeyboardManager sharedManager].enableAutoToolbar = NO;
    [self dismissViewControllerAnimated:1 completion:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
@end
