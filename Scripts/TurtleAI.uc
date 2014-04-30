class TurtleAI extends AIController;

var Pawn CurrentGoal;

var Vector TempDest;

var bool bResetMove;

var float TurretDistThreshold;

var AnimNodeSlot anim;

var ParticleSystem DeathEmitter;

var Vector Eh;

event Possess(Pawn inPawn, bool bVehicleTransition)
{
    super.Possess(inPawn, bVehicleTransition);
    Pawn.SetMovementPhysics();
}

function Pawn GetNearestFlower()
{
	local Pawn tmp;
	local Pawn ret;
	local float Distance;
	local float tmpDistance;
	
	ret = None;
	Distance  = 1000000.0;
	
	foreach AllActors(class'Pawn', tmp)
	{
		if(tmp.isa('Flower') == true)
		{
			tmpDistance = VSize(tmp.Location - Pawn.Location);
			if(tmpDistance < Distance){
				Distance = tmpDistance;
				ret = tmp;
			}
		}
		else if(tmp.IsA('MU_AutoTurret2') == true)
		{
			tmpDistance = VSize(tmp.Location - Pawn.Location);
			if(tmpDistance < Distance){
				Distance = tmpDistance;
				ret = tmp;
			}
		}
	}
	
	return ret;
}

auto state Idle
{
	function FindNewGoal()
	{
		if(Pawn == None)
			return;

		CurrentGoal = GetNearestFlower();
	}
	
	function bool HasReachedGoal()
	{
		local float dist;
		if(Pawn == none)
			return false;
		
		dist = VSize(CurrentGoal.Location - Pawn.Location);
		if(dist < 100)
		{	
			`log('HasReachedGoal dist true');
			return true;
		}
		else
		{
			`log('HasReachedGoal dist false');
			`Log(dist);
		}
		return false;
	}
	
	Begin:
	
	if(CurrentGoal == None || HasReachedGoal())
	{
		if(CurrentGoal != None){
			if(Pawn.IsA('BombTurtle'))
			{
				PlaySound(SoundCue'A_Weapon_ShockRifle.Cue.A_Weapon_SR_ComboExplosionCue');
				WorldInfo.MyEmitterPool.SpawnEmitter(DeathEmitter, Pawn.Location);
				HurtRadius(500, 128, class'DamageType', 0, Location);
				Pawn.Destroy();
			}
			else
			{
				CurrentGoal.TakeDamage(25, self, CurrentGoal.Location, vect(0.0,0.0,0.0), class'DamageType');
				WorldInfo.Game.Broadcast(self, "Hit!"); 
			}
		}
		FindNewGoal();
	}
	
	if(CurrentGoal != None){
			GotoState('March');
		}
}

state March
{
	function bool FindNavMeshPath()
	{
		
		//Clear cache and contraints
		NavigationHandle.PathConstraintList = none;
        NavigationHandle.PathGoalList = none;
        
        // Create constraints
        class'NavMeshPath_Toward'.static.TowardGoal( NavigationHandle, CurrentGoal );
        class'NavMeshGoal_At'.static.AtActor( NavigationHandle, CurrentGoal, 32 );
        
        // Find path
        return NavigationHandle.FindPath();
	}
	
Begin:
	
	if( NavigationHandle.ActorReachable( CurrentGoal ) )
    {
        FlushPersistentDebugLines();
 
        //Direct move
        MoveToward( CurrentGoal, CurrentGoal );
    }
    else if( FindNavMeshPath() )
    {
        NavigationHandle.SetFinalDestination(CurrentGoal.Location);
        FlushPersistentDebugLines();
        NavigationHandle.DrawPathCache(,TRUE);
 
        // move to the first node on the path
        if( NavigationHandle.GetNextMoveLocation( TempDest, Pawn.GetCollisionRadius()) )
        {
            DrawDebugLine(Pawn.Location,TempDest,255,0,0,true);
            DrawDebugSphere(TempDest,16,20,255,0,0,true);
 
            MoveTo( TempDest, CurrentGoal );
        }
    }
    else
    {
        //We can't follow, so get the hell out of this state, otherwise we'll enter an infinite loop.
        `Log("Else getting called!");
        GotoState('Idle');
    }
 		//goto 'Begin';
 	GotoState('Idle');
    
}

defaultproperties
{
	DeathEmitter=ParticleSystem'FX_VehicleExplosions.Effects.P_FX_VehicleDeathExplosion'
	
	TurretDistThreshold=512.0
}
