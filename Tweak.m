#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface UIResponder (BlockSearchKeyboard)
@end

@implementation UIResponder (BlockSearchKeyboard)

- (BOOL)custom_becomeFirstResponder {
    // בודק את שרשרת הרכיבים של השדה שמנסה לפתוח את המקלדת
    if ([self isKindOfClass:[UIView class]]) {
        UIView *current = (UIView *)self;
        while (current) {
            NSString *className = NSStringFromClass([current class]);
            
            // אם הרכיב שייך לשורת חיפוש בטלגרם/נייסגרם
            if ([className rangeOfString:@"Search" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                
                // בדיקה אם מדובר בחלון מודאלי (כגון שיתוף או העברת הודעה - Forward)
                UIResponder *responder = current;
                while (responder) {
                    if ([responder isKindOfClass:[UIViewController class]]) {
                        UIViewController *vc = (UIViewController *)responder;
                        if (vc.presentingViewController != nil) {
                            // מאפשר למקלדת לעלות בחלונות שיתוף
                            return [self custom_becomeFirstResponder];
                        }
                        break;
                    }
                    responder = responder.nextResponder;
                }
                
                // מונע מהמקלדת להיפתח בשורת החיפוש
                return NO;
            }
            current = current.superview;
        }
    }
    
    // בכל שאר המקומות (הזנת מספר טלפון, כתיבת הודעה בצ'אט וכו') - המקלדת תעלה כרגיל
    return [self custom_becomeFirstResponder];
}

@end

__attribute__((constructor)) static void initKeyboardBlocker(void) {
    Class class = [UIResponder class];
    SEL origSEL = @selector(becomeFirstResponder);
    SEL swizSEL = @selector(custom_becomeFirstResponder);
    
    Method origMethod = class_getInstanceMethod(class, origSEL);
    Method swizMethod = class_getInstanceMethod(class, swizSEL);
    
    if (origMethod && swizMethod) {
        method_exchangeImplementations(origMethod, swizMethod);
    }
}
