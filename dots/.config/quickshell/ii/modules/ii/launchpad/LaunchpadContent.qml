pragma ComponentBehavior: Bound

import qs
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    signal launchApp()

    property string query: ""

    readonly property list<DesktopEntry> allApps: {
        const list = Array.from(DesktopEntries.applications.values)
            .filter((app, index, self) => index === self.findIndex((t) => t.id === app.id));
        return list.sort((a, b) => a.name.localeCompare(b.name));
    }

    readonly property list<DesktopEntry> filteredApps: {
        const q = root.query.trim().toLowerCase();
        if (q.length === 0) return root.allApps;
        return root.allApps.filter(app => {
            return app.name.toLowerCase().includes(q) || app.id.toLowerCase().includes(q);
        });
    }

    readonly property bool searching: root.query.trim().length > 0

    readonly property int columns: {
        const minCell = 104;
        return Math.max(4, Math.floor(gridArea.width / minCell));
    }

    readonly property int rows: {
        const minCell = 104;
        return Math.max(3, Math.floor(gridArea.height / minCell));
    }

    readonly property int pageSize: Math.max(1, columns * rows)
    readonly property int pageCount: root.searching ? 1 : Math.max(1, Math.ceil(filteredApps.length / pageSize))

    function appAt(page: int, indexInPage: int): DesktopEntry {
        const indexOverall = page * pageSize + indexInPage;
        return filteredApps[indexOverall];
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: 10

            MaterialSymbol {
                text: "apps"
                font.pixelSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnLayer0
                Layout.alignment: Qt.AlignVCenter
            }

            ToolbarTextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search apps")
                text: root.query
                onTextChanged: root.query = text

                Component.onCompleted: forceActiveFocus()
            }
        }

        Item {
            id: gridArea
            Layout.fillWidth: true
            Layout.fillHeight: true

                SwipeView {
                    id: pages
                    anchors.fill: parent
                    interactive: !root.searching
                    clip: true

                    onInteractiveChanged: pages.currentIndex = 0


                Repeater {
                    model: root.pageCount
                    delegate: Item {
                        required property int modelData
                        readonly property int pageIndex: modelData

                        GridView {
                            id: grid
                            anchors.fill: parent
                            clip: true

                            readonly property int cell: Math.floor(Math.min(width / root.columns, height / root.rows))
                            cellWidth: cell
                            cellHeight: cell

                            model: root.searching ? root.filteredApps : root.pageSize

                            delegate: LaunchpadAppButton {
                                required property var modelData

                                desktopEntry: {
                                    if (root.searching) {
                                        return modelData;
                                    }
                                    return root.appAt(pageIndex, modelData);
                                }

                                width: grid.cellWidth
                                height: grid.cellHeight

                                visible: desktopEntry !== undefined && desktopEntry !== null
                                onClicked: {
                                    if (!desktopEntry) return;
                                    desktopEntry.execute();
                                    root.launchApp();
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            visible: !root.searching && root.pageCount > 1

            Repeater {
                model: root.pageCount
                delegate: Rectangle {
                    required property int modelData
                    readonly property bool active: pages.currentIndex === modelData
                    width: active ? 12 : 8
                    height: 8
                    radius: 4
                    color: active ? Appearance.colors.colPrimary : Appearance.colors.colOutlineVariant

                    Behavior on width {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }
            }
        }
    }
}
