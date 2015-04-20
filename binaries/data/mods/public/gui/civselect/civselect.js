
// Globals
var g_CivData = {};
var g_CultureData = {};
var g_player = 0;
var g_selected = "athen";

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
	
	predraw();
	
	var grpSel = Engine.GetGUIObjectByName("groupSelection");
	grpSel.list = [ "Ungrouped" ];
	grpSel.list_data = [ "nogroup" ];
	grpSel.selected = 0;
	
	draw();
	
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
	for (let code in g_CivData)
	{
		let civ = g_CivData[code];
		for (let culture of civ.Culture)
		{
			if (g_CultureData[culture] === undefined)
			{
				let data = Engine.ReadJSONFile("simulation/data/civs/cultures/"+culture+".json");
				if (!data)
					continue;
				
				g_CultureData[culture] = data;
			}
		}
	}
}

function predraw ()
{
//	horizSpaceRepeatedObjects("emblem[emb]", "emb", 16, 4);
	gridArrayRepeatedObjects("emblem[emb]", "emb", 16, 8);
}

function draw ()
{
	var emblemLimit = 16;
	
	var emb = 0;
	for (let civ in g_CivData)
	{	
		let embObj = Engine.GetGUIObjectByName("emblem["+emb+"]_img");
		embObj.sprite = "stretched:"+g_CivData[civ].Emblem;
		let embBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
		setBtnFunc (embBtn, selectCiv, [ civ ]);
		emb++;
	}
	for (emb; emb < emblemLimit; ++emb)
	{
		let embObj = Engine.GetGUIObjectByName("emblem["+emb+"]");
		embObj.hidden = true;
	}
	
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

