/* Copyright (C) 2021 Wildfire Games.
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

/*
	A vertical GUI Scrollbar, this class doesn't present all functionality
	to the scrollbar, it just controls the drawing, handles some events,
	and provides a wrapper for interaction with itself. Actual tracking
	of how far we've scrolled inside the owner is handled elsewhere.
*/

#ifndef INCLUDED_CGUISCROLLBARVERTICAL
#define INCLUDED_CGUISCROLLBARVERTICAL

#include "IGUIScrollBar.h"

/**
 * Vertical implementation of IGUIScrollBar
 *
 * @see IGUIScrollBar
 */
class CGUIScrollBarVertical : public IGUIScrollBar
{
public:
	CGUIScrollBarVertical(CGUI& pGUI);
	virtual ~CGUIScrollBarVertical();

public:
	/**
	 * Draw the scrollbar
	 */
	virtual void Draw();

	/**
	 * Setup the scrollbar, setting the size, length and position.
	 *
	 * @see IGUIScrollBar#Setup()
	 */
	virtual void Setup();
	virtual void Setup(const CRect& content);

	/**
	 * @see IGUIObject#HandleMessage()
	 */
	virtual void HandleMessage(SGUIMessage& Message);

	/**
	 * Set m_Pos with g_mouse_x/y input, i.e. when dragging.
	 */
	virtual void SetPosFromMousePos(const CVector2D& mouse);

	/**
	 * @see IGUIScrollBar#HoveringButtonMinus
	 */
	virtual bool HoveringButtonMinus(const CVector2D& mouse);

	/**
	 * @see IGUIScrollBar#HoveringButtonPlus
	 */
	virtual bool HoveringButtonPlus(const CVector2D& mouse);

	/**
	 * Set Right Aligned
	 * @param align Alignment
	 */
	void SetRightAligned(const bool& align) { m_RightAligned = align; }

	/**
	 * Get the rectangle of the actual BAR.
	 * @return Rectangle, CRect
	 */
	virtual CRect GetBarRect() const;

	/**
	 * Get the rectangle of the outline of the scrollbar, every component of the
	 * scrollbar should be inside this area.
	 * @return Rectangle, CRect
	 */
	virtual CRect GetOuterRect() const;

protected:
	/**
	 * Should the scrollbar be drawn on the left or on the right of the m_X value.
	 * Notice, this has nothing to do with where the owner places it.
	 */
	bool m_RightAligned;
};

#endif // INCLUDED_CGUISCROLLBARVERTICAL
