//
//  PictureViewController.h
//  Snap Ben
//
//  Created by benjaminhallock@gmail.com on 9/6/15.
//  Copyright © 2015 KZ. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PictureViewerDelegate <NSObject>
-(void)sendBackImage:(UIImage *)image orVideo:(NSURL *)videoURL;
@end

@interface PictureViewController : UIViewController

@property(nonatomic,assign)id delegate;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@property UIImage *image;

@property NSURL *videoURL;

-(id)initWithVideo:(NSURL *)videoURL orPicture:(UIImage *)image;

@end
