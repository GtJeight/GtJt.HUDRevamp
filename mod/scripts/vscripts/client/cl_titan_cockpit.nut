untyped

global function ClTitanCockpit_Init

global function ServerCallback_TitanEMP
global function ServerCallback_TitanCockpitBoot
global function TitanCockpit_DamageFeedback
global function TitanCockpit_AddPlayer
global function RegisterTitanBindings
global function GetTitanBindings
global function DeregisterTitanBindings
global function ServerCallback_TitanEmbark
global function ServerCallback_TitanDisembark
global function PlayerPressed_EjectEnable // so can be called directly for debugging
global function PlayerPressed_Eject // so can be called directly for debugging
global function TitanCockpit_IsBooting
global function ServerCallback_TitanCockpitEMP
global function TitanCockpit_EMPFadeScale
global function TitanCockpit_DoEMP
global function TitanEMP_Internal
global function ServerCallback_EjectConfirmed
global function LinkCoreHint

global function AddTitanCockpitManagedRUI
global function UpdateTitanCockpitVisibility
global function TitanCockpitDestroyRui
global function TitanCockpitDoomedThink
global function PlayerEjects
global function IsDisplayingEjectInterface
global function FlashCockpitLight
global function PlayCockpitSparkFX

global function FlashCockpitHealth

global function UpdateEjectHud_SetButtonPressTime
global function UpdateEjectHud_SetButtonPressCount

global function SetUnlimitedDash
#if MP
global function NetworkedVarChangedCallback_UpdateVanguardRUICoreStatus
global function DisplayFrontierRank
#endif

struct TitanCockpitManagedRUI
{
	bool exists = false
	var functionref() create
	void functionref() destroy
	bool functionref() shouldCreate
	int drawGroup = RUI_DRAW_COCKPIT
}

const TITAN_ALARM_SOUND 		= "titan_alarm"
const TITAN_NUCLEAR_DEATH_ALARM = "titan_nuclear_death_alarm"
const TITAN_EJECT_BOOST			= "titan_eject_boost"
const TITAN_EJECT_ASCENT		= "player_eject_windrush"
const TITAN_EJECT_APEX			= "player_eject_apex_wind"
const TITAN_EJECT_DESCENT		= "player_fallingdescent_windrush"

const EJECT_MIN_VELOCITY = 200.0
const EJECT_MAX_VELOCITY = 1000.0

enum eHUDCoreTimer {
	number,
	text,
	legion,
	hybrid
}

struct
{
	var coreHintRui
	var cockpitRui
	var cockpitLowerRui
	var cockpitAdditionalRui
	array<TitanCockpitManagedRUI> titanCockpitManagedRUIs

	string lastPilotSettings

	bool isFirstBoot = true
	var scorchHotstreakRui

	// GtJt HUD
	var smartCoreHud
	var healthHud
	var shieldHud
	var coreTimerNumHud
	var coreTimerTextHud
	var ionEnergyNumHud
	bool coreFired = false
	bool isMenuOpen = false
	// GtJt HUD
} file

// GtJt HUD
struct {
	vector healthPos = Vector(0.0, -0.2875, 0.0)
    vector shieldPos = Vector(0.0, -0.3475, 0.0)
} settings
// GtJt HUD

function ClTitanCockpit_Init()
{
	if ( reloadingScripts )
		return

	RegisterSignal( "DisembarkCheck" )
	RegisterSignal( "Rumble_Forward_End" )
	RegisterSignal( "Rumble_Back_End" )
	RegisterSignal( "Rumble_Left_End" )
	RegisterSignal( "Rumble_Right_End" )
	RegisterSignal( "EMP" )
	RegisterSignal( "Ejecting" )
	RegisterSignal( "TitanEMP_Internal" )
	RegisterSignal( "TitanUnDoomed" )
	RegisterSignal( "MonitorPlayerEjectAnimBeingStuck" )
	RegisterSignal( "DisplayFrontierRank" )

	PrecacheParticleSystem( $"xo_cockpit_spark_01" )

	if ( !IsModelViewer() && !IsLobby() )
	{
		AddCreateCallback( "titan_cockpit", TitanCockpitInit )
	}

	if ( !reloadingScripts )
	{
		level.cockpitGeoRef <- null
	}

	AddPlayerFunc( TitanCockpit_AddPlayer )

	AddCinematicEventFlagChangedCallback( CE_FLAG_TITAN_3P_CAM, CinematicEventFlagChanged )
	AddCinematicEventFlagChangedCallback( CE_FLAG_INTRO, CinematicEventFlagChanged )

	AddCallback_PlayerClassChanged( UpdateLastPlayerSettings )

	AddTitanCockpitManagedRUI( Scorch_CreateHotstreakBar, Scorch_DestroyHotstreakBar, Scorch_ShouldCreateHotstreakBar, RUI_DRAW_COCKPIT ) //RUI_DRAW_HUD
	AddTitanCockpitManagedRUI( SmartCore_CreateHud, SmartCore_DestroyHud, ShouldCreateHud, RUI_DRAW_COCKPIT )
	AddTitanCockpitManagedRUI( Health_CreateHud, Health_DestroyHud, ShouldCreateHud, RUI_DRAW_COCKPIT )
	AddTitanCockpitManagedRUI( Shield_CreateHud, Shield_DestroyHud, ShouldCreateHud, RUI_DRAW_COCKPIT )
	AddTitanCockpitManagedRUI( CoreTimerNum_CreateHud, CoreTimerNum_DestroyHud, ShouldCreateHud, RUI_DRAW_COCKPIT )
	AddTitanCockpitManagedRUI( CoreTimerText_CreateHud, CoreTimerText_DestroyHud, ShouldCreateHud, RUI_DRAW_COCKPIT )
	AddTitanCockpitManagedRUI( IonEnergyNum_CreateHud, IonEnergyNum_DestroyHud, IsPlayerIon, RUI_DRAW_COCKPIT )
}

// GtJt HUD

// void function UpdateTitanCockpitAdditionalRuis(entity player)
// {
// 	if ( file.cockpitRui == null )
// 		return
// 	// updated in cl_weapon_status
// 	UpdateTitanHealthNumberRui(player)
// 	UpdateCoreTimer(player)
// 	UpdateIonEnergyNumber(player)
// }

float lastShieldStateChangeTime = -5.0;
int lastShieldHealth = 0;


void function UpdateTitanHealthNumberRui(entity player)
{
	// update titan health
	RuiSetFloat( file.healthHud, "msgAlpha", GetConVarBool("comp_hud_healthbar") ? 0.9 : 0.0 )
	RuiSetString( file.healthHud, "msgText", player.GetHealth().tostring())
	RuiSetFloat2( file.healthHud, "msgPos", settings.healthPos + (GetConVarBool("comp_hud_healthbar_overlap") ? <0.0, -0.0225, 0.0> : <0,0,0>))

	// update titan shield
	entity soul = player.GetTitanSoul()
	if (!IsValid(soul))
		return
	int shieldHealth = soul.GetShieldHealth()
	if (shieldHealth > 0 && GetConVarBool("comp_hud_healthbar"))
	{
		if (lastShieldHealth <= 0)
		{
			lastShieldHealth = 1;
			lastShieldStateChangeTime = Time()
		}

		RuiSetFloat( file.shieldHud, "msgAlpha", 0.9 )
	}
	else
	{
		if (lastShieldHealth > 0)
		{
			lastShieldHealth = 0;
			lastShieldStateChangeTime = Time()
		}

		RuiSetFloat( file.shieldHud, "msgAlpha", 0.0 )
	}
	RuiSetString(file.shieldHud, "msgText", shieldHealth.tostring())
}

void function UpdateCoreTimer(entity player)
{
	// update core timer
	if (!GetConVarBool("comp_core_meter_timer") || !IsAlive(player) || !player.IsTitan())
		return

	entity soul = player.GetTitanSoul()
	if (!IsValid(soul))
		return

	string titanName = GetTitanCharacterName( player )
	if ( titanName == "ronin" )
	{
		float curTime = Time()
		float remainingTime = soul.GetCoreChargeExpireTime() - curTime
		if (remainingTime > 0.0)
		{
			if (!file.coreFired)
			{
				file.coreFired = true
			}
			int style = GetConVarInt("comp_core_meter_timer_style")
			switch (style)
			{
				case eHUDCoreTimer.number:
					UpdateNumberCoreTimer(remainingTime)
					break
				case eHUDCoreTimer.text:
					string text = format(Localize("#hud_core_timer_laser"), remainingTime)
					UpdateTextCoreTimer(text)
					break
				case eHUDCoreTimer.legion:
					UpdateLegionCoreTimer(player, remainingTime)
					break
				case eHUDCoreTimer.hybrid:
					UpdateLegionCoreTimer(player, remainingTime)
					string text = format(Localize("#hud_core_timer_laser"), remainingTime)
					UpdateTextCoreTimer(text)
				default:
					break
			}
		}
		else
		{
			if (file.coreFired)
			{
				player.p.smartCoreKills = 0
				file.coreFired = false
			}
			HideCoreTimers() // TODO only hide when menu close and on core disable?
		}
	}
	else if ( titanName == "ion" )
	{
		entity weapon = player.GetOffhandWeapon( OFFHAND_EQUIPMENT )
		if (!IsValid(weapon))
			return
		float coreFrac = weapon.GetSustainedDischargeFraction()
		float curTime = Time()
		float remainingTimeFake = soul.GetCoreChargeExpireTime() - curTime
		float duration = weapon.GetSustainedDischargeDuration()
		if (coreFrac > 0.0)
		{
			// real core
			if (!file.coreFired)
			{
				file.coreFired = true
			}
			float remainingTime = (1 - coreFrac) * duration
			int style = GetConVarInt("comp_core_meter_timer_style")
			switch (style)
			{
				case eHUDCoreTimer.number:
					UpdateNumberCoreTimer(remainingTime)
					// Hide ion fake core timer
					HideCoreTimer_Text()
					break
				case eHUDCoreTimer.text:
					string text = format(Localize("#hud_core_timer_laser"), remainingTime)
					UpdateTextCoreTimer(text)
					break
				case eHUDCoreTimer.legion:
					UpdateLegionCoreTimer(player, remainingTime)
					// Hide ion fake core timer
					HideCoreTimer_Text()
					break
				case eHUDCoreTimer.hybrid:
					UpdateLegionCoreTimer(player, remainingTime)
					string text = format(Localize("#hud_core_timer_laser"), remainingTime)
					UpdateTextCoreTimer(text)
				default:
					break
			}
		}
		else if (remainingTimeFake > 0.0)
		{
			if (file.coreFired)
			{
				// fake core
				HideCoreTimer_Smart()
				HideCoreTimer_Num()
				string text = format(Localize("#hud_core_timer_fake_laser"), remainingTimeFake)
				UpdateTextCoreTimer(text)
			}
			else if (remainingTimeFake > duration)
			{
				// core fire standby
				string text = format(Localize("#hud_core_timer_standby"), remainingTimeFake - duration)
				UpdateTextCoreTimer(text)
			}
		}
		else
		{
			if (file.coreFired)
			{
				player.p.smartCoreKills = 0
				file.coreFired = false
			}
			HideCoreTimers()
		}
	}
	else
	{
		HideCoreTimers()
	}
}

void function UpdateTitanCockpitAdditionalRuis_Thread(entity cockpit)
{
	entity player = GetLocalViewPlayer()
	player.EndSignal( "OnDeath" )
	cockpit.EndSignal( "OnDestroy" )
	player.EndSignal( "LocalPlayerDisconnected" )

	while(IsAlive(player) && IsValid(cockpit))
	{
		if (GetGameState() >= eGameState.Epilogue)
		{
			// printt("UpdateTitanCockpitAdditionalRuis_Thread not playing")
			return
		}
		if (clGlobal.isMenuOpen)
		{
			if (!file.isMenuOpen)
			{
				file.isMenuOpen = true
			}
			MenuOpen()
		}
		else
		{
			if (file.isMenuOpen)
			{
				file.isMenuOpen = false
			}
			UpdateTitanHealthNumberRui(player)
			UpdateCoreTimer(player)
			if (IsPlayerIon())
			{
				UpdateIonEnergyNumber(player)
				UpdateIonEnergyBar(player)
			}
		}
		WaitFrame()
	}
}

void function UpdateNumberCoreTimer(float remainingTime)
{
	RuiSetFloat2( file.coreTimerNumHud, "msgPos", GetConVarFloat3("comp_core_meter_timer_pos3") )
	RuiSetFloat( file.coreTimerNumHud, "msgFontSize", GetConVarFloat("comp_core_meter_timer_size") )
	RuiSetFloat( file.coreTimerNumHud, "msgAlpha", 0.9)
	RuiSetString( file.coreTimerNumHud, "msgText", format("%.2f", remainingTime))
}

void function UpdateTextCoreTimer(string text)
{
	RuiSetString( file.coreTimerTextHud, "lockMessage", text)
	RuiSetBool( file.coreTimerTextHud, "isVisible", true )
}

void function UpdateLegionCoreTimer(entity player, float remainingTime) {
	UpdateLegionCoreTimerInternal(player.p.smartCoreKills, remainingTime, player.GetZoomFrac())
}

void function UpdateLegionCoreTimerInternal(int kills, float remainingTime, float zoomFrac)
{
	RuiSetBool( file.smartCoreHud, "isLocked", GetConVarBool("comp_core_meter_timer_legion_color") )
	RuiSetString( file.smartCoreHud, "remainingTime", TimeToString( remainingTime, true, remainingTime > 60.0 ) )
	RuiSetString( file.smartCoreHud, "killCountText", format("X %i", kills) )
	RuiSetFloat( file.smartCoreHud, "zoomFrac", zoomFrac )
	RuiSetBool( file.smartCoreHud, "hasCloseRangeAmmo", false )
	RuiSetFloat( file.smartCoreHud, "smartCoreStatus", 1.00 )
}

void function HideCoreTimer_Num()
{
	RuiSetFloat( file.coreTimerNumHud, "msgAlpha", 0.0 )
}

void function HideCoreTimer_Text()
{
	RuiSetBool( file.coreTimerTextHud, "isVisible", false )
}

void function HideCoreTimer_Smart()
{
	RuiSetFloat( file.smartCoreHud, "smartCoreStatus", 0.00 )
}

void function HideCoreTimers()
{
	RuiSetFloat( file.coreTimerNumHud, "msgAlpha", 0.0 )
	RuiSetBool( file.coreTimerTextHud, "isVisible", false )
	RuiSetFloat( file.smartCoreHud, "smartCoreStatus", 0.00 )
}

var function SmartCore_CreateHud()
{
	Assert( file.smartCoreHud == null )

	file.smartCoreHud = CreateTitanCockpitRui( $"ui/smart_core.rpak" )
	RuiSetFloat( file.smartCoreHud, "smartCoreStatus", 0.00 )
	return file.smartCoreHud
}

void function SmartCore_DestroyHud()
{
	TitanCockpitDestroyRui( file.smartCoreHud )
	file.smartCoreHud = null
}

bool function ShouldCreateHud()
{
	entity player = GetLocalViewPlayer()
	return IsValid( player ) && IsAlive( player ) && player.IsTitan()
}

bool function IsPlayerIon() {
	entity player = GetLocalViewPlayer()
	if (IsValid( player ) && IsAlive( player ) && player.IsTitan())
	{
		return GetTitanCharacterName( player ) == "ion"
	}
	return false
}

void function UpdateIonEnergyNumber(entity player)
{
	if (!IsPlayerIon())
		return

	string text = player.GetSharedEnergyCount().tostring()
	if (GetConVarBool("comp_hud_ion_vortex_abosorbed_count") && ShouldRunPSGD())
	{
		entity weapon = player.GetActiveWeapon()
		if(weapon.GetWeaponClassName() == "mp_titanweapon_vortex_shield_ion")
		{
			int bullets = GetBulletsAbsorbedCount( weapon )
			int projectiles = GetProjectilesAbsorbedCount( weapon )
			if(bullets > 0)
			{
				text += format("\nBullets:%i/32", bullets)
			}
			if(projectiles > 0)
			{
				text += format("\nProjectiles:%i/32", projectiles)
			}
		}
	}
	UpdateIonEnergyNumberInternal(text)
}

void function UpdateIonEnergyNumberInternal(string text)
{
	if(GetConVarBool("comp_hud_ion_energy_enabled"))
	{
		RuiSetFloat2( file.ionEnergyNumHud, "msgPos", GetConVarFloat3("comp_hud_ion_energy_pos") )
		RuiSetFloat( file.ionEnergyNumHud, "msgFontSize", GetConVarFloat("comp_hud_ion_energy_size") )
		RuiSetFloat3( file.ionEnergyNumHud, "msgColor", GetConVarFloat3("comp_hud_ion_energy_color") / 255.0 )
		RuiSetString( file.ionEnergyNumHud, "msgText", text )
		RuiSetFloat( file.ionEnergyNumHud, "msgAlpha", 0.9 )
	}
	else
	{
		RuiSetString( file.ionEnergyNumHud, "msgText", "" )
		RuiSetFloat( file.ionEnergyNumHud, "msgAlpha", 0.0 )
	}
}

var function Health_CreateHud()
{
	Assert( file.healthHud == null )

	file.healthHud = CreateTitanCockpitRui( $"ui/cockpit_console_text_center.rpak", 5)
	RuiSetInt( file.healthHud, "maxLines", 1 )
	RuiSetInt( file.healthHud, "lineNum", 1 )
	RuiSetFloat2( file.healthHud, "msgPos", settings.healthPos )
	RuiSetString( file.healthHud, "msgText", "")
	RuiSetFloat( file.healthHud, "msgFontSize", 32.0 )
	RuiSetFloat3( file.healthHud, "msgColor", GetAccentColor() )
	RuiSetFloat( file.healthHud, "msgAlpha", 0.0 )
	RuiSetFloat( file.healthHud, "thicken", 0.0 )
	return file.healthHud
}

void function Health_DestroyHud()
{
	TitanCockpitDestroyRui( file.healthHud )
	file.healthHud = null
}

var function Shield_CreateHud()
{
	Assert( file.shieldHud == null )

	file.shieldHud = CreateTitanCockpitRui( $"ui/cockpit_console_text_center.rpak", 5)
	RuiSetInt( file.shieldHud, "maxLines", 1 )
	RuiSetInt( file.shieldHud, "lineNum", 1 )
	RuiSetFloat2( file.shieldHud, "msgPos", settings.shieldPos )
	RuiSetString( file.shieldHud, "msgText", "")
	RuiSetFloat( file.shieldHud, "msgFontSize", 32.0 )
	RuiSetFloat3( file.shieldHud, "msgColor", <0.33, 0.6, 1> )
	RuiSetFloat( file.shieldHud, "msgAlpha", 0.0 )
	RuiSetFloat( file.shieldHud, "thicken", 0.0 )
	return file.shieldHud
}

void function Shield_DestroyHud()
{
	TitanCockpitDestroyRui( file.shieldHud )
	file.shieldHud = null
}

var function CoreTimerNum_CreateHud()
{
	Assert( file.coreTimerNumHud == null )

	file.coreTimerNumHud = CreateTitanCockpitRui( $"ui/cockpit_console_text_center.rpak")
	RuiSetInt( file.coreTimerNumHud, "maxLines", 1 )
	RuiSetInt( file.coreTimerNumHud, "lineNum", 1 )
	RuiSetFloat2( file.coreTimerNumHud, "msgPos", GetConVarFloat3("comp_core_meter_timer_pos3") )
	RuiSetString( file.coreTimerNumHud, "msgText", "")
	RuiSetFloat( file.coreTimerNumHud, "msgFontSize", GetConVarFloat("comp_core_meter_timer_size") )
	RuiSetFloat3( file.coreTimerNumHud, "msgColor", GetAccentColor(true) )
	RuiSetFloat( file.coreTimerNumHud, "msgAlpha", 0.0 )
	RuiSetFloat( file.coreTimerNumHud, "thicken", 0.0 )
	return file.coreTimerNumHud
}

void function CoreTimerNum_DestroyHud()
{
	TitanCockpitDestroyRui( file.coreTimerNumHud )
	file.coreTimerNumHud = null
}

var function CoreTimerText_CreateHud()
{
	Assert( file.coreTimerTextHud == null )

	file.coreTimerTextHud = CreateTitanCockpitRui( $"ui/lockon_hud.rpak" )
	RuiSetString( file.coreTimerTextHud, "lockMessage", "")
	RuiSetGameTime( file.coreTimerTextHud, "lockEndTime", 0.0 )
	RuiSetBool( file.coreTimerTextHud, "isVisible", false )
	RuiSetBool( file.coreTimerTextHud, "northLock", false )
	RuiSetBool( file.coreTimerTextHud, "southLock", false )
	RuiSetBool( file.coreTimerTextHud, "westLock", false )
	RuiSetBool( file.coreTimerTextHud, "eastLock", false )
	return file.coreTimerTextHud
}

void function CoreTimerText_DestroyHud()
{
	TitanCockpitDestroyRui( file.coreTimerTextHud )
	file.coreTimerTextHud = null
}

var function IonEnergyNum_CreateHud()
{
	Assert( file.ionEnergyNumHud == null )

	file.ionEnergyNumHud = CreateTitanCockpitRui($"ui/cockpit_console_text_top_left.rpak", 5)
    RuiSetInt( file.ionEnergyNumHud, "maxLines", 3 )
    RuiSetInt( file.ionEnergyNumHud, "lineNum", 1 )
    RuiSetFloat2( file.ionEnergyNumHud, "msgPos", GetConVarFloat3("comp_hud_ion_energy_pos") )
    RuiSetString( file.ionEnergyNumHud, "msgText", "" )
    RuiSetFloat( file.ionEnergyNumHud, "msgFontSize", GetConVarFloat("comp_hud_ion_energy_size") )
    RuiSetFloat( file.ionEnergyNumHud, "msgAlpha", 0.0 )
    RuiSetFloat( file.ionEnergyNumHud, "thicken", 0.0 )
    RuiSetFloat3( file.ionEnergyNumHud, "msgColor", GetConVarFloat3("comp_hud_ion_energy_color") / 255.0 )
	return file.ionEnergyNumHud
}

void function IonEnergyNum_DestroyHud()
{
	TitanCockpitDestroyRui( file.ionEnergyNumHud )
	file.ionEnergyNumHud = null
}

void function MenuOpen()
{
	entity player = GetLocalViewPlayer()
	if (!IsAlive(player) || !player.IsTitan() || file.cockpitRui == null)
	{
		return
	}
	// titan health
	{
		RuiSetFloat2( file.healthHud, "msgPos", settings.healthPos + (GetConVarBool("comp_hud_healthbar_overlap") ? <0.0, -0.0225, 0.0> : <0,0,0>))
		RuiSetString( file.healthHud, "msgText", "10000")
		RuiSetFloat3( file.healthHud, "msgColor", GetAccentColor() )
		RuiSetFloat( file.healthHud, "msgAlpha", GetConVarBool("comp_hud_healthbar") ? 0.9 : 0.0)
	}
	// titan shield
	{
		RuiSetString( file.shieldHud, "msgText", "2500")
		RuiSetFloat( file.shieldHud, "msgAlpha", GetConVarBool("comp_hud_healthbar") ? 0.9 : 0.0 )
	}
	// core timer
	if (GetConVarBool("comp_core_meter_timer"))
	{
		HideCoreTimers()
		switch (GetConVarInt("comp_core_meter_timer_style")) {
			case eHUDCoreTimer.number:
				UpdateNumberCoreTimer(8.88)
				break
			case eHUDCoreTimer.text:
				UpdateTextCoreTimer(format(Localize("#hud_core_timer_sword"), 8.88))
				break
			case eHUDCoreTimer.legion:
				UpdateLegionCoreTimerInternal(10, 8.88, 1.0)
				break
			case eHUDCoreTimer.hybrid:
				UpdateLegionCoreTimerInternal(10, 8.88, 1.0)
				UpdateTextCoreTimer(format(Localize("#hud_core_timer_sword"), 8.88))
			default:
				break
		}
	}
	else
	{
		HideCoreTimers()
	}
	// Ion energy number
	if (IsPlayerIon())
	{
		UpdateIonEnergyNumberInternal("1000")
	}
}
// GtJt HUD

void function UpdateLastPlayerSettings( entity player )
{
	if ( IsPilot( player ) )
		file.lastPilotSettings = player.GetPlayerSettings()
}

TitanBindings function GetTitanBindings()
{
	TitanBindings Table
	Table.PlayerPressed_Eject = PlayerPressed_Eject
	Table.PlayerPressed_EjectEnable = PlayerPressed_EjectEnable
	return Table
}

bool function RegisterTitanBindings( entity player, TitanBindings bind )
{
	if ( player != GetLocalViewPlayer() )
		return false

	if ( player != GetLocalClientPlayer() )
		return false

	RegisterConCommandTriggeredCallback( "+useAndReload", bind.PlayerPressed_Eject )
	RegisterConCommandTriggeredCallback( "+use", bind.PlayerPressed_Eject )

	RegisterConCommandTriggeredCallback( "+scriptCommand1", bind.PlayerPressed_EjectEnable )

	return true
}

void function DeregisterTitanBindings( TitanBindings bind )
{
	DeregisterConCommandTriggeredCallback( "+useAndReload", bind.PlayerPressed_Eject )
	DeregisterConCommandTriggeredCallback( "+use", bind.PlayerPressed_Eject )

	if ( GetMapName() != "" )
	{
		DeregisterConCommandTriggeredCallback( "+scriptCommand1", bind.PlayerPressed_EjectEnable )
	}
}


void function TitanCockpit_AddPlayer( entity player )
{
	if ( IsModelViewer() )
		return

	player.s.lastCockpitDamageSoundTime <- 0
	player.s.inTitanCockpit <- false
	player.s.lastDialogTime <- 0
	player.s.titanCockpitDialogActive <- false
	player.s.titanCockpitDialogAliasList <- []

	player.s.hitVectors <- []
}

void function TitanCockpitInit( entity cockpit )
{
	entity player = GetLocalViewPlayer()
	Assert( player.GetCockpit() == cockpit )

	cockpit.s.ejectStartTime <- 0 // placed here to fix http://bugzilla.respawn.net/show_bug.cgi?id=156786

	if ( !IsAlive( player ) )
		return

	if ( !IsTitanCockpitModelName( cockpit.GetModelName() ) || IsWatchingThirdPersonKillReplay() )
	{
		player.s.inTitanCockpit = false
		return
	}

	if ( !player.s.inTitanCockpit )
		TitanEmbarkDSP( 0.5 )

	player.s.inTitanCockpit = true

	// code aint callin this currently
	CodeCallback_PlayerInTitanCockpit( GetLocalViewPlayer(), GetLocalViewPlayer() )

	// move this
	array<entity> targets = GetClientEntArrayBySignifier( "info_target" )
	foreach ( target in targets )
	{
		if ( target.GetTargetName() != "cockpit_geo_ref" )
			continue

		level.cockpitGeoRef = target
	}

	entity cockpitParent = expect entity( level.cockpitGeoRef )

	if ( !IsValid( cockpitParent ) )
		cockpitParent = GetLocalViewPlayer()

	cockpit.s.empInfo <- {}
	cockpit.s.empInfo["xOffset"] <- 0
	cockpit.s.empInfo["yOffset"] <- 0
	cockpit.s.empInfo["startTime"] <- 0
	cockpit.s.empInfo["duration"] <- 0
	cockpit.s.empInfo["sub_count"] <- 0
	cockpit.s.empInfo["sub_start"] <- 0
	cockpit.s.empInfo["sub_duration"] <- 0
	cockpit.s.empInfo["sub_pause"] <- 0
	cockpit.s.empInfo["sub_alpha"] <- 0

	cockpit.s.cockpitType <- 1
	cockpit.s.FOV <- 70

	cockpit.e.body = CreateCockpitBody( cockpit, player, cockpitParent )

	thread TitanCockpitAnimThink( cockpit, cockpit.e.body )

	if ( player.IsTitan() && IsAlive( player ) ) // pilot with titan cockpit gets thrown from titan
		thread TitanCockpitDoomedThink( cockpit, player )

	SetCockpitLightingEnabled( 0, true )
	ShowRUIHUD( cockpit )
}

//bind r "script_client ReloadScripts();script_client GetLocalViewPlayer().GetCockpit().Destroy()"
void function ShowRUIHUD( entity cockpit )
{
	// update topo positions
	int cameraAttachId = cockpit.LookupAttachment( "CAMERA" )
	vector cameraOrigin = cockpit.GetAttachmentOrigin( cameraAttachId )

	int lowerScreenAttachId = cockpit.LookupAttachment( "COCKPIT_HUD_BOTTOM" )
	vector lowerScreenOrigin = cockpit.GetAttachmentOrigin( lowerScreenAttachId )
	vector lowerScreenAngles = cockpit.GetAttachmentAngles( lowerScreenAttachId )

	int instrument1AttachId = cockpit.LookupAttachment( "COCKPIT_OBJ_1" )
	vector instrument1Origin = cockpit.GetAttachmentOrigin( instrument1AttachId )
	vector instrument1Angles = cockpit.GetAttachmentAngles( instrument1AttachId )

	lowerScreenOrigin = lowerScreenOrigin - cameraOrigin
	vector lowerScreenPosition = <lowerScreenOrigin.x, lowerScreenOrigin.y + TITAN_COCKPIT_LOWER_RUI_SCREEN_SQUARE_SIZE * .5, lowerScreenOrigin.z + (TITAN_COCKPIT_LOWER_RUI_SCREEN_SQUARE_SIZE) * .5>

	instrument1Origin = instrument1Origin - cameraOrigin
	vector instrument1Position = <instrument1Origin.x, instrument1Origin.y, instrument1Origin.z>
	vector instrument1RightVector = AnglesToRight( instrument1Angles ) * -1
	vector instrument1DownVector = AnglesToUp( instrument1Angles ) * -1

	RuiTopology_UpdatePos( clGlobal.topoTitanCockpitLowerHud, lowerScreenPosition, <0, -TITAN_COCKPIT_LOWER_RUI_SCREEN_SQUARE_SIZE, 0>, <0, 0, -(TITAN_COCKPIT_LOWER_RUI_SCREEN_SQUARE_SIZE * TITAN_COCKPIT_LOWER_RUI_SCREEN_HEIGHT_SCALE)> )
	RuiTopology_UpdatePos( clGlobal.topoTitanCockpitInstrument1, instrument1Position - (instrument1RightVector *  TITAN_COCKPIT_INSTRUMENT1_RUI_SCREEN_SQUARE_SIZE * 0.5) - (instrument1DownVector * TITAN_COCKPIT_INSTRUMENT1_RUI_SCREEN_SQUARE_SIZE * 0.5), instrument1RightVector * TITAN_COCKPIT_INSTRUMENT1_RUI_SCREEN_SQUARE_SIZE, instrument1DownVector * TITAN_COCKPIT_INSTRUMENT1_RUI_SCREEN_SQUARE_SIZE )

	// create ruis
	entity player = GetLocalViewPlayer()

	#if SP
	file.coreHintRui = CreateTitanCockpitRui( $"ui/core_hint.rpak" )
	#endif

	file.cockpitRui = CreateTitanCockpitRui( $"ui/ajax_cockpit_base.rpak" )
	RuiTrackFloat3( file.cockpitRui, "playerOrigin", player, RUI_TRACK_ABSORIGIN_FOLLOW )
	RuiTrackFloat3( file.cockpitRui, "playerEyeAngles", player, RUI_TRACK_EYEANGLES_FOLLOW )
	RuiTrackFloat( file.cockpitRui, "healthFrac", player, RUI_TRACK_HEALTH )
	RuiTrackFloat( file.cockpitRui, "shieldFrac", player, RUI_TRACK_SHIELD_FRACTION )
	RuiTrackFloat( file.cockpitRui, "dashFrac", player, RUI_TRACK_PLAYER_SUIT_POWER )
	RuiSetFloat( file.cockpitRui, "ejectManualTimeOut", EJECT_FADE_TIME )
	RuiSetFloat( file.cockpitRui, "ejectButtonTimeOut", TITAN_EJECT_MAX_PRESS_DELAY )
	RuiSetGameTime( file.cockpitRui, "ejectManualStartTime", -60.0 )
	RuiSetGameTime( file.cockpitRui, "ejectButtonPressTime", -60.0 )
	#if MP
	string titanName = GetTitanCharacterName( player )
	if ( titanName == "vanguard" )
	{
		RuiSetString( file.cockpitRui, "titanInfo1", GetVanguardCoreString( player, 1 ) )
		RuiSetString( file.cockpitRui, "titanInfo2", GetVanguardCoreString( player, 2 ) )
		RuiSetString( file.cockpitRui, "titanInfo3", GetVanguardCoreString( player, 3 ) )
		RuiSetString( file.cockpitRui, "titanInfo4", GetVanguardCoreString( player, 4 ) )
	}

	file.cockpitAdditionalRui = CreateTitanCockpitRui( $"ui/ajax_cockpit_fd.rpak" )
	RuiSetFloat( file.cockpitAdditionalRui, "ejectManualTimeOut", EJECT_FADE_TIME )
	RuiSetFloat( file.cockpitAdditionalRui, "ejectButtonTimeOut", TITAN_EJECT_MAX_PRESS_DELAY )
	RuiSetGameTime( file.cockpitAdditionalRui, "ejectManualStartTime", -60.0 )

	RuiSetDrawGroup( file.cockpitAdditionalRui, RUI_DRAW_NONE )
	#endif

#if SP
	bool ejectIsAllowed = false
#else
	bool ejectIsAllowed = !TitanEjectIsDisabled()
#endif
	RuiSetBool( file.cockpitRui, "ejectIsAllowed", ejectIsAllowed )

	string playerSettings = GetLocalViewPlayer().GetPlayerSettings()
	float health = player.GetPlayerModHealth()
	float healthPerSegment = GetPlayerSettingsFieldForClassName_HealthPerSegment( playerSettings )
	RuiSetInt( file.cockpitRui, "numHealthSegments", int( health / healthPerSegment ) )
	RuiTrackFloat( file.cockpitRui, "cockpitColor", player, RUI_TRACK_STATUS_EFFECT_SEVERITY, eStatusEffect.cockpitColor )

	file.cockpitLowerRui = CreateTitanCockpitLowerRui( $"ui/ajax_cockpit_lower.rpak" )
	RuiTrackFloat( file.cockpitLowerRui, "dashFrac", player, RUI_TRACK_PLAYER_SUIT_POWER )
	RuiTrackFloat3( file.cockpitLowerRui, "playerEyeAngles", player, RUI_TRACK_EYEANGLES_FOLLOW )
	RuiTrackFloat( file.cockpitLowerRui, "cockpitColor", player, RUI_TRACK_STATUS_EFFECT_SEVERITY, eStatusEffect.cockpitColor )

	var instrument1Rui = CreateTitanCockpitInstrument1Rui( $"ui/ajax_cockpit_insturment1.rpak" )
	RuiTrackFloat3( instrument1Rui, "playerEyeAngles", player, RUI_TRACK_EYEANGLES_FOLLOW )

	int numDashPips = int( floor( 100 / GetSettingsForPlayer_DodgeTable( GetLocalViewPlayer() )["dodgePowerDrain"] ) )
	RuiSetInt( file.cockpitRui, "numDashSegments", numDashPips )
	RuiSetInt( file.cockpitLowerRui, "numDashSegments", numDashPips )

	thread CockpitDoomedThink( cockpit )
	thread TitanCockpitDestroyRuisOnDeath( cockpit )
	thread TitanCockpitHealthChangedThink( cockpit, player )

	#if MP
	if ( GetCurrentPlaylistVarInt( "aegis_upgrades", 0 ) == 1 && !IsSpectating() && !IsWatchingKillReplay() )
		thread DisplayFrontierRank( file.isFirstBoot )
	#endif
	file.isFirstBoot = false

	UpdateTitanCockpitVisibility()
	// Must be after creating managed ruis
	thread UpdateTitanCockpitAdditionalRuis_Thread(cockpit)
}

#if MP
void function DisplayFrontierRank( bool isFirstBoot = true )
{
	GetLocalClientPlayer().Signal( "DisplayFrontierRank" )
	GetLocalClientPlayer().EndSignal( "DisplayFrontierRank" )

	wait 2.0

	TitanLoadoutDef titanLoadout = GetTitanLoadoutFromPersistentData( GetLocalClientPlayer(), GetPersistentSpawnLoadoutIndex( GetLocalClientPlayer(), "titan" ) )
	string titanClass = titanLoadout.titanClass

	array<ItemDisplayData> titanUpgrades = FD_GetUpgradesForTitanClass( titanClass )
	int maxActiveIndex
	foreach ( index, item in titanUpgrades )
	{
		RuiSetImage( file.cockpitAdditionalRui, "upgradeIcon" + (index + 1), item.image )
		RuiSetString( file.cockpitAdditionalRui, "upgradeName" + (index + 1), item.name )

		if ( !IsSubItemLocked( GetLocalClientPlayer(), item.ref, item.parentRef ) )
			maxActiveIndex++
	}

	RuiSetDrawGroup( file.cockpitAdditionalRui, RUI_DRAW_COCKPIT )

	bool firstBootDisplay
	if ( GameRules_GetGameMode() == FD )
		firstBootDisplay = isFirstBoot || !GetGlobalNetBool( "FD_waveActive" )
	else
		firstBootDisplay = isFirstBoot

	RuiSetBool( file.cockpitAdditionalRui, "isFirstBoot", firstBootDisplay )
	RuiSetImage( file.cockpitAdditionalRui, "titanIcon", GetIconForTitanClass( titanClass ) )
	RuiSetInt( file.cockpitAdditionalRui, "titanRank", FD_TitanGetLevel( GetLocalClientPlayer(), titanClass ) )
	RuiSetInt( file.cockpitAdditionalRui, "maxActiveIndex", maxActiveIndex )
	RuiSetGameTime( file.cockpitAdditionalRui, "updateTime", Time() )

	EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_FD_MetaUpgradeAnnouncement" )

	if ( firstBootDisplay )
	{
		wait 2.0

		for ( int index = 0; index < maxActiveIndex; index++ )
		{
			EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_FD_MetaUpgradeTextAppear" )

			wait 0.85

			EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_FD_MetaUpgradeBarFill" )

			wait 0.15
		}
	}
	else
	{
		wait 0.5

		for ( int index = 0; index < maxActiveIndex; index++ )
		{
			EmitSoundOnEntity( GetLocalClientPlayer(), "UI_InGame_FD_MetaUpgradeBarFill" )
			wait 0.05
		}
	}
}

string function GetVanguardCoreString( entity player, int index )
{
	Assert( player.IsTitan() )

	if ( !IsConnected() ) //Persistence isn't available when we disconnect
		return ""

	if ( player != GetLocalClientPlayer() )  //Client Persistence doesn't know about other players.
		return ""

	TitanLoadoutDef loadout = GetActiveTitanLoadout( player )

	entity soul = player.GetTitanSoul()
	if ( !IsValid( soul ) )
		return ""

	if ( index == 1 )
	{
		if ( soul.GetTitanSoulNetInt( "upgradeCount" ) >= 1 )
		{
			return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE1_TITLE" ), Localize( GetItemName( loadout.passive4 ) ) )
		}
		else
		{
			return  Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE1_TITLE" ), Localize( "#UPGRADE_IN_PROGRESS" ) )
		}
	}
	if ( index == 2 )
	{
		if ( soul.GetTitanSoulNetInt( "upgradeCount" ) >= 2 )
		{
			return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE2_TITLE" ), Localize( GetItemName( loadout.passive5 ) ) )
		}
		else
		{
			if ( soul.GetTitanSoulNetInt( "upgradeCount" ) >= 1 )
				return  Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE2_TITLE" ), Localize( "#UPGRADE_IN_PROGRESS" ) )
			else
				return  Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE2_TITLE" ), Localize( "#UPGRADE_NOT_INSTALLED" ) )
		}
	}
	if ( index == 3 )
	{
		if ( soul.GetTitanSoulNetInt( "upgradeCount" ) >= 3 )
		{
			return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE3_TITLE" ), Localize( GetItemName( loadout.passive6 ) ) )
		}
		else
		{
			if ( soul.GetTitanSoulNetInt( "upgradeCount" ) >= 2 )
				return  Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE3_TITLE" ), Localize( "#UPGRADE_IN_PROGRESS" ) )
			else
				return  Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE3_TITLE" ), Localize( "#UPGRADE_NOT_INSTALLED" ) )
		}
	}
	if ( index == 4 )
	{
		printt( loadout.passive4 )
		if ( loadout.passive4 == "pas_vanguard_core1" ) // Arc Rounds
		{
			entity offhandWeapon = player.GetOffhandWeapon( OFFHAND_RIGHT )
			if ( IsValid( offhandWeapon ) && ( offhandWeapon.HasMod( "missile_racks" ) || offhandWeapon.HasMod( "upgradeCore_MissileRack_Vanguard" ) ) )
				return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE4_TITLE" ), Localize( "#GEAR_VANGUARD_CORE2" ) )
			offhandWeapon = player.GetOffhandWeapon( OFFHAND_LEFT )
			if ( IsValid( offhandWeapon ) && ( offhandWeapon.HasMod( "energy_transfer" ) || offhandWeapon.HasMod( "energy_field_energy_transfer" ) ) )
				return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE4_TITLE" ), Localize( "#GEAR_VANGUARD_CORE3" ) )
		}
		else if ( loadout.passive4 == "pas_vanguard_core2" ) // Missile Racks
		{
			entity weapon = player.GetMainWeapons()[0]
			if ( IsValid( weapon ) && ( weapon.HasMod( "arc_rounds" ) || weapon.HasMod( "arc_rounds_with_battle_rifle" ) ) )
				return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE4_TITLE" ), Localize( "#GEAR_VANGUARD_CORE1" ) )
			entity offhandWeapon = player.GetOffhandWeapon( OFFHAND_LEFT )
			if ( IsValid( offhandWeapon ) && ( offhandWeapon.HasMod( "energy_transfer" ) || offhandWeapon.HasMod( "energy_field_energy_transfer" ) ) )
				return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE4_TITLE" ), Localize( "#GEAR_VANGUARD_CORE3" ) )
		}
		else if ( loadout.passive4 == "pas_vanguard_core3" ) // Energy Transfer
		{
			entity weapon = player.GetMainWeapons()[0]
			if ( IsValid( weapon ) && ( weapon.HasMod( "arc_rounds" ) || weapon.HasMod( "arc_rounds_with_battle_rifle" ) ) )
				return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE4_TITLE" ), Localize( "#GEAR_VANGUARD_CORE1" ) )
			entity offhandWeapon = player.GetOffhandWeapon( OFFHAND_RIGHT )
			if ( IsValid( offhandWeapon ) && ( offhandWeapon.HasMod( "missile_racks" ) || offhandWeapon.HasMod( "upgradeCore_MissileRack_Vanguard" ) ) )
				return Localize( "#TITAN_UPGRADE_STATUS_N_N", Localize( "#TITAN_UPGRADE4_TITLE" ), Localize( "#GEAR_VANGUARD_CORE2" ) )
		}
		return ""
	}

	unreachable
}
#endif

void function SetUnlimitedDash( bool active )
{
	if ( file.cockpitLowerRui == null )
		return

	RuiSetBool( file.cockpitLowerRui, "hasUnlimitedDash", active )
}

void function UpdateEjectHud_SetManualEjectStartTime( entity player )
{
	float timeNow = Time()
	player.p.ejectEnableTime = timeNow

	if ( file.cockpitRui != null )
		RuiSetGameTime( file.cockpitRui, "ejectManualStartTime", timeNow )

	if ( file.cockpitAdditionalRui != null )
		RuiSetGameTime( file.cockpitAdditionalRui, "ejectManualStartTime", timeNow )
}

void function UpdateEjectHud_SetButtonPressTime( entity player )
{
	float timeNow = Time()
	player.p.ejectPressTime	= timeNow

	if ( file.cockpitRui != null )
		RuiSetGameTime( file.cockpitRui, "ejectButtonPressTime", timeNow )

	//if ( file.cockpitAdditionalRui != null )
	//	RuiSetGameTime( file.cockpitAdditionalRui, "ejectButtonPressTime", timeNow )
}

void function UpdateEjectHud_SetButtonPressCount( entity player, int buttonCount )
{
	player.p.ejectPressCount = buttonCount

	if ( file.cockpitRui != null )
		RuiSetInt( file.cockpitRui, "ejectButtonCount", buttonCount )

	//if ( file.cockpitAdditionalRui != null )
	//	RuiSetInt( file.cockpitAdditionalRui, "ejectButtonCount", buttonCount )
}

void function UpdateTitanCockpitVisibility()
{
	entity player = GetLocalViewPlayer()
	if ( !IsValid( player ) )
		return

	if ( Tone_ShouldCreateTrackerHud( player ) )
		thread Tone_HudThink( player )
	else
		player.Signal( "StopToneHud" )

	foreach ( managedRUI in file.titanCockpitManagedRUIs )
	{
		bool shouldCreate = managedRUI.shouldCreate()
		if ( !managedRUI.exists && shouldCreate )
		{
			var rui = managedRUI.create()

			bool found = false
			foreach ( cockpitRui in player.p.titanCockpitRUIs )
			{
				if ( cockpitRui.rui == rui )
					found = true
			}
			if ( !found )
			{
				TitanCockpitRUI tcRUI
				tcRUI.rui = rui
				tcRUI.drawGroup = managedRUI.drawGroup
				player.p.titanCockpitRUIs.append( tcRUI )
			}

			managedRUI.exists = true
		}
		else if ( managedRUI.exists && !shouldCreate )
		{
			managedRUI.destroy()
			managedRUI.exists = false
		}
	}

	bool isVisible = true

	int ceFlags = player.GetCinematicEventFlags()
	if ( (ceFlags & CE_FLAG_INTRO) || (ceFlags & CE_FLAG_TITAN_3P_CAM) )
		isVisible = false
	if ( clGlobal.isSoloDialogMenuOpen )
		isVisible = false

	for ( int i = player.p.titanCockpitRUIs.len() - 1; i >= 0; i-- )
	{
		TitanCockpitRUI tcRUI = player.p.titanCockpitRUIs[ i ]
		RuiSetDrawGroup( tcRUI.rui, isVisible ? tcRUI.drawGroup : RUI_DRAW_NONE )
	}
}

void function AddTitanCockpitManagedRUI( var functionref() createFunc, void functionref() destroyFunc, bool functionref() shouldCreateFunc, int drawGroup )
{
	TitanCockpitManagedRUI managedRUI
	managedRUI.create = createFunc
	managedRUI.destroy = destroyFunc
	managedRUI.shouldCreate = shouldCreateFunc
	managedRUI.drawGroup = drawGroup

	file.titanCockpitManagedRUIs.append( managedRUI )
}

void function CinematicEventFlagChanged( entity player )
{
	UpdateTitanCockpitVisibility()
}

void function CockpitDoomedThink( entity cockpit )
{
	entity player = GetLocalViewPlayer()
	cockpit.EndSignal( "OnDestroy" )

	while ( IsAlive( player ) )
	{
		entity soul = player.GetTitanSoul()
		if ( !IsValid( soul ) ) //Defensive fix for bug 227087. Assumption is that the cockpit is likely to be destroyed soon if the soul is invalid.
			return
		if ( !soul.IsDoomed() )
			player.WaitSignal( "Doomed" )

		SetCockpitUIDoomedState( true )

		if ( !IsValid( soul ) ) //Defensive fix for bug 227087. Assumption is that the cockpit is likely to be destroyed soon if the soul is invalid.
			return
		if ( soul.IsDoomed() )
			player.WaitSignal( "TitanUnDoomed" )

		SetCockpitUIDoomedState( false )
	}
}

void function SetCockpitUIEjectingState( bool state )
{
	if ( file.cockpitRui != null )
		RuiSetBool( file.cockpitRui, "isEjecting", state )

	if ( file.cockpitAdditionalRui != null )
		RuiSetBool( file.cockpitAdditionalRui, "isEjecting", state )

	if ( file.cockpitLowerRui != null )
	{
		RuiSetBool( file.cockpitLowerRui, "isEjecting", state )
		if ( state )
			RuiSetString( file.cockpitLowerRui, "ejectPrompt", Localize( RollRandomEjectString() ) )
		else
			RuiSetString( file.cockpitLowerRui, "ejectPrompt", "" )
	}
}

void function SetCockpitUIDoomedState( bool state )
{
	if ( file.cockpitRui != null )
		RuiSetBool( file.cockpitRui, "isDoomed", state )

	if ( file.cockpitAdditionalRui != null )
		RuiSetBool( file.cockpitAdditionalRui, "isDoomed", state )
}

void function TitanCockpitDestroyRui( var ruiToDestroy )
{
	if ( ruiToDestroy == null )
		return

	entity player = GetLocalViewPlayer()

	for ( int i = player.p.titanCockpitRUIs.len() - 1; i >= 0; i-- )
	{
		TitanCockpitRUI tcRUI = player.p.titanCockpitRUIs[ i ]
		if ( tcRUI.rui == ruiToDestroy )
		{
			RuiDestroy( tcRUI.rui )
			player.p.titanCockpitRUIs.remove( i )
		}
	}
}

void function TitanCockpitDestroyRuisOnDeath( entity cockpit )
{
	entity player = GetLocalViewPlayer()

	OnThreadEnd(
	function() : ( cockpit )
		{
			foreach ( managedRUI in file.titanCockpitManagedRUIs )
			{
				if ( managedRUI.exists )
				{
					managedRUI.destroy()
					managedRUI.exists = false
				}
			}

			entity player = GetLocalViewPlayer()
			for ( int i = player.p.titanCockpitRUIs.len() - 1; i >= 0; i-- )
			{
				RuiDestroy( player.p.titanCockpitRUIs[ i ].rui )
				player.p.titanCockpitRUIs.remove( i )
			}

			player = GetLocalClientPlayer()
			if ( IsValid( player ) )
				player.Signal( "DisplayFrontierRank" )
			file.cockpitAdditionalRui = null
			file.cockpitRui = null
			file.cockpitLowerRui = null
			file.coreHintRui = null
		}
	)

	player.EndSignal( "OnDeath" )
	cockpit.EndSignal( "OnDestroy" )
	WaitForever()
}

function CockpitBodyThink( cockpit, cockpitBody )
{
	cockpitBody.EndSignal( "OnDestroy" )

	cockpit.WaitSignal( "OnDestroy" )

	cockpitBody.Destroy()
}


entity function CreateCockpitBody( entity cockpit, entity player, entity cockpitParent )
{
	#if SP
		string bodySettings = DEFAULT_PILOT_SETTINGS
	#else
		string bodySettings = file.lastPilotSettings
		if ( bodySettings == "" || bodySettings == "spectator" )
			bodySettings = Loadouts_GetSetFileForRequestedClass( player )
		if ( bodySettings == "" )
			bodySettings = "pilot_base"
	#endif

	asset bodyModelName = GetPlayerSettingsAssetForClassName( bodySettings, "armsmodel" )
	#if DEV
	if ( bodySettings == "" )
	{
		CodeWarning( "Couldn't find armsmodel for set file: " + bodySettings )
	}
	#endif

	entity cockpitBody = CreateClientSidePropDynamic( cockpitParent.GetOrigin(), Vector( 0, 0, 0 ), bodyModelName )
	cockpitBody.EnableRenderWithCockpit()
	cockpitBody.SetOrigin( cockpit.GetOrigin() )
	cockpitBody.SetParent( cockpit )

	thread CockpitBodyThink( cockpit, cockpitBody )

	return cockpitBody
}

function TitanEmbarkDSP( transitionTime )
{
}

function TitanDisembarkDSP( transitionTime )
{
}

function TitanCockpit_EMPFadeScale( entity cockpit, elapsedMod = 0 )
{
	local fadeInTime = 0.0
	local fadeOutTime = 1.5
	local elapsedTime = Time() - cockpit.s.empInfo.startTime
	elapsedTime += elapsedMod

	// ToDo:
	// Fade in/out from last frames amount so it doesnt pop
	// Make strength var to control max fade ( less strength returns max of like 0.5 )

	//------------------------
	// EMP effect is finished
	//------------------------

	//printt( "elapsedTime:" + elapsedTime + " cockpit.s.empInfo.duration:" + cockpit.s.empInfo.duration + " fadeOutTime:" + fadeOutTime )
	if ( elapsedTime < cockpit.s.empInfo.duration - fadeOutTime )
	{
		return 1.0
	}


	if ( elapsedTime >= fadeInTime + cockpit.s.empInfo.duration + fadeOutTime )
	{
		cockpit.s.empInfo.startTime = 0
		return 0.0
	}

	//------------------------
	// EMP effect is starting
	//------------------------

	if ( elapsedTime < fadeInTime )
	{
		return GraphCapped( elapsedTime, 0.0, fadeInTime, 0.0, 1.0 )
	}

	//----------------------
	// EMP effect is ending
	//----------------------

	if ( elapsedTime > fadeInTime + cockpit.s.empInfo.duration )
	{
		cockpit.s.empInfo["sub_count"] = 0
		return GraphCapped( elapsedTime, fadeInTime + cockpit.s.empInfo.duration, fadeInTime + cockpit.s.empInfo.duration + fadeOutTime, 1.0, 0.0 )
	}

	//---------------------
	// EMP flicker effect
	//---------------------

	// Time to start a new flicker
	if ( cockpit.s.empInfo["sub_start"] == 0 )
	{
		cockpit.s.empInfo["sub_start"] 		<- Time()
		if ( cockpit.s.empInfo["sub_count"] == 0 )
			cockpit.s.empInfo["sub_pause"] 	<- RandomFloatRange( 0.5, 1.5 )
		else
			cockpit.s.empInfo["sub_pause"] 	<- RandomFloat( 0.5 )
		cockpit.s.empInfo["sub_duration"] 	<- RandomFloatRange( 0.1, 0.4 )
		cockpit.s.empInfo["sub_alpha"] 		<- RandomFloatRange( 0.4, 0.9 )
		cockpit.s.empInfo["sub_count"]++;
	}
	local flickerElapsedTime = Time() - cockpit.s.empInfo["sub_start"]

	// Start a new flicker if the current one is finished
	if ( flickerElapsedTime > cockpit.s.empInfo["sub_pause"] + cockpit.s.empInfo["sub_duration"] )
		cockpit.s.empInfo["sub_start"] = 0

	if ( flickerElapsedTime < cockpit.s.empInfo["sub_pause"] )
	{
		// Pause before the flicker
		return 1.0
	}
	else if ( flickerElapsedTime < cockpit.s.empInfo["sub_pause"] + ( cockpit.s.empInfo["sub_duration"] / 2.0 ) )
	{
		// First half of the flicker
		return GraphCapped( flickerElapsedTime, 0.0, cockpit.s.empInfo["sub_duration"] / 2.0, 1.0, cockpit.s.empInfo["sub_alpha"] )
	}
	else
	{
		// Second half of the flicker
		return GraphCapped( flickerElapsedTime, cockpit.s.empInfo["sub_duration"] / 2.0, cockpit.s.empInfo["sub_duration"], cockpit.s.empInfo["sub_alpha"], 1.0 )
	}
}

function ServerCallback_TitanCockpitEMP( duration )
{
	thread TitanCockpit_DoEMP( duration / 4 )
}

function TitanCockpit_DoEMP( duration )
{
	entity player = GetLocalViewPlayer()
	entity cockpit = player.GetCockpit()

	if ( !IsValid( cockpit ) )
		return

	if ( !player.IsTitan() )
		return

	if ( !player.s.inTitanCockpit )
		return

	Signal( player, "EMP" )
	EndSignal( player, "EMP" )
	player.EndSignal( "OnDestroy" )

	// this needs tweaking... looks a bit artificial
	ClientCockpitShake( 0.25, 3, 1.0, Vector( 0, 0, 1 ) ) // amplitude, frequency, duration, direction

	thread PlayCockpitEMPLights( cockpit, duration )

	// Start the screens and vdu power outages
	cockpit.s.empInfo.xOffset = RandomFloatRange( 0.5, 0.75 )
	cockpit.s.empInfo.yOffset = RandomFloatRange( 0.5, 0.75 )
	if ( CoinFlip() )
		cockpit.s.empInfo.xOffset *= -1
	if ( CoinFlip() )
		cockpit.s.empInfo.yOffset *= -1

	cockpit.s.empInfo.startTime = Time()
	cockpit.s.empInfo.duration = duration

	EmitSoundOnEntity( player, EMP_IMPARED_SOUND )
	wait duration
	FadeOutSoundOnEntity( player, EMP_IMPARED_SOUND, 1.5 )
}

function PlayCockpitEMPLights( cockpit, duration )
{
	duration += 1.5 // blend out
	local attachID
	local origin
	local angles
	local fxLights = []

	string tagName = "COCKPIT" // SCR_CL_BL"
	attachID = cockpit.LookupAttachment( tagName )
	origin = cockpit.GetAttachmentOrigin( attachID )
	origin.z -= 25
	angles = Vector( 0, 0, 0 )
	local lightTable = {}
	lightTable.light <- CreateClientSideDynamicLight( origin, angles, Vector( 0.0, 0.0, 0.0 ), 80.0 )
	lightTable.modulate <- true
	fxLights.append( lightTable )

	wait 0.5

	foreach ( fxLight in fxLights )
	{
		fxLight.light.SetCockpitLight( true )
	}

	local startTime = Time()
	local rate = 1.2

	local endTime = Time() + duration

	while ( IsValid( cockpit ) )
	{
		if ( Time() > endTime )
			break

		float subtractColor = GraphCapped( Time(), endTime - 0.25, endTime, 1.0, 0.0 )
		local pulseFrac = GetPulseFrac( rate, startTime )
		pulseFrac *= subtractColor
		//pulseFrac -= fadeInColor

		foreach ( index, fxLight in fxLights )
		{
			Assert( fxLight.modulate )
			fxLight.light.SetLightColor( Vector( pulseFrac, 0, 0 ) )

			// the case where fxLight.modulate == false used to be handled by this script, which used undefined variable fadeInColor:
			//	fxLight.light.SetLightColor( Vector( fadeInColor, fadeInColor, fadeInColor ) )
		}

		WaitFrame()
	}

	foreach ( fxLight in fxLights )
	{
		fxLight.light.Destroy()
	}
}


function TitanCockpit_IsBooting( cockpit )
{
	return cockpit.GetTimeInCockpit() < 1.3
}

function TitanCockpitAnimThink( cockpit, body )
{
	cockpit.SetOpenViewmodelOffset( 20.0, 0.0, 10.0 )
	cockpit.Anim_NonScriptedPlay( "atpov_cockpit_hatch_close_idle" )

	if ( body )
		body.Anim_NonScriptedPlay( "atpov_cockpit_hatch_close_idle" )
}


bool function IsDisplayingEjectInterface( entity player )
{
	if ( !player.IsTitan() )
		return false

	if ( player.ContextAction_IsMeleeExecution() ) //Could just check for ContextAction_IsActive() if we need to be more general
		return false

	if ( !GetDoomedState( player ) && Time() - player.p.ejectEnableTime > EJECT_FADE_TIME )
		return false

	if ( Riff_TitanExitEnabled() == eTitanExitEnabled.Never || Riff_TitanExitEnabled() == eTitanExitEnabled.DisembarkOnly )
		return false

	//if ( !CanDisembark( player ) )
	//	return false

	return true
}

void function PlayerPressed_Eject( entity player )
{
	if ( !IsDisplayingEjectInterface( player ) )
		return

	if ( Time() - player.p.ejectPressTime > TITAN_EJECT_MAX_PRESS_DELAY )
		UpdateEjectHud_SetButtonPressCount( player, 0 )

	if ( !IsAlive( player ) )
		return

	EmitSoundOnEntity( player, "titan_eject_xbutton" )
	EmitSoundOnEntity( player, "hud_boost_card_radar_jammer_redtextbeep_1p" )
	UpdateEjectHud_SetButtonPressTime( player )
	UpdateEjectHud_SetButtonPressCount( player, (player.p.ejectPressCount + 1) )

	player.ClientCommand( "TitanEject " + player.p.ejectPressCount )

	entity cockpit = player.GetCockpit()
	if ( player.p.ejectPressCount < 3 || cockpit.s.ejectStartTime )
		return

	PlayerEjects( player, cockpit )
}

string function RollRandomEjectString()
{
	const int COCKPIT_EJECT_COMMON_COUNT = 6
	const int COCKPIT_EJECT_RARE_COUNT = 36
	const float CHANCE_FOR_RARE = 0.15

	float randForType = RandomFloat( 1.0 )
	if ( randForType < CHANCE_FOR_RARE )
	{
		int index = RandomInt( COCKPIT_EJECT_RARE_COUNT )
		string result = "#COCKPIT_EJECT_RARE_" + index
		return result
	}

	int index = RandomInt( COCKPIT_EJECT_COMMON_COUNT )
	string result = "#COCKPIT_EJECT_COMMON_" + index
	return result
}

void function PlayerEjects( entity player, entity cockpit ) //Note that this can be run multiple times in a frame, e.g. get damaged by 4 pellets of a shotgun that brings the Titan into a doomed state with auto eject. Not ideal
{
	// prevent animation from playing if player is in the middle of execution
	if ( player.ContextAction_IsActive() && !player.ContextAction_IsBusy() )
		return

	player.Signal( "Ejecting" )

	SetCockpitUIEjectingState( true )

	local ejectAlarmSound
	cockpit.s.ejectStartTime = Time()
	string animationName
	if ( GetNuclearPayload( player ) > 0 )
	{
		animationName = "atpov_cockpit_eject_nuclear"
		cockpit.Anim_NonScriptedPlay( animationName )
		if ( IsValid( cockpit.e.body ) )
			cockpit.e.body.Anim_NonScriptedPlay( "atpov_cockpit_eject_nuclear" )
		ejectAlarmSound = TITAN_NUCLEAR_DEATH_ALARM
	}
	else
	{
		animationName = "atpov_cockpit_eject"
		cockpit.Anim_NonScriptedPlay( animationName )
		if ( IsValid( cockpit.e.body ) )
			cockpit.e.body.Anim_NonScriptedPlay( "atpov_cockpit_eject" )

		ejectAlarmSound = TITAN_ALARM_SOUND
	}

	thread LightingUpdateAfterOpeningCockpit()
	thread EjectAudioThink( player, ejectAlarmSound )

	float animDuration = cockpit.GetSequenceDuration( animationName )

	thread MonitorPlayerEjectAnimBeingStuck( player, animDuration )
}

void function MonitorPlayerEjectAnimBeingStuck( entity player, float duration )
{
	player.Signal( "MonitorPlayerEjectAnimBeingStuck" )
	player.EndSignal( "MonitorPlayerEjectAnimBeingStuck" )
	player.EndSignal( "OnDeath" )
	player.EndSignal( "OnDestroy" )
	player.EndSignal( "SettingsChanged" )


	wait duration + 2.0 // 1s as a buffer

	if ( player.IsTitan() )
	{
		entity cockpit = player.GetCockpit()
		cockpit.Anim_NonScriptedPlay( "atpov_cockpit_hatch_close_idle" )
		if ( IsValid( cockpit.e.body ) )
			cockpit.e.body.Anim_NonScriptedPlay( "atpov_cockpit_hatch_close_idle" )

		SetCockpitUIEjectingState( false )
	}
}

function ServerCallback_EjectConfirmed()
{
	if ( !IsWatchingReplay() )
		return

	entity player = GetLocalViewPlayer()
	entity cockpit = player.GetCockpit()

	if ( !cockpit || !IsTitanCockpitModelName( cockpit.GetModelName() ) )
		return

	PlayerEjects( player, cockpit )
}

function EjectAudioThink( entity player, ejectAlarmSound = TITAN_ALARM_SOUND )
{
	EmitSoundOnEntity( player, ejectAlarmSound )
	TitanCockpit_PlayDialog( player, "manualEjectNotice" )

	player.EndSignal( "OnDeath" )

	player.WaitSignal( "SettingsChanged" )

	if ( player.GetPlayerClass() != "pilot" )
		return

	OnThreadEnd(
		function() : ( player )
		{
			if ( !IsAlive( player ) )
			{
				StopSoundOnEntity( player, TITAN_EJECT_ASCENT )
				StopSoundOnEntity( player, TITAN_EJECT_DESCENT )
			}
			else
			{
				FadeOutSoundOnEntity( player, TITAN_EJECT_ASCENT, 0.25 )
				FadeOutSoundOnEntity( player, TITAN_EJECT_DESCENT, 0.25 )
			}

			StopSoundOnEntity( player, TITAN_EJECT_APEX )
		}
	)

	EmitSoundOnEntity( player, TITAN_EJECT_BOOST )

	float startTime = Time()
	float duration = GetSoundDuration( TITAN_EJECT_ASCENT )
	EmitSoundOnEntity( player, TITAN_EJECT_ASCENT )
	float timeOut = duration - 0.25
	vector velocity
	float diff = 0.0

	const int STAGE_ASCENT = 1
	const int STAGE_APEX = 2
	const int STAGE_DESCENT = 3

	int ejectStage = STAGE_ASCENT

	string currentSound = TITAN_EJECT_ASCENT

	while ( diff < timeOut )
	{
		PerfStart( 127 )

		diff = (Time() - startTime)

		velocity = player.GetVelocity()
		float length = Length( velocity )

		if ( diff > 0.5 )
		{
			if ( player.IsOnGround() )
			{
				PerfEnd( 127 )
				break
			}
		}

		if ( ejectStage != STAGE_DESCENT && velocity.z < 0 )
		{
			FadeOutSoundOnEntity( player, TITAN_EJECT_ASCENT, 0.25 )
			timeOut = GetSoundDuration( TITAN_EJECT_DESCENT )
			EmitSoundOnEntity( player, TITAN_EJECT_DESCENT )
			currentSound = TITAN_EJECT_DESCENT
			ejectStage = STAGE_DESCENT
		}
		else if ( ejectStage == STAGE_ASCENT && length < 400 )
		{
			EmitSoundOnEntity( player, TITAN_EJECT_APEX )
			ejectStage = STAGE_APEX
		}

		PerfEnd( 127 )

		WaitFrame()
	}
}

function LightingUpdateAfterOpeningCockpit()
{
 	while ( true )
 	{
 		if ( !GetLocalViewPlayer().s.inTitanCockpit )
 			break
 		WaitFrame()
 	}

	SetCockpitLightingEnabled( 0, false )
}


function TonemappingUpdateAfterOpeningCockpit() //Deprecated, no longer used
{
	local duration = 3
	local tonemapMin = 2
	local tonemapMax = 5

 	while ( true )
 	{
 		if ( !GetLocalViewPlayer().s.inTitanCockpit )
 			break
 		WaitFrame()
 	}

	SetCockpitLightingEnabled( 0, false )

	AutoExposureSetExposureCompensationBias( tonemapMax )
	AutoExposureSnap()
	wait( 0.1 )

	TitanDisembarkDSP( 0.5 )

	local startTime = Time()
	while ( true )
	{
		local time = Time() - startTime
		float factor = GraphCapped( time, 0, duration, 1, 0 )
		factor = factor * factor * factor
		local toneMapScale = tonemapMin + (tonemapMax - tonemapMin) * factor
		AutoExposureSetExposureCompensationBias( toneMapScale )
		AutoExposureSnap()
		wait  0
		if ( factor == 0 )
			break
	}

	AutoExposureSetExposureCompensationBias( 0 )
}

function ServerCallback_TitanEmbark()
{
	TitanCockpit_PlayDialog( GetLocalViewPlayer(), "embark" )
}

function ServerCallback_TitanDisembark()
{
	entity player = GetLocalViewPlayer()

	thread LightingUpdateAfterOpeningCockpit()

	//HideFriendlyIndicatorAndCrosshairNames()

	//PlayMusic( "Music_FR_Militia_PilotAction2" )
}


function PlayerPressed_QuickDisembark( player )
{
	player.ClientCommand( "TitanDisembark" )
}

void function PlayerPressed_EjectEnable( entity player )
{
	if ( !player.IsTitan() )
		return

	if ( !IsAlive( player ) )
		return

	if ( IsValid( player.GetParent() ) )
		return

	if ( TitanEjectIsDisabled() )
	{
		EmitSoundOnEntity( player, "CoOp_SentryGun_DeploymentDeniedBeep" )
		SetTimedEventNotification( 1.5, "" )
		SetTimedEventNotification( 1.5, "#NOTIFY_EJECT_DISABLED" )
		return
	}

	if ( Riff_TitanExitEnabled() == eTitanExitEnabled.Never || 	Riff_TitanExitEnabled() == eTitanExitEnabled.DisembarkOnly )
		return

	//if ( !CanDisembark( player ) )
	//	return

	if ( player.ContextAction_IsMeleeExecution() ) //Could just check for ContextAction_IsActive() if we need to be more general
		return

	if ( player.GetHealth() == 1 )
	{
		#if MP
		if ( !FD_ReadyUpEnabled() )
		#endif
		{
			player.ClientCommand( "TitanEject " + 3 )
			return
		}
	}

	EmitSoundOnEntity( player, "titan_eject_dpad" )
	UpdateEjectHud_SetManualEjectStartTime( player )
	player.Signal( "UpdateRodeoAlert" ) // need this to hide titan stomp hint
}

float function CalcJoltMagnitude( player, cockpit, joltDir, float damageAmount, damageType, int damageSourceID )
{
	const float COCKPIT_MAX_JOLT_DAMAGE = 2000.0

	float resultRaw = damageAmount / COCKPIT_MAX_JOLT_DAMAGE
	return clamp( resultRaw, 0.0, 1.0 )
}

function JoltCockpit( cockpit, player, joltDir, float damageAmount, damageType, damageSourceId )
{
	float severity = CalcJoltMagnitude( player, cockpit, joltDir, damageAmount, damageType, expect int( damageSourceId ) )
	player.CockpitJolt( joltDir, severity )
}

function RandomizeDir( dir, randPitch = 0, randYaw = 0, basePitch = 0, baseYaw = 0 )
{
	local pitch = RandomFloatRange( -randPitch, randPitch )
	local yaw = RandomFloatRange( -randYaw, randYaw )
	local angles = VectorToAngles( dir )
	angles = AnglesCompose( angles, Vector( pitch, yaw, 0 ) )
	angles = AnglesCompose( angles, Vector( basePitch, baseYaw, 0 ) )
	return AnglesToForward( angles )
}

function TitanCockpitDoomedThink( cockpit, player )
{
	cockpit.EndSignal( "OnDestroy" )

	local titanSoul = player.GetTitanSoul()

	if ( titanSoul == null || !titanSoul.IsDoomed() )
		WaitSignal( player, "Doomed", "Ejecting" )

	local color = Vector( 0.6, 0.06, 0 )
	local radius = 70.0

	FlashCockpitLight( cockpit, color, radius, -1 )
}

void function TitanCockpitHealthChangedThink( cockpit, entity player )
{
	cockpit.EndSignal( "OnDestroy" )

	while ( true )
	{
		table results = WaitSignal( player, "HealthChanged" )

		if ( !IsAlive( player ) )
			continue

		float oldHealthFrac = float( results.oldHealth ) / float( player.GetMaxHealth() )
		float newHealthFrac = float( results.newHealth ) / float( player.GetMaxHealth() )

		if ( oldHealthFrac > newHealthFrac )
		{
			var rui = RuiCreate( $"ui/ajax_cockpit_lost_health_segment.rpak", clGlobal.topoTitanCockpitHud, RUI_DRAW_COCKPIT, 10 )
			RuiSetGameTime( rui, "startTime", Time() )
			RuiSetFloat( rui, "oldHealthFrac", oldHealthFrac )
			RuiSetFloat( rui, "newHealthFrac", newHealthFrac )

			string playerSettings = GetLocalViewPlayer().GetPlayerSettings()
			float health = player.GetPlayerModHealth()
			float healthPerSegment = GetPlayerSettingsFieldForClassName_HealthPerSegment( playerSettings )
			RuiSetInt( rui, "numHealthSegments", int( health / healthPerSegment ) )
		}
	}
}


function FlashCockpitLight( cockpit, color, radius, duration, tag = "SCR_CL_BL" )
{
	cockpit.EndSignal( "TitanUnDoomed" )
	cockpit.EndSignal( "OnDestroy" )

	local attachID = cockpit.LookupAttachment( tag )
	local origin = cockpit.GetAttachmentOrigin( attachID )
	local angles = Vector( 0, 0, 0 )

	local fxLight = CreateClientSideDynamicLight( origin, angles, color, radius )
	fxLight.SetCockpitLight( true )
	fxLight.SetParent( cockpit )

	OnThreadEnd(
		function() : ( fxLight )
		{
			fxLight.Destroy()
		}
	)

	local startTime = Time()
	local rate = 3.0

	while ( IsValid( cockpit ) && (Time() < startTime + duration || duration == -1 ) )
	{
		local pulseFrac = GetPulseFrac( rate, startTime )
		pulseFrac += 0.5
		fxLight.SetLightColor( Vector( color.x * pulseFrac, color.y * pulseFrac, color.z * pulseFrac ) )

		WaitFrame()
	}
}

function PlayCockpitSparkFX_Internal( cockpit, string tagName )
{
	expect entity( cockpit )

	// this is called from a delaythread so needs valid check
	if ( !IsValid( cockpit ) )
		return

	int attachID = cockpit.LookupAttachment( tagName )
	if ( attachID == 0 )
	{
		tagName = CoinFlip() ? "FX_TL_PANEL" : "FX_TR_PANEL"
		attachID = cockpit.LookupAttachment( tagName )
		Assert( attachID, "Could not find fallback attachment index " + attachID + " for '" + tagName + "'' in model " + GetLocalViewPlayer().GetCockpit().GetModelName() )
	}

	int fxID = GetParticleSystemIndex( $"xo_cockpit_spark_01" )
	int fxInstID = PlayFXOnTag( cockpit, fxID, attachID )

	EffectSetIsWithCockpit( fxInstID, true )
}

function PlayCockpitSparkFX( cockpit, int sparkCount )
{
	const int TAG_COUNT = 6
	const string[TAG_COUNT] cockpitFXEmitTags = [ "FX_TL_PANEL", "FX_TR_PANEL", "FX_TC_PANELA", "FX_TC_PANELB", "FX_BL_PANEL", "FX_BR_PANEL" ]
	array<int> playlist = [0,1,2,3,4,5]
	playlist.randomize()

	for ( int idx = 0; idx < sparkCount; idx++ )
	{
		int lookup = (idx % TAG_COUNT)
		int tagIndex = playlist[lookup]
		string tagName = cockpitFXEmitTags[tagIndex]
		PlayCockpitSparkFX_Internal( cockpit, tagName )
	}
}

const int DAMAGE_PER_SPARK = 1000
const int SPARK_MULTIPLIER = 3

int function CalSparkCountForHit( entity player, float damageAmount, bool becameDoomed )
{
	if ( becameDoomed )
		return 20
	if ( damageAmount <= 0 )
		return 0

	int healthNow = player.GetHealth()
	int healthPrev = healthNow + int( damageAmount )
	int healthMax = player.GetMaxHealth()

	bool isDoomed = GetDoomedState( player )
	int sparksNow = (healthNow / DAMAGE_PER_SPARK)
	int sparksPrev = (healthPrev / DAMAGE_PER_SPARK)
	if ( (healthPrev == healthMax) && !isDoomed )
		--sparksPrev	// no spark on first damage

	int delta = (sparksPrev - sparksNow)
	if ( delta < 0 )
		return 0

	return (delta * SPARK_MULTIPLIER)
}

function TitanCockpit_DamageFeedback( entity player, cockpit, float damageAmount, damageType, damageOrigin, damageSourceId, bool doomedNow, int doomedDamage )
{
	RumbleForTitanDamage( damageAmount )

	vector joltDir = Normalize( player.CameraPosition() - damageOrigin )
	float joltDamage = doomedNow ? float( doomedDamage ) : damageAmount
	JoltCockpit( cockpit, player, joltDir, joltDamage, damageType, damageSourceId )

	bool isShieldHit = (damageType & DF_SHIELD_DAMAGE) ? true : false
	if ( isShieldHit )
		return

	int sparkCount = CalSparkCountForHit( player, damageAmount, doomedNow );
	//printt( "sparks: " + sparkCount + "  dmg: " + damageAmount + "  - " + player.GetHealth() + " / " + player.GetMaxHealth() )
	PlayCockpitSparkFX( cockpit, sparkCount )
}

function ServerCallback_TitanCockpitBoot()
{
	thread ServerCallback_TitanCockpitBoot_Internal()
}

function ServerCallback_TitanCockpitBoot_Internal()
{
	AutoExposureSetExposureCompensationBias( -6 )
	AutoExposureSnap()
	wait  0.1
	AutoExposureSetExposureCompensationBias( 0 )
}

function ServerCallback_TitanEMP( maxValue, duration, fadeTime, doFlash = true, doSound = true )
{
	thread TitanEMP_Internal( maxValue, duration, fadeTime, doFlash, doSound )
}

function TitanEMP_Internal( maxValue, duration, fadeTime, doFlash = true, doSound = true )
{
	entity player = GetLocalViewPlayer()

	player.Signal( "TitanEMP_Internal" )
	player.EndSignal( "TitanEMP_Internal" )

	player.EndSignal( "OnDeath" )
	player.EndSignal( "SettingsChanged" )

	local angles = Vector( 0, -90, 90 )

	local wide = 16
	local tall = 9

	float fovOffset = Graph( player.GetFOV(), 75, 120, 4, 2.5 )

	local empVgui = CreateClientsideVGuiScreen( "vgui_titan_emp", VGUI_SCREEN_PASS_VIEWMODEL, Vector(0,0,0), Vector(0,0,0), wide, tall );

	//empVgui.SetParent( player.GetViewModelEntity(), "CAMERA_BASE" )
	empVgui.SetRefract( true ) // Force refract resolve before drawing vgui. (This can cost GPU!)
	empVgui.SetParent( player )
	empVgui.SetAttachOffsetOrigin( < fovOffset, wide / 2, -tall / 2 > )
	empVgui.SetAttachOffsetAngles( angles )

	empVgui.GetPanel().WarpEnable()

	local EMPScreenFX = HudElement( "EMPScreenFX", empVgui.GetPanel() )
	local EMPScreenFlash = HudElement( "EMPScreenFlash", empVgui.GetPanel() )

	OnThreadEnd(
		function() : ( player, empVgui )
		{
			empVgui.Destroy()
		}
	)

	EMPScreenFX.Show()
	EMPScreenFX.SetAlpha( maxValue * 255 )
	EMPScreenFX.FadeOverTimeDelayed( 0, fadeTime, duration )

	if ( doFlash )
	{
		EMPScreenFlash.Show()
		EMPScreenFlash.SetAlpha( 255 )
		EMPScreenFlash.FadeOverTimeDelayed( 0, fadeTime + duration, 0 )
	}

	if ( doSound )
	{
		EmitSoundOnEntity( player, EMP_IMPARED_SOUND )
		wait duration
		FadeOutSoundOnEntity( player, EMP_IMPARED_SOUND, fadeTime )
	}

	wait fadeTime
}


void function LinkCoreHint( entity soul )
{
	if ( file.coreHintRui == null )
		return

	RuiTrackFloat( file.coreHintRui, "coreFrac", soul, RUI_TRACK_SCRIPT_NETWORK_VAR, GetNetworkedVariableIndex( "coreAvailableFrac" ) )
}


void function FlashCockpitHealth( vector color )
{
	if ( file.cockpitRui == null )
		return

	RuiSetGameTime( file.cockpitRui, "startFlashTime", Time() )
	RuiSetFloat3( file.cockpitRui, "flashColor", color )
}

void function UpdateHealthSegmentCount()
{
	if ( file.cockpitRui == null )
		return

	entity player = GetLocalViewPlayer()
	string playerSettings = player.GetPlayerSettings()
	float health = player.GetPlayerModHealth()
	float healthPerSegment = GetPlayerSettingsFieldForClassName_HealthPerSegment( playerSettings )
	RuiSetInt( file.cockpitRui, "numHealthSegments", int( health / healthPerSegment ) )
}
#if MP
void function NetworkedVarChangedCallback_UpdateVanguardRUICoreStatus( entity soul, int oldValue, int newValue, bool actuallyChanged )
{
	if ( file.cockpitRui == null )
		return

	if ( actuallyChanged == false )
		return

	entity player = GetLocalViewPlayer()
	if ( !IsValid( player ) || !player.IsTitan() )
		return

	UpdateHealthSegmentCount()

	string titanName = GetTitanCharacterName( player )
	if ( titanName == "vanguard" )
	{
		RuiSetString( file.cockpitRui, "titanInfo1", GetVanguardCoreString( player, 1 ) )
		RuiSetString( file.cockpitRui, "titanInfo2", GetVanguardCoreString( player, 2 ) )
		RuiSetString( file.cockpitRui, "titanInfo3", GetVanguardCoreString( player, 3 ) )
		RuiSetString( file.cockpitRui, "titanInfo4", GetVanguardCoreString( player, 4 ) )
	}
}
#endif

var function Scorch_CreateHotstreakBar()
{
	Assert( file.scorchHotstreakRui == null )

	file.scorchHotstreakRui = CreateFixedTitanCockpitRui( $"ui/scorch_hotstreak_bar.rpak" )

	RuiTrackFloat( file.scorchHotstreakRui, "coreMeterMultiplier", GetLocalViewPlayer(), RUI_TRACK_SCRIPT_NETWORK_VAR, GetNetworkedVariableIndex( "coreMeterModifier" ) )

	return file.scorchHotstreakRui
}

void function Scorch_DestroyHotstreakBar()
{
	TitanCockpitDestroyRui( file.scorchHotstreakRui )
	file.scorchHotstreakRui = null
}

bool function Scorch_ShouldCreateHotstreakBar()
{
	entity player = GetLocalViewPlayer()

	if ( !IsAlive( player ) )
		return false

	array<entity> mainWeapons = player.GetMainWeapons()
	if ( mainWeapons.len() == 0 )
		return false

	entity primaryWeapon = mainWeapons[0]
	return primaryWeapon.HasMod( "fd_hot_streak" )
}

int function GetBulletsAbsorbedCount( entity vortexWeapon )
{
	if ( !vortexWeapon )
		return 0

	entity vortexSphere = vortexWeapon.GetWeaponUtilityEntity()
	if ( !vortexSphere )
		return 0

	return vortexSphere.GetBulletAbsorbedCount()
}

int function GetProjectilesAbsorbedCount( entity vortexWeapon )
{
	if ( !vortexWeapon )
		return 0

	entity vortexSphere = vortexWeapon.GetWeaponUtilityEntity()
	if ( !vortexSphere )
		return 0

	return vortexSphere.GetProjectileAbsorbedCount()
}