extends Control

const PerksDebugPanel = preload("res://Code/Debug/DebugPerksPanel.gd")

var debug_panels: Dictionary = {}
var current_panel: Control = null

@onready var panels_container = $PanelsContainer
@onready var tab_container = $TabContainer

func _ready():
	setup_menu()
	# Make sure pause state is maintained when debug menu opens
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup_menu():
	# Register panels
	register_debug_panel("Perks", PerksDebugPanel.new())
	
	# Connect tab changed signal
	tab_container.tab_changed.connect(_on_tab_changed)
	
	# Show first panel by default
	if not debug_panels.is_empty():
		show_panel(debug_panels.keys()[0])

func register_debug_panel(name: String, panel: Control):
	debug_panels[name] = panel
	panels_container.add_child(panel)
	
	# Create a new Control node for the tab
	var tab_control = Control.new()
	tab_control.name = name
	tab_container.add_child(tab_control)
	
	panel.visible = false

func show_panel(name: String):
	if current_panel:
		current_panel.visible = false
	
	if debug_panels.has(name):
		current_panel = debug_panels[name]
		current_panel.visible = true
		
		# Set the current tab
		var tab_index = tab_container.get_tab_idx_from_control(tab_container.get_node(name))
		if tab_index != -1:
			tab_container.current_tab = tab_index

func _on_tab_changed(tab: int):
	# Get the control for this tab
	var tab_control = tab_container.get_child(tab)
	if tab_control:
		show_panel(tab_control.name)

func _input(event):  # Changed from _unhandled_input
	if event.is_action_pressed("ui_cancel"):
		# When closing debug menu, restore the pause menu
		var pause_menu = get_tree().root.get_node_or_null("MainGame/CanvasLayer/UiPauseMenu")
		if pause_menu:
			pause_menu.show()
			queue_free()
		else:
			# If no pause menu found, unpause and close
			get_tree().paused = false
			for node in get_tree().get_nodes_in_group("game"):
				node.process_mode = Node.PROCESS_MODE_INHERIT
			queue_free()
		get_viewport().set_input_as_handled()  # Changed to use Viewport method
