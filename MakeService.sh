#! /bin/bash

if [[ $1 == "--help" ]]
then
  echo "MakeService.sh - Version: 1.2"
  echo ""
  echo "To create a service run the script without specifying anything. You will be asked to specify things..."
  echo "To remove a service run the script with --cleanup option and specify the service name as argument."
  echo ""
  exit
fi

if [[ "$USER" != "root" ]]
then
  echo "Try again with sudo in front..."
  exit
fi

if [[ $(ps -p 1 -o comm=) != "systemd" ]]
then
  echo "Error: This script can not create a service... Your system is not compatible!"
  exit
fi

if [[ $1 == "--cleanup" ]]
then
  shift
  ServiceName="$@"
  systemctl stop $ServiceName.service
  systemctl disable $ServiceName.service
  rm "/usr/bin/$ServiceName"
  rm "/etc/systemd/system/$ServiceName.service"
  systemctl daemon-reload
  exit
fi

Error=false
while [[ -z "$ServiceName" || -f "/usr/bin/$ServiceName" || -f "/etc/systemd/system/$ServiceName.service" ]]
do
  if [[ $Error == true ]]
  then
    echo ""
    echo "Error: A service like this already exists, or no name specified..."
  fi
  Error=true
  read -p "Please specify a name for this service.(Make it a single short word you can remember, no special characters!): " "ServiceName"
done
echo ""
read -p "Command you want to run right after the machine starts.(Use full paths, no exiting spaces or special characters, and don't quote the whole command! Just as you would give a command in command line. Keep in mind that this will be called by root not you so \$USER is root same goes for home dir that is why you need full path.): " "AtStart"
if [[ -z "$AtStart" ]]
then
  AtStart=":"
fi
echo ""
read -p "Command you want to run before the machine stops.(Same rules here!): " "AtStop"
if [[ -z "$AtStop" ]]
then
  AtStop=":"
fi
echo ""
if [[ $AtStart == ":" && $AtStop == ":" ]]
then
  echo "Error: There is no point in creating a service that does nothing... :P"
  exit
fi
Error=false
while [[ $ServiceType != "oneshot" && $ServiceType != "simple" && $ServiceType != "forking" ]]
do
  if [[ $Error == true ]]
  then
    echo ""
    echo "Error: Invalid service type! Try again..."
  fi
  Error=true
  echo ""
  read -p "Please specify the type of the process(Valid values are: \"oneshot\" for quick script or command that runs at startup/before shutdown and only does a short thing, and does not launch other processes; \"simple\" for longer script that may run for a while and doesn't require other daemons to wait for it; \"forking\" for process that may launch other processes...): " "ServiceType"
done
Error=false
while [[ $Persist != "yes" && $Persist != "no" ]]
do
  if [[ $Error == true ]]
  then
    echo ""
    echo "Error: Invalid answer! Try again..."
  fi
  Error=true
  echo ""
  read -p "Should the service be considered running when it exits?(yes/no): " "Persist"
done


touch "/tmp/$ServiceName.service"
echo "[Unit]" >> "/tmp/$ServiceName.service"
echo "Description=$ServiceName (Custom service of $SUDO_USER user.)" >> "/tmp/$ServiceName.service"
echo "" >> "/tmp/$ServiceName.service"
echo "[Service]" >> "/tmp/$ServiceName.service"
echo "Type=$ServiceType" >> "/tmp/$ServiceName.service"
echo "ExecStart=/usr/bin/$ServiceName start" >> "/tmp/$ServiceName.service"
echo "ExecStop=/usr/bin/$ServiceName stop" >> "/tmp/$ServiceName.service"
echo "RemainAfterExit=$Persist " >> "/tmp/$ServiceName.service"
echo "" >> "/tmp/$ServiceName.service"
echo "[Install]" >> "/tmp/$ServiceName.service"
echo "WantedBy=multi-user.target" >> "/tmp/$ServiceName.service"
cp -af "/tmp/$ServiceName.service" "/etc/systemd/system/$ServiceName.service"
rm "/tmp/$ServiceName.service"

touch "/tmp/$ServiceName"
echo "#! /bin/bash" >> "/tmp/$ServiceName"
echo "" >> "/tmp/$ServiceName"
echo "case \"\$1\"" >> "/tmp/$ServiceName"
echo "in" >> "/tmp/$ServiceName"
echo "  \"start\" ) $AtStart" >> "/tmp/$ServiceName"
echo "            ;;" >> "/tmp/$ServiceName"
echo "   \"stop\" ) $AtStop" >> "/tmp/$ServiceName"
echo "            ;;" >> "/tmp/$ServiceName"
echo "         *) echo \"Error: Unknown option!\"" >> "/tmp/$ServiceName"
echo "            exit 1" >> "/tmp/$ServiceName"
echo "            ;;" >> "/tmp/$ServiceName"
echo "esac" >> "/tmp/$ServiceName"
echo "exit 0" >> "/tmp/$ServiceName"
chmod +x "/tmp/$ServiceName"
cp -af "/tmp/$ServiceName" "/usr/bin/$ServiceName"
rm "/tmp/$ServiceName"

systemctl daemon-reload
systemctl enable $ServiceName.service
read -p "Would you like to run the service now? (y/n): " Yy
if [[ $Yy == [Yy]* ]]
then
  systemctl start $ServiceName.service
fi
