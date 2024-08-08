# Start from the official Rust image
FROM rust:latest

# Install dependencies including protobuf-compiler
RUN apt-get update && apt-get install -y protobuf-compiler git cmake

# Set the working directory
WORKDIR /app

# Clone the repository
RUN git clone https://github.com/elichai/kaspa-miner.git

# Change to the repository directory
WORKDIR /app/kaspa-miner

# Build the project using Cargo
RUN cargo build --release

# Expose any necessary ports (adjust according to your miner's requirements)
EXPOSE 3030

# Define the entry point
ENTRYPOINT ["./target/release/kaspa-miner"]

