#!/bin/bash
set -e

OS=$1
DISTRO=$2
VERSION=$3

echo "🔁 Retrying DNS resolution for PostgreSQL repo..."
for i in {1..5}; do
  if nslookup download.postgresql.org; then
    echo "✅ DNS resolution succeeded."
    break
  else
    echo "⏳ DNS resolution failed, retrying in 5s..."
    sleep 5
  fi
done

echo "🔄 Refreshing Red Hat subscription..."
subscription-manager refresh

echo "🔍 Checking subscription status..."
if subscription-manager status | grep -q "Content Access Mode is set to Simple Content Access"; then
  echo "✅ Simple Content Access is enabled. Proceeding with installation."
else
  echo "⚠️ Simple Content Access is not enabled. You may need to attach a subscription."
fi

echo "✅ Enabling required RHEL repositories..."
subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms

echo "🧹 Cleaning DNF cache..."
dnf clean all

echo "⬆️ Updating system..."
dnf update -y

echo "Installing PostgreSQL $VERSION ($DISTRO) on $OS"

if [[ "$OS" == "rhel9" ]]; then
  sudo dnf -qy module disable postgresql

  if [[ "$DISTRO" == "community" ]]; then
    # Add PostgreSQL Yum repository if not already installed
    if ! rpm -q pgdg-redhat-repo >/dev/null 2>&1; then
      sudo dnf install -y https://download.postgresql.org/pub/repos/yum/${VERSION}/redhat/rhel-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
      sudo dnf clean all
      sudo dnf makecache
    fi

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