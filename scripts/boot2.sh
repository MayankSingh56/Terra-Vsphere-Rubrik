#!/bin/bash
set -e

OS=$1
DISTRO=$2
VERSION=$3

LOGFILE="/root/bootstrap1.log"
exec > "$LOGFILE" 2>&1

echo "🔁 Retrying DNS resolution for PostgreSQL repo..."
for i in {1..5}; do
  if nslookup download.postgresql.org; then
    echo "✅ DNS resolution succeeded."

    echo "🌐 Checking network connectivity to PostgreSQL repo..."
    if curl -s --head https://download.postgresql.org | grep "200 OK" > /dev/null; then
      echo "✅ PostgreSQL repo is reachable."
      break
    else
      echo "❌ PostgreSQL repo is not reachable. Retrying in 5s..."
      sleep 5
    fi
  else
    echo "⏳ DNS resolution failed, retrying in 5s..."
    sleep 5
  fi

  if [ "$i" -eq 5 ]; then
    echo "❌ PostgreSQL repo is not reachable after retries. Falling back to RHEL base PostgreSQL."
    DISTRO="rhel-base"
  fi
done

echo "🔄 Checking if system is registered..."
if subscription-manager identity &>/dev/null; then
  echo "🔄 Refreshing Red Hat subscription..."
  timeout 60s subscription-manager refresh || echo "⚠️ Refresh timed out or failed."

  echo "🔍 Checking subscription status..."
  if subscription-manager status | grep -q "Simple Content Access"; then
    echo "✅ Simple Content Access is enabled. Proceeding with installation."
  else
    echo "⚠️ Simple Content Access is not enabled. You may need to attach a subscription."
  fi
else
  echo "⚠️ System is not registered with Red Hat. Skipping subscription checks."
fi

echo "✅ Enabling required RHEL repositories..."
subscription-manager repos --enable=rhel-9-for-x86_64-appstream-rpms
subscription-manager repos --enable=rhel-9-for-x86_64-baseos-rpms

echo "🧹 Cleaning DNF cache..."
dnf clean all

echo "⬆️ Updating system..."
dnf update -y

echo "📦 Installing PostgreSQL $VERSION ($DISTRO) on $OS"

if [[ "$OS" == "rhel9" ]]; then
  sudo dnf -qy module disable postgresql

  if [[ "$DISTRO" == "community" ]]; then
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

  elif [[ "$DISTRO" == "rhel-base" ]]; then
    sudo dnf install -y postgresql-server
    sudo postgresql-setup --initdb
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
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

echo "📦 Installing NFS client..."
if [[ "$OS" == "rhel9" ]]; then
  sudo dnf install -y nfs-utils
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true

elif [[ "$OS" == "debian12" ]]; then
  sudo apt-get install -y nfs-common
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true
fi

echo "🔍 Verifying PostgreSQL installation..."
psql --version || echo "⚠️ PostgreSQL not found in PATH"