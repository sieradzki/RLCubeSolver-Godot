import socket
import json
import threading


class RubiksCubeEnv:
  """ TCP client and an environment wrapper class """
  def __init__(self, server_address, server_port, cube_size=3, animation_enabled=False):
    self.server_address = server_address
    self.server_port = server_port
    self.cube_size = cube_size

    # Define observation and action spaces
    self.observation_space = self._define_observation_space(cube_size)
    self.action_space = self._define_action_space(cube_size)

    # Initialize server connection
    self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    self.socket.connect((server_address, server_port))

    # Ideally this would be run BEFORE the environment is created but we can just reset so w/e
    command = f"initialize:{cube_size},{int(animation_enabled)}"
    self._send(command)
    print(self._receive())

  def _define_observation_space(self, cube_size):
    # Each face of the cube can have a value from 0 to 5 (6 colors)
    return {'low': 0, 'high': 5, 'shape': (6, cube_size, cube_size)}

  def _define_action_space(self, cube_size):
    # Actions: side (2 options) vertical or horizontal, layer (range(cube_size)), angle (2 options)
    return {'side': [0, 2], 'layer': range(cube_size), 'angle': range(2)}

  def reset(self, no_moves):
    """ Reset the environment and receive the initial state """
    self._send(f"reset:{no_moves}")
    return self._receive()

  def step(self, action):
    """ Send the action to the server and receive the next state, reward and done flag """
    side_action = 0 if action[0] == 0 else 2
    action_str = f"{side_action},{action[1]},{action[2]}"
    self._send(f"step:{action_str}")
    return self._receive()

  def generate_neighbours(self):
    """ Generate neighbouring states by applying every possible move """
    neighbours = {}

    for side in [0, 1]:
      for layer in range(self.cube_size):
        for angle in [0, 1]:
          action = (side, layer, angle)
          neighbour_state, reward, done = self.step(
            action)

          # Add the resulting state and the action that led to it to the dictionary
          neighbours[action] = neighbour_state

          # Reset to the original state to try the next action
          action = (side, layer, 1 - angle)
          self.step(action)

    return neighbours

  def get_state(self):
    """ Get state of the environment """
    self._send("get_state")
    return self._receive()

  def is_solved(self, state):
    """ Check if the cube is in a solved state """
    self._send(f"is_solved:{state}")
    return self._receive()

  def close(self):
    """ Close the socket """
    self.socket.close()

  def _send(self, message):
    """ Send message to server """
    self.socket.sendall(message.encode())

  def _receive(self):
    """ Receive response from server """
    response = self.socket.recv(4096)
    return json.loads(response.decode())


if __name__ == "__main__":
  """ Testing """
  server_address = '127.0.0.1'
  server_port = 4242

  # Create the environment
  env = RubiksCubeEnv(server_address, server_port,
                      cube_size=2, animation_enabled=True)
  print(env.action_space)
  print(env.observation_space)

  # Test get_neighbours
  state = env.reset(0)
  # neighbours = env.generate_neighbours()
  # for action, neighbour in neighbours.items():
  # print(action, neighbour)
  input()
