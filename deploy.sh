#!/bin/bash
set -e

# 顏色定義
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> 階段 1: 執行 Terraform 資源配置...${NC}"
cd terraform
terraform init
terraform apply -auto-approve

echo -e "${GREEN}>>> 階段 2: 等待雲端主機初始化 (30s)...${NC}"
sleep 30

echo -e "${GREEN}>>> 階段 3: 執行 Ansible 配置管理 (經由 IAP Tunnel)...${NC}"
cd ../ansible
# 確保安裝了必要的 GCP 集合
ansible-galaxy collection install google.cloud --force
ansible-playbook playbook.yml

echo -e "${GREEN}>>> 部署完成！${NC}"
echo "Grafana 位址: 可透過 IAP Tunnel 存取 3000 埠"
