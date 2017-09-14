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

1. [Encryption](https://mesos.apache.org/documentation/latest/ssl/) required

   - Now let's modify the cluster_start script to encrypt master communications:
     - Generate an SSL keypair (script provided)
     ```
     ./generate_ssl_key_cert.sh
     ```
     - Mount the keypair directory into the mesos-master docker container
     ```
     -v "$(pwd)/ssl:/etc/ssl"
     ```
     - Enable SSL (TLS really), and point to the cert/key
     ```
     LIBPROCESS_SSL_ENABLED=1
     LIBPROCESS_SSL_CERT_FILE=/etc/ssl/cert.pem
     LIBPROCESS_SSL_KEY_FILE=/etc/ssl/key.pem
     ```
   - Run the `cluster_start.sh` script again to tear down the old cluster, start an SSL-enabled master, and watch the agent fail to connect to the master due to the agent's lack of encryption.
   - Now modify the cluster_start script to encrypt agent communications as well, mounting the same keypair directory and configuring the same LIBPROCESS_SSL variables.
   - Run the updated `cluster_start.sh` script again to see the agent successfully connect over SSL.
   - Now that the master and agent are encrypted, run the unmodified `run_command.sh` script and see that `mesos-execute` fails to register since it is not yet encrypted.
   ```
   I0914 scheduler.cpp:470] New master detected at master@127.0.0.1:5050
   E0914 scheduler.cpp:534] Request for call type SUBSCRIBE failed: Connection reset by peer
   ```
   - Now modify the `run_command.sh` script to encrypt the `mesos-execute` scheduler communication, mounting the keypair directory and adding the LIBPROCESS_SSL variables.
   You will see that the scheduler successfully subscribes and gets a frameworkID, but the task it launches fails, since the task executor is not configured to speak SSL back to the agent.
   ```
   Subscribed with ID 64508b54-92cc-4f40-a166-9bc74a58039b-0000
   Submitted task 'foo' to agent '64508b54-92cc-4f40-a166-9bc74a58039b-S0'
   Received status update TASK_FAILED for task 'foo'
     message: 'Executor terminated'
     source: SOURCE_AGENT
     reason: REASON_EXECUTOR_TERMINATED
   ```

   - To fix this, you must also add the LIBPROCESS_SSL variables to the `--env` parameter for the `mesos-execute` command. 
   Since `mesos-execute` runs the command directly (wrapped in a cgroup container, but without a docker container or dedicated filesystem image), you don't need to mount the keypair directory.
   Run the `run_command.sh` script again, and see that the scheduler subscribes, and now the task finishes successfully (exit code `0`).
   ```
   Subscribed with ID 64508b54-92cc-4f40-a166-9bc74a58039b-0001
   Submitted task 'foo' to agent '64508b54-92cc-4f40-a166-9bc74a58039b-S0'
   Received status update TASK_RUNNING for task 'foo'
   Received status update TASK_FINISHED for task 'foo'
     message: 'Command exited with status 0'
   ```

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
- TODO: Explain how to get to the webui, including agent UI for sandbox access
- TODO: only kill docker images we create
- No LIBPROCESS_SSL_CA_DIR (cannot verify certs)

## Out of scope:
- Building custom authN/Z modules (lengthy compiles)
- Secret generator/resolver
- Firewall rules (disabling endpoints)
