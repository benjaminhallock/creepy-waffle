
#import "CameraCollectionViewCell.h"
#import "UIColor.h"
#import "AppConstant.h"

@implementation CameraCollectionViewCell

- (void)awakeFromNib
{
    // Initialization code
    self.buttonImage.backgroundColor = [UIColor benFamousGreen];
    self.buttonClose.backgroundColor = [UIColor benFamousOrange];

        self.buttonImage.layer.masksToBounds = YES;
        self.buttonImage.layer.cornerRadius = 10;
        self.buttonImage.layer.borderWidth = 3;
        self.buttonImage.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.buttonImage.imageView setContentMode:UIViewContentModeScaleAspectFill];

        self.buttonClose.layer.cornerRadius = self.buttonClose.frame.size.height/4;
        self.buttonClose.layer.masksToBounds = 1;
}


-(IBAction)didDelete:(id)sender
{
   NSIndexPath *indexPath = [self.collectionView indexPathForCell:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_DELETE_CAMERA_PIC object:self userInfo:@{@"index": indexPath}];
}

-(IBAction)didTapButton:(id)sender
{
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_TAP_CAMERA_PIC object:self userInfo:@{@"index": indexPath}];
}

@end
