import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Loader {
        id: networkWallpaperLoader
        active: GlobalStates.networkWallpaperOpen

        sourceComponent: PanelWindow {
            id: panelWindow
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:networkWallpaper"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            color: "transparent"

            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true

            mask: Region {
                item: content
            }

            Component.onCompleted: {
                GlobalFocusGrab.addDismissable(panelWindow);
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.networkWallpaperOpen = false;
                }
            }

            NetworkWallpaperContent {
                id: content
                anchors.centerIn: parent
            }
        }
    }

    IpcHandler {
        target: "networkWallpaper"

        function toggle(): void {
            GlobalStates.networkWallpaperOpen = !GlobalStates.networkWallpaperOpen;
        }

        function open(): void {
            GlobalStates.networkWallpaperOpen = true;
        }

        function close(): void {
            GlobalStates.networkWallpaperOpen = false;
        }
    }

    GlobalShortcut {
        name: "networkWallpaperToggle"
        appid: "quickshell"
        description: "Toggle network wallpaper picker"
        onPressed: {
            GlobalStates.networkWallpaperOpen = !GlobalStates.networkWallpaperOpen;
        }
    }
}
