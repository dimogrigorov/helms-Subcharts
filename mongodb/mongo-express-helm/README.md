# This helm chart can be use for installing mongo-express on OCP 4.x

## Prerequisites
The chart must be installed in same namespace where mongodb replicaset has been installed.

### Create required secrets
oc create secret generic me-cred --type=basic-auth --from-literal=username="ME_CONFIG_BASICAUTH_USERNAME" --from-literal=password="ME_CONFIG_BASICAUTH_PASSWORD" --dry-run=client -o yaml |oc apply -f -

Set as value "ME_CONFIG_MONGODB_ADMINUSERNAME" - mongodb root user.
Specify secret name and secret key used by mongodb replicaset for admin credentials (ME_CONFIG_MONGODB_ADMINPASSWORD)

## Deployment
helm upgrade mongo-express mongo-express-0.1.0.tgz --install --values values.yaml
