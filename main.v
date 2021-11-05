module main

import gg
import gx

struct Game {
mut:
	gg   &gg.Context
	bird Bird
}

struct Bird {
mut:
	x        f32 = 256
	y        f32
	size     f32
	velocity f32
}

fn (mut bird Bird) update() {
	bird.velocity -= 1
	bird.y -= bird.velocity
}

fn main() {
	mut game := &Game{
		gg: 0
		bird: Bird{
			size: 128
		}
	}
	game.gg = gg.new_context(
		bg_color: gx.rgb(79, 229, 255)
		window_title: 'Flappy bird'
		frame_fn: frame
		user_data: game
		event_fn: on_event
	)
	game.gg.run()
}

fn frame(mut game Game) {
	game.bird.update()
	game.gg.begin()
	game.gg.draw_rect(game.bird.x, game.bird.y, game.bird.size, game.bird.size, gx.rgb(55,
		55, 55))
	game.gg.end()
}

fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .key_down {
		match e.key_code {
			.escape { exit(0) }
			.space { game.bird.velocity = 25 }
			else {}
		}
	}
}
