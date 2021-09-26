1 Pull MySQL Server docker image from Docker repository, add a tag to it then push to private repository.

Please refer to the following command line:

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
- email: hiroshifuu@outlook.com
  name: Feng Hao
name: mysqldb
sources:
- https://hub.docker.com/r/mysql/mysql-server/
version: 1.0

3 Edit values.yaml. You may want to specific the password, by setting mysqldbPassword: password.
image:
  pullPolicy: IfNotPresent
  repository: qio01:5000/mysql-server
  tag: latest
persistence:
  accessMode: ReadWriteOnce
  enabled: true
  size: 40Gi
  storageClass: standard
resources:
  requests:
    memory: 512Mi
    cpu: 500m
serviceType: ClusterIP
mysqldbPassword: password

4 Edit values.yaml. You may want to specific the password, by setting mysqldbPassword: password.
image:
  pullPolicy: IfNotPresent
  repository: dockerregistry-url/mysql-server
  tag: latest
persistence:
  accessMode: ReadWriteOnce
  enabled: true
  size: 40Gi
  storageClass: standard
resources:
  requests:
    memory: 512Mi
    cpu: 500m
serviceType: ClusterIP
mysqldbPassword: password

5 Create secret.yaml. If you have defined the mysqlRootPassword, the password will be configured. You could define a different password for root in the values.yaml by setting mysqlRootPassword.

apiVersion: v1
kind: Secret
metadata:
  name: {{ template "fullname" . }}
  labels:
    app: {{ template "fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
type: Opaque
data:
  mysqldb-root-password: {{ default "" .Values.mysqlRootPassword | b64enc | quote }}
  mysqldb-password: {{ default "" .Values.mysqldbPassword | b64enc | quote }}
{{- if .Values.mysqlRootPassword }}
  data-source-name: {{ printf "root%s@(localhost:3306)/" .Values.mysqlRootPassword | b64enc | quote}}
{{- else }}
  data-source-name: {{ printf "root@(localhost:3306)/" | b64enc | quote}}
{{- end }}

6 Edit deployment.yaml. A few things you might be interested to look at. The env configurations. MySQL user password, root password, default database, and allow for empty password all can be found here. The most important configuration is the mountPath of volumeMounts. This is for persistent storage, you need to set the mountPath correctly, different MySQL distribution will use different path.

apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: {{ template "fullname" . }}
  labels:
    app: {{ template "fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
spec:
  template:
    metadata:
      labels:
        app: {{ template "fullname" . }}
        release: {{ .Release.Name }}
        component: "{{.Release.Name}}"
        nautilian.snapshot.enabled: "true"
    spec:
      containers:
      - name: {{ template "fullname" . }}
        image: {{ .Values.image.repository}}:{{ .Values.image.tag}}
        imagePullPolicy: {{ .Values.image.pullPolicy }}
        env:
        - name: MYSQLDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ template "fullname" . }}
              key: mysqldb-root-password
        - name: MYSQLDB_USER
          value: {{ default "" .Values.mysqldbUser | quote }}
        - name: MYSQLDB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: {{ template "fullname" . }}
              key: mysqldb-password
        - name: MYSQLDB_DATABASE
          value: {{ default "" .Values.mysqldbDatabase | quote }}
        - name: ALLOW_EMPTY_PASSWORD
          value: "yes"
        ports:
        - name: mysql
          containerPort: 3306
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
          initialDelaySeconds: 30
          timeoutSeconds: 5
        readinessProbe:
          exec:
            command:
            - mysqladmin
            - ping
          initialDelaySeconds: 5
          timeoutSeconds: 1
        resources:
{{ toYaml .Values.resources | indent 10 }}
        volumeMounts:
        - name: data
          mountPath: /var/lib/mysql
      volumes:
      - name: config
        configMap:
          name: {{ template "fullname" . }}
      - name: data
      {{- if .Values.persistence.enabled }}
        persistentVolumeClaim:
          claimName: {{ .Values.persistence.existingClaim | default (include "fullname" .) }}
      {{- else }}
        emptyDir: {}
      {{- end -}}

7 Create svc.yaml to create a service in kubernetes.
apiVersion: v1
kind: Service
metadata:
  name: {{ template "fullname" . }}
  labels:
    app: {{ template "fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
spec:
  type: {{ .Values.serviceType }}
  ports:
  - name: mysql
    port: 3306
    targetPort: 3306
  selector:
    app: {{ template "fullname" . }}

8 Create pvc.yaml for the persistent volume.
{{- if and .Values.persistence.enabled (not .Values.persistence.existingClaim) }}
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: {{ template "fullname" . }}
  labels:
    app: {{ template "fullname" . }}
    chart: "{{ .Chart.Name }}-{{ .Chart.Version }}"
    release: "{{ .Release.Name }}"
    heritage: "{{ .Release.Service }}"
  annotations:
  {{- if .Values.persistence.storageClass }}
    volume.beta.kubernetes.io/storage-class: {{ .Values.persistence.storageClass | quote }}
  {{- else }}
    volume.alpha.kubernetes.io/storage-class: default
  {{- end }}
spec:
  accessModes:
    - {{ .Values.persistence.accessMode | quote }}
  resources:
    requests:
      storage: {{ .Values.persistence.size | quote }}
{{- end }}

9 Deploy using helm install.
helm install <chart_name> --name <release-name> --namespace <name-space> name

10 Login to the shell of the Pod to do MySQL configurations. Grant all privileges on that database and (in the future) tables. WITH GRANT OPTION creates a MySQL user that can edit the permissions of other users.
ALTER USER 'root'@'localhost' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'password';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
