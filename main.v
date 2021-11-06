import gg
import gx
import rand

struct Game {
mut:
	gg    &gg.Context
	time  int
	bird  Bird
	pipes []Pipe
}

// Bird logic
struct Bird {
mut:
	x        int = 256
	y        int
	size     int = 96
	velocity int
}

fn (mut bird Bird) update() {
	bird.velocity -= 1
	bird.y -= bird.velocity
}

// Pipe logic
struct Pipe {
mut:
	x int = 1920
	y int
	w int = 128
	h int
}

fn (mut pipe Pipe) update() {
	pipe.x -= 5
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

// Initialize window and state, then run
fn main() {
	mut game := &Game{
		gg: 0
		pipes: pipes()
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
	mut bird := &game.bird
	bird.update()
	game.gg.draw_rect(bird.x, bird.y, bird.size, bird.size, gx.rgb(26, 24, 34))
	if game.pipes.any(collides(bird, it)) || bird.y < 0 || bird.y + bird.size > 1080 {
		exit(0)
	}

	// Pipe draw / update logic
	for mut pipe in game.pipes {
		pipe.update()
		game.gg.draw_rect(pipe.x, pipe.y, pipe.w, pipe.h, gx.rgb(138, 198, 236))
	}

	game.gg.end()
}

// Key logic
fn on_event(e &gg.Event, mut game Game) {
	if e.typ == .key_down {
		match e.key_code {
			.escape { exit(0) }
			.space { game.bird.velocity = 20 }
			else {}
		}
	}
}
