// extend UIEvent if this event should be UI Kismet Event instead of a Level Kismet Event
class FlowerTurret extends SequenceEvent;


event activated()
{
	`log("It Must Have Worked");
}

defaultproperties
{
	ObjName="FlowerTurret"
	ObjCategory="WateringNature Events"

	OutputLinks.empty
	OutputLinks(0) = (LinkDesc = "FullyGrown")

	MaxTriggerCount = 0
	bPlayerOnly = false
	bAutoActivateOutputLinks = false
}
