# ============================================================
# Stage 1 — Build (Node.js + Angular CLI)
# ============================================================
FROM node:18-alpine AS builder

WORKDIR /app

# Copier les fichiers de dépendances en premier (cache layer)
COPY package.json package-lock.json ./

# Installer les dépendances (ci = clean install, plus rapide que install)
RUN npm ci --prefer-offline

# Copier le reste du code source
COPY . .

# Build en mode production
RUN npm run build -- --configuration=production

# ============================================================
# Stage 2 — Serve (Nginx)
# ============================================================
FROM nginx:1.25-alpine AS runtime

# Copier la configuration Nginx personnalisée
COPY nginx.conf /etc/nginx/nginx.conf

# Copier les fichiers buildés depuis le stage 1
# Le répertoire de sortie Angular est dist/<project-name>/browser
COPY --from=builder /app/dist/ /usr/share/nginx/html/

# Exposer le port 80
EXPOSE 80

# Vérification de santé
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Démarrer Nginx en premier plan
CMD ["nginx", "-g", "daemon off;"]
