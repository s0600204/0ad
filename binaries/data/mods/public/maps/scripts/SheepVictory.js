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
	this.CheckSheepVictory("border");
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

	this.CheckSheepVictory("capture");

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

	// If no sheep on map
	if (!sheepEntities.length)
		return;

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
	cmpTrigger.RegisterTrigger("OnDiplomacyChanged", "CalculateMutualAllyGroups", { "enabled": true });

	this.CalculateMutualAllyGroups();
};

/**
 * This unholy piece of code works out any groups of mutual allies, permitting said groups to be arbitrary.
 * Teams are ignored due to there being no guarantee of being locked.
 * It is possible for a player to be in more than one group. Hence the complexity.
 */
Trigger.prototype.CalculateMutualAllyGroups = function()
{
	let cmpPlayerManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager);
	let numPlayers = cmpPlayerManager.GetNumPlayers();

	// Caching Object, used to reduce calls to Engine.QueryInterface
	let mutualAllyMatrix = {};
	for (let i = 1; i < numPlayers; ++i)
		mutualAllyMatrix[i] = Engine.QueryInterface(cmpPlayerManager.GetPlayerByID(i), IID_Player).GetMutualAllies();

	let allyGroups = {};

	for (let player = 1; player < numPlayers; ++player)
	{
		let mutualAlliesOfPlayer = mutualAllyMatrix[player];

		allyGroups[player.toString()] = [player];

		for (let ally of mutualAlliesOfPlayer)
		{
			if (ally == player) // If self
				continue;

			let mutualAlliesOfMutualAlly = mutualAllyMatrix[ally];
			let grp = mutualAlliesOfMutualAlly.filter(allyOfAlly => {

					if (mutualAlliesOfPlayer.indexOf(allyOfAlly) == -1)
						return false;

					return mutualAlliesOfMutualAlly.every(x => mutualAlliesOfPlayer.indexOf(x) == -1 || mutualAllyMatrix[x].indexOf(allyOfAlly) > -1);

				});

			let key = grp.toString();
			
			if (!allyGroups[key])
				allyGroups[key] = grp;
		}
	}
	this.mutualAllyGroups = Object.keys(allyGroups).map(key => allyGroups[key]);

	this.CheckSheepVictory("diplomacy");
}

Trigger.prototype.CancelSheepTimers = function()
{
	if (!this.sheepVictoryTimers.length)
		return;

	let cmpTimer = Engine.QueryInterface(SYSTEM_ENTITY, IID_Timer);
	for (let timer of this.sheepVictoryTimers)
		cmpTimer.CancelTimer(timer);

	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);
	cmpGuiInterface.DeleteTimeNotification(this.sheepVictoryMessages.ownMessage);
	cmpGuiInterface.DeleteTimeNotification(this.sheepVictoryMessages.otherMessage);
}

/**
 * @param reason Reason for checking for victory. Only really has an effect if the diplomacy has been changed.
 * @todo Disable triggers after win/lose.
 */
Trigger.prototype.CheckSheepVictory = function(reason = null)
{
	let sheepTotal = 0;
	for (let p in this.sheepCountByPlayer)
		sheepTotal += this.sheepCountByPlayer[p].entitiesOwned.length;

	let groupTotals = [];
	let successfulGroup = -1;
	for (let group in this.mutualAllyGroups)
	{
		let totals = {
			"owned": 0,
			"inTerritory": 0
		};
		for (let player of this.mutualAllyGroups[group])
		{
			totals.owned += this.sheepCountByPlayer[player].entitiesOwned.length;
			totals.inTerritory += this.sheepCountByPlayer[player].entitiesInTerritory.length;
		}
		groupTotals.push(totals);

		if (totals.owned == sheepTotal)
			successfulGroup = group;
	}

	if (successfulGroup === -1)
	{
		this.CancelSheepTimers();
		this.lastSuccessfulGroup = -1;
		return;
	}

	let cmpGuiInterface = Engine.QueryInterface(SYSTEM_ENTITY, IID_GuiInterface);

	// Only display the following message if
	// * not all the sheep are in the successful group's shared territory, 
	// * and only if they've only just become the successful group (so we only get the message once, and not repeatedly)
	if (groupTotals[successfulGroup].inTerritory < sheepTotal)
	{
		if (successfulGroup != this.lastSuccessfulGroup)
		{
			cmpGuiInterface.PushNotification({
				"message": "%(_playerlist_)s have captured all the sheep, and only need to bring them to their territory!",
				"translateParameters": ["_playerlist_"],
				"parameters": {
					"_playerlist_": this.mutualAllyGroups[successfulGroup]
				}
			});
			this.lastSuccessfulGroup = successfulGroup;
		}

		this.CancelSheepTimers();
		return;
	}

	// If diplomacy changes, but the group stays the same, don't reset timers.
	if (reason == "diplomacy" && successfulGroup == this.lastSuccessfulGroup)
		return;

	this.lastSuccessfulGroup = successfulGroup;
	this.CancelSheepTimers();

	// Create new messages, and start timer to register defeat.
	let cmpPlayerManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_PlayerManager);
	let numPlayers = cmpPlayerManager.GetNumPlayers();

	// Add -1 to notify observers too
	let unsuccessfulPlayers = [-1];
	for (let i = 1; i < numPlayers; ++i)
		if (this.mutualAllyGroups[successfulGroup].indexOf(i) < 0)
			unsuccessfulPlayers.push(i);

	let cmpEndGameManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_EndGameManager);
	let sheepDuration = cmpEndGameManager.GetGameTypeSettings().wonderDuration || 30 * 1000;

	this.sheepVictoryMessages.otherMessage = cmpGuiInterface.AddTimeNotification({
		"message": markForTranslation("%(_playerlist_)s will win a wool-lined victory in %(time)s!"),
		"players": unsuccessfulPlayers,
		"translateParameters": ["_playerlist_"],
		"parameters": {
			"_playerlist_": this.mutualAllyGroups[successfulGroup]
		},
		"translateMessage": true
	}, sheepDuration);

	this.sheepVictoryMessages.ownMessage = cmpGuiInterface.AddTimeNotification({
		"message": markForTranslation("Look after your sheep, and you will win in %(time)s"),
		"players": this.mutualAllyGroups[successfulGroup],
		"translateMessage": true,
	}, sheepDuration);

	// Defeats all players not in the successful group. As the remaining players are all allied together, this causes a win state.
	let cmpTimer = Engine.QueryInterface(SYSTEM_ENTITY, IID_Timer);
	for (let player of unsuccessfulPlayers)
		if (this.sheepCountByPlayer[player])
			this.sheepVictoryTimers.push(cmpTimer.SetTimeout(this.sheepCountByPlayer[player].player, IID_Player, "SetState", sheepDuration, "defeated"));
};

var cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);

cmpTrigger.sheepVictoryTimers = [];
cmpTrigger.sheepVictoryMessages = {};
cmpTrigger.sheepCountByPlayer = {};
cmpTrigger.mutualAllyGroups = [];
cmpTrigger.lastSuccessfulGroup = -1;

cmpTrigger.DoAfterDelay(0, "GameStartSheepCount", null);
