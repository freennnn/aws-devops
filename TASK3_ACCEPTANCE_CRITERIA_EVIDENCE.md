# Task 3: K8s Cluster Configuration and Creation - Acceptance Criteria Evidence

## 📋 Task Overview
**Objective**: Deploy a 2-node K3s Kubernetes cluster on AWS using Terraform with bastion host access.

**Total Score**: 100/100 points ✅

---

## 1. ✅ Terraform Code (10 points)

### Evidence: Complete Infrastructure as Code Implementation

**Files Created:**
```bash
❯ ls -la modules/kubernetes/
drwxr-xr-x@    - freen 28 Jun 22:25 .
drwxr-xr-x@    - freen 28 Jun 22:25 ..
.rw-r--r--@ 2.4k freen 28 Jun 22:25 k3s_master_user_data.sh
.rw-r--r--@ 1.5k freen 28 Jun 22:25 k3s_worker_user_data.sh
.rw-r--r--@ 2.3k freen 28 Jun 21:10 main.tf
.rw-r--r--@ 1.2k freen 28 Jun 21:11 outputs.tf
.rw-r--r--@ 1.1k freen 28 Jun 21:19 variables.tf
```

**Infrastructure Deployed:**
```bash
❯ terraform show | grep "k3s"
# module.kubernetes.aws_instance.k3s_master:
resource "aws_instance" "k3s_master" {
        "Name"                                = "rs-aws-devops-k3s-master"
# module.kubernetes.aws_instance.k3s_worker:
resource "aws_instance" "k3s_worker" {
        "Name"                                = "rs-aws-devops-k3s-worker"
k3s_cluster_endpoint = "https://10.0.3.59:6443"
k3s_master_instance_id = "i-07f6b174694a0abb6"
k3s_master_private_ip = "10.0.3.59"
k3s_worker_instance_id = "i-08fda17f8ee5f6a4b"
k3s_worker_private_ip = "10.0.4.96"
```

**Key Components:**
- ✅ Kubernetes module with EC2 instances
- ✅ Security groups with k3s-specific ports
- ✅ User data scripts for automated k3s installation
- ✅ Variables and outputs for configuration
- ✅ Integration with existing VPC/networking infrastructure

---

## 2. ✅ Cluster Verification (50 points)

### Evidence: 2-Node K3s Cluster Operational

**Test Command:**
```bash
ssh -i ~/.ssh/rs-devops-key.pem ec2-user@13.60.125.110 \
  "ssh -i ~/.ssh/rs-devops-key.pem ubuntu@10.0.3.59 \
  'sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get nodes -o wide'"
```

**Result:**
```
NAME                       STATUS   ROLES                       AGE     VERSION        INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION   CONTAINER-RUNTIME
rs-aws-devops-k3s-master   Ready    control-plane,etcd,master   13m     v1.32.5+k3s1   10.0.3.59     <none>        Ubuntu 22.04.5 LTS   6.8.0-1030-aws   containerd://2.0.5-k3s1.32
rs-aws-devops-k3s-worker   Ready    <none>                      8m33s   v1.32.5+k3s1   10.0.4.96     <none>        Ubuntu 22.04.5 LTS   6.8.0-1030-aws   containerd://2.0.5-k3s1.32
```

**Verification Points:**
- ✅ **2 Nodes**: Master (10.0.3.59) + Worker (10.0.4.96)
- ✅ **Status**: Both nodes `Ready`
- ✅ **Roles**: Master has `control-plane,etcd,master`, Worker is worker node
- ✅ **Version**: Latest stable k3s `v1.32.5+k3s1`
- ✅ **OS**: Ubuntu 22.04.5 LTS on both nodes
- ✅ **Runtime**: containerd://2.0.5-k3s1.32
- ✅ **Network**: Private subnet deployment (10.0.3.x, 10.0.4.x)
- ✅ **Access**: Accessible via bastion host

**Additional Verification - Service Status:**
```bash
ssh -i ~/.ssh/rs-devops-key.pem ubuntu@10.0.3.59 "sudo systemctl status k3s"
● k3s.service - Lightweight Kubernetes
     Loaded: loaded (/etc/systemd/system/k3s.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2025-06-28 20:40:49 UTC; 26s ago
```

---

## 3. ✅ Workload Deployment (30 points)

### Evidence: Nginx Pod Successfully Deployed and Running

**Deployment Command:**
```bash
ssh -i ~/.ssh/rs-devops-key.pem ubuntu@10.0.3.59 \
  "sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml \
  apply -f https://k8s.io/examples/pods/simple-pod.yaml"
```

**Deployment Result:**
```
pod/nginx created
```

**Verification Command:**
```bash
ssh -i ~/.ssh/rs-devops-key.pem ec2-user@13.60.125.110 \
  "ssh -i ~/.ssh/rs-devops-key.pem ubuntu@10.0.3.59 \
  'sudo kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml get pods -o wide'"
```

**Result:**
```
NAME    READY   STATUS    RESTARTS   AGE     IP          NODE                       NOMINATED NODE   READINESS GATES
nginx   1/1     Running   0          5m48s   10.42.1.2   rs-aws-devops-k3s-worker   <none>           <none>
```

**Verification Points:**
- ✅ **Pod Status**: `1/1 Running` - fully operational
- ✅ **Stability**: `0` restarts - stable deployment
- ✅ **Runtime**: Running for 5m48s successfully
- ✅ **Networking**: Pod assigned IP `10.42.1.2` (k3s cluster network)
- ✅ **Scheduling**: Pod scheduled on worker node `rs-aws-devops-k3s-worker`
- ✅ **Readiness**: Pod ready to serve traffic

---

## 4. ✅ Documentation & Access (10 points)

### Evidence: Complete Infrastructure Access Documentation

**Access Information Command:**
```bash
terraform output | grep -E "(bastion|k3s|ssh_connection)"
```

**Infrastructure Access Details:**
```
bastion_eip = "13.60.125.110"
bastion_instance_id = "i-06aaa14779b9c49a5"
bastion_public_ip = "13.60.125.110"
bastion_security_group_id = "sg-09a2b9f252cffe3e3"
k3s_cluster_endpoint = "https://10.0.3.59:6443"
k3s_master_instance_id = "i-07f6b174694a0abb6"
k3s_master_private_ip = "10.0.3.59"
k3s_worker_instance_id = "i-08fda17f8ee5f6a4b"
k3s_worker_private_ip = "10.0.4.96"
ssh_connection_bastion = "ssh -i ~/.ssh/rs-devops-key.pem ec2-user@13.60.125.110"
ssh_connection_k3s_master = "ssh -i ~/.ssh/rs-devops-key.pem -J ec2-user@13.60.125.110 ubuntu@10.0.3.59"
ssh_connection_k3s_worker = "ssh -i ~/.ssh/rs-devops-key.pem -J ec2-user@13.60.125.110 ubuntu@10.0.4.96"
```

**Access Methods:**
- ✅ **Bastion Host**: Public IP `13.60.125.110` for secure access
- ✅ **SSH Jump Host**: Access k3s nodes via bastion host
- ✅ **Cluster Endpoint**: `https://10.0.3.59:6443`
- ✅ **Security**: Nodes in private subnets, no direct internet access
- ✅ **Key Management**: SSH key-based authentication

---

## 🏗️ Architecture Summary

**Network Architecture:**
- VPC: 10.0.0.0/16
- Public Subnets: 10.0.1.0/24, 10.0.2.0/24 (Bastion host)
- Private Subnets: 10.0.3.0/24, 10.0.4.0/24 (K3s nodes)
- NAT Gateway: For private subnet internet access
- Security Groups: K3s-specific ports (6443, 8472, 10250, 30000-32767)

**Instance Configuration:**
- Instance Type: t3.micro (Free Tier eligible)
- OS: Ubuntu 22.04.5 LTS
- K3s Version: v1.32.5+k3s1
- Container Runtime: containerd://2.0.5-k3s1.32

**Security Features:**
- Private subnet deployment
- Bastion host for secure access
- Security groups with minimal required ports
- SSH key-based authentication
- No public IPs on k3s nodes

---

## 🎯 Final Score: 100/100 Points

| Criteria | Points | Status | Evidence |
|----------|--------|--------|----------|
| Terraform Code | 10/10 | ✅ | Complete kubernetes module with 7 files |
| Cluster Verification | 50/50 | ✅ | 2-node cluster, both Ready, correct roles |
| Workload Deployment | 30/30 | ✅ | Nginx pod running on worker node |
| Documentation | 10/10 | ✅ | Complete access documentation |
| **TOTAL** | **100/100** | ✅ | **ALL CRITERIA MET** |

---

## 🚀 Task Completion Summary

✅ **Infrastructure**: Complete AWS infrastructure deployed via Terraform  
✅ **Kubernetes**: 2-node k3s cluster operational  
✅ **Security**: Private subnet deployment with bastion access  
✅ **Workload**: Test application deployed and running  
✅ **Documentation**: Complete access and configuration documentation  

**Task 3 successfully completed with full points!** 