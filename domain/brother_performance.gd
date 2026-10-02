class_name BrotherPerformance
extends RefCounted

enum Phase { IDLE, ACCEL, RUN, DECEL, PAIN }

const IDLE := &"Idle"
const ACCEL := &"Accel"
const RUN := &"Run"
const DECEL := &"Decel"
const HIT_FRONT := &"Hit_Front"
const HIT_BACK := &"Hit_Back"

var phase: int = Phase.IDLE

var _has_input: bool = false


func advance(p_has_input: bool) -> StringName:
	_has_input = p_has_input
	if phase == Phase.PAIN:
		return ""
	match phase:
		Phase.IDLE:
			if p_has_input:
				phase = Phase.ACCEL
				return ACCEL
		Phase.RUN:
			if not p_has_input:
				phase = Phase.DECEL
				return DECEL
	return ""


func settled() -> StringName:
	match phase:
		Phase.ACCEL:
			phase = Phase.RUN
			return RUN
		Phase.DECEL:
			phase = Phase.IDLE
			return IDLE
		Phase.PAIN:
			phase = Phase.RUN if _has_input else Phase.IDLE
			return RUN if _has_input else IDLE
	return ""


func take_hit(p_from_front: bool) -> StringName:
	phase = Phase.PAIN
	return HIT_FRONT if p_from_front else HIT_BACK


func is_hurting() -> bool:
	return phase == Phase.PAIN