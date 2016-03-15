# *TEF Cucumber* (a Cucumber extensions for the Task Execution Framework) 


## About
This gem provides extensions to the [**Task Execution Framework**](https://github.com/grange-insurance/tef-cucumber) make it easier to use the TEF to run Cucumber tests. 


## Services
The services below are additions to a basic TEF installation.

 - **Queuebert**  - Breaks down a test suite into individual tests and creates special cucumber tasks for them.       
 - **CukeWorker** - A specialized worker type that is aware of Bundler gemfiles and uses a special Cucumber formatter for test output.
 - **CukeKeeper** - A specialized keeper that will store the result of a Cucumber task in a database.
  
For information on how to set up each service, see the documentation for each service.
 
 - [**Queuebert**](https://github.com/grange-insurance/tef-cucumber/tree/master/gems/tef-queuebert)
 - [**CukeWorker**](https://github.com/grange-insurance/tef-cucumber/tree/master/gems/tef-worker-cuke_worker)
 - [**CukeKeeper**](https://github.com/grange-insurance/tef-cucumber/tree/master/gems/tef-cuke_keeper)
 
