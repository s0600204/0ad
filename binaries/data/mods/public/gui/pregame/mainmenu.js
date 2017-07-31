/**
 * Available backgrounds, added by the files in backgrounds/.
 */
var g_BackgroundLayerData = [];

/**
 * This is the handler that coordinates all other handlers.
 */
var g_MainMenuPage;

function init(data, hotloadData)
{
	g_MainMenuPage =
		new MainMenuPage(
			data,
			hotloadData,
			g_MainMenuItems,
			g_BackgroundLayerData,
			g_ProjectInformation,
			g_CommunityButtons);


	let tstCt = [ "blue", "red", "purple", "cyan", "rainbow", "tartan", "plaid", "brown", "black", "grey", "gray", "pink", "green", "magenta", "taupe", "mauve", "pecan", "orange" ];
	let tstDd = Engine.GetGUIObjectByName("testDrop");
	tstDd.list = tstCt;
	tstDd.selected = 2;

	let tstLt = Engine.GetGUIObjectByName("testList");
	tstLt.list = tstCt;
	tstLt.selected = 4;

	let tstOLt = Engine.GetGUIObjectByName("testOList");
	tstOLt.list_name = tstCt;
	tstOLt.list_a = tstCt;
	tstOLt.list_b = tstCt.reverse();
	tstOLt.list = tstCt;
	tstOLt.selected = 1;

	let tstTxt = Engine.GetGUIObjectByName("testTextbox").caption;
	let tstTB = Engine.GetGUIObjectByName("testTextboxScrollable");
	for (let i=0; i<3; ++i)
		tstTB.caption += '[font="sans-bold-12"]Scrollable [/font]' + tstTxt + "\n\n";

	let tstML = Engine.GetGUIObjectByName("testInputMultiline");
	for (let i=0; i<24; ++i)
		tstML.caption += "\n.";
	tstML.caption += "\nGroovy, baby!";
}

function getHotloadData()
{
	return g_MainMenuPage.getHotloadData();
}
