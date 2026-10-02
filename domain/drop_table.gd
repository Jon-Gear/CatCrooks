class_name DropTable
extends Resource

const TICKET_TOTAL := 100

@export var id: String = ""
@export var weights: Dictionary = {}


func total_weight() -> float:
	var total := 0.0
	for weight in weights.values():
		total += float(weight)
	return total


func normalize() -> Dictionary:
	var total := total_weight()
	if total <= 0.0 or total <= TICKET_TOTAL:
		return weights.duplicate()
	var tickets := Dictionary()
	for entry in weights:
		var weight := float(weights[entry])
		tickets[entry] = 0 if weight <= 0.0 else maxi(1, roundi(weight * TICKET_TOTAL / total))
	return tickets


func pick(random: RandomNumberGenerator = null) -> DefinitionId:
	var tickets := normalize()
	var total := 0.0
	for ticket in tickets.values():
		total += float(ticket)
	if total <= 0.0:
		return DefinitionId.create("")
	var roll := (random if random != null else RandomNumberGenerator.new()).randf() * total
	for entry in tickets:
		roll -= float(tickets[entry])
		if roll < 0.0:
			return DefinitionId.create(String(entry))
	return DefinitionId.create(String(tickets.keys().back()))
