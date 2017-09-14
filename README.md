# Securing Mesos Clusters

In these exercises, we will walk you through launching a Mesos master and agent, as well as an example framework (mesos-execute), under different security configurations, starting with the default insecure config and enabling each security feature as we go.

## Prerequisites

- You may want to prefetch the following docker images:
```
docker pull netflixoss/exhibitor:1.5.2
docker pull mesosphere/mesos-master:1.4.0-rc5
docker pull mesosphere/mesos-slave:1.4.0-rc5
```

## Exercises

0. Default configuration (insecure)
   - Start the basic cluster, with exhibitor/ZK, mesos-master, and mesos-agent.
   ```
   cd scripts
   ./insecure_cluster_start.sh
   ```
   - Run `docker ps` to see all three running.
   - Run insecure mesos-execute using `./insecure_run_command.sh`
   - Verify that mesos-execute subscribed, ran and finished successfully.
   ```
Subscribed with ID 01a2c4f7-3059-41b6-958e-cc8f1787b60c-0002
Submitted task 'foo' to agent '01a2c4f7-3059-41b6-958e-cc8f1787b60c-S0'
Received status update TASK_RUNNING for task 'foo'
Received status update TASK_FINISHED for task 'foo'
  message: 'Command exited with status 0'
   ```

1. Encryption required

   - stop master/agent/framework
   - start SSL-enabled master
   - start agent without SSL, fails to connect
   - restart agent with SSL, see that it connects
   - run insecure mesos-execute, fails to register
   - run secure mesos-execute sched, registers, but executor/task fails
   - run secure mesos-execute with task SSL env

1. Agent authentication

   - start secure master, require agent authN
     MESOS_AUTHENTICATE_AGENTS={{ agent_authentication_required }}
     MESOS_CREDENTIALS
   - start agent, fails to register
   - start agent with authN + credential
     MESOS_CREDENTIAL=file:///path/to/agent_principal.json

1. Framework authentication
   - MESOS_AUTHENTICATE_FRAMEWORKS={{ framework_authentication_required }}

<!---
1. Authorization

   ```
   MESOS_ACLS
   ```

1. HTTP authentication

   ```
   MESOS_AUTHENTICATE_HTTP_READWRITE={{ mesos_authenticate_http }}
   MESOS_AUTHENTICATE_HTTP_READONLY={{ mesos_authenticate_http }}
   ```
--->

## Notes/TODO
- TODO: only kill docker images we create
- No LIBPROCESS_SSL_CA_DIR (cannot verify certs)

## Out of scope:
- Building custom authN/Z modules (lengthy compiles)
- Secret generator/resolver
- Firewall rules (disabling endpoints)
