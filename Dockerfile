FROM openjdk:8-jdk-alpine
RUN apk --update add fontconfig ttf-dejavu
ENV PORT 8081
EXPOSE 8081
COPY target/*.jar /opt/app.jar
WORKDIR /opt
ENTRYPOINT exec java $JAVA_OPTS -jar app.jar