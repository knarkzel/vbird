module neural

import rand
import math { powf }

fn sigmoid(x f32) f32 {
	return 1 / (1 + powf(math.e, -1))
}

struct Node {
mut:
	data    f32
	bias    f32
	weights []f32
}

fn (n Node) weighted(index int) f32 {
	return n.data * n.weights[index] + n.bias
}

fn (nx Node) + (ny Node) Node {
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
mut:
	nodes [][]Node
}

// network returns a new network created by the passed in structure
pub fn network(structure []int) Network {
	mut network := Network{}
	// Input layer and hidden layers
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
	// Output layer
	network.nodes << [Node{}].repeat(structure.last())
	return network
}

// process feeds input into the network
pub fn (mut n Network) process(input []f32) {
	// set input data for each node in first layer
	for i in 0 .. input.len {
		n.nodes[0][i].data = input[i]
	}
	// feed input to next layer and process with sigmoid of sum
	for i in 1 .. n.nodes.len {
		for j in 0 .. n.nodes[i].len {
			mut sum := f32(0)
			for node in n.nodes[i - 1] {
				sum += node.weighted(j)
			}
			n.nodes[i][j].data = sigmoid(sum)
		}
	}
}

// output returns the data from network after processing input
pub fn (n Network) output() []f32 {
	return n.nodes.last().map(it.data)
}

// mutate alters all the nodes based on probability
pub fn (mut n Network) mutate() {
	for mut layer in n.nodes {
		for mut node in layer {
			if rand.f32() < 0.2 {
				node.bias *= rand.f32_in_range(0.5, 1)
				node.bias += rand.f32_in_range(0, 0.1)
				for mut weight in node.weights {
					weight *= rand.f32_in_range(0.5, 1)
				}
			}
		}
	}
}

// crossover breeds the average between two networks together
pub fn (nx Network) crossover(ny Network) Network {
	mut layers := [][]Node{}
	for i in 0 .. nx.nodes.len {
		mut nodes := []Node{}
		for j in 0 .. nx.nodes[i].len {
			nodes << nx.nodes[i][j] + ny.nodes[i][j]
		}
		layers << nodes
	}
	return Network{
		nodes: layers
	}
}
