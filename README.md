# Silly Apps

Some silly apps to play with.

## Architecture

With some blanks.

![silly apps](/silly-apps-arch.png)

## Requirements Checklist

To help us and yourself better understand how far you've made it, please check off the completed steps. Feel free to leave remarks that you feel would be useful in review.

### Base requirements

- [x] Automation: scripts should be provided for building and deploying the entire cluster.
  - Remarks: Created a GitLab CI file that builds docker images, tests and scans these images and then deploys them to Kubernetes cluster.
- [x] Helm is used to create the kubernetes resources
  - Remarks: Helm is used to create all Kubernetes resources.
- [x] Kubernetes resources have resource limits / requests configured
  - Remarks: Yes, all Kubernetes resources have limits and requests resources configured.
- [x] Environment variables needed by the apps are configured via kubernetes resources
  - Remarks: Used Kubernetes secrets to configure necessary environment variables.
- [x] `/flask/fib` endpoint in the flask service is not publicly exposed
  - Remarks: Yes, this endpoint cannot be accessed from outside of the Kubernetes cluster.
- [x] The BE services are deployed in backend namespace and FE service in frontend namespace
  - Remarks: Yes.
- [x] Accessing resources in the cluster should be done only via  Ambassador API Gateway  and resources (FE and public BE endpoints) are publicly accessible on a single domain
  - Remarks: All resources that need to be accessed from outside of the Kubernetes cluster are done via Ambassador Edge Stack.
- [x] Docker images employ best security practices and are small. Bonus: Build optimisation (duration, consumed resources)
  - Remarks: Yes.

### Additional requirements

- [x] Auto scaling
  - [x] Auto-scaling based on cpu/ram consumption (for generating more cpu/memory usage any of the services can be modified as needed)
  - [x] All taken steps to implement and test are listed
- [x] Monitoring:
  - [x] Configure basic cluster monitoring for nodes and pods with Prometheus and consume statistics from Ambassador.
  - [x] Bonus: Alerting configured
- Remarks:
  - To test CPU based Auto scaling for Flask App, follow below steps.
    - Comment following part in `flask-app/app.py` file.
      ```python
          if random() < 0.1:
              unfortunate_course_of_events()
      ```
    - Commit and push your code with above changes in a new branch say `test`.
    - Change already deployed flask app's image with new image created for branch `test`.
      ```bash
      $ kubectl set image deployment/flask flask=silly-apps/flask:test --namespace backend
      ```
    - Once the flask app pod is up with new image, run below commands to trigger CPU throttling.
      ```
      $ kubectl port-forward -n backend service/flask 8000
      ```
      Keep above command running in one terminal and in another terminal, run below.
      ```shell
      $ curl "http://localhost:8000/fib?n=30"
      ```
      Above will cause CPU throttling and you'll see new pods for flask app will be started as part of auto-scaling.
  - Monitoring
    - To configure basic cluster monitoring with some useful alerts pre-defined, please refer [monitoring](./monitoring/README.md).
