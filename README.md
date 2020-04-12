# docker-rclone-encfs-cron

Docker image for managing rclone upload/cleanup to google drive via cron
- Ubuntu 18.04
- rclone
- encfs
- cron

## Usage

```yaml
version: '3'

services:
  rclone:
    container_name: rclone
    image: ghtsto/rclone-encfs-cron
    restart: always
    volumes:
      - ${DATA_DIR}/rclone/config:/config
      - ${DATA_DIR}/rclone/cron/daily:/etc/cron.daily
      - ${DATA_DIR}/plexdrive/data:/data
      - ${DATA_DIR}/plexdrive/local-encrypted:/local
      - ${DATA_DIR}/plexdrive/encfs.xml:/encfs.xml
      - ${DATA_DIR}/plexdrive/encfspass:/encfspass
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
```

First, up and run your container as above. Next, create the ```rclone.conf``` file by using the built-in script

```bash
docker-compose exec <service_name> rclone_setup
```
