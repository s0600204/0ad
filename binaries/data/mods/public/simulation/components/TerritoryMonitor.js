
function TerritoryMonitor() {}

TerritoryMonitor.prototype.Schema =
	"<a:component/><empty/>";

TerritoryMonitor.prototype.Init = function()
{
	this.CurrentTerritory = 0;
};

TerritoryMonitor.prototype.OnHealthChanged = function(msg)
{
	if (msg.to > 0)
		return;

	let cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);
	cmpTrigger.CallEvent("TerritoryBorderCrossed", {"entity": this.entity, "from": this.CurrentTerritory, "to": -1 });
};

TerritoryMonitor.prototype.OnPositionChanged = function(msg)
{
	if (!msg.inWorld)
		return;

	let cmpTerritoryManager = Engine.QueryInterface(SYSTEM_ENTITY, IID_TerritoryManager);
	let territoryOwner = cmpTerritoryManager.GetOwner(msg.x, msg.z);

	if (this.CurrentTerritory !== territoryOwner)
	{
		let cmpTrigger = Engine.QueryInterface(SYSTEM_ENTITY, IID_Trigger);
		cmpTrigger.CallEvent("TerritoryBorderCrossed", {"entity": this.entity, "from": this.CurrentTerritory, "to": territoryOwner });
	}
	this.CurrentTerritory = territoryOwner;
};

TerritoryMonitor.prototype.Serialize = null;

Engine.RegisterComponentType(IID_TerritoryMonitor, "TerritoryMonitor", TerritoryMonitor);

