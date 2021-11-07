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
	for _ in 0 .. 250 {
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
	speedup    int = 1
	time       int
	birds      []Bird
	dead_birds []Bird
	pipes      []Pipe
}

fn (mut g Game) reset() {
	g.pipes.clear()
	g.pipes = pipes()
	g.time = 0

	capacity := g.dead_birds.len
	selection := if g.dead_birds.len < 5 { capacity } else { 5 }
	g.dead_birds.sort(a.fitness > b.fitness)
	// fill 50% with good birds
	for g.birds.len < g.dead_birds.len / 2 {
		bx := rand.int_in_range(0, selection)
		by := rand.int_in_range(0, selection)
		mut network := g.dead_birds[bx].network.crossover(g.dead_birds[by].network)
		network.mutate()
		g.birds << Bird{
			network: network
		}
	}
	// fill rest 50% with new birds
	for g.birds.len < capacity {
		g.birds << Bird{
			network: neural.network([3, 10, 1])
		}
	}
	g.dead_birds = []
}

// Bird logic
struct Bird {
mut:
	x        f32 = 256
	y        f32 = 1080 / 3
	size     f32 = 96
	velocity f32
	fitness  f32
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
		h: rand.intn(1080 / 2)
	}
	bottom := Pipe{
		y: top.h + 128 * 3
		h: 1080
	}
	return [top, bottom]
}

fn collides(bird Bird, pipe Pipe) bool {
	return bird.x < pipe.x + pipe.w && bird.x + bird.size > pipe.x && bird.y < pipe.y + pipe.h
		&& bird.size + bird.y > pipe.y
}

fn frame(mut g Game) {
	for _ in 0 .. g.speedup {
		g.time++
		if g.time > 90 {
			g.pipes << pipes()
			g.time = 0
		}

		for mut bird in g.birds {
			bird.fitness++
			bird.velocity--
			bird.y -= bird.velocity

			closest := g.pipes.filter(it.x + it.w > 256)
			y := bird.y / 1080
			bottom := closest[1].y / 1080
			top := (closest[0].y + closest[0].h) / 1080
			bird.network.process([y, bottom, top])

			if bird.network.output()[0] > 0.5 {
				bird.velocity = 20
			}

			if g.pipes.any(collides(bird, it)) || bird.y < 0 || bird.y + bird.size > 1080 {
				index := g.birds.index(*bird)
				g.dead_birds << bird
				g.birds.delete(index)
			}
		}

		for mut pipe in g.pipes {
			pipe.x -= 5
			if pipe.x + pipe.w < 0 {
				index := g.pipes.index(*pipe)
				g.pipes.delete(index)
			}
		}

		if g.birds.len <= 0 {
			g.reset()
		}
	}

	g.gg.begin()

	for bird in g.birds {
		g.gg.draw_rect(bird.x, bird.y, bird.size, bird.size, gx.rgb(26, 24, 34))
	}

	for pipe in g.pipes {
		g.gg.draw_rect(pipe.x, pipe.y, pipe.w, pipe.h, gx.rgb(138, 198, 236))
	}

	g.gg.end()
}

// Key logic
fn on_event(e &gg.Event, mut g Game) {
	if e.typ == .key_down {
		match e.key_code {
			.escape {
				exit(0)
			}
			.space {
				if g.speedup == 1 {
					g.speedup = 20
				} else {
					g.speedup = 1
				}
			}
			else {}
		}
	}
}
