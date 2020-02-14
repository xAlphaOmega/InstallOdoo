#!/bin/bash
while getopts :pd:v: arg; do
  case ${arg} in
    p ) PARTIAL_INSTALL=true ;;
    v ) VERSION=$OPTARG ;;
    d ) DIR=$OPTARG ;;
    \?) echo "Unknown option: -$OPTARG" >&2; exit 1;;
    : ) echo "Missing option argument for -$OPTARG" >&2; exit 1;;
  esac
done
if [[ -z "${VERSION}" ]]; then
    read -p "Which odoo version do u want to install? " VERSION
fi
PARTIAL_INSTALL=${PARTIAL_INSTALL:-false} # means full install
O_VERSION=${VERSION%.*}
O_USER="odoo"
O_GROUP=${O_USER}
O_DB_USER="$O_USER${O_VERSION}"
O_PASSWORD="admin"
O_HOST="localhost"
O_PORT_DB="5432"
O_PORT="$(printf "80%02d" ${O_VERSION})"
O_HOME=${DIR:-/opt/odoo}
O_CONF="/etc/odoo"
O_LOG="/var/odoo"
O_DIR="${O_HOME}/odoo${O_VERSION}"
YN='y'

echo -e "\e[96m\n- Updating Server\e[0m"
sudo apt-get update && sudo apt-get upgrade -y
sudo useradd ${O_USER} -p ${O_PASSWORD} -m -d ${O_HOME} -r -s /bin/bash
sudo usermod -aG ${O_GROUP} $(whoami)

while true; do
    if ${PARTIAL_INSTALL}; then
	    read -p "Clone odoo ? (Y/n) " YN
    fi
	case ${YN} in
	[Yy]* )
		echo -e "\e[96m\n- Cloning odoo\e[0m"
		sudo apt-get install git
		sudo su - ${O_USER} -c "git clone --depth 1 --single-branch --branch ${O_VERSION}.0 https://www.github.com/odoo/odoo ${O_DIR}/"
		echo -e "\e[92m\n- Odoo${O_VERSION} successfully cloned at ${O_DIR}/\e[0m"
		break
	;;
	[Nn]* )
		echo -e "\e[91m\n- odoo isn't cloned due to the choice of the user\e[0m"
		break
	;;
	* ) echo -e "Please answer (Y/n)";;
	esac
done

while true; do
    if ${PARTIAL_INSTALL}; then
	    read -p "Install odoo Requirements ? (Y/n)" YN
    fi
	case ${YN} in
	[Yy]* )
		if [[ ${O_VERSION} -lt 11 ]]; then V=''; elif [[ ${O_VERSION} -gt 10 ]]; then V='3'; fi
		echo -e "\e[96m\n- Installing odoo Requirements for python${V}\e[0m"
		sudo apt-get install python${V}-pip virtualenv libsasl2-dev libldap2-dev \
				     		 libxml2-dev python${V}-dev build-essential libssl-dev \
						     libffi-dev libxslt1-dev zlib1g-dev python${V}-ldap libpq-dev -y
		# Check that virtualenv run correctly or not
        sudo rm -r ${O_DIR}/.venv
# Login with current user to gain group permissions
sudo su ${O_USER} << EOF
		(virtualenv -p python${V} ${O_DIR}/.venv)
		if [ $? -ne 0 ]; then
			echo -e "\e[91mVirtual environment doesn't created\e[0m"
			exit 1
		else
			source ${O_DIR}/.venv/bin/activate
			pip install phonenumbers coverage pylint flake8 ipython ipdb
			pip install --upgrade --pre pylint-odoo
			(pip install -r ${O_DIR}/requirements.txt)
			if [ $? -ne 0 ]; then
				echo -e "\e[91m\nFailed to install some required libraries \e[0m" ; exit 1
			fi
            if [ ${O_VERSION} -gt 12 ]; then
				pip install firebase-admin
			fi
			deactivate
		    echo -e "\e[92m\n- Odoo python${V} requirements successfully installed at ${O_DIR}/.venv\e[0m"
		fi
EOF
		break
	;;
	[Nn]* )
		echo -e "\e[91m\n- Requirements isn't installed due to the choice of the user\e[0m"
		break
	;;
	* ) echo -e "Please answer (Y/n)";;
	esac
done
# Create soft link to odoo addons to python site packages
PYTHON=$(ls ${O_DIR}/.venv/lib/)
sudo su ${O_USER} << EOF
	mkdir ${O_DIR}/.venv/lib/${PYTHON}/site-packages/odoo/addons -p
	ln -s ${O_DIR}/addons/* ${O_DIR}/.venv/lib/${PYTHON}/site-packages/odoo/addons
	ln -s ${O_DIR}/odoo/addons/* ${O_DIR}/.venv/lib/${PYTHON}/site-packages/odoo/addons
	ln -s ${O_DIR}/odoo/* ${O_DIR}/.venv/lib/${PYTHON}/site-packages/odoo/
EOF

while true; do
    if ${PARTIAL_INSTALL}; then
        read -p "Install Node Dependencies ? (Y/n)" YN
    fi
	case ${YN} in
	[Yy]* )
		echo -e "\e[96m\n- Installing Node - Dependencies\e[0m"
		sudo apt-get install nodejs npm node-less -y
		sudo ln -s /usr/bin/nodejs /usr/bin/node
		sudo npm install -g less less-plugin-clean-css
		sudo npm install -g rtlcss
		echo -e "\e[92m\n- Node dependencies successfully installed\e[0m"
		break
	;;
	[Nn]* )
		echo -e "\e[91m\n- Node Dependencies isn't Installed due to the choice of the user\e[0m"
		break
	;;
	* ) echo -e "Please answer (Y/n)";;
	esac
done

while true; do
    if ${PARTIAL_INSTALL}; then
        read -p "Install postgresql & pgadmin3 ? (Y/n)" YN
    fi
	case ${YN} in
	[Yy]* )
		echo -e "\e[96m\n- Installing postgresql & pgadmin3\e[0m"
		sudo apt-get install postgresql pgadmin3 -y
		sudo -u postgres createuser ${O_DB_USER} -d -i -l -r
		sudo -u postgres psql -c "ALTER USER \"${O_DB_USER}\" WITH PASSWORD '${O_PASSWORD}';"
		sudo -u postgres psql -c "ALTER USER \"postgres\" WITH PASSWORD 'admin';"
		echo -e "\e[92m\n- postgresql & pgadmin3 successfully installed\e[0m"
		break
	;;
	[Nn]* )
		echo -e "\e[91m\n- postgresql & pgadmin3 isn't Installed due to the choice of the user\e[0m"
		break
	;;
	* ) echo -e "Please answer (Y/n)";;
	esac
done

while true; do
    if ${PARTIAL_INSTALL}; then
	    read -p "Install Wkhtmltopdf ? (Y/n)" YN
    fi
	case ${YN} in
	[Yy]* )
		echo -e "\e[96m\n- Installing wkhtmltox\e[0m"
		sudo apt install wkhtmltopdf
		echo -e "\e[92m\n- wkhtmltox successfully installed\e[0m"
		break
	;;
	[Nn]* )
		echo -e "\e[91m\n- Wkhtmltopdf isn't installed due to the choice of the user\e[0m"
		break
	;;
	* ) echo -e "Please answer (Y/n)";;
	esac
done

echo -e "\e[96m\n- Cleaning up your system & Creating Config file\e[0m"

sudo su - ${O_USER} -c "mkdir -p ${O_DIR}/addons_custom"
sudo mkdir -p ${O_CONF} ${O_LOG}
sudo touch ${O_CONF}/odoo${O_VERSION}.cfg ${O_LOG}/odoo${O_VERSION}.log

sudo cat <<EOF > ${O_CONF}/odoo${O_VERSION}.cfg
[options]
; This is the password that allows database operations:
addons_path = ${O_DIR}/addons,${O_DIR}/odoo/addons,${O_DIR}/addons_custom
admin_passwd = admin
db_user = ${O_DB_USER}
db_password = ${O_PASSWORD}
db_host = ${O_HOST}
db_port = ${O_PORT_DB}
xmlrpc_port = ${O_PORT}
EOF

sudo chown ${O_USER}:${O_GROUP} ${O_CONF} ${O_LOG} -R
sudo chmod 775 ${O_CONF} ${O_LOG} -R
sudo apt autoremove -y
ln -s ${O_CONF} ${O_HOME}/config

if [[ ${O_VERSION} -lt 10 ]]; then
sudo cat <<EOF > ${O_DIR}/odoo${O_VERSION}
source ${O_DIR}/.venv/bin/activate
if [[ \$@  =~ "scaffold" ]]; then
	${O_DIR}/openerp-server \$@
else
	${O_DIR}/openerp-server -c ${O_CONF}/odoo${O_VERSION}.cfg \$@
fi
EOF
else
sudo cat <<EOF > ${O_DIR}/odoo${O_VERSION}
source ${O_DIR}/.venv/bin/activate
if [[ \$@  =~ "scaffold" ]]; then
	${O_DIR}/odoo-bin \$@
else
	${O_DIR}/odoo-bin -c ${O_CONF}/odoo${O_VERSION}.cfg \$@
fi
EOF
fi
sudo chmod +x ${O_DIR}/odoo${O_VERSION}
sudo mv ${O_DIR}/odoo${O_VERSION} /usr/bin/
echo -e "\e[96m http://localhost:${O_PORT}\e[0m"
odoo${O_VERSION} -s

echo -e "\e[93m******************** Odoo${O_VERSION} installed successfuly ********************"
echo -e "- Odoo${O_VERSION} Directory: ${O_DIR}"
echo -e "- Extra addons directory: ${O_DIR}/addons_custom"
echo -e "- Config Directory: ${O_CONF}/odoo${O_VERSION}.cfg"
echo -e "- log Directory: ${O_LOG}/odoo${O_VERSION}.log\n"
echo -e "To run odoo${O_VERSION} server run the following commands:"
echo -e "     \e[39m- odoo${O_VERSION} [arg <parm>] \e[93m"
echo -e "Now open your browser and type:\e[39m http://${O_HOST}:${O_PORT}\e[93m"
