#!/bin/bash
set -e
OS=$1; DISTRO=$2; VERSION=$3
echo "Installing PostgreSQL $VERSION ($DISTRO) on $OS"

if [[ "$OS" == "rhel9" ]]; then
  sudo dnf -qy module disable postgresql
  if [[ "$DISTRO" == "community" ]]; then
    # Add PostgreSQL Yum repository if not already installed
    if ! rpm -q pgdg-redhat-repo >/dev/null 2>&1; then
      sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
      sudo dnf clean all
      sudo dnf makecache
    fi
    sudo dnf install -y postgresql${VERSION}-server postgresql${VERSION}
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
    # Add PostgreSQL APT repository
    sudo apt-get install -y wget ca-certificates
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" | sudo tee /etc/apt/sources.list.d/pgdg.list
    sudo apt-get update -y
    sudo apt-get install -y postgresql-${VERSION} postgresql-client-${VERSION}
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
elif [[ "$OS" == "oracle9" ]]; then
  sudo dnf -qy module disable postgresql
  if [[ "$DISTRO" == "community" ]]; then
    # Add PostgreSQL Yum repository for Oracle Linux
    if ! rpm -q pgdg-redhat-repo >/dev/null 2>&1; then
      sudo dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm
      sudo dnf clean all
      sudo dnf makecache
    fi
    sudo dnf install -y postgresql${VERSION}-server postgresql${VERSION}
    sudo /usr/pgsql-${VERSION}/bin/postgresql-${VERSION}-setup initdb
    sudo systemctl enable postgresql-${VERSION}
    sudo systemctl start postgresql-${VERSION}
  fi
elif [[ "$OS" == "sles15" ]]; then
  if [[ "$DISTRO" == "community" ]]; then
    sudo zypper refresh
    sudo zypper install -y postgresql${VERSION}-server postgresql${VERSION}
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
  fi
fi

# Install NFS client
if [[ "$OS" == "rhel9" ]] || [[ "$OS" == "oracle9" ]]; then
  sudo dnf install -y nfs-utils
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true
elif [[ "$OS" == "debian12" ]]; then
  sudo apt-get install -y nfs-common
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true
elif [[ "$OS" == "sles15" ]]; then
  sudo zypper install -y nfs-client
  sudo systemctl enable nfs-client.target || true
  sudo systemctl start nfs-client.target || true
fi

psql --version || true
