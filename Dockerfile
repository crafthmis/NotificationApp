# # Start from the official Go image
# FROM golang:1.23

# # Set the working directory inside the container
# WORKDIR /app

# # Copy go mod and sum files
# COPY go.mod go.sum ./

# # Download all dependencies
# RUN go mod download

# RUN apt-get update && apt-get install -y jq
# # Copy the entrypoint script
# COPY entrypoint.sh /app/entrypoint.sh
# RUN chmod +x /app/entrypoint.sh

# #Shell script

# # Copy the source code into the container
# COPY . .
# COPY config/env.json /app/config/env.json
# COPY backup.sql /docker-entrypoint-initdb.d/backup.sql



# # Build the application
# RUN go build -o main .

# # Expose port 8080 to the outside world
# EXPOSE 3000

# # Command to run the executable
# CMD ["./main"]
# Start from the official Go image
FROM golang:1.23

# Install necessary tools
RUN apt-get update && apt-get install -y netcat-openbsd


# Set the working directory
WORKDIR /app

# Copy go mod and sum files
COPY go.mod go.sum ./

# Download all dependencies
RUN go mod download

# Copy the source code
COPY . .

# Copy the entrypoint script
#COPY entrypoint.sh /app/entrypoint.sh

# Make the entrypoint script executable
#RUN chmod +x /app/entrypoint.sh

# Build the application
RUN go build -o main .

# Expose the port the app runs on
EXPOSE 3000

# Set the entrypoint script as the entrypoint
# ENTRYPOINT ["/app/entrypoint.sh"]
# CMD ["./main"]