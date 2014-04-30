class FireCosmos extends Actor
	placeable;

//variables ==========================================
var bool bTouchCheck;
var StaticMeshComponent FireCosmos;

//Size of the flower
var Float Size;

var float tempScale;

var bool IsFullyGrown;
var float maxSize;

//check to see if it is raining
var bool bStartGrowing;

var Turtle P; 



//functions=============================================

simulated event PostBeginPlay()
{
    Super.PostBeginPlay();
    Size = 1.0; 
	SetTimer(1, true, 'FireTimer');

}


event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{

    if(Other.IsA('CloudPawn')) 
    {
        if(IsFullyGrown == false)
        {
			bStartGrowing=true;
			//WorldInfo.Game.Broadcast(self, "bStartGrowing is true");
			bTouchCheck = true;
        }	
    }
}

event UnTouch(Actor Other)
{
	bStartGrowing=false;
	//WorldInfo.Game.Broadcast(self, "bStartGrowing is false");
}


Simulated function Tick(float DeltaTime)
{

	super.Tick(DeltaTime);

    maxSize = 3.0;
    
    if(bTouchCheck && size <= maxSize && bStartGrowing)
    {
		Size = Size + DeltaTime; //The speed at which the flower will grow

		FireCosmos.Setscale(size);


		//WorldInfo.Game.Broadcast(self, "Flower is growing");	
		
	
    }
}

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
}


function FireTimer ()
{
 
	 foreach OverlappingActors(class'Turtle', P, 5000.0, Location ) 
	 {
			//HurtRadius(500.0, 1000.0,class'DamageType', 0, Location);

			//P.TakeDamage(200, ???, P.Location , vect2d(0.0,0.0,0.0), class'DamageType');

			WorldInfo.Game.Broadcast(self, "Fire AOE @ Turtle!");
	 }
}




DefaultProperties
{
	begin object class=StaticMeshComponent Name=FireFlower
		StaticMesh=StaticMesh'ChristopherCustomMeshes.GroundCover.Mesh.CosmosFireFlower'
	end Object 

	FireCosmos= FireFlower

	Components.Add(FireFlower)

	bTouchCheck=False
    bCollideActors=True
    bBlockActors=False
    CollisionType=COLLIDE_TouchAll


}
