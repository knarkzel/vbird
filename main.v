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
	size     int
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
		bird: Bird{
			size: 96
		}
		pipes: pipes()
	}
	game.gg = gg.new_context(
		bg_color: gx.rgb(0xC9, 0xCE, 0xDC)
		window_title: 'Flappy bird'
		frame_fn: frame
		user_data: game
		event_fn: on_event
	)
	game.gg.run()
}

// Draw / update logic
fn frame(mut game Game) {
	game.time += 1
	if game.time > 90 {
		game.pipes << pipes()
		game.time = 0
	}

	game.gg.begin()

	game.bird.update()
	game.gg.draw_rect(game.bird.x, game.bird.y, game.bird.size, game.bird.size, gx.rgb(0x1A,
		0x18, 0x22))
	if game.pipes.any(collides(game.bird, it)) || game.bird.y < 0
		|| game.bird.y + game.bird.size > 1080 {
		exit(0)
	}

	for mut pipe in game.pipes {
		pipe.update()
		game.gg.draw_rect(pipe.x, pipe.y, pipe.w, pipe.h, gx.rgb(0x8A, 0xC6, 0xEC))
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
