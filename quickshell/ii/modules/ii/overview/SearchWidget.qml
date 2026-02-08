pragma ComponentBehavior: Bound

import Qt.labs.synchronizer
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    readonly property string xdgConfigHome: Directories.config
    readonly property int typingDebounceInterval: 200
    readonly property int typingResultLimit: 15 

    property string searchingText: LauncherSearch.query
    property bool showResults: searchingText != ""
    
    property real idleWidth: Math.max(Appearance.sizes.searchWidth * 1.5, 600)
    property real expandedWidth: Appearance.sizes.searchWidth * 2.2
    
    implicitWidth: showResults ? expandedWidth : idleWidth
    
    // FIXED: Smooth width animation
    Behavior on implicitWidth { 
        NumberAnimation { 
            duration: 500
            easing.type: Easing.OutExpo 
        } 
    }
    
    implicitHeight: searchWidgetContent.implicitHeight

    function focusFirstItem() { appResults.currentIndex = 0; }
    function focusSearchInput() { searchBar.forceFocus(); }
    function disableExpandAnimation() { searchBar.animateWidth = false; }
    function cancelSearch() { searchBar.searchInput.selectAll(); LauncherSearch.query = ""; searchBar.animateWidth = true; }
    function setSearchingText(text) { searchBar.searchInput.text = text; LauncherSearch.query = text; }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) return;
        if (event.key === Qt.Key_Backspace) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                if (event.modifiers & Qt.ControlModifier) {
                    let text = searchBar.searchInput.text;
                    let pos = searchBar.searchInput.cursorPosition;
                    if (pos > 0) {
                        let left = text.slice(0, pos);
                        let match = left.match(/(\s*\S+)\s*$/);
                        let deleteLen = match ? match[0].length : 1;
                        searchBar.searchInput.text = text.slice(0, pos - deleteLen) + text.slice(pos);
                        searchBar.searchInput.cursorPosition = pos - deleteLen;
                    }
                } else {
                    if (searchBar.searchInput.cursorPosition > 0) {
                        searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition - 1) + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                        searchBar.searchInput.cursorPosition -= 1;
                    }
                }
                searchBar.searchInput.cursorPosition = searchBar.searchInput.text.length;
                event.accepted = true;
            }
            return;
        }
        if (event.text && event.text.length === 1 && event.key !== Qt.Key_Enter && event.key !== Qt.Key_Return && event.key !== Qt.Key_Delete && event.text.charCodeAt(0) >= 0x20) {
            if (!searchBar.searchInput.activeFocus) {
                root.focusSearchInput();
                searchBar.searchInput.text = searchBar.searchInput.text.slice(0, searchBar.searchInput.cursorPosition) + event.text + searchBar.searchInput.text.slice(searchBar.searchInput.cursorPosition);
                searchBar.searchInput.cursorPosition += 1;
                event.accepted = true;
                root.focusFirstItem();
            }
        }
    }

    Item {
        id: searchWidgetContent
        anchors.top: parent.top
        anchors.topMargin: 40
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: root.implicitWidth
        implicitHeight: columnLayout.implicitHeight

        ColumnLayout {
            id: columnLayout
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width 
            spacing: 0

            SearchBar {
                id: searchBar
                Layout.fillWidth: true
                Layout.topMargin: 0
                Layout.bottomMargin: 0
                Synchronizer on searchingText {
                    property alias source: root.searchingText
                }
            }

            // FIXED: Properly rounded blur with outline
            Item {
                id: resultContainerWrapper
                visible: root.showResults
                Layout.fillWidth: true
                Layout.topMargin: 10
                
                // SMOOTH HEIGHT ANIMATION
                implicitHeight: root.showResults ? (resultContainer.implicitHeight + 4) : 0
                
                Behavior on implicitHeight { 
                    NumberAnimation { 
                        duration: 450
                        easing.type: Easing.OutExpo 
                    } 
                }
                
                // SMOOTH OPACITY for the whole container
                opacity: root.showResults ? 1 : 0
                Behavior on opacity { 
                    NumberAnimation { 
                        duration: 350
                        easing.type: Easing.OutQuad 
                    } 
                }

                // FIXED: Outer outline container
                Rectangle {
                    id: outlineContainer
                    anchors.fill: parent
                    radius: 26
                    antialiasing: true
                    smooth: true
                    color: "transparent"
                    border.width: 2
                    border.color: ColorUtils.transparentize(Appearance.colors.colOutline, 0.7)
                }

                // Blur background layer (properly clipped)
                Rectangle {
                    id: blurBackground
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 24
                    color: "transparent"
                    
                    antialiasing: true
                    smooth: true
                    clip: true
                    
                    // FIXED: Proper blur clipping with layer
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: blurBackground.width
                            height: blurBackground.height
                            radius: 24
                            antialiasing: true
                            smooth: true
                        }
                    }
                    
                    Rectangle {
                        anchors.fill: parent
                        radius: 24
                        antialiasing: true
                        smooth: true
                        color: ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.5)
                        
                        layer.enabled: true
                        layer.effect: FastBlur {
                            radius: 32
                            transparentBorder: false
                            cached: true
                        }
                    }
                }

                // Content layer
                Rectangle {
                    id: resultContainer
                    anchors.fill: parent
                    anchors.margins: 2
                    
                    radius: 24
                    antialiasing: true
                    smooth: true
                    clip: true
                    
                    color: ColorUtils.transparentize(Appearance.colors.colBackgroundSurfaceContainer, 0.15)
                    
                    implicitHeight: appResults.implicitHeight + 20

                    ListView {
                        id: appResults
                        anchors.fill: parent
                        anchors.margins: 10
                        
                        implicitHeight: Math.min(600, contentHeight)
                        
                        clip: true
                        spacing: 2
                        KeyNavigation.up: searchBar
                        highlightMoveDuration: 100

                        onFocusChanged: { if (focus) appResults.currentIndex = 1; }

                        Connections {
                            target: root
                            function onSearchingTextChanged() { if (appResults.count > 0) appResults.currentIndex = 0; }
                        }

                        Timer {
                            id: debounceTimer
                            interval: root.typingDebounceInterval
                            onTriggered: { resultModel.values = LauncherSearch.results ?? []; }
                        }

                        Connections {
                            target: LauncherSearch
                            function onResultsChanged() {
                                resultModel.values = LauncherSearch.results.slice(0, root.typingResultLimit);
                                root.focusFirstItem();
                                debounceTimer.restart();
                            }
                        }

                        model: ScriptModel {
                            id: resultModel
                            objectProp: "key"
                        }

                        delegate: SearchItem {
                            id: searchItem
                            required property var modelData
                            anchors.left: parent?.left
                            anchors.right: parent?.right
                            entry: modelData
                            query: StringUtils.cleanOnePrefix(root.searchingText, [Config.options.search.prefix.action, Config.options.search.prefix.app, Config.options.search.prefix.clipboard, Config.options.search.prefix.emojis, Config.options.search.prefix.math, Config.options.search.prefix.shellCommand, Config.options.search.prefix.webSearch])

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Tab) {
                                    if (LauncherSearch.results.length === 0) return;
                                    const tabbedText = searchItem.modelData.name;
                                    LauncherSearch.query = tabbedText;
                                    searchBar.searchInput.text = tabbedText;
                                    event.accepted = true;
                                    root.focusSearchInput();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
