
#import "CustomCameraView.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "AppConstant.h"
#import "ProgressHUD.h"
#import <Photos/Photos.h>
#import "utilities.h"
#import "PictureViewController.h"

@interface CustomCameraView () <UIImagePickerControllerDelegate, UIGestureRecognizerDelegate, AVCaptureFileOutputRecordingDelegate, UIScrollViewDelegate, UIAlertViewDelegate, PictureViewerDelegate>

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
@property (weak, nonatomic) IBOutlet UIButton *switchCameraButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraRollButton;
@property (strong, nonatomic) IBOutlet UIButton *takePictureButton;
@property (weak , nonatomic) IBOutlet UIButton *cancelButton;

@property (weak, nonatomic) NSTimer *timer;
@property BOOL didPickImageFromAlbum;
@property int initialScrollOffsetPosition;
@property UIRefreshControl *refreshControl;
@property BOOL didViewJustLoad;

@property CAShapeLayer *circle;
@property (strong, nonatomic) UIPageControl *pageControl;
@property UIScrollView *scrollViewPop;
@property UIActivityIndicatorView *spinner;

@property BOOL isCapturingVideo;
@property (atomic) int captureVideoNowCounter;
@property BOOL isDoneScrolling;

@property NSTimer *progressTimer;
@property NSTimer *timerForRecButton;
@property NSDate *startDate;
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
    [self performSelector:@selector(popRoot) withObject:self afterDelay:1.0f];
}

-(void) popRoot
{
    [self.navigationController popToRootViewControllerAnimated:0];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.didViewJustLoad = true;

    NSLog(@"%f", self.view.frame.size.height);
//    [self.collectionView registerNib:[UINib nibWithNibName:@"CameraCollectionViewCell" bundle:0] forCellWithReuseIdentifier:@"Cell"];

    self.captureVideoNowCounter = 0;

    self.takePictureButton.userInteractionEnabled = NO;
    self.switchCameraButton.userInteractionEnabled = NO;
    self.flashButton.userInteractionEnabled = NO;
    self.cameraRollButton.userInteractionEnabled = NO;

    //Taking screenshots of videos
    _didViewJustLoad = true;
    self.navigationController.navigationBarHidden = 1;
    self.cancelButton.backgroundColor = [UIColor clearColor];
    self.view.backgroundColor = [UIColor blackColor];
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
//    self.scrollView.scrollEnabled = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:1];

    if (_isPoppingUp && _didViewJustLoad)
    {
        NSLog(@"%f", self.view.frame.size.height);
        self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self.spinner startAnimating];
        self.spinner.frame = CGRectMake(self.view.frame.size.width/2 - 20, self.view.frame.size.height - 60, 40, 40);
        [self.view addSubview:self.spinner];
        self.didViewJustLoad = false;
    }

    [self runCamera];
    self.navigationController.navigationBarHidden = 1;
}

- (void)setPopUp
{
    [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
    _isPoppingUp = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

//    [self setLatestImageOffAlbum];

//    self.takePictureButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 - 8, self.view.frame.size.height, 82, 82)];
//    [self.takePictureButton setImage:[UIImage imageNamed:@"snap1"] forState:UIControlStateNormal];
    [self.takePictureButton addTarget:self action:@selector(onTakePhotoPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.takePictureButton addTarget:self action:@selector(buttonRelease:) forControlEvents:UIControlEventTouchDown];
//    [self.view addSubview:self.takePictureButton];

    [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationFade];
    self.cancelButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.switchCameraButton.imageView.contentMode = UIViewContentModeScaleAspectFit;

    if (!_didViewJustLoad)
    {
        [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
    } else {
        _didViewJustLoad = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

//Drag photos on top of other photos, then switch positions.
-(void) runCamera
{
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
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
        [self setupImagePicker];
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
    [UIView animateWithDuration:1.0f delay:1.0
         usingSpringWithDamping:0.2f initialSpringVelocity:0
                        options:0 animations:^{
        button.transform = CGAffineTransformMakeScale(.8,.8);
        button.transform = CGAffineTransformMakeScale(1.2, 1.2);
    } completion:0];
}

- (IBAction)onTakePhotoPressed:(UIButton *)button
{
    if (button)
    {
    [UIView animateWithDuration:.3f animations:^{
        button.transform = CGAffineTransformMakeScale(1.8,1.8);
        button.transform = CGAffineTransformMakeScale(1,1);
        button.transform = CGAffineTransformMakeScale(1.8,1.8);
        button.transform = CGAffineTransformMakeScale(1,1);
    }];
    }

    if (self.captureSession)
    {
        [self captureImageNow];
    }
}

- (IBAction)onFlashPressed:(id)sender
{
    if (self.flashMode == AVCaptureFlashModeOn) {
        self.flashMode = AVCaptureFlashModeOff;
        [self.flashButton setImage:[UIImage imageNamed:@"Flash Off"] forState:UIControlStateNormal];
    } else if (self.flashMode == AVCaptureFlashModeOff) {
        self.flashMode = AVCaptureFlashModeOn;
        [self.flashButton setImage:[UIImage imageNamed:@"Flash On"] forState:UIControlStateNormal];
    }
}

- (IBAction)onCloseCameraPressed:(UIButton *)sender
{
    if (self.picker)  [self.picker dismissViewControllerAnimated:1 completion:0];
    self.isPoppingUp = NO;
    self.cancelButton.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:0 withAnimation:UIStatusBarAnimationSlide];
    [self dismissViewControllerAnimated:0 completion:0];
    self.didPickImageFromAlbum = NO;
}

- (void)updateUI:(NSTimer *)timer
{
    static int count =0; count++;

    NSTimeInterval elapsedTime = self.startDate.timeIntervalSinceNow;

    if (elapsedTime <= 10)
    {
//        self.videoView.frame = CGRectMake(0, self.view.frame.size.height, self.view.frame.size.width , elapsedTime * -self.view.frame.size.height/10);
    }
    else
    {
        [self.takePictureButton setImage:[UIImage imageNamed:@"snap1"] forState:UIControlStateNormal];
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
            UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Photos Not Enabled" message:@"Settings -> Snap Ben -> Photos" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
            [curr2 show];
    }
    else if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
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

#warning NOT USED
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
//                                    self.collectionView.userInteractionEnabled = NO;
//                                    self.collectionView.alpha = .5f;
                                    self.takePictureButton.userInteractionEnabled = 0;
                                    self.takePictureButton.alpha = .5f;
                                }];
                           });

            //Convert this giant file to something more managable.
            [self convertVideoToLowQuailtyWithInputURL:videoURL outputURL:outputURL handler:^(NSURL *output, bool success) {
                if (success)
                {
                    [self ShowVideo:one andURL:outputURL];
                    [ProgressHUD showSuccess:@""];

                    dispatch_async(dispatch_get_main_queue(), ^{
                        [UIView animateWithDuration:.3f animations:^{
//                            self.collectionView.userInteractionEnabled = YES;
//                            self.collectionView.alpha = .5f;
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
         [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
         [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:1 completion:^{
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        [[UIApplication sharedApplication] setStatusBarHidden:1 withAnimation:UIStatusBarAnimationSlide];
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

    session.sessionPreset = AVCaptureSessionPresetHigh;

    // Find a suitable AVCaptureDevice
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

    [self setFlashMode:AVCaptureFlashModeOff forDevice:self.device];

    if ([self.device isFocusPointOfInterestSupported] && [self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] && [self.device lockForConfiguration:0])
    {
        [self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        [self.device setFocusPointOfInterest:self.view.center];
        [self.device unlockForConfiguration];
    }

    // Create a device input with the device and add it to the session.
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:self.device
                                                                        error:&error];
    if (!input)
    {
            UIAlertView* curr2=[[UIAlertView alloc] initWithTitle:@"Camera not enabled" message:@"Settings -> Snap Ben -> Camera" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
            [curr2 show];
        return;
    } else if ([session canAddInput:input])
    {
        [session addInput:input];
    }

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

                       if ([session canAddOutput:self.movieFileOutput])
                       {
                           [session addOutput:self.movieFileOutput];
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
//                                        [self.videoPreviewView.layer addSublayer:previewLayer];
                                          [self.view.layer insertSublayer:previewLayer atIndex:0];
                                          self.takePictureButton.userInteractionEnabled = YES;
                                          self.takePictureButton.userInteractionEnabled = YES;
                                          self.switchCameraButton.userInteractionEnabled = YES;
                                          self.flashButton.userInteractionEnabled = YES;
                                          self.cameraRollButton.userInteractionEnabled = YES;
                                          [self.spinner stopAnimating];
                                      });

                   });
}


-(void) didTapForFocusAndExposurePoint:(UITapGestureRecognizer *)point
{
    NSLog(@"TAP FOR EXPOSURE");

    if (point.state == UIGestureRecognizerStateEnded)
    {
        CGPoint save = [point locationInView:self.view];
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        view.layer.borderWidth = 3;
        view.layer.cornerRadius = 30;
        view.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:.8f].CGColor;
        view.center = save;
        view.backgroundColor = [UIColor colorWithWhite:1.0f alpha:.5f];
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

        if ([self.device lockForConfiguration:0])
        {
            if (point)
            {
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

//      Calculate based on landscape point
        CGPoint save = [point locationInView:self.view];
        NSLog(@"%@ OLD", NSStringFromCGPoint(save));
       CGPoint saveNew = CGPointMake(save.y/self.view.frame.size.height, (1 -save.x/self.view.frame.size.width));
        NSLog(@"%@ NEW", NSStringFromCGPoint(saveNew));

//        IF you held down the camera button
        if (CGRectContainsPoint(self.takePictureButton.frame, save))
        {
            self.isCapturingVideo = YES;
            NSLog(@"VIDEO STARTING");

            //ADD AUDIO INPUT
#warning WILL CAUSE RED BAR IF YOU DONT DISABLE IT.
            NSLog(@"Adding audio input");

            [self.captureSession beginConfiguration];
            AVCaptureDevice *audioCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
            NSError *error2 = nil;
            self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioCaptureDevice error:&error2];
            if (self.audioInput && [self.captureSession canAddInput:self.audioInput])
            {
                [self.captureSession addInput:self.audioInput];
            }
            else
            {
                UIAlertView *curr2 = [[UIAlertView alloc] initWithTitle:@"Microphone Not Enabled" message:@"Settings -> SnapBen -> Microphone" delegate:self cancelButtonTitle:@"Dismiss" otherButtonTitles:@"Settings", nil];
                    [curr2 show];
                NSLog(@"NO AUDIO");
                return;
            }

            [self.captureSession commitConfiguration];

#warning BUTTON DOESN"T RESET IF YOU HOLD DOWN FOR TEN SECONDS
            [self.timer invalidate];
            [self startCircle];
            self.startDate = [NSDate date];

            [self.takePictureButton setImage:[UIImage imageNamed:@"snap2"] forState:UIControlStateNormal];
            self.timerForRecButton = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(bounceRecButton) userInfo:0 repeats:1];

            [UIView animateWithDuration:.3f animations:^
             {
                 self.takePictureButton.transform = CGAffineTransformMakeScale(1.4,1.4);
                 self.takePictureButton.transform = CGAffineTransformMakeScale(1.0,1.0);
             }];

            [self captureVideoNow];
        }
        else
        {
//           ELSE YOUR HOLDING SCREEN FOR LOCK A&E
            if ([self.device lockForConfiguration:0] && self.isCapturingVideo == false && [self.device isFocusModeSupported:AVCaptureFocusModeLocked])
            {
                if (point)
                {
                    NSLog(@"if point");
                    [self.device setFocusPointOfInterest:saveNew];
                    [self.device setExposurePointOfInterest:saveNew];
                }
                [self.device setExposureMode:AVCaptureExposureModeLocked];
                [self.device setFocusMode:AVCaptureFocusModeLocked];
                [self.device unlockForConfiguration];
            }
        }
    }
    else if (point.state ==UIGestureRecognizerStateEnded)
    {
        if (self.isCapturingVideo)
        {
            self.isCapturingVideo = NO;
            NSLog(@"STOPPING VIDEO");
            [self captureStopVideoNow];
        }
    }
}

-(void)startCircle
{
    // Set up the shape of the circle
    int radius = 80;
    self.circle = [CAShapeLayer layer];
    // Make a circular shape
    self.circle.path = [UIBezierPath bezierPathWithRoundedRect:self.view.frame cornerRadius:0].CGPath;

    // Center the shape in self.view
    self.circle.position = CGPointMake(0,
                                       0);

    // Configure the apperence of the circle
    self.circle.fillColor = [UIColor clearColor].CGColor;
    self.circle.strokeColor = [UIColor redColor].CGColor;
    self.circle.lineWidth = 5;

    // Add to parent layer
    [self.view.layer addSublayer:self.circle];

    // Configure animation
    CABasicAnimation *drawAnimation = [CABasicAnimation animationWithKeyPath:@"strokeEnd"];
    drawAnimation.duration            = 10.0; // "animate over 10 seconds or so.."
    drawAnimation.repeatCount         = 1.0;  // Animate only once..

    // Animate from no part of the stroke being drawn to the entire stroke being drawn
    drawAnimation.fromValue = [NSNumber numberWithFloat:0.0f];
    drawAnimation.toValue   = [NSNumber numberWithFloat:1.0f];

    // Experiment with timing to get the appearence to look the way you want
    drawAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];

    // Add the animation to the circle
    [self.circle addAnimation:drawAnimation forKey:@"drawCircleAnimation"];
}

-(void)stopCircle
{
    [self.circle removeAllAnimations];
    [self.circle removeFromSuperlayer];
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

- (void)captureImageNow
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
        if (videoConnection) break;
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

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
     {
         if (!error)
         {
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             UIImage *image = [UIImage imageWithData:imageData];


             AVCaptureInput* currentCameraInput = [self.captureSession.inputs objectAtIndex:0];
             //           Fix Orientation
             if (((AVCaptureDeviceInput*)currentCameraInput).device.position == AVCaptureDevicePositionFront)
             {
                 NSLog(@"SELFIE");
                 image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
                 //Put filter on image afterwards;
             }

             NSLog(@"%f height %f width", image.size.height, image.size.width);
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
}

-(void) endVideoResetButton
{
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self stopCircle];
        [self.takePictureButton setImage:[UIImage imageNamed:@"snap1"] forState:UIControlStateNormal];
    });
    [self.captureSession removeInput:self.audioInput];
    [self.timerForRecButton invalidate];
    [self.progressTimer invalidate];
}

-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"FINISH");
    [self endVideoResetButton];

    AVAsset *movie = [AVAsset assetWithURL:outputFileURL];
    CMTime movieLength = movie.duration;

    if (movie)
    {
        if (CMTimeCompare(movieLength, CMTimeMake(1, 1)) == -1)
        {
            NSLog(@"TOO SHORT");
            [self performSelector:@selector(onTakePhotoPressed:) withObject:self.takePictureButton afterDelay:.5];
            [ProgressHUD dismiss];
        }
        else if (CMTimeCompare(movieLength, CMTimeMake(11, 1)) == -1)
        {
                NSLog(@"GOOD MOVIE");

                [ProgressHUD show:@""];

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
//                                        self.collectionView.userInteractionEnabled = NO;
//                                        self.collectionView.alpha = .5f;
                                        self.takePictureButton.userInteractionEnabled = NO;
                                        self.takePictureButton.alpha = .5f;
                                    }];
                               });

                //Convert this giant file to something more managable.
                [self convertVideoToLowQuailtyWithInputURL:outputFileURL outputURL:outputURL handler:^(NSURL *output, bool success){
                    if (success) {
//                        SENDING BACK THE VIDEO AND THUMBNAIL
                        [self ShowVideo:one andURL:output];
                        [ProgressHUD showSuccess:@""];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [UIView animateWithDuration:.3f animations:^{
                                self.takePictureButton.userInteractionEnabled = 1;
                                self.takePictureButton.alpha = 1;
                            }];
                        });
                    } else {
                        NSLog(@"FAILED VIDEO CONVERSION");
                    }
                }];
            return;
        }
        else
        {
//            Shouldn't happen but incase it somehow was.
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
#warning DOWNGRADED FROM HIGH QUALITY
    exportSession.outputURL = outputURL;
    exportSession.outputFileType =AVFileTypeQuickTimeMovie;

    [exportSession exportAsynchronouslyWithCompletionHandler:^{
        if (exportSession.status == AVAssetExportSessionStatusCompleted)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(outputURL,true);
            });
        }
        else if (exportSession.status == AVAssetExportSessionStatusFailed)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                handler(0,false);
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
            handler(0, false);
            });
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex) {
        //code for opening settings app in iOS 8
        [[UIApplication sharedApplication] openURL:[NSURL  URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else
    {
        [self dismissViewControllerAnimated:1 completion:0];
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

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    // Add your code here that uses the image.
}

-(void)bounceRecButton
{
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:0 options:UIViewAnimationOptionAllowAnimatedContent animations:^{
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.2,1.2);
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.8,1.8);
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.2,1.2);
        } completion:0];

    /*
    [UIView animateKeyframesWithDuration:.5f delay:0.0f options:UIViewKeyframeAnimationOptionAllowUserInteraction animations:^{
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.0,1.0);
        self.takePictureButton.transform = CGAffineTransformMakeScale(2.0,2.0);
        self.takePictureButton.transform = CGAffineTransformMakeScale(1.0,1.0);
    } completion:0];
     */
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
