class WindPhysicsVolume extends ForcedDirVolume;

simulated event Touch(Actor Other, PrimitiveComponent OtherComp, Vector HitLocation, Vector HitNormal)
{
	super.Touch(Other, OtherComp, HitLocation, HitNormal);
	`log("Volume: Touched");
	

}

DefaultProperties
{
	//actor props
	bStatic=false
	bNoDelete=false
	bCollideActors=true
	bCollideAsEncroacher=false
	Physics=PHYS_None
	bNoEncroachCheck=false
	CollisionType=COLLIDE_TouchAll	
	//collision primitives
	Begin Object Class=RB_RadialImpulseComponent Name=CollisionSphere
		AlwaysCheckCollision=true
		CollideActors=true
		ImpulseRadius=300
		ImpulseStrength=0
	End Object
	Components.Add(CollisionSphere)
	CollisionComponent=CollisionSphere
	//for debugging
	begin object class=DrawSphereComponent name=DrawSphere
		SphereRadius=300
		bDrawWireSphere=false
		HiddenGame=false
		HiddenEditor=false
		bIgnoreOwnerHidden=false
	end object
	Components.Add(DrawSphere)

	bCanStepUpOn=false
	ZoneVelocity=(50,100,0)
	bVelocityAffectsWalking=false
}
