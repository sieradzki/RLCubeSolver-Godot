import copy


def rotate_face_new(face, clockwise=True):
  """ Rotates a given face 90 degrees clockwise or counterclockwise. """
  N = len(face)
  new_face = [[0] * N for _ in range(N)]

  for i in range(N):
    for j in range(N):
      if clockwise:
        new_face[j][N - 1 - i] = face[i][j]
      else:
        new_face[N - 1 - j][i] = face[i][j]

  return new_face


def rotate_side_layers(cube, face_index, clockwise=True):
  """ Rotates the side layers adjacent to the rotated face. """
  N = len(cube[0])

  # Define the mapping of faces and their adjacent side layers
  side_layers = {
      0: {'U': (4, N - 1), 'L': (2, 0), 'D': (5, 0), 'R': (3, N - 1)},  # Front
      1: {'U': (4, 0), 'R': (3, 0), 'D': (5, N - 1), 'L': (2, N - 1)},  # Back
      # Left
      2: {'U': (4, 0, True), 'F': (0, 0), 'D': (5, 0, True), 'B': (1, N - 1)},
      # Right
      3: {'U': (4, N - 1, True), 'B': (1, 0), 'D': (5, N - 1, True), 'F': (0, N - 1)},
      4: {'F': (0, 0), 'L': (2, 0), 'B': (1, 0), 'R': (3, 0)},  # Up
      5: {'F': (0, N - 1), 'R': (3, N - 1), 'B': (1, N - 1), 'L': (2, N - 1)}  # Down
  }

  # Get the adjacent layers
  adj_layers = side_layers[face_index]
  edges = {dir: cube[adj[0]][adj[1] if len(adj) == 2 else (
    slice(None), adj[1])] for dir, adj in adj_layers.items()}

  # Rotate edges
  if clockwise:
    order = ['U', 'R', 'D', 'L']
  else:
    order = ['U', 'L', 'D', 'R']

  temp = edges[order[-1]]
  for i in range(len(order) - 1, 0, -1):
    edges[order[i]] = edges[order[i - 1]]
  edges[order[0]] = temp

  # Update the cube with the rotated edges
  for dir, adj in adj_layers.items():
    if len(adj) == 2:
      cube[adj[0]][adj[1]] = edges[dir]
    else:
      cube[adj[0]][slice(None), adj[1]] = edges[dir]

  return cube


def rotate_cube_new(cube, face, clockwise=True):
  """ Rotates a specific face and its adjacent side layers of the cube. """
  face_to_index = {'front': 0, 'back': 1,
                   'left': 2, 'right': 3, 'up': 4, 'down': 5}
  face_index = face_to_index[face]

  # Rotate the face itself
  cube[face_index] = rotate_face_new(cube[face_index], clockwise)

  # Rotate the side layers adjacent to the face
  cube = rotate_side_layers(cube, face_index, clockwise)

  return cube


unique_test_cube = [
    [[1 * 10 + j + i * 3 for j in range(3)] for i in range(3)],  # Front face
    [[2 * 10 + j + i * 3 for j in range(3)] for i in range(3)],  # Back face
    [[3 * 10 + j + i * 3 for j in range(3)] for i in range(3)],  # Left face
    [[4 * 10 + j + i * 3 for j in range(3)] for i in range(3)],  # Right face
    [[5 * 10 + j + i * 3 for j in range(3)] for i in range(3)],  # Up face
    [[6 * 10 + j + i * 3 for j in range(3)] for i in range(3)]   # Down face
]

# Rotate the front face clockwise and then counterclockwise
rotated_unique_cube = rotate_cube_new(
  copy.deepcopy(unique_test_cube), 'front', True)
rotated_unique_cube = rotate_cube_new(rotated_unique_cube, 'front', False)

print(rotated_unique_cube)
print(unique_test_cube)
print(rotated_unique_cube == unique_test_cube)
