extends VBoxContainer

const Save = preload("res://addons/savekit_lite/savekit_lite.gd")

func _ready() -> void:
	$Save.pressed.connect(func():
		$Result.text = "Save error: %s" % Save.save_data({"level": 2, "inventory": ["key", "星"]}))
	$Load.pressed.connect(func():
		var result = Save.load_data()
		$Result.text = "Load error: %s\nData: %s" % [result.error, result.data])
