class CloudPawn extends Pawn;

//new variables
var bool bTouchCheck;
var float myAmount;
var int stormAmount;
var int waterIncreaseAmount;
var bool bStartRegen;

//old variables
var Vector MeshTranslation;
var StaticMeshComponent RainAttachment;
var StaticMeshComponent CloudAttachment;
var float CamOffsetDistance; //distance to offset the camera from the player in unreal units
var float CamMinDistance, CamMaxDistance;
var float CamZoomTick; //how far to zoom in/out per command
var float CamHeight; //how high cam is relative to pawn pelvis
var StaticMeshComponent LightningAttachment;
var ParticleSystemComponent LightningHitAttachment;


//Functions

event PostBeginPlay()
{
	super.PostBeginPlay(); 
	SetPhysics(PHYS_Flying);
	`Log("Custom Pawn up"); //debug
	AddCloud();
	AddRain();
	AddLightning();
	Hide(RainAttachment, true);
	Hide(LightningAttachment,true);
}


simulated function AddCloud()
{
	CloudAttachment = new(self) class'StaticMeshComponent';
	
	MeshTranslation.Z = 350.0;
	CloudAttachment.SetTranslation(MeshTranslation);
	
	CloudAttachment.SetStaticMesh(StaticMesh'WN_Package.StaticMesh.SM_Cloud');
	AttachComponent(CloudAttachment);



}

exec function Hide(StaticMeshComponent component, bool Hidden)
{
	if(Hidden)
	{
		component.SetHidden(true);
		SetCollisionType(COLLIDE_NoCollision);
		`log("Cylinder should not be visible!");
	}
	else
	{
		component.SetHidden(false);
		SetCollisionType(COLLIDE_TouchAll);
		`Log("Cylinder should be visible!");
	}
}

simulated function AddLightning()
{
	LightningAttachment = new(self) class'StaticMeshComponent';
	
	//MeshTranslation.Z = 206.0;
	LightningAttachment.SetTranslation(MeshTranslation);
	
	LightningAttachment.SetStaticMesh(StaticMesh'WN_Package.StaticMesh.lightningbackup'); 
	AttachComponent(LightningAttachment);
}

simulated function AddRain()
{
	RainAttachment = new(self) class'StaticMeshComponent';
	
	MeshTranslation.Z = -50.0;
	RainAttachment.SetTranslation(MeshTranslation);
	
	RainAttachment.SetStaticMesh(StaticMesh'WN_Package.StaticMesh.SM_RainCylinder');
	AttachComponent(RainAttachment);
}


//only update pawn rotation while moving
simulated function FaceRotation(rotator NewRotation, float DeltaTime)
{
	// Do not update Pawn's rotation if no accel
	if (Normal(Acceleration)!=vect(0,0,0))
	{
		if ( Physics == PHYS_Ladder )
		{
			NewRotation = OnLadder.Walldir;
		}
		else if ( (Physics == PHYS_Walking) || (Physics == PHYS_Falling) || (Physics == PHYS_Flying) )
		{
			NewRotation = rotator((Location + Normal(Acceleration))-Location);
			NewRotation.Pitch = 0;
		}
		NewRotation = RLerp(Rotation,NewRotation,0.1,true);
		SetRotation(NewRotation);
	}
	
}

//orbit cam, follows player controller rotation
simulated function bool CalcCamera( float fDeltaTime, out vector out_CamLoc, out rotator out_CamRot, out float out_FOV )
{
	local vector HitLoc,HitNorm, End, Start, vecCamHeight;

	vecCamHeight = vect(0,0,0);
	vecCamHeight.Z = CamHeight;
	Start = Location;
	End = (Location+vecCamHeight)-(Vector(Controller.Rotation) * CamOffsetDistance);  //cam follow behind player controller
	out_CamLoc = End;

	//trace to check if cam running into wall/floor
	if(Trace(HitLoc,HitNorm,End,Start,false,vect(12,12,12))!=none)
	{
		out_CamLoc = HitLoc + vecCamHeight;
	}
	
	//camera will look slightly above player
   out_CamRot=rotator((Location + vecCamHeight) - out_CamLoc);
   return true;
}

function WaterTimer()
{
	if(myAmount > 0)
	{
		myAmount -= 5;
	}
}

function StrikeTimer()
{
	if(stormAmount > 0)
	{
		stormAmount -= 5;
	}
}

exec function Strike()
{
	if(stormAmount > 0)
	{
		stormAmount -= 1;
		Hide(LightningAttachment,false);
		WorldInfo.Game.Broadcast(self, "Strike Fired!");
		SetTimer(0.5, true, 'StrikeTimer');
	}
}

exec function StopStrike()
{
	Hide(LightningAttachment,true);
	WorldInfo.Game.Broadcast(self, "StopStrike Fired!"); 
	ClearTimer('StrikeTimer');
}

exec function Water()
{
	if(myAmount > 0)
	{
		myAmount -= 5;
		Hide(RainAttachment, false);
		`Log("Water is fired!");
		SetTimer(1, true, 'WaterTimer');
	}
}

exec function StopWater()
{
	Hide(RainAttachment, true);
	`Log("StopeWater is fired!");
	ClearTimer('WaterTimer');
}

/*
//New function that dictates cloud water regen =================================
exec function RegenWater()
{
	if(CloudController(Controller).bCanSuckWater)
	{
		waterRegen(55);
	}	
}

//water regeneration function =======================================
function waterRegen(int increastAmount)
{
	myAmount += increastAmount;
}

*/

//function checks to see if PC bool is true, then starts water regen
exec function RegenWater()
{
	if(CloudController(Controller).bCanSuckWater == true)
	{
		bStartRegen = true;
		WorldInfo.Game.Broadcast(self, "bStartRegen has been set to true!");
	}  
	else
	{
		bStartRegen = false;
	}
}
//timer that dictates amount of water thats regenerated over time
simulated event Tick (float DeltaTime)
{
	
	super.Tick(DeltaTime);

	//check to see if bool is true and amount isn't maxed out
	if(CloudController(Controller).bCanSuckWater && myAmount < 200)
	{
		myAmount += (DeltaTime * waterIncreaseAmount);
		//WorldInfo.Game.Broadcast(self, "myAmount is increasing!!");
        
	}

}

defaultproperties
{
	ViewPitchMin=-7000
	ViewPitchMax=1000
	CamHeight = 150.0 // was 40
	CamMinDistance = 150.0 //was 40
	CamMaxDistance = 350.0
	CamOffsetDistance=750.0 // was 500
	CamZoomTick=20.0

	//Initial amount of water
	myAmount = 100;
	stormAmount= 5;
	waterIncreaseAmount = 50;

	
	//Sets players state to constantly fly
	LandMovementState=PlayerFlying

	Begin Object Class=DecalComponent Name=CloudShadowDecalComponent
		DecalTransform=DecalTransform_OwnerRelative
		ParentRelativeOrientation=(Pitch=-16384,Yaw=-16384,Roll=0)
		DecalMaterial=DecalMaterial'WN_Package.Materials.CoolCloudDecal_001'
		Translation=(X=0,Y=0,Z=0)
		ParentRelativeLocation=(X=0,Y=0,Z=0)
		bMovableDecal=true
		bStaticDecal=false
		bNoclip=true
		bProjectOnTerrain=true
		bProjectOnSkeletalMeshes=true
		bProjectOnStaticMeshes=true
		bProjectOnBSP=true
	End Object
	Components.Add(CloudShadowDecalComponent)
	


	
}
	
	