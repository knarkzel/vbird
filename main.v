module main

import gg
import gx
import rand
import neural { Network }

// Initialize window and state, then run
fn main() {
	mut game := &Game{
		gg: 0
		pipes: pipes()
	}
	for _ in 0 .. 100 {
		game.birds << Bird{
			network: neural.network([3, 10, 1])
		}
	}
	game.gg = gg.new_context(
		bg_color: gx.rgb(201, 206, 220)
		window_title: 'Flappy bird'
		frame_fn: frame
		user_data: game
		event_fn: on_event
	)
	game.gg.run()
}

// Game state
struct Game {
mut:
	gg         &gg.Context
	time       int
	birds      []Bird
	dead_birds []Bird
	pipes      []Pipe
}

fn (mut g Game) reset() {
	g.pipes = pipes()
	g.birds = g.dead_birds
	g.dead_birds = []
	for mut bird in g.birds {
		bird.y = 1080 / 3
		bird.velocity = 0
	}
}

// Bird logic
struct Bird {
mut:
	x        f32 = 256
	y        f32 = 1080 / 3
	size     f32 = 96
	velocity f32
	network  Network
}

// Pipe logic
struct Pipe {
mut:
	x f32 = 1920
	y f32
	w f32 = 128
	h f32
}

fn pipes() []Pipe {
	top := Pipe{
		y: 0
		h: rand.intn(128 + 1080 / 2)
	}
	bottom := Pipe{
		y: top.h + 128 * 3
		h: 1080
	}
	return [top, bottom]
}

// Collision
fn collides(bird Bird, pipe Pipe) bool {
	return bird.x < pipe.x + pipe.w && bird.x + bird.size > pipe.x && bird.y < pipe.y + pipe.h
		&& bird.size + bird.y > pipe.y
}

// Draw / update logic
fn frame(mut game Game) {
	game.gg.begin()

	// Timer update logic
	game.time++
	if game.time > 90 {
		game.pipes << pipes()
		game.time = 0
	}

	// Bird draw / update logic
	for mut bird in game.birds {
		// Movement
		bird.velocity -= 1
		bird.y -= bird.velocity

		// Find closest pipe, pass to network
		closest := game.pipes.filter(it.x > 256)
		top := closest[0].y / 1080.0
		bottom := closest[1].y / 1080.0
		y := bird.y / 1080.0
		bird.network.process([top, bottom, y])

		// React to network output
		if bird.network.output()[0] > 0.5 {
			bird.velocity = 20
		}

		// Drawing
		game.gg.draw_rect(bird.x, bird.y, bird.size, bird.size, gx.rgb(26, 24, 34))
		if game.pipes.any(collides(bird, it)) || bird.y < 0 || bird.y + bird.size > 1080 {
			index := game.birds.index(*bird)
			game.dead_birds << bird
			game.birds.delete(index)
		}
	}

	// Pipe draw / update logic
	for mut pipe in game.pipes {
		pipe.x -= 5
		game.gg.draw_rect(pipe.x, pipe.y, pipe.w, pipe.h, gx.rgb(138, 198, 236))
		if pipe.x + pipe.w < 0 {
			index := game.pipes.index(*pipe)
			game.pipes.delete(index)
		}
	}

	// Reset if all birds are dead
	if game.birds.len <= 0 {
		game.reset()
	}

	game.gg.end()
}

// Key logic
fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .key_down {
		match e.key_code {
			.escape { exit(0) }
			else {}
		}
	}
}
