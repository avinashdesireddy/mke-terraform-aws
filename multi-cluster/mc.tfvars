cluster_name = "mc"
cluster1 = "mc1"
cluster2 = "mc2"
admin_password = ""
master_type = "m5.2xlarge"
master_count = 1
master_image_id = "ami-004556491237681fa"
msr_replica_count = 0
worker_type = "m5.2xlarge"
worker_count = 2
worker_image_id = "ami-004556491237681fa"
windows_worker_count = 0
mke_version = "3.5.1"
instance_volume_size = 200
worker_volume_size = 200

## MKE Vars
caCertPath = "/Users/avinashdesireddy/workspace/letsencrypt/config/live/cluster.avinashdesireddy.com/fullchain.pem"
certPath = "/Users/avinashdesireddy/workspace/letsencrypt/config/live/cluster.avinashdesireddy.com/cert.pem"
keyPath = "/Users/avinashdesireddy/workspace/letsencrypt/config/live/cluster.avinashdesireddy.com/privkey.pem"
licenseFilePath = "/Users/avinashdesireddy/workspace/secrets/mke_subscription.lic"