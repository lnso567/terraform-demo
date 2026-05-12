#output "app_vm_name" {
#  value = google_compute_instance.app_vm.name
#}

#output "monitor_vm_name" {
#  value = google_compute_instance.monitor_vm.name
#}

#output "app_vm_internal_ip" {
#  value = google_compute_instance.app_vm.network_interface[0].network_ip
#}

output "mig_self_link" {                                                        
  description = "MIG 完整 URI，供 LB 或其他资源引用"                           
  value       = google_compute_instance_group_manager.app_mig.id               
}
                                                                                
output "mig_instance_group" {
  description = "Instance Group URL，用于负载均衡器后端"
  value       = google_compute_instance_group_manager.app_mig.instance_group    
}

output "vpc_self_link" {
  description = "VPC 网络 URI"                                                  
  value       = google_compute_network.mgmt_vpc.id
}

output "subnet_self_link" {
  description = "子网 URI"
  value       = google_compute_subnetwork.mgmt_subnet.id
}

# --- 從 main.tf 移入的 Output ---
output "mig_name" {
  description = "MIG 名稱"
  value       = google_compute_instance_group_manager.app_mig.name
}

output "mig_instance_count" {
  description = "MIG 實例數量"
  value       = google_compute_instance_group_manager.app_mig.target_size
}

output "health_check_name" {
  description = "Health Check 名稱"
  value       = google_compute_health_check.app_hc.name
}