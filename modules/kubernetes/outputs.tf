output "k3s_master_instance_id" {
  description = "ID of the K3s master instance"
  value       = aws_instance.k3s_master.id
}

output "k3s_master_private_ip" {
  description = "Private IP address of the K3s master"
  value       = aws_instance.k3s_master.private_ip
}

output "k3s_master_public_ip" {
  description = "Public IP address of the K3s master (if in public subnet)"
  value       = aws_instance.k3s_master.public_ip
}

output "k3s_worker_instance_id" {
  description = "ID of the K3s worker instance"
  value       = aws_instance.k3s_worker.id
}

output "k3s_worker_private_ip" {
  description = "Private IP address of the K3s worker"
  value       = aws_instance.k3s_worker.private_ip
}

output "k3s_worker_public_ip" {
  description = "Public IP address of the K3s worker (if in public subnet)"
  value       = aws_instance.k3s_worker.public_ip
}

output "k3s_cluster_endpoint" {
  description = "K3s cluster API endpoint"
  value       = "https://${aws_instance.k3s_master.private_ip}:6443"
}

output "kubectl_config_command" {
  description = "Command to copy kubeconfig from master node"
  value       = "scp -i ~/.ssh/${var.key_name}.pem ubuntu@${aws_instance.k3s_master.private_ip}:/etc/rancher/k3s/k3s.yaml ~/.kube/config"
} 
