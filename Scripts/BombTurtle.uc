class BombTurtle extends Turtle;

event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	if (Health - Damage < 0)
	{
		Destroy();
		WorldInfo.Game.Broadcast(self, "BombTurtle is Dead!");
	}
	else
	{
		PlaySound(SoundCue'KismetGame_Assets.Sounds.Turtle_Death_Cue');
		Super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	}
}
defaultproperties
{
	GroundSpeed=+075.0000
	
	ControllerClass=class'TurtleAI' 
	
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0010.000000
		BlockZeroExtent=FALSE
	End Object
	
	Components.Remove(NanoPawnMesh)
	
	Begin Object Class=SkeletalMeshComponent Name=TurtleBombMesh
	SkeletalMesh=SkeletalMesh'KismetGame_Assets.Anims.SK_TurtleBomb_01'
	AnimSets(0)=AnimSet'KismetGame_Assets.Anims.SK_TurtleBomb_01_Anims'
	AnimTreeTemplate=AnimTree'KismetGame_Assets.Anims.TurtleBomb_AnimTree'
	BlockZeroExtent=TRUE
	BlockNonZeroExtent=TRUE
	CollideActors=TRUE
	BlockRigidBody=TRUE
	RBChannel=RBCC_Pawn
	RBCollideWithChannels=(Default=TRUE,Pawn=TRUE,DeadPawn=TRUE,BlockingVolume=TRUE,EffectPhysics=TRUE,FracturedMeshPart=TRUE,SoftBody=TRUE)
	bIgnoreControllersWhenNotRendered=TRUE
	End Object
	Mesh=TurtleBombMesh
	Components.Add(TurtleBombMesh)
}