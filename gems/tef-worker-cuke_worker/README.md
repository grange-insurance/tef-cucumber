Cuke Worker
=========

Cuke Worker is a Worker that is specifically designed to work cucumber tasks.


A Cucumber Worker's view of a task
=========

Below is an example Cucumber task. Cucumber tasks include additional information regarding how to run a Cucumber test.

```json      
  {
    "type":       "task",
    "task_type":  "cucumber",
    "guid":       "12345",
    "resources":  ["resource_1","resource_2"],
    "task_data":  {"cucumber_options": {"file_paths": ["tests/live/here/foo.feature:17"],
                                        "options": "--quiet"},
                   "root_location": "path/to/root",
                   "working_directory": "tests/run/here",
                   "gemfile": "tests/gemfile"},
    "suite_guid": "123456",
    "priority":   "7"
  }
```
