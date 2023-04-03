# INIT

## Minion initialization

This folder tries to orchestrate one or more minions initialization after its instance was created in the cloud. It installs 
network-manager, defines the virtual network(s) of the minions and its ip addresses if not dhcp enabled, its proxy configuration 
if used, installs or enables distribution repos.

You should call the orchestration with a command line like this

...
\# sudo salt-run state.orchestrate init pillar='{minions: \[m1, m2, m3\]}'
...

## Steps executed


### os_specific

This is a folder whose init.sls calls a state in the same folder that has the same name of the grains['os'] of the minion.
This state is run in the minion.

The folder init.sls has the following code:

...
\## note to me: path always from salt-base
{% set filename = grains.os_family | lower() %}
{% include 'init/os_specific/' + filename + '.sls' ignore missing %}
...


### networkmanager.sls

This state installs and takes the necessary steps so that Network Manager service manages all minions interfaces. 
This state is run in the minion.


### proxy.sls

This state checks if host pillar value **proxy** is not equal _none_ and then configures proxy settings for yum/apt and 
the salt minion.
This state is run in the minion.


### pacotes_basicos.sls

This state installs packages that are needed to the next steps.
This state is run in the minion.


### sdb_drivers.sls

This states configures sdb_drivers that will be used in the next steps or in other states.
This state is run in the minion


### sync_all

Sync modules/states/utils etc to the minion
This state is run in the master.


### define_interfaces.sls

This state checks if host pillar value **redefine_interfaces** is true and then uses host pillar dict **interfaces** to 
redefine the minion network virtual interfaces. 
This state is run in the pillar value (defined in **organization.sls** but can be overriden in the host pillar) **virtual_host**.


### set_extraips.sls

This states check the host pillar dict **interfaces** and configures static ip for the network virtual interfaces whose **dhcp** 
pillar value is true.
This state is run in the minion.

### set_ip.sls

This states configures static ip setting if the minion does not redefines interfaces and if the host pillar value **dhcp** is false.
This state is run in the minion.



