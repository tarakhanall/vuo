/**
 * @file
 * VuoEditorWindowCocoa implementation.
 *
 * @copyright Copyright © 2012–2020 Kosada Incorporated.
 * This code may be modified and distributed under the terms of the GNU Lesser General Public License (LGPL) version 2 or later.
 * For more information, see https://vuo.org/license.
 */

#include "VuoEditorWindowToolbar.hh"
#include "ui_VuoEditorWindow.h"

#include "VuoActivityIndicator.hh"
#include "VuoEditor.hh"
#include "VuoEditorWindow.hh"
#include "VuoErrorDialog.hh"
#include "VuoCodeWindow.hh"
#include "VuoCodeEditorStages.hh"

#if defined(slots)
#undef slots
#endif

#ifndef NS_RETURNS_INNER_POINTER
#define NS_RETURNS_INNER_POINTER
#endif
#include <Cocoa/Cocoa.h>
#include <objc/message.h>


/**
 * A multi-segment button control containing the 4 zoom operations.
 */
@interface VuoEditorZoomButtons : NSSegmentedControl
{
	QMacToolBarItem *_toolBarItem;  ///< The Qt widget corresponding to this Cocoa widget.
	bool _isDark;                   ///< True if dark mode is enabled.
	bool _isCodeEditor;             ///< True if these buttons are for a @ref VuoCodeWindow.
}
@end

@implementation VuoEditorZoomButtons
/**
 * Creates a zoom buttons widget.
 */
- (id)initWithQMacToolBarItem:(QMacToolBarItem *)toolBarItem isCodeEditor:(bool)codeEditor
{
	if (!(self = [super init]))
		return nil;

	_toolBarItem = toolBarItem;
	_isDark = false;
	_isCodeEditor = codeEditor;

	NSImage *zoomOutImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"zoom-out" ofType:@"pdf"]];
	[zoomOutImage setTemplate:YES];
	NSImage *zoomFitImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"zoom-fit" ofType:@"pdf"]];
	[zoomFitImage setTemplate:YES];
	NSImage *zoomActualImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"zoom-actual" ofType:@"pdf"]];
	[zoomActualImage setTemplate:YES];
	NSImage *zoomInImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"zoom-in" ofType:@"pdf"]];
	[zoomInImage setTemplate:YES];

	[self setSegmentCount:4];
	int segmentCount = 0;

	[self setImage:zoomOutImage forSegment:segmentCount];
	[self.cell setToolTip:[NSString stringWithUTF8String:VuoEditor::tr("Zoom Out").toUtf8().data()] forSegment:segmentCount];
	[zoomOutImage release];
	++segmentCount;

	[self setImage:zoomActualImage forSegment:segmentCount];
	[self.cell setToolTip:[NSString stringWithUTF8String:VuoEditor::tr("Actual Size").toUtf8().data()] forSegment:segmentCount];
	[zoomActualImage release];
	++segmentCount;

	if (!codeEditor)
	{
		[self setImage:zoomFitImage forSegment:segmentCount];
		[self.cell setToolTip:[NSString stringWithUTF8String:VuoEditor::tr("Zoom to Fit").toUtf8().data()] forSegment:segmentCount];
		[zoomFitImage release];
		++segmentCount;
	}

	[self setImage:zoomInImage forSegment:segmentCount];
	[self.cell setToolTip:[NSString stringWithUTF8String:VuoEditor::tr("Zoom In").toUtf8().data()] forSegment:segmentCount];
	[zoomInImage release];
	++segmentCount;

	[self setSegmentCount:segmentCount];

	[[self cell] setTrackingMode:NSSegmentSwitchTrackingMomentary];

	return self;
}

/**
 * Returns the bounds of the zoom buttons widget.
 */
- (NSRect)bounds
{
	return NSMakeRect(0, 0, [self segmentCount] == 4 ? 149 : 109, 24);
}

/**
 * Cocoa calls this method when a toolbar item is clicked.
 */
- (NSString *)itemIdentifier
{
	if (_isCodeEditor)
	{
		VuoCodeWindow *window = static_cast<VuoCodeWindow *>(_toolBarItem->parent()->parent());
		if ([self isSelectedForSegment:0])
			window->getZoomOutAction()->trigger();
		else if ([self isSelectedForSegment:1])
			window->getZoom11Action()->trigger();
		else if ([self isSelectedForSegment:2])
			window->getZoomInAction()->trigger();
	}
	else
	{
		VuoEditorWindow *window = static_cast<VuoEditorWindow *>(_toolBarItem->parent()->parent());
		if ([self isSelectedForSegment:0])
			window->getZoomOutAction()->trigger();
		else if ([self isSelectedForSegment:1])
			window->getZoom11Action()->trigger();
		else if ([self isSelectedForSegment:2])
			window->getZoomToFitAction()->trigger();
		else if ([self isSelectedForSegment:3])
			window->getZoomInAction()->trigger();
	}

	return QString::number(qulonglong(_toolBarItem)).toNSString();
}

/**
 * Renders the zoom buttons widget.
 */
- (void)drawRect:(NSRect)dirtyRect
{
	NSColor *color = [NSColor colorWithCalibratedWhite:1 alpha:(_isDark ? .2 : 1)];
	[color setFill];

	NSRect rect = [self bounds];
	rect.origin.y += 1;
	rect.size.width -= 2;
	rect.size.height -= 1;
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0];
	[path fill];

	[[self cell] drawInteriorWithFrame:dirtyRect inView:self];
}

/**
 * Applies dark mode rendering changes.
 */
- (void)updateColor:(bool)isDark
{
	_isDark = isDark;

	// Disable image-templating in dark mode, since it makes the icons too faint.
	int segments = self.segmentCount;
	for (int i = 0; i < segments; ++i)
		[[self imageForSegment:i] setTemplate:!isDark];

	self.needsDisplay = YES;
}
@end


/**
 * A "Show/Hide Events" toggle button.
 */
@interface VuoEditorEventsButton : NSView
{
	QMacToolBarItem *_toolBarItem;  ///< The Qt widget corresponding to this Cocoa widget.
	NSButton *button;               ///< The child button widget.
	bool _isDark;                   ///< True if dark mode is enabled.
}
- (id)initWithQMacToolBarItem:(QMacToolBarItem *)toolBarItem;
- (NSString *)itemIdentifier;
- (void)setState:(bool)state;
- (NSButton *)button;
@end

@implementation VuoEditorEventsButton
/**
 * Creates a show-events toggle button.
 */
- (id)initWithQMacToolBarItem:(QMacToolBarItem *)toolBarItem
{
	if (!(self = [super init]))
		return nil;

	_toolBarItem = toolBarItem;
	_isDark = false;

	button = [NSButton new];
	[button setFrame:NSMakeRect(0,1,32,24)];

	[button setButtonType:NSMomentaryChangeButton];
	[button setBordered:NO];

	[button setAction:@selector(itemIdentifier)];
	[button setTarget:self];

	[[button cell] setImageScaling:NSImageScaleNone];
	[[button cell] setShowsStateBy:NSContentsCellMask];


	// Wrap the button in a fixed-width subview, so the toolbar item doesn't change width when the label changes.
	[self setFrame:NSMakeRect(0,0,32,24)];
	[self addSubview:button];

	return self;
}

/**
 * Returns the bounds of the zoom buttons widget.
 */
- (NSRect)bounds
{
	// So the left side of the Zoom widget lines up with the left side of the canvas.
	double width = 68;

#ifdef VUO_PRO
	VuoEditorEventsButton_Pro();
#endif

	NSRect frame = button.frame;
	frame.origin.x = (width - frame.size.width) / 2.;
	button.frame = frame;

	return NSMakeRect(0, 0, width, 24);
}

/**
 * Cocoa calls this method when a toolbar item is clicked.
 */
- (NSString *)itemIdentifier
{
	VuoEditorWindow *window = static_cast<VuoEditorWindow *>(_toolBarItem->parent()->parent());
	window->getShowEventsAction()->trigger();

	return QString::number(qulonglong(_toolBarItem)).toNSString();
}

/**
 * Toggles the button.
 */
- (void)setState:(bool)state
{
	[button setState:state];

	NSImage *offImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"showEvents" ofType:@"pdf"]];
	if (state)
	{
		// Manage state manually, since we need to use NSMomentaryChangeButton to prevent the grey background when clicking.
		NSImage *onImage = [offImage copy];
		[onImage lockFocus];
		[[NSColor colorWithCalibratedRed:29./255 green:106./255 blue:229./255 alpha:1] set];	// #1d6ae5
		NSRectFillUsingOperation(NSMakeRect(0, 0, [onImage size].width, [onImage size].height), NSCompositeSourceAtop);
		[onImage unlockFocus];
		[button setImage:onImage];
		[onImage release];
	}
	else
	{
		[offImage setTemplate:YES];
		[button setImage:offImage];
	}

	[offImage release];
}

/**
 * Returns the button.
 */
- (NSButton *)button
{
	return button;
}

/**
 * Renders the button.
 */
- (void)drawRect:(NSRect)dirtyRect
{
	NSColor *color = [NSColor colorWithCalibratedWhite:1 alpha:(_isDark ? .2 : 1)];
	[color setFill];

	NSRect rect = [button frame];
	rect.origin.y -= 1;
	rect.size.height -= 1;
	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:rect xRadius:5.0 yRadius:5.0];
	[path fill];

	[super drawRect:dirtyRect];
}

/**
 * Applies dark mode rendering changes.
 */
- (void)updateColor:(bool)isDark
{
	_isDark = isDark;
	self.needsDisplay = YES;
}
@end

/**
 * On macOS 10.13, positions the sheet beneath the toolbar.
 * (On previous versions of macOS, this happened automatically,
 * but have to set titlebarAppearsTransparent on 10.13,
 * which causes sheets to incorrectly appear at the top of the window frame.)
 */
NSRect windowWillPositionSheetUsingRect(id self, SEL _cmd, NSWindow *window, NSWindow *sheet, NSRect rect)
{
	float titleAndToolbarHeight = window.frame.size.height - [window contentRectForFrameRect:window.frame].size.height;
	rect.origin.y -= titleAndToolbarHeight;
	return rect;
}

/**
 * Renders text vertically centered in the cell.
 *
 * From https://stackoverflow.com/a/33788973 .
 */
@interface VuoEditorTitleCell : NSTextFieldCell
@end
@implementation VuoEditorTitleCell
- (NSRect)titleRectForBounds:(NSRect)frame
{
	CGFloat stringHeight = self.attributedStringValue.size.height;
	NSRect titleRect = [super titleRectForBounds:frame];
	CGFloat oldOriginY = frame.origin.y;
	titleRect.origin.y = frame.origin.y + (frame.size.height - stringHeight) / 2.0;
	titleRect.size.height = titleRect.size.height - (titleRect.origin.y - oldOriginY);
	return titleRect;
}
- (void)drawInteriorWithFrame:(NSRect)cFrame inView:(NSView*)cView
{
	[super drawInteriorWithFrame:[self titleRectForBounds:cFrame] inView:cView];
}
@end

/**
 * Initializes the toolbar for this editor window.
 */
VuoEditorWindowToolbar::VuoEditorWindowToolbar(QMainWindow *window, bool isCodeEditor)
{
	NSView *nsView = (NSView *)window->winId();
	nsWindow = [nsView window];

	activityIndicatorTimer = NULL;

	running = false;
	buildInProgress = false;
	buildPending = false;
	stopInProgress = false;

	titleView = [NSTextField new];
	titleView.cell = [VuoEditorTitleCell new];
	titleView.font = [NSFont titleBarFontOfSize:0];
	titleView.selectable = NO;
	titleViewController = nil;

	toolBar = new QMacToolBar(window);
	{
		NSToolbar *tb = toolBar->nativeToolbar();

		// Workaround for apparent Qt bug, where QCocoaIntegration::clearToolbars() releases the toolbar after it's already been deallocated.
		[tb retain];

		[tb setAllowsUserCustomization:NO];
	}


	{
		runImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"run" ofType:@"pdf"]];
		[runImage setTemplate:YES];

		toolbarRunItem = toolBar->addItem(QIcon(), VuoEditor::tr("Run"));
		NSToolbarItem *ti = toolbarRunItem->nativeToolBarItem();
		[ti setImage:runImage];
		[ti setAutovalidates:NO];
		ti.toolTip = [NSString stringWithUTF8String:VuoEditor::tr("Compile and launch this composition.").toUtf8().data()];

		connect(toolbarRunItem, SIGNAL(activated()), window, SLOT(on_runComposition_triggered()));
	}


	{
		stopImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"stop" ofType:@"pdf"]];
		[stopImage setTemplate:YES];

		toolbarStopItem = toolBar->addItem(QIcon(), VuoEditor::tr("Stop"));
		NSToolbarItem *ti = toolbarStopItem->nativeToolBarItem();
		[ti setImage:stopImage];
		[ti setAutovalidates:NO];
		ti.toolTip = [NSString stringWithUTF8String:VuoEditor::tr("Shut down this composition.").toUtf8().data()];

		connect(toolbarStopItem, SIGNAL(activated()), window, SLOT(on_stopComposition_triggered()));
	}


	if (isCodeEditor)
	{
		eventsButton = NULL;
		toolbarEventsItem = NULL;
		toolBar->addSeparator();
	}
	else
	{
		toolbarEventsItem = toolBar->addItem(QIcon(), VuoEditor::tr("Show Events"));
		NSToolbarItem *ti = toolbarEventsItem->nativeToolBarItem();
		eventsButton = [[VuoEditorEventsButton alloc] initWithQMacToolBarItem:toolbarEventsItem];
		[ti setView:eventsButton];
		[ti setMinSize:[eventsButton bounds].size];
		ti.toolTip = [NSString stringWithUTF8String:VuoEditor::tr("Toggle whether the canvas shows event flow by highlighting trigger ports and nodes.").toUtf8().data()];
	}


	{
		toolbarZoomItem = toolBar->addItem(QIcon(), VuoEditor::tr("Zoom"));
		NSToolbarItem *ti = toolbarZoomItem->nativeToolBarItem();
		zoomButtons = [[VuoEditorZoomButtons alloc] initWithQMacToolBarItem:toolbarZoomItem isCodeEditor:isCodeEditor];
		[ti setView:zoomButtons];
		[ti setMinSize:[zoomButtons bounds].size];
	}


	VuoEditor *editor = (VuoEditor *)qApp;
	connect(editor, &VuoEditor::darkInterfaceToggled, this, &VuoEditorWindowToolbar::updateColor);
	updateColor(editor->isInterfaceDark());

#if VUO_PRO
	VuoEditorWindowToolbar_Pro();
#endif

	toolBar->attachToWindow(window->windowHandle());


	if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion == 13)
		class_addMethod(nsWindow.delegate.class,
						@selector(window:willPositionSheet:usingRect:),
						(IMP)windowWillPositionSheetUsingRect,
						"{CGRect={CGPoint=dd}{CGSize=dd}}@:@@{CGRect={CGPoint=dd}{CGSize=dd}}");
}

/**
 * Deallocates toolbar data.
 */
VuoEditorWindowToolbar::~VuoEditorWindowToolbar()
{
#if VUO_PRO
	VuoEditorWindowToolbarDestructor_Pro();
#endif
}

/**
 * Initializes the toolbar for this editor window.
 */
void VuoEditorWindowToolbar::update(bool eventsShown, bool zoomedToActualSize, bool zoomedToFit)
{
#if VUO_PRO
	update_Pro();
#endif

	if (!toolbarRunItem)
		return;

	NSToolbarItem *runItem  = toolbarRunItem->nativeToolBarItem();
	NSToolbarItem *stopItem = toolbarStopItem->nativeToolBarItem();

	if (stopInProgress)
	{
		[runItem  setEnabled:!buildPending];
		[stopItem setEnabled:NO];
	}
	else if (buildInProgress)
	{
		[runItem  setEnabled:NO];
		[stopItem setEnabled:YES];
	}
	else if (running)
	{
		[runItem  setEnabled:NO];
		[stopItem setEnabled:YES];
	}
	else
	{
		[runItem  setEnabled:YES];
		[stopItem setEnabled:NO];
	}

	if (toolbarEventsItem)
	{
		NSToolbarItem *eventsItem = toolbarEventsItem->nativeToolBarItem();
		[eventsItem setLabel:(eventsShown
			? [NSString stringWithUTF8String:VuoEditor::tr("Hide Events").toUtf8().data()]
			: [NSString stringWithUTF8String:VuoEditor::tr("Show Events").toUtf8().data()])];
		VuoEditorEventsButton *eventsButton = (VuoEditorEventsButton *)[eventsItem view];
		[eventsButton setState:eventsShown];
	}

	// Enable/disable the zoom11 (actual size) segment.
	[(NSSegmentedControl *)[toolbarZoomItem->nativeToolBarItem() view] setEnabled:!zoomedToActualSize forSegment:1];

	// Enable/disable the "Zoom to Fit" segment.
	[(NSSegmentedControl *)[toolbarZoomItem->nativeToolBarItem() view] setEnabled:!zoomedToFit forSegment:2];

	updateActivityIndicators();
}

/**
 * Indicates that a version of the composition is waiting to build.
 * A previous version may still be stopping at this point.
 */
void VuoEditorWindowToolbar::changeStateToBuildPending()
{
	buildPending = true;
}

/**
 * Advances the state from "build pending" to "build in progress".
 */
void VuoEditorWindowToolbar::changeStateToBuildInProgress()
{
	buildPending = false;
	buildInProgress = true;
}

/**
 * Advances the state from "build in progress" to "running".
 */
void VuoEditorWindowToolbar::changeStateToRunning()
{
	buildInProgress = false;
	running = true;
}

/**
 * Advances the state from "running" to "stop in progress".
 */
void VuoEditorWindowToolbar::changeStateToStopInProgress()
{
	stopInProgress = true;
}

/**
 * Advances the state from "stop in progress" to "stopped".
 */
void VuoEditorWindowToolbar::changeStateToStopped()
{
	buildInProgress = false;
	running = false;
	stopInProgress = false;
}

/**
 * Returns true if the window's composition is waiting to build.
 */
bool VuoEditorWindowToolbar::isBuildPending()
{
	return buildPending;
}

/**
 * Returns true if the window's composition is building.
 */
bool VuoEditorWindowToolbar::isBuildInProgress()
{
	return buildInProgress;
}

/**
 * Returns true if the window's composition is running.
 */
bool VuoEditorWindowToolbar::isRunning()
{
	return running;
}

/**
 * Returns true if the window's composition is stopping.
 */
bool VuoEditorWindowToolbar::isStopInProgress()
{
	return stopInProgress;
}

/**
 * Returns true if System Preferences > General > Show Scroll Bars is set to "When Scrolling" (only available on Mac OS 10.7+).
 * In this mode, scrollbars are drawn as overlays on top of content (instead of reducing the content area).
 */
bool VuoEditorWindowToolbar::usingOverlayScrollers()
{
	return [NSScroller preferredScrollerStyle] == NSScrollerStyleOverlay;
}

/**
 * Updates the animation of the activity indicators for building or stopping the composition (if needed).
 */
void VuoEditorWindowToolbar::updateActivityIndicators(void)
{
	if (buildInProgress || stopInProgress)
	{
		if (! activityIndicatorTimer)
		{
			activityIndicatorFrame = 0;

			activityIndicatorTimer = new QTimer(this);
			activityIndicatorTimer->setObjectName("VuoEditorWindowToolbar::activityIndicatorTimer");
			connect(activityIndicatorTimer, SIGNAL(timeout()), this, SLOT(updateActivityIndicators()));
			activityIndicatorTimer->start(250);
		}
	}
	else
	{
		if (activityIndicatorTimer)
		{
			activityIndicatorTimer->stop();
			delete activityIndicatorTimer;
			activityIndicatorTimer = NULL;
		}
	}

	if (buildInProgress)
	{
		VuoActivityIndicator *iconEngine = new VuoActivityIndicator(activityIndicatorFrame++);
		toolbarRunItem->setIcon(QIcon(iconEngine));
	}
	else
		[(NSToolbarItem *)toolbarRunItem->nativeToolBarItem() setImage:runImage];

	if (stopInProgress)
	{
		VuoActivityIndicator *iconEngine = new VuoActivityIndicator(activityIndicatorFrame++);
		toolbarStopItem->setIcon(QIcon(iconEngine));
	}
	else
		[(NSToolbarItem *)toolbarStopItem->nativeToolBarItem() setImage:stopImage];
}

/**
 * Makes the titlebar/toolbar dark (Digital Color Meter set to "Display native values" reads 0x808080).
 */
void VuoEditorWindowToolbar::updateColor(bool isDark)
{
	[(VuoEditorEventsButton *)eventsButton updateColor:isDark];
	[(VuoEditorEventsButton *)zoomButtons updateColor:isDark];

	{
		// Request a transparent titlebar (and toolbar) so the window's background color (set below) shows through.
		// "Previously NSWindow would make the titlebar transparent for certain windows with NSWindowStyleMaskTexturedBackground set,
		// even if titlebarAppearsTransparent was NO.  When linking against the 10.13 SDK, textured windows must
		// explicitly set titlebarAppearsTransparent to YES for this behavior."
		// - https://developer.apple.com/library/content/releasenotes/AppKit/RN-AppKit/
		objc_msgSend(nsWindow, sel_getUid("setTitlebarAppearsTransparent:"), true);

		// Requesting a transparent titlebar causes toolbar drawing to glitch (icons change color when defocused; text looks anemic).
		// Enabling Core Animation seems to avoid that Cocoa bug.
		((NSView *)nsWindow.contentView).wantsLayer = YES;

		if (NSProcessInfo.processInfo.operatingSystemVersion.minorVersion >= 12)
		{
			// "A window with titlebarAppearsTransparent is normally opted-out of automatic window tabbing."
			// - https://developer.apple.com/library/archive/releasenotes/AppKit/RN-AppKit/index.html
			// …but it works fine for us, so reenable it.
			// https://b33p.net/kosada/node/15412
			objc_msgSend(nsWindow, sel_getUid("setTabbingMode:"), 0 /*NSWindowTabbingModeAutomatic*/);
			objc_msgSend(nsWindow, sel_getUid("setTabbingIdentifier:"), @"Vuo Composition");
		}
	}

	if (isDark)
		[nsWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:.47 alpha:1]];
	else
		[nsWindow setBackgroundColor:[NSColor colorWithCalibratedWhite:.92 alpha:1]];
}