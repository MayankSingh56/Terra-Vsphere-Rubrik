#!/bin/bash
set -e
OS=$1; DISTRO=$2; VERSION=$3
echo "Installing PostgreSQL $VERSION ($DISTRO) on $OS"

if [[ "$OS" == "rhel9" ]]; then
  sudo dnf -qy module disable postgresql
  if [[ "$DISTRO" == "community" ]]; then
    sudo dnf install -y postgresql${VERSION}-server
    sudo /usr/pgsql-${VERSION}/bin/postgresql-${VERSION}-setup initdb
    sudo systemctl enable postgresql-${VERSION}
    sudo systemctl start postgresql-${VERSION}
  elif [[ "$DISTRO" == "edb-as" ]]; then
    sudo dnf -y install edb-postgres-as${VERSION}-server
    sudo /usr/edb/as${VERSION}/bin/edb-as-${VERSION}-setup initdb
    sudo systemctl enable edb-as-${VERSION}
    sudo systemctl start edb-as-${VERSION}
  elif [[ "$DISTRO" == "edb-pge" ]]; then
    sudo dnf -y install edb-postgres-pge${VERSION}-server
    sudo /usr/edb/pge${VERSION}/bin/edb-pge-${VERSION}-setup initdb
    sudo systemctl enable edb-pge-${VERSION}
    sudo systemctl start edb-pge-${VERSION}
  fi
elif [[ "$OS" == "debian12" ]]; then
  sudo apt-get update -y
  if [[ "$DISTRO" == "community" ]]; then
    sudo apt-get install -y postgresql-common postgresql-${VERSION}
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
  elif [[ "$DISTRO" == "edb-as" ]]; then
    sudo apt-get install -y edb-as${VERSION}-server
    sudo systemctl enable edb-as-${VERSION}
    sudo systemctl start edb-as-${VERSION}
  elif [[ "$DISTRO" == "edb-pge" ]]; then
    sudo apt-get install -y edb-pge${VERSION}-server
    sudo systemctl enable edb-pge-${VERSION}
    sudo systemctl start edb-pge-${VERSION}
  fi
fi

# Install NFS client
if [[ "$OS" == "rhel9" ]]; then
  sudo dnf install -y nfs-utils
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true
elif [[ "$OS" == "debian12" ]]; then
  sudo apt-get install -y nfs-common
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true
fi

psql --version || true
