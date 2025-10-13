# Use OpenJDK 21 as the base image
FROM openjdk:21-jdk-slim

# Set the working directory in the container
WORKDIR /app

# Copy the Gradle wrapper and build files
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .

# Make the gradlew script executable
RUN chmod +x gradlew

# Copy the source code
COPY src src

# Build the application
RUN ./gradlew build -x test

# Copy the built JAR file to the working directory (exclude the plain JAR)
RUN find build/libs -name "*.jar" -not -name "*-plain.jar" -exec cp {} app.jar \;

# Expose the port that the application runs on
EXPOSE 8081

# Set the entry point to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]