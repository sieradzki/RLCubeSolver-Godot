# RLCubeSolver-Godot
Solving Rubik's Cube with Reinforcement Learning

## Table of Contents
- [RLCubeSolver-Godot](#rlcubesolver-godot)
  - [Table of Contents](#table-of-contents)
  - [1. Description](#1-description)
  - [2. Features](#2-features)
  - [3. Installation and Setup](#3-installation-and-setup)
    - [3.1 Development Setup](#31-development-setup)
    - [3.2 Running the Solver](#32-running-the-solver)
  - [4. Methodology](#4-methodology)
  - [5. Results \& Limitations](#5-results--limitations)
  - [6. Acknowledgments](#6-acknowledgments)
## 1. Description

A reinforcement learning-powered Rubik’s Cube solver with a custom simulation environment built in Godot 4 and real-time TCP communication. The project integrates RL techniques with heuristic search, providing a scalable framework for solving cubes of various sizes.


## 2. Features
🧠 Advanced Reinforcement Learning Models: Train RL agents to solve Rubik’s Cubes (2x2, 3x3, 4x4, etc.).

🔍 Integrated A Search Algorithm:* Combines RL with A* to refine solutions and speed up convergence.

🛠️ Custom Simulation Environment: Built in Godot Engine to visualize and test the solving process.

🔗 TCP-Based Client-Server Communication: Enables real-time data exchange between the RL model and the simulation.

🚀 Hybrid Solver: Uses RL as a heuristic for A* to balance learning and search.

📊 Scalability: Adapts to various cube sizes and complexities.


---

## 3. Installation and Setup

### 3.1 Development Setup
1. **Clone the Repository:**
```bash
git clone https://github.com/sieradzki/RLCubeSolver-Godot.git
cd RLCubeSolver-Godot
```

2. **Install Dependencies:**
```bash
pip install -r requirements.txt
```

### 3.2 Running the Solver
1. **Launch the Godot project and start the server to connect with the RL model.**

2. **Start the Solver:**
```bash
python astar.py
```
---

## 4. Methodology
- Data Generation: Random cube states and their solutions were generated to train the RL model.

- State Encoding: The cube state is represented as a flattened one-hot encoded vector for neural network input.

- Training Process: The RL agent is trained to minimize the number of moves to solve the cube, while the A* search refines the final solution.

- This approach balances exploration (via RL) and exploitation (via A*) to find efficient solutions.

## 5. Results & Limitations
- ✅ High Success Rate: The solver reliably solves simpler states with shorter solution paths.

- ⏳ Performance Drops on Complex States: Solve rates and efficiency decline as the number of required moves increases, highlighting the limitations of the heuristic accuracy.

- 🟢 Scalability: The model handles various cube sizes, though larger cubes exponentially increase the state space, making A* searches more resource-intensive.

See the results in [agent/astar.ipynb](agent/astar.ipynb).

## 6. Acknowledgments

Inspired by state-of-the-art research in reinforcement learning and heuristic search techniques, including:

**Agostinelli, Forest, McAleer, Stephen, Shmakov, Alexander, & Baldi, Pierre (2019). Solving the Rubik’s Cube with Deep Reinforcement Learning and Search. Nature Machine Intelligence.**

```bibtex
@article{article,
  author = {Agostinelli, Forest and McAleer, Stephen and Shmakov, Alexander and Baldi, Pierre},
  year = {2019},
  month = {08},
  title = {Solving the Rubik’s cube with deep reinforcement learning and search},
  volume = {1},
  journal = {Nature Machine Intelligence},
  doi = {10.1038/s42256-019-0070-z}
}
```
