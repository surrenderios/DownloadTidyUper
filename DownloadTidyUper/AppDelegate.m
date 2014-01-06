//
//  AppDelegate.m
//  DownloadTidyUper
//
//  Created by surrender on 14-1-2.
//
//

#import "AppDelegate.h"
#import <Carbon/Carbon.h>
#import "SFBPopover.h"

//用于保存快捷键事件回调的引用，以便于可以注销
static EventHandlerRef g_EventHandlerRef = NULL;

//用于保存快捷键注册的引用，便于可以注销该快捷键
static EventHotKeyRef a_HotKeyRef = NULL;
static EventHotKeyRef b_HotKeyRef = NULL;

//快捷键注册使用的信息，用在回调中判断是哪个快捷键被触发
static EventHotKeyID a_HotKeyID = {'keyA',1};
static EventHotKeyID b_HotKeyID = {'keyB',2};

//快捷键的回调方法
OSStatus myHotKeyHandler(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData)
{
    //判定事件的类型是否与所注册的一致
    if (GetEventClass(inEvent) == kEventClassKeyboard && GetEventKind(inEvent) == kEventHotKeyPressed)
    {
        //获取快捷键信息，以判定是哪个快捷键被触发
        EventHotKeyID keyID;
        GetEventParameter(inEvent,
                          kEventParamDirectObject,
                          typeEventHotKeyID,
                          NULL,
                          sizeof(keyID),
                          NULL,
                          &keyID);
        if (keyID.id == a_HotKeyID.id) {
            NSLog(@"pressed:shift+command+A");
        }
        if (keyID.id == b_HotKeyID.id) {
            NSLog(@"pressed:option+B");
        }
    }
    
    return noErr;
}

@interface AppDelegate ()
{
@private
    SFBPopover * _popover;
}

@end

@implementation AppDelegate

#define kDMG          @"DMG"
#define kZIP          @"ZIP"
#define kMOVIE        @"Movies"
#define kMP3          @"Mp3"
#define kPIC          @"Pictures"
#define kDocs         @"Document"
#define kApplication  @"Applications"

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    //先注册快捷键的事件回调
    EventTypeSpec eventSpecs[] = {{kEventClassKeyboard,kEventHotKeyPressed}};
    InstallApplicationEventHandler(NewEventHandlerUPP(myHotKeyHandler),
                                   GetEventTypeCount(eventSpecs),
                                   eventSpecs,
                                   NULL,
                                   &g_EventHandlerRef);
    //注册快捷键:shift+command+A
    RegisterEventHotKey(kVK_ANSI_A,
                        cmdKey|shiftKey,
                        a_HotKeyID,
                        GetApplicationEventTarget(),
                        0,
                        &a_HotKeyRef);
    
    //注册快捷键:option+B
    RegisterEventHotKey(kVK_ANSI_B,
                        optionKey,
                        b_HotKeyID,
                        GetApplicationEventTarget(),
                        0,
                        &b_HotKeyRef);
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    //注销快捷键
    if (a_HotKeyRef)
    {
        UnregisterEventHotKey(a_HotKeyRef);
        a_HotKeyRef = NULL;
    }
    if (b_HotKeyRef)
    {
        UnregisterEventHotKey(b_HotKeyRef);
        b_HotKeyRef = NULL;
    }
    //注销快捷键的事件回调
    if (g_EventHandlerRef)
    {
        RemoveEventHandler(g_EventHandlerRef);
        g_EventHandlerRef = NULL;
    }
    
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag
{
    [self.window makeKeyAndOrderFront:nil];
    return YES;
}

- (void)awakeFromNib
{
    _dic = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"typeDic" ofType:@"plist"]];
    [_progressIndocator setMinValue:0.0];
    [_progressIndocator setMaxValue:100.0];
    
    _popover = [[SFBPopover alloc] initWithContentView:_customView];
    
    [_popover setBackgroundColor:[NSColor controlColor]];
    [_popover setDrawsArrow:YES];
    [_popover setPosition:SFBPopoverPositionBottom];
    [_popover setMovable:NO];
}


- (IBAction)start:(id)sender
{
    if (_isTidy) {
        return;
    }
    
    if (_finished) {
        NSAlert *alert = [self cancelAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    BOOL finished = [self tidyDownloads];
    
    //开始整理
    if (finished && !_isTidy) {
        sleep(1);
  
        NSAlert *alert = [self openDownloadAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(openaAlertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}




- (IBAction)undo:(id)sender
{
    if (_isTidy) {
        return;
    }
    if (_finished) {
        NSAlert *alert = [self WarmingAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
    }
}

- (IBAction)help:(id)sender
{
    if ([_popover isVisible]) {
        [_popover closePopover:sender];
    }else{
        NSPoint where = [_helpButton frame].origin;
		where.x += [_helpButton frame].size.width / 2;
		where.y += [_helpButton frame].size.height / 2;
        
		[_popover displayPopoverInWindow:[_helpButton window] atPoint:where];
    }
}

#pragma delegate
- (void) alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn) {
        return;
    }else{
        //取消之前的整理
        [self cancelTydiUp];
    }
}
- (void) openaAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
{
    if (returnCode == NSAlertDefaultReturn)  [[NSWorkspace sharedWorkspace]openFile:[[self DownloadPath] path]];
}
/*********************************分割线*******************************/

- (NSURL *)DownloadPath
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDownloadsDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSArray *)tidyUpFolderPath
{
    NSString *dPath = [[self DownloadPath] path];
    NSString *dmg = [dPath stringByAppendingPathComponent:kDMG];
    NSString *zip = [dPath stringByAppendingPathComponent:kZIP];
    NSString *movie = [dPath stringByAppendingPathComponent:kMOVIE];
    NSString *mp3 = [dPath stringByAppendingPathComponent:kMP3];
    NSString *pic = [dPath stringByAppendingPathComponent:kPIC];
    NSString *docs = [dPath stringByAppendingPathComponent:kDocs];
    NSString *apps = [dPath stringByAppendingPathComponent:kApplication];
    return @[dmg,zip,movie,mp3,pic,docs,apps];
}

- (BOOL)tidyDownloads
{
    [_progressIndocator setDoubleValue:0.0];
    [_progressIndocator incrementBy:20.0];
    _isTidy = YES;

     NSFileManager *fm = [NSFileManager defaultManager];
    
    //get download path
    NSString *DownloadPath = [[self DownloadPath] path];
    
    //first of all,get all the files in Downloads
    NSArray *DownloadFiles = [fm contentsOfDirectoryAtPath:DownloadPath error:nil];
    
    //if  few files,promote user do not have to tidy up
    if ([DownloadFiles count] < 10) {
        NSAlert *alert = [self doNotNeedAlert];
        [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
    }
    
    NSArray *folderNames = [self tidyUpFolderPath];
    for (NSString *path in folderNames) {
        if ([fm fileExistsAtPath:path]) {
              continue;
        }
        //else create a folder
        BOOL createBool  =  [fm createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
        if (!createBool) NSLog(@"error create folder");
    }
    
    NSString *dmgPath = [folderNames objectAtIndex:0];
    NSString *zipPath = [folderNames objectAtIndex:1];
    NSString *moviePath = [folderNames objectAtIndex:2];
    NSString *mp3Path = [folderNames objectAtIndex:3];
    NSString *picPath = [folderNames objectAtIndex:3];
    NSString *docPath = [folderNames objectAtIndex:5];
    NSString *appPath = [folderNames objectAtIndex:6];
    
    NSArray *dmgArray = [_dic objectForKey:kDMG];
    NSArray *zipArray = [_dic objectForKey:kZIP];
    NSArray *movieArray = [_dic objectForKey:kMOVIE];
    NSArray *mp3Array = [_dic objectForKey:kMP3];
    NSArray *picArray = [_dic objectForKey:kPIC];
    NSArray *docArray = [_dic objectForKey:kDocs];
    NSArray *appArray = [_dic objectForKey:kApplication];
    
    for (NSString *path in DownloadFiles) {
        //progress ++
       
        NSString *fullPath = [DownloadPath stringByAppendingPathComponent:path];
        NSString *extension = [path pathExtension];
        if (![fm fileExistsAtPath:fullPath]) {
            NSLog(@"file not exist");
            continue;
        }
        
        if ([dmgArray containsObject:extension]) {
               if (![fm moveItemAtPath:fullPath toPath:[dmgPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
        }
        else if ([zipArray containsObject:extension]){
            if (![fm moveItemAtPath:fullPath toPath:[zipPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
        }
        else if ([movieArray containsObject:extension]){
            if (![fm moveItemAtPath:fullPath toPath:[moviePath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
            
        }
        else if ([mp3Array containsObject:extension]){
            if (![fm moveItemAtPath:fullPath toPath:[mp3Path stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
        }
        else if ([picArray containsObject:extension]){
            if (![fm moveItemAtPath:fullPath toPath:[picPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
        }
        else if ([docArray containsObject:extension]){
            if (![fm moveItemAtPath:fullPath toPath:[docPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
        }
        else if ([appArray containsObject:extension]){
            if (![fm moveItemAtPath:fullPath toPath:[appPath stringByAppendingPathComponent:path] error:nil]) NSLog(@"move %@ failed",path);
        }
    }
    _isTidy = NO;
    _finished = YES;
    [_progressIndocator setDoubleValue:100.0];
    
     return YES;
}

- (void)cancelTydiUp
{
    [_progressIndocator setDoubleValue:0.0];
    [_progressIndocator incrementBy:20.0];
    _isTidy = YES;
    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *DownloadPath = [[self DownloadPath] path];
    NSArray *folderNames = [self tidyUpFolderPath];
    for (NSString *path in folderNames) {
        if (![fm fileExistsAtPath:path]) continue;

        NSArray *content = [fm contentsOfDirectoryAtPath:path error:nil];
        for (NSString *cPath in content) {
            NSString *fullPath = [path stringByAppendingPathComponent:cPath];
            if (![fm moveItemAtPath:fullPath toPath:[DownloadPath stringByAppendingPathComponent:cPath]error:nil]) {
                NSLog(@"move %@ failed",fullPath);
            }
        }
    }
    
    _finished = NO;
    _isTidy = NO;
    [_progressIndocator setDoubleValue:100.0];
}


- (NSAlert *)WarmingAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Attention" defaultButton:@"no" alternateButton:@"yes" otherButton:nil informativeTextWithFormat:@"Will you cancel the last tidyup?"];
    return alert;
}

- (NSAlert *)cancelAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Attention" defaultButton:@"yes" alternateButton:nil otherButton:nil informativeTextWithFormat:@"you have tidy up Downloads finished,Do not need tidy again"];
    return alert;
}

- (NSAlert *)doNotNeedAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Attention" defaultButton:@"yes" alternateButton:nil otherButton:nil informativeTextWithFormat:@"There is few files,you do not need tidyup"];
    return alert;
}

- (NSAlert *)openDownloadAlert
{
    NSAlert *alert = [NSAlert alertWithMessageText:@"Congradulation" defaultButton:@"yes" alternateButton:@"no" otherButton:Nil informativeTextWithFormat:@"I have tidy up your download finished,would you like to have a look at it"];
    return alert;
}


@end
