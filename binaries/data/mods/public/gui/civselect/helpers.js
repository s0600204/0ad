
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

function loadCultureData (civCodes)
{
	var cultureData = {};
	cultureData.nogroup = {
		"Name" : "Ungrouped",
		"Code" : "nogroup",
		"History" : "-",
		"civlist": []
	};
	
	for (let code of civCodes)
	{
		let civ = g_CivData[code];
		let grouped = false;
		let cultures = civ.Culture;
		if (typeof cultures === "string")
			cultures = [ cultures ];
		
		for (let culture of cultures)
		{
			if (cultureData[culture] === undefined)
			{
				let data = Engine.ReadJSONFile("simulation/data/civs/cultures/"+culture+".json");
				if (!data)
					continue;
				
				cultureData[culture] = data;
				cultureData[culture].civlist = [];
			}
			cultureData[culture].civlist.push(code);
			grouped = true;
		}
		if (!grouped)
			cultureData.nogroup.civlist.push(code);
	}
	return cultureData;
}

