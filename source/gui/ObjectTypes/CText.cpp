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

#include "CText.h"

#include "gui/CGUI.h"
#include "gui/CGUIScrollBarVertical.h"
#include "gui/CGUIText.h"
#include "scriptinterface/ScriptInterface.h"

CText::CText(CGUI& pGUI)
	: IGUIObject(pGUI),
	  IGUIScrollBarOwner(*static_cast<IGUIObject*>(this)),
	  IGUITextOwner(*static_cast<IGUIObject*>(this)),
	  m_BufferZone(),
	  m_Caption(),
	  m_Clip(),
	  m_Font(),
	  m_ScrollBar(),
	  m_ScrollBarStyle(),
	  m_ScrollResetOnChange(),
	  m_Sprite(),
	  m_TextAlign(),
	  m_TextVAlign(),
	  m_TextColor(),
	  m_TextColorDisabled(),
	  m_IconTooltip(),
	  m_IconTooltipStyle()
{
	RegisterSetting("buffer_zone", m_BufferZone);
	RegisterSetting("caption", m_Caption);
	RegisterSetting("clip", m_Clip);
	RegisterSetting("font", m_Font);
	RegisterSetting("scrollbar", m_ScrollBar);
	RegisterSetting("scrollbar_reset_on_change", m_ScrollResetOnChange);
	RegisterSetting("scrollbar_sticky_end", m_ScrollStickyEnd);
	RegisterSetting("scrollbar_style", m_ScrollBarStyle);
	RegisterSetting("sprite", m_Sprite);
	RegisterSetting("text_align", m_TextAlign);
	RegisterSetting("text_valign", m_TextVAlign);
	RegisterSetting("textcolor", m_TextColor);
	RegisterSetting("textcolor_disabled", m_TextColorDisabled);
	// Private settings
	RegisterSetting("_icon_tooltip", m_IconTooltip);
	RegisterSetting("_icon_tooltip_style", m_IconTooltipStyle);

	//SetSetting<bool>("ghost", true, true);
	SetSetting<bool>("scrollbar", false, true);
	SetSetting<bool>("clip", true, true);

	// Add scrollbar
	CGUIScrollBarVertical* bar = new CGUIScrollBarVertical(pGUI);
	bar->SetRightAligned(true);
	AddScrollBar(bar);

	// Add text
	AddText();
}

CText::~CText()
{
}

void CText::SetupText()
{
	if (m_GeneratedTexts.empty())
		return;

	float width = m_CachedActualSize.GetWidth();

	// Reduce width by scrollbar breadth if applicable.
	if (m_ScrollBar && GetScrollBar(0).GetStyle())
		width -= GetScrollBar(0).GetStyle()->m_Breadth;

	m_GeneratedTexts[0] = CGUIText(m_pGUI, m_Caption, m_Font, width, m_BufferZone, this);
	m_CachedContentSize = m_GeneratedTexts[0].GetSize();

	if (!m_ScrollBar)
		CalculateTextPosition(m_CachedActualSize, m_TextPos, m_GeneratedTexts[0]);
	else
	{
		bool bottom = false;
		if (m_ScrollResetOnChange)
			GetScrollBar(0).SetPos(0.0f);
		else
			// If we are currently scrolled to the bottom of the text, the UI designer has
			// specified that we should "stick" to the bottom, and more lines of text are
			// being added, then we need to update the scrollbar so we stay at the bottom.
			// And we need to determine this before we renew the scrollbars after adding
			// the text.
			bottom = KeepScrollBarAtEnd(0);

		GetScrollBar(0).Setup();

		if (bottom)
			GetScrollBar(0).SetPos(GetScrollBar(0).GetMaxPos());
	}
}

void CText::ResetStates()
{
	IGUIObject::ResetStates();
	IGUIScrollBarOwner::ResetStates();
}

void CText::UpdateCachedSize()
{
	IGUIObject::UpdateCachedSize();
	IGUITextOwner::UpdateCachedSize();
}

CSize2D CText::GetTextSize()
{
	UpdateText();
	return m_GeneratedTexts[0].GetSize();
}

void CText::HandleMessage(SGUIMessage& Message)
{
	IGUIObject::HandleMessage(Message);
	IGUIScrollBarOwner::HandleMessage(Message);

	switch (Message.type)
	{
	case GUIM_SETTINGS_UPDATED:
		if (Message.value == "scrollbar" || Message.value == "scrollbar_style")
			SetupText();

		if (Message.value == "scrollbar_style")
			GetScrollBar(0).SetScrollBarStyle(m_ScrollBarStyle);
		break;

	case GUIM_MOUSE_WHEEL_DOWN:
	case GUIM_MOUSE_WHEEL_UP:
		if (!m_ScrollBar)
			m_pParent->HandleMessage(Message);
		break;

	case GUIM_LOAD:
		GetScrollBar(0).SetScrollBarStyle(m_ScrollBarStyle);
		break;

	default:
		break;
	}

	// Deliberately placed after the switch...case.
	IGUITextOwner::HandleMessage(Message);
}

void CText::Draw()
{
	float bz = GetBufferedZ();

	if (m_ScrollBar)
		IGUIScrollBarOwner::Draw();

	m_pGUI.DrawSprite(m_Sprite, bz, m_CachedActualSize);

	float scroll = 0.f;
	if (m_ScrollBar)
		scroll = GetScrollBar(0).GetPos();

	// Clipping area (we'll have to subtract the scrollbar)
	CRect cliparea;
	if (m_Clip)
	{
		cliparea = m_CachedActualSize;

		if (m_ScrollBar)
		{
			// subtract scrollbar from cliparea
			if (cliparea.right > GetScrollBar(0).GetOuterRect().left &&
			    cliparea.right <= GetScrollBar(0).GetOuterRect().right)
				cliparea.right = GetScrollBar(0).GetOuterRect().left;

			if (cliparea.left >= GetScrollBar(0).GetOuterRect().left &&
			    cliparea.left < GetScrollBar(0).GetOuterRect().right)
				cliparea.left = GetScrollBar(0).GetOuterRect().right;
		}
	}

	const CGUIColor& color = m_Enabled ? m_TextColor : m_TextColorDisabled;

	if (m_ScrollBar)
		DrawText(0, color, m_CachedActualSize.TopLeft() - CVector2D(0.f, scroll), bz + 0.1f, cliparea);
	else
		DrawText(0, color, m_TextPos, bz + 0.1f, cliparea);
}

bool CText::MouseOverIcon()
{
	for (const CGUIText& guitext : m_GeneratedTexts)
		for (const CGUIText::SSpriteCall& spritecall : guitext.GetSpriteCalls())
		{
			// Check mouse over sprite
			if (!spritecall.m_Area.PointInside(m_pGUI.GetMousePos() - m_CachedActualSize.TopLeft()))
				continue;

			// If tooltip exists, set the property
			if (!spritecall.m_Tooltip.empty())
			{
				SetSettingFromString("_icon_tooltip_style", spritecall.m_TooltipStyle, true);
				SetSettingFromString("_icon_tooltip", spritecall.m_Tooltip, true);
			}

			return true;
		}

	return false;
}
