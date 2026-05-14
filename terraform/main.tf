# ==========================================
# DAY 8: MIG + Health Check + Autohealing
# ==========================================

# ── 0. 網路層 (基礎設施) ──────────────────────────────────────────────
resource "google_compute_network" "mgmt_vpc" {
  name                    = "mgmt-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "mgmt_subnet" {
  name          = "mgmt-subnet"
  ip_cidr_range = "10.10.10.0/24"
  network       = google_compute_network.mgmt_vpc.id
  region        = var.region
}

resource "google_compute_router" "router" {
  name    = "mgmt-router"
  region  = var.region
  network = google_compute_network.mgmt_vpc.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "mgmt-nat"
  router                             = google_compute_router.router.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "allow_iap" {
  name    = "allow-iap-ssh"
  network = google_compute_network.mgmt_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["22", "3000", "9090"]
  }
  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "allow_monitoring_internal" {
  name    = "allow-monitoring-internal"
  network = google_compute_network.mgmt_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["9100"]
  }
  source_ranges = ["10.10.10.0/24"]
}

# ── 1. 防火牆：允許 GCP Health Check ────────────────────────────────────────────
# GCP Health Check 來自特定 IP 網段，必須放行否則 MIG 會認為機器永遠死
resource "google_compute_firewall" "allow_health_check" {
  name        = "allow-gcp-health-check"
  network     = google_compute_network.mgmt_vpc.id
  target_tags = ["allow-health-check"]
  allow {
    protocol = "tcp"
    ports    = ["80", "443", "9100"] # Nginx (80/443) + node_exporter (9100)
  }
  # GCP 官方 Health Check IP 網段
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

# 增加外部訪問規則 (80/443)
resource "google_compute_firewall" "allow_web" {
  name    = "allow-public-web"
  network = google_compute_network.mgmt_vpc.id
  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}

# ── 2. Health Check 定義 ──────────────────────────────────────────────────────────
# 定義「什麼算活著」：HTTP 80 埠回傳 200 (這能更精準判斷 Docker 內的 Nginx 是否活著)
resource "google_compute_health_check" "app_hc" {
  name                = "app-http-health-check"
  check_interval_sec  = 10 
  timeout_sec         = 5  
  healthy_threshold   = 2  
  unhealthy_threshold = 3  

  http_health_check {
    port         = 80
    request_path = "/"
  }
}

# ── 3. Instance Template (VM 藍圖) ────────────────────────────────────────────
# 將 VM 設置轉化為可重複使用的藍圖
resource "google_compute_instance_template" "app_template" {
  name_prefix  = "app-worker-template-"
  machine_type = var.app_machine_type
  region       = var.region

  tags = ["http-server", "https-server", "allow-health-check"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
    disk_type    = "pd-balanced"
    disk_size_gb = 30
  }

  network_interface {
    network    = google_compute_network.mgmt_vpc.id
    subnetwork = google_compute_subnetwork.mgmt_subnet.id
  }

  # Startup Script: 安裝 Docker + Nginx + node_exporter (針對 Debian 改用 apt)
  metadata_startup_script = <<-EOT
 #!/bin/bash
 set -e
 exec > >(tee /var/log/startup-script.log) 2>&1

 # 1. 安裝 Docker
 apt-get update
 apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
 curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
 echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
 apt-get update
 apt-get install -y docker-ce docker-ce-cli containerd.io

 # 2. 啟動 Nginx (供 Health Check 驗證)
 docker run -d --name nginx_web --restart always -p 80:80 nginx:alpine

 # 3. 啟動 node_exporter
 docker run -d --name node_exporter --restart always \
 --net="host" --pid="host" \
 -v "/:/host:ro,rslave" \
 quay.io/prometheus/node-exporter:latest \
 --path.rootfs=/host
 EOT

  # 標籤：用於識別
  labels = {
    terraform = "day8"
    role      = "app-worker"
  }

  lifecycle {
    create_before_destroy = true # 更新時先建造新機器再砍舊機器
  }
}

# ── 4. Managed Instance Group (MIG) + Autohealing ──────────────────────────
# 啟動藍圖，綁定健康檢查，實現自癒
resource "google_compute_instance_group_manager" "app_mig" {
  name               = "app-worker-mig"
  base_instance_name = "app-worker"
  zone               = var.zone

  version {
    instance_template = google_compute_instance_template.app_template.id
  }

  target_size = 2 # 確保永遠有 2 台存活

  # Autohealing 政策
  auto_healing_policies {
    health_check      = google_compute_health_check.app_hc.id
    initial_delay_sec = 300 # 給予機器開機與拉取 Docker Image 的時間 (5分鐘)
  }

  # 滾動更新策略
  update_policy {
    type                  = "PROACTIVE" # 主動更新，非被動
    minimal_action        = "REPLACE"   # 需要時替換
    max_surge_fixed       = 0           # RECREATE 模式下必須為 0
    max_unavailable_fixed = 1           # 最多不可用 1 台
    replacement_method    = "RECREATE"  # 重新建立而非更新
  }

  # 命名前綴
  named_port {
    name = "http"
    port = 80
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ── 5. Output：輸出 MIG 資訊 ────────────────────────────────────────────────────
# output "mig_name" {
#   description = "MIG 名稱"
#   value       = google_compute_instance_group_manager.app_mig.name
# }
# 
# output "mig_instance_count" {
#   description = "MIG 實例數量"
#   value       = google_compute_instance_group_manager.app_mig.target_size
# }
# 
# output "health_check_name" {
#   description = "Health Check 名稱"
#   value       = google_compute_health_check.app_hc.name
# }