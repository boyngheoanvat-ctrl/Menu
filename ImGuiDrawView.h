#import <UIKit/UIKit.h>

@interface ImGuiDrawView : UIViewController
@property (assign, nonatomic) BOOL isMenuOpen;
- (void)drawView;
+ (void)showChange:(BOOL)open;
@end
