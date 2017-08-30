/* Copyright (C) 2017 Wildfire Games.
 * This file is part of 0 A.D.
 *
 * 0 A.D. is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * 0 A.D. is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with 0 A.D.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "Number.h"

#include "i18n/L10n.h"
#include "ps/CLogger.h"

NumberFmt::NumberFmt() : m_MaxDecimalPlaces(4), m_MinDecimalPlaces(0),
						 m_AutoAbbreviate(false), m_IsPercentage(false)
{
}

NumberFmt::~NumberFmt()
{
	delete m_IcuNumberInstance;
}

bool NumberFmt::Setup()
{
	const icu::Locale loc = g_L10n.GetCurrentLocale();
	UErrorCode IcuStatus = U_ZERO_ERROR;
	UNumberFormatStyle FormatStyle = m_IsPercentage ? UNUM_PERCENT : UNUM_DEFAULT;

	if (m_AutoAbbreviate)
		m_IcuNumberInstance = icu::CompactDecimalFormat::createInstance(loc, UNUM_SHORT, IcuStatus);
	else
		// Might seem odd to create as a `NumberFormat` and then type-cast to `DecimalFormat`.
		// However, this is *recommended* by the ICU documentation.
		m_IcuNumberInstance = (icu::DecimalFormat*) icu::NumberFormat::createInstance(loc, FormatStyle, IcuStatus);

	if (U_FAILURE(IcuStatus))
	{
		// Error code descriptions can be found at http://icu-project.org/apiref/icu4c/utypes_8h_source.html line 396
		LOGERROR("Error creating number format. ICU error code: %i.", IcuStatus);
		return false;
	}

	// By default, ICU automatically multiplies any number input to be formatted
	// as a percentage by 100 (so 0.5 => "50%", and 50 => "500%"). We never want
	// to do that, so we override.
	m_IcuNumberInstance->setMultiplier(0);

	// Effectively discard everything after the prescribed cut-off point.
	// (Means rounding can be dealt with on the JS side with no surprises.)
	m_IcuNumberInstance->setRoundingMode(icu::DecimalFormat::kRoundDown);

	m_MinDecimalPlaces = std::min(m_MinDecimalPlaces, m_MaxDecimalPlaces);
	m_IcuNumberInstance->setMaximumFractionDigits(m_MaxDecimalPlaces);
	m_IcuNumberInstance->setMinimumFractionDigits(m_MinDecimalPlaces);
	return true;
}

/**
 * @todo validate prefix and suffix
 * @todo remove conversion from utf16 -> utf8 -> utf16 (or whatever CStrW is)
 */
const CStrW NumberFmt::Format(const double number) const
{
	icu::UnicodeString formatted;
	CStr output;

	m_IcuNumberInstance->format(number, formatted);
	formatted.toUTF8String(output);

	return output.FromUTF8();
}

/**
 * @todo validate prefix and suffix
 * @todo remove conversion from utf16 -> utf8 -> utf16 (or whatever CStrW is)
 */
const CStrW NumberFmt::Format(const CStr number) const
{
	return Format(number.ToFloat());
}
