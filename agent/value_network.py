import torch
import torch.nn as nn
import torch.optim as optim
import torch.nn.functional as F
from torch.utils.data import DataLoader, Dataset
import json
import numpy as np
from torch.utils.tensorboard import SummaryWriter
from tqdm import tqdm
import random

# Setup TensorBoard and the device
writer = SummaryWriter()
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
print(f"Using device: {device}")


def load_and_split_dataset(file_path, test_ratio=0.2):
  """ Load the dataset from a JSON file and split it into training and test sets """
  with open(file_path, 'r') as f:
    data = json.load(f)

  np.random.shuffle(data)

  split_index = int(len(data) * (1 - test_ratio))
  train_data = data[:split_index]
  test_data = data[split_index:]

  return train_data, test_data


class CubeDataset(Dataset):
  def __init__(self, data):
    self.data = data

  def __len__(self):
    return len(self.data)

  def __getitem__(self, idx):
    state = self.data[idx]['state']
    cost_to_go = self.data[idx]['cost_to_go']
    # Flatten and one-hot encode the state
    state_oh = self.one_hot_encode(state)
    return state_oh, torch.tensor([cost_to_go], dtype=torch.float)

  def one_hot_encode(self, state):
    # Initialize a list to hold the one-hot encoded state
    state_oh = []

    # Iterate over each face's colors
    for face in state:
      for pair in face:
        for color in pair:
          # Create a one-hot encoded vector for this color
          color_oh = [0] * 6
          color_oh[color] = 1
          state_oh.extend(color_oh)

    return torch.tensor(state_oh, dtype=torch.float)

  def get_random_samples(self, num_samples=10):
    indices = random.sample(range(len(self.data)), num_samples)
    return [self[idx] for idx in indices]


class ResidualBlock(nn.Module):
  def __init__(self):
    super(ResidualBlock, self).__init__()
    self.fc1 = nn.Linear(1000, 1000)
    self.bn1 = nn.BatchNorm1d(1000)
    self.fc2 = nn.Linear(1000, 1000)
    self.bn2 = nn.BatchNorm1d(1000)

  def forward(self, x):
    identity = x
    out = F.relu(self.bn1(self.fc1(x)))
    out = self.bn2(self.fc2(out))
    out += identity  # Skip connection
    return F.relu(out)


class ValueNetwork(nn.Module):
  def __init__(self, input_size):
    super(ValueNetwork, self).__init__()
    # First fully connected layer, 144 for 2x2x2, 324 for 3x3x3, 576 for 4x4x4
    self.fc1 = nn.Linear(input_size, 5000)
    self.bn1 = nn.BatchNorm1d(5000)  # Batch normalization
    self.fc2 = nn.Linear(5000, 1000)  # Second fully connected layer
    self.bn2 = nn.BatchNorm1d(1000)  # Batch normalization
    # Sequence of four residual blocks
    self.res_blocks = nn.Sequential(
        ResidualBlock(),
        ResidualBlock(),
        ResidualBlock(),
        ResidualBlock()
    )
    self.output = nn.Linear(1000, 1)  # Output layer

  def forward(self, x):
    x = F.relu(self.bn1(self.fc1(x)))
    x = F.relu(self.bn2(self.fc2(x)))
    x = self.res_blocks(x)
    x = self.output(x)
    return x


def train_model(model, train_loader, test_loader, optimizer, criterion, epochs=10, cube_size='2x2x2'):
  """ Train the model using the training set and evaluate it using the test set"""
  model.to(device)  # Move model to the appropriate device
  best_loss = float('inf')
  for epoch in tqdm(range(epochs)):
    model.train()
    total_loss = 0
    for batch_idx, (data, target) in enumerate(train_loader):
      data, target = data.to(device), target.to(device)  # Move data to device
      optimizer.zero_grad()
      output = model(data)
      loss = criterion(output, target)
      loss.backward()
      optimizer.step()
      total_loss += loss.item()
    writer.add_scalar('Training Loss', loss.item(),
                      epoch)
    average_loss = total_loss / len(train_loader)
    print(f'Epoch {epoch}, Average Training Loss: {average_loss:.4f}')
    if average_loss < best_loss:
      best_loss = average_loss
      torch.save(model.state_dict(),
                 f'networks/best_value_network_{cube_size}.pth')
      print(
        f'Saved new best model with average training loss: {best_loss:.4f}')
    test_loss = test_model(model, test_loader, criterion)
    writer.add_scalar('Test Loss', test_loss, epoch)


def compute_accuracy(output, target, threshold=0.5):
  """ Compute the accuracy of the model's predictions """
  predictions = output.round()
  correct = (predictions == target).float()
  accuracy = correct.sum() / len(correct)
  return accuracy.item()


def test_model(model, test_loader, criterion):
  """ Evaluate the model using the test set"""
  model.eval()
  total_loss = 0
  total_accuracy = 0
  with torch.no_grad():
    for data, target in test_loader:
      data, target = data.to(device), target.to(device)
      output = model(data)
      loss = criterion(output, target)
      total_loss += loss.item()
      accuracy = compute_accuracy(output, target)
      total_accuracy += accuracy

  average_loss = total_loss / len(test_loader)
  average_accuracy = total_accuracy / len(test_loader)
  print(
    f'Test Average Loss: {average_loss:.4f}, Average Accuracy: {average_accuracy:.4f}')
  return average_loss


if __name__ == "__main__":
  cube_size = '2x2x2'
  # cube_size = '3x3x3'
  # cube_size = '4x4x4'
  dataset_path = f'data/rubiks_cube_data_{cube_size}.json'
  # dataset_path = f'/kaggle/input/rubiks-cube-data/rubiks_cube_data_{cube_size}.json'
  train_data, test_data = load_and_split_dataset(dataset_path, test_ratio=0.01)

  train_dataset = CubeDataset(train_data)
  train_loader = DataLoader(train_dataset, batch_size=10_000, shuffle=True)

  test_dataset = CubeDataset(test_data)
  test_loader = DataLoader(test_dataset, batch_size=1000, shuffle=False)

  # If training from a checkpoint
  # network_path = f'networks/best_value_network_{cube_size}.pth'
  # network_path = f'/kaggle/input/rubiks-cube-data/best_value_network_{cube_size}.pth'

  # model = ValueNetwork(144).to(device) # For 2x2x2 cube
  # model = ValueNetwork(324).to(device) # For 3x3x3 cube
  # model = ValueNetwork(576).to(device)  # For 4x4x4 cube
  # model.load_state_dict(torch.load(network_path, map_location=device))

  # If training from scratch
  model = ValueNetwork(144).to(device)  # For 2x2x2 cube
  # model = ValueNetwork(324).to(device)  # For 3x3x3 cube
  # model = ValueNetwork(576).to(device)  # For 4x4x4 cube

  optimizer = optim.Adam(model.parameters(), lr=1e-3)
  criterion = nn.MSELoss()

  train_model(model, train_loader, test_loader,
              optimizer, criterion, epochs=2, cube_size=cube_size)

  torch.save(model.state_dict(), f'networks/value_network_{cube_size}.pth')
  writer.close()
