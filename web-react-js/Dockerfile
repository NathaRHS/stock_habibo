# --- Build : Vite fige VITE_SPRING_URL dans le JS au moment du build
FROM node:22-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
ARG VITE_SPRING_URL=http://localhost:8080
ENV VITE_SPRING_URL=$VITE_SPRING_URL
RUN npm run build

# --- Exécution : nginx sert le dossier dist
FROM nginx:1.27-alpine
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
