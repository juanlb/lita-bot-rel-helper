# Rel Helper Lita Bot

##
Build docker with:
```
docker build -t juanlb/lita-bot-relatient:latest .
```
## Install

Create directory:
```
/home/ubuntu/lita_bot
```
(or the right user)

Put inside the directory:

- all scripts in `ec2_scripts1`
- `docker-compose.yml` file

## Docker compose
Be sure `.env` file is configured

Run:
```
docker-compose up -d
```
## Looping script
Start a `screen` session, and run:

```
cd /home/ubuntu/lita_bot
./lita_listener_loop.sh
```
and `detach` (CTRL+A+D)
