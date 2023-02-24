global function HudRevampSettings_Init

void function HudRevampSettings_Init()
{
	AddModTitle("HUD Revamp by Asymmetr")

	// General
	AddModCategory("#hud_general")
	AddConVarSetting("comp_hud_accent_color", "#comp_hud_accent_color", "float3")
	AddConVarSetting("comp_hud_boost_text_color", "#comp_hud_boost_text_color", "float3")

	AddConVarSettingEnum("comp_hud_healthbar", "#comp_hud_healthbar",
        [ "#hud_no", "#hud_yes" ] )
	AddConVarSettingEnum("comp_hud_healthbar_overlap", "#comp_hud_healthbar_overlap",
        [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting("comp_hud_health_text_offset", "#comp_hud_health_text_offset", "float2" )

	// Utilities
	AddModCategory("#hud_utilities")
	AddConVarSettingEnum("comp_hud_ability_cooldown", "#comp_hud_ability_cooldown", [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting("comp_hud_tactical_position", "#comp_hud_tactical_position", "float2")
	AddConVarSetting("comp_hud_ordnance_position", "#comp_hud_ordnance_position", "float2")
	AddConVarSetting("comp_hud_utility_position", "#comp_hud_utility_position", "float2")

	// Core/Titam Meter
	AddModCategory("#hud_core_titan_meter")
	AddConVarSetting("comp_hud_titan_meter_offset", "#comp_hud_titan_meter_offset", "float2" )
	AddConVarSetting("comp_hud_titan_meter_scale", "#comp_hud_titan_meter_scale", "float2" )

	// Pilot Health Display
	AddModCategory("#hud_pliot_health_display")
	AddConVarSettingEnum("comp_hud_pilot_healthbar", "#comp_hud_pilot_healthbar", [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting("comp_hud_pilot_healthbar_pos", "#comp_hud_pilot_healthbar_pos", "float2" )
	AddConVarSetting("comp_hud_pilot_healthbar_size", "#comp_hud_pilot_healthbar_size", "float" )
	AddConVarSetting("comp_hud_pilot_healthbar_color", "#comp_hud_pilot_healthbar_color", "float3" )

	// Wallkick Practice Display
	AddModCategory("#hud_wpd")
	AddConVarSettingEnum("comp_hud_wpd", "#comp_hud_wpd", [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting("comp_hud_wpd_pos", "#comp_hud_wpd_pos", "float2" )
	AddConVarSetting("comp_hud_wpd_size", "#comp_hud_wpd_size", "float" )
	AddConVarSetting("comp_hud_wpd_color", "#comp_hud_wpd_color", "float3" )

	// Damage Indicator
	AddModCategory("#hud_damage_indicator")
	AddConVarSettingEnum( "comp_hud_damage_indicator", "#comp_hud_damage_indicator",  [ "#hud_no", "#hud_yes" ] )
	AddConVarSettingEnum( "comp_hud_damage_indicator_style", "#comp_hud_damage_indicator_style",  [ "#hud_damage_indicator_style_classic", "#hud_damage_indicator_style_flashy" ] )
	AddConVarSettingEnum( "comp_hud_damage_indicator_victim_hp", "#comp_hud_damage_indicator_victim_hp",  [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting( "comp_hud_damage_indicator_pos", "#comp_hud_damage_indicator_pos",  "float2" )
	AddConVarSetting( "comp_hud_damage_indicator_duration", "#comp_hud_damage_indicator_duration",  "float" )
	AddConVarSetting( "comp_hud_damage_indicator_fade_time", "#comp_hud_damage_indicator_fade_time",  "float" )
	AddConVarSetting( "comp_hud_damage_indicator_color", "#comp_hud_damage_indicator_color",  "float3" )
	AddConVarSetting( "comp_hud_damage_indicator_color_crit", "#comp_hud_damage_indicator_color_crit",  "float3" )

	// Incoming Damage Indicator
	AddModCategory("#hud_incoming_damage_indicator")
	AddConVarSettingEnum( "comp_hud_incoming_damage_indicator", "#comp_hud_incoming_damage_indicator", [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_duration", "#comp_hud_incoming_damage_indicator_duration", "float" )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_fade_time", "#comp_hud_incoming_damage_indicator_fade_time", "float" )
	AddConVarSetting( "comp_hud_incoming_damage_indicator_color", "#comp_hud_incoming_damage_indicator_color", "float3" )

	// Core Meter Timer
	AddModCategory("#hud_core_timer")
	AddConVarSettingEnum( "comp_core_meter_timer", "#comp_core_meter_timer", [ "#hud_no", "#hud_yes" ] )
	AddConVarSettingEnum( "comp_core_meter_timer_style", "#comp_core_meter_timer_style", [ "#hud_Number", "#hud_Text", "#hud_Legion", "#hud_Hybrid" ] )
	AddConVarSetting("comp_core_meter_timer_pos", "#comp_core_meter_timer_pos", "float2" )
	AddConVarSetting("comp_core_meter_timer_size", "#comp_core_meter_timer_size", "float" )

	// Phase Glitch Detector
	AddModCategory("#hud_psgd")
	AddConVarSettingEnum( "comp_phase_glitch_detector_enabled", "#comp_phase_glitch_detector_enabled", [ "#hud_no", "#hud_yes" ] )
	AddConVarSetting("comp_phase_glitch_detector_pos", "#comp_phase_glitch_detector_pos", "float2")
	AddConVarSetting("comp_phase_glitch_detector_size", "#comp_phase_glitch_detector_size", "float" )

	// Ion HUD
	AddModCategory("#hud_ion_hud")
	AddConVarSettingEnum( "comp_hud_fix_ion_energy_bar", "#comp_hud_fix_ion_energy_bar", [ "#hud_no", "#hud_yes" ] )
	AddConVarSettingEnum( "comp_hud_use_short_energy_bar", "#comp_hud_use_short_energy_bar", [ "#hud_no", "#hud_yes" ] )
}
