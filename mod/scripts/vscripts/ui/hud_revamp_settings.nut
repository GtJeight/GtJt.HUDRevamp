global function HudRevampSettings_Init

void function HudRevampSettings_Init()
{
    printt("Adding settings :D")
	AddConVarSetting("comp_hud_accent_color", "Accent Color", "HUD Revamp - General", "float3")
	AddConVarSetting("comp_hud_boost_text_color", "Amped/Boost Display Color", "HUD Revamp - General", "float3")

	AddConVarSettingEnum("comp_hud_healthbar", "Titan Numerical Healthbar",
        "HUD Revamp - General", [ "No", "Yes" ] )
	AddConVarSettingEnum("comp_hud_healthbar_overlap", "Health Number Overlap With Bar",
        "HUD Revamp - General", [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_health_text_offset", "Health Number Offset", "HUD Revamp - General", "float2" )

	AddConVarSetting("comp_hud_tactical_position", "Left Utility Position", "HUD Revamp - Utilities", "float2")
	AddConVarSetting("comp_hud_ordnance_position", "Middle Utility Position", "HUD Revamp - Utilities", "float2")
	AddConVarSetting("comp_hud_utility_position", "Right Utility Position", "HUD Revamp - Utilities", "float2")
	AddConVarSetting("comp_hud_ability_cooldown_pos_offset", "Cooldown Text Position Offset", "HUD Revamp - Utilities", "float2")

	AddConVarSettingEnum("comp_hud_wpd", "Enable",
        "HUD Revamp - Wallkick Practice Display", [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_wpd_pos", "Position", "HUD Revamp - Wallkick Practice Display", "float2" )
	AddConVarSetting("comp_hud_wpd_size", "Font Size", "HUD Revamp - Wallkick Practice Display", "float" )
	AddConVarSetting("comp_hud_wpd_color", "Color", "HUD Revamp - Wallkick Practice Display", "float3" )

	AddConVarSettingEnum( "comp_hud_damage_indicator", "Enabled", "HUD Revamp - Damage Indicator", [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_damage_indicator_duration", "Duration", "HUD Revamp - Damage Indicator", "float" )
	AddConVarSetting( "comp_hud_damage_indicator_fade_time", "Fade Time", "HUD Revamp - Damage Indicator", "float" )

	AddConVarSettingEnum( "comp_hud_incoming_damage_indicator", "Enabled", "HUD Revamp - Incoming Damage Indicator", [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_duration", "Duration", "HUD Revamp - Incoming Damage Indicator", "float" )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_fade_time", "Fade Time", "HUD Revamp - Incoming Damage Indicator", "float" )

	AddConVarSettingEnum( "comp_phase_glitch_indicator", "Enable", "HUD Revamp - Phase Glitch Detector", [ "No", "Yes" ] )
	AddConVarSettingEnum( "comp_core_meter_timer", "Enable", "HUD Revamp - Core Meter Timer", [ "No", "Yes" ] )
	AddConVarSetting("comp_core_meter_timer_pos", "Timer Position", "HUD Revamp - Core Meter Timer", "float2" )
	//AddConVarSetting("")
}