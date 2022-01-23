# cCBD

### Design and architecture

Visit https://confluence.secure.ifao.net/display/TCA/cCBD%3A%3A+Technical+Specification

###### Contact
Team email: Quintessa@amadeusworkplace.onmicrosoft.com

### Build status
Master: 
[![Build Status](https://jenkins-pipeline-tchtne.cicd.rnd.amadeus.net/job/IFAO-SW2/job/CCBD/job/ccbd/job/master/badge/icon)](https://jenkins-pipeline-tchtne.cicd.rnd.amadeus.net/job/IFAO-SW2/job/CCBD/job/ccbd/job/master/)

### Build steps

#### Generate artifacts (inclusive of tests)
```
   cd <ccbd-cloned-repo-folder>
   mvn clean install
      -- or --
   mvn clean package
```
#### Generate artifacts excluding Junit tests
```
mvn clean install -DskipTests
```

> For code coverage report visit `/target/site/jacoco/index.html`
#### Generate test report
 ```
   cd <ccbd-cloned-repo-folder>
   mvn clean surefire-report:report
 ```
> For test report visit `/target/site/jacoco/index.html`

#### Generate Site report
```
   cd <ccbd-repo-folder>
   mvn clean site
```
> For site details, visit `/target/site/summary.html` or select the appropriate report in the same folder.

#### Generate Object Exchange schema
When the file `'/dtd/ObjectExchange4.dtd'` has a change, run the following maven task and the resulting DTD file in
`'/src/main/resources/xsd/ObjectExchange4_final.xsd'` has to be commited to git.
```
   mvn exec:exec
   mvn clean install
```    
>`exec:exec` is used to run the execution for generating the XSD from DTD file

### Java optimization properties
`JAVA_OPTS` properties set in the pods for optmial performance:
```
-Xss256k -Xms1G -Xmx4G -XX:+UseG1GC -XX:MaxGCPauseMillis=2000 -XX:+OptimizeStringConcat -XX:+UseStringCache -XX:MinHeapFreeRatio=40 -XX:MaxHeapFreeRatio=70 -XX:+UseStringDeduplication
```
Adjust the min and max JVM memory allocation variables according to the pod configuration.

### Java code formatting
###### IDE configuration
For IDE configuration [Eclipse , Intellij] please find the details here: https://confluence.secure.ifao.net/x/kDkUE

Once IDE is properly configured, please right-click and run the Jindent on the modified file, before commit.

###### Git hooks
Configure the git with pre-commit hooks that automates the indentation process as part of the commit. So when the dev trys to commit, pre-commit 
hooks are applied by default [this can be changed], and jident is run on the files [java only] that are committed. This ensures all the java files 
are following the indentation rules.
Steps to configure:
- configure the Jident in the runtime environment: https://confluence.secure.ifao.net/display/cytric/Jindent+for+Windows+-+Automatic+Indention+of+Java+Code#JindentforWindowsAutomaticIndentionofJavaCode-AutomateJindentwithGitHooks(RunJindentatcommitstime).1
- copy the following file to the folder: `ccbd\.git\hooks`
  - `scripts/git-hooks/commit-msg`
  - `scripts/git-hooks/pre-commit`

Once configured, pre-commit hooks are automatically applied while committing. For Intellij, we get the following checkbox: `Run Git hooks`, 
under "Before commit". Once the pre-commit hook run, the java files are Jindented [if required].

> The commit will fail if there is any jindent required. Commit and push, again and the files will be committed succussfully.


### Application Metrics
This application uses micrometer to publish metrics via actuator endpoint /actuator/prometheus. 

[C] - counter

[G] - gauge

[T] - timer

1. BookingEvent Listener to RabbitMQ
    * ccbd.listener.booking_event.received [C] - when a booking event is received
    * ccbd.listener.booking_event.duplicate [C] - when a duplicate booking event is received - a check done before save
    * ccbd.listener.booking_event.saved [C] - when a booking event is saved (multiple entries if multiple endpoints available)
    * ccbd.listener.booking_event.exception [C] - when message handle fails
        * tag: exception
        * value: parse_failed - when message parsing fails - probably issue with contract
        * value: db_connection - when mongo exception is thrown while saving a booking event 
        * value: unknown - when an unknown exception is thrown while saving a booking event 

2. ConfigEvent Listener
    * ccbd.listener.config_event.received [C] - when a config event is received
    * ccbd.listener.config_event.duplicate [C] - when a duplicate config is received
    * ccbd.listener.config_event.deleted [C] - when a config is received with changes, it is delete and insert operation
        * tag: system
        * value: <system_name> 
    * ccbd.listener.config_event.saved [C] - when a config is received
    * ccbd.listener.config_event.exception [C] - when message handle fails
        * tag: exception
        * value: parse_failed - when message parsing fails - probably issue with contract
        * value: mongo - when an exception is thrown while saving a config event 
        * value: unknown - when an unknown exception is thrown while saving a config event 

3. Send message to cCBD subscribers process
    * ccbd.scheduled.sendmessage [C] - When the scheduled task is initiated
    * ccbd.scheduled.sendmessage.system_endpoints.in_progress_send_failed [G] - Important! displays current number of system endpoints where process is in_progress or send_failed. Why is it important, the booking event belongs to these pairs will not be processed at the moment
    * ccbd.scheduled.sendmessage.booking_event_found [C] - when booking event is selected to process
    * ccbd.scheduled.sendmessage.booking_event_not_found [C] - when no booking event found to process -  {ccbd.scheduled.sendmessage = ccbd.scheduled.sendmessage.booking_event_found + ccbd.scheduled.sendmessage.booking_event_not_found} 
    * ccbd.scheduled.sendmessage.http.bookingdata.success [C]
    * ccbd.scheduled.sendmessage.http.bookingdata.error [C] -  {ccbd.scheduled.sendmessage.booking_event_found = ccbd.scheduled.sendmessage.http.bookingdata.success + ccbd.scheduled.sendmessage.http.bookingdata.error}
        * tag: error
        * value: 4xx5xx - when a client or server error is thrown
        * value: ConnectTimeoutException - when webservice request connection failed
        * value: ReadTimeoutException - when http connection to cytric read timeout
        * value: NotSslRecordException - when http request is made without sslcontext
        * value: SSLHandshakeException - when ssl handshake failed. One common scenario is that request does not contain valid issuer certificate
        * value: UnknownHostException - when IP address of host cannot be determined
        * value: unidentified exception(s) - there could be other exceptions 
    * ccbd.scheduled.sendmessage.config_available [C] - when config for system is available in DB
    * ccbd.scheduled.sendmessage.config_not_available [C] - when configuration data is not available in application -  {ccbd.scheduled.sendmessage.http.bookingdata.success = ccbd.scheduled.sendmessage.config_available + ccbd.scheduled.sendmessage.config_not_available}
        * tag: system
        * value: <system>
    * ccbd.scheduled.sendmessage.format.success [C] - {ccbd.scheduled.sendmessage.config_available = ccbd.scheduled.sendmessage.format.success}
    * ccbd.scheduled.sendmessage.http.ext.success [C]
        * tag(2): system
        * value: <system> 
        * tag(3): routing
        * value: <routing-endpoint-url> 
    * ccbd.scheduled.sendmessage.http.ext.error [C] - {ccbd.scheduled.sendmessage.format.success = ccbd.scheduled.sendmessage.http.ext.success + ccbd.scheduled.sendmessage.http.ext.error}
        * tag(1): error
        * value: 4xx5xx - when a client or server error is thrown
        * value: ConnectTimeoutException - when webservice request connection failed
        * value: ReadTimeoutException - when http connection to cytric read timeout
        * value: NotSslRecordException - when http request is made without sslcontext
        * value: SSLHandshakeException - when ssl handshake failed. One common scenario is that request does not contain valid issuer certificate
        * value: UnknownHostException - when IP address of host cannot be determined
        * value: unidentified exception(s) - there could be other exceptions
        * tag(2): system
        * value: <system> 
        * tag(3): routing
        * value: <routing-endpoint-url> 
    * ccbd.scheduled.sendmessage.completed [C] - when the booking-event is successfully accepted received by the ext system - {ccbd.scheduled.sendmessage.http.ext.success = ccbd.scheduled.sendmessage.completed + ccbd.scheduled.sendmessage.rejected} 
    * ccbd.scheduled.sendmessage.rejected [C] - when the booking-event is rejected by the ext system (rejected status in the response or due to any of external system endpoint request failure )
    * ccbd.scheduled.sendmessage.exception [C] - when an unknown exception is thrown while processing booking event
        * tag: exception
        * value: unknown 
                
4. Reset send failed process
    * ccbd.scheduled.reset_sendfailed.booking_event.length [G] - current number of booking events with send_failed status (eligibility to reset depends on config property scheduler.resetSendFailedMinutesAfter or scheduler.extsystem.<system>.<endpoint>.resetSendFailedMinutesAfter)
    * ccbd.scheduled.reset_sendfailed.reset [C] - number of booking events' status reset to ready from send_failed 
    
5. Reset in progress to ready
    * ccbd.scheduled.reset_inprogress.booking_event.length [G] - current number of booking events with in_progress status (eligibility to reset depends on config property scheduler.resetInProgressMinutesAfter)
    * ccbd.scheduled.reset_inprogress.reset [C] - number of booking events' status reset to ready from in_progress
    
6. Reset bookingdata notreceived to ready
    * ccbd.scheduled.reset_bookingdata_notreceived.booking_event.length [G] - current number of booking events with booking_data_not_avaiable status (eligibility to reset depends on config property scheduler.resetBookingDataNotReceivedMinutesAfter)
    * ccbd.scheduled.reset_bookingdata_notreceived.reset [C] - number of booking events' status reset to ready from bookingdata_notreceived
    
7. Timed
    * reactor_flow_duration_seconds{flow="ccbd.scheduled.sendmessage.mono"} [Count, Sum, Max] - time taken for reactor flow, sendmessageToSubscribers per each exception
    * method_timed_seconds{method="ccbd.scheduled.sendMessageToSubscribers.async"} [Count, Sum, Max] - time taken to execute scheduled task to reset_in_progress_to_ready
    * method_timed_seconds{method="ccbd.scheduled.reset_inprogress.async"} [Count, Sum, Max] - time taken to execute scheduled task to reset_in_progress_to_ready
    * method_timed_seconds{method="ccbd.scheduled.reset_sendfailed.async"} [Count, Sum, Max] - time taken to execute scheduled task to reset_send_failed_to_ready
    * method_timed_seconds{method="ccbd.scheduled.reset_bookingdata_notreceived.async"} [Count, Sum, Max] - time taken to execute scheduled task to reset_send_failed_to_ready
        
8. RabbitMQ
    * rabbitmq_rejected_total [C]
    * rabbitmq_acknowledged_published_total [C]
    * rabbitmq_not_acknowledged_published_total [C]
    * rabbitmq_channels [G]
    * rabbitmq_connections [G]
    * rabbitmq_failed_to_publish_total [C]
    * rabbitmq_unrouted_published_total [C]
    * rabbitmq_acknowledged_total [C]
    * rabbitmq_published_total [C]
    * rabbitmq_consumed_total [C]
    * spring_rabbitmq_listener_seconds{listener_id="bookingEventsReceiver"} [Count, Sum, Max]
    * spring_rabbitmq_listener_seconds{listener_id="configEventsReceiver"} [Count, Sum, Max]


### Tips to dashboard development

* Use wild card in query to get total count across systems
* Use `iterate` for count in timed window
