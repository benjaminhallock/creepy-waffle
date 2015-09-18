
#import "CustomCameraView.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/ImageIO.h>

#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>

#import "AppConstant.h"
#import "MessagesView.h"
#import "ProgressHUD.h"
#import <Parse/Parse.h>
#import "KLCPopup.h"
#import "UIColor.h"
#import <Photos/Photos.h>
#import "MessagesView.h"
#import "utilities.h"
#import "AppDelegate.h"
#import "SelectChatroomView.h"

#import "PictureViewController.h"

#import "CameraCollectionViewCell.h"
#import "LXReorderableCollectionViewFlowLayout.h"

#import <MediaPlayer/MediaPlayer.h>

@interface CustomCameraView () <UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate, LXReorderableCollectionViewDataSource, UICollectionViewDelegate, LXReorderableCollectionViewDelegateFlowLayout, UIAlertViewDelegate, PictureViewerDelegate>

@property (strong, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic,strong) ALAssetsLibrary *library;
@property AVCaptureSession *captureSession;
@property AVCaptureStillImageOutput *stillImageOutput;
@property AVCaptureMovieFileOutput *movieFileOutput;
@property AVCaptureDevice *device;
@property AVCaptureFlashMode *flashMode;
@property AVCaptureFocusMode *focusmode;
@property AVCaptureDeviceInput *audioInput;
@property UIImagePickerController *picker;

@property (weak, nonatomic) IBOutlet UIButton *flashButton;
@property (weak, nonatomic) IBOutlet UIButton *NextButton;
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraRollButton;
@property (weak, nonatomic) IBOutlet UIButton *takePictureButton;

@property (weak , nonatomic) IBOutlet UIButton *cancelButton;
@property (weak , nonatomic) IBOutlet UIButton *rightButton;
@property (weak , nonatomic) IBOutlet UIButton *counterButton;

@property (weak, nonatomic) NSTimer *timer;
@property BOOL didPickImageFromAlbum;
@property int initialScrollOffsetPosition;
@property UIRefreshControl *refreshControl;
@property BOOL didViewJustLoad;

@property KLCPopup *pop;
@property (strong, nonatomic) UIPageControl *pageControl;
@property UIScrollView *scrollViewPop;
@property UIActivityIndicatorView *spinner;
@property MPMoviePlayerController *mp;

@property BOOL isCapturingVideo;
@property (atomic) int captureVideoNowCounter;
@property BOOL isDoneScrolling;

@property NSTimer *progressTimer;
@property NSTimer *timerForRecButton;
@property NSDate *startDate;

@property UIView *videoView;
@property UIView *videoView2;

@property BOOL isCameraRollEnabled;
@end

@implementation CustomCameraView

@synthesize delegate;

- (id)initWithPopUp:(BOOL)popup
{
    self = [super init];
    if (self)
    {
        self.isPoppingUp = popup;
    }
    return self;
}

-(void) clearCameraStuff
{
    [self.arrayOfTakenPhotos removeAllObjects];
    [self.collectionView reloadData];
    [self setButtonsWithImage:0 withVideo:0 AndURL:0];
    [self performSelector:@selector(popRoot) withObject:self afterDelay:1.0f];
}

-(void) popRoot
{
    [self.navigationController popToRootViewControllerAnimated:0];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self runCamera];

    [self.collectionView registerNib:[UINib nibWithNibName:@"CameraCollectionViewCell" bundle:0] forCellWithReuseIdentifier:@"Cell"];

    self.captureVideoNowCounter = 0;

    self.takePictureButton.userInteractionEnabled = NO;
    self.switchCameraButton.userInteractionEnabled = NO;
    self.flashButton.userInteractionEnabled = NO;
    self.cameraRollButton.userInteractionEnabled = NO;
    self.NextButton.hidden = YES;
    self.counterButton.hidden = YES;

    //    [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];

    self.collectionView.backgroundColor = [UIColor clearColor];

    if (_isPoppingUp)
    {
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.spinner startAnimating];
        self.spinner.frame = CGRectMake(self.view.frame.size.width/2 + 10, self.view.frame.size.height + 28, 40, 40);
        [self.view addSubview:self.spinner];
    }

    if (!self.scrollView)
    {
        self.scrollView = [(AppDelegate *)[[UIApplication sharedApplication] delegate] scrollView];
    }

    //Taking screenshots of videos

    _didViewJustLoad = true;

    self.counterButton.backgroundColor = [UIColor benFamousOrange];

    self.navigationController.navigationBarHidden = 1;

    self.cancelButton.hidden = !_isPoppingUp;
    self.rightButton.hidden = _isPoppingUp;

    self.cancelButton.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor blackColor];

    //NOT ADDED.
    //    _refreshControl = [[UIRefreshControl alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    //    [_refreshControl beginRefreshing];

    self.arrayOfTakenPhotos = [NSMutableArray new];


    self.cameraRollButton.backgroundColor = [UIColor clearColor];

    self.switchCameraButton.backgroundColor = [UIColor clearColor];
    self.flashButton.backgroundColor = [UIColor clearColor];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(didTapForFocusAndExposurePoint:)];
    tap.delegate = self;
    [self.view addGestureRecognizer:tap];

    UILongPressGestureRecognizer *press = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressFocusAndExposure:)];
    press.delegate = self;
    [self.view addGestureRecognizer:press];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearCameraStuff) name:NOTIFICATION_CLEAR_CAMERA_STUFF object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableScrollview:) name:NOTIFICATION_ENABLESCROLLVIEW object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionViewDidDelete:) name:NOTIFICATION_DELETE_CAMERA_PIC object:0];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(collectionViewDidTap:) name:NOTIFICATION_TAP_CAMERA_PIC object:0];
}

- (void)removeInputs
{
    for (AVCaptureInput *input in self.captureSession.inputs)
    {
        [self.captureSession removeInput:input];
    }

    for(AVCaptureOutput *output in self.captureSession.outputs)
    {
        [self.captureSession removeOutput:output];
    }
}



-(void)enableScrollview:(NSNotification *)notification
{
    self.scrollView.scrollEnabled = YES;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:1];
#warning GETS CALLED WITH MESSAGESVIEW SIMULTANEOUSLY.

    self.navigationController.navigationBarHidden = 1;

    //Only way to check which camera is up and what screen is present.
    if (self.scrollView.contentOffset.x == 0)
    {
        if (!_didViewJustLoad && !_isPoppingUp)
        {
            [self.scrollView setContentOffset:CGPointMake(1, 0)];
            [self.scrollView setContentOffset:CGPointMake(0, 0)];
        }
    }
}

- (void)setPopUp
{
    [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];

    _isPoppingUp = YES;

    self.cancelButton.hidden = !_isPoppingUp;
    self.rightButton.hidden = _isPoppingUp;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self setLatestImageOffAlbum];

    [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationFade];

    self.cancelButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.rightButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.switchCameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    if (!_didViewJustLoad)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];

        if (self.navigationController.visibleViewController == self && self.scrollView.contentOffset.x  < 2)
        {
            [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:1];
            self.scrollView.scrollEnabled = YES;
        }
        else
        {
            //            [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
        }
    } else {
        _didViewJustLoad = NO;
        //            self.scrollView.scrollEnabled = NO;
    }

    self.takePictureButton.hidden = self.arrayOfTakenPhotos.count < 5 ? NO : YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (_isPoppingUp)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
        self.scrollView.scrollEnabled = NO;
    }

    self.scrollView.scrollEnabled = NO;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];

    if (_isPoppingUp)
    {
        self.scrollView.scrollEnabled = NO;
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    }
}

//Drag photos on top of other photos, then switch positions.

-(void) runCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
#warning FIX THIS EVENTUALLLYYYYY
        //      [self stopCaptureSession];

        if (!self.captureSession) [self setupCaptureSessionAndStartRunning];
        else [self startRunningCaptureSession];

    } else if (self.didPickImageFromAlbum)   _didPickImageFromAlbum = NO;
}

- (void)startRunningCaptureSession
{
    if (!self.captureSession.isRunning)
    {
        [self.captureSession startRunning];
        self.videoPreviewView.hidden = NO;
        [self.spinner stopAnimating];
    }
}


#pragma mark - IBACTIONS

- (IBAction)onAlbumPressed:(UIButton *)button
{
    [UIView animateWithDuration:.3f animations:^{
        button.transform = CGAffineTransformMakeScale(1.8,1.8);
        button.transform = CGAffineTransformMakeScale(1,1);
        button.transform = CGAffineTransformMakeScale(1.8,1.8);
        button.transform = CGAffineTransformMakeScale(1,1);
    }];
    if (self.arrayOfTakenPhotos.count == 5) {
        [ProgressHUD showError:@"No More Pictures"];
    } else {
        [self setupImagePicker];
    }
}

- (void)stopCaptureSession
{
    if (self.captureSession)
    {
        [self.captureSession stopRunning];
    }
}

//PART OF CAMERA TOUCHDOWN EVENT.
- (IBAction)buttonRelease:(UIButton *)button
{
    [UIView animateWithDuration:.3f animations:^{
        button.transform = CGAffineTransformMakeScale(.8,.8);
        button.transform = CGAffineTransformMakeScale(1.2, 1.2);
    }];
}

- (IBAction)onTakePhotoPressed:(UIButton *)button
{
    [UIView animateWithDuration:.3f animations:^{
        button.transform = CGAffineTransformMakeScale(1.8,1.8);
        button.transform = CGAffineTransformMakeScale(1,1);
        button.transform = CGAffineTransformMakeScale(1.8,1.8);
        button.transform = CGAffineTransformMakeScale(1,1);
    }];

    if (self.captureSession)
    {
        [self captureNow];
    }
}

- (IBAction)onFlashPressed:(id)sender
{
    if (self.flashMode == AVCaptureFlashModeOn) {
        self.flashMode = AVCaptureFlashModeOff;
        [self.flashButton setImage:[UIImage imageNamed:@"flash-off"] forState:UIControlStateNormal];
    } else if (self.flashMode == AVCaptureFlashModeOff) {
        self.flashMode = AVCaptureFlashModeOn;
        [self.flashButton setImage:[UIImage imageNamed:@"flash"] forState:UIControlStateNormal];
    }
}

- (IBAction)onCloseCameraPressed:(UIButton *)sender
{
    //    [self stopCaptureSession];

    if (self.picker) {
        [self.picker dismissViewControllerAnimated:1 completion:0];
    }


    self.isPoppingUp = NO;

    self.cancelButton.hidden = YES;
    self.rightButton.hidden = NO;

    PostNotification(NOTIFICATION_CAMERA_POPUP);

    [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];

    [self dismissViewControllerAnimated:0 completion:0];

    self.didPickImageFromAlbum = NO;
}



-(IBAction)didSlideRight:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width, 0) animated:YES];
}

- (void)updateUI:(NSTimer *)timer
{
    static int count =0; count++;

    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:self.startDate];

    int x = (int)self.arrayOfTakenPhotos.count;

    if (elapsedTime <= 10)
    {
        self.videoView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width , elapsedTime * -self.view.frame.size.height/10);
    }
    else
    {
        [self.takePictureButton setImage:[UIImage imageNamed:@"snap"] forState:UIControlStateNormal];
        [self.progressTimer invalidate];
        [self.timerForRecButton invalidate];
        [self captureStopVideoNow];
    }
}

#pragma mark - IMAGE PICKER

- (void)setupImagePicker
{
    if (_isCameraRollEnabled == NO)
    {
        if([[[UIDevice currentDevice] systemVersion] floatValue]<8.0)
        {
            UIAlertView* curr1=[[UIAlertView alloc] initWithTitle:@"Photos Not Enabled" message:@"Settings -> ben -> Photos" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            curr1.tag = 1;
            [curr1 show];
        }
        else
        {
            UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Photos Not Enabled" message:@"Settings -> ben -> Photos" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
            curr2.tag = 1;
            [curr2 show];
        }
    } else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
    {
        self.picker = [[UIImagePickerController alloc] init];

        self.picker.allowsEditing = 0;

        [self.picker setAutomaticallyAdjustsScrollViewInsets:1];

        self.picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;

        self.picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.picker.sourceType];

        self.picker.delegate = self;

        self.picker.navigationBar.backgroundColor = [UIColor benFamousGreen];

        //     [self stopCaptureSession];

        [self.navigationController presentViewController:self.picker animated:1 completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
            [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
        }];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{

    NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];

    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];

    NSLog(@"%@ MEDIA TYPE", mediaType);

    AVAsset *movie = [AVAsset assetWithURL:videoURL];
    CMTime movieLength = movie.duration;

    [ProgressHUD show:@""];

    if (movie)
    {
        if (CMTimeCompare(movieLength, CMTimeMake(11, 1)) == -1)
        {
            NSLog(@"GOOD MOVIE");
            AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
            AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
            generate1.appliesPreferredTrackTransform = YES;
            NSError *err = NULL;
            CMTime time = kCMTimeZero;
            CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];

            __block UIImage *one = [[UIImage alloc] initWithCGImage:oneRef];
            __block UIImage *video = [UIImage imageNamed:@"video"];

            NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"outputC%i.mov", _captureVideoNowCounter]];
            NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:outputPath])
            {
                if ([fileManager removeItemAtPath:outputPath error:0]) {
                    NSLog(@"REMOVED FILE");
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               if (one)
                               {
                                   NSLog(@"%@", NSStringFromCGSize(one.size));
                                   one = ResizeImage(one, one.size.width, one.size.height);
                                   one = [self drawImage:video inImage:one atPoint:CGPointMake((one.size.width/2 - video.size.width/2) , (one.size.height/2 - video.size.height/2))];
                               }
                               [UIView animateWithDuration:.3f animations:^
                                {
                                    self.collectionView.userInteractionEnabled = NO;
                                    self.collectionView.alpha = .5f;
                                    self.NextButton.userInteractionEnabled = NO;
                                    self.NextButton.alpha = .5;
                                    self.takePictureButton.userInteractionEnabled = 0;
                                    self.takePictureButton.alpha = .5f;
                                }];
                               [self.videoView removeFromSuperview];
                               [self.videoView2 removeFromSuperview];
                           });

            //Convert this giant file to something more managable.
            [self convertVideoToLowQuailtyWithInputURL:videoURL outputURL:outputURL handler:^(NSURL *output, bool success) {
                if (success)
                {
                    [self ShowVideo:one andURL:outputURL];
                    [ProgressHUD showSuccess:@""];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:.3f animations:^{
                            self.collectionView.userInteractionEnabled = YES;
                            self.collectionView.alpha = .5f;
                            self.NextButton.userInteractionEnabled = 1;
                            self.NextButton.alpha = .9;
                            self.takePictureButton.userInteractionEnabled = 1;
                            self.takePictureButton.alpha = 1;
                        }];
                    });
                    NSLog(@"SUCCESS");
                    //SAY THE BUTTON IS OKAY TO SEND.
                } else {
                    NSLog(@"FAIL");
                }
            }];

            [picker dismissViewControllerAnimated:1 completion:0];
            return;
        } else {
            NSLog(@"BAD MOVIE");
            [picker dismissViewControllerAnimated:1 completion:0];
            [ProgressHUD showError:@"Video Too Long (10s)"];
            return;
        }
    }


    UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];

    if (image.size.height/image.size.width * 9 != 16)
    {
        NSLog(@"%f", (image.size.height/image.size.width * 9));
        image = [self getSubImageFrom:image WithRect:CGRectMake(0, 0, 1080, 1920)];
        NSLog(@"%f %f", image.size.height, image.size.width);
    } else {
        NSLog(@"Image was perfectly sized");
    }

    self.didPickImageFromAlbum = YES;

    [picker dismissViewControllerAnimated:1 completion:^
     {
         [self setButtonsWithImage:image withVideo:false AndURL:0];

         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
         [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
         self.scrollView.scrollEnabled = YES;
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:1 completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
        self.scrollView.scrollEnabled = YES;
    }];
}

- (void)setLatestImageOffAlbum
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1)
    {
        NSLog(@"ios 8");
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
        PHFetchResult *fetchResult = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
        if (fetchResult)
        {
            PHAsset *lastAsset = [fetchResult lastObject];
            [[PHImageManager defaultManager] requestImageForAsset:lastAsset
                                                       targetSize:CGSizeMake(330, 320)
                                                      contentMode:PHImageContentModeDefault
                                                          options:PHImageRequestOptionsVersionCurrent
                                                    resultHandler:^(UIImage *result, NSDictionary *info) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            if (result)
                                                            {
                                                                _isCameraRollEnabled = YES;
                                                                self.cameraRollButton.alpha = 0;                                                [self.cameraRollButton setImage:result forState:UIControlStateNormal];

                                                                [UIView animateWithDuration:.3f animations:^{
                                                                    self.cameraRollButton.alpha = 1;
                                                                }];
                                                            }
                                                            else
                                                            {
                                                                NSLog(@"Camera Roll Error");
                                                                //                                                              Save bool to know if it is saed or not.
                                                            }
                                                        });
                                                    }];
        }
    }
    else
    {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        // Enumerate just the photos and videos group by using ALAssetsGroupSavedPhotos.
        [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop)
         {
             // Within the group enumeration block, filter to enumerate just photos.
             [group setAssetsFilter:[ALAssetsFilter allPhotos]];
             if ([group numberOfAssets] > 0)
                 // Chooses the photo at the last index
                 [group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *alAsset, NSUInteger index, BOOL *innerStop)
                  {
                      // The end of the enumeration is signaled by asset == nil.
                      if (alAsset)
                      {
                          ALAssetRepresentation *representation = [alAsset defaultRepresentation];
                          _isCameraRollEnabled = YES;
                          UIImage *image = [self cropImageCameraRoll:[UIImage imageWithCGImage:[representation fullScreenImage]]];
                          self.cameraRollButton.imageView.contentMode = UIViewContentModeScaleAspectFill;
                          self.cameraRollButton.alpha = 0;
                          [self.cameraRollButton setImage:image forState:UIControlStateNormal];

                          [UIView animateWithDuration:.3f animations:^{
                              self.cameraRollButton.alpha = 1;
                          }];

                          // Stop the enumerations
                          *stop = YES; *innerStop = YES;
                      }
                      else
                      {
                          NSLog(@"Camera roll error");
                      }
                  }];
         } failureBlock: ^(NSError *error) {
             NSLog(@"Cmaera roll error %@", error.userInfo);
         }];
    }

    self.cameraRollButton.layer.masksToBounds = 1;
    self.cameraRollButton.layer.cornerRadius = 10;
    self.cameraRollButton.backgroundColor = [UIColor benFamousGreen];
    self.cameraRollButton.layer.borderColor = [UIColor whiteColor].CGColor;
    self.cameraRollButton.layer.borderWidth = 3;
}


#pragma mark - CAMERA

// Create and configure a capture session and start it running
- (void)setupCaptureSessionAndStartRunning
{
    self.didPickImageFromAlbum = NO;

    NSError *error = nil;

    AVCaptureSession *session = [[AVCaptureSession alloc] init];

    session.sessionPreset = AVCaptureSessionPresetHigh; //FULL SCREEN;
    //    session.sessionPreset = AVCaptureSessionPresetPhoto;

    //    NOT USED YET
    //    CGRect layerRect = [[[self view] layer] bounds];
    //    [self.videoPreviewView setBounds:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    //    CGPoint point = CGPointMake(CGRectGetMidY(layerRect), CGRectGetMidX(layerRect));

    // Find a suitable AVCaptureDevice
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    [self setFlashMode:AVCaptureFlashModeOn forDevice:self.device];

    if ([self.device isFocusPointOfInterestSupported] && [self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        [self didTapForFocusAndExposurePoint:self.view.gestureRecognizers.lastObject];
    }

    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device
                                                                        error:&error];
    if (!input)
    {
        NSLog(@"No Camera Input");

        if([[[UIDevice currentDevice] systemVersion] floatValue]<8.0)
        {
            UIAlertView* curr1=[[UIAlertView alloc] initWithTitle:@"Camera not enabled" message:@"Settings -> ben -> Camera" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            curr1.tag = 121;
            [curr1 show];
        }
        else
        {
            UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Camera not enabled" message:@"Settings -> ben -> Camera" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
            curr2.tag=121;
            [curr2 show];
        }

        return;
    }

    if ([session canAddInput:input])
    {
        [session addInput:input];
    }

    // Create a VideoDataOutput and add it to the session
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    if ([session canAddOutput:output])
    {
        [session addOutput:output];
    }

    // Configure your output.
    dispatch_queue_t queue = dispatch_queue_create("myQueue", NULL);
    [output setSampleBufferDelegate:self queue:queue];

    // Specify the pixel format
    output.videoSettings =
    [NSDictionary dictionaryWithObject:
     [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]
                                forKey:(id)kCVPixelBufferPixelFormatTypeKey];

    //Stackoverflow help
    dispatch_queue_t layerQ = dispatch_queue_create("layerQ", NULL);
    dispatch_async(layerQ, ^
                   {
                       // Start the session running to start the flow of data
                       [session startRunning];

                       self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
                       NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
                       [self.stillImageOutput setOutputSettings:outputSettings];
                       [self.stillImageOutput automaticallyEnablesStillImageStabilizationWhenAvailable];

                       if ([session canAddOutput:self.stillImageOutput])
                       {
                           [session addOutput:self.stillImageOutput];
                       }

                       self.movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
                       self.movieFileOutput.minFreeDiskSpaceLimit = 1024*1024*10; // 10 MB
                       self.movieFileOutput.maxRecordedDuration = CMTimeMake(10, 1);

                       if ([session canAddOutput:_movieFileOutput])
                       {
                           [session addOutput:_movieFileOutput];
                       }

                       // Assign session to an ivar.
                       self.captureSession = session;

                       AVCaptureVideoPreviewLayer *previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
                       CGRect videoRect = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
                       previewLayer.frame = [UIScreen mainScreen].bounds; // Assume you want the preview layer to fill the view.
                       CGRect bounds = videoRect;
                       previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
                       previewLayer.bounds=bounds;
                       previewLayer.position=CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));

                       //Main thread does GUI
                       dispatch_async(dispatch_get_main_queue(), ^
                                      {
                                          [self.videoPreviewView.layer addSublayer:previewLayer];
                                          self.takePictureButton.userInteractionEnabled = YES;
                                          self.takePictureButton.userInteractionEnabled = YES;
                                          self.switchCameraButton.userInteractionEnabled = YES;
                                          self.flashButton.userInteractionEnabled = YES;
                                          self.cameraRollButton.userInteractionEnabled = YES;
                                          [self.spinner stopAnimating];
                                      });

                   });
}

-(void)deallocSession
{
    [self.videoPreviewView.layer.sublayers.lastObject removeFromSuperlayer];
    for(AVCaptureInput *input1 in self.captureSession.inputs) {
        [self.captureSession removeInput:input1];
    }

    for (AVCaptureOutput *output1 in self.captureSession.outputs)
    {
        [self.captureSession removeOutput:output1];
    }

    [self.captureSession stopRunning];
    self.captureSession = nil;
    self.stillImageOutput = nil;
    self.device = nil;

    //    input=nil;
    //    captureVideoPreviewLayer=nil;
    //    stillImageOutput=nil;
    //    self.vImagePreview=nil;
}

-(void) didTapForFocusAndExposurePoint:(UITapGestureRecognizer *)point
{
    NSLog(@"TAP FOR EXPOSURE");

    if (point.state == UIGestureRecognizerStateEnded)
    {
        CGPoint save = [point locationInView:self.view];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        view.layer.borderWidth = 3;
        view.layer.cornerRadius = 10;
        view.layer.borderColor = [UIColor whiteColor].CGColor;
        view.center = save;
        view.alpha = 0;
        [UIView animateWithDuration:0.3f animations:^{
            [self.view addSubview:view];
            view.alpha = 1;
            view.alpha = 0;
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];

        NSString *save2 = NSStringFromCGPoint(save);
        NSLog(@"%@ TAP", save2);
        save = CGPointMake(save.y/self.view.frame.size.height, (1 -save.x/self.view.frame.size.width));
        save2 = NSStringFromCGPoint(save);
        NSLog(@"%@ NEW", save2);

        if ([self.device lockForConfiguration:0]) {
            if (point) {
                NSLog(@"if point");
                [self.device setFocusPointOfInterest:save];
                [self.device setExposurePointOfInterest:save];
            }
            [self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
            [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [self.device unlockForConfiguration];
        }
    }
}

-(void) didLongPressFocusAndExposure:(UILongPressGestureRecognizer *)point
{
    if (point.state == UIGestureRecognizerStateBegan)
    {
        NSLog(@"HOLD");
        CGPoint save = [point locationInView:self.view];

        if (CGRectContainsPoint(self.takePictureButton.frame, save))
        {
            _isCapturingVideo = YES;
            NSLog(@"VIDEO");

            //ADD AUDIO INPUT
#warning WILL CAUSE RED BAR IF YOU DONT DISABLE IT.
            NSLog(@"Adding audio input");
            AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            NSError *error2 = nil;
            self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error2];

            if (self.audioInput && [_captureSession canAddInput:self.audioInput])
            {
                [self.captureSession addInput:self.audioInput];
            }
            else
            {
                if([[[UIDevice currentDevice] systemVersion] floatValue] < 8.0)
                {
                    UIAlertView *curr1 = [[UIAlertView alloc] initWithTitle:@"Microphone Not Enabled" message:@"Settings -> SnapBen -> Microphone" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil, nil];
                    curr1.tag = 66;
                    [curr1 show];
                }
                else
                {
                    UIAlertView *curr2 = [[UIAlertView alloc] initWithTitle:@"Microphone Not Enabled" message:@"Settings -> SnapBen -> Microphone" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Settings", nil];
                    curr2.tag = 66;
                    [curr2 show];
                }
                NSLog(@"NO AUDIO");
                return;
            }

            self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:.03 target:self selector:@selector(updateUI:) userInfo:nil repeats:YES];

            [_timer invalidate];

            self.collectionView.userInteractionEnabled = NO;
            self.NextButton.userInteractionEnabled = NO;

            //Juice
            self.videoView = [UIView new];
            self.videoView.layer.masksToBounds = 1;
            self.videoView.backgroundColor = [UIColor benFamousOrange];
            self.videoView.alpha = .9f;
            self.videoView.layer.cornerRadius = 0;
            self.videoView.layer.rasterizationScale = [UIScreen mainScreen].scale;
            self.videoView.layer.shouldRasterize = 1;
            self.videoView.layer.borderWidth = 0;
            self.videoView.layer.borderColor = [UIColor whiteColor].CGColor;
            [self.view addSubview:self.videoView];

            self.startDate = [NSDate date];

            [self.takePictureButton setImage:[UIImage imageNamed:@"snap2"] forState:UIControlStateNormal];

            self.timerForRecButton = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(bounceRecButton) userInfo:0 repeats:1];

            [UIView animateWithDuration:.3f animations:^
             {
                 self.takePictureButton.transform = CGAffineTransformMakeScale(1.4,1.4);
                 self.takePictureButton.transform = CGAffineTransformMakeScale(1.0,1.0);
             }];

            [self captureVideoNow];
            return;
        }

        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        view.layer.borderWidth = 5;
        view.layer.cornerRadius = 10;
        view.layer.borderColor = [UIColor whiteColor].CGColor;
        view.center = save;
        view.alpha = 0;
        [UIView animateWithDuration:0.9f animations:^{
            [self.view addSubview:view];
            view.alpha = 0;
            view.alpha = 1;
            view.backgroundColor = [UIColor lightTextColor];
        } completion:^(BOOL finished) {
            [view removeFromSuperview];
        }];

        NSString *save2 = {NSStringFromCGPoint(save)};
        NSLog(@"%@ HOLD", save2);

        save = CGPointMake(save.y/self.view.frame.size.height, (1 -save.x/self.view.frame.size.width));
        save2 = NSStringFromCGPoint(save);
        NSLog(@"%@ NEW", save2);

        if ([self.device lockForConfiguration:0])
        {
            if (point)
            {
                NSLog(@"if point");
                [self.device setFocusPointOfInterest:save];
                [self.device setExposurePointOfInterest:save];
            }
            [self.device setExposureMode:AVCaptureExposureModeLocked];
            [self.device setFocusMode:AVCaptureFocusModeLocked];
            [self.device unlockForConfiguration];
        }
    }
    else if (point.state ==UIGestureRecognizerStateEnded)
    {
        if (_isCapturingVideo)
        {
            _isCapturingVideo = NO;
            NSLog(@"STOPPING VIDEO");
            [self captureStopVideoNow];

            dispatch_async(dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:.3f animations:^
                 {
                     self.takePictureButton.transform = CGAffineTransformMakeScale(1.8,1.8);
                     self.takePictureButton.transform = CGAffineTransformMakeScale(1,1);
                     self.takePictureButton.transform = CGAffineTransformMakeScale(1.8,1.8);
                     self.takePictureButton.transform = CGAffineTransformMakeScale(1,1);
                 }];
                [self.takePictureButton setImage:[UIImage imageNamed:@"snap"] forState:UIControlStateNormal];
            });

            [self.timerForRecButton invalidate];
            [self.progressTimer invalidate];


        }
    }
}

-(IBAction)switchCameraTapped:(id)sender
{
    //Change camera source
    if(_captureSession)
    {
        //Indicate that some changes will be made to the session
        [_captureSession beginConfiguration];

        //Remove existing input
        AVCaptureInput* currentCameraInput = [_captureSession.inputs objectAtIndex:0];
        [_captureSession removeInput:currentCameraInput];

        [self cameraWithPosition:AVCaptureDevicePositionBack];

        //Get new input
        AVCaptureDevice *newCamera = nil;
        if(((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionBack)
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionFront];
        }
        else
        {
            newCamera = [self cameraWithPosition:AVCaptureDevicePositionBack];
        }

        //Add input to session
        AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:nil];
        if ([_captureSession canAddInput:newVideoInput])
        {
            [_captureSession addInput:newVideoInput];
        }
        //Commit all the configuration changes at once
        [_captureSession commitConfiguration];
    }
}

// Find a camera with the specified AVCaptureDevicePosition, returning nil if one is not found
- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if ([device position] == position) return device;
    }
    return nil;
}

- (void)captureNow
{
    self.takePictureButton.userInteractionEnabled = NO;

    AVCaptureConnection *videoConnection = nil;

    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
            {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) { break; }
    }

    // Set flash mode
    if (self.flashMode == AVCaptureFlashModeOff) {
        [self setFlashMode:AVCaptureFlashModeOff forDevice:self.device];
    } else {
        [self setFlashMode:AVCaptureFlashModeOn forDevice:self.device];
    }

    // Flash the screen white and fade it out to give UI feedback that a still image was taken

    UIView *flashView = [[UIView alloc] initWithFrame:self.videoPreviewView.window.bounds];
    flashView.backgroundColor = [UIColor whiteColor];
    [self.videoPreviewView.window addSubview:flashView];

    float flashDuration = self.flashMode == AVCaptureFlashModeOff ? 0.6f : 1.5f;

    [UIView animateWithDuration:flashDuration
                     animations:^{
                         flashView.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         [flashView removeFromSuperview];
                     }
     ];

    if (self.device.position == AVCaptureDevicePositionFront)
    {
        NSLog(@"SELFIE");
        //Put filter on image afterwards;
    }

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         if (!error)
         {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
             NSLog(@"%f height %f width", image.size.height, image.size.width);

             //             [self setButtonsWithImage:image withVideo:false AndURL:0];

             [self ShowPicture:image];

             self.takePictureButton.userInteractionEnabled = YES;
         } else {
             NSLog(@"%@",error.userInfo);
             self.takePictureButton.userInteractionEnabled = YES;
         }
     }];
}

-(void)captureVideoNow
{
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"output%i.mov", _captureVideoNowCounter]];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if ([fileManager fileExistsAtPath:outputPath])
    {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == YES)
        {
            _captureVideoNowCounter++;
        }
        else
        {
            NSLog(@"error %@", error.userInfo);
            _captureVideoNowCounter++;
            [self captureVideoNow];
            return;
        }
    }

    NSLog(@"Path to video: %@", outputURL.path);

    [self.movieFileOutput startRecordingToOutputFileURL:outputURL recordingDelegate:self];
}

-(void)captureStopVideoNow
{
    [self.movieFileOutput stopRecording];

    [_captureSession removeInput:self.audioInput];
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"FINISH");

    [ProgressHUD show:@""];
    AVAsset *movie = [AVAsset assetWithURL:outputFileURL];
    CMTime movieLength = movie.duration;

    if (movie)
    {
        [self.videoView removeFromSuperview];
        [self.videoView2 removeFromSuperview];
        if (CMTimeCompare(movieLength, CMTimeMake(1, 1)) == -1)
        {
            NSLog(@"TOO SHORT");
            [ProgressHUD showError:@"Too short"];
        }
        else
            if (CMTimeCompare(movieLength, CMTimeMake(11, 1)) == -1)
            {
                NSLog(@"GOOD MOVIE");

                //Get Image of first frame for picture.
                AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:outputFileURL options:nil];
                AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
                generate1.appliesPreferredTrackTransform = YES;
                NSError *err = NULL;
                CMTime time = kCMTimeZero;
                CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];


//                Making output url to convert the video to. with a thumbnail
                __block UIImage *one = [[UIImage alloc] initWithCGImage:oneRef];
                __block UIImage *video = [UIImage imageNamed:@"video"];
                NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), [NSString stringWithFormat:@"outputC%i.mov", _captureVideoNowCounter]];
                NSLog(@"Output: %@", outputPath);
                NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
                NSFileManager *fileManager = [NSFileManager defaultManager];
                if ([fileManager fileExistsAtPath:outputPath])
                {
                    [fileManager removeItemAtPath:outputPath error:0];
                }

                dispatch_async(dispatch_get_main_queue(), ^
                               {
                                   if (one)
                                   {
                                       NSLog(@"%@", NSStringFromCGSize(one.size));
                                       one = ResizeImage(one, one.size.width, one.size.height);
                                       one = [self drawImage:video inImage:one atPoint:CGPointMake((one.size.width/2 - video.size.width/2) , (one.size.height/2 - video.size.height/2))];
                                   }

                                   [UIView animateWithDuration:.3f animations:^
                                    {
                                        self.collectionView.userInteractionEnabled = NO;
                                        self.collectionView.alpha = .5f;
                                        self.takePictureButton.userInteractionEnabled = NO;
                                        self.takePictureButton.alpha = .5f;
                                        self.NextButton.userInteractionEnabled = NO;
                                        self.NextButton.alpha = .5;
                                    }];
                               });

                //Convert this giant file to something more managable.
                [self convertVideoToLowQuailtyWithInputURL:outputFileURL outputURL:outputURL handler:^(NSURL *output, bool success) {
                    if (success) {
//                        SENDING BACK THE VIDEO AND THUMBNAIL
                        [self ShowVideo:one andURL:output];
                        [ProgressHUD showSuccess:@""];

                        dispatch_async(dispatch_get_main_queue(), ^{
                            [UIView animateWithDuration:.3f animations:^{
                                self.collectionView.userInteractionEnabled = true;
                                self.collectionView.alpha = 1.0f;
                                self.takePictureButton.userInteractionEnabled = 1;
                                self.takePictureButton.alpha = 1;
                                self.NextButton.userInteractionEnabled = 1;
                                self.NextButton.alpha = .9;
                            }];
                            NSLog(@"SUCCESS");
                        });
                    } else {
                        NSLog(@"FAIL");
                    }
                }];

                return;
            } else {
                NSLog(@"BAD MOVIE");
                [ProgressHUD showError:@"Video Too Long (10s)"];
                return;
            }
    }
}

- (void)convertVideoToLowQuailtyWithInputURL:(NSURL*)inputURL
                                   outputURL:(NSURL *)outputURL
                                     handler:(void (^)(NSURL *output, bool success))handler
{
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:inputURL options:nil];
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputURL;
    exportSession.outputFileType =AVFileTypeQuickTimeMovie;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted)
        {
            //Need main thread for gui stuff.
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(outputURL,true);
            });
        } else if (exportSession.status == AVAssetExportSessionStatusFailed)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(0,false);
            });
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag
        == 66)
    {
        //code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag
        == 1)
    {
        //code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
    if (buttonIndex != alertView.cancelButtonIndex && alertView.tag
        == 121)
    {
        //code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
}

//Save to camera roll
- (void)video:(NSString *)videoPath didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo
{
    if (error == nil) {
        [[[UIAlertView alloc] initWithTitle:@"Saved to camera roll" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"Failed to save" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections {
    NSLog(@"START");
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"DROPPING");
}

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
}

-(void) animateNextButton
{
    if (!self.NextButton.isHidden)
    {
        [UIView animateKeyframesWithDuration:.5f delay:0.0f options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
            self.NextButton.transform = CGAffineTransformMakeScale(1.0,1.0);
            self.NextButton.transform = CGAffineTransformMakeScale(2.0,2.0);
            self.NextButton.transform = CGAffineTransformMakeScale(1.0,1.0);
        } completion:0];
    }
}

-(void)bounceRecButton
{
    [UIView animateKeyframesWithDuration:.5f delay:0.0f options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.0,1.0);
        self.takePictureButton.transform = CGAffineTransformMakeScale(2.0,2.0);
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.0,1.0);
    } completion:0];
}

-(void)ShowPicture:(UIImage *)image
{
    if (image)
    {
         PictureViewController *picture = [[PictureViewController alloc] initWithVideo:0 orPicture:image];
        picture.delegate = self;
        [self.navigationController pushViewController:picture animated:0];
    }
}

//DELEGATE
-(void)sendBackImage:(UIImage *)image orVideo:(NSURL *)videoURL
{
    if (videoURL)
    {
        NSDictionary *dictionary = [NSDictionary dictionaryWithObject:image forKey:videoURL.path];
        [delegate sendBackPictures:@[dictionary] withBool:1 andComment:0];
        [self dismissViewControllerAnimated:1 completion:0];
    }
    else
    {
        [delegate sendBackPictures:@[image] withBool:1 andComment:0];
        [self dismissViewControllerAnimated:1 completion:0];
    }
}

-(void)ShowVideo:(UIImage *)thumbnail andURL:(NSURL *)videoURL
{
    PictureViewController *picture = [[PictureViewController alloc] initWithVideo:videoURL orPicture:thumbnail];
    picture.delegate = self;
    [self.navigationController pushViewController:picture animated:0];
}

//Depending on number of pictures, line them up accordingly when deleted.
- (void)setButtonsWithImage:(UIImage *)image withVideo:(BOOL)isVideoTag AndURL:(NSURL *)videoURL
{
    if (image)
    {
        if (!isVideoTag && !videoURL)
        {
            [self.arrayOfTakenPhotos addObject:image];
        }
        else
        {
            //            Attach IMAGE TO PFFILE
            NSDictionary *dictionary = [NSDictionary dictionaryWithObject:image forKey:videoURL.path];
            [self.arrayOfTakenPhotos addObject:dictionary];
        }

        self.counterButton.titleLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.arrayOfTakenPhotos.count];

        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.arrayOfTakenPhotos.count - 1 inSection:0];
        [self.collectionView insertItemsAtIndexPaths:@[indexPath]];

        [_timer invalidate];
        _timer = [NSTimer scheduledTimerWithTimeInterval:1.5f target:self selector:@selector(animateNextButton) userInfo:0 repeats:1];
    }

    if (_arrayOfTakenPhotos.count < 5 && self.takePictureButton.isHidden)
    {
        [UIView animateWithDuration:1.0f animations:^{
            self.takePictureButton.alpha = 0;
            self.takePictureButton.alpha = 1;
            self.cameraRollButton.alpha = 0;
            self.cameraRollButton.alpha = 1;
            self.takePictureButton.hidden = NO;
            self.cameraRollButton.hidden = NO;
        }];
    }
    else if (_arrayOfTakenPhotos.count > 0 && self.NextButton.isHidden)
    {
        [UIView animateWithDuration:0.3f animations:^
         {
             self.NextButton.hidden = NO;
             self.counterButton.hidden = NO;
             self.NextButton.alpha = 0;
             self.NextButton.alpha = 1;
             self.counterButton.alpha = 0;
             self.counterButton.alpha = 1;
         }];
    }
    else if (_arrayOfTakenPhotos.count == 0 && self.NextButton.isHidden == NO)
    {
        [UIView animateWithDuration:.3f animations:^{
            self.NextButton.alpha = 1;
            self.NextButton.alpha = 0;
            self.counterButton.alpha = 1;
            self.counterButton.alpha = 0;
            self.NextButton.hidden = YES;
            self.counterButton.hidden = YES;
        }];
    }
    else if (self.arrayOfTakenPhotos.count == 5)
    {
        [UIView animateWithDuration:1.0f animations:^{
            self.takePictureButton.alpha = 1;
            self.takePictureButton.alpha = 0;
            self.cameraRollButton.alpha = 1;
            self.cameraRollButton.alpha = 0;
            self.takePictureButton.hidden = YES;
            self.cameraRollButton.hidden = YES;
        }];
    }
}


//NEXT BUTTON PRESSED
- (IBAction)didPressNextButton:(UIButton *)button
{

    [UIView animateWithDuration:.3 animations:^{
        button.transform = CGAffineTransformMakeScale(0.3,0.3);
        button.transform = CGAffineTransformMakeScale(1,1);
    }];

    button.userInteractionEnabled = NO;
    if (_arrayOfTakenPhotos.count == 0)
    {
        [ProgressHUD showError:@"No Pictures Taken"];
        button.userInteractionEnabled = YES;
    }
    else
    {
        if (self.isPoppingUp)
        {
            self.isPoppingUp = NO;

            self.cancelButton.hidden = YES;
            self.rightButton.hidden = NO;

            [delegate sendBackPictures:_arrayOfTakenPhotos withBool:YES andComment:@""];

            button.userInteractionEnabled = YES;

            [self dismissViewControllerAnimated:0 completion:0];

            [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];

            PostNotification(NOTIFICATION_CAMERA_POPUP);
        }
        else
        {
            SelectChatroomView *selectView = [SelectChatroomView new];
            self.delegate = selectView;
            [[UIApplication sharedApplication] setStatusBarHidden:0];
            [delegate sendBackPictures:_arrayOfTakenPhotos withBool:YES andComment:@""];

            [self.navigationController pushViewController:selectView animated:1];
            button.userInteractionEnabled = YES;
        }
    }
}

- (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ([device hasFlash] && [device isFlashModeSupported:flashMode])
    {
        NSError *error = nil;
        if ([device lockForConfiguration:&error])
        {
            [device setFlashMode:flashMode];
            [device unlockForConfiguration];
        }
        else
        {
            self.flashButton.hidden = YES;
            NSLog(@"%@", error);
        }
    }
}


// get sub image
- (UIImage*)getSubImageFrom:(UIImage *)imageTaken WithRect:(CGRect)rect
{
    CGFloat height = imageTaken.size.height;
    CGFloat width = imageTaken.size.width;
    NSLog(@"%f, %f", height, width);

    CGFloat newWidth = height * 9 / 16;
    CGFloat newX = abs((width - newWidth)) / 2;

    CGRect cropRect = CGRectMake(newX,0, newWidth ,height);

    UIGraphicsBeginImageContext(cropRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    // translated rectangle for drawing sub image
    CGRect drawRect = CGRectMake(-cropRect.origin.x, -cropRect.origin.y, imageTaken.size.width, imageTaken.size.height);
    // clip to the bounds of the image context
    // not strictly necessary as it will get clipped anyway?
    CGContextClipToRect(context, CGRectMake(0, 0, cropRect.size.width, cropRect.size.height));
    // draw image
    [imageTaken drawInRect:drawRect];

    // grab image
    UIImage* subImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return subImage;
}

-(UIImage *)cropImageCameraRoll:(UIImage *)imageTaken
{

    CGFloat height = imageTaken.size.height;
    CGFloat width = imageTaken.size.width;
    NSLog(@"%f, %f", height, width);

    CGFloat newWidth = height * 9 / 16;
    CGFloat newX = abs((width - newWidth)) / 2;

    CGRect cropRect = CGRectMake(newX,0, newWidth ,height);
    NSLog(@"%@", NSStringFromCGRect(cropRect));

    CGImageRef imageRef = CGImageCreateWithImageInRect([imageTaken CGImage], cropRect);
    UIImage *imageCropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    //    CGImageRef imageRef = CGImageCreateWithImageInRect([imageTaken CGImage], cropRect);
    //   UIImage *imageCropped = [UIImage imageWithCGImage:imageRef scale:imageTaken.scale orientation:imageTaken.imageOrientation];
    //    if (imageCropped.size.height/ imageCropped.size.width != 16/9) {
    //        return [UIImage imageWithCGImage:CGImageCreateWithImageInRect([imageTaken CGImage], cropRect) scale:imageTaken.scale orientation:imageTaken.imageOrientation];
    //    }
    return ResizeImage(imageCropped, 1080, 1920);
}

-(UIView *)addMovieWithURL:(NSURL *)url andRect:(CGRect)rect
{
    // Create an AVURLAsset with an NSURL containing the path to the video
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];

    // Create an AVPlayerItem using the asset
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];

    // Create the AVPlayer using the playeritem
    AVPlayer *player = [AVPlayer playerWithURL:url];

    // Create an AVPlayerLayer using the player
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];

    UIView *view = [[UIView alloc] initWithFrame:rect];
    view.backgroundColor = [UIColor whiteColor];

    // Add it to your view's sublayers
    [view.layer addSublayer:playerLayer];

    // You can play/pause using the AVPlayer object
    //    [player pause];

    // You can seek to a specified time
    [player seekToTime:kCMTimeZero];

    [player play];

    return view;
}

-(void)collectionViewDidDelete:(NSNotification *)notification
{
    NSIndexPath *index = notification.userInfo[@"index"];
    [self.arrayOfTakenPhotos removeObjectAtIndex:index.item];
    [self.collectionView deleteItemsAtIndexPaths:@[index]];

    self.counterButton.titleLabel.text = [NSString stringWithFormat:@"%lu",(unsigned long)self.arrayOfTakenPhotos.count];
    //Reset
    [self setButtonsWithImage:0 withVideo:0 AndURL:0];
}

-(NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.arrayOfTakenPhotos.count;
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)fromIndexPath willMoveToIndexPath:(NSIndexPath *)toIndexPath
{
    id object = [self.arrayOfTakenPhotos objectAtIndex:fromIndexPath.item];
    [self.arrayOfTakenPhotos removeObjectAtIndex:fromIndexPath.item];
    [self.arrayOfTakenPhotos insertObject:object atIndex:toIndexPath.item];
}

-(UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(60, self.view.frame.size.width - 100, 0, 0);
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    CameraCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];

    cell.collectionView = self.collectionView;

    if (self.arrayOfTakenPhotos.count)
    {
        id object = [self.arrayOfTakenPhotos objectAtIndex:indexPath.item];

        if ([object isKindOfClass:[NSDictionary class]]) {
            UIImage *image = [(NSDictionary *)object allValues].firstObject;
            NSString *path = [(NSDictionary *)object allKeys].firstObject;
            [cell.buttonImage setImage:image forState:UIControlStateNormal];
            cell.buttonImage.titleLabel.text = path;

        } else if ([object isKindOfClass:[UIImage class]]) {
            //Image
            [cell.buttonImage setImage:object forState:UIControlStateNormal];
        }
    }
    return cell;
}

-(void)collectionViewDidTap:(NSNotification *)notification
{
    NSIndexPath *index = notification.userInfo[@"index"];
    [self collectionView:self.collectionView didSelectItemAtIndexPath:index];
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    int indexx = (int)indexPath.row;

    self.scrollViewPop = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollViewPop.bounces = YES;
    self.scrollViewPop.pagingEnabled = 1;
    self.scrollViewPop.alwaysBounceHorizontal = 1;
    self.scrollViewPop.delegate = self;
    self.scrollViewPop.tag = 22;
    self.scrollViewPop.directionalLockEnabled = YES;
    self.scrollViewPop.showsHorizontalScrollIndicator = 0;

    _arrayOfScrollview = [NSMutableArray arrayWithCapacity:self.arrayOfTakenPhotos.count];

    self.scrollViewPop.contentSize = CGSizeMake(self.view.bounds.size.width * self.arrayOfTakenPhotos.count, self.view.bounds.size.width);

    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.scrollViewPop.frame.size.height - 20, self.scrollViewPop.frame.size.width, 10)];
    [self.pageControl setNumberOfPages:_arrayOfTakenPhotos.count];
    [self.pageControl setCurrentPage:(indexx)];

    int count = (int)self.arrayOfTakenPhotos.count;

    for (id pictureOrDic in self.arrayOfTakenPhotos)
    {
        CGRect rect = CGRectMake(([self.arrayOfTakenPhotos indexOfObject:pictureOrDic] * self.view.bounds.size.width - 2) + 2, 0, self.view.frame.size.width, self.view.frame.size.height);

        if ([pictureOrDic isKindOfClass:[NSDictionary class]]) // VIDEO
        {
            NSDictionary *dic = (NSDictionary *)pictureOrDic;
            NSString *path = dic.allKeys.firstObject;
            NSURL *url = [NSURL fileURLWithPath:path];

            int index = (int)[self.arrayOfTakenPhotos indexOfObject:pictureOrDic];

            MPMoviePlayerController *moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:url];
            moviePlayer.view.frame = rect;
            moviePlayer.view.layer.shouldRasterize = 1;
            moviePlayer.view.layer.rasterizationScale = [UIScreen mainScreen].scale;
            moviePlayer.view.layer.masksToBounds = YES;
            moviePlayer.view.contentMode = UIViewContentModeScaleToFill;
            moviePlayer.view.layer.cornerRadius = moviePlayer.view.frame.size.width/10;
            moviePlayer.view.layer.borderColor = [UIColor whiteColor].CGColor;
            moviePlayer.view.layer.borderWidth = 5;
            moviePlayer.view.layer.cornerRadius = 10;
            moviePlayer.view.userInteractionEnabled = 1;
            moviePlayer.view.clipsToBounds = YES;

            [moviePlayer setScalingMode:MPMovieScalingModeAspectFill];
            [moviePlayer setMovieSourceType:MPMovieSourceTypeFile];
            moviePlayer.controlStyle = MPMovieControlStyleNone;
            moviePlayer.repeatMode = MPMovieRepeatModeOne;
            [moviePlayer setShouldAutoplay:NO];
            moviePlayer.backgroundView.alpha = 0;

            moviePlayer.view.backgroundColor = [UIColor lightGrayColor];
            moviePlayer.backgroundView.backgroundColor = [UIColor lightGrayColor];

            [moviePlayer play];

            UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 40, 40)];
            closeButton.imageView.hidden = YES;
            [closeButton addTarget:self action:@selector(didTap:) forControlEvents:UIControlEventTouchUpInside];
            [closeButton setImage:[UIImage imageNamed:ASSETS_CLOSE] forState:UIControlStateNormal];
            closeButton.backgroundColor = [UIColor benFamousGreen];
            closeButton.layer.masksToBounds = 1;
            closeButton.layer.cornerRadius = 5;
            closeButton.layer.borderColor = [UIColor whiteColor].CGColor;
            closeButton.layer.borderWidth = 2;
            [moviePlayer.view addSubview:closeButton];

            [self.scrollViewPop addSubview:moviePlayer.view];
            [self.arrayOfScrollview addObject:moviePlayer];
            count--;

            if (count == 0)
            {
                [self.scrollViewPop setContentOffset:CGPointMake((self.view.frame.size.width * indexx), 0) animated:0];

                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
                [self.pop addGestureRecognizer:tap];

                self.pop = [KLCPopup popupWithContentView:self.scrollViewPop showType:KLCPopupShowTypeSlideInFromLeft dismissType:KLCPopupDismissTypeSlideOutToLeft maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:0 dismissOnContentTouch:0];

                [self.pop addSubview:self.pageControl];

                [self.pop show];
            }
        }
        else if ([pictureOrDic isKindOfClass:[UIImage class]])
        {

            UIImageView *popUpImageView;
            UIImage *image = (UIImage *)pictureOrDic;
            popUpImageView = [[UIImageView alloc] initWithFrame:rect];
            popUpImageView.image = image;
            popUpImageView.layer.masksToBounds = YES;
            popUpImageView.contentMode = UIViewContentModeScaleToFill;
            popUpImageView.layer.cornerRadius = popUpImageView.frame.size.width/10;
            popUpImageView.layer.borderColor = [UIColor whiteColor].CGColor;
            popUpImageView.layer.borderWidth = 5;
            popUpImageView.layer.cornerRadius = 10;
            popUpImageView.userInteractionEnabled = YES;

            UIButton *saveImageButton = [[UIButton alloc] initWithFrame:CGRectMake(15, 15, 40, 40)];

            saveImageButton.imageView.hidden = YES;

            [saveImageButton addTarget:self action:@selector(didTap:) forControlEvents:UIControlEventTouchUpInside];

            [saveImageButton setImage:[UIImage imageNamed:ASSETS_CLOSE] forState:UIControlStateNormal];
            saveImageButton.backgroundColor = [UIColor benFamousGreen];
            saveImageButton.layer.masksToBounds = 1;
            saveImageButton.layer.cornerRadius = 5;
            saveImageButton.layer.borderColor = [UIColor whiteColor].CGColor;
            saveImageButton.layer.borderWidth = 2;

            [popUpImageView addSubview:saveImageButton];

            [self.scrollViewPop addSubview:popUpImageView];
            [self.arrayOfScrollview addObject:popUpImageView];

            count--;

            if (count == 0)
            {
                [self.scrollViewPop setContentOffset:CGPointMake((self.view.frame.size.width * indexx), 0) animated:0];

                self.pop = [KLCPopup popupWithContentView:self.scrollViewPop showType:KLCPopupShowTypeSlideInFromLeft dismissType:KLCPopupDismissTypeSlideOutToLeft maskType:KLCPopupMaskTypeDimmed dismissOnBackgroundTouch:0 dismissOnContentTouch:0];

                UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
                [self.pop addGestureRecognizer:tap];

                [self.pop addSubview:self.pageControl];

                [self.pop show];
            }
            //Hid it in the KLCPopup code.
        }
    }//end for loop
}

//KLCPopup
- (void)didTap:(UITapGestureRecognizer *)tap
{
    [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];

    [self.pop dismiss:1];
    [KLCPopup dismissAllPopups];

    for (MPMoviePlayerController *object in self.arrayOfScrollview)
    {
        if ([object isKindOfClass:[MPMoviePlayerController class]])
        {
            [object stop];
            object.view.alpha = 0;
        }
    }
    self.scrollViewPop = nil;
    self.arrayOfScrollview = nil;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    //Stop the self.movieplayer in the button.
    //Unhide all the buttons back

    for (MPMoviePlayerController *object in self.arrayOfScrollview)
    {
        if ([object isKindOfClass:[MPMoviePlayerController class]])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [object stop];
                //                    [object setCurrentPlaybackTime:0.0f];
                //                    [object prepareToPlay];
            });
        }
    }
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView.tag == 22)
    {
        int x = (int)roundf(scrollView.contentOffset.x);
        int y = (int)self.view.frame.size.width;
        
        if (x % y == 0)
        {
            _isDoneScrolling = NO;
        }
        
        CGFloat index = scrollView.contentOffset.x / self.view.frame.size.width;
        
        int xx = roundf(index);
        
        dispatch_async(dispatch_get_main_queue(),^{

            [self.pageControl setCurrentPage:(xx)];
        });
        
        if (_isDoneScrolling == NO)
        {
            _isDoneScrolling = YES;
            if ([[self.arrayOfScrollview objectAtIndex:index] isKindOfClass:[MPMoviePlayerController class]])
            {
                [(MPMoviePlayerController *)[self.arrayOfScrollview objectAtIndex:index] play];
            }
        }
    }
}

-(void)checkMovieStatus:(NSNotification *)notification
{
    if(self.mp.readyForDisplay)
    {
        [self.mp play];
    }
}

- (UIImage *) drawImage:(UIImage *)fgImage
                inImage:(UIImage *)bgImage
                atPoint:(CGPoint)point
{
    UIImage *newImage;
    
    UIGraphicsBeginImageContextWithOptions(bgImage.size, FALSE, 0.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    [bgImage drawInRect:CGRectMake( 0, 0, bgImage.size.width, bgImage.size.height)];
    [fgImage drawInRect:CGRectMake(point.x, point.y, fgImage.size.width, fgImage.size.height)];
    UIGraphicsPopContext();
    newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
