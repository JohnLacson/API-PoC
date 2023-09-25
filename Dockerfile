# Use an official Nginx runtime as the base image
FROM nginx:alpine

# Copy your HTML file into the default Nginx document root directory
COPY Quote.html /usr/share/nginx/html/Quote.html

# Expose port 80 for Nginx
EXPOSE 80

# Start Nginx when the container starts
CMD ["nginx", "-g", "daemon off;"]
