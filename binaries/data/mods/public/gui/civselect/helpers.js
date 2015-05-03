
/**
 * Horizontally spaces objects repeated with the `<repeat>` tag
 * @param basename The base name of the object, such as "object[n]" or "object[a]_sub[b]"
 * @param splitvar The var identifying the repeat count, without the square brackets
 * @param limit The number of the objects
 * @param margin The gap, in px, between the repeated objects
 */
function horizSpaceRepeatedObjects (basename, splitvar, limit, margin)
{
	basename = basename.split("["+splitvar+"]", 2);
	for (let c = 0; c < limit; ++c)
	{
		let objObj = Engine.GetGUIObjectByName(basename.join("["+c+"]"));
		let objSize = objObj.size;
		let objWidth = objSize.right - objSize.left;
		objSize.left = c * (objWidth + margin) + margin;
		objSize.right = (c+1) * (objWidth + margin);
		objObj.size = objSize;
	}
}

function gridArrayRepeatedObjects (basename, splitvar, limit, vMargin, vOffset = 0)
{
	if (typeof limit === "number")
		limit = [0, (limit-1), limit];
	else
		limit[2] = limit[1] - limit[0] + 1;
	
	basename = basename.split("["+splitvar+"]", 2);
	var firstObj = Engine.GetGUIObjectByName(basename.join("["+limit[0]+"]"));
	
	var child = firstObj.getComputedSize();
	child.width = child.right - child.left;
	child.height = child.bottom - child.top;
	
	var parent = firstObj.parent.getComputedSize();
	parent.width = parent.right - parent.left;
	
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
			newSize.left = c * child.width + hMargin;
			newSize.right = (c+1) * child.width;
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
