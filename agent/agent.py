import random
from environment import RubiksCubeEnv
import time


class RubiksCubeAgent:
  def __init__(self, env):
    self.env = env

  def select_action(self):
    # Randomly select an action from the action space
    action = {
        'side': random.choice(list(self.env.action_space['side'])),
        'layer': random.choice(list(self.env.action_space['layer'])),
        'angle': random.choice(list(self.env.action_space['angle']))
    }
    return action

  def train(self, num_episodes):
    for episode in range(num_episodes):
      state = self.env.reset()
      done = False
      i = 0

      while not done and i < 200:
        action = self.select_action()
        next_state, reward, done = self.env.step(action)
        state = next_state
        time.sleep(0.1)
        i += 1

      print(f"Episode {episode + 1} finished, solved: {done}, steps: {i}")


if __name__ == "__main__":
  server_address = '127.0.0.1'
  server_port = 4242
  cube_size = 3
  animation_enabled = True

  env = RubiksCubeEnv(server_address, server_port,
                      cube_size, animation_enabled, random_moves=3)
  agent = RubiksCubeAgent(env)

  num_episodes = 100
  agent.train(num_episodes)

  env.close()
