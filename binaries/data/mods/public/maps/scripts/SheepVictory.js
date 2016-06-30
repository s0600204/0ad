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

Trigger.prototype.TotalSheepCount = function()
{
	let sheepTotal = 0;
	for (let p in this.sheepCountByPlayer)
		sheepTotal += this.sheepCountByPlayer[p].entitiesOwned.length;
	return sheepTotal;
};

Trigger.prototype.OnSheepCrossTerritoryBorder = function(data)
{
	if (!this.IsFlagSheep(data.entity))
		return;

	if (data.to > -1)
		this.sheepCountByPlayer[data.to].entitiesInTerritory.push(data.entity);

	if (data.from > -1)
	{
		let pos = this.sheepCountByPlayer[data.from].entitiesInTerritory.indexOf(data.entity);
		this.sheepCountByPlayer[data.from].entitiesInTerritory.splice(pos, 1);
	}

	this.StatusReport();
	this.CheckSheepVictory();
};

Trigger.prototype.OnSheepCapture = function(data)
{
	if (!this.IsFlagSheep(data.entity))
		return;

	if (data.to > -1)
		this.sheepCountByPlayer[data.to].entitiesOwned.push(data.entity);

	if (data.from > -1)
	{
		let pos = this.sheepCountByPlayer[data.from].entitiesOwned.indexOf(data.entity);
		this.sheepCountByPlayer[data.from].entitiesOwned.splice(pos, 1);
	}

	this.CheckSheepVictory();

	// If sheep killed/created. Shouldn't ever happen, but just in case...
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

/**
 * Currently used for debugging, and returned early to bypass for now. Might be altered to be of use later.
 */
Trigger.prototype.StatusReport = function()
{
	return;

	let msg = [];
	let ColorRectifier = clr => Math.round(clr * 255);

	for (let p in this.sheepCountByPlayer)
	{
		let cmpPlayer = Engine.QueryInterface(this.sheepCountByPlayer[p].player, IID_Player);
		let playerColor = cmpPlayer.GetColor();
		msg.push(sprintf("[color=\"%(color)s\"]%(player)s[/color]: %(count)s (%(count2)s)", {
			"player": cmpPlayer.GetName(),
			"count": this.sheepCountByPlayer[p].entitiesOwned.length,
			"count2": this.sheepCountByPlayer[p].entitiesInTerritory.length,
			"color": ColorRectifier(playerColor.r) + " " + ColorRectifier(playerColor.g) + " " + ColorRectifier(playerColor.b)
		}));
	}

	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);
	cmpGuiInterface.PushNotification({
		"message": msg.join(" - ")
	});
};

Trigger.prototype.GameStartSheepCount = function()
{
	let cmpRangeManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_RangeManager);
	let cmpPlayerManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager);
	let cmpTerritoryManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_TerritoryManager);

	let sheepEntities = [];

	for (let i = 0; i < Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager).GetNumPlayers(); ++i)
	{
		for (let ent of cmpRangeManager.GetEntitiesByPlayer(i))
		{
			if (!this.IsSheep(ent))
				continue;

			if (!this.IsFlagSheep(ent))
				ent = TriggerHelper.ReplaceEntity(ent, "other/flag_sheep");

			let cmpDamageReceiver = Engine.QueryInterface(ent, IID_DamageReceiver);
			cmpDamageReceiver.SetInvulnerability(true);

			sheepEntities.push(ent);
		}

		this.sheepCountByPlayer[i] = {
			"player": cmpPlayerManager.GetPlayerByID(i),
			"entitiesOwned": [],
			"entitiesInTerritory": []
		};
	}

	for (let ent of sheepEntities)
	{
		let cmpPosition = Engine.QueryInterface(ent, IID_Position);
		let pos = cmpPosition.GetPosition();
		let terrOwner = cmpTerritoryManager.GetOwner(pos.x, pos.z);
		this.sheepCountByPlayer[terrOwner].entitiesInTerritory.push(ent);

		let cmpOwnership = Engine.QueryInterface(ent, IID_Ownership);
		let currOwner = cmpOwnership.GetOwner();
		if (currOwner > 0)
			this.sheepCountByPlayer[currOwner].entitiesOwned.push(ent);
		else
		{
			if (terrOwner != 0)
				cmpOwnership.SetOwner(terrOwner);
			this.sheepCountByPlayer[terrOwner].entitiesOwned.push(ent);
		}
	}

	this.StatusReport();

	let cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);
	cmpTrigger.RegisterTrigger("OnTerritoryBorderCrossed", "OnSheepCrossTerritoryBorder", { "enabled": true });
	cmpTrigger.RegisterTrigger("OnOwnershipChanged", "OnSheepCapture", { "enabled": true });

	this.CheckSheepVictory();
};

/**
 * 
 * @todo Support for teams
 * @todo Notify players when a player has all the sheep, but has yet to bring them to their territory
 */
Trigger.prototype.CheckSheepVictory = function()
{
	let cmpTimer = Engine.QueryInterface(SYSTEM_ENTITY, IID_Timer);
	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);

	if (this.sheepVictoryTimer)
	{
		cmpTimer.CancelTimer(this.sheepVictoryTimer);
		cmpGuiInterface.DeleteTimeNotification(this.sheepVictoryMessages.ownMessage);
		cmpGuiInterface.DeleteTimeNotification(this.sheepVictoryMessages.otherMessage);
	}

	let sheepTotal = 0;
	for (let p in this.sheepCountByPlayer)
		sheepTotal += this.sheepCountByPlayer[p].entitiesOwned.length;

	let player = -1;
	for (let p in this.sheepCountByPlayer)
		if (this.sheepCountByPlayer[p].entitiesOwned.length == sheepTotal)
			player = +p;

	if (player < 1 || this.sheepCountByPlayer[player].entitiesInTerritory.length < sheepTotal)
		return;

	// Create new messages, and start timer to register defeat.
	let cmpPlayerManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager);
	let numPlayers = cmpPlayerManager.GetNumPlayers();

	// Add -1 to notify observers too
	let players = [-1];
	for (let i = 1; i < numPlayers; ++i)
		if (i != player)
			players.push(i);

	let cmpPlayer = Engine.QueryInterface(this.sheepCountByPlayer[player].player, IID_Player);
	let cmpEndGameManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_EndGameManager);
	let sheepDuration = cmpEndGameManager.GetGameTypeSettings().wonderDuration || 60 * 1000;

	this.sheepVictoryMessages.otherMessage = cmpGuiInterface.AddTimeNotification({
		"message": markForTranslation("%(player)s will win a wool-lined victory in %(time)s!"),
		"players": players,
		"parameters": {
			"player": cmpPlayer.GetName()
		},
		"translateMessage": true,
		"translateParameters": [],
	}, sheepDuration);

	this.sheepVictoryMessages.ownMessage = cmpGuiInterface.AddTimeNotification({
		"message": markForTranslation("Look after your sheep, and you will win in %(time)s"),
		"players": [player],
		"translateMessage": true,
	}, sheepDuration);

	this.sheepVictoryTimer = cmpTimer.SetTimeout(SYSTEM_ENTITY, IID_EndGameManager,
		"MarkPlayerAsWon", sheepDuration, player);
};

var cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);

cmpTrigger.sheepVictoryTimer = undefined;
cmpTrigger.sheepVictoryMessages = {};
cmpTrigger.sheepCountByPlayer = {};

cmpTrigger.DoAfterDelay(0, "GameStartSheepCount", null);
