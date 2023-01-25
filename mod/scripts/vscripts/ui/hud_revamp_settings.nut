global function HudRevampSettings_Init

void function HudRevampSettings_Init()
{
	AddModTitle("HUD Revamp ver GtJ8")

	// General
	AddModCategory("General")
	AddConVarSetting("comp_hud_accent_color", "Accent Color", "float3")
	AddConVarSetting("comp_hud_boost_text_color", "Amped/Boost Display Color", "float3")

	AddConVarSettingEnum("comp_hud_healthbar", "Titan Numerical Healthbar",
        [ "No", "Yes" ] )
	AddConVarSettingEnum("comp_hud_healthbar_overlap", "Health Number Overlap With Bar",
        [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_health_text_offset", "Health Number Offset", "float2" )

	// Utilities
	AddModCategory("Utilities")
	AddConVarSetting("comp_hud_tactical_position", "Left Utility Position", "float2")
	AddConVarSetting("comp_hud_ordnance_position", "Middle Utility Position", "float2")
	AddConVarSetting("comp_hud_utility_position", "Right Utility Position", "float2")
	AddConVarSettingEnum("comp_hud_ability_cooldown", "Show Cooldown Time", [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_ability_cooldown_pos_offset", "Cooldown Text Position Offset", "float2")

	// Core/Titam Meter
	AddModCategory("Core/Titan Meter")
	AddConVarSetting("comp_hud_titan_meter_offset", "Core Meter Offset", "float2" )
	AddConVarSetting("comp_hud_titan_meter_scale", "Scale", "float2" )

	// Wallkick Practice Display
	AddModCategory("Wallkick Practice Display")
	AddConVarSettingEnum("comp_hud_wpd", "Enable", [ "No", "Yes" ] )
	AddConVarSetting("comp_hud_wpd_pos", "Position", "float2" )
	AddConVarSetting("comp_hud_wpd_size", "Font Size", "float" )
	AddConVarSetting("comp_hud_wpd_color", "Color", "float3" )

	// Damage Indicator
	AddModCategory("Damage Indicator")
	AddConVarSettingEnum( "comp_hud_damage_indicator", "Enabled",  [ "No", "Yes" ] )
	AddConVarSettingEnum( "comp_hud_damage_indicator_victim_hp", "Show Victim HP",  [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_damage_indicator_duration", "Duration",  "float" )
	AddConVarSetting( "comp_hud_damage_indicator_fade_time", "Fade Time",  "float" )
	AddConVarSetting( "comp_hud_damage_indicator_color", "Color",  "float3" )
	AddConVarSetting( "comp_hud_damage_indicator_color_crit", "Color on critical hits",  "float3" )

	// Incoming Damage Indicator
	AddModCategory("Incoming Damage Indicator")
	AddConVarSettingEnum( "comp_hud_incoming_damage_indicator", "Enabled", [ "No", "Yes" ] )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_duration", "Duration", "float" )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_fade_time", "Fade Time", "float" )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_color", "Color", "float3" )

	// Core Meter Timer
	AddModCategory("Core Meter Timer")
	AddConVarSettingEnum( "comp_core_meter_timer", "Enable", [ "No", "Yes" ] )
	AddConVarSettingEnum( "comp_core_meter_timer_style", "Style", [ "Number", "Text" ] )
	AddConVarSetting("comp_core_meter_timer_pos", "Timer Position", "float2" )
	AddConVarSetting("comp_core_meter_timer_size", "Font Size", "float" )

	// Phase Glitch Detector
	AddModCategory("Phase Glitch Detector")
	AddConVarSettingEnum( "comp_phase_glitch_detector", "Enable", [ "No", "Yes" ] )
	AddConVarSetting("comp_phase_glitch_detector_pos", "Detector Position", "float2")
	AddConVarSetting("comp_phase_glitch_detector_size", "Font Size", "float" )
}