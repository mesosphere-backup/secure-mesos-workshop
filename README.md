# Securing Mesos Clusters

In these exercises, we will walk you through launching a Mesos master and agent, as well as an example framework (mesos-execute), under different security configurations, starting with the default insecure config and enabling each security feature as we go.

## Exercises
0. Default (insecure)

   - start exhibitor
   - start insecure master
   - start insecure agent
   - run insecure mesos-execute
  
1. SSL

   - stop master/agent/framework
   - start SSL-enabled master
   - start agent without SSL, fails to connect
   - restart agent with SSL, see that it connects
   - run insecure mesos-execute, fails to register
   - run secure mesos-execute sched, registers, but executor/task fails
   - run secure mesos-execute with task SSL env
  
2. Agent authentication

   - start secure master, require agent authN
     MESOS_AUTHENTICATE_AGENTS={{ agent_authentication_required }}
     MESOS_CREDENTIALS
   - start agent, fails to register
   - start agent with authN + credential
     MESOS_CREDENTIAL=file:///path/to/agent_principal.json
    
3. Fwk authentication
   - MESOS_AUTHENTICATE_FRAMEWORKS={{ framework_authentication_required }}

4. ACLs

   ```
   MESOS_ACLS
   ```

5. HTTP authentication

   ```
   MESOS_AUTHENTICATE_HTTP_READWRITE={{ mesos_authenticate_http }}
   MESOS_AUTHENTICATE_HTTP_READONLY={{ mesos_authenticate_http }}
   ```

## Notes/TODO
- only kill docker images we create
- No LIBPROCESS_SSL_CA_DIR (cannot verify certs)

## Out of scope:
- Building custom authN/Z modules (lengthy compiles)
- Secret generator/resolver
- Firewall rules (disabling endpoints)
