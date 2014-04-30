//------------------------------------------------------------------------------------------------
// Author: Christopher Nelson
// Date: 08-24-13
// Credit: Romero UnrealScript, Michelle M, Justin Gallo.
// 
// Purpose: Draw a canvas HUD to our level that illustrates the water resource amount and current attack power.
//------------------------------------------------------------------------------------------------

class WNCloudHUD extends HUD;
//variable declaration

var MultiFont gameFont;


var Texture2D gameTexture;

//function declaration

function DrawHUD ()
{
	super.DrawHUD ();
	
	//Draws the water amount to HUD
	waterAmount();


	//Draws information text to HUD
	drawHUDText();

	//Adds Storm Number to HUD
	drawStormAmount();

}



event PostRender()
{
	super.PostRender();
}

//drawing water score to HUD
function waterAmount()
{
	
	Canvas.Font= gameFont;
	Canvas.SetDrawColor (255, 255, 255);
	Canvas.SetPos (0,0); 
	
	Canvas.DrawText("Water Amount: ");
	
	if(CloudPawn(PlayerOwner.Pawn).myAmount < 75)
	{
		Canvas.SetDrawColor(255, 0, 0); //Red
	}
	else if(CloudPawn(PlayerOwner.Pawn).myAmount < 150)
	{
		Canvas.SetDrawColor(255, 255, 0); //Yellow
	}
	else
	{
		Canvas.SetDrawColor(0, 255, 0); //Green
	}
	
	Canvas.SetPos(220, 0);
	Canvas.DrawText(CloudPawn(PlayerOwner.Pawn).myAmount);
}

//draws storm amount to HUD
function drawStormAmount()
{
	local WNGame rGame;
	local int stormAmount;

	rGame = WNGame ( WorldInfo.Game );
	if(rGame != none)
	{
		//creating a copy so the formatting cannot be changed later
		stormAmount = CloudPawn(PlayerOwner.Pawn).stormAmount;
	}

	Canvas.Font= gameFont;
	Canvas.SetDrawColor (153, 50, 204); //Purpleish color
	Canvas.SetPos (850, 0); 
	
	Canvas.DrawText("Storms Remaining: ");

	if(stormAmount < 4)
	{
		Canvas.SetDrawColor(255, 0, 0); //Red
	}
	else if(stormAmount < 10)
	{
		Canvas.SetDrawColor(255, 255, 0); //Yellow
	}
	else
	{
		Canvas.SetDrawColor(0, 255, 0); //Green
	}

	Canvas.SetPos(1100, 0);
	Canvas.DrawText(stormAmount);
	
}

//Informs player on resource conditions
function drawHUDText()
{
	local string myText;
	
	local WNGame rGame;
	local int myAmount;

	rGame = WNGame ( WorldInfo.Game );
	if(rGame != none)
		{
			//creating a copy so the formatting cannot be changed later
			myAmount = CloudPawn(PlayerOwner.Pawn).myAmount;
		}

	if(myAmount < 80)
	{
		myText = "Water supply is low!";

		Canvas.Font= gamefont;

		Canvas.SetPos(500, 0);

		//Red Text Color
		Canvas.SetDrawColor (250, 0, 0); //Red

		Canvas.DrawText(myText, ,1, 1);
	}
	else
	{
		myText = "Good Water supply!";

		Canvas.Font= gamefont;

		Canvas.SetPos(500, 0);

		//Red Text Color
		Canvas.SetDrawColor (0, 250, 0); //Green

		Canvas.DrawText(myText, ,1, 1);
	}

}

//Draws HUD interface bar at top of screen ; currently not used
function drawTextureBar()
{
	Canvas.SetPos (0, 0);
	Canvas.SetDrawColor(148, 148,148); //gray
	Canvas.DrawTile(gameTexture, (gameTexture.SizeX * 15),gameTexture.SizeY, 0, 0, gameTexture.SizeX, gameTexture.SizeY);
}


DefaultProperties
{
	gameFont = MultiFont'UI_Fonts_Final.menus.Fonts_AmbexHeavy'

	gameTexture = Texture2D'UDKHUD.player_brown'

}

