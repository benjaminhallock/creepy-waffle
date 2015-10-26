
#import <UIKit/UIKit.h>

@interface UIColor (JSQMessages)

#pragma mark - Message bubble colors

/**
 *  @return A color object containing HSB values similar to the iOS 7 messages app green bubble color.
 */
+ (UIColor *)jsq_messageBubbleGreenColor;

/**
 *  @return A color object containing HSB values similar to the iOS 7 messages app blue bubble color.
 */
+ (UIColor *)jsq_messageBubbleBlueColor;

/**
 *  @return A color object containing HSB values similar to the iOS 7 red color.
 */
+ (UIColor *)jsq_messageBubbleRedColor;

/**
 *  @return A color object containing HSB values similar to the iOS 7 messages app light gray bubble color.
 */
+ (UIColor *)jsq_messageBubbleLightGrayColor;

+ (UIColor *)benFlatPeach;
+ (UIColor *)benFamousGreen;
+ (UIColor *)benFamousOrange;
+ (UIColor *)benFlatGreen;
+ (UIColor *)benFlatOrange;
+ (UIColor *)benMustardYellow;
+ (UIColor *)benBubbleGreen;
+ (UIColor *)benForestGreen;
+ (UIColor *)benDarkBlue;
+ (UIColor *)benFlatRed;
+ (UIColor *)benFlatterGreen;
+ (UIColor *)mustardGreen;


+(UIColor *)ben1A;
+(UIColor *)ben1B;
+(UIColor *)ben1C;
+(UIColor *)ben1D;
+(UIColor *)ben1E;
+(UIColor *)ben2A;
+(UIColor *)ben2B;
+(UIColor *)ben2C;
+(UIColor *)ben2D;
+(UIColor *)ben2E;
+(UIColor *)ben3A;
+(UIColor *)ben3B;
+(UIColor *)ben3C;
+(UIColor *)ben3D;
+(UIColor *)ben3E;
+(UIColor *)ben4A;
+(UIColor *)ben4B;
+(UIColor *)ben4C;
+(UIColor *)ben4D;

+(UIColor *)ben4E;


+ (UIColor *)blueTintColor;

+(UIColor *)benRandomCore;

+ (NSArray *)arrayOfColorsCore;


+ (UIColor *) colorFromString:(NSString *)string;
+(UIColor *)colorWithColor:(UIColor *)color;
+ (NSString *) stringFromColor:(UIColor *)color;

#pragma mark - Utilities

/**
 *  Creates and returns a new color object whose brightness component is decreased by the given value, using the initial color values of the receiver.
 *
 *  @param value A floating point value describing the amount by which to decrease the brightness of the receiver.
 *
 *  @return A new color object whose brightness is decreased by the given values. The other color values remain the same as the receiver.
 */
- (UIColor *)jsq_colorByDarkeningColorWithValue:(CGFloat)value;

@end