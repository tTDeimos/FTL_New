// TrapBlock.as

#include "Hitters.as";
#include "MapFlags.as";

int openRecursion = 0;

void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(false);

	this.set_bool("open", false);
	// this.Tag("place norotate");

	//block knight sword
	this.Tag("blocks sword");
	this.Tag("blocks water");
	this.Tag("builder always hit");

	this.set_TileType("background tile", CMap::tile_wood_back);

	MakeDamageFrame(this);
	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	
	this.SetLight(false);
	this.SetLightRadius(8.0f);
	this.SetLightColor(SColor(255, 255, 255, 255));
}

void onTick(CBlob @ this){

	//if(getLocalPlayerBlob() !is null){
	//	if(this.getTeamNum() == getLocalPlayerBlob().getTeamNum())this.SetLight(true);
	//	else this.SetLight(false);
	//}
}

//TODO: fix flags sync and hitting
/*void onDie( CBlob@ this )
{
	SetSolidFlag(this, false);
}*/

void onSetStatic(CBlob@ this, const bool isStatic)
{
	CSprite@ sprite = this.getSprite();
	if (sprite is null) return;

	sprite.getConsts().accurateLighting = true;

	if (!isStatic) return;

	this.getSprite().PlaySound("/build_door.ogg");
}

void onHealthChange(CBlob@ this, f32 oldHealth)
{
	if (!isOpen(this))
	{
		MakeDamageFrame(this);
	}
}

void MakeDamageFrame(CBlob@ this)
{
	f32 hp = this.getHealth();
	f32 full_hp = this.getInitialHealth();
	int frame = (hp > full_hp * 0.9f) ? 0 : ((hp > full_hp * 0.4f) ? 1 : 2);
	this.getSprite().animation.frame = frame;
}

bool isOpen(CBlob@ this)
{
	return !this.getShape().getConsts().collidable;
}

void setOpen(CBlob@ this, bool open)
{
	CSprite@ sprite = this.getSprite();

	if (open)
	{
		sprite.SetZ(-100.0f);
		// sprite.animation.frame = 3;
		sprite.SetAnimation("open");
		this.getShape().getConsts().collidable = false;

		const uint touching = this.getTouchingCount();
		for (uint i = 0; i < touching; i++)
		{
			CBlob@ t = this.getTouchingByIndex(i);
			if (t is null) continue;

			t.AddForce(Vec2f_zero); // forces collision checks again
		}
		Sound::Play("airlock_open.ogg");
	}
	else
	{
		sprite.SetZ(100.0f);
		sprite.SetAnimation("close");
		// MakeDamageFrame(this);
		this.getShape().getConsts().collidable = true;
	}

	//TODO: fix flags sync and hitting
	//SetSolidFlag(this, !open);

	if (this.getTouchingCount() <= 1 && openRecursion < 5)
	{
		SetBlockAbove(this, open);
		openRecursion++;
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return !opensThis(this, blob) && !isOpen(this);
}

bool opensThis(CBlob@ this, CBlob@ blob)
{
	return ((blob.getTeamNum() == this.getTeamNum() || true) &&
	        !isOpen(this) && blob.isCollidable() &&
	        (blob.hasTag("player") || blob.hasTag("vehicle"))) || (this.getTeamNum() == 255);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	if (opensThis(this, blob))
	{
		openRecursion = 0;
		setOpen(this, true);
	}
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
	if (blob is null) return;

	bool touching = false;
	const uint count = this.getTouchingCount();
	for (uint step = 0; step < count; ++step)
	{
		CBlob@ blob = this.getTouchingByIndex(step);
		if (blob.isCollidable())
		{
			touching = true;
			break;
		}
	}

	if (!touching)
	{
		setOpen(this, false);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

void SetBlockAbove(CBlob@ this, const bool open)
{
	CBlob@ blobAbove = getMap().getBlobAtPosition(this.getPosition() + Vec2f(0, -8));
	if (blobAbove is null || blobAbove.getName() != "trap_block") return;

	setOpen(blobAbove, open);
}