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

#ifndef INCLUDED_NUMBERFMT
#define INCLUDED_NUMBERFMT

#include "lib/external_libraries/icu.h"
#include "ps/CStr.h"

class NumberFmt
{

public:
	NumberFmt();
	~NumberFmt();

	/**
	 * Returns true if NumberFormat is successfully setup, false if not.
	 */
	bool Setup();

	const CStrW Format(const double number) const;
	const CStrW Format(const CStr number) const;

	int m_MaxDecimalPlaces;
	int m_MinDecimalPlaces;

	/**
	 * If true, then the number will be automatically abbreviated.
	 * ie. 12000 => 12K
	 */
	bool m_AutoAbbreviate;

	bool m_IsPercentage;

private:

	/**
	 * Pointer to ICU's number format instance.
	 */
	icu::DecimalFormat* m_IcuNumberInstance;
};

#endif // INCLUDED_NUMBERFMT
