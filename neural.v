module neural

import rand
import math { powf }

fn sigmoid(x f32) f32 {
	return 1 / (1 + powf(math.e, -x))
}

struct Node {
pub mut:
	data    f32
	bias    f32
	weights []f32
}

fn (nx Node) average(ny Node) Node {
	mut weights := []f32{}
	for i in 0 .. nx.weights.len {
		weights << (nx.weights[i] + ny.weights[i]) / 2
	}
	return Node{
		bias: (nx.bias + ny.bias) / 2
		weights: weights
	}
}

pub struct Network {
pub mut:
	nodes [][]Node
}

pub fn network(structure []int) Network {
	mut network := Network{}
	for i in 0 .. structure.len - 1 {
		mut nodes := []Node{}
		for _ in 0 .. structure[i] {
			mut weights := []f32{}
			for _ in 0 .. structure[i + 1] {
				weights << rand.f32_in_range(-1, 1)
			}
			nodes << Node{
				bias: rand.f32_in_range(-1, 1)
				weights: weights
			}
		}
		network.nodes << nodes
	}
	network.nodes << [Node{}].repeat(structure.last())
	return network
}

pub fn (mut n Network) process(input []f32) {
	for i, mut node in n.nodes[0] {
		node.data = input[i]
	}
	for i in 1 .. n.nodes.len {
		for j in 0 .. n.nodes[i].len {
			mut sum := f32(0)
			for node in n.nodes[i - 1] {
				sum += node.data * node.weights[j] + node.bias
			}
			n.nodes[i][j].data = sigmoid(sum)
		}
	}
}

pub fn (n Network) output() []f32 {
	return n.nodes.last().map(it.data)
}

pub fn (mut n Network) mutate() {
	for mut layer in n.nodes {
		for mut node in layer {
			if rand.f32() < 0.2 {
				node.bias *= rand.f32_in_range(0.5, 1)
				for mut weight in node.weights {
					weight *= rand.f32_in_range(0.5, 1)
				}
			}
		}
	}
}

pub fn (nx Network) crossover(ny Network) Network {
	mut layers := [][]Node{}
	for i, layer in nx.nodes {
		mut nodes := []Node{}
		for j, node in layer {
			nodes << node.average(ny.nodes[i][j])
		}
		layers << nodes
	}
	return Network{
		nodes: layers
	}
}
