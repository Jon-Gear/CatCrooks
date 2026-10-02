class_name WaveSchedule
extends Resource

@export var spawner_count: int = 4
@export var inter_wave_seconds: float = 5.0


func enemies_for_wave(wave_number: int) -> int:
	return spawner_count * maxi(wave_number, 0)
