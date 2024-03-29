
#include "BombCommon.as";

void onInit(CBlob@ this)
{
	CShape@ shape = this.getShape();
	ShapeConsts@ consts = shape.getConsts();
	consts.bullet = true;
	consts.net_threshold_multiplier = 4.0f;
	this.Tag("projectile");

	//dont collide with top of the map
	this.SetMapEdgeFlags(0);

	this.server_SetTimeToDie(100);
	
	this.getSprite().SetLighting(false);
	this.getSprite().SetZ(-49.0f);
	
	this.SetLight(true);
	this.SetLightRadius(8);
	this.SetLightColor(SColor(255, 0, 255, 0));
	
	//this.set_u16("birth",getMap().getTimeSinceStart());
	
	this.Tag("laser");
	this.set_u8("Damage", 2);
}

void onTick(CBlob@ this)
{
	CShape@ shape = this.getShape();

	f32 angle;

	angle = (this.getVelocity()).Angle();
	this.setAngleDegrees(-angle);

	shape.SetGravityScale(0.0f);
	/*
	if(this.get_u16("birth") < getMap().getTimeSinceStart()-10){
		CBlob @laser = server_CreateBlob("heavy_laser",this.getTeamNum(),this.getPosition());
		if(laser !is null)laser.setVelocity(this.getVelocity());
		this.server_Die();
	}*/
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if(blob !is null)if(blob.getName() == "pilots_seat" || blob.hasTag("projectiles_ignore_me"))return;
	
	if(blob !is null)
	if(blob.getName() == "shield" && this.getTeamNum() != blob.getTeamNum())
	{
		blob.server_Die();
		Sound::Play("shield_pop.ogg");
		this.server_Die();
	}
	
	if(this !is null && blob !is null)
	if((blob.getName() == "turret" || blob.hasTag("room")) && this.getTeamNum() != blob.getTeamNum())
	{
		if(getNet().isServer())this.server_setTeamNum(10);
		SetupBomb(this, 10, 48.0f, 40.0f, 12.0f, 1.0f, true);
		Sound::Play("laser_hull_hit.ogg");
		this.server_Die();
	}
	
	if(solid){
		if(getNet().isServer())this.server_setTeamNum(10);
		SetupBomb(this, 10, 48.0f, 40.0f, 12.0f, 1.0f, true);
		Sound::Play("laser_hull_hit.ogg");
		this.server_Die();
	}
	
	
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if(blob.hasTag("projectile") || blob.hasTag("projectiles_ignore_me"))
	{
		return false;
	}
	
	if(blob.getName() == "pilots_seat")
	{
		return false;
	}
	
	if(blob.getName() == "shield" && this.getTeamNum() != blob.getTeamNum())
	{
		return true;
	}

	bool check = this.getTeamNum() != blob.getTeamNum();
	if (!check)
	{
		CShape@ shape = blob.getShape();
		check = (shape.isStatic() && !shape.getConsts().platform);
	}

	if (check)
	{
		if (this.getShape().isStatic() ||
		        this.hasTag("collided") ||
		        blob.hasTag("dead") ||
		        blob.hasTag("ignore_arrow"))
		{
			return false;
		}
		else
		{
			return true;
		}
	}

	return false;
}