// Tweak.xm
// Among Us iOS Cheat - Modern GUI
// Based on actual game classes from dump

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>
#import <sys/mman.h>

// ============================================================
// MARK: - Configuration
// ============================================================

static BOOL g_alwaysImpostor = YES;
static BOOL g_unlockAllCosmetics = YES;
static BOOL g_espEnabled = YES;
static BOOL g_autoWinEnabled = NO;
static BOOL g_noBanMode = YES;
static BOOL g_showGhosts = NO;
static BOOL g_unlockAllCubes = YES;
static BOOL g_infiniteVents = NO;
static BOOL g_instantKill = NO;

// ============================================================
// MARK: - Floating Button & GUI System
// ============================================================

static UIButton *g_floatingButton = nil;
static UIView *g_cheatMenuView = nil;
static UIView *g_overlayView = nil;
static UIWindow *g_cheatWindow = nil;

// ============================================================
// MARK: - FORWARD DECLARATIONS
// ============================================================

static void updateESP(void);
static void showCheatMenu(void);
static void hideCheatMenu(void);
static void buttonTapped(void);
static void createFloatingButton(void);

// ============================================================
// MARK: - Class References from Dump
// ============================================================

// From dump: PlayerControl (Image: Assembly-CSharp.dll)
@interface PlayerControl : NSObject
@property (nonatomic, assign) int PlayerId;
@property (nonatomic, assign) BOOL IsImpostor;
@property (nonatomic, assign) BOOL IsDead;
@property (nonatomic, assign) BOOL Disconnected;
@property (nonatomic, strong) NSString *PlayerName;
@property (nonatomic, assign) int ColorId;
@property (nonatomic, strong) id myPhysics;
@property (nonatomic, strong) id role;
+ (PlayerControl *)LocalPlayer;
- (void)MurderPlayer:(id)player;
- (void)SetImpostor:(BOOL)isImpostor;
@end

// From dump: GameData (Image: Assembly-CSharp.dll)
@interface GameData : NSObject
@property (nonatomic, strong) NSArray *AllPlayers;
@property (nonatomic, assign) int TotalTasks;
@property (nonatomic, assign) int CompletedTasks;
+ (GameData *)Instance;
- (id)GetPlayerById:(int)playerId;
@end

// From dump: ShipStatus (Image: Assembly-CSharp.dll)  
@interface ShipStatus : NSObject
@property (nonatomic, assign) int MapId;
@property (nonatomic, assign) int NumImpostors;
@property (nonatomic, assign) int MaxPlayers;
@property (nonatomic, assign) BOOL GameEnded;
+ (ShipStatus *)Instance;
@end

// From dump: HatManager (Image: Assembly-CSharp.dll)
@interface HatManager : NSObject
@property (nonatomic, strong) NSArray *AllHats;
@property (nonatomic, strong) NSArray *AllPets;
@property (nonatomic, strong) NSArray *AllSkins;
@property (nonatomic, strong) NSArray *AllVisors;
@property (nonatomic, strong) NSArray *AllNamePlates;
+ (HatManager *)Instance;
- (BOOL)HasPurchased:(id)itemId;
- (BOOL)IsAvailable:(id)itemId;
@end

// From dump: CosmicubeManager (Image: Assembly-CSharp.dll)
@interface CosmicubeManager : NSObject
+ (CosmicubeManager *)Instance;
- (NSArray *)GetAllCubeData;
- (BOOL)IsCompleted:(id)cubeData;
@end

// From dump: InnerNetClient
@interface InnerNetClient : NSObject
+ (InnerNetClient *)Instance;
- (void)SendRpc;
@property (nonatomic, assign) int ClientId;
@end

// ============================================================
// MARK: - Modern GUI Implementation
// ============================================================

@interface CheatMenuViewController : UIViewController <UIGestureRecognizerDelegate> {
    UIScrollView *scrollView;
    UIView *contentView;
    UISwitch *impostorSwitch;
    UISwitch *cosmeticsSwitch;
    UISwitch *espSwitch;
    UISwitch *autoWinSwitch;
    UISwitch *antiBanSwitch;
    UISwitch *showGhostsSwitch;
    UISwitch *cubesSwitch;
    UISwitch *ventsSwitch;
    UISwitch *killSwitch;
    UILabel *statusLabel;
    UIView *headerView;
    UIView *footerView;
    NSMutableArray *toggleRows;
}
@end

@implementation CheatMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Modern dark theme with gradient
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.view.bounds;
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.05 green:0.05 blue:0.15 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.1 green:0.1 blue:0.2 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.0 green:0.0 blue:0.1 alpha:1.0].CGColor
    ];
    gradient.locations = @[@0.0, @0.5, @1.0];
    [self.view.layer insertSublayer:gradient atIndex:0];
    
    toggleRows = [NSMutableArray array];
    
    [self setupNavigationBar];
    [self setupScrollView];
    [self setupHeader];
    [self setupToggles];
    [self setupFooter];
    [self setupGestures];
}

- (void)setupNavigationBar {
    self.title = @"⚙️ Cheat Menu";
    
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = [UIColor colorWithRed:0.05 green:0.05 blue:0.15 alpha:1.0];
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: [UIColor whiteColor],
        NSFontAttributeName: [UIFont boldSystemFontOfSize:20]
    };
    
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.translucent = NO;
    
    // Close button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:24 weight:UIFontWeightLight];
    closeBtn.frame = CGRectMake(0, 0, 44, 44);
    [closeBtn addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:closeBtn];
    
    // Apply button
    UIButton *applyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    [applyBtn setTitle:@"Apply" forState:UIControlStateNormal];
    [applyBtn setTitleColor:[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0] forState:UIControlStateNormal];
    applyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    applyBtn.frame = CGRectMake(0, 0, 70, 44);
    [applyBtn addTarget:self action:@selector(applyTapped) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:applyBtn];
}

- (void)setupScrollView {
    scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    scrollView.backgroundColor = [UIColor clearColor];
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:scrollView];
    
    contentView = [[UIView alloc] init];
    contentView.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:contentView];
}

- (void)setupHeader {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.9];
    header.layer.cornerRadius = 16;
    header.layer.masksToBounds = YES;
    
    // Icon
    UILabel *iconLabel = [[UILabel alloc] init];
    iconLabel.text = @"🎮";
    iconLabel.font = [UIFont systemFontOfSize:40];
    iconLabel.textAlignment = NSTextAlignmentCenter;
    
    // Title
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = @"Among Us Cheats";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    
    // Status
    statusLabel = [[UILabel alloc] init];
    statusLabel.text = @"● Ready";
    statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    statusLabel.font = [UIFont systemFontOfSize:14];
    statusLabel.textAlignment = NSTextAlignmentCenter;
    
    [header addSubview:iconLabel];
    [header addSubview:titleLabel];
    [header addSubview:statusLabel];
    [contentView addSubview:header];
    headerView = header;
}

- (void)setupToggles {
    CGFloat padding = 20;
    CGFloat toggleHeight = 70;
    
    NSArray *toggleConfigs = @[
        @{@"key": @"impostor", @"title": @"🔴 Always Impostor", @"sub": @"You will always be the Impostor", @"default": @(g_alwaysImpostor)},
        @{@"key": @"cosmetics", @"title": @"👗 Unlock All Cosmetics", @"sub": @"All hats, skins, pets, visors, nameplates", @"default": @(g_unlockAllCosmetics)},
        @{@"key": @"cubes", @"title": @"📦 Unlock All Cubes", @"sub": @"All cosmicubes and their rewards", @"default": @(g_unlockAllCubes)},
        @{@"key": @"esp", @"title": @"👁️ ESP Overlay", @"sub": @"Show player positions and roles", @"default": @(g_espEnabled)},
        @{@"key": @"ghosts", @"title": @"👻 Show Ghosts", @"sub": @"Show dead players in ESP", @"default": @(g_showGhosts)},
        @{@"key": @"autowin", @"title": @"🏆 Auto Win", @"sub": @"Instantly win as Impostor", @"default": @(g_autoWinEnabled)},
        @{@"key": @"vents", @"title": @"🌀 Infinite Vents", @"sub": @"No cooldown on vent usage", @"default": @(g_infiniteVents)},
        @{@"key": @"kill", @"title": @"⚔️ Instant Kill", @"sub": @"No kill cooldown", @"default": @(g_instantKill)},
        @{@"key": @"antiban", @"title": @"🛡️ Anti-Ban", @"sub": @"Bypass anti-cheat detection", @"default": @(g_noBanMode)}
    ];
    
    for (NSDictionary *config in toggleConfigs) {
        [self createToggleWithKey:config[@"key"] 
                            title:config[@"title"] 
                         subtitle:config[@"sub"] 
                          default:[config[@"default"] boolValue]
                          atIndex:[toggleConfigs indexOfObject:config]];
    }
}

- (void)createToggleWithKey:(NSString *)key title:(NSString *)title 
                   subtitle:(NSString *)subtitle default:(BOOL)defaultValue
                    atIndex:(NSInteger)index {
    
    CGFloat padding = 20;
    CGFloat x = padding;
    CGFloat y = 20 + (index * 80);
    CGFloat width = self.view.bounds.size.width - (padding * 2);
    CGFloat height = 70;
    
    UIView *row = [[UIView alloc] initWithFrame:CGRectMake(x, y, width, height)];
    row.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.9];
    row.layer.cornerRadius = 12;
    row.layer.masksToBounds = YES;
    row.layer.borderWidth = 0.5;
    row.layer.borderColor = [UIColor colorWithWhite:0.25 alpha:1.0].CGColor;
    
    // Icon and title
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 12, width - 100, 22)];
    titleLabel.text = title;
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightMedium];
    [row addSubview:titleLabel];
    
    // Subtitle
    UILabel *subLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 36, width - 100, 18)];
    subLabel.text = subtitle;
    subLabel.textColor = [UIColor colorWithWhite:0.5 alpha:1.0];
    subLabel.font = [UIFont systemFontOfSize:12];
    [row addSubview:subLabel];
    
    // Switch
    UISwitch *toggle = [[UISwitch alloc] init];
    toggle.onTintColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    toggle.tintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    toggle.on = defaultValue;
    toggle.frame = CGRectMake(width - 70, 18, 51, 31);
    toggle.tag = index;
    [row addSubview:toggle];
    
    // Store reference
    NSDictionary *toggleInfo = @{@"key": key, @"switch": toggle};
    [toggleRows addObject:toggleInfo];
    
    [contentView addSubview:row];
}

- (void)setupFooter {
    CGFloat padding = 20;
    CGFloat y = 20 + (toggleRows.count * 80) + 20;
    CGFloat width = self.view.bounds.size.width - (padding * 2);
    
    footerView = [[UIView alloc] initWithFrame:CGRectMake(padding, y, width, 100)];
    footerView.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.9];
    footerView.layer.cornerRadius = 12;
    footerView.layer.masksToBounds = YES;
    
    // Version info
    UILabel *versionLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 16, width - 32, 20)];
    versionLabel.text = @"Version 2.0.0";
    versionLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    versionLabel.font = [UIFont systemFontOfSize:12];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:versionLabel];
    
    // Credits
    UILabel *creditLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 40, width - 32, 20)];
    creditLabel.text = @"Made with ❤️ for the community";
    creditLabel.textColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    creditLabel.font = [UIFont systemFontOfSize:12];
    creditLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:creditLabel];
    
    // Tip
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, 64, width - 32, 20)];
    tipLabel.text = @"💡 Triple-tap anywhere to reopen this menu";
    tipLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    tipLabel.font = [UIFont systemFontOfSize:11];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [footerView addSubview:tipLabel];
    
    [contentView addSubview:footerView];
    
    [self layoutViews];
}

- (void)layoutViews {
    CGFloat padding = 20;
    CGFloat totalHeight = 20 + 100 + 20 + (toggleRows.count * 80) + 20 + 100 + 30;
    
    contentView.frame = CGRectMake(0, 0, self.view.bounds.size.width, totalHeight);
    scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, totalHeight);
}

- (void)setupGestures {
    // Swipe down to close
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] 
        initWithTarget:self action:@selector(closeTapped)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.view addGestureRecognizer:swipeDown];
}

- (void)closeTapped {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformMakeScale(0.9, 0.9);
        self.view.alpha = 0;
    } completion:^(BOOL finished) {
        [self dismissViewControllerAnimated:NO completion:^{
            hideCheatMenu();
        }];
    }];
}

- (void)applyTapped {
    // Get all toggle values
    for (NSDictionary *toggleInfo in toggleRows) {
        NSString *key = toggleInfo[@"key"];
        UISwitch *toggle = toggleInfo[@"switch"];
        BOOL value = toggle.on;
        
        if ([key isEqualToString:@"impostor"]) g_alwaysImpostor = value;
        else if ([key isEqualToString:@"cosmetics"]) g_unlockAllCosmetics = value;
        else if ([key isEqualToString:@"cubes"]) g_unlockAllCubes = value;
        else if ([key isEqualToString:@"esp"]) g_espEnabled = value;
        else if ([key isEqualToString:@"ghosts"]) g_showGhosts = value;
        else if ([key isEqualToString:@"autowin"]) g_autoWinEnabled = value;
        else if ([key isEqualToString:@"vents"]) g_infiniteVents = value;
        else if ([key isEqualToString:@"kill"]) g_instantKill = value;
        else if ([key isEqualToString:@"antiban"]) g_noBanMode = value;
    }
    
    // Update ESP visibility
    if (g_espOverlay) {
        UIView *overlay = (__bridge UIView *)g_espOverlay;
        overlay.hidden = !g_espEnabled;
        if (g_espEnabled) {
            updateESP();
        }
    }
    
    // Show success animation
    statusLabel.text = @"✅ Applied!";
    statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.transform = CGAffineTransformMakeScale(0.98, 0.98);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.transform = CGAffineTransformIdentity;
        }];
    }];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        statusLabel.text = @"● Ready";
        statusLabel.textColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.view.alpha = 0;
    self.view.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:0 animations:^{
        self.view.alpha = 1;
        self.view.transform = CGAffineTransformIdentity;
    } completion:nil];
}

@end

// ============================================================
// MARK: - Menu Show/Hide Functions
// ============================================================

static void showCheatMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_cheatWindow) {
            g_cheatWindow.hidden = NO;
            [g_cheatWindow makeKeyAndVisible];
            return;
        }
        
        UIWindow *mainWindow = [UIApplication sharedApplication].keyWindow;
        if (!mainWindow) {
            mainWindow = [[UIApplication sharedApplication].windows firstObject];
        }
        if (!mainWindow) return;
        
        g_cheatWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        g_cheatWindow.backgroundColor = [UIColor clearColor];
        g_cheatWindow.windowLevel = UIWindowLevelAlert + 1;
        
        CheatMenuViewController *vc = [[CheatMenuViewController alloc] init];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        nav.modalPresentationStyle = UIModalPresentationFullScreen;
        nav.view.backgroundColor = [UIColor clearColor];
        
        g_cheatWindow.rootViewController = nav;
        g_cheatWindow.hidden = NO;
        [g_cheatWindow makeKeyAndVisible];
        
        // Add blur background
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.frame = g_cheatWindow.bounds;
        blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [g_cheatWindow insertSubview:blurView atIndex:0];
    });
}

static void hideCheatMenu(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_cheatWindow) {
            g_cheatWindow.hidden = YES;
            [g_cheatWindow resignKeyWindow];
            g_cheatWindow = nil;
        }
        // Restore main window
        UIWindow *mainWindow = [UIApplication sharedApplication].windows.firstObject;
        if (mainWindow) {
            [mainWindow makeKeyAndVisible];
        }
    });
}

// ============================================================
// MARK: - Floating Button
// ============================================================

static void buttonTapped(void) {
    [UIView animateWithDuration:0.15 animations:^{
        g_floatingButton.transform = CGAffineTransformMakeScale(0.7, 0.7);
        g_floatingButton.alpha = 0.7;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:0.5 options:0 animations:^{
            g_floatingButton.transform = CGAffineTransformIdentity;
            g_floatingButton.alpha = 1;
        } completion:^(BOOL finished) {
            showCheatMenu();
        }];
    }];
}

static void handleDrag(UIPanGestureRecognizer *gesture) {
    UIButton *btn = (UIButton *)gesture.view;
    CGPoint translation = [gesture translationInView:btn.superview];
    
    if (gesture.state == UIGestureRecognizerStateChanged) {
        CGRect newFrame = btn.frame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        
        CGFloat margin = 10;
        newFrame.origin.x = MAX(margin, MIN(newFrame.origin.x, btn.superview.bounds.size.width - newFrame.size.width - margin));
        newFrame.origin.y = MAX(margin, MIN(newFrame.origin.y, btn.superview.bounds.size.height - newFrame.size.height - margin));
        
        btn.frame = newFrame;
        [gesture setTranslation:CGPointZero inView:btn.superview];
    }
}

static void createFloatingButton(void) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows firstObject];
        }
        if (!window) return;
        
        if (g_floatingButton) {
            [g_floatingButton removeFromSuperview];
            g_floatingButton = nil;
        }
        
        // Modern floating button with gradient
        g_floatingButton = [UIButton buttonWithType:UIButtonTypeCustom];
        CGFloat size = 64;
        g_floatingButton.frame = CGRectMake(window.bounds.size.width - size - 20, 
                                            window.bounds.size.height - size - 100, 
                                            size, size);
        
        // Gradient background
        CAGradientLayer *gradient = [CAGradientLayer layer];
        gradient.frame = CGRectMake(0, 0, size, size);
        gradient.colors = @[
            (id)[UIColor colorWithRed:0.2 green:0.8 blue:0.4 alpha:1.0].CGColor,
            (id)[UIColor colorWithRed:0.1 green:0.6 blue:0.3 alpha:1.0].CGColor
        ];
        gradient.startPoint = CGPointMake(0, 0);
        gradient.endPoint = CGPointMake(1, 1);
        gradient.cornerRadius = size / 2;
        [g_floatingButton.layer insertSublayer:gradient atIndex:0];
        
        g_floatingButton.layer.cornerRadius = size / 2;
        g_floatingButton.layer.shadowColor = [UIColor blackColor].CGColor;
        g_floatingButton.layer.shadowOffset = CGSizeMake(0, 4);
        g_floatingButton.layer.shadowOpacity = 0.5;
        g_floatingButton.layer.shadowRadius = 12;
        g_floatingButton.layer.borderWidth = 2;
        g_floatingButton.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        
        // Icon with emoji
        UILabel *iconLabel = [[UILabel alloc] initWithFrame:g_floatingButton.bounds];
        iconLabel.text = @"🎮";
        iconLabel.font = [UIFont systemFontOfSize:32];
        iconLabel.textAlignment = NSTextAlignmentCenter;
        iconLabel.userInteractionEnabled = NO;
        [g_floatingButton addSubview:iconLabel];
        
        // Button action using block
        [g_floatingButton addTarget:(id)^(id sender) {
            buttonTapped();
        } action:@selector(invoke) forControlEvents:UIControlEventTouchUpInside];
        
        // Drag gesture
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:(id)^(UIPanGestureRecognizer *gesture) {
            handleDrag(gesture);
        } action:@selector(invoke)];
        [g_floatingButton addGestureRecognizer:pan];
        
        [window addSubview:g_floatingButton];
        [window bringSubviewToFront:g_floatingButton];
        
        // Entrance animation
        g_floatingButton.transform = CGAffineTransformMakeScale(0.01, 0.01);
        g_floatingButton.alpha = 0;
        [UIView animateWithDuration:0.6 delay:1.0 usingSpringWithDamping:0.6 initialSpringVelocity:0.8 options:0 animations:^{
            g_floatingButton.transform = CGAffineTransformIdentity;
            g_floatingButton.alpha = 1;
        } completion:nil];
        
        // Pulse animation
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        pulse.duration = 2.0;
        pulse.fromValue = @1.0;
        pulse.toValue = @1.05;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        [g_floatingButton.layer addAnimation:pulse forKey:@"pulse"];
    });
}

// ============================================================
// MARK: - Triple Tap Gesture Handler
// ============================================================

static void handleTripleTap(UIGestureRecognizer *gesture) {
    if (g_cheatWindow && !g_cheatWindow.hidden) {
        hideCheatMenu();
    } else {
        showCheatMenu();
    }
}

// ============================================================
// MARK: - Hook Functions - Always Impostor
// ============================================================

static BOOL (*orig_PlayerControl_get_IsImpostor)(id self, SEL sel);
static BOOL hooked_PlayerControl_get_IsImpostor(id self, SEL sel) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (localPlayer && self == localPlayer) {
            return YES;
        }
    }
    return orig_PlayerControl_get_IsImpostor ? orig_PlayerControl_get_IsImpostor(self, sel) : NO;
}

// ============================================================
// MARK: - Hook Functions - Unlock All Cosmetics
// ============================================================

static BOOL (*orig_HasPurchased)(id self, SEL sel, id itemId);
static BOOL hooked_HasPurchased(id self, SEL sel, id itemId) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_HasPurchased ? orig_HasPurchased(self, sel, itemId) : NO;
}

static BOOL (*orig_IsAvailable)(id self, SEL sel);
static BOOL hooked_IsAvailable(id self, SEL sel) {
    if (g_unlockAllCosmetics) {
        return YES;
    }
    return orig_IsAvailable ? orig_IsAvailable(self, sel) : NO;
}

// ============================================================
// MARK: - Hook Functions - Unlock All Cubes
// ============================================================

static BOOL (*orig_CubeIsCompleted)(id self, SEL sel, id cubeData);
static BOOL hooked_CubeIsCompleted(id self, SEL sel, id cubeData) {
    if (g_unlockAllCubes) {
        return YES;
    }
    return orig_CubeIsCompleted ? orig_CubeIsCompleted(self, sel, cubeData) : NO;
}

// ============================================================
// MARK: - Hook Functions - Infinite Vents
// ============================================================

static float (*orig_GetVentCooldown)(id self, SEL sel);
static float hooked_GetVentCooldown(id self, SEL sel) {
    if (g_infiniteVents) {
        return 0.0f;
    }
    return orig_GetVentCooldown ? orig_GetVentCooldown(self, sel) : 0.0f;
}

// ============================================================
// MARK: - Hook Functions - Instant Kill
// ============================================================

static float (*orig_GetKillCooldown)(id self, SEL sel);
static float hooked_GetKillCooldown(id self, SEL sel) {
    if (g_instantKill) {
        return 0.0f;
    }
    return orig_GetKillCooldown ? orig_GetKillCooldown(self, sel) : 0.0f;
}

// ============================================================
// MARK: - ESP Overlay
// ============================================================

@interface ESPOverlay : UIView
@property (nonatomic, strong) NSMutableArray *playerLabels;
@end

@implementation ESPOverlay

- (instancetype)init {
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.playerLabels = [NSMutableArray array];
        self.hidden = !g_espEnabled;
        
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (window) {
            self.frame = window.bounds;
            [window addSubview:self];
            [window bringSubviewToFront:self];
        }
    }
    return self;
}

- (void)updateESP {
    if (!g_espEnabled) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;
    
    // Remove old labels
    for (UILabel *label in self.playerLabels) {
        [label removeFromSuperview];
    }
    [self.playerLabels removeAllObjects];
    
    // Get game data
    GameData *gameData = [objc_getClass("GameData") performSelector:@selector(Instance)];
    if (!gameData) return;
    
    NSArray *players = [gameData performSelector:@selector(AllPlayers)];
    if (!players) return;
    
    PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
    if (!localPlayer) return;
    
    int localId = [[localPlayer valueForKey:@"PlayerId"] intValue];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    CGSize screenSize = window.bounds.size;
    CGFloat centerX = screenSize.width / 2;
    CGFloat centerY = screenSize.height / 2;
    
    for (id player in players) {
        BOOL isDead = [[player valueForKey:@"IsDead"] boolValue];
        BOOL isDisconnected = [[player valueForKey:@"Disconnected"] boolValue];
        
        if (!g_showGhosts && isDead) continue;
        if (isDisconnected) continue;
        
        int playerId = [[player valueForKey:@"PlayerId"] intValue];
        if (playerId == localId) continue;
        
        NSString *playerName = [player valueForKey:@"PlayerName"];
        BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
        
        // Try to get position from myPhysics
        id myPhysics = [player valueForKey:@"myPhysics"];
        if (!myPhysics) continue;
        
        // Get position - try different approaches
        CGPoint position = CGPointZero;
        if ([myPhysics respondsToSelector:@selector(position)]) {
            position = [[myPhysics valueForKey:@"position"] CGPointValue];
        } else if ([myPhysics respondsToSelector:@selector(transform)]) {
            id transform = [myPhysics valueForKey:@"transform"];
            if (transform && [transform respondsToSelector:@selector(position)]) {
                position = [[transform valueForKey:@"position"] CGPointValue];
            }
        }
        
        if (position.x == 0 && position.y == 0) continue;
        
        // Convert to screen space - rough mapping
        float screenX = (position.x / 50.0f) * centerX + centerX;
        float screenY = centerY - (position.y / 50.0f) * centerY;
        
        // Create label with modern styling
        NSString *roleIcon = isImpostor ? @"🔴" : (isDead ? @"👻" : @"🟢");
        NSString *labelText = [NSString stringWithFormat:@"%@ %@", playerName, roleIcon];
        
        UIColor *bgColor = isImpostor ? [UIColor colorWithRed:0.8 green:0.1 blue:0.1 alpha:0.6] : 
                                       [UIColor colorWithRed:0.1 green:0.6 blue:0.1 alpha:0.6];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(screenX - 60, screenY - 20, 120, 40)];
        label.text = labelText;
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont boldSystemFontOfSize:13];
        label.textAlignment = NSTextAlignmentCenter;
        label.backgroundColor = bgColor;
        label.layer.cornerRadius = 8;
        label.clipsToBounds = YES;
        label.layer.borderWidth = 1;
        label.layer.borderColor = [UIColor colorWithWhite:1 alpha:0.2].CGColor;
        
        // Add distance indicator
        float distance = sqrt(position.x * position.x + position.y * position.y);
        UILabel *distLabel = [[UILabel alloc] initWithFrame:CGRectMake(screenX - 30, screenY + 22, 60, 16)];
        distLabel.text = [NSString stringWithFormat:@"%.0fm", distance];
        distLabel.textColor = [UIColor colorWithWhite:0.8 alpha:0.7];
        distLabel.font = [UIFont systemFontOfSize:10];
        distLabel.textAlignment = NSTextAlignmentCenter;
        distLabel.backgroundColor = [UIColor colorWithWhite:0 alpha:0.3];
        distLabel.layer.cornerRadius = 4;
        distLabel.clipsToBounds = YES;
        
        [self addSubview:label];
        [self addSubview:distLabel];
        [self.playerLabels addObject:label];
        [self.playerLabels addObject:distLabel];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    if (window) {
        self.frame = window.bounds;
    }
}

@end

// ============================================================
// MARK: - ESP Update Timer
// ============================================================

static void updateESP(void) {
    if (g_espOverlay) {
        ESPOverlay *overlay = (__bridge ESPOverlay *)g_espOverlay;
        [overlay updateESP];
    }
}

// ============================================================
// MARK: - Hook Functions - Auto Win
// ============================================================

static void (*orig_CheckEndCriteria)(id self, SEL sel);
static void hooked_CheckEndCriteria(id self, SEL sel) {
    if (g_autoWinEnabled) {
        GameData *gd = [objc_getClass("GameData") performSelector:@selector(Instance)];
        NSArray *allPlayers = [gd performSelector:@selector(AllPlayers)];
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        
        if (localPlayer && allPlayers) {
            // Kill all non-impostors
            for (id player in allPlayers) {
                if (player != localPlayer) {
                    BOOL isImpostor = [[player valueForKey:@"IsImpostor"] boolValue];
                    if (!isImpostor) {
                        [player setValue:@YES forKey:@"IsDead"];
                    }
                }
            }
            
            // Trigger game end
            ShipStatus *shipStatus = [objc_getClass("ShipStatus") performSelector:@selector(Instance)];
            if (shipStatus) {
                [shipStatus setValue:@YES forKey:@"GameEnded"];
            }
        }
        return;
    }
    
    if (orig_CheckEndCriteria) {
        orig_CheckEndCriteria(self, sel);
    }
}

// ============================================================
// MARK: - Hook Functions - Anti-Ban
// ============================================================

static BOOL (*orig_SystemIntegrityCheck)(id, SEL);
static BOOL hooked_SystemIntegrityCheck(id self, SEL sel) {
    if (g_noBanMode) {
        return YES;
    }
    return orig_SystemIntegrityCheck ? orig_SystemIntegrityCheck(self, sel) : YES;
}

static BOOL (*orig_IsBanned)(id, SEL);
static BOOL hooked_IsBanned(id self, SEL sel) {
    if (g_noBanMode) {
        return NO;
    }
    return orig_IsBanned ? orig_IsBanned(self, sel) : NO;
}

static void (*orig_ValidatePacket)(id, SEL, id);
static void hooked_ValidatePacket(id self, SEL sel, id packet) {
    if (g_noBanMode && packet) {
        // Try to sanitize packet
        @try {
            NSArray *keys = @[@"cheatReported", @"detected", @"suspicious", @"flagged", @"invalid", @"hackDetected"];
            for (NSString *key in keys) {
                if ([packet respondsToSelector:NSSelectorFromString([NSString stringWithFormat:@"set%@:", [key capitalizedString]])]) {
                    [packet setValue:@0 forKey:key];
                }
            }
        } @catch (NSException *e) {}
        return;
    }
    if (orig_ValidatePacket) {
        orig_ValidatePacket(self, sel, packet);
    }
}

// ============================================================
// MARK: - Hook Functions - Player Spawn
// ============================================================

static void (*orig_OnPlayerSpawn)(id, SEL, id);
static void hooked_OnPlayerSpawn(id self, SEL sel, id player) {
    if (g_alwaysImpostor) {
        PlayerControl *localPlayer = [objc_getClass("PlayerControl") performSelector:@selector(LocalPlayer)];
        if (player == localPlayer) {
            [player setValue:@YES forKey:@"IsImpostor"];
        }
    }
    if (orig_OnPlayerSpawn) {
        orig_OnPlayerSpawn(self, sel, player);
    }
}

// ============================================================
// MARK: - Injection Entry Point
// ============================================================

__attribute__((constructor))
static void init_cheat(void) {
    NSLog(@"[AmongUsCheat] 🚀 Injecting cheat...");
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[AmongUsCheat] Initializing features...");
        
        // Get classes
        Class playerControl = objc_getClass("PlayerControl");
        Class shipStatus = objc_getClass("ShipStatus");
        Class hatManager = objc_getClass("HatManager");
        Class cosmicubeManager = objc_getClass("CosmicubeManager");
        Class innerNetClient = objc_getClass("InnerNetClient");
        
        if (!playerControl) {
            NSLog(@"[AmongUsCheat] ❌ PlayerControl not found!");
            return;
        }
        
        // ============================================================
        // Hook IsImpostor
        // ============================================================
        SEL isImpostorSel = NSSelectorFromString(@"IsImpostor");
        if (isImpostorSel) {
            Method m = class_getInstanceMethod(playerControl, isImpostorSel);
            if (m) {
                orig_PlayerControl_get_IsImpostor = (BOOL (*)(id, SEL))method_getImplementation(m);
                class_replaceMethod(playerControl, isImpostorSel, (IMP)hooked_PlayerControl_get_IsImpostor, method_getTypeEncoding(m));
                NSLog(@"[AmongUsCheat] ✅ Hooked IsImpostor");
            }
        }
        
        // ============================================================
        // Hook Cosmetics
        // ============================================================
        if (hatManager && g_unlockAllCosmetics) {
            SEL hasPurchasedSel = NSSelectorFromString(@"HasPurchased:");
            if (hasPurchasedSel) {
                Method m = class_getInstanceMethod(hatManager, hasPurchasedSel);
                if (m) {
                    orig_HasPurchased = (BOOL (*)(id, SEL, id))method_getImplementation(m);
                    class_replaceMethod(hatManager, hasPurchasedSel, (IMP)hooked_HasPurchased, method_getTypeEncoding(m));
                    NSLog(@"[AmongUsCheat] ✅ Hooked HasPurchased");
                }
            }
            
            SEL isAvailableSel = NSSelectorFromString(@"IsAvailable");
            if (isAvailableSel) {
                Method m = class_getInstanceMethod(hatManager, isAvailableSel);
                if (m) {
                    orig_IsAvailable = (BOOL (*)(id, SEL))method_getImplementation(m);
                    class_replaceMethod(hatManager, isAvailableSel, (IMP)hooked_IsAvailable, method_getTypeEncoding(m));
                    NSLog(@"[AmongUsCheat] ✅ Hooked IsAvailable");
                }
            }
        }
        
        // ============================================================
        // Hook Cosmicubes
        // ============================================================
        if (cosmicubeManager && g_unlockAllCubes) {
            SEL completedSel = NSSelectorFromString(@"IsCompleted:");
            if (completedSel) {
                Method m = class_getInstanceMethod(cosmicubeManager, completedSel);
                if (m) {
                    orig_CubeIsCompleted = (BOOL (*)(id, SEL, id))method_getImplementation(m);
                    class_replaceMethod(cosmicubeManager, completedSel, (IMP)hooked_CubeIsCompleted, method_getTypeEncoding(m));
                    NSLog(@"[AmongUsCheat] ✅ Hooked Cosmicube IsCompleted");
                }
            }
        }
        
        // ============================================================
        // Hook Auto Win
        // ============================================================
        if (shipStatus && g_autoWinEnabled) {
            SEL checkEndSel = NSSelectorFromString(@"CheckEndCriteria");
            if (checkEndSel) {
                Method m = class_getInstanceMethod(shipStatus, checkEndSel);
                if (m) {
                    orig_CheckEndCriteria = (void (*)(id, SEL))method_getImplementation(m);
                    class_replaceMethod(shipStatus, checkEndSel, (IMP)hooked_CheckEndCriteria, method_getTypeEncoding(m));
                    NSLog(@"[AmongUsCheat] ✅ Hooked CheckEndCriteria");
                }
            }
        }
        
        // ============================================================
        // Hook Anti-Ban
        // ============================================================
        if (g_noBanMode) {
            NSArray *antiCheatClasses = @[
                @"AntiCheatManager",
                @"SecurityManager", 
                @"IntegrityChecker",
                @"CheatDetection",
                @"ServerValidator",
                @"BanManager"
            ];
            
            for (NSString *className in antiCheatClasses) {
                Class cls = objc_getClass([className UTF8String]);
                if (!cls) continue;
                
                SEL integritySel = NSSelectorFromString(@"VerifyIntegrity");
                if (integritySel) {
                    Method m = class_getInstanceMethod(cls, integritySel);
                    if (m) {
                        orig_SystemIntegrityCheck = (BOOL (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(cls, integritySel, (IMP)hooked_SystemIntegrityCheck, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] ✅ Hooked %@.VerifyIntegrity", className);
                    }
                }
                
                SEL banSel = NSSelectorFromString(@"IsDeviceBanned");
                if (banSel) {
                    Method m = class_getInstanceMethod(cls, banSel);
                    if (m) {
                        orig_IsBanned = (BOOL (*)(id, SEL))method_getImplementation(m);
                        class_replaceMethod(cls, banSel, (IMP)hooked_IsBanned, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] ✅ Hooked %@.IsDeviceBanned", className);
                    }
                }
            }
            
            if (innerNetClient) {
                SEL validateSel = NSSelectorFromString(@"ValidatePacket:");
                if (validateSel) {
                    Method m = class_getInstanceMethod(innerNetClient, validateSel);
                    if (m) {
                        orig_ValidatePacket = (void (*)(id, SEL, id))method_getImplementation(m);
                        class_replaceMethod(innerNetClient, validateSel, (IMP)hooked_ValidatePacket, method_getTypeEncoding(m));
                        NSLog(@"[AmongUsCheat] ✅ Hooked ValidatePacket");
                    }
                }
            }
        }
        
        // ============================================================
        // Hook Infinite Vents
        // ============================================================
        if (g_infiniteVents) {
            SEL cooldownSel = NSSelectorFromString(@"GetVentCooldown");
            if (cooldownSel) {
                Method m = class_getInstanceMethod(playerControl, cooldownSel);
                if (m) {
                    orig_GetVentCooldown = (float (*)(id, SEL))method_getImplementation(m);
                    class_replaceMethod(playerControl, cooldownSel, (IMP)hooked_GetVentCooldown, method_getTypeEncoding(m));
                    NSLog(@"[AmongUsCheat] ✅ Hooked GetVentCooldown");
                }
            }
        }
        
        // ============================================================
        // Hook Instant Kill
        // ============================================================
        if (g_instantKill) {
            SEL killCooldownSel = NSSelectorFromString(@"GetKillCooldown");
            if (killCooldownSel) {
                Method m = class_getInstanceMethod(playerControl, killCooldownSel);
                if (m) {
                    orig_GetKillCooldown = (float (*)(id, SEL))method_getImplementation(m);
                    class_replaceMethod(playerControl, killCooldownSel, (IMP)hooked_GetKillCooldown, method_getTypeEncoding(m));
                    NSLog(@"[AmongUsCheat] ✅ Hooked GetKillCooldown");
                }
            }
        }
        
        // ============================================================
        // Hook OnSpawn
        // ============================================================
        SEL onSpawnSel = NSSelectorFromString(@"OnSpawn");
        if (onSpawnSel) {
            Method m = class_getInstanceMethod(playerControl, onSpawnSel);
            if (m) {
                orig_OnPlayerSpawn = (void (*)(id, SEL, id))method_getImplementation(m);
                class_replaceMethod(playerControl, onSpawnSel, (IMP)hooked_OnPlayerSpawn, method_getTypeEncoding(m));
                NSLog(@"[AmongUsCheat] ✅ Hooked OnSpawn");
            }
        }
        
        // ============================================================
        // Setup ESP
        // ============================================================
        if (g_espEnabled) {
            dispatch_async(dispatch_get_main_queue(), ^{
                ESPOverlay *overlay = [[ESPOverlay alloc] init];
                g_espOverlay = (__bridge_retained void *)overlay;
                
                [NSTimer scheduledTimerWithTimeInterval:0.5
                                                repeats:YES
                                                  block:^(NSTimer *timer) {
                    updateESP();
                }];
                
                NSLog(@"[AmongUsCheat] ✅ ESP initialized");
            });
        }
        
        // ============================================================
        // Setup Floating Button
        // ============================================================
        createFloatingButton();
        
        // ============================================================
        // Setup Triple Tap
        // ============================================================
        UIWindow *window = [UIApplication sharedApplication].keyWindow;
        if (!window) {
            window = [[UIApplication sharedApplication].windows firstObject];
        }
        
        if (window) {
            // Remove existing triple tap
            NSArray *gestures = [window.gestureRecognizers copy];
            for (UIGestureRecognizer *gesture in gestures) {
                if ([gesture isKindOfClass:[UITapGestureRecognizer class]] && 
                    ((UITapGestureRecognizer *)gesture).numberOfTapsRequired == 3) {
                    [window removeGestureRecognizer:gesture];
                }
            }
            
            UITapGestureRecognizer *tripleTap = [[UITapGestureRecognizer alloc] initWithTarget:(id)^(UITapGestureRecognizer *recognizer) {
                handleTripleTap(recognizer);
            } action:@selector(invoke)];
            tripleTap.numberOfTapsRequired = 3;
            [window addGestureRecognizer:tripleTap];
            
            NSLog(@"[AmongUsCheat] ✅ Triple-tap gesture added");
        }
        
        NSLog(@"[AmongUsCheat] 🎉 Injection complete!");
        NSLog(@"[AmongUsCheat] Features:");
        NSLog(@"[AmongUsCheat]   🔴 Always Impostor: %@", g_alwaysImpostor ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   👗 Unlock Cosmetics: %@", g_unlockAllCosmetics ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   📦 Unlock Cubes: %@", g_unlockAllCubes ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   👁️ ESP: %@", g_espEnabled ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   👻 Show Ghosts: %@", g_showGhosts ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   🏆 Auto Win: %@", g_autoWinEnabled ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   🌀 Infinite Vents: %@", g_infiniteVents ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   ⚔️ Instant Kill: %@", g_instantKill ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat]   🛡️ Anti-Ban: %@", g_noBanMode ? @"ON" : @"OFF");
        NSLog(@"[AmongUsCheat] 💡 Tap the 🎮 button or triple-tap anywhere to open the menu!");
    });
}

// ============================================================
// MARK: - Debug Command Functions
// ============================================================

extern "C" void ToggleImpostor() {
    g_alwaysImpostor = !g_alwaysImpostor;
    NSLog(@"[AmongUsCheat] AlwaysImpostor: %@", g_alwaysImpostor ? @"ON" : @"OFF");
}

extern "C" void ToggleESP() {
    g_espEnabled = !g_espEnabled;
    if (g_espOverlay) {
        ESPOverlay *overlay = (__bridge ESPOverlay *)g_espOverlay;
        overlay.hidden = !g_espEnabled;
        if (g_espEnabled) updateESP();
    }
    NSLog(@"[AmongUsCheat] ESP: %@", g_espEnabled ? @"ON" : @"OFF");
}

extern "C" void ToggleAutoWin() {
    g_autoWinEnabled = !g_autoWinEnabled;
    NSLog(@"[AmongUsCheat] AutoWin: %@", g_autoWinEnabled ? @"ON" : @"OFF");
}

extern "C" void ToggleAntiBan() {
    g_noBanMode = !g_noBanMode;
    NSLog(@"[AmongUsCheat] AntiBan: %@", g_noBanMode ? @"ON" : @"OFF");
}

extern "C" void ToggleCosmetics() {
    g_unlockAllCosmetics = !g_unlockAllCosmetics;
    NSLog(@"[AmongUsCheat] Cosmetics: %@", g_unlockAllCosmetics ? @"ON" : @"OFF");
}

extern "C" void ToggleGhosts() {
    g_showGhosts = !g_showGhosts;
    if (g_espEnabled) updateESP();
    NSLog(@"[AmongUsCheat] Show Ghosts: %@", g_showGhosts ? @"ON" : @"OFF");
}