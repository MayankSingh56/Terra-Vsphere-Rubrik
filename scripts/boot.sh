#!/bin/bash

# Log everything to a file
exec > >(tee /var/log/bootstrap.log) 2>&1

# Trap errors and show line number
trap 'echo "❌ Script failed at line $LINENO"; exit 1' ERR

echo "🔧 Restarting NetworkManager..."
systemctl restart NetworkManager

echo "📡 IP address info:"
ip a

echo "🔍 DNS resolution test (google.com)..."
nslookup google.com || echo "⚠️ DNS resolution failed"

echo "🌐 Internet connectivity test (Google)..."
curl -I https://www.google.com || echo "⚠️ Internet access failed"

echo "📍 Routing table:"
ip r

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


echo "🚀 Starting PostgreSQL installation..."

# Check if PostgreSQL repo is already installed
if ! rpm -q pgdg-redhat-repo >/dev/null 2>&1; then
  echo "📦 Installing PostgreSQL Yum repo..."
  curl --retry 5 --retry-delay 3 -O https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  rpm -ivh pgdg-redhat-repo-latest.noarch.rpm
else
  echo "✅ PostgreSQL Yum repo already installed."
fi

# Disable default PostgreSQL module
dnf -qy module disable postgresql

# Install PostgreSQL 15
dnf install -y postgresql15-server postgresql15

# Initialize the database
/usr/pgsql-15/bin/postgresql-15-setup initdb

# Enable and start the service
systemctl enable postgresql-15
systemctl start postgresql-15

# Confirm installation
echo "🧪 PostgreSQL version:"
psql --version

echo "✅ PostgreSQL installation complete."