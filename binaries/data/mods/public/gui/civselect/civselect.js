
// Globals
var g_CivData = {};
var g_GroupingData = {};
var g_player = 0;
var g_selected = "athen";
var g_currentGroup = "none";
var g_groupLimit = 8;
var g_emblemLimit = 16;

/**
 * Run when UI Page loaded.
 */
function init (settings)
{
//	warn(uneval(settings));
	
	initCivs();
	
	g_player = settings.player;
	if (settings.current !== "random")
		g_selected = settings.current;
	
	var grpSel = Engine.GetGUIObjectByName("groupSelection");
	grpSel.list = [ "Ungrouped", "By Culture" ];
	grpSel.list_data = [ "nogroup", "culture" ];
	grpSel.selected = 0;
	
	selectCiv(g_selected);
}

/**
 * Load civ data
 */
function initCivs ()
{
	// Cache civ data
	g_CivData = loadCivData(true);
	
	// Cache culture data
	g_GroupingData.culture = loadCultureData(Object.keys(g_CivData));
}

function chooseGrouping (choice)
{
	if (choice === "nogroup")
		draw_ungrouped();
	else
		draw_grouped(choice);
}

function draw_grouped (group)
{
	var grp = 0;
	var emb = 0;
	var vOffset = 8;
	var grouping = g_GroupingData[group];
	for (let code in grouping)
	{
		
		let grpObj = Engine.GetGUIObjectByName("civGroup["+grp+"]");
		let grpSize = grpObj.size;
		grpSize.top = vOffset;
		grpObj.size = grpSize;
		grpObj.hidden = false;
		
		let grpHeading = Engine.GetGUIObjectByName("groupHeading["+grp+"]");
		grpHeading.caption = grouping[code].Name;
		let range = [ emb ];
		
		for (let civ of grouping[code].civlist)
		{
			let embObj = Engine.GetGUIObjectByName("emblem["+emb+"]_img");
			embObj.sprite = "stretched:"+g_CivData[civ].Emblem;
			let embBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
			setBtnFunc (embBtn, selectCiv, [ civ ]);
			Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = false;
			emb++;
		}
		range[1] = emb - 1;
		
		vOffset += grpHeading.size.bottom + 2;
		vOffset += gridArrayRepeatedObjects("emblem[emb]", "emb", range, 4, vOffset);
		vOffset += 8;
		grp++;
	}
	for (emb; emb < g_emblemLimit; ++emb)
		Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = true;
	for (grp; grp < g_groupLimit; ++grp)
		Engine.GetGUIObjectByName("civGroup["+grp+"]").hidden = true;
}

function draw_ungrouped ()
{
	gridArrayRepeatedObjects("emblem[emb]", "emb", 16, 8);
	var emb = 0;
	for (let civ in g_CivData)
	{	
		let embObj = Engine.GetGUIObjectByName("emblem["+emb+"]_img");
		embObj.sprite = "stretched:"+g_CivData[civ].Emblem;
		let embBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
		setBtnFunc (embBtn, selectCiv, [ civ ]);
		Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = false;
		emb++;
	}
	for (emb; emb < g_emblemLimit; ++emb)
		Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = true;
	for (let grp = 0; grp < g_groupLimit; ++grp)
		Engine.GetGUIObjectByName("civGroup["+grp+"]").hidden = true;
	
}

function selectCiv (code)
{
	g_selected = code;
	
	var heading = Engine.GetGUIObjectByName("selectedCiv_heading");
	heading.caption = g_CivData[code].Name;
	
	var history = Engine.GetGUIObjectByName("selectedCiv_history");
	history.caption = g_CivData[code].History;
	
}

function selectGroup ()
{
	
	
}

function setBtnFunc (btn, func, vars = null)
{
	btn.onPress = function () { func.apply(null, vars); };
}

