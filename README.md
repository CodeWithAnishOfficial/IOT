# IOT
🚀 3️⃣ ENV-based docker compose commands (THIS is what you want)
🔹 DEV – Infra
docker compose \
--env-file .env.dev \
-f infra/docker/docker-compose.yml \
--profile infra up --build -d

🔹 DEV – Backend
docker compose \
--env-file .env.dev \
-f infra/docker/docker-compose.yml \
--profile backend up --build -d

🔹 DEV – Frontend
docker compose \
--env-file .env.dev \
-f infra/docker/docker-compose.yml \
--profile frontend up --build -d

🔹 DEV – Everything
docker compose \
--env-file .env.dev \
-f infra/docker/docker-compose.yml \
--profile all up --build -d

🔥 PROD commands
🔹 PROD – Infra
docker compose \
--env-file .env.prod \
-f infra/docker/docker-compose.yml \
--profile infra up --build -d

🔹 PROD – Backend
docker compose \
--env-file .env.prod \
-f infra/docker/docker-compose.yml \
--profile backend up --build -d

🔹 PROD – Frontend
docker compose \
--env-file .env.prod \
-f infra/docker/docker-compose.yml \
--profile frontend up --build -d