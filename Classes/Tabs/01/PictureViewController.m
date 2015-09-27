//
//  PictureViewController.m
//  Snap Ben
//
//  Created by benjaminhallock@gmail.com on 9/6/15.
//  Copyright © 2015 KZ. All rights reserved.
//

#import "PictureViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface PictureViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property MPMoviePlayerController *moviePlayer;
@end

@implementation PictureViewController

@synthesize moviePlayer;

-(id)initWithVideo:(NSURL *)videoURL orPicture:(UIImage *)image;
{
    self = [super init];

    if (self)
    {
        self.image = image;
        self.videoURL = videoURL;
    }
    return self;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [moviePlayer stop];
    moviePlayer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.videoURL)
    {
        [self loadMovie];
    }
    else
    {
    self.imageView.image = self.image;
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(changeFirstResponder)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];

    self.textField.frame = CGRectMake(0, 500, self.view.frame.size.width, 40);
    self.textField.hidden = 1;

//    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
//    [self.view addGestureRecognizer:tap];

//    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didPan:)];
//    [self.view addGestureRecognizer:pan];
}

-(void)loadMovie
{
    moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:self.videoURL];
    moviePlayer.view.frame = CGRectMake(30, 30, self.view.frame.size.width - 30, self.view.frame.size.height - 30);
//    moviePlayer.view.frame = self.view.frame;
    moviePlayer.view.transform = CGAffineTransformMakeScale(1.4f, 1.4f);
    moviePlayer.shouldAutoplay = true;
//    moviePlayer.view.layer.shouldRasterize = 1;
//    moviePlayer.view.layer.rasterizationScale = [UIScreen mainScreen].scale;
    moviePlayer.view.layer.masksToBounds = YES;
    moviePlayer.view.contentMode = UIViewContentModeScaleToFill;
//    moviePlayer.view.layer.cornerRadius = moviePlayer.view.frame.size.width/10;
//    moviePlayer.view.layer.borderColor = [UIColor whiteColor].CGColor;
    moviePlayer.view.layer.borderWidth = 1;
    moviePlayer.view.layer.cornerRadius = 10;
    moviePlayer.view.userInteractionEnabled = 1;
    moviePlayer.view.clipsToBounds = YES;
    moviePlayer.scalingMode = MPMovieScalingModeAspectFill;
    moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.controlStyle = MPMovieControlStyleNone;
    moviePlayer.repeatMode = MPMovieRepeatModeOne;
    moviePlayer.backgroundView.alpha = 0;

    [self.view insertSubview:moviePlayer.view atIndex:1];

    [moviePlayer play];
}

-(void)changeFirstResponder
{
    [self.textField becomeFirstResponder]; //will return YES;
}

-(void)didPan:(UIPanGestureRecognizer *)pan
{
    CGPoint point = [pan locationInView:self.view];

    if (CGRectContainsPoint(self.textField.frame, point))
    {
        if (point.y < self.view.frame.size.height - 100 && point.y > 50)
        {
            self.textField.frame = CGRectMake(0, point.y - 15, self.view.frame.size.width, 40);
        }

    }
}

-(void)didTap:(UITapGestureRecognizer *)tap
{
    if (self.textField.isHidden)
    {
    self.textField.hidden = 0;
    [self.textField becomeFirstResponder];
    }
    else
    {
        if (self.textField.hasText)
        {
            [self.textField resignFirstResponder];
        }
        else
        {
            [self.textField resignFirstResponder];
            self.textField.hidden = 1;
        }
    }
}

-(IBAction)didPressSendButton:(id)sender
{
    if (self.videoURL)
    {
    [self.delegate sendBackImage:self.image orVideo:self.videoURL];
    }
    else
    {
    [self.delegate sendBackImage:self.image orVideo:0];
    }
}

-(IBAction)didPressClose:(id)sender
{
//    [self dismissViewControllerAnimated:0 completion:0];
    [self.navigationController popViewControllerAnimated:0];
}


-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (!textField.hasText)
    {
        textField.hidden = YES;
    }
    [textField resignFirstResponder];
    return YES;
}

@end
