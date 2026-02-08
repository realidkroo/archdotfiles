pragma ComponentBehavior: Bound

import qs.modules.ii.bar.weather
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Scope {
    id: pillBar

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }

        LazyLoader {
            id: pillBarLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked && Config.options.bar.pillDock.enable
            required property ShellScreen modelData

            component: PanelWindow {
                id: pillBarRoot
                screen: pillBarLoader.modelData

                readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
                readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
                readonly property bool focusingThisMonitor: HyprlandData.activeWorkspace?.monitor == monitor?.name
                readonly property var biggestWindow: HyprlandData.biggestWindowForWorkspace(HyprlandData.monitors[monitor?.id]?.activeWorkspace.id)
                property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
                property bool isHovered: hoverArea.containsMouse
                property bool shouldShow: !Config.options.bar.pillDock.autoHide || isHovered

                function truncateTitle(title, maxLen) {
                    if (!title) return "";
                    if (title.length <= maxLen) return title;
                    return title.substring(0, maxLen) + "...";
                }

                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: Config.options.bar.pillDock.pushWindows ? (Appearance.sizes.baseBarHeight + Config.options.bar.pillDock.margin) : 0
                WlrLayershell.namespace: "quickshell:pillbar"
                WlrLayershell.layer: WlrLayer.Top

                implicitHeight: Appearance.sizes.baseBarHeight + Config.options.bar.pillDock.margin + (Config.options.bar.pillDock.autoHide ? 5 : 0)
                implicitWidth: screen.width

                color: "transparent"

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                Component.onCompleted: {
                    GlobalFocusGrab.addPersistent(pillBarRoot);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(pillBarRoot);
                }

                // Hover detection area for auto-hide
                MouseArea {
                    id: hoverArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                // Shadow
                StyledRectangularShadow {
                    target: pillBackground
                    visible: pillBarRoot.shouldShow
                    opacity: pillBackground.opacity
                }

                // Background pill
                Rectangle {
                    id: pillBackground
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        top: !Config.options.bar.bottom ? parent.top : undefined
                        bottom: Config.options.bar.bottom ? parent.bottom : undefined
                        topMargin: Config.options.bar.pillDock.margin
                        bottomMargin: Config.options.bar.pillDock.margin
                    }
                    width: pillContent.implicitWidth + 16
                    height: Appearance.sizes.baseBarHeight
                    radius: Appearance.rounding.windowRounding
                    color: Appearance.colors.colLayer0
                    border.width: 1
                    border.color: Appearance.colors.colLayer0Border
                    clip: true

                    opacity: pillBarRoot.shouldShow ? 1 : 0
                    y: pillBarRoot.shouldShow ? 0 : (Config.options.bar.bottom ? Appearance.sizes.baseBarHeight : -Appearance.sizes.baseBarHeight)
                    
                    Behavior on opacity {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on y {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    Behavior on width {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                    }
                }

                // Content
                RowLayout {
                    id: pillContent
                    anchors.centerIn: pillBackground
                    height: pillBackground.height
                    spacing: 4

                    Behavior on implicitWidth {
                        animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
                    }

                    // Left sidebar button
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        LeftSidebarButton {
                            colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                        }
                    }

                    // Active window (truncated)
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        ColumnLayout {
                            spacing: -4
                            StyledText {
                                Layout.maximumWidth: 150
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colSubtext
                                elide: Text.ElideRight
                                text: pillBarRoot.focusingThisMonitor && pillBarRoot.activeWindow?.activated && pillBarRoot.biggestWindow ?
                                    pillBarRoot.activeWindow?.appId :
                                    (pillBarRoot.biggestWindow?.class) ?? Translation.tr("Desktop")
                            }
                            StyledText {
                                Layout.maximumWidth: 150
                                font.pixelSize: Appearance.font.pixelSize.small
                                color: Appearance.colors.colOnLayer0
                                elide: Text.ElideRight
                                text: {
                                    const title = pillBarRoot.focusingThisMonitor && pillBarRoot.activeWindow?.activated && pillBarRoot.biggestWindow ?
                                        pillBarRoot.activeWindow?.title :
                                        (pillBarRoot.biggestWindow?.title) ?? `${Translation.tr("Workspace")} ${pillBarRoot.monitor?.activeWorkspace?.id ?? 1}`;
                                    return pillBarRoot.truncateTitle(title, Config.options.bar.pillDock.maxTitleLength);
                                }
                            }
                        }
                    }

                    // Resources
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        Resources {
                            alwaysShowAllResources: false
                        }
                    }

                    // Workspaces
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        padding: workspacesWidget.widgetPadding
                        Workspaces {
                            id: workspacesWidget
                            Layout.fillHeight: true
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.RightButton
                                onPressed: event => {
                                    if (event.button === Qt.RightButton) {
                                        GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
                                    }
                                }
                            }
                        }
                    }

                    // Clock & Utils
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        ClockWidget {
                            showDate: true
                            Layout.alignment: Qt.AlignVCenter
                        }
                        BatteryIndicator {
                            visible: Battery.available
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }

                    // Weather (if enabled)
                    Loader {
                        active: Config.options.bar.weather.enable
                        Layout.alignment: Qt.AlignVCenter
                        sourceComponent: BarGroup {
                            WeatherBar {}
                        }
                    }

                    // System tray
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        SysTray {
                            Layout.fillHeight: true
                            invertSide: Config?.options.bar.bottom
                        }
                    }

                    // Right indicators
                    BarGroup {
                        Layout.alignment: Qt.AlignVCenter
                        RippleButton {
                            id: rightSidebarButton
                            implicitWidth: indicatorsRowLayout.implicitWidth + 10 * 2
                            implicitHeight: indicatorsRowLayout.implicitHeight + 5 * 2
                            buttonRadius: Appearance.rounding.full
                            colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
                            colBackgroundHover: Appearance.colors.colLayer1Hover
                            colRipple: Appearance.colors.colLayer1Active
                            colBackgroundToggled: Appearance.colors.colSecondaryContainer
                            colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                            colRippleToggled: Appearance.colors.colSecondaryContainerActive
                            toggled: GlobalStates.sidebarRightOpen
                            property color colText: toggled ? Appearance.m3colors.m3onSecondaryContainer : Appearance.colors.colOnLayer0

                            Behavior on colText {
                                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                            }

                            onClicked: GlobalStates.sidebarRightOpen = !GlobalStates.sidebarRightOpen

                            RowLayout {
                                id: indicatorsRowLayout
                                anchors.centerIn: parent
                                property real realSpacing: 15
                                spacing: 0

                                Revealer {
                                    reveal: Audio.sink?.audio?.muted ?? false
                                    Layout.fillHeight: true
                                    Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                    MaterialSymbol {
                                        text: "volume_off"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: rightSidebarButton.colText
                                    }
                                }
                                Revealer {
                                    reveal: Audio.source?.audio?.muted ?? false
                                    Layout.fillHeight: true
                                    Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                    MaterialSymbol {
                                        text: "mic_off"
                                        iconSize: Appearance.font.pixelSize.larger
                                        color: rightSidebarButton.colText
                                    }
                                }
                                HyprlandXkbIndicator {
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.rightMargin: indicatorsRowLayout.realSpacing
                                    color: rightSidebarButton.colText
                                }
                                Revealer {
                                    reveal: Notifications.silent || Notifications.unread > 0
                                    Layout.fillHeight: true
                                    Layout.rightMargin: reveal ? indicatorsRowLayout.realSpacing : 0
                                    NotificationUnreadCount {}
                                }
                                MaterialSymbol {
                                    text: Network.materialSymbol
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: rightSidebarButton.colText
                                }
                                MaterialSymbol {
                                    Layout.leftMargin: indicatorsRowLayout.realSpacing
                                    visible: BluetoothStatus.available
                                    text: BluetoothStatus.connected ? "bluetooth_connected" : BluetoothStatus.enabled ? "bluetooth" : "bluetooth_disabled"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: rightSidebarButton.colText
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
