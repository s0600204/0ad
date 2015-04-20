
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

function gridArrayRepeatedObjects (basename, splitvar, limit, vMargin)
{
	basename = basename.split("["+splitvar+"]", 2);
	var firstObj = Engine.GetGUIObjectByName(basename.join("[0]"));
	
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
	
	var i = 0;
	for (let r = 0; r < Math.floor(limit/rowLength); ++r)
	{
		for (let c = 0; c < rowLength	; ++c)
		{
			let newSize = new GUISize();
			newSize.left = c * child.width + hMargin;
			newSize.right = (c+1) * child.width;
			newSize.top = r * child.height + vMargin;
			newSize.bottom = (r+1) * child.height;
			Engine.GetGUIObjectByName(basename.join("["+ i++ +"]")).size = newSize;
		}
	}
	
	
}

