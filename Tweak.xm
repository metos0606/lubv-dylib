// LUBV Ultimate - In-Game GUI Control
// For injection with E-sign

#import <substrate.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// ============================================================
// SETTINGS MANAGER
// ============================================================

@interface LUBVSettings : NSObject
@property (nonatomic, assign) BOOL alwaysImpostor;
@property (nonatomic, assign) BOOL noKillCooldown;
@property (nonatomic, assign) BOOL alwaysCanKill;
@property (nonatomic, assign) BOOL alwaysCanVent;
@property (nonatomic, assign) BOOL alwaysCanSabotage;
@property (nonatomic, assign) BOOL alwaysCanReport;
@property (nonatomic, assign) BOOL espEnabled;
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL showGUI;
@property (nonatomic, assign) BOOL wallhack;
@property (nonatomic, assign) BOOL instantTasks;
+ (instancetype)sharedInstance;
@end

@implementation LUBVSettings

+ (instancetype)sharedInstance {
    static LUBVSettings *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[LUBVSettings alloc] init];
        instance.alwaysImpostor = YES;
        instance.noKillCooldown = YES;
        instance.alwaysCanKill = YES;
        instance.alwaysCanVent = YES;
        instance.alwaysCanSabotage = YES;
        instance.alwaysCanReport = YES;
        instance.espEnabled = YES;
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.showGUI = YES;
        instance.wallhack = YES;
        instance.instantTasks = NO;
    });
    return instance;
}

@end

// ============================================================
// FLOATING GUI BUTTON
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableArray *switches;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:0.95];
        self.layer.cornerRadius = 25;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 8;
        self.layer.shadowOpacity = 0.6;
        
        [self setTitle:@"L" forState:UIControlStateNormal];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableArray array];
        [self createMenu];
    }
    return self;
}

- (void)createMenu {
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(-200, -350, 240, 420)];
    self.menuView.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.97];
    self.menuView.layer.cornerRadius = 20;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 4);
    self.menuView.layer.shadowRadius = 12;
    self.menuView.layer.shadowOpacity = 0.9;
    self.menuView.hidden = YES;
    [self addSubview:self.menuView];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 40, 240, 380)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.menuView addSubview:self.scrollView];
    
    // Title bar
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 240, 40)];
    titleBar.backgroundColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:0.2];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(40, 5, 160, 30)];
    title.text = @"LUBV CONTROLS";
    title.textColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:1];
    title.font = [UIFont boldSystemFontOfSize:16];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(200, 5, 30, 30);
    [closeBtn setTitle:@"X" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    NSArray *features = @[
        @"Always Impostor",
        @"No Kill Cooldown",
        @"Always Can Kill",
        @"Always Can Vent",
        @"Always Can Sabotage",
        @"Always Can Report",
        @"ESP Outline",
        @"God Mode",
        @"No Vent Cooldown",
        @"Fast Speed",
        @"Wallhack",
        @"Instant Tasks"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"alwaysCanSabotage", @"alwaysCanReport",
        @"espEnabled", @"godMode", @"noVentCooldown", @"fastSpeed",
        @"wallhack", @"instantTasks"
    ];
    
    for (int i = 0; i < features.count; i++) {
        int y = 8 + (i * 32);
        
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, y, 230, 30)];
        if (i % 2 == 0) {
            rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.5];
        }
        rowView.layer.cornerRadius = 8;
        [self.scrollView addSubview:rowView];
        
        UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(5, y + 2, 50, 26)];
        switchControl.tag = i;
        switchControl.onTintColor = [UIColor colorWithRed:0.91 green:0.27 blue:0.38 alpha:1];
        switchControl.transform = CGAffineTransformMakeScale(0.7, 0.7);
        [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
        
        LUBVSettings *settings = [LUBVSettings sharedInstance];
        BOOL isOn = [[settings valueForKey:keys[i]] boolValue];
        switchControl.on = isOn;
        
        [self.scrollView addSubview:switchControl];
        [self.switches addObject:switchControl];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(60, y + 4, 160, 22)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:12];
        [self.scrollView addSubview:label];
    }
    
    self.scrollView.contentSize = CGSizeMake(240, features.count * 32 + 20);
}

- (void)switchToggled:(UISwitch *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"alwaysCanSabotage", @"alwaysCanReport",
        @"espEnabled", @"godMode", @"noVentCooldown", @"fastSpeed",
        @"wallhack", @"instantTasks"
    ];
    
    [settings setValue:@(sender.on) forKey:keys[sender.tag]];
    NSLog(@"LUBV: %@ = %@", keys[sender.tag], sender.on ? @"ON" : @"OFF");
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    self.menuView.hidden = !self.menuView.hidden;
    
    if (self.isMenuOpen) {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:0 animations:^{
            self.menuView.alpha = 1.0;
        } completion:nil];
    } else {
        [UIView animateWithDuration:0.2 animations:^{
            self.menuView.alpha = 0.0;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    newCenter.x = MAX(40, MIN(screenBounds.size.width - 40, newCenter.x));
    newCenter.y = MAX(40, MIN(screenBounds.size.height - 40, newCenter.y));
    
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

// ============================================================
// INJECT GUI
// ============================================================

static LUBVGUIButton *guiButton = nil;

__attribute__((constructor)) static void initialize() {
    NSLog(@"========================================");
    NSLog(@"LUBV ULTIMATE Dylib Loaded!");
    NSLog(@"========================================");
    NSLog(@"Double tap with 2 fingers to hide/show GUI");
    NSLog(@"Drag the L button anywhere");
    NSLog(@"========================================");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        
        guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 100, 50, 50)];
        [keyWindow addSubview:guiButton];
    });
}

// ============================================================
// FEATURE HOOKS (Using Method Swizzling)
// ============================================================

static void setupHooks() {
    Class playerClass = NSClassFromString(@"PlayerControl");
    if (playerClass) {
        // Always Impostor
        Method isImpostor = class_getInstanceMethod(playerClass, @selector(IsImpostor));
        if (isImpostor) {
            IMP newImp = imp_implementationWithBlock(^BOOL(id self) {
                if ([LUBVSettings sharedInstance].alwaysImpostor) {
                    return YES;
                }
                return ((BOOL (*)(id, SEL))method_getImplementation(isImpostor))(self, @selector(IsImpostor));
            });
            method_setImplementation(isImpostor, newImp);
        }
        
        // Always Can Kill
        Method canKill = class_getInstanceMethod(playerClass, @selector(CanKill));
        if (canKill) {
            IMP newImp = imp_implementationWithBlock(^BOOL(id self) {
                if ([LUBVSettings sharedInstance].alwaysCanKill) {
                    return YES;
                }
                return ((BOOL (*)(id, SEL))method_getImplementation(canKill))(self, @selector(CanKill));
            });
            method_setImplementation(canKill, newImp);
        }
        
        // Always Can Vent
        Method canVent = class_getInstanceMethod(playerClass, @selector(CanVent));
        if (canVent) {
            IMP newImp = imp_implementationWithBlock(^BOOL(id self) {
                if ([LUBVSettings sharedInstance].alwaysCanVent) {
                    return YES;
                }
                return ((BOOL (*)(id, SEL))method_getImplementation(canVent))(self, @selector(CanVent));
            });
            method_setImplementation(canVent, newImp);
        }
    }
}

__attribute__((constructor)) static void hooks() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        setupHooks();
    });
}
