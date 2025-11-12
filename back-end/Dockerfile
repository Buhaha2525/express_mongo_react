# Utilise une image Node.js officielle avec Alpine (plus légère)
FROM node:22.18.0-alpine

# Crée le répertoire de l'application
WORKDIR /app

# Copie les fichiers de configuration du package
COPY package*.json ./

COPY .env ./
# Installe les dépendances 
RUN npm install

# Copie le reste du code source
COPY . .

# Expose le port utilisé par l'application
EXPOSE 5001
EXPOSE 5002

# Définit la variable d'environnement pour NODE_ENV
ENV NODE_ENV=production

# Commande pour démarrer l'application
CMD ["npm", "start"]
