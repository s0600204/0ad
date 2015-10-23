
// Globals
var g_CivData = {};
var g_GroupingData = {};
var g_player = 0;
var g_selected = {
	"isGroup": false,
	"code": "athen"
};
var g_groupChoice = "none";
var g_margin = 8;
var g_headEmbSize = 80;

/**
 * Run when UI Page loaded.
 */
function init (settings)
{
//	warn(uneval(settings));

	// Cache civ data
	g_CivData = loadCivData(true);
	
	g_player = settings.player;
	if (settings.current !== "random" && Object.keys(g_CivData).indexOf(settings.current) > -1)
		g_selected.code = settings.current;
	else
	{
		var num = Math.floor(Math.random() * Object.keys(g_CivData).length);
		g_selected.code = Object.keys(g_CivData)[num];
	}
	
	// Cache grouping data and create list
	var grpList = [ "Ungrouped" ];
	var grpList_data = [ "nogroup" ];
	for (let grp of Engine.BuildDirEntList("simulation/data/civs/grouping/", "*.json", false))
	{
		let data = Engine.ReadJSONFile(grp);
		if (!data)
			continue;
		
		translateObjectKeys(data, [ "ListEntry" ]);
		g_GroupingData[data.Code] = loadGroupingSchema(data.Folder, data.CivAttribute);
		grpList.push(data.ListEntry);
		grpList_data.push(data.Code);
		
	}
	
	var grpSel = Engine.GetGUIObjectByName("groupSelection");
	grpSel.list = grpList;
	grpSel.list_data = grpList_data;
	grpSel.selected = 0;
	
	selectCiv(g_selected.code);
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
	var vOffset = 0;
	g_groupChoice = group;
	var grouping = g_GroupingData[group];
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
		grpSize.left = (code === "groupless") ? g_margin : g_headEmbSize-g_margin;
		grpObj.size = grpSize;
		grpObj.hidden = false;
		
		g_GroupingData[g_groupChoice][code].embs = [];
		
		let grpHeading = Engine.GetGUIObjectByName("civGroup["+grp+"]_heading");
		grpHeading.caption = grouping[code].Name;

		if (code !== "groupless")
		{
			let grpBtn = Engine.GetGUIObjectByName("emblem["+emb+"]_btn");
			setBtnFunc(grpBtn, selectGroup, [ code ]);
			setEmbPos("emblem["+emb+"]", 0, vOffset+g_margin);
			setEmbSize("emblem["+emb+"]", g_headEmbSize);
			
			let sprite = (code!==g_selected.code) ? "grayscale:" : "";
			if (grouping[code].Emblem)
				sprite += grouping[code].Emblem;
			else
				sprite += g_CivData[grouping[code].civlist[0]].Emblem;
			Engine.GetGUIObjectByName("emblem["+emb+"]_img").sprite = "stretched:"+sprite;
			Engine.GetGUIObjectByName("emblem["+emb+"]").hidden = false;
			g_GroupingData[g_groupChoice][code].embs.push(emb);
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
			g_GroupingData[g_groupChoice][code].embs.push(emb);

			embImg.sprite = "stretched:";
			if (civ !== g_selected.code && code !== g_selected.code)
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
		vOffset += gridArrayRepeatedObjects("emblem[emb]", "emb", 4, range, vOffset, ((code==="groupless")?g_margin:g_headEmbSize));
		vOffset += g_margin * 2;
		grp++;
	}
	hideRemaining("emblem[", emb, "]");
	hideRemaining("civGroup[", grp, "]");
}

function draw_ungrouped ()
{
	setEmbSize("emblem[0]");
	gridArrayRepeatedObjects("emblem[emb]", "emb", 8);
	var emb = 0;
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
		if (civ !== g_selected.code)
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
	
	g_selected.isGroup = false;
	g_selected.code = code;
	
	var heading = Engine.GetGUIObjectByName("selected_heading");
	heading.caption = g_CivData[code].Name;
	
	var civList = Engine.GetGUIObjectByName("selected_civs");
	civList.hidden = true;
	
	var history = Engine.GetGUIObjectByName("selected_history");
	history.caption = g_CivData[code].History;
	
	var size = history.parent.size;
	size.top = 48;
	history.parent.size = size;
	
	var choice = Engine.GetGUIObjectByName("selected_text");
	choice.caption = "You have selected the "+g_CivData[code].Name;
}

function selectGroup (code)
{
	highlightEmblems(g_GroupingData[g_groupChoice][code].embs);
	
	g_selected.isGroup = true;
	g_selected.code = code;
	
	var heading = Engine.GetGUIObjectByName("selected_heading");
	heading.caption = g_GroupingData[g_groupChoice][code].Name;
	
	var civList = Engine.GetGUIObjectByName("selected_civs");
	civList.hidden = false;
	civList.caption = "";
	let civCount = 0;
	for (let civ of g_GroupingData[g_groupChoice][code].civlist)
	{
		civList.caption += g_CivData[civ].Name+"\n";
		civCount++;
	}
	
	var history = Engine.GetGUIObjectByName("selected_history");
	history.caption = g_GroupingData[g_groupChoice][code].History;
	var size = history.parent.size;
	size.top = 18 * civCount + 64;
	history.parent.size = size;
	
	var choice = Engine.GetGUIObjectByName("selected_text");
	if (g_GroupingData[g_groupChoice][code].Singular)
		choice.caption = "A "+g_GroupingData[g_groupChoice][code].Singular+" civ will be picked at random."; 
	else
		choice.caption = "A civ will be picked at random from this group";
}

function highlightEmblems (embs = [], gray = false)
{
	if (!gray)
		if (g_selected.isGroup)
		{
			if (g_GroupingData[g_groupChoice][g_selected.code])
				highlightEmblems(g_GroupingData[g_groupChoice][g_selected.code].embs, true);
		}
		else
			highlightEmblems(g_CivData[g_selected.code].embs, true);
	
	for (let e of embs) {
		var embImg = Engine.GetGUIObjectByName("emblem["+e+"]_img");
		var sprite = embImg.sprite.split(":");
		embImg.sprite = "stretched:" + ((gray)?"grayscale:":"") + sprite.pop();
	}
}

function setBtnFunc (btn, func, vars = null)
{
	btn.onPress = function () { func.apply(null, vars); };
}

function returnCiv ()
{
	let code = g_selected.code;
	if (g_selected.isGroup)
	{
		// pick random(-ish) civ from group's list
		let num = g_GroupingData[g_groupChoice][code].civlist.length;
		num = Math.floor(Math.random() * num);
		code = g_GroupingData[g_groupChoice][code].civlist[num];
	}
	Engine.PopGuiPageCB({
			"player": g_player,
			"civ": code
		});
}
