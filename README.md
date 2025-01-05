## Setup Kubernetes in a Flash

As part of CKA preparation I was looking into how to setup Kubernetes in a flash. Problem is it is not easy to setup. There are lots of tutorials to read and follow but there is always some small details which get missed. So I decided to write my own script that combines all the steps together in a simple shell script. All of these steps are tested on Ubuntu 22.04 LTS. Most likely it will work on other ubuntu distributions as well. Depending on your internet speed you can have a control plane setup in less than 3 minutes using this script.

You can also spend time going over the [Kubeadmin Tutorial](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/)

### Prerequisites

You can use a VM on your local machine. Official requirement is to have 2gb/2cpu for control plane. But I would recommend using 4gb/4cpu nodes for better result. I am using virtual box locally for creating the VM. You will need to install virtualbox and vagrant on your machine. Vagrant is a tool that makes it easy to create and configure lightweight, reproducible, and portable development environments. It lets you focus on what you do best: writing code. With Vagrant, you can build a single development environment from multiple machines using VirtualBox. However vagrant is not needed and you can use the VirtualBox GUI to create and clone VMs.

### Pro Tips

Make sure to have your ssh key in authorized_keys of the VM. This will help you to connect to the VM without entering password. Also make sure to disable firewall on the VM. You don't want to open any ports for SSH, HTTP and HTTPS. If you are using a cloud provider like AWS or GCP then you can use their console to disable firewalls. However do note that, when you add worker node, both machines must be able to connect to each other on various ports used by Kubernetes.

### Control Plane Steps

Once you have your virtual machine ready and running. On control plane node run the following and wait for it to complete.

```bash
curl  https://raw.githubusercontent.com/mirislam/k8s/refs/heads/main/k8s_flash.sh | sh -
```

Once complete, note the command that was printed. You will need it to have worker node join the cluster.

If you have missed it, you can get the command by running the following on control plane node.
sudo kubeadm token create --print-join-command

Which will print output like the following:

```bash 
kubeadm join 192.168.86.56:6443 --token 517vn2.tay62xj7ztz9vt5l --discovery-token-ca-cert-hash sha256:354e8853acba4cce0c0a532e97cb1f7b3a3ee96be9ff3a2a007ef8d152f58f81
```

### Worker Node Steps

Once you have your virtual machine ready and running. On worker node run the following and wait for it to complete.

```bash
wget https://raw.githubusercontent.com/mirislam/k8s/refs/heads/main/k8s_flash.sh
chmod +x k8s_flash.sh
./k8s_flash.sh node
```

Once the above commands are completed your worker node will be ready to join the cluster. Use the join command provided by control plane node and run it on worker node. Make sure to prefix the command with sudo.

### Test Cluster

On the control plane give the command to see if the worker node has joined the cluster or not

```bash 
kubectl get nodes
```

Output will be similar to this:

```
mislam@k8s-cp1:~$ kubectl get nodes
NAME      STATUS   ROLES           AGE   VERSION
k8s-cp1   Ready    control-plane   84m   v1.32.0
k8s-n1    Ready    <none>          69m   v1.32.0
```




