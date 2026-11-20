
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

    PlayerEffects {
        id: effects

        player: Player
    }

    readonly property color _well: theme.palette.isDark ? "#0a0a0a" : "#e2e2e2"

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
            anchors.bottomMargin: VLCStyle.dp(10, VLCStyle.scale)

            clip: true
            contentWidth: width
            contentHeight: pages.height
            boundsBehavior: Flickable.StopAtBounds

            T.ScrollBar.vertical: T.ScrollBar {
                id: scrollBar

                parent: flickable
                x: flickable.width - width - VLCStyle.dp(3, VLCStyle.scale)
                height: flickable.height
                width: VLCStyle.dp(4, VLCStyle.scale)
                policy: flickable.contentHeight > flickable.height ? T.ScrollBar.AlwaysOn
                                                                   : T.ScrollBar.AlwaysOff
                minimumSize: 0.1

                contentItem: Rectangle {
                    radius: width / 2
                    color: theme.fg.secondary
                    opacity: scrollBar.pressed || scrollBar.hovered ? 0.8 : 0.4
                }
            }

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

                Divider { visible: root.currentTab === 0 }

                GroupTitle {
                    visible: root.currentTab === 0
                    text: qsTr("Picture")
                }

                T.Label {
                    x: VLCStyle.dp(28, VLCStyle.scale)
                    width: pages.width - 2 * x
                    visible: root.currentTab === 0 && aspectChoice.count === 0
                    wrapMode: Text.WordWrap
                    text: qsTr("These settings appear while a video is playing.")
                    font.pixelSize: VLCStyle.dp(13, VLCStyle.scale)
                    color: theme.fg.secondary
                }

                ChoiceSection {
                    id: aspectChoice
                    visible: root.currentTab === 0 && count > 0
                    title: qsTr("Aspect Ratio")
                    choiceModel: Player.aspectRatio
                }

                ChoiceSection {
                    visible: root.currentTab === 0 && count > 0
                    title: qsTr("Crop")
                    choiceModel: Player.crop
                }

                ChoiceSection {
                    visible: root.currentTab === 0 && count > 0
                    title: qsTr("Zoom")
                    choiceModel: Player.zoom
                }

                ChoiceSection {
                    visible: root.currentTab === 0 && count > 0
                    title: qsTr("Fit")
                    choiceModel: Player.fit
                }

                ChoiceSection {
                    visible: root.currentTab === 0 && count > 0
                    title: qsTr("Deinterlace")
                    choiceModel: Player.deinterlace
                }

                ChoiceSection {
                    visible: root.currentTab === 0 && count > 0
                    title: qsTr("Deinterlace Mode")
                    choiceModel: Player.deinterlaceMode
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

                ChoiceSection {
                    visible: root.currentTab === 1 && count > 0
                    title: qsTr("Stereo Mode")
                    choiceModel: Player.audioStereoMode
                }

                Divider { visible: root.currentTab === 1 }

                GroupTitle {
                    visible: root.currentTab === 1
                    text: qsTr("Synchronization")
                }

                PanelSlider {
                    visible: root.currentTab === 1
                    title: qsTr("Audio Track Delay")
                    from: -10000
                    to: 10000
                    stepSize: 50
                    origin: 0
                    value: Player.audioDelayMS
                    valueText: qsTr("%1 s").arg((value / 1000).toFixed(3))
                    scaleLabels: [qsTr("-10 s"), qsTr("0 s"), qsTr("+10 s")]
                    onMoved: (v) => { Player.audioDelayMS = Math.round(v) }
                }

                Divider { visible: root.currentTab === 1 }

                EqualizerSection {
                    visible: root.currentTab === 1
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

                GroupTitle {
                    visible: root.currentTab === 2
                    text: qsTr("Synchronization")
                }

                PanelSlider {
                    visible: root.currentTab === 2
                    title: qsTr("Subtitle Track Delay")
                    from: -10000
                    to: 10000
                    stepSize: 50
                    origin: 0
                    value: Player.subtitleDelayMS
                    valueText: qsTr("%1 s").arg((value / 1000).toFixed(3))
                    scaleLabels: [qsTr("-10 s"), qsTr("0 s"), qsTr("+10 s")]
                    onMoved: (v) => { Player.subtitleDelayMS = Math.round(v) }
                }

                PanelSlider {
                    visible: root.currentTab === 2
                    title: qsTr("Subtitle Speed")
                    from: 0.5
                    to: 1.5
                    stepSize: 0.01
                    origin: 1
                    value: Player.subtitleFPS
                    valueText: qsTr("%1 x").arg(value.toFixed(2))
                    scaleLabels: [qsTr("0.5 x"), qsTr("1 x"), qsTr("1.5 x")]
                    onMoved: (v) => { Player.subtitleFPS = Math.round(v * 100) / 100 }
                }

                Divider { visible: root.currentTab === 2 }

                GroupTitle {
                    visible: root.currentTab === 2
                    text: qsTr("Appearance")
                }

                PanelSlider {
                    visible: root.currentTab === 2
                    title: qsTr("Subtitle Size")
                    from: 50
                    to: 300
                    stepSize: 5
                    origin: 100
                    value: effects.subtitleScale
                    valueText: qsTr("%1 %").arg(Math.round(value))
                    onMoved: (v) => { effects.subtitleScale = Math.round(v) }
                }

                PanelSlider {
                    visible: root.currentTab === 2
                    title: qsTr("Subtitle Height")
                    from: 0
                    to: 400
                    stepSize: 5
                    origin: 0
                    value: effects.subtitleMargin
                    valueText: qsTr("%1 px").arg(Math.round(value))
                    onMoved: (v) => { effects.subtitleMargin = Math.round(v) }
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

    // label, value box (click to reset) and a horizontal slider
    component PanelSlider: Column {
        id: control

        required property string title
        required property real value
        property real from: 0
        property real to: 100
        property real stepSize: 1
        // where the orange fill starts, and what a click on the value restores
        property real origin: from
        property string valueText: String(value)
        property var scaleLabels: []

        signal moved(real value)

        width: pages.width
        spacing: VLCStyle.dp(6, VLCStyle.scale)

        Item {
            width: parent.width
            height: VLCStyle.dp(36, VLCStyle.scale)

            SectionTitle {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
                anchors.right: valueBox.left
                anchors.verticalCenter: parent.verticalCenter
                text: control.title
            }

            T.AbstractButton {
                id: valueBox

                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(140, VLCStyle.scale)
                height: VLCStyle.dp(36, VLCStyle.scale)

                Accessible.name: qsTr("Reset %1").arg(control.title)

                onClicked: control.moved(control.origin)

                T.ToolTip.visible: hovered && control.value !== control.origin
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
                    text: control.valueText
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

            from: control.from
            to: control.to
            stepSize: control.stepSize
            snapMode: T.Slider.SnapAlways

            Accessible.name: control.title

            Binding on value {
                when: !slider.pressed
                value: Math.max(slider.from, Math.min(slider.to, control.value))
            }

            onMoved: control.moved(value)

            readonly property real _handleW: VLCStyle.dp(8, VLCStyle.scale)
            readonly property real _span: width - _handleW
            readonly property real _handleX: visualPosition * _span

            background: Rectangle {
                y: (slider.height - height) / 2
                width: slider.width
                height: VLCStyle.dp(14, VLCStyle.scale)
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: root._well

                Rectangle {
                    readonly property real zero: (control.origin - control.from) / (control.to - control.from)
                                                 * slider._span + slider._handleW / 2
                    readonly property real pos: slider._handleX + slider._handleW / 2
                    x: Math.min(zero, pos)
                    width: Math.abs(pos - zero)
                    height: parent.height
                    radius: parent.radius
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
            visible: control.scaleLabels.length === 3

            Repeater {
                model: control.scaleLabels

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

    // a label with the current choice; clicking it lists the choices
    component ChoiceSection: Column {
        id: choice

        required property string title
        required property var choiceModel
        property bool open: false
        property string currentText: ""
        readonly property alias count: choiceRepeater.count

        width: pages.width
        spacing: VLCStyle.dp(4, VLCStyle.scale)
        bottomPadding: VLCStyle.dp(8, VLCStyle.scale)

        Item {
            width: parent.width
            height: VLCStyle.dp(30, VLCStyle.scale)

            SectionTitle {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(28, VLCStyle.scale)
                anchors.bottom: parent.bottom
                text: choice.title
            }
        }

        RowButton {
            text: choice.currentText !== "" ? choice.currentText : qsTr("Default")
            chevron: choice.open ? VLCIcons.ic_fluent_chevron_up_24
                                 : VLCIcons.ic_fluent_chevron_down_24
            Accessible.name: choice.title
            onClicked: choice.open = !choice.open
        }

        Repeater {
            id: choiceRepeater

            model: choice.choiceModel

            T.AbstractButton {
                id: choiceRow

                required property var model
                required property int index

                readonly property bool isChecked: !!model.checked

                function syncCurrent() {
                    if (isChecked)
                        choice.currentText = model.display
                }

                onIsCheckedChanged: syncCurrent()
                Component.onCompleted: syncCurrent()

                visible: choice.open
                width: choice.width
                height: VLCStyle.dp(36, VLCStyle.scale)

                Accessible.name: model.display
                Accessible.checkable: true
                Accessible.checked: isChecked

                onClicked: {
                    model.checked = true
                    choice.open = false
                }

                background: Rectangle {
                    color: theme.fg.primary
                    opacity: choiceRow.hovered || choiceRow.visualFocus ? 0.06 : 0
                }

                contentItem: Item {
                    Widgets.IconLabel {
                        x: VLCStyle.dp(26, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        visible: choiceRow.isChecked
                        text: VLCIcons.check
                        font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                        color: theme.accent
                    }

                    T.Label {
                        x: VLCStyle.dp(62, VLCStyle.scale)
                        width: parent.width - x - VLCStyle.dp(20, VLCStyle.scale)
                        anchors.verticalCenter: parent.verticalCenter
                        text: choiceRow.model.display
                        elide: Text.ElideRight
                        font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                        color: theme.fg.primary
                    }
                }
            }
        }
    }

    component GroupTitle: Item {
        property alias text: groupLabel.text

        width: pages.width
        height: VLCStyle.dp(40, VLCStyle.scale)

        T.Label {
            id: groupLabel

            x: VLCStyle.dp(28, VLCStyle.scale)
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
            color: theme.fg.primary
        }
    }

    // full width row button: text on the left, chevron on the right
    component RowButton: T.AbstractButton {
        id: rowButton

        property string chevron: VLCIcons.ic_fluent_chevron_down_24

        x: VLCStyle.dp(20, VLCStyle.scale)
        width: pages.width - 2 * x
        height: VLCStyle.dp(44, VLCStyle.scale)

        background: Rectangle {
            color: root._well
            radius: VLCStyle.dp(4, VLCStyle.scale)
            border.width: VLCStyle.dp(1, VLCStyle.scale)
            border.color: rowButton.visualFocus ? theme.accent : theme.border
        }

        contentItem: Item {
            T.Label {
                anchors.left: parent.left
                anchors.leftMargin: VLCStyle.dp(16, VLCStyle.scale)
                anchors.right: chevronLabel.left
                anchors.verticalCenter: parent.verticalCenter
                text: rowButton.text
                elide: Text.ElideRight
                font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                color: rowButton.hovered ? theme.fg.primary : theme.fg.secondary
            }

            Widgets.IconLabel {
                id: chevronLabel

                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(12, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: rowButton.chevron
                font.pixelSize: VLCStyle.dp(20, VLCStyle.scale)
                color: theme.fg.secondary
            }
        }
    }

    component OnOffSwitch: T.AbstractButton {
        id: onOff

        width: VLCStyle.dp(64, VLCStyle.scale)
        height: VLCStyle.dp(30, VLCStyle.scale)

        checkable: false

        property bool on: false

        Accessible.checkable: true
        Accessible.checked: on

        background: Rectangle {
            color: root._well
            radius: VLCStyle.dp(4, VLCStyle.scale)
            border.width: VLCStyle.dp(1, VLCStyle.scale)
            border.color: onOff.visualFocus ? theme.accent : theme.border
        }

        contentItem: Item {
            Rectangle {
                x: onOff.on ? parent.width - width - VLCStyle.dp(3, VLCStyle.scale)
                            : VLCStyle.dp(3, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                width: VLCStyle.dp(26, VLCStyle.scale)
                height: parent.height - VLCStyle.dp(6, VLCStyle.scale)
                radius: VLCStyle.dp(3, VLCStyle.scale)
                color: onOff.on ? theme.accent : theme.fg.secondary
                opacity: onOff.on ? 1 : 0.5
            }

            T.Label {
                x: onOff.on ? VLCStyle.dp(8, VLCStyle.scale)
                            : parent.width - width - VLCStyle.dp(8, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: onOff.on ? qsTr("ON") : qsTr("OFF")
                font.pixelSize: VLCStyle.dp(11, VLCStyle.scale)
                color: theme.fg.secondary
            }
        }
    }

    component EqualizerSection: Column {
        id: equalizer

        property bool presetsOpen: false
        property bool bandsOpen: false

        width: pages.width
        spacing: VLCStyle.dp(8, VLCStyle.scale)

        Item {
            width: parent.width
            height: VLCStyle.dp(40, VLCStyle.scale)

            T.Label {
                x: VLCStyle.dp(28, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Equalizer")
                font.pixelSize: VLCStyle.dp(15, VLCStyle.scale)
                color: theme.fg.primary
            }

            OnOffSwitch {
                anchors.right: parent.right
                anchors.rightMargin: VLCStyle.dp(20, VLCStyle.scale)
                anchors.verticalCenter: parent.verticalCenter

                Accessible.name: qsTr("Equalizer")

                on: effects.equalizerEnabled
                onClicked: effects.equalizerEnabled = !effects.equalizerEnabled
            }
        }

        RowButton {
            text: effects.preset >= 0 ? effects.presetNames[effects.preset] : qsTr("Custom")
            chevron: equalizer.presetsOpen ? VLCIcons.ic_fluent_chevron_up_24
                                           : VLCIcons.ic_fluent_chevron_down_24
            Accessible.name: qsTr("Equalizer preset")
            onClicked: equalizer.presetsOpen = !equalizer.presetsOpen
        }

        Column {
            width: parent.width
            visible: equalizer.presetsOpen

            Repeater {
                model: equalizer.presetsOpen ? effects.presetNames : []

                T.AbstractButton {
                    id: presetRow

                    required property int index
                    required property string modelData

                    width: equalizer.width
                    height: VLCStyle.dp(36, VLCStyle.scale)

                    Accessible.name: modelData

                    onClicked: {
                        effects.preset = index
                        effects.equalizerEnabled = true
                        equalizer.presetsOpen = false
                    }

                    background: Rectangle {
                        color: theme.fg.primary
                        opacity: presetRow.hovered || presetRow.visualFocus ? 0.06 : 0
                    }

                    contentItem: Item {
                        Widgets.IconLabel {
                            x: VLCStyle.dp(26, VLCStyle.scale)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: effects.preset === presetRow.index
                            text: VLCIcons.check
                            font.pixelSize: VLCStyle.dp(18, VLCStyle.scale)
                            color: theme.accent
                        }

                        T.Label {
                            x: VLCStyle.dp(62, VLCStyle.scale)
                            anchors.verticalCenter: parent.verticalCenter
                            text: presetRow.modelData
                            font.pixelSize: VLCStyle.dp(14, VLCStyle.scale)
                            color: theme.fg.primary
                        }
                    }
                }
            }
        }

        RowButton {
            text: equalizer.bandsOpen ? qsTr("Collapse Settings") : qsTr("Expand Settings")
            chevron: equalizer.bandsOpen ? VLCIcons.ic_fluent_chevron_down_24
                                         : VLCIcons.ic_fluent_chevron_right_24
            onClicked: equalizer.bandsOpen = !equalizer.bandsOpen
        }

        Column {
            width: parent.width
            visible: equalizer.bandsOpen
            spacing: VLCStyle.dp(2, VLCStyle.scale)

            PanelSlider {
                title: qsTr("Preamp")
                from: -20
                to: 20
                stepSize: 0.5
                origin: 12
                value: effects.preamp
                valueText: qsTr("%1 dB").arg((Math.round(value * 10) / 10 || 0).toFixed(1))
                onMoved: (v) => {
                    effects.preamp = v
                    effects.equalizerEnabled = true
                }
            }

            Repeater {
                model: equalizer.bandsOpen ? effects.bandNames : []

                PanelSlider {
                    required property int index
                    required property string modelData

                    title: modelData
                    from: -20
                    to: 20
                    stepSize: 0.5
                    origin: 0
                    value: effects.bands[index]
                    valueText: qsTr("%1 dB").arg((Math.round(value * 10) / 10 || 0).toFixed(1))
                    onMoved: (v) => {
                        effects.setBand(index, v)
                        effects.equalizerEnabled = true
                    }
                }
            }
        }
    }
}
