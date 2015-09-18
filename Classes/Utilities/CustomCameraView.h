//
//  AddRecommendationViewController.h
//  Recommend
//

#import "CustomCameraView.h"
#import <UIKit/UIKit.h>
#import "MessagesView.h"
#import "MasterScrollView.h"

#pragma mark - DELEGATE
@protocol CustomCameraDelegate <NSObject>
-(void)sendBackPictures:(NSArray *)images withBool:(bool)didTakePicture andComment:(NSString *)comment;
@end

@interface CustomCameraView : UIViewController

@property(nonatomic,assign)id delegate;

-(id)initWithPopUp:(BOOL)popup;

-(void)setPopUp;

@property (strong, nonatomic) MasterScrollView *scrollView;

@property BOOL isReturningFromBackButton;

@property NSMutableArray *arrayOfTakenPhotos;
@property NSMutableArray *arrayOfScrollview;

@property (weak, nonatomic) IBOutlet UIView *videoPreviewView;

@property (atomic) BOOL isPoppingUp;

@end
