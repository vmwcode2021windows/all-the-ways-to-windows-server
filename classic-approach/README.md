# Classic Approach
The classic approach to building a Windows server consists of using vRealize Automation (vRA) in conjunction with vRealize Orchestrator (vRO) and Action Based Extensibility (ABX).

The end result of this solution is a Windows server, with an addtional disk on the E: drive, a specified user in the local administrators group and Notepad++ installed.

## Overview
This solution uses the native features of vRA to build a Windows servers.  There are multiple components that each play an important role in the overall process.

**Component** | **Description**
----------|--------------
Cloud Account | The vCenter where the server will be built
Cloud Zone | The available clusters/hosts for a server build
Project | Represents the group that will have access, permissions are supplied here
Cloud Template | The "blueprint" for the server deployment - consists of the building blocks
Image Mappings | Defines the machine templates to use for a build
Flavor Mappings | Defines the size of a server build (cpu/mem)
Network Profile | Defining available networks and ranges for a deployment
Active Directory Integration | Allows for accounts to be created in AD
Event Broker Subscription | Entry point to into different phases of the build process
ABX Actions | Custom code that can be called by an Event Broker Subscription
vRO Workflows | Custom workflows that can be called by an Event Broker Subscription

## High-level Flow
Without wading into the weeds, these are the steps that make up this classic approach to building a server with vRA
1. The components on the cloud template are processed
1. Based on the tagging strategy, the compute for the server will be chosen
1. Based on tagging, the network for the server will be used
1. The account will be pre-created in Active Directory
1. The server will be provisioned in vCenter and join Active Directory
1. An account will be added to the local admin group with a vRO workflow
1. The attached disk will be intialized/formatted with an ABX action
1. Notepad++ will be installed on the server with a vRO workflow

## Cloud Template
The cloud template consists of three objects:
* Cloud.vSphere.Machine
* Cloud.vSphere.Network
* Cloud.vSphere.Disk

There are three inputs definted in the cloud template:
* os_version
* flavor
* localAdmin

There are four custom properties on the machine object
* image (from the os_version input)
* flavor (from the flavor input)
* localAdmin (from the localAdmin input)
* customizationSpec (an os customization spec in vcenter that includes domain join)

```
formatVersion: 1
inputs:
  os_version:
    type: string
    title: Operating System
  flavor:
    type: string
    title: Size
    enum:
      - Small
      - Medium
      - Large
  localAdmin:
    type: string
    title: Admin
resources:
  Cloud_vSphere_Disk_1:
    type: Cloud.vSphere.Disk
    properties:
      capacityGb: 5
  Cloud_vSphere_Machine_1:
    type: Cloud.vSphere.Machine
    properties:
      customizationSpec: joindomain
      image: '${input.os_version}'
      flavor: '${input.flavor}'
      localAdmin: '${input.localAdmin}'
      networks:
        - network: '${resource.Cloud_vSphere_Network_1.id}'
          assignment: static
      attachedDisks:
        - source: '${resource.Cloud_vSphere_Disk_1.id}'
  Cloud_vSphere_Network_1:
    type: Cloud.vSphere.Network
    properties:
      networkType: existing
      constraints:
        - tag: 'networkprofile:dev'
 ``` 
## Image Mapping
There are two flavor mappings defined for the cloud account, they each point to a valid template in vCenter:
* win2k16
* win2k19

![Image Mappings](images/image%20mappings.png?raw=true)


## Flavor Mappings
There are three flavor mappings defined
* Small
* Medium
* Large

![Flavor Mappings](images/flavor%20mappings.png?raw=true)

## Network Profiles
There is one network profile defined, consisting of two networks.  Each network has IP Ranges defined.  In this particular set up, vRA is acting as the IPAM and will choose an available IP for the server build.  Due to restrictions in this lab, each network only has one IP defined in the range.

![Network Profiles](images/network%20profile.png?raw=true)

![Networks](images/networks.png?raw=true)

![IP Range](images/ip%20range.png?raw=true)

## Active Directory Integration
The Active Directory integration was added and configured to point to a valid AD instance.  And an OU was specified for the Project that will be building servers.

![AD Integration](images/ad%20integration.png?raw=true)

![AD Project](images/ad%20project.png?raw=true)

With this integration, vRA will pre-create the computer account for a server build by this project in the OU specified.  This integration supports the ability to overwrite the OU or skip the integration entirely with additional settings in a cloud template.

## Project
The project has been given access to provision in the required cloud zones.  The project has also been given a simple default naming convention, so the user doesn't need to specify a server name during the build process.

![Naming Template](images/naming%20template.png?raw=true)

## Event Broker
There are three Event Broker Subscriptions configured for this process, each for the Compute Provision Post event (after the server has been provisioned)
* Add Local Admin (calls vRO)
* Format Disk (calls ABX)
* Install Notepad++ (calls vRO)

All three subscriptions are set to Blocking, which tells vRA that they can each only run one at a time.  To determine the order in which they run, the priority is set differently for each.  In general, for each event topic, all of the blocking subscriptions will run first in the order determined by their priority (and as documented by VMware when priorities are shared).  Once they are finished, all Non-Blocking subscriptions for that event topic will then run at the same time.

So when work needs to happen in a certain order, it can.  But for work that is not dependent on other items, they can run at once at the end.

![Subscriptions](images/subscriptions.png?raw=true)

![Subscription](images/subscription.png?raw=true)

## Event Broker Payload
A quick note about the payload that is passed from the Event Broker to an ABX Action or a vRO Workflow.  In ABX, that payload is installed in the $inputs parameter of the handler function.  In vRO, the workflow should be configured with an input called inputProperties of type Properties.

Each event topic has a documented set of inputs that are included in the paylod.  Some of those properties are writable and can therefore be sent back to the Event Broker as outputs.  When working with the Event Broker, it is helpful to inspect/log those variables to get a better understanding of what information is available.

A common use case is to access the custom properties of a template, which is included in the payload for most provisionging topics.  For example, accessed like this in a vRO worklow:
```
var customProps = inputProperties.customProperties
```

## vRO - Add Local Admin
This workflow:
* Parses the server name and local admin account from inputProperties payload
* Prepares a PowerShell script to add the account to local admins
* Uses built-in workflow to get the VM Object with that name
* Uses built-in workflow to run a program on the guest OS, passing the local path powershell and the script as arguments

```
vmname = inputProperties.resourceNames[0];
var admin = inputProperties.customProperties["localAdmin"];

scriptArgs =  '"';
scriptArgs += "Add-LocalGroupMember -Group Administrators -Member '" + admin + "'";
scriptArgs += '"';
```

*See Install Notepad++ section below for workflow screenshots, as these are pretty similar.*

## vRO - Install Notepad++
This workflow works nearly the same as the one to add a local adminstrator
* Parses the server name from the inputProperties payload
* Prepares a PowerShell script to download and install Notepad++
* Uses built-in workflow to get the VM Object with that name
* Uses built-in workflow to run a program on the guest OS, passing the local path powershell and the script as arguments

It can be very handy to use Config Elements and their Attributes to create re-usable variables.  These elements are shared by workflows and can be re-used easily.  This will help to avoid hard-coding values in multiple workflows, which can be problematic when those values need to change in the future.

![Install Npp Inputs](images/install%20npp%20-%20inputs.png?raw=true)

![Install Npp Vars](images/install%20npp%20-%20variables.png?raw=true)

![Install Npp Schema](images/install%20npp%20-%20schema.png?raw=true)

![Config Element](images/config%20element.png?raw=true)

```
vmname = inputProperties.resourceNames[0];
scriptArgs =  '"[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12';
scriptArgs += ";Invoke-WebRequest -Uri " + nppPath + " -Outfile C:\\npp.exe";
scriptArgs += ';C:\\npp.exe /S"';
```

## ABX - Format Drive
This ABX action works similar to the vRO workflows, but is less modular.  It's written in PowerShell
* Connects to the vCenter (user/pwd params stored as Action Constants)
* Prepares a script to initialize/format the disk and assign to E: drive
* Uses invoke-vmscript to run the script on the VM (user/pwd params stored as Action Constants)

Action Constants for ABX are similar to Config Elements in vRO. They provide you a central location to create variables/values which can be shared across multiple actions.

![Action Constants](images/action%20constants.png?raw=true)

```
function handler($context, $inputs) {
    
    $vmname = $inputs.resourceNames[0]

    # Build Credentials, stored as Action Constants
    $user = $inputs["vcUser"]
    $pass = $context.getSecret($inputs["vcPassword"])
    $secPass = ConvertTo-SecureString $pass -AsPlainText -Force
    $cred = New-Object System.Management.Automation.PSCredential ($user, $secPass)
    
    $osUser = $inputs["osUser"]
    $osPass = $context.getSecret($inputs["osPassword"])
    $osSecPass = ConvertTo-SecureString $osPass -AsPlainText -Force
    $osCred = New-Object System.Management.Automation.PSCredential ($osUser, $osSecPass)
    write-host "oscred"

    # Ignore cert errors for this powerCLI session
    Set-PowerCLIConfiguration -Scope Session -InvalidCertificateAction Ignore -Confirm:$false

    # Connect to the vcenter
    $vc = connect-viserver -server "vsphere.local" -credential $cred

    # Get the vm object 
    $vm = get-vm $vmname -server $vc

	  # Create a script that can be run on the vm to initialize/format the disk
    $script =  '$disk = get-disk | ? {$_.PartitionStyle -eq "Raw"} | select -first 1;'
    $script += 'initialize-disk -inputobject $disk;'
    $script += '$p = new-partition $disk.number -UseMaximumSize -AssignDriveLetter:$false;'
    $script += '$p | Format-Volume -FileSystem NTFS -Confirm:$false;' 
    $script += '$p | Set-Partition -NewDriveLetter "E"'
    
	  # Invoke the script on the vm
    $result = invoke-vmscript -vm $vm -ScriptText $script -GuestCredential $osCred
}
```
