Trigger.prototype.SheepCaptureMessages = {
	"fromGaia": [
		"%(_player_to)s found a sheep a-wandering",
		"%(_player_to)s gave a sheep a new home",
		"%(_player_to)s located a sheep",
		"%(_player_to)s gains a *baa*ing bundle of wool",
	],
	"fromPlayer": [
		"%(_player_to)s stole a sheep from %(_player_from)s",
		"%(_player_to)s rustled a sheep from %(_player_from)s",
		"%(_player_to)s nicked a sheep from %(_player_from)s",
		"%(_player_to)s \"borrowed\" a sheep from %(_player_from)s",
		"%(_player_to)s saved a sheep from the cruelty of %(_player_from)s",
		"%(_player_to)s took advantage of the weary shepherds of %(_player_from)s",
		"%(_player_to)s sneakily pinched a sheep from the flock of %(_player_from)s",
	]
};

Trigger.prototype.IsFlagSheep = function(entity)
{
	return TriggerHelper.EntityHasClass(entity, "Sheep") && TriggerHelper.EntityHasClass(entity, "Flag");
};

Trigger.prototype.IsSheep = function(entity)
{
	return TriggerHelper.EntityHasClass(entity, "Sheep");
}

Trigger.prototype.OnSheepCapture = function(data)
{
	if (!this.IsFlagSheep(data.entity))
		return;

	if (data.to > -1)
		this.sheepCountByPlayer[data.to].entities.push(data.entity);

	if (data.from > -1)
	{
		let pos = this.sheepCountByPlayer[data.from].entities.indexOf(data.entity);
		this.sheepCountByPlayer[data.from].entities.splice(pos, 1);
	}

	// If sheep killed/reincarnated
	if (data.to === -1 || data.from === -1)
		return;

	let msgs = [];
	if (data.from === 0)
		msgs = this.SheepCaptureMessages.fromGaia;
	else if (data.to > 0)
		msgs = this.SheepCaptureMessages.fromPlayer;

	if (!msgs.length)
		return;

	this.StatusReport();

	let rndIdx = Math.floor(Math.random() * msgs.length);
	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);
	cmpGuiInterface.PushNotification({
		"message": msgs[rndIdx],
		"type": "aichat",
		"translateMessage": true,
		"translateParameters": ["_player_from", "_player_to"],
		"parameters": {
			"_player_from": data.from,
			"_player_to": data.to
		},
		"players": [0]
	});
};

Trigger.prototype.StatusReport = function()
{
	let msg = [];
	for (let p in this.sheepCountByPlayer)
	{
		let cmpPlayer = Engine.QueryInterface(this.sheepCountByPlayer[p].player, IID_Player);
		let playerColor = cmpPlayer.GetColor();
		msg.push(sprintf("[color=\"%(color)s\"]%(player)s[/color]: %(count)s", {
			"player": cmpPlayer.GetName(),
			"count": this.sheepCountByPlayer[p].entities.length,
			"color": this.ColorRectifier(playerColor.r) + " " + this.ColorRectifier(playerColor.g) + " " + this.ColorRectifier(playerColor.b)
		}));
	}

	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);
	cmpGuiInterface.PushNotification({
		"message": msg.join(" - ")
	});
};

Trigger.prototype.ColorRectifier = function(clr)
{
	return Math.round(clr * 255);
};

Trigger.prototype.GameStartSheepCount = function()
{
	let cmpRangeManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_RangeManager);
	let cmpPlayerManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager);

	cmpPlayerManager.GetAllPlayerEntities().forEach((elem, i) => {
		let ents = [];
		for (let ent of cmpRangeManager.GetEntitiesByPlayer(i))
		{
			if (this.IsFlagSheep(ent))
				ents.push(ent);
			else if (this.IsSheep(ent))
				ents.push(TriggerHelper.ReplaceEntity(ent, "other/flag_sheep"));
		}
		this.sheepCountByPlayer[i] = {
			"player": elem,
			"entities": ents
		};
	});

	this.StatusReport();
	var cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);
	cmpTrigger.RegisterTrigger("OnOwnershipChanged", "OnSheepCapture", { "enabled": true });
};

Trigger.prototype.CheckSheepVictory = function(data)
{
	let ent = data.entity;
	let cmpWonder = Engine.QueryInterface(ent, IID_Wonder);
	if (!cmpWonder)
		return;

	let timer = this.sheepVictoryTimers[ent];
	let messages = this.sheepVictoryMessages[ent] || {};

	let cmpTimer = Engine.QueryInterface(SYSTEM_ENTITY, IID_Timer);
	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);

	if (timer)
	{
		cmpTimer.CancelTimer(timer);
		cmpGuiInterface.DeleteTimeNotification(messages.ownMessage);
		cmpGuiInterface.DeleteTimeNotification(messages.otherMessage);
	}

	if (data.to <= 0)
		return;

	// Create new messages, and start timer to register defeat.
	let cmpPlayerManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager);
	let numPlayers = cmpPlayerManager.GetNumPlayers();

	// Add -1 to notify observers too
	let players = [-1];
	for (let i = 1; i < numPlayers; ++i)
		if (i != data.to)
			players.push(i);

	let cmpPlayer = QueryOwnerInterface(ent, IID_Player);
	let cmpEndGameManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_EndGameManager);
	let sheepDuration = cmpEndGameManager.GetGameTypeSettings().sheepDuration || 20 * 60 * 1000;

	messages.otherMessage = cmpGuiInterface.AddTimeNotification({
		"message": markForTranslation("%(player)s will have won in %(time)s"),
		"players": players,
		"parameters": {
			"player": cmpPlayer.GetName()
		},
		"translateMessage": true,
		"translateParameters": [],
	}, sheepDuration);

	messages.ownMessage = cmpGuiInterface.AddTimeNotification({
		"message": markForTranslation("You will have won in %(time)s"),
		"players": [data.to],
		"translateMessage": true,
	}, sheepDuration);

	timer = cmpTimer.SetTimeout(SYSTEM_ENTITY, IID_EndGameManager,
		"MarkPlayerAsWon", sheepDuration, data.to);

	this.wonderVictoryTimers[ent] = timer;
	this.wonderVictoryMessages[ent] = messages;
};

var cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);

//cmpTrigger.RegisterTrigger("OnOwnershipChanged", "CheckSheepVictory", { "enabled": true });
cmpTrigger.sheepVictoryTimers = {};
cmpTrigger.sheepVictoryMessages = {};
cmpTrigger.sheepCountByPlayer = {};

cmpTrigger.DoAfterDelay(0, "GameStartSheepCount", null);
