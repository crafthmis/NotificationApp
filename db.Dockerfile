# Use the official Postgres image as the base
FROM postgres:13

# Install jq for parsing JSON files
RUN apt-get update && apt-get install -y jq

# Copy the entrypoint script
#COPY entrypoint.sh /app/entrypoint.sh
#RUN chmod +x /app/entrypoint.sh

# Copy the env.json config file
COPY config/env.json /app/config/env.json

# Set the entrypoint to the custom script
#ENTRYPOINT ["/app/entrypoint.sh"]

# Keep the default Postgres CMD
#CMD ["postgres"]
