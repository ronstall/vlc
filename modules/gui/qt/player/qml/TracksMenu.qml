
/*****************************************************************************
 * Copyright (C) 2020 VLC authors and VideoLAN
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * ( at your option ) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/
import QtQuick
import QtQuick.Templates as T

import VLC.MainInterface
import VLC.Style
import VLC.Player
import VLC.Widgets as Widgets
import VLC.Util
import VLC.Dialogs

// Tracks sidebar of the redesign: one panel with Video / Audio / Subtitles
// tabs, track lists with a check mark and the synchronisation sliders.
T.Popup {
    id: root

    // 0: video, 1: audio, 2: subtitles
    property int currentTab: 2

    width: Math.min(VLCStyle.dp(400, VLCStyle.scale), parent ? parent.width : 400)
    height: Math.min(VLCStyle.dp(524, VLCStyle.scale), _maxHeight)

    property real _maxHeight: 524

    padding: 0

    readonly property ColorContext colorContext: ColorContext {
        id: theme
        colorSet: ColorContext.Window
    }

    readonly property color _well: theme.palette.isDark ? "#0a0a0a" : theme.bg.secondary

    background: Rectangle {
        color: theme.bg.primary
        radius: VLCStyle.dp(8, VLCStyle.scale)
        border.width: VLCStyle.dp(1, VLCStyle.scale)
        border.color: theme.border
    }

    contentItem: Item {
        clip: true

        // tab bar
        Rectangle {
            id: tabBar

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: VLCStyle.dp(1, VLCStyle.scale)
            y: VLCStyle.dp(1, VLCStyle.scale)
            height: VLCStyle.dp(48, VLCStyle.scale)

            color: root._well
            radius: VLCStyle.dp(8, VLCStyle.scale)

            Row {
                anchors.fill: parent
                anchors.leftMargin: VLCStyle.dp(14, VLCStyle.scale)
                anchors.rightMargin: VLCStyle.dp(14, VLCStyle.scale)

                Repeater {
                    model: [
                        { icon: VLCIcons.topbar_video, text: qsTr("Video") },
                        { icon: VLCIcons.volume_high, text: qsTr("Audio") },
                        { icon: VLCIcons.audiosub, text: qsTr("Subtitles") }
                    ]

                    T.AbstractButton {
                        id: tab

                        required property int index
                        required property var modelData

                        readonly property bool selected: root.currentTab === index

                        width: parent.width / 3
                        height: parent.height

                        Accessible.name: modelData.text

                        onClicked: root.currentTab = index

                        contentItem: Item {
                            Row {
                                anchors.centerIn: parent
                                spacing: VLCStyle.dp(10, VLCStyle.scale)

                                Widgets.IconLabel {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tab.modelData.icon
                                    font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                                    color: tab.selected ? theme.accent : theme.fg.secondary
                                    opacity: tab.selected || tab.hovered ? 1 : 0.7
                                }

                                T.Label {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tab.modelData.text
                                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                                    color: tab.selected ? theme.fg.primary : theme.fg.secondary
                                    opacity: tab.selected || tab.hovered ? 1 : 0.7
                                }
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: VLCStyle.dp(2, VLCStyle.scale)
                                visible: tab.selected
                                color: theme.accent
                            }
                        }
                    }
                }
            }
        }

        Flickable {
            id: flickable

            anchors.top: tabBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: footer.top

            clip: true
            contentWidth: width
            contentHeight: pages.height
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: Widgets.ScrollBarExt { }

            Column {
                id: pages

                width: flickable.width
                bottomPadding: VLCStyle.dp(12, VLCStyle.scale)

                // Video
                TrackSection {
                    visible: root.currentTab === 0
                    title: qsTr("Video Tracks")
                    tracksModel: Player.videoTracks
                    actionIcon: VLCIcons.add
                    actionText: qsTr("Add a video file")
                    onAction: DialogsProvider.loadVideoFile()
                }

                // Audio
                TrackSection {
                    visible: root.currentTab === 1
                    title: qsTr("Audio Tracks")
                    tracksModel: Player.audioTracks
                    actionIcon: VLCIcons.add
                    actionText: qsTr("Add an audio file")
                    onAction: DialogsProvider.loadAudioFile()
                }

                Divider { visible: deviceSection.visible }

                TrackSection {
                    id: deviceSection

                    visible: root.currentTab === 1 && count > 0
                    title: qsTr("Output Device")
                    allowNone: false
                    tracksModel: Player.audioDevices
                }

                Divider { visible: root.currentTab === 1 }

                DelaySection {
                    visible: root.currentTab === 1
                    title: qsTr("Audio Track Delay")
                    delayMS: Player.audioDelayMS
                    onMoved: (ms) => { Player.audioDelayMS = ms }
                }

                // Subtitles
                TrackSection {
                    visible: root.currentTab === 2
                    title: qsTr("Subtitle Tracks")
                    tracksModel: Player.subtitleTracks
                    actionIcon: VLCIcons.add
                    actionText: qsTr("Add a subtitle file")
                    onAction: DialogsProvider.loadSubtitlesFile()
                }

                Divider { visible: root.currentTab === 2 }

                DelaySection {
                    visible: root.currentTab === 2
                    title: qsTr("Subtitle Track Delay")
                    delayMS: Player.subtitleDelayMS
                    onMoved: (ms) => { Player.subtitleDelayMS = ms }
                }
            }
        }

        T.AbstractButton {
            id: footer

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: VLCStyle.dp(20, VLCStyle.scale)
            anchors.bottomMargin: VLCStyle.dp(16, VLCStyle.scale)
            height: VLCStyle.dp(36, VLCStyle.scale)

            text: qsTr("Show Preferences")

            onClicked: {
                root.close()
                DialogsProvider.prefsDialog()
            }

            background: Rectangle {
                color: root._well
                radius: VLCStyle.dp(4, VLCStyle.scale)
                border.width: footer.visualFocus ? VLCStyle.dp(1, VLCStyle.scale) : 0
                border.color: theme.accent
            }

            contentItem: T.Label {
                text: footer.text
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                color: footer.hovered ? theme.fg.primary : theme.fg.secondary
            }
        }
    }

    component Divider: Item {
        width: pages.width
        height: VLCStyle.dp(13, VLCStyle.scale)

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: VLCStyle.dp(1, VLCStyle.scale)
            color: theme.border
        }
    }

    component SectionTitle: T.Label {
        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
        color: theme.fg.secondary
        elide: Text.ElideRight
    }

    component TrackSection: Column {
        id: section

        required property string title
        required property var tracksModel
        property string actionIcon: ""
        property string actionText: ""
        // clicking the selected row turns it off (tracks, not devices)
        property bool allowNone: true
        readonly property alias count: trackRepeater.count

        signal action()

        width: pages.width

        Item {
            width: parent.width
            height: VLCStyle.dp(56, VLCStyle.scale)

            SectionTitle {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
                anchors.right: actionButton.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: VLCStyle.dp(4, VLCStyle.scale)
                text: section.title
            }

            T.AbstractButton {
                id: actionButton

                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: VLCStyle.dp(4, VLCStyle.scale)

                width: VLCStyle.dp(32, VLCStyle.scale)
                height: width

                visible: section.actionIcon !== ""

                Accessible.name: section.actionText

                T.ToolTip.visible: hovered
                T.ToolTip.text: section.actionText
                T.ToolTip.delay: VLCStyle.delayToolTipAppear

                onClicked: section.action()

                background: Rectangle {
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    color: theme.fg.primary
                    opacity: actionButton.hovered || actionButton.visualFocus ? 0.08 : 0
                }

                contentItem: Widgets.IconLabel {
                    text: section.actionIcon
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                    color: actionButton.hovered ? theme.fg.primary : theme.fg.secondary
                }
            }
        }

        Repeater {
            id: trackRepeater

            model: section.tracksModel

            T.AbstractButton {
                id: trackRow

                required property var model

                width: section.width
                height: VLCStyle.dp(44, VLCStyle.scale)

                Accessible.name: trackRow.model.display
                Accessible.checkable: true
                Accessible.checked: trackRow.model.checked

                onClicked: {
                    if (!trackRow.model.checked)
                        trackRow.model.checked = true
                    else if (section.allowNone)
                        trackRow.model.checked = false
                }

                background: Rectangle {
                    color: theme.fg.primary
                    opacity: trackRow.hovered || trackRow.visualFocus ? 0.06 : 0
                }

                contentItem: Item {
                    Widgets.IconLabel {
                        x: VLCStyle.dp(26, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: trackRow.model.checked
                        text: VLCIcons.check
                        font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                        color: theme.accent
                    }

                    T.Label {
                        anchors.left: parent.left
                        anchors.leftMargin: VLCStyle.dp(62, VLCStyle.scale)
                        anchors.right: parent.right
                        anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        text: trackRow.model.display
                        elide: Text.ElideMiddle
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        color: theme.fg.primary
                        opacity: trackRow.model.checked || trackRow.hovered ? 1 : 0.8
                    }
                }
            }
        }
    }

    component DelaySection: Column {
        id: delay

        required property string title
        required property int delayMS

        signal moved(int ms)

        width: pages.width
        topPadding: VLCStyle.dp(8, VLCStyle.scale)
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        SectionTitle {
            x: VLCStyle.dp(28, VLCStyle.scale)
            text: qsTr("Synchronization")
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            color: theme.fg.primary
        }

        Item {
            width: parent.width
            height: VLCStyle.dp(36, VLCStyle.scale)

            SectionTitle {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: delay.title
            }

            // value box, click to reset
            T.AbstractButton {
                id: valueBox

                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(140, VLCStyle.scale)
                height: VLCStyle.dp(36, VLCStyle.scale)

                Accessible.name: qsTr("Reset the delay")

                onClicked: delay.moved(0)

                T.ToolTip.visible: hovered && delay.delayMS !== 0
                T.ToolTip.text: qsTr("Click to reset")
                T.ToolTip.delay: VLCStyle.delayToolTipAppear

                background: Rectangle {
                    color: root._well
                    radius: VLCStyle.dp(4, VLCStyle.scale)
                    border.width: VLCStyle.dp(1, VLCStyle.scale)
                    border.color: theme.border
                }

                contentItem: T.Label {
                    leftPadding: VLCStyle.dp(14, VLCStyle.scale)
                    verticalAlignment: Text.AlignVCenter
                    text: qsTr("%1 s").arg((delay.delayMS / 1000).toFixed(3))
                    font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                    color: theme.fg.primary
                }
            }
        }

        T.Slider {
            id: slider

            x: VLCStyle.dp(20, VLCStyle.scale)
            width: parent.width - 2 * x
            height: VLCStyle.dp(24, VLCStyle.scale)

            from: -10000
            to: 10000
            stepSize: 50
            snapMode: T.Slider.SnapAlways

            Accessible.name: delay.title

            Binding on value {
                when: !slider.pressed
                value: Math.max(slider.from, Math.min(slider.to, delay.delayMS))
            }

            onMoved: delay.moved(Math.round(value))

            readonly property real _handleW: VLCStyle.dp(8, VLCStyle.scale)
            readonly property real _handleX: visualPosition * (width - _handleW)

            background: Rectangle {
                y: (slider.height - height) / 2
                width: slider.width
                height: VLCStyle.dp(14, VLCStyle.scale)
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: root._well

                // fill between the zero point and the handle
                Rectangle {
                    readonly property real zero: (slider.width - slider._handleW) / 2 + slider._handleW / 2
                    readonly property real pos: slider._handleX + slider._handleW / 2
                    x: Math.min(zero, pos)
                    width: Math.abs(pos - zero)
                    height: parent.height
                    color: theme.accent
                    opacity: 0.45
                }
            }

            handle: Rectangle {
                x: slider._handleX
                y: (slider.height - height) / 2
                width: slider._handleW
                height: VLCStyle.dp(22, VLCStyle.scale)
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: theme.accent
            }
        }

        Item {
            x: VLCStyle.dp(20, VLCStyle.scale)
            width: parent.width - 2 * x
            height: VLCStyle.dp(16, VLCStyle.scale)

            Repeater {
                model: [qsTr("-10 s"), qsTr("0 s"), qsTr("+10 s")]

                T.Label {
                    required property int index
                    required property string modelData

                    x: index === 0 ? 0 : index === 1 ? (parent.width - width) / 2 : parent.width - width
                    text: modelData
                    font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
                    color: theme.fg.secondary
                }
            }
        }
    }
}
