# IBM Resiliency Orchestration 7.3 Quick Start Guide for EXPRESSCLUSTER X 4.0 (Windows Data mirror)

## About This Guide

This guide provides how to integrate Resiliency Orchestration (RO) 7.3 with EXPRESSCLUSTER X 4.0 (ECX) using mirror disks with 2 nodes. The guide assumes its readers to have EXPRESSCLUSTER X basic knowledge and setup skills.


## System Overview

### System Requirement

- 3 servers are needed.
  - 1 RO server and 2 ECX servers
    - RO server (Linux)
      - RO must be installed on a Linux server.
    - ECX servers (Windows)
      - Having mirror disk
        - At least 2 partitions are required on each mirror disk.
          - Cluster Partition that has volume size of 1024MB.
          - Data Partition that has volume size depending on Database sizing.
  - 3 servers are needed to be IP reachable one another.


### System Configuration

- RO server
  - 1 server
  - CentOS Linux release 7.4.1708 (Core)
    - Kernel version 3.10.0-693.el7.x86_64
  - Resiliency Orchestration 7.3.45171
- ECX servers
  - 2 servers
    - Productive server and Remote server
  - Windows Server 2016 Datacenter
  - EXPRESSCLUSTER X4.0 for Windows

		Sample configuration
		
		                                         <Internet>
		                                          |
		                                          |         Productive Site
		                                          |  +--------------------------+
		                                          +--| Productive Server        |
		                                          |  | - Windows Server 2016    |
		                                          |  | - EXPRESSCLUSTER X 4.0   |
		                                          |  |                          |
		                                          |  | RAM   :  4GB             |
		 +-----------------------------------+    |  | Disk 0: 40GB OS          |
		 | Resiliention Orchestration Server |    |  |      C: local partition  |
		 | - CentOS 7.4                      |    |  | Disk 1: 30GB mirror disk |
		 | - Resiliency Orchestration 7.3    |    |  |      E: cluster partition|
		 |                                   |    |  |      F: mirror partition |
		 | RAM              :  8GB           |    |  +--------------------------+
		 | Boot Disk        :  1GB           +----+
		 | Swap Disk        :  4GB           |    |
		 | RO Install Disk  : 40GB           |    |          Remote Site
		 +-----------------------------------+    |  +--------------------------+
		                                          +--| Remote Server            |
		                                          |  | - Windows Server 2016    |
		                                          |  | - EXPRESSCLUSTER X 4.0   |
		                                          |  |                          |
		                                          |  | RAM   :  4GB             |
		                                          |  | Disk 0: 40GB OS          |
		                                          |  |      C: local partition  |
		                                          |  | Disk 1: 30GB mirror disk |
		                                          |  |      E: cluster partition|
		                                          |  |      F: mirror partition |
		                                          |  +--------------------------+
		                                          |

#### ECX configuration

- Failover Group: `failover`
	- Group resource
		- fip               : floating IP address resource
		- md                : mirror disk resource

- Monitor resource
	- fipw1             : floating IP monitor resource
	- mdnw1             : mirror connect monitor resource
	- mdw1              : mirror disk monitor resource
	- userw             : user-mode monitor resource


#### RO configuration

- 1 Application Group that includes 1 recovery group.
    - AppGroup: Application Groups
    - ECX     : Recovery Groups
- RO folder path             : `/opt/panaces/`
- Scripts folder path for ECX: `/opt/panaces/scripts/ECX/`


## System setup

### Install and setup EXPRESSCLUSTER X

1. Install EXPRESSCLUSTER X
2. Register ECX licenses
    - EXPRESSCLUSTER X 4.0 for Windows
    - EXPRESSCLUSTER X Replicator 4.0 for Windows
3. Create a cluster and a failover group
    - Failover Group: failover
        - fip: floating IP resource
        - md : mirror disk resource
4. Start a group on Productive server


### Install Resiliency Orchestration

Please refer to `IBM Resiliency Orchestration 7.3 Installation Guide.pdf`.


### Allow ECX servers to communicate with RO server via WMI

Please refer to page 55 in `IBM Resiliency Orchestration 7.3 Installation Guide.pdf`. (Enabling WMI on Windows subsystem)


### Copy the custom script to each servers

1. Create a folder `/opt/panaces/scripts/ECX` on RO server
2. Copy **ECX_RepInfo.tcl** to `/opt/panaces/scripts/ECX` on RO server
3. Change permission of **ECX_RepInfo.tcl** to 777
4. Edit **fip** and **port** in **ECX_RepInfo.tcl**
	- **fip** is the floating IP address in ECX cluster
	- **port** is the port to communicate with ClusterManager
5. Copy **checkstatus.bat** and **movegrp.bat** to ECX servers
    - You can copy scripts to anywhere in ECX servers


### Create Production Site and Remote Site on RO dashboard

The below steps is how to create Site.

You need to follow the below steps twice to create Production Site and Remote Site.

1. Click **Discover**
2. Mouse over **Discover >**
3. Select **Sites**
4. Click **Create New Site**
5. **Create New Site:**
    - Input **Site Name** and **Site Address**


### Create Component Subsystems

The below steps is how to create Component Subsystem.

You need to follow the below steps twice to register Production server and Remote server.

1. Click **Discover**
2. Mouse over **Discover >**
3. Select **Subsystems**
4. Select **Create new Windows**
5. Click **Go**
6. **New Component Discovery**
    - Input **IP Address**
    - Input **Name**
    - Select Production Site or Remote Site as **Component Site**
    - Select **Add new credential**
        - Input Administrator to **User Name**
        - Input the password of Administrator to **Password**
7. Click **Save**


### Create Recovery Group

1. Click **Discover**
2. Click **Discover Recovery Group**
3. **Group Details**
    - Input **Group Name**
    - Select **VM Replication with OtherReplicator** as **Solution Signature**
    - Input EXPRESSCLUSTER X as **Other_Replicator**
4. **Define Group Relationship**
    - **Server Component**
        - Select Production server as **PRIMARY COMPONENT**
        - Select Remote server as **REMOTE COMPONENT**
    - **Network Component**
        - Select Production server as **PRIMARY COMPONENT**
        - Select Remote server as **REMOTE COMPONENT**
    - **Configuration Details : Name**
        - **License**
            - Select **Recovery [Management, Monitoring]**
            - Click **Save**
5. Click **Finish**
6. Click tool icon (Change Continuity) in **Action**
7. Click **Manage Group**
8. Click **OK**


### Create Application Group

1. Click **Discover**
2. Click **Discover Application Group**
3. **Organization Selection**
    - Click **Next**
4. **Application Group Details**
    - Input **Application Group Name**
    - Select **Recovery Gruops**
        - Select the recovery group
        - Click **>>**
5. **Create Recovery Order - Name**
    - Drag and drop **Application Group Name** to **Recovery Order**
6. **Application Group Details**
    - Input **Configured RTO** and **Configured RPO**
7. Click **Finish**
8. Click tool icon (Change Continuity) in **Action**
9. Click **Manage Group**
10. Click **OK**


### Edit BCO Workflows of Recovery Group

The below steps is how to show a list of BCO Workflows.

1. Click **Manage**
2. Click a group name that you want to edit
3. Click **View all workflows**

You need to edit BCO Workflows by clicking a pen icon and publish the workflow.

A workflow consists of some actions.

You can edit an action by double-clicking the action icon.


1. **NormarlFullCopy**

    It is needless to edit a workflow because EXPRESSCLUSTER copies data on a mirror disk constantly.
    
    Only publishing is needed.
    
    - Click **Next**
    - Click **Publish Workflow**


2. **Failover**

    - 1st action: Check status of a Productive server
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select a Productive server as **Server/Machine Name**
            - Select **Script** as **Type Of Custom Action**
            - Input the path of **checkstatus.bat** as **Command/Script to be executed with absolute path**
    - 2nd action: Check status of a Remote server
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select a Remote server as **Server/Machine Name**
            - Select **Script** as **Type Of Custom Action**
            - Input the path of **checkstatus.bat** as **Command/Script to be executed with absolute path**
    - 3rd action: Group failover
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select a Productive server as **Server/Machine Name**
            - Select **Script** as **Type Of Custom Action**
            - Input the path of **movegrp.bat** as **Command/Script to be executed with absolute path**
    - Click **Export** to export the workflow xml data
    - Click **Next**
    - Click **Publish Workflow**


3. **Failback**

    - 1st action: Check status of a Remote server
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select a Remote server as **Server/Machine Name**
            - Select **Script** as **Type Of Custom Action**
            - Input the path of **checkstatus.bat** as **Command/Script to be executed with absolute path**
    - 2nd action: Check status of a Productive server
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select a Productive server as **Server/Machine Name**
            - Select **Script** as **Type Of Custom Action**
            - Input the path of **checkstatus.bat** as **Command/Script to be executed with absolute path**
    - 3rd action: Group failback
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select a Remote server as **Server/Machine Name**
            - Select **Script** as **Type Of Custom Action**
            - Input the path of **movegrp.bat** as **Command/Script to be executed with absolute path**
    - Click **Export** to export the workflow xml data
    - Click **Next**
    - Click **Publish Workflow**


4. **FallbackResync

    It is needless to edit a workflow because EXPRESSCLUSTER copies data on a mirror disk constantly.
    
    Only publishing is needed.
    
    - Click **Next**
    - Click **Publish Workflow**


### Edit BP Workflow of Recovery Group

- **ReplicationInfoWorkflow**

    - 1st action: Execute the custom script to calculate RPO
        - **Run-time settings**
            - Input **Name** and **Description**
        - **Action Properties**
            - Select **AgentNode** as **Server/Machine Name**
            - Select **IBM Resiliency Orchestration Integration Tcl Script** as **Type Of Custom Action**
            - Input `/opt/panaces/scripts/ECX/ECX_RepInfo.tcl` as **Command/Script to be executed with absolute path**
    - Click **Next**
    - Click **Publish Workflow**


### Execute BCO Workflows of Recovery Group

After executing 4 BCO workflows that you created in the previous steps, the RTO is displayed on RO dashboard.

The below steps is how to execute BCO workflows.

1. Click **Manage**
2. Click a group name
3. Click **Execute** in **Continuity Workflows**


### Execute BP Workflow of Recovery Group

**ReplicationInfoWorkflow** is executed every 10 minutes automatically to calculate RPO.

After executing the workflow, the RPO is displayed on RO dashboard.


### Edit BCO Workflows of Application Group

1. **Failover**
    - Click **Add    >**
    - Select **Workflows**
    - Click **Import Workflow**
    - Select the workflow of **Failover** that you exported in the previous steps

2. **Failback**
    - Click **Add    >**
    - Select **Workflows**
    - Click **Import Workflow**
    - Select the workflow of **Failback** that you exported in the previous steps


### Execute BCO Workflows of Application Group

Execute **Failover** and **Failback** to display the RTO on RO dashboard.


### Edit Drill Workflows of Application Group

The below steps is how to show a list of Drill Workflows.

1. Click **Drill**
2. Click **Summary**
3. Click a group name that you want to edit

For example, if you want to execute a simple failover test, you should edit **Switchover**.


### Execute Drill Workflows of Application Group

1. Click **Drill**
2. Click **Summary**
3. Click a group name
4. Click **Execute**


----
2019.03.27	Ogata Yosuke <y-ogata@hg.jp.nec.com>	1st issue
