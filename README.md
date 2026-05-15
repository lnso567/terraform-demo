# GCP Infrastructure & Automation Lab

This repository documents my hands-on journey through Google Cloud infrastructure, evolving from a single VM to a production-grade architecture with load balancing, autohealing, and monitoring — all managed via Infrastructure as Code.

## 🗺️ Learning Journey

| Day | Theme | Key Milestones | Architecture Shift |
|:---:|-------|---------------|:------------------:|
| **1** | 🥚 Foundation | VPC + Subnet + Firewall + VM + NAT | 單一 VM 打通網路 |
| **2** | 🏗 Multi-VPC | App-VPC / Mgmt-VPC 隔離 + VPC Peering | 網路分段與互通 |
| **3** | ⚙️ Automation | `count` / `for_each` 批量建置 + `locals` 腳本共用 | 硬編碼 → 程式化宣告 |
| **4** | 🔒 Security Hardening | Persistent Disk 掛載 + SELinux + Firewalld + node_exporter | 安全加固與持久化 |
| **5-6** | 📦 Variable Extraction | `variables.tf` / `tfvars` 抽離 + 錯誤處理 + dnf 重試機制 | 可維護性提升 |
| **7** | 📊 Zero-Touch Monitoring | Grafana Provisioning + Dashboard 1860 auto-download + SELinux port 授權 | 監控全自動化 |
| **8** | ♻️ Autohealing (MIG) | Instance Template → MIG(2台) → Health Check → 自動重建 | 寵物 → 畜牧 |
| **9** | 🌐 Global Load Balancer | Cloud LB + URL Map + Backend Service + Cloud Armor | 單一入口 + 安全防護 |

## 🏛 Current Architecture (Day 9)

```
                    🌍 Internet
                        │
                  Cloud Load Balancer
                  (Global External HTTP)
                        │
                   URL Map
                        │
                  Backend Service
                  + Cloud Armor WAF
                        │
              ┌─────────┴─────────┐
          MIG (2 instances)   Health Check
          Autohealing ON      TCP :80
              │                    │
              └────────┬───────────┘
                       │
                mgmt-vpc (10.20.10.0/24)
                ├── Cloud NAT (outbound)
                ├── IAP Tunnel (SSH access)
                └── Firewall Rules
```

## 🛠 Infrastructure Stack

| Layer | Technology | Purpose |
|:------|:-----------|:--------|
| **IaC** | Terraform | Provision VPC, Compute, LB, Security |
| **CaC** | Ansible | Configure OS, Docker, SELinux, Monitoring |
| **OS** | Debian 11 / RHEL 9 | App workers & Monitor host |
| **Monitoring** | Prometheus + Grafana | Metrics collection & visualization |
| **Auth** | IAP Tunnel | Zero-trust SSH without public IP |
| **WAF** | Cloud Armor | L7 traffic filtering at LB edge |

## 🚀 Getting Started

```bash
# 1. Provision infrastructure
cd terraform && terraform init && terraform apply

# 2. Configure via Ansible (through IAP Tunnel)
ansible-playbook -i ansible/inventory_gcp.yml ansible/playbook.yml

# 3. Cleanup after session
./destroy.sh
```

## 💰 Cost Management

| Mode | Usage | Est. Cost | Credit Status |
|:-----|:------|:---------:|:-------------:|
| **Safe Lab** ✅ | ~2 hrs/day | ~$66 / 60 days | ✅ Safe (~22% of $300) |
| **Always-On** ⚠️ | 24/7 | ~$327 / month | 🔴 Exhausts credit in ~28 days |

> Always run `./destroy.sh` after each session. Verify in GCP Console that no instances remain.

## 📁 Repository Structure

```
gcp-terraform-lab/
├── terraform/          # IaC: main.tf, variables.tf, outputs.tf, provider.tf
│   ├── main.tf         # Resources: VPC, MIG, LB, Cloud Armor
│   ├── variables.tf    # Parameterized configs
│   ├── outputs.tf      # Exported values (MIG info, LB IP)
│   └── provider.tf     # GCP provider config
├── ansible/            # CaC: Playbooks & Roles
│   ├── playbook.yml    # Entry point
│   ├── inventory_gcp.yml  # Dynamic GCP inventory
│   ├── ansible.cfg     # IAP Tunnel proxy config
│   └── roles/          # app + monitor roles
├── deploy.sh           # One-click deploy
├── destroy.sh          # One-click teardown
├── gssh.sh             # IAP SSH wrapper
└── troubleshooting.md  # Known issues & solutions
```