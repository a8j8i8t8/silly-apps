# Silly Apps

Some silly apps to play with.

## Architecture

With some blanks.

![silly apps](/silly-apps-arch.png)

## Requirements Checklist

To help us and yourself better understand how far you've made it, please check off the completed steps. Feel free to leave remarks that you feel would be useful in review.

### Base requirements

- [ ] Automation: scripts should be provided for building and deploying the entire cluster.
  - Remarks: ...
- [ ] Helm is used to create the kubernetes resources
  - Remarks: ...
- [ ] Kubernetes resources have resource limits / requests configured
  - Remarks: ...
- [ ] Environment variables needed by the apps are configured via kubernetes resources
  - Remarks: ...
- [ ] `/flask/fib` endpoint in the flask service is not publicly exposed
  - Remarks: ...
- [ ] The BE services are deployed in backend namespace and FE service in frontend namespace
  - Remarks: ...
- [ ] Accessing resources in the cluster should be done only via  Ambassador API Gateway  and resources (FE and public BE endpoints) are publicly accessible on a single domain
  - Remarks: ...
- [ ] Docker images employ best security practices and are small. Bonus: Build optimisation (duration, consumed resources)
  - Remarks: ...

### Additional requirements

- [ ] Auto scaling
  - [ ] Auto-scaling based on cpu/ram consumption (for generating more cpu/memory usage any of the services can be modified as needed)
  - [ ] All taken steps to implement and test are listed
- [ ] Monitoring:
  - [ ] Configure basic cluster monitoring for nodes and pods with Prometheus and consume statistics from Ambassador.
  - [ ] Bonus: Alerting configured
- Remarks: ...
