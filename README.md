# KindDevCluster  
Bootstrap a Development Kubernetes Cluster with KIND

## To-Dos

1. **Set Kind Cluster Type**  
   Predefined configs are available in `bootstrap/kind-config`.

2. **Verify LoadBalancer IP Address Pool**
   1. Check `bootstrap/metallb/ipaddresspool.yaml` to ensure the IP range matches your local network.
   2. run "docker inspect network kind" to check your Pod Network
   3. Network Address is listed under IPAM.Config.Subnet -> Choose an IP Range within this Subnet.

3. **Create a CA Certificate**  
   Adjust the `-subj` string to match your organization's requirements.

   ```bash
   mkdir -p CA
   openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
     -nodes -keyout CA/ca.key -out CA/ca.crt \
     -subj "/C=DE/ST=NRW/L=Bonn/O=MeinLabor/OU=CA/CN=meinlab-ca"
   ```

4. **Install exdns (k8s_gateway)**  
   Change the domain as needed.

   ```bash
   helm repo add k8s_gateway https://ori-edge.github.io/k8s_gateway/
   helm install exdns --set domain=cluster.dev k8s_gateway/k8s-gateway
   ```

5. **Configure Local DNS Resolution on macOS**  
   This enables resolution of `*.cluster.dev` via your Kubernetes DNS (e.g., k8s_gateway or CoreDNS).

   ```bash
   export domain="cluster.dev"
   export dns_ip="192.168.0.50"  # Replace with the LoadBalancer IP of your DNS service

   sudo mkdir -p /etc/resolver
   sudo tee /etc/resolver/$domain > /dev/null <<EOF
   nameserver $dns_ip
   port 53
   EOF
   ```

6. **(optional) Trust the CA Certificate with your mac**