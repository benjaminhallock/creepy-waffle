

#import "CustomCollectionViewCell.h"

@implementation CustomCollectionViewCell

@synthesize imageView, name, label;

- (void) format
{
    self.imageView.layer.borderWidth = 2;
    self.imageView.layer.masksToBounds = YES;
    self.imageView.layer.cornerRadius = 10;
#warning RASTERIZING
    self.layer.rasterizationScale = [UIScreen mainScreen].scale;
    self.layer.shouldRasterize = YES;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        self.backgroundColor = [UIColor whiteColor];
        self.imageView.layer.shadowColor = [UIColor blackColor].CGColor;
        self.imageView.layer.shadowRadius = 5.0f;
        self.imageView.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
        self.imageView.layer.shadowOpacity = 0.5f;
        self.imageView.layer.borderColor = [UIColor redColor].CGColor;
        self.imageView.layer.borderWidth = 1;
        self.imageView.backgroundColor = [UIColor clearColor];
        self.imageView.layer.cornerRadius = 5;
        self.imageView.layer.masksToBounds = 1;

        // Selected background view
        UIView *backgroundView = [[UIView alloc]initWithFrame:self.bounds];
        backgroundView.layer.borderColor = [[UIColor colorWithRed:1 green:1 blue:1 alpha:1]CGColor];
        backgroundView.layer.borderWidth = 0.0f;
        self.selectedBackgroundView = backgroundView;

        // set content view
        CGRect frame  = CGRectMake(self.bounds.origin.x + 5, self.bounds.origin.y+ 5, self.bounds.size.width, self.bounds.size.height);
        self.imageView = [[PFImageView alloc] initWithFrame:frame];
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        [self.contentView addSubview:self.imageView];

    CGRect frame2 = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, 28, 28);
        label = [[UILabel alloc] initWithFrame:frame2];
        label.layer.cornerRadius = self.bounds.size.width/3.5/2;
        label.layer.masksToBounds = 1;
        label.layer.borderColor = [[UIColor whiteColor]CGColor];
        label.layer.borderWidth = 1;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont fontWithName:@"Helvetica Bold" size:12];
        label.textColor = [UIColor whiteColor];

        [self insertSubview:label aboveSubview:self.imageView];
    }
    return self;
}
@end
