pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

RowLayout {
    id: root
    spacing: 12
    property bool animateWidth: false
    property alias searchInput: searchInput
    property string searchingText
    
    readonly property bool isActive: searchingText !== ""
    property int itemHeight: 46

    function forceFocus() {
        searchInput.forceActiveFocus();
    }

    enum SearchPrefixType { Action, App, Clipboard, Emojis, Math, ShellCommand, WebSearch, DefaultSearch }

    property var searchPrefixType: {
        if (root.searchingText.startsWith(Config.options.search.prefix.action)) return SearchBar.SearchPrefixType.Action;
        if (root.searchingText.startsWith(Config.options.search.prefix.app)) return SearchBar.SearchPrefixType.App;
        if (root.searchingText.startsWith(Config.options.search.prefix.clipboard)) return SearchBar.SearchPrefixType.Clipboard;
        if (root.searchingText.startsWith(Config.options.search.prefix.emojis)) return SearchBar.SearchPrefixType.Emojis;
        if (root.searchingText.startsWith(Config.options.search.prefix.math)) return SearchBar.SearchPrefixType.Math;
        if (root.searchingText.startsWith(Config.options.search.prefix.shellCommand)) return SearchBar.SearchPrefixType.ShellCommand;
        if (root.searchingText.startsWith(Config.options.search.prefix.webSearch)) return SearchBar.SearchPrefixType.WebSearch;
        return SearchBar.SearchPrefixType.DefaultSearch;
    }

    // --- 1. SEARCH INPUT ---
    Rectangle {
        id: inputBackground
        Layout.fillWidth: true
        Layout.preferredHeight: root.itemHeight
        Layout.alignment: Qt.AlignVCenter
        Layout.minimumWidth: 200
        
        radius: height / 2
        color: ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.4)
        antialiasing: true
        smooth: true
        border.width: 0
        
        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutQuad } }
        clip: true

        ToolbarTextField { 
            id: searchInput
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            verticalAlignment: TextInput.AlignVCenter
            background: Item {} 

            focus: GlobalStates.overviewOpen
            font.pixelSize: Appearance.font.pixelSize.small
            placeholderText: Translation.tr("Search, calculate or run")
            
            color: Appearance.colors.colOnSurface
            placeholderTextColor: ColorUtils.transparentize(color, 0.4)
            
            Behavior on color { ColorAnimation { duration: 300 } }

            onTextChanged: LauncherSearch.query = text
            onAccepted: {
                if (appResults.count > 0) {
                    let firstItem = appResults.itemAtIndex(0);
                    if (firstItem && firstItem.clicked) firstItem.clicked();
                }
            }
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Tab) {
                    if (LauncherSearch.results.length === 0) return;
                    const tabbedText = LauncherSearch.results[0].name;
                    LauncherSearch.query = tabbedText;
                    searchInput.text = tabbedText;
                    event.accepted = true;
                }
            }
        }
    }

    // --- 2. SEARCH ICON (POPS FIRST - delay 100ms) ---
    Rectangle {
        id: iconBackground
        Layout.preferredWidth: root.itemHeight
        Layout.preferredHeight: root.itemHeight
        Layout.alignment: Qt.AlignVCenter
        radius: height / 2
        
        color: root.isActive 
               ? ColorUtils.transparentize(Appearance.colors.colPrimaryContainer, 0.3)
               : ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.4)
        
        antialiasing: true
        smooth: true
        border.width: 0

        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.OutQuad } }
        
        // Pop animation
        property real animScale: 1
        property real animOpacity: 1
        scale: animScale
        opacity: animOpacity
        
        SequentialAnimation {
            id: iconPopAnimation
            running: false
            
            PauseAnimation { duration: 100 }
            
            ParallelAnimation {
                NumberAnimation {
                    target: iconBackground
                    property: "animScale"
                    from: 0.3
                    to: 1
                    duration: 400
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.5
                }
                
                NumberAnimation {
                    target: iconBackground
                    property: "animOpacity"
                    from: 0
                    to: 1
                    duration: 300
                }
            }
        }
        
        Connections {
            target: GlobalStates
            function onOverviewOpenChanged() {
                if (GlobalStates.overviewOpen) {
                    iconPopAnimation.start();
                }
            }
        }

        MaterialShapeWrappedMaterialSymbol {
            id: searchIcon
            anchors.centerIn: parent
            iconSize: Appearance.font.pixelSize.large
            
            color: root.isActive 
                   ? Appearance.colors.colOnPrimaryContainer
                   : Appearance.colors.colOnSurface
            Behavior on color { ColorAnimation { duration: 300 } }

            shape: switch(root.searchPrefixType) {
                case SearchBar.SearchPrefixType.Action: return MaterialShape.Shape.Pill;
                case SearchBar.SearchPrefixType.App: return MaterialShape.Shape.Clover4Leaf;
                case SearchBar.SearchPrefixType.Clipboard: return MaterialShape.Shape.Gem;
                case SearchBar.SearchPrefixType.Emojis: return MaterialShape.Shape.Sunny;
                case SearchBar.SearchPrefixType.Math: return MaterialShape.Shape.PuffyDiamond;
                case SearchBar.SearchPrefixType.ShellCommand: return MaterialShape.Shape.PixelCircle;
                case SearchBar.SearchPrefixType.WebSearch: return MaterialShape.Shape.SoftBurst;
                default: return MaterialShape.Shape.Cookie7Sided;
            }
            text: switch (root.searchPrefixType) {
                case SearchBar.SearchPrefixType.Action: return "settings_suggest";
                case SearchBar.SearchPrefixType.App: return "apps";
                case SearchBar.SearchPrefixType.Clipboard: return "content_paste_search";
                case SearchBar.SearchPrefixType.Emojis: return "add_reaction";
                case SearchBar.SearchPrefixType.Math: return "calculate";
                case SearchBar.SearchPrefixType.ShellCommand: return "terminal";
                case SearchBar.SearchPrefixType.WebSearch: return "travel_explore";
                case SearchBar.SearchPrefixType.DefaultSearch: return "search";
                default: return "search";
            }
        }
    }

    // --- 3. RIGHT BUTTONS ---
    Item {
        id: rightButtonsWrapper
        Layout.alignment: Qt.AlignVCenter
        
        property real contentWidth: rightButtonLayout.implicitWidth
        
        Layout.preferredWidth: root.isActive ? 0 : contentWidth
        Layout.preferredHeight: root.itemHeight
        clip: true 

        Behavior on Layout.preferredWidth { 
            NumberAnimation { 
                duration: 450
                easing.type: Easing.OutExpo 
            } 
        }

        RowLayout {
            id: rightButtonLayout
            spacing: 12
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            
            opacity: root.isActive ? 0 : 1
            visible: opacity > 0
            Behavior on opacity { 
                NumberAnimation { 
                    duration: 250
                    easing.type: Easing.OutQuad 
                } 
            }

            // -- Google Lens (SECOND - delay 250ms) --
            IconToolbarButton {
                id: lensButton
                implicitWidth: root.itemHeight
                implicitHeight: root.itemHeight
                onClicked: {
                    GlobalStates.overviewOpen = false;
                    Quickshell.execDetached(["qs", "-p", Quickshell.shellPath(""), "ipc", "call", "region", "search"]);
                }
                text: "image_search"
                
                property real animScale: 1
                property real animOpacity: 1
                scale: animScale
                opacity: animOpacity
                
                SequentialAnimation {
                    id: lensPopAnimation
                    running: false
                    
                    PauseAnimation { duration: 250 }
                    
                    ParallelAnimation {
                        NumberAnimation {
                            target: lensButton
                            property: "animScale"
                            from: 0.3
                            to: 1
                            duration: 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                        
                        NumberAnimation {
                            target: lensButton
                            property: "animOpacity"
                            from: 0
                            to: 1
                            duration: 300
                        }
                    }
                }
                
                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        if (GlobalStates.overviewOpen) {
                            lensPopAnimation.start();
                        }
                    }
                }
                
                background: Rectangle {
                    radius: parent.height / 2
                    antialiasing: true
                    smooth: true
                    color: parent.hovered ? ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.3) 
                                          : ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.4)
                    border.width: 0
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
                StyledToolTip { text: Translation.tr("Google Lens") }
            }

            // -- Song Rec (THIRD - delay 400ms) --
            IconToolbarButton {
                id: songRecButton
                implicitWidth: root.itemHeight
                implicitHeight: root.itemHeight
                toggled: SongRec.running
                onClicked: SongRec.toggleRunning()
                text: "music_cast"

                colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                
                property real animScale: 1
                property real animOpacity: 1
                scale: animScale
                opacity: animOpacity
                
                SequentialAnimation {
                    id: songPopAnimation
                    running: false
                    
                    PauseAnimation { duration: 400 }
                    
                    ParallelAnimation {
                        NumberAnimation {
                            target: songRecButton
                            property: "animScale"
                            from: 0.3
                            to: 1
                            duration: 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                        
                        NumberAnimation {
                            target: songRecButton
                            property: "animOpacity"
                            from: 0
                            to: 1
                            duration: 300
                        }
                    }
                }
                
                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        if (GlobalStates.overviewOpen) {
                            songPopAnimation.start();
                        }
                    }
                }
                
                background: MaterialShape {
                    antialiasing: true
                    smooth: true
                    RotationAnimation on rotation {
                        running: songRecButton.toggled
                        duration: 12000
                        easing.type: Easing.Linear
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                    }
                    shape: MaterialShape.Shape.Circle 
                    color: {
                        if (songRecButton.toggled) return songRecButton.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                        else return songRecButton.hovered ? ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.3) 
                                                          : ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.4)
                    }
                    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                }
                StyledToolTip { text: Translation.tr("Recognize music") }
            }

            // -- Workspace Toggle (FOURTH - delay 550ms) --
            IconToolbarButton {
                id: workspaceToggleButton
                implicitWidth: root.itemHeight
                implicitHeight: root.itemHeight
                toggled: GlobalStates.workspaceVisible
                onClicked: GlobalStates.workspaceVisible = !GlobalStates.workspaceVisible
                text: "grid_view"

                colText: toggled ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSurfaceVariant
                
                property real animScale: 1
                property real animOpacity: 1
                scale: animScale
                opacity: animOpacity
                
                SequentialAnimation {
                    id: workspacePopAnimation
                    running: false
                    
                    PauseAnimation { duration: 550 }
                    
                    ParallelAnimation {
                        NumberAnimation {
                            target: workspaceToggleButton
                            property: "animScale"
                            from: 0.3
                            to: 1
                            duration: 400
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.5
                        }
                        
                        NumberAnimation {
                            target: workspaceToggleButton
                            property: "animOpacity"
                            from: 0
                            to: 1
                            duration: 300
                        }
                    }
                }
                
                Connections {
                    target: GlobalStates
                    function onOverviewOpenChanged() {
                        if (GlobalStates.overviewOpen) {
                            workspacePopAnimation.start();
                        }
                    }
                }
                
                background: MaterialShape {
                    antialiasing: true
                    smooth: true
                    shape: MaterialShape.Shape.Circle
                    color: {
                        if (workspaceToggleButton.toggled) return workspaceToggleButton.hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary
                        else return workspaceToggleButton.hovered ? ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHighest, 0.3) 
                                                                  : ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.4)
                    }
                    Behavior on color { animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this) }
                }
                StyledToolTip { text: Translation.tr("Toggle workspaces") }
            }
        }
    }
}
