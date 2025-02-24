module main

import gg
import gx
import os
import rand
import bfck

/*         ---UTILS---        */
pub fn delete[T](arr []T, index int) []T {
    if index < 0 || index >= arr.len {
        return arr
    }

    mut new_arr := unsafe { arr[..index] }
    new_arr << arr[index + 1..]
    return new_arr
}

pub fn find[T](arr []T, elem T) int {
	for n,i in arr {if i == elem {return n}} return -1
}

pub fn pad(n u64, len u8) string {
    mut num_str := n.str()
    for num_str.len < int(len) {
        num_str = ' ' + num_str
    }
    return num_str
}

pub fn color_transition(start_color gx.Color, end_color gx.Color, total_steps int, current_step int) gx.Color {
	if current_step <= 0 {
		return start_color
	}
	if current_step >= total_steps {
		return end_color
	}

	r1, g1, b1, a1 := start_color.r, start_color.g, start_color.b, start_color.a
	r2, g2, b2, a2 := end_color.r, end_color.g, end_color.b, end_color.a

	t := f32(current_step) / f32(total_steps)

	r := u8(f32(r1) + (f32(r2) - f32(r1)) * t)
	g := u8(f32(g1) + (f32(g2) - f32(g1)) * t)
	b := u8(f32(b1) + (f32(b2) - f32(b1)) * t)
	a := u8(f32(a1) + (f32(a2) - f32(a1)) * t)

	return gx.Color{r, g, b, a}
}
/*--------------------------*/

const window_title = "Brainfuck Race"
const window_width = 1080
const window_height = 720
const allowed_keycodes = unsafe{[gg.KeyCode(65), gg.KeyCode(68), gg.KeyCode(83), gg.KeyCode(87), gg.KeyCode(262),
	gg.KeyCode(263), gg.KeyCode(264), gg.KeyCode(265)]}

enum State {
	menu
	rules
	ingame
	tasks
	pause
	p1_win
	p2_win
	tutorial
}

struct App {
mut:
	gg         &gg.Context = unsafe {nil}
	txtcfg		 gx.TextCfg
	theme			 Theme
	frame_counter	u64
	state			 State = .menu // temporarly
	ui				 UI
	pressed    []gg.KeyCode = []gg.KeyCode{cap: 8}
	p1_bf      bfck.Brainfuck
	p2_bf      bfck.Brainfuck
	p1_anim    int
	p2_anim    int
	str_task   string
	m_select   int
}

struct Theme {
mut:
	background		gx.Color
	f_color			gx.Color
	s_color			gx.Color
	f_selection		gx.Color
	s_selection		gx.Color
	font_color		gx.Color
	task_back		gx.Color
}

struct UI {
mut:
	window_width	int
	window_height	int
	border_width	int
	font_size		int
}

fn (mut app App) new_game() {
	app.p1_bf = bfck.new_brainfuck("")
	app.p2_bf = bfck.new_brainfuck("")
	app.str_task = ''
}

fn init(mut app App) {
	app.ui.window_width = window_width
	app.ui.window_height = window_height
	app.ui.border_width = (window_height / 40 + window_width / 40) / 2
	app.ui.font_size = 32
	app.new_game()
}

fn (mut app App) handle_combo(k1 gg.KeyCode, k2 gg.KeyCode) {
		 if (k1 == .w && k2 == .a) || (k2 == .w && k1 == .a) {app.p1_bf.add_command('[')}
	else if (k1 == .w && k2 == .d) || (k2 == .w && k1 == .d) {app.p1_bf.add_command(']')}
	else if (k1 == .s && k2 == .d) || (k2 == .s && k1 == .d) {app.p1_bf.add_command('.')}
	else if (k1 == .s && k2 == .a) || (k2 == .s && k1 == .a) {app.p1_bf.add_command(',')}
	else if (k1 == .w && k2 == .s) || (k2 == .w && k1 == .s) {app.p1_bf.code = ''}
	else if (k1 == .a && k2 == .d) || (k2 == .a && k1 == .d) {
		if app.p1_bf.code.len != 0 {app.p1_bf.code = app.p1_bf.code[0..app.p1_bf.code.len - 1]}
	}

	else if (k1 == .up && k2 == .left) || (k2 == .up && k1 == .left) {app.p2_bf.add_command('[')}
	else if (k1 == .up && k2 == .right) || (k2 == .up && k1 == .right) {app.p2_bf.add_command(']')}
	else if (k1 == .down && k2 == .right) || (k2 == .down && k1 == .right) {app.p2_bf.add_command('.')}
	else if (k1 == .down && k2 == .left) || (k2 == .down && k1 == .left) {app.p2_bf.add_command(',')}
	else if (k1 == .down && k2 == .up) || (k2 == .down && k1 == .up) {app.p2_bf.code = ''}
	else if (k1 == .left && k2 == .right) || (k2 == .left && k1 == .right) {
		if app.p2_bf.code.len != 0 {app.p2_bf.code = app.p2_bf.code[0..app.p2_bf.code.len - 1]}
	}
}

fn (mut app App) handle_move (ek gg.KeyCode) {
	aidx := find(allowed_keycodes, ek)
	if aidx != -1 {
		idx := find(app.pressed, ek)
		if idx != -1 {
			app.pressed = delete(app.pressed, idx)
			mut combo := -1
			if aidx < 4 { //p1 keykode
				for n,i in app.pressed {if find(allowed_keycodes, i) < 4 {combo = n}}
				if app.p1_bf.code.len % 31 == 0 && app.p1_bf.code.len != 0 {app.p1_bf.code += "!"}
				if combo == -1 {
					match ek {
						.w {app.p1_bf.add_command('+')}
						.a {app.p1_bf.add_command('<')}
						.s {app.p1_bf.add_command('-')}
						.d {app.p1_bf.add_command('>')}
						else {}
					}
				} else {
					app.handle_combo(ek, app.pressed[combo])
					app.pressed = delete(app.pressed, combo)
				}
				app.p1_bf = bfck.new_brainfuck(app.p1_bf.code)
				app.p1_bf.run() or {}
				if app.p1_bf.out == app.str_task {app.state = .p1_win app.pressed = []}
				app.p1_anim = 20
			} else {
				for n,i in app.pressed {if find(allowed_keycodes, i) > 3 {combo = n}}
				if app.p2_bf.code.len % 31 == 0 && app.p2_bf.code.len != 0 {app.p2_bf.code += "!"}
				if combo == -1 {
					match ek {
						.up     {app.p2_bf.add_command('+')}
						.left   {app.p1_bf.add_command('<')}
						.down   {app.p1_bf.add_command('-')}
						.right  {app.p1_bf.add_command('>')}
						else {}
					}
				} else {
					app.handle_combo(ek, app.pressed[combo])
					app.pressed = delete(app.pressed, combo)
				}
				app.p2_bf = bfck.new_brainfuck(app.p2_bf.code)
				app.p2_bf.run() or {}
				if app.p2_bf.out == app.str_task {app.state = .p2_win; app.pressed = []}
				app.p2_anim = 20
			}
		}
	}
}

fn (mut app App) handle_task_keys (ek gg.KeyCode) {
	if (ek == .w && app.pressed.contains(.up)) || (ek == .up && app.pressed.contains(.w)) {app.state = .ingame; app.pressed = []}
}

fn (mut app App) handle_menu_keys(ek gg.KeyCode) {
  if ek == .up {app.m_select--}
  else if ek == .down {app.m_select++}
  if app.m_select < 0 {app.m_select = 3}
  else if app.m_select > 3 {app.m_select = 0}
  if ek == .enter {
    match app.m_select {
      0 {app.state = .tasks}
      3 {exit(0)}
      else {}
    }
  }
}

fn on_event(e &gg.Event, mut app App) {
	match e.typ {
		.mouse_down {}
		.mouse_up {}
		.touches_ended {}
		.touches_began {}
		.key_down {
			ek := e.key_code
			if ek == .escape {app.gg.quit()}
			else if (app.state == .ingame || app.state ==.tasks) && allowed_keycodes.contains(ek) && !app.pressed.contains(ek) {
				app.pressed << ek
			}
			else if app.state == .p1_win || app.state == .p2_win {
				app.new_game()
				app.state = .tasks
			}
		}
		.key_up {
			ek := e.key_code
			if app.state == .ingame  {app.handle_move(ek)}
			if app.state == .tasks   {app.handle_task_keys(ek)}
			if app.state == .menu    {app.handle_menu_keys(ek)}
		}
		.resized, .restored, .resumed {}
		else {}
	}
}

fn frame(mut app App) {
	app.frame_counter++
	app.gg.begin()
	match app.state {
	  .menu   {app.draw_menu()}
		.ingame {app.draw_ingame()}
		.tasks  {app.draw_tasks()}
		.p1_win, .p2_win {app.draw_win()}
		else {}
	}
	app.gg.end()
}

fn (mut app App) gen_task () {
	lines := os.read_lines("str_tasks") or {panic(err)}
	app.str_task = lines[rand.int_in_range(0, lines.len) or {0}]
}
fn (mut app App) draw_menu() {
  app.gg.draw_rect_filled(0, 0, window_width, window_height, app.theme.task_back)
  mut cfg := gx.TextCfg{
    size: (app.ui.window_width + app.ui.window_height) / 15
    color: app.theme.background
    align: .center
    vertical_align: .middle
  }
  app.gg.draw_text(app.ui.window_width / 2, app.ui.window_height / 6, "Brainfuck Race", cfg)
  cfg = gx.TextCfg{...cfg, size: (app.ui.window_width + app.ui.window_height) / 30}
  hstep := int(app.ui.window_height / 6)
  x := int(app.ui.window_width / 2)
  app.gg.draw_text(x, app.ui.window_height / 6 + hstep * 1, "Start game", if app.m_select != 0 {cfg} else {gx.TextCfg{...cfg, color: app.theme.f_selection}})
  app.gg.draw_text(x, app.ui.window_height / 6 + hstep * 2, "Rules", if app.m_select != 1 {cfg} else {gx.TextCfg{...cfg, color: app.theme.s_selection}})
  app.gg.draw_text(x, app.ui.window_height / 6 + hstep * 3, "Tutorial", if app.m_select != 2 {cfg} else {gx.TextCfg{...cfg, color: app.theme.f_selection}})
  app.gg.draw_text(x, app.ui.window_height / 6 + hstep * 4, "Exit", if app.m_select != 3 {cfg} else {gx.TextCfg{...cfg, color: app.theme.s_selection}})
}

fn (mut app App) draw_win() {
	cfg := gx.TextCfg {
		size: (app.ui.window_width + app.ui.window_height) / 25
		color: app.theme.background
		align: .center
		vertical_align: .middle
		mono: true
	}
	if app.state == .p1_win {
		app.gg.draw_rect_filled(0, 0, app.ui.window_width, app.ui.window_height, app.theme.f_color)
		app.gg.draw_text(app.ui.window_width / 2, app.ui.window_height / 2, 'Player 1 won!', cfg)
	} else if app.state == .p2_win {
		app.gg.draw_rect_filled(0, 0, app.ui.window_width, app.ui.window_height, app.theme.s_color)
		app.gg.draw_text(app.ui.window_width / 2, app.ui.window_height / 2, 'Player 2 won!', cfg)
	}
}

fn (mut app App) draw_tasks() {
	if app.str_task == '' {app.gen_task()}
	app.gg.draw_rect_filled(0, 0, app.ui.window_width, app.ui.window_height, app.theme.task_back)
	cfg := gx.TextCfg {
		size: (app.ui.window_width + app.ui.window_height) / 25
		color: app.theme.background
		align: .center
		vertical_align: .middle
		mono: true
	}
	app.gg.draw_text(app.ui.window_width / 2, app.ui.window_height / 3, 'Print "${app.str_task}"', cfg)
	p1_ready, p2_ready := app.pressed.contains(.w), app.pressed.contains(.up)
	app.gg.draw_rounded_rect_filled(
		app.ui.window_width / 2 - 100,
		app.ui.window_height / 3 + app.ui.border_width * 4,
		200,
		100,
		20,
		app.theme.background
	)
	app.gg.draw_text(
		app.ui.window_width / 2 - 50,
		app.ui.window_height / 3 + app.ui.border_width * 6 + 100,
		'p1',
		cfg
	)
	app.gg.draw_text(
		app.ui.window_width / 2 + 50,
		app.ui.window_height / 3 + app.ui.border_width * 6 + 100,
		'p2',
		cfg
	)
	app.gg.draw_line(
		app.ui.window_width / 2,
		app.ui.window_height / 3 + app.ui.border_width * 4,
		app.ui.window_width / 2,
		app.ui.window_height / 3 + app.ui.border_width * 4 + 100,
		app.theme.task_back
	)
	if p1_ready {
		app.gg.draw_circle_filled(
			app.ui.window_width / 2 - 50,
			app.ui.window_height / 3 + app.ui.border_width * 4 + 50,
			30,
			app.theme.f_color
		)
	}
	if p2_ready {
		app.gg.draw_circle_filled(
			app.ui.window_width / 2 + 50,
			app.ui.window_height / 3 + app.ui.border_width * 4 + 50,
			30,
			app.theme.s_color
		)
	}
}

fn (mut app App) draw_ingame() {
	app.gg.draw_rect_filled(0, 0, app.ui.window_width / 2, app.ui.window_height, app.theme.f_color)
	app.gg.draw_rect_filled(app.ui.window_width / 2, 0, app.ui.window_width / 2, app.ui.window_height, app.theme.s_color)
	app.gg.draw_rounded_rect_filled(
		app.ui.border_width,
		app.ui.border_width,
		app.ui.window_width / 2 - app.ui.border_width * 2,
		app.ui.window_height - app.ui.border_width * 2,
		20,
		app.theme.background
	)
	app.gg.draw_rounded_rect_filled(
		app.ui.window_width / 2 + app.ui.border_width,
		app.ui.border_width,
		app.ui.window_width / 2 - app.ui.border_width * 2,
		app.ui.window_height - app.ui.border_width * 2,
		20,
		app.theme.background
	)

	player_size := (app.ui.window_height + app.ui.window_width) / 100
	player_x := app.ui.window_width / 4 - player_size / 2
	player_y := app.ui.window_height - app.ui.window_height / 3

	if app.p1_anim != 0 {
	  mut circ_col := color_transition(app.theme.f_color, app.theme.s_color, 10, 20 - app.p1_anim)
		if app.p1_anim < 11 {circ_col = color_transition(app.theme.s_color, app.theme.f_color, 10, 10 - app.p1_anim)}
		app.p1_anim--
		app.gg.draw_circle_filled(player_x, player_y, player_size, circ_col)
	} else {app.gg.draw_circle_filled(player_x, player_y, player_size, app.theme.f_color)}
	if app.p2_anim != 0 {
    mut circ_col := color_transition(app.theme.s_color, app.theme.f_color, 10, 20 - app.p2_anim)
    if app.p2_anim < 11 {circ_col = color_transition(app.theme.f_color, app.theme.s_color, 10, 10 - app.p2_anim)}
    app.p2_anim--
    app.gg.draw_circle_filled(player_x + app.ui.window_width / 2, player_y, player_size, circ_col)
	} else {app.gg.draw_circle_filled(player_x + app.ui.window_width / 2, player_y, player_size, app.theme.s_color)}
	fcfg := gx.TextCfg {
		size: (app.ui.window_width + app.ui.window_height) / 50
		color: app.theme.f_color
		align: .center
		mono: true
	}
	scfg := gx.TextCfg{
		...fcfg
		color:app.theme.s_color
	}
	mut lines := app.p1_bf.code.split("!")
	if lines.len > 5 {lines = unsafe{lines[lines.len - 5..lines.len]}}
	for y, line in lines {
		app.gg.draw_text(player_x, (app.ui.window_height / 4 - player_size / 2) / 2 + y * fcfg.size, line, fcfg)
	}
	lines = app.p2_bf.code.split("!")
	if lines.len > 5 {lines = unsafe{lines[lines.len - 5..lines.len]}}
	for y, line in lines {
		app.gg.draw_text(player_x + app.ui.window_width / 2, (app.ui.window_height / 4 - player_size / 2) / 2 + y * fcfg.size, line, scfg)
	}

	mut x := app.ui.border_width * 3/2
	mut y := player_y + app.ui.border_width * 3
	if app.p1_bf.out != '' {app.gg.draw_text(x, y, "Out: ${app.p1_bf.out}", gx.TextCfg{...fcfg, align: .left})}
	y += app.ui.border_width * 2
	for n, i in app.p1_bf.tape {
		if app.p1_bf.ptr == n {
			app.gg.draw_text(x, y, pad(i, 4), scfg)
		} else {app.gg.draw_text(x, y, pad(i, 4), fcfg)}
		x += ((app.ui.window_width + app.ui.window_height) / 38)
		if n == 9 {x = app.ui.border_width * 3 / 2; y += (app.ui.window_width + app.ui.window_height) / 50}
	}
	x = app.ui.border_width * 3/2 + app.ui.window_width / 2
	y = player_y + app.ui.border_width * 3
	if app.p2_bf.out != '' {app.gg.draw_text(x, y, "Out: ${app.p2_bf.out}", gx.TextCfg{...scfg, align: .left})}
	y += app.ui.border_width * 2
	for n, i in app.p2_bf.tape {
		if app.p2_bf.ptr == n {
			app.gg.draw_text(x, y, pad(i, 4), fcfg)
		} else {app.gg.draw_text(x, y, pad(i, 4), scfg)}
		x += ((app.ui.window_width + app.ui.window_height) / 38)
		if n == 9 {x = app.ui.border_width * 3/2 + app.ui.window_width / 2; y += (app.ui.window_width + app.ui.window_height) / 50}
	}
}

fn main () {
	mut app := &App{}
	app.theme.background 	= gx.rgb(24, 24, 37)
	app.theme.f_color 		= gx.rgb(137, 180, 250)
	app.theme.f_selection	= gx.rgb(137, 220, 235)
	app.theme.s_color 		= gx.rgb(243, 139, 168)
	app.theme.s_selection	= gx.rgb(235, 160, 172)
	app.theme.font_color	= gx.rgb(245, 224, 220)
	app.theme.task_back		= gx.rgb(203, 166, 247)
	app.gg = gg.new_context(
		bg_color: app.theme.background
		width: window_width
		height: window_height
		window_title: window_title
		frame_fn: frame
		init_fn: init
		event_fn: on_event
		user_data: app
		sample_count: 4
	)
	app.txtcfg = gx.TextCfg {
		color: app.theme.font_color
		size: app.ui.font_size
	}
	app.gg.run()
}
