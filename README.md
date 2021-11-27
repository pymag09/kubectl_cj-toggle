# cj-switch

This is the plugin for kubectl which is prepared to be installed with `krew`.  
First and foremost this tool is for people who like CLI. You can do a lot with k9s, Lens etc. but what could be better than pure CLI.

## About the plugin

If you have significant amount of cronjobs, moreover they are spread across multiple namespaces and you need disable/enable all or some of them for some reason, you can do this by using the plugin. Kubernetes cluster that is running bunch of cronjobs is absolutely possible and normal scenario. When arbitrary service has an issue which can affect dependant microservices, you might want to put on hold all cronjobs which do synchronizations for example.

---

Default behavior of cj-switch is inverting the 'spec.suspend' value of a cron job ('True' turns to 'False' and vice versa). It is also possible to set 'spec.suspend' to True or False explicitly. If you need to preserve previous state and revert it later, please use -f key (for instance when some jobs are suspended, some are not).

### Usage: cj-switch

```
    -A, --all-namespaces: If present, list the requested object(s) across all namespaces.
                          Namespace in current context is ignored even if specified with --namespace.
    -n, --namespace='':   If present, the namespace scope for this CLI request
    -h, --help:           This page
    -l, --selector='':    Selector (label query) to filter on, supports '=', '==', and '!='.(e.g. -l key1=value1,key2=value2)
    -r:                   Restore previous state from file. Works in conjunction with -f
    -f:                   Save current state to file.
    -s:                   Disable or enable cron job. Possible values [true|True|False|false].
```
