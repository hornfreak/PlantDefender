class Snake extends Pawn placeable;


defaultproperties
{
	Begin Object Name=CollisionCylinder
		CollisionRadius=+0034.000000
		CollisionHeight=+0034.000000
		BlockZeroExtent=FALSE
	End Object
	
	Components.Remove(Sprite)
	
	Begin Object Class=SkeletalMeshComponent Name=NanoPawnMesh
	SkeletalMesh=SkeletalMesh'KismetGame_Assets.Anims.SK_Snake'
	AnimSets(0)=AnimSet'KismetGame_Assets.Anims.SK_Snake_Anims'
	AnimTreeTemplate=AnimTree'KismetGame_Assets.Anims.Snake_AnimTree'
	BlockZeroExtent=TRUE
	BlockNonZeroExtent=TRUE
	CollideActors=TRUE
	BlockRigidBody=TRUE
	RBChannel=RBCC_Pawn
	RBCollideWithChannels=(Default=TRUE,Pawn=TRUE,DeadPawn=TRUE,BlockingVolume=TRUE,EffectPhysics=TRUE,FracturedMeshPart=TRUE,SoftBody=TRUE)
	bIgnoreControllersWhenNotRendered=TRUE
	End Object
	Mesh=NanoPawnMesh
	Components.Add(NanoPawnMesh)
}
