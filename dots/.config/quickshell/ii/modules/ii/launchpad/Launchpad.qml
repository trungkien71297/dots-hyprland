import qs
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Scope {
    id: root

    Loader {
        id: launchpadLoader
        active: GlobalStates.launchpadOpen

        sourceComponent: PanelWindow {
            id: launchpadWindow
            visible: launchpadLoader.active

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            implicitWidth: launchpadBackground.width + Appearance.sizes.elevationMargin * 2
            implicitHeight: launchpadBackground.height + Appearance.sizes.elevationMargin * 2

            WlrLayershell.namespace: "quickshell:launchpad"
            WlrLayershell.layer: WlrLayer.Overlay
            // Hyprland 0.49: Focus is always exclusive and setting this breaks mouse focus grab
            // WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "transparent"

            function close(): void {
                GlobalStates.launchpadOpen = false;
            }

            mask: Region {
                item: launchpadBackground
            }

            HyprlandFocusGrab {
                id: grab
                windows: [launchpadWindow]
                active: launchpadWindow.visible
                onCleared: () => {
                    if (!active)
                        launchpadWindow.close();
                }
            }

            StyledRectangularShadow {
                target: launchpadBackground
            }

            Rectangle {
                id: launchpadBackground
                anchors.centerIn: parent
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colLayer0Border
                radius: Appearance.rounding.windowRounding

                readonly property real targetWidth: Math.floor((launchpadWindow.screen?.width ?? 1600) * 2 / 3)
                readonly property real targetHeight: Math.floor((launchpadWindow.screen?.height ?? 900) * 1 / 2)

                width: Math.max(720, Math.min(targetWidth, 1400))
                height: Math.max(520, Math.min(targetHeight, 900))

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        launchpadWindow.close();
                        event.accepted = true;
                        return;
                    }
                }

                RippleButton {
                    id: closeButton
                    implicitWidth: 40
                    implicitHeight: 40
                    buttonRadius: Appearance.rounding.full
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: 16
                        rightMargin: 16
                    }
                    onClicked: launchpadWindow.close()
                    contentItem: MaterialSymbol {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.title
                        text: "close"
                    }
                }

                LaunchpadContent {
                    id: content
                    anchors.fill: parent
                    anchors.margins: 20
                    focus: true

                    onLaunchApp: {
                        launchpadWindow.close();
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "launchpad"

        function toggle(): void {
            GlobalStates.launchpadOpen = !GlobalStates.launchpadOpen;
        }

        function close(): void {
            GlobalStates.launchpadOpen = false;
        }

        function open(): void {
            GlobalStates.launchpadOpen = true;
        }
    }

    GlobalShortcut {
        name: "launchpadToggle"
        description: "Toggles launchpad on press"

        onPressed: {
            GlobalStates.launchpadOpen = !GlobalStates.launchpadOpen;
        }
    }
}
