# --- Build : Maven officiel (évite les soucis de fins de ligne CRLF de mvnw sous Windows)
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /build

# Les dépendances sont mises en cache tant que pom.xml ne change pas
COPY pom.xml .
RUN mvn -B -q dependency:go-offline

COPY src ./src
RUN mvn -B -q package -DskipTests

# --- Exécution : le .war Spring Boot est exécutable (java -jar)
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /build/target/*.war app.war

# FileStorageService écrit dans ./uploads (= /app/uploads)
RUN mkdir -p /app/uploads
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.war"]
