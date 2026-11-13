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

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include "player_effects.hpp"

#include <QLocale>

#include <vlc_aout.h>
#include <vlc_player.h>
#include <vlc_vout.h>

#include "../../../audio_filter/equalizer_presets.h"

namespace
{

constexpr int BAND_COUNT = EQZ_BANDS_MAX;

bool parseBands(const char* psz_bands, qreal* bands)
{
    if (!psz_bands || !*psz_bands)
        return false;
    const QStringList list = QString::fromUtf8(psz_bands).split(' ', Qt::SkipEmptyParts);
    if (list.count() < BAND_COUNT)
        return false;
    for (int i = 0; i < BAND_COUNT; i++)
        bands[i] = QLocale::c().toFloat(list[i]);
    return true;
}

}

PlayerEffects::PlayerEffects(QObject* parent)
    : QObject(parent)
{
}

void PlayerEffects::setPlayer(PlayerController* player)
{
    if (m_player == player)
        return;
    m_player = player;
    emit playerChanged();
    if (m_player)
        load();
}

void PlayerEffects::load()
{
    vlc_player_t* player = m_player->getPlayer();

    {
        vlc_player_locker lock{ player };
        m_subtitleScale = vlc_player_GetSubtitleTextScale(player);
    }

    SharedVOutThread vout = m_player->getVout();
    if (vout)
        m_subtitleMargin = var_GetInteger(vout.get(), "sub-margin");

    emit subtitleChanged();

    SharedAOut aout = m_player->getAout();
    if (!aout)
    {
        // nothing to read from yet: start from the flat preset
        m_preset = 0;
        m_preamp = eqz_preset_10b[0].f_preamp;
        emit equalizerChanged();
        return;
    }
    vlc_object_t* obj = VLC_OBJECT(aout.get());

    m_vlcFreqs = var_InheritBool(obj, "equalizer-vlcfreqs");

    char* psz_filters = var_GetNonEmptyString(aout.get(), "audio-filter");
    m_enabled = psz_filters
        && QString::fromUtf8(psz_filters).split(':').contains(QStringLiteral("equalizer"));
    free(psz_filters);

    m_preamp = var_InheritFloat(obj, "equalizer-preamp");

    char* psz_preset = var_InheritString(obj, "equalizer-preset");
    m_preset = -1;
    if (psz_preset)
    {
        for (int i = 0; i < NB_PRESETS; i++)
            if (!strcasecmp(preset_list[i], psz_preset))
                m_preset = i;
        free(psz_preset);
    }

    char* psz_bands = var_InheritString(obj, "equalizer-bands");
    if (parseBands(psz_bands, m_bands))
    {
        // hand made bands win over the preset, see the equalizer filter
        if (m_preset >= 0)
            for (int i = 0; i < BAND_COUNT; i++)
                if (qAbs(m_bands[i] - eqz_preset_10b[m_preset].f_amp[i]) > 0.05)
                {
                    m_preset = -1;
                    break;
                }
    }
    else
    {
        if (m_preset < 0)
            m_preset = 0;
        for (int i = 0; i < BAND_COUNT; i++)
            m_bands[i] = eqz_preset_10b[m_preset].f_amp[i];
        m_preamp = eqz_preset_10b[m_preset].f_preamp;
    }
    free(psz_bands);

    emit equalizerChanged();
}

void PlayerEffects::applyEqualizer()
{
    if (!m_player)
        return;
    SharedAOut aout = m_player->getAout();
    if (!aout)
        return;

    QStringList bands;
    for (int i = 0; i < BAND_COUNT; i++)
        bands << QLocale::c().toString(m_bands[i], 'f', 1);

    // the filter creates these when it starts; creating them first lets it
    // start with our values
    var_Create(aout.get(), "equalizer-bands", VLC_VAR_STRING | VLC_VAR_DOINHERIT);
    var_Create(aout.get(), "equalizer-preamp", VLC_VAR_FLOAT | VLC_VAR_DOINHERIT);
    var_SetString(aout.get(), "equalizer-bands", qtu(bands.join(' ')));
    var_SetFloat(aout.get(), "equalizer-preamp", m_preamp);
}

void PlayerEffects::setEqualizerEnabled(bool enabled)
{
    if (m_enabled == enabled || !m_player)
        return;
    if (enabled)
        applyEqualizer();
    if (vlc_player_aout_EnableFilter(m_player->getPlayer(), "equalizer", enabled) != 0)
        return;
    m_enabled = enabled;
    emit equalizerChanged();
}

void PlayerEffects::setPreset(int preset)
{
    if (preset < 0 || preset >= NB_PRESETS)
        return;
    m_preset = preset;
    for (int i = 0; i < BAND_COUNT; i++)
        m_bands[i] = eqz_preset_10b[preset].f_amp[i];
    m_preamp = eqz_preset_10b[preset].f_preamp;
    applyEqualizer();
    emit equalizerChanged();
}

QStringList PlayerEffects::getPresetNames() const
{
    QStringList names;
    for (int i = 0; i < NB_PRESETS; i++)
        names << qfut(preset_list_text[i]);
    return names;
}

QStringList PlayerEffects::getBandNames() const
{
    const float* table = m_vlcFreqs ? f_vlc_frequency_table_10b
                                    : f_iso_frequency_table_10b;
    QStringList names;
    for (int i = 0; i < BAND_COUNT; i++)
    {
        if (table[i] >= 1000)
            names << qtr("%1 kHz").arg(table[i] / 1000.);
        else
            names << qtr("%1 Hz").arg(qRound(table[i]));
    }
    return names;
}

QVariantList PlayerEffects::getBands() const
{
    QVariantList bands;
    for (int i = 0; i < BAND_COUNT; i++)
        bands << m_bands[i];
    return bands;
}

void PlayerEffects::setPreamp(qreal preamp)
{
    preamp = qBound(-20., preamp, 20.);
    if (qFuzzyCompare(m_preamp, preamp))
        return;
    m_preamp = preamp;
    applyEqualizer();
    emit equalizerChanged();
}

void PlayerEffects::setBand(int index, qreal value)
{
    if (index < 0 || index >= BAND_COUNT)
        return;
    value = qBound(-20., value, 20.);
    if (qFuzzyCompare(m_bands[index], value))
        return;
    m_bands[index] = value;
    m_preset = -1;
    applyEqualizer();
    emit equalizerChanged();
}

void PlayerEffects::setSubtitleScale(int scale)
{
    scale = qBound(10, scale, 500);
    if (m_subtitleScale == scale || !m_player)
        return;
    vlc_player_t* player = m_player->getPlayer();
    {
        vlc_player_locker lock{ player };
        vlc_player_SetSubtitleTextScale(player, scale);
    }
    m_subtitleScale = scale;
    emit subtitleChanged();
}

void PlayerEffects::setSubtitleMargin(int margin)
{
    margin = qMax(0, margin);
    if (m_subtitleMargin == margin || !m_player)
        return;
    const PlayerController::VOutThreadList vouts = m_player->getVouts();
    for (const SharedVOutThread& vout : vouts)
        var_SetInteger(vout.get(), "sub-margin", margin);
    m_subtitleMargin = margin;
    emit subtitleChanged();
}
