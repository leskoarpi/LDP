#!/bin/bash

# Hiba esetén a szkript leáll
set -e

# Változók definiálása
MYSQL_ROOT_PASSWORD="AdminSql1234"
WP_DB_NAME="wordpress"
WP_DB_USER="wpadmin"
WP_DB_PASSWORD="wp1234"
WP_SITE_PATH="/var/www/html"
WP_DOWNLOAD_URL="https://wordpress.org/latest.tar.gz"

# Csomaglista frissítése
echo "Csomaglista frissítése..."
sudo apt-get update

# Apache telepítése, ha még nincs telepítve
if ! dpkg -l | grep -q apache2; then
  echo "Apache telepítése..."
  sudo apt-get install -y apache2
else
  echo "Apache már telepítve van."
fi

# Apache engedélyezése és indítása
echo "Apache engedélyezése és indítása..."
sudo systemctl enable apache2
sudo systemctl start apache2

# MySQL telepítése, ha még nincs telepítve
if ! dpkg -l | grep -q mariadb-server; then
  echo "MySQL telepítése..."
  sudo apt-get install -y mariadb-server
else
  echo "MySQL már telepítve van."
fi

# MySQL biztonsági beállítások
echo "MySQL biztonsági beállítások..."
sudo mysql_secure_installation

# PHP és szükséges kiterjesztések telepítése, ha még nincsenek telepítve
PHP_CSP=("php" "libapache2-mod-php" "php-mysql" "php-curl" "php-gd" "php-mbstring" "php-xml" "php-xmlrpc" "php-soap" "php-intl" "php-zip")
for pkg in "${PHP_CSP[@]}"; do
  if ! dpkg -l | grep -q "$pkg"; then
    echo "$pkg telepítése..."
    sudo apt-get install -y "$pkg"
  else
    echo "$pkg már telepítve van."
  fi
done

# Apache újraindítása a PHP változások alkalmazásához
echo "Apache újraindítása..."
sudo systemctl restart apache2

# MySQL adatbázis és felhasználó létrehozása
echo "MySQL adatbázis és felhasználó létrehozása..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS $WP_DB_NAME;"
sudo mysql -e "CREATE USER IF NOT EXISTS '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# WordPress letöltése és kicsomagolása
echo "WordPress letöltése és kicsomagolása..."
cd "$WP_SITE_PATH"
sudo wget -c "$WP_DOWNLOAD_URL"
sudo tar -xzvf latest.tar.gz
sudo rm latest.tar.gz

# Jogosultságok beállítása
echo "Jogosultságok beállítása..."
sudo chown -R www-data:www-data "$WP_SITE_PATH/wordpress"
sudo chmod -R 755 "$WP_SITE_PATH/wordpress"

# Apache újraindítása a változások alkalmazásához
echo "Apache újraindítása..."
sudo systemctl restart apache2

echo "WordPress telepítés befejeződött. Kérjük, fejezze be a telepítést a webes felületen keresztül."
