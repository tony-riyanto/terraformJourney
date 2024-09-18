# Fargate-ecs-terraform

This is a script that will allow you to successfully spin up Fargate using Terraform.
The Load balancer URL is configured to listen on port 3000.
When Terraform spins up your load balancer URL, please use port:3000, e.g example.com:3000

# using https://medium.com/@olayinkasamuel44/using-terraform-and-fargate-to-create-amazons-ecs-e3308c1b9166

Code dans https://github.com/Samuelking011/Fargate-ecs-terraform

Tested OK on 18/09/2024
http://cb-load-balancer-755637949.us-east-1.elb.amazonaws.com:8080/api/create
http://cb-load-balancer-755637949.us-east-1.elb.amazonaws.com:8080/actuator/

aws_cloudwatch_metric_alarm.service_cpu_low: Creation complete after 0s [id=cb_cpu_utilization_low]
aws_cloudwatch_metric_alarm.service_cpu_high: Creation complete after 0s [id=cb_cpu_utilization_high]

Apply complete! Resources: 36 added, 0 changed, 0 destroyed.

== build image
mvn compile jib:dockerBuild
docker run -p 8080:8080 -d --name titi tonyriyanto/ecsaccount:s4
docker push tonyriyanto/ecsaccount:s4
