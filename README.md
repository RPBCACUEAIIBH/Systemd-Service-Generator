This script is an easy way to add a command to startup by turning it into a systemd service.
(Only works on systems using systemd!)

- Run the script without any arguments but with sudo in front.
- You will be asked to specify service name, command you want to run at startup, and command you want to run before shutdown. Bot commands are optional, you can skip them by leaving the prompt empty and hitting enter...
- If the service it created doesn't work, and/or you want to remove it, you can run the script with sudo in front, --cleanup option, and service name as argument to remove it.

Successfully tested on Ubuntu 17.10, and raspbian, should work on any linux using systemd.
