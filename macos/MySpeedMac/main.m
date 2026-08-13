#import <Cocoa/Cocoa.h>
#import <ServiceManagement/ServiceManagement.h>

static NSString *const MySpeedProductName = @"MySpeed macOS";

static NSString *L(NSString *key) {
    return NSLocalizedString(key, nil);
}

@interface MySpeedAppDelegate : NSObject <NSApplicationDelegate>
@property(nonatomic, strong) NSStatusItem *statusItem;
@property(nonatomic, strong) NSMenuItem *statusMenuItem;
@property(nonatomic, strong) NSMenuItem *loginMenuItem;
@property(nonatomic, strong) NSTask *backend;
@property(nonatomic, strong) NSFileHandle *logHandle;
@property(nonatomic, strong) NSTimer *healthTimer;
@property(nonatomic, strong) NSURL *supportDirectory;
@property(nonatomic) NSInteger healthAttempts;
@property(nonatomic) BOOL isQuitting;
@property(nonatomic) BOOL ownsBackend;
@end

@implementation MySpeedAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSURL *applicationSupport = [[[NSFileManager defaultManager]
        URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] firstObject];
    self.supportDirectory = [applicationSupport URLByAppendingPathComponent:@"MySpeed" isDirectory:YES];
    [self configureMenu];

    NSError *error = nil;
    if (![self prepareRuntime:&error]) {
        [self setStatus:L(@"status.launchFailed")];
        [self showError:[NSString stringWithFormat:L(@"error.runtimePrepare"), error.localizedDescription]];
        return;
    }
    [self probeExistingServer];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    self.isQuitting = YES;
    [self.healthTimer invalidate];
    if (self.ownsBackend && self.backend.running) {
        [self.backend terminate];
        [self.backend waitUntilExit];
    }
    [self.logHandle closeFile];
}

- (void)configureMenu {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.image = [NSImage imageWithSystemSymbolName:@"gauge.with.dots.needle.50percent"
                                            accessibilityDescription:@"MySpeed"];
    self.statusItem.button.toolTip = MySpeedProductName;

    NSMenu *menu = [[NSMenu alloc] init];
    self.statusMenuItem = [[NSMenuItem alloc] initWithTitle:L(@"status.starting") action:nil keyEquivalent:@""];
    self.statusMenuItem.enabled = NO;
    [menu addItem:self.statusMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self menuItem:L(@"menu.openDashboard") action:@selector(openDashboard:) key:@"o"]];
    [menu addItem:[self menuItem:L(@"menu.restartService") action:@selector(restartBackend:) key:@"r"]];
    [menu addItem:[self menuItem:L(@"menu.openDataDirectory") action:@selector(openDataDirectory:) key:@""]];
    [menu addItem:[self menuItem:L(@"menu.viewLog") action:@selector(openLog:) key:@""]];
    [menu addItem:[NSMenuItem separatorItem]];

    self.loginMenuItem = [self menuItem:L(@"menu.launchAtLogin") action:@selector(toggleLoginItem:) key:@""];
    self.loginMenuItem.state = SMAppService.mainAppService.status == SMAppServiceStatusEnabled
        ? NSControlStateValueOn : NSControlStateValueOff;
    [menu addItem:self.loginMenuItem];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItem:[self menuItem:L(@"menu.quit") action:@selector(quit:) key:@"q"]];
    self.statusItem.menu = menu;
}

- (NSMenuItem *)menuItem:(NSString *)title action:(SEL)action key:(NSString *)key {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = self;
    return item;
}

- (BOOL)prepareRuntime:(NSError **)error {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray<NSURL *> *directories = @[
        self.supportDirectory,
        [self.supportDirectory URLByAppendingPathComponent:@"bin" isDirectory:YES],
        [self.supportDirectory URLByAppendingPathComponent:@"data/logs" isDirectory:YES],
        [self.supportDirectory URLByAppendingPathComponent:@"data/servers" isDirectory:YES],
        [self.supportDirectory URLByAppendingPathComponent:@"data/certs" isDirectory:YES]
    ];
    for (NSURL *directory in directories) {
        if (![manager createDirectoryAtURL:directory withIntermediateDirectories:YES attributes:nil error:error]) return NO;
    }

    NSURL *bundledBin = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"bin" isDirectory:YES];
    NSURL *destinationBin = [self.supportDirectory URLByAppendingPathComponent:@"bin" isDirectory:YES];
    NSArray<NSURL *> *providers = [manager contentsOfDirectoryAtURL:bundledBin
                                         includingPropertiesForKeys:nil options:0 error:error];
    if (!providers) return NO;

    for (NSURL *source in providers) {
        NSURL *destination = [destinationBin URLByAppendingPathComponent:source.lastPathComponent];
        if ([manager fileExistsAtPath:destination.path] && ![manager removeItemAtURL:destination error:error]) return NO;
        if (![manager copyItemAtURL:source toURL:destination error:error]) return NO;
        if (![manager setAttributes:@{NSFilePosixPermissions: @0755} ofItemAtPath:destination.path error:error]) return NO;
    }

    NSURL *logURL = [self.supportDirectory URLByAppendingPathComponent:@"data/logs/macos-app.log"];
    if (![manager fileExistsAtPath:logURL.path]) [manager createFileAtPath:logURL.path contents:nil attributes:nil];
    self.logHandle = [NSFileHandle fileHandleForWritingAtPath:logURL.path];
    [self.logHandle seekToEndOfFile];
    return self.logHandle != nil;
}

- (void)probeExistingServer {
    NSURL *dashboard = [NSURL URLWithString:@"http://127.0.0.1:5216"];
    __weak typeof(self) weakSelf = self;
    [[[NSURLSession sharedSession] dataTaskWithURL:dashboard
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                typeof(self) self = weakSelf;
                if (!self) return;
                if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                    self.ownsBackend = NO;
                    [self setStatus:L(@"status.running")];
                } else {
                    [self startBackendAndOpen:YES];
                }
            });
        }] resume];
}

- (void)startBackendAndOpen:(BOOL)openWhenReady {
    if (self.backend.running) return;
    NSURL *backendURL = [[[[NSBundle mainBundle] executableURL] URLByDeletingLastPathComponent]
                         URLByAppendingPathComponent:@"MySpeedBackend"];
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:backendURL.path]) {
        [self setStatus:L(@"status.backendMissing")];
        [self showError:L(@"error.backendMissing")];
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.executableURL = backendURL;
    task.currentDirectoryURL = self.supportDirectory;
    NSMutableDictionary *environment = [[[NSProcessInfo processInfo] environment] mutableCopy];
    NSString *language = [NSLocale preferredLanguages].firstObject ?: @"en";
    BOOL usesChineseDefaults = [language.lowercaseString hasPrefix:@"zh"];
    if (!environment[@"SERVER_PORT"]) environment[@"SERVER_PORT"] = @"5216";
    if (!environment[@"MYSPEED_UI_LANGUAGE"]) environment[@"MYSPEED_UI_LANGUAGE"] = language;
    if (!environment[@"MYSPEED_DEFAULT_PROVIDER"])
        environment[@"MYSPEED_DEFAULT_PROVIDER"] = usesChineseDefaults ? @"libre" : @"cloudflare";
    if (!environment[@"MYSPEED_DEFAULT_LIBRE_ID"])
        environment[@"MYSPEED_DEFAULT_LIBRE_ID"] = usesChineseDefaults ? @"cn-edu-nju" : @"none";
    if (!environment[@"MYSPEED_SKIP_OOKLA_DOWNLOAD"]) environment[@"MYSPEED_SKIP_OOKLA_DOWNLOAD"] = @"true";
    task.environment = environment;
    task.standardOutput = self.logHandle;
    task.standardError = self.logHandle;

    __weak typeof(self) weakSelf = self;
    task.terminationHandler = ^(NSTask *finishedTask) {
        dispatch_async(dispatch_get_main_queue(), ^{
            typeof(self) self = weakSelf;
            if (!self) return;
            self.backend = nil;
            self.ownsBackend = NO;
            if (!self.isQuitting) {
                [self setStatus:[NSString stringWithFormat:L(@"status.stopped"), finishedTask.terminationStatus]];
            }
        });
    };

    NSError *error = nil;
    if ([task launchAndReturnError:&error]) {
        self.backend = task;
        self.ownsBackend = YES;
        [self setStatus:L(@"status.startingService")];
        [self beginHealthChecksAndOpen:openWhenReady];
    } else {
        [self setStatus:L(@"status.launchFailed")];
        [self showError:[NSString stringWithFormat:L(@"error.backendLaunch"), error.localizedDescription]];
    }
}

- (void)beginHealthChecksAndOpen:(BOOL)openWhenReady {
    [self.healthTimer invalidate];
    self.healthAttempts = 0;
    __weak typeof(self) weakSelf = self;
    self.healthTimer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
        typeof(self) self = weakSelf;
        if (!self) { [timer invalidate]; return; }
        self.healthAttempts += 1;
        NSURL *dashboard = [NSURL URLWithString:@"http://127.0.0.1:5216"];
        [[[NSURLSession sharedSession] dataTaskWithURL:dashboard
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([(NSHTTPURLResponse *)response statusCode] == 200) {
                        [timer invalidate];
                        [self setStatus:L(@"status.running")];
                        if (openWhenReady) [self openDashboard:nil];
                    } else if (self.healthAttempts >= 30) {
                        [timer invalidate];
                        [self setStatus:L(@"status.notResponding")];
                    }
                });
            }] resume];
    }];
}

- (void)setStatus:(NSString *)text {
    self.statusMenuItem.title = text;
    self.statusItem.button.toolTip = [NSString stringWithFormat:@"%@ · %@", MySpeedProductName, text];
}

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = MySpeedProductName;
    alert.informativeText = message;
    [alert runModal];
}

- (void)openDashboard:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://127.0.0.1:5216"]];
}

- (void)openDataDirectory:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:self.supportDirectory];
}

- (void)openLog:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[self.supportDirectory URLByAppendingPathComponent:@"data/logs/macos-app.log"]];
}

- (void)restartBackend:(id)sender {
    [self.healthTimer invalidate];
    if (self.ownsBackend && self.backend.running) {
        self.isQuitting = YES;
        [self.backend terminate];
        [self.backend waitUntilExit];
        self.isQuitting = NO;
    }
    self.backend = nil;
    self.ownsBackend = NO;
    [self startBackendAndOpen:NO];
}

- (void)toggleLoginItem:(id)sender {
    NSError *error = nil;
    SMAppService *service = SMAppService.mainAppService;
    BOOL success = service.status == SMAppServiceStatusEnabled
        ? [service unregisterAndReturnError:&error]
        : [service registerAndReturnError:&error];
    if (!success) {
        [self showError:[NSString stringWithFormat:L(@"error.loginItem"), error.localizedDescription]];
    }
    self.loginMenuItem.state = service.status == SMAppServiceStatusEnabled
        ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)quit:(id)sender {
    [[NSApplication sharedApplication] terminate:nil];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *application = [NSApplication sharedApplication];
        MySpeedAppDelegate *delegate = [[MySpeedAppDelegate alloc] init];
        application.delegate = delegate;
        [application setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [application run];
    }
    return 0;
}
