#!/bin/bash
if [ $1 == 'install' ]; then 
cd "${ansible_user_dir}"
export _resource_name="${resource_name}"
export _resource_team="${resource_team}"
export _org_name="${resource_org}"
export _resource_version="${resource_version}"
export _resource_file="${resource_file}"
export _tar_artifact_dir="${_resource_name}"_v"${_resource_version}"
export _tar_artifact_name="$_tar_artifact_dir/$_resource_file"
export NGC_CLI_API_KEY="${NGC_CLI_API_KEY}"
export PATH=$PATH:/usr/local/bin/ngc-cli
sudo rm -rf tokkio-ui
sudo rm -rf "${_tar_artifact_dir}"
sudo mkdir -p tokkio-ui
ngc user who --org "${_org_name}"
export TOKKIO_UI_RESOURCE_URL="$_org_name/$_resource_team/$_resource_name:$_resource_version"
ngc registry resource download-version "${TOKKIO_UI_RESOURCE_URL}" --org "${_org_name}"
sudo tar -C tokkio-ui -xf "${_tar_artifact_name}"
cd tokkio-ui
python3 init.py
cp *.js build/
# configure nginx 
DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get install nginx -y
sudo mkdir -p /etc/nginx/sites-available/tokkio-ui && sudo mkdir -p /var/www/tokkio-ui
sudo cp -rp build/*  /var/www/tokkio-ui/
sudo rm -rf /etc/nginx/sites-enabled/default
sudo cat << 'EOF' | sudo tee /etc/nginx/sites-enabled/tokkio-ui
server {
    listen 80;
    server_name _;
    root /var/www/tokkio-ui;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
EOF
sudo systemctl restart nginx
sudo systemctl status nginx
else
sudo systemctl stop nginx
sudo apt-get purge nginx* -y 
sudo rm -rf /var/www/tokkio-ui/
echo "stopped tokkio-ui"
fi