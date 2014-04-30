class Cloud extends Actor;


defaultproperties
{
	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
        bEnabled=TRUE
		bCastShadows=false
    End Object
    Components.Add(MyLightEnvironment)
	
	Begin Object Class=StaticMeshComponent Name=CloudMesh
		StaticMesh=StaticMesh'WN_Package.StaticMesh.SM_Cloud'
	End Object
	Components.Add(CloudMesh)
}
