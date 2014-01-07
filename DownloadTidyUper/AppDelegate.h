//
//  AppDelegate.h
//  DownloadTidyUper
//
//  Created by surrender on 14-1-2.
//
//

#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>



@property (assign) IBOutlet NSWindow *window;
@property (nonatomic, strong) NSDictionary *dic;
@property (assign) BOOL isTidy;
@property (assign) BOOL finished;
@property (weak) IBOutlet NSProgressIndicator *progressIndocator;
@property (weak) IBOutlet NSView *customView;
@property (weak) IBOutlet NSButton *helpButton;
@property (weak) IBOutlet NSButton *startButton;
@property (weak) IBOutlet NSButton *undoButton;
@property (weak) IBOutlet NSTextField *nameLabel;
@property (weak) IBOutlet NSTextField *textInfo;


- (IBAction)start:(id)sender;
- (IBAction)undo:(id)sender;
- (IBAction)help:(id)sender;
@end
