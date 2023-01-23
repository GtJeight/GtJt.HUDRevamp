global function HudRevampSettings_Init

void function HudRevampSettings_Init()
{
    printt("Adding settings :D")
	AddConVarSetting("comp_hud_accent_color", "Accent Color", "HUD Revamp - General", "float3")
	AddConVarSettingEnum("comp_hud_healthbar", "Titan Numerical Healthbar", 
        "HUD Revamp - General", [ "No", "Yes" ] )
	AddConVarSettingEnum("comp_hud_healthbar_overlap", "Health Number Overlap With Bar", 
        "HUD Revamp - General", [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_boost_text_color", "Amped/Boost Display Color", "HUD Revamp - General", "float3")

	AddConVarSetting("comp_hud_ammo_pos", "Ammo Position", "HUD Revamp - General", "float2")
	AddConVarSetting("comp_hud_holstered_weapons_pos", "Holstered Weapons Position", "HUD Revamp - General", "float2")

	AddConVarSetting("comp_hud_ability_bg_alpha", "Background Alpha", 
		"HUD Revamp - Abilities", "float")
	AddConVarSetting("comp_hud_ability_ui_scale", "UI Scale", "HUD Revamp - Abilities", "float")
	AddConVarSetting("comp_hud_ability_bar_thickness", "Progress Bar Thickness", "HUD Revamp - Abilities", "float")
	AddConVarSetting("comp_hud_ability_icon_scale", "Icon Scale", "HUD Revamp - Abilities", "float")
	AddConVarSetting("comp_hud_ability_bar_empty_color", "Bar Color (Empty)", 
		"HUD Revamp - Abilities", "float3")
	AddConVarSetting("comp_hud_ability_bg_bar_empty_color", "Background Bar Color (Empty)", 
		"HUD Revamp - Abilities", "float3")
	AddConVarSetting("comp_hud_ability_cooldown_pos_offset", "Cooldown Text Position Offset", "HUD Revamp - Abilities", "float2")
	AddConVarSettingEnum("comp_hud_vertical_side_bar", "Vertical Side Bar", 
        "HUD Revamp - Abilities", [ "No", "Yes" ] )

	AddConVarSetting("comp_hud_ordnance_position", "Ordnance Position", "HUD Revamp - Ability Specific", "float2")
	AddConVarSetting("comp_hud_tactical_position", "Tactical Position", "HUD Revamp - Ability Specific", "float2")
	AddConVarSetting("comp_hud_utility_position", "Titan Utility Position", "HUD Revamp - Ability Specific", "float2")
	//AddConVarSetting( "comp_hud_boost_icon_scale", "Boost Icon Scale", "HUD Revamp - Ability Specific", "float" )
	AddConVarSetting( "comp_hud_boost_position", "Boost Position", "HUD Revamp - Ability Specific", "float2" )

	AddConVarSettingEnum( "comp_hud_pilot_healthbar", "Enabled", "HUD Revamp - Pilot Health Bar", [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_pilot_healthbar_pos", "Position", "HUD Revamp - Pilot Health Bar", "float2" )
	AddConVarSetting( "comp_hud_pilot_healthbar_size", "Size", "HUD Revamp - Pilot Health Bar", "float2" )
	
	AddConVarSetting( "comp_hud_titan_meter_offset", "Offset", "HUD Revamp - Titan Meter", "float2" )
	AddConVarSetting( "comp_hud_titan_meter_scale", "Scale", "HUD Revamp - Titan Meter", "float2" )

	AddConVarSettingEnum("comp_hud_wpd", "Enable", 
        "HUD Revamp - Wallkick Practice Display", [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_wpd_pos", "Position", "HUD Revamp - Wallkick Practice Display", "float2" )
	AddConVarSetting("comp_hud_wpd_size", "Font Size", "HUD Revamp - Wallkick Practice Display", "float" )

	AddConVarSettingEnum( "comp_hud_damage_indicator", "Enabled", "HUD Revamp - Damage Indicator", [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_damage_indicator_duration", "Duration", "HUD Revamp - Damage Indicator", "float" )
	AddConVarSetting( "comp_hud_damage_indicator_fade_time", "Fade Time", "HUD Revamp - Damage Indicator", "float" )

	AddConVarSettingEnum( "comp_hud_incoming_damage_indicator", "Enabled", "HUD Revamp - Incoming Damage Indicator", [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_duration", "Duration", "HUD Revamp - Incoming Damage Indicator", "float" )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_fade_time", "Fade Time", "HUD Revamp - Incoming Damage Indicator", "float" )

	//AddConVarSetting("")
}