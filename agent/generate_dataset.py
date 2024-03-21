import os
import json
import numpy as np
from environment import RubiksCubeEnv
from tqdm import tqdm
import time


def generate_data(env, num_samples, min_scramble_moves, max_scramble_moves, file_path, log_every_n=10_000):
  """ Generate a dataset of scrambled Rubik's Cube states and their cost to go."""
  data = []

  # Generate a list of no_moves values uniformly distributed across the range
  no_moves_list = np.linspace(
    min_scramble_moves, max_scramble_moves, num_samples, dtype=int)

  for i, no_moves in enumerate(no_moves_list):
    state = env.reset(no_moves)
    data.append({'state': state, 'cost_to_go': int(no_moves)})

    if (i + 1) % log_every_n == 0 or i == num_samples - 1:
      samples_processed = i + 1

      print(f"Processed {samples_processed}/{num_samples} samples. ")

  with open(file_path, 'w') as f:
    json.dump(data, f)

  print(
    f"Generated {num_samples} samples and saved to {file_path}")


if __name__ == "__main__":
  server_address = '127.0.0.1'
  server_port = 4242
  cube_size = 2
  # cube_size = 3
  # cube_size = 4
  animation_enabled = False
  num_samples = 1_000_000
  min_scramble_moves = 0
  max_scramble_moves = 12  # for 2x2x2
  # max_scramble_moves = 15  # for 3x3x3 and 4x4x4
  file_path = 'data/rubiks_cube_data_2x2x2.json'
  # file_path = 'data/rubiks_cube_data_3x3x3.json'
  # file_path = 'data/rubiks_cube_data_4x4x4.json'

  env = RubiksCubeEnv(server_address, server_port,
                      cube_size, animation_enabled)
  generate_data(env, num_samples, min_scramble_moves,
                max_scramble_moves, file_path)
  env.close()
