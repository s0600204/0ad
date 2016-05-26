
// Globals
var g_CivData = {};
var g_GroupingData = {};
var g_GroupingChoice = "none";
var g_Player = 0;
var g_Selected = {
	"isGroup": false,
	"code": "athen"
};
var g_EmblemMargin = 8;
var g_HeaderEmblemSize = 80;

/**
 * Run when UI Page loaded.
 */
function init (settings)
{
	// Cache civ data
	g_CivData = loadCivData(true);

	g_Player = settings.player;

	// If no civ passed, choose one at random
	if (!settings.civ)
	{
		let num = Math.floor(Math.random() * Object.keys(g_CivData).length);
		settings.civ = {
			"codes": [ Object.keys(g_CivData)[num] ],
			"grouped": false
		};
	}

	// Cache grouping data and create list
	let grpList = [ "Ungrouped" ];
	let grpList_data = [ "nogroup" ];
	for (let grp of Engine.BuildDirEntList("simulation/data/civs/grouping/", "*.json", false))
	{
		let data = Engine.ReadJSONFile(grp);
		if (!data)
			continue;

		translateObjectKeys(data, ["ListEntry"]);
		g_GroupingData[data.Code] = loadGroupingSchema(data.Folder, data.CivAttribute);
		grpList.push(data.ListEntry);
		grpList_data.push(data.Code);
	}

	let grpSel = Engine.GetGUIObjectByName("groupSelection");
	grpSel.list = grpList;
	grpSel.list_data = grpList_data;

	// Read civ choice from passed data
	if (!settings.civ.grouped)
	{
		g_Selected.code = settings.civ.codes[0];
		grpSel.selected = 0;
		selectCiv(g_Selected.code);
	}
	else
	{
		g_GroupingChoice = settings.civ.group.type;
		g_Selected.isGroup = true;
		if (settings.civ.group.code !== "all")
		{
			g_Selected.code = settings.civ.group.code;
			grpSel.selected = grpSel.list_data.indexOf(g_GroupingChoice);
			selectGroup(g_Selected.code);
		}
		else
		{
			grpSel.selected = 0;
			selectAllCivs();
		}
	}
}

function chooseGrouping (choice)
{
	Engine.GetGUIObjectByName("allUngrouped").hidden = !(choice === "nogroup");
	if (choice === "nogroup")
		draw_ungrouped();
	else
		draw_grouped(choice);
}

function draw_grouped (group)
{
	let grp = 0;
	let emb = 0;
	let vOffset = 0;
	g_GroupingChoice = group;
	let grouping = g_GroupingData[group];
	for (let civ in g_CivData)
		g_CivData[civ].embs = [];
	for (let code in grouping)
	{
		// Pre-emptive check to make sure we have at least one emblem left
		if (!Engine.GetGUIObjectByName("emblem["+emb+"]"))
			break;

		let grpObj = Engine.GetGUIObjectByName("civGroup["+grp+"]");
		if (grpObj === undefined)
		{
			error("There are more grouping choices available than can be supported by the current GUI layout");
			break;
		}

		let grpSize = grpObj.size;
		grpSize.top = vOffset;
		grpSize.left = (code === "groupless") ? g_EmblemMargin : g_HeaderEmblemSize-g_EmblemMargin;
		grpObj.size = grpSize;
		grpObj.hidden = false;

		g_GroupingData[g_GroupingChoice][code].embs = [];

		let grpHeading = Engine.GetGUIObjectByName("civGroup["+grp+"]_heading");
		grpHeading.caption = grouping[code].Name;

		if (code !== "groupless")
		{
			let grpBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
			setBtnFunc(grpBtn, selectGroup, [ code ]);
			setEmbPos("emblem["+emb+"]", 0, vOffset+g_EmblemMargin);
			setEmbSize("emblem["+emb+"]", g_HeaderEmblemSize);
			
			let sprite = (code!==g_Selected.code) ? "grayscale:" : "";
			if (grouping[code].Emblem)
				sprite += grouping[code].Emblem;
			else
				sprite += g_CivData[grouping[code].civlist[0]].Emblem;
			Engine.GetGUIObjectByName("emblem["+emb+"]_img").sprite = "stretched:"+sprite;
			Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = false;
			g_GroupingData[g_GroupingChoice][code].embs.push(emb);
			++emb;
		}

		let range = [ emb ];

		for (let civ of grouping[code].civlist)
		{
			let embImg = Engine.GetGUIObjectByName("emblem["+emb+"]_img");
			if (embImg === undefined)
			{
				error("There are not enough images in the current GUI layout to support that many civs");
				break;
			}
			g_CivData[civ].embs.push(emb);
			g_GroupingData[g_GroupingChoice][code].embs.push(emb);

			embImg.sprite = "stretched:";
			if (civ !== g_Selected.code && code !== g_Selected.code)
				embImg.sprite += "grayscale:";
			embImg.sprite += g_CivData[civ].Emblem;

			let embBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
			setBtnFunc(embBtn, selectCiv, [ civ ]);
			Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = false;
			emb++;
		}
		range[1] = emb - 1;

		setEmbSize("emblem["+range[0]+"]", 58);
		vOffset += grpHeading.size.bottom + 2;
		vOffset += gridArrayRepeatedObjects("emblem[emb]", "emb", 4, range, vOffset, ((code==="groupless")?g_EmblemMargin:g_HeaderEmblemSize));
		vOffset += g_EmblemMargin * 2;
		grp++;
	}
	hideRemaining("emblem[", emb, "]");
	hideRemaining("civGroup[", grp, "]");
}

function draw_ungrouped ()
{
	setEmbSize("emblem[0]");
	gridArrayRepeatedObjects("emblem[emb]", "emb", 8);
	let emb = 0;
	for (let civ in g_CivData)
	{	
		g_CivData[civ].embs = [ emb ];
		
		let embImg = Engine.GetGUIObjectByName("emblem["+emb+"]_img");
		if (embImg === undefined)
		{
			error("There are not enough images in the current GUI layout to support that many civs");
			break;
		}

		embImg.sprite = "stretched:";
		if (civ !== g_Selected.code)
			embImg.sprite += "grayscale:";
		embImg.sprite += g_CivData[civ].Emblem;

		let embBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
		setBtnFunc(embBtn, selectCiv, [ civ ]);
		Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = false;
		emb++;
	}
	hideRemaining("emblem[", emb, "]");
	hideRemaining("civGroup[", 0, "]");
}

function selectCiv (code)
{
	highlightEmblems(g_CivData[code].embs);
	Engine.GetGUIObjectByName("allUngrouped_check").checked = false;

	g_Selected.isGroup = false;
	g_Selected.code = code;

	let heading = Engine.GetGUIObjectByName("selected_heading");
	heading.caption = g_CivData[code].Name;
	
	let civList = Engine.GetGUIObjectByName("selected_civs");
	civList.hidden = true;

	let history = Engine.GetGUIObjectByName("selected_history");
	history.caption = g_CivData[code].History;

	let size = history.parent.size;
	size.top = 48;
	history.parent.size = size;
	history.parent.hidden = false;

	let choice = Engine.GetGUIObjectByName("selected_text");
	choice.caption = sprintf(translate("You have selected the %(civname)s"), {"civname": g_CivData[code].Name});
}

function selectGroup (code)
{
	highlightEmblems(g_GroupingData[g_GroupingChoice][code].embs);
	Engine.GetGUIObjectByName("allUngrouped_check").checked = false;

	g_Selected.isGroup = true;
	g_Selected.code = code;

	let heading = Engine.GetGUIObjectByName("selected_heading");
	heading.caption = g_GroupingData[g_GroupingChoice][code].Name;

	let civList = Engine.GetGUIObjectByName("selected_civs");
	civList.hidden = false;
	civList.caption = "";
	let civCount = 0;
	for (let civ of g_GroupingData[g_GroupingChoice][code].civlist)
	{
		civList.caption += g_CivData[civ].Name+"\n";
		civCount++;
	}

	let history = Engine.GetGUIObjectByName("selected_history");
	history.caption = g_GroupingData[g_GroupingChoice][code].History;
	let size = history.parent.size;
	size.top = 18 * civCount + 64;
	history.parent.size = size;
	history.parent.hidden = false;

	let choice = Engine.GetGUIObjectByName("selected_text");
	if (g_GroupingData[g_GroupingChoice][code].Singular)
		choice.caption = sprintf(translate("A random %(civGroup)s civ will be chosen."), {
			"civGroup": g_GroupingData[g_GroupingChoice][code].Singular
		}); 
	else
		choice.caption = translate("A civ will be chosen at random from this group");
}

function selectAllCivs ()
{
	Engine.GetGUIObjectByName("allUngrouped_check").checked = true;

	let embs = [];
	for (let i=0; ; ++i)
	{
		if (!Engine.GetGUIObjectByName("emblem["+i+"]"))
			break;
		embs.push(i);
	}
	highlightEmblems(embs);

	g_Selected.isGroup = true;
	g_Selected.code = "all";

	let heading = Engine.GetGUIObjectByName("selected_heading");
	heading.caption = sprintf(translate("Random %(civGroup)s"), {
			"civGroup": translateWithContext("All Civs", "All")
		});

	let civList = Engine.GetGUIObjectByName("selected_civs");
	civList.hidden = false;
	civList.caption = "";
	let civCount = 0;
	for (let civ in g_CivData)
	{
		civList.caption += g_CivData[civ].Name+"\n";
		civCount++;
	}

	let history = Engine.GetGUIObjectByName("selected_history");
	history.parent.hidden = true;

	let choice = Engine.GetGUIObjectByName("selected_text");
	choice.caption = translate("A civ will be chosen at random");
}

function highlightEmblems (embs = [])
{
	for (let e=0; ; ++e)
	{
		if (!Engine.GetGUIObjectByName("emblem["+e+"]"))
			return;

		let embImg = Engine.GetGUIObjectByName("emblem["+e+"]_img");
		let sprite = embImg.sprite.split(":");
		embImg.sprite = "stretched:" + ((embs.indexOf(e)<0)?"grayscale:":"") + sprite.pop();
	}
}

function setBtnFunc (btn, func, vars = null)
{
	btn.onPress = function () { func.apply(null, vars); };
}

function returnCiv ()
{
	let code = g_Selected.code;
	let civ = {
			"codes": [ g_Selected.code ],
			"grouped": false,
		}
	if (g_Selected.isGroup)
	{
		civ.codes = g_Selected.code == "all" ? Object.keys(g_CivData) : g_GroupingData[g_GroupingChoice][code].civlist;
		civ.grouped = true;
		civ.group = {
				"caption": g_Selected.code === "all" ? "All" : g_GroupingData[g_GroupingChoice][code].Singular,
				"code": g_Selected.code,
				"type": g_GroupingChoice,
			};
	}
	Engine.PopGuiPageCB({
			"player": g_Player,
			"civ": civ,
		});
}
