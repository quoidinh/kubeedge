# Create a basic API with Ruby on Rails

![Create a basic API with Ruby on Rails](https://f001.backblazeb2.com/file/webcrunch/lets-build-create-a-basic-api.jpg)

This is a small ongoing series that discusses what it takes to build a basic API in 2021 using Ruby on Rails as your backend. This code is the source of truth for a basic API related to Band data. We talk about returning JSON in various ways, routing, API versioning, authentication, and more.

- Read more at: [https://web-crunch.com/posts/create-a-basic-api-with-ruby-on-rails](https://web-crunch.com/posts/create-a-basic-api-with-ruby-on-rails)
- [Subscribe to the YouTube channel](https://youtube.com/c/webcrunch)
## Docker

Docker has been added with docker-compose to make the execution a lot easier.

To get up and running with run the following:

```
docker-compose up
```

After the server is running, run the following command to create the database schema:

```
docker-compose exec web /myapp/bin/rails db:migrate RAILS_ENV=development
```

Next, run the following command to fill up some data from the seeds:

```
docker-compose exec web /myapp/bin/rails db:seed RAILS_ENV=development
```

Consequently, we can try `http://localhost:3000/api/v1/bands` and it should show us 5 bands and 4 members for the first band `The Beatles`.

## Docker Hub

This API is available as a pubilc docker image on [Docker Hub](https://hub.docker.com/r/geshan/band-api).

## Kubernetes

All the kubernetes artifacts are in the `.k8s` directory. This is a bare-bones Kubernetes definition without service and any scaling or laod balancing.

### Setup Kind

To setup local k8s clusetr with kind run:

```
cat <<EOF | kind create cluster --config=-
kind: Cluster         
apiVersion: kind.x-k8s.io/v1alpha4
nodes:                
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
```

### Then to run

To run the Rails Bands API app on your Kind Kubernetes cluster execute the following on the project root:

```
kubectl apply -f ./.k8s
```

The deployment will be created and migration will run. Then to port forward the deployment to local port run the following:

```
kubectl port-forward deployment/bands-api-web 8001:3000
```

After that try `http://localhost:8001/api/v1/bands` , you should see the 5 bands and members from the `db/seeds.rb` file.
