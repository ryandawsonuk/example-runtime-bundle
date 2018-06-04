FROM openjdk:8-jdk-alpine
ENV PORT 8081
EXPOSE 8081
COPY target/*.jar /opt/app.jar
WORKDIR /opt
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar