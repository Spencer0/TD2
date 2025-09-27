extends Control
class_name GameStatsUI

# -------------------------
# UI References
# -------------------------
@onready var money_label: RichTextLabel = $PanelContainer2/GameStats/MoneyLabel
@onready var lives_label: RichTextLabel = $PanelContainer2/GameStats/HealthLabel 
@onready var wave_label: RichTextLabel = $PanelContainer2/GameStats/WavesLabel

# -------------------------
# Dependencies
# -------------------------
@export var level_manager: LevelManager

# -------------------------
# Lifecycle
# -------------------------
func _ready() -> void:
	if level_manager:
		level_manager.connect("stats_updated", Callable(self, "_on_stats_updated"))
		# Initialize with current values
		_on_stats_updated(level_manager.current_money, level_manager.current_lives, level_manager.current_wave)
	else:
		push_error("GameStatsUI: No LevelManager assigned!")

# -------------------------
# Signal Handlers
# -------------------------
func _on_stats_updated(money: int, lives: int, wave: int) -> void:
	if money_label:
		money_label.text = "Money: $" + str(money)
	if lives_label:
		lives_label.text = "Lives: " + str(lives)
	if wave_label:
		wave_label.text = "Wave: " + str(wave) + "/" + str(level_manager.max_waves if level_manager else "?")

# -------------------------
# Public API (for manual updates if needed)
# -------------------------
func update_display(money: int, lives: int, wave: int, max_waves: int = 10) -> void:
	if money_label:
		money_label.text = "Money: $" + str(money)
	if lives_label:
		lives_label.text = "Lives: " + str(lives)  
	if wave_label:
		wave_label.text = "Wave: " + str(wave) + "/" + str(max_waves)
