# ============================================================
# Stage 1 — Build (Maven + Java 17)
# ============================================================
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copier uniquement le pom.xml en premier pour profiter du cache Maven
COPY pom.xml .

# Télécharger les dépendances (cette couche sera mise en cache si pom.xml ne change pas)
RUN mvn dependency:go-offline -B --no-transfer-progress

# Copier le reste du code source
COPY src ./src

# Build sans les tests (les tests sont dans le workflow CI)
RUN mvn package -DskipTests --no-transfer-progress

# ============================================================
# Stage 2 — Run (JRE alpine léger)
# ============================================================
FROM eclipse-temurin:17-jre-alpine AS runtime

# Créer un utilisateur non-root pour la sécurité
RUN addgroup -S village && adduser -S village -G village

WORKDIR /app

# Copier le JAR depuis le stage 1
COPY --from=builder /app/target/*.jar app.jar

# Changer le propriétaire des fichiers
RUN chown -R village:village /app

# Passer à l'utilisateur non-root
USER village

# Exposer le port de l'application Spring Boot
EXPOSE 8080

# Vérification de santé (Spring Boot Actuator)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# Options JVM optimisées pour les conteneurs
ENV JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Djava.security.egd=file:/dev/./urandom"

# Démarrer l'application Spring Boot
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
