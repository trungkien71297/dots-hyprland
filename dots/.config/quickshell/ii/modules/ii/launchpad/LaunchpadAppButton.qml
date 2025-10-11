pragma ComponentBehavior: Bound


import QtQuick
import QtQuick.Layouts
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.waffle.looks
import qs
import qs.services
import Qt.labs.synchronizer
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

RippleButton {
    id: root

    required property DesktopEntry desktopEntry

    buttonRadius: 14
    pointingHandCursor: true

    colBackground: ColorUtils.transparentize(Appearance.colors.colLayer1Hover, 1)
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active

    contentItem: ColumnLayout {
        anchors.centerIn: parent
        spacing: 6

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 56
            implicitHeight: 56

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: ColorUtils.transparentize(Appearance.colors.colSurfaceContainerHigh, 0.3)
            }

            WAppIcon {
                anchors.centerIn: parent
                iconName: root.desktopEntry.icon
                implicitSize: 32
                tryCustomIcon: false
            }
        }

        StyledText {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            text: root.desktopEntry.name
            color: Appearance.colors.colOnLayer0
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }
}
