class MU_AutoTurret2 extends Pawn HideCategories(AI,Camera,Debug,Pawn,Physics)
   placeable;
//   HideCategories(AI,Camera,Debug,Pawn,Physics) => 
//   hide the AI, Camera, Debug, Pawn, and Physics categories so they do not show up in the Properties window inside of UnrealEd




//Min and Max Rotators Struct - limiting turret rotation
struct RotationRange
{
   var() Rotator RotLimitMin;
   var() Rotator RotLimitMax; 
   var() Bool bLimitPitch;
   var() Bool bLimitYaw;
   var() Bool bLimitRoll;
   
   // max min + - 360 degrees
   
   structdefaultproperties
   {
      RotLimitMin=(Pitch=-65536,Yaw=-65536,Roll=-65536)
      RotLimitMax=(Pitch=65536,Yaw=65536,Roll=65536)
   }
};

// Sounds for turret behaviors
struct TurretSoundGroup
{
   var() SoundCue FireSound;
   var() SoundCue DamageSound;
   var() SoundCue SpinUpSound;
   var() SoundCue WakeSound;
   var() SoundCue SleepSound;
   var() SoundCue DeathSound;
};

//PSystems for the turret
struct TurretEmitterGroup
{
   var() ParticleSystem DamageEmitter;
   var() ParticleSystem MuzzleFlashEmitter;
   var() ParticleSystem DestroyEmitter;
   var() Float MuzzleFlashDuration;
   var() Name DamageEmitterParamName;
   var() Bool bStopDamageEmitterOnDeath;
   
   //Name of the parameter within the damage effect’s particle system that allows control of the spawn rate of the particles, and 
   //a Bool to specify whether the damage effect continues after the destruction of the turret
   
   structdefaultproperties
   {
      MuzzleFlashDuration=0.33
   }
};


//Bone, Socket, Controller names
struct TurretBoneGroup
{
   var() Name DestroySocket;
   var() Name DamageSocket;
   var() Name FireSocket;
   var() Name PivotControllerName;
   
   //three socket names and the name of a skeletal controller
};


//Rotators defining turret poses
struct TurretRotationGroup
{
   var() Rotator IdleRotation;
   var() Rotator AlertRotation;
   var() Rotator DeathRotation; 
   var() Bool bRandomDeath;
   
   //The rotation of the turret is interpolated from its current orientation to one of these three rotations depending on the situation
   //predefined pose when the turret is destroyed or a randomly calculated pose

};




var Pawn EnemyTarget;      //The new enemy the turret should target this tick
var Pawn LastEnemyTarget;   //The enemy the turret was targeting last tick
var Vector EnemyDir;      //Vector from the turret's base to the enemy's location this tick
var Vector LastEnemyDir;   //Vector from the turret's base to the enemy's location last tick

var float TotalInterpTime;   //Total time to interpolate rotation
var Float ElapsedTime;      //Time spent in the current interpolation
var Float RotationAlpha;   //Curret alpha for interpolating to a new rotation
var Rotator StartRotation;   //Beginning rotation for interpolating
var Rotator TargetRotation;   //Desired rotations for interpolating

var Vector FireLocation;   //World position of the firing socket
var Rotator FireRotation;   //World orientation of the firing socket

var SkelControlSingleBone PivotController;      //The  skelcontrol in the AnimTree

var Bool bCanFire;      //Is the turret in a firing state?
var Bool bDestroyed;      //Has the turret been destroyed?
var Int MaxTurretHealth;      //Max health for this turret
var Float FullRevTime;   //Seconds to make full rev at min rot rate

var Float GElapsedTime;   //Elapsed time since last global tick
//The G prefix is simply to indicate this is to be used in the global Tick() function instead of any state Tick() functions
//amount of time that has passed since the last enemy locating update performed in the classes global Tick() function

var Int OrigMinRotRate;   //Beginning value of MinTurretRotRate

var ParticleSystemComponent DamageEffect;      //PSys component for damage effects
var ParticleSystemComponent MuzzleFlashEffect;   //PSys component for muzzle flashes
var ParticleSystemComponent DestroyEffect;      //PSys component for destruction effects


//   declared as editable and placed within the Turret category
var(Turret) SkeletalMeshComponent TurretMesh;         //SkelMeshComp for the turret
var(Turret) DynamicLightEnvironmentComponent LightEnvironment;   //For efficient lighting
var(Turret) SkeletalMesh DestroyedMesh;            //destroyed SkelMesh

var(Turret) TurretBoneGroup TurretBones;   // Socket, Controller names
//A single instance of the TurretBoneGroup struct defined earlier is needed to provide the names of the sockets and 
//skeletal controller needed to control the turret’s rotation and attach effects to

var(Turret) TurretRotationGroup TurretRotations;   //Rotations defining turret poses
var(Turret) RotationRange RotLimit;         //Rotation limits for turret
var(Turret) Int MinTurretRotRate;         //Min Rotation speed Rot/Second
var(Turret) Int MaxTurretRotRate;         //Max Rotation speed Rot/Second

var(Turret) class<Projectile> ProjClass;      //Type of projectile the turret fires
var(Turret) Int RoundsPerSec;            //Number of rounds to fire per second
var(Turret) Int AimRotError;            //Maximum units of error in turret aiming

var(Turret) TurretEmitterGroup TurretEmitters;   //PSystems used by the turret
var(Turret) TurretSoundGroup TurretSounds;      //Sounds used for turret behaviors

var(Turret) Int TurretHealth;      //Initial amount of health for the turret
//While Pawns have a Health property, the turret uses its own TurretHealth property to keep all properties contained within the Turret group



event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	MaxTurretHealth = TurretHealth;
	OrigMinRotRate = MinTurretRotRate;
	FullRevTime = 65536.0 / Float(MinTurretRotRate);
	
	//To initialize the PivotController variable, we need to find a reference to the SkelControlSingleBone skeletal controller 
	//located within the AnimTree assigned to the SkeletalMeshComponent. Passing the TurretBones.PivotControllerName value to the 
	//component’s FindSkelControl() function and casting the result to a SkelControlSingleBone accomplishes this
	//Note: The code is using the Mesh variable to reference the SkeletalMeshComponenet even though we declared the TurretMesh variable
	// in this class. If you’ll remember, the SkeletalMeshComponent was assigned to both of these variables in the default properties 
	//so they both reference the same component. The Mesh variable was chosen to be used in the code as it is shorter and means less typing.
	PivotController=SkelControlSingleBone(Mesh.FindSkelControl(TurretBones.PivotControllerName));
	
	//FireLocation and FireRotation variables are initialized by passing them along with the TurretBones.FireSocket value 
	//to the SkeletalMeshComponent’s GetSocketWorldLocationAndRotation() function
	//second and third parameters of this function are declared using the Out specifier
	Mesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);
	
	//ParticleSystems specified in the TurretEmitters struct are assigned as the templates for the three ParticleSystemComponents 
	//for the damage, destroy, and muzzle flash effect
	DamageEffect.SetTemplate(TurretEmitters.DamageEmitter);
	MuzzleFlashEffect.SetTemplate(TurretEmitters.MuzzleFlashEmitter);
	DestroyEffect.SetTemplate(TurretEmitters.DestroyEmitter);
	
	//The three ParticleSystemComponents are attached to the appropriate sockets of the SkeletalMeshComponent 
	//using the AttachComponentToSocket() function of the SkeletalMeshComponent
	Mesh.AttachComponentToSocket(DamageEffect, TurretBones.DamageSocket);
	Mesh.AttachComponentToSocket(MuzzleFlashEffect, TurretBones.FireSocket);
	Mesh.AttachComponentToSocket(DestroyEffect, TurretBones.DestroySocket);
	
	SetPhysics(PHYS_None);
}

function DoRotation(Rotator NewRotation, Float InterpTime)
{
	StartRotation = PivotController.BoneRotation;
	TargetRotation = NewRotation;
	RotationAlpha = 0.0;
	TotalInterpTime = InterpTime;
	
	//call the RotateTimer() function every 0.033 seconds, or 30 times a second
	SetTimer(0.033,true,'RotateTimer');

}


function RotateTimer()
{
	RotationAlpha += 0.033;  //RotationAlpha is incremented by the same value as the rate of the timer, 0.033
	
	//RLerp() function defined in the Object class performs the interpolation calculation based on the beginning rotation, 
	//ending rotation, and current alpha values passed to the function
	//a Bool, specifies whether to use the shortest distance to interpolate from the beginning rotation to the ending
	if(RotationAlpha <= TotalInterpTime)
   		PivotController.BoneRotation = RLerp(StartRotation,TargetRotation,RotationAlpha,true);
   	else
   		ClearTimer('RotateTimer');

}




//default initial state of the turret
auto state Idle
{
	//place the turret in the Alert state if it manages to get shot or damaged without having an enemy targeted
	event TakeDamage(   int Damage,
       Controller InstigatedBy,
       vector HitLocation, 
       vector Momentum,
       class<DamageType> DamageType,
       optional TraceHitInfo HitInfo,
       optional Actor DamageCauser   )
	{
		Global.TakeDamage(Damage,InstigatedBy,HitLocation,Momentum,DamageType,HitInfo,DamageCauser);
		if(TurretHealth > 0)
		{
		   GotoState('Alert');
		}

	}
	
	//see global tick function for remarks
	//same as global but only searches in front of the turret
	function Tick(Float Delta)
	{
		local Float currDot;
		local Float thisDot;

		local Turtle P;
		
		local Bool bHasTarget; //new enemy was found

		currDot = -1.01;

		if(GElapsedTime > 0.5 && !bDestroyed)
		{
			GElapsedTime = 0.0;
			bHasTarget = false;
	
			foreach WorldInfo.AllPawns(class'Turtle',P)
			{
				if(FastTrace(P.Location,FireLocation))
				{
					//is Rotation the orientation of the entire turret??????
					thisDot = Normal(Vector(PivotController.BoneRotation)) Dot
					Normal(((P.Location - FireLocation) << Rotation));                 //??????? unknown syntax   << is forward vector transformation ?????
					//thisDot >=0 means in front of the turret + or - 90 degrees
					//pawn velocity minimum to be seen - so in front of turret and moving
					if(P.Health > 0 && VSize(P.Velocity) > 16.0 && thisDot >= 0.0 && thisDot >= currDot)
					{
					   EnemyTarget = P;
					   currDot = thisDot;
					   bHasTarget = true;
					}
				}
			}
			if(bHasTarget && !IsInState('Defend'))
			{
			   GotoState('Defend');
			}
			else if(!bHasTarget && IsInState('Defend'))
			{
			   GotoState('Alert');
			}
	
		}
		else
		{
			GElapsedTime += Delta; //incremented by the time passed since the last Tick() function call
		}
	}
	
	//begin the interpolation to the idle pose and play the SleepSound SoundCue
	function BeginIdling()
	{
		DoRotation(TurretRotations.IdleRotation, 1.0);
		if(TurretSounds.SleepSound != None)
		{
   			PlaySound(TurretSounds.SleepSound);
   			`log("Turret sleep sound");
   		}
	}
	
	//BeginState() event is executed when the state is made active
	//starts the interpolation to the alert pose if necessary and calls the BeginIdling() function to place the turret in the idle pose 
	//and play the SleepSound SoundCue assuming one is specified
	//if the previous state was anything other than the Alert state, 
	//the turret should interpolate to the alert pose before beginning the interpolation to the idle pose
	//it seemed reasonable that the turret would always follow the same progression of idle-alert-firing-alert-idle
	//Since the interpolation takes 1.0 second, the BeginIdling() function is called as a non-looping timer with a rate of 1.0 seconds
	event BeginState(Name PreviousStateName)
	{
		if(PreviousStateName != 'Alert')
		{
		   DoRotation(TurretRotations.AlertRotation, 1.0);
		   SetTimer(1.0,false,'BeginIdling');
		}
		else
   			BeginIdling();
	}

}
//end of the idle state code

//turret is actively searching for any visible enemy to target and attack
state Alert
{
	//add - scan the area by animating its rotation
	function Tick(Float Delta)
	{
		local Rotator AnimRot; //rotation to be added to the turret’s current rotation each tick to animate the turret scanning the area

        Global.Tick(Delta);
        
        AnimRot.Yaw = MinTurretRotRate * Delta; //Delta time since last tick
		PivotController.BoneRotation += AnimRot;
		
		//If the blimitYaw property is True and the Yaw of the current rotation is outside the limits set in the RotLimitMin 
		//and RotLimitMax Rotators, the MinTurretRotrate value is multiplied by -1 to reverse the direction of the turret’s rotation
		if(RotLimit.bLimitYaw)
		{
		   if(   PivotController.BoneRotation.Yaw >= RotLimit.RotLimitMax.Yaw    ||
		      PivotController.BoneRotation.Yaw <= RotLimit.RotLimitMin.Yaw   )
		   {
		      MinTurretRotRate *= -1;
		   }
		}
	}
	
	//place the turret back into the Idle state if it has not been destroyed
	function IdleTimer()
	{
		if(!bDestroyed)
		{
		   GotoState('Idle');
		}
	}
	
	event BeginState(Name PreviousStateName)
	{
		//The first is a Rotator to hold the initial rotation the sweep should begin from. 
		//This rotation is the rotation specified in the AlertRotation property of the TurretRotations struct with its Yaw value 
		//substituted with the current Yaw of the turret. 
		//The other local variable is a Float value representing the amount of total time the turret’s sweep of the area will last.
		local Rotator AlertRot;
		local Float RevTime;
		
		//first assigned the value of the AlertRotation. 
		//Then its Yaw value is replaced with the current Yaw of the turret normalized to the range of 0 to 65536 (360 degrees)
		AlertRot = TurretRotations.AlertRotation;
		AlertRot.Yaw = PivotController.BoneRotation.Yaw % 65536; //does this make sense ?????????????
		
		//This sweep will consist of panning from the current yaw to the far limit, back to the near limit and 
		//then to the Yaw specified by the AlertRotation
		if(RotLimit.bLimitYaw)
		{
			//which limit is farther from the current rotation of the pivot
			//The time it takes to make the full sweep given the current rotation of the turret is calculated by taking the 
			//difference between the far limit and the current rotation and dividing that value by the original minimum rotation rate 
			//of the turret. 
			//Then the amount of time it takes to make one complete sweep from the minimum limit to the maximum limit is calculate 
			//using the same method and added to the previous calculation. 
			//Finally, the time to pan from the far limit to the AlertRotation is calculated and added to the overall result. 
			//This value is assigned to the RevTime variable in each of the If/Else blocks.
			if(AlertRot.Yaw > Float(RotLimit.RotLimitMax.Yaw + RotLimit.RotLimitMin.Yaw) / 2.0)
			{
			   RevTime = (Float(AlertRot.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate)) +
			      (Float(RotLimit.RotLimitMax.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate)) +
			      (Float(RotLimit.RotLimitMax.Yaw - TurretRotations.AlertRotation.Yaw) / Float(OrigMinRotRate));

			    MinTurretRotRate = -1 * OrigMinRotRate;
			}
			else
			{
			   RevTime = (Float(RotLimit.RotLimitMax.Yaw - AlertRot.Yaw) / Float(OrigMinRotRate)) +
			      (Float(RotLimit.RotLimitMax.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate)) +
			      (Float(TurretRotations.AlertRotation.Yaw - RotLimit.RotLimitMin.Yaw) / Float(OrigMinRotRate));
			    MinTurretRotRate = OrigMinRotRate;
			}

		}
		else
		{
			//the turret will rotate the long way around from its current rotation back to the AlertRotation
			RevTime = FullRevTime;
			
			//?????????? what is going on here ?????????????
			//must be + or - 32767 not 0 to 65536, but why % 65536 on yaw above?
			
			//Half a revolution is added to the AlertRotation’s Yaw property. By checking the current rotation against that value,
			//the turret can be narrowed down to facing one hemisphere or the other
			//The amount of time to be removed from the full revolution time is calculated by taking the difference between 
			//the current rotation and either the AlertRotation or one full revolution from the AlertRotation. 
			//That value is then divided by the OrigTurretRotRate. 
			//The subtractions in these calculations should be performed in an order such that the results are negative values 
			//as the point of the calculations is to find the portion of the full revolution that needs to be omitted 
			//based on the current rotation
			if(AlertRot.Yaw > (TurretRotations.AlertRotation.Yaw + 32768))
			{
				RevTime += Float(AlertRot.Yaw - (TurretRotations.AlertRotation.Yaw + 65536)) /
         			Float(OrigMinRotRate);

         		MinTurretRotRate = -1 * OrigMinRotRate;
			}
			else
			{
				RevTime += Float(TurretRotations.AlertRotation.Yaw - AlertRot.Yaw) /
         			Float(OrigMinRotRate);

         		MinTurretRotRate = OrigMinRotRate;
			}
		}
		
		//The rate of the timer is the RevTime + 1.0 seconds to account for the initial rotation to the AlertRot pose
		SetTimer(RevTime + 1.0,false,'Idletimer');
		
		DoRotation(AlertRot, 1.0);
		
		if(TurretSounds.WakeSound != None)
		{
   			PlaySound(TurretSounds.WakeSound);
   			`log("Turret wake sound");
   		}
	}
}
//end of alert state code




//Once an enemy has been found, the Defend state is entered. This state handles targeting the enemy and firing projectiles
//firing functionality of the turret is handled by two functions. The first function named TimedFire() spawns the projectile, 
//activates the muzzle flash, and plays the firing sound. The second function named StopMuzzleFlash() simply deactivates the muzzle flash
state Defend
{
	function StopMuzzleFlash()
	{
		MuzzleFlashEffect.DeactivateSystem();
	}
	
	//set to loop when the turret begins the Defend state and will be cleared when the turret leaves the Defend state
	function TimedFire()
	{
		local Projectile Proj;

		Proj = Spawn(ProjClass,self,,FireLocation,FireRotation,,True);
		
		//If the spawn was successful and the projectile is not about to be deleted
		if( Proj != None && !Proj.bDeleteMe )
		{
			Proj.Init(Vector(FireRotation));
			if(TurretEmitters.MuzzleFlashEmitter != None)
			{
			   MuzzleFlashEffect.ActivateSystem();
			   SetTimer(TurretEmitters.MuzzleFlashDuration,false,'StopMuzzleFlash');
			}
			if(TurretSounds.FireSound != None)
				PlaySound(TurretSounds.FireSound);
		}
	}
	
	//timer function that starts the firing process by setting a looping timer for the TimedFire() function and 
	//enables the targeting process by toggling the bCanFire variable
	function BeginFire()
	{
		if(RoundsPerSec > 0)
		{
		   SetTimer(1.0/RoundsPerSec,true,'TimedFire');
		   bCanFire = true;
		}
	}
	
	
	event BeginState(Name PreviousStateName)
	{
		//If the turret is entering the Defend state from the Alert state, 
		//the IdleTimer must be cleared if it is currently active to prevent the turret from inadvertently being placed into the Idle state
		if(PreviousStateName == 'Alert')
		{
		   if(IstImerActive('IdleTimer'))
		      ClearTimer('IdleTimer');
		}
		bCanFire = false;
		//FireLocation and FireRotation properties are initialized with the current location and rotation of the socket located at the 
		//muzzle tip by calling the GetSocketWorldLocationAndRotation() function of the SkeletalMeshComponent
		Mesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);
		
		//the turret interpolates to face the current enemy
		//takes the vector from the muzzle tip to the enemy and transforms that into world space. 
		//Then, the resulting Vecotr is cast to a Rotator to get the rotation necessary to cause the turret to point at the enemy
		DoRotation(Rotator((EnemyTarget.Location - FireLocation) << Rotation), 1.0);
		
		if(TurretSounds.SpinUpsound != None)
		{
   			PlaySound(TurretSounds.SpinUpSound);
   			`log("Turret spinup sound");
   		}
   		//start a timer to execute the BeginFire() function after 1.0 second has passed
   		SetTimer(1.0,false,'BeginFire');

	}

	event EndState(Name NewStateName)
	{
		//clear the TimedFire() timer to stop the turret from firing
		ClearTimer('TimedFire');
	}
	
	function Tick(Float Delta)
	{
		local Rotator InterpRot;
		local Rotator DiffRot;
		local Int MaxDiffRot;
		
		Global.Tick(Delta);
		
		if(bCanFire)
		{
			EnemyDir = EnemyTarget.Location - Location;
			
			//new enemy has been acquired or current enemy has moved or current targeting interpolation has completed
			//targeting variables are initialized or reset
			if(   EnemyTarget != LastEnemyTarget    ||
			   EnemyDir != LastEnemyDir       ||
			   ElapsedTime >= TotalInterpTime   )
			{
				LastEnemyDir = EnemyDir;
				LastEnemyTarget = EnemyTarget;
				
				StartRotation = PivotController.BoneRotation;
				TargetRotation = Rotator((EnemyTarget.Location - FireLocation) << Rotation);
				
				DiffRot = TargetRotation - StartRotation;
				MaxDiffRot = Max(Max(DiffRot.Pitch,DiffRot.Yaw),DiffRot.Roll);
				
				TotalInterpTime = Abs(Float(MaxDiffRot) / Float(MaxTurretRotRate));
				
				ElapsedTime = Delta; //ElapsedTime is set equal to the time passed since the last tick
			}
			else
			{
			   ElapsedTime += Delta;
			}
			
			//The turret is rotated a portion of the way towards the final desired rotation each tick
			//nov 2010 flaw in logic
			//RotationAlpha = FClamp(ElapsedTime / TotalInterpTime,0.0,1.0);
			if(TotalInterpTime == 0)
				RotationAlpha = 1.0;
			else
                RotationAlpha = FClamp(ElapsedTime / TotalInterpTime,0.0,1.0);
            //end nov 2010 flaw in logic
			InterpRot = RLerp(StartRotation,TargetRotation,RotationAlpha,true);
			
			if(RotLimit.bLimitPitch)
			   InterpRot.Pitch = Clamp(InterpRot.Pitch,
			            RotLimit.RotLimitMin.Pitch, 
			            RotLimit.RotLimitMax.Pitch   );
			
			if(RotLimit.bLimitYaw)
			   InterpRot.Yaw = Clamp(   InterpRot.Yaw, 
			            RotLimit.RotLimitMin.Yaw, 
			            RotLimit.RotLimitMax.Yaw   );
			
			if(RotLimit.bLimitRoll)
			   InterpRot.Roll = Clamp(   InterpRot.Roll, 
			            RotLimit.RotLimitMin.Roll, 
			            RotLimit.RotLimitMax.Roll   );
			            
			PivotController.BoneRotation = InterpRot;  //update the turret
			
			//firing location and rotation variables are updated with the new orientation of the turret
			Mesh.GetSocketWorldLocationAndRotation(TurretBones.FireSocket,FireLocation,FireRotation);
			
			//firing rotation is adjusted with a random aim error
			FireRotation.Pitch += Rand(AimRotError * 2) - AimRotError;
			FireRotation.Yaw += Rand(AimRotError * 2) - AimRotError;
			FireRotation.Roll += Rand(AimRotError * 2) - AimRotError;
		}
	}
}
//end defend state code



//enters after its health has reached 0
state Dead
{
	//Tick() and TakeDamage() functions are going to be ignored in this state
	ignores Tick, TakeDamage;
	
	//timer function that handles the playing of the destruction effects
	function PlayDeath()
	{
		if(TurretEmitters.DestroyEmitter != None)
   			DestroyEffect.ActivateSystem();
   		if(TurretSounds.DeathSound != None)
   		{
   			PlaySound(TurretSounds.DeathSound);
   			`log("Turret death sound");
   		}
   		if(DestroyedMesh != None)
   			Mesh.SetSkeletalMesh(DestroyedMesh);
   		if(TurretEmitters.bStopDamageEmitterOnDeath)
   			DamageEffect.DeactivateSystem();
   		
   		Destroy();
   		WorldInfo.Game.Broadcast(self, "Turret is dead!");
	}
	
	
	function DoRandomDeath()
	{
		local Rotator DeathRot;

        DeathRot = RotRand(true); //calculate a random rotation. A value of True is passed to the function to include the Roll component
        
        if(RotLimit.bLimitPitch)
		   DeathRot.Pitch = Clamp(   DeathRot.Pitch,
		            RotLimit.RotLimitMin.Pitch, 
		            RotLimit.RotLimitMax.Pitch   );
		if(RotLimit.bLimitYaw)
		   DeathRot.Yaw = Clamp(   DeathRot.Yaw,
		            RotLimit.RotLimitMin.Yaw, 
		            RotLimit.RotLimitMax.Yaw   );
		if(RotLimit.bLimitRoll)
		   DeathRot.Roll = Clamp(   DeathRot.Roll, 
		            RotLimit.RotLimitMin.Roll, 
		            RotLimit.RotLimitMax.Roll   );

		DoRotation(DeathRot, 1.0);
	}
	
	
	event BeginState(Name PreviousSateName)
	{
		bDestroyed = true;

        if(!TurretRotations.bRandomDeath)
   			DoRotation(TurretRotations.DeathRotation, 1.0);
   		else
   			DoRandomDeath();
   			
   		//timer is set to execute the PlayDeath() function after the interpolation to the new rotation has completed
   		SetTimer(1.0,false,'PlayDeath');



	}




}
//end of dead state code


//TakeDamage() function inherited from the parent
//enable the turret to handle playing its damage effects and sounds as well as making use of its TurretHealth variable 
//in place of the inherited Health variable
event TakeDamage(int Damage,
       Controller InstigatedBy,
       vector HitLocation,
       vector Momentum,
       class<DamageType> DamageType,
       optional TraceHitInfo HitInfo,
       optional Actor DamageCauser   )
{
	TurretHealth -= Damage;
	//determine if the DamageEmitter exists and then sets the value of the spawn rate parameter of the DamageEffect 
	//accordingly using the SetFloatParam() function of the ParticleSystemComponent
	if(TurretEmitters.DamageEmitter != None)
	{
		//The parameter name is passed to the SetFloatParameter() function as the first parameter 
		//and the value to be assigned to that parameter is passed as the second parameter. 
		//The parameter in the particle system is expecting a value between 0.0 and 1.0 representing the relative amount of damage done 
		//to the turret. This value is mapped to a new range which determines the amount of particles to spawn each second.
		//"FClamp" calculated by dividing the current health value by the initial maximum health value to get a percentage of the turret’s health remaining. 
		//That result is then subtracted from 1.0 to get the inverse percentage, or the percentage of damage done. 
		//This is then clamped between 0.0 and 1.0 for good measure.
	   //DamageEffect.SetFloatParameter(TurretEmitters.DamageEmitterParamName,  FClamp(1-Float(TurretHealth)/Float(MaxTurretHealth)),0.0,1.0)  ); //typo on web page
	   DamageEffect.SetFloatParameter(TurretEmitters.DamageEmitterParamName,  FClamp(1-(Float(TurretHealth)/Float(MaxTurretHealth)),0.0,1.0)  );
	}
	
	if(TurretSounds.DamageSound != None)
	{
   		PlaySound(TurretSounds.DamageSound);
   		`log("Turret damage sound");
   	}
   	
	//any Pawn who shoots at and damages the turret becomes the turret’s enemy and is targeted
   	if(InstigatedBy.Pawn != None)
   		EnemyTarget = InstigatedBy.Pawn;

   	if(TurretHealth <= 0)
	{
	   GotoState('Dead');
	}

}


//global Tick() function is responsible for finding visible enemies for the turret to target and attack.
//This function exists outside of any state and is used when the turret is in the Alert or Defend states
//main responsibility is to pick a new enemy for the turret by finding the player that is closest to the current aim of the turret. 
//This will require calculating the dot product of the direction the turret is aiming and the direction to the player in question
//and comparing the result to that of each subsequent player.
function Tick(Float Delta)
{
	//Two local Float variables ware used to store the current dot product and the current closest dot product.
	local Float currDot;
	local Float thisDot;
	
	//An iterator is used to loop through all the players in the match.
	//This requires a UTPawn local variable to hold a reference to each player in the iterator.
	local Turtle P;
	
	local Bool bHasTarget; //new enemy was found
	
	//The result of each dot product operation is between -1 and 1. -1 being in the exact opposite direction to where the turret is aiming
	//and 1 being directly in the turret’s aim. The currDot is initialized to a value of -1.01 so that the result of the dot product 
	//for any player found will be higher than the initial value.
	currDot = -1.01;

	//targeting to only be performed once every 0.5 seconds and only if the turret has not been destroyed
	if(GElapsedTime > 0.5 && !bDestroyed)
	{
		GElapsedTime = 0.0;
		bHasTarget = false;

		foreach WorldInfo.AllPawns(class'Turtle',P)
		{
			//function returns True if no world geometry was encountered when tracing to the end location from the start location
			if(FastTrace(P.Location,FireLocation))
			{
				//is Rotation the orientation of the entire turret??????
				thisDot = Normal(Vector(PivotController.BoneRotation)) Dot
				Normal(((P.Location - FireLocation) << Rotation));                 //??????? unknown syntax   << is forward vector transformation ?????
				if(P.Health > 0 && thisDot >= currDot)
				{
				   EnemyTarget = P;
				   currDot = thisDot;
				   bHasTarget = true;
				}
			}
		}
		if(bHasTarget && !IsInState('Defend'))
		{
		   GotoState('Defend');
		}
		else if(!bHasTarget && IsInState('Defend'))
		{
		   GotoState('Alert');
		}

	}
	else
	{
		GElapsedTime += Delta; //incremented by the time passed since the last Tick() function call
	}

}
/*event Touch( Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal )
{
	if(Other.IsA('Turtle'))
	{
		Destroy();
	}
}*/


//The DynamicLightEnvirnmentComponent has no properties which need be set. All the defaults will suffice. 
//    It is assigned to the LightEnvironment variable and added to the Components array
//The SkeletalMeshComponent needs to be created, added to the Components array and assigned to the TurretMesh variable of this class 
//    as well as the Mesh variable inherited from the Pawn class. 
//    In addition, the SkeletalMesh, AnimTreeTemplate, PhysicsAsset, and LightEnvirnment properties of the component are set. 
//    The assets assigned to the Skeletalmesh, AnimTreeTemplate, and PhysicsAsset are located in the TurretContent package provided
//SecondsBeforeInactive property will be set to a fairly high value of 10000.0, instead of a value of 1.0 like the other two componenets, 
//    to ensure the ParticleSystem continues playing at all times
//default sounds from the UT3 assets are assigned
//One custom and two stock ParticleSystems along with the name of the parameter controlling the spawn rate within the damage emitter
//Each of the rotations contained within the TurretRotations struct can be set with default values
//rotation rate, firing rate, health, projectile class, aim error are all given default values. 
//         In addition one inherited property is set here as well: bEdShouldSnap. This variable is given a value of True 
//         to make the turret snap to the grid when placing instances of it inside of UnrealEd
defaultproperties
{
  Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
  End Object
  LightEnvironment=MyLightEnvironment
  Components.Add(MyLightEnvironment)
  
  Begin Object class=SkeletalMeshComponent name=SkelMeshComp0
        //SkeletalMesh=SkeletalMesh'TurretContent.TurretMesh'
        SkeletalMesh=SkeletalMesh'TurretContent.TurretActor'
        AnimTreeTemplate=AnimTree'TurretContent.TurretAnimTree'
        PhysicsAsset=PhysicsAsset'TurretContent.TurretMesh_Physics'
        LightEnvironment=MyLightEnvironment
   End Object
   Components.Add(SkelMeshComp0)
   TurretMesh=SkelMeshComp0
   Mesh=SkelMeshComp0

   Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent0
         SecondsBeforeInactive=1
  End Object
  MuzzleFlashEffect=ParticleSystemComponent0
  Components.Add(ParticleSystemComponent0)
  
  Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent1
     SecondsBeforeInactive=1
  End Object
  DestroyEffect=ParticleSystemComponent1
  Components.Add(ParticleSystemComponent1)
  
  Begin Object Class=ParticleSystemComponent Name=ParticleSystemComponent2
     SecondsBeforeInactive=10000.0
  End Object
  DamageEffect=ParticleSystemComponent2
  Components.Add(ParticleSystemComponent2)
  
  TurretBones={(
     DestroySocket=DamageLocation,
     DamageSocket=DamageLocation,
     FireSocket=FireLocation,
     PivotControllerName=PivotController
   )}

   TurretSounds={(
     //FireSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue',
     //DamageSound=SoundCue'A_Weapon_Stinger.Weapons.A_Weapon_Stinger_FireImpactCue',
     //SpinUpSound=SoundCue'A_Vehicle_Turret.Cue.AxonTurret_PowerUpCue',
     //WakeSound=SoundCue'A_Vehicle_Turret.Cue.A_Turret_TrackStart01Cue',
     //SleepSound=SoundCue'A_Vehicle_Turret.Cue.A_Turret_TrackStop01Cue',
     //DeathSound=SoundCue'A_Vehicle_Turret.Cue.AxonTurret_PowerDownCue'
     FireSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_FireCue',
     DamageSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_ImpactCue',
     SpinUpSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_RaiseCue',
     WakeSound=SoundCue'A_Vehicle_Manta.SoundCues.A_Vehicle_Manta_Start',
     SleepSound=SoundCue'A_Vehicle_Manta.SoundCues.A_Vehicle_Manta_Stop',
     DeathSound=SoundCue'A_Weapon_Link.Cue.A_Weapon_Link_LowerCue'
   )}

   TurretEmitters={(
     DamageEmitter=ParticleSystem'TurretContent.P_TurretDamage',
     //MuzzleFlashEmitter=ParticleSystem'WP_Stinger.Particles.P_Stinger_3P_MF_Alt_Fire',
     //DestroyEmitter=ParticleSystem'FX_VehicleExplosions.Effects.P_FX_VehicleDeathExplosion',
     //DamageEmitter=ParticleSystem'Envy_Effects.Vehicle_Damage.P_Vehicle_Damage_1_Scorpion',
     MuzzleFlashEmitter=ParticleSystem'VH_Scorpion.Effects.PS_Scorpion_Gun_MuzzleFlash_Red',
     DestroyEmitter=ParticleSystem'Envy_Effects.VH_Deaths.P_VH_Death_SMALL_Near',
     DamageEmitterParamName=DamageParticles
   )}

   TurretRotations={(
     IdleRotation=(Pitch=-8192,Yaw=0,Roll=0),
     AlertRotation=(Pitch=0,Yaw=0,Roll=0),
     DeathRotation=(Pitch=8192,Yaw=4551,Roll=10922)
   )}

   MinTurretRotRate=2048
   MaxTurretRotRate=128000
  TurretHealth=500
  AimRotError=128
  ProjClass=class'UTGame.UTProj_LinkPowerPlasma'
  RoundsPerSec=3
  bEdShouldSnap=true

}
//default properties  changed TurretRotRate=128000 to MaxTurretRotRate=128000
//default properties  changed DestroyedEffect=ParticleSystemComponent1 to DestroyEffect=ParticleSystemComponent1
//turret sounds to those existing in udk
//use alternate turret mesh
//use emitters from udk - still need custom damage emitter
//MinTurretRotRate=8192 was missing from my code, was it in the web page? yes missing
//turret seems to have blind spot now try    MinTurretRotRate=2048 nope no effect
