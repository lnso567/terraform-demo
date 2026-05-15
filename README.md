# GCP Infrastructure & Automation Lab

This repository documents my hands-on experience with GCP infrastructure management, focusing on Infrastructure as Code (IaC) and configuration management.

## 🏗 Infrastructure Overview
The environment is designed for performance and reliability, utilizing the following specifications in the `asia-east1` region:

| Component | Specification | Purpose |
| :--- | :--- | :--- |
| **App Workers (MIG)** | `e2-standard-4` | Docker performance & LB health checks |
| **Monitor Host** | `e2-standard-4` | Prometheus/Grafana efficiency |
| **Boot Disk** | `pd-balanced` (30GB) | Optimal IOPS for RHEL 9/TSDB |

## 🛠 Operational Workflow
1.  **Deployment**: Infrastructure is provisioned using **Terraform** and managed via **Ansible** playbooks.
2.  **Safety First**: To adhere to cost management and security best practices, always verify that no resources remain active after sessions.
    *   Use the provided `./destroy.sh` script to decommission all resources.
    *   Verify the GCP Console to ensure no lingering instances.

## 💰 Cost Management
*   **Safe Lab Mode (Recommended)**: Running ~2 hours/day keeps costs around $66 USD over 60 days, well within the $300 free credit.
*   **Warning**: 24/7 "Always-On" mode is **Risky** and will exhaust credits in ~28 days, leading to out-of-pocket charges.

## 🚀 Getting Started
1.  **Provisioning**: `cd terraform && terraform init && terraform apply`
2.  **Configuration**: `ansible-playbook -i ansible/inventory_gcp.yml ansible/playbook.yml`
3.  **Cleanup**: `cd .. && ./destroy.sh`

目前進度 DAY 9