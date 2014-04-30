//------------------------------------------------------------------------------------------------
// Author: Christopher Nelson
// Date: 03/15/2014
// Credit: Justin G. , Jason L. 
// 
// Purpose: Draw a canvas HUD to our level that illustrates the water resource amount and current attack power.
//------------------------------------------------------------------------------------------------
class CloudController extends PlayerController;

var bool bCanSuckWater;

//functions=======================================


//Update player rotation when walking
state PlayerWalking
{
ignores SeePlayer, HearNoise, Bump;


   function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
   {
	  local Vector tempAccel;
		local Rotator CameraRotationYawOnly;
		

      if( Pawn == None )
      {
         return;
      }

      if (Role == ROLE_Authority)
      {
         // Update ViewPitch for remote clients
         Pawn.SetRemoteViewPitch( Rotation.Pitch );
      }

      tempAccel.Y =  PlayerInput.aStrafe * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
      tempAccel.X = PlayerInput.aForward * DeltaTime * 100 * PlayerInput.MoveForwardSpeed;
      tempAccel.Z = 0; //no vertical movement for now, may be needed by ladders later
      
	 //get the controller yaw to transform our movement-accelerations by
	CameraRotationYawOnly.Yaw = Rotation.Yaw; 
	tempAccel = tempAccel>>CameraRotationYawOnly; //transform the input by the camera World orientation so that it's in World frame
	Pawn.Acceleration = tempAccel;
   
	Pawn.FaceRotation(Rotation,DeltaTime); //notify pawn of rotation

    CheckJumpOrDuck();
   }
}

state PlayerFlying
{
ignores SeePlayer, HearNoise, Bump;

	function PlayerMove(float DeltaTime)
	{
		local vector X,Y,Z;

		GetAxes(Rotation,X,Y,Z);

		Pawn.Acceleration = PlayerInput.aForward*X + PlayerInput.aStrafe*Y + PlayerInput.aUp*vect(0,0,1);
		Pawn.Acceleration = Pawn.AccelRate * Normal(Pawn.Acceleration);

		if ( bCheatFlying && (Pawn.Acceleration == vect(0,0,0)) )
			Pawn.Velocity = vect(0,0,0);
		// Update rotation.
		UpdateRotation( DeltaTime );

		if ( Role < ROLE_Authority ) // then save this move and replicate it
			ReplicateMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
		else
			ProcessMove(DeltaTime, Pawn.Acceleration, DCLICK_None, rot(0,0,0));
	}

	event BeginState(Name PreviousStateName)
	{
		Pawn.SetPhysics(PHYS_Flying);
	}
}

//Controller rotates with turning input
function UpdateRotation( float DeltaTime )
{
local Rotator   DeltaRot, newRotation, ViewRotation;

   ViewRotation = Rotation;
   if (Pawn!=none)
   {
      Pawn.SetDesiredRotation(ViewRotation);
   }

   // Calculate Delta to be applied on ViewRotation
   DeltaRot.Yaw   = PlayerInput.aTurn;
   DeltaRot.Pitch   = PlayerInput.aLookUp;

   ProcessViewRotation( DeltaTime, ViewRotation, DeltaRot );
   SetRotation(ViewRotation);

   NewRotation = ViewRotation;
   NewRotation.Roll = Rotation.Roll;

   if ( Pawn != None )
      Pawn.FaceRotation(NewRotation, deltatime); //notify pawn of rotation
}


simulated event Tick (float deltaTime)
{
    local vector snappedLocation;

    Super.Tick(deltaTime);

    if (Pawn != none)
    {
        snappedLocation = Pawn.Location;
        snappedLocation.Y = 0.0;
        Pawn.SetLocation(snappedLocation);
    }
}
DefaultProperties
{
  bCanSuckWater = false
}