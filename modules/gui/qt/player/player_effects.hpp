/*****************************************************************************
 * Copyright (C) 2023 VLC authors and VideoLAN
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

#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>
#include "qt.hpp"

#include "player_controller.hpp"

/**
 * Live audio equalizer and subtitle appearance settings for the tracks
 * sidebar. Values apply to the running playback and are not written to the
 * configuration.
 */
class PlayerEffects : public QObject
{
    Q_OBJECT
    Q_PROPERTY(PlayerController* player READ getPlayer WRITE setPlayer NOTIFY playerChanged FINAL)

    Q_PROPERTY(bool equalizerEnabled READ isEqualizerEnabled WRITE setEqualizerEnabled NOTIFY equalizerChanged FINAL)
    // index in presetNames, -1 when the bands were changed by hand
    Q_PROPERTY(int preset READ getPreset WRITE setPreset NOTIFY equalizerChanged FINAL)
    Q_PROPERTY(QStringList presetNames READ getPresetNames CONSTANT FINAL)
    Q_PROPERTY(QStringList bandNames READ getBandNames CONSTANT FINAL)
    Q_PROPERTY(QVariantList bands READ getBands NOTIFY equalizerChanged FINAL)
    Q_PROPERTY(qreal preamp READ getPreamp WRITE setPreamp NOTIFY equalizerChanged FINAL)

    // percentage, 100 is the normal size
    Q_PROPERTY(int subtitleScale READ getSubtitleScale WRITE setSubtitleScale NOTIFY subtitleChanged FINAL)
    // pixels above the bottom of the video
    Q_PROPERTY(int subtitleMargin READ getSubtitleMargin WRITE setSubtitleMargin NOTIFY subtitleChanged FINAL)

public:
    explicit PlayerEffects(QObject* parent = nullptr);

    PlayerController* getPlayer() const { return m_player; }
    void setPlayer(PlayerController* player);

    bool isEqualizerEnabled() const { return m_enabled; }
    void setEqualizerEnabled(bool enabled);

    int getPreset() const { return m_preset; }
    void setPreset(int preset);

    QStringList getPresetNames() const;
    QStringList getBandNames() const;
    QVariantList getBands() const;

    qreal getPreamp() const { return m_preamp; }
    void setPreamp(qreal preamp);

    Q_INVOKABLE void setBand(int index, qreal value);

    int getSubtitleScale() const { return m_subtitleScale; }
    void setSubtitleScale(int scale);

    int getSubtitleMargin() const { return m_subtitleMargin; }
    void setSubtitleMargin(int margin);

signals:
    void playerChanged();
    void equalizerChanged();
    void subtitleChanged();

private:
    void load();
    void applyEqualizer();

    PlayerController* m_player = nullptr;
    bool m_enabled = false;
    bool m_vlcFreqs = true;
    int m_preset = -1;
    qreal m_preamp = 12.;
    qreal m_bands[10] = {};
    int m_subtitleScale = 100;
    int m_subtitleMargin = 0;
};
