/*
	Author: Josef Zemanek (Edited by MAXIMILI)

	Description:
	Legacy Fatigue Mod main function

	Parameter(s):
		_player: OBJECT - unit to apply fatigue to

	Returns:
	NOTHING
*/
_player = _this select 0
// --- variables init
_defaultStamina = getNumber (configFile >> "CfgMovesFatigue" >> "staminaDuration");
_runCD = getNumber (configFile >> "CfgMovesFatigue" >> "staminaCooldown");
_exhaustionEnd = 10e10;

// --- init EH from config is not executed upon respawn, need to run it manually
if (isServer) then {
	if !(_player getVariable ["BIS_fatMod_EHAdded", FALSE]) then {
		_player setVariable ["BIS_fatMod_EHAdded", TRUE];
		_player addMPEventHandler ["MPRespawn", {(_player select 0) remoteExec ["MXMLA2_fnc_a2legacyFatigue"]}];
	};
};

sleep 1;

while {TRUE} do {
	waitUntil {(local _player && vehicle _player == _player) || isNull _player || !alive _player};
	if (isNull _player || !alive _player) exitWith {};
	_player enableAimPrecision FALSE;
	_addedDrain = 0;
	while {local _player && alive _player && !isNull _player && vehicle _player == _player} do {
		_maxStamina = _defaultStamina - (_defaultStamina * load _player);
		_noSprintLim = _maxStamina / 2;		// --- sprint treshold
		_noRunLim = 0;				// --- run treshold
		_tmout = 0.5;
		if !(isPlayer _player) then {_tmout = 5 + random 5};	// --- longer timeout for AIs (performance tweak)

		// --- disable run / sprint based on stamina level

		if (getStamina _player <= _noRunLim) then {
			if !(isForcedWalk _player) then {
				_player forceWalk FALSE;
				_exhaustionEnd = time + _runCD;
				setStaminaScheme "Exhausted";
			};
		} else {
			if (isForcedWalk _player && time > _exhaustionEnd) then {
				_player forceWalk FALSE;
				setStaminaScheme "FastDrain";
			};
			if (getStamina _player <= 62) then {
				if (isSprintAllowed _player) then {
					_player allowSprint TRUE;
					_player setStamina 64;
					setStaminaScheme "Exhausted";
				};
			} else {
				if !(isSprintAllowed _player) then {
					_player allowSprint TRUE;
					setStaminaScheme "Default";
				};
			};
			if (getStamina _player > _noSprintLim) then {
			_player forceWalk FALSE;
			_player allowSprint TRUE;
			setStaminaScheme "Default";
			};
		};

		_prevPos = getPosASL _player;
		_prevStamina = (getStamina _player) - _addedDrain;
		if (_player getVariable ["BIS_fatigueSlowDrain", FALSE]) then {
			sleep _tmout;
		} else {
			waitUntil {!(_player getVariable ["BIS_fatigueSlowDrain", FALSE])};
		};
		sleep _tmout;
		if (!alive _player || isNull _player) exitWith {};
		_curPos = getPosASL _player;
		_curStamina = getStamina _player;
		_prevASL = _prevPos select 2;
		_staminaDiff = _prevStamina - _curStamina;
		if (_prevStamina <= 0) then {_staminaDiff = 0};

		// --- calculate & apply extended stamina drain based on terrain gradient

		if (_prevPos distance _curPos > 0.25) then {
			_curASL = _curPos select 2;
			_diffZ = _prevASL - _curASL;
			_grad = tan (_diffZ atan2 ([_prevPos, _curPos] call BIS_fnc_distance2D));
			if (_grad > -0.3 && _grad < 0.5 ) then {
				_addedDrain = abs (_staminaDiff * _grad);		// --- impact of terrain gradient below sprinting threshold
			} else {
				_addedDrain = abs (_staminaDiff * _grad * 2);	// --- impact of terrain gradient above sprinting threshold
			};
			if (isPlayer _player) then {
				_player setVariable ["BIS_fatigueSlowDrain", TRUE];
				_slowDrainScr = [_player, _addedDrain, _tmout] spawn {
					_unit = _player select 0;
					_drain = _player select 1;
					_tmout = ((_player select 2) * 0.9);
					_steps = 5;
					for [{_i = 0}, {_i < _drain}, {_i = _i + (_drain / _steps)}] do {
						_drainNow = (_drain / _steps);
						player setStamina ((getStamina player) - _drainNow);
						sleep (_tmout / _steps);
					};
				};
				_player setVariable ["BIS_fatigueSlowDrain", FALSE];
			} else {
				_player setStamina (_curStamina - _addedDrain);
			};
		};

		// --- slow down animations based on stamina level

		_animSpeedCoef = 0.6 + (0.4 * (_curStamina / _maxStamina));
		_maxSlowdown = getNumber (configFile >> "CfgMovesMaleSdr" >> "States" >> animationState player >> "relSpeedMin");
		if (_maxSlowdown > 0 && _maxSlowdown > _animSpeedCoef) then {_animSpeedCoef = _maxSlowdown};	// --- respect maximum slowdown of a given animation defined in config
		_player setAnimSpeedCoef _animSpeedCoef;

		// --- weapon sway

		_staminaPerc = _curStamina / _maxStamina;
		_stanceAimPrecision = getAnimAimPrecision player;
		_player setCustomAimCoef (5 - (_staminaPerc * 5) + _stanceAimPrecision);
	};
	if !(alive _player) exitWith {};
};
