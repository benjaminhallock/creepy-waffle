#import "JCNotificationBannerViewIOS7Style.h"
#import "UIColor.h"
#import "AppConstant.h"

@implementation JCNotificationBannerViewIOS7Style

- (id) initWithNotification:(JCNotificationBanner*)notification {
  self = [super initWithNotification:notification];
  if (self) {
      self.titleLabel.textColor = [UIColor whiteColor];


      self.titleLabel.layer.shadowOffset = CGSizeMake(1, 1);
      self.titleLabel.layer.shadowColor = [UIColor darkGrayColor].CGColor;
      self.titleLabel.layer.shadowRadius = 3.0;
      self.titleLabel.layer.shadowOpacity = 0.6;


      self.messageLabel.textColor = [UIColor whiteColor];

      self.messageLabel.layer.shadowOffset = CGSizeMake(1, 1);
      self.messageLabel.layer.shadowColor = [UIColor darkGrayColor].CGColor;
      self.messageLabel.layer.shadowRadius = 3.0;
      self.messageLabel.layer.shadowOpacity = 0.6;

      self.backgroundColor = [UIColor benFamousGreen];

      self.layer.shadowOffset = CGSizeMake(0, 1);
      self.layer.shadowColor = [UIColor darkGrayColor].CGColor;
      self.layer.shadowRadius = 3.0;
      self.layer.shadowOpacity = 0.8;
  }
  return self;
}

/** Overriden to do no custom drawing */
- (void) drawRect:(CGRect)rect {
}

@end
