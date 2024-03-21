import heapq
import matplotlib.pyplot as plt
import torch
import json
import random
from torch.utils.data import Dataset
from value_network import ValueNetwork
from value_network import CubeDataset
from environment import RubiksCubeEnv
import time
from tqdm import tqdm

device = torch.device("cuda" if torch.cuda.is_available() else "cpu")


def one_hot_encode(cube_state):
  # Convert the cube state to the input format expected by the model
  state_oh = []

  # Iterate over each face's colors
  for face in cube_state:
    for pair in face:
      for color in pair:
        # Create a one-hot encoded vector for this color
        color_oh = [0] * 6
        color_oh[color] = 1
        state_oh.extend(color_oh)

  return torch.tensor(state_oh, dtype=torch.float)


def heuristic(cube_state, model):
  """ Estimate the cost to solve the cube from the given state using the given model """
  # state_oh = one_hot_encode(cube_state)
  # Add batch dimension and move to device
  state_oh = cube_state.unsqueeze(0).to(device)

  with torch.no_grad():
    cost_estimate = model(state_oh).item()  # Get the heuristic value
  return cost_estimate


def reconstruct_path(came_from, current_state):
  """ Reconstruct the path from the start state to the current state using the came_from dictionary"""
  total_path = [current_state]
  while current_state in came_from:
    current_state, action = came_from[current_state]
    # Prepend action because we are tracing back the path
    total_path.insert(0, action)
  return total_path


def generate_all_possible_actions(cube_size):
  """ Generate all possible actions for the given cube size """
  actions = []
  for side in [0, 1]:
    for layer in range(cube_size):
      for angle in [0, 1]:
        action = (side, layer, angle)
        actions.append(action)

  return actions


def reverse_move(action):
  """ Reverse the given action """
  return (action[0], action[1], 1 - action[2])


def astar_search(model, env, initial_scramble=2, max_explored_states=200, lambda_weight=1):
  """ Perform an A* search to solve the cube from the given state using the given model
  lambda_weight is a parameter that can be used to adjust the weight of the heuristic in the f score
  to control the tradeoff between the heuristic and the cost to reach the current state.
  """
  env.reset(0)
  initial_actions = []

  # Scramble the cube with random actions
  for _ in range(initial_scramble):
    action = random.choice(generate_all_possible_actions(env.cube_size))
    env.step(action)
    initial_actions.append(action)

  initial_state = env.get_state()
  initial_state_encoded = one_hot_encode(initial_state)
  initial_path = []

  # Initialize the open and closed sets
  open_set = set([tuple(initial_state_encoded.tolist())])
  closed_set = set()

  # Initialize the g and f scores for each state
  g_score = {tuple(initial_state_encoded.tolist()): 0}
  f_score = {tuple(initial_state_encoded.tolist()): heuristic(
    initial_state_encoded, model) * lambda_weight}
  came_from = {tuple(initial_state_encoded.tolist()): initial_path}

  explored_states_count = 0

  while open_set and explored_states_count < max_explored_states:
    explored_states_count += 1
    current_encoded = min(open_set, key=lambda o: f_score[o])
    current_path = came_from[current_encoded]

    # Reset to the initial state and reapply the actions to get to the current state
    env.reset(0)
    for action in initial_actions + current_path:
      env.step(action)

    # Check if the current state is the goal state
    if env.is_solved(env.get_state()):
      return current_path

    open_set.remove(current_encoded)
    closed_set.add(current_encoded)

    # Generate all possible actions and apply them to the current state
    for action in generate_all_possible_actions(env.cube_size):
      env.step(action)
      new_state = env.get_state()
      new_state_encoded = one_hot_encode(new_state)
      new_path = current_path + [action]

      if tuple(new_state_encoded.tolist()) in closed_set:
        env.step(reverse_move(action))  # Reverse the action to undo it
        continue

      tentative_g_score = g_score[current_encoded] + 1
      tentative_f_score = tentative_g_score + \
          heuristic(new_state_encoded, model) * lambda_weight

      # If the new state is not in the open set or the new path has a lower f score, update the open set and scores
      if tuple(new_state_encoded.tolist()) not in open_set or tentative_f_score < f_score.get(tuple(new_state_encoded.tolist()), float('inf')):
        open_set.add(tuple(new_state_encoded.tolist()))
        came_from[tuple(new_state_encoded.tolist())] = new_path
        g_score[tuple(new_state_encoded.tolist())] = tentative_g_score
        f_score[tuple(new_state_encoded.tolist())] = tentative_f_score

      env.step(reverse_move(action))  # Reverse the action to undo it

  print("Reached maximum number of explored states without finding a solution.")
  return None


def test_astar(model_paths, cube_sizes, costs_to_go, env_setup):
  """ Test the A* search algorithm with the given model paths, cube sizes, and costs_to_go"""
  solve_rates = {size: [] for size in cube_sizes}
  move_counts = {size: [] for size in cube_sizes}

  for size in cube_sizes:
    network_path = model_paths[size]
    if size == 2:
      model = ValueNetwork(144).to(device)
      # costs_to_go = range(0, 12)
    elif size == 3:
      model = ValueNetwork(324).to(device)
      # costs_to_go = range(0, 15)
    elif size == 4:
      model = ValueNetwork(576).to(device)
      # costs_to_go = range(0, 15)
    model.load_state_dict(torch.load(network_path, map_location=device))
    model.eval()
    env = RubiksCubeEnv(**env_setup, cube_size=size)

    for cost_to_go in costs_to_go:
      print(f"Testing {size}x{size}x{size} cube with cost_to_go {cost_to_go}")
      solve_count = 0
      total_moves = 0
      test_cases = 10

      for _ in tqdm(range(test_cases)):
        actions = astar_search(model, env, cost_to_go)

        if actions is not None:
          solve_count += 1
          total_moves += len(actions)

      solve_rate = solve_count / test_cases
      avg_moves = total_moves / solve_count if solve_count > 0 else 0

      solve_rates[size].append(solve_rate)
      move_counts[size].append(avg_moves)

  return solve_rates, move_counts


def plot_results(solve_rates, move_counts, costs_to_go):
  """ Plot the solve rates and move counts for the given cost-to-go values"""
  plt.figure(figsize=(14, 6))

  colors = {'2': '#425066', '3': '#12b5cb', '4': '#e52592'}

  max_length = max(len(costs_to_go), max(len(rates) for rates in solve_rates.values(
  )), max(len(counts) for counts in move_counts.values()))

  # Adjust the lengths of the lists to match the maximum possible length - there was a bug when the lengths were different
  if len(costs_to_go) < max_length:
    # print(f"Warning: 'costs_to_go' length is less than some of the 'rates' or 'counts'. Adjusting 'x_values' accordingly.")
    costs_to_go = costs_to_go + [None] * (max_length - len(costs_to_go))

  for size, rates in solve_rates.items():
    x_values = costs_to_go[:len(rates)]
    plt.plot(x_values, rates, '-o',
             label=f'{size}x{size}x{size}', color=colors[str(size)])

  plt.title('Wskaźnik rozwiązywalności w zależności od cost-to-go')
  plt.xlabel('Cost-to-go')
  # Adjust xticks to match the maximum possible length
  plt.xticks(costs_to_go[:max_length])
  plt.ylabel('Solve Rate')
  plt.legend()
  plt.grid(True)
  plt.savefig('solve_rate_vs_cost_to_go.png')
  plt.show()

  plt.figure(figsize=(14, 6))

  for size, counts in move_counts.items():
    x_values = costs_to_go[:len(counts)]
    plt.plot(x_values, counts, '-o',
             label=f'{size}x{size}x{size}', color=colors[str(size)])

  plt.title('Średnia ilość ruchów w zależności od cost-to-go')
  plt.xlabel('Cost-to-go')
  # Adjust xticks to match the maximum possible length
  plt.xticks(costs_to_go[:max_length])
  plt.ylabel('Średnia ilość ruchów')
  plt.legend()
  plt.grid(True)
  plt.show()

  plt.tight_layout()
  plt.savefig('average_move_count_vs_cost_to_go.png')


if __name__ == '__main__':
  """ Test for solve rate and average moves """
  device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
  model_paths = {
      2: './networks/best_value_network_2x2x2.pth',
      3: './networks/best_value_network_3x3x3.pth',
      4: './networks/best_value_network_4x4x4.pth'
  }

  cube_sizes = [2, 3, 4]
  cost_to_gos = range(0, 14)
  env_setup = {
      'server_address': '127.0.0.1',
      'server_port': 4242,
      'animation_enabled': False
  }

  solve_rates, move_counts = test_astar(
    model_paths, cube_sizes, cost_to_gos, env_setup)
  plot_results(solve_rates, move_counts, cost_to_gos)

""" For individual testing """
#   cube_sizes = [2]
#   cost_to_gos = range(0, 12)
#   env_setup = {
#       'server_address': '127.0.0.1',
#       'server_port': 4242,
#       'animation_enabled': False
#   }
#   solve_rates_2x2x2, move_counts_2x2x2 = test_astar(
#     model_paths, cube_sizes, cost_to_gos, env_setup)

#   plot_results(solve_rates_2x2x2, move_counts_2x2x2, cost_to_gos)

#   cube_sizes = [3]
#   cost_to_gos = range(0, 15)
#   env_setup = {
#       'server_address': '127.0.0.1',
#       'server_port': 4242,
#       'animation_enabled': False
#   }
#   solve_rates_3x3x3, move_counts_3x3x3 = test_astar(
#     model_paths, cube_sizes, cost_to_gos, env_setup)
#   plot_results(solve_rates_3x3x3, move_counts_3x3x3, cost_to_gos)

#   cube_sizes = [4]
#   cost_to_gos = range(0, 15)
#   env_setup = {
#       'server_address': '127.0.0.1',
#       'server_port': 4242,
#       'animation_enabled': False
#   }
#   solve_rates_4x4x4, move_counts_4x4x4 = test_astar(
#     model_paths, cube_sizes, cost_to_gos, env_setup)
#   plot_results(solve_rates_4x4x4, move_counts_4x4x4, cost_to_gos)

#   combined_solve_rates = {
#     '2': solve_rates_2x2x2[2],
#     '3': solve_rates_3x3x3[3],
#     '4': solve_rates_4x4x4[4]
# }

#   combined_move_counts = {
#       '2': move_counts_2x2x2[2],
#       '3': move_counts_3x3x3[3],
#       '4': move_counts_4x4x4[4]
#   }

#   combined_costs_to_go = list(range(0, 15))

#   plot_results(combined_solve_rates, combined_move_counts, combined_costs_to_go)
