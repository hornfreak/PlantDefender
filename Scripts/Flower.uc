class Flower extends Pawn
    placeable;

var bool bTouchCheck;
var StaticMeshComponent Flower;
var Float Size; //Size of the flower
var float tempScale;
var bool IsFullyGrown;
var float maxSize;

var bool bStartGrowing;

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    Size = 1.0;
}


event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{

    if(Other.IsA('CloudPawn')) 
    {
        if(IsFullyGrown == false)
        {
			bStartGrowing=true;
			WorldInfo.Game.Broadcast(self, "bStartGrowing is true");
			bTouchCheck = true;
        }
    }
}

event UnTouch(Actor Other)
{
	bStartGrowing=false;
	WorldInfo.Game.Broadcast(self, "bStartGrowing is false");
}


Simulated function Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

    maxSize = 3.0;
    
    if(bTouchCheck && size <= maxSize && bStartGrowing)
    {
		Size = Size + DeltaTime; //The speed at which the flower will grow

		Flower.Setscale(size);
        
		if(size == maxSize)
		{
			Health = 100;
			shutdown();
		}
	
    }
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if (Health - Damage < 0)
	{
		Destroy();
		WorldInfo.Game.Broadcast(self, "Flower is Dead!");
	}
	else
	{
		PlaySound(SoundCue'KismetGame_Assets.Sounds.Turtle_Death_Cue');
		Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	}
}
 
defaultproperties
{
    
    Begin Object Class=StaticMeshComponent Name=FlowerMesh
        StaticMesh=StaticMesh'WN_Package.StaticMesh.SM_Flower_01'
    End Object
    
    Flower = FlowerMesh
    
    Components.Add(FlowerMesh)
    
    bTouchCheck=False
    bCollideActors=True
    bBlockActors=False
    CollisionType=COLLIDE_TouchAll
	Health=25
}
