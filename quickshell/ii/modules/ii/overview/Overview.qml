import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false
    
    // FIXED: Track if we've done initial animation
    property bool hasAnimatedOnce: false

    PanelWindow {
        id: panelWindow
        
        property string searchingText: ""
        
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)
        property bool monitorIsFocused: (Hyprland.focusedMonitor?.id == monitor?.id)
        
        visible: GlobalStates.overviewOpen || searchBarAnimator.running || workspaceAnimator.running

        WlrLayershell.namespace: "quickshell-overview"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"

        mask: Region {
            item: GlobalStates.overviewOpen || searchBarAnimator.running || workspaceAnimator.running ? columnLayout : null
        }

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (!GlobalStates.overviewOpen) {
                    searchWidget.disableExpandAnimation();
                    overviewScope.dontAutoCancelSearch = false;
                    GlobalFocusGrab.dismiss();
                    overviewScope.hasAnimatedOnce = false;
                } else {
                    if (!overviewScope.dontAutoCancelSearch) {
                        searchWidget.cancelSearch();
                    }
                    GlobalFocusGrab.addDismissable(panelWindow);
                }
            }
        }

        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                GlobalStates.overviewOpen = false;
            }
        }
        implicitWidth: columnLayout.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        function setSearchingText(text) {
            searchWidget.setSearchingText(text);
            searchWidget.focusFirstItem();
        }

        Column {
            id: columnLayout
            visible: GlobalStates.overviewOpen || searchBarAnimator.running || workspaceAnimator.running
            anchors.centerIn: parent
            
            spacing: 30

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    GlobalStates.overviewOpen = false;
                } else if (event.key === Qt.Key_Left) {
                    if (!panelWindow.searchingText)
                        Hyprland.dispatch("workspace r-1");
                } else if (event.key === Qt.Key_Right) {
                    if (!panelWindow.searchingText)
                        Hyprland.dispatch("workspace r+1");
                }
            }

            // SEARCH BAR - Animates FIRST (only on launch)
            Item {
                id: searchBarContainer
                width: searchWidget.implicitWidth
                height: searchWidget.implicitHeight
                anchors.horizontalCenter: parent.horizontalCenter
                
                opacity: searchBarAnimator.targetOpacity
                scale: searchBarAnimator.targetScale
                transformOrigin: Item.Center
                
                NumberAnimation {
                    id: searchBarAnimator
                    property real targetOpacity: GlobalStates.overviewOpen ? 1 : 0
                    property real targetScale: GlobalStates.overviewOpen ? 1 : 0.9
                    
                    running: false
                    
                    property bool shouldRun: GlobalStates.overviewOpen
                    onShouldRunChanged: {
                        // FIXED: Only animate on first open
                        if (shouldRun && !overviewScope.hasAnimatedOnce) {
                            overviewScope.hasAnimatedOnce = true;
                            searchBarOpacityAnim.from = 0;
                            searchBarOpacityAnim.to = 1;
                            searchBarScaleAnim.from = 0.9;
                            searchBarScaleAnim.to = 1;
                            searchBarOpacityAnim.start();
                            searchBarScaleAnim.start();
                        } else if (shouldRun) {
                            // Already animated, just show
                            targetOpacity = 1;
                            targetScale = 1;
                        } else {
                            // Closing
                            searchBarOpacityAnim.from = 1;
                            searchBarOpacityAnim.to = 0;
                            searchBarScaleAnim.from = 1;
                            searchBarScaleAnim.to = 0.9;
                            searchBarOpacityAnim.start();
                            searchBarScaleAnim.start();
                        }
                    }
                }
                
                NumberAnimation {
                    id: searchBarOpacityAnim
                    target: searchBarAnimator
                    property: "targetOpacity"
                    duration: 300
                    easing.type: Easing.OutCubic
                }
                
                NumberAnimation {
                    id: searchBarScaleAnim
                    target: searchBarAnimator
                    property: "targetScale"
                    duration: 350
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }

                SearchWidget {
                    id: searchWidget
                    anchors.fill: parent
                    Synchronizer on searchingText {
                        property alias source: panelWindow.searchingText
                    }
                }
            }

            // WORKSPACE OVERVIEW - FIXED: Smooth toggle without launch animation
            Loader {
                id: overviewLoader
                anchors.horizontalCenter: parent.horizontalCenter
                active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true) && GlobalStates.workspaceVisible
                
                // FIXED: Simple opacity fade for workspace toggle
                opacity: workspaceAnimator.targetOpacity
                scale: workspaceAnimator.targetScale
                transformOrigin: Item.Top
                
                NumberAnimation {
                    id: workspaceAnimator
                    property real targetOpacity: (GlobalStates.overviewOpen && overviewLoader.active) ? 1 : 0
                    property real targetScale: (GlobalStates.overviewOpen && overviewLoader.active) ? 1 : 0.95
                    
                    running: false
                    
                    property bool shouldRun: GlobalStates.overviewOpen && overviewLoader.active
                    onShouldRunChanged: {
                        if (shouldRun && !overviewScope.hasAnimatedOnce) {
                            // First time - delayed animation
                            workspaceDelayTimer.start();
                        } else if (shouldRun) {
                            // Just toggling on - smooth fade in
                            workspaceOpacityAnim.from = targetOpacity;
                            workspaceOpacityAnim.to = 1;
                            workspaceOpacityAnim.duration = 250;
                            workspaceScaleAnim.from = targetScale;
                            workspaceScaleAnim.to = 1;
                            workspaceScaleAnim.duration = 250;
                            workspaceOpacityAnim.start();
                            workspaceScaleAnim.start();
                        } else {
                            // Toggling off - smooth fade out
                            workspaceDelayTimer.stop();
                            workspaceOpacityAnim.from = targetOpacity;
                            workspaceOpacityAnim.to = 0;
                            workspaceOpacityAnim.duration = 200;
                            workspaceScaleAnim.from = targetScale;
                            workspaceScaleAnim.to = 0.95;
                            workspaceScaleAnim.duration = 200;
                            workspaceOpacityAnim.start();
                            workspaceScaleAnim.start();
                        }
                    }
                }
                
                Timer {
                    id: workspaceDelayTimer
                    interval: 150
                    repeat: false
                    onTriggered: {
                        workspaceOpacityAnim.from = 0;
                        workspaceOpacityAnim.to = 1;
                        workspaceOpacityAnim.duration = 350;
                        workspaceScaleAnim.from = 0.95;
                        workspaceScaleAnim.to = 1;
                        workspaceScaleAnim.duration = 400;
                        workspaceOpacityAnim.start();
                        workspaceScaleAnim.start();
                    }
                }
                
                NumberAnimation {
                    id: workspaceOpacityAnim
                    target: workspaceAnimator
                    property: "targetOpacity"
                    duration: 350
                    easing.type: Easing.OutCubic
                }
                
                NumberAnimation {
                    id: workspaceScaleAnim
                    target: workspaceAnimator
                    property: "targetScale"
                    duration: 400
                    easing.type: Easing.OutCubic
                }
                
                sourceComponent: OverviewWidget {
                    screen: panelWindow.screen
                    visible: (panelWindow.searchingText == "")
                }
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        panelWindow.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"
        function toggle() { GlobalStates.overviewOpen = !GlobalStates.overviewOpen; }
        function workspacesToggle() { GlobalStates.overviewOpen = !GlobalStates.overviewOpen; }
        function close() { GlobalStates.overviewOpen = false; }
        function open() { GlobalStates.overviewOpen = true; }
        function toggleReleaseInterrupt() { GlobalStates.superReleaseMightTrigger = false; }
        function clipboardToggle() { overviewScope.toggleClipboard(); }
    }

    GlobalShortcut { name: "searchToggle"; onPressed: { GlobalStates.overviewOpen = !GlobalStates.overviewOpen; } }
    GlobalShortcut { name: "overviewWorkspacesClose"; onPressed: { GlobalStates.overviewOpen = false; } }
    GlobalShortcut { name: "overviewWorkspacesToggle"; onPressed: { GlobalStates.overviewOpen = !GlobalStates.overviewOpen; } }
    GlobalShortcut {
        name: "searchToggleRelease"
        onPressed: { GlobalStates.superReleaseMightTrigger = true; }
        onReleased: { if (!GlobalStates.superReleaseMightTrigger) { GlobalStates.superReleaseMightTrigger = true; return; } GlobalStates.overviewOpen = !GlobalStates.overviewOpen; }
    }
    GlobalShortcut { name: "searchToggleReleaseInterrupt"; onPressed: { GlobalStates.superReleaseMightTrigger = false; } }
    GlobalShortcut { name: "overviewClipboardToggle"; onPressed: { overviewScope.toggleClipboard(); } }
    GlobalShortcut { name: "overviewEmojiToggle"; onPressed: { overviewScope.toggleEmojis(); } }
}
