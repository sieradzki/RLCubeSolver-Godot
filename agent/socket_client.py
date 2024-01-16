import socket
import threading

""" This is mostly for testing purposes. I'll rewrite it later when the environment-agent communication is more fleshed out. """

# Shared flag - set to False when the server closes the connection
should_continue = True


def handle_server_communication(sock):
  """ Handles communication with the server. Runs in a separate thread."""
  global should_continue

  while should_continue:  # Loop until the server closes the connection
    response = sock.recv(4096)
    if not response:
      print("No response from server, exiting.")
      should_continue = False
      break

    response_str = response.decode()
    if response_str == "close_connection":
      print("Server closed the connection.")
      should_continue = False
      break

    print(f"Response from server: {response_str}")


def main():
  global should_continue

  server_address = '127.0.0.1'
  server_port = 4242

  with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:  # Create a TCP socket
    sock.connect((server_address, server_port))
    print("Connected to server")

    # Start the thread for handling server communication
    thread = threading.Thread(target=handle_server_communication, args=(sock,))
    thread.start()

    while should_continue:
      # This will still block the main thread even when the server closes the connection but we won't be using it later so w/e
      message = input("Enter a command: ")
      if message.lower() == 'exit' or not should_continue:
        break

      # Send the message to the server
      sock.sendall(message.encode())

    # Close the socket if the server hasn't already
    sock.shutdown(socket.SHUT_RDWR) 
    sock.close()

    # Wait for the network thread to finish
    thread.join()


if __name__ == "__main__":
  main()
