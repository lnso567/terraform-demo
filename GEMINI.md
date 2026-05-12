# GCP Terraform Lab - Project Guidance

## 🚀 Premium Lab Infrastructure (Recommended)

To ensure maximum performance and avoid resource bottlenecks during development (especially for Day 8 LB and Day 9 Monitoring), the following specifications are used:

| Component | Specification | Reason |
| :--- | :--- | :--- |
| **App Workers (MIG)** | `e2-standard-4` (4 vCPU, 16GB RAM) | Smooth LB health checks and Docker performance. |
| **Monitor Host** | `e2-standard-4` (4 vCPU, 16GB RAM) | Fluid Prometheus queries and Grafana rendering. |
| **Boot Disk** | `pd-balanced`, 30GB | Faster RHEL 9 boot and TSDB write performance. |

---

## 💰 Cost Management & Budget ($300 Free Credit)

### Mode 1: Safe Lab Mode (Recommended)
*   **Workflow:** Always run `./destroy.sh` after each session.
*   **Usage:** ~2 hours/day.
*   **Estimated Cost:** ~$66 USD over 60 days.
*   **Credit Status:** Very Safe. Only uses ~22% of the $300 credit.

### Mode 2: 24/7 Always-On Mode (Caution)
*   **Workflow:** Keeping instances running for continuous monitoring.
*   **Estimated Cost:** ~$327 USD / month.
*   **Credit Status:** **Risky.** The $300 credit will be exhausted in ~28 days. Out-of-pocket charges will apply thereafter.

---

## 🛠 Operational Rules
1.  **Always Verify Destruction:** After finishing work, run `terraform destroy` or use the provided `./destroy.sh` and verify in the GCP Console that no instances remain.
2.  **Region:** Taiwan (`asia-east1`) is used for low latency and consistent pricing for `e2-standard` series.
3.  **Disk Performance:** Never use `pd-standard` (HDD) for Prometheus or RHEL 9; the IOPS bottleneck will cause significant lag.
