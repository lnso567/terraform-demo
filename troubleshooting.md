# GCP 雲端架構實戰故障排除指南 (Day 9 Troubleshooting)

## 1. 資源枯竭 (ZONE_RESOURCE_POOL_EXHAUSTED)
### 問題描述
`terraform apply` 顯示成功，但 Compute Engine 執行個體群組 (MIG) 中健康個體為 0，且 VM 總數顯示為 0。在 MIG 的「錯誤」分頁看到 `ZONE_RESOURCE_POOL_EXHAUSTED`。

### 根本原因
雲端供應商在特定區域（如 `asia-east1-a`）的特定機器型號（如 `e2-standard-4`）庫存暫時告罄。

### 解決對策
*   **更換可用區 (Zone)**：從 a 區切換至 b 或 c 區。
*   **跨區域遷移 (Region Migration)**：遷移至資源更充裕的區域（如 `asia-northeast1` 東京）。
*   **更換機器系列**：若 `e2` 系列皆無貨，考慮改用 `n2` 或 `n1` 系列。

---

## 2. Terraform 變數覆蓋陷阱 (Variable Precedence)
### 問題描述
修改了 `variables.tf` 中的 `zone` 或 `region` 設定，但執行 `apply` 時錯誤日誌仍顯示舊的區域設定。

### 根本原因
專案目錄中存在 `terraform.tfvars` 檔案。根據 Terraform 優先權規則，`.tfvars` 檔案的設定會覆蓋 `variables.tf` 的預設值。

### 解決對策
*   檢查並清理 `terraform/terraform.tfvars` 檔案。
*   確保沒有硬編碼 (Hardcoding) 的設定殘留在 `.tfvars` 中。

---

## 3. 跨區域遷移的網路衝突 (Subnet Scope Conflict)
### 問題描述
搬遷區域時出現 `Invalid value for field 'instance.networkInterfaces[0]'` 或 `Invalid IPCidrRange` 衝突。

### 根本原因
*   **作用域不匹配**：VM 位於新區域 (東京)，但嘗試引用舊區域 (台灣) 的子網。
*   **IP 網段衝突**：嘗試在新區域建立與舊區域相同名稱且相同 CIDR (`10.10.10.0/24`) 的子網。

### 解決對策
*   **更新子網配置**：明確指定子網的 `region` 屬性。
*   **變更 CIDR 網段**：將衝突的網段 (如 `10.10.10.0/24`) 更改為新網段 (如 `10.20.10.0/24`)。

---

## 4. 作業系統與啟動腳本優化 (OS & Startup Script)
### 經驗總結
在雲端環境中，OS 的選擇會影響部署的穩定性與速度。

*   **RHEL 9**：安全性高但權限與 Repo 管理較嚴格，易與第三方 Docker Repo 衝突，且為付費鏡像，受帳號權限限制。
*   **Debian 11/12**：輕量、啟動極快、與 Docker 相容性完美，且無額外授權費用。

### 建議做法
開發與 Web 服務建議優先使用 **Debian/Ubuntu**，以降低 Startup Script 失敗與健康檢查不通過的機率。

---

## 5. 狀態鎖定問題 (Error acquiring the state lock)
### 問題描述
執行指令時出現 `Error acquiring the state lock: resource temporarily unavailable`。

### 根本原因
前次操作未正常結束，導致 `.tfstate` 檔案被鎖定。

### 解決對策
*   手動刪除鎖定檔：`rm terraform/terraform.tfstate.lock.info`。
*   或者在執行時加上 `-lock=false` (不建議用於正式環境)。

---

## 6. Cloud Armor 與 WAF 觀念 (Web Application Firewall)
### 核心觀念
Cloud Armor 是 Google Cloud 原生的 **WAF (Web Application Firewall)**，負責在負載平衡器 (LB) 層級過濾惡意流量。

*   **它的角色**：它就像是您基礎設施的「全域警衛」，決定哪些 IP 或地理區域可以進入您的後端服務。
*   **與 Cloudflare 的關係**：
    *   **同級產品**：兩者都屬於邊緣安全防護 (Edge Security)，運作在 OSI 第 7 層 (應用層)。
    *   **差異**：Cloudflare 通常透過 DNS 接管來保護各種雲平台；Cloud Armor 則是與 GCP 的全域負載平衡器 (GLB) 原生整合，不需要改 DNS 權限。
*   **配置方式**：在 `terraform/main.tf` 的 `google_compute_security_policy` 區塊中定義 `rule`（規則）。
    *   `action = "allow"`：給過。
    *   `action = "deny(403)"`：拒絕訪問並回傳 403 錯誤。

### 常見誤區
*   **它不是防火牆規則 (Firewall Rule)**：VPC 防火牆是在 L3/L4 層級控制 VM 的進入；Cloud Armor 是在 L7 層級控制進到 LB 的 Web 流量。
*   **生效範圍**：必須將 Security Policy 綁定到 **Backend Service** 才會生效。
