#import <UIKit/UIKit.h>

@interface SearchBlockerView : UIView
@end

@implementation SearchBlockerView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return self;
}
@end

static void applyBlocker(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = nil;
        for (UIWindow *window in [UIApplication sharedApplication].windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }
        if (!keyWindow && [UIApplication sharedApplication].windows.count > 0) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        if (keyWindow) {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            SearchBlockerView *blocker = [[SearchBlockerView alloc] initWithFrame:CGRectMake(0, 44, screenWidth, 80)];
            blocker.backgroundColor = [UIColor clearColor];
            blocker.userInteractionEnabled = YES;
            blocker.tag = 999988;
            
            [[keyWindow viewWithTag:999988] removeFromSuperview];
            [keyWindow addSubview:blocker];
        }
    });
}

__attribute__((constructor)) static void init(void) {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification * _Nonnull note) {
        applyBlocker();
    }];
}
