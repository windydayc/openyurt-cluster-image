Install sealer v0.8.6:

```bash
wget https://github.com/sealerio/sealer/releases/download/v0.8.6/sealer-v0.8.6-linux-amd64.tar.gz
tar -zxvf sealer-v0.8.6-linux-amd64.tar.gz -C /usr/bin
```

Build an openyurt cluster image:

```bash
cd openyurt-latest

# build openyurt ClusterImage
sealer build -t registry-1.docker.io/your_dockerhub_username/openyurt-cluster:latest -f Kubefile .

# login to dockerhub
sealer login registry-1.docker.io -u your_dockerhub_username -p xxx

# push to dockerhub
sealer push registry-1.docker.io/your_dockerhub_username/openyurt-cluster:latest
```

Install an openyurt cluster:

```bash
sealer run registry-1.docker.io/your_dockerhub_username/openyurt-cluster:latest -e APIServerAdvertiseAddress=47.115.228.119,YurttunnelServerAddress=47.115.228.119,FlannelNetWork=10.244.0.0/16,PodSubnet=10.244.0.0/16,ServiceSubnet=10.96.0.0/12
```

