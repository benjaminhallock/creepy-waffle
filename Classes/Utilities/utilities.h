

#import <UIKit/UIKit.h>
#import "MessagesView.h"

//-------------------------------------------------------------------------------------------------------------------------------------------------
void			LoginUser					(MasterScrollView *scrollView);
void			ShowProfileSettings		    (MessagesView *target);
void			ShowNewMessage       	    (id target);

UIImage*		ResizeImage					(UIImage *image, CGFloat width, CGFloat height);

void			PostNotification			(NSString *notification);

//-------------------------------------------------------------------------------------------------------------------------------------------------
NSString*		TimeElapsed					(NSTimeInterval seconds);
