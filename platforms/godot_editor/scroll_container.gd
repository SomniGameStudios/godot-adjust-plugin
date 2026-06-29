# MIT License
#
# Copyright (c) 2026-present Somni Game Studios
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends ScrollContainer

# Drag-to-scroll: lets the options list be swiped with a finger (or mouse drag).
# Scroll position tracks the pointer 1:1 while dragging inside the container; no
# inertia. Relies on Godot's "emulate mouse from touch" (on by default).

var _swiping := false
var _swipe_start := Vector2.ZERO
var _swipe_mouse_start := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if get_global_rect().has_point(get_global_mouse_position()):
		if event is InputEventMouseButton:
			var mb := event as InputEventMouseButton
			if mb.pressed:
				_swiping = true
				_swipe_start = Vector2(get_h_scroll(), get_v_scroll())
				_swipe_mouse_start = mb.position
			else:
				_swiping = false
		elif _swiping and event is InputEventMouseMotion:
			var mm := event as InputEventMouseMotion
			var delta := mm.position - _swipe_mouse_start
			if horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
				set_h_scroll(int(_swipe_start.x - delta.x))
			if vertical_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
				set_v_scroll(int(_swipe_start.y - delta.y))
	else:
		_swiping = false
