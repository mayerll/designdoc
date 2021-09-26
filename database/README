README

1 Pull MySQL Server docker image from Docker repository, tag it as
appreciate, then push to private repository.

$./001-push-mysql-image.sh

2 Exec helm init to initialize Helm Chart.
Edit Chart.yaml. This is optional, it is just to provide information of your deployment and make it more professional.

Please refer to the following example:

description: MySQL is the world's most popular open source database. With its proven performance, reliability, and ease-of-use, MySQL has become the leading choice of database for web applications of all sorts, ranging from personal websites and small online shops all the way to large-scale, high profile web operations like Facebook, Twitter, and YouTube.
home: http://www.mysql.com
icon: https://www.mysql.com/common/logos/logo-mysql-170x115.png
keywords:
- component=repo.mysql.com/yum/mysql-5.7-community/docker/x86_64/mysql-community-server-minimal-5.7.21-1.el7.x86_64.rpm
maintainers:
- email: test@outlook.com
  name: test
name: mysqldb
sources:
- https://hub.docker.com/r/mysql/mysql-server/
version: 1.0

3 Edit values.yaml. You may want to specific the password, by setting mysqldbPassword: password.

Please refer to the following example:
$cat ./03-values.yaml

4 Edit values.yaml. You may want to specific the password, by setting mysqldbPassword: password.

Please refer to the following example:
$cat ./04-values.yaml

5 Create secret.yaml. If you have defined the mysqlRootPassword, the password will be configured. You could define a different password for root in the values.yaml by setting mysqlRootPassword.

Please refer to the following example:
$cat ./05-secret.yaml

6 Edit deployment.yaml. A few things you might be interested to look at. The env configurations. MySQL user password, root password, default database, and allow for empty password all can be found here. The most important configuration is the mountPath of volumeMounts. This is for persistent storage, you need to set the mountPath correctly, different MySQL distribution will use different path.

Please refer to the following example:
$cat ./06-deployment.yaml

7 Create svc.yaml to create a service in kubernetes.

Please refer to the following example:
$cat ./07-svc.yaml

8 Create pvc.yaml for the persistent volume.

Please refer to the following example:
$cat ./08-pvc.yaml

9 Deploy using helm install.
helm install <chart_name> --name <release-name> --namespace <name-space> name

10 Login to the shell of the Pod to do MySQL configurations. Grant all privileges on that database and (in the future) tables. WITH GRANT OPTION creates a MySQL user that can edit the permissions of other users.
ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
