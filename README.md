
# Install Odoo

This script to install Odoo CE versions on Ubuntu

## Installation	
- `./odoo.sh [arg <parm>]`
- `-v <version>` Choose odoo version
- `-d <directory>` Change the default directory
- `-p` Step by Step `Partial` installation 

## Partial Installation Steps
- `Which Odoo version do u want to install?` just type [8, 9, 10, 11, 12, 13]
- `Clone Odoo ?` (y) will clone selected version of Odoo at directory `/opt/odoo/odoo13`
- `Install Odoo Requirements ?` (y) will create `virtualenv` & install required python library
- `Install Node Dependencies ?`(y) Will install Node Dependencies
- `Install postgresql - pgadmin3 ?` (y) will create postgres user used for Odoo
- `Install Wkhtmltopdf ?` (y) to download & install `wkhtmltox` needed to print PDF reports 
- Extra addons directory `/opt/odoo/odoo13/addons_custom`
- Config file `/etc/odoo/odoo13.cfg`
- Log file `/var/odoo/odoo13.log`
- Odoo command file `/usr/bin/odoo13`

## Odoo Usage
- `odoo13` command will run odoo server with configuration at `/etc/odoo/odoo13.cfg`
- to run it manually follow the next steps: 
	- `source /opt/odoo/odoo13/.venv/bin/activate`
	- `/opt/odoo/odoo13/odoo-bin -c /etc/odoo/odoo13.cfg`
