# EasyChess

## Production Environment Variables

### 1. `REDIS_HOST`

- **Description**: The host address of the production Redis instance.
- **Example**: `redis://39.31.120.11`

### 2. `REDIS_PORT`

- **Description** The port of the production Redis instance.
- **Example**: `6379`

### 3. `REDIS_PASSWORD`

- **Description**: The password of the production Redis instance.
- **Example**: `password`

### 4. `PORT`

- **Description**: The port on which the server will listen.
- **Example**: `3000`

### 5. `SECRET_KEY_BASE`

- **Description**: The secret key base for the production environment. (generated using `mix phx.gen.secret`)
- **Example**: `a1b2c3d4e5f6g7h8i9j0`