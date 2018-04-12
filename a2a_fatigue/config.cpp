class CfgPatches
{
	class m_a2ata3_fatigue
	{
		units[] = {};
		weapons[]={};
		requiredVersion = 0.1;
		requiredAddons[] = {"a2a_anims_config", "A3_Characters_F", "A3_UI_F", "m_a2ata3_data",};
	};
};
//#include "cfgAnimStamina.cpp" //configure animation exhaust speed (causing many problems with other mods)
class CfgFunctions
{
	class MXMLA2
	{
		tag = "MXMLA2";
		class Misc
		{
			class a2legacyFatigue
			{
				file = "A2ATA3\a2a_fatigue\Functions\Misc\fn_legacyFatigue.sqf"; // Function file path
			};
		};
	};
};
/*
class CfgVehicles
{
	class Land;
	class Man: Land {};
	class CAManBase: Man
	{
		class EventHandlers
		{
			class MXMLA2_LegacyFatigue
			{
				init = "(_this select 0) spawn MXMLA2_fnc_a2legacyFatigue"; //On player spawn (disable while testing)
			};
		};
	};
}; */