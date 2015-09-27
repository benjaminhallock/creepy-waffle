#import "NavigationController.h"

@implementation NavigationController 

- (void)viewDidLoad
{

    NSShadow* shadow = [NSShadow new];
    shadow.shadowOffset = CGSizeMake(0.0f, 0.0f);
    shadow.shadowColor = [UIColor whiteColor];

    self.navigationBar.barTintColor = [UIColor benFamousGreen];
    self.navigationBar.opaque = NO;
    self.navigationBar.translucent = NO;
    self.navigationBar.tintColor = [UIColor whiteColor];

    self.navigationBar.titleTextAttributes =  @{
                                                NSForegroundColorAttributeName: [UIColor whiteColor],
                                                NSFontAttributeName: [UIFont fontWithName:@"Helvetica Neue" size:20.0f],
                                                NSShadowAttributeName: shadow
                                                };
    self.navigationBar.translucent = 1;

}

@end
