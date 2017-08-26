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

#include "CGUIScrollBarVertical.h"

#include "gui/CGUI.h"
#include "ps/CLogger.h"

CGUIScrollBarVertical::CGUIScrollBarVertical(CGUI& pGUI)
 : IGUIScrollBar(pGUI)
{
}

CGUIScrollBarVertical::~CGUIScrollBarVertical()
{
}

void CGUIScrollBarVertical::Setup()
{
	CRect host = GetHostGUIObject().GetCachedSize();
	CRect content = GetHostGUIObject().GetContentSize();

	SetScrollRange(content.GetHeight());
	Setup(host);

	// If the content width is wider than the host, assume there
	// is also a horizontal scrollbar and make room for it.
	if (content.GetWidth() > host.GetWidth())
		SetLength(host.bottom - host.top - GetStyle()->m_Breadth);
}

void CGUIScrollBarVertical::Setup(const CRect& content)
{
	SetScrollSpace(content.GetHeight());

	SetX(m_RightAligned ? content.right : content.left);
	SetY(content.top);
	SetZ(GetHostGUIObject().GetBufferedZ());

	SetLength(content.bottom - content.top);
}

void CGUIScrollBarVertical::SetPosFromMousePos(const CVector2D& mouse)
{
	if (!GetStyle())
		return;

	/**
	 * Calculate the position for the top of the item being scrolled
	 */
	float emptyBackground = m_Breadth - m_BarSize;

	if (GetStyle()->m_UseEdgeButtons)
		emptyBackground -= GetStyle()->m_Breadth * 2;

	m_Pos = m_PosWhenPressed + GetMaxPos() * (mouse.Y - m_BarPressedAtPos.Y) / emptyBackground;
}

void CGUIScrollBarVertical::Draw()
{
	if (!GetStyle())
	{
		LOGWARNING("Attempt to draw a vertical scrollbar without a style.");
		return;
	}

	if (IsNeeded())
	{
		CRect outline = GetOuterRect();

		m_pGUI.DrawSprite(
			GetStyle()->m_SpriteBackVertical,
			m_Z + 0.1f,
			CRect(
				outline.left,
				outline.top + (GetStyle()->m_UseEdgeButtons ? GetStyle()->m_Breadth : 0),
				outline.right,
				outline.bottom - (GetStyle()->m_UseEdgeButtons ? GetStyle()->m_Breadth : 0)
			)
		);

		if (GetStyle()->m_UseEdgeButtons)
		{
			const CGUISpriteInstance* button_top;
			const CGUISpriteInstance* button_bottom;

			if (m_ButtonMinusHovered)
			{
				if (m_ButtonMinusPressed)
					button_top = &(GetStyle()->m_SpriteButtonTopPressed ? GetStyle()->m_SpriteButtonTopPressed : GetStyle()->m_SpriteButtonTop);
				else
					button_top = &(GetStyle()->m_SpriteButtonTopOver ? GetStyle()->m_SpriteButtonTopOver : GetStyle()->m_SpriteButtonTop);
			}
			else
				button_top = &GetStyle()->m_SpriteButtonTop;

			if (m_ButtonPlusHovered)
			{
				if (m_ButtonPlusPressed)
					button_bottom = &(GetStyle()->m_SpriteButtonBottomPressed ? GetStyle()->m_SpriteButtonBottomPressed : GetStyle()->m_SpriteButtonBottom);
				else
					button_bottom = &(GetStyle()->m_SpriteButtonBottomOver ? GetStyle()->m_SpriteButtonBottomOver : GetStyle()->m_SpriteButtonBottom);
			}
			else
				button_bottom = &GetStyle()->m_SpriteButtonBottom;

			m_pGUI.DrawSprite(
				*button_top,
				m_Z + 0.2f,
				CRect(
					outline.left,
					outline.top,
					outline.right,
					outline.top + GetStyle()->m_Breadth
				)
			);

			m_pGUI.DrawSprite(
				*button_bottom,
				m_Z + 0.2f,
				CRect(
					outline.left,
					outline.bottom - GetStyle()->m_Breadth,
					outline.right,
					outline.bottom
				)
			);
		}

		m_pGUI.DrawSprite(
			GetStyle()->m_SpriteBarVertical,
			m_Z + 0.2f,
			GetBarRect()
		);
	}
}

void CGUIScrollBarVertical::HandleMessage(SGUIMessage& Message)
{
	switch (Message.type)
	{
	case GUIM_MOUSE_WHEEL_UP:
		ScrollMinus();
		break;

	case GUIM_MOUSE_WHEEL_DOWN:
		ScrollPlus();
		break;

	default:
		break;
	}

	IGUIScrollBar::HandleMessage(Message);
}

CRect CGUIScrollBarVertical::GetBarRect() const
{
	CRect ret;
	if (!GetStyle())
		return ret;

	// Get from where the scroll area begins to where it ends
	float from = m_Y;
	float to = m_Y + m_Length - m_BarSize;

	if (GetStyle()->m_UseEdgeButtons)
	{
		from += GetStyle()->m_Breadth;
		to -= GetStyle()->m_Breadth;
	}

	ret.top = from + (to - from) * m_Pos / GetMaxPos();
	ret.bottom = ret.top + m_BarSize;
	ret.right = m_X + (m_RightAligned ? 0 : GetStyle()->m_Breadth);
	ret.left = ret.right - GetStyle()->m_Breadth;

	return ret;
}

CRect CGUIScrollBarVertical::GetOuterRect() const
{
	CRect ret;
	if (!GetStyle())
		return ret;

	ret.top = m_Y;
	ret.bottom = m_Y + m_Length;
	ret.right = m_X + (m_RightAligned ? 0 : GetStyle()->m_Breadth);
	ret.left = ret.right - GetStyle()->m_Breadth;

	return ret;
}

bool CGUIScrollBarVertical::HoveringButtonMinus(const CVector2D& mouse)
{
	if (!GetStyle())
		return false;

	float StartX = m_RightAligned ? m_X - GetStyle()->m_Breadth : m_X;

	return mouse.X >= StartX &&
	       mouse.X <= StartX + GetStyle()->m_Breadth &&
	       mouse.Y >= m_Y &&
	       mouse.Y <= m_Y + GetStyle()->m_Breadth;
}

bool CGUIScrollBarVertical::HoveringButtonPlus(const CVector2D& mouse)
{
	if (!GetStyle())
		return false;

	float StartX = m_RightAligned ? m_X - GetStyle()->m_Breadth : m_X;

	return mouse.X > StartX &&
	       mouse.X < StartX + GetStyle()->m_Breadth &&
	       mouse.Y > m_Y + m_Length - GetStyle()->m_Breadth &&
	       mouse.Y < m_Y + m_Length;
}
