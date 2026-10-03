#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface SafeSearchBlockerView : UIView
@end

@implementation SafeSearchBlockerView
// בולע כל לחיצה שמגיעה אליו
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    return self;
}
@end

@implementation UINavigationBar (BlockSearch)

- (void)custom_layoutSubviews {
    [self custom_layoutSubviews];
    
    // בדיקה האם מדובר בבר הראשי של רשימת השיחות
    UIViewController *parentVC = nil;
    UIResponder *responder = self.nextResponder;
    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            parentVC = (UIViewController *)responder;
            break;
        }
        responder = responder.nextResponder;
    }
    
    // אם הבר שייך למסך מודאלי (כגון שיתוף/העברה), לא נחסום
    if (parentVC && parentVC.presentingViewController != nil) {
        UIView *existing = [self viewWithTag:887766];
        if (existing) {
            [existing removeFromSuperview];
        }
        return;
    }

    // הגדרת שכבת חסימה מעל אזור שורת החיפוש בתוך ה-Navigation Bar
    static NSInteger blockerTag = 887766;
    UIView *blocker = [self viewWithTag:blockerTag];
    if (!blocker) {
        CGRect zeroRect = (CGRect){{0, 0}, {0, 0}};
        blocker = [[SafeSearchBlockerView alloc] initWithFrame:zeroRect];
        blocker.tag = blockerTag;
        blocker.backgroundColor = [UIColor clearColor];
        blocker.userInteractionEnabled = YES;
        [self addSubview:blocker];
    }
    
    // כיסוי מדויק של שטח ה-Navigation Bar
    blocker.frame = self.bounds;
    [self bringSubviewToFront:blocker];
}

@end

__attribute__((constructor)) static void initSafeBlocker(void) {
    Class class = [UINavigationBar class];
    SEL origSEL = @selector(layoutSubviews);
    SEL swizSEL = @selector(custom_layoutSubviews);
    
    Method origMethod = class_getInstanceMethod(class, origSEL);
    Method swizMethod = class_getInstanceMethod(class, swizSEL);
    
    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}
