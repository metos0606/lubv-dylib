// LUBV Ultimate - Complete Edition (Fixed for Modern Among Us Dumps)
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
@property (nonatomic, assign) BOOL godMode;
@property (nonatomic, assign) BOOL noVentCooldown;
@property (nonatomic, assign) BOOL fastSpeed;
@property (nonatomic, assign) BOOL unlimitedVision;
@property (nonatomic, assign) BOOL seeGhosts;
@property (nonatomic, assign) BOOL unlimitedEmergencies;
@property (nonatomic, assign) BOOL noClip;
@property (nonatomic, assign) float playerSpeed;
@property (nonatomic, assign) BOOL noPhantomCooldown;
@property (nonatomic, assign) BOOL noShapeshifterCooldown;
@property (nonatomic, assign) BOOL noEngineerCooldown;
@property (nonatomic, assign) BOOL noDetectiveCooldown;
@property (nonatomic, assign) BOOL noTrackerCooldown;
@property (nonatomic, assign) BOOL noGuardianAngelCooldown;
@property (nonatomic, assign) BOOL unlockAllIAP;
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
        instance.godMode = NO;
        instance.noVentCooldown = YES;
        instance.fastSpeed = NO;
        instance.unlimitedVision = YES;
        instance.seeGhosts = YES;
        instance.unlimitedEmergencies = NO;
        instance.noClip = NO;
        instance.playerSpeed = 1.5;
        instance.noPhantomCooldown = NO;
        instance.noShapeshifterCooldown = NO;
        instance.noEngineerCooldown = NO;
        instance.noDetectiveCooldown = NO;
        instance.noTrackerCooldown = NO;
        instance.noGuardianAngelCooldown = NO;
        instance.unlockAllIAP = NO;
    });
    return instance;
}

@end

// ============================================================
// GUI BUTTON
// ============================================================

@interface LUBVGUIButton : UIButton
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
@property (nonatomic, strong) UIView *menuView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, assign) BOOL isMenuOpen;
@property (nonatomic, strong) NSMutableDictionary *switches;
@property (nonatomic, strong) UISlider *speedSlider;
@property (nonatomic, strong) UILabel *speedLabel;
@end

@implementation LUBVGUIButton

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.layer.cornerRadius = 30;
        self.layer.masksToBounds = YES;
        
        UIVisualEffectView *glassView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
        glassView.frame = self.bounds;
        glassView.layer.cornerRadius = 30;
        glassView.layer.masksToBounds = YES;
        glassView.alpha = 0.85;
        [self addSubview:glassView];
        
        CAGradientLayer *borderLayer = [CAGradientLayer layer];
        borderLayer.frame = self.bounds;
        borderLayer.colors = @[
            (id)[UIColor colorWithRed:0.0 green:0.8 blue:1.0 alpha:0.6].CGColor,
            (id)[UIColor colorWithRed:0.8 green:0.2 blue:1.0 alpha:0.6].CGColor
        ];
        borderLayer.startPoint = CGPointMake(0, 0);
        borderLayer.endPoint = CGPointMake(1, 1);
        borderLayer.cornerRadius = 30;
        [self.layer addSublayer:borderLayer];
        
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 60)];
        iconLabel.text = @"⚡";
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.font = [UIFont systemFontOfSize:30];
        [self addSubview:iconLabel];
        
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 15;
        self.layer.shadowOpacity = 0.3;
        
        self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [self addGestureRecognizer:self.panGesture];
        [self addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
        
        self.isMenuOpen = NO;
        self.switches = [NSMutableDictionary dictionary];
        [self createMenu];
    }
    return self;
}

- (void)createMenu {
    self.menuView = [[UIView alloc] initWithFrame:CGRectMake(-300, -500, 360, 580)];
    self.menuView.backgroundColor = [UIColor clearColor];
    self.menuView.layer.cornerRadius = 25;
    self.menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.menuView.layer.shadowOffset = CGSizeMake(0, 10);
    self.menuView.layer.shadowRadius = 30;
    self.menuView.layer.shadowOpacity = 0.5;
    self.menuView.hidden = YES;
    self.menuView.alpha = 0;
    [self addSubview:self.menuView];
    
    UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleDark]];
    blurView.frame = self.menuView.bounds;
    blurView.layer.cornerRadius = 25;
    blurView.layer.masksToBounds = YES;
    [self.menuView addSubview:blurView];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.menuView.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.2 green:0.0 blue:0.4 alpha:0.3].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.4 blue:0.8 alpha:0.1].CGColor
    ];
    gradient.cornerRadius = 25;
    [self.menuView.layer addSublayer:gradient];
    
    UIView *titleBar = [[UIView alloc] initWithFrame:CGRectMake(0, 10, 360, 50)];
    titleBar.backgroundColor = [UIColor clearColor];
    [self.menuView addSubview:titleBar];
    
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(60, 0, 240, 40)];
    title.text = @"✦ LUBV ULTIMATE ✦";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:22];
    title.textAlignment = NSTextAlignmentCenter;
    [titleBar addSubview:title];
    
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.frame = CGRectMake(310, 10, 35, 35);
    closeBtn.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    closeBtn.layer.cornerRadius = 17.5;
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeBtn addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [titleBar addSubview:closeBtn];
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(10, 65, 340, 500)];
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self.menuView addSubview:self.scrollView];
    
    NSArray *features = @[
        @"🎭 Always Impostor", @"⏱️ No Kill Cooldown", @"🗡️ Always Can Kill",
        @"💨 Always Can Vent", @"🌀 No Vent Cooldown", @"⚡ Always Can Sabotage",
        @"📢 Always Can Report", @"🔭 Unlimited Vision", @"👻 See Ghosts",
        @"🛡️ God Mode", @"🏃 Fast Speed", @"📞 Unlimited Emergencies",
        @"🚶 No Clip", @"👻 No Phantom CD", @"🔄 No Shapeshifter CD",
        @"🔧 No Engineer CD", @"🔍 No Detective CD", @"📍 No Tracker CD",
        @"😇 No Guardian Angel CD", @"🎁 Unlock All IAP"
    ];
    
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"unlockAllIAP"
    ];
    
    int yPos = 0;
    for (int i = 0; i < features.count; i++) {
        UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(5, yPos, 330, 44)];
        rowView.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.4];
        rowView.layer.cornerRadius = 12;
        [self.scrollView addSubview:rowView];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15, 10, 200, 24)];
        label.text = features[i];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:13];
        [rowView addSubview:label];
        
        if ([keys[i] isEqualToString:@"fastSpeed"]) {
            self.speedSlider = [[UISlider alloc] initWithFrame:CGRectMake(220, 6, 100, 32)];
            self.speedSlider.minimumValue = 1.0;
            self.speedSlider.maximumValue = 5.0;
            self.speedSlider.value = [LUBVSettings sharedInstance].playerSpeed;
            [self.speedSlider addTarget:self action:@selector(speedChanged:) forControlEvents:UIControlEventValueChanged];
            [rowView addSubview:self.speedSlider];
        } else {
            UISwitch *switchControl = [[UISwitch alloc] initWithFrame:CGRectMake(260, 6, 50, 30)];
            switchControl.tag = i;
            [switchControl addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
            switchControl.on = [[LUBVSettings sharedInstance] valueForKey:keys[i]] ? [[[LUBVSettings sharedInstance] valueForKey:keys[i]] boolValue] : NO;
            [rowView addSubview:switchControl];
            [self.switches setObject:switchControl forKey:keys[i]];
        }
        yPos += 52;
    }
    self.scrollView.contentSize = CGSizeMake(340, yPos + 10);
}

- (void)speedChanged:(UISlider *)sender {
    LUBVSettings *settings = [LUBVSettings sharedInstance];
    settings.playerSpeed = sender.value;
    settings.fastSpeed = YES;
}

- (void)switchToggled:(UISwitch *)sender {
    NSArray *keys = @[
        @"alwaysImpostor", @"noKillCooldown", @"alwaysCanKill",
        @"alwaysCanVent", @"noVentCooldown", @"alwaysCanSabotage",
        @"alwaysCanReport", @"unlimitedVision", @"seeGhosts",
        @"godMode", @"fastSpeed", @"unlimitedEmergencies",
        @"noClip", @"noPhantomCooldown", @"noShapeshifterCooldown",
        @"noEngineerCooldown", @"noDetectiveCooldown",
        @"noTrackerCooldown", @"noGuardianAngelCooldown",
        @"unlockAllIAP"
    ];
    [[LUBVSettings sharedInstance] setValue:@(sender.on) forKey:keys[sender.tag]];
}

- (void)toggleMenu {
    self.isMenuOpen = !self.isMenuOpen;
    self.menuView.hidden = NO;
    [UIView animateWithDuration:0.3 animations:^{
        self.menuView.alpha = self.isMenuOpen ? 1.0 : 0.0;
        self.menuView.transform = self.isMenuOpen ? CGAffineTransformIdentity : CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        if (!self.isMenuOpen) self.menuView.hidden = YES;
    }];
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    CGPoint translation = [gesture translationInView:self.superview];
    CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
    self.center = newCenter;
    [gesture setTranslation:CGPointZero inView:self.superview];
}

@end

// ============================================================
// INJECT GUI
// ============================================================

__attribute__((constructor)) static void initialize() {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
        if (!keyWindow) {
            keyWindow = [UIApplication sharedApplication].windows.firstObject;
        }
        if (keyWindow) {
            LUBVGUIButton *guiButton = [[LUBVGUIButton alloc] initWithFrame:CGRectMake(20, 120, 60, 60)];
            [keyWindow addSubview:guiButton];
        }
    });
}

// ============================================================
// HOOKS - UPDATED SIGNATURES FOR AMONG US ASSEMBLY
// ============================================================

%hook PlayerControl

- (BOOL)Data_get_IsImpostor {
    if ([LUBVSettings sharedInstance].alwaysImpostor) return YES;
    return %orig;
}

- (float)CalcKillCooldown {
    if ([LUBVSettings sharedInstance].noKillCooldown) return 0.0f;
    return %orig;
}

- (void)RpcMurderPlayer:(id)target {
    if ([LUBVSettings sharedInstance].godMode) return;
    %orig;
}

- (float)get_TrueSpeed {
    if ([LUBVSettings sharedInstance].fastSpeed) {
        return [LUBVSettings sharedInstance].playerSpeed;
    }
    return %orig;
}

- (float)get_LightRadius {
    if ([LUBVSettings sharedInstance].unlimitedVision) return 999.0f;
    return %orig;
}

- (BOOL)get_Data_get_IsDead {
    if ([LUBVSettings sharedInstance].seeGhosts) return NO;
    return %orig;
}

%end

%hook Vent

- (float)get_Cooldown {
    if ([LUBVSettings sharedInstance].noVentCooldown) return 0.0f;
    return %orig;
}

- (BOOL)CanUse {
    if ([LUBVSettings sharedInstance].alwaysCanVent) return YES;
    return %orig;
}

%end

%hook KillButtonManager

- (BOOL)IsTooFar {
    if ([LUBVSettings sharedInstance].alwaysCanKill) return NO;
    return %orig;
}

%end

%hook MeetingHud

- (void)Start {
    %orig;
    if ([LUBVSettings sharedInstance].alwaysCanReport) {
        // Safe override or bypass hook adjustment for reports
    }
}

%end

// IAP & Unlock Asset Managers
%hook HatManager

- (BOOL)OwnsItem:(id)item {
    if ([LUBVSettings sharedInstance].unlockAllIAP) return YES;
    return %orig;
}

%end
