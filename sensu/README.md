# Sensu architecture
Sensu has 4 basic components: daemons, subscriptions, checks, assets, and handlers. It
also runs two types of daemons. 

## Daemons
The first is sensu-backend which is the control service. `sensuctl` commands
connect to the http api port of sensu-backend. It also has a basic dashboard
served over http and a websocket port. The second type of daemon is a
sensu-agent.  This is a lightweight go daemon that connects to the backend
websocket port and subscribes to subscriptions. Because the agents are
lightweight and by default we run them out of alpine containers, they should
have minimal overhead when adding it as a rider to pods.

## Subscriptions
Subscriptions are just tags specified on each sensu-agent that tell it what
checks apply to it. When you create a check you specify subscriptions it should
apply to and when you start a client you specify subscriptions it should
respond to.

## Checks
A check describes a command an agent should run. These are nagios compliant
check commands. The binary is typically stored as an asset. One such check we
use is the node-prometheus check, which uses the prometheus node-exporter to
collect metrics.

    api_version: core/v2
    type: CheckConfig
    metadata:
      namespace: kubernetes
      name: node-prometheus
    spec:
      runtime_assets:
      - prometheus-collector
      command: sensu-prometheus-collector -exporter-url http://$HOST_IP:9100/metrics
      subscriptions:
      - daemonset
      publish: true
      interval: 10
      output_metric_format: influxdb_line
      output_metric_handlers:
      - influxdb

This tells every agent with the subscription "daemonset" to run the command
specified every 10 seconds and that it will format metrics for influxdb. The
`sensu-prometheus-collector` already outputs the metrics in the sensu format,
the format field here is telling sensu how to handle this.

## Assets
One of the most interesting parts of the sensu architecture is that a well
designed system can have subscriptions manage the entire process. An asset is a
tarball that's distributed by sensu-backend to agents that need it. Each check
runs with whatever runtime assets are specified.

    api_version: core/v2
    type: Asset
    metadata:
      namespace: kubernetes
      name: prometheus-collector
    spec:
      url: https://github.com/sensu/sensu-prometheus-collector/releases/download/1.1.4/sensu-prometheus-collector_1.1.4_linux_amd64.tar.gz
      sha512: 8d2a5ea6d97818f0da97e8bcf1f2ca765d7acb890dba0682dd35cc6f09714da59b7e974d7f8dbaba507fefa2104b3e145bd31f924fdf154b8870892d0afb4767

## Handlers
On the other side of the checks are the handlers. These collect events
(typically a metric or check result) and process them some how. This could be
sending a slack alert or putting the data in the database. The are very similar
to checks, but operate in reverse from a data flow perspective and always
execute on the backend.

    api_version: core/v2
    type: Handler
    metadata:
      namespace: kubernetes
      name: influxdb
    spec:
      type: pipe
      runtime_assets:
      - influxdb-handler
      command: sensu-influxdb-handler -a 'http://influxdb.sensu.svc.cluster.local:8086' -d sensu -u sensu -p password
      timeout: 10
      filters:
      - has_metrics
