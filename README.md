# designdoc

In order to guarantee the data security and stability of service, we need to
make a plan on the backup strategy and scaling up strategy.

1 Backup strategy
All the data should be backed up automatically by the cronjob, we can create
a cronjob on the kubernetes and backup the data of database to S3 bucket
automatically.

2 scale up strategy
We can set up auto scale strategy by setting the threshhold of CPU and Memory
e.g:

kubectl autoscale deployment <deployment-name> --min=2 --max=5 --cpu-percent=80
Execute "kubectl get hpa" to get the available hpa in your cluster.


Memory:
Please refer to the file : scale/memory-based-autoscaling.sh
In this section, we are discussing how you can deploy autoscaling on the basis of memory that pods are consuming. We have used the command “kubectl top pod” to get the utilized pod memory and applied the logic.

Get the average pod memory of the running pods: Execute the script as follows:
./memory-based-autoscaling.sh --action get-podmemory --deployment <deploymentname>
Once this command is executed, you can check the logs in directory /var/log/kube-deploy/.



Deploy autoscaling on the basis of pod memory: Execute the script as follows:
./memory-based-autoscaling.sh --action deploy-pod-autoscaling --deployment <deployment-name> --scaleup <scaleupthreshold> --scaledown <scaledownthreshold>
Check the same log file once the script is executed. If the average pod memory will cross the scaleup threshold, it will launch one more pod. Similarly, the Scale down policy condition will check two things:

whether the average pod memory is less than the scaledown threshold, and
if the no. of current pods is greater than the minimum count we have set while creating the hpa.
For example, if we have no. of pods running 3 and the minimum count is 2, in this case, the deployment will be scaled down if the average pod memory is less than the scaledown threshold. In other cases, if we have two running pods and minimum is also set to 2, even if the average pod memory is less than the threshold, the deployment won’t be scaled down.

Once you verify that the above actions are working fine, you can schedule the script as a cronjob to execute at every 5 mins. Provide the full path of the script in crontab.

*/5 * * * * /bin/bash /opt/kubernetes/memory-based-autoscaling.sh --action deploy-pod-autoscaling --deployment xxxxxx --scaleup 80 --scaledown 20 > /dev/null 2>&1


Others:

The metric-server deploy it’s resources in its own namespace. Wait a few 
minutes if you are following along, and you should be able to get information 
about any pods resources by using the command Kubectl top command.
I am editing the metric-server-deployment.yaml in order to use it without a 
certificate, add the bold lines under the volume section :

$ cd metrics-server/deploy/1.8+/
$ sudo vi metrics-server-deployment.yaml
      - name: metrics-server
        image: k8s.gcr.io/metrics-server-amd64:v0.3.3
        command: # added line
          - /metric-server # added line
          - --kubelet-insecure-tls # added line
$ kubectl apply -f . 
$ kubectl -n kube-system get pods
$ kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
minikube   393m         19%    1196Mi          20%


