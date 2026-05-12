#!/bin/bash
# destroy.sh - 撤收所有 GCP 資源

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${RED}警告：即將刪除所有受控的 GCP 資源 (VPC, VM, Disk)...${NC}"
read -p "您確定要繼續嗎？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "操作已取消。"
    exit 1
fi

echo -e "${GREEN}>>> 正在執行 Terraform Destroy...${NC}"
cd terraform
terraform destroy -auto-approve

echo -e "${GREEN}>>> 資源已成功清理。${NC}"
