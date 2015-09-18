

#import <UIKit/UIKit.h>
#import <ParseUI/ParseUI.h>
#import <Parse/Parse.h>


@interface CustomCollectionViewCell : UICollectionViewCell
@property PFImageView *imageView;
@property NSString *name;
@property UILabel *label;
- (void)format;
@end
