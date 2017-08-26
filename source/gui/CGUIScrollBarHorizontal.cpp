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

#include "precompiled.h"

#include "CGUIScrollBarHorizontal.h"

#include "gui/CGUI.h"
#include "ps/CLogger.h"

CGUIScrollBarHorizontal::CGUIScrollBarHorizontal(CGUI& pGUI)
 : IGUIScrollBar(pGUI)
{
}

CGUIScrollBarHorizontal::~CGUIScrollBarHorizontal()
{
}

void CGUIScrollBarHorizontal::Setup()
{
	CRect host = GetHostGUIObject().GetCachedSize();
	CRect content = GetHostGUIObject().GetContentSize();

	SetScrollRange(content.GetWidth());
	Setup(host);

	// If the content height is taller than the host, assume there
	// is also a vertical scrollbar and make room for it.
	if (content.GetHeight() > host.GetHeight())
		SetLength(host.right - host.left - GetStyle()->m_Breadth);
}

void CGUIScrollBarHorizontal::Setup(const CRect& content)
{
	SetScrollSpace(content.GetHeight());

	SetX(content.left);
	SetY(m_BottomAligned ? content.bottom : content.top);
	SetZ(GetHostGUIObject().GetBufferedZ());

	SetLength(content.right - content.left);
}

void CGUIScrollBarHorizontal::SetPosFromMousePos(const CVector2D& mouse)
{
	if (!GetStyle())
		return;

	/**
	 * Calculate the position for the top of the item being scrolled
	 */
	float emptyBackground = m_Breadth - m_BarSize;

	if (GetStyle()->m_UseEdgeButtons)
		emptyBackground -= GetStyle()->m_Breadth * 2;

	m_Pos = m_PosWhenPressed + GetMaxPos() * (mouse.X - m_BarPressedAtPos.X) / emptyBackground;
}

void CGUIScrollBarHorizontal::Draw()
{
	if (!GetStyle())
	{
		LOGWARNING("Attempt to draw scrollbar without a style.");
		return;
	}

	if (IsNeeded())
	{
		CRect outline = GetOuterRect();

		m_pGUI.DrawSprite(
			GetStyle()->m_SpriteBackHorizontal,
			m_Z + 0.1f,
			CRect(
				outline.left + (GetStyle()->m_UseEdgeButtons ? GetStyle()->m_Breadth : 0),
				outline.top,
				outline.right - (GetStyle()->m_UseEdgeButtons ? GetStyle()->m_Breadth : 0),
				outline.bottom
			)
		);

		if (GetStyle()->m_UseEdgeButtons)
		{
			const CGUISpriteInstance* button_left;
			const CGUISpriteInstance* button_right;

			if (m_ButtonMinusHovered)
			{
				if (m_ButtonMinusPressed)
					button_left = &(GetStyle()->m_SpriteButtonLeftPressed ? GetStyle()->m_SpriteButtonLeftPressed : GetStyle()->m_SpriteButtonLeft);
				else
					button_left = &(GetStyle()->m_SpriteButtonLeftOver ? GetStyle()->m_SpriteButtonLeftOver : GetStyle()->m_SpriteButtonLeft);
			}
			else
				button_left = &GetStyle()->m_SpriteButtonLeft;

			if (m_ButtonPlusHovered)
			{
				if (m_ButtonPlusPressed)
					button_right = &(GetStyle()->m_SpriteButtonRightPressed ? GetStyle()->m_SpriteButtonRightPressed : GetStyle()->m_SpriteButtonRight);
				else
					button_right = &(GetStyle()->m_SpriteButtonRightOver ? GetStyle()->m_SpriteButtonRightOver : GetStyle()->m_SpriteButtonRight);
			}
			else
				button_right = &GetStyle()->m_SpriteButtonRight;

			m_pGUI.DrawSprite(
				*button_left,
				m_Z + 0.2f,
				CRect(
					outline.left,
					outline.top,
					outline.left + GetStyle()->m_Breadth,
					outline.bottom
				)
			);

			m_pGUI.DrawSprite(
				*button_right,
				m_Z + 0.2f,
				CRect(
					outline.right - GetStyle()->m_Breadth,
					outline.top,
					outline.right,
					outline.bottom
				)
			);
		}

		m_pGUI.DrawSprite(
			GetStyle()->m_SpriteBarHorizontal,
			m_Z + 0.2f,
			GetBarRect()
		);
	}
}

/**
 * @todo Can we use the host's m_NeedsScrollbar (or whatever it is) for this?
 */
void CGUIScrollBarHorizontal::HandleMessage(SGUIMessage &Message)
{
	switch (Message.type)
	{

	case GUIM_MOUSE_WHEEL_UP:
	{
		// Only respond to scroll wheel if there is no vertical scrollbar
		CRect host = GetHostGUIObject().GetCachedSize();
		CRect content = GetHostGUIObject().GetContentSize();
		if (content.GetHeight() <= host.GetHeight())
			ScrollMinus();
		break;
	}

	case GUIM_MOUSE_WHEEL_DOWN:
	{
		// Only respond to scroll wheel if there is no vertical scrollbar
		CRect host = GetHostGUIObject().GetCachedSize();
		CRect content = GetHostGUIObject().GetContentSize();
		if (content.GetHeight() <= host.GetHeight())
			ScrollPlus();
		break;
	}

	default:
		break;
	}

	IGUIScrollBar::HandleMessage(Message);
}

CRect CGUIScrollBarHorizontal::GetBarRect() const
{
	CRect ret;
	if (!GetStyle())
		return ret;

	// Get from where the scroll area begins to where it ends
	float from = m_X;
	float to = m_X + m_Length - m_BarSize;

	if (GetStyle()->m_UseEdgeButtons)
	{
		from += GetStyle()->m_Breadth;
		to -= GetStyle()->m_Breadth;
	}

	ret.bottom = m_Y + (m_BottomAligned ? 0.f : GetStyle()->m_Breadth);
	ret.top = ret.bottom - GetStyle()->m_Breadth;
	ret.left = from + (to - from) * (m_Pos / GetMaxPos());
	ret.right = ret.left + m_BarSize;

	return ret;
}

CRect CGUIScrollBarHorizontal::GetOuterRect() const
{
	CRect ret;
	if (!GetStyle())
		return ret;

	ret.left = m_X;
	ret.right = m_X + m_Length;
	ret.bottom = m_Y + (m_BottomAligned ? 0 : GetStyle()->m_Breadth);
	ret.top = ret.bottom - GetStyle()->m_Breadth;

	return ret;
}

bool CGUIScrollBarHorizontal::HoveringButtonMinus(const CVector2D& mouse)
{
	if (!GetStyle())
		return false;

	float StartY = m_BottomAligned ? m_Y - GetStyle()->m_Breadth : m_Y;

	return mouse.X >= m_X &&
	       mouse.X <= m_X + GetStyle()->m_Breadth &&
	       mouse.Y >= StartY &&
	       mouse.Y <= StartY + GetStyle()->m_Breadth;
}

bool CGUIScrollBarHorizontal::HoveringButtonPlus(const CVector2D& mouse)
{
	if (!GetStyle())
		return false;

	float StartY = m_BottomAligned ? m_Y - GetStyle()->m_Breadth : m_Y;

	return mouse.X > m_X + m_Length &&
	       mouse.X < m_X + m_Length + GetStyle()->m_Breadth &&
	       mouse.Y > StartY - GetStyle()->m_Breadth &&
	       mouse.Y < StartY;
}
