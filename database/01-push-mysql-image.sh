# docker pull the image of mysql and push it to the private-docker-registry-url
docker pull mysql/mysql-server:5.7.21 
docker tag mysql/mysql-server:5.7.21 <private-docker-registry-url>/mysql-server:latest
docker push
