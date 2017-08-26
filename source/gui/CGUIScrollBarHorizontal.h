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
	A horizontal GUI Scrollbar, this class doesn't present all functionality
	to the scrollbar, it just controls the drawing, handles some events,
	and provides a wrapper for interaction with itself. Actual tracking
	of how far we've scrolled inside the owner is handled elsewhere.
*/

#ifndef INCLUDED_CGUISCROLLBARHORIZONTAL
#define INCLUDED_CGUISCROLLBARHORIZONTAL

#include "IGUIScrollBar.h"

/**
 * Horizontal implementation of IGUIScrollBar
 *
 * @see IGUIScrollBar
 */
class CGUIScrollBarHorizontal : public IGUIScrollBar
{
public:
	CGUIScrollBarHorizontal(CGUI& pGUI);
	virtual ~CGUIScrollBarHorizontal();

public:
	/**
	 * Draw the scroll-bar
	 */
	virtual void Draw();

	/**
	 * Setup the scrollbar. Sets the size, length and position.
	 * An object owning scrollbars still has to call this (preferably
	 * in the object's own Setup function), it isn't called
	 * automatically. There are two variations covering several common
	 * uses.
	 *
	 * The first assumes that the content is inside the host and thus
	 * uses the host's dimensions.
	 *
	 * The second permits a CRect defining the dimensions of the
	 * scrollable content to be passed. Any object that uses this still
	 * has to set a scroll range.
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
	 * Set Bottom Aligned
	 * @param align Alignment
	 */
	void SetBottomAligned(const bool &align) { m_BottomAligned = align; }

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
	 * Should the scrollbar appear above or below the m_Y value.
	 * Notice, this has nothing to do with where the owner places it.
	 */
	bool m_BottomAligned;
};

#endif // INCLUDED_CGUISCROLLBARHORIZONTAL
