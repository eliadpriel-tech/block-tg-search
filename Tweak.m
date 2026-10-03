#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIView (BlockTelegramSearch)
@end

@implementation UIView (BlockTelegramSearch)

- (UIView *)custom_hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [self custom_hitTest:point withEvent:event];
    
    if (hitView) {
        // בודק את שרשרת התצוגות של הרכיב שנלחץ
        UIView *current = hitView;
        while (current) {
            NSString *className = NSStringFromClass([current class]);
            
            // זיהוי רכיב החיפוש של טלגרם ברשימת השיחות
            if ([className containsString:@"SearchBar"] || 
                [className containsString:@"SearchContentNode"] || 
                [className containsString:@"ChatListSearch"]) {
                
                // בדיקה אם אנחנו בתוך מסך מודאלי (כגון העברת הודעה / Forward)
                UIResponder *responder = current;
                while (responder) {
                    if ([responder isKindOfClass:[UIViewController class]]) {
                        UIViewController *vc = (UIViewController *)responder;
                        if (vc.presentingViewController != nil) {
                            // מאפשר חיפוש בחלון שיתוף/העברה
                            return hitView;
                        }
                        break;
                    }
                    responder = responder.nextResponder;
                }
                
                // מבטל את הלחיצה על שורת החיפוש במסך הראשי
                return nil;
            }
            current = current.superview;
        }
    }
    
    return hitView;
}

@end

__attribute__((constructor)) static void initTweak(void) {
    Class class = [UIView class];
    SEL origSEL = @selector(hitTest:withEvent:);
    SEL swizSEL = @selector(custom_hitTest:withEvent:);
    
    Method origMethod = class_getInstanceMethod(class, origSEL);
    Method swizMethod = class_getInstanceMethod(class, swizSEL);
    
    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}
