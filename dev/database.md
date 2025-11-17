# Development Database Setup Guide

This guide covers connecting to your local MySQL development database running in the `devsql` Podman container.

## Container Overview

After running `dev.sh`, you will have a MySQL container with the following configuration:

- **Container Name**: `devsql`
- **Port**: `3306`
- **Default User**: `valet` (no password)
- **Root User**: `root` (no password)
- **Default Database**: `global_default`
- **Volume**: `devsql_data` (persistent storage)

## Laravel Application Configuration

### 1. Laravel `.env` Database Settings

For each Laravel project, update your `.env` file with these connection settings:

```dotenv
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=your_project_repo_name  # UNIQUE PER APP - use your project's name
DB_USERNAME=valet
DB_PASSWORD=
```

### 2. Creating a New Database for Your Project

Before running migrations, you need to create a database for your project:

**Option A: Using MySQL CLI**
```bash
mysql -u valet -h 127.0.0.1 -e "CREATE DATABASE your_project_name;"
```

**Option B: Using Beekeeper Studio**
1. Connect to the database (see connection settings below)
2. Click "New Query"
3. Run: `CREATE DATABASE your_project_name;`
4. Refresh the database list

### 3. Running Migrations

Once the database is created and your `.env` is configured:

```bash
cd ~/Code/your_project
php artisan migrate
```

## Beekeeper Studio Connection

Use these settings to connect to your development database with Beekeeper Studio:

| Setting | Value |
| :--- | :--- |
| **Connection Type** | MySQL |
| **Host** | `127.0.0.1` |
| **Port** | `3306` |
| **User** | `valet` |
| **Password** | *(Leave blank)* |
| **Default Database** | `global_default` (optional) |

### Connecting to a Specific Project Database

After creating your project's database, you can set it as the default database in the connection settings, or simply select it from the database dropdown after connecting.

## Container Management

### Start the Container
```bash
systemctl --user start container-devsql.service
```

### Stop the Container
```bash
systemctl --user stop container-devsql.service
```

### Restart the Container
```bash
systemctl --user restart container-devsql.service
```

### Check Container Status
```bash
systemctl --user status container-devsql.service
```

### View Container Logs
```bash
podman logs devsql
```

### Access MySQL Shell Directly
```bash
podman exec -it devsql mysql -u valet
```

## Troubleshooting

### Connection Refused

If you get a "connection refused" error, check if the container is running:

```bash
podman ps | grep devsql
```

If it's not running, start it:

```bash
systemctl --user start container-devsql.service
```

### Database Doesn't Exist

If you get a "database doesn't exist" error in Laravel, make sure you've created the database:

```bash
mysql -u valet -h 127.0.0.1 -e "SHOW DATABASES;"
```

If your database isn't listed, create it using one of the methods above.

### Reset Everything

If you need to completely reset your database container and start fresh:

```bash
# Stop and remove the container
systemctl --user stop container-devsql.service
podman rm -f devsql

# Remove the data volume (WARNING: This deletes all your databases!)
podman volume rm devsql_data

# Restart the container (will recreate everything)
cd ~/Containers/devsql
podman-compose up -d

# Regenerate and enable the systemd service
podman generate systemd --name devsql --files --new
mv container-devsql.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable container-devsql.service
```

## Workflow for New Laravel Projects

1. Clone or create your Laravel project
2. Copy `.env.example` to `.env`
3. Update the database settings in `.env` (see Laravel configuration above)
4. Create the database: `mysql -u valet -h 127.0.0.1 -e "CREATE DATABASE your_project_name;"`
5. Run migrations: `php artisan migrate`
6. Start developing! 🚀
