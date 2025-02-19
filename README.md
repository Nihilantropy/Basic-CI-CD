# Basic-CI-CD
A basic CI/CD project

1) setup docker-compose  with 3 services: jenkins, gitlab and nexus
	 - jenkins will be used for the main ci/cd pipeline
	 - gitlab will store the files on which the pipeline will be exectued everytime a change occurs or when manually requested
	 - nexus will be the hub on which the final docker image will be stored in order to be used on the kubernetes cluster (installed with helm)

2) develop flask-app:
	A simple python app with 2 endopints.
	We need to use the env variable in order to setupt custom values via the template.
	This values will (e.g. agentName) will be set in the values.yaml file, provided by the helm chart
