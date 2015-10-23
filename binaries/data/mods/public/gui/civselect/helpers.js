
/**
 * Arranges same-size `<repeat>`d objects in a grid. Automatically scales to object size.
 * @param basename The base name of the object, such as "object[n]" or "object[a]_sub[b]"
 * @param splitvar The var identifying the repeat count, without the square brackets
 * @param vMargin The gap, in px, between the rows
 * @param limit Array of limits, of the form `[ {from}, {to} ]`. If an empty array, then it will do all objects matching the basname
 * @param vOffset Vertical offset from top of parent object to start drawing from
 * @return The height difference between the top of the first element and the bottom of the last.
 */
function gridArrayRepeatedObjects (basename, splitvar="n", vMargin=0, limit=[], vOffset=0, hOffset=0)
{
	basename = basename.split("["+splitvar+"]", 2);

	if (limit.length == 0)
	{
		limit = [0, 0, 1];
		while (Engine.GetGUIObjectByName(basename.join("["+ (limit[1]+1) +"]")))
		{
			++limit[1];
			++limit[2];
		}
	}
	else if (limit.length < 2)
	{
		error("Invalid limit arguments");
		return 0;
	}
	else
		limit[2] = limit[1] - limit[0] + 1;
	
	var firstObj = Engine.GetGUIObjectByName(basename.join("["+limit[0]+"]"));
	var child = firstObj.getComputedSize();
	child.width = child.right - child.left;
	child.height = child.bottom - child.top;
	
	var parent = firstObj.parent.getComputedSize();
	parent.width = parent.right - parent.left - hOffset;
	
	var rowLength = Math.floor(parent.width / child.width);
	
	var hMargin = parent.width - child.width * rowLength;
	hMargin = Math.round(hMargin / (rowLength + 1));
	
	child.width += hMargin;
	child.height += vMargin;
	
	var i = limit[0];
	for (let r = 0; r < Math.ceil(limit[2]/rowLength); ++r)
	{
		for (let c = 0; c < rowLength; ++c)
		{
			let newSize = new GUISize();
			newSize.left = c * child.width + hMargin + hOffset;
			newSize.right = (c+1) * child.width + hOffset;
			newSize.top = r * child.height + vMargin + vOffset;
			newSize.bottom = (r+1) * child.height + vOffset;
			Engine.GetGUIObjectByName(basename.join("["+ i++ +"]")).size = newSize;
			
			if (i > limit[1])
				break;
		}
	}
	
	var lastObj = Engine.GetGUIObjectByName(basename.join("["+(i-1)+"]"));
	return (lastObj.size.bottom - firstObj.size.top);
}

/**
 * Load Data about a grouping schema
 * 
 * @param attr The JSON attribute in the Civ JSON files that lists which of the groups in this schema that civ belongs to
 * @param folder The folder containing the groups of this schema
 */
function loadGroupingSchema (folder, attr)
{
	var groupData = {};
	var groupless = [];
	
	for (let code of Object.keys(g_CivData))
	{
		let civ = g_CivData[code];
		let nogroup = true;
		let groups = civ[attr] || [];
		if (typeof groups === "string")
			groups = [ groups ];
		
		for (let grp of groups)
		{
			if (groupData[grp] === undefined)
			{
				let data = Engine.ReadJSONFile("simulation/data/civs/"+folder+"/"+grp+".json");
				if (!data)
					continue;
				
				groupData[grp] = data;
				groupData[grp].civlist = [];
			}
			groupData[grp].civlist.push(code);
			nogroup = false;
		}
		if (nogroup)
			groupless.push(code);
	}
	if (groupless.length > 0)
		groupData.groupless = {
			"Name" : "Ungrouped",
			"Code" : "groupless",
			"History" : "-",
			"civlist": groupless
		};
	return groupData;
}

function setEmbSize (objectName, length=128)
{
	var objSize = Engine.GetGUIObjectByName(objectName).size;
	objSize.right = objSize.left + length;
	objSize.bottom = objSize.top + length;
	Engine.GetGUIObjectByName(objectName).size = objSize;
}

function setEmbPos (objectName, x=0, y=0)
{
	var objSize = Engine.GetGUIObjectByName(objectName).size;
	var wid = objSize.right - objSize.left;
	objSize.left = x;
	objSize.top = y;
	Engine.GetGUIObjectByName(objectName).size = objSize;
	setEmbSize(objectName, wid);
}
