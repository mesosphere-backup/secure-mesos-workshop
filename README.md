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

1. [Encryption](https://mesos.apache.org/documentation/latest/ssl/)

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

1. Agent [authentication](https://mesos.apache.org/documentation/latest/authentication/)

   - Modify `cluster_start.sh` to configure the allowed credentials.
   ```
   MESOS_CREDENTIALS="file:///etc/credentials/credentials.json"
   ```
   Mount the prepopulated credentials file (modify it if you like) into the `mesos-master` container.
   ```
   -v "$(pwd)/credentials:/etc/credentials"
   ```
   And require agent authentication on the master.
   ```
   MESOS_AUTHENTICATE_AGENTS=1
   ```
   - Now if you run `cluster_start.sh`, the master will start successfully, but the agent will be unable to authenticate (debug in the agent log).
   ```
   I0914 slave.cpp:971] New master detected at master@127.0.0.1:5050
   I0914 slave.cpp:995] No credentials provided. Attempting to register without authentication
   I0914 slave.cpp:885] Agent asked to shut down by master@127.0.0.1:5050 because 'Agent is not authenticated'
   ```
   - Now modify `cluster_start.sh` to configure the agent to load its authentication credential.
   ```
   MESOS_CREDENTIAL="file:///etc/credentials/credential.json"
   ```
   The `mesos-agent` container will also need to mount the credentials directory.
   ```
   -v "$(pwd)/credentials:/etc/credentials"
   ```
   - Now when you run `cluster_start.sh`, the agent will successfully authenticate and register.
   ```
	 I0914 slave.cpp:971] New master detected at master@127.0.0.1:5050
	 I0914 slave.cpp:1033] Authenticating with master master@127.0.0.1:5050
	 I0914 slave.cpp:1044] Using default CRAM-MD5 authenticatee
	 I0914 slave.cpp:1128] Successfully authenticated with master master@127.0.0.1:5050
	 I0914 slave.cpp:1174] Registered with master master@127.0.0.1:5050; given agent ID 792cd31b-18ee-4fb6-aef1-01d998e691aa-S0
   ```

1. Framework [authentication](https://mesos.apache.org/documentation/latest/authentication/)
   - The master is already configured with allowed credentials (applies to agent, framework, and HTTP authentication), so all that's left is to require framework authentication on the master. Let's enable this for both v0 and v1 (HTTP) frameworks. V1 also requires us to select an authenticator, so we'll use the default `basic` authenticator. Other authenticators may be loaded via Mesos modules.
   ```
   MESOS_AUTHENTICATE_FRAMEWORKS=1
   MESOS_AUTHENTICATE_HTTP_FRAMEWORKS=1
   MESOS_HTTP_FRAMEWORK_AUTHENTICATORS=basic
   ```
   - Now if you run `cluster_start.sh` and view the master log, you will notice that agent, framework, and http framework authentication are all required.
   ```
   I0914 master.cpp:494] Master only allowing authenticated frameworks to register
   I0914 master.cpp:508] Master only allowing authenticated agents to register
   I0914 master.cpp:521] Master only allowing authenticated HTTP frameworks to register
   I0914 credentials.hpp:37] Loading credentials for authentication from '/etc/credentials/credentials.json'
   ```
   - If you try `run_command.sh` without authentication, you will see it fail to subscribe.
   ```
   I0914 19:34:11.941700    14 scheduler.cpp:470] New master detected at master@127.0.0.1:5050
   E0914 19:34:12.210691     9 execute.cpp:666] EXIT with status 1: Received an ERROR event: Received unexpected '401 Unauthorized' () for SUBSCRIBE
   ```
   - To enable authentication in `mesos-execute`, you need to set the `--principal` and `--secret` flags as described in https://github.com/apache/mesos/blob/1.4.0-rc5/src/cli/execute.cpp#L311-L317
   - For your own frameworks, make sure that you're setting `FrameworkInfo.principal` and passing the credential (principal + secret) on to the MesosSchedulerDriver (v0) or as part of the Subscribe message (v1). See the source for `mesos-execute` for an example: https://github.com/apache/mesos/blob/1.4.0-rc5/src/cli/execute.cpp#L1126-L1135


1. [Authorization](https://mesos.apache.org/documentation/latest/authorization/)

   ```
   MESOS_ACLS=...
   ```

1. HTTP authentication

   ```
   MESOS_AUTHENTICATE_HTTP_READWRITE=true
   MESOS_AUTHENTICATE_HTTP_READONLY=true
   ```

## TODO
- TODO: Explain how to get to the webui, including agent UI for sandbox access
- TODO: only kill docker images we create

## Out of scope:
- No Certificate authority (LIBPROCESS_SSL_CA_DIR) signing the certs, so we cannot verify them.
- Building custom authN/Z modules (lengthy compiles)
- Secret generator/resolver
- Firewall rules (disabling endpoints)
