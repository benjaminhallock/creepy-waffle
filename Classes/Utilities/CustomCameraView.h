//
//  AddRecommendationViewController.h
//  Recommend


#import "AppConstant.h"

#pragma mark - DELEGATE
@protocol CustomCameraDelegate <NSObject>
-(void)sendBackPictures:(NSArray *)images withBool:(bool)didTakePicture andComment:(NSString *)comment;
@end

@interface CustomCameraView : UIViewController
@property(nonatomic,assign)id delegate;

-(id)initWithPopUp:(BOOL)popup;
-(void)setPopUp;

@property IBOutlet UITableView *tableView;

@property BOOL isReturningFromBackButton;
@property NSMutableArray *arrayOfScrollview;
@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;
@property (atomic) BOOL isPoppingUp;

@end
