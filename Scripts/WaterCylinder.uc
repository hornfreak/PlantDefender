class WaterCylinder extends Actor placeable;

defaultproperties
{
	Begin Object Class=StaticMeshComponent Name=WaterMesh
		StaticMesh=StaticMesh'WN_Package.StaticMesh.SM_RainCylinder'
	End Object
	Components.Add(WaterMesh)
	
	bCollideActors=True
	bBlockActors=False
	CollisionType=COLLIDE_TouchAll
}
