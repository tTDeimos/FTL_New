#include "LoadEvent.as";

const string[] systemNames = 
{
	"Shields",
	"Engines",
	"Oxygen",
	"Medical",
	"Cloning",
	"Weapons"
};

const int system_Amount = 6;

void onInit(CBlob @this){

	for(int s = 0;s < system_Amount;s+=1)
	{
		this.set_u8("Power_"+systemNames[s],0);
		this.set_u8("Bars_"+systemNames[s],0);
		this.set_u8("Zoltan_"+systemNames[s],0);
		this.set_u8("Damaged_"+systemNames[s],0);
	}
	
	this.set_u8("Power_Oxygen",1);
	this.set_u8("Bars_Oxygen",1);
	
	this.set_u8("CurrentPower",4);
	this.set_u8("MaxPower",5);
	
	this.set_u8("Level",5);
	this.set_u8("MaxLevel",100);
	
	this.set_u8("upgrade_cost_base",10);
	this.set_u8("upgrade_cost_level",1);

	this.set_u16("FTLDrive",0);
	this.set_u16("FTLDriveMax",10000);
	
	this.addCommandID("power_handle");
	this.addCommandID("ftl_jump");
}

void onTick(CBlob@ this){

	if(getGameTime() % 30 == 0){

		AssignPower(this);
		
		UpdateSystemAmount(this);
		
		this.set_u8("MaxPower",this.get_u8("Level"));

	}
	
	if(this.get_u16("FTLDrive") < this.get_u16("FTLDriveMax")){
		
		this.set_u16("FTLDrive",this.get_u16("FTLDrive")+this.get_u8("Power_Engines"));
		this.Untag("played_ready");
	
	} else {
		if(!this.hasTag("played_ready")){
			this.Tag("played_ready");
			Sound::Play("ftl_ready.ogg");
		}
	}
	
	PilotControl(this);
}

void UpdateSystemAmount(CBlob@ this){

	CBlob@[] blobs;
	
	getBlobsByTag("room", blobs);

	
	for(int s = 0;s < system_Amount;s+=1)
	{
		this.set_u8("Bars_"+systemNames[s],0);
		this.set_u8("Damaged_"+systemNames[s],0);
	}
	
	
	for (u32 k = 0; k < blobs.length; k++)
	{
		CBlob@ blob = blobs[k];
		if(blob.getTeamNum() == this.getTeamNum()){
			
			if(blob.getName() == "oxygen_generator"){
				this.set_u8("Bars_Oxygen",this.get_u8("Bars_Oxygen")+blob.get_u8("Level"));
				this.set_u8("Damaged_Oxygen",this.get_u8("Damaged_Oxygen")+blob.get_u8("Damage"));
			}
			
			if(blob.getName() == "cloning_bay"){
				this.set_u8("Bars_Cloning",this.get_u8("Bars_Cloning")+blob.get_u8("Level"));
				this.set_u8("Damaged_Cloning",this.get_u8("Damaged_Cloning")+blob.get_u8("Damage"));
			}
			
			if(blob.getName() == "engine_room"){
				this.set_u8("Bars_Engines",this.get_u8("Bars_Engines")+blob.get_u8("Level"));
				this.set_u8("Damaged_Engines",this.get_u8("Damaged_Engines")+blob.get_u8("Damage"));
			}
			
			if(blob.getName() == "shield_generator"){
				this.set_u8("Bars_Shields",this.get_u8("Bars_Shields")+blob.get_u8("Level"));
				this.set_u8("Damaged_Shields",this.get_u8("Damaged_Shields")+blob.get_u8("Damage"));
			}
			
			if(blob.getName() == "weapon_room"){
				this.set_u8("Bars_Weapons",this.get_u8("Bars_Weapons")+blob.get_u8("Level"));
				this.set_u8("Damaged_Weapons",this.get_u8("Damaged_Weapons")+blob.get_u8("Damage"));
			}
			
		}
	}
	
	for(int s = 0;s < system_Amount;s+=1)
	{
		if(this.get_u8("Bars_"+systemNames[s])-this.get_u8("Damaged_"+systemNames[s]) < this.get_u8("Power_"+systemNames[s])){
			int dif = this.get_u8("Power_"+systemNames[s])-(this.get_u8("Bars_"+systemNames[s])-this.get_u8("Damaged_"+systemNames[s]));
			this.set_u8("Power_"+systemNames[s],this.get_u8("Bars_"+systemNames[s])-this.get_u8("Damaged_"+systemNames[s]));
			this.set_u8("CurrentPower",this.get_u8("CurrentPower")+dif);
		}
	}
	
	int Power = this.get_u8("CurrentPower");
	int ZoltanExcessPower = 0;
	for(int s = 0;s < system_Amount;s+=1)
	{
		Power += this.get_u8("Power_"+systemNames[s]);
		if(this.get_u8("Bars_"+systemNames[s])-this.get_u8("Damaged_"+systemNames[s]) < this.get_u8("Power_"+systemNames[s])+this.get_u8("Zoltan_"+systemNames[s]))ZoltanExcessPower += this.get_u8("Zoltan_"+systemNames[s]);
		//print("Stats for "+systemNames[s]+": Bars:"+this.get_u8("Bars_"+systemNames[s])+" Power:"+this.get_u8("Power_"+systemNames[s])+" Zoltan:"+this.get_u8("Zoltan_"+systemNames[s]));
	}
	
	this.set_u8("CurrentPower",this.get_u8("CurrentPower")+(this.get_u8("MaxPower")-Power)+ZoltanExcessPower);
}

void AssignPower(CBlob@ this){

	{
		CBlob@[] blobs;
		
		getBlobsByName("oxygen_generator", blobs);
		
		float Amount = 0;
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				Amount += (blob.get_u8("Level")-blob.get_u8("Damage"));
			}
		}
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				if(blob.get_u8("Level")-blob.get_u8("Damage") > 0)blob.set_f32("Power",(this.get_u8("Power_Oxygen")*1.0f)/Amount*((blob.get_u8("Level")-blob.get_u8("Damage"))*1.0f)-blob.get_u16("IonDamage"));
			}
		}
	}
	
	{
		CBlob@[] blobs;
		
		getBlobsByName("cloning_bay", blobs);
		
		float Amount = 0;
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				Amount += (blob.get_u8("Level")-blob.get_u8("Damage"));
			}
		}
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				blob.set_f32("Power",(this.get_u8("Power_Cloning")*1.0f)/Amount*((blob.get_u8("Level")-blob.get_u8("Damage"))*1.0f)-blob.get_u16("IonDamage"));
			}
		}
	}

	{
		CBlob@[] blobs;
		
		getBlobsByName("engine_room", blobs);
		
		float Amount = 0;
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				Amount += blob.get_u8("Level");
			}
		}
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				blob.set_f32("Power",(this.get_u8("Power_Engines")*1.0f)/Amount*((blob.get_u8("Level")-blob.get_u8("Damage"))*1.0f)-blob.get_u16("IonDamage"));
			}
		}
	}
	
	{
		CBlob@[] blobs;
		
		getBlobsByName("shield_generator", blobs);
		
		float Amount = 0;
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				Amount += blob.get_u8("Level");
			}
		}
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				blob.set_f32("Power",(this.get_u8("Power_Shields")*1.0f)/Amount*((blob.get_u8("Level")-blob.get_u8("Damage"))*1.0f)-blob.get_u16("IonDamage"));
			}
		}
	}
	
	{
		CBlob@[] blobs;
		
		getBlobsByName("weapon_room", blobs);
		
		float Amount = 0;
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				Amount += blob.get_u8("Level");
			}
		}
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			if(blob.getTeamNum() == this.getTeamNum()){
				blob.set_f32("Power",(this.get_u8("Power_Weapons")*1.0f)/Amount*((blob.get_u8("Level")-blob.get_u8("Damage"))*1.0f)-blob.get_u16("IonDamage"));
			}
		}
	}
	
	//Zoltans
	{ 
		for(int s = 0;s < system_Amount;s+=1)
		{
			this.set_u8("Zoltan_"+systemNames[s],0);
		}
		
		CBlob@[] blobs;
		
		getBlobsByName("zoltan", blobs);
		
		for (u32 k = 0; k < blobs.length; k++)
		{
			CBlob@ blob = blobs[k];
			
			if(blob.getTeamNum() != this.getTeamNum())continue;
			
			CBlob@[] rooms;
		
			getBlobsByTag("room", rooms);

			for (u32 l = 0; l < rooms.length; l++)
			{
				CBlob@ room = rooms[l];
				if(room.getTeamNum() != this.getTeamNum())continue;
				if(Maths::Sqrt(Maths::Pow(blob.getPosition().x-room.getPosition().x, 2)+Maths::Pow(blob.getPosition().y-room.getPosition().y, 2)) < 20){
					room.set_f32("Power",room.get_f32("Power")+1.0f);
					if(room.get_f32("Power") > room.get_u8("Level")-room.get_u8("Damage"))room.set_f32("Power",room.get_u8("Level")-room.get_u8("Damage"));
					
					if(room.getName() == "shield_generator")this.set_u8("Zoltan_Shields",this.get_u8("Zoltan_Shields")+1);
					if(room.getName() == "engine_room")this.set_u8("Zoltan_Engines",this.get_u8("Zoltan_Engines")+1);
					if(room.getName() == "oxygen_generator")this.set_u8("Zoltan_Oxygen",this.get_u8("Zoltan_Oxygen")+1);
					if(room.getName() == "cloning_bay")this.set_u8("Zoltan_Cloning",this.get_u8("Zoltan_Cloning")+1);
					if(room.getName() == "weapon_room")this.set_u8("Zoltan_Weapons",this.get_u8("Zoltan_Weapons")+1);
					
					break;
				}
			}
		}
	}
}


void PilotControl(CBlob @this){

	if(getNet().isClient()){
	
		if(getLocalPlayer() is null)return;
		if(getLocalPlayer().getBlob() is null)return;
		if(!getLocalPlayer().getBlob().isAttachedToPoint("PILOT"))return;
		if(getLocalPlayer().getBlob().getTeamNum() != this.getTeamNum())return;
	
		int GUIScale = 2;
	
		int SysX = 0;
	
		CControls @controls = getControls();
		if(!this.hasTag("click")){
			for(int s = 0;s < system_Amount;s+=1)
			{
			
				if(this.get_u8("Bars_"+systemNames[s])-this.get_u8("Damaged_"+systemNames[s]) > 0){
				
					if(controls.getMouseScreenPos().x > 24*GUIScale+(SysX*20*GUIScale)+16*GUIScale && getControls().getMouseScreenPos().x < 24*GUIScale+(SysX*20*GUIScale)+32*GUIScale){

						if(controls.mousePressed1){
							if(this.get_u8("Bars_"+systemNames[s])-this.get_u8("Damaged_"+systemNames[s]) <= this.get_u8("Power_"+systemNames[s]))Sound::Play("cant_power.ogg");
							else Sound::Play("power_up.ogg");
							this.Tag("click");
							CBitStream bt;
							bt.write_u8(u8(s));
							bt.write_bool(true);
							this.SendCommand(this.getCommandID("power_handle"), bt);
						}
						if(controls.mousePressed2){
							this.Tag("click");
							CBitStream bt;
							bt.write_u8(u8(s));
							bt.write_bool(false);
							this.SendCommand(this.getCommandID("power_handle"), bt);
							Sound::Play("power_down.ogg");
						}
						
						
						
					}
					
					
					SysX += 1;
				
				}
			}
			
			if(controls.mousePressed1){
				if(controls.getMouseScreenPos().x > getScreenWidth()/2-60*GUIScale && controls.getMouseScreenPos().x < getScreenWidth()/2+60*GUIScale && controls.getMouseScreenPos().y < 52*GUIScale && controls.getMouseScreenPos().y > 4*GUIScale){
					
					this.SendCommand(this.getCommandID("ftl_jump"));
					this.Tag("click");
				}
			}
		} else {
			if(!controls.mousePressed1 && !controls.mousePressed2)this.Untag("click");
		}
		
		
	}
	
}





void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	bool isServer = getNet().isServer();

	if (isServer && cmd == this.getCommandID("power_handle"))
	{
		int system_number = 0;
		system_number = params.read_u8();
		
		bool OnOff = params.read_bool();
		
		string name = systemNames[system_number];
		
		if(OnOff){
			if(this.get_u8("CurrentPower") > 0 && this.get_u8("Bars_"+name)-this.get_u8("Damaged_"+name) > this.get_u8("Power_"+name)){
				this.set_u8("Power_"+name,this.get_u8("Power_"+name)+1);
				this.set_u8("CurrentPower",this.get_u8("CurrentPower")-1);
				this.Sync("Power_"+name,true);
				this.Sync("CurrentPower",true);
			}
		} else {
			if(this.get_u8("Power_"+name) > 0){
				this.set_u8("Power_"+name,this.get_u8("Power_"+name)-1);
				this.set_u8("CurrentPower",this.get_u8("CurrentPower")+1);
				this.Sync("Power_"+name,true);
				this.Sync("CurrentPower",true);
			}
		}
	}
	
	if (cmd == this.getCommandID("ftl_jump"))
	{
		if(this.get_u16("FTLDrive") >= this.get_u16("FTLDriveMax")){
			
			this.set_u16("FTLDrive",0);
			this.Tag("first_jump");
			
			Sound::Play("ftl_soon.ogg");
			
			if(isServer){
				this.Sync("FTLDrive",true);
				this.Sync("first_jump",true);
				server_CreateBlob("event_loader",0,this.getPosition());
			}
		}
	}
}


void onRender(CSprite@ this)
{
	CBlob@ blob = this.getBlob();

	if(getLocalPlayer() is null)return;
	if(getLocalPlayer().getBlob() !is null)
	if(getLocalPlayer().getBlob().getTeamNum() != blob.getTeamNum())return;
	
	int GUIScale = 2;
	
	int Power = blob.get_u8("CurrentPower");
	int PowerMax = blob.get_u8("MaxPower");
	
	int Y = getScreenHeight()-24*GUIScale;
	
	for(int p = PowerMax-1;p >= 0; p -= 1){
	
		if(p < Power)GUI::DrawIcon("PowerBars.png", 1, Vec2f(20,5), Vec2f(4*GUIScale,Y-(p*6*GUIScale)));
		else GUI::DrawIcon("PowerBars.png", 0, Vec2f(20,5), Vec2f(4*GUIScale,Y-(p*6*GUIScale)));
		
		if(p < Power)GUI::DrawIcon("PowerBarLinks.png", 1, Vec2f(8,12), Vec2f(25*GUIScale,Y+2*GUIScale-(p*6*GUIScale)));
		else GUI::DrawIcon("PowerBarLinks.png", 0, Vec2f(8,12), Vec2f(25*GUIScale,Y+2*GUIScale-(p*6*GUIScale)));
	
	}
	
	int PowerUp = 3;
	if(Power > 0)PowerUp = 0;
	
	GUI::DrawIcon("PowerLinks.png", PowerUp, Vec2f(16,8), Vec2f(25*GUIScale,Y+14*GUIScale));
	
	int SysX = 0;
	
	for(int s = 0;s < system_Amount;s+=1){
		
		int SystemPower = 0;
		int SystemMax = 0;
		int SystemZoltan = 0;
		int SystemDamage = 0;
		
		string name = systemNames[s];
		
		SystemZoltan = blob.get_u8("Zoltan_"+name);
		SystemPower = blob.get_u8("Power_"+name)+SystemZoltan;
		SystemMax = blob.get_u8("Bars_"+name);
		SystemDamage = blob.get_u8("Damaged_"+name);
		
		if(SystemMax > 0){
		
			GUI::DrawIcon("PowerLinks.png", PowerUp+2, Vec2f(16,8), Vec2f(25*GUIScale+(SysX*20*GUIScale)+12*GUIScale,Y+14*GUIScale));
			if(SysX != 0)GUI::DrawIcon("PowerLinks.png", PowerUp+1, Vec2f(16,8), Vec2f(25*GUIScale+(SysX*20*GUIScale)-2*GUIScale,Y+14*GUIScale));
			
			GUI::DrawIcon("PowerIcons.png", s, Vec2f(16,16), Vec2f(24*GUIScale+(SysX*20*GUIScale)+16*GUIScale,Y-4*GUIScale));
			
			for(int p = 0;p < SystemMax;p+=1){
				if(p < SystemPower)GUI::DrawIcon("MiniPowerBars.png", 1, Vec2f(12,4), Vec2f(26*GUIScale+(SysX*20*GUIScale)+16*GUIScale,Y-12*GUIScale-p*6*GUIScale));
				else GUI::DrawIcon("MiniPowerBars.png", 0, Vec2f(12,4), Vec2f(26*GUIScale+(SysX*20*GUIScale)+16*GUIScale,Y-12*GUIScale-p*6*GUIScale));
				if(p < SystemZoltan)GUI::DrawIcon("MiniPowerBars.png", 2, Vec2f(12,4), Vec2f(26*GUIScale+(SysX*20*GUIScale)+16*GUIScale,Y-12*GUIScale-p*6*GUIScale));
			}
			
			SysX += 1;
		
		}
	}
	
	Y = 4*GUIScale;
	
	int FTLLength = 10;
	float FTLCharge = (blob.get_u16("FTLDrive")*1.0f)/(blob.get_u16("FTLDriveMax")*1.0f);
	
	bool Charged = false;
	
	if(FTLCharge >= 1.0f)Charged = true;
	
	CBlob@[] blobs;
	
	getBlobsByName("event_loader", blobs);
	
	if(blobs.length > 0)Charged = true;
	
	for(int b = 0;b < FTLLength;b+=1){
	
		int image = 1;
		
		if(b == 0)image = 0;
		if(b == FTLLength-1)image = 2;
		
		GUI::DrawIcon("FTLJumpBar.png", image, Vec2f(12,48), Vec2f(getScreenWidth()/2+b*12*GUIScale-FTLLength*6*GUIScale,Y));
		
		if(!Charged){
			if(b+1 < FTLLength*FTLCharge)GUI::DrawIcon("FTLJumpBar.png", image+3, Vec2f(12,48), Vec2f(getScreenWidth()/2+b*12*GUIScale-FTLLength*6*GUIScale,Y));
		} else {
			GUI::DrawIcon("FTLJumpBar.png", image+6, Vec2f(12,48), Vec2f(getScreenWidth()/2+b*12*GUIScale-FTLLength*6*GUIScale,Y));
		}
	
	}
	
	if(Charged){
		if(blobs.length > 0)
		{
			if(blobs[0].get_u16("timer") <= 10*30)GUI::DrawIcon("JUMPSOON.png", 0, Vec2f(96,48), Vec2f(getScreenWidth()/2-48*GUIScale,Y));
			else GUI::DrawIcon("JUMPING.png", 0, Vec2f(98,48), Vec2f(getScreenWidth()/2-48*GUIScale,Y));
		}
		else 
			GUI::DrawIcon("JUMP.png", 0, Vec2f(96,48), Vec2f(getScreenWidth()/2-48*GUIScale,Y));
	}
	
	v_showminimap = false;
	
}