import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import QtQuick.Effects
import Quickshell
import Quickshell.Io

MouseArea {
    id: root
    
    implicitWidth: 420
    implicitHeight: background.height + Appearance.sizes.elevationMargin * 2
    
    property string previewSource: ""
    property int selectedSourceIndex: 0
    property bool isLoading: RandomNetworkWallpaper.loading
    property bool hasPreview: previewSource !== "" && !isLoading
    
    readonly property var sourcesList: [
        { key: "wallhaven", name: "Wallhaven", icon: "image" },
        { key: "anime", name: "Anime", icon: "star" },
        { key: "danbooru", name: "Danbooru", icon: "auto_awesome" },
        { key: "konachan", name: "Konachan", icon: "landscape" },
        { key: "gelbooru", name: "Gelbooru", icon: "collections" },
        { key: "safebooru", name: "Safebooru", icon: "verified" },
        { key: "picre", name: "pic.re", icon: "palette" },
        { key: "waifu", name: "Waifu", icon: "face" },
        { key: "reddit", name: "Reddit", icon: "forum" },
        { key: "animewallpaper", name: "r/Anime", icon: "favorite" },
        { key: "widescreen", name: "Wide", icon: "panorama" },
        { key: "minimal", name: "Minimal", icon: "square" }
    ]

    // Update preview when wallpaper is ready
    Connections {
        target: RandomNetworkWallpaper
        function onWallpaperReady(path) {
            root.previewSource = "file://" + path
        }
        function onErrorOccurred(message) {
            print("[NetworkWallpaperUI] Error:", message)
        }
    }

    // Shadow
    StyledRectangularShadow {
        target: background
    }

    // Main background
    Rectangle {
        id: background
        anchors.centerIn: parent
        width: parent.width - Appearance.sizes.elevationMargin * 2
        height: mainLayout.implicitHeight + 32
        color: Appearance.colors.colLayer0
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        radius: Appearance.rounding.screenRounding - Appearance.sizes.hyprlandGapsOut + 1

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                MaterialSymbol {
                    text: "cloud_download"
                    iconSize: 22
                    color: Appearance.colors.colOnLayer0
                }

                StyledText {
                    text: "Network Wallpaper"
                    font.pixelSize: Appearance.font.pixelSize.larger
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                IconToolbarButton {
                    implicitWidth: 28
                    implicitHeight: 28
                    text: "close"
                    onClicked: GlobalStates.networkWallpaperOpen = false
                }
            }

            // Source selector - 2 rows
            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 6
                columnSpacing: 6

                Repeater {
                    model: root.sourcesList

                    RippleButton {
                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        buttonRadius: Appearance.rounding.small
                        toggled: root.selectedSourceIndex === index
                        colBackground: toggled ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer1
                        colBackgroundHover: toggled ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer1Hover
                        colRipple: Appearance.colors.colLayer1Active

                        onClicked: {
                            root.selectedSourceIndex = index
                            RandomNetworkWallpaper.setSource(modelData.key)
                        }

                        contentItem: RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            MaterialSymbol {
                                text: modelData.icon
                                iconSize: 14
                                color: parent.parent.toggled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            }

                            StyledText {
                                text: modelData.name
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: parent.parent.toggled ? Appearance.colors.colOnPrimaryContainer : Appearance.colors.colOnLayer1
                            }
                        }

                        StyledToolTip {
                            text: root.sourcesList[index]?.key || ""
                        }
                    }
                }
            }

            // Image preview area
            Rectangle {
                id: previewContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                color: Appearance.colors.colLayer1
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: Appearance.colors.colLayer1Border
                clip: true

                // Placeholder when no image
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: !previewImage.visible && !root.isLoading

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "wallpaper"
                        iconSize: 40
                        color: Appearance.colors.colOnLayer1Inactive
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Click 'Fetch' to get a wallpaper"
                        color: Appearance.colors.colOnLayer1Inactive
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }

                // Loading indicator
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    visible: root.isLoading

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        text: "progress_activity"
                        iconSize: 40
                        color: Appearance.colors.colPrimary

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                            running: root.isLoading
                        }
                    }

                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Fetching..."
                        color: Appearance.colors.colOnLayer1Inactive
                    }
                }

                // Preview image
                Image {
                    id: previewImage
                    anchors.fill: parent
                    anchors.margins: 4
                    source: root.previewSource
                    fillMode: Image.PreserveAspectFit
                    visible: status === Image.Ready && !root.isLoading
                    asynchronous: true
                    cache: false

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: previewImage.width
                            height: previewImage.height
                            radius: Appearance.rounding.small
                        }
                    }
                }

                // Source badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    visible: previewImage.visible
                    color: Appearance.m3colors.darkmode ? "#80000000" : "#80ffffff"
                    radius: Appearance.rounding.small
                    implicitWidth: badgeRow.implicitWidth + 10
                    implicitHeight: badgeRow.implicitHeight + 4

                    RowLayout {
                        id: badgeRow
                        anchors.centerIn: parent
                        spacing: 3

                        MaterialSymbol {
                            text: root.sourcesList[root.selectedSourceIndex]?.icon || "image"
                            iconSize: 12
                            color: Appearance.colors.colOnLayer0
                        }

                        StyledText {
                            text: root.sourcesList[root.selectedSourceIndex]?.name || ""
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            color: Appearance.colors.colOnLayer0
                        }
                    }
                }
            }

            // Action buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Fetch button
                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    enabled: !root.isLoading
                    buttonRadius: Appearance.rounding.normal
                    colBackground: Appearance.colors.colLayer1
                    colBackgroundHover: Appearance.colors.colLayer1Hover
                    colRipple: Appearance.colors.colLayer1Active

                    onClicked: {
                        RandomNetworkWallpaper.fetchRandom("")
                    }

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: root.isLoading ? "hourglass_empty" : "shuffle"
                            iconSize: 18
                            color: Appearance.colors.colOnLayer1
                        }

                        StyledText {
                            text: root.isLoading ? "Loading..." : "Fetch"
                            color: Appearance.colors.colOnLayer1
                        }
                    }
                }

                // Accept/Apply button - prominent when preview exists
                RippleButton {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    visible: root.hasPreview
                    buttonRadius: Appearance.rounding.normal
                    colBackground: Appearance.colors.colPrimary
                    colBackgroundHover: Appearance.colors.colPrimaryHover
                    colRipple: Appearance.colors.colPrimaryActive

                    onClicked: {
                        if (RandomNetworkWallpaper.lastDownloadedPath) {
                            Wallpapers.apply(RandomNetworkWallpaper.lastDownloadedPath)
                            GlobalStates.networkWallpaperOpen = false
                        }
                    }

                    contentItem: RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        MaterialSymbol {
                            text: "check"
                            iconSize: 18
                            color: Appearance.colors.colOnPrimary
                        }

                        StyledText {
                            text: "Accept"
                            color: Appearance.colors.colOnPrimary
                            font.bold: true
                        }
                    }
                }

                // Open folder button (right-click for settings)
                Item {
                    id: folderButtonContainer
                    implicitWidth: 38
                    implicitHeight: 38
                    
                    property bool showSettings: false

                    IconToolbarButton {
                        id: folderButton
                        anchors.fill: parent
                        text: "folder_open"
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", RandomNetworkWallpaper.downloadDir])
                        }

                        StyledToolTip {
                            text: "Open folder (right-click for settings)"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: folderButtonContainer.showSettings = true
                    }

                    // Settings popup
                    Popup {
                        id: settingsPopup
                        visible: folderButtonContainer.showSettings
                        x: -settingsPopup.width + folderButton.width
                        y: -settingsPopup.height - 8
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        onClosed: {
                            // Save API key when closing (only if not empty)
                            if (apiKeyField.text.length > 0) {
                                if (!Config.options.wallpaper) Config.options.wallpaper = {}
                                Config.options.wallpaper.wallhavenApiKey = apiKeyField.text
                                RandomNetworkWallpaper.wallhavenApiKey = apiKeyField.text
                            }
                            folderButtonContainer.showSettings = false
                        }

                        background: Rectangle {
                            color: Appearance.colors.colLayer0
                            radius: Appearance.rounding.normal
                            border.width: 1
                            border.color: Appearance.colors.colLayer0Border

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                shadowEnabled: true
                                shadowColor: "#40000000"
                                shadowBlur: 0.5
                                shadowVerticalOffset: 4
                                shadowHorizontalOffset: 0
                            }
                        }

                        contentItem: ColumnLayout {
                            spacing: 12

                            // Header
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                MaterialSymbol {
                                    text: "settings"
                                    iconSize: 18
                                    color: Appearance.colors.colOnLayer0
                                }

                                StyledText {
                                    text: "Settings"
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.bold: true
                                }
                            }

                            // API Key field
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                StyledText {
                                    text: "Wallhaven API Key"
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colOnLayer1Inactive
                                }

                                MaterialTextField {
                                    id: apiKeyField
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 240
                                    placeholderText: "Enter API key (optional)"
                                    text: Config.options?.wallpaper?.wallhavenApiKey ?? ""
                                    echoMode: TextInput.Password
                                }
                            }

                            // NSFW toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                StyledText {
                                    text: "NSFW Content"
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer0
                                }

                                Item { Layout.fillWidth: true }

                                StyledSwitch {
                                    checked: RandomNetworkWallpaper.nsfwEnabled
                                    onCheckedChanged: {
                                        RandomNetworkWallpaper.nsfwEnabled = checked
                                    }
                                }
                            }

                            StyledText {
                                Layout.fillWidth: true
                                Layout.preferredWidth: 240
                                text: "Requires API key for Wallhaven NSFW"
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: Appearance.colors.colOnLayer1Inactive
                                wrapMode: Text.WordWrap
                            }
                        }

                        padding: 12
                    }
                }
            }
        }
    }
}
